import SwiftUI

/// The schools of creed: what aqeedah is, why there is only one, the creed of the Salaf (Athari) and the
/// schools of kalam (Ash'ari, Maturidi, Mu'tazilah) beside the rejected Khawarij. Sits beneath the
/// Madhahib of Fiqh in the Historical & Biographical list.
struct AqeedahMadhabView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text("In short: fiqh may have several valid opinions, but aqeedah is one. The creed of the Salaf, the Athari creed, is the creed of the Prophet, his Companions, and every prophet before him; the Ash'ari and Maturidi schools are later schools of kalam that Sunnis broadly count among themselves while disagreeing with them, and the Mu'tazilah and Khawarij are rejected by all.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT IS AQEEDAH?")) {
                    Text("**Aqeedah (عَقِيدَة)** comes from the root **ع-ق-د**, “to tie“ or “to knot.“ The **aqd (عَقد)** is a knot, and a **contract** is called an aqd because it binds. Aqeedah is what the heart is knotted upon: the beliefs a Muslim holds with certainty about Allah, His angels, His books, His messengers, the Last Day, and the divine decree.")
                        .font(.body)

                    Text("It is the answer to “what do you believe?“, as opposed to **fiqh (فِقه)**, “understanding,“ which answers “what do you do, and how?“: prayer, fasting, trade, marriage, and the rest of the practical rulings.")
                        .font(.body)

                    ScriptureQuote(text: "“The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All of them have believed in Allah and His angels and His books and His messengers, [saying], ‘We make no distinction between any of His messengers’” (Quran 2:285).", arabic: "ءَامَنَ ٱلرَّسُولُ بِمَآ أُنزِلَ إِلَيۡهِ مِن رَّبِّهِۦ وَٱلۡمُؤۡمِنُونَۚ كُلٌّ ءَامَنَ بِٱللَّهِ وَمَلَٰٓئِكَتِهِۦ وَكُتُبِهِۦ وَرُسُلِهِۦ لَا نُفَرِّقُ بَيۡنَ أَحَدٖ مِّن رُّسُلِهِۦۚ")

