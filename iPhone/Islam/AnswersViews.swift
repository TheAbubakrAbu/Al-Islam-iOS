import SwiftUI

/// The "Answering Other Paths" articles: replies from the Quran and the Sunnah to Sufism, the Shia,
/// Christianity, Judaism, Hinduism, paganism, Buddhism, and atheism, each ending with the invitation.

struct SufismAnswerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: purifying the heart is part of Islam, but the later Sufi orders added intermediaries, grave veneration, invented dhikr, absolute obedience to shaykhs, and claims that Allah dwells in or is one with creation. Each of these is answered by the Quran and the Sunnah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT IS SUFISM?")) {
                    Text(articleMarkdown: "**Tasawwuf (تَصَوُّف)**, Sufism, is named after **suf (صُوف)**, wool, for the coarse woollen garments the early ascetics wore. It began as a name for asceticism and devotion in the second and third centuries AH. The early ascetics of the Salaf, such as al-Fudayl ibn Iyad and Ibn al-Mubarak, were men of the Sunnah, and the purification of the heart (**tazkiyah**) is a duty in the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "91:9-10")

                    Text(articleMarkdown: "Over the centuries, however, organised **tariqahs (طُرُق)** appeared: a **tariqah (طَرِيقَة)**, from ط-ر-ق, is a road, and here an order with its own way of travelling to Allah. Each had a **shaykh (شَيخ)**, an elder or master, a pledge of obedience to him (**bay‘ah (بَيعَة)**, from ب-ي-ع, the pledge sealed by a clasp of hands), set formulas of **dhikr (ذِكر)**, the remembrance of Allah, and ranks of “saints,“ and ideas entered that the Salaf never knew: seeking help from the dead, building over graves, dhikr with music and dancing, the shaykh’s word above the text, and the doctrines of **hulul (حُلُول)**, from ح-ل-ل, to alight and dwell in a place (Allah dwelling in creation), and **wahdat al-wujud (وَحدَة الوُجُود)**, the oneness of being (that creation and Creator are one). Even al-Junayd (d. 297 AH), whom the Sufis take as their imam, tied the whole matter to the Sunnah:")
                        .font(.body)
                    ScriptureQuote(text: "“All the paths are closed to the creation except for the one who follows the footsteps of the Messenger” (al-Junayd, in al-Qushayri, ar-Risalah).", arabic: "الطُّرُقُ كُلُّهَا مَسدُودَةٌ عَلَى الخَلقِ إِلَّا عَلَى مَنِ اقتَفَى أَثَرَ الرَّسُولِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ", dimmed: true)
                }

                Section(header: ArticleHeader("1. CLOSENESS TO ALLAH IS THROUGH WHAT HE LEGISLATED")) {
                    Text(articleMarkdown: "The Sufi orders offer a “path“ to Allah of their own devising. But Allah told us who His **awliya’ (أَولِيَاء)**, from و-ل-ي, nearness (the singular is **wali (وَلِي)**, a close friend of Allah), are and how they reach Him:")
                        .font(.body)
                    ScriptureQuote(quran: "10:62-63")

                    Text(verbatim: "And in the hadith qudsi:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:6502", cite: "Sahih al-Bukhari 6502", arabic: 45...62, english: 21...65)

                    Text(verbatim: "Obligations first, then the voluntary acts the Prophet (peace be upon him) taught. There is no third road of secret litanies, and no rank of wali reached by other than faith and taqwa.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. NO INTERMEDIARIES BETWEEN THE SERVANT AND ALLAH")) {
                    Text(articleMarkdown: "Calling upon dead saints, prophets, or shaykhs for help, children, or rescue, the **istighathah** practised at shrines, is the shirk that the Quran was revealed against. The pagans of Makkah did exactly this, and with the same excuse:")
                        .font(.body)
                    ScriptureQuote(quran: "39:3", words: 4...32)

                    ScriptureQuote(quran: "46:5-6")

                    ScriptureQuote(quran: "35:14", words: 0...13)

                    Text(verbatim: "Allah is near without any go-between:")
                        .font(.body)
                    ScriptureQuote(quran: "2:186", words: 0...10)

                    Text(verbatim: "The Companions understood this. In a drought, Umar (may Allah be pleased with him) did not go to the Prophet’s grave, a few steps away, to ask him; he asked the Prophet’s living uncle to supplicate:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1010", cite: "Sahih al-Bukhari 1010", arabic: 45...59, text: "“O Allah! We used to ask our Prophet to invoke You for rain, and You would bless us with rain, and now we ask his uncle to invoke You for rain. O Allah! Bless us with rain”")

                    Text(verbatim: "And the Prophet (peace be upon him) taught Ibn Abbas:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:2516", cite: "Sunan al-Tirmidhi 2516; graded sahih by al-Albani", arabic: 72...79, english: 38...50)
                }

                Section(header: ArticleHeader("3. GRAVES ARE NOT SHRINES")) {
                    Text(verbatim: "The domes, tombs, and festivals at the graves of the “saints“ are the opposite of what the Prophet (peace be upon him) commanded. Ali (may Allah be pleased with him) said to Abu al-Hayyaj:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:969a", cite: "Sahih Muslim 969", arabic: 40...62, english: 0...29)

                    ScriptureQuote(hadith: "muslim:972a", cite: "Sahih Muslim 972", arabic: 33...39, english: 0...12)

                    Text(verbatim: "Five days before his death he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:532", cite: "Sahih Muslim 532", arabic: 91...110, english: 65...100)

                    ScriptureQuote(hadith: "bukhari:1330", cite: "Sahih al-Bukhari 1330, Sahih Muslim 529", arabic: 36...43, english: 10...28)
                }

                Section(header: ArticleHeader("4. INVENTED DHIKR AND GATHERINGS")) {
                    Text(verbatim: "Dhikr is the life of the heart, and the Prophet (peace be upon him) taught its words, times, and numbers. The set formulas, counted litanies, swaying circles, music, and dancing of the orders are not from him. When the Companions saw men counting dhikr in circles in the mosque of Kufah, Ibn Mas‘ud (may Allah be pleased with him) said to them:")
                        .font(.body)
                    ScriptureQuote(hadith: "darimi:206", cite: "Sunan al-Darimi 206; graded sahih by al-Albani, as-Silsilah as-Sahihah 2005", arabic: 230...245, text: "“By the One in whose hand is my soul, either you are upon a religion more guided than the religion of Muhammad, or you are opening a door of misguidance”")

                    ScriptureQuote(hadith: "muslim:867a", cite: "Sahih Muslim 867", arabic: 73...78, english: 102...114)

                    Text(verbatim: "As for music in worship, the Prophet (peace be upon him) counted musical instruments among the things people would try to make lawful (Sahih al-Bukhari 5590). Worship with drums and flutes is not the Sunnah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("5. NO EXCESS IN ASCETICISM")) {
                    Text(verbatim: "The severe self-denial of some orders, withdrawal from marriage and society, and hunger as worship come from monasticism, which Allah said the Christians invented:")
                        .font(.body)
                    ScriptureQuote(quran: "57:27", words: 18...22)

                    ScriptureQuote(quran: "5:87")

                    Text(verbatim: "When three men resolved to pray all night, fast every day, and never marry, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:5063", cite: "Sahih al-Bukhari 5063", arabic: 105...124, english: 113...161)
                }

                Section(header: ArticleHeader("6. THE SHAYKH IS NOT ABOVE THE TEXT")) {
                    Text(articleMarkdown: "The orders teach that the disciple must be before his shaykh “like a corpse in the hands of its washer,“ and that the shaykh’s unveilings (**kashf (كَشف)**, from ك-ش-ف, to uncover) are a source of knowledge beside revelation. Allah described people who gave their scholars that place:")
                        .font(.body)
                    ScriptureQuote(quran: "9:31", words: 0...6)

                    ScriptureQuote(quran: "7:3")

                    Text(verbatim: "Revelation ended with the Prophet (peace be upon him). No dream, vision, or intuition of any shaykh adds to it or overrides it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("7. ALLAH IS NOT HIS CREATION")) {
                    Text(verbatim: "The doctrines of hulul and wahdat al-wujud, associated with al-Hallaj (d. 309 AH) and Ibn Arabi (d. 638 AH), say that Allah dwells in creation or that everything is Him. This is not Islam by any school. Allah is the Creator, separate from and above His creation, and nothing is like Him:")
                        .font(.body)
                    ScriptureQuote(quran: "42:11", words: 13...18)

                    ScriptureQuote(quran: "112:1-4")

                    ScriptureQuote(quran: "7:54", words: 0...13)

                    Text(verbatim: "His nearness to His servants is by His knowledge, hearing, and help, not by mixing with them:")
                        .font(.body)
                    ScriptureQuote(quran: "50:16")
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Is all tasawwuf condemned?**")
                        .font(.body)
                    Text(verbatim: "No, and fairness is part of the religion. Ibn Taymiyyah (may Allah have mercy on him) gives the balanced verdict in Majmu‘ al-Fatawa (11/16-18): the early ascetics were people striving in the obedience of Allah as others strove, some of them foremost and drawn near, some moderate, and among both kinds were those who erred in their striving and those who sinned and repented or did not; so the truth is neither to accept everything called Sufism nor to condemn everyone called a Sufi. Adh-Dhahabi honours al-Fudayl ibn Iyad, Ibrahim ibn Adham, and al-Junayd in Siyar A‘lam an-Nubala’ as imams of worship and the Sunnah, and al-Junayd’s own words about the Sunnah were quoted above. The criterion is not the name but the Sunnah: what agrees with the Book and the Sunnah is accepted, whoever said it, and what opposes them is rejected, whoever said it.")
                        .font(.body)

                    Text(articleMarkdown: "**Were Ibn Taymiyyah, Ibn al-Qayyim, or an-Nawawi Sufis?**")
                        .font(.body)
                    Text(verbatim: "None of them took a tariqah, gave bay‘ah to a shaykh, or practised the rites of the orders. Ibn al-Qayyim’s Madarij as-Salikin is a commentary on Manazil as-Sa’irin of Abu Isma‘il al-Harawi (d. 481 AH), a Hanbali of Herat who defended the creed of the Salaf; Ibn al-Qayyim praises him where he is right and corrects him openly where his expressions slip toward fana’ (فَنَاء, the passing away of the self) and ittihad (اِتِّحَاد, union with Allah), saying:")
                        .font(.body)
                    ScriptureQuote(text: "“Shaykh al-Islam is beloved to us, but the truth is more beloved to us than him” (Ibn al-Qayyim, Madarij as-Salikin).", arabic: "شَيخُ الإِسلَامِ حَبِيبٌ إِلَينَا، وَالحَقُّ أَحَبُّ إِلَينَا مِنهُ", dimmed: true)

                    Text(verbatim: "Ibn Taymiyyah wrote on the stations of the heart, on the awliya’, and on the errors of the orders in the same volumes in which he defended the early ascetics. An-Nawawi wrote Riyad as-Salihin and al-Adhkar to return remembrance and conduct to the texts. These scholars took the science of the heart from the Quran and the Sunnah and judged the Sufis by them; that is not membership of an order.")
                        .font(.body)

                    Text(articleMarkdown: "**Is ihsan and purifying the soul (tazkiyah) Sufism?**")
                        .font(.body)
                    Text(articleMarkdown: "**Ihsan (إِحسَان)**, from ح-س-ن, to do a thing well and beautifully, is what the Prophet (peace be upon him) defined as worshipping Allah as though you see Him; **tazkiyah (تَزكِيَة)**, from ز-ك-و, to grow and to be purified, is the purifying of the soul. Both are Islam itself. Allah made purification one of the purposes of sending the Messenger (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(quran: "2:151")

                    Text(verbatim: "He declared success for the one who purifies his soul (Quran 91:9-10, quoted above), and the Prophet (peace be upon him) defined ihsan in the hadith of Jibril (Sahih Muslim 8, quoted above). Whoever wants tazkiyah has it in the Quran, the prayer, the fast, dhikr as taught, and the company of the righteous, and he needs no order to reach it.")
                        .font(.body)

                    Text(articleMarkdown: "**Is gathering for dhikr an innovation?**")
                        .font(.body)
                    Text(verbatim: "Gathering to learn, to recite, and to remember Allah as He is remembered in the Sunnah is beloved to Allah. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2700a", cite: "Sahih Muslim 2700", arabic: 42...60, english: 25...62)

                    Text(verbatim: "What is rejected is the invented form: chanting in unison, counted formulas assigned by a shaykh, swaying, drums, and the belief that these are the path. That is exactly what Ibn Mas‘ud (may Allah be pleased with him) denounced in Kufah (Sunan al-Darimi 206, quoted in section 4): the men in those circles were counting Allahu Akbar, la ilaha illa Allah, and subhan Allah a hundred times each on pebbles, words of truth, and he still called it a door of misguidance because the form was not from the Prophet (peace be upon him). When they protested that they had intended only good, he answered that many who intend good never reach it.")
                        .font(.body)

                    Text(articleMarkdown: "**Are prayer beads allowed?**")
                        .font(.body)
                    Text(verbatim: "The Sunnah is to count on the fingers. The Prophet (peace be upon him) commanded the believing women to keep up the takbir, taqdis, and tahlil and:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:1501", cite: "Sunan Abi Dawud 1501; graded hasan by al-Albani", arabic: 30...35, english: 34...51)

                    Text(verbatim: "Ibn Taymiyyah held that counting on the fingers is the Sunnah, that counting with date stones or pebbles is good, and that a string of beads is permissible and not disliked when the intention is sound, though some of the scholars disliked it (Majmu‘ al-Fatawa, vol. 22). What is rejected is making the beads a badge of the order, or a thing worn for show.")
                        .font(.body)

                    Text(articleMarkdown: "**Do the awliya’ have karamat, and may we ask them for help?**")
                        .font(.body)
                    Text(verbatim: "They may have karamat, as shown above from the Quran and the Sahih. Allah tells of the one who brought the throne of the queen of Saba’ to Sulayman:")
                        .font(.body)
                    ScriptureQuote(quran: "27:40", words: 0...13)

                    Text(verbatim: "But a karamah (كَرَامَة, from ك-ر-م, honour: an honour Allah grants a righteous believer without his asking) gives the servant no share in what belongs to Allah. The dead do not hear the callers, and they will disown those who called them (Quran 35:14 and 46:5-6, quoted in section 2). Calling upon a dead wali for a need is the shirk of the Arabs who said “that they may bring us nearer to Allah“ (Quran 39:3, quoted in section 2); asking a living, present, able person for what he can do is permitted, and asking a righteous living person to supplicate for you is what Umar did with al-Abbas (Sahih al-Bukhari 1010, quoted in section 2).")
                        .font(.body)

                    Text(articleMarkdown: "**May we seek blessing from a shaykh’s body, clothes, or grave?**")
                        .font(.body)
                    Text(verbatim: "Tabarruk with the person was specific to the Prophet (peace be upon him) in his lifetime: when he shaved his head at Mina, the Companions took his hair, and Abu Talhah was the first to receive it (Sahih al-Bukhari 171; Sahih Muslim 1305). They did not do this with Abu Bakr, Umar, Uthman, or Ali, who were the best of people after him, and ash-Shatibi notes in al-I‘tisam that this leaving was an agreement among them that such things belonged to the Prophet alone. As for graves, the Prophet (peace be upon him) forbade taking them as places of worship five days before his death (Sahih Muslim 532, quoted in section 3), and Ibn Taymiyyah explains in Iqtida’ as-Sirat al-Mustaqim that seeking blessing at graves is the road to worshipping their occupants.")
                        .font(.body)

                    Text(articleMarkdown: "**Is the division into shari‘ah, tariqah, and haqiqah valid?**")
                        .font(.body)
                    Text(articleMarkdown: "No. The three words are Arabic: **shari‘ah (شَرِيعَة)**, from ش-ر-ع, is the path to water, and so the revealed law; **tariqah (طَرِيقَة)** is a road; and **haqiqah (حَقِيقَة)**, from ح-ق-ق, is the reality of a thing. But dividing the religion into an outer law for the common people, an order for the disciple, and an inner reality above the law is an invention: Allah gave the Prophet (peace be upon him) one way and commanded him to follow it:")
                        .font(.body)
                    ScriptureQuote(quran: "45:18")

                    Text(verbatim: "The Book was sent as a criterion over what preceded it (Quran 5:48), and there is no reality above it that frees anyone from it. The claim that the elite reach a haqiqah where the shari‘ah no longer binds them is answered by the Prophet’s words to the three men who wanted more than his Sunnah: “Whoever turns away from my Sunnah is not of me“ (Sahih al-Bukhari 5063, quoted in section 5). The shari‘ah is the haqiqah, and the tariqah is the Sunnah.")
                        .font(.body)

                    Text(articleMarkdown: "**Was the Prophet created from light before everything else?**")
                        .font(.body)
                    Text(verbatim: "No. Allah commanded him to say:")
                        .font(.body)
                    ScriptureQuote(quran: "18:110", words: 0...10)

                    Text(verbatim: "The report attributed to Jabir, that the first thing Allah created was the light of your Prophet, has no known sound chain, and al-Albani ruled it baseless (as-Silsilah ad-Da‘ifah). What the authentic Sunnah says is:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:4700", cite: "Sunan Abi Dawud 4700; graded sahih by al-Albani", arabic: 57...78, english: 44...77)

                    Text(verbatim: "The Prophet (peace be upon him) is the best of creation, but he was created as a man, from the offspring of Adam, and his honour is in his servitude and his message, not in a light that would make him other than a man.")
                        .font(.body)

                    Text(articleMarkdown: "**Is pledging bay‘ah to a shaykh required?**")
                        .font(.body)
                    Text(verbatim: "No. In the Sunnah, bay‘ah is a pledge to the ruler to hear and obey in what is good. Ubadah ibn as-Samit (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:7199", cite: "Sahih al-Bukhari 7199, Sahih Muslim 1709", arabic: 20...52, english: 0...77)

                    Text(verbatim: "There is no pledge to a shaykh in the Quran, in the Sunnah, or among the Companions. The only absolute following is of the Prophet (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(quran: "3:31", words: 0...10)

                    Text(articleMarkdown: "**Is fana’ or wahdat al-wujud part of Islam?**")
                        .font(.body)
                    Text(verbatim: "No. The Creator is other than His creation; He originated everything, and nothing is like Him (Quran 42:11 and Surat al-Ikhlas, quoted in section 7):")
                        .font(.body)
                    ScriptureQuote(quran: "6:101")

                    Text(verbatim: "The one who claims that his existence is Allah’s existence, or that he has passed away into Him, has denied the difference between the Creator and the created that every prophet was sent to teach. Ibn Taymiyyah refuted the people of ittihad at length, showing that their doctrine ends in declaring the idolaters right, since if everything is Him then nothing was ever worshipped but Him (Majmu‘ al-Fatawa, vol. 2). Whoever is overcome by a state and says such a word without meaning it is excused for his state, but the state is not the path and the word is not the truth.")
                        .font(.body)

                    Text(articleMarkdown: "**Is music in dhikr allowed?**")
                        .font(.body)
                    Text(verbatim: "No. The Prophet (peace be upon him) counted instruments among the things people would try to make lawful (Sahih al-Bukhari 5590, cited in section 4), and Ibn Mas‘ud (may Allah be pleased with him) swore by Allah that the “amusement of speech“ in this ayah is singing, as Ibn Kathir records in his tafsir:")
                        .font(.body)
                    ScriptureQuote(quran: "31:6")

                    Text(verbatim: "If instruments are forbidden in leisure, they are further from being a means of worship. Dhikr in the Sunnah is with the tongue and the heart, in the words the Prophet (peace be upon him) taught, with dignity and without a drum.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE INVITATION")) {
                    Text(verbatim: "What is true in Sufism, sincerity, remembrance, weeping over sin, love of Allah and His Messenger, is all in the Sunnah already, without the additions. The books of Ibn al-Qayyim, especially Madarij as-Salikin and al-Wabil as-Sayyib, take the whole science of the heart and return it to the Quran and the Sunnah. The one who wants Allah finds Him on the road of His Messenger, and the Prophet (peace be upon him) said of that road, in the hadith qudsi:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:7405", cite: "Sahih al-Bukhari 7405", arabic: 56...74, english: 74...120)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Purify the heart by the Sunnah, call upon Allah alone, leave the graves as the Prophet left them, and keep every shaykh beneath the text. That is the tazkiyah of the Salaf, and it needs no order.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Sufi / tasawwuf (صُوفِيّ / تَصَوُّف)**: from **suf (صُوف)**, wool, after the coarse woollen garments worn by the early ascetics. Ibn Taymiyyah (may Allah have mercy on him) records that the name was not current in the first three generations, that the Sufis first appeared in Basra, and that the first small lodge of the Sufis was built there by some of the companions of Abd al-Wahid ibn Zayd, himself a companion of al-Hasan al-Basri (Majmu‘ al-Fatawa 11/5-7). He also shows why the other proposed origins fail the rules of Arabic derivation: the relative adjective from **as-Suffah** (the poor Companions who lived in the Prophet’s mosque) would be Suffi, from **as-saff** (the first row in prayer) it would be Saffi, and from **as-safwah** (the elect) it would be Safawi; so the name goes back to wool. The Greek **sophia** (wisdom), which some later writers proposed, is not an Arabic root at all. Al-Qushayri, himself a Sufi, admits in ar-Risalah that no analogy or derivation in the Arabic language supports the name and that it is rather like a nickname, and Ibn Khaldun (al-Muqaddimah) judges wool the most likely origin. The Companions and the Tabi‘in never used the word; their names for the matter were faith, worship, and zuhd.")
                        .font(.body)

                    Text(articleMarkdown: "**Zuhd (زُهد)**: from ز-ه-د, to turn away from a thing because one has no desire for it. True asceticism is not rags, hunger, or withdrawal from people; it is the heart’s freedom from the world. Ibn al-Qayyim relates from his teacher Ibn Taymiyyah that zuhd is to leave what does not benefit in the Hereafter, and wara‘ (scrupulousness) is to leave what one fears will harm there (Madarij as-Salikin). The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2956", cite: "Sahih Muslim 2956", arabic: 28...32, english: 0...12)
                    ScriptureQuote(hadith: "bukhari:6416", cite: "Sahih al-Bukhari 6416", arabic: 41...48, english: 14...26)

                    Text(articleMarkdown: "**Tariqah (طَرِيقَة)**, pl. turuq: “way,“ from ط-ر-ق; in Sufi usage an organised order with its own chain of shaykhs, litany, and rites. The major orders and the men they are named after: the **Qadiriyyah** after Abd al-Qadir al-Jilani (d. 561 AH), a Hanbali preacher of Baghdad whose own book al-Ghunyah affirms the creed of the Salaf, and whose later followers went far beyond him; the **Rifa‘iyyah** after Ahmad ar-Rifa‘i (d. 578 AH); the **Shadhiliyyah** after Abu al-Hasan ash-Shadhili (d. 656 AH); the **Naqshbandiyyah** after Baha’ ad-Din Naqshband (d. 791 AH); and the **Tijaniyyah** after Ahmad at-Tijani (d. 1230 AH). None of them existed in the three generations the Prophet (peace be upon him) called the best of people (Sahih al-Bukhari 2652), and a way to Allah that the best generations did not know is not the way of the Prophet (peace be upon him).")
                        .font(.body)

                    Text(articleMarkdown: "**Shaykh / murshid (شَيخ / مُرشِد)**: the head of an order; murshid is from ر-ش-د, to guide aright. The orders make his word binding on the disciple. In Islam the only man who is followed absolutely is the Messenger (peace be upon him); everyone else is followed when he agrees with the Book and the Sunnah and left when he departs from them.")
                        .font(.body)

                    Text(articleMarkdown: "**Murid (مُرِيد)**: “the one who wills,“ from إِرَادَة: the disciple who has handed his will over to a shaykh.")
                        .font(.body)

                    Text(articleMarkdown: "**Bay‘ah (بَيعَة)**: a pledge, from ب-ي-ع, to conclude a deal by clasping hands. In the Sunnah, bay‘ah is given to the Prophet (peace be upon him) and after him to the Muslim ruler, to hear and obey in what is good (Sahih al-Bukhari 7199, Sahih Muslim 1709); the orders moved it to the shaykh, with a rite of hand-clasping and a sworn litany.")
                        .font(.body)

                    Text(articleMarkdown: "**Wird / awrad (وِرد / أَورَاد)**: a set daily portion of remembrance, from و-ر-د, to come down to water. Among the Salaf a man’s wird was his nightly portion of Quran and prayer; the orders assigned fixed formulas and counts composed by the shaykh.")
                        .font(.body)

                    Text(articleMarkdown: "**Hadrah (حَضرَة)**: “presence“: the collective dhikr gathering of the orders, with swaying, drumming, and chanting in unison.")
                        .font(.body)

                    Text(articleMarkdown: "**Sama‘ (سَمَاع)**: “listening“: dhikr with singing and instruments, often with dancing. The Prophet (peace be upon him) counted musical instruments among the things people would try to make lawful (Sahih al-Bukhari 5590, cited in section 4 below).")
                        .font(.body)

                    Text(articleMarkdown: "**Wali / awliya’ (وَلِيّ / أَولِيَاء)**: from و-ل-ي, nearness and support. The Quran defines the awliya’ of Allah as every believer who fears Him (Quran 10:62-63, quoted in section 1 below), not a class of appointed saints. Ibn Taymiyyah’s book al-Furqan bayna Awliya’ ar-Rahman wa Awliya’ ash-Shaytan makes following the Sunnah the only test of wilayah.")
                        .font(.body)

                    Text(articleMarkdown: "**Karamah (كَرَامَة)**: an honour that Allah grants a righteous servant, from ك-ر-م, nobility and generosity. Ahl as-Sunnah affirm karamat: the provision Maryam received in her prayer chamber, the People of the Cave who slept for centuries (Quran 18:9-26), the throne of the queen of Saba’ brought by one who had knowledge of the Scripture (Quran 27:40), and the light that went before Usayd ibn Hudayr and Abbad ibn Bishr on a dark night (Sahih al-Bukhari 3805). Of Maryam, Allah said:")
                        .font(.body)
                    ScriptureQuote(quran: "3:37", words: 9...33)

                    Text(verbatim: "A karamah is a gift, not a rank; it proves nothing about a person unless he follows the Sunnah, and it never makes him someone to be called upon.")
                        .font(.body)

                    Text(articleMarkdown: "**Fana’ / baqa’ (فَنَاء / بَقَاء)**: “passing away“ and “subsistence“: the claim that the self is annihilated in the witnessing of Allah until nothing but He is seen. Ibn Taymiyyah distinguishes three things called fana’: passing away from willing anything other than Allah, which is the state of the prophets and their followers; passing away from witnessing other than Him, which is a weakness that overcomes some worshippers and is not a goal; and the claim that nothing other than Him exists, which is the doctrine of hulul and ittihad (Majmu‘ al-Fatawa, vol. 10).")
                        .font(.body)

                    Text(articleMarkdown: "**Hulul (حُلُول)**: “indwelling,“ from ح-ل-ل, to alight in a place: the claim that Allah dwells in a creature. **Ittihad (اتِّحَاد)**: “union“: the claim that the servant becomes one with Allah. **Wahdat al-wujud (وَحدَة الوُجُود)**: “the oneness of existence“: the doctrine of Ibn Arabi (d. 638 AH) that the existence of creation is the very existence of the Creator. Al-Hallaj (d. 309 AH) was executed in Baghdad for heresy; the words “Ana al-Haqq“ (I am the Truth) are attributed to him. Ibn Taymiyyah refuted this doctrine at length (Majmu‘ al-Fatawa, vol. 2), and section 7 below answers it from the Quran.")
                        .font(.body)

                    Text(articleMarkdown: "**Qutb / ghawth / abdal (قُطب / غَوث / أَبدَال)**: “axis,“ “succour,“ and “substitutes“: in the orders, a hidden hierarchy of saints who are said to govern the world, the ghawth being the one people cry to for help. Ibn Taymiyyah says that the names ghawth, awtad, aqtab, and nujaba’ are found neither in the Book of Allah nor in any report from the Prophet (peace be upon him), and that the one term with a report behind it, the abdal, rests on a chain that is not established (Majmu‘ al-Fatawa, vol. 11); Ibn al-Qayyim rules that the hadiths of the abdal, aqtab, aghwath, nuqaba’, nujaba’, and awtad are all baseless attributions to the Messenger of Allah (al-Manar al-Munif). No creature governs the world; that belongs to Allah alone.")
                        .font(.body)

                    Text(articleMarkdown: "**Kashf (كَشف)**: “unveiling“: an inspiration or vision claimed as a source of knowledge. Revelation ended with the last of the prophets (Quran 33:40), and no kashf is a proof in the religion; it is judged by the texts, never the reverse.")
                        .font(.body)

                    Text(articleMarkdown: "**Khalwah (خَلوَة)**: “seclusion“: a retreat, often of forty days, in a cell with fasting and litanies set by the shaykh. The retreat of the Sunnah is i‘tikaf in the mosque, which the Prophet (peace be upon him) practised in the last ten nights of Ramadan until he died (Sahih al-Bukhari 2026).")
                        .font(.body)

                    Text(articleMarkdown: "**Shari‘ah / tariqah / haqiqah (شَرِيعَة / طَرِيقَة / حَقِيقَة)**: the claimed three levels of the religion: the outer law, the Sufi path, and the inner reality that the elite reach. Answered under Common Questions below.")
                        .font(.body)

                    Text(articleMarkdown: "**Ihsan (إِحسَان)**: “doing well,“ from ح-س-ن, beauty and excellence; the third level of the religion in the hadith of Jibril, after Islam and iman. The Prophet (peace be upon him) defined it:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:8a", cite: "Sahih Muslim 8", arabic: 297...307, english: 470...489)

                    Text(verbatim: "This is the real spiritual path: worship with the presence of the heart, inside the shari‘ah, needing no order.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SufismAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Sufism")
        .selectableArticleList(article: "SufismAnswerView")
    }
}

struct ShiaAnswerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Shia claim that Ali was appointed by divine text, that the imams are infallible, and that the Companions betrayed the Prophet. The Quran praises the Companions, Ali himself ranked Abu Bakr and Umar above himself, and the imamate is found nowhere among the pillars of Islam.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHO ARE THE SHIA?")) {
                    Text(articleMarkdown: "**Shia (شِيعَة)** means “party“: the party of Ali. The largest group, the **Twelvers (الاِثنَا عَشَرِيَّة)**, hold that the Prophet (peace be upon him) appointed Ali as his successor by explicit command, that Ali and eleven of his descendants are infallible imams appointed by Allah, that belief in the imamate is a pillar of the religion, that the twelfth imam went into hiding in 260 AH and is still alive, and that most of the Companions, above all Abu Bakr, Umar, and Aisha, betrayed the Prophet after his death. From these beliefs came the cursing of the Companions, the wailing and self-beating of Ashura, the shrines, temporary marriage (**mut‘ah**), and **taqiyyah**, concealing one’s belief.")
                        .font(.body)

                    Text(articleMarkdown: "**Shi‘ah (شِيعَة)** means a party or a body of followers, from the root ش-ي-ع, to follow, spread, and support. The Quran uses the word for those who follow a man upon his way, saying of Ibrahim that he was of the party of Nuh, and for the sects into which people split (Quran 6:159):")
                        .font(.body)
                    ScriptureQuote(quran: "37:83")

                    Text(articleMarkdown: "Historically, **Shi‘at Ali**, the party of Ali, was the body of Muslims who stood with Ali (may Allah be pleased with him) at Siffin in 37 AH; it was an alignment in a dispute among Muslims, not a creed, and the Companions who fought beside him, such as Ammar ibn Yasir, whom Umar had appointed governor of Kufah (Sahih al-Bukhari 755), had given bay‘ah to Abu Bakr and Umar and honoured them as Ali did. Only later did the name narrow to those who held that Ali had been appointed by divine text and that whoever preceded him had wronged him.")
                        .font(.body)

                    Text(verbatim: "In the first sense, Ahl as-Sunnah are the true partisans of Ali. They love him and his household because the Prophet (peace be upon him) loved them; they love those whom the Prophet and Ali loved, Abu Bakr, Umar, Uthman, Aisha, and the rest of the Companions; and they do not hate anyone whom the two of them loved. Ali’s own conduct toward Abu Bakr, Umar, and Uthman is set out in section 2 below. A love of Ali that requires hatred of those he loved is not his party. The party that Allah calls successful is defined by faith and by loyalty to Allah and His Messenger, and every Companion and every member of the household is inside it:")
                        .font(.body)
                    ScriptureQuote(quran: "58:22", words: 37...50)

                    Text(articleMarkdown: "The Salaf called those who reject the Companions the **Rafidah (الرَّافِضَة)**, “the rejecters,“ from ر-ف-ض, to cast off. The name goes back to Zayd ibn Ali ibn al-Husayn (may Allah have mercy on him), the grandson of al-Husayn, who rose against the Umayyads in Kufah in 122 AH. Those who had gathered to him demanded that he disavow Abu Bakr and Umar; he refused and asked Allah’s mercy on them, so they deserted him, and he said, “You have rejected me“ (rafadtumuni). Those who stayed with him became the **Zaydiyyah**, and those who left became the Rafidah. Ibn Taymiyyah (Minhaj as-Sunnah) and Ibn Kathir (al-Bidayah wan-Nihayah, events of 122 AH) record the story, ash-Shahrastani (al-Milal wan-Nihal) records that they cast him off when they learned that he would not disavow the two shaykhs, and al-Ash‘ari (Maqalat al-Islamiyyin) records that the name was given for their rejection of the caliphates of Abu Bakr and Umar. From then on the Salaf counted honouring the Companions and the Ahlul Bayt (أَهل البَيت, the people of the House: the Prophet’s household and family) together as a mark of the Sunnah, and rejecting the Companions as the mark of the Rafidah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. ALLAH PRAISED THE COMPANIONS")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) declared Himself pleased with the Companions, in verses revealed while they were alive, knowing what they would do:")
                        .font(.body)
                    ScriptureQuote(quran: "9:100", words: 0...12)

                    ScriptureQuote(quran: "48:18")

                    ScriptureQuote(quran: "48:29", words: 0...17)

                    Text(verbatim: "Then He made a share of the war spoils for “those who came after them,“ on the condition that they pray for the Companions and bear no resentment toward them (Quran 59:10). The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3673", cite: "Sahih al-Bukhari 3673, Sahih Muslim 2541", arabic: 31...46, english: 4...40)

                    ScriptureQuote(hadith: "muslim:2531", cite: "Sahih Muslim 2531", arabic: 128...137, english: 177...206)

                    Text(verbatim: "A claim that these people apostatised is a claim that Allah praised apostates and the Prophet left his religion in the hands of traitors. It is a claim against Allah and His Messenger before it is a claim against the Companions.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. ALI HIMSELF ON ABU BAKR AND UMAR")) {
                    Text(verbatim: "The Prophet (peace be upon him) ordered Abu Bakr, and no one else, to lead the prayer in his final illness, repeating the order three times (Sahih al-Bukhari 664, Sahih Muslim 418), and said from the pulpit:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3654", cite: "Sahih al-Bukhari 3654, Sahih Muslim 2382", arabic: 93...111, english: 92...138)

                    Text(verbatim: "Ali’s own son, Muhammad ibn al-Hanafiyyah, asked him who the best of people was after the Messenger of Allah. Ali said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3671", cite: "Sahih al-Bukhari 3671", arabic: 31...53, english: 20...50)

                    Text(verbatim: "Ali gave his daughter Umm Kulthum, the granddaughter of the Prophet (peace be upon him), in marriage to Umar (Sahih al-Bukhari 2881; Sunan al-Nasa’i 1978), and named three of his own sons Abu Bakr, Umar, and Uthman, as the Shia biographers themselves record (al-Mufid, al-Irshad). A man does not marry his daughter to the one who “usurped“ his right and name his children after his enemies.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. THE IMAMATE IS NOT A PILLAR")) {
                    Text(verbatim: "If belief in twelve imams were the greatest pillar of the religion, it would be the clearest thing in the Quran and the Sunnah. It is in neither. The Prophet (peace be upon him) counted the pillars:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:8", cite: "Sahih al-Bukhari 8, Sahih Muslim 16", arabic: 33...53, text: "“Islam is based on (the following) five (principles): To testify that none has the right to be worshipped but Allah and Muhammad is Allah's Messenger (ﷺ). To offer the (compulsory congregational) prayers dutifully and perfectly. To pay Zakat (i.e. obligatory charity). To perform Hajj. (i.e. Pilgrimage to Mecca) To observe fast during the month of Ramadan”")

                    Text(verbatim: "And when Jibril asked him about faith, he counted six things (Sahih Muslim 8), none of them an imam. Allah completed the religion (Quran 5:3) without a word about it.")
                        .font(.body)

                    Text(verbatim: "As for the hadith of Ghadir Khumm, the Prophet (peace be upon him) said there, on the way back from the Farewell Hajj after complaints against Ali from the army of Yemen:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3713", cite: "Sunan al-Tirmidhi 3713; graded sahih by al-Albani", arabic: 40...44, english: 4...14)

                    Text(articleMarkdown: "**Mawla** means beloved, ally, and supporter, the sense in which Allah is the mawla of the believers (Quran 47:11); it is not the word for ruler, and it was said to defend Ali’s honour, not to appoint him. In the same sermon the Prophet (peace be upon him) commanded holding fast to the Book of Allah and reminded the people of the rights of his household (Sahih Muslim 2408), which Ahl as-Sunnah do. If it had been an appointment, Ali would have said so at Saqifah, and instead he pledged allegiance to Abu Bakr, then Umar, then Uthman, and served under them.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. NOBODY IS INFALLIBLE AFTER THE PROPHET")) {
                    Text(verbatim: "The Quran addresses even the Prophet (peace be upon him) with correction:")
                        .font(.body)
                    ScriptureQuote(quran: "80:1-2")

                    ScriptureQuote(quran: "66:1")

                    Text(verbatim: "If the Messenger is corrected by revelation, no one after him is infallible; Ali said of himself, “I am only a man among the Muslims.“ And the idea of a hidden imam, alive for over a thousand years and needed by the religion yet absent from it, has no basis in any text.")
                        .font(.body)
                }

                Section(header: ArticleHeader("5. AISHA, THE MOTHER OF THE BELIEVERS")) {
                    Text(verbatim: "Allah declared the innocence of Aisha (may Allah be pleased with her) in ten verses of Surat an-Nur when the hypocrites slandered her, and ended:")
                        .font(.body)
                    ScriptureQuote(quran: "24:26", words: 8...15)

                    ScriptureQuote(quran: "33:6", words: 0...6)

                    Text(verbatim: "The Prophet (peace be upon him) died in her house, on her day, leaning against her chest (Sahih al-Bukhari 4449). Whoever curses her curses the mother of the believers, and whoever slanders her has opposed the Quran.")
                        .font(.body)
                }

                Section(header: ArticleHeader("6. FATIMAH AND THE INHERITANCE")) {
                    Text(verbatim: "The Shia say Abu Bakr wronged Fatimah (may Allah be pleased with her) over the land of Fadak. Abu Bakr applied the Prophet’s own words:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:6725", cite: "Sahih al-Bukhari 6725, Sahih Muslim 1759", arabic: 57...87, english: 49...98)

                    Text(verbatim: "Ali and al-Abbas later confirmed to Umar that they knew the Prophet had said this, and when Ali became caliph he did not distribute Fadak as inheritance either. Abu Bakr followed the Sunnah, and Fatimah, a human being, was hurt; the Sunnah is not overturned by that.")
                        .font(.body)
                }

                Section(header: ArticleHeader("7. MUT'AH, WAILING, AND TAQIYYAH")) {
                    Text(verbatim: "Temporary marriage was forbidden by the Prophet (peace be upon him), and the narrator of its prohibition is Ali himself:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:5115", cite: "Sahih al-Bukhari 5115, Sahih Muslim 1407", arabic: 32...46, english: 5...21)

                    Text(verbatim: "The self-beating and wailing of Ashura for al-Husayn (may Allah be pleased with him), whose martyrdom Ahl as-Sunnah grieve as a crime and a tragedy, is what the Prophet (peace be upon him) disowned:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1294", cite: "Sahih al-Bukhari 1294, Sahih Muslim 103", arabic: 29...38, english: 4...27)

                    Text(verbatim: "And the doctrine that concealing one’s belief is a virtue has no place in a religion whose Prophet and Companions proclaimed it under torture; the Quran allows hiding faith only under real compulsion (Quran 16:106).")
                        .font(.body)
                }

                Section(header: ArticleHeader("8. THE QURAN IS PRESERVED")) {
                    Text(verbatim: "Some classical Twelver sources, including narrations in al-Kulayni’s al-Kafi (2/634), claim the Quran was altered and that the true Quran is with the hidden imam. Ahl as-Sunnah reject this absolutely, and hold every Muslim, Sunni or Shia, to Allah’s promise:")
                        .font(.body)
                    ScriptureQuote(quran: "15:9")

                    Text(verbatim: "The Quran the Shia recite is the same mushaf Uthman sent to the cities, which shows that the claim is false even by their own practice.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Do Sunnis love Ali and the Ahlul Bayt?**")
                        .font(.body)
                    Text(verbatim: "Yes, and it is part of the creed, not a courtesy. Ali (may Allah be pleased with him) said that the Prophet (peace be upon him) gave him a promise:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:#146", cite: "Sahih Muslim 78", arabic: 50...57, english: 27...44)

                    Text(verbatim: "On the eve of the conquest of Khaybar the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4210", cite: "Sahih al-Bukhari 4210", arabic: 33...47, english: 9...40)

                    Text(verbatim: "In the morning he called for Ali, prayed for his sore eyes, and gave him the flag. At Ghadir Khumm he said three times, “I remind you of Allah regarding my household“ (Sahih Muslim 2408), and Abu Bakr, the first caliph, lived by it:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3751", cite: "Sahih al-Bukhari 3751", arabic: 30...38, english: 0...13)

                    Text(verbatim: "Of al-Hasan the Prophet (peace be upon him) said from the pulpit:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3746", cite: "Sahih al-Bukhari 3746", arabic: 33...44, english: 34...58)
                    ScriptureQuote(hadith: "tirmidhi:3768", cite: "Sunan al-Tirmidhi 3768; graded sahih by al-Albani", arabic: 37...42, english: 7...17)

                    Text(verbatim: "Ahl as-Sunnah send blessings on the family of Muhammad in every prayer, and their books of creed name love of the household among the marks of the Sunnah.")
                        .font(.body)

                    Text(articleMarkdown: "**Did the Prophet appoint Ali at Ghadir Khumm?**")
                        .font(.body)
                    Text(articleMarkdown: "No. The words were “Whoever I am his mawla, then Ali is his mawla“ (Sunan al-Tirmidhi 3713, quoted in section 3), said on the way back from the Farewell Hajj after some of the men of the Yemen expedition had complained about Ali (Ibn Kathir, al-Bidayah wan-Nihayah). **Mawla** means beloved, ally, and supporter, and Allah uses the same word for His relation to every believer:")
                        .font(.body)
                    ScriptureQuote(quran: "47:11")

                    Text(verbatim: "Not one Companion who heard it understood a caliphate from it; had it been an appointment, the Muhajirun and Ansar would have raised it at Saqifah, and Ali himself would have. Instead, Ali gave bay‘ah to Abu Bakr (Sahih al-Bukhari 4240), served Umar as his counsellor in Madinah and married his daughter to him, and served Uthman. Ibn Taymiyyah discusses the hadith and its context at length in Minhaj as-Sunnah.")
                        .font(.body)

                    Text(articleMarkdown: "**Why did Ali give bay‘ah to Abu Bakr and serve under the three caliphs?**")
                        .font(.body)
                    Text(verbatim: "Because he believed them to be the rightful caliphs and the best of the ummah after the Prophet (peace be upon him). Aisha relates that after Fatimah’s death Ali sought reconciliation with Abu Bakr, and in the mosque, after the Zuhr prayer:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4240", cite: "Sahih al-Bukhari 4240", arabic: 332...371, english: 550...646)

                    Text(verbatim: "His own ranking, “Abu Bakr, then Umar,“ was quoted in section 2 (Sahih al-Bukhari 3671). A man of Ali’s courage, who feared no one, did not conceal his belief for twenty-five years and then serve as a counsellor and judge under those he thought had usurped him. The claim requires that Ali was either a coward or a hypocrite, and he was neither.")
                        .font(.body)

                    Text(articleMarkdown: "**Did Umar attack Fatimah’s house?**")
                        .font(.body)
                    Text(verbatim: "The story that Umar struck Fatimah, broke her rib, or caused her to miscarry has no chain of narration in the Sahih, the Sunan, or the Musnad, and Ibn Taymiyyah answers the claim in Minhaj as-Sunnah. What is established is the opposite: Umar married Umm Kulthum, the daughter of Ali and Fatimah, and when he distributed garments in Madinah his companions called her “your wife, the daughter of the Messenger of Allah“ (Sahih al-Bukhari 2881); the funeral prayer over “Umm Kulthum bint Ali, the wife of Umar ibn al-Khattab,“ was offered together with that of her son Zayd, with Ibn Umar and Abu Hurayrah among those present (Sunan an-Nasa’i 1978; graded sahih by al-Albani). Ali also named one of his sons Umar. A father does not give his daughter to the man who broke her mother’s rib.")
                        .font(.body)

                    Text(articleMarkdown: "**Did Abu Bakr wrong Fatimah over Fadak?**")
                        .font(.body)
                    Text(verbatim: "No. He applied the Prophet’s own words, “We are not inherited from; what we leave is charity“ (Sahih al-Bukhari 6725, Sahih Muslim 1759, quoted in section 6), and he maintained the Prophet’s household from that property exactly as the Prophet had done. When Ali met him about it, Abu Bakr wept and said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4240", cite: "Sahih al-Bukhari 4240", arabic: 261...276, english: 405...436)

                    Text(verbatim: "Ali and al-Abbas later acknowledged the same hadith before Umar (Sahih al-Bukhari 3094, Sahih Muslim 1757), and when Ali became caliph he left Fadak as charity and did not distribute it as inheritance. Fatimah (may Allah be pleased with her) was hurt, and she is honoured for her station; but a hadith of the Prophet is not overturned by anyone’s hurt.")
                        .font(.body)

                    Text(articleMarkdown: "**What do Sunnis say about Karbala and Yazid?**")
                        .font(.body)
                    Text(verbatim: "That al-Husayn (may Allah be pleased with him) was killed unjustly, as a martyr, on 10 Muharram 61 AH by the army of Ubaydullah ibn Ziyad, and that his killing is one of the greatest crimes committed in this ummah. The Prophet (peace be upon him) had said “Husayn is from me, and I am from Husayn“ (Sunan al-Tirmidhi 3775, quoted below). Ahl as-Sunnah grieve for him as the Prophet permitted grief, with sorrow of the heart and tears, and without wailing, striking the cheeks, or tearing the garments (Sahih al-Bukhari 1294, quoted in section 7). As for Yazid ibn Mu‘awiyah, Ibn Taymiyyah records the position of Ahmad ibn Hanbal and the imams: he was a king among the kings of the Muslims, neither loved nor cursed, not a Companion and not one of the righteous, and the crime at Karbala is not excused; but the Muslim does not make cursing a named individual a part of his religion (Majmu‘ al-Fatawa 4/481-484).")
                        .font(.body)

                    Text(articleMarkdown: "**Do the Shia have a different Quran?**")
                        .font(.body)
                    Text(verbatim: "Fairness requires exactness. The Mushaf printed and recited by the Shia is the same Uthmani text, in the same order, as the Mushaf of the Muslims everywhere, and no Shia today produces a different one. But the classical Twelver sources contain narrations claiming that the Quran was altered and that the complete Quran is with the hidden imam, including narrations in al-Kafi (section 8 above), and some of their scholars held to them. Ahl as-Sunnah reject every such claim from any source by the promise of Allah to guard His Book (Quran 15:9, quoted in section 8), and they hold the Shia to the Mushaf in their own hands, which refutes the narrations.")
                        .font(.body)

                    Text(articleMarkdown: "**Is mut‘ah lawful?**")
                        .font(.body)
                    Text(verbatim: "No. It was permitted in the early period, then forbidden. Ali himself narrates its prohibition at Khaybar (Sahih al-Bukhari 5115, Sahih Muslim 1407, quoted in section 7), and Sabrah al-Juhani heard the Prophet (peace be upon him) declare in the year of the conquest of Makkah:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:1406l", cite: "Sahih Muslim 1406", arabic: 40...48, english: 11...25)

                    Text(verbatim: "A prohibition until the Day of Resurrection, narrated by Ali among others, cannot be revived by anyone. Marriage in Islam is a bond intended to last, with rights of inheritance, lineage, and maintenance that a marriage set to expire does not carry.")
                        .font(.body)

                    Text(articleMarkdown: "**Is taqiyyah part of Islam?**")
                        .font(.body)
                    Text(verbatim: "Only as a concession under real threat to life, not as a way of life. Allah said:")
                        .font(.body)
                    ScriptureQuote(quran: "16:106", words: 6...11)

                    Text(verbatim: "and He allowed the believer to guard himself against the disbelievers when he is in their power (Quran 3:28). Ibn Kathir records in his tafsir that the ayah of compulsion was revealed about Ammar ibn Yasir under torture in Makkah. It is not permission to conceal one’s creed among Muslims, to swear to what one does not believe, or to teach the religion one way in public and another in private. Concealing belief as a settled practice is what the Prophet (peace be upon him) described as the mark of the hypocrite:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:33", cite: "Sahih al-Bukhari 33", arabic: 33...44, text: "“The signs of a hypocrite are three: Whenever he speaks, he tells a lie. Whenever he promises, he always breaks it (his promise ). If you trust him, he proves to be dishonest”")

                    Text(verbatim: "The Companions proclaimed their faith under the whips of Makkah, and Ali, who is said to have practised taqiyyah for decades, was the boldest of men.")
                        .font(.body)

                    Text(articleMarkdown: "**Do Sunnis reject the fiqh of the Ahlul Bayt?**")
                        .font(.body)
                    Text(verbatim: "No. The imams of the household are imams of Ahl as-Sunnah in hadith and fiqh. Ja‘far as-Sadiq narrates from his father Muhammad al-Baqir from Jabir in Sahih Muslim, and it is Malik, the imam of Madinah, who carries his narration of the Prophet’s tawaf to Muslim (Sahih Muslim 1263); the long hadith of the Prophet’s Hajj comes through the same father and son (Sahih Muslim 1218). Malik recorded him in the Muwatta’, and Abu Hanifah is reported to have said that he had not seen anyone more learned in fiqh than Ja‘far ibn Muhammad (adh-Dhahabi, Siyar A‘lam an-Nubala’). Ali Zayn al-Abidin and Muhammad al-Baqir are narrators in both Sahihs. What Ahl as-Sunnah reject is not the household’s fiqh but the narrations forged in their names, which the imams themselves disowned.")
                        .font(.body)

                    Text(articleMarkdown: "**Are the Shia disbelievers, and may we pray with them?**")
                        .font(.body)
                    Text(verbatim: "Fairness here is a duty. The common Shia are Muslims of Ahl al-Qiblah, who testify to the two testimonies, pray toward the Ka‘bah, and fast Ramadan, and they are judged by their deeds like everyone else; the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:391", cite: "Sahih al-Bukhari 391", arabic: 31...45, english: 4...27)

                    Text(verbatim: "No specific person is declared a disbeliever without the conditions being met and the obstacles removed, and the scholars warn with the Prophet’s words:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:6103", cite: "Sahih al-Bukhari 6103", arabic: 40...49, english: 4...23)

                    Text(verbatim: "But certain beliefs are disbelief by the texts, whoever holds them: deifying Ali or the imams, claiming that the Quran was altered, or accusing Aisha of what Allah declared her innocent of (Quran 24:26, quoted in section 5). The scholars of Ahl as-Sunnah distinguish the ordinary Shia from those who hold these, and prayer behind an imam is judged by what he manifests; the safest course is to pray behind one whose creed is sound, while treating every Muslim with justice and good conduct.")
                        .font(.body)

                    Text(articleMarkdown: "**What about the hadith of the twelve caliphs?**")
                        .font(.body)
                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:1821f", cite: "Sahih Muslim 1821", english: [20...34, 62...73], arabicText: "لاَ يَزَالُ هَذَا الدِّينُ عَزِيزًا مَنِيعًا إِلَى اثنَى عَشَرَ خَلِيفَةً … كُلُّهُم مِن قُرَيشٍ")

                    Text(verbatim: "The hadith speaks of caliphs under whom the religion is strong and the people are gathered; that describes the rightly guided caliphs and the great caliphs of the Umayyads and early Abbasids, whom the ummah actually united under, as Ibn Kathir explains in his commentary on Quran 5:12. It cannot describe imams of whom only Ali, and al-Hasan for a few months before he made peace, ever ruled, and a twelfth who has been hidden for more than a thousand years, and the hadith makes no mention of Ali’s line, of infallibility, or of an appointment.")
                        .font(.body)

                    Text(articleMarkdown: "**Was Abu Talib a Muslim?**")
                        .font(.body)
                    Text(verbatim: "No. Ahl as-Sunnah honour his protection of the Prophet (peace be upon him) and his defence of him against Quraysh, but the Sahih is explicit that he died on the religion of Abd al-Muttalib, refusing to say la ilaha illa Allah though the Prophet pleaded with him at his deathbed (Sahih al-Bukhari 1360, Sahih Muslim 24), and when al-Abbas asked what his protection had availed him, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3883", cite: "Sahih al-Bukhari 3883", arabic: 42...54, english: 39...62)

                    Text(verbatim: "The claim that he was a secret believer contradicts these hadiths, one of them reported by his own brother al-Abbas, and it is made only to serve the doctrine that the imams’ ancestors must all have been believers.")
                        .font(.body)

                    Text(articleMarkdown: "**Who are the “Shi‘at Ali“ whom the Quran calls successful?**")
                        .font(.body)
                    Text(verbatim: "The Quran does not speak of a party of Ali; it speaks of the party of Allah (Quran 58:22, quoted above), the people of faith whom Allah is pleased with and who are pleased with Him, and it names among them the first Muhajirun and Ansar (Quran 9:100, quoted in section 1), of whom Ali was one and Abu Bakr and Umar were the foremost. Those who love the Companions and the household together, without cursing anyone the Prophet (peace be upon him) loved, are the party of Allah, and they alone are the true party of Ali.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE INVITATION")) {
                    Text(verbatim: "Ahl as-Sunnah love Ali more truly than those who curse his companions in his name. He is the fourth of the rightly guided caliphs, the one of whom the Prophet (peace be upon him) said, “You are to me as Harun was to Musa, except that there is no prophet after me“ (Sahih Muslim 2404), and the husband of Fatimah and father of the two masters of the youth of Paradise. Loving him and loving Abu Bakr, Umar, Uthman, and Aisha are one love, because they loved one another. The Muslim asks for all of them:")
                        .font(.body)
                    ScriptureQuote(quran: "59:10", words: 5...22)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Allah praised the Companions, Ali ranked Abu Bakr and Umar above himself and married his daughter to Umar, no imamate is among the pillars, and no one after the Prophet is infallible. Love of the Ahlul Bayt, which Ahl as-Sunnah share, does not require any of the beliefs built upon it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Shia / shi‘ah (شِيعَة)**: from ش-ي-ع, to follow and support: a party of followers, as explained above. In the language every man has his shi‘ah; as a name it came to mean those who hold that the leadership after the Prophet (peace be upon him) belonged to Ali and his descendants by divine text.")
                        .font(.body)

                    Text(articleMarkdown: "**Ahlul Bayt (أَهل البَيت)**: “the people of the house“: the household of the Prophet (peace be upon him). The ayah of purification comes in the middle of an address to his wives (Quran 33:32-34), so they are inside it by its context:")
                        .font(.body)
                    ScriptureQuote(quran: "33:33", words: 15...24)

                    Text(verbatim: "The Prophet (peace be upon him) then wrapped al-Hasan, al-Husayn, Fatimah, and Ali in his cloak and recited it over them (Sahih Muslim 2424), so they are inside it by his word. Zayd ibn Arqam (may Allah be pleased with him), who heard the sermon at Ghadir Khumm, was asked who the household are, and answered:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2408a", cite: "Sahih Muslim 2408", arabic: 212...236, english: 269...323)

                    Text(verbatim: "Ahl as-Sunnah love all of them, the wives and the relatives together, and it is part of their creed.")
                        .font(.body)

                    Text(articleMarkdown: "**Rafidah (الرَّافِضَة)**: “the rejecters,“ from ر-ف-ض: those who rejected Abu Bakr and Umar and deserted Zayd ibn Ali for refusing to disavow them, as explained above. The Salaf used the name for whoever curses the Companions.")
                        .font(.body)

                    Text(articleMarkdown: "**Zaydiyyah (الزَّيدِيَّة)**: the followers of Zayd ibn Ali (d. 122 AH). They are the closest of the Shia to Ahl as-Sunnah: Zayd himself and the early Zaydiyyah accepted the caliphates of Abu Bakr and Umar, holding that the less excellent may lead while the more excellent is present, and did not curse the Companions (the Jarudiyyah, who later prevailed in Yemen, fault the two caliphs), and and they claim neither infallibility nor a hidden imam; their imam is any descendant of Fatimah who is learned and rises openly (ash-Shahrastani, al-Milal wan-Nihal).")
                        .font(.body)

                    Text(articleMarkdown: "**Imamiyyah / Ithna ‘Ashariyyah (الإِمَامِيَّة / الاِثنَا عَشَرِيَّة)**: “the Twelvers,“ the largest body of the Shia today. Their twelve imams are Ali, al-Hasan, al-Husayn, Ali Zayn al-Abidin, Muhammad al-Baqir, Ja‘far as-Sadiq, Musa al-Kazim, Ali ar-Rida, Muhammad al-Jawad, Ali al-Hadi, al-Hasan al-Askari, and Muhammad ibn al-Hasan, who is said to have gone into occultation as a small child in Samarra in 260 AH. Ahl as-Sunnah honour the first of these as the fourth rightly guided caliph, the next two as the masters of the youth of Paradise, and Zayn al-Abidin, al-Baqir, and as-Sadiq as imams of knowledge and piety whose narrations are in the books of the Sunnah; the dispute is not over loving them but over the claims of divine appointment and infallibility made for them.")
                        .font(.body)

                    Text(articleMarkdown: "**Isma‘iliyyah (الإِسمَاعِيلِيَّة)**: named after Isma‘il ibn Ja‘far as-Sadiq, who died in his father’s lifetime and whom they hold to be the seventh imam. From them came the Fatimid dynasty that ruled North Africa and Egypt (297-567 AH), and the **Qaramitah** of Bahrayn, who in 317 AH attacked Makkah during the Hajj, slaughtered the pilgrims inside the sanctuary, and carried off the Black Stone, which stayed away from the Ka‘bah for about twenty-two years (Ibn Kathir, al-Bidayah wan-Nihayah, events of 317 AH). Their doctrine of a hidden meaning (batin) behind the texts emptied the shari‘ah of its rulings.")
                        .font(.body)

                    Text(articleMarkdown: "**Nusayriyyah (النُّصَيرِيَّة)**: named after Muhammad ibn Nusayr (third century AH), who claimed that Ali was divine. They hold Ali to be God made manifest, believe in the transmigration of souls, and keep their doctrine secret from outsiders. Ibn Taymiyyah, asked about them, ruled that they are outside Islam altogether (Majmu‘ al-Fatawa, vol. 35), and no school of the Muslims, Sunni or Shia, counts their creed as Islam.")
                        .font(.body)

                    Text(articleMarkdown: "**Ghulat (غُلَاة)**: “extremists,“ from غ-ل-و, to exceed the bound: those who raised Ali or the imams to divinity or prophethood. The first were the **Saba’iyyah**, the followers of Abdullah ibn Saba’, whom al-Ash‘ari (Maqalat al-Islamiyyin) and ash-Shahrastani (al-Milal wan-Nihal) count as the first of the ghulat. Ali (may Allah be pleased with him) burned a group of these heretics, whom the commentators, including Ibn Hajar in Fath al-Bari, identify as people who had claimed divinity for him, and Ibn Abbas commented:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3017", cite: "Sahih al-Bukhari 3017", arabic: 11...54, english: 0...55)

                    Text(verbatim: "Ali was the first to disown those who exaggerated about him, and the Imami Shia themselves disown the ghulat.")
                        .font(.body)

                    Text(articleMarkdown: "**Imamah (إِمَامَة)**: “leadership.“ For Ahl as-Sunnah the caliphate is a trust established by the choice and pledge of the Muslims for the good of the religion and the people; for the Twelvers it is a pillar of faith, the appointment by Allah of twelve named men, without which faith is incomplete. The pillars the Prophet (peace be upon him) counted are in section 3 below.")
                        .font(.body)

                    Text(articleMarkdown: "**‘Ismah (عِصمَة)**: “protection“ from sin and error. Ahl as-Sunnah affirm it for the prophets in what they convey from Allah; the Twelvers claim it for the twelve imams and for Fatimah, which makes their words a revelation beside the Quran.")
                        .font(.body)

                    Text(articleMarkdown: "**Ghaybah (غَيبَة)**: “occultation“: the claim that the twelfth imam has been hidden since 260 AH and will return as the Mahdi. Ahl as-Sunnah believe in a Mahdi from the household of the Prophet (peace be upon him), of the descendants of Fatimah, whose name will be the Prophet’s name and whose father’s name will be his father’s name, and who will fill the earth with justice as it was filled with oppression (Sunan Abi Dawud 4282, graded hasan sahih by al-Albani; Sunan Abi Dawud 4284, graded sahih by al-Albani); that is Muhammad ibn Abdullah, not Muhammad ibn al-Hasan, and not a child hidden for more than a thousand years.")
                        .font(.body)

                    Text(articleMarkdown: "**Raj‘ah (رَجعَة)**: “return“: the Twelver belief that the imams and their enemies will be brought back to life before the Day of Resurrection so that the imams may take their due. No text of the Quran or the Sunnah mentions it.")
                        .font(.body)

                    Text(articleMarkdown: "**Bada’ (بَدَاء)**: “the appearing of what was hidden“: the belief that Allah decides a matter and then a new view appears to Him; it entered the Shia sources to explain why an expected imam died before his father. Ahl as-Sunnah reject it, because Allah has encompassed all things in knowledge (Quran 65:12) and nothing appears to Him that He did not know.")
                        .font(.body)

                    Text(articleMarkdown: "**Taqiyyah (تَقِيَّة)**: from و-ق-ي, to guard: concealing one’s belief to escape harm. Discussed under Common Questions below.")
                        .font(.body)

                    Text(articleMarkdown: "**Tawalla / tabarra (تَوَلِّي / تَبَرِّي)**: loyalty to the imams and disavowal of their enemies. In Twelver usage the “enemies“ include Abu Bakr, Umar, Uthman, and Aisha, so tabarra becomes a duty of hating the Companions. The loyalty and disavowal of Ahl as-Sunnah is for the sake of Allah toward faith and disbelief, and never between the Companions of one Prophet.")
                        .font(.body)

                    Text(articleMarkdown: "**Mut‘ah (مُتعَة)**: “enjoyment“: marriage contracted for a fixed period against a payment, ending by itself. Discussed under Common Questions below.")
                        .font(.body)

                    Text(articleMarkdown: "**Ashura and latm (عَاشُورَاء / لَطم)**: Ashura is the tenth of Muharram, which the Prophet (peace be upon him) fasted and commanded to be fasted in thanks for the deliverance of Musa (Sahih al-Bukhari 2004). Latm means striking the face or chest. The Twelvers made the day a season of mourning for al-Husayn with breast-beating, wailing, and self-wounding, which the Prophet (peace be upon him) disowned in the hadith quoted in section 7.")
                        .font(.body)

                    Text(articleMarkdown: "**Ghadir Khumm (غَدِير خُمّ)**: the pool between Makkah and Madinah where the Prophet (peace be upon him) halted on the way back from the Farewell Hajj and said, “Whoever I am his mawla, then Ali is his mawla“ (Sunan al-Tirmidhi 3713, quoted in section 3), after commanding the people to hold to the Book of Allah and reminding them three times of his household (Sahih Muslim 2408). The Twelvers keep the day as the festival of Ali’s appointment; what was actually said is explained in section 3 and under Common Questions.")
                        .font(.body)

                    Text(articleMarkdown: "**Karbala (كَربَلَاء)**: the place in Iraq where al-Husayn ibn Ali (may Allah be pleased with him) was killed on 10 Muharram 61 AH, with most of his family and companions, by the army sent by Ubaydullah ibn Ziyad, the governor of Kufah for Yazid ibn Mu‘awiyah, after the people of Kufah who had invited him abandoned him (Ibn Kathir, al-Bidayah wan-Nihayah, events of 61 AH). Ahl as-Sunnah hold his killing to be one of the gravest crimes in the history of the ummah. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3775", cite: "Sunan al-Tirmidhi 3775; graded hasan by al-Albani", arabic: 34...43, english: 7...20)

                    Text(articleMarkdown: "**Marja‘ (مَرجِع)**: “the one referred to,“ from ر-ج-ع, to return: in Twelver usage the senior jurist (marja‘ at-taqlid) whom the laity must follow during the occultation. Ahl as-Sunnah ask the people of knowledge (Quran 16:43) but bind themselves absolutely to no one but the Messenger (peace be upon him).")
                        .font(.body)

                    Text(articleMarkdown: "**Sahabi (صَحَابِيّ)**: a Companion: in the definition of Ibn Hajar, whoever met the Prophet (peace be upon him) believing in him and died upon Islam (al-Isabah). Allah’s praise of them is quoted in section 1 below, and no one who met the Prophet in faith and died upon it is outside it.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ShiaAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering the Shia")
        .selectableArticleList(article: "ShiaAnswerView")
    }
}

