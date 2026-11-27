import SwiftUI

/// One scholar's entry: a bold name with the Arabic, a secondary line of dates and place, and a description.
struct ScholarEntry: View {
    let name: String
    let arabic: String
    let meta: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("**\(name)**, \(arabic)")
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

struct SahabahScholarsView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the first scholars of Islam were the Companions, taught directly by the Prophet. Every chain of knowledge in the religion passes through them.")
                }

                Section(header: ArticleHeader("WHY SCHOLARS MATTER")) {
                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) raised the people of knowledge above others and made asking them an obligation on the one who does not know:")
                    ScriptureQuote(quran: "58:11", words: 17...25)

                    ScriptureQuote(quran: "39:9", words: 12...23)

                    ScriptureQuote(quran: "35:28", words: 7...12)

                    ScriptureQuote(quran: "16:43", words: 8...14)

                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:71", cite: "Saheeh al-Bukhaari 71, Saheeh Muslim 1037", arabic: 32...39, english: 6...20)

                    ScriptureQuote(hadith: "bukhari:100", cite: "Saheeh al-Bukhaari 100", arabic: 32...60, english: 6...71)

                    ArticleParagraph(verbatim: "Knowledge in Islam is not opinion; it is transmission. A scholar is one who carries the Quran and the Sunnah with understanding, from a teacher who carried it from his, back to the Companions and the Prophet (peace be upon him). This is why the scholars of Ahl as-Sunnah are known by their chains and their teachers.")
                }

                Section(header: ArticleHeader("THE FIRST SCHOLARS")) {
                    ArticleParagraph(verbatim: "The Companions (may Allah be pleased with them) learned the Quran as it came down and the Sunnah from the one who lived it. Among them some were singled out for knowledge. The Prophet (peace be upon him) said:")
                    ScriptureQuote(hadith: "tirmidhi:3790", cite: "Jaami‘ at-Tirmidhi 3790; graded saheeh by al-Albaani", arabic: 31...67, english: 7...101)

                    ScriptureQuote(hadith: "bukhari:4999", cite: "Saheeh al-Bukhaari 4999", arabic: 34...47, english: 22...36)
                }

                Section(header: ArticleHeader("THE RIGHTLY GUIDED CALIPHS")) {
                    ScholarEntry(name: "Abu Bakr as-Siddeeq", arabic: "أَبُو بَكر الصِّدِّيق", meta: "d. 13 AH / 634 CE · Madinah", description: "The most knowledgeable of the Companions. When the Prophet (peace be upon him) hinted from the pulpit that a servant had been given the choice to meet his Lord, Abu Bakr alone understood and wept, and the narrator says, “Abu Bakr was the most knowledgeable of us” (Saheeh al-Bukhaari 3654). He led the prayer in the Prophet’s final illness by his command (Saheeh al-Bukhaari 664), fought the apostates, and ordered the first collection of the Quran.")
                    ScriptureQuote(hadith: "bukhari:3654", cite: "Saheeh al-Bukhaari 3654, Saheeh Muslim 2382", arabic: 29...84, english: 0...86)
                    ScriptureQuote(hadith: "bukhari:664", cite: "Saheeh al-Bukhaari 664, Saheeh Muslim 418", arabic: 32...53, english: 16...48)

                    ScholarEntry(name: "Umar ibn al-Khattaab", arabic: "عُمَرُ بنُ الخَطَّابِ", meta: "d. 23 AH / 644 CE · Madinah", description: "Of whom the Prophet (peace be upon him) said, “If there were to be a muhaddath (one inspired with the truth) in my nation, it would be Umar” (Saheeh al-Bukhaari 3689). The Quran came down agreeing with his view more than once. He organised the Hijri calendar, the Taraaweeh congregation, the courts, and the provinces, and sent scholars such as Ibn Mas‘ood to teach the new cities.")
                    ScriptureQuote(hadith: "bukhari:3689", cite: "Saheeh al-Bukhaari 3689, Saheeh Muslim 2398", arabic: 30...43, english: 4...36)

                    ScholarEntry(name: "Uthmaan ibn Affaan", arabic: "عُثمَانُ بنُ عَفَّانَ", meta: "d. 35 AH / 656 CE · Madinah", description: "Married to two daughters of the Prophet (peace be upon him), one after the other, hence “Dhun-Noorayn.” He gathered the nation upon one written Quran, sending official copies to the great cities, the mushaf every Muslim reads today.")

                    ScholarEntry(name: "Ali ibn Abi Taalib", arabic: "عَلِيُّ بنُ أَبِي طَالِبٍ", meta: "d. 40 AH / 661 CE · Koofah", description: "Raised in the Prophet’s house and among the first to believe. The Prophet (peace be upon him) gave him the banner at Khaybar, saying Allah would grant victory at his hands (Saheeh al-Bukhaari 3701). A judge of the highest rank, the teacher of the scholars of Koofah, and the narrator of the hadith on the Khawaarij, whom he fought.")
                    ScriptureQuote(hadith: "bukhari:3701", cite: "Saheeh al-Bukhaari 3701, Saheeh Muslim 2406", arabic: 28...35, english: 4...21)
                }

                Section(header: ArticleHeader("THE SCHOLARS AMONG THE COMPANIONS")) {
                    ScholarEntry(name: "Abdullah ibn Mas‘ood", arabic: "عَبدُ اللَّهِ بنُ مَسعُودٍ", meta: "d. 32 AH / 653 CE · Madinah, taught in Koofah", description: "The sixth person to accept Islam and the first to recite the Quran aloud in Makkah. The Prophet (peace be upon him) named him first among those to take the Quran from. Sent by Umar to Koofah, his students (Alqamah, al-Aswad, Masrooq, then Ibraaheem an-Nakha‘i, then Hammaad, then Abu Haneefah) became the Iraqi school of fiqh.")

                    ScholarEntry(name: "Abdullah ibn Abbaas", arabic: "عَبدُ اللَّهِ بنُ عَبَّاسٍ", meta: "d. 68 AH / 687 CE · Taa’if", description: "The Prophet’s cousin, for whom he prayed, “O Allah, teach him the Book” (Saheeh al-Bukhaari 75) and “give him understanding of the religion” (Saheeh al-Bukhaari 143). He became “the Interpreter of the Quran” and “the Scholar of the Nation,” the teacher of Mujaahid, Ikrimah, Sa‘eed ibn Jubayr, and Ataa’, and the root of the Makkan school of tafseer.")
                    ScriptureQuote(hadith: "bukhari:75", cite: "Saheeh al-Bukhaari 75", arabic: 16...28, english: 0...18)
                    ScriptureQuote(hadith: "bukhari:143", cite: "Saheeh al-Bukhaari 143, Saheeh Muslim 2477", arabic: 28...45, english: 0...38)

                    ScholarEntry(name: "Aa’ishah bint Abi Bakr", arabic: "عَائِشَة بِنت أَبِي بَكر", meta: "d. 58 AH / 678 CE · Madinah", description: "The Mother of the Believers and the most knowledgeable woman of the nation; the Prophet (peace be upon him) said her superiority over women is like that of thareed over other food (Saheeh al-Bukhaari 3770). The senior Companions asked her about inheritance, the Prophet’s worship, and his private life, and she corrected scholars from the Quran and Sunnah. Over two thousand hadith are narrated from her.")
                    ScriptureQuote(hadith: "bukhari:3770", cite: "Saheeh al-Bukhaari 3770, Saheeh Muslim 2446", arabic: 37...44, english: 4...19)

                    ScholarEntry(name: "Zayd ibn Thaabit", arabic: "زَيدُ بنُ ثَابِتٍ", meta: "d. 45 AH / 665 CE · Madinah", description: "The Prophet’s scribe of revelation, who learned the script of the Jews at his command in about half a month (Sunan Abi Daawood 3645; Jaami‘ at-Tirmidhi 2715; graded hasan saheeh by al-Albaani). The most knowledgeable in inheritance law (Jaami‘ at-Tirmidhi 3790), he was chosen by Abu Bakr to collect the Quran and by Uthmaan to head its transcription.")
                    ScriptureQuote(hadith: "abudawud:3645", cite: "Sunan Abi Daawood 3645; graded hasan saheeh by al-Albaani", arabic: 24...55, english: 0...53)
                    ScriptureQuote(hadith: "tirmidhi:2715", cite: "Jaami‘ at-Tirmidhi 2715; graded hasan saheeh by al-Albaani", arabic: 24...74, english: 0...73)

                    ScholarEntry(name: "Mu‘aadh ibn Jabal", arabic: "مُعَاذُ بنُ جَبَلٍ", meta: "d. 18 AH / 639 CE · Syria", description: "The most knowledgeable in the lawful and the unlawful (Jaami‘ at-Tirmidhi 3790). The Prophet (peace be upon him) sent him to Yemen as teacher and judge with the words, “let the first thing you call them to be the tawheed of Allah” (Saheeh al-Bukhaari 7372), and rode with him while teaching him the right of Allah upon His servants (Saheeh al-Bukhaari 2856).")
                    ScriptureQuote(hadith: "bukhari:7372", cite: "Saheeh al-Bukhaari 7372, Saheeh Muslim 19a", arabic: 49...64, english: 0...39)
                    ScriptureQuote(hadith: "bukhari:2856", cite: "Saheeh al-Bukhaari 2856, Saheeh Muslim 30a", arabic: 26...82, english: 0...85)

                    ScholarEntry(name: "Ubayy ibn Ka‘b", arabic: "أُبَيُّ بنُ كَعبٍ", meta: "d. c. 22 AH / 643 CE · Madinah", description: "The master of the reciters. Allah commanded the Prophet (peace be upon him) to recite Surat al-Bayyinah to him by name, and Ubayy wept (Saheeh al-Bukhaari 4959). Umar chose him to lead the Taraaweeh prayer.")
                    ScriptureQuote(hadith: "bukhari:4959", cite: "Saheeh al-Bukhaari 4959, Saheeh Muslim 799", arabic: 19...44, english: 0...54)

                    ScholarEntry(name: "Abu Hurayrah", arabic: "أَبُو هُرَيرَة", meta: "d. 59 AH / 679 CE · Madinah", description: "The most prolific narrator of hadith, having devoted himself to the Prophet’s company for the last years of his life and, by the Prophet’s prayer, forgotten nothing he heard. He narrated because the Quran condemns concealing knowledge (Saheeh al-Bukhaari 118), and over five thousand hadith reached the nation through him.")
                    ScriptureQuote(hadith: "bukhari:118", cite: "Saheeh al-Bukhaari 118", arabic: 18...81, english: 0...126)

                    ScholarEntry(name: "Abdullah ibn Umar", arabic: "عَبدُ اللَّهِ بنُ عُمَرَ", meta: "d. 73 AH / 693 CE · Makkah", description: "Of whom the Prophet (peace be upon him) said, “What an excellent man Abdullah is, if only he prayed at night,” after which he hardly slept (Saheeh al-Bukhaari 3738). The most careful follower of the Prophet’s every action, the teacher of Naafi‘ and Saalim, and a root of the Madinan school of Imam Maalik.")
                    ScriptureQuote(hadith: "bukhari:3738", cite: "Saheeh al-Bukhaari 3738, Saheeh Muslim 2479", arabic: 122...141, english: 148...178)

                    ScholarEntry(name: "Hudhayfah ibn al-Yamaan", arabic: "حُذَيفَةُ بنُ اليَمَانِ", meta: "d. 36 AH / 656 CE · Madaa’in", description: "The keeper of the Prophet’s secret, who asked him about evil while others asked about good, and preserved his guidance for times of trial: “Hold to the community of the Muslims and their leader” (Saheeh al-Bukhaari 7084).")
                    ScriptureQuote(hadith: "bukhari:7084", cite: "Saheeh al-Bukhaari 7084, Saheeh Muslim 1847", arabic: 129...140, english: 189...219)

                    ScholarEntry(name: "Abu ad-Dardaa’, Abu Moosa al-Ash‘ari, Abu Dharr, Jaabir, Anas", arabic: "وَغَيرُهُم", meta: "the teachers of the cities", description: "Abu ad-Dardaa’ taught in Damascus; Abu Moosa al-Ash‘ari, given “one of the flutes of the family of Daawood” (Saheeh al-Bukhaari 5048), governed and taught Basrah and Koofah; Abu Dharr, than whom “the sky has not shaded nor the earth carried anyone more truthful” (Jaami‘ at-Tirmidhi 3801; graded saheeh by al-Albaani), was the voice of ascetic honesty; Jaabir ibn Abdullah had a circle in the Prophet’s mosque; and Anas ibn Maalik, the Prophet’s servant for ten years, blessed with wealth and children by his prayer (Saheeh al-Bukhaari 6334) and with long life (al-Adab al-Mufrad 653; graded saheeh by al-Albaani), taught in Basrah until 93 AH.")
                    ScriptureQuote(hadith: "bukhari:5048", cite: "Saheeh al-Bukhaari 5048, Saheeh Muslim 793", arabic: 40...49, english: 7...25)
                    ScriptureQuote(hadith: "tirmidhi:3801", cite: "Jaami‘ at-Tirmidhi 3801; graded saheeh by al-Albaani", arabic: 40...49, english: 7...25)
                    ScriptureQuote(hadith: "bukhari:6334", cite: "Saheeh al-Bukhaari 6334, Saheeh Muslim 2480", arabic: 25...32, english: 0...30)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The Companions were the first scholars and the first teachers. Every madhhab of fiqh, every school of tafseer, and every chain of hadith goes back to one of these men and women sitting before the Prophet.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Sahaabi (صَحَابِيّ)**: a Companion, from the root ص-ح-ب, “to accompany.” Ibn Hajar (may Allah have mercy on him) gives the accepted definition in al-Isaabah:")
                        ScriptureQuote(text: "“The Sahaabi is one who met the Prophet (peace be upon him) believing in him, and died upon Islam” (Ibn Hajar, al-Isaabah fi Tamyeez as-Sahaabah).", arabic: "الصَّحَابِيُّ: مَن لَقِيَ النَّبِيَّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ مُؤمِنًا بِهِ، وَمَاتَ عَلَى الإِسلَامِ", dimmed: true)
                        ArticleParagraph(verbatim: "So a Companion is not only one who kept his company for years; whoever met him as a believer, even once, and died a Muslim is a Sahaabi. Allah declared Himself pleased with them, and so Ahl as-Sunnah hold that every Companion is trustworthy in what he narrates; a chain is examined below the Companion, never at him:")
                        ScriptureQuote(quran: "9:100", words: 0...12)
                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) forbade abusing them:")
                        ScriptureQuote(hadith: "bukhari:3673", cite: "Saheeh al-Bukhaari 3673, Saheeh Muslim 2541", arabic: 31...46, english: 4...40)

                        ArticleParagraph(articleMarkdown: "**Ahlul Bayt (أَهل البَيت)**: “the People of the House,” from bayt (بَيت), “house”: the household of the Prophet (peace be upon him). They are his wives, whom the verse of purification addresses in its context, and his relatives for whom zakaah is forbidden, the families of Ali, Aqeel, Ja‘far, and al-Abbaas, as Zayd ibn Arqam explained (Saheeh Muslim 2408). Allah says:")
                        ScriptureQuote(quran: "33:33", words: 15...24)
                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) wrapped Ali, Faatimah, al-Hasan, and al-Husayn in his cloak and recited this verse over them (Saheeh Muslim 2424).")
                        ScriptureQuote(hadith: "muslim:2424", cite: "Saheeh Muslim 2424", arabic: 35...78, english: 0...19)
                        ArticleParagraph(verbatim: "And at the pool of Khumm, between Makkah and Madinah, he said:")
                        ScriptureQuote(hadith: "muslim:2408a", cite: "Saheeh Muslim 2408", arabic: 179...185, english: 226...245)
                        ArticleParagraph(verbatim: "Ahl as-Sunnah love them, honour them, and keep this will, without raising them above the rank Allah gave them; see the page “The People of the House.”")

                        ArticleParagraph(articleMarkdown: "**The Ten Promised Paradise (العَشَرَة المُبَشَّرُون بِالجَنَّة)**: “the ten given glad tidings of Paradise,” from bushra (بُشرَى), “glad tidings”: ten Companions named together as people of Paradise in one hadith. The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "tirmidhi:3747", cite: "Jaami‘ at-Tirmidhi 3747; graded saheeh by al-Albaani", arabic: 30...66, english: 7...58)
                        ArticleParagraph(verbatim: "Sa‘d is Sa‘d ibn Abi Waqqaas and Sa‘eed is Sa‘eed ibn Zayd, as Sa‘eed ibn Zayd himself narrated (Sunan Abi Daawood 4649; graded saheeh by al-Albaani). Others were given the glad tidings individually, among them Faatimah (Saheeh al-Bukhaari 3623), al-Hasan and al-Husayn (Jaami‘ at-Tirmidhi 3768; graded saheeh by al-Albaani), and Abdullah ibn Salaam (Saheeh al-Bukhaari 3812); the ten are singled out because they were named in one breath.")
                        ScriptureQuote(hadith: "abudawud:4649", cite: "Sunan Abi Daawood 4649; graded saheeh by al-Albaani", arabic: 44...102, english: 43...133)
                        ScriptureQuote(hadith: "bukhari:3623", cite: "Saheeh al-Bukhaari 3623, Saheeh Muslim 2450", arabic: 122...133, english: 157...184)
                        ScriptureQuote(hadith: "tirmidhi:3768", cite: "Jaami‘ at-Tirmidhi 3768; graded saheeh by al-Albaani", arabic: 37...42, english: 7...17)
                        ScriptureQuote(hadith: "bukhari:3812", cite: "Saheeh al-Bukhaari 3812", arabic: 27...47, english: 0...25)

                        ArticleParagraph(articleMarkdown: "**The Rightly Guided Caliphs (الخُلَفَاء الرَّاشِدُون)**: Abu Bakr, Umar, Uthmaan, and Ali (may Allah be pleased with them), in that order of caliphate and of excellence. Khaleefah (خَلِيفَة) is from the root خ-ل-ف, “to come after, to succeed,” and raashid (رَاشِد) from ر-ش-د, “to be rightly guided.” The Prophet (peace be upon him) commanded the nation to hold to “my Sunnah and the Sunnah of the rightly guided caliphs after me” (Sunan Abi Daawood 4607; graded saheeh by al-Albaani), a hadith quoted in full on the pages “Salafiyyah” and “Ahl As-Sunnah” in this app. Their practice is therefore a guided pattern for the nation, not personal opinion. Umar ibn Abd al-Azeez is often counted with them for his justice.")
                        ScriptureQuote(hadith: "abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 96...132, english: 129...192)

                        ArticleParagraph(articleMarkdown: "**The Four Abdullahs (العَبَادِلَة الأَربَعَة)**: Abaadilah is the plural of Abdullah. Four young Companions who each bore the name, outlived most of the others, and became the teachers of the following generation: Abdullah ibn Abbaas, Abdullah ibn Umar, Abdullah ibn az-Zubayr, and Abdullah ibn Amr ibn al-As (may Allah be pleased with them). Imam Ahmad named these four as the Abaadilah and did not count Abdullah ibn Mas‘ood, for all his knowledge, because he died early, in 32 AH, before the nation needed their fataawa; when the four agreed on a ruling the jurists said, “this is the saying of the Abaadilah” (Ibn as-Salaah, Uloom al-Hadith).")

                        ArticleParagraph(articleMarkdown: "**The Mothers of the Believers (أُمَّهَات المُؤمِنِين)**: from umm (أُمّ), “mother”: the wives of the Prophet (peace be upon him), given this title by Allah Himself. They are forbidden in marriage to the nation forever (Quran 33:53), honoured as mothers are honoured, and were teachers of the religion, above all Aa’ishah and Umm Salamah:")
                        ScriptureQuote(quran: "33:53", words: 49...62)
                        ScriptureQuote(quran: "33:6", words: 0...6)

                        ArticleParagraph(articleMarkdown: "**Taabi‘i (تَابِعِيّ)** and **Taabi‘ at-Taabi‘een (تَابِع التَّابِعِين)**: from the root ت-ب-ع, “to follow.” A Taabi‘i (Successor) is one who met a Companion as a Muslim and died as a Muslim; a Taabi‘ at-Taabi‘een is one who likewise met a Taabi‘i. They are the second and third of the three generations the Prophet (peace be upon him) called the best of people (Saheeh al-Bukhaari 2652), and they are “those who followed them with good conduct” of the verse above. Sa‘eed ibn al-Musayyib, al-Hasan al-Basri, and Mujaahid are of the first; Maalik, Sufyaan ath-Thawri, and al-Awzaa‘i are of the second. See the page “The Salaf and the Imams.”")
                        ScriptureQuote(hadith: "bukhari:2652", cite: "Saheeh al-Bukhaari 2652, Saheeh Muslim 2533", arabic: 29...37, english: 4...23)

                        ArticleParagraph(articleMarkdown: "**The Seven Jurists of Madinah (الفُقَهَاء السَّبعَة)**: seven Taabi‘oon of Madinah whose fataawa formed the school inherited by Imam Maalik: Sa‘eed ibn al-Musayyib, Urwah ibn az-Zubayr, al-Qaasim ibn Muhammad ibn Abi Bakr, Khaarijah ibn Zayd ibn Thaabit, Sulaymaan ibn Yasaar, Ubaydullah ibn Abdullah ibn Utbah, and Abu Bakr ibn Abd ar-Rahman ibn al-Haarith, though some name Abu Salamah ibn Abd ar-Rahman or Saalim ibn Abdullah ibn Umar as the seventh. Urwah was the son of az-Zubayr, al-Qaasim the grandson of Abu Bakr, and Khaarijah the son of Zayd ibn Thaabit, which shows how knowledge passed within the households of the Companions.")

                        ArticleParagraph(articleMarkdown: "**Salaf (سَلَف)**: “those who came before,” from the root س-ل-ف, “to precede.” In the usage of the scholars it means the Companions, the Taabi‘oon, and the Taabi‘ at-Taabi‘een, the three best generations, and then those who followed their way. The Prophet (peace be upon him) used the word of himself when he told Faatimah of his approaching death:")
                        ScriptureQuote(hadith: "bukhari:6285", cite: "Saheeh al-Bukhaari 6285", arabic: 168...175, english: 241...259)
                        ArticleParagraph(verbatim: "“Salafi” therefore means nothing more than one who follows the Salaf in creed and practice, as explained on the page “Salafiyyah.”")

                        ArticleParagraph(articleMarkdown: "**Aalim (عَالِم)**, plural **ulama (عُلَمَاء)**: “one who knows,” from the root ع-ل-م. In the Quran the ulama are those who fear Allah because they know Him (Quran 35:28, quoted above), so knowledge that does not produce fear is not the knowledge Allah praised, and the sign that Allah wants good for a person is that He gives him understanding of the religion (Saheeh al-Bukhaari 71, quoted above). Ibn Mas‘ood (may Allah be pleased with him) said that knowledge is not abundance of narration; knowledge is fear of Allah (Ahmad, az-Zuhd; cited by Ibn Katheer in his Tafseer under Quran 35:28).")

                        ArticleParagraph(articleMarkdown: "**Rabbaani (رَبَّانِيّ)**: from Rabb (رَبّ), “Lord”: one devoted to his Lord who nurtures the people upon His religion. Allah says that the prophets commanded their followers:")
                        ScriptureQuote(quran: "3:79", words: 19...27)
                        ArticleParagraph(verbatim: "Ibn Abbaas explained the Rabbaaniyyoon as the forbearing and the jurists, and al-Bukhaari adds in the chapter headings of his Saheeh, “it is said that the Rabbaani is the one who nurtures the people with the small matters of knowledge before the great ones” (Saheeh al-Bukhaari, Kitaab al-Ilm, chapter “Knowledge before speech and action”).")

                        ArticleParagraph(articleMarkdown: "**Ahl adh-Dhikr (أَهل الذِّكر)**: “the people of the Reminder,” dhikr (ذِكر) being the revelation Allah sent down: those who know it, whom Allah commands the one who does not know to ask (Quran 16:43, quoted above). The verse speaks first of the people of the earlier Scriptures, and its ruling covers the scholars of the Quran and Sunnah in every age, as the scholars of tafseer explain.")

                        ArticleParagraph(articleMarkdown: "**Imam (إِمَام)**: “one who is followed,” from the root أ-م-م, the same word as the leader of the prayer. In scholarship it is the title of a scholar whose knowledge made him a reference for others, as in “Imam Maalik” and “Imam Ahmad.” Allah says of the leaders of the Children of Israel:")
                        ScriptureQuote(quran: "32:24")
                        ArticleParagraph(verbatim: "Ibn al-Qayyim relates in Madaarij as-Saalikeen that he heard his teacher Ibn Taymiyyah say that by patience and certainty leadership in the religion is attained. In Ahl as-Sunnah the title carries no infallibility; an imam is followed for his evidence.")

                        ArticleParagraph(articleMarkdown: "**Haafiz (حَافِظ)**: “preserver,” from the root ح-ف-ظ. Among the hadith scholars it is the rank of one who has memorised a great body of hadith with their chains and knows their narrators, above the ordinary muhaddith; Ibn Hajar and adh-Dhahabi are called al-Haafiz. In common speech it is also used for one who has memorised the whole Quran. The Prophet (peace be upon him) prayed for those who preserve his words:")
                        ScriptureQuote(hadith: "tirmidhi:2657", cite: "Jaami‘ at-Tirmidhi 2657; graded saheeh by al-Albaani", arabic: 36...49, english: 21...54)

                        ArticleParagraph(articleMarkdown: "**Muhaddith (مُحَدِّث)**: from hadith (حَدِيث), “speech, report”: a scholar who transmits and examines the narrations of the Prophet (peace be upon him): their chains, their narrators, their wordings, and their hidden defects. Al-Bukhaari, Muslim, Abu Daawood, and in our time al-Albaani are muhaddithoon. Not every muhaddith is a jurist; as the Prophet (peace be upon him) said in the hadith narrated by Zayd ibn Thaabit, “many a bearer of knowledge conveys it to one who is more versed than he is, and many a bearer of knowledge is not versed in it” (Sunan Abi Daawood 3660; graded saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "abudawud:3660", cite: "Sunan Abi Daawood 3660; graded saheeh by al-Albaani", arabic: 39...60, english: 8...55)

                        ArticleParagraph(articleMarkdown: "**Faqeeh (فَقِيه)**: from fiqh (فِقه), “understanding”: a scholar who derives the rulings of the lawful and the unlawful from the texts. The Prophet (peace be upon him) prayed that Ibn Abbaas be given fiqh (Saheeh al-Bukhaari 143), and Mu‘aadh was the most knowledgeable of the Companions in the lawful and the unlawful (Jaami‘ at-Tirmidhi 3790, quoted above).")

                        ArticleParagraph(articleMarkdown: "**Mufassir (مُفَسِّر)**: from tafseer (تَفسِير), “explanation,” from the root ف-س-ر, “to uncover”: a scholar who explains the Quran by the Quran, the Sunnah, the statements of the Companions and the Taabi‘oon, and the Arabic language. Ibn Abbaas was the first great mufassir, by the prayer of the Prophet (peace be upon him) that he be taught the Book (Saheeh al-Bukhaari 75); at-Tabari, Ibn Katheer, and as-Sa‘di are among his heirs. See the page “Tafseer.”")

                        ArticleParagraph(articleMarkdown: "**Mujtahid (مُجتَهِد)**: from ijtihaad (اِجتِهَاد), “exerting effort,” from the root ج-ه-د: a scholar qualified to derive rulings directly from the Quran and Sunnah on questions the texts do not settle by their plain wording. The Prophet (peace be upon him) promised the judge who strives and is correct two rewards and the one who strives and errs one reward (Saheeh al-Bukhaari 7352), so ijtihaad is honoured even when it misses, and its error is forgiven, not followed.")
                        ScriptureQuote(hadith: "bukhari:7352", cite: "Saheeh al-Bukhaari 7352, Saheeh Muslim 1716", arabic: 46...60, english: 7...71)

                        ArticleParagraph(articleMarkdown: "**Qaadi (قَاضِي)**: “judge,” from the root ق-ض-ي, “to decide”: the scholar appointed to judge between people by the Sharee‘ah. Ali and Mu‘aadh judged in Yemen in the Prophet’s lifetime, Shurayh judged Koofah for Umar and Ali, and later scholars such as Abu Yoosuf, the chief judge of the Abbasids, and Ibn Hajar, the chief Shaafi‘i judge of Egypt, held the office.")

                        ArticleParagraph(articleMarkdown: "**Shaykh al-Islam (شَيخ الإِسلَام)**: shaykh (شَيخ) is “elder” or “master”: a title of honour given by the scholars to one to whom the people of an age turned in creed and law. It was given to Abu Ismaa‘eel al-Harawi in the fifth century, to Ibn Taymiyyah above all, and to Ibn Hajar; Ibn Naasir ad-Deen ad-Dimashqi wrote ar-Radd al-Waafir to show how many imams had used it for Ibn Taymiyyah.")

                        ArticleParagraph(articleMarkdown: "**Ameer al-Mu’mineen fil-Hadith (أَمِير المُؤمِنِين فِي الحَدِيث)**: “the Commander of the Believers in hadith,” the highest title of the hadith scholars, given to a handful of masters in each age, among them Shu‘bah and Sufyaan ath-Thawri, as adh-Dhahabi records in Siyar A‘laam an-Nubalaa’, then al-Bukhaari, and in later times Ibn Hajar.")

                        ArticleParagraph(articleMarkdown: "**Mujaddid (مُجَدِّد)**: “renewer,” from the root ج-د-د: one who renews the religion after it has been neglected, by teaching the Sunnah and removing innovation. The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "abudawud:4291", cite: "Sunan Abi Daawood 4291; graded saheeh by al-Albaani", arabic: 36...49, english: 4...25)
                        ArticleParagraph(verbatim: "The scholars counted Umar ibn Abd al-Azeez as the renewer of the first century and ash-Shaafi‘i of the second, and later scholars counted Ibn Taymiyyah and Muhammad ibn Abd al-Wahhaab among the renewers of their centuries. The hadith does not say the renewer must be one man; Ibn Katheer wrote in al-Bidaayah wan-Nihaayah that it includes the carriers of knowledge of every field.")

                        ArticleParagraph(articleMarkdown: "**Isnaad (إِسنَاد)**: “chain of support,” from the root س-ن-د, “to lean upon”: the chain of narrators by which a hadith reaches us: “so-and-so told me, from so-and-so, from the Prophet.” Abdullah ibn al-Mubaarak’s words that the isnaad is part of the religion are quoted on the page “The Salaf and the Imams.” Muhammad ibn Seereen described how the demand for it began:")
                        ScriptureQuote(text: "“They did not use to ask about the isnaad, but when the fitnah occurred they said: name your men to us. So the people of the Sunnah were looked at and their hadith taken, and the people of innovation were looked at and their hadith not taken” (Muqaddimah of Saheeh Muslim).", arabic: "لَم يَكُونُوا يَسأَلُونَ عَنِ الإِسنَادِ، فَلَمَّا وَقَعَتِ الفِتنَةُ قَالُوا: سَمُّوا لَنَا رِجَالَكُم، فَيُنظَرُ إِلَى أَهلِ السُّنَّةِ فَيُؤخَذُ حَدِيثُهُم، وَيُنظَرُ إِلَى أَهلِ البِدَعِ فَلاَ يُؤخَذُ حَدِيثُهُم", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**Jarh wa Ta‘deel (الجَرح وَالتَّعدِيل)**: “criticism and declaring trustworthy”; jarh (جَرح) is literally “wounding” and ta‘deel is from ‘adl (عَدل), “uprightness”: the science of judging narrators, so that a hadith is accepted only from the truthful and the accurate. It is founded on the Quranic command to verify reports:")
                        ScriptureQuote(quran: "49:6", words: 0...7)
                        ArticleParagraph(verbatim: "Its imams were Shu‘bah, Yahya ibn Sa‘eed al-Qattaan, Ibn Ma‘een, Ali ibn al-Madeeni, Ahmad, al-Bukhaari, Abu Haatim, and an-Nasaa’i, and its rulings fill the books of narrators such as Tahdheeb al-Kamaal of al-Mizzi and Tahdheeb at-Tahdheeb of Ibn Hajar.")

                        ArticleParagraph(articleMarkdown: "**Siyar (سِيَر)**: plural of seerah (سِيرَة), “way of life,” from the root س-ي-ر, “to travel”: biographies. The greatest work of the kind is Siyar A‘laam an-Nubalaa’ of adh-Dhahabi, the lives of the notable figures of the nation from the Companions to his own day, and the source of much on these pages.")

                        ArticleParagraph(articleMarkdown: "**Tabaqaat (طَبَقَات)**: “layers” or “generations,” from the root ط-ب-ق. The scholars arranged the narrators and the jurists in generations, the Companions, then the Taabi‘oon, and so on, in books such as at-Tabaqaat al-Kubra of Ibn Sa‘d, Tabaqaat al-Hanaabilah of Ibn Abi Ya‘la, and Tabaqaat ash-Shaafi‘iyyah of as-Subki, so that a chain can be checked: each narrator must have lived in the generation that could meet the one above him.")
                    }
                }

                ArticleSourcesSection(article: "SahabahScholarsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Scholars of the Sahaabah")
        .englishArticle().selectableArticleList(article: "SahabahScholarsView")
    }
}

struct SalafScholarsView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Taabi‘oon learned from the Companions, their students became the imams of fiqh and hadith, and together these three generations are the Salaf whose understanding defines Ahl as-Sunnah.")
                }

                Section(header: ArticleHeader("THE TAABI‘OON (SUCCESSORS)")) {
                    ArticleParagraph(articleMarkdown: "The **Taabi‘oon (التَّابِعُون)** met the Companions and took the religion from them. The Prophet (peace be upon him) called them the second best generation (Saheeh al-Bukhaari 2652).")
                    ScriptureQuote(hadith: "bukhari:2652", cite: "Saheeh al-Bukhaari 2652, Saheeh Muslim 2533", arabic: 29...37, english: 4...23)
                    ArticleParagraph(verbatim: "Among the greatest:")

                    ScholarEntry(name: "Sa‘eed ibn al-Musayyib", arabic: "سَعِيدُ بنُ المُسَيَّبِ", meta: "d. 94 AH / 713 CE · Madinah", description: "The master of the Taabi‘oon and chief of the seven jurists of Madinah, married to the daughter of Abu Hurayrah and the most knowledgeable of the people in the judgements of Umar.")

                    ScholarEntry(name: "Al-Hasan al-Basri", arabic: "الحَسَن البَصرِي", meta: "d. 110 AH / 728 CE · Basrah", description: "Raised in the house of Umm Salamah, the preacher of Basrah whose sermons on the Hereafter, sincerity, and the decree are the pattern of every later reminder. It was from his circle that Waasil ibn Ata withdrew to found the Mu‘tazilah, and al-Hasan remained upon the Sunnah.")

                    ScholarEntry(name: "Mujaahid ibn Jabr", arabic: "مُجَاهِدُ بنُ جَبرٍ", meta: "d. 104 AH / 722 CE · Makkah", description: "Who said he read the Quran to Ibn Abbaas three times, stopping at every verse to ask about it. His explanations fill the tafseer of at-Tabari.")

                    ScholarEntry(name: "Sa‘eed ibn Jubayr, Ikrimah, Ataa’ ibn Abi Rabaah", arabic: "تَلَامِيذُ ابنِ عَبَّاسٍ", meta: "d. 95, 105, 114 AH · Koofah and Makkah", description: "The three other great students of Ibn Abbaas. Sa‘eed ibn Jubayr was killed by al-Hajjaaj in 95 AH after the revolt of Ibn al-Ash‘ath, and his death is counted a martyrdom; Ikrimah carried his master’s tafseer; Ataa’ was the mufti of Makkah in the Hajj season.")

                    ScholarEntry(name: "Muhammad ibn Seereen", arabic: "مُحَمَّدُ بنُ سِيرِينَ", meta: "d. 110 AH / 728 CE · Basrah", description: "The scrupulous jurist who said, “This knowledge is religion, so look from whom you take your religion” (Muqaddimah of Saheeh Muslim). His caution about narrators is the seed of the science of hadith criticism.")

                    ScholarEntry(name: "Ibraaheem an-Nakha‘i and Alqamah", arabic: "إِبرَاهِيم النَّخَعِي وَعَلقَمَة", meta: "d. 96 and 62 AH · Koofah", description: "The heirs of Ibn Mas‘ood in Koofah. Alqamah resembled his teacher in manner and knowledge; an-Nakha‘i was the jurist of Iraq whose student Hammaad taught Abu Haneefah.")

                    ScholarEntry(name: "Umar ibn Abd al-Azeez", arabic: "عُمَرُ بنُ عَبدِ العَزِيزِ", meta: "d. 101 AH / 720 CE · Syria", description: "The just caliph counted among the rightly guided, who ordered the first official writing down of the hadith and returned the wealth of the state to the people.")

                    ScholarEntry(name: "Ibn Shihaab az-Zuhri", arabic: "ابنُ شِهَابٍ الزُّهرِيُّ", meta: "d. 124 AH / 742 CE · Madinah", description: "The first to systematically record the hadith of Madinah, the teacher of Maalik, and a narrator in the chains of a huge part of the Sunnah.")
                }

                Section(header: ArticleHeader("THE IMAMS OF FIQH")) {
                    ArticleParagraph(articleMarkdown: "The students of the Taabi‘oon, the **Atbaa‘ at-Taabi‘een**, were the third generation. From them and from the students they taught came the four imams of the schools of fiqh (see “The Madhaahib of Fiqh”): **Abu Haneefah** (80–150 AH), **Maalik** (93–179 AH), **ash-Shaafi‘i** (150–204 AH), and **Ahmad ibn Hanbal** (164–241 AH). Beside them stood imams of equal rank whose schools did not survive as madhaahib but whose knowledge did:")

                    ScholarEntry(name: "Al-Awzaa‘i", arabic: "الأَوزَاعِي", meta: "88–157 AH · Beirut, Syria", description: "The imam of Syria, whose school was followed in Syria for about two centuries and in Andalusia until the Maaliki school replaced it, and who said, “Hold to the narrations of those who came before, even if the people reject you” (al-Khateeb al-Baghdaadi, Sharaf Ashaab al-Hadith 6; al-Aajurri, ash-Sharee‘ah 127).")

                    ScholarEntry(name: "Sufyaan ath-Thawri", arabic: "سُفيَان الثَّورِي", meta: "97–161 AH · Koofah", description: "Called “the Commander of the Believers in hadith,” a jurist with his own school, and the ascetic who said innovation is more beloved to Iblees than sin, for sin is repented of and innovation is not (al-Laalakaa’i, Sharh Usool I‘tiqaad Ahl as-Sunnah 238).")

                    ScholarEntry(name: "Al-Layth ibn Sa‘d", arabic: "اللَّيثُ بنُ سَعدٍ", meta: "94–175 AH · Egypt", description: "The imam of Egypt, of whom ash-Shaafi‘i said he was a greater jurist than Maalik but his students did not preserve his school (adh-Dhahabi, Siyar A‘laam an-Nubalaa’, vol. 8, in his biography).")

                    ScholarEntry(name: "Abdullah ibn al-Mubaarak", arabic: "عَبدُ اللَّهِ بنُ المُبَارَكِ", meta: "118–181 AH · Marw, Khuraasaan", description: "Scholar, merchant, warrior, and ascetic in one; the author of az-Zuhd and al-Jihad, and the man who said, “The isnaad is part of the religion; were it not for the isnaad, anyone would say whatever he wished” (Muqaddimah of Saheeh Muslim).")

                    ScholarEntry(name: "Sufyaan ibn Uyaynah, Wakee‘, al-Fudayl ibn Iyaad", arabic: "ابنُ عُيَينَةَ، وَكِيعٌ، الفُضَيلُ", meta: "d. 198, 197, 187 AH · Makkah and Koofah", description: "Sufyaan ibn Uyaynah, the hadith master of Makkah and teacher of ash-Shaafi‘i and Ahmad; Wakee‘ ibn al-Jarraah, the teacher of ash-Shaafi‘i and Ahmad in Koofah; and al-Fudayl ibn Iyaad, the repentant highwayman who became the worshipper of the Haram, whose words on sincerity the Salaf passed down.")
                }

                Section(header: ArticleHeader("THE IMAMS OF HADITH")) {
                    ArticleParagraph(verbatim: "The generation after the four imams gave the nation the collections in which the Sunnah is preserved:")

                    ScholarEntry(name: "Yahya ibn Ma‘een, Ali ibn al-Madeeni, Ishaaq ibn Raahwayh", arabic: "أَئِمَّة الجَرح وَالتَّعدِيل", meta: "d. 233, 234, 238 AH · Baghdaad, Basrah, Nishapur", description: "The masters of narrator criticism, the companions of Imam Ahmad, and the teachers of al-Bukhaari.")

                    ScholarEntry(name: "Muhammad ibn Ismaa‘eel al-Bukhaari", arabic: "البُخَارِي", meta: "194–256 AH / 810–870 CE · Bukhara", description: "Who chose about 7,300 hadith from six hundred thousand for his Saheeh, the most authentic book after the Quran, praying two units before entering each one.")

                    ScholarEntry(name: "Muslim ibn al-Hajjaaj", arabic: "مُسلِم", meta: "204–261 AH / 821–875 CE · Nishapur", description: "Al-Bukhaari’s student, whose Saheeh is second to his master’s in authenticity and first in arrangement.")

                    ScholarEntry(name: "Abu Daawood, at-Tirmidhi, an-Nasaa’i, Ibn Maajah", arabic: "أَصحَاب السُّنَن", meta: "d. 275, 279, 303, 273 AH", description: "The authors of the four Sunan, completing the six books. At-Tirmidhi (a student of al-Bukhaari) recorded the grade of each hadith and the opinions of the jurists; an-Nasaa’i was the strictest of them in narrators.")

                    ScholarEntry(name: "Ad-Daarimi, Ibn Khuzaymah, Ibn Hibbaan, ad-Daaraqutni, al-Haakim, al-Bayhaqi", arabic: "الحُفَّاظ", meta: "3rd to 5th century AH", description: "The hadith masters whose Sunan, Saheehs, and Mustadrak preserved what the six left, and whose books on creed (al-Bukhaari’s Khalq Af‘aal al-Ibaad, the reply to the Jahmiyyah of Uthmaan ibn Sa‘eed ad-Daarimi (d. 280 AH), a different man from the Daarimi of the Sunan, Ibn Khuzaymah’s Kitaab at-Tawheed) recorded the Athari creed with its evidences; al-Bayhaqi, though Ash‘ari in creed, preserved in al-Asmaa’ was-Sifaat the narrations of the Salaf on the attributes.")

                    ScholarEntry(name: "Al-Barbahaari, Ibn Battah, al-Laalakaa’i, Ibn Abd al-Barr, al-Khateeb al-Baghdaadi", arabic: "أَئِمَّة السُّنَّة", meta: "d. 329, 387, 418, 463, 463 AH", description: "Al-Barbahaari and Ibn Battah, the Hanbali imams of Iraq, and the Shaafi‘i al-Laalakaa’i, who wrote the creed of the Salaf down sect by sect (Sharh as-Sunnah, al-Ibaanah, Sharh Usool I‘tiqaad Ahl as-Sunnah); the Maaliki Ibn Abd al-Barr of Andalusia, the hadith master of the West; and al-Khateeb, the historian of Baghdaad and author of Sharaf Ashaab al-Hadith.")
                }

                Section(header: ArticleHeader("WHAT MADE THEM THE SALAF")) {
                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                    ScriptureQuote(hadith: "muslim:2699a", cite: "Saheeh Muslim 2699", arabic: 101...125, english: 111...166)

                    ArticleParagraph(verbatim: "The Salaf were such gatherings: men who sat before the Companions and passed on what they heard, word for word, with the names of those they heard it from. They did not philosophise the creed, and they did not invent worship. Their agreement is a proof, because the Prophet (peace be upon him) guaranteed their goodness.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("From Ibn al-Musayyib and al-Hasan al-Basri to the four imams and the authors of the six books, the Salaf carried the religion by chains of teacher and student. The understanding of these generations is the measure of every later scholar.")
                }

                ArticleSourcesSection(article: "SalafScholarsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Salaf and the Imams")
        .englishArticle().selectableArticleList(article: "SalafScholarsView")
    }
}

