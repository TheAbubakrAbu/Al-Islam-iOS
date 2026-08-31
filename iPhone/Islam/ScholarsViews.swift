import SwiftUI

/// The "Scholars of Ahl as-Sunnah" list section and its articles: the learned Companions, the Salaf and
/// the imams, at-Tabari, Ibn Taymiyyah and his students (Ibn al-Qayyim, adh-Dhahabi, Ibn Kathir), and the
/// later scholars of the Sunnah.
struct ScholarsSectionView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("SCHOLARS OF AHL AS-SUNNAH")) {
            row("The Scholars of the Sahabah", destination: SahabahScholarsView())
            row("The Salaf and the Imams", destination: SalafScholarsView())
            row("Ibn Jarir at-Tabari", destination: TabariView())
            row("Shaykh al-Islam Ibn Taymiyyah", destination: IbnTaymiyyahView())
            row("Ibn al-Qayyim", destination: IbnQayyimView())
            row("Adh-Dhahabi", destination: DhahabiView())
            row("Ibn Kathir", destination: IbnKathirView())
            row("Later Scholars of the Sunnah", destination: LaterScholarsView())
        }
    }

    private func row<D: View>(_ title: String, destination: @autoclosure @escaping () -> D) -> some View {
        NavigationLink(destination: LazyDestination { destination() }) {
            Text(title)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

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
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the first scholars of Islam were the Companions, taught directly by the Prophet. Every chain of knowledge in the religion passes through them.")
                        .font(.body)
                }

                Section(header: Text("WHY SCHOLARS MATTER")) {
                    Text("Allah (Glorified and Exalted be He) raised the people of knowledge above others and made asking them an obligation on the one who does not know:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah will raise those who have believed among you and those who were given knowledge, by degrees” (Quran 58:11).", arabic: "يَرۡفَعِ ٱللَّهُ ٱلَّذِينَ ءَامَنُواْ مِنكُمۡ وَٱلَّذِينَ أُوتُواْ ٱلۡعِلۡمَ دَرَجَٰتٖۚ")

                    ScriptureQuote(text: "“Say, ‘Are those who know equal to those who do not know?’ Only they will remember [who are] people of understanding” (Quran 39:9).", arabic: "قُلۡ هَلۡ يَسۡتَوِي ٱلَّذِينَ يَعۡلَمُونَ وَٱلَّذِينَ لَا يَعۡلَمُونَۗ إِنَّمَا يَتَذَكَّرُ أُوْلُواْ ٱلۡأَلۡبَٰبِ")

                    ScriptureQuote(text: "“Only those fear Allah, from among His servants, who have knowledge” (Quran 35:28).", arabic: "إِنَّمَا يَخۡشَى ٱللَّهَ مِنۡ عِبَادِهِ ٱلۡعُلَمَٰٓؤُاْۗ")

                    ScriptureQuote(text: "“So ask the people of the message if you do not know” (Quran 16:43).", arabic: "فَسۡـَٔلُوٓاْ أَهۡلَ ٱلذِّكۡرِ إِن كُنتُمۡ لَا تَعۡلَمُونَ")

                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whomever Allah wishes good for, He gives him understanding of the religion” (Sahih al-Bukhari 71, Sahih Muslim 1037).", arabic: "مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُفَقِّهْهُ فِي الدِّينِ", dimmed: true)

                    ScriptureQuote(text: "“Allah does not take away knowledge by snatching it from the people, but He takes it away by taking the scholars, until when no scholar remains the people take ignorant men as leaders, who are asked and give verdicts without knowledge, so they go astray and lead others astray” (Sahih al-Bukhari 100).", arabic: "إِنَّ اللَّهَ لاَ يَقْبِضُ الْعِلْمَ انْتِزَاعًا، يَنْتَزِعُهُ مِنَ الْعِبَادِ، وَلَكِنْ يَقْبِضُ الْعِلْمَ بِقَبْضِ الْعُلَمَاءِ، حَتَّى إِذَا لَمْ يُبْقِ عَالِمًا، اتَّخَذَ النَّاسُ رُءُوسًا جُهَّالاً فَسُئِلُوا، فَأَفْتَوْا بِغَيْرِ عِلْمٍ، فَضَلُّوا وَأَضَلُّوا", dimmed: true)

                    Text("Knowledge in Islam is not opinion; it is transmission. A scholar is one who carries the Quran and the Sunnah with understanding, from a teacher who carried it from his, back to the Companions and the Prophet (peace be upon him). This is why the scholars of Ahl as-Sunnah are known by their chains and their teachers.")
                        .font(.body)
                }

                Section(header: Text("THE FIRST SCHOLARS")) {
                    Text("The Companions (may Allah be pleased with them) learned the Quran as it came down and the Sunnah from the one who lived it. Among them some were singled out for knowledge. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The most merciful of my nation to my nation is Abu Bakr, the most severe of them in the command of Allah is Umar, the most truly modest of them is Uthman ibn Affan, the most knowledgeable of them in the lawful and the unlawful is Mu‘adh ibn Jabal, the most knowledgeable of them in inheritance is Zayd ibn Thabit, the best reciter among them is Ubayy ibn Ka‘b, and every nation has a trustworthy one, and the trustworthy one of this nation is Abu Ubaydah ibn al-Jarrah” (Sunan al-Tirmidhi 3790; graded sahih by al-Albani).", arabic: "أَرْحَمُ أُمَّتِي بِأُمَّتِي أَبُو بَكْرٍ وَأَشَدُّهُمْ فِي أَمْرِ اللَّهِ عُمَرُ وَأَصْدَقُهُمْ حَيَاءً عُثْمَانُ وَأَعْلَمُهُمْ بِالْحَلاَلِ وَالْحَرَامِ مُعَاذُ بْنُ جَبَلٍ وَأَفْرَضُهُمْ زَيْدُ بْنُ ثَابِتٍ وَأَقْرَؤُهُمْ أُبَىُّ بْنُ كَعْبٍ وَلِكُلِّ أُمَّةٍ أَمِينٌ وَأَمِينُ هَذِهِ الأُمَّةِ أَبُو عُبَيْدَةَ بْنُ الْجَرَّاحِ", dimmed: true)

                    ScriptureQuote(text: "“Take the Quran from four: Abdullah ibn Mas‘ud, Salim, Mu‘adh, and Ubayy ibn Ka‘b” (Sahih al-Bukhari 4999).", arabic: "خُذُوا الْقُرْآنَ مِنْ أَرْبَعَةٍ مِنْ عَبْدِ اللَّهِ بْنِ مَسْعُودٍ وَسَالِمٍ وَمُعَاذٍ وَأُبَىِّ بْنِ كَعْبٍ", dimmed: true)
                }

                Section(header: Text("THE RIGHTLY GUIDED CALIPHS")) {
                    ScholarEntry(name: "Abu Bakr as-Siddiq", arabic: "أَبُو بَكر الصِّدِّيق", meta: "d. 13 AH / 634 CE · Madinah", description: "The most knowledgeable of the Companions. When the Prophet (peace be upon him) hinted from the pulpit that a servant had been given the choice to meet his Lord, Abu Bakr alone understood and wept, and the narrator says, “Abu Bakr was the most knowledgeable of us“ (Sahih al-Bukhari 3654). He led the prayer in the Prophet’s final illness by his command (Sahih al-Bukhari 664), fought the apostates, and ordered the first collection of the Quran.")

                    ScholarEntry(name: "Umar ibn al-Khattab", arabic: "عُمَر بن الخَطَّاب", meta: "d. 23 AH / 644 CE · Madinah", description: "Of whom the Prophet (peace be upon him) said, “If there were to be a muhaddath (one inspired with the truth) in my nation, it would be Umar“ (Sahih al-Bukhari 3689). The Quran came down agreeing with his view more than once. He organised the Hijri calendar, the Tarawih congregation, the courts, and the provinces, and sent scholars such as Ibn Mas‘ud to teach the new cities.")

                    ScholarEntry(name: "Uthman ibn Affan", arabic: "عُثمَان بن عَفَّان", meta: "d. 35 AH / 656 CE · Madinah", description: "Married to two daughters of the Prophet (peace be upon him), one after the other, hence “Dhun-Nurayn.“ He gathered the nation upon one written Quran, sending official copies to the great cities, the mushaf every Muslim reads today.")

                    ScholarEntry(name: "Ali ibn Abi Talib", arabic: "عَلِي بن أَبِي طَالِب", meta: "d. 40 AH / 661 CE · Kufah", description: "Raised in the Prophet’s house and among the first to believe. The Prophet (peace be upon him) gave him the banner at Khaybar, saying Allah would grant victory at his hands (Sahih al-Bukhari 3701). A judge of the highest rank, the teacher of the scholars of Kufah, and the narrator of the hadith on the Khawarij, whom he fought.")
                }

                Section(header: Text("THE SCHOLARS AMONG THE COMPANIONS")) {
                    ScholarEntry(name: "Abdullah ibn Mas‘ud", arabic: "عَبد الله بن مَسعُود", meta: "d. 32 AH / 653 CE · Madinah, taught in Kufah", description: "The sixth person to accept Islam and the first to recite the Quran aloud in Makkah. The Prophet (peace be upon him) named him first among those to take the Quran from. Sent by Umar to Kufah, his students (Alqamah, al-Aswad, Masruq, then Ibrahim al-Nakha‘i, then Hammad, then Abu Hanifah) became the Iraqi school of fiqh.")

                    ScholarEntry(name: "Abdullah ibn Abbas", arabic: "عَبد الله بن عَبَّاس", meta: "d. 68 AH / 687 CE · Ta’if", description: "The Prophet’s cousin, for whom he prayed, “O Allah, teach him the Book“ (Sahih al-Bukhari 75) and “give him understanding of the religion“ (Sahih al-Bukhari 143). He became “the Interpreter of the Quran“ and “the Scholar of the Nation,“ the teacher of Mujahid, Ikrimah, Sa‘id ibn Jubayr, and Ata’, and the root of the Makkan school of tafsir.")

                    ScholarEntry(name: "Aisha bint Abi Bakr", arabic: "عَائِشَة بِنت أَبِي بَكر", meta: "d. 58 AH / 678 CE · Madinah", description: "The Mother of the Believers and the most knowledgeable woman of the nation; the Prophet (peace be upon him) said her superiority over women is like that of tharid over other food (Sahih al-Bukhari 3770). The senior Companions asked her about inheritance, the Prophet’s worship, and his private life, and she corrected scholars from the Quran and Sunnah. Over two thousand hadith are narrated from her.")

                    ScholarEntry(name: "Zayd ibn Thabit", arabic: "زَيد بن ثَابِت", meta: "d. 45 AH / 665 CE · Madinah", description: "The Prophet’s scribe of revelation, who learned Hebrew at his command in a fortnight. The most knowledgeable in inheritance law (Sunan al-Tirmidhi 3790), he was chosen by Abu Bakr to collect the Quran and by Uthman to head its transcription.")

                    ScholarEntry(name: "Mu‘adh ibn Jabal", arabic: "مُعَاذ بن جَبَل", meta: "d. 18 AH / 639 CE · Syria", description: "The most knowledgeable in the lawful and the unlawful (Sunan al-Tirmidhi 3790). The Prophet (peace be upon him) sent him to Yemen as teacher and judge with the words, “let the first thing you call them to be the tawhid of Allah“ (Sahih al-Bukhari 7372), and rode with him while teaching him the right of Allah upon His servants (Sahih al-Bukhari 2856).")

                    ScholarEntry(name: "Ubayy ibn Ka‘b", arabic: "أُبَيّ بن كَعب", meta: "d. c. 22 AH / 643 CE · Madinah", description: "The master of the reciters. Allah commanded the Prophet (peace be upon him) to recite Surat al-Bayyinah to him by name, and Ubayy wept (Sahih al-Bukhari 4959). Umar chose him to lead the Tarawih prayer.")

                    ScholarEntry(name: "Abu Hurayrah", arabic: "أَبُو هُرَيرَة", meta: "d. 59 AH / 679 CE · Madinah", description: "The most prolific narrator of hadith, having devoted himself to the Prophet’s company for the last years of his life and, by the Prophet’s prayer, forgotten nothing he heard. He narrated because the Quran condemns concealing knowledge (Sahih al-Bukhari 118), and over five thousand hadith reached the nation through him.")

                    ScholarEntry(name: "Abdullah ibn Umar", arabic: "عَبد الله بن عُمَر", meta: "d. 73 AH / 693 CE · Makkah", description: "Of whom the Prophet (peace be upon him) said, “What an excellent man Abdullah is, if only he prayed at night,“ after which he hardly slept (Sahih al-Bukhari 3738). The most careful follower of the Prophet’s every action, the teacher of Nafi‘ and Salim, and a root of the Madinan school of Imam Malik.")

                    ScholarEntry(name: "Hudhayfah ibn al-Yaman", arabic: "حُذَيفَة بن اليَمَان", meta: "d. 36 AH / 656 CE · Mada’in", description: "The keeper of the Prophet’s secret, who asked him about evil while others asked about good, and preserved his guidance for times of trial: “Hold to the community of the Muslims and their leader“ (Sahih al-Bukhari 7084).")

                    ScholarEntry(name: "Abu ad-Darda’, Abu Musa al-Ash‘ari, Abu Dharr, Jabir, Anas", arabic: "وَغَيرُهُم", meta: "the teachers of the cities", description: "Abu ad-Darda’ taught in Damascus; Abu Musa al-Ash‘ari, given “one of the flutes of the family of Dawud“ (Sahih al-Bukhari 5048), governed and taught Basrah and Kufah; Abu Dharr, than whom “the sky has not shaded nor the earth carried anyone more truthful“ (Sunan al-Tirmidhi 3801; graded sahih by al-Albani), was the voice of ascetic honesty; Jabir ibn Abdullah had a circle in the Prophet’s mosque; and Anas ibn Malik, the Prophet’s servant for ten years, blessed with long life and children by his prayer (Sahih al-Bukhari 6334), taught in Basrah until 93 AH.")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The Companions were the first scholars and the first teachers. Every madhhab of fiqh, every school of tafsir, and every chain of hadith goes back to one of these men and women sitting before the Prophet.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Sahabi (صَحَابِيّ)**: a Companion, from the root ص-ح-ب, “to accompany.“ Ibn Hajar (may Allah have mercy on him) gives the accepted definition in al-Isabah:")
                        .font(.body)
                    ScriptureQuote(text: "“The Sahabi is one who met the Prophet (peace be upon him) believing in him, and died upon Islam” (Ibn Hajar, al-Isabah fi Tamyiz as-Sahabah).", arabic: "الصَّحَابِيُّ: مَنْ لَقِيَ النَّبِيَّ صلى الله عليه وسلم مُؤْمِنًا بِهِ، وَمَاتَ عَلَى الإِسْلَامِ", dimmed: true)
                    Text("So a Companion is not only one who kept his company for years; whoever met him as a believer, even once, and died a Muslim is a Sahabi. Allah declared Himself pleased with them, and so Ahl as-Sunnah hold that every Companion is trustworthy in what he narrates; a chain is examined below the Companion, never at him:")
                        .font(.body)
                    ScriptureQuote(text: "“And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).", arabic: "وَٱلسَّٰبِقُونَ ٱلۡأَوَّلُونَ مِنَ ٱلۡمُهَٰجِرِينَ وَٱلۡأَنصَارِ وَٱلَّذِينَ ٱتَّبَعُوهُم بِإِحۡسَٰنٖ رَّضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُ")
                    Text("The Prophet (peace be upon him) forbade abusing them:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not abuse my Companions, for if any one of you spent gold equal to Uhud, it would not equal a mudd of one of them, or even half of it” (Sahih al-Bukhari 3673, Sahih Muslim 2541).", arabic: "لاَ تَسُبُّوا أَصْحَابِي، فَلَوْ أَنَّ أَحَدَكُمْ أَنْفَقَ مِثْلَ أُحُدٍ ذَهَبًا مَا بَلَغَ مُدَّ أَحَدِهِمْ وَلاَ نَصِيفَهُ", dimmed: true)

                    Text("**Ahlul Bayt (أَهل البَيت)**: “the People of the House,“ from bayt (بَيت), “house“: the household of the Prophet (peace be upon him). They are his wives, whom the verse of purification addresses in its context, and his relatives for whom zakah is forbidden, the families of Ali, Aqil, Ja‘far, and al-Abbas, as Zayd ibn Arqam explained (Sahih Muslim 2408). Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah intends only to remove from you the impurity [of sin], O people of the [Prophet's] household, and to purify you with [extensive] purification” (Quran 33:33).", arabic: "إِنَّمَا يُرِيدُ ٱللَّهُ لِيُذۡهِبَ عَنكُمُ ٱلرِّجۡسَ أَهۡلَ ٱلۡبَيۡتِ وَيُطَهِّرَكُمۡ تَطۡهِيرٗا")
                    Text("The Prophet (peace be upon him) wrapped Ali, Fatimah, al-Hasan, and al-Husayn in his cloak and recited this verse over them (Sahih Muslim 2424), and at the pool of Khumm, between Makkah and Madinah, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“And the people of my household: I remind you of Allah regarding the people of my household” (Sahih Muslim 2408).", arabic: "وَأَهْلُ بَيْتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهْلِ بَيْتِي", dimmed: true)
                    Text("Ahl as-Sunnah love them, honour them, and keep this will, without raising them above the rank Allah gave them; see the page “The People of the House.“")
                        .font(.body)

                    Text("**The Ten Promised Paradise (العَشَرَة المُبَشَّرُون بِالجَنَّة)**: “the ten given glad tidings of Paradise,“ from bushra (بُشرَى), “glad tidings“: ten Companions named together as people of Paradise in one hadith. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Abu Bakr is in Paradise, Umar is in Paradise, Uthman is in Paradise, Ali is in Paradise, Talhah is in Paradise, az-Zubayr is in Paradise, Abd ar-Rahman ibn Awf is in Paradise, Sa‘d is in Paradise, Sa‘id is in Paradise, and Abu Ubaydah ibn al-Jarrah is in Paradise” (Sunan al-Tirmidhi 3747; graded sahih by al-Albani).", arabic: "أَبُو بَكْرٍ فِي الْجَنَّةِ وَعُمَرُ فِي الْجَنَّةِ وَعُثْمَانُ فِي الْجَنَّةِ وَعَلِيٌّ فِي الْجَنَّةِ وَطَلْحَةُ فِي الْجَنَّةِ وَالزُّبَيْرُ فِي الْجَنَّةِ وَعَبْدُ الرَّحْمَنِ بْنُ عَوْفٍ فِي الْجَنَّةِ وَسَعْدٌ فِي الْجَنَّةِ وَسَعِيدٌ فِي الْجَنَّةِ وَأَبُو عُبَيْدَةَ بْنُ الْجَرَّاحِ فِي الْجَنَّةِ", dimmed: true)
                    Text("Sa‘d is Sa‘d ibn Abi Waqqas and Sa‘id is Sa‘id ibn Zayd, as Sa‘id ibn Zayd himself narrated (Sunan Abi Dawud 4649; graded sahih by al-Albani). Others were given the glad tidings individually, among them Fatimah (Sahih al-Bukhari 3623), al-Hasan and al-Husayn (Sunan al-Tirmidhi 3768; graded sahih by al-Albani), and Abdullah ibn Salam (Sahih al-Bukhari 3812); the ten are singled out because they were named in one breath.")
                        .font(.body)

                    Text("**The Rightly Guided Caliphs (الخُلَفَاء الرَّاشِدُون)**: Abu Bakr, Umar, Uthman, and Ali (may Allah be pleased with them), in that order of caliphate and of excellence. Khalifah (خَلِيفَة) is from the root خ-ل-ف, “to come after, to succeed,“ and rashid (رَاشِد) from ر-ش-د, “to be rightly guided.“ The Prophet (peace be upon him) commanded the nation to hold to “my Sunnah and the Sunnah of the rightly guided caliphs after me“ (Sunan Abi Dawud 4607; graded sahih by al-Albani), a hadith quoted in full on the pages “Salafiyyah“ and “Ahl As-Sunnah“ in this app. Their practice is therefore a guided pattern for the nation, not personal opinion. Umar ibn Abd al-Aziz is often counted with them for his justice.")
                        .font(.body)

                    Text("**The Four Abdullahs (العَبَادِلَة الأَربَعَة)**: Abadilah is the plural of Abdullah. Four young Companions who each bore the name, outlived most of the others, and became the teachers of the following generation: Abdullah ibn Abbas, Abdullah ibn Umar, Abdullah ibn az-Zubayr, and Abdullah ibn Amr ibn al-As (may Allah be pleased with them). Imam Ahmad named these four as the Abadilah and did not count Abdullah ibn Mas‘ud, for all his knowledge, because he died early, in 32 AH, before the nation needed their fatawa; when the four agreed on a ruling the jurists said, “this is the saying of the Abadilah“ (Ibn as-Salah, Ulum al-Hadith).")
                        .font(.body)

                    Text("**The Mothers of the Believers (أُمَّهَات المُؤمِنِين)**: from umm (أُمّ), “mother“: the wives of the Prophet (peace be upon him), given this title by Allah Himself. They are forbidden in marriage to the nation forever (Quran 33:53), honoured as mothers are honoured, and were teachers of the religion, above all Aisha and Umm Salamah:")
                        .font(.body)
                    ScriptureQuote(text: "“The Prophet is more worthy of the believers than themselves, and his wives are [in the position of] their mothers” (Quran 33:6).", arabic: "ٱلنَّبِيُّ أَوۡلَىٰ بِٱلۡمُؤۡمِنِينَ مِنۡ أَنفُسِهِمۡۖ وَأَزۡوَٰجُهُۥٓ أُمَّهَٰتُهُمۡۗ")

                    Text("**Tabi‘i (تَابِعِيّ)** and **Tabi‘ at-Tabi‘in (تَابِع التَّابِعِين)**: from the root ت-ب-ع, “to follow.“ A Tabi‘i (Successor) is one who met a Companion as a Muslim and died as a Muslim; a Tabi‘ at-Tabi‘in is one who likewise met a Tabi‘i. They are the second and third of the three generations the Prophet (peace be upon him) called the best of people (Sahih al-Bukhari 2652), and they are “those who followed them with good conduct“ of the verse above. Sa‘id ibn al-Musayyib, al-Hasan al-Basri, and Mujahid are of the first; Malik, Sufyan ath-Thawri, and al-Awza‘i are of the second. See the page “The Salaf and the Imams.“")
                        .font(.body)

                    Text("**The Seven Jurists of Madinah (الفُقَهَاء السَّبعَة)**: seven Tabi‘un of Madinah whose fatawa formed the school inherited by Imam Malik: Sa‘id ibn al-Musayyib, Urwah ibn az-Zubayr, al-Qasim ibn Muhammad ibn Abi Bakr, Kharijah ibn Zayd ibn Thabit, Sulayman ibn Yasar, Ubaydullah ibn Abdullah ibn Utbah, and Abu Bakr ibn Abd ar-Rahman ibn al-Harith, though some name Abu Salamah ibn Abd ar-Rahman or Salim ibn Abdullah ibn Umar as the seventh. Urwah was the son of az-Zubayr, al-Qasim the grandson of Abu Bakr, and Kharijah the son of Zayd ibn Thabit, which shows how knowledge passed within the households of the Companions.")
                        .font(.body)

                    Text("**Salaf (سَلَف)**: “those who came before,“ from the root س-ل-ف, “to precede.“ In the usage of the scholars it means the Companions, the Tabi‘un, and the Tabi‘ at-Tabi‘in, the three best generations, and then those who followed their way. The Prophet (peace be upon him) used the word of himself when he told Fatimah of his approaching death:")
                        .font(.body)
                    ScriptureQuote(text: "“So fear Allah and be patient, for I am the best predecessor (salaf) for you” (Sahih al-Bukhari 6285).", arabic: "فَاتَّقِي اللَّهَ وَاصْبِرِي، فَإِنِّي نِعْمَ السَّلَفُ أَنَا لَكَ", dimmed: true)
                    Text("“Salafi“ therefore means nothing more than one who follows the Salaf in creed and practice, as explained on the page “Salafiyyah.“")
                        .font(.body)

                    Text("**Alim (عَالِم)**, plural **ulama (عُلَمَاء)**: “one who knows,“ from the root ع-ل-م. In the Quran the ulama are those who fear Allah because they know Him (Quran 35:28, quoted above), so knowledge that does not produce fear is not the knowledge Allah praised, and the sign that Allah wants good for a person is that He gives him understanding of the religion (Sahih al-Bukhari 71, quoted above). Ibn Mas‘ud (may Allah be pleased with him) said that knowledge is not abundance of narration; knowledge is fear of Allah (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm wa Fadlih).")
                        .font(.body)

                    Text("**Rabbani (رَبَّانِيّ)**: from Rabb (رَبّ), “Lord“: one devoted to his Lord who nurtures the people upon His religion. Allah says that the prophets commanded their followers:")
                        .font(.body)
                    ScriptureQuote(text: "“Be pious scholars of the Lord because of what you have taught of the Scripture and because of what you have studied” (Quran 3:79).", arabic: "كُونُواْ رَبَّٰنِيِّـۧنَ بِمَا كُنتُمۡ تُعَلِّمُونَ ٱلۡكِتَٰبَ وَبِمَا كُنتُمۡ تَدۡرُسُونَ")
                    Text("Ibn Abbas explained the Rabbaniyyun as the forbearing and the jurists, and al-Bukhari adds in the chapter headings of his Sahih, “it is said that the Rabbani is the one who nurtures the people with the small matters of knowledge before the great ones“ (Sahih al-Bukhari, Kitab al-‘Ilm, chapter “Knowledge before speech and action“).")
                        .font(.body)

                    Text("**Ahl adh-Dhikr (أَهل الذِّكر)**: “the people of the Reminder,“ dhikr (ذِكر) being the revelation Allah sent down: those who know it, whom Allah commands the one who does not know to ask (Quran 16:43, quoted above). The verse speaks first of the people of the earlier Scriptures, and its ruling covers the scholars of the Quran and Sunnah in every age, as the scholars of tafsir explain.")
                        .font(.body)

                    Text("**Imam (إِمَام)**: “one who is followed,“ from the root أ-م-م, the same word as the leader of the prayer. In scholarship it is the title of a scholar whose knowledge made him a reference for others, as in “Imam Malik“ and “Imam Ahmad.“ Allah says of the leaders of the Children of Israel:")
                        .font(.body)
                    ScriptureQuote(text: "“And We made from among them leaders guiding by Our command when they were patient and [when] they were certain of Our signs” (Quran 32:24).", arabic: "وَجَعَلۡنَا مِنۡهُمۡ أَئِمَّةٗ يَهۡدُونَ بِأَمۡرِنَا لَمَّا صَبَرُواْۖ وَكَانُواْ بِـَٔايَٰتِنَا يُوقِنُونَ")
                    Text("Ibn al-Qayyim writes in Madarij as-Salikin that by patience and certainty leadership in the religion is attained. In Ahl as-Sunnah the title carries no infallibility; an imam is followed for his evidence.")
                        .font(.body)

                    Text("**Hafiz (حَافِظ)**: “preserver,“ from the root ح-ف-ظ. Among the hadith scholars it is the rank of one who has memorised a great body of hadith with their chains and knows their narrators, above the ordinary muhaddith; Ibn Hajar and adh-Dhahabi are called al-Hafiz. In common speech it is also used for one who has memorised the whole Quran. The Prophet (peace be upon him) prayed for those who preserve his words:")
                        .font(.body)
                    ScriptureQuote(text: "“May Allah gladden a man who hears something from us and conveys it as he heard it; perhaps the one it is conveyed to understands it better than the one who heard it” (Sunan al-Tirmidhi 2657; graded sahih by al-Albani).", arabic: "نَضَّرَ اللَّهُ امْرَأً سَمِعَ مِنَّا شَيْئًا فَبَلَّغَهُ كَمَا سَمِعَ فَرُبَّ مُبَلَّغٍ أَوْعَى مِنْ سَامِعٍ", dimmed: true)

                    Text("**Muhaddith (مُحَدِّث)**: from hadith (حَدِيث), “speech, report“: a scholar who transmits and examines the narrations of the Prophet (peace be upon him): their chains, their narrators, their wordings, and their hidden defects. Al-Bukhari, Muslim, Abu Dawud, and in our time al-Albani are muhaddithun. Not every muhaddith is a jurist; as the Prophet (peace be upon him) said in the hadith narrated by Zayd ibn Thabit, “many a bearer of knowledge conveys it to one who is more versed than he is, and many a bearer of knowledge is not versed in it“ (Sunan Abi Dawud 3660; graded sahih by al-Albani).")
                        .font(.body)

                    Text("**Faqih (فَقِيه)**: from fiqh (فِقه), “understanding“: a scholar who derives the rulings of the lawful and the unlawful from the texts. The Prophet (peace be upon him) prayed that Ibn Abbas be given fiqh (Sahih al-Bukhari 143), and Mu‘adh was the most knowledgeable of the Companions in the lawful and the unlawful (Sunan al-Tirmidhi 3790, quoted above).")
                        .font(.body)

                    Text("**Mufassir (مُفَسِّر)**: from tafsir (تَفسِير), “explanation,“ from the root ف-س-ر, “to uncover“: a scholar who explains the Quran by the Quran, the Sunnah, the statements of the Companions and the Tabi‘un, and the Arabic language. Ibn Abbas was the first great mufassir, by the prayer of the Prophet (peace be upon him) that he be taught the Book (Sahih al-Bukhari 75); at-Tabari, Ibn Kathir, and as-Sa‘di are among his heirs. See the page “Tafsir.“")
                        .font(.body)

                    Text("**Mujtahid (مُجتَهِد)**: from ijtihad (اِجتِهَاد), “exerting effort,“ from the root ج-ه-د: a scholar qualified to derive rulings directly from the Quran and Sunnah on questions the texts do not settle by their plain wording. The Prophet (peace be upon him) promised the judge who strives and is correct two rewards and the one who strives and errs one reward (Sahih al-Bukhari 7352), so ijtihad is honoured even when it misses, and its error is forgiven, not followed.")
                        .font(.body)

                    Text("**Qadi (قَاضِي)**: “judge,“ from the root ق-ض-ي, “to decide“: the scholar appointed to judge between people by the Shari‘ah. Ali and Mu‘adh judged in Yemen in the Prophet’s lifetime, Shurayh judged Kufah for Umar and Ali, and later scholars such as Abu Yusuf, the chief judge of the Abbasids, and Ibn Hajar, the chief Shafi‘i judge of Egypt, held the office.")
                        .font(.body)

                    Text("**Shaykh al-Islam (شَيخ الإِسلَام)**: shaykh (شَيخ) is “elder“ or “master“: a title of honour given by the scholars to one to whom the people of an age turned in creed and law. It was given to Abu Isma‘il al-Harawi in the fifth century, to Ibn Taymiyyah above all, and to Ibn Hajar; Ibn Nasir ad-Din ad-Dimashqi wrote ar-Radd al-Wafir to show how many imams had used it for Ibn Taymiyyah.")
                        .font(.body)

                    Text("**Amir al-Mu’minin fil-Hadith (أَمِير المُؤمِنِين فِي الحَدِيث)**: “the Commander of the Believers in hadith,“ the highest title of the hadith scholars, given to a handful of masters in each age, among them Shu‘bah and Sufyan ath-Thawri, as adh-Dhahabi records in Siyar A‘lam an-Nubala’, then al-Bukhari, and in later times Ibn Hajar.")
                        .font(.body)

                    Text("**Mujaddid (مُجَدِّد)**: “renewer,“ from the root ج-د-د: one who renews the religion after it has been neglected, by teaching the Sunnah and removing innovation. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah will raise for this nation at the end of every hundred years one who will renew its religion for it” (Sunan Abi Dawud 4291; graded sahih by al-Albani).", arabic: "إِنَّ اللَّهَ يَبْعَثُ لِهَذِهِ الأُمَّةِ عَلَى رَأْسِ كُلِّ مِائَةِ سَنَةٍ مَنْ يُجَدِّدُ لَهَا دِينَهَا", dimmed: true)
                    Text("The scholars counted Umar ibn Abd al-Aziz as the renewer of the first century and ash-Shafi‘i of the second, and later scholars counted Ibn Taymiyyah and Muhammad ibn Abd al-Wahhab among the renewers of their centuries. The hadith does not say the renewer must be one man; Ibn Kathir wrote in al-Bidayah wan-Nihayah that it includes the carriers of knowledge of every field.")
                        .font(.body)

                    Text("**Isnad (إِسنَاد)**: “chain of support,“ from the root س-ن-د, “to lean upon“: the chain of narrators by which a hadith reaches us: “so-and-so told me, from so-and-so, from the Prophet.“ Abdullah ibn al-Mubarak’s words that the isnad is part of the religion are quoted on the page “The Salaf and the Imams.“ Muhammad ibn Sirin described how the demand for it began:")
                        .font(.body)
                    ScriptureQuote(text: "“They did not use to ask about the isnad, but when the fitnah occurred they said: name your men to us. So the people of the Sunnah were looked at and their hadith taken, and the people of innovation were looked at and their hadith not taken” (Muqaddimah of Sahih Muslim).", arabic: "لَمْ يَكُونُوا يَسْأَلُونَ عَنِ الإِسْنَادِ، فَلَمَّا وَقَعَتِ الْفِتْنَةُ قَالُوا: سَمُّوا لَنَا رِجَالَكُمْ، فَيُنْظَرُ إِلَى أَهْلِ السُّنَّةِ فَيُؤْخَذُ حَدِيثُهُمْ، وَيُنْظَرُ إِلَى أَهْلِ الْبِدَعِ فَلاَ يُؤْخَذُ حَدِيثُهُمْ", dimmed: true)

                    Text("**Jarh wa Ta‘dil (الجَرح وَالتَّعدِيل)**: “criticism and declaring trustworthy“; jarh (جَرح) is literally “wounding“ and ta‘dil is from ‘adl (عَدل), “uprightness“: the science of judging narrators, so that a hadith is accepted only from the truthful and the accurate. It is founded on the Quranic command to verify reports:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, if there comes to you a disobedient one with information, investigate” (Quran 49:6).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ إِن جَآءَكُمۡ فَاسِقُۢ بِنَبَإٖ فَتَبَيَّنُوٓاْ")
                    Text("Its imams were Shu‘bah, Yahya ibn Sa‘id al-Qattan, Ibn Ma‘in, Ali ibn al-Madini, Ahmad, al-Bukhari, Abu Hatim, and an-Nasa’i, and its rulings fill the books of narrators such as Tahdhib al-Kamal of al-Mizzi and Tahdhib at-Tahdhib of Ibn Hajar.")
                        .font(.body)

                    Text("**Siyar (سِيَر)**: plural of sirah (سِيرَة), “way of life,“ from the root س-ي-ر, “to travel“: biographies. The greatest work of the kind is Siyar A‘lam an-Nubala’ of adh-Dhahabi, the lives of the notable figures of the nation from the Companions to his own day, and the source of much on these pages.")
                        .font(.body)

                    Text("**Tabaqat (طَبَقَات)**: “layers“ or “generations,“ from the root ط-ب-ق. The scholars arranged the narrators and the jurists in generations, the Companions, then the Tabi‘un, and so on, in books such as at-Tabaqat al-Kubra of Ibn Sa‘d, Tabaqat al-Hanabilah of Ibn Abi Ya‘la, and Tabaqat ash-Shafi‘iyyah of as-Subki, so that a chain can be checked: each narrator must have lived in the generation that could meet the one above him.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Scholars of the Sahabah")
        .selectableArticleList()
    }
}