struct ChristianityAnswerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Muslims honour Isa (Jesus) as one of the greatest messengers, born of a virgin, and reject that he is God, the son of God, or part of a trinity. The Quran, the words of Jesus in the Gospels, and reason all point the same way: Jesus called to the worship of one God.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT MUSLIMS BELIEVE ABOUT JESUS")) {
                    Text(articleMarkdown: "No Muslim is a Muslim without believing in **Isa ibn Maryam (عِيسَى ابنُ مَريَمَ)**: that he is a messenger of Allah and His word, born of the virgin Maryam without a father, that he spoke in the cradle, healed the blind and the leper, and raised the dead by Allah’s permission, that he was neither killed nor crucified but raised alive to heaven, and that he will return before the end of the world. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3435", cite: "Sahih al-Bukhari 3435", arabic: 34...71, english: 4...81)

                    ScriptureQuote(quran: "3:42")

                    ScriptureQuote(hadith: "bukhari:3443", cite: "Sahih al-Bukhari 3443", arabic: 31...46, english: 4...39)

                    Text(verbatim: "So the disagreement is not about whether to honour Jesus, but about what he was.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. JESUS IS NOT GOD")) {
                    ScriptureQuote(quran: "5:72", words: 18...32)

                    ScriptureQuote(quran: "5:75")

                    Text(verbatim: "One who eats, sleeps, prays, grows, and dies is a creature. A virgin birth does not make him divine; Adam had neither father nor mother:")
                        .font(.body)
                    ScriptureQuote(quran: "3:59")

                    Text(verbatim: "The Gospels themselves record Jesus praying to God, saying he could do nothing of himself (John 5:30), not knowing the hour that only the Father knows (Mark 13:32), and calling the Father “the only true God“ and himself the one He sent (John 17:3). Nowhere in them does he say “I am God, worship me.“")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. GOD HAS NO SON")) {
                    ScriptureQuote(quran: "19:88-93")

                    ScriptureQuote(quran: "112:1-4")

                    Text(verbatim: "The Quran even records how Jesus himself will answer on the Day of Judgement:")
                        .font(.body)
                    ScriptureQuote(quran: "5:116", words: 0...30)

                    ScriptureQuote(quran: "5:117", words: 0...11)
                }

                Section(header: ArticleHeader("3. THE TRINITY")) {
                    ScriptureQuote(quran: "4:171", words: 0...37)

                    ScriptureQuote(quran: "5:73", words: 0...13)

                    Text(verbatim: "The word “trinity“ is not in the Bible. The doctrine was fixed by councils of bishops at Nicaea in 325 CE and Constantinople in 381 CE, three centuries after Jesus, over the objection of Christians who held that he was created. The commandment Jesus called the first was the one every prophet taught: “Hear, O Israel: the Lord our God, the Lord is one“ (Mark 12:29, quoting Deuteronomy 6:4). Muslims hold to that.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. THE CRUCIFIXION AND ORIGINAL SIN")) {
                    ScriptureQuote(quran: "4:157-158")

                    Text(verbatim: "The doctrine that all mankind inherits Adam’s sin (inherited guilt in the Western churches, inherited death and corruption in the Eastern) and that God had to sacrifice His son to forgive it contradicts justice and the mercy of Allah. Adam repented and was forgiven (Quran 2:37); no one carries another’s guilt; and Allah forgives whom He wills, without a victim:")
                        .font(.body)
                    ScriptureQuote(quran: "6:164", words: 9...19)

                    ScriptureQuote(quran: "39:53")
                }

                Section(header: ArticleHeader("5. JESUS FORETOLD MUHAMMAD")) {
                    ScriptureQuote(quran: "61:6", words: 0...23)

                    ScriptureQuote(quran: "7:157", words: 0...11)

                    Text(verbatim: "Jesus promised “another Comforter“ who would abide forever and guide to all truth (John 14:16, 16:13); Moses promised a prophet like himself “from among their brethren“ (Deuteronomy 18:18), whom Ibn Taymiyyah and Ibn al-Qayyim identified as coming from the children of Ishmael, since no Israelite prophet after Moses came with a law and a nation as he did. And Jesus will return, the Prophet (peace be upon him) said, as a follower of the final revelation:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3448", cite: "Sahih al-Bukhari 3448, Sahih Muslim 155", arabic: 34...50, english: 4...52)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Do Muslims believe in Jesus?**")
                        .font(.body)
                    Text(verbatim: "Yes, and it is an article of faith, as the hadith of the testimony quoted above shows (Sahih al-Bukhari 3435): whoever denies Jesus is not a Muslim. Allah commands the believers to say:")
                        .font(.body)
                    ScriptureQuote(quran: "2:136")
                    Text(verbatim: "Muslims believe in his virgin birth, his miracles by Allah’s permission (Quran 3:49), his being raised alive to heaven, and his return. The Quran records his first words, spoken from the cradle, and they are the whole of what Muslims say about him:")
                        .font(.body)
                    ScriptureQuote(quran: "19:30")

                    Text(articleMarkdown: "**Do Muslims and Christians worship the same God?**")
                        .font(.body)
                    Text(verbatim: "The Creator of the heavens and the earth, the God of Abraham, Moses and Jesus, is one, and Allah commands Muslims to say so to the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(quran: "29:46", words: 20...25)
                    Text(verbatim: "But to describe Him as three, or as a man who was born and died, is to misdescribe Him: He neither begets nor is born (Quran 112:3, quoted above). The God they claim, the God of Abraham and Moses, is Allah, and in that sense the Lord is one (Quran 29:46); but worship directed to Jesus or his mother is worship of a creature (Quran 5:116), so what Islam corrects is both the description of God and the direction of the worship. That is why Ibn Taymiyyah (may Allah have mercy on him) titled his great work al-Jawab as-Sahih li man baddala din al-Masih, “the correct answer to those who changed the religion of the Messiah“: the dispute is over what was changed, not over which God.")
                        .font(.body)

                    Text(articleMarkdown: "**Did Jesus ever say “I am God, worship me“?**")
                        .font(.body)
                    Text(verbatim: "No. His own words in the Gospels say the opposite. “I can of mine own self do nothing“ (John 5:30). “My Father is greater than I“ (John 14:28). “Why callest thou me good? there is none good but one, that is, God“ (Mark 10:18). “This is life eternal, that they might know thee the only true God, and Jesus Christ, whom thou hast sent“ (John 17:3). Asked for the first commandment, he answered, “Hear, O Israel; the Lord our God is one Lord“ (Mark 12:29). And he fell on his face and prayed, “not as I will, but as thou wilt“ (Matthew 26:39). No one prays to himself. The Quran records that he commanded the Children of Israel to worship Allah, his Lord and theirs (Quran 5:72, quoted above), and it records what he did say:")
                        .font(.body)
                    ScriptureQuote(quran: "43:63-64")
                    Text(verbatim: "And on the Day of Judgement he will disown those who worshipped him (Quran 5:116-117, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Did Jesus die on the cross?**")
                        .font(.body)
                    Text(verbatim: "No. The Quran states that they neither killed nor crucified him, but another was made to resemble him (Quran 4:157-158, quoted above). Allah said to him:")
                        .font(.body)
                    ScriptureQuote(quran: "3:55", words: 3...11)
                    Text(verbatim: "Ibn Kathir relates from Ibn Abbas (may Allah be pleased with them) that when the house was surrounded, the likeness of Jesus was cast upon one of his companions, who was taken and crucified while Jesus was raised alive. Even the early history of Christianity shows the disagreement the Quran describes: the church father Irenaeus records that the followers of Basilides, in the second century, held that another man was crucified in his place (Against Heresies 1.24.4). Jesus did not die then; he will return, and the Prophet (peace be upon him) told us what follows:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:4324", cite: "Sunan Abi Dawud 4324; graded sahih by al-Albani", arabic: 72...84, english: 83...107)

                    Text(articleMarkdown: "**Was Jesus the son of God?**")
                        .font(.body)
                    Text(verbatim: "No. The Quran’s rejection of this (Quran 19:88-93 and 112:1-4, quoted above) is reasoned, not merely asserted:")
                        .font(.body)
                    ScriptureQuote(quran: "6:101")
                    ScriptureQuote(quran: "2:116-117")
                    Text(verbatim: "A son requires a mate, a beginning, and a likeness to the father; none of that is possible for the One who created everything. When the Bible calls Adam, Israel, David and the peacemakers sons of God, it means beloved servants, and that is what Jesus was, as Allah says of every single creature:")
                        .font(.body)
                    ScriptureQuote(quran: "19:93")

                    Text(articleMarkdown: "**Who was Paul, and why does it matter?**")
                        .font(.body)
                    Text(verbatim: "Paul (Saul of Tarsus) never met Jesus in his lifetime. He persecuted his followers, then reported a vision of him (Acts 9). Thirteen letters of the New Testament are attributed to him, and they, not the words of Jesus, are the source of the doctrines that the death of Jesus atones for sin and that the Law of Moses is finished for believers (Romans 10:4, Galatians 2-3). He clashed with Peter, the chief of the disciples, over whether Gentile converts must keep the Law (Galatians 2:11-14), and the Ebionites, the early Jewish followers of Jesus, rejected him as an apostate from the Law (Irenaeus, Against Heresies 1.26.2). It matters because a religion built on a man who never heard Jesus, and who overrode those who did, is not the religion of Jesus. The Quran describes the pattern:")
                        .font(.body)
                    ScriptureQuote(quran: "5:14", words: 0...11)

                    Text(articleMarkdown: "**Is the Bible the word of God?**")
                        .font(.body)
                    Text(verbatim: "Muslims believe that Allah revealed the Tawrah to Musa, the Zabur to Dawud and the Injil (الإِنجِيل, the Gospel) to Isa, and that the books in circulation today contain some of that revelation mixed with the writing, editing, and translating of men. The Quran says of the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(quran: "2:79", words: 0...14)
                    ScriptureQuote(quran: "3:78")
                    ScriptureQuote(quran: "5:13", words: 7...15)
                    Text(verbatim: "The Quran says the same of the Torah: a party of them distorted it after they had understood it (Quran 2:75). The manuscripts confirm it. The last twelve verses of Mark (16:9-20) and the story of the woman taken in adultery (John 7:53-8:11) are absent from the oldest complete manuscripts, Codex Sinaiticus and Codex Vaticanus of the fourth century. The one verse that states the Trinity in so many words (1 John 5:7 in the King James Version) is missing from every early Greek manuscript and is dropped by modern translations. The thousands of surviving manuscripts differ from one another in countless readings, and no original of any book exists. The Quran, by contrast, was memorised and written down in the Prophet’s lifetime, and Allah guaranteed its preservation (Quran 15:9).")
                        .font(.body)

                    Text(articleMarkdown: "**Did Jesus foretell Muhammad?**")
                        .font(.body)
                    Text(verbatim: "Yes, as the Quran states (Quran 61:6 and 7:157, quoted above). Jesus promised “another Comforter“ who would abide forever, “the Spirit of truth,“ who “shall not speak of himself; but whatsoever he shall hear, that shall he speak“ and who “will shew you things to come“ (John 14:16, 16:13). Christians read this as the Holy Spirit, since John 14:26 names him so; Muslims, following Quran 61:6, read it as pointing to Ahmad, and Ibn Taymiyyah argued in al-Jawab as-Sahih that one who “shall not speak of himself“ and “will shew you things to come“ is a human messenger who conveys only what he is given, which is exactly how the Quran describes Muhammad (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(quran: "53:3-4")
                    Text(verbatim: "The Jews of Jesus’s time were themselves awaiting three figures: the Messiah, Elijah, and “that Prophet“ (John 1:19-21, 25), the prophet like Moses of Deuteronomy 18:18. Ibn al-Qayyim gathered these prophecies in Hidayat al-Hayara fi Ajwibat al-Yahud wan-Nasara, and Ibn Taymiyyah in al-Jawab as-Sahih.")
                        .font(.body)

                    Text(articleMarkdown: "**Do Muslims worship Muhammad?**")
                        .font(.body)
                    Text(verbatim: "No, and Islam forbids it more strictly than any religion forbids anything. Muslims are not “Muhammadans“: they worship Allah alone and follow Muhammad (peace be upon him) as His messenger. Allah commanded him to say:")
                        .font(.body)
                    ScriptureQuote(quran: "18:110", words: 0...10)
                    ScriptureQuote(quran: "7:188", words: 0...10)
                    Text(verbatim: "He himself forbade what the Christians did with Jesus:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3445", cite: "Sahih al-Bukhari 3445", arabic: 36...49, english: 6...35)
                    ScriptureQuote(hadith: "bukhari:1330", cite: "Sahih al-Bukhari 1330, Sahih Muslim 529", arabic: 36...43, english: 10...28)
                    Text(verbatim: "When he died, Abu Bakr (may Allah be pleased with him) stood and said, “Whoever worshipped Muhammad, then Muhammad is dead; but whoever worshipped Allah, then Allah is alive and shall never die,“ and recited (Sahih al-Bukhari 3667):")
                        .font(.body)
                    ScriptureQuote(quran: "3:144", words: 0...15)

                    Text(articleMarkdown: "**Will Jesus return?**")
                        .font(.body)
                    Text(verbatim: "Yes, as the hadith quoted above states (Sahih al-Bukhari 3448, Sahih Muslim 155). He will descend, kill the false messiah (the Dajjal) (Sahih Muslim 2937), break the cross, and rule by the Quran; every Christian and Jew alive will then believe in him as he truly is. The Quran points to this:")
                        .font(.body)
                    ScriptureQuote(quran: "43:61")
                    ScriptureQuote(quran: "4:159")
                    Text(verbatim: "Ibn Kathir explains, following Ibn Jarir at-Tabari, that “before his death“ means before the death of Jesus: when he returns, the People of the Scripture who remain will believe in him as the servant and messenger of Allah, and Abu Hurayrah (may Allah be pleased with him) recited this very ayah after narrating the hadith of his descent.")
                        .font(.body)

                    Text(articleMarkdown: "**Was Islam spread by the sword?**")
                        .font(.body)
                    Text(verbatim: "No. Faith cannot be compelled, and Allah forbids trying:")
                        .font(.body)
                    ScriptureQuote(quran: "2:256", words: 0...8)
                    ScriptureQuote(quran: "10:99")
                    Text(verbatim: "The Prophet’s own practice shows it. The Christians of Najran sent their leaders to Madinah; after debate they declined Islam, made a treaty that left them their religion and their churches, and asked him to send a trustworthy man back with them, and he sent Abu Ubaydah (may Allah be pleased with him) (Sahih al-Bukhari 4380); the terms of the treaty are recorded by Abu Yusuf in Kitab al-Kharaj and al-Baladhuri in Futuh al-Buldan. He forbade the killing of women and children in war (Sahih al-Bukhari 3015) and commanded that the Copts of Egypt be treated well when the Muslims reached them (Sahih Muslim 2543). The assurance of Umar (may Allah be pleased with him) to the Christians of Jerusalem guaranteed their churches and crosses (Tarikh at-Tabari). The ancient churches of Egypt and Syria are still standing and still in use after fourteen centuries of Muslim rule; had Islam been spread by the sword, they would not be. And the lands with the largest Muslim populations today, in the islands and coasts of the East, were reached by merchants and preachers, not by armies. Allah commands:")
                        .font(.body)
                    ScriptureQuote(quran: "60:8")

                    Text(articleMarkdown: "**Can Muslims eat the food of Christians and marry their women?**")
                        .font(.body)
                    ScriptureQuote(quran: "5:5", words: 0...22)
                    Text(verbatim: "Ibn Abbas (may Allah be pleased with them) explained that “their food“ means their slaughtered animals, as al-Bukhari records in the chapter on the slaughter of the People of the Scripture. Pork, wine, and carrion remain forbidden, and the meat must be properly slaughtered, not strangled or beaten to death (Quran 5:3). A Muslim man may marry a chaste Christian woman; she keeps her religion, and their children are raised as Muslims. A Muslim woman may not marry a non-Muslim (Quran 2:221). These rulings show how Islam sees the People of the Scripture: nearer to the Muslims than the idolaters, and called to the truth.")
                        .font(.body)

                    Text(articleMarkdown: "**Are Christians going to Hell?**")
                        .font(.body)
                    Text(verbatim: "Whoever hears the message of Muhammad (peace be upon him) and dies rejecting it is not saved by attributing a son to Allah. The Quran says so of those who call Allah the Messiah or one of three (Quran 5:72-73, quoted above), and adds:")
                        .font(.body)
                    ScriptureQuote(quran: "3:85")
                    ScriptureQuote(hadith: "muslim:153", cite: "Sahih Muslim 153", arabic: 29...54, english: 0...52)
                    Text(verbatim: "At the same time the Quran does not treat them as one mass (Quran 3:113). It praises those among the People of the Scripture who believed, and it records what is good in the Christians in particular:")
                        .font(.body)
                    ScriptureQuote(quran: "3:113")
                    ScriptureQuote(quran: "3:199")
                    ScriptureQuote(quran: "5:82", words: 10...26)
                    Text(verbatim: "As for the ayah that promises reward to Jews, Christians and Sabians who believed and did righteousness (Quran 2:62), Ibn Kathir explains that it concerns those who followed their own prophet in his time, before the next was sent: after Muhammad (peace be upon him) nothing is accepted except following him, as Ibn Abbas said and as 3:85 makes clear. And Allah does not punish one whom the message never reached:")
                        .font(.body)
                    ScriptureQuote(quran: "17:15", words: 15...20)
                    Text(verbatim: "So the question is not about a label but about knowing the truth and rejecting it. Judgement of individuals belongs to Allah; the Muslim’s duty is to convey the message with wisdom and good instruction (Quran 16:125).")
                        .font(.body)

                    Text(articleMarkdown: "**What did Jesus actually teach?**")
                        .font(.body)
                    Text(verbatim: "The same religion as every prophet. In the Gospels he named the first commandment as the oneness of God (Mark 12:29); said he came to fulfil the Law of Moses, not to destroy it (Matthew 5:17); prayed with his face to the ground (Matthew 26:39); fasted forty days (Matthew 4:2); was circumcised on the eighth day (Luke 2:21); said “my Father is greater than I“ (John 14:28); greeted his disciples with “Peace be unto you“ (John 20:19); and called God “my Father, and your Father; and my God, and your God“ (John 20:17). A man who prostrates, fasts, keeps the Law, avoids pork, and says that God is greater than himself is recognisably a Muslim. The Quran gives his message:")
                        .font(.body)
                    ScriptureQuote(quran: "3:50-51")
                    ScriptureQuote(quran: "19:31", words: 5...10)

                    Text(articleMarkdown: "**Is “Allah“ a different god from the God of the Bible?**")
                        .font(.body)
                    Text(verbatim: "No. Allah is the Arabic word for God, the one Creator. Arabic-speaking Christians and Jews have always said Allah, and Arabic Bibles use the word on every page; the Prophet’s own father was named Abdullah, servant of Allah, before Islam. The language of Jesus, Aramaic, calls God Alaha, and the Hebrew of the Torah uses Eloah and Elohim, all from the same Semitic root. The Quran itself counts churches and synagogues among the places in which the name of Allah is mentioned:")
                        .font(.body)
                    ScriptureQuote(quran: "22:40", words: 11...26)
                    Text(verbatim: "The difference is not the name but the description, and the Muslim invites the Christian to describe Him as Jesus did.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE INVITATION")) {
                    ScriptureQuote(quran: "3:64")

                    Text(verbatim: "The Quran also notes what is good in them, that among them are priests and monks who are not arrogant (Quran 5:82), and commands kindness and justice to those who do not fight the Muslims (Quran 60:8). The Muslim invites the Christian to the religion of Jesus himself: one God, worshipped alone, and His messenger obeyed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Islam gives Jesus his true place: a mighty messenger and the word of Allah, not God and not His son. He ate food, prayed, and called to the worship of his Lord and ours, and he foretold the one who would come after him.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Nasara (النَّصَارَى)**: the Quran’s name for the Christians. Ibn Kathir (may Allah have mercy on him) gives two derivations in his tafsir of 2:62: from **an-Nasirah (النَّاصِرَة)**, Nazareth, the town of Jesus, or from **nasr (نَصر)**, help, because they helped one another, as the disciples answered when Jesus asked who would be his helpers for Allah (Quran 3:52, 61:14):")
                        .font(.body)
                    ScriptureQuote(quran: "3:52", words: 11...20)

                    Text(articleMarkdown: "**Ahl al-Kitab (أَهلُ الكِتَاب)**: “the People of the Scripture,“ the Jews and the Christians, the two communities that received a revealed Book before the Quran. Islam gives them a standing distinct from the idolaters: their slaughtered meat and their chaste women are lawful to Muslims (Quran 5:5), they are to be argued with only in the best manner (Quran 29:46), and yet their doctrines are refuted without apology (Quran 4:171).")
                        .font(.body)

                    Text(articleMarkdown: "**Isa ibn Maryam (عِيسَى ابنُ مَريَم)**: Jesus, the son of Mary. The Quran names him by his mother, a standing reminder that he had no father, and mentions him by name more often than it mentions Muhammad (peace be upon them both). Muslims say “alayhis-salam“ (peace be upon him) after his name as after every prophet.")
                        .font(.body)

                    Text(articleMarkdown: "**Al-Masih (المَسِيح)**: “the Messiah,“ from **masaha (مَسَحَ)**, to wipe or to anoint; the Hebrew mashiah and the Greek christos mean the same, “the anointed one.“ Ibn Kathir notes several explanations of the name, among them that he wiped over the sick and they were healed by Allah’s permission. The Quran confirms that this title belongs to Jesus alone, so a Muslim who says “Messiah“ affirms exactly what the Jews denied:")
                        .font(.body)
                    ScriptureQuote(quran: "3:45", words: 3...19)

                    Text(articleMarkdown: "**Injil (الإِنجِيل)**: from the Greek euangelion, “good news“: the revelation Allah gave to Jesus. It is not the same thing as the four Gospels. The Injil of the Quran is what Jesus received and taught, and no copy of it survives in the tongue he spoke:")
                        .font(.body)
                    ScriptureQuote(quran: "5:46", words: 12...16)

                    Text(articleMarkdown: "**The Gospels (الأَنَاجِيل)**: Matthew, Mark, Luke and John, the four accounts of Jesus at the start of the New Testament. They were written in Greek by others, decades after him (scholars date them to roughly 65–100 CE), while Jesus spoke Aramaic; their authors do not name themselves, and the titles were attached later. So they are at best reports about Jesus containing some of his words in translation, not the Injil itself. Muslims judge their contents by the Quran: what agrees with it is accepted, what contradicts it is rejected, and the rest is left alone.")
                        .font(.body)

                    Text(articleMarkdown: "**The Bible**: the Old Testament (the Jewish scriptures) and the New Testament (Gospels, Acts, the letters, Revelation). Protestants count 66 books and Catholics 73 (adding the books they call deuterocanonical), and the Orthodox churches count more still. The list itself was fixed by councils of bishops, at Hippo (393 CE) and Carthage (397 CE), and for Catholics finally at Trent (1546 CE). A book whose table of contents was voted on by men centuries after Jesus is not what Islam means by the Injil.")
                        .font(.body)

                    Text(articleMarkdown: "**Paul of Tarsus (بُولُس)**: a Jew of Tarsus who persecuted the followers of Jesus, never met him in his lifetime, and then reported a vision of him on the road to Damascus (Acts 9). Thirteen letters of the New Testament are attributed to him, more than to any other writer, and they, not the words of Jesus, are the source of the doctrines that the death of Jesus atones for sin and that the Law of Moses is no longer binding (Romans 10:4, Galatians 3). Jesus himself said he came to fulfil the Law, not to destroy it (Matthew 5:17). Muslim scholars who examined the Christian texts, such as Ibn Hazm in al-Fisal and Ibn Taymiyyah in al-Jawab as-Sahih, traced the alteration of the religion of the Messiah to those who came after him.")
                        .font(.body)

                    Text(articleMarkdown: "**Trinity (التَّثلِيث)**: the doctrine that God is one essence in three persons, Father, Son and Holy Spirit. The word is not in the Bible. The doctrine was defined at the Council of Nicaea (325 CE), which declared the Son “of one substance“ with the Father, and completed at the Council of Constantinople (381 CE), which added the Holy Spirit. The Quran names it and rejects it (Quran 4:171, 5:73).")
                        .font(.body)

                    Text(articleMarkdown: "**Incarnation (التَّجَسُّد)**: the belief that God became flesh in Jesus. Islam holds that the Creator does not enter His creation: Jesus was a word from Allah cast to Maryam, a human being who ate food like his mother (Quran 5:75).")
                        .font(.body)

                    Text(articleMarkdown: "**Crucifixion (الصَّلب)**: Christianity teaches that Jesus was crucified, died, and rose on the third day. The Quran denies that he was killed or crucified: another was made to resemble him, and Allah raised him alive (Quran 4:157-158).")
                        .font(.body)

                    Text(articleMarkdown: "**Atonement and original sin (الفِدَاء والخَطِيئَة الأَصلِيَّة)**: the Western Christian doctrine (Catholic and Protestant) that all mankind inherits the guilt of Adam, and the Eastern doctrine of inherited death and corruption; all agree that it is removed only through the sacrifice of the son of God. Islam teaches that Adam repented and was forgiven (Quran 2:37), that no soul bears the burden of another (Quran 6:164), and that Allah forgives whom He wills directly, without a victim (Quran 39:53).")
                        .font(.body)

                    Text(articleMarkdown: "**“Son of God“ (ابنُ اللَّهِ)**: in the Bible the phrase is used loosely. Adam is “the son of God“ (Luke 3:38), Israel is God’s “firstborn son“ (Exodus 4:22), David is told “Thou art my Son“ (Psalm 2:7), and the peacemakers “shall be called the children of God“ (Matthew 5:9). It meant a beloved and obedient servant. Later Christians made it literal for Jesus alone, and the Quran rejects that in the strongest terms (Quran 9:30, 19:88-93, 112:1-4).")
                        .font(.body)

                    Text(articleMarkdown: "**The Holy Spirit (رُوحُ القُدُس)**: in the Quran Ruh al-Qudus is the angel Jibril, by whom Allah supported Jesus (Quran 2:87, 5:110) and by whom He sent down the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "16:102")
                    Text(verbatim: "The Prophet (peace be upon him) prayed for the poet Hassan ibn Thabit (may Allah be pleased with him) with the same words, and in another narration named the angel:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:453", cite: "Sahih al-Bukhari 453, Sahih Muslim 2485", arabic: 41...54, english: 17...33)
                    ScriptureQuote(hadith: "bukhari:3213", cite: "Sahih al-Bukhari 3213", arabic: 27...33, english: 6...15)
                    Text(verbatim: "So the Holy Spirit is a created angel, not a person of the Godhead.")
                        .font(.body)

                    Text(articleMarkdown: "**Kalimat Allah and Ruh minhu (كَلِمَةُ اللهِ ورُوحٌ مِنه)**: Jesus is called “His word“ and “a soul from Him“ (Quran 4:171, quoted above). Ibn Kathir explains that he is a word from Allah because he was created by Allah’s word “Be,“ without a father, not because he is a part of Allah’s speech; and “a spirit from Him“ means a spirit created by Him, just as Allah says He subjected to us all that is in the heavens and the earth “from Him“ (Quran 45:13), that is, as His creation, not from His essence. The angel said to Maryam:")
                        .font(.body)
                    ScriptureQuote(quran: "3:47", words: 10...22)

                    Text(articleMarkdown: "**Maryam (مَريَم)**: Mary, the daughter of Imran, the only woman named in the Quran, and a surah bears her name. She was chosen above the women of the worlds (Quran 3:42, quoted above), conceived Jesus as a virgin, and is called a supporter of truth (Quran 5:75). Muslims honour her without worshipping her, and the Quran rejects taking her as a deity besides Allah (Quran 5:116):")
                        .font(.body)
                    ScriptureQuote(quran: "19:20")
                    ScriptureQuote(quran: "66:12")

                    Text(articleMarkdown: "**The Hawariyyun (الحَوَارِيُّون)**: the disciples of Jesus, from **hawar (حَوَر)**, whiteness, said to refer to their white garments or to the purity of their hearts. They declared themselves Muslims (Quran 3:52, quoted above), asked Allah for a table from heaven (Quran 5:112-115), and were supported against those who disbelieved (Quran 61:14).")
                        .font(.body)

                    Text(articleMarkdown: "**Arius (آرِيُوس) and the early Christians who denied the Trinity**: Arius (d. 336 CE), a priest of Alexandria, taught that the Son was created and had a beginning, and that the Father alone is God without beginning. His view was condemned at Nicaea, yet for decades afterwards much of the church, and later whole Gothic nations, held it. Before him the Ebionites, described by the church fathers Irenaeus and Eusebius, held Jesus to be a man and not God, kept the Law of Moses, and rejected Paul. The Quran’s account of Jesus was therefore not foreign to early Christianity; it was the side that lost.")
                        .font(.body)

                    Text(articleMarkdown: "**Catholic, Orthodox, Protestant**: the three main branches of Christianity. The Catholic Church under the Pope of Rome and the Eastern Orthodox churches divided in 1054 CE; the Protestants broke from Rome in the Reformation begun by Martin Luther in 1517 CE, rejecting papal authority and holding to the Bible alone. All three affirm the Trinity, the Incarnation, and the Crucifixion; they differ over authority, sacraments, and the saints. Islam’s discussion with them concerns what all three share.")
                        .font(.body)

                    Text(articleMarkdown: "**The “Gospel of Barnabas“**: a book that presents Jesus as foretelling Muhammad by name. Muslims should not rely on it. No manuscript of it older than the sixteenth century is known, it contains historical errors, and it even denies that Jesus is the Messiah, which contradicts the Quran (Quran 3:45). The case of Islam rests on the Quran and the Sunnah, not on disputed books.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ChristianityAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Christianity")
        .selectableArticleList(article: "ChristianityAnswerView")
    }
}

struct JudaismAnswerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Muslims believe in Musa (Moses), the Torah, and all the prophets of the Children of Israel. The Quran answers the rejection of Jesus and Muhammad, the changing of the scripture, and the claim of a chosen race, and calls the Jews back to the covenant of their own prophets.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT MUSLIMS BELIEVE")) {
                    Text(articleMarkdown: "Islam affirms **Musa (مُوسَى)** as one of the five greatest messengers, the **Tawrah (التَّورَاة)** as revelation, and Ibrahim, Ishaq, Ya‘qub, Yusuf, Dawud, Sulayman, and the other prophets of the Children of Israel, and it forbids distinguishing between them:")
                        .font(.body)
                    ScriptureQuote(quran: "2:136")

                    ScriptureQuote(quran: "5:44", words: 0...5)

                    Text(verbatim: "When the Prophet (peace be upon him) came to Madinah and found the Jews fasting Ashura for the deliverance of Musa, he said, “We have more right to Musa than you,“ fasted it, and commanded fasting it (Sahih al-Bukhari 2004). Moses is a Muslim’s prophet, mentioned in the Quran more than any other.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. THE COVENANT AND THE PROPHETS WHO CAME AFTER")) {
                    Text(verbatim: "Allah reminds the Children of Israel of His favour upon them and of the covenant they gave, to believe in what He would send after Musa:")
                        .font(.body)
                    ScriptureQuote(quran: "2:40-41")

                    ScriptureQuote(quran: "2:87")

                    Text(verbatim: "Believing in Moses and rejecting Jesus and Muhammad is not faith in God; it is choosing among His messengers:")
                        .font(.body)
                    ScriptureQuote(quran: "4:150-151")
                }

                Section(header: ArticleHeader("2. MUHAMMAD IS IN THEIR SCRIPTURE")) {
                    ScriptureQuote(quran: "2:146")

                    ScriptureQuote(quran: "7:157", words: 0...11)

                    Text(verbatim: "Moses told his people that God would raise up for them “a prophet from among their brethren, like unto you,“ and put His words in his mouth (Deuteronomy 18:18): Ibn Taymiyyah (al-Jawab as-Sahih) and Ibn al-Qayyim (Hidayat al-Hayara) read “their brethren“ as the children of Ishmael, and the prophet like Moses, with a law, a nation, and victory, as Muhammad (peace be upon him), since no Israelite prophet after Moses matched him in that. The rabbi Abdullah ibn Salam recognised him on sight in Madinah, tested him with questions “that only a prophet knows,“ and declared, “I testify that you are the Messenger of Allah“ (Sahih al-Bukhari 3329).")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. THE SCRIPTURE WAS CHANGED")) {
                    ScriptureQuote(quran: "5:13", words: 0...15)

                    ScriptureQuote(quran: "2:79", words: 0...14)

                    Text(verbatim: "The Torah of Moses was revelation; the text that exists today was written down and transmitted by hands after him, as its own tradition concedes for its closing verses (Talmud, Bava Batra 15a) and as academic scholars of the text hold for much more, and it contains the account of Moses’ death and burial. The Quran, by contrast, is guarded by Allah (Quran 15:9), memorised in full by millions, and unchanged since it was revealed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. NO CHOSEN RACE")) {
                    Text(verbatim: "The Children of Israel were favoured with prophets and revelation, and the Quran says so (Quran 2:47). But favour is a trust, not a bloodline, and nobility before Allah is by faith and righteousness alone:")
                        .font(.body)
                    ScriptureQuote(quran: "49:13", words: 0...15)

                    ScriptureQuote(quran: "62:6")

                    Text(verbatim: "Ibrahim, whom both peoples claim, was neither a Jew nor a Christian:")
                        .font(.body)
                    ScriptureQuote(quran: "3:67-68")
                }

                Section(header: ArticleHeader("5. WHAT THE QURAN CONDEMNS AND WHAT IT DOES NOT")) {
                    Text(verbatim: "The Quran’s censure is of those who broke the covenant, killed the prophets, and concealed the truth, not of a people as such. It says of the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(quran: "3:113-114")

                    Text(verbatim: "Jews who accepted Islam, such as Abdullah ibn Salam, are among the Companions, and the Prophet (peace be upon him) dealt justly with the Jews of Madinah by treaty, and Umar made fulfilling Allah’s covenant with the People of the Scripture part of his final advice (Sahih al-Bukhari 3162).")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Do Muslims believe in Moses and the Torah?**")
                        .font(.body)
                    Text(verbatim: "Yes, as the ayah of faith in all the prophets (Quran 2:136, quoted above) and the Prophet’s fasting of Ashura for the deliverance of Musa (Sahih al-Bukhari 2004) show. Musa is one of the five messengers of firm resolve, and Allah honoured him by speaking to him directly:")
                        .font(.body)
                    ScriptureQuote(quran: "4:164", words: 10...13)
                    ScriptureQuote(quran: "2:53")
                    Text(verbatim: "When a Muslim struck a Jew who had sworn by the one who preferred Musa over all people, the Prophet (peace be upon him) rebuked the Muslim:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:2411", cite: "Sahih al-Bukhari 2411", arabic: 90...109, english: 89...135)

                    Text(articleMarkdown: "**Are the Jews the chosen people?**")
                        .font(.body)
                    Text(verbatim: "Allah did favour Bani Isra’il (بَنُو إِسرَائِيل, the Children of Israel; Isra’il is the name Allah gave the prophet Ya‘qub) in their time, with prophets, revelation, and kingdom, and the Quran says so plainly, twice in the same surah (Quran 2:47, 2:122):")
                        .font(.body)
                    ScriptureQuote(quran: "2:47")
                    ScriptureQuote(quran: "45:16")
                    Text(verbatim: "But the favour was a trust, conditional on the covenant, and the covenant never included the wrongdoers. When Ibrahim asked that leadership be for his descendants:")
                        .font(.body)
                    ScriptureQuote(quran: "2:124", words: 15...19)
                    Text(verbatim: "When they claimed to be Allah’s children and beloved:")
                        .font(.body)
                    ScriptureQuote(quran: "5:18", words: 0...15)
                    Text(verbatim: "Nobility before Allah is by piety (Quran 49:13, quoted above), and the nation Allah calls the best is defined by what it does, not by whose son it is:")
                        .font(.body)
                    ScriptureQuote(quran: "3:110", words: 0...11)

                    Text(articleMarkdown: "**Is Islam anti-Jewish?**")
                        .font(.body)
                    Text(verbatim: "No. The Quran’s censure is of deeds, breaking covenants, killing prophets, concealing the truth, and taking usury (Quran 4:161), and it praises the believers among the People of the Scripture in the same breath (Quran 3:113-114, quoted above):")
                        .font(.body)
                    ScriptureQuote(quran: "3:199")
                    Text(verbatim: "Even the ayah that describes the Jews of the Prophet’s time as the most hostile of people to the believers (Quran 5:82) is a report of conduct, not a verdict on descent, which is why the same Quran excepts those among them who believe (Quran 3:113-114). The Prophet’s own life settles the matter. Anas (may Allah be pleased with him) narrated:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1356", cite: "Sahih al-Bukhari 1356", arabic: 21...75, english: 0...71)
                    ScriptureQuote(hadith: "bukhari:2916", cite: "Sahih al-Bukhari 2916", arabic: 20...34, english: 0...17)
                    ScriptureQuote(hadith: "bukhari:1312", cite: "Sahih al-Bukhari 1312, Sahih Muslim 961", arabic: 40...59, english: 52...86)
                    Text(verbatim: "Safiyyah bint Huyayy (may Allah be pleased with her), a Mother of the Believers, was the daughter of the chief of Banu an-Nadir; the Prophet (peace be upon him) freed her and married her (Sahih al-Bukhari 371), and when Hafsah (may Allah be pleased with her) taunted her as “the daughter of a Jew“ he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3894", cite: "Sunan al-Tirmidhi 3894; graded sahih by al-Albani", arabic: 58...69, english: 52...80)
                    Text(verbatim: "And the rule Allah laid down for every non-Muslim who is not at war with the Muslims applies to the Jews as to anyone else:")
                        .font(.body)
                    ScriptureQuote(quran: "60:8")

                    Text(articleMarkdown: "**What happened between the Prophet and the Jewish tribes of Madinah?**")
                        .font(.body)
                    Text(verbatim: "When the Prophet (peace be upon him) arrived in Madinah he made a written covenant with its Jewish tribes, recorded in the Sirah of Ibn Hisham: they kept their religion and property, and each side would defend the city and not aid its enemies. The three main tribes broke it in turn. Banu Qaynuqa broke the peace after Badr and were besieged and expelled. Banu an-Nadir plotted to kill the Prophet, were besieged, and were exiled with what their camels could carry; Surat al-Hashr describes it (Quran 59:2-4):")
                        .font(.body)
                    ScriptureQuote(quran: "59:4")
                    Text(verbatim: "Banu Qurayzah were left in place after that, as Ibn Umar (may Allah be pleased with them) reports, until they too fought against him (Sahih al-Bukhari 4028), siding with the Confederates who besieged Madinah in the Battle of the Trench, as Surat al-Ahzab records (Quran 33:26-27). When they surrendered they chose to accept the verdict of Sa‘d ibn Mu‘adh (may Allah be pleased with him), their former ally, who ruled that the fighting men be executed and the rest taken captive, and the Prophet (peace be upon him) said he had judged with the judgement of Allah (Sahih al-Bukhari 4121); the sentence was also what their own Torah prescribes for a city taken in war (Deuteronomy 20:12-14). Allah says:")
                        .font(.body)
                    ScriptureQuote(quran: "33:26")
                    Text(verbatim: "The cause in each case was treachery and war, not religion. The Jews of Khaybar, after their defeat, were left on their land as tenants paying half the harvest (Sahih al-Bukhari 2328), and at the Prophet’s death his armour was still in pledge with a Jew (Sahih al-Bukhari 2916, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Why did most Jews reject Muhammad?**")
                        .font(.body)
                    Text(verbatim: "Not for lack of recognition. The Quran says they knew him as they knew their own sons (Quran 2:146, quoted above), and that they had been praying for his coming:")
                        .font(.body)
                    ScriptureQuote(quran: "2:89", words: 16...25)
                    ScriptureQuote(quran: "2:109", words: 0...20)
                    ScriptureQuote(quran: "6:20")
                    Text(verbatim: "The cause the Quran names is envy that prophethood had passed from Bani Isra’il to the children of Isma‘il (Quran 2:90). The story of Abdullah ibn Salam (may Allah be pleased with him) shows it. Before announcing his Islam he asked the Prophet (peace be upon him) to question the Jews about him; they called him the best of them and the son of the best of them, and when he then declared his faith they called him the worst of them and the son of the worst (Sahih al-Bukhari 3938). The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3941", cite: "Sahih al-Bukhari 3941", arabic: 20...28, english: 4...20)

                    Text(articleMarkdown: "**Is the Torah of today preserved?**")
                        .font(.body)
                    Text(verbatim: "Not intact. The Quran says that they distorted words, forgot a portion, and wrote with their own hands (Quran 5:13 and 2:79, quoted above), and that a party of them altered the Torah knowingly:")
                        .font(.body)
                    ScriptureQuote(quran: "2:75")
                    ScriptureQuote(quran: "5:15", words: 0...15)
                    Text(verbatim: "The text itself bears this out. Deuteronomy 34 narrates the death of Musa. Three ancient versions of the Torah survive, the Hebrew Masoretic text, the Samaritan Pentateuch, and the Greek Septuagint, and they differ from one another in thousands of readings; in the ages of the patriarchs in Genesis 5 and 11 the differences add up to more than a thousand years of chronology. The Dead Sea Scrolls show these differing text-types already circulating side by side before the time of Jesus. The oldest complete Hebrew manuscript dates from around 1000 CE. What is true in it is confirmed by the Quran, which Allah Himself has guarded (Quran 15:9).")
                        .font(.body)

                    Text(articleMarkdown: "**Is Muhammad mentioned in the Torah?**")
                        .font(.body)
                    Text(verbatim: "Yes (Quran 7:157, quoted above). Abdullah ibn Amr (may Allah be pleased with them), who had read the earlier scriptures, was asked about the Prophet’s description in the Torah and answered:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:2125", cite: "Sahih al-Bukhari 2125", arabic: 48...70, english: 50...113)
                    Text(verbatim: "In the Torah as it stands, Musa is promised a prophet “like unto“ himself from the “brethren“ of Israel (Deuteronomy 18:18), which Ibn Taymiyyah and Ibn al-Qayyim read as the children of Isma‘il, of whom Allah had promised Ibrahim twelve princes and a great nation (Genesis 17:20). The blessing of Musa says the Lord “came from Sinai, and rose up from Seir unto them; he shined forth from mount Paran“ (Deuteronomy 33:2): Sinai is the revelation to Musa, Seir the land of Isa, and Paran the wilderness where Isma‘il settled (Genesis 21:21), that is, the Hijaz. Isaiah 42 foretells a servant who brings law to the nations and calls on Kedar, the son of Isma‘il (Genesis 25:13), to sing a new song. Ibn al-Qayyim gathered these in Hidayat al-Hayara, and Ibn Taymiyyah in al-Jawab as-Sahih.")
                        .font(.body)

                    Text(articleMarkdown: "**Which son did Ibrahim take to sacrifice?**")
                        .font(.body)
                    Text(verbatim: "Isma‘il. The Quran tells the story without naming him, but the order of the narrative settles it:")
                        .font(.body)
                    ScriptureQuote(quran: "37:102")
                    ScriptureQuote(quran: "37:112")
                    Text(verbatim: "The good news of Ishaq comes after the sacrifice, so the boy of the sacrifice was the son Ibrahim already had, Isma‘il. Moreover Ishaq was announced together with Ya‘qub, his son, to come after him (Quran 11:71), so Ibrahim could not have been commanded to sacrifice him as a boy; and the ransom of the ram is tied to the rites of Makkah, where Isma‘il was raised (Sahih al-Bukhari 3364). This is the view of Ibn Taymiyyah (Majmu‘ al-Fatawa), Ibn al-Qayyim (Zad al-Ma‘ad), and Ibn Kathir (in his tafsir and al-Bidayah wan-Nihayah). The Torah itself supports it: Genesis 22:2 calls the son to be sacrificed “thine only son,“ and Isma‘il was born some fourteen years before Ishaq (Genesis 16:16, 21:5), so for those years he alone was the only son. Ibn Kathir regarded the name of Ishaq in that verse as an insertion.")
                        .font(.body)

                    Text(articleMarkdown: "**Was Ibrahim a Jew?**")
                        .font(.body)
                    ScriptureQuote(quran: "3:65")
                    Text(verbatim: "The Torah came centuries after Ibrahim, and the very word “Jew“ comes from his great-grandson Yahudha. He was a hanif, a Muslim (Quran 3:67-68, quoted above), and so were his sons:")
                        .font(.body)
                    ScriptureQuote(quran: "2:131-132")

                    Text(articleMarkdown: "**What laws do Jews and Muslims share?**")
                        .font(.body)
                    Text(verbatim: "A great deal, because the source is one. Circumcision (Sahih al-Bukhari 3356, quoted below). Dietary law: no pork, no blood, no carrion, and slaughter by the throat, so that Allah made their food lawful for Muslims:")
                        .font(.body)
                    ScriptureQuote(quran: "5:5", words: 4...12)
                    Text(verbatim: "Fasting, which the Torah and Ashura show:")
                        .font(.body)
                    ScriptureQuote(quran: "2:183", words: 3...13)
                    Text(verbatim: "Ritual purity, with washing after impurity and before worship (Leviticus 15, Exodus 30:19-21). Prayer at fixed times, morning, noon and evening (Daniel 6:10, Psalm 55:17), with prostration on the face (Numbers 20:6, Genesis 17:3). Modest dress and the head covering of women (Genesis 24:65). The prohibition of images and of usury among the people (Deuteronomy 23:19-20), which Islam extends to all mankind. A Jew who visits a mosque and a Muslim who visits a synagogue each recognise the other.")
                        .font(.body)

                    Text(articleMarkdown: "**Will the Jews believe in Isa when he returns?**")
                        .font(.body)
                    ScriptureQuote(quran: "4:159")
                    Text(verbatim: "Ibn Kathir explains, following Ibn Jarir at-Tabari, that “before his death“ means before the death of Isa: when he descends, every Jew and Christian who remains will believe in him as he truly is, the servant and messenger of Allah, and Abu Hurayrah (may Allah be pleased with him) recited this ayah after narrating the hadith of his descent (Sahih al-Bukhari 3448). Before that, the Dajjal will claim to be the Messiah and gather followers from among them (Sahih Muslim 2944, quoted below), and Isa will kill him (Sahih Muslim 2937).")
                        .font(.body)

                    Text(articleMarkdown: "**Are Jews disbelievers, and what is owed to them?**")
                        .font(.body)
                    Text(verbatim: "Whoever hears of Muhammad (peace be upon him) and rejects him is a disbeliever in the Quran’s terms, whatever his lineage, just as the Quran says of the Christians who call Allah one of three (Quran 5:73). Surat al-Bayyinah opens by naming “those who disbelieved among the People of the Scripture“ (Quran 98:1) and states their end:")
                        .font(.body)
                    ScriptureQuote(quran: "98:6")
                    ScriptureQuote(hadith: "muslim:153", cite: "Sahih Muslim 153", arabic: 29...54, english: 0...52)
                    Text(verbatim: "Judgement of individuals belongs to Allah, who does not punish anyone the message never reached (Quran 17:15). What is owed to them in this world is justice, kindness where there is no war (Quran 60:8, quoted above), the honouring of treaties, and the protection of their lives and property:")
                        .font(.body)
                    ScriptureQuote(quran: "5:8")
                    ScriptureQuote(hadith: "bukhari:3166", cite: "Sahih al-Bukhari 3166", arabic: 32...45, english: 4...31)
                    Text(verbatim: "Umar (may Allah be pleased with him) made fulfilling Allah’s covenant with the People of the Scripture part of his final advice (Sahih al-Bukhari 3162, mentioned above).")
                        .font(.body)

                    Text(articleMarkdown: "**Should Muslims hate Jews?**")
                        .font(.body)
                    Text(verbatim: "No. Hatred in Islam is for disbelief and oppression, never for a lineage, and it never licenses injustice. A Jew who accepts Islam is a brother in full, as Abdullah ibn Salam and Safiyyah were, and the Prophet (peace be upon him) rebuked his own wife for a taunt about Safiyyah’s birth (Sunan al-Tirmidhi 3894, quoted above). Allah commands:")
                        .font(.body)
                    ScriptureQuote(quran: "5:2", words: 26...45)
                    ScriptureQuote(quran: "16:90", words: 1...13)
                    Text(verbatim: "Ibn Taymiyyah (may Allah have mercy on him) explains in Majmu‘ al-Fatawa that love and enmity for the sake of Allah follow faith and deeds, so that one person may deserve both in different measures, and that a believer is commanded to be just even to those he opposes. The Muslim rejects what the Jews rejected of the truth and invites them to it; he does not hate them for being Jews.")
                        .font(.body)

                    Text(articleMarkdown: "**What is the Muslim view of the Jewish expectation of a Messiah?**")
                        .font(.body)
                    Text(verbatim: "The Messiah already came. He was Isa ibn Maryam (Quran 3:45, quoted below), and he announced the messenger who would follow him:")
                        .font(.body)
                    ScriptureQuote(quran: "61:6")
                    Text(verbatim: "The one who will come claiming to be the awaited Messiah is the Dajjal, of whom every prophet warned his people:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:7131", cite: "Sahih al-Bukhari 7131", arabic: 22...41, english: 4...45)
                    Text(verbatim: "Then the true Messiah will return (Sahih al-Bukhari 3448, Sahih Muslim 155), and those who have waited for a Messiah will find him to be the one their fathers rejected.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE INVITATION")) {
                    ScriptureQuote(quran: "3:64", words: 0...24)

                    Text(verbatim: "The God of Abraham, Isaac, Jacob, and Moses is Allah, and the religion they brought was submission to Him. The Muslim invites the Jew to the last prophet of that same line, foretold by Moses, and to the Book that confirms the truth of what came before it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Islam honours Moses and the Torah, and asks the Children of Israel to keep the covenant they gave: to believe in the messengers who came after him, whom their own scripture foretold, and to worship the God of Abraham as Abraham did.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Yahud (اليَهُود)**: the Jews. Ibn Kathir (may Allah have mercy on him), in his tafsir of 2:62, relates that the name comes from **hada (هَادَ)**, to return and repent, from the words of Musa’s people, “inna hudna ilayk“ (indeed, we have turned back to You); the commentators also mention **Yahudha (يَهُوذَا)**, Judah, the son of Ya‘qub whose tribe gave its name to the kingdom of Judah and then to the whole people:")
                        .font(.body)
                    ScriptureQuote(quran: "7:156", words: 1...11)

                    Text(articleMarkdown: "**Bani Isra’il (بَنُو إِسرَائِيل)**: the Children of Israel. Isra’il is the prophet Ya‘qub (Jacob), as the Quran shows when it says that Israel forbade a food upon himself before the Torah was revealed (Quran 3:93); Ibn Kathir notes that the name means “servant of Allah.“ His twelve sons became the twelve tribes, the **asbat (الأَسبَاط)**:")
                        .font(.body)
                    ScriptureQuote(quran: "7:160", words: 0...4)

                    Text(articleMarkdown: "**Ahl al-Kitab (أَهلُ الكِتَاب)**: “the People of the Scripture,“ the Jews and the Christians, who received a revealed Book before the Quran. Islam gives them a standing distinct from the idolaters: their slaughtered meat and their chaste women are lawful to Muslims (Quran 5:5), they are argued with in the best manner (Quran 29:46), and they are invited to the common word of worshipping Allah alone (Quran 3:64, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Tawrah (التَّورَاة)**: the Hebrew torah, “instruction“: the revelation given to Musa, in which was guidance and light (Quran 5:44, quoted above). Today “Torah“ names the first five books of the Bible, the Pentateuch (Genesis, Exodus, Leviticus, Numbers, Deuteronomy). These contain much of what was revealed, but they were not all written by Musa: Deuteronomy 34 records his death and burial, says that no one knows his grave “unto this day,“ and speaks of him in the past. This is what the Quran means when it says that a portion was forgotten and that men wrote with their own hands (Quran 5:13, 2:79, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Talmud (التَّلمُود)**: the “oral law“ of the rabbis: the Mishnah, a code compiled around 200 CE, and the Gemara, the commentary on it completed around 500 CE in the Babylonian Talmud. Rabbinic Judaism is built on it as much as on the Torah. For Muslims it is the opinion of scholars, not revelation, and the Quran warns against turning the words of scholars into law beside Allah’s (Quran 9:31, quoted below).")
                        .font(.body)

                    Text(articleMarkdown: "**Zabur (الزَّبُور)**: from **zabara (زَبَرَ)**, to write; the Book given to Dawud (David), corresponding to the Psalms. The Quran mentions it three times (Quran 4:163, 17:55, 21:105). Muslims hold that Dawud was a prophet and a king, not merely a poet:")
                        .font(.body)
                    ScriptureQuote(quran: "4:163", words: 23...25)

                    Text(articleMarkdown: "**Ahbar (أَحبَار) and rabbaniyyun (رَبَّانِيُّون)**: the scholars of the Jews. Ahbar is the plural of **habr (حَبر)**, a learned man; rabbani is from **rabb (رَبّ)**, one who raises people with knowledge, and the title “rabbi“ comes from the Hebrew rav, master. The Quran honours those who judged by the Tawrah (Quran 5:44, quoted above) and condemns those who concealed the truth and sold it (Quran 5:63, 2:174). It then says of their followers:")
                        .font(.body)
                    ScriptureQuote(quran: "9:31", words: 0...19)
                    Text(verbatim: "The Salaf explained that taking scholars as lords does not mean bowing to them; it means obeying them when they made lawful what Allah had forbidden and forbade what He had allowed. Hudhayfah and Ibn Abbas (may Allah be pleased with them) said so, as at-Tabari records in his tafsir, and Ibn Taymiyyah explains it at length in Majmu‘ al-Fatawa. The warning applies to Muslims who do the same with their own scholars.")
                        .font(.body)

                    Text(articleMarkdown: "**Sabbath, as-Sabt (السَّبت)**: Saturday, the day of rest imposed on Bani Isra’il as part of their covenant, on which they were forbidden to work. The Quran recalls the oath they took, the town by the sea whose people fished on the Sabbath and were punished (Quran 7:163, 2:65), and states that the Sabbath was a test for that people, not a law for all:")
                        .font(.body)
                    ScriptureQuote(quran: "4:154", words: 9...18)
                    ScriptureQuote(quran: "16:124")
                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:876", cite: "Sahih al-Bukhari 876", arabic: 41...70, english: 7...92)
                    Text(verbatim: "Islam’s day is Friday, a day of congregational prayer, not of rest.")
                        .font(.body)

                    Text(articleMarkdown: "**The Messiah, al-Masih (المَسِيح), Hebrew Mashiah**: “the anointed one,“ the king from the line of Dawud whom the Jews awaited. The Quran declares that Isa ibn Maryam was that Messiah, and that the Jews rejected him:")
                        .font(.body)
                    ScriptureQuote(quran: "3:45", words: 9...19)
                    Text(verbatim: "They still await another, and the Prophet (peace be upon him) warned that a false messiah, al-Masih ad-Dajjal, will come before the Hour and that many of them will follow him:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2944", cite: "Sahih Muslim 2944", arabic: 31...39, english: 0...13)

                    Text(articleMarkdown: "**Bayt al-Maqdis (بَيتُ المَقدِس) and the Temple of Sulayman**: “the Holy House,“ the sanctuary of Jerusalem, which the Quran calls **al-Masjid al-Aqsa (المَسجِدُ الأَقصَى)**, the farthest mosque. It was the first qiblah of the Muslims and the destination of the Prophet’s night journey:")
                        .font(.body)
                    ScriptureQuote(quran: "17:1")
                    Text(articleMarkdown: "The Prophet (peace be upon him) said it was the second mosque built on earth, forty years after the Ka‘bah (Sahih al-Bukhari 3366), and one of only three mosques to which a journey may be undertaken (Sahih al-Bukhari 1189). The prophet Sulayman (Solomon) built its temple, with the jinn Allah had subjected to him working for him (Quran 34:12-13), and when he finished he asked Allah for three things, among them that whoever came to it only to pray there would leave as free of sin as on the day his mother bore him (Sunan an-Nasa’i 693; graded sahih by al-Albani). The Quran records that the Children of Israel were twice punished for corruption by enemies who entered the sanctuary (Quran 17:4-7). Muslims call the city **al-Quds (القُدس)**, the Holy.")
                        .font(.body)

                    Text(articleMarkdown: "**The Ark, at-Tabut (التَّابُوت)**: the chest of the covenant of the Bible (Exodus 25), which held relics of the family of Musa and Harun. The Quran mentions its return as the sign of the kingship of Talut (Saul):")
                        .font(.body)
                    ScriptureQuote(quran: "2:248", words: 3...21)

                    Text(articleMarkdown: "**Circumcision (الخِتَان) and kosher (الكَاشِير)**: two laws Jews and Muslims share. Circumcision is the covenant of Ibrahim, and the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3356", cite: "Sahih al-Bukhari 3356", arabic: 32...42, english: 4...15)
                    Text(verbatim: "Kosher (Hebrew kasher, “fit“) is the Jewish dietary law: no pork, no blood, animals slaughtered by cutting the throat. The halal of Islam is close to it, which is why Allah made the food of the People of the Scripture lawful (Quran 5:5, quoted above). But some Jewish prohibitions were a punishment specific to them, which Jesus was sent to lift in part (Quran 3:50):")
                        .font(.body)
                    ScriptureQuote(quran: "6:146", words: 0...6)

                    Text(articleMarkdown: "**Samaritans (السَّامِرِيُّون)**: a small community, fewer than a thousand people today, that accepts only the Torah (in its own version, the Samaritan Pentateuch), worships on Mount Gerizim rather than in Jerusalem, and has been at odds with the Jews since ancient times (John 4:9). The Quran names **as-Samiri (السَّامِرِيّ)** as the man who made the calf for Bani Isra’il in the absence of Musa; the exegetes differ on his origin, and some said he was of a tribe of that name:")
                        .font(.body)
                    ScriptureQuote(quran: "20:85")

                    Text(articleMarkdown: "**Orthodox, Conservative, Reform**: the main branches of Judaism today. Orthodox Jews hold the written and oral law binding in full; Reform Judaism, begun in nineteenth-century Germany, treats the law as adaptable to modern life; Conservative Judaism stands between them. A Muslim finds the Orthodox nearest to what the Quran describes of the religion of Musa, and all of them further from it than Islam is.")
                        .font(.body)

                    Text(articleMarkdown: "**Isra’iliyyat (الإِسرَائِيلِيَّات)**: reports taken from Jewish sources that found their way into the books of tafsir and history. The Prophet (peace be upon him) permitted narrating them and forbade taking them as truth:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3461", cite: "Sahih al-Bukhari 3461", arabic: 29...46, english: 4...55)
                    ScriptureQuote(hadith: "bukhari:4485", cite: "Sahih al-Bukhari 4485", arabic: 47...58, english: 30...52)
                    Text(verbatim: "Ibn Kathir set out the rule in the introduction to his tafsir: what the Quran and Sunnah confirm is accepted, what they contradict is rejected, and what they are silent about is neither believed nor denied, and it is not narrated as religion.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "JudaismAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Judaism")
        .selectableArticleList(article: "JudaismAnswerView")
    }
}

struct HinduismAnswerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Hinduism worships many gods through images and teaches rebirth and caste. The Quran answers with the argument of Ibrahim against idols, the oneness of the Creator, the resurrection instead of reincarnation, and the equality of all people before Allah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT HINDUISM TEACHES")) {
                    Text(articleMarkdown: "Hinduism is not one creed but a family of traditions from India. Most Hindus worship many deities (Brahma, Vishnu, Shiva, Krishna, Rama, Ganesha, Durga, and others) through **murtis**, images and statues, in temples and homes; many also speak of one supreme reality, **Brahman**, behind them all, and some hold that the deities are its faces. Central are **karma** and **samsara**, the cycle of rebirth in which the soul returns in a new body according to its deeds, and the ordering of society into hereditary **castes**.")
                        .font(.body)

                    Text(articleMarkdown: "Notably, the oldest Hindu scriptures contain statements of one God without image: “He is One, without a second“ (Chandogya Upanishad 6:2:1), and a verse whose Sanskrit says **na tasya pratima asti**, “there is no pratima of Him“ (Shvetashvatara Upanishad 4:19; Yajurveda 32:3), which Muslims read as “no image“ and many Hindu commentators read as “no likeness“ or “no equal.“ Either reading says the same thing about worship: what has no likeness cannot be represented by a carved one. Islam calls Hindus back to that.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. THE ARGUMENT OF IBRAHIM")) {
                    Text(verbatim: "Ibrahim (peace be upon him) grew up among a people who carved and worshipped images, and the Quran records his challenge:")
                        .font(.body)
                    ScriptureQuote(quran: "21:52-54")

                    Text(verbatim: "He broke the idols and left the largest, and when they asked who had done it, he told them to ask the big one, if it could speak. They knew it could not, and he said:")
                        .font(.body)
                    ScriptureQuote(quran: "21:66-67")

                    ScriptureQuote(quran: "2:170")
                }

                Section(header: ArticleHeader("2. THE CREATOR IS ONE, AND HAS NO IMAGE")) {
                    ScriptureQuote(quran: "21:22")

                    ScriptureQuote(quran: "22:73")

                    ScriptureQuote(quran: "16:20-21")

                    Text(verbatim: "A statue is made by a man from stone; the one who made it is greater than it. And Allah has no form to be carved:")
                        .font(.body)
                    ScriptureQuote(quran: "42:11", words: 13...18)

                    Text(verbatim: "If the images are meant only as “aids“ to reach the one Brahman behind them, that is the very excuse of the pagans of Makkah, and the Quran rejected it (Quran 39:3). Allah is reached directly, without images or intermediaries (Quran 2:186).")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. RESURRECTION, NOT REBIRTH")) {
                    Text(verbatim: "There is no cycle of rebirth. Each soul lives once, dies once, and is raised once to be judged, with full justice and no forgetting:")
                        .font(.body)
                    ScriptureQuote(quran: "23:99-100")

                    ScriptureQuote(quran: "75:3-4")

                    ScriptureQuote(quran: "99:7-8")

                    Text(verbatim: "The idea of karma reaches for justice, and Islam gives it in full: every deed is recorded and repaid, but by a Judge who knows, not by a blind law, and with a mercy that forgives the one who repents. Nobody is punished for a life he cannot remember.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. NO CASTE BEFORE ALLAH")) {
                    ScriptureQuote(quran: "49:13")

                    ScriptureQuote(quran: "17:70")

                    Text(verbatim: "In the Farewell Sermon the Prophet (peace be upon him) declared that no Arab has superiority over a non-Arab, nor a white man over a black man, nor a black man over a white man, except by piety (Musnad Ahmad 23489; graded sahih by al-Albani). Bilal, an Abyssinian former slave, gave the call to prayer from the roof of the Ka‘bah. There is no priestly caste in Islam and no untouchable; all stand shoulder to shoulder in one row.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Do Hindus and Muslims worship the same God?**")
                        .font(.body)
                    Text(verbatim: "There is only one Creator, and whoever turns to the Maker of the heavens and the earth is turning to Him; the Quran told the Muslims to say to the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(quran: "29:46", words: 20...25)
                    Text(verbatim: "But worship offered to murtis, to avatars, or to a pantheon of devas is not worship of that One; it is what Ibrahim (peace be upon him) rebuked in his father and his people (Quran 21:52-54). Allah accepts worship only when it is His alone:")
                        .font(.body)
                    ScriptureQuote(quran: "4:48")

                    Text(articleMarkdown: "**Did Hindu scriptures mention Muhammad (peace be upon him)?**")
                        .font(.body)
                    Text(verbatim: "Some Muslims point to passages in the Vedas and Puranas that they read as prophecies of a final messenger. These readings are disputed, and Islam does not rest on them; the Prophet’s truth is proved by the Quran itself. What is certain is that no people was left without a warner, so India too was reached by Allah’s message in its time, whether or not any record of it survives:")
                        .font(.body)
                    ScriptureQuote(quran: "35:24", words: 5...11)
                    ScriptureQuote(quran: "16:36", words: 0...10)
                    Text(verbatim: "Every messenger spoke the language of his people (Quran 14:4), and Allah has told us the stories of some messengers and not of others (Quran 40:78). We do not put names to the ones He did not name.")
                        .font(.body)

                    Text(articleMarkdown: "**Were Rama or Krishna prophets?**")
                        .font(.body)
                    Text(verbatim: "We do not know, and we neither affirm nor deny it, for Allah has told us of some messengers and not of others (Quran 4:164):")
                        .font(.body)
                    ScriptureQuote(quran: "40:78", words: 0...13)
                    Text(verbatim: "What we do know is what every true messenger taught, so if a prophet was sent to India, this was his message:")
                        .font(.body)
                    ScriptureQuote(quran: "21:25")
                    Text(verbatim: "The stories that make Rama or Krishna an incarnation of God, and the worship offered to their images, cannot come from a prophet, because no prophet is ever worshipped and no prophet ever asked to be:")
                        .font(.body)
                    ScriptureQuote(quran: "3:79-80")
                    Text(verbatim: "This is the same answer Islam gives about Isa (peace be upon him): a true messenger, later raised by his followers to a rank he never claimed.")
                        .font(.body)

                    Text(articleMarkdown: "**Is yoga allowed?**")
                        .font(.body)
                    Text(verbatim: "Stretching, breathing exercises, and postures done purely for the health of the body are permitted, like any exercise, so long as nothing of Hindu belief or ritual is attached to them. What is not permitted is the religious core of yoga: the Sun Salutation (surya namaskar), which is by name and by form a sequence of bowing to the sun; chanting OM or mantras to deities; and the aim of “union” with Brahman or of awakening a divine energy within. Allah says:")
                        .font(.body)
                    ScriptureQuote(quran: "41:37", words: 6...14)
                    ScriptureQuote(quran: "2:165", words: 0...15)
                    Text(verbatim: "The Muslim who wants stillness and discipline has the prayer, the night prayer, dhikr, and reflection on creation, none of which borrow the rites of another religion. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:4031", cite: "Sunan Abi Dawud 4031; graded hasan sahih by al-Albani", arabic: 34...38, english: 4...12)
                    Text(verbatim: "The pagans of Makkah were told: “For you is your religion, and for me is my religion” (Quran 109:6). A Muslim keeps his worship unmixed.")
                        .font(.body)

                    Text(articleMarkdown: "**Why do Muslims eat beef while Hindus revere the cow?**")
                        .font(.body)
                    Text(verbatim: "Because Allah, who created the cattle, made them lawful and named them among His gifts:")
                        .font(.body)
                    ScriptureQuote(quran: "5:1", words: 5...12)
                    ScriptureQuote(quran: "16:5")
                    Text(verbatim: "The pagan Arabs also set animals apart for their idols: beasts no one might eat but whom they chose, and camels whose backs they forbade, and the Quran rebuked them for it (Quran 6:138-139):")
                        .font(.body)
                    ScriptureQuote(quran: "5:103", words: 0...17)
                    Text(verbatim: "The Prophet (peace be upon him) himself sacrificed cows. Aishah (may Allah be pleased with her) said of the Farewell Hajj:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1709", cite: "Sahih al-Bukhari 1709", arabic: 67...85, english: 64...95)
                    Text(verbatim: "The Quran also records two warnings about sanctifying an animal: the calf that Bani Isra’il worshipped in Musa’s absence, of which Allah said:")
                        .font(.body)
                    ScriptureQuote(quran: "20:88-89")
                    Text(verbatim: "And the cow that Bani Isra’il were commanded to slaughter (Quran 2:67-71), from which the longest surah of the Quran takes its name, al-Baqarah. At the same time Islam commands kindness to every animal; the Prophet (peace be upon him) said that Allah has prescribed ihsan in everything, even in slaughter (Sahih Muslim 1955). A Muslim eats beef with gratitude and never with mockery of his Hindu neighbour.")
                        .font(.body)

                    Text(articleMarkdown: "**Reincarnation or resurrection?**")
                        .font(.body)
                    Text(verbatim: "Resurrection. The soul does not pass from body to body; it is taken at death, held in the barzakh, and returned to its own body on the Day of Judgement (Quran 23:99-100; 39:42). The One who made the body the first time will remake it:")
                        .font(.body)
                    ScriptureQuote(quran: "36:78-79")
                    Text(verbatim: "The same person who acted is the one who answers, and he remembers. Even the punishment of the Fire is described as happening to one continuing body:")
                        .font(.body)
                    ScriptureQuote(quran: "4:56")
                    Text(verbatim: "And the people of Paradise die only once:")
                        .font(.body)
                    ScriptureQuote(quran: "44:56")
                    Text(verbatim: "Reincarnation punishes a person for a life he cannot remember and rewards him for one he cannot recall; the resurrection judges a man for what he knows he did, with his own limbs as witnesses (Quran 36:65).")
                        .font(.body)

                    Text(articleMarkdown: "**Caste or equality?**")
                        .font(.body)
                    Text(verbatim: "Equality of origin and of worth, with rank only by piety (Quran 49:13). The Farewell Sermon abolished the superiority of Arab over non-Arab and of one colour over another (mentioned above). The Prophet (peace be upon him) also said:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3955", cite: "Sunan al-Tirmidhi 3955; graded hasan by al-Albani", arabic: 53...73, english: 40...80)
                    Text(verbatim: "When Abu Dharr (may Allah be pleased with him) insulted a man by his mother, the Prophet (peace be upon him) told him:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:30", cite: "Sahih al-Bukhari 30", arabic: 40...54, english: 45...78)
                    Text(verbatim: "Bilal the Abyssinian, Salman the Persian, and Suhayb the Roman (may Allah be pleased with them) sat with the nobles of Quraysh as equals. Zayd ibn Harithah, a freed slave, commanded the army at Mu’tah (Sahih al-Bukhari 4261), and when some criticised the command of his son Usamah, the Prophet (peace be upon him) said that Zayd had deserved the leadership and was among the most beloved of people to him, and that Usamah was so after him (Sahih al-Bukhari 4469). In every mosque the rich man and the poor man stand in one row and prostrate on one floor. No one is born a priest, and no one is born untouchable.")
                        .font(.body)

                    Text(articleMarkdown: "**Is Islam a foreign Arab religion for India?**")
                        .font(.body)
                    Text(verbatim: "Islam came to the Arabs first but was never for them alone:")
                        .font(.body)
                    ScriptureQuote(quran: "34:28", words: 0...6)
                    ScriptureQuote(quran: "21:107")
                    Text(verbatim: "Among the Companions were an Abyssinian, a Persian, and a Roman. When Surat al-Jumu‘ah was revealed and Abu Hurayrah asked who the “others” not yet joined to the Arabs were, the Prophet (peace be upon him) put his hand on Salman al-Farisi and said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4897", cite: "Sahih al-Bukhari 4897", arabic: 68...80, english: 74...100)
                    Text(verbatim: "Muhammad ibn al-Qasim entered Sindh in 92-93 AH (711-712 CE), within a century of the Hijrah (al-Baladhuri, Futuh al-Buldan), and today more Muslims live in South Asia than in all the Arab lands together. A religion is not judged by the land it started in but by whether it is true; Ibrahim, Musa, and Isa (peace be upon them) were none of them Indian, and the truth they brought was for every land.")
                        .font(.body)

                    Text(articleMarkdown: "**What about karma and justice?**")
                        .font(.body)
                    Text(verbatim: "Islam gives everything karma reaches for and more. Every deed is weighed (Quran 99:7-8), no one is wronged, and good is multiplied (Quran 4:40). No soul carries another’s burden:")
                        .font(.body)
                    ScriptureQuote(quran: "6:164", words: 9...19)
                    ScriptureQuote(quran: "53:38-41")
                    Text(verbatim: "But the Judge is a Person who sees, not a mechanism that grinds. He can be asked, and He forgives:")
                        .font(.body)
                    ScriptureQuote(quran: "39:53")
                    Text(verbatim: "Karma has no one to repent to, no one to pray to, and no mercy; it explains the suffering of a child by a crime the child cannot remember. Islam says the child is innocent, the trial has a purpose, and the account is settled once, in full, before a Lord who is both Just and Merciful.")
                        .font(.body)

                    Text(articleMarkdown: "**Do Muslims believe in an impersonal absolute like Brahman?**")
                        .font(.body)
                    Text(verbatim: "No. Allah is not a force, a principle, or a ground of being; He is a living Lord who describes Himself by name:")
                        .font(.body)
                    ScriptureQuote(quran: "59:22-24")
                    Text(verbatim: "He is One without parts or equal (Quran 112), nothing is like Him (Quran 42:11), and He is near to whoever calls Him (Quran 2:186). In a hadith qudsi He says:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:7405", cite: "Sahih al-Bukhari 7405", arabic: 31...74, english: 6...120)
                    Text(verbatim: "An impersonal absolute cannot love you, hear you, or forgive you. Allah does all three.")
                        .font(.body)

                    Text(articleMarkdown: "**Does Islam accept the Vedas or the Gita as revelation?**")
                        .font(.body)
                    Text(verbatim: "We do not know their origin, and we neither declare them revealed nor declare that no revelation ever reached India (Quran 40:78). The rule the Prophet (peace be upon him) gave for the books of others is this:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4485", cite: "Sahih al-Bukhari 4485", arabic: 47...57, english: 30...52)
                    Text(verbatim: "The Quran is the guardian and judge over whatever came before:")
                        .font(.body)
                    ScriptureQuote(quran: "5:48", words: 0...11)
                    Text(verbatim: "So the sentences in the Upanishads that say the One has no image and no second are true, and we say so gladly; the hymns to many gods, the caste of the Purusha Sukta, and the avatars are not from Allah, and we say that too.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE INVITATION")) {
                    Text(verbatim: "Islam asks the Hindu to keep what the oldest of his scriptures said, that the One has no image and no second, and to leave the many gods for the One who made them all:")
                        .font(.body)
                    ScriptureQuote(quran: "13:16", words: 0...27)

                    ScriptureQuote(quran: "16:125", words: 0...10)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "One Creator without image, one life followed by judgement, and one humanity ranked only by piety: this is what Ibrahim taught in a land of idols, and what Islam offers in its place.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Hindu (هِندُوسِيّ)**: not a name from any scripture. It comes from Sindhu, the Sanskrit name of the Indus river; the Persians pronounced it “Hindu” and used it for the land and the peoples beyond that river, and the Arabs took it from them as al-Hind (الهِند). “Hinduism” as the name of one religion is a modern usage, gathering under one word many traditions and philosophies that never called themselves by it.")
                        .font(.body)

                    Text(articleMarkdown: "**Sanatana Dharma**: “the eternal order” or “eternal law,” the name many Hindus prefer for their tradition. Islam agrees that the true religion is eternal and one, but says it is the religion Allah gave to every prophet, not a set of rites tied to one land:")
                        .font(.body)
                    ScriptureQuote(quran: "42:13", words: 1...23)
                    ScriptureQuote(quran: "3:19", words: 0...4)

                    Text(articleMarkdown: "**Brahman** and **Ishvara**: Brahman is the impersonal absolute of the Upanishads, the one reality behind all things, of which the school of Advaita (“non-duality,” taught by Shankara around the eighth century CE) says that the soul and the world are ultimately not different from it. Ishvara is a personal Lord, worshipped under names such as Vishnu or Shiva. Islam rejects both the impersonal absolute and the many lords: Allah is one personal Lord who knows, hears, sees, speaks, loves, and is pleased and angered, and He is utterly distinct from His creation:")
                        .font(.body)
                    ScriptureQuote(quran: "2:255", words: 0...11)
                    ScriptureQuote(quran: "19:93")

                    Text(articleMarkdown: "**Atman**: the self or soul, which Advaita holds to be identical with Brahman (“that thou art,” Chandogya Upanishad 6:8:7). Islam affirms that the soul (**ruh, الرُّوح**) is real, but it is a created thing whose nature Allah has kept mostly hidden (Quran 17:85). Allah breathed into Adam “of My [created] soul” (Quran 15:29); the soul is His creation and His servant, never a part of Him. Ibn Taymiyyah (may Allah have mercy on him) wrote at length against the Sufi doctrine of the “unity of existence” (wahdat al-wujud) precisely because it makes the creature one with the Creator, the same error in a Muslim dress (Majmu‘ al-Fatawa, volume 2).")
                        .font(.body)

                    Text(articleMarkdown: "**Samsara**: the cycle of birth, death, and rebirth in which the soul returns in new bodies. Islam knows one birth, one death, and one resurrection (Quran 23:99-100). The people of Paradise will say to one another:")
                        .font(.body)
                    ScriptureQuote(quran: "37:58-59")

                    Text(articleMarkdown: "**Karma**: literally “action”; the law by which deeds bear fruit in this life or the next. Islam affirms that every deed is recorded and repaid in full (Quran 99:7-8), but by a Judge who knows and forgives, not by a blind mechanism:")
                        .font(.body)
                    ScriptureQuote(quran: "4:40")

                    Text(articleMarkdown: "**Moksha**: “liberation” from samsara, understood as merging into Brahman or eternal union with the deity. Islam’s salvation is not dissolution but entry into Paradise as a living, conscious person:")
                        .font(.body)
                    ScriptureQuote(quran: "3:185", words: 9...22)

                    Text(articleMarkdown: "**Dharma**: duty, right order, religion; each caste and stage of life has its own dharma. Islam’s **din (الدِّين)** is one for all, revealed and complete:")
                        .font(.body)
                    ScriptureQuote(quran: "5:3", words: 39...49)

                    Text(articleMarkdown: "**Avatar**: “descent,” a deity taking a body on earth. Vishnu is said to have ten avatars, among them Rama, the hero of the Ramayana, and Krishna, the speaker of the Bhagavad Gita. Islam denies that the Creator ever enters His creation or takes a body:")
                        .font(.body)
                    ScriptureQuote(quran: "6:101")

                    Text(articleMarkdown: "**Murti** and **puja**: the murti is the image or statue in which the deity is held to be present; puja is the worship offered to it, with flowers, food, lamps, and prostration. This is exactly what Ibrahim (peace be upon him) confronted in his own people (Quran 21:52-54), and what the Quran describes as worshipping what cannot create a fly (Quran 22:73).")
                        .font(.body)

                    Text(articleMarkdown: "**The Vedas, Upanishads, and Gita**: the four Vedas (Rig, Sama, Yajur, Atharva) are the oldest Hindu texts, the Rig Veda dating to roughly 1500-1200 BCE. The Upanishads are the later philosophical texts, and the Bhagavad Gita is Krishna’s discourse to the warrior Arjuna, a part of the epic Mahabharata. The Quran does not name them; the scriptures it names are the Tawrah, the Zabur, the Injil, the scrolls of Ibrahim and Musa (Quran 87:18-19), and itself, while it affirms that Allah sent messengers whose stories He did not relate (Quran 40:78). The Quran is the criterion over every earlier book (Quran 5:48): whatever agrees with it about the One God is truth, and whatever contradicts it is not from Allah.")
                        .font(.body)

                    Text(articleMarkdown: "**Trimurti**: the “three forms,” Brahma the creator, Vishnu the preserver, and Shiva the destroyer. The Quran answers every division of the divine work, and names Allah alone as the Creator, the Inventor, and the Fashioner (Quran 59:24, quoted in the questions below):")
                        .font(.body)
                    ScriptureQuote(quran: "23:91")

                    Text(articleMarkdown: "**Varna** and caste: the four hereditary classes, Brahmin (priests), Kshatriya (rulers and warriors), Vaishya (merchants and farmers), and Shudra (labourers), described in the Rig Veda (10:90) as born from the different limbs of the primal man, and codified in the Laws of Manu; and below them the Dalits, once called untouchables, outside the system altogether. Islam has no priestly class and no hereditary rank; nobility is by piety alone (Quran 49:13), and the Prophet (peace be upon him) said that people are all the children of Adam, and Adam was created from dust (Sunan al-Tirmidhi 3955; graded hasan by al-Albani).")
                        .font(.body)

                    Text(articleMarkdown: "**Yoga**: “yoking” or “union”; in Hindu teaching a discipline of body, breath, and mind whose goal is union with Brahman or the deity. Its physical postures are one thing; its spiritual aim is another (see the questions below).")
                        .font(.body)

                    Text(articleMarkdown: "**Guru**: the teacher, in many traditions treated as a channel of the divine and honoured with rites of devotion. Islam honours scholars but forbids making any human a lord:")
                        .font(.body)
                    ScriptureQuote(quran: "9:31")

                    Text(articleMarkdown: "**OM** and **mantra**: OM is the sacred syllable held to be the sound of Brahman itself, chanted at the start of prayers and meditation; a mantra is a formula repeated for spiritual power. The Muslim’s remembrance is of Allah by His revealed names, in words He taught:")
                        .font(.body)
                    ScriptureQuote(quran: "7:180", words: 0...4)

                    Text(articleMarkdown: "**Shirk (شِرك)**: from sharika, to share; giving any part of what belongs to Allah alone, whether worship, prayer, sacrifice, or lordship, to another. It is the one sin Allah has said He does not forgive for the one who dies upon it (Quran 4:48). Luqman told his son:")
                        .font(.body)
                    ScriptureQuote(quran: "31:13", words: 6...13)

                    Text(articleMarkdown: "**Tawhid (تَوحِيد)**: from wahhada, to make one; affirming that Allah alone is the Lord, alone deserves worship, and is alone in His names and attributes. Its clearest statement is Surat al-Ikhlas:")
                        .font(.body)
                    ScriptureQuote(quran: "112:1-4")

                    Text(articleMarkdown: "**Fitrah (فِطرَة)**: from fatara, to originate; the natural disposition on which Allah creates every human being, which knows its Maker and inclines to worship Him alone. The Hindu who looks past the images to a single supreme reality is feeling the pull of that fitrah:")
                        .font(.body)
                    ScriptureQuote(quran: "30:30")
                    ScriptureQuote(hadith: "bukhari:1385", cite: "Sahih al-Bukhari 1385", arabic: 31...41, english: 4...31)

                    Text(articleMarkdown: "**Ba‘th (بَعث)**: “raising”; the resurrection of the body from the grave for judgement, the Islamic answer to rebirth:")
                        .font(.body)
                    ScriptureQuote(quran: "22:7")
                }

                ArticleSourcesSection(article: "HinduismAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Hinduism")
        .selectableArticleList(article: "HinduismAnswerView")
    }
}