struct TabariView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Ibn Jareer at-Tabari (224–310 AH) wrote the greatest early tafseer and the great early history of Islam, gathering the explanations of the Companions and Taabi‘oon with their chains.")
                }

                Section(header: ArticleHeader("HIS LIFE")) {
                    ArticleParagraph(articleMarkdown: "**Abu Ja‘far Muhammad ibn Jareer at-Tabari (مُحَمَّدُ بنُ جَرِيرٍ الطَّبَرِيُّ)** was born in 224 AH / 839 CE in Aamul in Tabaristan, on the southern shore of the Caspian Sea. He memorised the Quran at seven, led the prayer at eight, and wrote hadith at nine. He travelled to Rayy, Baghdaad, Basrah, Koofah, Syria, and Egypt in search of knowledge, then settled in Baghdaad, where he taught until his death in 310 AH / 923 CE.")

                    ArticleParagraph(verbatim: "He never married, ate little, and is said to have written forty pages a day for forty years. He refused gifts from rulers and the office of judge, living from a small income sent by his father from Tabaristan.")
                }

                Section(header: ArticleHeader("HIS WORKS")) {
                    ArticleParagraph(articleMarkdown: "**Jaami‘ al-Bayaan ‘an Ta’weel Ay al-Quran (جَامِع البَيَان)**, known as Tafseer at-Tabari: the mother of all books of tafseer. For each verse he gathers the explanations of the Companions and the Taabi‘oon with their chains of narration, weighs them, and gives his judgement with the reasoning from the Arabic language. Later works of tafseer bil-ma’thoor, including Ibn Katheer’s, draw on it.")

                    ArticleParagraph(articleMarkdown: "**Taareekh ar-Rusul wal-Mulook (تَارِيخ الرُّسُل وَالمُلُوك)**, the History of the Prophets and Kings: the great chronicle from the creation to the year 302 AH, in which the reports are given with their chains so that the reader can judge them, since he warned in its introduction that he was a transmitter, not a guarantor, of what he collected.")

                    ArticleParagraph(articleMarkdown: "**Tahdheeb al-Athar**, a hadith work left unfinished; **Ikhtilaaf al-Fuqahaa’** on the differences of the jurists; and **Sareeh as-Sunnah (صَرِيح السُّنَّة)**, his short statement of creed.")
                }

                Section(header: ArticleHeader("HIS CREED")) {
                    ArticleParagraph(verbatim: "In Sareeh as-Sunnah he laid out the belief of Ahl as-Sunnah: that the Quran is the speech of Allah, uncreated; that the believers will see their Lord on the Day of Resurrection; that faith is word and deed and increases and decreases; that the decree, good and bad, is from Allah; and that the best of the nation after its Prophet are Abu Bakr, Umar, Uthmaan, and Ali. He affirmed the attributes as they came, and his tafseer on the verse of the Throne affirms Allah’s rising without asking how.")

                    ArticleParagraph(verbatim: "He was a mujtahid whose own school of fiqh, the Jareeriyyah, was followed for a time and then faded, which shows that a man can be an imam of the nation without leaving behind a madhhab.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("At-Tabari gathered what the first generations said about every verse and every year of history, with the chains that let the nation check it. He is the imam of the mufassiroon and the historians.")
                }

                ArticleSourcesSection(article: "TabariView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("At-Tabari")
        .englishArticle().selectableArticleList(article: "TabariView")
    }
}