struct SalafScholarsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Tabi'un learned from the Companions, their students became the imams of fiqh and hadith, and together these three generations are the Salaf whose understanding defines Ahl as-Sunnah.")
                        .font(.body)
                }

                Section(header: Text("THE TABI'UN (SUCCESSORS)")) {
                    Text("The **Tabi‘un (التَّابِعُون)** met the Companions and took the religion from them. The Prophet (peace be upon him) called them the second best generation (Sahih al-Bukhari 2652). Among the greatest:")
                        .font(.body)

                    ScholarEntry(name: "Sa‘id ibn al-Musayyib", arabic: "سَعِيد بن المُسَيَّب", meta: "d. 94 AH / 713 CE · Madinah", description: "The master of the Tabi‘un and chief of the seven jurists of Madinah, married to the daughter of Abu Hurayrah and the most knowledgeable of the people in the judgements of Umar.")

                    ScholarEntry(name: "Al-Hasan al-Basri", arabic: "الحَسَن البَصرِي", meta: "d. 110 AH / 728 CE · Basrah", description: "Raised in the house of Umm Salamah, the preacher of Basrah whose sermons on the Hereafter, sincerity, and the decree are the pattern of every later reminder. It was from his circle that Wasil ibn Ata withdrew to found the Mu‘tazilah, and al-Hasan remained upon the Sunnah.")

                    ScholarEntry(name: "Mujahid ibn Jabr", arabic: "مُجَاهِد بن جَبر", meta: "d. 104 AH / 722 CE · Makkah", description: "Who said he read the Quran to Ibn Abbas three times, stopping at every verse to ask about it. His explanations fill the tafsir of at-Tabari.")

                    ScholarEntry(name: "Sa‘id ibn Jubayr, Ikrimah, Ata’ ibn Abi Rabah", arabic: "تَلَامِيذ ابن عَبَّاس", meta: "d. 95, 105, 114 AH · Kufah and Makkah", description: "The three other great students of Ibn Abbas. Sa‘id ibn Jubayr was killed by al-Hajjaj in 95 AH for his faith; Ikrimah carried his master’s tafsir; Ata’ was the mufti of Makkah in the Hajj season.")

                    ScholarEntry(name: "Muhammad ibn Sirin", arabic: "مُحَمَّد بن سِيرِين", meta: "d. 110 AH / 728 CE · Basrah", description: "The scrupulous jurist who said, “This knowledge is religion, so look from whom you take your religion“ (Muqaddimah of Sahih Muslim). His caution about narrators is the seed of the science of hadith criticism.")

                    ScholarEntry(name: "Ibrahim al-Nakha‘i and Alqamah", arabic: "إِبرَاهِيم النَّخَعِي وَعَلقَمَة", meta: "d. 96 and 62 AH · Kufah", description: "The heirs of Ibn Mas‘ud in Kufah. Alqamah resembled his teacher in manner and knowledge; al-Nakha‘i was the jurist of Iraq whose student Hammad taught Abu Hanifah.")

                    ScholarEntry(name: "Umar ibn Abd al-Aziz", arabic: "عُمَر بن عَبد العَزِيز", meta: "d. 101 AH / 720 CE · Syria", description: "The just caliph counted among the rightly guided, who ordered the first official writing down of the hadith and returned the wealth of the state to the people.")

                    ScholarEntry(name: "Ibn Shihab az-Zuhri", arabic: "ابن شِهَاب الزُّهرِي", meta: "d. 124 AH / 742 CE · Madinah", description: "The first to systematically record the hadith of Madinah, the teacher of Malik, and a narrator in the chains of a huge part of the Sunnah.")
                }

                Section(header: Text("THE IMAMS OF FIQH")) {
                    Text("The students of the Tabi‘un, the **Atba‘ at-Tabi‘in**, were the third generation. Among them the four imams of the schools of fiqh (see “The Madhahib of Fiqh“): **Abu Hanifah** (80–150 AH), **Malik** (93–179 AH), **al-Shafi‘i** (150–204 AH), and **Ahmad ibn Hanbal** (164–241 AH). Beside them stood imams of equal rank whose schools did not survive as madhahib but whose knowledge did:")
                        .font(.body)

                    ScholarEntry(name: "Al-Awza‘i", arabic: "الأَوزَاعِي", meta: "88–157 AH · Beirut, Syria", description: "The imam of Syria, whose school was followed there and in Andalusia for two centuries, and who said, “Hold to the narrations of those who came before, even if the people reject you.“")

                    ScholarEntry(name: "Sufyan al-Thawri", arabic: "سُفيَان الثَّورِي", meta: "97–161 AH · Kufah", description: "Called “the Commander of the Believers in hadith,“ a jurist with his own school, and the ascetic who said innovation is more beloved to Iblis than sin.")

                    ScholarEntry(name: "Al-Layth ibn Sa‘d", arabic: "اللَّيث بن سَعد", meta: "94–175 AH · Egypt", description: "The imam of Egypt, of whom al-Shafi‘i said he was a greater jurist than Malik but his students did not preserve his school.")

                    ScholarEntry(name: "Abdullah ibn al-Mubarak", arabic: "عَبد الله بن المُبَارَك", meta: "118–181 AH · Marw, Khurasan", description: "Scholar, merchant, warrior, and ascetic in one; the author of az-Zuhd and al-Jihad, and the man who said, “The isnad is part of the religion; were it not for the isnad, anyone would say whatever he wished“ (Muqaddimah of Sahih Muslim).")

                    ScholarEntry(name: "Sufyan ibn Uyaynah, Waki‘, al-Fudayl ibn Iyad", arabic: "ابن عُيَينَة، وَكِيع، الفُضَيل", meta: "d. 198, 197, 187 AH · Makkah and Kufah", description: "Sufyan ibn Uyaynah, the hadith master of Makkah and teacher of al-Shafi‘i and Ahmad; Waki‘ ibn al-Jarrah, the teacher of al-Shafi‘i and Ahmad in Kufah; and al-Fudayl ibn Iyad, the repentant highwayman who became the worshipper of the Haram, whose words on sincerity the Salaf passed down.")
                }

                Section(header: Text("THE IMAMS OF HADITH")) {
                    Text("The generation after the four imams gave the nation the collections in which the Sunnah is preserved:")
                        .font(.body)

                    ScholarEntry(name: "Yahya ibn Ma‘in, Ali ibn al-Madini, Ishaq ibn Rahwayh", arabic: "أَئِمَّة الجَرح وَالتَّعدِيل", meta: "d. 233, 234, 238 AH · Baghdad, Basrah, Nishapur", description: "The masters of narrator criticism, the companions of Imam Ahmad, and the teachers of al-Bukhari.")

                    ScholarEntry(name: "Muhammad ibn Isma‘il al-Bukhari", arabic: "البُخَارِي", meta: "194–256 AH / 810–870 CE · Bukhara", description: "Who chose about 7,300 hadith from six hundred thousand for his Sahih, the most authentic book after the Quran, praying two units before entering each one.")

                    ScholarEntry(name: "Muslim ibn al-Hajjaj", arabic: "مُسلِم", meta: "204–261 AH / 821–875 CE · Nishapur", description: "Al-Bukhari’s student, whose Sahih is second to his master’s in authenticity and first in arrangement.")

                    ScholarEntry(name: "Abu Dawud, al-Tirmidhi, al-Nasa’i, Ibn Majah", arabic: "أَصحَاب السُّنَن", meta: "d. 275, 279, 303, 273 AH", description: "The authors of the four Sunan, completing the six books. Al-Tirmidhi (a student of al-Bukhari) recorded the grade of each hadith and the opinions of the jurists; al-Nasa’i was the strictest of them in narrators.")

                    ScholarEntry(name: "Ad-Darimi, Ibn Khuzaymah, Ibn Hibban, ad-Daraqutni, al-Hakim, al-Bayhaqi", arabic: "الحُفَّاظ", meta: "3rd to 5th century AH", description: "The hadith masters whose Sunan, Sahihs, and Mustadrak preserved what the six left, and whose books on creed (al-Bukhari’s Khalq Af‘al al-‘Ibad, ad-Darimi’s reply to the Jahmiyyah, Ibn Khuzaymah’s Kitab al-Tawhid, al-Bayhaqi’s al-Asma’ was-Sifat) recorded the Athari creed with its evidences.")

                    ScholarEntry(name: "Al-Barbahari, Ibn Battah, al-Lalaka’i, Ibn Abd al-Barr, al-Khatib al-Baghdadi", arabic: "أَئِمَّة السُّنَّة", meta: "d. 329, 387, 418, 463, 463 AH", description: "The Hanbali imams of Baghdad who wrote the creed of the Salaf down sect by sect (Sharh as-Sunnah, al-Ibanah, Sharh Usul I‘tiqad Ahl as-Sunnah); the Maliki Ibn Abd al-Barr of Andalusia, the hadith master of the West; and al-Khatib, the historian of Baghdad and author of Sharaf Ashab al-Hadith.")
                }

                Section(header: Text("WHAT MADE THEM THE SALAF")) {
                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“No people gather in one of the houses of Allah, reciting the Book of Allah and studying it together, except that tranquillity descends upon them, mercy covers them, the angels surround them, and Allah mentions them to those with Him” (Sahih Muslim 2699).", arabic: "وَمَا اجْتَمَعَ قَوْمٌ فِي بَيْتٍ مِنْ بُيُوتِ اللَّهِ يَتْلُونَ كِتَابَ اللَّهِ وَيَتَدَارَسُونَهُ بَيْنَهُمْ إِلاَّ نَزَلَتْ عَلَيْهِمُ السَّكِينَةُ وَغَشِيَتْهُمُ الرَّحْمَةُ وَحَفَّتْهُمُ الْمَلاَئِكَةُ وَذَكَرَهُمُ اللَّهُ فِيمَنْ عِنْدَهُ", dimmed: true)

                    Text("The Salaf were such gatherings: men who sat before the Companions and passed on what they heard, word for word, with the names of those they heard it from. They did not philosophise the creed, and they did not invent worship. Their agreement is a proof, because the Prophet (peace be upon him) guaranteed their goodness.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("From Ibn al-Musayyib and al-Hasan al-Basri to the four imams and the authors of the six books, the Salaf carried the religion by chains of teacher and student. The understanding of these generations is the measure of every later scholar.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Salaf and the Imams")
        .selectableArticleList()
    }
}