struct PaganismAnswerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: paganism, old and new, worships created things: idols, spirits, ancestors, nature, and stars. The Quran shows where idol worship came from, why the pagans' own admission that Allah is the Creator refutes them, and why nothing created deserves worship.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT IS PAGANISM?")) {
                    Text(articleMarkdown: "**Shirk (شِرك)** in its oldest form: the worship of many gods, idols carved from stone and wood, spirits of the dead, sacred trees and stones, the sun, moon, and stars, and the spirits of places. The Arabs of Makkah were pagans of this kind, with 360 idols around the Ka‘bah, and the Quran addressed them first. Modern paganism, whether tribal, “new age,“ or a revival of old European and Near Eastern cults, is the same thing with new names.")
                        .font(.body)

                    Text(verbatim: "Ibn Abbas (may Allah be pleased with him) explained how it began. The idols of the people of Nuh, Wadd, Suwa‘, Yaghuth, Ya‘uq, and Nasr, were the names of righteous men:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4920", cite: "Sahih al-Bukhari 4920", arabic: 66...91, english: 93...152)

                    Text(verbatim: "Every idol began as excess in honouring someone or something Allah created. That is why Islam guards so carefully against the veneration of graves and saints: it is the road paganism took.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. THE PAGANS ADMIT THE CREATOR")) {
                    Text(verbatim: "The pagans of Makkah did not deny Allah. They believed He created the heavens and the earth, and they turned to Him alone in the storm. Their shirk was to worship others alongside Him:")
                        .font(.body)
                    ScriptureQuote(quran: "43:87")

                    ScriptureQuote(quran: "29:65")

                    ScriptureQuote(quran: "23:84-87")

                    Text(verbatim: "So the argument of the Quran is: the One you admit created you, provides for you, and saves you at sea is the only One who deserves your worship. Anything else is created like you.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. NOTHING CREATED DESERVES WORSHIP")) {
                    ScriptureQuote(quran: "7:191-192")

                    ScriptureQuote(quran: "7:194")

                    ScriptureQuote(quran: "25:3")

                    ScriptureQuote(quran: "34:22")

                    Text(verbatim: "Ibrahim (peace be upon him) reasoned through the star, the moon, and the sun, and saw that whatever sets and vanishes cannot be a lord:")
                        .font(.body)
                    ScriptureQuote(quran: "6:79")
                }

                Section(header: ArticleHeader("3. THE INTERCESSION EXCUSE")) {
                    Text(verbatim: "Pagans in every age say the idols are only a way to reach the High God, or that the spirits carry prayers to Him. The Quran quotes the excuse and rejects it:")
                        .font(.body)
                    ScriptureQuote(quran: "10:18")

                    ScriptureQuote(quran: "12:40", words: 15...31)
                }

                Section(header: ArticleHeader("4. THE END OF THE IDOLS")) {
                    Text(verbatim: "When the Prophet (peace be upon him) entered Makkah in 8 AH, he struck the 360 idols around the Ka‘bah with his stick, reciting:")
                        .font(.body)
                    ScriptureQuote(quran: "17:81")

                    Text(verbatim: "The House built by Ibrahim for the worship of Allah alone was cleansed and has remained so (Sahih al-Bukhari 4287). And the Prophet (peace be upon him) sent Ali to leave no image without effacing it and no raised grave without levelling it (Sahih Muslim 969), closing the road by which idols return.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Were the Arabs always idolaters?**")
                        .font(.body)
                    Text(verbatim: "No. Makkah was founded on tawhid. Ibrahim and Isma‘il (peace be upon them) raised the House for the worship of Allah alone and prayed that their descendants would be Muslims and would be sent a messenger from among themselves (Quran 2:127-129):")
                        .font(.body)
                    ScriptureQuote(quran: "2:127")
                    ScriptureQuote(quran: "3:96")
                    ScriptureQuote(quran: "3:97", words: 9...17)
                    ScriptureQuote(quran: "14:35")
                    Text(verbatim: "The Arabs kept much of that religion for centuries: the Hajj, the tawaf (طَوَاف, from ط-و-ف, to go round: the circling of the Ka‘bah), the sanctity of the House and the sacred months. Idolatry came in later through ‘Amr ibn Luhayy of Khuza‘ah, whom the Prophet (peace be upon him) saw dragging his intestines in the Fire (Sahih al-Bukhari 3521, quoted below), and who, as Ibn Ishaq relates, brought Hubal from Syria and set it up at the Ka‘bah. Some hanifs, seekers of the religion of Ibrahim, still refused the idols in the Prophet’s own generation. Zayd ibn ‘Amr ibn Nufayl would not eat what was slaughtered for the idols (Sahih al-Bukhari 3826), and Asma’ bint Abi Bakr (may Allah be pleased with her) saw him standing with his back against the Ka‘bah, saying:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3828", cite: "Sahih al-Bukhari 3828", arabic: 30...39, english: 16...32)
                    Text(verbatim: "Islam did not bring a new god to the Arabs; it removed the intruders.")
                        .font(.body)

                    Text(articleMarkdown: "**Is the Ka‘bah or the Black Stone idolatry?**")
                        .font(.body)
                    Text(verbatim: "No. Muslims pray toward the Ka‘bah, not to it; it is a direction commanded by Allah, so that the whole Ummah faces one point:")
                        .font(.body)
                    ScriptureQuote(quran: "2:144", words: 9...19)
                    Text(verbatim: "The House was built by Ibrahim on the condition “do not associate anything with Me” (Quran 22:26). As for the Black Stone, the Muslims kiss it only because the Prophet (peace be upon him) did, and the Companions said so plainly. ‘Umar (may Allah be pleased with him) came to it, kissed it, and said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1597", cite: "Sahih al-Bukhari 1597, Sahih Muslim 1270", arabic: 28...46, english: 11...42)
                    Text(verbatim: "No Muslim prays to the stone, asks it for anything, or believes it hears. Idolatry is directing worship to a created thing; following a command about where to face is obedience to the Creator.")
                        .font(.body)

                    Text(articleMarkdown: "**Are shrines, relics, and saints’ tombs paganism?**")
                        .font(.body)
                    Text(verbatim: "Praying to the dead, asking them for children or cures, vowing and sacrificing at their graves, and circling their shrines is the same shirk as the idols of Nuh’s people, which began as the honouring of righteous men (Quran 71:23). The Prophet (peace be upon him) warned against the first step on that road even on his deathbed:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:435", cite: "Sahih al-Bukhari 435, Sahih Muslim 531", arabic: 48...56, english: 37...56)
                    ScriptureQuote(hadith: "muslim:532", cite: "Sahih Muslim 532", arabic: 91...110, english: 65...100)
                    Text(verbatim: "He sent ‘Ali to level every raised grave (Sahih Muslim 969), and he forbade plastering graves, sitting on them, and building over them (Sahih Muslim 970). Visiting graves to remember death and to pray for the dead is Sunnah; building shrines over them and praying to their occupants is the very thing the Prophet (peace be upon him) cursed. Ibn al-Qayyim (may Allah have mercy on him) devoted a long section of Ighathat al-Lahfan to showing how the veneration of graves turns into the worship of their occupants.")
                        .font(.body)

                    Text(articleMarkdown: "**Are astrology, fortune-telling, and magic shirk?**")
                        .font(.body)
                    Text(verbatim: "Astrology is a branch of magic (Sunan Abi Dawud 3905) and attributing rain to a star is disbelief in Allah (Sahih al-Bukhari 846), both quoted below. Asking a fortune-teller voids the prayer of forty nights (Sahih Muslim 2230), and believing him is worse; the Prophet (peace be upon him) said that whoever goes to a kahin (كَاهِن, a soothsayer who claims to know the unseen) and believes what he says has nothing to do with what was sent down to Muhammad (Sunan Abi Dawud 3904; graded sahih by al-Albani). Where do the kahins get the occasional truth that impresses their clients? Aishah (may Allah be pleased with her) asked exactly that:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2228a", cite: "Sahih Muslim 2228", arabic: 36...48, english: 23...51)
                    ScriptureQuote(hadith: "bukhari:3210", cite: "Sahih al-Bukhari 3210", arabic: 45...72, english: 6...48)
                    Text(verbatim: "Magic is the second of the seven destroyers (Sahih al-Bukhari 2766), and the Quran says of those who buy it that they have no share in the Hereafter (Quran 2:102). Its practice involves serving devils, and that is shirk.")
                        .font(.body)

                    Text(articleMarkdown: "**Are omens and superstitions shirk?**")
                        .font(.body)
                    Text(articleMarkdown: "Omens (**tiyarah (طِيَرَة)**, from ط-ي-ر, a bird, because the Arabs would startle a bird and take its direction of flight as a sign) are shirk by the Prophet’s own words (Sunan Abi Dawud 3910, quoted below), because they attach harm and benefit to something Allah gave no power. Black cats, broken mirrors, unlucky numbers and days, and “touch wood” all fall under it. Islam replaces the omen with the good word:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:5776", cite: "Sahih al-Bukhari 5776", arabic: 29...42, english: 4...22)
                    Text(verbatim: "Even swearing by something other than Allah, as pagans swore by their idols and ancestors, was forbidden as a form of shirk:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:1535", cite: "Sunan al-Tirmidhi 1535; graded sahih by al-Albani", arabic: 41...48, english: 31...42)
                    Text(verbatim: "The cure the Prophet (peace be upon him) gave is tawakkul, reliance on Allah, which drives the omen out of the heart.")
                        .font(.body)

                    Text(articleMarkdown: "**Is it shirk to seek blessing from a tree, a stone, or a place?**")
                        .font(.body)
                    Text(verbatim: "Yes, if one believes the thing itself gives blessing. On a campaign the Prophet (peace be upon him) passed a tree of the pagans called Dhat Anwat, on which they used to hang their weapons, and some of those with him asked for one like it:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:2180", cite: "Sunan al-Tirmidhi 2180; graded sahih by al-Albani", arabic: 40...82, english: 0...55)
                    Text(verbatim: "Blessing (barakah) belongs to Allah, who places it where He wills: in the Quran, in Zamzam, in the sacred places He named. It is not sought from a tree, a wall, a saint’s cloth, or a stone.")
                        .font(.body)

                    Text(articleMarkdown: "**What of nature, “Mother Earth,” the sun and the moon?**")
                        .font(.body)
                    Text(verbatim: "They are creatures and signs. The sun, moon, mountains, and trees prostrate to Allah (Quran 22:18, quoted below); to prostrate to them is to worship a fellow servant, and Allah forbade it in so many words:")
                        .font(.body)
                    ScriptureQuote(quran: "41:37", words: 6...14)
                    Text(verbatim: "Ibrahim (peace be upon him) reasoned from the setting of the star, the moon, and the sun that what vanishes cannot be a lord (Quran 6:76-79). The Quran invites us to look at nature and see the One behind it:")
                        .font(.body)
                    ScriptureQuote(quran: "2:164")
                    ScriptureQuote(quran: "10:31")
                    Text(verbatim: "Caring for the earth is a duty in Islam; the Prophet (peace be upon him) said that no Muslim plants a tree or sows a crop from which a bird, a person, or an animal eats but that it is counted as charity for him (Sahih al-Bukhari 2320, Sahih Muslim 1553). But the earth is Allah’s creation and our trust, not our mother or our goddess.")
                        .font(.body)

                    Text(articleMarkdown: "**Did Islam keep pagan rites?**")
                        .font(.body)
                    Text(verbatim: "No. Hajj, tawaf, the sacrifice, and the sanctity of the House are older than paganism in Arabia; they are the rites of Ibrahim, whom Allah commanded:")
                        .font(.body)
                    ScriptureQuote(quran: "22:27")
                    ScriptureQuote(quran: "2:125", words: 11...21)
                    Text(verbatim: "The pagans had corrupted these rites with naked tawaf, whistling and clapping at the House, a partner in the talbiyah (see the key terms above), and tribal privileges. Quraysh, calling themselves al-Hums, would not stand at Arafat with the other Arabs:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4520", cite: "Sahih al-Bukhari 4520", arabic: 20...53, english: 0...51)
                    Text(verbatim: "Islam stripped every one of these away and restored the rite of Ibrahim. In the year before the Farewell Hajj Abu Bakr had it proclaimed:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1622", cite: "Sahih al-Bukhari 1622", arabic: 53...62, english: 43...64)
                    Text(verbatim: "And in the Farewell Hajj itself, standing at Arafat, the Prophet (peace be upon him) declared:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:1218a", cite: "Sahih Muslim 1218", arabic: 797...808, english: 1306...1329)
                    Text(verbatim: "A rite is pagan by what it is offered to, not by its age. Prostration, fasting, and pilgrimage existed among idolaters too; offered to Allah alone, on His command, they are worship.")
                        .font(.body)

                    Text(articleMarkdown: "**What were al-Lat, al-‘Uzza, and Manat, and what became of them?**")
                        .font(.body)
                    Text(verbatim: "Al-Lat was a white stone at Ta’if, the idol of Thaqif, with a house built over it; al-‘Uzza was a group of trees with a shrine at Nakhlah, the most venerated idol of Quraysh; Manat was a stone at Qudayd on the coast road to Madinah, venerated by the Aws and Khazraj. The Quran named them and stripped them of everything but their names (Quran 53:19-23, quoted below). After the conquest of Makkah in 8 AH the Prophet (peace be upon him) sent Khalid ibn al-Walid to al-‘Uzza, and he destroyed it and its shrine, and he sent Sa‘d ibn Zayd al-Ashhali to Manat; al-Lat was demolished when Thaqif accepted Islam in 9 AH, by al-Mughirah ibn Shu‘bah and Abu Sufyan (Ibn Hisham, as-Sirah an-Nabawiyyah; Ibn Kathir, al-Bidayah wan-Nihayah). He also sent Jarir ibn Abdullah to the idol-house of Khath‘am in the south:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3020", cite: "Sahih al-Bukhari 3020", arabic: 25...37, english: 6...27)
                    Text(verbatim: "Jarir went with a hundred and fifty horsemen, tore it down, and burned it. Within two years of the conquest not one of the great idols of Arabia was standing.")
                        .font(.body)

                    Text(articleMarkdown: "**Is asking the jinn or spirits shirk?**")
                        .font(.body)
                    Text(verbatim: "Yes. Seeking refuge with the jinn, asking them for knowledge or help, and making pacts with them was the paganism of the old Arabs (Quran 72:6, quoted below), and the jinn and the angels will disown their worshippers on the Day of Judgement (Quran 34:41). Allah describes the reckoning:")
                        .font(.body)
                    ScriptureQuote(quran: "6:128", words: 3...16)
                    ScriptureQuote(quran: "6:100")
                    Text(verbatim: "Spirit-guides, séances, channelling, and “communicating with the departed” are the same thing in modern dress. The one who answers is a jinn, and the price is the servant’s religion. Refuge is sought from the jinn, in Allah, not with the jinn.")
                        .font(.body)

                    Text(articleMarkdown: "**Are crystals, energy healing, and “manifesting” paganism?**")
                        .font(.body)
                    Text(verbatim: "To believe that a stone heals by its own energy, that a ritual draws “abundance” from “the universe,” or that one’s intention bends the cosmos is to attribute Allah’s acts to His creation. It is the intercession excuse in new words (Quran 39:3) and the calling on what cannot answer (Quran 10:106; 7:194):")
                        .font(.body)
                    ScriptureQuote(quran: "13:14")
                    ScriptureQuote(quran: "16:53")
                    Text(verbatim: "Islam has its own healing: medicine, which the Prophet (peace be upon him) commanded, and ruqyah with the Quran and the supplications he taught. When the Companions asked him about the incantations they had used in Jahiliyyah (جَاهِلِيَّة, from ج-ه-ل, ignorance: the age before Islam), he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2200", cite: "Sahih Muslim 2200", arabic: 38...48, english: 10...32)
                    Text(verbatim: "And the one who wants provision is told where it comes from:")
                        .font(.body)
                    ScriptureQuote(quran: "65:3", words: 5...10)
                }

                Section(header: ArticleHeader("THE INVITATION")) {
                    ScriptureQuote(quran: "43:26-27")

                    ScriptureQuote(quran: "109:1-6")

                    Text(verbatim: "Allah is nearer than any idol, hears without any intermediary, and forgives the one who turns to Him. The pagan is invited to worship the One he already knows made him.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Paganism is the worship of created things, born of excess in honouring the dead and the beautiful. The pagans themselves admit that Allah created them, and that admission is the proof that He alone should be worshipped.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Paganism / wathaniyyah (الوَثَنِيَّة)**: from **wathan (وَثَن)**, an idol; the scholars of language say a wathan is anything set up to be worshipped, of stone or otherwise, while a **sanam (صَنَم)** is an image carved in a form. The Quran uses both words for what Ibrahim (peace be upon him) rejected:")
                        .font(.body)
                    ScriptureQuote(quran: "22:30", words: 17...23)
                    ScriptureQuote(quran: "29:17", words: 0...24)

                    Text(articleMarkdown: "**Shirk (شِرك)**: from sharika, to share; giving to another any of what belongs to Allah alone: worship, prayer, sacrifice, vows, fear, hope, or lordship. It is the essence of every paganism and the one sin not forgiven for the one who dies upon it (Quran 4:48):")
                        .font(.body)
                    ScriptureQuote(quran: "22:31", words: 5...20)

                    Text(articleMarkdown: "**Taghut (طَاغُوت)**: from tagha, to exceed all bounds; Ibn al-Qayyim (may Allah have mercy on him) defined it as anything by which a servant exceeds his limit, whether something worshipped, followed, or obeyed in place of Allah (I‘lam al-Muwaqqi‘in). Every idol set up to be served in Allah’s place, and every devil who calls people to it, is a taghut; the righteous man venerated without his consent is not one, and he will disown those who worshipped him on the Day of Judgement. Rejecting the taghut is the first half of faith:")
                        .font(.body)
                    ScriptureQuote(quran: "2:256", words: 9...20)
                    ScriptureQuote(quran: "39:17", words: 0...9)

                    Text(articleMarkdown: "**Jahiliyyah (جَاهِلِيَّة)**: “the age of ignorance,” the state of the Arabs before revelation: idols, blood feuds, burying daughters, usury, boasting of lineage, and omens. The Quran uses the word for the traits themselves, in the zeal of the disbelievers and even in the thoughts and display it warns the believers against (Quran 48:26; 3:154; 33:33); the Prophet (peace be upon him) told Abu Dharr, when he insulted a man by his mother, that he was a man in whom there was still jahiliyyah (Sahih al-Bukhari 30). Allah asks:")
                        .font(.body)
                    ScriptureQuote(quran: "5:50")

                    Text(articleMarkdown: "**Hubal, al-Lat, al-‘Uzza, and Manat**: the chief idols of the Arabs. Hubal stood at the Ka‘bah itself and was the idol of Quraysh; at Uhud Abu Sufyan, still a pagan, cried out in its name, and the Prophet (peace be upon him) had the Muslims answer him:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4043", cite: "Sahih al-Bukhari 4043", arabic: 141...163, english: 248...281)
                    Text(verbatim: "Al-Lat was the idol of Thaqif at Ta’if; al-‘Uzza, the most honoured by Quraysh, was at Nakhlah on the road to Ta’if; and Manat stood at Qudayd by the sea, venerated by the Aws and Khazraj. The Quran named all three and mocked the claim that they were “daughters of Allah” while the pagans themselves wanted only sons:")
                        .font(.body)
                    ScriptureQuote(quran: "53:19-23")
                    Text(verbatim: "All of them were destroyed in the eighth and ninth years after the Hijrah (see the questions below).")
                        .font(.body)

                    Text(articleMarkdown: "**‘Amr ibn Luhayy**: the chief of Khuza‘ah who, generations before the Prophet (peace be upon him), brought idol worship into the pure religion of Ibrahim and Isma‘il at Makkah. Ibn Ishaq relates, in the Sirah of Ibn Hisham, that he was the first to change the religion of Isma‘il: he brought the idol Hubal from Syria, set it up for the people to worship, and instituted the sacred animals that were dedicated to the gods. The Prophet (peace be upon him) saw his punishment:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3521", cite: "Sahih al-Bukhari 3521, Sahih Muslim 2856", arabic: 44...59, english: 57...90)

                    Text(articleMarkdown: "**The idols of the people of Nuh**: Wadd, Suwa‘, Yaghuth, Ya‘uq, and Nasr (Quran 71:23), which Ibn Abbas (may Allah be pleased with him) explained were the names of righteous men whose statues were later worshipped (Sahih al-Bukhari 4920, quoted above). Ibn Taymiyyah (may Allah have mercy on him) drew from this the rule that shirk first entered mankind through excessive veneration of the righteous and their graves (Iqtida’ as-Sirat al-Mustaqim).")
                        .font(.body)

                    Text(articleMarkdown: "**Tiyarah (طِيَرَة)**: from tayr, a bird; taking omens, originally from the flight of birds, then from any sign, day, number, or event. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:3910", cite: "Sunan Abi Dawud 3910; graded sahih by al-Albani", arabic: 32...35, english: 4...16)
                    Text(verbatim: "The narrator, Ibn Mas‘ud (may Allah be pleased with him), added that there is none of us but that something of it touches him, but Allah removes it by reliance on Him. The Prophet (peace be upon him) also said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:5757", cite: "Sahih al-Bukhari 5757", arabic: 31...38, english: 4...13)
                    Text(verbatim: "That is: no disease spreads by itself without Allah’s decree, no bird-omen, no owl of the dead calling from a grave, and no ill luck in the month of Safar.")
                        .font(.body)

                    Text(articleMarkdown: "**Kahin (كَاهِن)**: a fortune-teller or soothsayer who claims knowledge of the unseen, in the old Arabia by contact with a jinn. The Quran closes that door:")
                        .font(.body)
                    ScriptureQuote(quran: "27:65", words: 0...9)
                    ScriptureQuote(hadith: "muslim:2230", cite: "Sahih Muslim 2230", arabic: 36...47, english: 0...20)

                    Text(articleMarkdown: "**Sihr (سِحر)**: magic; spells, knots, and the summoning of devils to harm, bind, or separate. The Quran traces it to the devils in the days of Sulayman, who taught people “that by which they cause separation between a man and his wife” (Quran 2:102), and Surat al-Falaq seeks refuge from “the blowers in knots” (Quran 113:4). The Prophet (peace be upon him) counted it second only to shirk among the destroyers:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:2766", cite: "Sahih al-Bukhari 2766", arabic: 35...68, english: 4...93)

                    Text(articleMarkdown: "**Tanjim (تَنجِيم)**: from najm, a star; astrology, reading fates and fortunes in the heavens. Astronomy, the study of the stars for calendars, direction, and knowledge, is praised in the Quran; astrology is a branch of magic:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:3905", cite: "Sunan Abi Dawud 3905; graded hasan by al-Albani", arabic: 40...51, english: 4...29)
                    ScriptureQuote(hadith: "bukhari:846", cite: "Sahih al-Bukhari 846", arabic: 82...92, english: 90...109)

                    Text(articleMarkdown: "**Nature worship and animism**: worship of the sun, moon, stars, rivers, mountains, trees, and the spirits held to live in them, from the Egyptians and Babylonians to modern “Mother Earth” cults. The Quran presents all of nature as itself a worshipper, never a god:")
                        .font(.body)
                    ScriptureQuote(quran: "22:18", words: 0...20)

                    Text(articleMarkdown: "**Ancestor worship**: offerings, prayers, and vows to the spirits of the dead, found in the old Roman, Chinese, and African religions and in modern “veneration” of the departed. The Quran shows the dead, the angels, and the righteous disowning such worship on the Day of Judgement:")
                        .font(.body)
                    ScriptureQuote(quran: "34:40-41")
                    ScriptureQuote(quran: "72:6")

                    Text(articleMarkdown: "**Hajj and Tawaf**: the rites Allah gave to Ibrahim (peace be upon him) at the House he built for the worship of Allah alone:")
                        .font(.body)
                    ScriptureQuote(quran: "22:26")
                    Text(verbatim: "Allah then commanded Ibrahim to proclaim the Hajj, and described its sacrifice, its feeding of the poor, and its tawaf around the ancient House (Quran 22:27-29). The pagans kept the rites but corrupted them: they filled the House with idols, performed tawaf naked, and added a partner to the talbiyah. Ibn Abbas (may Allah be pleased with him) reported:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:3028", cite: "Sahih Muslim 3028", arabic: 37...49, english: 0...31)
                    ScriptureQuote(hadith: "muslim:1185", cite: "Sahih Muslim 1185", arabic: 30...67, english: 0...52)
                    ScriptureQuote(quran: "8:35")

                    Text(articleMarkdown: "**Modern paganism**: neo-paganism and Wicca, which revive the old gods and goddesses and “the Goddess”; crystals and stones believed to carry healing energy; “manifesting,” in which one asks “the universe” for what one wants; and astrology, tarot, and spirit-guides. These are the old shirk in new words: calling on what cannot hear, and attributing giving and healing to what has no power:")
                        .font(.body)
                    ScriptureQuote(quran: "10:106")
                    ScriptureQuote(quran: "46:5")
                }

                ArticleSourcesSection(article: "PaganismAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Paganism")
        .selectableArticleList(article: "PaganismAnswerView")
    }
}