struct IbnTaymiyyahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Ibn Taymiyyah (661–728 AH) is Shaykh al-Islam, the reviver who defended the creed of the Salaf against the sects and the philosophers, fought the Mongols, and died in prison for the truth. His students carried his knowledge to the whole nation.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HIS LIFE")) {
                        ArticleParagraph(articleMarkdown: "**Taqi ad-Deen Ahmad ibn Abd al-Haleem ibn Abd as-Salaam ibn Taymiyyah (أَحمَدُ بنُ عَبدِ الحَلِيمِ بنِ تَيمِيَّةَ)** was born on 10 Rabee‘ al-Awwal 661 AH / 22 January 1263 CE in Harran, in a family of Hanbali scholars. When the Mongols advanced, the family fled to Damascus in 667 AH, carrying their books on a cart. His father taught at the Umayyad Mosque, and when he died in 682 AH the son, at twenty-one, took his teaching post.")

                        ArticleParagraph(verbatim: "He memorised the Quran as a child and mastered hadith, fiqh, Arabic, tafseer, and the books of the sects and the philosophers, so that he could refute them from their own words. He never married, lived simply, and gave away what he had.")
                    }

                    Section(header: ArticleHeader("THE MONGOLS AND THE TRIALS")) {
                        ArticleParagraph(verbatim: "When the Mongols under Ghazan took Damascus in 699 AH, he went to the Mongol camp himself and demanded the release of the prisoners. In 702 AH, at the battle of Shaqhab, he stood among the soldiers, gave the fatwa that fighting the Mongols was obligatory although they professed Islam, since they ruled by the Yasa of Genghis Khan, and swore to the hesitant that Allah would give victory. The Mongols were defeated.")

                        ArticleParagraph(verbatim: "His refutations of grave-worship, of the philosophers, and of the theologians made him enemies among the rulers’ scholars. He was imprisoned in Cairo (705–707 AH) over his creed, in Alexandria in 709 AH, in the citadel of Damascus in 720 AH over a fatwa on divorce, and finally in 726 AH over his ruling that travelling to visit graves is not legislated. Denied ink and paper in the end, he died in the citadel on 20 Dhul-Qa‘dah 728 AH / 26 September 1328 CE. Ibn Katheer records that the crowd at his funeral was beyond counting, the largest Damascus had seen.")

                        ArticleParagraph(verbatim: "Ibn al-Qayyim heard him say in prison:")
                        ScriptureQuote(text: "“What can my enemies do to me? My paradise and my garden are in my breast; wherever I go they go with me and never leave me. My imprisonment is seclusion, my killing is martyrdom, and my expulsion from my land is travel” (Ibn al-Qayyim, al-Waabil as-Sayyib, p. 48).", arabic: "مَا يَصنَعُ أَعدَائِي بِي؟ أَنَا جَنَّتِي وَبُستَانِي فِي صَدرِي، أَينَ رُحتُ فَهِيَ مَعِي لَا تُفَارِقُنِي، إِنَّ حَبسِي خَلوَةٌ، وَقَتلِي شَهَادَةٌ، وَإِخرَاجِي مِن بَلَدِي سِيَاحَةٌ", dimmed: true)
                    }

                    Section(header: ArticleHeader("HIS WORKS")) {
                        ArticleParagraph(articleMarkdown: "**Al-Aqeedah al-Waasitiyyah (العَقِيدَة الوَاسِطِيَّة)**: the creed of the Salaf in a few pages, written in one sitting for a judge from Waasit, and examined and approved in three public debates in Damascus in 705 AH.")
                        ArticleParagraph(articleMarkdown: "**Minhaaj as-Sunnah an-Nabawiyyah (مِنهَاج السُّنَّة النَّبَوِيَّة)**: the reply to the Raafidi Ibn al-Mutahhar al-Hilli, and the most complete defence of the Companions and the caliphate ever written.")
                        ArticleParagraph(articleMarkdown: "**Daar’ Ta‘aarud al-Aql wan-Naql**: showing that sound reason never contradicts authentic revelation, and answering the kalaam theologians on their own ground.")
                        ArticleParagraph(articleMarkdown: "**Iqtidaa’ as-Siraat al-Mustaqeem**: on innovations and on imitating the disbelievers in their festivals. **Al-Jawaab as-Saheeh**: the reply to Christianity. **Ar-Radd ‘ala al-Mantiqiyyeen**: the refutation of Greek logic. **Al-Uboodiyyah**, **Al-Furqaan**, **As-Siyaasah ash-Shar‘iyyah**, and hundreds of treatises gathered in the thirty-seven volumes of **Majmoo‘ al-Fataawa (مَجمُوع الفَتَاوَى)**.")
                    }

                    Section(header: ArticleHeader("HIS STUDENTS")) {
                        ArticleParagraph(articleMarkdown: "His greatest legacy is the men he taught and who kept his company: **Ibn al-Qayyim**, who never left him from 712 AH and was imprisoned with him; **adh-Dhahabi**, the historian of Islam; **Ibn Katheer**, the mufassir and historian; **al-Mizzi**, his older companion and the master of the narrators of the six books; **Ibn Abd al-Haadi**, who wrote his biography; **Ibn Muflih**, the Hanbali jurist; and **al-Bazzaar**, who recorded his manners. Ibn al-Qayyim, adh-Dhahabi, and Ibn Katheer have their own articles here.")

                        ArticleParagraph(verbatim: "Adh-Dhahabi wrote that he had not seen anyone like him, and Ibn Hajar al-Asqalaani, who differed with him on some matters, endorsed the book defending him and wrote that his fame needs no description. Like every scholar after the Prophet (peace be upon him), he could err, and the scholars of the Sunnah accepted from him what agreed with the evidence and left what did not, which is exactly what he asked of them.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HIS LIFE")) {
                        ArticleParagraph(articleMarkdown: "**Taqi ad-Deen Ahmad ibn Abd al-Haleem ibn Taymiyyah (أَحمَدُ بنُ عَبدِ الحَلِيمِ بنِ تَيمِيَّةَ)** was born in 661 AH / 1263 CE in Harran, in a family of Hanbali scholars who fled the Mongols to Damascus, where at twenty-one he took his late father’s teaching post. He mastered hadith, fiqh, Arabic, tafseer, and the books of the sects and the philosophers, so that he could refute them from their own words.")
                    }

                    Section(header: ArticleHeader("THE MONGOLS AND THE TRIALS")) {
                        ArticleParagraph(verbatim: "When the Mongols took Damascus in 699 AH, he went to their camp himself and demanded the release of the prisoners, and at Shaqhab in 702 AH he stood among the soldiers until the Mongols were defeated.")
                        ArticleParagraph(verbatim: "His refutations of grave-worship, of the philosophers, and of the theologians made him enemies, and he was imprisoned again and again, until he died in the citadel of Damascus in 728 AH / 1328 CE. Ibn Katheer records that the crowd at his funeral was beyond counting.")
                    }

                    Section(header: ArticleHeader("HIS WORKS")) {
                        ArticleParagraph(articleMarkdown: "**Al-Aqeedah al-Waasitiyyah**, the creed of the Salaf in a few pages; **Minhaaj as-Sunnah an-Nabawiyyah**, the reply to a Raafidi book and the fullest defence of the Companions; **Daar’ Ta‘aarud al-Aql wan-Naql**, showing that sound reason never contradicts authentic revelation; and hundreds of treatises gathered in the thirty-seven volumes of **Majmoo‘ al-Fataawa (مَجمُوع الفَتَاوَى)**.")
                    }

                    Section(header: ArticleHeader("HIS STUDENTS")) {
                        ArticleParagraph(articleMarkdown: "His greatest legacy is the men he taught and who kept his company: **Ibn al-Qayyim**, **adh-Dhahabi**, **Ibn Katheer**, and **al-Mizzi**. Like every scholar after the Prophet (peace be upon him), he could err, and the scholars of the Sunnah took from him what agreed with the evidence, as he asked of them.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Ibn Taymiyyah revived the creed of the Salaf when it had been buried under kalaam and grave-worship, answered every sect from the Quran and Sunnah, and paid for it with his freedom and his life. The title Shaykh al-Islam is his by the agreement of those who came after.")
                }

                ArticleSourcesSection(article: "IbnTaymiyyahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ibn Taymiyyah")
        .englishArticle().selectableArticleList(article: "IbnTaymiyyahView")
    }
}