struct TabariView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ibn Jarir at-Tabari (224–310 AH) wrote the greatest early tafsir and the great early history of Islam, gathering the explanations of the Companions and Tabi'un with their chains.")
                        .font(.body)
                }

                Section(header: Text("HIS LIFE")) {
                    Text("**Abu Ja‘far Muhammad ibn Jarir at-Tabari (مُحَمَّد بن جَرِير الطَّبَرِي)** was born in 224 AH / 839 CE in Amul in Tabaristan, on the southern shore of the Caspian Sea. He memorised the Quran at seven, led the prayer at eight, and wrote hadith at nine. He travelled to Rayy, Baghdad, Basrah, Kufah, Syria, and Egypt in search of knowledge, then settled in Baghdad, where he taught until his death in 310 AH / 923 CE.")
                        .font(.body)

                    Text("He never married, ate little, and is said to have written forty pages a day for forty years. He refused gifts from rulers and the office of judge, living from a small income sent by his father from Tabaristan.")
                        .font(.body)
                }

                Section(header: Text("HIS WORKS")) {
                    Text("**Jami‘ al-Bayan ‘an Ta’wil Ay al-Quran (جَامِع البَيَان)**, known as Tafsir at-Tabari: the mother of all books of tafsir. For each verse he gathers the explanations of the Companions and the Tabi‘un with their chains of narration, weighs them, and gives his judgement with the reasoning from the Arabic language. Later works of tafsir bil-ma’thur, including Ibn Kathir’s, draw on it.")
                        .font(.body)

                    Text("**Tarikh ar-Rusul wal-Muluk (تَارِيخ الرُّسُل وَالمُلُوك)**, the History of the Prophets and Kings: the great chronicle from the creation to the year 302 AH, in which the reports are given with their chains so that the reader can judge them, since he warned in its introduction that he was a transmitter, not a guarantor, of what he collected.")
                        .font(.body)

                    Text("**Tahdhib al-Athar**, a hadith work left unfinished; **Ikhtilaf al-Fuqaha’** on the differences of the jurists; and **Sarih as-Sunnah (صَرِيح السُّنَّة)**, his short statement of creed.")
                        .font(.body)
                }

                Section(header: Text("HIS CREED")) {
                    Text("In Sarih as-Sunnah he laid out the belief of Ahl as-Sunnah: that the Quran is the speech of Allah, uncreated; that the believers will see their Lord on the Day of Resurrection; that faith is word and deed and increases and decreases; that the decree, good and bad, is from Allah; and that the best of the nation after its Prophet are Abu Bakr, Umar, Uthman, and Ali. He affirmed the attributes as they came, and his tafsir on the verse of the Throne affirms Allah’s rising without asking how.")
                        .font(.body)

                    Text("He was a mujtahid whose own school of fiqh, the Jaririyyah, was followed for a time and then faded, which shows that a man can be an imam of the nation without leaving behind a madhhab.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("At-Tabari gathered what the first generations said about every verse and every year of history, with the chains that let the nation check it. He is the imam of the mufassirun and the historians.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("At-Tabari")
        .selectableArticleList()
    }
}