struct BuddhismAnswerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Buddhism seeks escape from suffering through detachment and rebirth, without a Creator. The Quran answers that the world has a purpose and a Maker, that suffering is a test with meaning, that the self is real and accountable, and that salvation is by Allah's mercy, not by extinguishing desire.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT BUDDHISM TEACHES")) {
                    Text(articleMarkdown: "Buddhism follows Siddhartha Gautama, the Buddha (“the awakened one“), who lived in northern India around the fifth century BCE. Its core is the Four Noble Truths: there is suffering, and all conditioned existence is marked by it (**dukkha**), suffering comes from craving, it ends by ending craving, and the way is the Eightfold Path of ethics, meditation, and wisdom. It teaches **karma** and rebirth, denies a permanent self (**anatta**), and aims at **nirvana**, the extinction of craving and of rebirth. It has no Creator God; the Buddha did not teach one. In practice most Buddhists bow to and make offerings before images of the Buddha and of bodhisattvas, and some schools venerate many celestial beings.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. THE WORLD HAS A MAKER AND A PURPOSE")) {
                    Text(verbatim: "A path that begins with suffering but never asks who made the sufferer has left out the first question. The Quran puts it directly:")
                        .font(.body)
                    ScriptureQuote(quran: "52:35-36")

                    ScriptureQuote(quran: "44:38-39")

                    ScriptureQuote(quran: "23:115")

                    Text(verbatim: "Suffering is not the nature of existence; it is a test set by a Creator who made both death and life for a purpose:")
                        .font(.body)
                    ScriptureQuote(quran: "67:2")
                }

                Section(header: ArticleHeader("2. SUFFERING HAS MEANING")) {
                    Text(verbatim: "Islam does not deny suffering; it gives it a reason and an end. It purifies, it is answered by patience, and it is followed by ease:")
                        .font(.body)
                    ScriptureQuote(quran: "2:155-157")

                    ScriptureQuote(quran: "94:5-6")

                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:5641", cite: "Sahih al-Bukhari 5641", arabic: 40...63, english: 4...39)

                    ScriptureQuote(hadith: "muslim:2999", cite: "Sahih Muslim 2999", arabic: 39...64, english: 0...73)

                    Text(verbatim: "The answer to craving is not to extinguish the self but to direct it: to want Allah and the Hereafter more than the world. The Buddha sought to escape the cycle; the believer is not in a cycle, but on a single road to his Lord.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. THE SOUL IS REAL AND RETURNS ONCE")) {
                    Text(verbatim: "Buddhism denies a lasting self, yet speaks of rebirth; what, then, is reborn? The Quran affirms the soul as real, created, and known to its Maker, and affirms one death and one resurrection:")
                        .font(.body)
                    ScriptureQuote(quran: "17:85")

                    ScriptureQuote(quran: "39:42")

                    ScriptureQuote(quran: "23:99-100")

                    Text(verbatim: "Justice is real too, and exact, but it is the justice of a Judge who knows every deed, not an impersonal karma that punishes a person for a past he cannot recall.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. THE MIDDLE WAY IS THE SUNNAH")) {
                    Text(verbatim: "The Buddha left extreme asceticism for a “middle way,“ yet his path still turned monks from marriage, property, and the world. Islam’s middle way is fuller: enjoy what Allah made lawful, in moderation, and worship Him in the midst of life:")
                        .font(.body)
                    ScriptureQuote(quran: "7:32", words: 0...10)

                    ScriptureQuote(quran: "25:67")

                    ScriptureQuote(hadith: "bukhari:5063", cite: "Sahih al-Bukhari 5063", arabic: 119...124, english: 143...161)

                    Text(verbatim: "And the goal is not the extinction of the self but its fulfilment: a soul at peace, returning to its Lord, in a Paradise where craving is satisfied, not destroyed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("5. SALVATION IS BY MERCY, NOT BY SELF-EFFORT ALONE")) {
                    Text(verbatim: "Buddhism has no one to turn to; each person must work out his own release. Islam says the effort is required, but the end is a gift:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:5673", cite: "Sahih al-Bukhari 5673, Sahih Muslim 2816", arabic: 29...51, english: 6...52)

                    ScriptureQuote(hadith: "muslim:2664", cite: "Sahih Muslim 2664", arabic: 39...58, english: 0...40)

                    Text(verbatim: "As for the statues and offerings, the Buddha himself, by the Buddhist account, said that he is truly honoured by following his teaching (Mahaparinibbana Sutta, DN 16); and the worship of images is the shirk every prophet forbade (Quran 21:52-54).")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Was the Buddha a prophet?**")
                        .font(.body)
                    Text(verbatim: "We do not know. Allah sent messengers whose stories He did not tell us:")
                        .font(.body)
                    ScriptureQuote(quran: "4:164", words: 0...9)
                    ScriptureQuote(quran: "16:36", words: 0...10)
                    Text(verbatim: "So a messenger may well have been sent to the people of the Ganges plain. But every messenger taught one thing above all:")
                        .font(.body)
                    ScriptureQuote(quran: "21:25")
                    Text(verbatim: "The Buddhism that has come down to us teaches no Creator and directs no worship to Him. So either the Buddha’s teaching was changed after him, as the teaching of Isa (peace be upon him) was changed, or he was not a messenger of Allah. We do not affirm his prophethood, and we do not insult him; we say what we know and stop at what we do not (Quran 40:78).")
                        .font(.body)

                    Text(articleMarkdown: "**Does Buddhism have a God?**")
                        .font(.body)
                    Text(verbatim: "Classical Buddhism has none; it speaks of gods (devas) as beings within the cycle, but of no Creator. The Quran’s answer is the question it puts to every denier: were you created by nothing, or did you create yourselves, or did you create the heavens and the earth? (Quran 52:35-36, quoted above.) The messengers put the same question to their peoples:")
                        .font(.body)
                    ScriptureQuote(quran: "14:10", words: 1...17)
                    Text(verbatim: "Tellingly, Buddhists in practice do bow, make offerings, and ask for help, before the Buddha, before the bodhisattvas, and before local spirits. A religion without a God has not kept its followers from worshipping, because the fitrah demands an object:")
                        .font(.body)
                    ScriptureQuote(quran: "30:30")

                    Text(articleMarkdown: "**Is meditation allowed?**")
                        .font(.body)
                    Text(verbatim: "Reflection and remembrance are commanded. The believers are those who “give thought to the creation of the heavens and the earth” (Quran 3:191, quoted below), and Allah asks:")
                        .font(.body)
                    ScriptureQuote(quran: "30:8", words: 0...14)
                    Text(verbatim: "The heart finds its rest in dhikr (ذِكر, the remembrance of Allah) (Quran 13:28), and the Prophet (peace be upon him) himself withdrew to reflect and worship before revelation came. Aishah (may Allah be pleased with her) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3", cite: "Sahih al-Bukhari 3", arabic: 47...68, english: 24...61)
                    Text(verbatim: "What is not allowed is Buddhist meditation as such: chanting mantras, visualising Buddhas, emptying the self to realise “no-self,” or sitting before a statue in a posture of devotion. Islamic reflection has an object, Allah and His signs; it fills the heart rather than emptying it. The prayer itself, with its stillness, its recitation, and its prostration, is the Muslim’s daily discipline of the mind, and the Sunnah retreat (i‘tikaf) in the mosque is his seclusion.")
                        .font(.body)

                    Text(articleMarkdown: "**Is Islam against desire and pleasure?**")
                        .font(.body)
                    Text(verbatim: "No. Allah rebukes those who forbid His adornment and good provision (Quran 7:32, quoted above), and commands:")
                        .font(.body)
                    ScriptureQuote(quran: "5:87-88")
                    ScriptureQuote(quran: "28:77", words: 0...15)
                    Text(verbatim: "The believer’s prayer asks for both worlds:")
                        .font(.body)
                    ScriptureQuote(quran: "2:201", words: 3...13)
                    Text(verbatim: "When Abu ad-Darda’ fasted every day and prayed every night, his brother Salman (may Allah be pleased with them) made him eat and sleep and told him that his Lord, his own self, and his family each had a right over him; the Prophet (peace be upon him) said: “Salman has spoken the truth” (Sahih al-Bukhari 1968). He refused the three men who vowed perpetual fasting, all-night prayer, and celibacy: whoever turns away from my Sunnah is not of me (Sahih al-Bukhari 5063, quoted above). Desire is not the enemy; disobedience is. Pleasure within Allah’s limits is His gift, and gratitude for it is worship.")
                        .font(.body)

                    Text(articleMarkdown: "**Karma or qadar?**")
                        .font(.body)
                    Text(articleMarkdown: "**Qadar (قَدَر)**, from ق-د-ر, to measure out, is Allah’s decree: His knowledge, His writing, His will, and His creating of all that is. Both qadar and karma say deeds have consequences. The difference is who keeps the account. In Islam it is a Lord who sees:")
                        .font(.body)
                    ScriptureQuote(quran: "99:7-8")
                    ScriptureQuote(quran: "4:40")
                    ScriptureQuote(quran: "6:164", words: 9...19)
                    Text(verbatim: "Karma has no mercy and no one to ask for it. Allah has both:")
                        .font(.body)
                    ScriptureQuote(quran: "39:53")
                    Text(verbatim: "And in a hadith qudsi Allah says:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2577a", cite: "Sahih Muslim 2577", arabic: 88...100, english: 94...118)
                    Text(verbatim: "Qadar also answers the child born blind or poor, for whom karma has only the verdict of a past life: he has done nothing wrong, his trial is measured with mercy, and his patience will be rewarded without account (Quran 39:10).")
                        .font(.body)

                    Text(articleMarkdown: "**Rebirth or resurrection?**")
                        .font(.body)
                    Text(verbatim: "Resurrection. There is no return to this world (Quran 23:99-100, quoted above). What returns is the same person, raised from the dead by the One who made him the first time:")
                        .font(.body)
                    ScriptureQuote(quran: "21:104", words: 6...15)
                    ScriptureQuote(quran: "2:28")
                    ScriptureQuote(quran: "19:67")
                    Text(verbatim: "Buddhism itself struggles to say what is reborn if there is no self. Islam has no such puzzle: the soul is one, it lives once, and it will stand once before its Lord.")
                        .font(.body)

                    Text(articleMarkdown: "**Is nirvana the same as Paradise?**")
                        .font(.body)
                    Text(verbatim: "No. Nirvana is named after the going-out of a flame: the end of craving and of rebirth. Buddhists deny that it is simple annihilation and mostly decline to describe it at all; what is not claimed for it is a person living with his Lord, for there is no Lord in it. Paradise is a place, eternal, embodied, personal, and full of delight:")
                        .font(.body)
                    ScriptureQuote(quran: "41:31", words: 7...15)
                    ScriptureQuote(quran: "50:35")
                    ScriptureQuote(quran: "32:17")
                    Text(verbatim: "The Prophet (peace be upon him) said that Allah says:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3244", cite: "Sahih al-Bukhari 3244, Sahih Muslim 2824", arabic: 28...42, english: 6...32)
                    Text(verbatim: "The greatest of its joys is the one Buddhism cannot offer at all: seeing the Face of the Lord (Quran 75:22-23). Islam does not ask a man to stop wanting; it promises him what he wants, and better.")
                        .font(.body)

                    Text(articleMarkdown: "**Should Muslims be vegetarian?**")
                        .font(.body)
                    Text(verbatim: "No, though a Muslim may eat little meat if he likes. Allah made animals lawful and said so (Quran 5:87-88, above):")
                        .font(.body)
                    ScriptureQuote(quran: "16:5")
                    ScriptureQuote(quran: "22:36")
                    Text(verbatim: "The Prophet (peace be upon him) ate meat, sacrificed animals, and sacrificed cows on behalf of his wives at Hajj (Sahih al-Bukhari 1709). To forbid what Allah allowed is itself a sin. But Islam commands mercy to animals more strictly than any vegetarian creed:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3318", cite: "Sahih al-Bukhari 3318", arabic: 31...44, english: 4...33)
                    ScriptureQuote(hadith: "muslim:1955a", cite: "Sahih Muslim 1955", arabic: 36...55, english: 12...52)
                    Text(verbatim: "And a man was forgiven his sins for giving water to a thirsty dog; when the Companions asked whether there was reward in serving animals, the Prophet (peace be upon him) said there is a reward for serving any living creature (Sahih al-Bukhari 2363, Sahih Muslim 2244). The animals are communities like us (Quran 6:38); we are permitted to eat them, and forbidden to torment them.")
                        .font(.body)

                    Text(articleMarkdown: "**Is Buddhist compassion the same as Islamic mercy?**")
                        .font(.body)
                    Text(verbatim: "They meet in practice and differ in root. Buddhist compassion (karuna) is a cultivated state of mind; Islamic mercy (rahmah) is an attribute of Allah, ar-Rahman, which He shares with His creatures and commands from them. The Prophet (peace be upon him) was sent as “a mercy to the worlds” (Quran 21:107), and he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2319a", cite: "Sahih Muslim 2319, Sahih al-Bukhari 7376", arabic: 69...77, english: 8...26)
                    ScriptureQuote(hadith: "abudawud:4941", cite: "Sunan Abi Dawud 4941; graded sahih by al-Albani", arabic: 37...46, english: 4...35)
                    ScriptureQuote(hadith: "muslim:2752c", cite: "Sahih Muslim 2752", arabic: 26...57, english: 0...80)
                    Text(verbatim: "Islamic mercy is also joined to justice: it feeds the poor by law (zakah), protects the weak by law, and punishes the oppressor. A mercy that has no Judge behind it is only a feeling; the mercy of Islam is a command, a promise, and a Name.")
                        .font(.body)

                    Text(articleMarkdown: "**Is monasticism praiseworthy?**")
                        .font(.body)
                    Text(verbatim: "No. Allah called it something people invented and then failed to keep (Quran 57:27, quoted below), and the Prophet (peace be upon him) said that whoever turns away from his Sunnah of marrying, sleeping, and eating is not of him (Sahih al-Bukhari 5063, quoted below). Sa‘d ibn Abi Waqqas (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:5073", cite: "Sahih al-Bukhari 5073", arabic: 22...37, english: 0...25)
                    Text(verbatim: "The Muslim’s asceticism (zuhd) is in the heart, not in the abandonment of duties: he marries, earns, raises children, serves his neighbours, and fights injustice, and in the midst of all that he keeps his heart for Allah and seeks the Hereafter without forgetting his share of the world (Quran 28:77, above). The Companions were traders, farmers, soldiers, and fathers, and they were the best of this Ummah.")
                        .font(.body)

                    Text(articleMarkdown: "**Is the self (nafs) an illusion?**")
                        .font(.body)
                    Text(verbatim: "No. The soul is real, though its nature is known only to its Maker (Quran 17:85, quoted above). Allah swears by it:")
                        .font(.body)
                    ScriptureQuote(quran: "91:7-10")
                    Text(verbatim: "It is the self that will testify on the Day of Judgement:")
                        .font(.body)
                    ScriptureQuote(quran: "75:14")
                    Text(verbatim: "And it is the self, purified, that is welcomed home:")
                        .font(.body)
                    ScriptureQuote(quran: "89:27-28")
                    Text(verbatim: "If there were no self there would be no one to suffer, no one to be liberated, and no one to be reborn; Buddhists have long debated how to answer that, and the doctrine of no-self sits uneasily with the Four Noble Truths it was meant to serve. Islam says: you are real, your Lord is real, and the road between you is real. Purify the self; do not deny it.")
                        .font(.body)

                    Text(articleMarkdown: "**Are the Buddhist precepts like Islamic law?**")
                        .font(.body)
                    Text(verbatim: "The five precepts for laypeople, not to kill, steal, commit sexual misconduct, lie, or take intoxicants, are all commanded in Islam:")
                        .font(.body)
                    ScriptureQuote(quran: "6:151")
                    ScriptureQuote(quran: "5:90")
                    Text(verbatim: "Notice that the Quran’s list begins with the one precept Buddhism lacks: do not associate anything with Allah. Right conduct is agreed; the question is whom one is right before. A law without a Lawgiver is advice, and Islam gives the moral sense that every sound heart shares its source and its Judge.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE INVITATION")) {
                    Text(verbatim: "Islam agrees with the Buddhist that craving for the world enslaves, that compassion is a duty, and that the mind must be disciplined. It adds what he lacks: the One who made him, the reason he suffers, the soul that will meet its Lord, and a mercy to hope in.")
                        .font(.body)
                    ScriptureQuote(quran: "36:60-61")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Buddhism describes suffering and denies the Creator; Islam names the Creator and gives suffering its meaning. There is one life, one soul, one Judge, and one road: worship Allah, be patient, and hope for His mercy.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Buddha**: Sanskrit for “the awakened one,” a title, not a name. It was taken by Siddhartha Gautama, a prince of the Shakya clan born at Lumbini at the foot of the Himalayas, who lived in northern India around the fifth century BCE (the traditional and the modern datings differ by some decades), left his palace and family in search of the end of suffering, and taught for the rest of his life. Buddhists hold that there were Buddhas before him and will be after him. Islam does not know whether any messenger of Allah was sent to that land in that age (Quran 40:78; see the questions below).")
                        .font(.body)

                    Text(articleMarkdown: "**Dharma (Pali: dhamma)**: “the teaching,” the Buddha’s doctrine, and also the law of things. With **sangha**, the community of monks and nuns, and the Buddha himself, it forms the “three jewels” in which a Buddhist “takes refuge.” The Muslim takes refuge in Allah alone, and his religion is what Allah revealed, not what a man discovered.")
                        .font(.body)

                    Text(articleMarkdown: "**The Four Noble Truths**: that there is suffering (dukkha) in all conditioned existence; that suffering arises from craving (tanha); that it ceases when craving ceases; and that the way to that cessation is the Eightfold Path. **The Eightfold Path**: right view, right intention, right speech, right action, right livelihood, right effort, right mindfulness, and right concentration. Much of this is sound conduct that Islam also commands; what is missing is the One who commands it and the One to whom the path leads.")
                        .font(.body)

                    Text(articleMarkdown: "**Dukkha**: suffering, unsatisfactoriness, the ache of existence. The Quran does not deny it:")
                        .font(.body)
                    ScriptureQuote(quran: "90:4")
                    ScriptureQuote(quran: "84:6")
                    Text(verbatim: "But it names its Author and its purpose: a test set by a merciful Creator, ending in a meeting with Him (Quran 67:2, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Tanha**: craving or thirst, the root of suffering in Buddhist teaching. Islam does not command the extinction of desire but its direction: the believer desires Allah, His pleasure, and Paradise more than the world, and enjoys the world within His limits (Quran 7:32, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Anatta**: “no-self”; the teaching that there is no permanent soul, only a passing bundle of processes. **Anicca**: impermanence, the passing of all things. Islam affirms the second and denies the first: everything created passes, but the soul is real, created, accountable, and will return to its Lord (Quran 17:85; see the questions below).")
                        .font(.body)

                    Text(articleMarkdown: "**Karma** and **rebirth**: deeds shaping the next existence, in an endless cycle across human, animal, and celestial births, until release. Islam teaches one life, one death, one resurrection, and one judgement by a Lord who knows, not by an impersonal law (Quran 23:99-100, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Nirvana**: literally “blowing out,” as of a flame; the extinction of craving and of the cycle of rebirth, described in negatives and said to be beyond description. Islam’s goal is the opposite of extinction: a real Paradise for a real person, in the presence of the Lord who made him.")
                        .font(.body)

                    Text(articleMarkdown: "**Theravada, Mahayana, Vajrayana**: the three great branches. Theravada (“the way of the elders”), in Sri Lanka and Southeast Asia, keeps to the Pali canon and the ideal of the monk. Mahayana (“the great vehicle”), in East Asia, added many scriptures, celestial Buddhas, and the bodhisattva ideal. Vajrayana (“the diamond vehicle”), in Tibet and Mongolia, added tantric rites, mantras, and lamas. In all three, bowing before images, offerings, and appeals to Buddhas or bodhisattvas are part of ordinary devotion, though Buddhists usually call this veneration rather than the worship of a god; and none of it is directed to a Creator.")
                        .font(.body)

                    Text(articleMarkdown: "**Bodhisattva**: in Mahayana, a being who has reached the threshold of nirvana but stays to help others, and who is prayed to for aid, such as Avalokiteshvara, who is called Guanyin in East Asia. Prayer to any being other than Allah is shirk, however compassionate that being is held to be (Quran 10:18; 39:3).")
                        .font(.body)

                    Text(articleMarkdown: "**Meditation**: in Buddhism, the disciplined stilling and observation of the mind, sometimes with mantras or visualisation, aimed at insight and release. Islam has its own disciplines of the heart, reflection and remembrance, with Allah as their object (see the questions below).")
                        .font(.body)

                    Text(articleMarkdown: "**Monasticism**: the celibate, propertyless life of the monk, the highest calling in Buddhism. Islam says of the monasticism of the Christians:")
                        .font(.body)
                    ScriptureQuote(quran: "57:27", words: 11...30)

                    Text(articleMarkdown: "**Khaliq (الخَالِق)**: the Creator, from khalaqa, to bring into being by measure. This is the name Buddhism leaves out and the Quran begins with:")
                        .font(.body)
                    ScriptureQuote(quran: "59:24")

                    Text(articleMarkdown: "**Qadar (قَدَر)**: from qaddara, to measure out; Allah’s decree of all things by His knowledge and will, the Islamic answer to karma. What befalls a person is measured by a Lord who knows him, not by a ledger of past lives:")
                        .font(.body)
                    ScriptureQuote(quran: "54:49")

                    Text(articleMarkdown: "**Ruh (رُوح)**: the soul, which Allah breathes into each person and takes at death; real, single, and known to its Maker, though its nature is hidden from us (Quran 17:85, quoted above).")
                        .font(.body)

                    Text(articleMarkdown: "**Sabr (صَبر)**: patience, from sabara, to hold firm; the believer’s response to dukkha, which Islam makes a source of reward rather than an occasion for escape:")
                        .font(.body)
                    ScriptureQuote(quran: "2:153")
                    ScriptureQuote(quran: "39:10", words: 15...20)

                    Text(articleMarkdown: "**Tafakkur (تَفَكُّر)**: reflection, from fakkara, to think; the Muslim’s contemplation, whose object is not emptiness but the signs of the Creator:")
                        .font(.body)
                    ScriptureQuote(quran: "3:191", words: 0...16)

                    Text(articleMarkdown: "**Dhikr (ذِكر)**: remembrance of Allah with the tongue and the heart, in the words He and His Messenger taught; it is what gives the heart the peace that meditation seeks:")
                        .font(.body)
                    ScriptureQuote(quran: "13:28")
                    ScriptureQuote(quran: "33:41")

                    Text(articleMarkdown: "**Rahbaniyyah (رَهبَانِيَّة)**: monasticism, from rahiba, to fear; the withdrawal from marriage and the world that the Quran describes as a human invention (Quran 57:27, above) and that the Prophet (peace be upon him) refused for his Ummah (Sahih al-Bukhari 5063, quoted above).")
                        .font(.body)
                }

                ArticleSourcesSection(article: "BuddhismAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Buddhism")
        .selectableArticleList(article: "BuddhismAnswerView")
    }
}