struct IbnQayyimView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Ibn al-Qayyim (691–751 AH) was the closest student of Ibn Taymiyyah and the scholar who turned the creed of the Salaf into books on the heart, worship, and law that Muslims still read every day.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HIS LIFE")) {
                        ArticleParagraph(articleMarkdown: "**Shams ad-Deen Muhammad ibn Abi Bakr ibn Ayyoob (مُحَمَّدُ بنُ أَبِي بَكرٍ ابنُ قَيِّمِ الجَوزِيَّةِ)** was born in 691 AH / 1292 CE in Damascus. His father was the **qayyim**, the caretaker, of the Jawziyyah school, hence the name Ibn Qayyim al-Jawziyyah. He studied every science of the religion with the scholars of Damascus and, from 712 AH, devoted himself to Ibn Taymiyyah, staying with him until the shaykh died in 728 AH.")

                        ArticleParagraph(verbatim: "He was imprisoned with his teacher in the citadel for holding that travelling to visit graves is not legislated, and was released after the shaykh’s death. He spent the prison reading the Quran and in reflection, and later said it opened to him what he could not have gained outside. He taught at the Sadriyyah school, led prayer at the Jawziyyah, performed Hajj many times, and died on 13 Rajab 751 AH / 1350 CE.")
                    }

                    Section(header: ArticleHeader("HIS WORKS")) {
                        ArticleParagraph(articleMarkdown: "**Madaarij as-Saalikeen (مَدَارِج السَّالِكِين)**: the stations of the journey to Allah, taking the language of the Sufis and correcting it by the Quran and the Sunnah; his masterpiece on the purification of the heart.")
                        ArticleParagraph(articleMarkdown: "**Zad al-Ma‘aad (زَاد المَعَاد)**: the guidance of the Prophet (peace be upon him) in every part of life, from worship to medicine, drawn from the seerah and the hadith.")
                        ArticleParagraph(articleMarkdown: "**I‘laam al-Muwaqqi‘een (إِعلَام المُوَقِّعِين)**: the principles of law and fatwa, and the danger of blind following.")
                        ArticleParagraph(articleMarkdown: "**Al-Waabil as-Sayyib** on dhikr; **Ad-Da’ wad-Dawaa’** (al-Jawaab al-Kaafi) on sin and its cure; **Ighaathat al-Lahfaan** on the snares of Shaytaan and the shirk of the grave-worshippers; **Ar-Rooh** on the soul; **Miftaah Daar as-Sa‘aadah** on knowledge; **Al-Fawaa’id**; **Haadi al-Arwaah** on Paradise; and **al-Kaafiyah ash-Shaafiyah** (an-Nooniyyah), a poem of some six thousand lines on the creed of the Salaf.")
                    }

                    Section(header: ArticleHeader("HIS WORDS")) {
                        ScriptureQuote(text: "“In the heart is a disorder that nothing gathers except turning to Allah; in it is a loneliness that nothing removes except intimacy with Him in solitude; in it is a sorrow that nothing takes away except the joy of knowing Him and the truthfulness of dealing with Him” (Madaarij as-Saalikeen 3/156).", arabic: "فِي القَلبِ شَعَثٌ لَا يَلُمُّهُ إِلَّا الإِقبَالُ عَلَى اللَّهِ، وَفِيهِ وَحشَةٌ لَا يُزِيلُهَا إِلَّا الأُنسُ بِهِ فِي خَلوَتِهِ، وَفِيهِ حُزنٌ لَا يُذهِبُهُ إِلَّا السُّرُورُ بِمَعرِفَتِهِ وَصِدقِ مُعَامَلَتِهِ", dimmed: true)

                        ArticleParagraph(articleMarkdown: "His students included **Ibn Katheer**, who said he had not seen anyone who worshipped more than him, and **Ibn Rajab al-Hanbali**, the author of Jaami‘ al-Uloom wal-Hikam, who studied with him in his last years.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HIS LIFE")) {
                        ArticleParagraph(articleMarkdown: "**Shams ad-Deen Muhammad ibn Abi Bakr (مُحَمَّدُ بنُ أَبِي بَكرٍ ابنُ قَيِّمِ الجَوزِيَّةِ)**, born in Damascus in 691 AH / 1292 CE, takes his name from his father, the **qayyim** (caretaker) of the Jawziyyah school. From 712 AH he kept the company of Ibn Taymiyyah until the shaykh died, and he died in 751 AH / 1350 CE.")
                    }

                    Section(header: ArticleHeader("HIS WORKS")) {
                        ArticleParagraph(articleMarkdown: "**Madaarij as-Saalikeen** on the heart’s journey to Allah, **Zad al-Ma‘aad** on the guidance of the Prophet (peace be upon him), **I‘laam al-Muwaqqi‘een** on law and fatwa, and **ad-Da’ wad-Dawaa’** on sin and its cure, among many others.")
                    }

                    Section(header: ArticleHeader("HIS WORDS")) {
                        ScriptureQuote(text: "“In the heart is a disorder that nothing gathers except turning to Allah; in it is a loneliness that nothing removes except intimacy with Him in solitude; in it is a sorrow that nothing takes away except the joy of knowing Him and the truthfulness of dealing with Him” (Madaarij as-Saalikeen 3/156).", arabic: "فِي القَلبِ شَعَثٌ لَا يَلُمُّهُ إِلَّا الإِقبَالُ عَلَى اللَّهِ، وَفِيهِ وَحشَةٌ لَا يُزِيلُهَا إِلَّا الأُنسُ بِهِ فِي خَلوَتِهِ، وَفِيهِ حُزنٌ لَا يُذهِبُهُ إِلَّا السُّرُورُ بِمَعرِفَتِهِ وَصِدقِ مُعَامَلَتِهِ", dimmed: true)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Ibn al-Qayyim took the knowledge of his teacher and wrote it for the heart. On dhikr, repentance, sin, love of Allah, and the way of the Prophet, his books are the most read of any scholar of the Salaf after the imams themselves.")
                }

                ArticleSourcesSection(article: "IbnQayyimView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ibn al-Qayyim")
        .englishArticle().selectableArticleList(article: "IbnQayyimView")
    }
}