struct IbnTaymiyyahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ibn Taymiyyah (661–728 AH) is Shaykh al-Islam, the reviver who defended the creed of the Salaf against the sects and the philosophers, fought the Mongols, and died in prison for the truth. His students carried his knowledge to the whole nation.")
                        .font(.body)
                }

                Section(header: Text("HIS LIFE")) {
                    Text("**Taqi ad-Din Ahmad ibn Abd al-Halim ibn Abd as-Salam ibn Taymiyyah (أَحمَد بن عَبد الحَلِيم بن تَيمِيَّة)** was born on 10 Rabi‘ al-Awwal 661 AH / 22 January 1263 CE in Harran, in a family of Hanbali scholars. When the Mongols advanced, the family fled to Damascus in 667 AH, carrying their books on a cart. His father taught at the Umayyad Mosque, and when he died in 682 AH the son, at twenty-one, took his teaching post.")
                        .font(.body)

                    Text("He memorised the Quran as a child and mastered hadith, fiqh, Arabic, tafsir, and the books of the sects and the philosophers, so that he could refute them from their own words. He never married, lived simply, and gave away what he had.")
                        .font(.body)
                }

                Section(header: Text("THE MONGOLS AND THE TRIALS")) {
                    Text("When the Mongols under Ghazan took Damascus in 699 AH, he went to the Mongol camp himself and demanded the release of the prisoners. In 702 AH, at the battle of Shaqhab, he stood among the soldiers, gave the fatwa that fighting the Mongols was obligatory although they professed Islam, since they ruled by the Yasa of Genghis Khan, and swore to the hesitant that Allah would give victory. The Mongols were defeated.")
                        .font(.body)

                    Text("His refutations of grave-worship, of the philosophers, and of the theologians made him enemies among the rulers’ scholars. He was imprisoned in Cairo (705–707 AH) over his creed, in Alexandria in 709 AH, in the citadel of Damascus in 720 AH over a fatwa on divorce, and finally in 726 AH over his ruling that travelling to visit graves is not legislated. Denied ink and paper in the end, he died in the citadel on 20 Dhul-Qa‘dah 728 AH / 26 September 1328 CE. Ibn Kathir records that the crowd at his funeral was beyond counting, the largest Damascus had seen.")
                        .font(.body)

                    Text("Ibn al-Qayyim heard him say in prison:")
                        .font(.body)
                    ScriptureQuote(text: "“What can my enemies do to me? My paradise and my garden are in my breast; wherever I go they go with me and never leave me. My imprisonment is seclusion, my killing is martyrdom, and my expulsion from my land is travel” (Ibn al-Qayyim, al-Wabil as-Sayyib, p. 48).", arabic: "مَا يَصْنَعُ أَعْدَائِي بِي؟ أَنَا جَنَّتِي وَبُسْتَانِي فِي صَدْرِي، أَيْنَ رُحْتُ فَهِيَ مَعِي لَا تُفَارِقُنِي، إِنَّ حَبْسِي خَلْوَةٌ، وَقَتْلِي شَهَادَةٌ، وَإِخْرَاجِي مِنْ بَلَدِي سِيَاحَةٌ", dimmed: true)
                }

                Section(header: Text("HIS WORKS")) {
                    Text("**Al-Aqidah al-Wasitiyyah (العَقِيدَة الوَاسِطِيَّة)**: the creed of the Salaf in a few pages, written in one sitting for a judge from Wasit, and examined and approved in three public debates in Damascus in 705 AH.")
                        .font(.body)
                    Text("**Minhaj as-Sunnah an-Nabawiyyah (مِنهَاج السُّنَّة النَّبَوِيَّة)**: the reply to the Rafidi Ibn al-Mutahhar al-Hilli, and the most complete defence of the Companions and the caliphate ever written.")
                        .font(.body)
                    Text("**Dar’ Ta‘arud al-‘Aql wan-Naql**: showing that sound reason never contradicts authentic revelation, and answering the kalam theologians on their own ground.")
                        .font(.body)
                    Text("**Iqtida’ as-Sirat al-Mustaqim**: on innovations and on imitating the disbelievers in their festivals. **Al-Jawab as-Sahih**: the reply to Christianity. **Ar-Radd ‘ala al-Mantiqiyyin**: the refutation of Greek logic. **Al-‘Ubudiyyah**, **Al-Furqan**, **As-Siyasah ash-Shar‘iyyah**, and hundreds of treatises gathered in the thirty-seven volumes of **Majmu‘ al-Fatawa (مَجمُوع الفَتَاوَى)**.")
                        .font(.body)
                }

                Section(header: Text("HIS STUDENTS")) {
                    Text("His greatest legacy is the men he taught: **Ibn al-Qayyim**, who never left him from 712 AH and was imprisoned with him; **adh-Dhahabi**, the historian of Islam; **Ibn Kathir**, the mufassir and historian; **al-Mizzi**, the master of the narrators of the six books; **Ibn Abd al-Hadi**, who wrote his biography; **Ibn Muflih**, the Hanbali jurist; and **al-Bazzar**, who recorded his manners. Each has his own article or entry here.")
                        .font(.body)

                    Text("Adh-Dhahabi wrote that he had not seen anyone like him, and Ibn Hajar al-Asqalani, who differed with him on some matters, endorsed the book defending him and wrote that his fame needs no description. Like every scholar after the Prophet (peace be upon him), he could err, and the scholars of the Sunnah accepted from him what agreed with the evidence and left what did not, which is exactly what he asked of them.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Ibn Taymiyyah revived the creed of the Salaf when it had been buried under kalam and grave-worship, answered every sect from the Quran and Sunnah, and paid for it with his freedom and his life. The title Shaykh al-Islam is his by the agreement of those who came after.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ibn Taymiyyah")
        .selectableArticleList()
    }
}