struct AtheismAnswerView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "AtheismAnswerView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Atheism")
        .selectableArticleList(article: "AtheismAnswerView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: atheism says there is no God and the universe came from nothing or made itself. The Quran answers with the argument that made a Companion's heart nearly fly: nothing comes from nothing, order does not come from chaos, and the very fitrah of man knows its Maker."),
        ]),
        ArticleSection("WHAT ATHEISM CLAIMS", [
            .text("Atheism denies that there is a Creator. The universe, in this view, either has no cause, or caused itself, or has always existed, and life, consciousness, and moral law arose from matter without purpose. The Quran met this claim in the Arabs who said:"),
            .ayah("45:24"),
            .text("Notice the verdict: “they are only assuming.“ Atheism is not the result of knowledge; it is a claim that cannot be proved, since to know there is no God one would have to know everything."),
        ]),
        ArticleSection("1. THE ARGUMENT THAT SHOOK A HEART", [
            .text("Jubayr ibn Mut‘im, still a pagan, came to Madinah and heard the Prophet (peace be upon him) recite Surat at-Tur in the Maghrib prayer. He said that when the Prophet reached these verses, his heart nearly flew (Sahih al-Bukhari 4854):"),
            .ayah("52:35-36"),
            .text("There are only three possibilities for anything that begins to exist: it came from nothing, it made itself, or something else made it. Nothing produces nothing. A thing cannot make itself before it exists. So the universe, which began, was made by something outside it, uncreated, without beginning, and powerful enough to bring everything into being. That is what Muslims call Allah:"),
            .ayah("57:3"),
            .text("The question “then who created God?“ does not apply: the argument is that whatever begins needs a maker, and Allah did not begin. The Prophet (peace be upon him) taught that this question comes from Shaytan and is to be cut off:"),
            .hadith("bukhari:3276", cite: "Sahih al-Bukhari 3276, Sahih Muslim 134", arabic: 31...50, english: [4...40]),
        ]),
        ArticleSection("2. ORDER POINTS TO A DESIGNER", [
            .ayah("67:3-4"),
            .ayah("88:17-20"),
            .ayah("3:190-191"),
            .text("The constants of physics are balanced so finely that a small change would leave no stars, no chemistry, and no life; a single cell carries a coded library that no chance process writes; and the human eye that reads these words is the product of the very order the atheist says has no author. Ibrahim’s argument, that what sets and vanishes cannot be the lord, is the same argument: the dependent points to the Independent."),
            .ayah("41:53"),
        ]),
        ArticleSection("3. THE FITRAH", [
            .markdown("The **fitrah (فِطرَة)**, from ف-ط-ر, to originate or split something open anew, is the disposition Allah created every human upon. Belief in a Creator is not taught; it is born in every human being, and atheism is what has to be taught over it:"),
            .ayah("30:30"),
            .hadith("bukhari:1385", cite: "Sahih al-Bukhari 1385", arabic: 31...41, english: [4...31]),
            .ayah("7:172", words: 0...16),
            .text("This is why the atheist in the crashing aircraft prays, and why every people in every age has worshipped something. The Quran describes it in the pagans:"),
            .ayah("29:65"),
        ]),
        ArticleSection("4. THE RESURRECTION IS NOT HARDER THAN THE FIRST CREATION", [
            .text("The atheist says a dead body cannot live again. The Quran answers with the man’s own origin:"),
            .ayah("36:78-79"),
            .ayah("2:28"),
            .ayah("75:36-40"),
            .text("And a world without resurrection is a world without justice, where the murderer and the murdered end the same. The moral sense every human has, that this cannot be right, is itself a witness that there is a Day of reckoning."),
        ]),
        ArticleSection("5. WHY THE QURAN?", [
            .text("To know that God exists is the first step; the second is to know what He wants. The Quran presents itself as His word and gives its proof: recited by an unlettered man fourteen centuries ago, preserved unchanged, without contradiction, and free of contradiction, as it challenges its readers to test:"),
            .ayah("21:30"),
            .ayah("23:14"),
            .ayah("4:82"),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Who created God?**"),
            .text("No one, and the question misunderstands the argument. The claim is not that everything has a cause but that everything that begins has a cause. The universe began; Allah did not. He is the First, with nothing before Him (Quran 57:3, quoted above), and the Eternal Refuge on whom all depend while He depends on nothing (Quran 112:2). The Prophet (peace be upon him) taught his Companions to say before sleeping:"),
            .hadith("muslim:2713a", cite: "Sahih Muslim 2713", arabic: 55...75, english: [98...139]),
            .text("A chain of caused causes must end in an uncaused Cause, or nothing would ever have started; if every cause needed a prior cause the series would never reach the present. The Prophet (peace be upon him) told us that this question is Shaytan’s last move and is to be cut off with refuge in Allah (Sahih al-Bukhari 3276, Sahih Muslim 134, quoted above)."),
            .markdown("**Why is there evil and suffering?**"),
            .text("Because this life is a test, not the reward:"),
            .ayah("67:2"),
            .ayah("21:35"),
            .ayah("2:155"),
            .ayah("29:2-3"),
            .ayah("2:216", words: 6...24),
            .text("Much of the suffering in the world is what human hands have earned (Quran 30:41), and for the believer no pain is wasted; the Prophet (peace be upon him) said:"),
            .hadith("bukhari:5641", cite: "Sahih al-Bukhari 5641", arabic: 40...63, english: [4...39]),
            .hadith("bukhari:5645", cite: "Sahih al-Bukhari 5645", arabic: 40...46, english: [4...16]),
            .hadith("muslim:2999", cite: "Sahih Muslim 2999", arabic: 39...64, english: [0...73]),
            .text("The Prophet (peace be upon him) himself was orphaned, buried six of his seven children, was driven from his city, and was wounded at Uhud. The atheist’s complaint proves the opposite of what he intends: if there is no God, “evil” is only what one animal dislikes, and there is nothing to complain to. The very sense that suffering ought not to be is a sense of a standard beyond the world, and of a Day when it is set right."),
            .markdown("**Why can’t we see God?**"),
            .text("Because the creature cannot bear it in this life. When Musa (peace be upon him) asked to see Him, Allah revealed Himself to the mountain and it crumbled, and Musa fell unconscious (Quran 7:143):"),
            .ayah("6:103"),
            .text("The Prophet (peace be upon him) said:"),
            .hadith("muslim:179a", cite: "Sahih Muslim 179", english: [69...110], arabicText: "حِجَابُهُ النُّورُ لَو كَشَفَهُ لأَحرَقَت سُبُحَاتُ وَجهِهِ مَا انتَهَى إِلَيهِ بَصَرُهُ مِن خَلقِهِ"),
            .text("Seeing is promised, in the Hereafter, to those who believed without it:"),
            .ayah("75:22-23"),
            .hadith("bukhari:7434", cite: "Sahih al-Bukhari 7434", arabic: 31...41, english: [21...41]),
            .text("Meanwhile no one has seen his own mind, gravity, or the past, and no one doubts them; we know them by their effects. The effects of the Creator are everything that exists."),
            .markdown("**Doesn’t science explain everything?**"),
            .text("Science describes how things happen; it cannot say why there is anything at all, why the laws are what they are, or what anything is for. To explain the workings of a machine is not to show that it had no maker. The Quran commands observation, and its first revealed word was “Recite” (Quran 96:1-5); it points to the origin of the cosmos and of life (Quran 21:30) and promises that the signs in the horizons and in ourselves will confirm it (Quran 41:53, both quoted above). Reflection on creation is the mark of “those of understanding” (Quran 3:190-191). Allah asks:"),
            .ayah("39:9", words: 12...19),
            .ayah("35:28", words: 7...12),
            .text("Al-Khwarizmi in algebra, Ibn al-Haytham in optics, and az-Zahrawi in surgery were believers who studied creation as a book with an Author. Science answers the “how”; revelation answers the “who” and the “why.” A man who knows only the first has read the footnotes and skipped the title page."),
            .markdown("**Isn’t religion the cause of wars?**"),
            .text("Wars are caused by greed, pride, land, and power, in believers and unbelievers alike; men without any religion have fought as fiercely as men with one. Islam’s law of war forbids what the pagans permitted:"),
            .ayah("2:190"),
            .ayah("5:32", words: 0...26),
            .ayah("2:256", words: 0...8),
            .ayah("60:8"),
            .ayah("5:8", words: 0...18),
            .text("The Prophet (peace be upon him) forbade the killing of women and children (Sahih al-Bukhari 3015), forbade treachery and mutilation (Sahih Muslim 1731), and said:"),
            .hadith("bukhari:3166", cite: "Sahih al-Bukhari 3166", arabic: 32...45, english: [4...31]),
            .text("Allah even names the protection of monasteries, churches, and synagogues among the reasons He permits the believers to fight (Quran 22:40). Men fight over everything; it was religion that first told them when they may not."),
            .markdown("**Can we be good without God?**"),
            .text("A person can do good deeds without believing, because the knowledge of good and evil is planted in every soul by its Maker:"),
            .ayah("91:7-8"),
            .hadith("muslim:2553a", cite: "Sahih Muslim 2553", arabic: 41...53, english: [11...35]),
            .text("But that is the point: the moral sense is itself evidence of the One who inspired it. Without a Lawgiver, “good” is a preference, binding on no one; without a Judge, no wrong is ever set right, and the tyrant who dies in his bed has won. Islam says neither:"),
            .ayah("95:8"),
            .ayah("21:47"),
            .text("And no good deed is lost with Him, even the smallest (Quran 4:40). The atheist who is kind is living on borrowed capital; he acts on a law he says has no Lawgiver."),
            .markdown("**Aren’t all religions equally man-made?**"),
            .text("Islam does not say all religions are equal; it says one was sent by Allah to every prophet, and men altered it:"),
            .ayah("3:19", words: 0...17),
            .ayah("3:85"),
            .text("The Quran is the criterion over what came before (Quran 5:48), and it stands apart from every other scripture in two ways that can be tested: it was preserved word for word, as Allah promised, and it has never been matched, as Allah challenged (Quran 2:23; 17:88, quoted below):"),
            .ayah("15:9"),
            .text("The man-made is many and contradictory; the revealed is one, and the differences between religions are the measure of how far men have drifted from it."),
            .markdown("**What about evolution?**"),
            .text("Muslims believe what Allah told us about our origin: Adam (peace be upon him) was created by Allah directly, from clay, shaped by His hands, and given the soul by His breath:"),
            .ayah("38:71-72"),
            .ayah("3:59"),
            .text("The Prophet (peace be upon him) said:"),
            .hadith("bukhari:3326", cite: "Sahih al-Bukhari 3326", arabic: 29...34, english: [4...11]),
            .hadith("tirmidhi:2955", cite: "Sunan al-Tirmidhi 2955; graded sahih by al-Albani", arabic: 41...64, english: [7...56]),
            .text("That living things vary and adapt is observed, and Islam does not deny it; the colours and forms of the children of Adam are themselves an example, and the hadith just quoted says where they came from. What a Muslim cannot accept is that Adam (peace be upon him) had a human or an animal ancestor, or that man is here with no Creator, no purpose, and no soul. On the first, Allah has told us plainly how Adam was made, and revelation is knowledge; the descent of species is an inference about a past nobody witnessed, however carefully it is drawn from the evidence we do have, and inferences are revised while what Allah said is not. On the second, no fossil and no mechanism can show that nobody made it: to describe how a thing works has never answered who made it, or why. So the believer studies the workings of life closely, as Allah’s handiwork, and holds what Allah said about Adam as certain."),
            .markdown("**Isn’t the Quran a man’s book?**"),
            .text("The man it came through could not read or write:"),
            .ayah("29:48"),
            .text("He had lived forty years among his people without a line of poetry or preaching:"),
            .ayah("10:16"),
            .text("The pagans said it was dictated by a foreigner, and the Quran answered that the man they meant did not even speak Arabic (Quran 16:103). The Book challenged them to produce one surah like it (Quran 2:23) and they never did, though they were the masters of the language and would have given anything to silence him. It contains no contradiction (Quran 4:82, quoted above), it corrects the Prophet himself in places, and it describes what no man of that age knew. No man writes a book that rebukes its author."),
            .markdown("**What if I have doubts?**"),
            .text("A passing doubt is not disbelief, and hating it is faith. The Companions came to the Prophet (peace be upon him) troubled by thoughts they were ashamed to speak:"),
            .hadith("muslim:132a", cite: "Sahih Muslim 132", arabic: 24...48, english: [0...39]),
            .text("Ibrahim (peace be upon him) asked to be shown how the dead are raised, “only that my heart may be satisfied” (Quran 2:260), and the Prophet (peace be upon him) said:"),
            .hadith("bukhari:3372", cite: "Sahih al-Bukhari 3372", arabic: 40...58, english: [4...51]),
            .text("Allah addressed His Prophet (peace be upon him) with a condition he never fell into, so that those after him would learn where to take a doubt:"),
            .ayah("10:94"),
            .text("Doubts are cured by knowledge, by asking those who know, by looking at the signs (Quran 41:53), and by supplication; the Prophet (peace be upon him) taught that when the whisper reaches “who created your Lord?” one seeks refuge in Allah and stops (Sahih al-Bukhari 3276, above). A doubt examined honestly leads to certainty; a doubt fed in secret leads to the dark."),
            .markdown("**If God decreed everything, how am I responsible?**"),
            .text("Because the decree includes your own will and your own choosing. Allah knows and has written what you will do, and nothing at all happens outside His will; but the choice is really yours, and He does not force it upon you:"),
            .ayah("76:3"),
            .ayah("81:28-29"),
            .ayah("18:29", words: 0...9),
            .text("When the Companions asked whether they should stop working and rely on what was written, the Prophet (peace be upon him) said:"),
            .hadith("bukhari:4949", cite: "Sahih al-Bukhari 4949", arabic: 67...72, english: [65...92]),
            .text("You experience your choices as your own, you are praised and blamed for them by everyone including the atheist, and Allah’s foreknowledge no more forces them than a historian’s knowledge forces the past. He inspired the soul with its wickedness and its righteousness and made the purifying or the corrupting of it a man’s own deed, for which he answers (Quran 91:7-10), and He does not burden a soul beyond its capacity (Quran 2:286)."),
            .markdown("**Does God need our worship?**"),
            .text("No. Worship is for our benefit, not His:"),
            .ayah("51:56-57"),
            .ayah("14:8"),
            .ayah("39:7", words: 0...13),
            .text("In a hadith qudsi He says:"),
            .hadith("muslim:2577a", cite: "Sahih Muslim 2577", arabic: 101...132, english: [119...188]),
            .text("We are the ones in need (Quran 35:15, above). Worship is the soul finding what it was made for, as the eye was made for light."),
            .markdown("**Why would a loving God punish forever?**"),
            .text("Allah’s mercy comes first and reaches everything:"),
            .ayah("6:12", words: 8...11),
            .ayah("7:156", words: 12...21),
            .hadith("bukhari:3194", cite: "Sahih al-Bukhari 3194, Sahih Muslim 2751", arabic: 33...47, english: [4...25]),
            .text("He forgives all sins for whoever turns to Him (Quran 39:53), and He is more merciful to His servants than a mother to her child (Sahih al-Bukhari 5999, Sahih Muslim 2754). No one is punished who was not reached by the truth:"),
            .ayah("4:165", words: 0...10),
            .ayah("17:15", words: 15...20),
            .text("The Fire is for the one who knew and refused, who was called for a lifetime and turned his back until death closed the door; and its people will themselves confess that a warner came to them and that they denied him (Quran 67:8-11). Rejecting the Creator knowingly is not a small sin against a small being; it is the rejection of the Infinite, and its refusal does not expire because the one who made it dies. Even so, the Prophet (peace be upon him) said:"),
            .hadith("muslim:2755", cite: "Sahih Muslim 2755", arabic: 34...58, english: [0...52]),
            .text("The door is open until the last breath. Love that never judged would leave every oppressor unpunished and every victim unavenged; that is not love but indifference."),
            .markdown("**Is agnosticism (“we cannot know”) reasonable?**"),
            .text("It is not the neutral ground it looks like, because it claims to have no knowledge while setting aside the knowledge every soul was given. Allah created mankind on the fitrah (Quran 30:30) and took their testimony “Am I not your Lord?” (Quran 7:172), and the signs are in the horizons and in ourselves (Quran 41:53), all quoted above. Denial that outruns the heart is described in the Quran:"),
            .ayah("27:14", words: 0...5),
            .text("And the messengers’ own question stands:"),
            .ayah("14:10", words: 3...8),
            .text("Not knowing which religion is true is a reason to search, not to stop; not knowing whether there is a Maker, while standing in His creation, is not humility but refusal. The agnostic who prays in the crashing plane knows more than he admits."),
        ]),
        ArticleSection("THE INVITATION", [
            .ayah("51:20-21"),
            .text("The atheist is asked only to be consistent: to follow the evidence for a cause to its Cause, and to listen to the voice in himself that already knows. Allah does not compel belief (Quran 10:99); He invites to it with reason, and He forgives whoever turns to Him."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Nothing comes from nothing, order does not write itself, and the fitrah knows its Maker. The universe that began was begun by the One who did not, and He sent a Book to say who He is and what He asks."),
        ]),
        ArticleSection("KEY TERMS", [
            .markdown("**Atheism / ilhad (إِلحَاد)**: from lahada, to deviate or lean away; the lahd is the niche in a grave that is cut sideways, away from the straight shaft. Ilhad is thus any leaning away from the truth, and the **mulhid (مُلحِد)** in later usage is the one who denies the Creator altogether. The Quran uses the root for those who twist Allah’s names and His verses:"),
            .ayah("7:180"),
            .ayah("41:40", words: 0...7),
            .markdown("**Dahriyyah (الدَّهرِيَّة)**: from dahr, time; the ancient materialists who held that the world has no beginning and no Judge, only time that wears everything away. The Quran quoted them (Quran 45:24, above), and Ibn Hazm (may Allah have mercy on him) refuted those who say the world is eternal in the opening chapters of al-Fisal fi al-Milal. Since the pagan Arabs blamed “time” for every loss, the Prophet (peace be upon him) taught:"),
            .hadith("muslim:2246e", cite: "Sahih Muslim 2246", arabic: 23...29, english: [0...10]),
            .text("That is, what they call time is Allah’s disposal of affairs: “in My Hands are all things, and I cause the revolution of day and night” (Sahih al-Bukhari 4826)."),
            .markdown("**Agnosticism**: from the Greek for “not knowing”; the claim that whether God exists cannot be known. The messengers answered it with a question of their own, “Can there be doubt about Allah, Creator of the heavens and earth?” (Quran 14:10, quoted in the questions below)."),
            .markdown("**Naturalism / materialism**: the belief that matter and its laws are all there is, that the universe caused itself or has no cause, and that mind, purpose, and morality are by-products of matter. The Quran’s three-fold question (Quran 52:35-36, quoted below) is aimed exactly here: created by nothing, self-created, or created by another?"),
            .markdown("**Scientism**: the belief that the methods of natural science are the only road to knowledge, so that whatever they cannot measure does not exist. The Quran honours knowledge and observation, and describes the limit of a knowledge that stops at the surface:"),
            .ayah("30:7"),
            .ayah("53:28"),
            .markdown("**Secularism**: the confining of religion to private belief, with life, law, and learning conducted as if there were no God. Islam knows no such division; the whole of a life is offered to its Maker:"),
            .ayah("6:162"),
            .markdown("**Humanism**: the creed that makes man the measure of all things and the source of his own values. The Quran’s diagnosis of it is a single sentence:"),
            .ayah("96:6-7"),
            .ayah("35:15"),
            .markdown("**Nihilism**: from the Latin nihil, nothing; the conclusion, drawn honestly by some atheists and resisted by others, that life has no meaning, value, or purpose. The Quran names the alternative:"),
            .ayah("23:115"),
            .markdown("**Deism**: belief in a Creator who made the world and then left it to run by itself, sending no revelation and hearing no prayer. The Quran describes a Lord who is never absent from His creation:"),
            .ayah("55:29"),
            .ayah("35:41", words: 1...15),
            .markdown("**The fitrah (الفِطرَة)**: the innate disposition on which every human is born, which knows its Maker before any teaching (Quran 30:30; Sahih al-Bukhari 1385, both quoted above). Ibn Taymiyyah (may Allah have mercy on him) held that the affirmation of the Creator is settled in the fitrah of every person whose nature is sound, and that proofs are needed only to remove what has been laid over it (Dar’ Ta‘arud al-‘Aql wan-Naql)."),
            .markdown("**The argument from creation**: whatever begins to exist has a cause other than itself; the universe began; therefore it has a Cause that did not begin. This is the argument of Surat at-Tur (Quran 52:35-36, quoted above), and Ibn Kathir (may Allah have mercy on him) notes in his tafsir that the verse is a step-by-step proof: they were not brought into being without a maker, and they did not bring themselves into being, so it is Allah who created them."),
            .markdown("**The argument from design**: order, fine-tuning, and law point to a Designer; a text points to an author, and the universe is a text without a misprint (Quran 67:3-4 and 88:17-20, both quoted above). Ibn al-Qayyim (may Allah have mercy on him) filled much of Miftah Dar as-Sa‘adah with the signs of wisdom in the creatures, from the human body to the birds and the bees, as proofs of their Maker."),
            .markdown("**The argument from the fitrah**: belief in a Creator is universal, spontaneous, and returns under pressure (Quran 29:65, quoted above); it is the atheism that must be learned and maintained."),
            .markdown("**Contingency**: everything we observe depends on something else for its existence and could have been otherwise; a chain of dependent things cannot hold itself up, and must rest on One who is independent, necessary, and self-sufficient. That is the meaning of as-Samad in Surat al-Ikhlas, which Ibn Abbas (may Allah be pleased with him) explained as the Master to whom all creation turns in its needs (Tafsir Ibn Kathir):"),
            .ayah("112:2"),
            .markdown("**The Quranic challenge (التَّحَدِّي)**: the Quran’s standing proof of its origin, an open challenge to produce anything like it, never met in fourteen centuries:"),
            .ayah("2:23"),
            .ayah("17:88"),
        ]),
    ]
}