struct DhahabiView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: adh-Dhahabi (673–748 AH) was the hadith master and historian who wrote the biographies of the whole nation, judging every narrator and scholar by the standard of the Salaf.")
                }

                Section(header: ArticleHeader("HIS LIFE")) {
                    ArticleParagraph(articleMarkdown: "**Shams ad-Deen Muhammad ibn Ahmad ibn Uthmaan adh-Dhahabi (مُحَمَّدُ بنُ أَحمَدَ الذَّهَبِيُّ)** was born in 673 AH / 1274 CE in Damascus to a family of Turkmen origin; his name comes from his father’s trade in gold. He began with the Quran and its readings, then gave himself to hadith, travelling to Ba‘labakk, Aleppo, Cairo, Alexandria, Makkah, and Madinah and hearing from more than a thousand teachers.")

                    ArticleParagraph(verbatim: "In Damascus he studied with Ibn Taymiyyah and al-Mizzi, and was appointed to teach hadith at several schools, including Turbat Umm as-Saalih, an-Nafeesiyyah, and at-Tankiziyyah. He lost his sight in his last years and died in 748 AH / 1348 CE.")
                }

                Section(header: ArticleHeader("HIS WORKS")) {
                    ArticleParagraph(articleMarkdown: "**Siyar A‘laam an-Nubalaa’ (سِيَر أَعلَام النُّبَلَاء)**: the biographies of the notable figures of Islam from the Companions to his own time, in some twenty-five volumes, with his own judgements on their knowledge, creed, and character.")
                    ArticleParagraph(articleMarkdown: "**Taareekh al-Islam (تَارِيخ الإِسلَام)**: the history of Islam by decade with the deaths of the notable men of each, the largest work of its kind.")
                    ArticleParagraph(articleMarkdown: "**Meezaan al-I‘tidaal**: the criticised narrators of hadith, one by one, with the verdicts of the imams. **Tadhkirat al-Huffaaz**: the generations of the hadith masters. **Al-Kaashif** on the narrators of the six books. **Talkhees al-Mustadrak**, his check on al-Haakim’s claims of authenticity.")
                    ArticleParagraph(articleMarkdown: "**Al-Uluww lil-Aliyy al-Ghaffaar (العُلُوّ)**: the sayings of the Salaf affirming that Allah is above His creation, gathered generation by generation; and **al-Kabaa’ir**, the major sins with their evidences.")
                }

                Section(header: ArticleHeader("HIS STANDARD")) {
                    ArticleParagraph(articleMarkdown: "Describing the qualities a hadith master needs, he wrote that he must be pious, intelligent, learned in grammar and language, upright, modest, and **Salafi** (Siyar A‘laam an-Nubalaa’ 13/380), and throughout his biographies he praises scholars for being upon the creed of the Salaf and records where others fell into kalaam. Of his teacher Ibn Taymiyyah he wrote that his like had not been seen, while noting his own reservations with fairness; this balance is why his verdicts are trusted by all.")

                    ArticleParagraph(verbatim: "He warned the scholars of his time against pride in knowledge, and his short treatises of advice, such as Bayaan Zaghal al-Ilm wat-Talab, show the humility the Salaf demanded of the learned.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Through adh-Dhahabi the nation knows who its scholars and narrators were, what they believed, and how far they can be trusted. He measured every one of them by the Sunnah, and he asked to be measured the same way.")
                }

                ArticleSourcesSection(article: "DhahabiView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Adh-Dhahabi")
        .englishArticle().selectableArticleList(article: "DhahabiView")
    }
}