struct IbnQayyimView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ibn al-Qayyim (691–751 AH) was the closest student of Ibn Taymiyyah and the scholar who turned the creed of the Salaf into books on the heart, worship, and law that Muslims still read every day.")
                        .font(.body)
                }

                Section(header: Text("HIS LIFE")) {
                    Text("**Shams ad-Din Muhammad ibn Abi Bakr ibn Ayyub (مُحَمَّد بن أَبِي بَكر ابن قَيِّم الجَوزِيَّة)** was born in 691 AH / 1292 CE in Damascus. His father was the **qayyim**, the caretaker, of the Jawziyyah school, hence the name Ibn Qayyim al-Jawziyyah. He studied every science of the religion with the scholars of Damascus and, from 712 AH, devoted himself to Ibn Taymiyyah, staying with him until the shaykh died in 728 AH.")
                        .font(.body)

                    Text("He was imprisoned with his teacher in the citadel for holding that travelling to visit graves is not legislated, and was released after the shaykh’s death. He spent the prison reading the Quran and in reflection, and later said it opened to him what he could not have gained outside. He taught at the Sadriyyah school, led prayer at the Jawziyyah, performed Hajj many times, and died on 13 Rajab 751 AH / 1350 CE.")
                        .font(.body)
                }

                Section(header: Text("HIS WORKS")) {
                    Text("**Madarij as-Salikin (مَدَارِج السَّالِكِين)**: the stations of the journey to Allah, taking the language of the Sufis and correcting it by the Quran and the Sunnah; his masterpiece on the purification of the heart.")
                        .font(.body)
                    Text("**Zad al-Ma‘ad (زَاد المَعَاد)**: the guidance of the Prophet (peace be upon him) in every part of life, from worship to medicine, drawn from the seerah and the hadith.")
                        .font(.body)
                    Text("**I‘lam al-Muwaqqi‘in (إِعلَام المُوَقِّعِين)**: the principles of law and fatwa, and the danger of blind following.")
                        .font(.body)
                    Text("**Al-Wabil as-Sayyib** on dhikr; **Ad-Da’ wad-Dawa’** (al-Jawab al-Kafi) on sin and its cure; **Ighathat al-Lahfan** on the snares of Shaytan and the shirk of the grave-worshippers; **Ar-Ruh** on the soul; **Miftah Dar as-Sa‘adah** on knowledge; **Al-Fawa’id**; **Hadi al-Arwah** on Paradise; and **al-Kafiyah ash-Shafiyah** (an-Nuniyyah), a poem of some six thousand lines on the creed of the Salaf.")
                        .font(.body)
                }

                Section(header: Text("HIS WORDS")) {
                    ScriptureQuote(text: "“In the heart is a disorder that nothing gathers except turning to Allah; in it is a loneliness that nothing removes except intimacy with Him in solitude; in it is a sorrow that nothing takes away except the joy of knowing Him and the truthfulness of dealing with Him” (Madarij as-Salikin 3/156).", arabic: "فِي الْقَلْبِ شَعَثٌ لَا يَلُمُّهُ إِلَّا الْإِقْبَالُ عَلَى اللَّهِ، وَفِيهِ وَحْشَةٌ لَا يُزِيلُهَا إِلَّا الْأُنْسُ بِهِ فِي خَلْوَتِهِ، وَفِيهِ حُزْنٌ لَا يُذْهِبُهُ إِلَّا السُّرُورُ بِمَعْرِفَتِهِ وَصِدْقِ مُعَامَلَتِهِ", dimmed: true)

                    Text("His students included **Ibn Kathir**, who said he had not seen anyone who worshipped more than him, and **Ibn Rajab al-Hanbali**, the author of Jami‘ al-‘Ulum wal-Hikam, who studied with him in his last years.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Ibn al-Qayyim took the knowledge of his teacher and wrote it for the heart. On dhikr, repentance, sin, love of Allah, and the way of the Prophet, his books are the most read of any scholar of the Salaf after the imams themselves.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ibn al-Qayyim")
        .selectableArticleList()
    }
}