                    Text("When Jibril (peace be upon him) asked the Prophet (peace be upon him) about faith, he answered:")
                        .font(.body)
                    ScriptureQuote(text: "“That you affirm your faith in Allah, in His angels, in His Books, in His Apostles, in the Day of Judgment, and you affirm your faith in the Divine Decree about good and evil” (Sahih Muslim 8).", arabic: "أَنْ تُؤْمِنَ بِاللَّهِ وَمَلاَئِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ وَالْيَوْمِ الآخِرِ وَتُؤْمِنَ بِالْقَدَرِ خَيْرِهِ وَشَرِّهِ", dimmed: true)
                }

                Section(header: ArticleHeader("ONE AQEEDAH, MANY FIQH OPINIONS")) {
                    Text("Fiqh can carry more than one valid answer. The Companions (may Allah be pleased with them) themselves differed in fiqh in the Prophet’s own lifetime, and he approved both sides. After the Battle of the Trench he said:")
                        .font(.body)
                    ScriptureQuote(text: "“None should offer the 'Asr prayer but at Bani Quraiza.’ The 'Asr prayer became due for some of them on the way. Some of them decided not to offer the Salat but at Bani Quraiza while others decided to offer the Salat on the spot and said that the intention of the Prophet (ﷺ) was not what the former party had understood. And when that was told to the Prophet (ﷺ) he did not blame anyone of them” (Sahih al-Bukhari 946).", arabic: "قَالَ النَّبِيُّ صلى الله عليه وسلم لَنَا لَمَّا رَجَعَ مِنَ الأَحْزَابِ لاَ يُصَلِّيَنَّ أَحَدٌ الْعَصْرَ إِلاَّ فِي بَنِي قُرَيْظَةَ. فَأَدْرَكَ بَعْضُهُمُ الْعَصْرَ فِي الطَّرِيقِ فَقَالَ بَعْضُهُمْ لاَ نُصَلِّي حَتَّى نَأْتِيَهَا، وَقَالَ بَعْضُهُمْ بَلْ نُصَلِّي لَمْ يُرَدْ مِنَّا ذَلِكَ. فَذُكِرَ لِلنَّبِيِّ صلى الله عليه وسلم فَلَمْ يُعَنِّفْ وَاحِدًا مِنْهُمْ", dimmed: true)

                    Text("One group took his words literally and delayed the prayer; the other understood them to mean “hurry,“ and prayed on time. Both were sincere, both reasoned from his command, and he rebuked neither. This is fiqh: sincere, qualified effort in understanding, where more than one answer can be acceptable.")
                        .font(.body)

                    Text("Aqeedah is different. There is no “two valid opinions“ on whether Allah is One, whether the Quran is His speech, or whether He will be seen in Paradise. Creed is fixed by revelation, and it never changed from the first prophet to the last:")
                        .font(.body)

                    ScriptureQuote(text: "“And We sent not before you any messenger except that We revealed to him that, ‘There is no deity except Me, so worship Me’” (Quran 21:25).", arabic: "وَمَآ أَرۡسَلۡنَا مِن قَبۡلِكَ مِن رَّسُولٍ إِلَّا نُوحِيٓ إِلَيۡهِ أَنَّهُۥ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعۡبُدُونِ")

                    ScriptureQuote(text: "“He has ordained for you of religion what He enjoined upon Noah and that which We have revealed to you, [O Muhammad], and what We enjoined upon Abraham and Moses and Jesus - to establish the religion and not be divided therein” (Quran 42:13).", arabic: "شَرَعَ لَكُم مِّنَ ٱلدِّينِ مَا وَصَّىٰ بِهِۦ نُوحٗا وَٱلَّذِيٓ أَوۡحَيۡنَآ إِلَيۡكَ وَمَا وَصَّيۡنَا بِهِۦٓ إِبۡرَٰهِيمَ وَمُوسَىٰ وَعِيسَىٰٓۖ أَنۡ أَقِيمُواْ ٱلدِّينَ وَلَا تَتَفَرَّقُواْ فِيهِۚ")

                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The prophets are paternal brothers; their mothers are different, but their religion is one” (Sahih al-Bukhari 3443, Sahih Muslim 2365).", arabic: "وَالأَنْبِيَاءُ إِخْوَةٌ لِعَلاَّتٍ، أُمَّهَاتُهُمْ شَتَّى، وَدِينُهُمْ وَاحِدٌ", dimmed: true)

                    Text("So Nuh, Ibrahim, Musa, Isa, and Muhammad (peace be upon them all) had one and the same aqeedah, with different laws (shari‘ah). Abu Bakr, Umar, Uthman, Ali, Ibn Mas‘ud, Ibn Abbas, Aisha, and all the senior Companions had one creed; the Ahlul Bayt (the Prophet’s wives, Ali, Fatimah, al-Hasan, al-Husayn, and the rest of his household) had that same creed; and the Companions differed among themselves in fiqh without ever splitting over creed. That single creed is what the schools below are measured against.")
                        .font(.body)
                }

                Section(header: ArticleHeader("TWO ROADS: ATHAR AND KALAM")) {
                    Text("Every school of creed in Islamic history walks one of two roads.")
                        .font(.body)

                    Text("**1. The road of athar (أَثَر, “narration“ or “track“)**: creed is taken from the Quran, the Sunnah, and the reports of the Companions, and the mind submits to the text. Whatever Allah affirmed for Himself is affirmed as He said it, without asking how, and whatever He negated is negated.")
                        .font(.body)

                    Text("**2. The road of kalam (عِلم الكَلَام, from the root ك-ل-م, speech: “speculative theology,“ named for the arguing it consists of)**: creed is argued from rational premises, many of them inherited from Greek philosophy, which entered Muslim lands through the translation movement of the second and third centuries AH. The text is then reinterpreted to fit the conclusions of reason.")
                        .font(.body)

                    Text("The Salaf (السَّلَف, from the root س-ل-ف: those who have gone before, meaning the first three generations) warned against the second road before it even had a name. Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“As for those in whose hearts is deviation [from truth], they will follow that of it which is unspecific, seeking discord and seeking an interpretation [suitable to them]” (Quran 3:7).", arabic: "فَأَمَّا ٱلَّذِينَ فِي قُلُوبِهِمۡ زَيۡغٞ فَيَتَّبِعُونَ مَا تَشَٰبَهَ مِنۡهُ ٱبۡتِغَآءَ ٱلۡفِتۡنَةِ وَٱبۡتِغَآءَ تَأۡوِيلِهِۦۖ")

                    Text("Aisha (may Allah be pleased with her) said the Prophet (peace be upon him) recited this verse and then said:")
                        .font(.body)
                    ScriptureQuote(text: "“If you see those who follow thereof that is not entirely clear, then they are those whom Allah has named [as having deviation (from the Truth)] 'So beware of them” (Sahih al-Bukhari 4547).", arabic: "فَإِذَا رَأَيْتَ الَّذِينَ يَتَّبِعُونَ مَا تَشَابَهَ مِنْهُ، فَأُولَئِكَ الَّذِينَ سَمَّى اللَّهُ، فَاحْذَرُوهُمْ", dimmed: true)

                    Text("The Prophet (peace be upon him) also said:")
                        .font(.body)
                    ScriptureQuote(text: "“Controverting about the Qur'an is disbelief” (Sunan Abi Dawud 4603; graded hasan sahih by al-Albani).", arabic: "الْمِرَاءُ فِي الْقُرْآنِ كُفْرٌ", dimmed: true)

                    Text("When a man asked Imam Malik (may Allah have mercy on him) how Allah rose over the Throne, he answered with the rule that defines the road of athar:")
                        .font(.body)
                    ScriptureQuote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asma' was-Sifat 867; al-Lalaka'i 664).", arabic: "الِاسْتِوَاءُ غَيْرُ مَجْهُولٍ، وَالْكَيْفُ غَيْرُ مَعْقُولٍ، وَالْإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنْهُ بِدْعَةٌ", dimmed: true)

                    Text("Imam al-Shafi‘i (may Allah have mercy on him) said of the people of kalam:")
                        .font(.body)
                    ScriptureQuote(text: "“My ruling on the people of kalam is that they be beaten with palm branches and sandals and paraded among the clans and tribes, and it be said: this is the reward of one who left the Book and the Sunnah and took up kalam” (Ibn Abi Hatim, Adab al-Shafi'i 182; adh-Dhahabi, Siyar 10/29).", arabic: "حُكْمِي فِي أَهْلِ الْكَلَامِ أَنْ يُضْرَبُوا بِالْجَرِيدِ وَالنِّعَالِ، وَيُطَافَ بِهِمْ فِي الْعَشَائِرِ وَالْقَبَائِلِ، وَيُقَالَ: هَذَا جَزَاءُ مَنْ تَرَكَ الْكِتَابَ وَالسُّنَّةَ وَأَخَذَ فِي الْكَلَامِ", dimmed: true)
                }

                Section(header: ArticleHeader("THE CREED OF THE SALAF: THE ATHARI SCHOOL")) {
                    Text("The **Athari (الأَثَرِي)** creed is named after **athar**, narration, not after a person. Its people were called **Ahl al-Hadith (أَهل الحَدِيث)**, **Ahl al-Athar (أَهل الأَثَر)**, and **Ahl as-Sunnah (أَهل السُّنَّة)**. It is simply the creed of the Prophet (peace be upon him) and his Companions, written down and defended when the sects appeared.")
                        .font(.body)

                    Text("Its imam is **Ahmad ibn Hanbal (أَحمَد بن حَنبَل)** (164–241 AH / 780–855 CE), the **Imam of Ahl as-Sunnah**, who left behind both a madhhab of fiqh, the Hanbali school, and one of the earliest written creeds of Ahl as-Sunnah, the **Usul as-Sunnah**, dictated to his student Abdus ibn Malik al-Attar. He did not invent a creed; he preserved one. His own words describe what the school is:")
                        .font(.body)
                    ScriptureQuote(text: "“The foundations of the Sunnah with us are: holding fast to what the Companions of the Messenger of Allah were upon, taking them as an example, abandoning innovations; and every innovation is misguidance” (Ahmad ibn Hanbal, Usul as-Sunnah; al-Lalaka'i 317).", arabic: "أُصُولُ السُّنَّةِ عِنْدَنَا: التَّمَسُّكُ بِمَا كَانَ عَلَيْهِ أَصْحَابُ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَالِاقْتِدَاءُ بِهِمْ، وَتَرْكُ الْبِدَعِ، وَكُلُّ بِدْعَةٍ فَهِيَ ضَلَالَةٌ", dimmed: true)

                    Text("**The Mihnah (المِحنَة, “the Inquisition“)**: in 218 AH the caliph al-Ma’mun adopted the Mu‘tazili doctrine that the Quran is created and forced the scholars to profess it. Under him, al-Mu‘tasim, and al-Wathiq (218–234 AH), Imam Ahmad was chained, imprisoned for about two years, and flogged until he lost consciousness, and he refused to say a word other than what the Quran and Sunnah said. When they demanded he adopt their creed, he replied:")
                        .font(.body)
                    ScriptureQuote(text: "“Give me something from the Book of Allah or the Sunnah of the Messenger of Allah so that I may say it” (Hanbal ibn Ishaq, Dhikr Mihnat al-Imam Ahmad; adh-Dhahabi, Siyar 11/241).", arabic: "أَعْطُونِي شَيْئًا مِنْ كِتَابِ اللَّهِ أَوْ سُنَّةِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ حَتَّى أَقُولَ بِهِ", dimmed: true)

                    Text("He was released from prison in 221 AH after the flogging, kept to his house under al-Wathiq, and the Mihnah was ended by al-Mutawakkil in 234 AH with the Sunnah intact; the Muslims called him the **Defender of the Sunnah**. Because he did not bend when almost everyone else did, the creed of the Salaf came to be identified with him, though it is older than him and belongs to no one.")
                        .font(.body)

                    Text("**Its method**: the names and attributes of Allah are affirmed as they came, without **tahrif (تَحرِيف)** (changing the meaning), **ta‘til (تَعطِيل)** (denying them), **takyif (تَكيِيف)** (asking how), or **tamthil (تَمثِيل)** (likening Him to creation). The measure is:")
                        .font(.body)
                    ScriptureQuote(text: "“There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).", arabic: "لَيۡسَ كَمِثۡلِهِۦ شَيۡءٞۖ وَهُوَ ٱلسَّمِيعُ ٱلۡبَصِيرُ")

                    ScriptureQuote(text: "“Indeed, your Lord is Allah, who created the heavens and earth in six days and then established Himself above the Throne” (Quran 7:54).", arabic: "إِنَّ رَبَّكُمُ ٱللَّهُ ٱلَّذِي خَلَقَ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ فِي سِتَّةِ أَيَّامٖ ثُمَّ ٱسۡتَوَىٰ عَلَى ٱلۡعَرۡشِۖ")

                    Text("So Allah is affirmed to be above His Throne as He said, without asking how, exactly as Imam Malik answered. The Quran is the uncreated speech of Allah. The believers will see their Lord in Paradise. Faith is belief, statement, and action; it increases and decreases. No Muslim is declared a disbeliever for a sin. All the Companions are loved and none is cursed. This is the creed of the four imams of fiqh, not only Ahmad: **Abu Ja‘far al-Tahawi (الطَّحَاوِي)** (d. 321 AH), a Hanafi, opened his famous creed by describing it as the creed of Ahl as-Sunnah wal-Jama‘ah according to the madhhab of Abu Hanifah, Abu Yusuf, and Muhammad ibn al-Hasan ash-Shaybani.")
                        .font(.body)

                    Text("**Its books**: Usul as-Sunnah of Imam Ahmad; as-Sunnah of his son Abdullah; Khalq Af‘al al-‘Ibad of al-Bukhari; Sharh as-Sunnah of al-Barbahari (d. 329 AH); al-Ibanah of Ibn Battah (d. 387 AH); Sharh Usul I‘tiqad Ahl as-Sunnah of al-Lalaka’i (d. 418 AH); al-Aqidah al-Tahawiyyah; Lum‘at al-I‘tiqad of Ibn Qudamah (d. 620 AH); and al-Aqidah al-Wasitiyyah of Ibn Taymiyyah (d. 728 AH).")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE SCHOOLS OF KALAM")) {
                    Text("Three schools took the road of kalam. One is rejected outright; two are counted broadly within Ahl as-Sunnah while being disagreed with in specific matters of creed.")
                        .font(.body)

                    Text("**1. The Mu‘tazilah (المُعتَزِلَة)**, founded by **Wasil ibn Ata (وَاصِل بن عَطَاء)** (80–131 AH). He withdrew (**i‘tazala**) from the circle of the great Successor al-Hasan al-Basri in Basrah over the ruling on the major sinner, and his followers took the name. They held that the Quran is created, that Allah is knowing and powerful “by His essence“ with no attribute additional to it, which Ahl as-Sunnah rightly called a denial of the attributes, that He will not be seen in the Hereafter, and that man creates his own actions independently of Allah’s decree, so that the Salaf counted them among the **Qadariyyah (القَدَرِيَّة)**. It was their creed that al-Ma’mun imposed in the Mihnah and that Imam Ahmad was imprisoned for refusing. They placed reason above revelation, and every school of Ahl as-Sunnah, Athari, Ash‘ari, and Maturidi alike, rejects them.")
                        .font(.body)

                    Text("Of the deniers of the decree the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The Qadariyyah are the Magians of this community” (Sunan Abi Dawud 4691; graded hasan by al-Albani).", arabic: "الْقَدَرِيَّةُ مَجُوسُ هَذِهِ الأُمَّةِ", dimmed: true)

                    Text("And when the first man to speak against the decree, Ma‘bad al-Juhani, appeared in Basrah, Ibn Umar (may Allah be pleased with them both) was told of it and said:")
                        .font(.body)
                    ScriptureQuote(text: "“When you happen to meet such people tell them that I have nothing to do with them and they have nothing to do with me. And verily they are in no way responsible for my (belief). Abdullah ibn Umar swore by Him (the Lord) (and said): If any one of them (who does not believe in the Divine Decree) had with him gold equal to the bulk of (the mountain) Uhud and spent it (in the way of Allah), Allah would not accept it unless he affirmed his faith in Divine Decree” (Sahih Muslim 8).", arabic: "فَإِذَا لَقِيتَ أُولَئِكَ فَأَخْبِرْهُمْ أَنِّي بَرِيءٌ مِنْهُمْ وَأَنَّهُمْ بُرَآءُ مِنِّي وَالَّذِي يَحْلِفُ بِهِ عَبْدُ اللَّهِ بْنُ عُمَرَ لَوْ أَنَّ لأَحَدِهِمْ مِثْلَ أُحُدٍ ذَهَبًا فَأَنْفَقَهُ مَا قَبِلَ اللَّهُ مِنْهُ حَتَّى يُؤْمِنَ بِالْقَدَرِ", dimmed: true)

                    Text("**2. The Ash‘ariyyah (الأَشعَرِيَّة)**, named after **Abu al-Hasan Ali ibn Isma‘il al-Ash‘ari (أَبُو الحَسَن الأَشعَرِي)** (260–324 AH / 874–936 CE) of Basrah and Baghdad. He is a descendant of the Companion Abu Musa al-Ash‘ari (may Allah be pleased with him), not to be confused with him. Abu al-Hasan spent about forty years as a Mu‘tazili theologian, the student and stepson of their leader al-Jubba’i, before renouncing the Mu‘tazilah publicly in the mosque of Basrah around 300 AH. He then passed through a middle period in which he followed Ibn Kullab, affirming some attributes by rational proof and reinterpreting others, and ended in a final period in which he wrote **al-Ibanah ‘an Usul al-Diyanah** and declared:")
                        .font(.body)
                    ScriptureQuote(text: "“The position we hold and the religion we follow is: holding fast to the Book of our Lord and the Sunnah of our Prophet and what is narrated from the Companions, the Successors, and the imams of hadith … and we say what Abu Abdullah Ahmad ibn Muhammad ibn Hanbal said, and we oppose whatever opposes his statement” (al-Ash'ari, al-Ibanah, p. 20).", arabic: "قَوْلُنَا الَّذِي نَقُولُ بِهِ وَدِيَانَتُنَا الَّتِي نَدِينُ بِهَا: التَّمَسُّكُ بِكِتَابِ رَبِّنَا وَبِسُنَّةِ نَبِيِّنَا صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَمَا رُوِيَ عَنِ الصَّحَابَةِ وَالتَّابِعِينَ وَأَئِمَّةِ الْحَدِيثِ … وَبِمَا كَانَ يَقُولُ بِهِ أَبُو عَبْدِ اللَّهِ أَحْمَدُ بْنُ مُحَمَّدِ بْنِ حَنْبَلٍ قَائِلُونَ، وَلِمَا خَالَفَ قَوْلَهُ مُخَالِفُونَ", dimmed: true)

                    Text("The school that carries his name did not settle on this final position. It built on his middle period and on the theologians who came after him (al-Juwayni, al-Ghazali, and al-Razi), who went further in reinterpreting the attributes and in adopting kalam; al-Baqillani, the earliest of them, still affirmed the attributes of the Hand and the Face without ta’wil. Many great scholars of fiqh and hadith held the Ash‘ari creed, among them al-Nawawi, Ibn Hajar, and al-Qurtubi, and Ahl as-Sunnah honour them and benefit from their works while disagreeing with them where they departed from the Salaf. And the one who follows Abu al-Hasan himself to the end of his life arrives at the creed of Imam Ahmad.")
                        .font(.body)

                    Text("**3. The Maturidiyyah (المَاتُرِيدِيَّة)**, named after **Abu Mansur Muhammad ibn Muhammad al-Maturidi (أَبُو مَنصُور المَاتُرِيدِي)** (d. 333 AH / 944 CE) of Maturid near Samarqand, a Hanafi jurist. His creed is close to the Ash‘ari one with some differences of detail, and it spread with the Hanafi school through Central Asia, Turkey, and the Indian subcontinent. The assessment is the same as for the Ash‘aris.")
                        .font(.body)

                    Text("Notice the difference in the names. The Ash‘ari and Maturidi schools are named after two men who lived three hundred years after the Prophet (peace be upon him); the Mu‘tazilah after an act of withdrawal. The Athari creed is named after nothing but the narrations themselves, because it existed before any of these men were born.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE REJECTED SECTS")) {
                    Text("Two groups are disavowed by all of Ahl as-Sunnah, whatever their school: the Mu‘tazilah above and the **Khawarij (الخَوَارِج)**.")
                        .font(.body)

                    Text("The Khawarij, “those who went out,“ were the first sect in Islam. They broke away from Ali (may Allah be pleased with him) after the arbitration at Siffin in 37 AH, raising the slogan “no judgement but Allah’s,“ declared Muslims disbelievers for major sins, rebelled against the Muslim rulers, and finally assassinated Ali in 40 AH. They did not follow kalam; they followed their own hasty reading of the Quran, without the Companions. The Prophet (peace be upon him) described them before they appeared. When Dhul-Khuwaysirah said to him, “Be just,“ he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Leave him, for he has companions who pray and fast in such a way that you will consider your fasting negligible in comparison to theirs. They recite Qur'an but it does not go beyond their throats (i.e. they do not act on it) and they will desert Islam as an arrow goes through a victim's body” (Sahih al-Bukhari 3610, Sahih Muslim 1064).", arabic: "دَعْهُ فَإِنَّ لَهُ أَصْحَابًا، يَحْقِرُ أَحَدُكُمْ صَلاَتَهُ مَعَ صَلاَتِهِمْ وَصِيَامَهُ مَعَ صِيَامِهِمْ، يَقْرَءُونَ الْقُرْآنَ لاَ يُجَاوِزُ تَرَاقِيَهُمْ، يَمْرُقُونَ مِنَ الدِّينِ كَمَا يَمْرُقُ السَّهْمُ مِنَ الرَّمِيَّةِ", dimmed: true)

                    Text("Ali (may Allah be pleased with him) narrated:")
                        .font(.body)
                    ScriptureQuote(text: "“In the last days of this world there will appear some young foolish people who will use (in their claim) the best speech of all people (i.e. the Qur'an) and they will abandon Islam as an arrow going through the game. Their belief will not go beyond their throats (i.e. they will have practically no belief)” (Sahih al-Bukhari 3611, Sahih Muslim 1066).", arabic: "يَأْتِي فِي آخِرِ الزَّمَانِ قَوْمٌ حُدَثَاءُ الأَسْنَانِ، سُفَهَاءُ الأَحْلاَمِ، يَقُولُونَ مِنْ خَيْرِ قَوْلِ الْبَرِيَّةِ، يَمْرُقُونَ مِنَ الإِسْلاَمِ كَمَا يَمْرُقُ السَّهْمُ مِنَ الرَّمِيَّةِ", dimmed: true)

                    ScriptureQuote(text: "“'The Khawarij are the dogs of Hell” (Sunan Ibn Majah 173; graded sahih by al-Albani).", arabic: "الْخَوَارِجُ كِلاَبُ النَّارِ", dimmed: true)

                    Text("When they told Ali, “There is no judgement but Allah’s,“ he replied:")
                        .font(.body)
                    ScriptureQuote(text: "“The statement is true but it is intentionally applied (to support) a wrong (cause)” (Sahih Muslim 1066).", arabic: "كَلِمَةُ حَقٍّ أُرِيدَ بِهَا بَاطِلٌ", dimmed: true)

                    Text("Every group that declares Muslims disbelievers for sins and takes up arms against them on that basis walks the path of the Khawarij, whatever it calls itself today. Ahl as-Sunnah hold the opposite: the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If a man says to his brother, O Kafir (disbeliever)!' Then surely one of them is such (i.e., a Kafir)” (Sahih al-Bukhari 6103, Sahih Muslim 60).", arabic: "إِذَا قَالَ الرَّجُلُ لأَخِيهِ يَا كَافِرُ فَقَدْ بَاءَ بِهِ أَحَدُهُمَا", dimmed: true)

                    Text("Other sects the Salaf warned against include the **Jahmiyyah (الجَهمِيَّة)** of Jahm ibn Safwan (d. 128 AH), who denied Allah’s attributes altogether and were the root of every later denial; the **Murji’ah (المُرجِئَة)**, who said sins do not harm faith; the **Qadariyyah (القَدَرِيَّة)**, who denied the decree; and the **Rafidah (الرَّافِضَة)**, who rejected the Companions. See “Answering the Shia“ and the other articles under Salafiyyah below.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHICH CREED IS CORRECT?")) {
                    Text("The creed of the Salaf, the Athari creed, is the correct one, and the reason is not that a scholar said so. It is that creed is known only through revelation:")
                        .font(.body)
                    ScriptureQuote(text: "“Nor does he speak from [his own] inclination. It is not but a revelation revealed” (Quran 53:3-4).", arabic: "وَمَا يَنطِقُ عَنِ ٱلۡهَوَىٰٓ ۝ إِنۡ هُوَ إِلَّا وَحۡيٞ يُوحَىٰ")

                    Text("And the people who received that revelation and lived with the one who brought it understood it best:")
                        .font(.body)
                    ScriptureQuote(text: "“The people of my generation are the best, then those who follow them, and then whose who follow the latter” (Sahih al-Bukhari 2652).", arabic: "خَيْرُ النَّاسِ قَرْنِي، ثُمَّ الَّذِينَ يَلُونَهُمْ، ثُمَّ الَّذِينَ يَلُونَهُمْ", dimmed: true)

                    ScriptureQuote(text: "“And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).", arabic: "وَٱلسَّٰبِقُونَ ٱلۡأَوَّلُونَ مِنَ ٱلۡمُهَٰجِرِينَ وَٱلۡأَنصَارِ وَٱلَّذِينَ ٱتَّبَعُوهُم بِإِحۡسَٰنٖ رَّضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُ")

                    Text("The first three generations did not learn kalam, did not reinterpret the attributes, and did not say the Quran was created. Whatever creed they did not hold cannot be the creed of Islam, because Islam was complete in their time:")
                        .font(.body)
                    ScriptureQuote(text: "“This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as religion” (Quran 5:3).", arabic: "ٱلۡيَوۡمَ أَكۡمَلۡتُ لَكُمۡ دِينَكُمۡ وَأَتۡمَمۡتُ عَلَيۡكُمۡ نِعۡمَتِي وَرَضِيتُ لَكُمُ ٱلۡإِسۡلَٰمَ دِينٗاۚ")

                    Text("Shaykh al-Islam Ibn Taymiyyah (may Allah have mercy on him) put it in one sentence:")
                        .font(.body)
                    ScriptureQuote(text: "“There is no blame on the one who manifests the way of the Salaf, ascribes himself to it, and takes pride in it; rather it is obligatory to accept that from him by agreement, for the way of the Salaf can be nothing but the truth” (Majmu' al-Fatawa 4/149).", arabic: "لَا عَيْبَ عَلَى مَنْ أَظْهَرَ مَذْهَبَ السَّلَفِ وَانْتَسَبَ إِلَيْهِ وَاعْتَزَى إِلَيْهِ، بَلْ يَجِبُ قَبُولُ ذَلِكَ مِنْهُ بِالِاتِّفَاقِ، فَإِنَّ مَذْهَبَ السَّلَفِ لَا يَكُونُ إِلَّا حَقًّا", dimmed: true)

                    Text("This is said with fairness. Ash‘aris and Maturidis are Muslims of Ahl al-Qiblah whose scholars served the religion; the disagreement with them is over specific points of creed, argued with evidence and good manners, not with the enmity owed to the Mu‘tazilah or the Khawarij. And every Muslim, whatever label he inherited, is invited to the same thing: the Quran and the Sunnah as the Companions understood them.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text("**Where is Allah?**")
                        .font(.body)
                    Text("Above His Throne, above the seven heavens, as He said of Himself, while His knowledge, hearing, and sight encompass everything. The Prophet (peace be upon him) asked the slave girl of Mu‘awiyah ibn al-Hakam:")
                        .font(.body)
                    ScriptureQuote(text: "“Where is Allah? She said: He is in the heaven. He said: Who am I? She said: Thou art the Messenger of Allah. He said: Grant her freedom, she is a believing woman” (Sahih Muslim 537).", arabic: "أَيْنَ اللَّهُ. قَالَتْ فِي السَّمَاءِ. قَالَ مَنْ أَنَا. قَالَتْ أَنْتَ رَسُولُ اللَّهِ. قَالَ أَعْتِقْهَا فَإِنَّهَا مُؤْمِنَةٌ", dimmed: true)

                    Text("He accepted “in the heaven” as the answer of a believer and made it the test of her faith. He said the same of himself when some complained about his division of gold:")
                        .font(.body)
                    ScriptureQuote(text: "“Don't you trust me though I am the truth worthy man of the One in the Heavens, and I receive the news of Heaven (i.e. Divine Inspiration) both in the morning and in the evening?” (Sahih al-Bukhari 4351).", arabic: "أَلاَ تَأْمَنُونِي وَأَنَا أَمِينُ مَنْ فِي السَّمَاءِ، يَأْتِينِي خَبَرُ السَّمَاءِ صَبَاحًا وَمَسَاءً", dimmed: true)
                    ScriptureQuote(text: "“The Compassionate One has mercy on those who are merciful. If you show mercy to those who are on the earth, He Who is in the heaven will show mercy to you” (Sunan Abi Dawud 4941; graded sahih by al-Albani).", arabic: "الرَّاحِمُونَ يَرْحَمُهُمُ الرَّحْمَنُ ارْحَمُوا أَهْلَ الأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ", dimmed: true)

                    Text("The Quran says:")
                        .font(.body)
                    ScriptureQuote(text: "“The Most Merciful [who is] above the Throne established” (Quran 20:5).", arabic: "ٱلرَّحۡمَٰنُ عَلَى ٱلۡعَرۡشِ ٱسۡتَوَىٰ")
                    ScriptureQuote(text: "“Do you feel secure that He who [holds authority] in the heaven would not cause the earth to swallow you and suddenly it would sway?” (Quran 67:16).", arabic: "ءَأَمِنتُم مَّن فِي ٱلسَّمَآءِ أَن يَخۡسِفَ بِكُمُ ٱلۡأَرۡضَ فَإِذَا هِيَ تَمُورُ")

                    Text("Zaynab bint Jahsh (may Allah be pleased with her) used to say to the other wives of the Prophet (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“You were given in marriage by your families, while I was married (to the Prophet) by Allah from over seven Heavens” (Sahih al-Bukhari 7420).", arabic: "زَوَّجَكُنَّ أَهَالِيكُنَّ، وَزَوَّجَنِي اللَّهُ تَعَالَى مِنْ فَوْقِ سَبْعِ سَمَوَاتٍ", dimmed: true)

                    Text("“In the heaven” means above it, as the Arabs say “in” for “upon” (Pharaoh threatened to crucify the magicians “on (fi) the trunks of palm trees,” Quran 20:71), and it does not mean that the heaven contains Him, for He is greater than everything He made. As for “He is with you wherever you are” (Quran 57:4), the same verse ties it to His knowing what enters the earth and what descends from the heaven, and the verse of the secret counsel is framed by His knowledge, opening “Do you not consider that Allah knows” and closing “Allah is, of all things, Knowing” (Quran 58:7), which is why the translators render it “with them [in knowledge].” So the Salaf explained it: ad-Dahhak said, “He is above the Throne and His knowledge is with them”; Sufyan ath-Thawri, asked about the verse, said, “His knowledge”; and Imam Ahmad answered the Jahmiyyah with the same (Abdullah ibn Ahmad, as-Sunnah; al-Lalaka’i, Sharh Usul I‘tiqad Ahl as-Sunnah; Ibn Abd al-Barr, at-Tamhid). Imam Malik’s answer about the rising is quoted above. Abu Hanifah (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever says, ‘I do not know whether my Lord is in the heaven or on the earth,’ has disbelieved, because Allah says, ‘The Most Merciful above the Throne established,’ and His Throne is above His seven heavens” (Abu Hanifah, al-Fiqh al-Absat; cited by adh-Dhahabi in al-'Uluw).", arabic: "مَنْ قَالَ لَا أَعْرِفُ رَبِّي فِي السَّمَاءِ أَوْ فِي الْأَرْضِ فَقَدْ كَفَرَ، لِأَنَّ اللَّهَ تَعَالَى يَقُولُ: الرَّحْمَنُ عَلَى الْعَرْشِ اسْتَوَى، وَعَرْشُهُ فَوْقَ سَبْعِ سَمَاوَاتٍ", dimmed: true)

                    Text("Ibn Abd al-Barr the Maliki (d. 463 AH) wrote in at-Tamhid that the scholars of the Companions and the Tabi‘un, from whom the interpretation of the Quran is taken, said of the verse of the secret counsel: He is above the Throne and His knowledge is in every place. Adh-Dhahabi (d. 748 AH) gathered the statements of the Salaf on this in a book of its own, al-‘Uluw lil-‘Aliyy al-Ghaffar. The Jahmiyyah said “He is everywhere,” and the later kalam schools said “He is neither inside the world nor outside it, neither above nor below,” which, as the imams of the Sunnah answered, is a description of nothing.")
                        .font(.body)

                    Text("**Do we interpret Allah’s attributes?**")
                        .font(.body)
                    Text("We affirm them with their meanings in Arabic and leave their “how” to Allah. The verse “There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11), quoted above, negates likeness and affirms attributes in one breath, and Allah commands:")
                        .font(.body)
                    ScriptureQuote(text: "“And to Allah belong the best names, so invoke Him by them. And leave [the company of] those who practice deviation concerning His names” (Quran 7:180).", arabic: "وَلِلَّهِ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰ فَٱدۡعُوهُ بِهَاۖ وَذَرُواْ ٱلَّذِينَ يُلۡحِدُونَ فِيٓ أَسۡمَٰٓئِهِۦۚ")

                    Text("Deviation (ilhad) in His names includes denying them, likening them, and naming Him with what He did not name Himself. Al-Walid ibn Muslim asked al-Awza‘i, Malik, Sufyan ath-Thawri, and al-Layth ibn Sa‘d about the hadiths of the attributes, and they all said:")
                        .font(.body)
                    ScriptureQuote(text: "“Pass them on as they came, without asking how” (al-Lalaka'i, Sharh Usul I'tiqad Ahl as-Sunnah; adh-Dhahabi, al-'Uluw).", arabic: "أَمِرُّوهَا كَمَا جَاءَتْ بِلَا كَيْفٍ", dimmed: true)

                    Text("“As they came” means with their meaning; a text has nothing to pass on if its meaning is unknown. When Allah says He has mercy, we know what mercy is in the language and we do not know how His mercy is; when He says He rose over the Throne, the rising is known and the “how” is not, exactly as Malik said. What Ahl as-Sunnah refuse is ta’wil in the later sense: turning a word from its plain meaning to another because of a rational objection, such as making the Hand “power,” the Face “the Self,” and the rising “conquest.” Ibn Kathir (may Allah have mercy on him), a Shafi‘i, set out the rule at the verse of the Throne:")
                        .font(.body)
                    ScriptureQuote(text: "“In this matter we follow the way of the righteous Salaf: Malik, al-Awza‘i, ath-Thawri, al-Layth ibn Sa‘d, ash-Shafi‘i, Ahmad, Ishaq ibn Rahawayh, and the other imams of the Muslims, early and late, which is to pass the texts on as they came, without asking how, without likening, and without denial” (Ibn Kathir, Tafsir, at Quran 7:54).", arabic: "وَإِنَّمَا نَسْلُكُ فِي هَذَا الْمَقَامِ مَذْهَبَ السَّلَفِ الصَّالِحِ: مَالِكٍ وَالْأَوْزَاعِيِّ وَالثَّوْرِيِّ وَاللَّيْثِ بْنِ سَعْدٍ وَالشَّافِعِيِّ وَأَحْمَدَ وَإِسْحَاقَ بْنِ رَاهَوَيْهِ وَغَيْرِهِمْ مِنْ أَئِمَّةِ الْمُسْلِمِينَ قَدِيمًا وَحَدِيثًا، وَهُوَ إِمْرَارُهَا كَمَا جَاءَتْ مِنْ غَيْرِ تَكْيِيفٍ وَلَا تَشْبِيهٍ وَلَا تَعْطِيلٍ", dimmed: true)

                    Text("The one who follows what is unclear in pursuit of an interpretation is the one the Prophet (peace be upon him) warned against (Quran 3:7 and Sahih al-Bukhari 4547, above). And every imam Ibn Kathir named died before the Ash‘ari and Maturidi schools existed: the way of the Salaf is not a later party’s position but the oldest position there is.")
                        .font(.body)

                    Text("**Is the Quran the created or the uncreated speech of Allah?**")
                        .font(.body)
                    Text("The Quran is the speech of Allah, revealed, not created; it came from Him and to Him it will return. Speech is an attribute of the Speaker, and an attribute of Allah is not a creature. Allah calls the Quran His own words:")
                        .font(.body)
                    ScriptureQuote(text: "“And if any one of the polytheists seeks your protection, then grant him protection so that he may hear the words of Allah” (Quran 9:6).", arabic: "وَإِنۡ أَحَدٞ مِّنَ ٱلۡمُشۡرِكِينَ ٱسۡتَجَارَكَ فَأَجِرۡهُ حَتَّىٰ يَسۡمَعَ كَلَٰمَ ٱللَّهِ")
                    ScriptureQuote(text: "“They wish to change the words of Allah” (Quran 48:15).", arabic: "يُرِيدُونَ أَن يُبَدِّلُواْ كَلَٰمَ ٱللَّهِۚ")

                    Text("The Prophet (peace be upon him) taught us to say:")
                        .font(.body)
                    ScriptureQuote(text: "“I seek refuge in the Perfect Word of Allah from the evil of what He has created,” (Sahih Muslim 2708).", arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ", dimmed: true)

                    Text("Refuge is sought only in Allah and His attributes, never in a created thing, and the Salaf used this very hadith against the Jahmiyyah. The doctrine that the Quran is created came from al-Ja‘d ibn Dirham and Jahm, was adopted by the Mu‘tazilah, and was imposed by force in the Mihnah; Imam Ahmad’s stand is told above. Abu Hanifah (may Allah have mercy on him), a contemporary of Jahm who refuted his followers, had written a century before the Mihnah:")
                        .font(.body)
                    ScriptureQuote(text: "“The Quran is the speech of Allah the Exalted: written in the mushafs, preserved in the hearts, recited on the tongues, sent down upon the Prophet … and the Quran is not created” (Abu Hanifah, al-Fiqh al-Akbar).", arabic: "وَالْقُرْآنُ كَلَامُ اللَّهِ تَعَالَى، فِي الْمَصَاحِفِ مَكْتُوبٌ، وَفِي الْقُلُوبِ مَحْفُوظٌ، وَعَلَى الْأَلْسُنِ مَقْرُوءٌ، وَعَلَى النَّبِيِّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ مُنَزَّلٌ … وَالْقُرْآنُ غَيْرُ مَخْلُوقٍ", dimmed: true)

                    Text("Al-Bukhari wrote a whole book on the matter, Khalq Af‘al al-‘Ibad, “The Creation of the Servants’ Actions”: the Quran is uncreated, while our reciting, writing, and voices are our own created actions. At-Tahawi stated in his creed that the Quran is the speech of Allah that came from Him as speech without a “how,” that it is not the speech of any created being, and that whoever hears it and claims it is human speech has disbelieved. The later Ash‘ari position, that Allah’s speech is one eternal inner meaning while the recited Quran is a created expression of it, is a compromise the Salaf did not know: what is between the two covers of the mushaf is the speech of Allah.")
                        .font(.body)

                    Text("**Will the believers see Allah?**")
                        .font(.body)
                    Text("Yes, in the Hereafter, with their eyes, without encompassing Him. The Quran says:")
                        .font(.body)
                    ScriptureQuote(text: "“[Some] faces, that Day, will be radiant, Looking at their Lord” (Quran 75:22-23).", arabic: "وُجُوهٞ يَوۡمَئِذٖ نَّاضِرَةٌ ۝ إِلَىٰ رَبِّهَا نَاظِرَةٞ")
                    ScriptureQuote(text: "“For them who have done good is the best [reward] and extra” (Quran 10:26).", arabic: "لِّلَّذِينَ أَحۡسَنُواْ ٱلۡحُسۡنَىٰ وَزِيَادَةٞۖ")

                    Text("The Prophet (peace be upon him) explained the “extra” in this verse:")
                        .font(.body)
                    ScriptureQuote(text: "“When those deserving of Paradise would enter Paradise, the Blessed and the Exalted would ask: Do you wish Me to give you anything more? They would say: Hast Thou not brightened our faces? Hast Thou not made us enter Paradise and saved us from Fire? He (the narrator) said: He (God) would lift the veil, and of things given to them nothing would he dearer to them than the sight of their Lord, the Mighty and the Glorious” (Sahih Muslim 181).", arabic: "إِذَا دَخَلَ أَهْلُ الْجَنَّةِ الْجَنَّةَ - قَالَ - يَقُولُ اللَّهُ تَبَارَكَ وَتَعَالَى تُرِيدُونَ شَيْئًا أَزِيدُكُمْ فَيَقُولُونَ أَلَمْ تُبَيِّضْ وُجُوهَنَا أَلَمْ تُدْخِلْنَا الْجَنَّةَ وَتُنَجِّنَا مِنَ النَّارِ - قَالَ - فَيَكْشِفُ الْحِجَابَ فَمَا أُعْطُوا شَيْئًا أَحَبَّ إِلَيْهِمْ مِنَ النَّظَرِ إِلَى رَبِّهِمْ عَزَّ وَجَلَّ", dimmed: true)

                    Text("Jarir ibn Abdillah (may Allah be pleased with him) said the Prophet (peace be upon him) looked at the full moon and said:")
                        .font(.body)
                    ScriptureQuote(text: "“Certainly you will see your Lord as you see this moon and you will have no trouble in seeing Him” (Sahih al-Bukhari 554, Sahih Muslim 633).", arabic: "إِنَّكُمْ سَتَرَوْنَ رَبَّكُمْ كَمَا تَرَوْنَ هَذَا الْقَمَرَ لاَ تُضَامُّونَ فِي رُؤْيَتِهِ", dimmed: true)

                    Text("Ash-Shafi‘i (may Allah have mercy on him) drew the same proof from the opposite verse:")
                        .font(.body)
                    ScriptureQuote(text: "“No! Indeed, from their Lord, that Day, they will be partitioned” (Quran 83:15).", arabic: "كـَلَّآ إِنَّهُمۡ عَن رَّبِّهِمۡ يَوۡمَئِذٖ لَّمَحۡجُوبُونَ")

                    Text("He said that since the disbelievers are veiled from Him in His anger, His friends will see Him in His pleasure (related by al-Lalaka’i, and by Ibn Kathir at this verse). The Mu‘tazilah denied the seeing and set “Vision perceives Him not” (Quran 6:103) against it, but perceiving (idrak) is encompassing, not seeing: the believers will see Him and never encompass Him, just as they know Him and never encompass His knowledge. The Ash‘aris affirm the seeing, and Ahl as-Sunnah agree with them here.")
                        .font(.body)

                    Text("**Is the Muslim who commits a major sin a believer or a disbeliever?**")
                        .font(.body)
                    Text("A believer with deficient faith: a believer by his faith and a sinner (fasiq) by his major sin. He is not expelled from Islam, and in the Hereafter he is under Allah’s will, forgiven or punished and then brought out of the Fire by the tawhid (تَوحِيد, from the root و-ح-د: singling Allah out in everything that belongs to Him alone) he died upon. Three sects went wrong here: the Khawarij said he is a disbeliever, the Mu‘tazilah said he is in a station between the two, and the Murji’ah said his faith is untouched. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, Allah does not forgive association with Him, but He forgives what is less than that for whom He wills” (Quran 4:48).", arabic: "إِنَّ ٱللَّهَ لَا يَغۡفِرُ أَن يُشۡرَكَ بِهِۦ وَيَغۡفِرُ مَا دُونَ ذَٰلِكَ لِمَن يَشَآءُۚ")
                    ScriptureQuote(text: "“And if two factions among the believers should fight, then make settlement between the two” (Quran 49:9).", arabic: "وَإِن طَآئِفَتَانِ مِنَ ٱلۡمُؤۡمِنِينَ ٱقۡتَتَلُواْ فَأَصۡلِحُواْ بَيۡنَهُمَاۖ")
                    ScriptureQuote(text: "“The believers are but brothers” (Quran 49:10).", arabic: "إِنَّمَا ٱلۡمُؤۡمِنُونَ إِخۡوَةٞ")

                    Text("Allah calls fighting Muslims “believers” and “brothers” while their sin is at its height. The Prophet (peace be upon him) said to Abu Dharr:")
                        .font(.body)
                    ScriptureQuote(text: "“Nobody says: 'None has the right to be worshipped but Allah' and then later on he dies while believing in that, except that he will enter Paradise.‘ I said, ’Even if he had committed illegal sexual intercourse and theft?‘ He said. 'Even if he had committed illegal sexual intercourse and theft” (Sahih al-Bukhari 5827).", arabic: "مَا مِنْ عَبْدٍ قَالَ لاَ إِلَهَ إِلاَّ اللَّهُ. ثُمَّ مَاتَ عَلَى ذَلِكَ، إِلاَّ دَخَلَ الْجَنَّةَ. قُلْتُ وَإِنْ زَنَى وَإِنْ سَرَقَ قَالَ وَإِنْ زَنَى وَإِنْ سَرَقَ", dimmed: true)

                    Text("When he took the pledge of the Companions not to associate anything with Allah, not to steal, not to commit adultery, and not to kill their children, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever among you fulfills his pledge will be rewarded by Allah. And whoever indulges in any one of them (except the ascription of partners to Allah) and gets the punishment in this world, that punishment will be an expiation for that sin. And if one indulges in any of them, and Allah conceals his sin, it is up to Him to forgive or punish him (in the Hereafter)” (Sahih al-Bukhari 18).", arabic: "فَمَنْ وَفَى مِنْكُمْ فَأَجْرُهُ عَلَى اللَّهِ، وَمَنْ أَصَابَ مِنْ ذَلِكَ شَيْئًا فَعُوقِبَ فِي الدُّنْيَا فَهُوَ كَفَّارَةٌ لَهُ، وَمَنْ أَصَابَ مِنْ ذَلِكَ شَيْئًا ثُمَّ سَتَرَهُ اللَّهُ، فَهُوَ إِلَى اللَّهِ إِنْ شَاءَ عَفَا عَنْهُ، وَإِنْ شَاءَ عَاقَبَهُ", dimmed: true)

                    Text("A sinner whose matter is “with Allah, if He wills He pardons him” is not a disbeliever, for the disbeliever is not pardoned. And when a man cursed a Companion who had been flogged more than once for drinking, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not curse him, for by Allah, I know for he loves Allah and His Apostle” (Sahih al-Bukhari 6780).", arabic: "لاَ تَلْعَنُوهُ، فَوَاللَّهِ مَا عَلِمْتُ أَنَّهُ يُحِبُّ اللَّهَ وَرَسُولَهُ", dimmed: true)

                    Text("A drinker who loves Allah and His Messenger is a believer with a sin, not a disbeliever. That faith rises and falls is stated in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“It is He who sent down tranquillity into the hearts of the believers that they would increase in faith along with their [present] faith” (Quran 48:4).", arabic: "هُوَ ٱلَّذِيٓ أَنزَلَ ٱلسَّكِينَةَ فِي قُلُوبِ ٱلۡمُؤۡمِنِينَ لِيَزۡدَادُوٓاْ إِيمَٰنٗا مَّعَ إِيمَٰنِهِمۡۗ")
                    ScriptureQuote(text: "“And when His verses are recited to them, it increases them in faith” (Quran 8:2).", arabic: "وَإِذَا تُلِيَتۡ عَلَيۡهِمۡ ءَايَٰتُهُۥ زَادَتۡهُمۡ إِيمَٰنٗا")

                    Text("So sins lower faith without ending it, and repentance and good deeds raise it again; this is al-Bukhari’s “it increases and decreases” quoted in the Key Terms. The Companions, and the Ahlul Bayt with them, never made takfir of a Muslim for a sin, and Ali fought the Khawarij precisely for doing so.")
                        .font(.body)

                    Text("**Do we believe in the decree while having free will?**")
                        .font(.body)
                    Text("Yes, both at once, because Allah affirmed both at once. Belief in the decree has four levels: Allah knew everything before it was; He wrote it; nothing happens except by His will; and He created everything, including the servants’ acts.")
                        .font(.body)
                    ScriptureQuote(text: "“No disaster strikes upon the earth or among yourselves except that it is in a register before We bring it into being” (Quran 57:22).", arabic: "مَآ أَصَابَ مِن مُّصِيبَةٖ فِي ٱلۡأَرۡضِ وَلَا فِيٓ أَنفُسِكُمۡ إِلَّا فِي كِتَٰبٖ مِّن قَبۡلِ أَن نَّبۡرَأَهَآۚ")
                    ScriptureQuote(text: "“While Allah created you and that which you do?” (Quran 37:96).", arabic: "وَٱللَّهُ خَلَقَكُمۡ وَمَا تَعۡمَلُونَ")

                    Text("And in the same Quran the servant’s will is real, and it is the ground of his reward:")
                        .font(.body)
                    ScriptureQuote(text: "“For whoever wills among you to take a right course. And you do not will except that Allah wills - Lord of the worlds” (Quran 81:28-29).", arabic: "لِمَن شَآءَ مِنكُمۡ أَن يَسۡتَقِيمَ ۝ وَمَا تَشَآءُونَ إِلَّآ أَن يَشَآءَ ٱللَّهُ رَبُّ ٱلۡعَٰلَمِينَ")
                    ScriptureQuote(text: "“Indeed, We guided him to the way, be he grateful or be he ungrateful” (Quran 76:3).", arabic: "إِنَّا هَدَيۡنَٰهُ ٱلسَّبِيلَ إِمَّا شَاكِرٗا وَإِمَّا كَفُورًا")

                    Text("The verses of at-Takwir put the two together in a single breath: a will of yours, inside the will of Allah. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah ordained the measures (of quality) of the creation fifty thousand years before He created the heavens and the earth, as His Throne was upon water” (Sahih Muslim 2653).", arabic: "كَتَبَ اللَّهُ مَقَادِيرَ الْخَلاَئِقِ قَبْلَ أَنْ يَخْلُقَ السَّمَوَاتِ وَالأَرْضَ بِخَمْسِينَ أَلْفَ سَنَةٍ - قَالَ - وَعَرْشُهُ عَلَى الْمَاءِ", dimmed: true)

                    Text("When the Companions asked whether they should then rely on what is written and give up deeds, he answered:")
                        .font(.body)
                    ScriptureQuote(text: "“Carry on doing (good) deeds, for everybody will find easy to do such deeds as will lead him to his destined place for which he has been created” (Sahih al-Bukhari 4949, Sahih Muslim 2647).", arabic: "اعْمَلُوا فَكُلٌّ مُيَسَّرٌ لِمَا خُلِقَ لَهُ", dimmed: true)

                    Text("That is the whole answer: the decree is not a reason to stop; it is the unseen behind your striving, and you are addressed by the command, not by the hidden book. When Umar (may Allah be pleased with him) turned back from a land struck by plague and Abu Ubaydah asked whether he was fleeing from the decree of Allah, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Yes, we are running from what Allah had ordained to what Allah has ordained” (Sahih al-Bukhari 5729).", arabic: "نَعَمْ نَفِرُّ مِنْ قَدَرِ اللَّهِ إِلَى قَدَرِ اللَّهِ", dimmed: true)

                    Text("Choosing a course is itself part of what Allah decreed. Ibn Umar’s disavowal of the Qadariyyah is quoted above (Sahih Muslim 8). The Qadariyyah denied the decree to protect man’s freedom, the Jabriyyah (الجَبرِيَّة, from ج-ب-ر, compulsion) denied man’s freedom to protect the decree, and Ahl as-Sunnah accept both sets of texts; Ibn al-Qayyim (may Allah have mercy on him) wrote Shifa’ al-‘Alil on nothing else.")
                        .font(.body)

                    Text("**Are the Ash‘aris and Maturidis disbelievers?**")
                        .font(.body)
                    Text("No. They are Muslims of Ahl al-Qiblah who bear witness to the two testimonies, pray our prayer, and love the Prophet and his Companions. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever prays like us and faces our Qibla and eats our slaughtered animals is a Muslim and is under Allah's and His Apostle's protection. So do not betray Allah by betraying those who are in His protection” (Sahih al-Bukhari 391).", arabic: "مَنْ صَلَّى صَلاَتَنَا، وَاسْتَقْبَلَ قِبْلَتَنَا، وَأَكَلَ ذَبِيحَتَنَا، فَذَلِكَ الْمُسْلِمُ الَّذِي لَهُ ذِمَّةُ اللَّهِ وَذِمَّةُ رَسُولِهِ، فَلاَ تُخْفِرُوا اللَّهَ فِي ذِمَّتِهِ", dimmed: true)

                    Text("His warning that a charge of disbelief thrown at a brother returns upon one of the two (Sahih al-Bukhari 6103, quoted above) applies here with full force. Their scholars, an-Nawawi, Ibn Hajar, al-Qurtubi, al-Bayhaqi, and many more, served the Sunnah, and every Muslim is in their debt. Ibn Taymiyyah (may Allah have mercy on him), who debated the Ash‘aris more than anyone, wrote that the theologians who affirm the attributes are nearer to the Sunnah than those who deny them, and laid down that a specific person is not declared a disbeliever for an error of interpretation until the proof has been established against him and his excuse removed (Majmu‘ al-Fatawa). The disagreement with them is real, in the attributes, in the definition of faith, in the speech of Allah, and in the place of reason, and it is argued in the manner set out under Which Creed Is Correct above.")
                        .font(.body)

                    Text("**Can I follow a fiqh madhhab (Hanafi, Maliki, Shafi‘i, Hanbali) and hold the Athari creed?**")
                        .font(.body)
                    Text("Yes, and that is exactly what the four imams did. Their fiqh differed; their creed was one, and it was the creed of the Salaf. Abu Hanifah’s statements on the Quran and on Allah being above His Throne are quoted above (al-Fiqh al-Akbar, al-Fiqh al-Absat), and at-Tahawi, a Hanafi, opened his creed by calling it the creed of Abu Hanifah and his two companions. Malik’s answer on the rising is the motto of the whole creed. Ash-Shafi‘i (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“I believe in Allah and in what came from Allah as Allah intended, and I believe in the Messenger of Allah and in what came from the Messenger of Allah as the Messenger of Allah intended” (Ibn Qudamah, Lum'at al-I'tiqad).", arabic: "آمَنْتُ بِاللَّهِ وَبِمَا جَاءَ عَنِ اللَّهِ عَلَى مُرَادِ اللَّهِ، وَآمَنْتُ بِرَسُولِ اللَّهِ وَبِمَا جَاءَ عَنْ رَسُولِ اللَّهِ عَلَى مُرَادِ رَسُولِ اللَّهِ", dimmed: true)

                    Text("Ahmad is its imam. The great scholars of every madhhab after them held the same: Ibn Abd al-Barr the Maliki (at-Tamhid), Ibn Kathir and adh-Dhahabi the Shafi‘is, Ibn Qudamah and Ibn Rajab the Hanbalis, and in recent times Ibn Baz and Ibn al-Uthaymin, Hanbalis in fiqh, and al-Albani, who followed the evidence without binding himself to a madhhab. Following a madhhab in fiqh is following a qualified scholar where the texts admit more than one understanding; following the Salaf in creed is following the Prophet and his Companions where they admit only one. There is no tension between the two. The tension people feel comes only from the fact that two of the kalam schools grew up inside two of the fiqh schools and came to be confused with them.")
                        .font(.body)

                    Text("**Did the Companions or the Ahlul Bayt hold a different creed?**")
                        .font(.body)
                    Text("No. Ali (may Allah be pleased with him) was asked by his son Muhammad ibn al-Hanafiyyah who the best of people was after the Messenger of Allah, and he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Abu Bakr.‘ I asked, ’Who then?‘ He said, ’Then `Umar. ‘ I was afraid he would say ’Uthman, so I said, ‘Then you?’ He said, ‘I am only an ordinary person” (Sahih al-Bukhari 3671).", arabic: "قَالَ أَبُو بَكْرٍ. قُلْتُ ثُمَّ مَنْ قَالَ ثُمَّ عُمَرُ. وَخَشِيتُ أَنْ يَقُولَ عُثْمَانُ قُلْتُ ثُمَّ أَنْتَ قَالَ مَا أَنَا إِلاَّ رَجُلٌ مِنَ الْمُسْلِمِينَ", dimmed: true)

                    Text("This ranking, Abu Bakr then Umar, is the creed of Ahl as-Sunnah on the tongue of Ali himself, taught to his own son. He named three of his sons Abu Bakr, Umar, and Uthman, as the biographers of both sides record (Ibn Sa‘d, at-Tabaqat al-Kubra; Ibn Taymiyyah, Minhaj as-Sunnah; the Shia scholar al-Mufid, al-Irshad), and he gave his daughter Umm Kulthum, the Prophet’s granddaughter, in marriage to Umar. Al-Bukhari relates that when Umar was distributing garments, someone said to him:")
                        .font(.body)
                    ScriptureQuote(text: "“O chief of the believers! Give this garment to your wife, the (grand) daughter of Allah's Messenger (ﷺ).’ They meant Um Kulthum, the daughter of `Ali” (Sahih al-Bukhari 2881).", arabic: "يَا أَمِيرَ الْمُؤْمِنِينَ أَعْطِ هَذَا ابْنَةَ رَسُولِ اللَّهِ صلى الله عليه وسلم الَّتِي عِنْدَكَ. يُرِيدُونَ أُمَّ كُلْثُومٍ بِنْتَ عَلِيٍّ", dimmed: true)

                    Text("The Arabs call a granddaughter a daughter, and the Prophet’s granddaughter was in Umar’s house as his wife. Al-Hasan ibn Ali gave up the caliphate to Mu‘awiyah to spare Muslim blood, fulfilling what the Prophet (peace be upon him) had foretold of him (Sahih al-Bukhari 2704). Ja‘far as-Sadiq, the great-great-grandson of Ali, whose mother descended from Abu Bakr on both sides, used to say:")
                        .font(.body)
                    ScriptureQuote(text: "“Abu Bakr begot me twice” (adh-Dhahabi, Siyar A'lam an-Nubala').", arabic: "وَلَدَنِي أَبُو بَكْرٍ مَرَّتَيْنِ", dimmed: true)

                    Text("And Zayd ibn Ali refused to disavow Abu Bakr and Umar even when it cost him his army, as told under Rafidah below. The Ahlul Bayt held the creed of the Companions because they were Companions and the children of Companions; the claim that they hid another religion behind taqiyyah is a charge against their honesty, and Ahl as-Sunnah defend their honesty.")
                        .font(.body)

                    Text("**Is it enough to say “I follow the Quran and Sunnah” without the understanding of the Salaf?**")
                        .font(.body)
                    Text("No, because the Khawarij said the same. They recited the Quran, and the Prophet (peace be upon him) said it did not pass their throats (Sahih al-Bukhari 3610, above); al-Bukhari relates that Ibn Umar counted them the worst of Allah’s creation because they took verses revealed about the disbelievers and applied them to the believers. Every sect quotes the Quran; what separates truth from error is the understanding with which it is read, and Allah bound the believer to the understanding of the first believers:")
                        .font(.body)
                    ScriptureQuote(text: "“And whoever opposes the Messenger after guidance has become clear to him and follows other than the way of the believers - We will give him what he has taken and drive him into Hell, and evil it is as a destination” (Quran 4:115).", arabic: "وَمَن يُشَاقِقِ ٱلرَّسُولَ مِنۢ بَعۡدِ مَا تَبَيَّنَ لَهُ ٱلۡهُدَىٰ وَيَتَّبِعۡ غَيۡرَ سَبِيلِ ٱلۡمُؤۡمِنِينَ نُوَلِّهِۦ مَا تَوَلَّىٰ وَنُصۡلِهِۦ جَهَنَّمَۖ وَسَآءَتۡ مَصِيرًا")

                    Text("“The way of the believers” when this verse came down was the way of the Companions, and Allah made following it a condition of safety alongside obeying the Messenger. He praised those who follow the Muhajirun and the Ansar “with good conduct” (Quran 9:100, above), the Prophet (peace be upon him) called his generation the best of people (Sahih al-Bukhari 2652, above), and for the time of disagreement he commanded:")
                        .font(.body)
                    ScriptureQuote(text: "“for those of you who live after me will see great disagreement. You must then follow my sunnah and that of the rightly-guided caliphs. Hold to it and stick fast to it. Avoid novelties, for every novelty is an innovation, and every innovation is an error” (Sunan Abi Dawud 4607; graded sahih by al-Albani).", arabic: "فَإِنَّهُ مَنْ يَعِشْ مِنْكُمْ بَعْدِي فَسَيَرَى اخْتِلاَفًا كَثِيرًا فَعَلَيْكُمْ بِسُنَّتِي وَسُنَّةِ الْخُلَفَاءِ الْمَهْدِيِّينَ الرَّاشِدِينَ تَمَسَّكُوا بِهَا وَعَضُّوا عَلَيْهَا بِالنَّوَاجِذِ وَإِيَّاكُمْ وَمُحْدَثَاتِ الأُمُورِ فَإِنَّ كُلَّ مُحْدَثَةٍ بِدْعَةٌ وَكُلَّ بِدْعَةٍ ضَلاَلَةٌ", dimmed: true)

                    Text("He did not say “my Sunnah alone”; he joined to it the Sunnah of the caliphs, because their understanding of his Sunnah is part of it. Ibn Mas‘ud (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever of you would follow an example, let him follow the example of the Companions of the Messenger of Allah, for they were the most righteous of this nation in heart, the deepest in knowledge, and the least in affectation” (Ibn Abd al-Barr, Jami' Bayan al-'Ilm wa-Fadlih; Abu Nu'aym, Hilyat al-Awliya').", arabic: "مَنْ كَانَ مِنْكُمْ مُتَأَسِّيًا فَلْيَتَأَسَّ بِأَصْحَابِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، فَإِنَّهُمْ كَانُوا أَبَرَّ هَذِهِ الْأُمَّةِ قُلُوبًا، وَأَعْمَقَهَا عِلْمًا، وَأَقَلَّهَا تَكَلُّفًا", dimmed: true)

                    Text("Imam Ahmad’s Usul as-Sunnah, quoted above, begins with the same rule: holding to what the Companions were upon. “Quran and Sunnah” is the right slogan; “as the Companions understood them” is what makes it true.")
                        .font(.body)

                    Text("**Is a single-chain (ahad) hadith proof in creed?**")
                        .font(.body)
                    Text("Yes. An authentic hadith is proof in creed exactly as it is proof in law; the division between “proof for rulings” and “not proof for beliefs” was invented by the kalam schools, and the Companions did not know it. The Prophet (peace be upon him) sent Mu‘adh alone to Yemen to teach the people the creed itself:")
                        .font(.body)
                    ScriptureQuote(text: "“Invite the people to testify that none has the right to be worshipped but Allah and I am Allah's Messenger (ﷺ), and if they obey you to do so, then teach them that Allah has enjoined on them five prayers in every day and night (in twenty-four hours)” (Sahih al-Bukhari 1395, Sahih Muslim 19).", arabic: "ادْعُهُمْ إِلَى شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ، وَأَنِّي رَسُولُ اللَّهِ، فَإِنْ هُمْ أَطَاعُوا لِذَلِكَ فَأَعْلِمْهُمْ أَنَّ اللَّهَ قَدِ افْتَرَضَ عَلَيْهِمْ خَمْسَ صَلَوَاتٍ فِي كُلِّ يَوْمٍ وَلَيْلَةٍ", dimmed: true)

                    Text("In another wording, “let the first thing you call them to be that they single out Allah” (Sahih al-Bukhari 7372). If the report of one trustworthy man did not establish belief, sending one man to teach it would have been pointless. When the qiblah was changed, one man carried the news to Quba:")
                        .font(.body)
                    ScriptureQuote(text: "While the people were offering the Fajr prayer at Quba' (near Medina), someone came to them and said: ‘It has been revealed to Allah's Messenger (ﷺ) tonight, and he has been ordered to pray facing the Ka`ba.’ So turn your faces to the Ka`ba. Those people were facing Sham (Jerusalem) so they turned their faces towards Ka`ba (at Mecca) (Sahih al-Bukhari 403).", arabic: "بَيْنَا النَّاسُ بِقُبَاءٍ فِي صَلاَةِ الصُّبْحِ إِذْ جَاءَهُمْ آتٍ فَقَالَ إِنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم قَدْ أُنْزِلَ عَلَيْهِ اللَّيْلَةَ قُرْآنٌ، وَقَدْ أُمِرَ أَنْ يَسْتَقْبِلَ الْكَعْبَةَ فَاسْتَقْبِلُوهَا، وَكَانَتْ وُجُوهُهُمْ إِلَى الشَّأْمِ، فَاسْتَدَارُوا إِلَى الْكَعْبَةِ", dimmed: true)

                    Text("They turned in the middle of the prayer on the word of one man, and the Prophet (peace be upon him) did not censure them; a single report changed the direction of worship. He prayed for the single transmitter and made him a carrier of the religion:")
                        .font(.body)
                    ScriptureQuote(text: "“May Allah brighten a man who hears a tradition from us, gets it by heart and passes it on to others” (Sunan Abi Dawud 3660; graded sahih by al-Albani).", arabic: "نَضَّرَ اللَّهُ امْرَأً سَمِعَ مِنَّا حَدِيثًا فَحَفِظَهُ حَتَّى يُبَلِّغَهُ", dimmed: true)

                    Text("Allah commanded that a group from every division go out to learn and then warn their people:")
                        .font(.body)
                    ScriptureQuote(text: "“For there should separate from every division of them a group [remaining] to obtain understanding in the religion and warn their people when they return to them” (Quran 9:122).", arabic: "فَلَوۡلَا نَفَرَ مِن كُلِّ فِرۡقَةٖ مِّنۡهُمۡ طَآئِفَةٞ لِّيَتَفَقَّهُواْ فِي ٱلدِّينِ وَلِيُنذِرُواْ قَوۡمَهُمۡ إِذَا رَجَعُوٓاْ إِلَيۡهِمۡ")
                    ScriptureQuote(text: "“O you who have believed, if there comes to you a disobedient one with information, investigate” (Quran 49:6).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ إِن جَآءَكُمۡ فَاسِقُۢ بِنَبَإٖ فَتَبَيَّنُوٓاْ")

                    Text("Warning by a few implies that the few are to be believed, and the command to verify the report of a disobedient man implies that the report of a trustworthy man is accepted as it is. Ash-Shafi‘i argued the point at length in ar-Risalah, Ibn Abd al-Barr in at-Tamhid, and Ibn al-Qayyim in as-Sawa‘iq al-Mursalah: the rule of the Salaf is that a sahih hadith gives knowledge and is acted upon in all things, creed included.")
                        .font(.body)

                    Text("**Is the “three categories of tawhid” a bid‘ah?**")
                        .font(.body)
                    Text("No. A bid‘ah (بِدعَة, from ب-د-ع, to originate something with no precedent) is a new act of worship; a classification is a way of teaching what the texts contain, like “the five pillars of Islam,” “the six pillars of faith,” or the division of fiqh into worship and dealings. Allah Himself distinguishes the tawhid the idolaters affirmed from the tawhid they refused:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you asked them, ‘Who created the heavens and earth?’ they would surely say, ‘Allah’” (Quran 31:25).", arabic: "وَلَئِن سَأَلۡتَهُم مَّنۡ خَلَقَ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ لَيَقُولُنَّ ٱللَّهُۚ")
                    ScriptureQuote(text: "“We only worship them that they may bring us nearer to Allah in position” (Quran 39:3).", arabic: "مَا نَعۡبُدُهُمۡ إِلَّا لِيُقَرِّبُونَآ إِلَى ٱللَّهِ زُلۡفَىٰٓ")

                    Text("The Makkan idolaters affirmed that Allah alone creates, provides, and controls (Quran 10:31, 43:87), which is tawhid ar-rububiyyah, and they were still mushrikin, because they worshipped others “to bring us nearer to Allah,” which is a breach of tawhid al-uluhiyyah. The Prophet (peace be upon him) was not sent to teach them that Allah exists; he was sent so that they would worship Him alone, and he sent Mu‘adh to call the People of the Book first “to single out Allah” (Sahih al-Bukhari 7372). The distinction is therefore in the Quran itself; the terms only name it, as Surah Maryam 19:65 names all three in one verse (see Key Terms). Nor is the classification new: Ibn Battah al-‘Ukbari (d. 387 AH) set out the three in al-Ibanah, saying that the foundation of faith in Allah is to believe in His rububiyyah, in His wahdaniyyah in worship, and in His attributes; Ibn al-Qayyim in Madarij as-Salikin and Ibn Abi al-‘Izz al-Hanafi (d. 792 AH) in his commentary on at-Tahawiyyah explained that the tawhid the messengers brought is of two kinds, of knowledge and affirmation, and of intent and seeking, which are the same three headings folded into two; and Ibn Taymiyyah used the division throughout his works. Whoever objects to the classification while affirming everything in it disagrees over a word, not over creed.")
                        .font(.body)

                    Text("**Why does the correct creed matter if I pray and fast?**")
                        .font(.body)
                    Text("Because deeds are accepted on the basis of creed, not the other way round. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“If you should associate [anything] with Allah, your work would surely become worthless” (Quran 39:65).", arabic: "لَئِنۡ أَشۡرَكۡتَ لَيَحۡبَطَنَّ عَمَلُكَ")
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘Shall we [believers] inform you of the greatest losers as to [their] deeds? [They are] those whose effort is lost in worldly life, while they think that they are doing well in work.’ Those are the ones who disbelieve in the verses of their Lord and in [their] meeting Him, so their deeds have become worthless; and We will not assign to them on the Day of Resurrection any importance” (Quran 18:103-105).", arabic: "قُلۡ هَلۡ نُنَبِّئُكُم بِٱلۡأَخۡسَرِينَ أَعۡمَٰلًا ۝ ٱلَّذِينَ ضَلَّ سَعۡيُهُمۡ فِي ٱلۡحَيَوٰةِ ٱلدُّنۡيَا وَهُمۡ يَحۡسَبُونَ أَنَّهُمۡ يُحۡسِنُونَ صُنۡعًا ۝ أُوْلَٰٓئِكَ ٱلَّذِينَ كَفَرُواْ بِـَٔايَٰتِ رَبِّهِمۡ وَلِقَآئِهِۦ فَحَبِطَتۡ أَعۡمَٰلُهُمۡ فَلَا نُقِيمُ لَهُمۡ يَوۡمَ ٱلۡقِيَٰمَةِ وَزۡنٗا")

                    Text("Ibn Umar swore that a man who spent a mountain of gold would have nothing accepted from him until he believed in the decree (Sahih Muslim 8, above), and the Prophet (peace be upon him) described the Khawarij, beside whose prayer and fasting you would belittle your own, as passing out of the religion (Sahih al-Bukhari 3610, above). Prayer and fasting are the branches and creed is the root, and a tree with a rotten root bears nothing however green it looks. That is why the Prophet (peace be upon him) spent the Makkan years teaching tawhid before the five prayers were made obligatory, why he sent Mu‘adh to teach the testimony before the prayer and the zakah, and why Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, Allah only accepts from the righteous [who fear Him]” (Quran 5:27).", arabic: "إِنَّمَا يَتَقَبَّلُ ٱللَّهُ مِنَ ٱلۡمُتَّقِينَ")

                    Text("None of this means that a Muslim who has never studied the terms is lost; most Muslims hold the creed of the Salaf by instinct, believing that Allah is above, that the Quran is His word, and that they will see Him, without knowing the names of the sects that denied it. Learning the creed protects that instinct from the doubts of the sects and the slogans of the Khawarij. And a right creed is not a licence to abandon the deeds: faith is belief, statement, and action, and the one who has learned the truth about Allah has the most reason of all to pray and fast.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text("Aqeedah is the knot in the heart, and it is one: the creed of all the prophets, held by every Companion and the Ahlul Bayt alike. The Salaf preserved it as the Athari creed, Imam Ahmad defended it under torture, and the schools of kalam that came three centuries later are measured against it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text("**Aqeedah (عَقِيدَة) and i‘tiqad (اِعتِقَاد)**: aqeedah, from the root ع-ق-د explained above, is the belief itself; i‘tiqad is the verbal noun of i‘taqada, “to hold firmly,” the act of holding it, which is why the classic books carry names like Sharh Usul I‘tiqad Ahl as-Sunnah of al-Lalaka’i (d. 418 AH) and Lum‘at al-I‘tiqad of Ibn Qudamah (d. 620 AH). Nobody founded aqeedah; it is the scholars’ word for what the Quran and Sunnah call iman, and its content was fixed by revelation before any school existed.")
                        .font(.body)

                    Text("**Iman (إِيمَان)**: from the root **أ-م-ن**, which carries both **amn**, security, and **tasdiq**, affirming something as true; the brothers of Yusuf used the same verb when they said “you would not believe us” (Quran 12:17). In the Shari‘ah, iman is belief in the heart, statement on the tongue, and action of the limbs; it increases by obedience and decreases by sin. Al-Bukhari opened the Book of Faith in his Sahih with exactly this definition:")
                        .font(.body)
                    ScriptureQuote(text: "“It is statement and action, and it increases and decreases” (Sahih al-Bukhari, Kitab al-Iman, opening chapter).", arabic: "وَهُوَ قَوْلٌ وَفِعْلٌ، وَيَزِيدُ وَيَنْقُصُ", dimmed: true)

                    Text("Its six pillars are the ones the Prophet (peace be upon him) listed for Jibril in the hadith quoted above (Sahih Muslim 8): belief in Allah, His angels, His books, His messengers, the Last Day, and the decree. The Quran gathers the first five in one verse and names the sixth in another:")
                        .font(.body)
                    ScriptureQuote(text: "“But [true] righteousness is [in] one who believes in Allah, the Last Day, the angels, the Book, and the prophets” (Quran 2:177).", arabic: "وَلَٰكِنَّ ٱلۡبِرَّ مَنۡ ءَامَنَ بِٱللَّهِ وَٱلۡيَوۡمِ ٱلۡأٓخِرِ وَٱلۡمَلَٰٓئِكَةِ وَٱلۡكِتَٰبِ وَٱلنَّبِيِّـۧنَ")
                    ScriptureQuote(text: "“Indeed, all things We created with predestination” (Quran 54:49).", arabic: "إِنَّا كُلَّ شَيۡءٍ خَلَقۡنَٰهُ بِقَدَرٖ")

                    Text("Deeds belong to faith, which is why the Prophet (peace be upon him) counted modesty among its branches:")
                        .font(.body)
                    ScriptureQuote(text: "“Faith (Belief) consists of more than sixty branches (i.e. parts). And Haya (This term ‘Haya’ covers a large number of concepts which are to be taken together; amongst them are self respect, modesty, bashfulness, and scruple, etc.) is a part of faith” (Sahih al-Bukhari 9).", arabic: "الإِيمَانُ بِضْعٌ وَسِتُّونَ شُعْبَةً، وَالْحَيَاءُ شُعْبَةٌ مِنَ الإِيمَانِ", dimmed: true)

                    Text("**Tawhid (تَوحِيد)**: the verbal noun of wahhada, “to make one” or “to single out,” from the root **و-ح-د**: to single Allah out in everything that belongs to Him alone. It is the Prophet’s own word: sending Mu‘adh to Yemen he said, “let the first thing you call them to be that they single out Allah (yuwahhidu Allah)” (Sahih al-Bukhari 7372). The scholars describe what the Quran contains under three headings: **tawhid ar-rububiyyah (تَوحِيد الرُّبُوبِيَّة)**, Allah alone creates, owns, provides, and controls; **tawhid al-uluhiyyah (تَوحِيد الأُلُوهِيَّة)**, Allah alone is worshipped; and **tawhid al-asma’ was-sifat (تَوحِيد الأَسمَاء وَالصِّفَات)**, His names and attributes are affirmed as He affirmed them, without likeness. This is not a new creed but a description, just as “the five pillars of Islam” is a description of what the Prophet (peace be upon him) said (Sahih al-Bukhari 8). One verse carries all three:")
                        .font(.body)
                    ScriptureQuote(text: "“Lord of the heavens and the earth and whatever is between them - so worship Him and have patience for His worship. Do you know of any similarity to Him?” (Quran 19:65).", arabic: "رَّبُّ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ وَمَا بَيۡنَهُمَا فَٱعۡبُدۡهُ وَٱصۡطَبِرۡ لِعِبَٰدَتِهِۦۚ هَلۡ تَعۡلَمُ لَهُۥ سَمِيّٗا")

                    Text("“Lord of the heavens and the earth” is rububiyyah, “so worship Him” is uluhiyyah, and “Do you know of any similarity to Him?” is the names and attributes. Surah al-Ikhlas does the same in four verses:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, Nor is there to Him any equivalent’” (Quran 112:1-4).", arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ ۝ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ۝ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ")

                    Text("**Athar (أَثَر), Athari, Ahl al-Athar, Ahl al-Hadith**: athar, from the root **أ-ث-ر**, is a track or a trace, what someone leaves behind; Allah says He records “what they have put forth and what they left behind (atharahum)” (Quran 36:12). A narration is an athar because it is the trace the Prophet (peace be upon him) and his Companions left. So the creed is named after narration, not after any man, and its people are **Ahl al-Athar (أَهل الأَثَر)** and **Ahl al-Hadith (أَهل الحَدِيث)**; its imam is Ahmad ibn Hanbal, as its own section above explains. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“A group of people amongst my followers will remain obedient to Allah's orders and they will not be harmed by anyone who will not help them or who will oppose them, till Allah's Order (the Last Day) comes upon them while they are still on the right path” (Sahih al-Bukhari 3641, Sahih Muslim 1920).", arabic: "لاَ يَزَالُ مِنْ أُمَّتِي أُمَّةٌ قَائِمَةٌ بِأَمْرِ اللَّهِ، لاَ يَضُرُّهُمْ مَنْ خَذَلَهُمْ وَلاَ مَنْ خَالَفَهُمْ حَتَّى يَأْتِيَهُمْ أَمْرُ اللَّهِ وَهُمْ عَلَى ذَلِكَ", dimmed: true)

                    Text("Imam Ahmad (may Allah have mercy on him) said of this group:")
                        .font(.body)
                    ScriptureQuote(text: "“If this victorious group is not the people of hadith, then I do not know who they are” (al-Hakim, Ma'rifat Ulum al-Hadith, with a chain Ibn Hajar graded sahih; al-Khatib al-Baghdadi, Sharaf Ashab al-Hadith; an-Nawawi, Sharh Sahih Muslim 13/67).", arabic: "إِنْ لَمْ تَكُنْ هَذِهِ الطَّائِفَةُ الْمَنْصُورَةُ أَصْحَابَ الْحَدِيثِ فَلَا أَدْرِي مَنْ هُمْ", dimmed: true)

                    Text("**Kalam (كَلَام) and the mutakallimun (المُتَكَلِّمُون)**: kalam means “speech.” **‘Ilm al-kalam** is theology argued by speech, that is, by rational premises and disputation, instead of received by narration, and the mutakallimun are its practitioners. Its first practitioners in Islam were the Mu‘tazilah; the Ash‘ari and Maturidi schools later took up its tools in order to answer them. The Salaf condemned it by name: ash-Shafi‘i’s verdict is quoted above under Two Roads, and Imam Ahmad said that a man of kalam never prospers, and that you hardly see anyone look into kalam without corruption entering his heart (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm wa-Fadlih).")
                        .font(.body)

                    Text("**Ahl as-Sunnah wal-Jama‘ah (أَهل السُّنَّة وَالجَمَاعَة)**: the Sunnah, from **س-ن-ن**, is a laid-down path, the way of the Prophet (peace be upon him); the Jama‘ah, from **ج-م-ع**, “to gather,” is the united body of the Companions and whoever holds to their way. The name is not a party label: the Jama‘ah is the Prophet’s own name for the saved group (the hadith below), and the Sunnah is what he commanded to be held fast to (Sunan Abi Dawud 4607; graded sahih by al-Albani; quoted above in Common Questions). Having said that this nation would split into seventy-three sects, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“seventy two of them will go to Hell and one of them will go to Paradise, and it is the majority group” (Sunan Abi Dawud 4597; graded hasan by al-Albani).", arabic: "ثِنْتَانِ وَسَبْعُونَ فِي النَّارِ وَوَاحِدَةٌ فِي الْجَنَّةِ وَهِيَ الْجَمَاعَةُ", dimmed: true)

                    Text("Ibn Mas‘ud (may Allah be pleased with him) explained that the Jama‘ah is whatever agrees with the truth, even if you are alone (al-Lalaka’i, Sharh Usul I‘tiqad Ahl as-Sunnah). And Ibn Abbas (may Allah be pleased with them both) is related to have used the very phrase in explaining the verse:")
                        .font(.body)
                    ScriptureQuote(text: "“On the Day [some] faces will turn white and [some] faces will turn black” (Quran 3:106).", arabic: "يَوۡمَ تَبۡيَضُّ وُجُوهٞ وَتَسۡوَدُّ وُجُوهٞۚ")
                    Text("Ibn Kathir (may Allah have mercy on him) relates it from him in his Tafsir at this verse: the faces of Ahl as-Sunnah wal-Jama‘ah will turn white, and the faces of the people of innovation and division will turn black.")
                        .font(.body)

                    Text("**Salaf (سَلَف) and Khalaf (خَلَف)**: salaf, from **س-ل-ف**, is what has gone before; Allah says of a destroyed people, “We made them a precedent (salafan)” (Quran 43:56). In creed, the Salaf are the first three generations, the Companions, the Tabi‘un, and their followers, whom the Prophet (peace be upon him) called the best of people (Sahih al-Bukhari 2652, quoted above). Khalaf, from **خ-ل-ف**, is what comes after; the Quran speaks of “successors (khalf)” who inherited the Scripture and neglected it (Quran 7:169). In the books of creed the Khalaf are the later scholars who took up kalam and reinterpretation. A saying spread among them, “the way of the Salaf is safer, the way of the Khalaf is more knowledgeable and wiser,” and Ibn Taymiyyah (may Allah have mercy on him) answered in al-Fatwa al-Hamawiyyah that the way of the Salaf is safer, more knowledgeable, and wiser all at once, because it is the way of the people who understood revelation best.")
                        .font(.body)

                    Text("**Mu‘tazilah (المُعتَزِلَة)**: from **ع-ز-ل**, i‘tazala, “to withdraw” or “to set oneself apart.” Wasil ibn Ata (80–131 AH) sat in the circle of al-Hasan al-Basri (d. 110 AH) in Basrah. When a man asked about the Muslim who commits a major sin, Wasil answered ahead of his teacher that he is neither a believer nor a disbeliever but in “a station between the two stations,” and withdrew to a pillar of the mosque with those who agreed with him; al-Hasan said, “Wasil has withdrawn from us (i‘tazalana Wasil)” (ash-Shahrastani, al-Milal wan-Nihal). His companion Amr ibn Ubayd (d. 144 AH) joined him, and the name stuck. They built their creed on five principles (al-usul al-khamsah): **tawhid**, by which they meant that Allah is knowing and powerful by His essence with no attributes additional to it, which Ahl as-Sunnah call a denial of the attributes; **‘adl**, “justice,” by which they meant that Allah does not create the servants’ acts; **al-wa‘d wal-wa‘id**, the promise and the threat, by which they meant that the major sinner is in the Fire forever; **al-manzilah bayn al-manzilatayn**, the station between two stations; and **enjoining good and forbidding evil**, by which they justified revolt against the rulers. They called themselves “the people of tawhid and justice”; Ahl as-Sunnah called them the Mu‘tazilah and, for their denial of the decree, the Qadariyyah (al-Ash‘ari, Maqalat al-Islamiyyin; ash-Shahrastani, al-Milal wan-Nihal).")
                        .font(.body)

                    Text("**Ash‘ariyyah (الأَشعَرِيَّة)**: named after Abu al-Hasan Ali ibn Isma‘il al-Ash‘ari (260–324 AH), not after the Companion Abu Musa al-Ash‘ari (may Allah be pleased with him), his ancestor. He was a Mu‘tazili for about forty years under his stepfather al-Jubba’i, renounced them publicly in the mosque of Basrah, and ended by writing al-Ibanah on the creed of Imam Ahmad, as quoted above (Ibn Asakir, Tabyin Kadhib al-Muftari). The school that bears his name follows his middle period rather than his last book: it affirms seven attributes (life, knowledge, power, will, hearing, sight, and speech) by rational proof, reinterprets (**ta’wil**) or consigns the meaning of (**tafwid**) the rest, such as the Hand, the Face, and the rising over the Throne, and proves the existence of Allah by the kalam argument from the origination of bodies rather than by the way of the Quran.")
                        .font(.body)

                    Text("**Maturidiyyah (المَاتُرِيدِيَّة)**: named after Abu Mansur Muhammad ibn Muhammad al-Maturidi (d. 333 AH) of Maturid, a quarter of Samarqand, a Hanafi jurist and the author of Kitab at-Tawhid and Ta’wilat al-Quran; the school is described above under The Schools of Kalam.")
                        .font(.body)

                    Text("**Khawarij (الخَوَارِج), Haruriyyah (الحَرُورِيَّة), al-Muhakkimah (المُحَكِّمَة)**: three names for one sect. Khawarij is from kharaja, “to go out”: they went out against Ali (may Allah be pleased with him), and in the Prophet’s words, quoted above under The Rejected Sects, they “pass out” of the religion. Haruriyyah is from Harura’, the village near Kufah where they first gathered after Siffin; the name was already current among the Companions, for when a woman asked Aisha (may Allah be pleased with her) whether a menstruating woman makes up her prayers, she replied:")
                        .font(.body)
                    ScriptureQuote(text: "“Are you from the Huraura' (a town in Iraq?) We were with the Prophet (ﷺ) and used to get our periods but he never ordered us to offer them (the Prayers missed during menses)” (Sahih al-Bukhari 321).", arabic: "أَحَرُورِيَّةٌ أَنْتِ كُنَّا نَحِيضُ مَعَ النَّبِيِّ صلى الله عليه وسلم فَلاَ يَأْمُرُنَا بِهِ", dimmed: true)

                    Text("Al-Muhakkimah is from their slogan “no judgement (hukm) but Allah’s,” with which they rejected the arbitration (tahkim) between Ali and Mu‘awiyah; Ali’s reply to it is quoted above. Ali fought them at Nahrawan in 38 AH, and one of the Khawarij, Abd ar-Rahman ibn Muljam, struck him down in Kufah in Ramadan 40 AH (Ibn Kathir, al-Bidayah wan-Nihayah; ash-Shahrastani, al-Milal wan-Nihal).")
                        .font(.body)

                    Text("**Jahmiyyah (الجَهمِيَّة)**: the followers of Jahm ibn Safwan (executed 128 AH), who took his ideas from al-Ja‘d ibn Dirham. He denied Allah’s names and attributes altogether, said the Quran is created, that Allah is everywhere and not above His Throne, that faith is bare knowledge in the heart, and that man is compelled in his acts. Salm ibn Ahwaz executed him in Marw in 128 AH (at-Tabari, Tarikh, events of 128 AH; Ibn Kathir, al-Bidayah wan-Nihayah). Before him the governor Khalid ibn Abdillah al-Qasri had said at the Eid prayer in Wasit:")
                        .font(.body)
                    ScriptureQuote(text: "“O people, offer your sacrifices, may Allah accept them from you; I am sacrificing al-Ja‘d ibn Dirham, for he claims that Allah did not take Ibrahim as a close friend and did not speak to Musa. Exalted is Allah far above what al-Ja‘d says.” Then he came down and slaughtered him (al-Bukhari, Khalq Af'al al-'Ibad; ad-Darimi, ar-Radd 'ala al-Jahmiyyah; al-Lalaka'i, Sharh Usul I'tiqad Ahl as-Sunnah).", arabic: "أَيُّهَا النَّاسُ ضَحُّوا تَقَبَّلَ اللَّهُ ضَحَايَاكُمْ، فَإِنِّي مُضَحٍّ بِالْجَعْدِ بْنِ دِرْهَمٍ، إِنَّهُ زَعَمَ أَنَّ اللَّهَ لَمْ يَتَّخِذْ إِبْرَاهِيمَ خَلِيلًا، وَلَمْ يُكَلِّمْ مُوسَى تَكْلِيمًا، تَعَالَى اللَّهُ عَمَّا يَقُولُ الْجَعْدُ عُلُوًّا كَبِيرًا. ثُمَّ نَزَلَ فَذَبَحَهُ", dimmed: true)

                    Text("Every later denial of the attributes, however refined, is a portion of Jahm’s inheritance, which is why the Salaf called the deniers “Jahmiyyah” whatever they called themselves.")
                        .font(.body)

                    Text("**Murji’ah (المُرجِئَة)**: from **ر-ج-أ**, arja’a, “to postpone” or “to defer”; the Quran speaks of “others deferred (murjawn) until the command of Allah” (Quran 9:106). They deferred deeds out of faith: faith, they said, is affirmation only, so sins do not diminish it and the sinner is a believer of complete faith; the extreme form, Jahm’s, makes faith bare knowledge in the heart. The Salaf distinguished this from the milder “irja’ of the jurists” of Kufah, who left deeds out of the definition of faith yet affirmed that sins are punished and commanded the deeds; they disagreed with the latter as an error in wording and with the former as a heresy (Ibn Taymiyyah, Kitab al-Iman).")
                        .font(.body)

                    Text("**Qadariyyah (القَدَرِيَّة)**: named after **qadar (قَدَر)**, the decree, which they denied; they said Allah does not decree the servants’ deeds and that each man originates his own action, so that the matter is “new” and unforeknown. The first to say it was Ma‘bad al-Juhani in Basrah, as Yahya ibn Ya‘mur reported when he brought the matter to Ibn Umar (Sahih Muslim 8, quoted above under The Schools of Kalam), then Ghaylan of Damascus, and the Mu‘tazilah inherited it from them.")
                        .font(.body)

                    Text("**Jabriyyah (الجَبرِيَّة)**: from **jabr (جَبر)**, compulsion: the opposite error, that man has no real will or act at all and is moved like a feather in the wind. This was Jahm’s view. Ahl as-Sunnah stand between the two: Allah creates all things, including the servants’ acts, and the servant truly wills, chooses, and acts, and is justly rewarded or punished; see the question on the decree above.")
                        .font(.body)

                    Text("**Rafidah (الرَّافِضَة)**: from **rafada (رَفَضَ)**, “to reject” or “to desert.” In 122 AH Zayd ibn Ali ibn al-Husayn (may Allah have mercy on him), the grandson of al-Husayn, rose in Kufah against the Umayyads. Those who had pledged to him demanded that he disavow Abu Bakr and Umar. He refused and said they were his grandfather’s two ministers, so they deserted him, and he said, “You have rejected me (rafadtumuni).” Those who deserted him were called the Rafidah, and the Zaydiyyah are those who stayed with Zayd (ash-Shahrastani, al-Milal wan-Nihal; Ibn Taymiyyah, Minhaj as-Sunnah; Ibn Kathir, al-Bidayah wan-Nihayah, events of 122 AH). The Rafidah reject the Companions who transmitted the religion, and so cast away the very channel it reached us through; see “Answering the Shia” under Salafiyyah.")
                        .font(.body)

                    Text("**The four errors in the attributes**: **tahrif (تَحرِيف)**, from **ح-ر-ف**, to turn a word from its place, as the Quran says of those who “distort words from their [proper] usages” (Quran 4:46): changing the meaning of a text, such as reading “rose over” as “conquered”; **ta‘til (تَعطِيل)**, from **ع-ط-ل**, to leave idle or empty, as in “an abandoned well” (Quran 22:45): stripping Allah of the attribute altogether; **takyif (تَكيِيف)**, from kayfa, “how”: assigning a manner to the attribute; and **tamthil (تَمثِيل)**, from mithl, “a likeness”: likening it to the attributes of creation. To these the scholars add **tafwid al-ma‘na (تَفوِيض المَعنَى)**, consigning the meaning: the claim that the Salaf recited the texts of the attributes without knowing what they meant. The Salaf consigned only the “how,” never the meaning; Imam Malik’s “the rising is not unknown,” quoted above under Two Roads, says so plainly. Ibn Taymiyyah (may Allah have mercy on him) wrote:")
                        .font(.body)
                    ScriptureQuote(text: "“The position of the people of tafwid, who claim to be following the Sunnah and the Salaf, is among the worst of the positions of the people of innovation and heresy” (Ibn Taymiyyah, Dar' Ta'arud al-'Aql wan-Naql 1/205).", arabic: "قَوْلُ أَهْلِ التَّفْوِيضِ الَّذِينَ يَزْعُمُونَ أَنَّهُمْ مُتَّبِعُونَ لِلسُّنَّةِ وَالسَّلَفِ مِنْ شَرِّ أَقْوَالِ أَهْلِ الْبِدَعِ وَالْإِلْحَادِ", dimmed: true)

                    Text("**Istiwa’ (اِستِوَاء)**: from **س-و-ي**; istawa ‘ala means to rise over and settle upon. Allah says of Himself in seven places that He “established Himself above the Throne” (Quran 7:54, 10:3, 13:2, 20:5, 25:59, 32:4, 57:4). In the Book of Tawhid of his Sahih, al-Bukhari related from the Tabi‘i Abu al-‘Aliyah that istawa means “He rose (irtafa‘a),” and from Mujahid that it means “He ascended over (‘ala) the Throne.” The Jahmiyyah denied it, the later kalam schools read it as istawla, “He conquered,” a reading the Salaf rejected and the Arabs never used, and Malik (may Allah have mercy on him) gave the rule that settles it, quoted above.")
                        .font(.body)

                    Text("**Bid‘ah (بِدعَة)**: from **ب-د-ع**, to originate something with no precedent; Allah is “Originator (Badi‘) of the heavens and the earth” (Quran 2:117) because He made them from nothing. In the religion, a bid‘ah is a newly invented way of worship that has no basis from the Prophet (peace be upon him), practised as though it were part of the religion (ash-Shatibi, al-I‘tisam). He said:")
                        .font(.body)
                    ScriptureQuote(text: "“If somebody innovates something which is not in harmony with the principles of our religion, that thing is rejected” (Sahih al-Bukhari 2697, Sahih Muslim 1718).", arabic: "مَنْ أَحْدَثَ فِي أَمْرِنَا هَذَا مَا لَيْسَ فِيهِ فَهُوَ رَدٌّ", dimmed: true)

                    Text("and in his sermons he used to say, “every innovation is misguidance” (Sahih Muslim 867). Innovations in creed are the gravest kind, because they are inventions about Allah Himself.")
                        .font(.body)

                    Text("**The hadith of the seventy-three sects**: the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The Jews were split up into seventy-one or seventy-two sects; and the Christians were split up into seventy one or seventy-two sects; and my community will be split up into seventy-three sects” (Sunan Abi Dawud 4596; graded hasan sahih by al-Albani).", arabic: "افْتَرَقَتِ الْيَهُودُ عَلَى إِحْدَى أَوْ ثِنْتَيْنِ وَسَبْعِينَ فِرْقَةً وَتَفَرَّقَتِ النَّصَارَى عَلَى إِحْدَى أَوْ ثِنْتَيْنِ وَسَبْعِينَ فِرْقَةً وَتَفْتَرِقُ أُمَّتِي عَلَى ثَلاَثٍ وَسَبْعِينَ فِرْقَةً", dimmed: true)

                    Text("Together with the report of Mu‘awiyah above, which names the saved sect as the Jama‘ah, this is the foundation of the Salaf’s writing about the sects. Ibn Taymiyyah (may Allah have mercy on him) added a caution in Majmu‘ al-Fatawa: the Prophet counted all seventy-three as “my nation,” so belonging to a deviant sect is a threat of the Fire, not by itself disbelief, and whoever declares every one of the seventy-two sects a disbeliever has opposed the Book, the Sunnah, and the consensus of the Companions and the four imams.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "AqeedahMadhabView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Madhahib of Aqeedah")
        .selectableArticleList()
    }
}