struct IbnKathirView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Ibn Katheer (701–774 AH) wrote the most widely read tafseer of the Quran and the great history al-Bidaayah wan-Nihaayah, following the method of his teacher Ibn Taymiyyah: the Quran by the Quran, then the Sunnah, then the Salaf.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HIS LIFE")) {
                        ArticleParagraph(articleMarkdown: "**Imaad ad-Deen Ismaa‘eel ibn Umar ibn Katheer (إِسمَاعِيلُ بنُ عُمَرَ بنِ كَثِيرٍ)** was born in 701 AH / 1301 CE in a village near Busra in Syria. His father, a preacher, died when he was a small child, and his elder brother brought him to Damascus in 706 AH, where he memorised the Quran and studied with the great scholars of the city.")

                        ArticleParagraph(articleMarkdown: "He was the student of **al-Mizzi**, whose daughter he married, of **Ibn Taymiyyah**, whom he loved and defended, and of **adh-Dhahabi**. A Shaafi‘i in fiqh, he taught at the Umayyad Mosque and several schools and succeeded adh-Dhahabi at the Umm as-Saalih school. He lost his sight at the end of his life and died in Sha‘baan 774 AH / 1373 CE. By his own wish he was buried beside his teacher Ibn Taymiyyah in the Sufi cemetery of Damascus.")
                    }

                    Section(header: ArticleHeader("HIS WORKS")) {
                        ArticleParagraph(articleMarkdown: "**Tafseer al-Quran al-Azeem (تَفسِير القُرآن العَظِيم)**: the tafseer most read by Muslims today, in which he explains each verse by other verses, then by the hadith with its grade, then by the Companions and Taabi‘oon, and warns against the Israelite reports and weak narrations. He set out the method in his introduction, quoting his teacher Ibn Taymiyyah’s Muqaddimah fi Usool at-Tafseer:")
                        ScriptureQuote(text: "“If someone asks: what is the best method of tafseer? The answer is that the soundest method is that the Quran be explained by the Quran; what is left general in one place is explained in another. If that defeats you, then by the Sunnah, for it explains the Quran and clarifies it” (Ibn Taymiyyah, Muqaddimah fi Usool at-Tafseer, quoted in the introduction of Tafseer Ibn Katheer).", arabic: "فَإِن قَالَ قَائِلٌ: فَمَا أَحسَنُ طُرُقِ التَّفسِيرِ؟ فَالجَوَابُ: إِنَّ أَصَحَّ الطُّرُقِ فِي ذَلِكَ أَن يُفَسَّرَ القُرآنُ بِالقُرآنِ، فَمَا أُجمِلَ فِي مَكَانٍ فَإِنَّهُ قَد فُسِّرَ فِي مَوضِعٍ آخَرَ، فَإِن أَعيَاكَ ذَلِكَ فَعَلَيكَ بِالسُّنَّةِ فَإِنَّهَا شَارِحَةٌ لِلقُرآنِ وَمُوَضِّحَةٌ لَهُ", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**Al-Bidaayah wan-Nihaayah (البِدَايَة وَالنِّهَايَة)**, “The Beginning and the End”: the history of the world from the creation, through the prophets, the seerah in great detail, the caliphates, and the events of every year to 768 AH, ending with the signs of the Hour and the Hereafter. **Qisas al-Anbiyaa’** (the stories of the prophets) and **as-Seerah an-Nabawiyyah** are drawn from it.")

                        ArticleParagraph(articleMarkdown: "**Jaami‘ al-Masaaneed was-Sunan**, an arrangement of the hadith of the ten books by Companion; **Ikhtisaar Uloom al-Hadith**, on the science of hadith; **Tabaqaat ash-Shaafi‘iyyah**; and a commentary on Saheeh al-Bukhaari left unfinished.")
                    }

                    Section(header: ArticleHeader("HIS PLACE")) {
                        ArticleParagraph(verbatim: "Ibn Katheer carried the knowledge of Ibn Taymiyyah and adh-Dhahabi into the two books that every later generation opened first: the tafseer and the history. In his tafseer the creed of the Salaf is stated at every verse of the attributes, and in his history the Companions are defended and the sects are exposed.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HIS LIFE")) {
                        ArticleParagraph(articleMarkdown: "**Imaad ad-Deen Ismaa‘eel ibn Umar ibn Katheer (إِسمَاعِيلُ بنُ عُمَرَ بنِ كَثِيرٍ)** was born in 701 AH / 1301 CE near Busra in Syria and grew up in Damascus, the student of **al-Mizzi**, whose daughter he married, of **Ibn Taymiyyah**, and of **adh-Dhahabi**. A Shaafi‘i in fiqh, he taught at the Umayyad Mosque, died in 774 AH / 1373 CE, and was buried by his own wish beside Ibn Taymiyyah.")
                    }

                    Section(header: ArticleHeader("HIS WORKS")) {
                        ArticleParagraph(articleMarkdown: "**Tafseer al-Quran al-Azeem (تَفسِير القُرآن العَظِيم)**: the tafseer most read by Muslims today, explaining each verse by other verses, then by the hadith with its grade, then by the Companions and Taabi‘oon, and warning against the Israelite reports and weak narrations.")
                        ArticleParagraph(articleMarkdown: "**Al-Bidaayah wan-Nihaayah (البِدَايَة وَالنِّهَايَة)**: the history of the world from the creation through the prophets, the seerah and the events of every year to his own time, ending with the signs of the Hour; his **Qisas al-Anbiyaa’** and **as-Seerah an-Nabawiyyah** are drawn from it.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Ibn Katheer explained the Quran by the Quran, the Sunnah, and the Salaf, and told the history of the nation from the beginning to the end. No student of the Quran and no reader of the seerah is without his books.")
                }

                ArticleSourcesSection(article: "IbnKathirView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ibn Katheer")
        .englishArticle().selectableArticleList(article: "IbnKathirView")
    }
}