struct DhahabiView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: adh-Dhahabi (673–748 AH) was the hadith master and historian who wrote the biographies of the whole nation, judging every narrator and scholar by the standard of the Salaf.")
                        .font(.body)
                }

                Section(header: Text("HIS LIFE")) {
                    Text("**Shams ad-Din Muhammad ibn Ahmad ibn Uthman adh-Dhahabi (مُحَمَّد بن أَحمَد الذَّهَبِي)** was born in 673 AH / 1274 CE in Damascus to a family of Turkmen origin; his name comes from his father’s trade in gold. He began with the Quran and its readings, then gave himself to hadith, travelling to Ba‘labakk, Aleppo, Cairo, Alexandria, Makkah, and Madinah and hearing from more than a thousand teachers.")
                        .font(.body)

                    Text("In Damascus he studied with Ibn Taymiyyah and al-Mizzi, and was appointed to teach hadith at several schools, including the Dar al-Hadith al-Ashrafiyyah. He lost his sight in his last years and died in 748 AH / 1348 CE.")
                        .font(.body)
                }

                Section(header: Text("HIS WORKS")) {
                    Text("**Siyar A‘lam an-Nubala’ (سِيَر أَعلَام النُّبَلَاء)**: the biographies of the notable figures of Islam from the Companions to his own time, in some twenty-five volumes, with his own judgements on their knowledge, creed, and character.")
                        .font(.body)
                    Text("**Tarikh al-Islam (تَارِيخ الإِسلَام)**: the history of Islam by decade with the deaths of the notable men of each, the largest work of its kind.")
                        .font(.body)
                    Text("**Mizan al-I‘tidal**: the criticised narrators of hadith, one by one, with the verdicts of the imams. **Tadhkirat al-Huffaz**: the generations of the hadith masters. **Al-Kashif** on the narrators of the six books. **Talkhis al-Mustadrak**, his check on al-Hakim’s claims of authenticity.")
                        .font(.body)
                    Text("**Al-‘Uluww lil-‘Aliyy al-Ghaffar (العُلُوّ)**: the sayings of the Salaf affirming that Allah is above His creation, gathered generation by generation; and **al-Kaba’ir**, the major sins with their evidences.")
                        .font(.body)
                }

                Section(header: Text("HIS STANDARD")) {
                    Text("Describing the qualities a hadith master needs, he wrote that he must be pious, intelligent, learned in grammar and language, upright, modest, and **Salafi** (Siyar A‘lam an-Nubala’ 13/380), and throughout his biographies he praises scholars for being upon the creed of the Salaf and records where others fell into kalam. Of his teacher Ibn Taymiyyah he wrote that his like had not been seen, while noting his own reservations with fairness; this balance is why his verdicts are trusted by all.")
                        .font(.body)

                    Text("He warned the scholars of his time against pride in knowledge, and his short treatises of advice, such as his letter to Ibn Taymiyyah on gentleness with people, show the humility the Salaf demanded of the learned.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Through adh-Dhahabi the nation knows who its scholars and narrators were, what they believed, and how far they can be trusted. He measured every one of them by the Sunnah, and he asked to be measured the same way.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Adh-Dhahabi")
        .selectableArticleList()
    }
}

struct IbnKathirView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ibn Kathir (701–774 AH) wrote the most widely read tafsir of the Quran and the great history al-Bidayah wan-Nihayah, following the method of his teacher Ibn Taymiyyah: the Quran by the Quran, then the Sunnah, then the Salaf.")
                        .font(.body)
                }

                Section(header: Text("HIS LIFE")) {
                    Text("**Imad ad-Din Isma‘il ibn Umar ibn Kathir (إِسمَاعِيل بن عُمَر بن كَثِير)** was born in 701 AH / 1301 CE in a village near Busra in Syria. His father, a preacher, died when he was a small child, and his elder brother brought him to Damascus in 706 AH, where he memorised the Quran and studied with the great scholars of the city.")
                        .font(.body)

                    Text("He was the student of **al-Mizzi**, whose daughter he married, of **Ibn Taymiyyah**, whom he loved and defended, and of **adh-Dhahabi**. A Shafi‘i in fiqh, he taught at the Umayyad Mosque and several schools and succeeded adh-Dhahabi at the Umm as-Salih school. He lost his sight at the end of his life and died in Sha‘ban 774 AH / 1373 CE. By his own wish he was buried beside his teacher Ibn Taymiyyah in the Sufi cemetery of Damascus.")
                        .font(.body)
                }

                Section(header: Text("HIS WORKS")) {
                    Text("**Tafsir al-Quran al-‘Azim (تَفسِير القُرآن العَظِيم)**: the tafsir most read by Muslims today, in which he explains each verse by other verses, then by the hadith with its grade, then by the Companions and Tabi‘un, and warns against the Israelite reports and weak narrations. He set out the method in his introduction:")
                        .font(.body)
                    ScriptureQuote(text: "“If someone asks: what is the best method of tafsir? The answer is that the soundest method is that the Quran be explained by the Quran; what is left general in one place is explained in another. If that defeats you, then by the Sunnah, for it explains the Quran and clarifies it” (Tafsir Ibn Kathir, introduction).", arabic: "فَإِنْ قَالَ قَائِلٌ: فَمَا أَحْسَنُ طُرُقِ التَّفْسِيرِ؟ فَالْجَوَابُ: إِنَّ أَصَحَّ الطُّرُقِ فِي ذَلِكَ أَنْ يُفَسَّرَ الْقُرْآنُ بِالْقُرْآنِ، فَمَا أُجْمِلَ فِي مَكَانٍ فَإِنَّهُ قَدْ فُسِّرَ فِي مَوْضِعٍ آخَرَ، فَإِنْ أَعْيَاكَ ذَلِكَ فَعَلَيْكَ بِالسُّنَّةِ فَإِنَّهَا شَارِحَةٌ لِلْقُرْآنِ وَمُوَضِّحَةٌ لَهُ", dimmed: true)

                    Text("**Al-Bidayah wan-Nihayah (البِدَايَة وَالنِّهَايَة)**, “The Beginning and the End“: the history of the world from the creation, through the prophets, the seerah in great detail, the caliphates, and the events of every year to 768 AH, ending with the signs of the Hour and the Hereafter. **Qisas al-Anbiya’** (the stories of the prophets) and **as-Sirah an-Nabawiyyah** are drawn from it.")
                        .font(.body)

                    Text("**Jami‘ al-Masanid was-Sunan**, an arrangement of the hadith of the ten books by Companion; **Ikhtisar ‘Ulum al-Hadith**, on the science of hadith; **Tabaqat ash-Shafi‘iyyah**; and a commentary on Sahih al-Bukhari left unfinished.")
                        .font(.body)
                }

                Section(header: Text("HIS PLACE")) {
                    Text("Ibn Kathir carried the knowledge of Ibn Taymiyyah and adh-Dhahabi into the two books that every later generation opened first: the tafsir and the history. In his tafsir the creed of the Salaf is stated at every verse of the attributes, and in his history the Companions are defended and the sects are exposed.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Ibn Kathir explained the Quran by the Quran, the Sunnah, and the Salaf, and told the history of the nation from the beginning to the end. No student of the Quran and no reader of the seerah is without his books.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ibn Kathir")
        .selectableArticleList()
    }
}

struct LaterScholarsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: after Ibn Taymiyyah's circle, the creed and the hadith of the Salaf were carried by scholars such as Ibn Rajab, Ibn Hajar, Muhammad ibn Abd al-Wahhab, and, in our own era, Ibn Baz, al-Albani, and Ibn al-Uthaymin.")
                        .font(.body)
                }

                Section(header: Text("THE EIGHTH AND NINTH CENTURIES")) {
                    ScholarEntry(name: "Ibn Rajab al-Hanbali", arabic: "ابن رَجَب الحَنبَلِي", meta: "736–795 AH / 1335–1393 CE · Baghdad and Damascus", description: "The student of Ibn al-Qayyim, whose Jami‘ al-‘Ulum wal-Hikam explains fifty foundational hadith, whose Fath al-Bari on Sahih al-Bukhari was left unfinished, and whose Lata’if al-Ma‘arif and Dhayl Tabaqat al-Hanabilah are read to this day. He wrote that the way of the Salaf is the truth in every matter of creed.")

                    ScholarEntry(name: "Ibn Hajar al-Asqalani", arabic: "ابن حَجَر العَسقَلَانِي", meta: "773–852 AH / 1372–1449 CE · Cairo", description: "The Commander of the Believers in hadith of his age, whose Fath al-Bari on Sahih al-Bukhari is the greatest commentary on any hadith book, with Bulugh al-Maram, Tahdhib at-Tahdhib, al-Isabah on the Companions, and Nukhbat al-Fikar. A Shafi‘i who leaned toward the Ash‘ari school in some matters, he is honoured by all of Ahl as-Sunnah for his service to the Sunnah, and he endorsed the defence of Ibn Taymiyyah.")
                }

                Section(header: Text("THE REVIVAL IN NAJD")) {
                    ScholarEntry(name: "Muhammad ibn Abd al-Wahhab", arabic: "مُحَمَّد بن عَبد الوَهَّاب", meta: "1115–1206 AH / 1703–1792 CE · Najd, Arabia", description: "A Hanbali scholar who found the people of Arabia calling upon the dead at graves and trees and returned them to tawhid with the Quran and Sunnah, in Kitab at-Tawhid, al-Usul ath-Thalathah, Kashf ash-Shubuhat, and the Nawaqid al-Islam. He wrote that he followed Imam Ahmad in fiqh and called to nothing but what the four imams called to. His call, supported by Muhammad ibn Sa‘ud, made the creed of the Salaf the creed of a state and spread its books through the nation.")

                    ScholarEntry(name: "Muhammad ibn Ali ash-Shawkani", arabic: "الشَّوكَانِي", meta: "1173–1250 AH / 1759–1834 CE · Sana‘a, Yemen", description: "The judge of Yemen who left the Zaydi school for the Sunnah, and wrote Nayl al-Awtar on the hadith of rulings, Fath al-Qadir in tafsir, and Irshad al-Fuhul on the principles of law.")
                }

                Section(header: Text("THE SCHOLARS OF OUR ERA")) {
                    ScholarEntry(name: "Abd al-Aziz ibn Baz", arabic: "عَبد العَزِيز بن بَاز", meta: "1330–1420 AH / 1910–1999 CE · Riyadh", description: "Blind from the age of twenty, the Grand Mufti of Saudi Arabia, known for his gentleness, his charity, and his fatawa, which were spread across the world, and for his patience in answering every questioner.")

                    ScholarEntry(name: "Muhammad Nasir ad-Din al-Albani", arabic: "مُحَمَّد نَاصِر الدِّين الأَلبَانِي", meta: "1332–1420 AH / 1914–1999 CE · Damascus and Amman", description: "The hadith master of the age, a watchmaker who taught himself in the Zahiriyyah library of Damascus and then graded the hadith of the Sunan and hundreds of other works: as-Silsilah as-Sahihah, as-Silsilah ad-Da‘ifah, Irwa’ al-Ghalil, and Sifat Salat an-Nabi. The grades “sahih by al-Albani“ cited in these pages are his.")

                    ScholarEntry(name: "Muhammad ibn Salih al-Uthaymin", arabic: "مُحَمَّد بن صَالِح العُثَيمِين", meta: "1347–1421 AH / 1929–2001 CE · Unayzah", description: "The teacher of the Qasim, whose explanations of al-Wasitiyyah, Kitab at-Tawhid, Riyad as-Salihin, and Bulugh al-Maram, and whose ash-Sharh al-Mumti‘ in fiqh, are the textbooks of students of knowledge today, taught with clarity and with an ease of manner remembered by all who sat with him.")

                    Text("Beside these three stood **Muqbil ibn Hadi al-Wadi‘i** in Yemen, **Muhammad Aman al-Jami** and **Ahmad an-Najmi** in the Hijaz, and their teachers and students. They differed at times in fiqh and in judgement, as scholars do, and were one in creed: the creed of the Salaf.")
                        .font(.body)
                }

                Section(header: Text("HOW TO TAKE FROM THE SCHOLARS")) {
                    Text("A scholar is followed for his evidence, not for himself. Imam Malik said that everyone’s words may be accepted or rejected except those of the one in the Prophet’s grave, and every imam after him said the same. So the Muslim learns from the scholars of the Sunnah with respect, asks them what he does not know, and keeps the Quran and Sunnah as the final word for all of them:")
                        .font(.body)
                    ScriptureQuote(text: "“And it is not for the believers to go forth [to battle] all at once. For there should separate from every division of them a group [remaining] to obtain understanding in the religion and warn their people when they return to them that they might be cautious” (Quran 9:122).", arabic: "وَمَا كَانَ ٱلۡمُؤۡمِنُونَ لِيَنفِرُواْ كَآفَّةٗۚ فَلَوۡلَا نَفَرَ مِن كُلِّ فِرۡقَةٖ مِّنۡهُمۡ طَآئِفَةٞ لِّيَتَفَقَّهُواْ فِي ٱلدِّينِ وَلِيُنذِرُواْ قَوۡمَهُمۡ إِذَا رَجَعُوٓاْ إِلَيۡهِمۡ لَعَلَّهُمۡ يَحۡذَرُونَ")
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Are the scholars infallible?**")
                        .font(.body)
                    Text("No. Only the Prophet (peace be upon him) is protected from error in what he conveys from Allah; every scholar after him is right at times and wrong at times, and is followed only as far as he follows the evidence. Allah made the Quran and the Sunnah, not any man, the court of appeal:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you disagree over anything, refer it to Allah and the Messenger, if you should believe in Allah and the Last Day” (Quran 4:59).", arabic: "فَإِن تَنَٰزَعۡتُمۡ فِي شَيۡءٖ فَرُدُّوهُ إِلَى ٱللَّهِ وَٱلرَّسُولِ إِن كُنتُمۡ تُؤۡمِنُونَ بِٱللَّهِ وَٱلۡيَوۡمِ ٱلۡأٓخِرِۚ")
                    Text("The Companions said this first. When people answered a hadith with the opinion of Abu Bakr and Umar, Ibn Abbas (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Stones are about to rain down on you from the sky! I say, ‘the Messenger of Allah (peace be upon him) said,’ and you say, ‘Abu Bakr and Umar said’” (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm wa Fadlih; Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "يُوشِكُ أَنْ تَنْزِلَ عَلَيْكُمْ حِجَارَةٌ مِنَ السَّمَاءِ، أَقُولُ: قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم، وَتَقُولُونَ: قَالَ أَبُو بَكْرٍ وَعُمَرُ", dimmed: true)
                    Text("The imams said the same of themselves. Malik’s saying that everyone’s words may be accepted or rejected except those of the one in the Prophet’s grave (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm wa Fadlih) is given above. Ash-Shafi‘i (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The Muslims are agreed that whoever has a Sunnah of the Messenger of Allah (peace be upon him) made clear to him is not permitted to leave it for the saying of anyone” (Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "أَجْمَعَ الْمُسْلِمُونَ عَلَى أَنَّ مَنِ اسْتَبَانَتْ لَهُ سُنَّةٌ عَنْ رَسُولِ اللَّهِ صلى الله عليه وسلم لَمْ يَحِلَّ لَهُ أَنْ يَدَعَهَا لِقَوْلِ أَحَدٍ", dimmed: true)
                    Text("And Ahmad (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not imitate me, nor Malik, nor ash-Shafi‘i, nor al-Awza‘i, nor ath-Thawri; take from where they took” (Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "لَا تُقَلِّدْنِي وَلَا تُقَلِّدْ مَالِكًا وَلَا الشَّافِعِيَّ وَلَا الْأَوْزَاعِيَّ وَلَا الثَّوْرِيَّ، وَخُذْ مِنْ حَيْثُ أَخَذُوا", dimmed: true)
                    Text("Ibn Taymiyyah devoted a treatise, Raf‘ al-Malam ‘an al-A’immat al-A‘lam, to explaining why the imams sometimes ruled against a hadith: it had not reached them, or they did not judge it authentic, or they understood it differently, or they held it abrogated. Their error is excused and rewarded, but it is not followed once the evidence is known.")
                        .font(.body)

                    Text("**Whom do I follow when the scholars differ?**")
                        .font(.body)
                    Text("The evidence, and the scholar who shows it to you. Allah commanded that matters be returned to those able to draw conclusions from the texts:")
                        .font(.body)
                    ScriptureQuote(text: "“But if they had referred it back to the Messenger or to those of authority among them, then the ones who [can] draw correct conclusions from it would have known about it” (Quran 4:83).", arabic: "وَلَوۡ رَدُّوهُ إِلَى ٱلرَّسُولِ وَإِلَىٰٓ أُوْلِي ٱلۡأَمۡرِ مِنۡهُمۡ لَعَلِمَهُ ٱلَّذِينَ يَسۡتَنۢبِطُونَهُۥ مِنۡهُمۡۗ")
                    Text("A layman is not asked to weigh the proofs himself; he asks the most knowledgeable and God-fearing scholar he can reach, and when he can understand the evidence he follows what it supports, even against his own teacher. Difference among scholars is not a licence to pick the easiest opinion: Sulayman at-Taymi (may Allah have mercy on him) said that if you take the concession of every scholar, all evil gathers in you (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm wa Fadlih). And the scholar who errs after striving is not sinning. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“When a judge gives a ruling, striving to reach the truth, and is correct, he has two rewards; and when he gives a ruling, striving, and errs, he has one reward” (Sahih al-Bukhari 7352).", arabic: "إِذَا حَكَمَ الْحَاكِمُ فَاجْتَهَدَ ثُمَّ أَصَابَ فَلَهُ أَجْرَانِ، وَإِذَا حَكَمَ فَاجْتَهَدَ ثُمَّ أَخْطَأَ فَلَهُ أَجْرٌ", dimmed: true)
                    Text("So difference among the scholars is not a reason to abandon all of them, nor to follow desire under the name of choice. Ask the best you can reach, follow the proof when it is clear, and do not make the differences of the scholars a religion of your own.")
                        .font(.body)

                    Text("**Was Ibn Taymiyyah an anthropomorphist (mujassim)?**")
                        .font(.body)
                    Text("No. The charge was made by his opponents in his lifetime and answered in his lifetime. His own creed, al-Aqidah al-Wasitiyyah, lays down at its beginning:")
                        .font(.body)
                    ScriptureQuote(text: "“Part of faith in Allah is faith in what He has described Himself with in His Book and in what His Messenger Muhammad (peace be upon him) has described Him with, without distortion (tahrif) or denial (ta‘til), and without asking how (takyif) or likening (tamthil)” (Ibn Taymiyyah, al-Aqidah al-Wasitiyyah).", arabic: "وَمِنَ الإِيمَانِ بِاللَّهِ: الإِيمَانُ بِمَا وَصَفَ بِهِ نَفْسَهُ فِي كِتَابِهِ، وَبِمَا وَصَفَهُ بِهِ رَسُولُهُ مُحَمَّدٌ صلى الله عليه وسلم، مِنْ غَيْرِ تَحْرِيفٍ وَلَا تَعْطِيلٍ، وَمِنْ غَيْرِ تَكْيِيفٍ وَلَا تَمْثِيلٍ", dimmed: true)
                    Text("He then cites the verse that is the foundation of the whole creed:")
                        .font(.body)
                    ScriptureQuote(text: "“There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).", arabic: "لَيۡسَ كَمِثۡلِهِۦ شَيۡءٞۖ وَهُوَ ٱلسَّمِيعُ ٱلۡبَصِيرُ")
                    Text("A mujassim (مُجَسِّم), from jism (جِسم), “body,“ is one who likens Allah to the bodies of His creation. A man who affirms the attributes exactly as Allah affirmed them and denies any likeness exactly as Allah denied it is not a mujassim; he is on the way of the Salaf. In 705 AH al-Wasitiyyah was examined in three public sessions in Damascus before the judges and scholars of the city, and nothing against the Sunnah was found in it; Ibn Abd al-Hadi records the sessions in al-‘Uqud ad-Durriyyah and Ibn Kathir in al-Bidayah wan-Nihayah. When a later writer claimed that whoever called him Shaykh al-Islam was a disbeliever, Ibn Nasir ad-Din ad-Dimashqi replied with ar-Radd al-Wafir, gathering the words of more than eighty scholars of every school who had given him that title, and Ibn Hajar wrote an endorsement of the book. Adh-Dhahabi, who knew him for years, wrote that he had not seen his like (see the page “Ibn Taymiyyah“).")
                        .font(.body)

                    Text("**Did Ibn Taymiyyah hate Ali or the Ahlul Bayt?**")
                        .font(.body)
                    Text("No. Minhaj as-Sunnah is a reply to a Rafidi book, and it refutes the exaggeration about Ali, not Ali. In it Ibn Taymiyyah affirms Ali’s virtues, his caliphate as the fourth of the rightly guided, and that he was nearer to the truth than those who fought him, citing the Prophet’s words about Ammar, who was killed in Ali’s army at Siffin:")
                        .font(.body)
                    ScriptureQuote(text: "“A band of rebels will kill Ammar” (Sahih Muslim 2916).", arabic: "تَقْتُلُ عَمَّارًا الْفِئَةُ الْبَاغِيَةُ", dimmed: true)
                    Text("In al-Wasitiyyah he writes that Ahl as-Sunnah:")
                        .font(.body)
                    ScriptureQuote(text: "“love the People of the House of the Messenger of Allah (peace be upon him), take them as allies, and keep the will of the Messenger of Allah (peace be upon him) concerning them” (Ibn Taymiyyah, al-Aqidah al-Wasitiyyah).", arabic: "وَيُحِبُّونَ أَهْلَ بَيْتِ رَسُولِ اللَّهِ صلى الله عليه وسلم وَيَتَوَلَّوْنَهُمْ، وَيَحْفَظُونَ فِيهِمْ وَصِيَّةَ رَسُولِ اللَّهِ صلى الله عليه وسلم", dimmed: true)
                    Text("This is the creed of every Sunni, for Ali (may Allah be pleased with him) reported the Prophet’s promise:")
                        .font(.body)
                    ScriptureQuote(text: "“It is a promise of the unlettered Prophet (peace be upon him) to me that none loves me but a believer and none hates me but a hypocrite” (Sahih Muslim 78).", arabic: "إِنَّهُ لَعَهْدُ النَّبِيِّ الأُمِّيِّ صلى الله عليه وسلم إِلَىَّ أَنْ لاَ يُحِبَّنِي إِلاَّ مُؤْمِنٌ وَلاَ يُبْغِضَنِي إِلاَّ مُنَافِقٌ", dimmed: true)
                    Text("Imam Ahmad said that whoever does not affirm the caliphate of Ali is more astray than his family’s donkey (al-Khallal, as-Sunnah; Ibn Abi Ya‘la, Tabaqat al-Hanabilah), and Ibn Taymiyyah, a Hanbali, followed him in this. He was called an enemy of Ali by those whose claims against the other Companions he refused to accept; refusing to curse the Companions is a mark of the Sunnah, not of hatred.")
                        .font(.body)

                    Text("**Why do Salafis respect an-Nawawi and Ibn Hajar although they interpreted some attributes?**")
                        .font(.body)
                    Text("Because justice is a command, and a man is judged by the whole of his work. An-Nawawi and Ibn Hajar (may Allah have mercy on them) gave the nation Sharh Sahih Muslim, Riyad as-Salihin, the Forty Hadith, Fath al-Bari, and Bulugh al-Maram; their service to the Sunnah is beyond calculation. In some matters of the divine attributes they followed the interpretation (ta’wil) of the Ash‘ari school that dominated their time, and in this they erred; the Salafi does not follow them in it, and says so openly. But he does not throw away the imam because of a mistake. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not let the hatred of a people prevent you from being just. Be just; that is nearer to righteousness” (Quran 5:8).", arabic: "وَلَا يَجۡرِمَنَّكُمۡ شَنَـَٔانُ قَوۡمٍ عَلَىٰٓ أَلَّا تَعۡدِلُواْۚ ٱعۡدِلُواْ هُوَ أَقۡرَبُ لِلتَّقۡوَىٰۖ")
                    Text("Adh-Dhahabi wrote in Siyar A‘lam an-Nubala’, in the biography of the imam Muhammad ibn Nasr al-Marwazi:")
                        .font(.body)
                    ScriptureQuote(text: "“If every time an imam erred in his ijtihad in a single matter, with an error that is forgiven him, we rose against him, called him an innovator, and abandoned him, then neither Ibn Nasr nor Ibn Mandah nor those greater than them would be safe with us” (adh-Dhahabi, Siyar A‘lam an-Nubala’).", arabic: "وَلَوْ أَنَّا كُلَّمَا أَخْطَأَ إِمَامٌ فِي اجْتِهَادِهِ فِي آحَادِ الْمَسَائِلِ خَطَأً مَغْفُورًا لَهُ، قُمْنَا عَلَيْهِ وَبَدَّعْنَاهُ وَهَجَرْنَاهُ، لَمَا سَلِمَ مَعَنَا لَا ابْنُ نَصْرٍ وَلَا ابْنُ مَنْدَهْ وَلَا مَنْ هُوَ أَكْبَرُ مِنْهُمَا", dimmed: true)
                    Text("Ibn Baz and Ibn al-Uthaymin (may Allah have mercy on them), when asked about the two, answered in the same spirit: they are imams of Ahl as-Sunnah whose good is immense, who erred in the interpretation of some attributes, and whose error is not followed. The rule is that of Ahl as-Sunnah in every age: take the truth from whoever brings it, leave the error of whoever falls into it, and ask Allah’s mercy for the scholars.")
                        .font(.body)

                    Text("**How do I know a scholar is trustworthy?**")
                        .font(.body)
                    Text("By the same test the Salaf applied to narrators. Muhammad ibn Sirin (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“This knowledge is religion, so look from whom you take your religion” (Muqaddimah of Sahih Muslim).", arabic: "إِنَّ هَذَا الْعِلْمَ دِينٌ، فَانْظُرُوا عَمَّنْ تَأْخُذُونَ دِينَكُمْ", dimmed: true)
                    Text("Look for four things. Sound creed: he affirms the names and attributes as they came, honours the Companions, and does not call to any sect. Knowledge of the texts: he speaks from the Quran and the Sunnah with their evidences, not from stories and opinions. A chain of teachers: he sat before known scholars of the Sunnah and they know him, for knowledge is transmission, and the Prophet (peace be upon him) warned that when the scholars are gone people take ignorant heads who give verdicts without knowledge (Sahih al-Bukhari 100). And practice: his fear of Allah shows in his conduct, for Allah says that the knowledgeable are the ones who fear Him (Quran 35:28). A man with a title, a following, or eloquence but without these is not a scholar, however many listen to him.")
                        .font(.body)

                    Text("**Is taking from the scholars blind imitation (taqlid)?**")
                        .font(.body)
                    Text("No, when it is done as Allah commanded. Taqlid (تَقلِيد) is to accept a ruling without knowing its evidence, and the one who does not know is ordered to do exactly that: ask the one who knows:")
                        .font(.body)
                    ScriptureQuote(text: "“So ask the people of the message if you do not know” (Quran 16:43).", arabic: "فَسۡـَٔلُوٓاْ أَهۡلَ ٱلذِّكۡرِ إِن كُنتُمۡ لَا تَعۡلَمُونَ")
                    Text("The command is repeated in Surat al-Anbiya (Quran 21:7). Ibn Abd al-Barr writes in Jami‘ Bayan al-‘Ilm that the scholars do not differ that the common people must follow their scholars in what befalls them, since they cannot see where the proof lies, and Ibn al-Qayyim discusses in I‘lam al-Muwaqqi‘in the saying that the layman’s madhhab is the madhhab of his mufti. Blameworthy taqlid is something else: clinging to a man’s opinion after the proof against it is known, or taking a scholar as the measure of truth instead of the texts. Allah condemned the People of the Book for exactly this:")
                        .font(.body)
                    ScriptureQuote(text: "“They have taken their scholars and monks as lords besides Allah” (Quran 9:31).", arabic: "ٱتَّخَذُوٓاْ أَحۡبَارَهُمۡ وَرُهۡبَٰنَهُمۡ أَرۡبَابٗا مِّن دُونِ ٱللَّهِ")
                    Text("Ibn Kathir explains in his tafsir that they did not worship them, but obeyed them when they made the unlawful lawful and the lawful unlawful. So the Salafi asks the scholars, accepts their answer, and asks for the evidence when he can understand it, and the scholars of the Sunnah are the first to give it.")
                        .font(.body)

                    Text("**Were the four imams upon the creed of the Salaf?**")
                        .font(.body)
                    Text("Yes, and their own words prove it. The creed of Abu Hanifah is preserved in al-Fiqh al-Akbar and in the creed of at-Tahawi, who wrote it as the belief of Abu Hanifah and his two companions Abu Yusuf and Muhammad ibn al-Hasan. Malik was asked how Allah rose over the Throne and replied:")
                        .font(.body)
                    ScriptureQuote(text: "“The rising is not unknown, the how of it is beyond reason, belief in it is obligatory, and asking about it is innovation” (al-Lalaka’i, Sharh Usul I‘tiqad Ahl as-Sunnah 664; al-Bayhaqi, al-Asma’ was-Sifat 867).", arabic: "الِاسْتِوَاءُ غَيْرُ مَجْهُولٍ، وَالْكَيْفُ غَيْرُ مَعْقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنْهُ بِدْعَةٌ", dimmed: true)
                    Text("Ash-Shafi‘i said:")
                        .font(.body)
                    ScriptureQuote(text: "“I believe in Allah and in what came from Allah as Allah intended it, and I believe in the Messenger of Allah and in what came from the Messenger of Allah as the Messenger of Allah intended it” (Ibn Qudamah, Lum‘at al-I‘tiqad).", arabic: "آمَنْتُ بِاللَّهِ وَبِمَا جَاءَ عَنِ اللَّهِ عَلَى مُرَادِ اللَّهِ، وَآمَنْتُ بِرَسُولِ اللَّهِ وَبِمَا جَاءَ عَنْ رَسُولِ اللَّهِ عَلَى مُرَادِ رَسُولِ اللَّهِ", dimmed: true)
                    Text("And Ahmad’s Usul as-Sunnah, quoted on the page “Madhahib of Aqeedah,“ is the creed of the Salaf set down line by line. All four affirmed the attributes without asking how, held that the Quran is the speech of Allah and not created, and honoured all the Companions. Malik, ash-Shafi‘i, and Ahmad held that faith is speech and action, increasing and decreasing; Abu Hanifah expressed the matter differently, and Ibn Taymiyyah explains in Kitab al-Iman that much of that dispute was one of wording, since he too held that the disobedient believer is under the threat of punishment. The kalam schools that later attached themselves to the names of the imams came after them and differed from them.")
                        .font(.body)

                    Text("**Which books should a beginner start with?**")
                        .font(.body)
                    Text("Begin with creed, then the Sunnah, then rulings, and take each with a teacher or a reliable explanation. In creed: al-Usul ath-Thalathah (the three fundamentals: who is your Lord, what is your religion, who is your Prophet) and Kitab at-Tawhid of Muhammad ibn Abd al-Wahhab, then al-Aqidah al-Wasitiyyah of Ibn Taymiyyah, with the explanations of Ibn al-Uthaymin. In hadith: the Forty of an-Nawawi, then Riyad as-Salihin, then Umdat al-Ahkam and Bulugh al-Maram for the hadith of rulings. In tafsir: Tafsir Ibn Kathir, or the short tafsir of as-Sa‘di. Read a little every day, memorise what you can, act on what you learn, and make the Prophet’s supplication your own:")
                        .font(.body)
                    ScriptureQuote(text: "“And say, ‘My Lord, increase me in knowledge’” (Quran 20:114).", arabic: "وَقُل رَّبِّ زِدۡنِي عِلۡمٗا")

                    Text("**Why were Ahmad and Ibn Taymiyyah imprisoned if they were upon the truth?**")
                        .font(.body)
                    Text("Because trial is the lot of those who hold to the truth, not a sign against it. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“Do the people think that they will be left to say, ‘We believe’ and they will not be tried? But We have certainly tried those before them, and Allah will surely make evident those who are truthful, and He will surely make evident the liars” (Quran 29:2-3).", arabic: "أَحَسِبَ ٱلنَّاسُ أَن يُتۡرَكُوٓاْ أَن يَقُولُوٓاْ ءَامَنَّا وَهُمۡ لَا يُفۡتَنُونَ ۝ وَلَقَدۡ فَتَنَّا ٱلَّذِينَ مِن قَبۡلِهِمۡۖ فَلَيَعۡلَمَنَّ ٱللَّهُ ٱلَّذِينَ صَدَقُواْ وَلَيَعۡلَمَنَّ ٱلۡكَٰذِبِينَ")
                    Text("The Prophet (peace be upon him) was asked which people are tried most severely and said:")
                        .font(.body)
                    ScriptureQuote(text: "“The Prophets, then those nearest to them, then those nearest to them. A man is tried according to his religion; if he is firm in his religion, then his trials are more severe” (Sunan al-Tirmidhi 2398; graded hasan sahih by al-Albani).", arabic: "الأَنْبِيَاءُ ثُمَّ الأَمْثَلُ فَالأَمْثَلُ فَيُبْتَلَى الرَّجُلُ عَلَى حَسَبِ دِينِهِ فَإِنْ كَانَ دِينُهُ صُلْبًا اشْتَدَّ بَلاَؤُهُ", dimmed: true)
                    Text("Ahmad was imprisoned and flogged in the Mihnah, the inquisition of 218 to 234 AH in which the caliphs al-Ma’mun, al-Mu‘tasim, and al-Wathiq forced the Mu‘tazili doctrine that the Quran is created upon the scholars; he refused, and when al-Mutawakkil ended the trial the nation called him the Imam of Ahl as-Sunnah. Ibn Taymiyyah’s al-Wasitiyyah was cleared by the councils of Damascus in 705 AH, yet his opponents had him summoned to Cairo, where he was imprisoned over his creed from 705 to 707 AH; he was imprisoned in Damascus in 720 AH over his ruling that a triple divorce pronounced at once counts as one, and finally in 726 AH over his ruling that setting out on a journey only to visit graves is not legislated; he died in the citadel in 728 AH. Before them Abu Hanifah was imprisoned for refusing the judgeship and Malik was flogged, and the Prophet (peace be upon him) himself was driven from Makkah. Allah says that the believers before us were shaken until the Messenger and those with him said, “When is the help of Allah?“ (Quran 2:214). Prison did not harm the truth they carried; it is the books of their opponents that are forgotten.")
                        .font(.body)

                    Text("**Is knowledge only for scholars?**")
                        .font(.body)
                    Text("No. Every Muslim must learn what his worship requires: the meaning of the testimony of faith, how to purify and pray, what to fast and give, and the rulings of whatever trade or situation he is in; this is obligatory on each individual, as Ibn Abd al-Barr explains in Jami‘ Bayan al-‘Ilm. Beyond that, becoming a scholar is a communal obligation which some must fulfil for all, as the verse of Surat at-Tawbah above lays down. And every Muslim carries what he has learned to others. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Convey from me, even if it were a single sentence” (Sahih al-Bukhari 3461).", arabic: "بَلِّغُوا عَنِّي وَلَوْ آيَةً", dimmed: true)
                    Text("Every step on the road is rewarded:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever treads a path in search of knowledge, Allah will make easy for him thereby a path to Paradise” (Sahih Muslim 2699).", arabic: "وَمَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ", dimmed: true)
                    Text("The Companions were farmers, traders, and soldiers, and they were the most knowledgeable of the nation, because they learned a little and acted on it before they learned more. Knowledge is for everyone who seeks it; the rank of scholar is for those who give their lives to it.")
                        .font(.body)

                    Text("**Who are the scholars of our time we can rely on?**")
                        .font(.body)
                    Text("This page names three whose knowledge, creed, and character the scholars of the Sunnah have agreed upon and who have gone to their Lord: Ibn Baz, al-Albani, and Ibn al-Uthaymin (may Allah have mercy on them), with those named beside them. Their books, fatawa, and recorded lessons remain, and they are the safest starting point for a student today, together with the scholars of the Sunnah who learned from them. Abdullah ibn Mas‘ud (may Allah be pleased with him) gave the principle:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever would follow a way, let him follow the way of one who has died, for the living is not safe from trial; those are the Companions of Muhammad (peace be upon him)” (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm wa Fadlih).", arabic: "مَنْ كَانَ مُسْتَنًّا فَلْيَسْتَنَّ بِمَنْ قَدْ مَاتَ، فَإِنَّ الْحَيَّ لَا تُؤْمَنُ عَلَيْهِ الْفِتْنَةُ، أُولَئِكَ أَصْحَابُ مُحَمَّدٍ صلى الله عليه وسلم", dimmed: true)
                    Text("For the living, apply the test given above: sound creed, knowledge of the texts, a known chain of teachers, and practice, and ask the people of the Reminder when you do not know, as Allah commanded in the verse of Surat an-Nahl quoted above. The names change from age to age; the test does not.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The chain never broke. From Ibn Rajab and Ibn Hajar to the revival in Najd and the scholars of the last century, the creed of the Salaf and the science of hadith were handed down teacher to student, and the same is asked of the student today: take the evidence, honour the scholars, and follow the Prophet.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Later Scholars")
        .selectableArticleList()
    }
}