struct LaterScholarsView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: after Ibn Taymiyyah's circle, the creed and the hadith of the Salaf were carried by scholars such as Ibn Rajab, Ibn Hajar, Muhammad ibn Abd al-Wahhaab, and, in our own era, Ibn Baaz, al-Albaani, and Ibn al-Uthaymeen.")
                }

                Section(header: ArticleHeader("THE EIGHTH AND NINTH CENTURIES")) {
                    ScholarEntry(name: "Ibn Rajab al-Hanbali", arabic: "ابنُ رَجَبٍ الحَنبَلِيُّ", meta: "736–795 AH / 1335–1393 CE · Baghdaad and Damascus", description: "The student of Ibn al-Qayyim, whose Jaami‘ al-Uloom wal-Hikam explains fifty foundational hadith, whose Fath al-Baari on Saheeh al-Bukhaari was left unfinished, and whose Lataa’if al-Ma‘aarif and Dhayl Tabaqaat al-Hanaabilah are read to this day. In Fadl Ilm as-Salaf ‘ala Ilm al-Khalaf he wrote that beneficial knowledge is to master the texts of the Quran and the Sunnah and their meanings, bound by what is reported from the Companions, the Taabi‘oon, and those who followed them.")

                    ScholarEntry(name: "Ibn Hajar al-Asqalaani", arabic: "ابنُ حَجَرٍ العَسقَلَانِيُّ", meta: "773–852 AH / 1372–1449 CE · Cairo", description: "The Commander of the Believers in hadith of his age, whose Fath al-Baari on Saheeh al-Bukhaari is the greatest commentary on any hadith book, with Buloogh al-Maraam, Tahdheeb at-Tahdheeb, al-Isaabah on the Companions, and Nukhbat al-Fikar. A Shaafi‘i who leaned toward the Ash‘ari school in some matters, he is honoured by all of Ahl as-Sunnah for his service to the Sunnah, and he endorsed the defence of Ibn Taymiyyah.")
                }

                Section(header: ArticleHeader("THE REVIVAL IN NAJD")) {
                    ScholarEntry(name: "Muhammad ibn Abd al-Wahhaab", arabic: "مُحَمَّدُ بنُ عَبدِ الوَهَّابِ", meta: "1115–1206 AH / 1703–1792 CE · Najd, Arabia", description: "A Hanbali scholar who found the people of Arabia calling upon the dead at graves and trees and returned them to tawheed with the Quran and Sunnah, in Kitaab at-Tawheed, al-Usool ath-Thalaathah, Kashf ash-Shubuhaat, and the Nawaaqid al-Islam. He wrote that he followed Imam Ahmad in fiqh and called to nothing but what the four imams called to. His call, supported by Muhammad ibn Sa‘ood, made the creed of the Salaf the creed of a state and spread its books through the nation.")

                    ScholarEntry(name: "Muhammad ibn Ali ash-Shawkaani", arabic: "الشَّوكَانِي", meta: "1173–1250 AH / 1759–1834 CE · San‘a, Yemen", description: "The judge of Yemen who left the Zaydi school for the Sunnah, and wrote Nayl al-Awtaar on the hadith of rulings, Fath al-Qadeer in tafseer, and Irshaad al-Fuhool on the principles of law.")
                }

                Section(header: ArticleHeader("THE SCHOLARS OF OUR ERA")) {
                    ScholarEntry(name: "Abd al-Azeez ibn Baaz", arabic: "عَبدُ العَزِيزِ بنُ بَازٍ", meta: "1330–1420 AH / 1912–1999 CE · Riyadh", description: "Blind from the age of twenty, the Grand Mufti of Saudi Arabia, known for his gentleness, his charity, and his fataawa, which were spread across the world, and for his patience in answering every questioner.")

                    ScholarEntry(name: "Muhammad Naasir ad-Deen al-Albaani", arabic: "مُحَمَّد نَاصِر الدِّين الأَلبَانِي", meta: "1332–1420 AH / 1914–1999 CE · Damascus and Amman", description: "The hadith master of the age, a watchmaker who taught himself in the Zaahiriyyah library of Damascus and then graded the hadith of the Sunan and hundreds of other works: as-Silsilah as-Saheehah, as-Silsilah ad-Da‘eefah, Irwaa’ al-Ghaleel, and Sifaat Salaat an-Nabi. The grades “saheeh by al-Albaani” cited in these pages are his.")

                    ScholarEntry(name: "Muhammad ibn Saalih al-Uthaymeen", arabic: "مُحَمَّدُ بنُ صَالِحٍ العُثَيمِينَ", meta: "1347–1421 AH / 1929–2001 CE · Unayzah", description: "The teacher of the Qaasim, whose explanations of al-Waasitiyyah, Kitaab at-Tawheed, Riyaad as-Saaliheen, and Buloogh al-Maraam, and whose ash-Sharh al-Mumti‘ in fiqh, are the textbooks of students of knowledge today, taught with clarity and with an ease of manner remembered by all who sat with him.")

                    ArticleParagraph(articleMarkdown: "Beside these three stood **Muqbil ibn Haadi al-Waadi‘i** in Yemen, **Muhammad Amaan al-Jaami** in Madinah and **Ahmad an-Najmi** in Jaazaan, and their teachers and students. They differed at times in fiqh and in judgement, as scholars do, and were one in creed: the creed of the Salaf.")
                }

                Section(header: ArticleHeader("HOW TO TAKE FROM THE SCHOLARS")) {
                    ArticleParagraph(verbatim: "A scholar is followed for his evidence, not for himself. A saying famous from Imam Maalik, and reported with an authentic chain from the Taabi‘i Mujaahid before him, is that everyone’s words may be accepted or rejected except those of the Prophet (peace be upon him), and every imam said the same. So the Muslim learns from the scholars of the Sunnah with respect, asks them what he does not know, and keeps the Quran and Sunnah as the final word for all of them:")
                    ScriptureQuote(quran: "9:122")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Are the scholars infallible?**")
                        ArticleParagraph(verbatim: "No. Only the Prophet (peace be upon him) is protected from error in what he conveys from Allah; every scholar after him is right at times and wrong at times, and is followed only as far as he follows the evidence. Allah made the Quran and the Sunnah, not any man, the court of appeal:")
                        ScriptureQuote(quran: "4:59", words: 10...23)
                        ArticleParagraph(verbatim: "The Companions said this first. When the caliph Uthmaan forbade combining Umrah with Hajj, Ali (may Allah be pleased with them both) entered ihraam for the two together and said:")
                        ScriptureQuote(hadith: "bukhari:1563", cite: "Saheeh al-Bukhaari 1563", arabic: 43...53, english: 44...58)
                        ArticleParagraph(verbatim: "The imams said the same of themselves. The saying given above, that everyone’s words may be accepted or rejected except the Prophet’s, is famous from Maalik without a known chain; it is authentic from Mujaahid (al-Bukhaari, Raf‘ al-Yadayn) and from al-Hakam ibn Utaybah (Ibn Abd al-Barr, Jaami‘ Bayaan al-Ilm wa Fadlih 2/925). Ash-Shaafi‘i (may Allah have mercy on him) said:")
                        ScriptureQuote(text: "“The Muslims are agreed that whoever has a Sunnah of the Messenger of Allah (peace be upon him) made clear to him is not permitted to leave it for the saying of anyone” (Ibn al-Qayyim, I‘laam al-Muwaqqi‘een).", arabic: "أَجمَعَ المُسلِمُونَ عَلَى أَنَّ مَنِ استَبَانَت لَهُ سُنَّةٌ عَن رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ لَم يَحِلَّ لَهُ أَن يَدَعَهَا لِقَولِ أَحَدٍ", dimmed: true)
                        ArticleParagraph(verbatim: "And Ahmad (may Allah have mercy on him) said:")
                        ScriptureQuote(text: "“Do not imitate me, nor Maalik, nor ash-Shaafi‘i, nor al-Awzaa‘i, nor ath-Thawri; take from where they took” (Ibn al-Qayyim, I‘laam al-Muwaqqi‘een).", arabic: "لَا تُقَلِّدنِي وَلَا تُقَلِّد مَالِكًا وَلَا الشَّافِعِيَّ وَلَا الأَوزَاعِيَّ وَلَا الثَّورِيَّ، وَخُذ مِن حَيثُ أَخَذُوا", dimmed: true)
                        ArticleParagraph(verbatim: "Ibn Taymiyyah devoted a treatise, Raf‘ al-Malaam ‘an al-A’immat al-A‘laam, to explaining why the imams sometimes ruled against a hadith: it had not reached them, or they did not judge it authentic, or they understood it differently, or they held it abrogated. Their error is excused and rewarded, but it is not followed once the evidence is known.")

                        ArticleParagraph(articleMarkdown: "**Whom do I follow when the scholars differ?**")
                        ArticleParagraph(verbatim: "The evidence, and the scholar who shows it to you. Allah commanded that matters be returned to those able to draw conclusions from the texts:")
                        ScriptureQuote(quran: "4:83", words: 9...20)
                        ArticleParagraph(verbatim: "A layman is not asked to weigh the proofs himself; he asks the most knowledgeable and God-fearing scholar he can reach, and when he can understand the evidence he follows what it supports, even against his own teacher. Difference among scholars is not a licence to pick the easiest opinion: Sulaymaan at-Taymi (may Allah have mercy on him) said that if you take the concession of every scholar, all evil gathers in you (Ibn Abd al-Barr, Jaami‘ Bayaan al-Ilm wa Fadlih). And the scholar who errs after striving is not sinning. The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:7352", cite: "Saheeh al-Bukhaari 7352", arabic: 46...60, english: 7...71)
                        ArticleParagraph(verbatim: "So difference among the scholars is not a reason to abandon all of them, nor to follow desire under the name of choice. Ask the best you can reach, follow the proof when it is clear, and do not make the differences of the scholars a religion of your own.")

                        ArticleParagraph(articleMarkdown: "**Was Ibn Taymiyyah an anthropomorphist (mujassim)?**")
                        ArticleParagraph(verbatim: "No. The charge was made by his opponents in his lifetime and answered in his lifetime. His own creed, al-Aqeedah al-Waasitiyyah, lays down at its beginning:")
                        ScriptureQuote(text: "“Part of faith in Allah is faith in what He has described Himself with in His Book and in what His Messenger Muhammad (peace be upon him) has described Him with, without distortion (tahreef) or denial (ta‘teel), and without asking how (takyeef) or likening (tamtheel)” (Ibn Taymiyyah, al-Aqeedah al-Waasitiyyah).", arabic: "وَمِنَ الإِيمَانِ بِاللَّهِ: الإِيمَانُ بِمَا وَصَفَ بِهِ نَفسَهُ فِي كِتَابِهِ، وَبِمَا وَصَفَهُ بِهِ رَسُولُهُ مُحَمَّدٌ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، مِن غَيرِ تَحرِيفٍ وَلَا تَعطِيلٍ، وَمِن غَيرِ تَكيِيفٍ وَلَا تَمثِيلٍ", dimmed: true)
                        ArticleParagraph(verbatim: "He then cites the verse that is the foundation of the whole creed:")
                        ScriptureQuote(quran: "42:11", words: 13...18)
                        ArticleParagraph(verbatim: "A mujassim (مُجَسِّم), from jism (جِسم), “body,” is one who likens Allah to the bodies of His creation. A man who affirms the attributes exactly as Allah affirmed them and denies any likeness exactly as Allah denied it is not a mujassim; he is on the way of the Salaf. In 705 AH al-Waasitiyyah was examined in three public sessions in Damascus before the judges and scholars of the city, and nothing against the Sunnah was found in it; Ibn Abd al-Haadi records the sessions in al-Uqood ad-Durriyyah and Ibn Katheer in al-Bidaayah wan-Nihaayah. When a later writer claimed that whoever called him Shaykh al-Islam was a disbeliever, Ibn Naasir ad-Deen ad-Dimashqi replied with ar-Radd al-Waafir, gathering the words of more than eighty scholars of every school who had given him that title, and Ibn Hajar wrote an endorsement of the book. Adh-Dhahabi, who knew him for years, wrote that he had not seen his like (see the page “Ibn Taymiyyah”).")

                        ArticleParagraph(articleMarkdown: "**Did Ibn Taymiyyah hate Ali or the Ahlul Bayt?**")
                        ArticleParagraph(verbatim: "No. Minhaaj as-Sunnah is a reply to a Raafidi book, and it refutes the exaggeration about Ali, not Ali. In it Ibn Taymiyyah affirms Ali’s virtues, his caliphate as the fourth of the rightly guided, and that he was nearer to the truth than those who fought him, citing the Prophet’s words about Ammaar, who was killed in Ali’s army at Siffeen:")
                        ScriptureQuote(hadith: "muslim:2916c", cite: "Saheeh Muslim 2916", arabic: 30...33, english: 0...6)
                        ArticleParagraph(verbatim: "In al-Waasitiyyah he writes that Ahl as-Sunnah:")
                        ScriptureQuote(text: "“love the People of the House of the Messenger of Allah (peace be upon him), take them as allies, and keep the will of the Messenger of Allah (peace be upon him) concerning them” (Ibn Taymiyyah, al-Aqeedah al-Waasitiyyah).", arabic: "وَيُحِبُّونَ أَهلَ بَيتِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ وَيَتَوَلَّونَهُم، وَيَحفَظُونَ فِيهِم وَصِيَّةَ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ", dimmed: true)
                        ArticleParagraph(verbatim: "This is the creed of every Sunni, for Ali (may Allah be pleased with him) reported the Prophet’s promise:")
                        ScriptureQuote(hadith: "muslim:#146", cite: "Saheeh Muslim 78", arabic: 40...57, english: 13...44)
                        ArticleParagraph(verbatim: "Imam Ahmad said that whoever does not affirm the caliphate of Ali is more astray than his family’s donkey (al-Khallaal, as-Sunnah; Ibn Abi Ya‘la, Tabaqaat al-Hanaabilah), and Ibn Taymiyyah, a Hanbali, followed him in this. He was called an enemy of Ali by those whose claims against the other Companions he refused to accept; refusing to curse the Companions is a mark of the Sunnah, not of hatred.")

                        ArticleParagraph(articleMarkdown: "**Why do Salafis respect an-Nawawi and Ibn Hajar although they interpreted some attributes?**")
                        ArticleParagraph(verbatim: "Because justice is a command, and a man is judged by the whole of his work. An-Nawawi and Ibn Hajar (may Allah have mercy on them) gave the nation Sharh Saheeh Muslim, Riyaad as-Saaliheen, the Forty Hadith, Fath al-Baari, and Buloogh al-Maraam; their service to the Sunnah is beyond calculation. In some matters of the divine attributes they followed the interpretation (ta’weel) of the Ash‘ari school that dominated their time, and in this they erred; the Salafi does not follow them in it, and says so openly. But he does not throw away the imam because of a mistake. Allah says:")
                        ScriptureQuote(quran: "5:8", words: 8...18)
                        ArticleParagraph(verbatim: "Adh-Dhahabi wrote in Siyar A‘laam an-Nubalaa’, in the biography of the imam Muhammad ibn Nasr al-Marwazi:")
                        ScriptureQuote(text: "“If every time an imam erred in his ijtihaad in a single matter, with an error that is forgiven him, we rose against him, called him an innovator, and abandoned him, then neither Ibn Nasr nor Ibn Mandah nor those greater than them would be safe with us” (adh-Dhahabi, Siyar A‘laam an-Nubalaa’ 14/40).", arabic: "وَلَو أَنَّا كُلَّمَا أَخطَأَ إِمَامٌ فِي اجتِهَادِهِ فِي آحَادِ المَسَائِلِ خَطَأً مَغفُورًا لَهُ، قُمنَا عَلَيهِ وَبَدَّعنَاهُ وَهَجَرنَاهُ، لَمَا سَلِمَ مَعَنَا لَا ابنُ نَصرٍ وَلَا ابنُ مَندَه وَلَا مَن هُوَ أَكبَرُ مِنهُمَا", dimmed: true)
                        ArticleParagraph(verbatim: "Ibn Baaz and Ibn al-Uthaymeen (may Allah have mercy on them), when asked about the two, answered in the same spirit: they are imams of Ahl as-Sunnah whose good is immense, who erred in the interpretation of some attributes, and whose error is not followed. The rule is that of Ahl as-Sunnah in every age: take the truth from whoever brings it, leave the error of whoever falls into it, and ask Allah’s mercy for the scholars.")

                        ArticleParagraph(articleMarkdown: "**How do I know a scholar is trustworthy?**")
                        ArticleParagraph(verbatim: "By the same test the Salaf applied to narrators. Muhammad ibn Seereen (may Allah have mercy on him) said:")
                        ScriptureQuote(text: "“This knowledge is religion, so look from whom you take your religion” (Muqaddimah of Saheeh Muslim).", arabic: "إِنَّ هَذَا العِلمَ دِينٌ، فَانظُرُوا عَمَّن تَأخُذُونَ دِينَكُم", dimmed: true)
                        ArticleParagraph(verbatim: "Look for four things. Sound creed: he affirms the names and attributes as they came, honours the Companions, and does not call to any sect. Knowledge of the texts: he speaks from the Quran and the Sunnah with their evidences, not from stories and opinions. A chain of teachers: he sat before known scholars of the Sunnah and they know him, for knowledge is transmission, and the Prophet (peace be upon him) warned that when the scholars are gone people take ignorant heads who give verdicts without knowledge (Saheeh al-Bukhaari 100). And practice: his fear of Allah shows in his conduct, for Allah says that the knowledgeable are the ones who fear Him (Quran 35:28). A man with a title, a following, or eloquence but without these is not a scholar, however many listen to him.")
                        ScriptureQuote(hadith: "bukhari:100", cite: "Saheeh al-Bukhaari 100, Saheeh Muslim 2673", arabic: 32...60, english: 6...71)
                        ScriptureQuote(quran: "35:28", words: 7...12)

                        ArticleParagraph(articleMarkdown: "**Is taking from the scholars blind imitation (taqleed)?**")
                        ArticleParagraph(verbatim: "No, when it is done as Allah commanded. Taqleed (تَقلِيد) is to accept a ruling without knowing its evidence, and the one who does not know is ordered to do exactly that: ask the one who knows:")
                        ScriptureQuote(quran: "16:43", words: 8...14)
                        ArticleParagraph(verbatim: "The command is repeated in Surat al-Anbiya (Quran 21:7).")
                        ScriptureQuote(quran: "21:7", words: 7...13)
                        ArticleParagraph(verbatim: "Ibn Abd al-Barr writes in Jaami‘ Bayaan al-Ilm that the scholars do not differ that the common people must follow their scholars in what befalls them, since they cannot see where the proof lies, and Ibn al-Qayyim discusses in I‘laam al-Muwaqqi‘een the saying that the layman’s madhhab is the madhhab of his mufti. Blameworthy taqleed is something else: clinging to a man’s opinion after the proof against it is known, or taking a scholar as the measure of truth instead of the texts. Allah condemned the People of the Book for exactly this:")
                        ScriptureQuote(quran: "9:31", words: 0...6)
                        ArticleParagraph(verbatim: "Ibn Katheer explains in his tafseer that they did not worship them, but obeyed them when they made the unlawful lawful and the lawful unlawful. So the Salafi asks the scholars, accepts their answer, and asks for the evidence when he can understand it, and the scholars of the Sunnah are the first to give it.")

                        ArticleParagraph(articleMarkdown: "**Were the four imams upon the creed of the Salaf?**")
                        ArticleParagraph(verbatim: "Yes, and their own words prove it. The creed of Abu Haneefah is preserved in the creed of at-Tahaawi, who wrote it as the belief of Abu Haneefah and his two companions Abu Yoosuf and Muhammad ibn al-Hasan, and in al-Fiqh al-Akbar, which the Hanafis attribute to him by a weak chain. Maalik was asked how Allah rose over the Throne and replied:")
                        ScriptureQuote(text: "“The rising is not unknown, the how of it is beyond reason, belief in it is obligatory, and asking about it is innovation” (al-Laalakaa’i, Sharh Usool I‘tiqaad Ahl as-Sunnah 664; al-Bayhaqi, al-Asmaa’ was-Sifaat 867).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)
                        ArticleParagraph(verbatim: "Ash-Shaafi‘i is reported to have said:")
                        ScriptureQuote(text: "“I believe in Allah and in what came from Allah as Allah intended it, and I believe in the Messenger of Allah and in what came from the Messenger of Allah as the Messenger of Allah intended it” (Ibn Qudaamah, Lum‘at al-I‘tiqaad, without a chain; Ibn Taymiyyah: “what ash-Shaafi‘i said is true,” Majmoo‘ al-Fataawa 6/354).", arabic: "آمَنتُ بِاللَّهِ وَبِمَا جَاءَ عَنِ اللَّهِ عَلَى مُرَادِ اللَّهِ، وَآمَنتُ بِرَسُولِ اللَّهِ وَبِمَا جَاءَ عَن رَسُولِ اللَّهِ عَلَى مُرَادِ رَسُولِ اللَّهِ", dimmed: true)
                        ArticleParagraph(verbatim: "And Ahmad’s Usool as-Sunnah, quoted on the page “Madhaahib of Aqeedah,” is the creed of the Salaf set down line by line. All four affirmed the attributes without asking how, held that the Quran is the speech of Allah and not created, and honoured all the Companions. Maalik, ash-Shaafi‘i, and Ahmad held that faith is speech and action, increasing and decreasing; Abu Haneefah expressed the matter differently, and Ibn Taymiyyah explains in Kitaab al-Eemaan that much of that dispute was one of wording, since he too held that the disobedient believer is under the threat of punishment. The kalaam schools that later attached themselves to the names of the imams came after them and differed from them.")

                        ArticleParagraph(articleMarkdown: "**Which books should a beginner start with?**")
                        ArticleParagraph(verbatim: "Begin with creed, then the Sunnah, then rulings, and take each with a teacher or a reliable explanation. In creed: al-Usool ath-Thalaathah (the three fundamentals: who is your Lord, what is your religion, who is your Prophet) and Kitaab at-Tawheed of Muhammad ibn Abd al-Wahhaab, then al-Aqeedah al-Waasitiyyah of Ibn Taymiyyah, with the explanations of Ibn al-Uthaymeen. In hadith: the Forty of an-Nawawi, then Riyaad as-Saaliheen, then Umdat al-Ahkaam and Buloogh al-Maraam for the hadith of rulings. In tafseer: Tafseer Ibn Katheer, or the short tafseer of as-Sa‘di. Read a little every day, memorise what you can, act on what you learn, and make the Prophet’s supplication your own:")
                        ScriptureQuote(quran: "20:114", words: 13...16)

                        ArticleParagraph(articleMarkdown: "**Why were Ahmad and Ibn Taymiyyah imprisoned if they were upon the truth?**")
                        ArticleParagraph(verbatim: "Because trial is the lot of those who hold to the truth, not a sign against it. Allah says:")
                        ScriptureQuote(quran: "29:2-3")
                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) was asked which people are tried most severely and said:")
                        ScriptureQuote(hadith: "tirmidhi:2398", cite: "Jaami‘ at-Tirmidhi 2398; graded hasan saheeh by al-Albaani", arabic: 28...42, english: 14...46)
                        ArticleParagraph(verbatim: "Ahmad was imprisoned and flogged in the Mihnah, the inquisition of 218 to 234 AH in which the caliphs al-Ma’moon, al-Mu‘tasim, and al-Waathiq forced the Mu‘tazili doctrine that the Quran is created upon the scholars; he refused, and when al-Mutawakkil ended the trial the nation called him the Imam of Ahl as-Sunnah. Ibn Taymiyyah’s al-Waasitiyyah was cleared by the councils of Damascus in 705 AH, yet his opponents had him summoned to Cairo, where he was imprisoned over his creed from 705 to 707 AH; he was imprisoned in Damascus in 720 AH over his ruling that a triple divorce pronounced at once counts as one, and finally in 726 AH over his ruling that setting out on a journey only to visit graves is not legislated; he died in the citadel in 728 AH. Before them Abu Haneefah was imprisoned for refusing the judgeship and Maalik was flogged, and the Prophet (peace be upon him) himself was driven from Makkah. Allah says that the believers before us were shaken until the Messenger and those with him said, “When is the help of Allah?” (Quran 2:214).")
                        ScriptureQuote(quran: "2:214", words: 15...24)
                        ArticleParagraph(verbatim: "Prison did not harm the truth they carried; it is the books of their opponents that are forgotten.")

                        ArticleParagraph(articleMarkdown: "**Is knowledge only for scholars?**")
                        ArticleParagraph(verbatim: "No. Every Muslim must learn what his worship requires: the meaning of the testimony of faith, how to purify and pray, what to fast and give, and the rulings of whatever trade or situation he is in; this is obligatory on each individual, as Ibn Abd al-Barr explains in Jaami‘ Bayaan al-Ilm. Beyond that, becoming a scholar is a communal obligation which some must fulfil for all, as the verse of Surat at-Tawbah above lays down. And every Muslim carries what he has learned to others. The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:3461", cite: "Saheeh al-Bukhaari 3461", arabic: 29...32, english: 4...16)
                        ArticleParagraph(verbatim: "Every step on the road is rewarded:")
                        ScriptureQuote(hadith: "muslim:2699a", cite: "Saheeh Muslim 2699", arabic: 88...100, english: 90...109)
                        ArticleParagraph(verbatim: "The Companions were farmers, traders, and soldiers, and they were the most knowledgeable of the nation, because they learned a little and acted on it before they learned more. Knowledge is for everyone who seeks it; the rank of scholar is for those who give their lives to it.")

                        ArticleParagraph(articleMarkdown: "**Who are the scholars of our time we can rely on?**")
                        ArticleParagraph(verbatim: "This page names three whose knowledge, creed, and character the scholars of the Sunnah have agreed upon and who have gone to their Lord: Ibn Baaz, al-Albaani, and Ibn al-Uthaymeen (may Allah have mercy on them), with those named beside them. Their books, fataawa, and recorded lessons remain, and they are the safest starting point for a student today, together with the scholars of the Sunnah who learned from them. A saying reported from Abdullah ibn Mas‘ood and from Abdullah ibn Umar (may Allah be pleased with them) gives the principle:")
                        ScriptureQuote(text: "“Whoever of you would follow an example, let him follow the example of the Companions of the Messenger of Allah, for they were the most righteous of this nation in heart, the deepest in knowledge, and the least in affectation” (Ibn Abd al-Barr, Jaami‘ Bayaan al-Ilm wa Fadlih 1810, from Ibn Mas‘ood through Qataadah, who did not meet him; Abu Nu‘aym, Hilyat al-Awliyaa’ 1/305, from Ibn Umar).", arabic: "مَن كَانَ مِنكُم مُتَأَسِّيًا فَليَتَأَسَّ بِأَصحَابِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، فَإِنَّهُم كَانُوا أَبَرَّ هَذِهِ الأُمَّةِ قُلُوبًا، وَأَعمَقَهَا عِلمًا، وَأَقَلَّهَا تَكَلُّفًا", dimmed: true)
                        ArticleParagraph(verbatim: "For the living, apply the test given above: sound creed, knowledge of the texts, a known chain of teachers, and practice, and ask the people of the Reminder when you do not know, as Allah commanded in the verse of Surat an-Nahl quoted above. The names change from age to age; the test does not.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Are the scholars infallible?**")
                        ArticleParagraph(verbatim: "No. Only the Prophet (peace be upon him) is protected from error in what he conveys from Allah; every scholar after him is right at times and wrong at times, and is followed only as far as he follows the evidence. Allah made the Quran and the Sunnah, not any man, the court of appeal:")
                        ScriptureQuote(quran: "4:59", words: 10...23)

                        ArticleParagraph(articleMarkdown: "**How do I know a scholar is trustworthy?**")
                        ArticleParagraph(verbatim: "By the same test the Salaf applied to narrators. Muhammad ibn Seereen (may Allah have mercy on him) said:")
                        ScriptureQuote(text: "“This knowledge is religion, so look from whom you take your religion” (Muqaddimah of Saheeh Muslim).", arabic: "إِنَّ هَذَا العِلمَ دِينٌ، فَانظُرُوا عَمَّن تَأخُذُونَ دِينَكُم", dimmed: true)
                        ArticleParagraph(verbatim: "Look for four things: sound creed, knowledge of the texts, a chain of known teachers of the Sunnah, and practice in which his fear of Allah shows. A man with a title, a following, or eloquence but without these is not a scholar, however many listen to him.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The chain never broke. From Ibn Rajab and Ibn Hajar to the revival in Najd and the scholars of the last century, the creed of the Salaf and the science of hadith were handed down teacher to student, and the same is asked of the student today: take the evidence, honour the scholars, and follow the Prophet.")
                }

                ArticleSourcesSection(article: "LaterScholarsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Later Scholars")
        .englishArticle().selectableArticleList(article: "LaterScholarsView")
    }
}
