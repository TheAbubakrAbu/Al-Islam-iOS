import SwiftUI

/// The "Answering Other Paths" articles: replies from the Quran and the Sunnah to Sufism, the Shia,
/// Christianity, Judaism, Hinduism, paganism, Buddhism, and atheism, each ending with the invitation.

struct SufismAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: purifying the heart is part of Islam, but the later Sufi orders added intermediaries, grave veneration, invented dhikr, absolute obedience to shaykhs, and claims that Allah dwells in or is one with creation. Each of these is answered by the Quran and the Sunnah.")
                        .font(.body)
                }

                Section(header: Text("WHAT IS SUFISM?")) {
                    Text("**Tasawwuf (تَصَوُّف)**, Sufism, began as a name for asceticism and devotion in the second and third centuries AH. The early ascetics of the Salaf, such as al-Fudayl ibn Iyad and Ibn al-Mubarak, were men of the Sunnah, and the purification of the heart (**tazkiyah**) is a duty in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“He has succeeded who purifies it, and he has failed who instills it [with corruption]” (Quran 91:9-10).", arabic: "قَدۡ أَفۡلَحَ مَن زَكَّىٰهَا ۝ وَقَدۡ خَابَ مَن دَسَّىٰهَا")

                    Text("Over the centuries, however, organised **tariqahs** (orders) appeared, each with a shaykh, a pledge of obedience, set formulas of dhikr, and ranks of “saints,“ and ideas entered that the Salaf never knew: seeking help from the dead, building over graves, dhikr with music and dancing, the shaykh’s word above the text, and the doctrines of **hulul** (Allah dwelling in creation) and **wahdat al-wujud** (that creation and Creator are one). Even al-Junayd (d. 297 AH), whom the Sufis take as their imam, tied the whole matter to the Sunnah:")
                        .font(.body)
                    ScriptureQuote(text: "“All the paths are closed to the creation except for the one who follows the footsteps of the Messenger” (al-Qushayri, ar-Risalah).", arabic: "الطُّرُقُ كُلُّهَا مَسْدُودَةٌ عَلَى الْخَلْقِ إِلَّا مَنِ اقْتَفَى أَثَرَ الرَّسُولِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ", dimmed: true)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Sufi / tasawwuf (صُوفِيّ / تَصَوُّف)**: from **suf (صُوف)**, wool, after the coarse woollen garments worn by the early ascetics. Ibn Taymiyyah (may Allah have mercy on him) records that the name was not current in the first three generations, that the Sufis first appeared in Basra, and that the first small lodge of the Sufis was built there by some of the companions of Abd al-Wahid ibn Zayd, himself a companion of al-Hasan al-Basri (Majmu‘ al-Fatawa 11/5-7). He also shows why the other proposed origins fail the rules of Arabic derivation: the relative adjective from **as-Suffah** (the poor Companions who lived in the Prophet’s mosque) would be Suffi, from **as-saff** (the first row in prayer) it would be Saffi, and from **as-safwah** (the elect) it would be Safawi; so the name goes back to wool. The Greek **sophia** (wisdom), which some later writers proposed, is not an Arabic root at all. Al-Qushayri, himself a Sufi, admits in ar-Risalah that no analogy or derivation in the Arabic language supports the name and that it is rather like a nickname, and Ibn Khaldun (al-Muqaddimah) judges wool the most likely origin. The Companions and the Tabi‘in never used the word; their names for the matter were faith, worship, and zuhd.")
                        .font(.body)

                    Text("**Zuhd (زُهْد)**: from ز-ه-د, to turn away from a thing because one has no desire for it. True asceticism is not rags, hunger, or withdrawal from people; it is the heart’s freedom from the world. Ibn al-Qayyim relates from his teacher Ibn Taymiyyah that zuhd is to leave what does not benefit in the Hereafter, and wara‘ (scrupulousness) is to leave what one fears will harm there (Madarij as-Salikin). The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The world is a prison for the believer and a paradise for the disbeliever” (Sahih Muslim 2956).", arabic: "الدُّنْيَا سِجْنُ الْمُؤْمِنِ وَجَنَّةُ الْكَافِرِ", dimmed: true)
                    ScriptureQuote(text: "“Be in this world as if you were a stranger or a traveller” (Sahih al-Bukhari 6416).", arabic: "كُنْ فِي الدُّنْيَا كَأَنَّكَ غَرِيبٌ، أَوْ عَابِرُ سَبِيلٍ", dimmed: true)

                    Text("**Tariqah (طَرِيقَة)**, pl. turuq: “way,“ from ط-ر-ق; in Sufi usage an organised order with its own chain of shaykhs, litany, and rites. The major orders and the men they are named after: the **Qadiriyyah** after Abd al-Qadir al-Jilani (d. 561 AH), a Hanbali preacher of Baghdad whose own book al-Ghunyah affirms the creed of the Salaf, and whose later followers went far beyond him; the **Rifa‘iyyah** after Ahmad ar-Rifa‘i (d. 578 AH); the **Shadhiliyyah** after Abu al-Hasan ash-Shadhili (d. 656 AH); the **Naqshbandiyyah** after Baha’ ad-Din Naqshband (d. 791 AH); and the **Tijaniyyah** after Ahmad at-Tijani (d. 1230 AH). None of them existed in the three generations the Prophet (peace be upon him) called the best of people (Sahih al-Bukhari 2652), and a way to Allah that the best generations did not know is not the way of the Prophet (peace be upon him).")
                        .font(.body)

                    Text("**Shaykh / murshid (شَيْخ / مُرْشِد)**: the head of an order; murshid is from ر-ش-د, to guide aright. The orders make his word binding on the disciple. In Islam the only man who is followed absolutely is the Messenger (peace be upon him); everyone else is followed when he agrees with the Book and the Sunnah and left when he departs from them.")
                        .font(.body)

                    Text("**Murid (مُرِيد)**: “the one who wills,“ from إِرَادَة: the disciple who has handed his will over to a shaykh.")
                        .font(.body)

                    Text("**Bay‘ah (بَيْعَة)**: a pledge, from ب-ي-ع, to conclude a deal by clasping hands. In the Sunnah, bay‘ah is given to the Prophet (peace be upon him) and after him to the Muslim ruler, to hear and obey in what is good (Sahih al-Bukhari 7199, Sahih Muslim 1709); the orders moved it to the shaykh, with a rite of hand-clasping and a sworn litany.")
                        .font(.body)

                    Text("**Wird / awrad (وِرْد / أَوْرَاد)**: a set daily portion of remembrance, from و-ر-د, to come down to water. Among the Salaf a man’s wird was his nightly portion of Quran and prayer; the orders assigned fixed formulas and counts composed by the shaykh.")
                        .font(.body)

                    Text("**Hadrah (حَضْرَة)**: “presence“: the collective dhikr gathering of the orders, with swaying, drumming, and chanting in unison.")
                        .font(.body)

                    Text("**Sama‘ (سَمَاع)**: “listening“: dhikr with singing and instruments, often with dancing. The Prophet (peace be upon him) counted musical instruments among the things people would try to make lawful (Sahih al-Bukhari 5590, cited in section 4 below).")
                        .font(.body)

                    Text("**Wali / awliya’ (وَلِيّ / أَوْلِيَاء)**: from و-ل-ي, nearness and support. The Quran defines the awliya’ of Allah as every believer who fears Him (Quran 10:62-63, quoted in section 1 below), not a class of appointed saints. Ibn Taymiyyah’s book al-Furqan bayna Awliya’ ar-Rahman wa Awliya’ ash-Shaytan makes following the Sunnah the only test of wilayah.")
                        .font(.body)

                    Text("**Karamah (كَرَامَة)**: an honour that Allah grants a righteous servant, from ك-ر-م, nobility and generosity. Ahl as-Sunnah affirm karamat: the provision Maryam received in her prayer chamber, the People of the Cave who slept for centuries (Quran 18:9-26), the throne of the queen of Saba’ brought by one who had knowledge of the Scripture (Quran 27:40), and the light that went before Usayd ibn Hudayr and Abbad ibn Bishr on a dark night (Sahih al-Bukhari 3805). Of Maryam, Allah said:")
                        .font(.body)
                    ScriptureQuote(text: "“Every time Zechariah entered upon her in the prayer chamber, he found with her provision. He said, ‘O Mary, from where is this [coming] to you?’ She said, ‘It is from Allah. Indeed, Allah provides for whom He wills without account’” (Quran 3:37).", arabic: "كُلَّمَا دَخَلَ عَلَيۡهَا زَكَرِيَّا ٱلۡمِحۡرَابَ وَجَدَ عِندَهَا رِزۡقٗاۖ قَالَ يَٰمَرۡيَمُ أَنَّىٰ لَكِ هَٰذَاۖ قَالَتۡ هُوَ مِنۡ عِندِ ٱللَّهِۖ إِنَّ ٱللَّهَ يَرۡزُقُ مَن يَشَآءُ بِغَيۡرِ حِسَابٍ")

                    Text("A karamah is a gift, not a rank; it proves nothing about a person unless he follows the Sunnah, and it never makes him someone to be called upon.")
                        .font(.body)

                    Text("**Fana’ / baqa’ (فَنَاء / بَقَاء)**: “passing away“ and “subsistence“: the claim that the self is annihilated in the witnessing of Allah until nothing but He is seen. Ibn Taymiyyah distinguishes three things called fana’: passing away from willing anything other than Allah, which is the state of the prophets and their followers; passing away from witnessing other than Him, which is a weakness that overcomes some worshippers and is not a goal; and the claim that nothing other than Him exists, which is the doctrine of hulul and ittihad (Majmu‘ al-Fatawa, vol. 10).")
                        .font(.body)

                    Text("**Hulul (حُلُول)**: “indwelling,“ from ح-ل-ل, to alight in a place: the claim that Allah dwells in a creature. **Ittihad (اتِّحَاد)**: “union“: the claim that the servant becomes one with Allah. **Wahdat al-wujud (وَحْدَة الوُجُود)**: “the oneness of existence“: the doctrine of Ibn Arabi (d. 638 AH) that the existence of creation is the very existence of the Creator. Al-Hallaj (d. 309 AH) was executed in Baghdad after his saying “Ana al-Haqq“ (I am the Truth). Ibn Taymiyyah refuted this doctrine at length (Majmu‘ al-Fatawa, vol. 2), and section 7 below answers it from the Quran.")
                        .font(.body)

                    Text("**Qutb / ghawth / abdal (قُطْب / غَوْث / أَبْدَال)**: “axis,“ “succour,“ and “substitutes“: in the orders, a hidden hierarchy of saints who are said to govern the world, the ghawth being the one people cry to for help. Ibn Taymiyyah says that the names ghawth, awtad, aqtab, and nujaba’ are found neither in the Book of Allah nor in any report from the Prophet (peace be upon him), and that the one term with a report behind it, the abdal, rests on a chain that is not established (Majmu‘ al-Fatawa, vol. 11); Ibn al-Qayyim rules that the hadiths of the abdal, aqtab, aghwath, nuqaba’, nujaba’, and awtad are all baseless attributions to the Messenger of Allah (al-Manar al-Munif). No creature governs the world; that belongs to Allah alone.")
                        .font(.body)

                    Text("**Kashf (كَشْف)**: “unveiling“: an inspiration or vision claimed as a source of knowledge. Revelation ended with the last of the prophets (Quran 33:40), and no kashf is a proof in the religion; it is judged by the texts, never the reverse.")
                        .font(.body)

                    Text("**Khalwah (خَلْوَة)**: “seclusion“: a retreat, often of forty days, in a cell with fasting and litanies set by the shaykh. The retreat of the Sunnah is i‘tikaf in the mosque, which the Prophet (peace be upon him) practised in the last ten nights of Ramadan until he died (Sahih al-Bukhari 2026).")
                        .font(.body)

                    Text("**Shari‘ah / tariqah / haqiqah (شَرِيعَة / طَرِيقَة / حَقِيقَة)**: the claimed three levels of the religion: the outer law, the Sufi path, and the inner reality that the elite reach. Answered under Common Questions below.")
                        .font(.body)

                    Text("**Ihsan (إِحْسَان)**: “doing well,“ from ح-س-ن, beauty and excellence; the third level of the religion in the hadith of Jibril, after Islam and iman. The Prophet (peace be upon him) defined it:")
                        .font(.body)
                    ScriptureQuote(text: "“That you worship Allah as if you see Him, for though you do not see Him, He sees you” (Sahih Muslim 8).", arabic: "أَنْ تَعْبُدَ اللَّهَ كَأَنَّكَ تَرَاهُ فَإِنْ لَمْ تَكُنْ تَرَاهُ فَإِنَّهُ يَرَاكَ", dimmed: true)

                    Text("This is the real spiritual path: worship with the presence of the heart, inside the shari‘ah, needing no order.")
                        .font(.body)
                }

                Section(header: Text("1. CLOSENESS TO ALLAH IS THROUGH WHAT HE LEGISLATED")) {
                    Text("The Sufi orders offer a “path“ to Allah of their own devising. But Allah told us who His **awliya’** (close friends) are and how they reach Him:")
                        .font(.body)
                    ScriptureQuote(text: "“Unquestionably, [for] the allies of Allah there will be no fear concerning them, nor will they grieve. Those who believed and were fearing Allah” (Quran 10:62-63).", arabic: "أَلَآ إِنَّ أَوۡلِيَآءَ ٱللَّهِ لَا خَوۡفٌ عَلَيۡهِمۡ وَلَا هُمۡ يَحۡزَنُونَ ۝ ٱلَّذِينَ ءَامَنُواْ وَكَانُواْ يَتَّقُونَ")

                    Text("And in the hadith qudsi:")
                        .font(.body)
                    ScriptureQuote(text: "“The most beloved thing by which My servant draws near to Me is what I have made obligatory upon him, and My servant continues to draw near to Me with voluntary deeds until I love him” (Sahih al-Bukhari 6502).", arabic: "وَمَا تَقَرَّبَ إِلَىَّ عَبْدِي بِشَىْءٍ أَحَبَّ إِلَىَّ مِمَّا افْتَرَضْتُ عَلَيْهِ، وَمَا يَزَالُ عَبْدِي يَتَقَرَّبُ إِلَىَّ بِالنَّوَافِلِ حَتَّى أُحِبَّهُ", dimmed: true)

                    Text("Obligations first, then the voluntary acts the Prophet (peace be upon him) taught. There is no third road of secret litanies, and no rank of wali reached by other than faith and taqwa.")
                        .font(.body)
                }

                Section(header: Text("2. NO INTERMEDIARIES BETWEEN THE SERVANT AND ALLAH")) {
                    Text("Calling upon dead saints, prophets, or shaykhs for help, children, or rescue, the **istighathah** practised at shrines, is the shirk that the Quran was revealed against. The pagans of Makkah did exactly this, and with the same excuse:")
                        .font(.body)
                    ScriptureQuote(text: "“And those who take protectors besides Him [say], ‘We only worship them that they may bring us nearer to Allah in position’” (Quran 39:3).", arabic: "وَٱلَّذِينَ ٱتَّخَذُواْ مِن دُونِهِۦٓ أَوۡلِيَآءَ مَا نَعۡبُدُهُمۡ إِلَّا لِيُقَرِّبُونَآ إِلَى ٱللَّهِ زُلۡفَىٰٓ إِنَّ ٱللَّهَ يَحۡكُمُ بَيۡنَهُمۡ فِي مَا هُمۡ فِيهِ يَخۡتَلِفُونَۗ إِنَّ ٱللَّهَ لَا يَهۡدِي مَنۡ هُوَ كَٰذِبٞ كَفَّارٞ")

                    ScriptureQuote(text: "“And who is more astray than he who invokes besides Allah those who will not respond to him until the Day of Resurrection, and they, of their invocation, are unaware. And when the people are gathered [that Day], they [who were invoked] will be enemies to them, and they will be deniers of their worship” (Quran 46:5-6).", arabic: "وَمَنۡ أَضَلُّ مِمَّن يَدۡعُواْ مِن دُونِ ٱللَّهِ مَن لَّا يَسۡتَجِيبُ لَهُۥٓ إِلَىٰ يَوۡمِ ٱلۡقِيَٰمَةِ وَهُمۡ عَن دُعَآئِهِمۡ غَٰفِلُونَ ۝ وَإِذَا حُشِرَ ٱلنَّاسُ كَانُواْ لَهُمۡ أَعۡدَآءٗ وَكَانُواْ بِعِبَادَتِهِمۡ كَٰفِرِينَ")

                    ScriptureQuote(text: "“If you invoke them, they do not hear your supplication; and if they heard, they would not respond to you. And on the Day of Resurrection they will deny your association” (Quran 35:14).", arabic: "إِن تَدۡعُوهُمۡ لَا يَسۡمَعُواْ دُعَآءَكُمۡ وَلَوۡ سَمِعُواْ مَا ٱسۡتَجَابُواْ لَكُمۡۖ وَيَوۡمَ ٱلۡقِيَٰمَةِ يَكۡفُرُونَ بِشِرۡكِكُمۡۚ")

                    Text("Allah is near without any go-between:")
                        .font(.body)
                    ScriptureQuote(text: "“And when My servants ask you, [O Muhammad], concerning Me - indeed I am near. I respond to the invocation of the supplicant when he calls upon Me” (Quran 2:186).", arabic: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌۖ أُجِيبُ دَعۡوَةَ ٱلدَّاعِ إِذَا دَعَانِۖ")

                    Text("The Companions understood this. In a drought, Umar (may Allah be pleased with him) did not go to the Prophet’s grave, a few steps away, to ask him; he asked the Prophet’s living uncle to supplicate:")
                        .font(.body)
                    ScriptureQuote(text: "“O Allah, we used to ask You for rain through our Prophet and You gave us rain, and now we ask You through the uncle of our Prophet, so give us rain.” And they were given rain (Sahih al-Bukhari 1010).", arabic: "اللَّهُمَّ إِنَّا كُنَّا نَتَوَسَّلُ إِلَيْكَ بِنَبِيِّنَا فَتَسْقِينَا وَإِنَّا نَتَوَسَّلُ إِلَيْكَ بِعَمِّ نَبِيِّنَا فَاسْقِنَا. قَالَ فَيُسْقَوْنَ", dimmed: true)

                    Text("And the Prophet (peace be upon him) taught Ibn Abbas:")
                        .font(.body)
                    ScriptureQuote(text: "“When you ask, ask Allah, and when you seek help, seek help from Allah” (Sunan al-Tirmidhi 2516; graded sahih by al-Albani).", arabic: "إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ وَإِذَا اسْتَعَنْتَ فَاسْتَعِنْ بِاللَّهِ", dimmed: true)
                }

                Section(header: Text("3. GRAVES ARE NOT SHRINES")) {
                    Text("The domes, tombs, and festivals at the graves of the “saints“ are the opposite of what the Prophet (peace be upon him) commanded. Ali (may Allah be pleased with him) said to Abu al-Hayyaj:")
                        .font(.body)
                    ScriptureQuote(text: "“Shall I not send you on the mission the Messenger of Allah sent me on? Do not leave an image without effacing it, nor a raised grave without levelling it” (Sahih Muslim 969).", arabic: "أَلاَّ أَبْعَثُكَ عَلَى مَا بَعَثَنِي عَلَيْهِ رَسُولُ اللَّهِ صلى الله عليه وسلم أَنْ لاَ تَدَعَ تِمْثَالاً إِلاَّ طَمَسْتَهُ وَلاَ قَبْرًا مُشْرِفًا إِلاَّ سَوَّيْتَهُ", dimmed: true)

                    ScriptureQuote(text: "“Do not sit on the graves and do not pray facing towards them” (Sahih Muslim 972).", arabic: "لاَ تَجْلِسُوا عَلَى الْقُبُورِ وَلاَ تُصَلُّوا إِلَيْهَا", dimmed: true)

                    Text("Five days before his death he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Those before you used to take the graves of their prophets and righteous men as places of worship. Do not take graves as places of worship; I forbid you from that” (Sahih Muslim 532).", arabic: "أَلاَ وَإِنَّ مَنْ كَانَ قَبْلَكُمْ كَانُوا يَتَّخِذُونَ قُبُورَ أَنْبِيَائِهِمْ وَصَالِحِيهِمْ مَسَاجِدَ أَلاَ فَلاَ تَتَّخِذُوا الْقُبُورَ مَسَاجِدَ إِنِّي أَنْهَاكُمْ عَنْ ذَلِكَ", dimmed: true)

                    ScriptureQuote(text: "“Allah cursed the Jews and the Christians, who took the graves of their prophets as places of worship” (Sahih al-Bukhari 1330, Sahih Muslim 529).", arabic: "لَعَنَ اللَّهُ الْيَهُودَ وَالنَّصَارَى، اتَّخَذُوا قُبُورَ أَنْبِيَائِهِمْ مَسْجِدًا", dimmed: true)
                }

                Section(header: Text("4. INVENTED DHIKR AND GATHERINGS")) {
                    Text("Dhikr is the life of the heart, and the Prophet (peace be upon him) taught its words, times, and numbers. The set formulas, counted litanies, swaying circles, music, and dancing of the orders are not from him. When the Companions saw men counting dhikr in circles in the mosque of Kufah, Ibn Mas‘ud (may Allah be pleased with him) said to them:")
                        .font(.body)
                    ScriptureQuote(text: "“By the One in whose hand is my soul, either you are upon a religion more guided than the religion of Muhammad, or you are opening a door of misguidance” (Sunan al-Darimi 206; graded sahih by al-Albani, as-Silsilah as-Sahihah 2005).", arabic: "وَالَّذِي نَفْسِي بِيَدِهِ، إِنَّكُمْ لَعَلَى مِلَّةٍ هِيَ أَهْدَى مِنْ مِلَّةِ مُحَمَّدٍ، أَوْ مُفْتَتِحُو بَابِ ضَلَالَةٍ", dimmed: true)

                    ScriptureQuote(text: "“The worst of matters are the newly invented ones, and every innovation is misguidance” (Sahih Muslim 867).", arabic: "وَشَرُّ الأُمُورِ مُحْدَثَاتُهَا وَكُلُّ بِدْعَةٍ ضَلاَلَةٌ", dimmed: true)

                    Text("As for music in worship, the Prophet (peace be upon him) counted musical instruments among the things people would try to make lawful (Sahih al-Bukhari 5590). Worship with drums and flutes is not the Sunnah.")
                        .font(.body)
                }

                Section(header: Text("5. NO EXCESS IN ASCETICISM")) {
                    Text("The severe self-denial of some orders, withdrawal from marriage and society, and hunger as worship come from monasticism, which Allah said the Christians invented:")
                        .font(.body)
                    ScriptureQuote(text: "“And monasticism, which they innovated; We did not prescribe it for them” (Quran 57:27).", arabic: "وَرَهۡبَانِيَّةً ٱبۡتَدَعُوهَا مَا كَتَبۡنَٰهَا عَلَيۡهِمۡ")

                    ScriptureQuote(text: "“O you who have believed, do not prohibit the good things which Allah has made lawful to you and do not transgress. Indeed, Allah does not like transgressors” (Quran 5:87).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ لَا تُحَرِّمُواْ طَيِّبَٰتِ مَآ أَحَلَّ ٱللَّهُ لَكُمۡ وَلَا تَعۡتَدُوٓاْۚ إِنَّ ٱللَّهَ لَا يُحِبُّ ٱلۡمُعۡتَدِينَ")

                    Text("When three men resolved to pray all night, fast every day, and never marry, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“By Allah, I am the most fearful of Allah among you and the most conscious of Him, yet I fast and break my fast, I pray and I sleep, and I marry women. Whoever turns away from my Sunnah is not of me” (Sahih al-Bukhari 5063).", arabic: "أَمَا وَاللَّهِ إِنِّي لأَخْشَاكُمْ لِلَّهِ وَأَتْقَاكُمْ لَهُ، لَكِنِّي أَصُومُ وَأُفْطِرُ، وَأُصَلِّي وَأَرْقُدُ وَأَتَزَوَّجُ النِّسَاءَ، فَمَنْ رَغِبَ عَنْ سُنَّتِي فَلَيْسَ مِنِّي", dimmed: true)
                }

                Section(header: Text("6. THE SHAYKH IS NOT ABOVE THE TEXT")) {
                    Text("The orders teach that the disciple must be before his shaykh “like a corpse in the hands of its washer,“ and that the shaykh’s unveilings (**kashf**) are a source of knowledge beside revelation. Allah described people who gave their scholars that place:")
                        .font(.body)
                    ScriptureQuote(text: "“They have taken their scholars and monks as lords besides Allah” (Quran 9:31).", arabic: "ٱتَّخَذُوٓاْ أَحۡبَارَهُمۡ وَرُهۡبَٰنَهُمۡ أَرۡبَابٗا مِّن دُونِ ٱللَّهِ")

                    ScriptureQuote(text: "“Follow, [O mankind], what has been revealed to you from your Lord and do not follow other than Him any allies. Little do you remember” (Quran 7:3).", arabic: "ٱتَّبِعُواْ مَآ أُنزِلَ إِلَيۡكُم مِّن رَّبِّكُمۡ وَلَا تَتَّبِعُواْ مِن دُونِهِۦٓ أَوۡلِيَآءَۗ قَلِيلٗا مَّا تَذَكَّرُونَ")

                    Text("Revelation ended with the Prophet (peace be upon him). No dream, vision, or intuition of any shaykh adds to it or overrides it.")
                        .font(.body)
                }

                Section(header: Text("7. ALLAH IS NOT HIS CREATION")) {
                    Text("The doctrines of hulul and wahdat al-wujud, associated with al-Hallaj (d. 309 AH) and Ibn Arabi (d. 638 AH), say that Allah dwells in creation or that everything is Him. This is not Islam by any school. Allah is the Creator, separate from and above His creation, and nothing is like Him:")
                        .font(.body)
                    ScriptureQuote(text: "“There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).", arabic: "لَيۡسَ كَمِثۡلِهِۦ شَيۡءٞۖ وَهُوَ ٱلسَّمِيعُ ٱلۡبَصِيرُ")

                    ScriptureQuote(text: "“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent’” (Quran 112:1-4).", arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ ۝ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ۝ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ")

                    ScriptureQuote(text: "“Indeed, your Lord is Allah, who created the heavens and earth in six days and then established Himself above the Throne” (Quran 7:54).", arabic: "إِنَّ رَبَّكُمُ ٱللَّهُ ٱلَّذِي خَلَقَ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ فِي سِتَّةِ أَيَّامٖ ثُمَّ ٱسۡتَوَىٰ عَلَى ٱلۡعَرۡشِۖ")

                    Text("His nearness to His servants is by His knowledge, hearing, and help, not by mixing with them:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have already created man and know what his soul whispers to him, and We are closer to him than [his] jugular vein” (Quran 50:16).", arabic: "وَلَقَدۡ خَلَقۡنَا ٱلۡإِنسَٰنَ وَنَعۡلَمُ مَا تُوَسۡوِسُ بِهِۦ نَفۡسُهُۥۖ وَنَحۡنُ أَقۡرَبُ إِلَيۡهِ مِنۡ حَبۡلِ ٱلۡوَرِيدِ")
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Is all tasawwuf condemned?**")
                        .font(.body)
                    Text("No, and fairness is part of the religion. Ibn Taymiyyah (may Allah have mercy on him) gives the balanced verdict in Majmu‘ al-Fatawa (11/16-18): the early ascetics were people striving in the obedience of Allah as others strove, some of them foremost and drawn near, some moderate, and among both kinds were those who erred in their striving and those who sinned and repented or did not; so the truth is neither to accept everything called Sufism nor to condemn everyone called a Sufi. Adh-Dhahabi honours al-Fudayl ibn Iyad, Ibrahim ibn Adham, and al-Junayd in Siyar A‘lam an-Nubala’ as imams of worship and the Sunnah, and al-Junayd’s own words about the Sunnah were quoted above. The criterion is not the name but the Sunnah: what agrees with the Book and the Sunnah is accepted, whoever said it, and what opposes them is rejected, whoever said it.")
                        .font(.body)

                    Text("**Were Ibn Taymiyyah, Ibn al-Qayyim, or an-Nawawi Sufis?**")
                        .font(.body)
                    Text("None of them took a tariqah, gave bay‘ah to a shaykh, or practised the rites of the orders. Ibn al-Qayyim’s Madarij as-Salikin is a commentary on Manazil as-Sa’irin of Abu Isma‘il al-Harawi (d. 481 AH), a Hanbali of Herat who defended the creed of the Salaf; Ibn al-Qayyim praises him where he is right and corrects him openly where his expressions slip toward fana’ and ittihad, saying:")
                        .font(.body)
                    ScriptureQuote(text: "“Shaykh al-Islam is beloved to us, but the truth is more beloved to us than him” (Ibn al-Qayyim, Madarij as-Salikin).", arabic: "شَيْخُ الْإِسْلَامِ حَبِيبٌ إِلَيْنَا، وَالْحَقُّ أَحَبُّ إِلَيْنَا مِنْهُ", dimmed: true)

                    Text("Ibn Taymiyyah wrote on the stations of the heart, on the awliya’, and on the errors of the orders in the same volumes in which he defended the early ascetics. An-Nawawi wrote Riyad as-Salihin and al-Adhkar to return remembrance and conduct to the texts. These scholars took the science of the heart from the Quran and the Sunnah and judged the Sufis by them; that is not membership of an order.")
                        .font(.body)

                    Text("**Is ihsan and purifying the soul (tazkiyah) Sufism?**")
                        .font(.body)
                    Text("Ihsan and tazkiyah are Islam itself. Allah made purification one of the purposes of sending the Messenger (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“Just as We have sent among you a messenger from yourselves reciting to you Our verses and purifying you and teaching you the Book and wisdom and teaching you that which you did not know” (Quran 2:151).", arabic: "كَمَآ أَرۡسَلۡنَا فِيكُمۡ رَسُولٗا مِّنكُمۡ يَتۡلُواْ عَلَيۡكُمۡ ءَايَٰتِنَا وَيُزَكِّيكُمۡ وَيُعَلِّمُكُمُ ٱلۡكِتَٰبَ وَٱلۡحِكۡمَةَ وَيُعَلِّمُكُم مَّا لَمۡ تَكُونُواْ تَعۡلَمُونَ")

                    Text("He declared success for the one who purifies his soul (Quran 91:9-10, quoted above), and the Prophet (peace be upon him) defined ihsan in the hadith of Jibril (Sahih Muslim 8, quoted above). Whoever wants tazkiyah has it in the Quran, the prayer, the fast, dhikr as taught, and the company of the righteous, and he needs no order to reach it.")
                        .font(.body)

                    Text("**Is gathering for dhikr an innovation?**")
                        .font(.body)
                    Text("Gathering to learn, to recite, and to remember Allah as He is remembered in the Sunnah is beloved to Allah. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“No people sit remembering Allah but the angels surround them, mercy covers them, tranquillity descends upon them, and Allah mentions them to those who are with Him” (Sahih Muslim 2700).", arabic: "لاَ يَقْعُدُ قَوْمٌ يَذْكُرُونَ اللَّهَ عَزَّ وَجَلَّ إِلاَّ حَفَّتْهُمُ الْمَلاَئِكَةُ وَغَشِيَتْهُمُ الرَّحْمَةُ وَنَزَلَتْ عَلَيْهِمُ السَّكِينَةُ وَذَكَرَهُمُ اللَّهُ فِيمَنْ عِنْدَهُ", dimmed: true)

                    Text("What is rejected is the invented form: chanting in unison, counted formulas assigned by a shaykh, swaying, drums, and the belief that these are the path. That is exactly what Ibn Mas‘ud (may Allah be pleased with him) denounced in Kufah (Sunan al-Darimi 206, quoted in section 4): the men in those circles were counting Allahu Akbar, la ilaha illa Allah, and subhan Allah a hundred times each on pebbles, words of truth, and he still called it a door of misguidance because the form was not from the Prophet (peace be upon him). When they protested that they had intended only good, he answered that many who intend good never reach it.")
                        .font(.body)

                    Text("**Are prayer beads allowed?**")
                        .font(.body)
                    Text("The Sunnah is to count on the fingers. The Prophet (peace be upon him) commanded the believing women to keep up the takbir, taqdis, and tahlil and:")
                        .font(.body)
                    ScriptureQuote(text: "“to count them on the fingers, for they will be questioned and made to speak” (Sunan Abi Dawud 1501; graded hasan by al-Albani).", arabic: "وَأَنْ يَعْقِدْنَ بِالأَنَامِلِ فَإِنَّهُنَّ مَسْئُولاَتٌ مُسْتَنْطَقَاتٌ", dimmed: true)

                    Text("Ibn Taymiyyah held that counting on the fingers is the Sunnah, that counting with date stones or pebbles is good, and that a string of beads is permissible and not disliked when the intention is sound, though some of the scholars disliked it (Majmu‘ al-Fatawa, vol. 22). What is rejected is making the beads a badge of the order, or a thing worn for show.")
                        .font(.body)

                    Text("**Do the awliya’ have karamat, and may we ask them for help?**")
                        .font(.body)
                    Text("They may have karamat, as shown above from the Quran and the Sahih. Allah tells of the one who brought the throne of the queen of Saba’ to Sulayman:")
                        .font(.body)
                    ScriptureQuote(text: "“Said one who had knowledge from the Scripture, ‘I will bring it to you before your glance returns to you’” (Quran 27:40).", arabic: "قَالَ ٱلَّذِي عِندَهُۥ عِلۡمٞ مِّنَ ٱلۡكِتَٰبِ أَنَا۠ ءَاتِيكَ بِهِۦ قَبۡلَ أَن يَرۡتَدَّ إِلَيۡكَ طَرۡفُكَۚ")

                    Text("But a karamah gives the servant no share in what belongs to Allah. The dead do not hear the callers, and they will disown those who called them (Quran 35:14 and 46:5-6, quoted in section 2). Calling upon a dead wali for a need is the shirk of the Arabs who said “that they may bring us nearer to Allah“ (Quran 39:3, quoted in section 2); asking a living, present, able person for what he can do is permitted, and asking a righteous living person to supplicate for you is what Umar did with al-Abbas (Sahih al-Bukhari 1010, quoted in section 2).")
                        .font(.body)

                    Text("**May we seek blessing from a shaykh’s body, clothes, or grave?**")
                        .font(.body)
                    Text("Tabarruk with the person was specific to the Prophet (peace be upon him) in his lifetime: when he shaved his head at Mina, the Companions took his hair, and Abu Talhah was the first to receive it (Sahih al-Bukhari 171; Sahih Muslim 1305). They did not do this with Abu Bakr, Umar, Uthman, or Ali, who were the best of people after him, and ash-Shatibi notes in al-I‘tisam that this leaving was an agreement among them that such things belonged to the Prophet alone. As for graves, the Prophet (peace be upon him) forbade taking them as places of worship five days before his death (Sahih Muslim 532, quoted in section 3), and Ibn Taymiyyah explains in Iqtida’ as-Sirat al-Mustaqim that seeking blessing at graves is the road to worshipping their occupants.")
                        .font(.body)

                    Text("**Is the division into shari‘ah, tariqah, and haqiqah valid?**")
                        .font(.body)
                    Text("No. Allah gave the Prophet (peace be upon him) one way and commanded him to follow it:")
                        .font(.body)
                    ScriptureQuote(text: "“Then We put you, [O Muhammad], on an ordained way concerning the matter [of religion]; so follow it and do not follow the inclinations of those who do not know” (Quran 45:18).", arabic: "ثُمَّ جَعَلۡنَٰكَ عَلَىٰ شَرِيعَةٖ مِّنَ ٱلۡأَمۡرِ فَٱتَّبِعۡهَا وَلَا تَتَّبِعۡ أَهۡوَآءَ ٱلَّذِينَ لَا يَعۡلَمُونَ")

                    Text("The Book was sent as a criterion over what preceded it (Quran 5:48), and there is no reality above it that frees anyone from it. The claim that the elite reach a haqiqah where the shari‘ah no longer binds them is answered by the Prophet’s words to the three men who wanted more than his Sunnah: “Whoever turns away from my Sunnah is not of me“ (Sahih al-Bukhari 5063, quoted in section 5). The shari‘ah is the haqiqah, and the tariqah is the Sunnah.")
                        .font(.body)

                    Text("**Was the Prophet created from light before everything else?**")
                        .font(.body)
                    Text("No. Allah commanded him to say:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘I am only a man like you, to whom has been revealed that your god is one God’” (Quran 18:110).", arabic: "قُلۡ إِنَّمَآ أَنَا۠ بَشَرٞ مِّثۡلُكُمۡ يُوحَىٰٓ إِلَيَّ أَنَّمَآ إِلَٰهُكُمۡ إِلَٰهٞ وَٰحِدٞۖ")

                    Text("The report attributed to Jabir, that the first thing Allah created was the light of your Prophet, has no known sound chain, and al-Albani ruled it baseless (as-Silsilah ad-Da‘ifah). What the authentic Sunnah says is:")
                        .font(.body)
                    ScriptureQuote(text: "“The first thing Allah created was the Pen. He said to it: Write. It asked: What should I write, my Lord? He said: Write what was decreed about everything till the Last Hour comes” (Sunan Abi Dawud 4700; graded sahih by al-Albani).", arabic: "إِنَّ أَوَّلَ مَا خَلَقَ اللَّهُ الْقَلَمَ فَقَالَ لَهُ اكْتُبْ. قَالَ رَبِّ وَمَاذَا أَكْتُبُ قَالَ اكْتُبْ مَقَادِيرَ كُلِّ شَىْءٍ حَتَّى تَقُومَ السَّاعَةُ", dimmed: true)

                    Text("The Prophet (peace be upon him) is the best of creation, but he was created as a man, from the offspring of Adam, and his honour is in his servitude and his message, not in a light that would make him other than a man.")
                        .font(.body)

                    Text("**Is pledging bay‘ah to a shaykh required?**")
                        .font(.body)
                    Text("No. In the Sunnah, bay‘ah is a pledge to the ruler to hear and obey in what is good. Ubadah ibn as-Samit (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“We gave the pledge of allegiance to the Messenger of Allah that we would listen and obey, both when we were active and when we were tired, that we would not dispute the authority with its people, and that we would stand for the truth or speak the truth wherever we were, not fearing for the sake of Allah the blame of any blamer” (Sahih al-Bukhari 7199, Sahih Muslim 1709).", arabic: "بَايَعْنَا رَسُولَ اللَّهِ صلى الله عليه وسلم عَلَى السَّمْعِ وَالطَّاعَةِ فِي الْمَنْشَطِ وَالْمَكْرَهِ. وَأَنْ لاَ نُنَازِعَ الأَمْرَ أَهْلَهُ، وَأَنْ نَقُومَ ـ أَوْ نَقُولَ ـ بِالْحَقِّ حَيْثُمَا كُنَّا لاَ نَخَافُ فِي اللَّهِ لَوْمَةَ لاَئِمٍ", dimmed: true)

                    Text("There is no pledge to a shaykh in the Quran, in the Sunnah, or among the Companions. The only absolute following is of the Prophet (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘If you should love Allah, then follow me, [so] Allah will love you and forgive you your sins’” (Quran 3:31).", arabic: "قُلۡ إِن كُنتُمۡ تُحِبُّونَ ٱللَّهَ فَٱتَّبِعُونِي يُحۡبِبۡكُمُ ٱللَّهُ وَيَغۡفِرۡ لَكُمۡ ذُنُوبَكُمۡۚ")

                    Text("**Is fana’ or wahdat al-wujud part of Islam?**")
                        .font(.body)
                    Text("No. The Creator is other than His creation; He originated everything, and nothing is like Him (Quran 42:11 and Surat al-Ikhlas, quoted in section 7):")
                        .font(.body)
                    ScriptureQuote(text: "“[He is] Originator of the heavens and the earth. How could He have a son when He does not have a companion and He created all things? And He is, of all things, Knowing” (Quran 6:101).", arabic: "بَدِيعُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ أَنَّىٰ يَكُونُ لَهُۥ وَلَدٞ وَلَمۡ تَكُن لَّهُۥ صَٰحِبَةٞۖ وَخَلَقَ كُلَّ شَيۡءٖۖ وَهُوَ بِكُلِّ شَيۡءٍ عَلِيمٞ")

                    Text("The one who claims that his existence is Allah’s existence, or that he has passed away into Him, has denied the difference between the Creator and the created that every prophet was sent to teach. Ibn Taymiyyah refuted the people of ittihad at length, showing that their doctrine ends in declaring the idolaters right, since if everything is Him then nothing was ever worshipped but Him (Majmu‘ al-Fatawa, vol. 2). Whoever is overcome by a state and says such a word without meaning it is excused for his state, but the state is not the path and the word is not the truth.")
                        .font(.body)

                    Text("**Is music in dhikr allowed?**")
                        .font(.body)
                    Text("No. The Prophet (peace be upon him) counted instruments among the things people would try to make lawful (Sahih al-Bukhari 5590, cited in section 4), and Ibn Mas‘ud (may Allah be pleased with him) swore by Allah that the “amusement of speech“ in this ayah is singing, as Ibn Kathir records in his tafsir:")
                        .font(.body)
                    ScriptureQuote(text: "“And of the people is he who buys the amusement of speech to mislead [others] from the way of Allah without knowledge and who takes it in ridicule. Those will have a humiliating punishment” (Quran 31:6).", arabic: "وَمِنَ ٱلنَّاسِ مَن يَشۡتَرِي لَهۡوَ ٱلۡحَدِيثِ لِيُضِلَّ عَن سَبِيلِ ٱللَّهِ بِغَيۡرِ عِلۡمٖ وَيَتَّخِذَهَا هُزُوًاۚ أُوْلَٰٓئِكَ لَهُمۡ عَذَابٞ مُّهِينٞ")

                    Text("If instruments are forbidden in leisure, they are further from being a means of worship. Dhikr in the Sunnah is with the tongue and the heart, in the words the Prophet (peace be upon him) taught, with dignity and without a drum.")
                        .font(.body)
                }

                Section(header: Text("THE INVITATION")) {
                    Text("What is true in Sufism, sincerity, remembrance, weeping over sin, love of Allah and His Messenger, is all in the Sunnah already, without the additions. The books of Ibn al-Qayyim, especially Madarij as-Salikin and al-Wabil as-Sayyib, take the whole science of the heart and return it to the Quran and the Sunnah. The one who wants Allah finds Him on the road of His Messenger, and the Prophet (peace be upon him) said of that road, in the hadith qudsi:")
                        .font(.body)
                    ScriptureQuote(text: "“If he draws near to Me a hand-span, I draw near to him an arm’s length, and if he draws near to Me an arm’s length, I draw near to him a fathom, and if he comes to Me walking, I come to him running” (Sahih al-Bukhari 7405).", arabic: "وَإِنْ تَقَرَّبَ إِلَىَّ بِشِبْرٍ تَقَرَّبْتُ إِلَيْهِ ذِرَاعًا، وَإِنْ تَقَرَّبَ إِلَىَّ ذِرَاعًا تَقَرَّبْتُ إِلَيْهِ بَاعًا، وَإِنْ أَتَانِي يَمْشِي أَتَيْتُهُ هَرْوَلَةً", dimmed: true)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Purify the heart by the Sunnah, call upon Allah alone, leave the graves as the Prophet left them, and keep every shaykh beneath the text. That is the tazkiyah of the Salaf, and it needs no order.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Sufism")
        .selectableArticleList()
    }
}

struct ShiaAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Shia claim that Ali was appointed by divine text, that the imams are infallible, and that the Companions betrayed the Prophet. The Quran praises the Companions, Ali himself ranked Abu Bakr and Umar above himself, and the imamate is found nowhere among the pillars of Islam.")
                        .font(.body)
                }

                Section(header: Text("WHO ARE THE SHIA?")) {
                    Text("**Shia (شِيعَة)** means “party“: the party of Ali. The largest group, the **Twelvers (الاِثنَا عَشَرِيَّة)**, hold that the Prophet (peace be upon him) appointed Ali as his successor by explicit command, that Ali and eleven of his descendants are infallible imams appointed by Allah, that belief in the imamate is a pillar of the religion, that the twelfth imam went into hiding in 260 AH and is still alive, and that most of the Companions, above all Abu Bakr, Umar, and Aisha, betrayed the Prophet after his death. From these beliefs came the cursing of the Companions, the wailing and self-beating of Ashura, the shrines, temporary marriage (**mut‘ah**), and **taqiyyah**, concealing one’s belief.")
                        .font(.body)

                    Text("**Shi‘ah (شِيعَة)** means a party or a body of followers, from the root ش-ي-ع, to follow, spread, and support. The Quran uses the word for those who follow a man upon his way, saying of Ibrahim that he was of the party of Nuh, and for the sects into which people split (Quran 6:159):")
                        .font(.body)
                    ScriptureQuote(text: "“And indeed, among his kind was Abraham” (Quran 37:83).", arabic: "وَإِنَّ مِن شِيعَتِهِۦ لَإِبۡرَٰهِيمَ")

                    Text("Historically, **Shi‘at Ali**, the party of Ali, was the body of Muslims who stood with Ali (may Allah be pleased with him) at Siffin in 37 AH; it was an alignment in a dispute among Muslims, not a creed, and the Companions who fought beside him, such as Ammar ibn Yasir, whom Umar had appointed governor of Kufah (Sahih al-Bukhari 755), had given bay‘ah to Abu Bakr and Umar and honoured them as Ali did. Only later did the name narrow to those who held that Ali had been appointed by divine text and that whoever preceded him had wronged him.")
                        .font(.body)

                    Text("In the first sense, Ahl as-Sunnah are the true partisans of Ali. They love him and his household because the Prophet (peace be upon him) loved them; they love those whom the Prophet and Ali loved, Abu Bakr, Umar, Uthman, Aisha, and the rest of the Companions; and they do not hate anyone whom the two of them loved. Ali’s own conduct toward Abu Bakr, Umar, and Uthman is set out in section 2 below. A love of Ali that requires hatred of those he loved is not his party. The party that Allah calls successful is defined by faith and by loyalty to Allah and His Messenger, and every Companion and every member of the household is inside it:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah is pleased with them, and they are pleased with Him - those are the party of Allah. Unquestionably, the party of Allah - they are the successful” (Quran 58:22).", arabic: "رَضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُۚ أُوْلَٰٓئِكَ حِزۡبُ ٱللَّهِۚ أَلَآ إِنَّ حِزۡبَ ٱللَّهِ هُمُ ٱلۡمُفۡلِحُونَ")

                    Text("The Salaf called those who reject the Companions the **Rafidah (الرَّافِضَة)**, “the rejecters,“ from ر-ف-ض, to cast off. The name goes back to Zayd ibn Ali ibn al-Husayn (may Allah have mercy on him), the grandson of al-Husayn, who rose against the Umayyads in Kufah in 122 AH. Those who had gathered to him demanded that he disavow Abu Bakr and Umar; he refused and asked Allah’s mercy on them, so they deserted him, and he said, “You have rejected me“ (rafadtumuni). Those who stayed with him became the **Zaydiyyah**, and those who left became the Rafidah. Ibn Taymiyyah (Minhaj as-Sunnah) and Ibn Kathir (al-Bidayah wan-Nihayah, events of 122 AH) record the story, ash-Shahrastani (al-Milal wan-Nihal) records that they cast him off when they learned that he would not disavow the two shaykhs, and al-Ash‘ari (Maqalat al-Islamiyyin) records that the name was given for their rejection of the caliphates of Abu Bakr and Umar. From then on the Salaf counted honouring the Companions and the Ahlul Bayt together as a mark of the Sunnah, and rejecting the Companions as the mark of the Rafidah.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Shia / shi‘ah (شِيعَة)**: from ش-ي-ع, to follow and support: a party of followers, as explained above. In the language every man has his shi‘ah; as a name it came to mean those who hold that the leadership after the Prophet (peace be upon him) belonged to Ali and his descendants by divine text.")
                        .font(.body)

                    Text("**Ahlul Bayt (أَهْل البَيْت)**: “the people of the house“: the household of the Prophet (peace be upon him). The ayah of purification comes in the middle of an address to his wives (Quran 33:32-34), so they are inside it by its context:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah intends only to remove from you the impurity [of sin], O people of the [Prophet's] household, and to purify you with [extensive] purification” (Quran 33:33).", arabic: "إِنَّمَا يُرِيدُ ٱللَّهُ لِيُذۡهِبَ عَنكُمُ ٱلرِّجۡسَ أَهۡلَ ٱلۡبَيۡتِ وَيُطَهِّرَكُمۡ تَطۡهِيرٗا")

                    Text("The Prophet (peace be upon him) then wrapped al-Hasan, al-Husayn, Fatimah, and Ali in his cloak and recited it over them (Sahih Muslim 2424), so they are inside it by his word. Zayd ibn Arqam (may Allah be pleased with him), who heard the sermon at Ghadir Khumm, was asked who the household are, and answered:")
                        .font(.body)
                    ScriptureQuote(text: "“His wives are of his household, but his household are those who are forbidden the sadaqah after him.” He was asked: Who are they? He said: “The family of Ali, the family of Aqil, the family of Ja‘far, and the family of al-Abbas” (Sahih Muslim 2408).", arabic: "نِسَاؤُهُ مِنْ أَهْلِ بَيْتِهِ وَلَكِنْ أَهْلُ بَيْتِهِ مَنْ حُرِمَ الصَّدَقَةَ بَعْدَهُ. قَالَ وَمَنْ هُمْ قَالَ هُمْ آلُ عَلِيٍّ وَآلُ عَقِيلٍ وَآلُ جَعْفَرٍ وَآلُ عَبَّاسٍ", dimmed: true)

                    Text("Ahl as-Sunnah love all of them, the wives and the relatives together, and it is part of their creed.")
                        .font(.body)

                    Text("**Rafidah (الرَّافِضَة)**: “the rejecters,“ from ر-ف-ض: those who rejected Abu Bakr and Umar and deserted Zayd ibn Ali for refusing to disavow them, as explained above. The Salaf used the name for whoever curses the Companions.")
                        .font(.body)

                    Text("**Zaydiyyah (الزَّيْدِيَّة)**: the followers of Zayd ibn Ali (d. 122 AH). They are the closest of the Shia to Ahl as-Sunnah: in the main they accept the caliphates of Abu Bakr and Umar, holding that the less excellent may lead while the more excellent is present, they do not curse the Companions, and they claim neither infallibility nor a hidden imam; their imam is any descendant of Fatimah who is learned and rises openly (ash-Shahrastani, al-Milal wan-Nihal).")
                        .font(.body)

                    Text("**Imamiyyah / Ithna ‘Ashariyyah (الإِمَامِيَّة / الاِثْنَا عَشَرِيَّة)**: “the Twelvers,“ the largest body of the Shia today. Their twelve imams are Ali, al-Hasan, al-Husayn, Ali Zayn al-Abidin, Muhammad al-Baqir, Ja‘far as-Sadiq, Musa al-Kazim, Ali ar-Rida, Muhammad al-Jawad, Ali al-Hadi, al-Hasan al-Askari, and Muhammad ibn al-Hasan, who is said to have gone into occultation as a small child in Samarra in 260 AH. Ahl as-Sunnah honour the first of these as the fourth rightly guided caliph, the next two as the masters of the youth of Paradise, and Zayn al-Abidin, al-Baqir, and as-Sadiq as imams of knowledge and piety whose narrations are in the books of the Sunnah; the dispute is not over loving them but over the claims of divine appointment and infallibility made for them.")
                        .font(.body)

                    Text("**Isma‘iliyyah (الإِسْمَاعِيلِيَّة)**: named after Isma‘il ibn Ja‘far as-Sadiq, who died in his father’s lifetime and whom they hold to be the seventh imam. From them came the Fatimid dynasty that ruled North Africa and Egypt (297-567 AH), and the **Qaramitah** of Bahrayn, who in 317 AH attacked Makkah during the Hajj, slaughtered the pilgrims inside the sanctuary, and carried off the Black Stone, which stayed away from the Ka‘bah for about twenty-two years (Ibn Kathir, al-Bidayah wan-Nihayah, events of 317 AH). Their doctrine of a hidden meaning (batin) behind the texts emptied the shari‘ah of its rulings.")
                        .font(.body)

                    Text("**Nusayriyyah (النُّصَيْرِيَّة)**: named after Muhammad ibn Nusayr (third century AH), who claimed that Ali was divine. They hold Ali to be God made manifest, believe in the transmigration of souls, and keep their doctrine secret from outsiders. Ibn Taymiyyah, asked about them, ruled that they are outside Islam altogether (Majmu‘ al-Fatawa, vol. 35), and no school of the Muslims, Sunni or Shia, counts their creed as Islam.")
                        .font(.body)

                    Text("**Ghulat (غُلَاة)**: “extremists,“ from غ-ل-و, to exceed the bound: those who raised Ali or the imams to divinity or prophethood. The first were the **Saba’iyyah**, the followers of Abdullah ibn Saba’, whom al-Ash‘ari (Maqalat al-Islamiyyin) and ash-Shahrastani (al-Milal wan-Nihal) count as the first of the ghulat. Ali (may Allah be pleased with him) burned a group of these heretics, whom the commentators, including Ibn Hajar in Fath al-Bari, identify as people who had claimed divinity for him, and Ibn Abbas commented:")
                        .font(.body)
                    ScriptureQuote(text: "Ali burnt some people, and the news reached Ibn Abbas, who said: “Had I been in his place I would not have burnt them, as the Prophet said, ‘Do not punish with the punishment of Allah.’ But I would have killed them, for the Prophet said, ‘Whoever has changed his religion, kill him’” (Sahih al-Bukhari 3017).", arabic: "أَنَّ عَلِيًّا ـ رضى الله عنه ـ حَرَّقَ قَوْمًا، فَبَلَغَ ابْنَ عَبَّاسٍ فَقَالَ لَوْ كُنْتُ أَنَا لَمْ أُحَرِّقْهُمْ، لأَنَّ النَّبِيَّ صلى الله عليه وسلم قَالَ لاَ تُعَذِّبُوا بِعَذَابِ اللَّهِ. وَلَقَتَلْتُهُمْ كَمَا قَالَ النَّبِيُّ صلى الله عليه وسلم مَنْ بَدَّلَ دِينَهُ فَاقْتُلُوهُ", dimmed: true)

                    Text("Ali was the first to disown those who exaggerated about him, and the Imami Shia themselves disown the ghulat.")
                        .font(.body)

                    Text("**Imamah (إِمَامَة)**: “leadership.“ For Ahl as-Sunnah the caliphate is a trust established by the choice and pledge of the Muslims for the good of the religion and the people; for the Twelvers it is a pillar of faith, the appointment by Allah of twelve named men, without which faith is incomplete. The pillars the Prophet (peace be upon him) counted are in section 3 below.")
                        .font(.body)

                    Text("**‘Ismah (عِصْمَة)**: “protection“ from sin and error. Ahl as-Sunnah affirm it for the prophets in what they convey from Allah; the Twelvers claim it for the twelve imams and for Fatimah, which makes their words a revelation beside the Quran.")
                        .font(.body)

                    Text("**Ghaybah (غَيْبَة)**: “occultation“: the claim that the twelfth imam has been hidden since 260 AH and will return as the Mahdi. Ahl as-Sunnah believe in a Mahdi from the household of the Prophet (peace be upon him), of the descendants of Fatimah, whose name will be the Prophet’s name and whose father’s name will be his father’s name, and who will fill the earth with justice as it was filled with oppression (Sunan Abi Dawud 4282, graded hasan sahih by al-Albani; Sunan Abi Dawud 4284, graded sahih by al-Albani); that is Muhammad ibn Abdullah, not Muhammad ibn al-Hasan, and not a child hidden for more than a thousand years.")
                        .font(.body)

                    Text("**Raj‘ah (رَجْعَة)**: “return“: the Twelver belief that the imams and their enemies will be brought back to life before the Day of Resurrection so that the imams may take their due. No text of the Quran or the Sunnah mentions it.")
                        .font(.body)

                    Text("**Bada’ (بَدَاء)**: “the appearing of what was hidden“: the belief that Allah decides a matter and then a new view appears to Him; it entered the Shia sources to explain why an expected imam died before his father. Ahl as-Sunnah reject it, because Allah has encompassed all things in knowledge (Quran 65:12) and nothing appears to Him that He did not know.")
                        .font(.body)

                    Text("**Taqiyyah (تَقِيَّة)**: from و-ق-ي, to guard: concealing one’s belief to escape harm. Discussed under Common Questions below.")
                        .font(.body)

                    Text("**Tawalla / tabarra (تَوَلِّي / تَبَرِّي)**: loyalty to the imams and disavowal of their enemies. In Twelver usage the “enemies“ include Abu Bakr, Umar, Uthman, and Aisha, so tabarra becomes a duty of hating the Companions. The loyalty and disavowal of Ahl as-Sunnah is for the sake of Allah toward faith and disbelief, and never between the Companions of one Prophet.")
                        .font(.body)

                    Text("**Mut‘ah (مُتْعَة)**: “enjoyment“: marriage contracted for a fixed period against a payment, ending by itself. Discussed under Common Questions below.")
                        .font(.body)

                    Text("**Ashura and latm (عَاشُورَاء / لَطْم)**: Ashura is the tenth of Muharram, which the Prophet (peace be upon him) fasted and commanded to be fasted in thanks for the deliverance of Musa (Sahih al-Bukhari 2004). Latm means striking the face or chest. The Twelvers made the day a season of mourning for al-Husayn with breast-beating, wailing, and self-wounding, which the Prophet (peace be upon him) disowned in the hadith quoted in section 7.")
                        .font(.body)

                    Text("**Ghadir Khumm (غَدِير خُمّ)**: the pool between Makkah and Madinah where the Prophet (peace be upon him) halted on the way back from the Farewell Hajj and said, “Whoever I am his mawla, then Ali is his mawla“ (Sunan al-Tirmidhi 3713, quoted in section 3), after commanding the people to hold to the Book of Allah and reminding them three times of his household (Sahih Muslim 2408). The Twelvers keep the day as the festival of Ali’s appointment; what was actually said is explained in section 3 and under Common Questions.")
                        .font(.body)

                    Text("**Karbala (كَرْبَلَاء)**: the place in Iraq where al-Husayn ibn Ali (may Allah be pleased with him) was killed on 10 Muharram 61 AH, with most of his family and companions, by the army sent by Ubaydullah ibn Ziyad, the governor of Kufah for Yazid ibn Mu‘awiyah, after the people of Kufah who had invited him abandoned him (Ibn Kathir, al-Bidayah wan-Nihayah, events of 61 AH). Ahl as-Sunnah hold his killing to be one of the gravest crimes in the history of the ummah. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Husayn is from me, and I am from Husayn. Allah loves whoever loves Husayn” (Sunan al-Tirmidhi 3775; graded hasan by al-Albani).", arabic: "حُسَيْنٌ مِنِّي وَأَنَا مِنْ حُسَيْنٍ أَحَبَّ اللَّهُ مَنْ أَحَبَّ حُسَيْنًا", dimmed: true)

                    Text("**Marja‘ (مَرْجِع)**: “the one referred to,“ from ر-ج-ع, to return: in Twelver usage the senior jurist (marja‘ at-taqlid) whom the laity must follow during the occultation. Ahl as-Sunnah ask the people of knowledge (Quran 16:43) but bind themselves absolutely to no one but the Messenger (peace be upon him).")
                        .font(.body)

                    Text("**Sahabi (صَحَابِيّ)**: a Companion: in the definition of Ibn Hajar, whoever met the Prophet (peace be upon him) believing in him and died upon Islam (al-Isabah). Allah’s praise of them is quoted in section 1 below, and no one who met the Prophet in faith and died upon it is outside it.")
                        .font(.body)
                }

                Section(header: Text("1. ALLAH PRAISED THE COMPANIONS")) {
                    Text("Allah (Glorified and Exalted be He) declared Himself pleased with the Companions, in verses revealed while they were alive, knowing what they would do:")
                        .font(.body)
                    ScriptureQuote(text: "“And the first forerunners among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him, and He has prepared for them gardens beneath which rivers flow, wherein they will abide forever. That is the great attainment” (Quran 9:100).", arabic: "وَٱلسَّٰبِقُونَ ٱلۡأَوَّلُونَ مِنَ ٱلۡمُهَٰجِرِينَ وَٱلۡأَنصَارِ وَٱلَّذِينَ ٱتَّبَعُوهُم بِإِحۡسَٰنٖ رَّضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُ")

                    ScriptureQuote(text: "“Certainly was Allah pleased with the believers when they pledged allegiance to you, [O Muhammad], under the tree, and He knew what was in their hearts, so He sent down tranquillity upon them and rewarded them with an imminent conquest” (Quran 48:18).", arabic: "لَّقَدۡ رَضِيَ ٱللَّهُ عَنِ ٱلۡمُؤۡمِنِينَ إِذۡ يُبَايِعُونَكَ تَحۡتَ ٱلشَّجَرَةِ فَعَلِمَ مَا فِي قُلُوبِهِمۡ فَأَنزَلَ ٱلسَّكِينَةَ عَلَيۡهِمۡ وَأَثَٰبَهُمۡ فَتۡحٗا قَرِيبٗا")

                    ScriptureQuote(text: "“Muhammad is the Messenger of Allah; and those with him are forceful against the disbelievers, merciful among themselves. You see them bowing and prostrating [in prayer], seeking bounty from Allah and [His] pleasure” (Quran 48:29).", arabic: "مُّحَمَّدٞ رَّسُولُ ٱللَّهِۚ وَٱلَّذِينَ مَعَهُۥٓ أَشِدَّآءُ عَلَى ٱلۡكُفَّارِ رُحَمَآءُ بَيۡنَهُمۡۖ تَرَىٰهُمۡ رُكَّعٗا سُجَّدٗا يَبۡتَغُونَ فَضۡلٗا مِّنَ ٱللَّهِ وَرِضۡوَٰنٗاۖ")

                    Text("Then He made a share of the war spoils for “those who came after them,“ on the condition that they pray for the Companions and bear no resentment toward them (Quran 59:10). The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not abuse my Companions, for if one of you spent gold the size of Uhud, it would not reach a mudd of one of them, nor half of it” (Sahih al-Bukhari 3673, Sahih Muslim 2541).", arabic: "لاَ تَسُبُّوا أَصْحَابِي، فَلَوْ أَنَّ أَحَدَكُمْ أَنْفَقَ مِثْلَ أُحُدٍ ذَهَبًا مَا بَلَغَ مُدَّ أَحَدِهِمْ وَلاَ نَصِيفَهُ", dimmed: true)

                    ScriptureQuote(text: "“My Companions are a safety for my nation, and when my Companions go, what has been promised to my nation will come to it” (Sahih Muslim 2531).", arabic: "وَأَصْحَابِي أَمَنَةٌ لأُمَّتِي فَإِذَا ذَهَبَ أَصْحَابِي أَتَى أُمَّتِي مَا يُوعَدُونَ", dimmed: true)

                    Text("A claim that these people apostatised is a claim that Allah praised apostates and the Prophet left his religion in the hands of traitors. It is a claim against Allah and His Messenger before it is a claim against the Companions.")
                        .font(.body)
                }

                Section(header: Text("2. ALI HIMSELF ON ABU BAKR AND UMAR")) {
                    Text("The Prophet (peace be upon him) ordered Abu Bakr, and no one else, to lead the prayer in his final illness, repeating the order three times (Sahih al-Bukhari 664, Sahih Muslim 418), and said from the pulpit:")
                        .font(.body)
                    ScriptureQuote(text: "“The person who has favoured me most with his company and his wealth is Abu Bakr. If I were to take a close friend other than my Lord, I would have taken Abu Bakr” (Sahih al-Bukhari 3654, Sahih Muslim 2382).", arabic: "إِنَّ مِنْ أَمَنِّ النَّاسِ عَلَىَّ فِي صُحْبَتِهِ وَمَالِهِ أَبَا بَكْرٍ، وَلَوْ كُنْتُ مُتَّخِذًا خَلِيلاً غَيْرَ رَبِّي لاَتَّخَذْتُ أَبَا بَكْرٍ", dimmed: true)

                    Text("Ali’s own son, Muhammad ibn al-Hanafiyyah, asked him who the best of people was after the Messenger of Allah. Ali said:")
                        .font(.body)
                    ScriptureQuote(text: "“Abu Bakr.” I said: Then who? He said: “Then Umar.” I feared he would say Uthman, so I said: Then you? He said: “I am only a man among the Muslims” (Sahih al-Bukhari 3671).", arabic: "قَالَ أَبُو بَكْرٍ. قُلْتُ ثُمَّ مَنْ قَالَ ثُمَّ عُمَرُ. وَخَشِيتُ أَنْ يَقُولَ عُثْمَانُ قُلْتُ ثُمَّ أَنْتَ قَالَ مَا أَنَا إِلاَّ رَجُلٌ مِنَ الْمُسْلِمِينَ", dimmed: true)

                    Text("Ali gave his daughter Umm Kulthum, the granddaughter of the Prophet (peace be upon him), in marriage to Umar (Sahih al-Bukhari 2881; Sunan al-Nasa’i 1978), and named three of his own sons Abu Bakr, Umar, and Uthman, as the Shia biographers themselves record (al-Mufid, al-Irshad). A man does not marry his daughter to the one who “usurped“ his right and name his children after his enemies.")
                        .font(.body)
                }

                Section(header: Text("3. THE IMAMATE IS NOT A PILLAR")) {
                    Text("If belief in twelve imams were the greatest pillar of the religion, it would be the clearest thing in the Quran and the Sunnah. It is in neither. The Prophet (peace be upon him) counted the pillars:")
                        .font(.body)
                    ScriptureQuote(text: "“Islam is built upon five: the testimony that there is no deity but Allah and that Muhammad is the Messenger of Allah, establishing the prayer, giving zakah, Hajj, and fasting Ramadan” (Sahih al-Bukhari 8, Sahih Muslim 16).", arabic: "بُنِيَ الإِسْلاَمُ عَلَى خَمْسٍ شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَأَنَّ مُحَمَّدًا رَسُولُ اللَّهِ، وَإِقَامِ الصَّلاَةِ، وَإِيتَاءِ الزَّكَاةِ، وَالْحَجِّ، وَصَوْمِ رَمَضَانَ", dimmed: true)

                    Text("And when Jibril asked him about faith, he counted six things (Sahih Muslim 8), none of them an imam. Allah completed the religion (Quran 5:3) without a word about it.")
                        .font(.body)

                    Text("As for the hadith of Ghadir Khumm, the Prophet (peace be upon him) said there, on the way back from the Farewell Hajj after complaints against Ali from the army of Yemen:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever I am his mawla, then Ali is his mawla” (Sunan al-Tirmidhi 3713; graded sahih by al-Albani).", arabic: "مَنْ كُنْتُ مَوْلاَهُ فَعَلِيٌّ مَوْلاَهُ", dimmed: true)

                    Text("**Mawla** means beloved, ally, and supporter, the sense in which Allah is the mawla of the believers (Quran 47:11); it is not the word for ruler, and it was said to defend Ali’s honour, not to appoint him. In the same sermon the Prophet (peace be upon him) commanded holding fast to the Book of Allah and reminded the people of the rights of his household (Sahih Muslim 2408), which Ahl as-Sunnah do. If it had been an appointment, Ali would have said so at Saqifah, and instead he pledged allegiance to Abu Bakr, then Umar, then Uthman, and served under them.")
                        .font(.body)
                }

                Section(header: Text("4. NOBODY IS INFALLIBLE AFTER THE PROPHET")) {
                    Text("The Quran addresses even the Prophet (peace be upon him) with correction:")
                        .font(.body)
                    ScriptureQuote(text: "“The Prophet frowned and turned away because there came to him the blind man, [interrupting]” (Quran 80:1-2).", arabic: "عَبَسَ وَتَوَلَّىٰٓ ۝ أَن جَآءَهُ ٱلۡأَعۡمَىٰ")

                    ScriptureQuote(text: "“O Prophet, why do you prohibit [yourself from] what Allah has made lawful for you, seeking the approval of your wives?” (Quran 66:1).", arabic: "يَٰٓأَيُّهَا ٱلنَّبِيُّ لِمَ تُحَرِّمُ مَآ أَحَلَّ ٱللَّهُ لَكَۖ تَبۡتَغِي مَرۡضَاتَ أَزۡوَٰجِكَۚ وَٱللَّهُ غَفُورٞ رَّحِيمٞ")

                    Text("If the Messenger is corrected by revelation, no one after him is infallible; Ali said of himself, “I am only a man among the Muslims.“ And the idea of a hidden imam, alive for over a thousand years and needed by the religion yet absent from it, has no basis in any text.")
                        .font(.body)
                }

                Section(header: Text("5. AISHA, THE MOTHER OF THE BELIEVERS")) {
                    Text("Allah declared the innocence of Aisha (may Allah be pleased with her) in ten verses of Surat an-Nur when the hypocrites slandered her, and ended:")
                        .font(.body)
                    ScriptureQuote(text: "“Those [good people] are declared innocent of what the slanderers say. For them is forgiveness and noble provision” (Quran 24:26).", arabic: "أُوْلَٰٓئِكَ مُبَرَّءُونَ مِمَّا يَقُولُونَۖ لَهُم مَّغۡفِرَةٞ وَرِزۡقٞ كَرِيمٞ")

                    ScriptureQuote(text: "“The Prophet is more worthy of the believers than themselves, and his wives are [in the position of] their mothers” (Quran 33:6).", arabic: "ٱلنَّبِيُّ أَوۡلَىٰ بِٱلۡمُؤۡمِنِينَ مِنۡ أَنفُسِهِمۡۖ وَأَزۡوَٰجُهُۥٓ أُمَّهَٰتُهُمۡۗ")

                    Text("The Prophet (peace be upon him) died in her house, on her day, leaning against her chest (Sahih al-Bukhari 4449). Whoever curses her curses the mother of the believers, and whoever slanders her has opposed the Quran.")
                        .font(.body)
                }

                Section(header: Text("6. FATIMAH AND THE INHERITANCE")) {
                    Text("The Shia say Abu Bakr wronged Fatimah (may Allah be pleased with her) over the land of Fadak. Abu Bakr applied the Prophet’s own words:")
                        .font(.body)
                    ScriptureQuote(text: "“We are not inherited from; what we leave is charity, but the family of Muhammad may eat from this wealth.” And Abu Bakr said: “By Allah, I will not leave anything I saw the Messenger of Allah doing in it except that I do it” (Sahih al-Bukhari 6725, Sahih Muslim 1759).", arabic: "لاَ نُورَثُ، مَا تَرَكْنَا صَدَقَةٌ، إِنَّمَا يَأْكُلُ آلُ مُحَمَّدٍ مِنْ هَذَا الْمَالِ. قَالَ أَبُو بَكْرٍ وَاللَّهِ لاَ أَدَعُ أَمْرًا رَأَيْتُ رَسُولَ اللَّهِ صلى الله عليه وسلم يَصْنَعُهُ فِيهِ إِلاَّ صَنَعْتُهُ", dimmed: true)

                    Text("Ali and al-Abbas later confirmed to Umar that they knew the Prophet had said this, and when Ali became caliph he did not distribute Fadak as inheritance either. Abu Bakr followed the Sunnah, and Fatimah, a human being, was hurt; the Sunnah is not overturned by that.")
                        .font(.body)
                }

                Section(header: Text("7. MUT'AH, WAILING, AND TAQIYYAH")) {
                    Text("Temporary marriage was forbidden by the Prophet (peace be upon him), and the narrator of its prohibition is Ali himself:")
                        .font(.body)
                    ScriptureQuote(text: "“The Messenger of Allah forbade temporary marriage with women on the day of Khaybar, and the eating of the flesh of domestic donkeys” (Sahih al-Bukhari 5115, Sahih Muslim 1407).", arabic: "إِنَّ النَّبِيَّ صلى الله عليه وسلم نَهَى عَنِ الْمُتْعَةِ وَعَنْ لُحُومِ الْحُمُرِ الأَهْلِيَّةِ زَمَنَ خَيْبَرَ", dimmed: true)

                    Text("The self-beating and wailing of Ashura for al-Husayn (may Allah be pleased with him), whose martyrdom Ahl as-Sunnah grieve as a crime and a tragedy, is what the Prophet (peace be upon him) disowned:")
                        .font(.body)
                    ScriptureQuote(text: "“He is not of us who strikes the cheeks, tears the garments, and calls with the call of the days of ignorance” (Sahih al-Bukhari 1294, Sahih Muslim 103).", arabic: "لَيْسَ مِنَّا مَنْ لَطَمَ الْخُدُودَ، وَشَقَّ الْجُيُوبَ، وَدَعَا بِدَعْوَى الْجَاهِلِيَّةِ", dimmed: true)

                    Text("And the doctrine that concealing one’s belief is a virtue has no place in a religion whose Prophet and Companions proclaimed it under torture; the Quran allows hiding faith only under real compulsion (Quran 16:106).")
                        .font(.body)
                }

                Section(header: Text("8. THE QURAN IS PRESERVED")) {
                    Text("Some classical Twelver sources, including narrations in al-Kulayni’s al-Kafi (2/634), claim the Quran was altered and that the true Quran is with the hidden imam. Ahl as-Sunnah reject this absolutely, and hold every Muslim, Sunni or Shia, to Allah’s promise:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian” (Quran 15:9).", arabic: "إِنَّا نَحۡنُ نَزَّلۡنَا ٱلذِّكۡرَ وَإِنَّا لَهُۥ لَحَٰفِظُونَ")

                    Text("The Quran the Shia recite is the same mushaf Uthman sent to the cities, which shows that the claim is false even by their own practice.")
                        .font(.body)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Do Sunnis love Ali and the Ahlul Bayt?**")
                        .font(.body)
                    Text("Yes, and it is part of the creed, not a courtesy. Ali (may Allah be pleased with him) said that the Prophet (peace be upon him) gave him a promise:")
                        .font(.body)
                    ScriptureQuote(text: "“No one but a believer would love me, and none but a hypocrite would hate me” (Sahih Muslim 78).", arabic: "لاَ يُحِبَّنِي إِلاَّ مُؤْمِنٌ وَلاَ يُبْغِضَنِي إِلاَّ مُنَافِقٌ", dimmed: true)

                    Text("On the eve of the conquest of Khaybar the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Tomorrow I will give this flag to a man through whose hands Allah will give victory. He loves Allah and His Messenger, and Allah and His Messenger love him” (Sahih al-Bukhari 4210).", arabic: "لأُعْطِيَنَّ هَذِهِ الرَّايَةَ غَدًا رَجُلاً، يَفْتَحُ اللَّهُ عَلَى يَدَيْهِ، يُحِبُّ اللَّهَ وَرَسُولَهُ، وَيُحِبُّهُ اللَّهُ وَرَسُولُهُ", dimmed: true)

                    Text("In the morning he called for Ali, prayed for his sore eyes, and gave him the flag. At Ghadir Khumm he said three times, “I remind you of Allah regarding my household“ (Sahih Muslim 2408), and Abu Bakr, the first caliph, lived by it:")
                        .font(.body)
                    ScriptureQuote(text: "Abu Bakr used to say: “Look after Muhammad in his household” (Sahih al-Bukhari 3751).", arabic: "ارْقُبُوا مُحَمَّدًا صلى الله عليه وسلم فِي أَهْلِ بَيْتِهِ", dimmed: true)

                    Text("Of al-Hasan the Prophet (peace be upon him) said from the pulpit:")
                        .font(.body)
                    ScriptureQuote(text: "“This son of mine is a sayyid, and perhaps Allah will bring about peace between two groups of the Muslims through him” (Sahih al-Bukhari 3746).", arabic: "ابْنِي هَذَا سَيِّدٌ، وَلَعَلَّ اللَّهَ أَنْ يُصْلِحَ بِهِ بَيْنَ فِئَتَيْنِ مِنَ الْمُسْلِمِينَ", dimmed: true)
                    ScriptureQuote(text: "“Al-Hasan and al-Husayn are the chiefs of the youths of Paradise” (Sunan al-Tirmidhi 3768; graded sahih by al-Albani).", arabic: "الْحَسَنُ وَالْحُسَيْنُ سَيِّدَا شَبَابِ أَهْلِ الْجَنَّةِ", dimmed: true)

                    Text("Ahl as-Sunnah send blessings on the family of Muhammad in every prayer, and their books of creed name love of the household among the marks of the Sunnah.")
                        .font(.body)

                    Text("**Did the Prophet appoint Ali at Ghadir Khumm?**")
                        .font(.body)
                    Text("No. The words were “Whoever I am his mawla, then Ali is his mawla“ (Sunan al-Tirmidhi 3713, quoted in section 3), said on the way back from the Farewell Hajj after some of the men of the Yemen expedition had complained about Ali (Ibn Kathir, al-Bidayah wan-Nihayah). **Mawla** means beloved, ally, and supporter, and Allah uses the same word for His relation to every believer:")
                        .font(.body)
                    ScriptureQuote(text: "“That is because Allah is the protector of those who have believed and because the disbelievers have no protector” (Quran 47:11).", arabic: "ذَٰلِكَ بِأَنَّ ٱللَّهَ مَوۡلَى ٱلَّذِينَ ءَامَنُواْ وَأَنَّ ٱلۡكَٰفِرِينَ لَا مَوۡلَىٰ لَهُمۡ")

                    Text("Not one Companion who heard it understood a caliphate from it; had it been an appointment, the Muhajirun and Ansar would have raised it at Saqifah, and Ali himself would have. Instead, Ali gave bay‘ah to Abu Bakr (Sahih al-Bukhari 4240), served Umar as his counsellor in Madinah and married his daughter to him, and served Uthman. Ibn Taymiyyah discusses the hadith and its context at length in Minhaj as-Sunnah.")
                        .font(.body)

                    Text("**Why did Ali give bay‘ah to Abu Bakr and serve under the three caliphs?**")
                        .font(.body)
                    Text("Because he believed them to be the rightful caliphs and the best of the ummah after the Prophet (peace be upon him). Aisha relates that after Fatimah’s death Ali sought reconciliation with Abu Bakr, and in the mosque, after the Zuhr prayer:")
                        .font(.body)
                    ScriptureQuote(text: "Ali uttered the tashahhud, magnified the right of Abu Bakr, and related that what he had done was not out of jealousy of Abu Bakr nor denial of that with which Allah had favoured him, “but we used to consider that we had a share in this affair, and he decided it without us, so we felt hurt.” The Muslims were pleased with that and said: You have done right (Sahih al-Bukhari 4240).", arabic: "وَتَشَهَّدَ عَلِيٌّ فَعَظَّمَ حَقَّ أَبِي بَكْرٍ، وَحَدَّثَ أَنَّهُ لَمْ يَحْمِلْهُ عَلَى الَّذِي صَنَعَ نَفَاسَةً عَلَى أَبِي بَكْرٍ، وَلاَ إِنْكَارًا لِلَّذِي فَضَّلَهُ اللَّهُ بِهِ، وَلَكِنَّا نَرَى لَنَا فِي هَذَا الأَمْرِ نَصِيبًا، فَاسْتَبَدَّ عَلَيْنَا، فَوَجَدْنَا فِي أَنْفُسِنَا، فَسُرَّ بِذَلِكَ الْمُسْلِمُونَ وَقَالُوا أَصَبْتَ", dimmed: true)

                    Text("His own ranking, “Abu Bakr, then Umar,“ was quoted in section 2 (Sahih al-Bukhari 3671). A man of Ali’s courage, who feared no one, did not conceal his belief for twenty-five years and then serve as a counsellor and judge under those he thought had usurped him. The claim requires that Ali was either a coward or a hypocrite, and he was neither.")
                        .font(.body)

                    Text("**Did Umar attack Fatimah’s house?**")
                        .font(.body)
                    Text("The story that Umar struck Fatimah, broke her rib, or caused her to miscarry has no chain of narration in the Sahih, the Sunan, or the Musnad, and Ibn Taymiyyah answers the claim in Minhaj as-Sunnah. What is established is the opposite: Umar married Umm Kulthum, the daughter of Ali and Fatimah, and when he distributed garments in Madinah his companions called her “your wife, the daughter of the Messenger of Allah“ (Sahih al-Bukhari 2881); Ibn Umar prayed the funeral prayer over “Umm Kulthum bint Ali, the wife of Umar ibn al-Khattab,“ and her son Zayd together (Sunan an-Nasa’i 1978; graded sahih by al-Albani). Ali also named one of his sons Umar. A father does not give his daughter to the man who broke her mother’s rib.")
                        .font(.body)

                    Text("**Did Abu Bakr wrong Fatimah over Fadak?**")
                        .font(.body)
                    Text("No. He applied the Prophet’s own words, “We are not inherited from; what we leave is charity“ (Sahih al-Bukhari 6725, Sahih Muslim 1759, quoted in section 6), and he maintained the Prophet’s household from that property exactly as the Prophet had done. When Ali met him about it, Abu Bakr wept and said:")
                        .font(.body)
                    ScriptureQuote(text: "“By Him in whose hand is my soul, keeping good relations with the relatives of the Messenger of Allah is dearer to me than keeping good relations with my own relatives” (Sahih al-Bukhari 4240).", arabic: "وَالَّذِي نَفْسِي بِيَدِهِ لَقَرَابَةُ رَسُولِ اللَّهِ صلى الله عليه وسلم أَحَبُّ إِلَىَّ أَنْ أَصِلَ مِنْ قَرَابَتِي", dimmed: true)

                    Text("Ali and al-Abbas later acknowledged the same hadith before Umar (Sahih al-Bukhari 3094, Sahih Muslim 1757), and when Ali became caliph he left Fadak as charity and did not distribute it as inheritance. Fatimah (may Allah be pleased with her) was hurt, and she is honoured for her station; but a hadith of the Prophet is not overturned by anyone’s hurt.")
                        .font(.body)

                    Text("**What do Sunnis say about Karbala and Yazid?**")
                        .font(.body)
                    Text("That al-Husayn (may Allah be pleased with him) was killed unjustly, as a martyr, on 10 Muharram 61 AH by the army of Ubaydullah ibn Ziyad, and that his killing is one of the greatest crimes committed in this ummah. The Prophet (peace be upon him) had said “Husayn is from me, and I am from Husayn“ (Sunan al-Tirmidhi 3775, quoted above). Ahl as-Sunnah grieve for him as the Prophet permitted grief, with sorrow of the heart and tears, and without wailing, striking the cheeks, or tearing the garments (Sahih al-Bukhari 1294, quoted in section 7). As for Yazid ibn Mu‘awiyah, Ibn Taymiyyah records the position of Ahmad ibn Hanbal and the imams: he was a king among the kings of the Muslims, neither loved nor cursed, not a Companion and not one of the righteous, and the crime at Karbala is not excused; but the Muslim does not make cursing a named individual a part of his religion (Majmu‘ al-Fatawa 4/481-484).")
                        .font(.body)

                    Text("**Do the Shia have a different Quran?**")
                        .font(.body)
                    Text("Fairness requires exactness. The Mushaf printed and recited by the Shia is the same Uthmani text, in the same order, as the Mushaf of the Muslims everywhere, and no Shia today produces a different one. But the classical Twelver sources contain narrations claiming that the Quran was altered and that the complete Quran is with the hidden imam, including narrations in al-Kafi (section 8 above), and some of their scholars held to them. Ahl as-Sunnah reject every such claim from any source by the promise of Allah to guard His Book (Quran 15:9, quoted in section 8), and they hold the Shia to the Mushaf in their own hands, which refutes the narrations.")
                        .font(.body)

                    Text("**Is mut‘ah lawful?**")
                        .font(.body)
                    Text("No. It was permitted in the early period, then forbidden. Ali himself narrates its prohibition at Khaybar (Sahih al-Bukhari 5115, Sahih Muslim 1407, quoted in section 7), and Sabrah al-Juhani heard the Prophet (peace be upon him) declare in the year of the conquest of Makkah:")
                        .font(.body)
                    ScriptureQuote(text: "“Behold, it is forbidden from this very day of yours to the Day of Resurrection” (Sahih Muslim 1406).", arabic: "أَلاَ إِنَّهَا حَرَامٌ مِنْ يَوْمِكُمْ هَذَا إِلَى يَوْمِ الْقِيَامَةِ", dimmed: true)

                    Text("A prohibition until the Day of Resurrection, narrated by Ali among others, cannot be revived by anyone. Marriage in Islam is a bond intended to last, with rights of inheritance, lineage, and maintenance that a marriage set to expire does not carry.")
                        .font(.body)

                    Text("**Is taqiyyah part of Islam?**")
                        .font(.body)
                    Text("Only as a concession under real threat to life, not as a way of life. Allah said:")
                        .font(.body)
                    ScriptureQuote(text: "“except for one who is forced [to renounce his religion] while his heart is secure in faith” (Quran 16:106).", arabic: "إِلَّا مَنۡ أُكۡرِهَ وَقَلۡبُهُۥ مُطۡمَئِنُّۢ بِٱلۡإِيمَٰنِ")

                    Text("and He allowed the believer to guard himself against the disbelievers when he is in their power (Quran 3:28). Ibn Kathir records in his tafsir that the ayah of compulsion was revealed about Ammar ibn Yasir under torture in Makkah. It is not permission to conceal one’s creed among Muslims, to swear to what one does not believe, or to teach the religion one way in public and another in private. Concealing belief as a settled practice is what the Prophet (peace be upon him) described as the mark of the hypocrite:")
                        .font(.body)
                    ScriptureQuote(text: "“The signs of a hypocrite are three: whenever he speaks, he tells a lie; whenever he promises, he breaks it; and if you trust him, he proves dishonest” (Sahih al-Bukhari 33).", arabic: "آيَةُ الْمُنَافِقِ ثَلاَثٌ إِذَا حَدَّثَ كَذَبَ، وَإِذَا وَعَدَ أَخْلَفَ، وَإِذَا اؤْتُمِنَ خَانَ", dimmed: true)

                    Text("The Companions proclaimed their faith under the whips of Makkah, and Ali, who is said to have practised taqiyyah for decades, was the boldest of men.")
                        .font(.body)

                    Text("**Do Sunnis reject the fiqh of the Ahlul Bayt?**")
                        .font(.body)
                    Text("No. The imams of the household are imams of Ahl as-Sunnah in hadith and fiqh. Ja‘far as-Sadiq narrates from his father Muhammad al-Baqir from Jabir in Sahih Muslim, and it is Malik, the imam of Madinah, who carries his narration of the Prophet’s tawaf to Muslim (Sahih Muslim 1263); the long hadith of the Prophet’s Hajj comes through the same father and son (Sahih Muslim 1218). Malik recorded him in the Muwatta’, and Abu Hanifah is reported to have said that he had not seen anyone more learned in fiqh than Ja‘far ibn Muhammad (adh-Dhahabi, Siyar A‘lam an-Nubala’). Ali Zayn al-Abidin and Muhammad al-Baqir are narrators in both Sahihs. What Ahl as-Sunnah reject is not the household’s fiqh but the narrations forged in their names, which the imams themselves disowned.")
                        .font(.body)

                    Text("**Are the Shia disbelievers, and may we pray with them?**")
                        .font(.body)
                    Text("Fairness here is a duty. The common Shia are Muslims of Ahl al-Qiblah, who testify to the two testimonies, pray toward the Ka‘bah, and fast Ramadan, and they are judged by their deeds like everyone else; the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever prays our prayer, faces our qiblah, and eats our slaughtered meat is a Muslim, under the protection of Allah and His Messenger” (Sahih al-Bukhari 391).", arabic: "مَنْ صَلَّى صَلاَتَنَا، وَاسْتَقْبَلَ قِبْلَتَنَا، وَأَكَلَ ذَبِيحَتَنَا، فَذَلِكَ الْمُسْلِمُ الَّذِي لَهُ ذِمَّةُ اللَّهِ وَذِمَّةُ رَسُولِهِ", dimmed: true)

                    Text("No specific person is declared a disbeliever without the conditions being met and the obstacles removed, and the scholars warn with the Prophet’s words:")
                        .font(.body)
                    ScriptureQuote(text: "“If a man says to his brother, ‘O disbeliever,’ then surely one of them is such” (Sahih al-Bukhari 6103).", arabic: "إِذَا قَالَ الرَّجُلُ لأَخِيهِ يَا كَافِرُ فَقَدْ بَاءَ بِهِ أَحَدُهُمَا", dimmed: true)

                    Text("But certain beliefs are disbelief by the texts, whoever holds them: deifying Ali or the imams, claiming that the Quran was altered, or accusing Aisha of what Allah declared her innocent of (Quran 24:26, quoted in section 5). The scholars of Ahl as-Sunnah distinguish the ordinary Shia from those who hold these, and prayer behind an imam is judged by what he manifests; the safest course is to pray behind one whose creed is sound, while treating every Muslim with justice and good conduct.")
                        .font(.body)

                    Text("**What about the hadith of the twelve caliphs?**")
                        .font(.body)
                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“This religion will continue to remain powerful and dominant until there have been twelve caliphs… all of them from Quraysh” (Sahih Muslim 1821).", arabic: "لاَ يَزَالُ هَذَا الدِّينُ عَزِيزًا مَنِيعًا إِلَى اثْنَىْ عَشَرَ خَلِيفَةً … كُلُّهُمْ مِنْ قُرَيْشٍ", dimmed: true)

                    Text("The hadith speaks of caliphs under whom the religion is strong and the people are gathered; that describes the rightly guided caliphs and the great caliphs of the Umayyads and early Abbasids, whom the ummah actually united under, as Ibn Kathir explains in his commentary on Quran 5:12. It cannot describe imams of whom only Ali, and al-Hasan for a few months before he made peace, ever ruled, and a twelfth who has been hidden for more than a thousand years, and the hadith makes no mention of Ali’s line, of infallibility, or of an appointment.")
                        .font(.body)

                    Text("**Was Abu Talib a Muslim?**")
                        .font(.body)
                    Text("No. Ahl as-Sunnah honour his protection of the Prophet (peace be upon him) and his defence of him against Quraysh, but the Sahih is explicit that he died on the religion of Abd al-Muttalib, refusing to say la ilaha illa Allah though the Prophet pleaded with him at his deathbed (Sahih al-Bukhari 1360, Sahih Muslim 24), and when al-Abbas asked what his protection had availed him, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“He is in a shallow fire, and had it not been for me, he would have been in the lowest depth of the Fire” (Sahih al-Bukhari 3883).", arabic: "هُوَ فِي ضَحْضَاحٍ مِنْ نَارٍ، وَلَوْلاَ أَنَا لَكَانَ فِي الدَّرَكِ الأَسْفَلِ مِنَ النَّارِ", dimmed: true)

                    Text("The claim that he was a secret believer contradicts these hadiths, one of them reported by his own brother al-Abbas, and it is made only to serve the doctrine that the imams’ ancestors must all have been believers.")
                        .font(.body)

                    Text("**Who are the “Shi‘at Ali“ whom the Quran calls successful?**")
                        .font(.body)
                    Text("The Quran does not speak of a party of Ali; it speaks of the party of Allah (Quran 58:22, quoted above), the people of faith whom Allah is pleased with and who are pleased with Him, and it names among them the first Muhajirun and Ansar (Quran 9:100, quoted in section 1), of whom Ali was one and Abu Bakr and Umar were the foremost. Those who love the Companions and the household together, without cursing anyone the Prophet (peace be upon him) loved, are the party of Allah, and they alone are the true party of Ali.")
                        .font(.body)
                }

                Section(header: Text("THE INVITATION")) {
                    Text("Ahl as-Sunnah love Ali more truly than those who curse his companions in his name. He is the fourth of the rightly guided caliphs, the one of whom the Prophet (peace be upon him) said, “You are to me as Harun was to Musa, except that there is no prophet after me“ (Sahih Muslim 2404), and the husband of Fatimah and father of the two masters of the youth of Paradise. Loving him and loving Abu Bakr, Umar, Uthman, and Aisha are one love, because they loved one another. The Muslim asks for all of them:")
                        .font(.body)
                    ScriptureQuote(text: "“Our Lord, forgive us and our brothers who preceded us in faith and put not in our hearts [any] resentment toward those who have believed. Our Lord, indeed You are Kind and Merciful” (Quran 59:10).", arabic: "رَبَّنَا ٱغۡفِرۡ لَنَا وَلِإِخۡوَٰنِنَا ٱلَّذِينَ سَبَقُونَا بِٱلۡإِيمَٰنِ وَلَا تَجۡعَلۡ فِي قُلُوبِنَا غِلّٗا لِّلَّذِينَ ءَامَنُواْ رَبَّنَآ إِنَّكَ رَءُوفٞ رَّحِيمٌ")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Allah praised the Companions, Ali ranked Abu Bakr and Umar above himself and married his daughter to Umar, no imamate is among the pillars, and no one after the Prophet is infallible. Love of the Ahlul Bayt, which Ahl as-Sunnah share, does not require any of the beliefs built upon it.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering the Shia")
        .selectableArticleList()
    }
}

struct ChristianityAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Muslims honour Isa (Jesus) as one of the greatest messengers, born of a virgin, and reject that he is God, the son of God, or part of a trinity. The Quran, the words of Jesus in the Gospels, and reason all point the same way: Jesus called to the worship of one God.")
                        .font(.body)
                }

                Section(header: Text("WHAT MUSLIMS BELIEVE ABOUT JESUS")) {
                    Text("No Muslim is a Muslim without believing in **Isa ibn Maryam (عِيسَى ابن مَريَم)**: that he is a messenger of Allah and His word, born of the virgin Maryam without a father, that he spoke in the cradle, healed the blind and the leper, and raised the dead by Allah’s permission, that he was neither killed nor crucified but raised alive to heaven, and that he will return before the end of the world. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever testifies that there is no deity but Allah alone with no partner, that Muhammad is His servant and Messenger, that Isa is the servant of Allah and His Messenger and His word which He cast to Maryam and a spirit from Him, and that Paradise is true and the Fire is true, Allah will admit him into Paradise according to his deeds” (Sahih al-Bukhari 3435).", arabic: "مَنْ شَهِدَ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، وَأَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ، وَأَنَّ عِيسَى عَبْدُ اللَّهِ وَرَسُولُهُ وَكَلِمَتُهُ، أَلْقَاهَا إِلَى مَرْيَمَ، وَرُوحٌ مِنْهُ، وَالْجَنَّةُ حَقٌّ وَالنَّارُ حَقٌّ، أَدْخَلَهُ اللَّهُ الْجَنَّةَ عَلَى مَا كَانَ مِنَ الْعَمَلِ", dimmed: true)

                    ScriptureQuote(text: "“And [mention] when the angels said, ‘O Mary, indeed Allah has chosen you and purified you and chosen you above the women of the worlds’” (Quran 3:42).", arabic: "وَإِذۡ قَالَتِ ٱلۡمَلَٰٓئِكَةُ يَٰمَرۡيَمُ إِنَّ ٱللَّهَ ٱصۡطَفَىٰكِ وَطَهَّرَكِ وَٱصۡطَفَىٰكِ عَلَىٰ نِسَآءِ ٱلۡعَٰلَمِينَ")

                    ScriptureQuote(text: "“Both in this world and in the Hereafter, I am the nearest of all the people to Jesus, the son of Mary. The prophets are paternal brothers; their mothers are different, but their religion is one” (Sahih al-Bukhari 3443).", arabic: "أَنَا أَوْلَى النَّاسِ بِعِيسَى ابْنِ مَرْيَمَ فِي الدُّنْيَا وَالآخِرَةِ، وَالأَنْبِيَاءُ إِخْوَةٌ لِعَلاَّتٍ، أُمَّهَاتُهُمْ شَتَّى، وَدِينُهُمْ وَاحِدٌ", dimmed: true)

                    Text("So the disagreement is not about whether to honour Jesus, but about what he was.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Nasara (النَّصَارَى)**: the Quran’s name for the Christians. Ibn Kathir (may Allah have mercy on him) gives two derivations in his tafsir of 2:62: from **an-Nasirah (النَّاصِرَة)**, Nazareth, the town of Jesus, or from **nasr (نَصْر)**, help, because they helped one another, as the disciples answered when Jesus asked who would be his helpers for Allah (Quran 3:52, 61:14):")
                        .font(.body)
                    ScriptureQuote(text: "“The disciples said, ‘We are supporters for Allah. We have believed in Allah and testify that we are Muslims [submitting to Him]’” (Quran 3:52).", arabic: "قَالَ ٱلۡحَوَارِيُّونَ نَحۡنُ أَنصَارُ ٱللَّهِ ءَامَنَّا بِٱللَّهِ وَٱشۡهَدۡ بِأَنَّا مُسۡلِمُونَ")

                    Text("**Ahl al-Kitab (أَهْلُ الكِتَاب)**: “the People of the Scripture,“ the Jews and the Christians, the two communities that received a revealed Book before the Quran. Islam gives them a standing distinct from the idolaters: their slaughtered meat and their chaste women are lawful to Muslims (Quran 5:5), they are to be argued with only in the best manner (Quran 29:46), and yet their doctrines are refuted without apology (Quran 4:171).")
                        .font(.body)

                    Text("**Isa ibn Maryam (عِيسَى ابْنُ مَرْيَم)**: Jesus, the son of Mary. The Quran names him by his mother, a standing reminder that he had no father, and mentions him by name more often than it mentions Muhammad (peace be upon them both). Muslims say “alayhis-salam“ (peace be upon him) after his name as after every prophet.")
                        .font(.body)

                    Text("**Al-Masih (المَسِيح)**: “the Messiah,“ from **masaha (مَسَحَ)**, to wipe or to anoint; the Hebrew mashiah and the Greek christos mean the same, “the anointed one.“ Ibn Kathir notes several explanations of the name, among them that he wiped over the sick and they were healed by Allah’s permission. The Quran confirms that this title belongs to Jesus alone, so a Muslim who says “Messiah“ affirms exactly what the Jews denied:")
                        .font(.body)
                    ScriptureQuote(text: "“O Mary, indeed Allah gives you good tidings of a word from Him, whose name will be the Messiah, Jesus, the son of Mary - distinguished in this world and the Hereafter and among those brought near [to Allah]” (Quran 3:45).", arabic: "يَٰمَرۡيَمُ إِنَّ ٱللَّهَ يُبَشِّرُكِ بِكَلِمَةٖ مِّنۡهُ ٱسۡمُهُ ٱلۡمَسِيحُ عِيسَى ٱبۡنُ مَرۡيَمَ وَجِيهٗا فِي ٱلدُّنۡيَا وَٱلۡأٓخِرَةِ وَمِنَ ٱلۡمُقَرَّبِينَ")

                    Text("**Injil (الإِنْجِيل)**: from the Greek euangelion, “good news“: the revelation Allah gave to Jesus. It is not the same thing as the four Gospels. The Injil of the Quran is what Jesus received and taught, and no copy of it survives in the tongue he spoke:")
                        .font(.body)
                    ScriptureQuote(text: "“and We gave him the Gospel, in which was guidance and light” (Quran 5:46).", arabic: "وَءَاتَيۡنَٰهُ ٱلۡإِنجِيلَ فِيهِ هُدٗى وَنُورٞ")

                    Text("**The Gospels (الأَنَاجِيل)**: Matthew, Mark, Luke and John, the four accounts of Jesus at the start of the New Testament. They were written in Greek by others, decades after him (scholars date them to roughly 65–100 CE), while Jesus spoke Aramaic; their authors do not name themselves, and the titles were attached later. So they are at best reports about Jesus containing some of his words in translation, not the Injil itself. Muslims judge their contents by the Quran: what agrees with it is accepted, what contradicts it is rejected, and the rest is left alone.")
                        .font(.body)

                    Text("**The Bible**: the Old Testament (the Jewish scriptures) and the New Testament (Gospels, Acts, the letters, Revelation). Protestants count 66 books and Catholics 73 (adding the books they call deuterocanonical), and the Orthodox churches count more still. The list itself was fixed by councils of bishops, at Hippo (393 CE) and Carthage (397 CE), and for Catholics finally at Trent (1546 CE). A book whose table of contents was voted on by men centuries after Jesus is not what Islam means by the Injil.")
                        .font(.body)

                    Text("**Paul of Tarsus (بُولُس)**: a Jew of Tarsus who persecuted the followers of Jesus, never met him in his lifetime, and then reported a vision of him on the road to Damascus (Acts 9). Thirteen letters of the New Testament are attributed to him, more than to any other writer, and they, not the words of Jesus, are the source of the doctrines that the death of Jesus atones for sin and that the Law of Moses is no longer binding (Romans 10:4, Galatians 3). Jesus himself said he came to fulfil the Law, not to destroy it (Matthew 5:17). Muslim scholars who examined the Christian texts, such as Ibn Hazm in al-Fisal and Ibn Taymiyyah in al-Jawab as-Sahih, traced the alteration of the religion of the Messiah to those who came after him.")
                        .font(.body)

                    Text("**Trinity (التَّثْلِيث)**: the doctrine that God is one essence in three persons, Father, Son and Holy Spirit. The word is not in the Bible. The doctrine was defined at the Council of Nicaea (325 CE), which declared the Son “of one substance“ with the Father, and completed at the Council of Constantinople (381 CE), which added the Holy Spirit. The Quran names it and rejects it (Quran 4:171, 5:73).")
                        .font(.body)

                    Text("**Incarnation (التَّجَسُّد)**: the belief that God became flesh in Jesus. Islam holds that the Creator does not enter His creation: Jesus was a word from Allah cast to Maryam, a human being who ate food like his mother (Quran 5:75).")
                        .font(.body)

                    Text("**Crucifixion (الصَّلْب)**: Christianity teaches that Jesus was crucified, died, and rose on the third day. The Quran denies that he was killed or crucified: another was made to resemble him, and Allah raised him alive (Quran 4:157-158).")
                        .font(.body)

                    Text("**Atonement and original sin (الفِدَاء والخَطِيئَة الأَصْلِيَّة)**: the doctrine that all mankind inherits the guilt of Adam and can be forgiven only through the sacrifice of the son of God. Islam teaches that Adam repented and was forgiven (Quran 2:37), that no soul bears the burden of another (Quran 6:164), and that Allah forgives whom He wills directly, without a victim (Quran 39:53).")
                        .font(.body)

                    Text("**“Son of God“ (ابْنُ الله)**: in the Bible the phrase is used loosely. Adam is “the son of God“ (Luke 3:38), Israel is God’s “firstborn son“ (Exodus 4:22), David is told “Thou art my Son“ (Psalm 2:7), and the peacemakers “shall be called the children of God“ (Matthew 5:9). It meant a beloved and obedient servant. Later Christians made it literal for Jesus alone, and the Quran rejects that in the strongest terms (Quran 9:30, 19:88-93, 112:1-4).")
                        .font(.body)

                    Text("**The Holy Spirit (رُوحُ القُدُس)**: in the Quran Ruh al-Qudus is the angel Jibril, by whom Allah supported Jesus (Quran 2:87, 5:110) and by whom He sent down the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘The Pure Spirit has brought it down from your Lord in truth to make firm those who believe and as guidance and good tidings to the Muslims’” (Quran 16:102).", arabic: "قُلۡ نَزَّلَهُۥ رُوحُ ٱلۡقُدُسِ مِن رَّبِّكَ بِٱلۡحَقِّ لِيُثَبِّتَ ٱلَّذِينَ ءَامَنُواْ وَهُدٗى وَبُشۡرَىٰ لِلۡمُسۡلِمِينَ")
                    Text("The Prophet (peace be upon him) prayed for the poet Hassan ibn Thabit (may Allah be pleased with him) with the same words, and in another narration named the angel:")
                        .font(.body)
                    ScriptureQuote(text: "“O Hassan, reply on behalf of Allah’s Messenger. O Allah, help him with the Holy Spirit” (Sahih al-Bukhari 453, Sahih Muslim 2485).", arabic: "يَا حَسَّانُ، أَجِبْ عَنْ رَسُولِ اللَّهِ صلى الله عليه وسلم، اللَّهُمَّ أَيِّدْهُ بِرُوحِ الْقُدُسِ", dimmed: true)
                    ScriptureQuote(text: "“Lampoon them, and Jibril is with you” (Sahih al-Bukhari 3213).", arabic: "اهْجُهُمْ ـ أَوْ هَاجِهِمْ ـ وَجِبْرِيلُ مَعَكَ", dimmed: true)
                    Text("So the Holy Spirit is a created angel, not a person of the Godhead.")
                        .font(.body)

                    Text("**Kalimat Allah and Ruh minhu (كَلِمَةُ اللهِ ورُوحٌ مِنْه)**: Jesus is called “His word“ and “a soul from Him“ (Quran 4:171, quoted below). Ibn Kathir explains that he is a word from Allah because he was created by Allah’s word “Be,“ without a father, not because he is a part of Allah’s speech; and “a spirit from Him“ means a spirit created by Him, just as Allah says He subjected to us all that is in the heavens and the earth “from Him“ (Quran 45:13), that is, as His creation, not from His essence. The angel said to Maryam:")
                        .font(.body)
                    ScriptureQuote(text: "“Such is Allah; He creates what He wills. When He decrees a matter, He only says to it, ‘Be,’ and it is” (Quran 3:47).", arabic: "كَذَٰلِكِ ٱللَّهُ يَخۡلُقُ مَا يَشَآءُۚ إِذَا قَضَىٰٓ أَمۡرٗا فَإِنَّمَا يَقُولُ لَهُۥ كُن فَيَكُونُ")

                    Text("**Maryam (مَرْيَم)**: Mary, the daughter of Imran, the only woman named in the Quran, and a surah bears her name. She was chosen above the women of the worlds (Quran 3:42, quoted above), conceived Jesus as a virgin, and is called a supporter of truth (Quran 5:75). Muslims honour her without worshipping her, and the Quran rejects taking her as a deity besides Allah (Quran 5:116):")
                        .font(.body)
                    ScriptureQuote(text: "“She said, ‘How can I have a boy while no man has touched me and I have not been unchaste?’” (Quran 19:20).", arabic: "قَالَتۡ أَنَّىٰ يَكُونُ لِي غُلَٰمٞ وَلَمۡ يَمۡسَسۡنِي بَشَرٞ وَلَمۡ أَكُ بَغِيّٗا")
                    ScriptureQuote(text: "“And [the example of] Mary, the daughter of 'Imran, who guarded her chastity, so We blew into [her garment] through Our angel, and she believed in the words of her Lord and His scriptures and was of the devoutly obedient” (Quran 66:12).", arabic: "وَمَرۡيَمَ ٱبۡنَتَ عِمۡرَٰنَ ٱلَّتِيٓ أَحۡصَنَتۡ فَرۡجَهَا فَنَفَخۡنَا فِيهِ مِن رُّوحِنَا وَصَدَّقَتۡ بِكَلِمَٰتِ رَبِّهَا وَكُتُبِهِۦ وَكَانَتۡ مِنَ ٱلۡقَٰنِتِينَ")

                    Text("**The Hawariyyun (الحَوَارِيُّون)**: the disciples of Jesus, from **hawar (حَوَر)**, whiteness, said to refer to their white garments or to the purity of their hearts. They declared themselves Muslims (Quran 3:52, quoted above), asked Allah for a table from heaven (Quran 5:112-115), and were supported against those who disbelieved (Quran 61:14).")
                        .font(.body)

                    Text("**Arius (آرِيُوس) and the early Christians who denied the Trinity**: Arius (d. 336 CE), a priest of Alexandria, taught that the Son was created and had a beginning, and that the Father alone is God without beginning. His view was condemned at Nicaea, yet for decades afterwards much of the church, and later whole Gothic nations, held it. Before him the Ebionites, described by the church fathers Irenaeus and Eusebius, held Jesus to be a man and not God, kept the Law of Moses, and rejected Paul. The Quran’s account of Jesus was therefore not foreign to early Christianity; it was the side that lost.")
                        .font(.body)

                    Text("**Catholic, Orthodox, Protestant**: the three main branches of Christianity. The Catholic Church under the Pope of Rome and the Eastern Orthodox churches divided in 1054 CE; the Protestants broke from Rome in the Reformation begun by Martin Luther in 1517 CE, rejecting papal authority and holding to the Bible alone. All three affirm the Trinity, the Incarnation, and the Crucifixion; they differ over authority, sacraments, and the saints. Islam’s discussion with them concerns what all three share.")
                        .font(.body)

                    Text("**The “Gospel of Barnabas“**: a book that presents Jesus as foretelling Muhammad by name. Muslims should not rely on it. No manuscript of it older than the sixteenth century is known, it contains historical errors, and it even denies that Jesus is the Messiah, which contradicts the Quran (Quran 3:45). The case of Islam rests on the Quran and the Sunnah, not on disputed books.")
                        .font(.body)
                }

                Section(header: Text("1. JESUS IS NOT GOD")) {
                    ScriptureQuote(text: "“They have certainly disbelieved who say, ‘Allah is the Messiah, the son of Mary’ while the Messiah has said, ‘O Children of Israel, worship Allah, my Lord and your Lord.’ Indeed, he who associates others with Allah - Allah has forbidden him Paradise, and his refuge is the Fire” (Quran 5:72).", arabic: "إِنَّهُۥ مَن يُشۡرِكۡ بِٱللَّهِ فَقَدۡ حَرَّمَ ٱللَّهُ عَلَيۡهِ ٱلۡجَنَّةَ وَمَأۡوَىٰهُ ٱلنَّارُۖ وَمَا لِلظَّٰلِمِينَ مِنۡ أَنصَارٖ")

                    ScriptureQuote(text: "“The Messiah, son of Mary, was not but a messenger; [other] messengers have passed on before him. And his mother was a supporter of truth. They both used to eat food. Look how We make clear to them the signs; then look how they are deluded” (Quran 5:75).", arabic: "مَّا ٱلۡمَسِيحُ ٱبۡنُ مَرۡيَمَ إِلَّا رَسُولٞ قَدۡ خَلَتۡ مِن قَبۡلِهِ ٱلرُّسُلُ وَأُمُّهُۥ صِدِّيقَةٞۖ كَانَا يَأۡكُلَانِ ٱلطَّعَامَۗ ٱنظُرۡ كَيۡفَ نُبَيِّنُ لَهُمُ ٱلۡأٓيَٰتِ ثُمَّ ٱنظُرۡ أَنَّىٰ يُؤۡفَكُونَ")

                    Text("One who eats, sleeps, prays, grows, and dies is a creature. A virgin birth does not make him divine; Adam had neither father nor mother:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, the example of Jesus to Allah is like that of Adam. He created Him from dust; then He said to him, ‘Be,’ and he was” (Quran 3:59).", arabic: "إِنَّ مَثَلَ عِيسَىٰ عِندَ ٱللَّهِ كَمَثَلِ ءَادَمَۖ خَلَقَهُۥ مِن تُرَابٖ ثُمَّ قَالَ لَهُۥ كُن فَيَكُونُ")

                    Text("The Gospels themselves record Jesus praying to God, saying he could do nothing of himself (John 5:30), not knowing the hour that only the Father knows (Mark 13:32), and calling the Father “the only true God“ and himself the one He sent (John 17:3). Nowhere in them does he say “I am God, worship me.“")
                        .font(.body)
                }

                Section(header: Text("2. GOD HAS NO SON")) {
                    ScriptureQuote(text: "“And they say, ‘The Most Merciful has taken [for Himself] a son.’ You have done an atrocious thing. The heavens almost rupture therefrom and the earth splits open and the mountains collapse in devastation that they attribute to the Most Merciful a son. And it is not appropriate for the Most Merciful that He should take a son. There is no one in the heavens and earth but that he comes to the Most Merciful as a servant” (Quran 19:88-93).", arabic: "وَقَالُواْ ٱتَّخَذَ ٱلرَّحۡمَٰنُ وَلَدٗا ۝ لَّقَدۡ جِئۡتُمۡ شَيۡـًٔا إِدّٗا ۝ تَكَادُ ٱلسَّمَٰوَٰتُ يَتَفَطَّرۡنَ مِنۡهُ وَتَنشَقُّ ٱلۡأَرۡضُ وَتَخِرُّ ٱلۡجِبَالُ هَدًّا ۝ أَن دَعَوۡاْ لِلرَّحۡمَٰنِ وَلَدٗا ۝ وَمَا يَنۢبَغِي لِلرَّحۡمَٰنِ أَن يَتَّخِذَ وَلَدًا ۝ إِن كُلُّ مَن فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ إِلَّآ ءَاتِي ٱلرَّحۡمَٰنِ عَبۡدٗا")

                    ScriptureQuote(text: "“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent’” (Quran 112:1-4).", arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ ۝ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ۝ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ")

                    Text("The Quran even records how Jesus himself will answer on the Day of Judgement:")
                        .font(.body)
                    ScriptureQuote(text: "“And [beware the Day] when Allah will say, ‘O Jesus, Son of Mary, did you say to the people, “Take me and my mother as deities besides Allah?”’ He will say, ‘Exalted are You! It was not for me to say that to which I have no right. If I had said it, You would have known it’” (Quran 5:116).", arabic: "وَإِذۡ قَالَ ٱللَّهُ يَٰعِيسَى ٱبۡنَ مَرۡيَمَ ءَأَنتَ قُلۡتَ لِلنَّاسِ ٱتَّخِذُونِي وَأُمِّيَ إِلَٰهَيۡنِ مِن دُونِ ٱللَّهِۖ قَالَ سُبۡحَٰنَكَ مَا يَكُونُ لِيٓ أَنۡ أَقُولَ مَا لَيۡسَ لِي بِحَقٍّۚ إِن كُنتُ قُلۡتُهُۥ فَقَدۡ عَلِمۡتَهُۥۚ")

                    ScriptureQuote(text: "“I said not to them except what You commanded me - to worship Allah, my Lord and your Lord” (Quran 5:117).", arabic: "مَا قُلۡتُ لَهُمۡ إِلَّا مَآ أَمَرۡتَنِي بِهِۦٓ أَنِ ٱعۡبُدُواْ ٱللَّهَ رَبِّي وَرَبَّكُمۡۚ")
                }

                Section(header: Text("3. THE TRINITY")) {
                    ScriptureQuote(text: "“O People of the Scripture, do not commit excess in your religion or say about Allah except the truth. The Messiah, Jesus, the son of Mary, was but a messenger of Allah and His word which He directed to Mary and a soul [created at a command] from Him. So believe in Allah and His messengers. And do not say, ‘Three’; desist - it is better for you. Indeed, Allah is but one God” (Quran 4:171).", arabic: "يَٰٓأَهۡلَ ٱلۡكِتَٰبِ لَا تَغۡلُواْ فِي دِينِكُمۡ وَلَا تَقُولُواْ عَلَى ٱللَّهِ إِلَّا ٱلۡحَقَّۚ إِنَّمَا ٱلۡمَسِيحُ عِيسَى ٱبۡنُ مَرۡيَمَ رَسُولُ ٱللَّهِ وَكَلِمَتُهُۥٓ أَلۡقَىٰهَآ إِلَىٰ مَرۡيَمَ وَرُوحٞ مِّنۡهُۖ فَـَٔامِنُواْ بِٱللَّهِ وَرُسُلِهِۦۖ وَلَا تَقُولُواْ ثَلَٰثَةٌۚ ٱنتَهُواْ خَيۡرٗا لَّكُمۡۚ إِنَّمَا ٱللَّهُ إِلَٰهٞ وَٰحِدٞۖ")

                    ScriptureQuote(text: "“They have certainly disbelieved who say, ‘Allah is the third of three.’ And there is no god except one God” (Quran 5:73).", arabic: "لَّقَدۡ كَفَرَ ٱلَّذِينَ قَالُوٓاْ إِنَّ ٱللَّهَ ثَالِثُ ثَلَٰثَةٖۘ وَمَا مِنۡ إِلَٰهٍ إِلَّآ إِلَٰهٞ وَٰحِدٞۚ")

                    Text("The word “trinity“ is not in the Bible. The doctrine was fixed by councils of bishops at Nicaea in 325 CE and Constantinople in 381 CE, three centuries after Jesus, over the objection of Christians who held that he was created. The commandment Jesus called the first was the one every prophet taught: “Hear, O Israel: the Lord our God, the Lord is one“ (Mark 12:29, quoting Deuteronomy 6:4). Muslims hold to that.")
                        .font(.body)
                }

                Section(header: Text("4. THE CRUCIFIXION AND ORIGINAL SIN")) {
                    ScriptureQuote(text: "“And they did not kill him, nor did they crucify him; but [another] was made to resemble him to them. And indeed, those who differ over it are in doubt about it. They have no knowledge of it except the following of assumption. And they did not kill him, for certain. Rather, Allah raised him to Himself. And ever is Allah Exalted in Might and Wise” (Quran 4:157-158).", arabic: "وَقَوۡلِهِمۡ إِنَّا قَتَلۡنَا ٱلۡمَسِيحَ عِيسَى ٱبۡنَ مَرۡيَمَ رَسُولَ ٱللَّهِ وَمَا قَتَلُوهُ وَمَا صَلَبُوهُ وَلَٰكِن شُبِّهَ لَهُمۡۚ وَإِنَّ ٱلَّذِينَ ٱخۡتَلَفُواْ فِيهِ لَفِي شَكّٖ مِّنۡهُۚ مَا لَهُم بِهِۦ مِنۡ عِلۡمٍ إِلَّا ٱتِّبَاعَ ٱلظَّنِّۚ وَمَا قَتَلُوهُ يَقِينَۢا ۝ بَل رَّفَعَهُ ٱللَّهُ إِلَيۡهِۚ وَكَانَ ٱللَّهُ عَزِيزًا حَكِيمٗا")

                    Text("The doctrine that all mankind inherits Adam’s sin and that God had to sacrifice His son to forgive it contradicts justice and the mercy of Allah. Adam repented and was forgiven (Quran 2:37); no one carries another’s guilt; and Allah forgives whom He wills, without a victim:")
                        .font(.body)
                    ScriptureQuote(text: "“And every soul earns not [blame] except against itself, and no bearer of burdens will bear the burden of another” (Quran 6:164).", arabic: "وَلَا تَكۡسِبُ كُلُّ نَفۡسٍ إِلَّا عَلَيۡهَاۚ وَلَا تَزِرُ وَازِرَةٞ وِزۡرَ أُخۡرَىٰۚ")

                    ScriptureQuote(text: "“Say, ‘O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful’” (Quran 39:53).", arabic: "قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ")
                }

                Section(header: Text("5. JESUS FORETOLD MUHAMMAD")) {
                    ScriptureQuote(text: "“And [mention] when Jesus, the son of Mary, said, ‘O children of Israel, indeed I am the messenger of Allah to you confirming what came before me of the Torah and bringing good tidings of a messenger to come after me, whose name is Ahmad’” (Quran 61:6).", arabic: "وَإِذۡ قَالَ عِيسَى ٱبۡنُ مَرۡيَمَ يَٰبَنِيٓ إِسۡرَٰٓءِيلَ إِنِّي رَسُولُ ٱللَّهِ إِلَيۡكُم مُّصَدِّقٗا لِّمَا بَيۡنَ يَدَيَّ مِنَ ٱلتَّوۡرَىٰةِ وَمُبَشِّرَۢا بِرَسُولٖ يَأۡتِي مِنۢ بَعۡدِي ٱسۡمُهُۥٓ أَحۡمَدُۖ")

                    ScriptureQuote(text: "“Those who follow the Messenger, the unlettered prophet, whom they find written in what they have of the Torah and the Gospel” (Quran 7:157).", arabic: "ٱلَّذِينَ يَتَّبِعُونَ ٱلرَّسُولَ ٱلنَّبِيَّ ٱلۡأُمِّيَّ ٱلَّذِي يَجِدُونَهُۥ مَكۡتُوبًا عِندَهُمۡ فِي ٱلتَّوۡرَىٰةِ وَٱلۡإِنجِيلِ")

                    Text("Jesus promised “another Comforter“ who would abide forever and guide to all truth (John 14:16, 16:13); Moses promised a prophet like himself from the brothers of Israel, the children of Ishmael (Deuteronomy 18:18). And Jesus will return, the Prophet (peace be upon him) said, as a follower of the final revelation:")
                        .font(.body)
                    ScriptureQuote(text: "“By the One in whose hand is my soul, the son of Maryam will soon descend among you as a just ruler; he will break the cross, kill the swine, and abolish the jizyah” (Sahih al-Bukhari 3448, Sahih Muslim 155).", arabic: "وَالَّذِي نَفْسِي بِيَدِهِ، لَيُوشِكَنَّ أَنْ يَنْزِلَ فِيكُمُ ابْنُ مَرْيَمَ حَكَمًا عَدْلاً، فَيَكْسِرَ الصَّلِيبَ، وَيَقْتُلَ الْخِنْزِيرَ، وَيَضَعَ الْجِزْيَةَ", dimmed: true)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Do Muslims believe in Jesus?**")
                        .font(.body)
                    Text("Yes, and it is an article of faith, as the hadith of the testimony quoted above shows (Sahih al-Bukhari 3435): whoever denies Jesus is not a Muslim. Allah commands the believers to say:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O believers], ‘We have believed in Allah and what has been revealed to us and what has been revealed to Abraham and Ishmael and Isaac and Jacob and the Descendants and what was given to Moses and Jesus and what was given to the prophets from their Lord. We make no distinction between any of them, and we are Muslims [in submission] to Him’” (Quran 2:136).", arabic: "قُولُوٓاْ ءَامَنَّا بِٱللَّهِ وَمَآ أُنزِلَ إِلَيۡنَا وَمَآ أُنزِلَ إِلَىٰٓ إِبۡرَٰهِـۧمَ وَإِسۡمَٰعِيلَ وَإِسۡحَٰقَ وَيَعۡقُوبَ وَٱلۡأَسۡبَاطِ وَمَآ أُوتِيَ مُوسَىٰ وَعِيسَىٰ وَمَآ أُوتِيَ ٱلنَّبِيُّونَ مِن رَّبِّهِمۡ لَا نُفَرِّقُ بَيۡنَ أَحَدٖ مِّنۡهُمۡ وَنَحۡنُ لَهُۥ مُسۡلِمُونَ")
                    Text("Muslims believe in his virgin birth, his miracles by Allah’s permission (Quran 3:49), his being raised alive to heaven, and his return. The Quran records his first words, spoken from the cradle, and they are the whole of what Muslims say about him:")
                        .font(.body)
                    ScriptureQuote(text: "“[Jesus] said, ‘Indeed, I am the servant of Allah. He has given me the Scripture and made me a prophet’” (Quran 19:30).", arabic: "قَالَ إِنِّي عَبۡدُ ٱللَّهِ ءَاتَىٰنِيَ ٱلۡكِتَٰبَ وَجَعَلَنِي نَبِيّٗا")

                    Text("**Do Muslims and Christians worship the same God?**")
                        .font(.body)
                    Text("The Creator of the heavens and the earth, the God of Abraham, Moses and Jesus, is one, and Allah commands Muslims to say so to the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(text: "“And our God and your God is one; and we are Muslims [in submission] to Him” (Quran 29:46).", arabic: "وَإِلَٰهُنَا وَإِلَٰهُكُمۡ وَٰحِدٞ وَنَحۡنُ لَهُۥ مُسۡلِمُونَ")
                    Text("But to describe Him as three, or as a man who was born and died, is to misdescribe Him: He neither begets nor is born (Quran 112:3, quoted above). So the object of worship is one, and what Islam corrects is the Christian description of Him. That is why Ibn Taymiyyah (may Allah have mercy on him) titled his great work al-Jawab as-Sahih li man baddala din al-Masih, “the correct answer to those who changed the religion of the Messiah“: the dispute is over what was changed, not over which God.")
                        .font(.body)

                    Text("**Did Jesus ever say “I am God, worship me“?**")
                        .font(.body)
                    Text("No. His own words in the Gospels say the opposite. “I can of mine own self do nothing“ (John 5:30). “My Father is greater than I“ (John 14:28). “Why callest thou me good? there is none good but one, that is, God“ (Mark 10:18). “This is life eternal, that they might know thee the only true God, and Jesus Christ, whom thou hast sent“ (John 17:3). Asked for the first commandment, he answered, “Hear, O Israel; the Lord our God is one Lord“ (Mark 12:29). And he fell on his face and prayed, “not as I will, but as thou wilt“ (Matthew 26:39). No one prays to himself. The Quran records that he commanded the Children of Israel to worship Allah, his Lord and theirs (Quran 5:72, quoted above), and it records what he did say:")
                        .font(.body)
                    ScriptureQuote(text: "“And when Jesus brought clear proofs, he said, ‘I have come to you with wisdom and to make clear to you some of that over which you differ, so fear Allah and obey me. Indeed, Allah is my Lord and your Lord, so worship Him. This is a straight path’” (Quran 43:63-64).", arabic: "وَلَمَّا جَآءَ عِيسَىٰ بِٱلۡبَيِّنَٰتِ قَالَ قَدۡ جِئۡتُكُم بِٱلۡحِكۡمَةِ وَلِأُبَيِّنَ لَكُم بَعۡضَ ٱلَّذِي تَخۡتَلِفُونَ فِيهِۖ فَٱتَّقُواْ ٱللَّهَ وَأَطِيعُونِ ۝ إِنَّ ٱللَّهَ هُوَ رَبِّي وَرَبُّكُمۡ فَٱعۡبُدُوهُۚ هَٰذَا صِرَٰطٞ مُّسۡتَقِيمٞ")
                    Text("And on the Day of Judgement he will disown those who worshipped him (Quran 5:116-117, quoted above).")
                        .font(.body)

                    Text("**Did Jesus die on the cross?**")
                        .font(.body)
                    Text("No. The Quran states that they neither killed nor crucified him, but another was made to resemble him (Quran 4:157-158, quoted above). Allah said to him:")
                        .font(.body)
                    ScriptureQuote(text: "“O Jesus, indeed I will take you and raise you to Myself and purify you from those who disbelieve” (Quran 3:55).", arabic: "يَٰعِيسَىٰٓ إِنِّي مُتَوَفِّيكَ وَرَافِعُكَ إِلَيَّ وَمُطَهِّرُكَ مِنَ ٱلَّذِينَ كَفَرُواْ")
                    Text("Ibn Kathir relates from Ibn Abbas (may Allah be pleased with them) that when the house was surrounded, the likeness of Jesus was cast upon one of his companions, who was taken and crucified while Jesus was raised alive. Even the early history of Christianity shows the disagreement the Quran describes: the church father Irenaeus records that the followers of Basilides, in the second century, held that another man was crucified in his place (Against Heresies 1.24.4). Jesus did not die then; he will return, and the Prophet (peace be upon him) told us what follows:")
                        .font(.body)
                    ScriptureQuote(text: "“He will destroy the Antichrist and will live on the earth for forty years and then he will die. The Muslims will pray over him” (Sunan Abi Dawud 4324; graded sahih by al-Albani).", arabic: "وَيُهْلِكُ الْمَسِيحَ الدَّجَّالَ فَيَمْكُثُ فِي الأَرْضِ أَرْبَعِينَ سَنَةً ثُمَّ يُتَوَفَّى فَيُصَلِّي عَلَيْهِ الْمُسْلِمُونَ", dimmed: true)

                    Text("**Was Jesus the son of God?**")
                        .font(.body)
                    Text("No. The Quran’s rejection of this (Quran 19:88-93 and 112:1-4, quoted above) is reasoned, not merely asserted:")
                        .font(.body)
                    ScriptureQuote(text: "“[He is] Originator of the heavens and the earth. How could He have a son when He does not have a companion and He created all things? And He is, of all things, Knowing” (Quran 6:101).", arabic: "بَدِيعُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ أَنَّىٰ يَكُونُ لَهُۥ وَلَدٞ وَلَمۡ تَكُن لَّهُۥ صَٰحِبَةٞۖ وَخَلَقَ كُلَّ شَيۡءٖۖ وَهُوَ بِكُلِّ شَيۡءٍ عَلِيمٞ")
                    ScriptureQuote(text: "“They say, ‘Allah has taken a son.’ Exalted is He! Rather, to Him belongs whatever is in the heavens and the earth. All are devoutly obedient to Him, Originator of the heavens and the earth. When He decrees a matter, He only says to it, ‘Be,’ and it is” (Quran 2:116-117).", arabic: "وَقَالُواْ ٱتَّخَذَ ٱللَّهُ وَلَدٗاۗ سُبۡحَٰنَهُۥۖ بَل لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ كُلّٞ لَّهُۥ قَٰنِتُونَ ۝ بَدِيعُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ وَإِذَا قَضَىٰٓ أَمۡرٗا فَإِنَّمَا يَقُولُ لَهُۥ كُن فَيَكُونُ")
                    Text("A son requires a mate, a beginning, and a likeness to the father; none of that is possible for the One who created everything. When the Bible calls Adam, Israel, David and the peacemakers sons of God, it means beloved servants, and that is what Jesus was: there is no one in the heavens and the earth but comes to the Most Merciful as a servant (Quran 19:93, quoted above).")
                        .font(.body)

                    Text("**Who was Paul, and why does it matter?**")
                        .font(.body)
                    Text("Paul (Saul of Tarsus) never met Jesus in his lifetime. He persecuted his followers, then reported a vision of him (Acts 9). Thirteen letters of the New Testament are attributed to him, and they, not the words of Jesus, are the source of the doctrines that the death of Jesus atones for sin and that the Law of Moses is finished for believers (Romans 10:4, Galatians 2-3). He clashed with Peter, the chief of the disciples, over whether Gentile converts must keep the Law (Galatians 2:11-14), and the Ebionites, the early Jewish followers of Jesus, rejected him as an apostate from the Law (Irenaeus, Against Heresies 1.26.2). It matters because a religion built on a man who never heard Jesus, and who overrode those who did, is not the religion of Jesus. The Quran describes the pattern:")
                        .font(.body)
                    ScriptureQuote(text: "“And from those who say, ‘We are Christians’ We took their covenant; but they forgot a portion of that of which they were reminded” (Quran 5:14).", arabic: "وَمِنَ ٱلَّذِينَ قَالُوٓاْ إِنَّا نَصَٰرَىٰٓ أَخَذۡنَا مِيثَٰقَهُمۡ فَنَسُواْ حَظّٗا مِّمَّا ذُكِّرُواْ بِهِۦ")

                    Text("**Is the Bible the word of God?**")
                        .font(.body)
                    Text("Muslims believe that Allah revealed the Tawrah to Musa, the Zabur to Dawud and the Injil to Isa, and that the books in circulation today contain some of that revelation mixed with the writing, editing, and translating of men. The Quran says of the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(text: "“So woe to those who write the ‘scripture’ with their own hands, then say, ‘This is from Allah,’ in order to exchange it for a small price” (Quran 2:79).", arabic: "فَوَيۡلٞ لِّلَّذِينَ يَكۡتُبُونَ ٱلۡكِتَٰبَ بِأَيۡدِيهِمۡ ثُمَّ يَقُولُونَ هَٰذَا مِنۡ عِندِ ٱللَّهِ لِيَشۡتَرُواْ بِهِۦ ثَمَنٗا قَلِيلٗاۖ")
                    ScriptureQuote(text: "“And indeed, there is among them a party who alter the Scripture with their tongues so you may think it is from the Scripture, but it is not from the Scripture. And they say, ‘This is from Allah,’ but it is not from Allah. And they speak untruth about Allah while they know” (Quran 3:78).", arabic: "وَإِنَّ مِنۡهُمۡ لَفَرِيقٗا يَلۡوُۥنَ أَلۡسِنَتَهُم بِٱلۡكِتَٰبِ لِتَحۡسَبُوهُ مِنَ ٱلۡكِتَٰبِ وَمَا هُوَ مِنَ ٱلۡكِتَٰبِ وَيَقُولُونَ هُوَ مِنۡ عِندِ ٱللَّهِ وَمَا هُوَ مِنۡ عِندِ ٱللَّهِۖ وَيَقُولُونَ عَلَى ٱللَّهِ ٱلۡكَذِبَ وَهُمۡ يَعۡلَمُونَ")
                    ScriptureQuote(text: "“They distort words from their [proper] usages and have forgotten a portion of that of which they were reminded” (Quran 5:13).", arabic: "يُحَرِّفُونَ ٱلۡكَلِمَ عَن مَّوَاضِعِهِۦ وَنَسُواْ حَظّٗا مِّمَّا ذُكِّرُواْ بِهِۦۚ")
                    Text("The Quran says the same of the Torah: a party of them distorted it after they had understood it (Quran 2:75). The manuscripts confirm it. The last twelve verses of Mark (16:9-20) and the story of the woman taken in adultery (John 7:53-8:11) are absent from the oldest complete manuscripts, Codex Sinaiticus and Codex Vaticanus of the fourth century. The one verse that states the Trinity in so many words (1 John 5:7 in the King James Version) is missing from every early Greek manuscript and is dropped by modern translations. The thousands of surviving manuscripts differ from one another in countless readings, and no original of any book exists. The Quran, by contrast, was memorised and written down in the Prophet’s lifetime, and Allah guaranteed its preservation (Quran 15:9).")
                        .font(.body)

                    Text("**Did Jesus foretell Muhammad?**")
                        .font(.body)
                    Text("Yes, as the Quran states (Quran 61:6 and 7:157, quoted above). Jesus promised “another Comforter“ who would abide forever, “the Spirit of truth,“ who “shall not speak of himself; but whatsoever he shall hear, that shall he speak“ and who “will shew you things to come“ (John 14:16, 16:13). That is the description of a prophet who conveys only what he is given, which is exactly how the Quran describes Muhammad (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“Nor does he speak from [his own] inclination. It is not but a revelation revealed” (Quran 53:3-4).", arabic: "وَمَا يَنطِقُ عَنِ ٱلۡهَوَىٰٓ ۝ إِنۡ هُوَ إِلَّا وَحۡيٞ يُوحَىٰ")
                    Text("The Jews of Jesus’s time were themselves awaiting three figures: the Messiah, Elijah, and “that Prophet“ (John 1:19-21, 25), the prophet like Moses of Deuteronomy 18:18. Ibn al-Qayyim gathered these prophecies in Hidayat al-Hayara fi Ajwibat al-Yahud wan-Nasara, and Ibn Taymiyyah in al-Jawab as-Sahih.")
                        .font(.body)

                    Text("**Do Muslims worship Muhammad?**")
                        .font(.body)
                    Text("No, and Islam forbids it more strictly than any religion forbids anything. Muslims are not “Muhammadans“: they worship Allah alone and follow Muhammad (peace be upon him) as His messenger. Allah commanded him to say:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘I am only a man like you, to whom has been revealed that your god is one God’” (Quran 18:110).", arabic: "قُلۡ إِنَّمَآ أَنَا۠ بَشَرٞ مِّثۡلُكُمۡ يُوحَىٰٓ إِلَيَّ أَنَّمَآ إِلَٰهُكُمۡ إِلَٰهٞ وَٰحِدٞۖ")
                    ScriptureQuote(text: "“Say, ‘I hold not for myself [the power of] benefit or harm, except what Allah has willed’” (Quran 7:188).", arabic: "قُل لَّآ أَمۡلِكُ لِنَفۡسِي نَفۡعٗا وَلَا ضَرًّا إِلَّا مَا شَآءَ ٱللَّهُۚ")
                    Text("He himself forbade what the Christians did with Jesus:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not exaggerate in praising me as the Christians praised the son of Mary, for I am only a slave. So call me the slave of Allah and His Messenger” (Sahih al-Bukhari 3445).", arabic: "لاَ تُطْرُونِي كَمَا أَطْرَتِ النَّصَارَى ابْنَ مَرْيَمَ، فَإِنَّمَا أَنَا عَبْدُهُ، فَقُولُوا عَبْدُ اللَّهِ وَرَسُولُهُ", dimmed: true)
                    ScriptureQuote(text: "“Allah cursed the Jews and the Christians because they took the graves of their Prophets as places for praying” (Sahih al-Bukhari 1330, Sahih Muslim 529).", arabic: "لَعَنَ اللَّهُ الْيَهُودَ وَالنَّصَارَى، اتَّخَذُوا قُبُورَ أَنْبِيَائِهِمْ مَسْجِدًا", dimmed: true)
                    Text("When he died, Abu Bakr (may Allah be pleased with him) stood and said, “Whoever worshipped Muhammad, then Muhammad is dead; but whoever worshipped Allah, then Allah is alive and shall never die,“ and recited (Sahih al-Bukhari 3667):")
                        .font(.body)
                    ScriptureQuote(text: "“Muhammad is not but a messenger. [Other] messengers have passed on before him. So if he was to die or be killed, would you turn back on your heels [to unbelief]?” (Quran 3:144).", arabic: "وَمَا مُحَمَّدٌ إِلَّا رَسُولٞ قَدۡ خَلَتۡ مِن قَبۡلِهِ ٱلرُّسُلُۚ أَفَإِيْن مَّاتَ أَوۡ قُتِلَ ٱنقَلَبۡتُمۡ عَلَىٰٓ أَعۡقَٰبِكُمۡۚ")

                    Text("**Will Jesus return?**")
                        .font(.body)
                    Text("Yes, as the hadith quoted above states (Sahih al-Bukhari 3448, Sahih Muslim 155). He will descend, kill the false messiah (the Dajjal) (Sahih Muslim 2937), break the cross, and rule by the Quran; every Christian and Jew alive will then believe in him as he truly is. The Quran points to this:")
                        .font(.body)
                    ScriptureQuote(text: "“And indeed, Jesus will be [a sign for] knowledge of the Hour, so be not in doubt of it, and follow Me. This is a straight path” (Quran 43:61).", arabic: "وَإِنَّهُۥ لَعِلۡمٞ لِّلسَّاعَةِ فَلَا تَمۡتَرُنَّ بِهَا وَٱتَّبِعُونِۚ هَٰذَا صِرَٰطٞ مُّسۡتَقِيمٞ")
                    ScriptureQuote(text: "“And there is none from the People of the Scripture but that he will surely believe in Jesus before his death. And on the Day of Resurrection he will be against them a witness” (Quran 4:159).", arabic: "وَإِن مِّنۡ أَهۡلِ ٱلۡكِتَٰبِ إِلَّا لَيُؤۡمِنَنَّ بِهِۦ قَبۡلَ مَوۡتِهِۦۖ وَيَوۡمَ ٱلۡقِيَٰمَةِ يَكُونُ عَلَيۡهِمۡ شَهِيدٗا")
                    Text("Ibn Kathir explains, following Ibn Jarir at-Tabari, that “before his death“ means before the death of Jesus: when he returns, the People of the Scripture who remain will believe in him as the servant and messenger of Allah, and Abu Hurayrah (may Allah be pleased with him) recited this very ayah after narrating the hadith of his descent.")
                        .font(.body)

                    Text("**Was Islam spread by the sword?**")
                        .font(.body)
                    Text("No. Faith cannot be compelled, and Allah forbids trying:")
                        .font(.body)
                    ScriptureQuote(text: "“There shall be no compulsion in [acceptance of] the religion. The right course has become clear from the wrong” (Quran 2:256).", arabic: "لَآ إِكۡرَاهَ فِي ٱلدِّينِۖ قَد تَّبَيَّنَ ٱلرُّشۡدُ مِنَ ٱلۡغَيِّۚ")
                    ScriptureQuote(text: "“And had your Lord willed, those on earth would have believed - all of them entirely. Then, [O Muhammad], would you compel the people in order that they become believers?” (Quran 10:99).", arabic: "وَلَوۡ شَآءَ رَبُّكَ لَأٓمَنَ مَن فِي ٱلۡأَرۡضِ كُلُّهُمۡ جَمِيعًاۚ أَفَأَنتَ تُكۡرِهُ ٱلنَّاسَ حَتَّىٰ يَكُونُواْ مُؤۡمِنِينَ")
                    Text("The Prophet’s own practice shows it. The Christians of Najran sent their leaders to Madinah; after debate they declined Islam, made a treaty that left them their religion and their churches, and asked him to send a trustworthy man back with them, and he sent Abu Ubaydah (may Allah be pleased with him) (Sahih al-Bukhari 4380); the terms of the treaty are recorded by Abu Yusuf in Kitab al-Kharaj and al-Baladhuri in Futuh al-Buldan. He forbade the killing of women and children in war (Sahih al-Bukhari 3015) and commanded that the Copts of Egypt be treated well when the Muslims reached them (Sahih Muslim 2543). The assurance of Umar (may Allah be pleased with him) to the Christians of Jerusalem guaranteed their churches and crosses (Tarikh at-Tabari). The ancient churches of Egypt and Syria are still standing and still in use after fourteen centuries of Muslim rule; had Islam been spread by the sword, they would not be. And the lands with the largest Muslim populations today, in the islands and coasts of the East, were reached by merchants and preachers, not by armies. Allah commands:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them. Indeed, Allah loves those who act justly” (Quran 60:8).", arabic: "لَّا يَنۡهَىٰكُمُ ٱللَّهُ عَنِ ٱلَّذِينَ لَمۡ يُقَٰتِلُوكُمۡ فِي ٱلدِّينِ وَلَمۡ يُخۡرِجُوكُم مِّن دِيَٰرِكُمۡ أَن تَبَرُّوهُمۡ وَتُقۡسِطُوٓاْ إِلَيۡهِمۡۚ إِنَّ ٱللَّهَ يُحِبُّ ٱلۡمُقۡسِطِينَ")

                    Text("**Can Muslims eat the food of Christians and marry their women?**")
                        .font(.body)
                    ScriptureQuote(text: "“This day [all] good foods have been made lawful, and the food of those who were given the Scripture is lawful for you and your food is lawful for them. And [lawful in marriage are] chaste women from among the believers and chaste women from among those who were given the Scripture before you” (Quran 5:5).", arabic: "ٱلۡيَوۡمَ أُحِلَّ لَكُمُ ٱلطَّيِّبَٰتُۖ وَطَعَامُ ٱلَّذِينَ أُوتُواْ ٱلۡكِتَٰبَ حِلّٞ لَّكُمۡ وَطَعَامُكُمۡ حِلّٞ لَّهُمۡۖ وَٱلۡمُحۡصَنَٰتُ مِنَ ٱلۡمُؤۡمِنَٰتِ وَٱلۡمُحۡصَنَٰتُ مِنَ ٱلَّذِينَ أُوتُواْ ٱلۡكِتَٰبَ مِن قَبۡلِكُمۡ")
                    Text("Ibn Abbas (may Allah be pleased with them) explained that “their food“ means their slaughtered animals, as al-Bukhari records in the chapter on the slaughter of the People of the Scripture. Pork, wine, and carrion remain forbidden, and the meat must be properly slaughtered, not strangled or beaten to death (Quran 5:3). A Muslim man may marry a chaste Christian woman; she keeps her religion, and their children are raised as Muslims. A Muslim woman may not marry a non-Muslim (Quran 2:221). These rulings show how Islam sees the People of the Scripture: nearer to the Muslims than the idolaters, and called to the truth.")
                        .font(.body)

                    Text("**Are Christians going to Hell?**")
                        .font(.body)
                    Text("Whoever hears the message of Muhammad (peace be upon him) and dies rejecting it is not saved by attributing a son to Allah. The Quran says so of those who call Allah the Messiah or one of three (Quran 5:72-73, quoted above), and adds:")
                        .font(.body)
                    ScriptureQuote(text: "“And whoever desires other than Islam as religion - never will it be accepted from him, and he, in the Hereafter, will be among the losers” (Quran 3:85).", arabic: "وَمَن يَبۡتَغِ غَيۡرَ ٱلۡإِسۡلَٰمِ دِينٗا فَلَن يُقۡبَلَ مِنۡهُ وَهُوَ فِي ٱلۡأٓخِرَةِ مِنَ ٱلۡخَٰسِرِينَ")
                    ScriptureQuote(text: "“By Him in whose hand is the life of Muhammad, he who among the community of Jews or Christians hears about me but does not affirm his belief in that with which I have been sent, and dies in this state, shall be but one of the denizens of Hellfire” (Sahih Muslim 153).", arabic: "وَالَّذِي نَفْسُ مُحَمَّدٍ بِيَدِهِ لاَ يَسْمَعُ بِي أَحَدٌ مِنْ هَذِهِ الأُمَّةِ يَهُودِيٌّ وَلاَ نَصْرَانِيٌّ ثُمَّ يَمُوتُ وَلَمْ يُؤْمِنْ بِالَّذِي أُرْسِلْتُ بِهِ إِلاَّ كَانَ مِنْ أَصْحَابِ النَّارِ", dimmed: true)
                    Text("At the same time the Quran does not treat them as one mass (Quran 3:113). It praises those among the People of the Scripture who believed, and it records what is good in the Christians in particular:")
                        .font(.body)
                    ScriptureQuote(text: "“They are not [all] the same; among the People of the Scripture is a community standing [in obedience], reciting the verses of Allah during periods of the night and prostrating [in prayer]” (Quran 3:113).", arabic: "لَيۡسُواْ سَوَآءٗۗ مِّنۡ أَهۡلِ ٱلۡكِتَٰبِ أُمَّةٞ قَآئِمَةٞ يَتۡلُونَ ءَايَٰتِ ٱللَّهِ ءَانَآءَ ٱلَّيۡلِ وَهُمۡ يَسۡجُدُونَ")
                    ScriptureQuote(text: "“And indeed, among the People of the Scripture are those who believe in Allah and what was revealed to you and what was revealed to them, [being] humbly submissive to Allah. They do not exchange the verses of Allah for a small price. Those will have their reward with their Lord. Indeed, Allah is swift in account” (Quran 3:199).", arabic: "وَإِنَّ مِنۡ أَهۡلِ ٱلۡكِتَٰبِ لَمَن يُؤۡمِنُ بِٱللَّهِ وَمَآ أُنزِلَ إِلَيۡكُمۡ وَمَآ أُنزِلَ إِلَيۡهِمۡ خَٰشِعِينَ لِلَّهِ لَا يَشۡتَرُونَ بِـَٔايَٰتِ ٱللَّهِ ثَمَنٗا قَلِيلًاۚ أُوْلَٰٓئِكَ لَهُمۡ أَجۡرُهُمۡ عِندَ رَبِّهِمۡۗ إِنَّ ٱللَّهَ سَرِيعُ ٱلۡحِسَابِ")
                    ScriptureQuote(text: "“and you will find the nearest of them in affection to the believers those who say, ‘We are Christians.’ That is because among them are priests and monks and because they are not arrogant” (Quran 5:82).", arabic: "وَلَتَجِدَنَّ أَقۡرَبَهُم مَّوَدَّةٗ لِّلَّذِينَ ءَامَنُواْ ٱلَّذِينَ قَالُوٓاْ إِنَّا نَصَٰرَىٰۚ ذَٰلِكَ بِأَنَّ مِنۡهُمۡ قِسِّيسِينَ وَرُهۡبَانٗا وَأَنَّهُمۡ لَا يَسۡتَكۡبِرُونَ")
                    Text("As for the ayah that promises reward to Jews, Christians and Sabians who believed and did righteousness (Quran 2:62), Ibn Kathir explains that it concerns those who followed their own prophet in his time, before the next was sent: after Muhammad (peace be upon him) nothing is accepted except following him, as Ibn Abbas said and as 3:85 makes clear. And Allah does not punish one whom the message never reached:")
                        .font(.body)
                    ScriptureQuote(text: "“And never would We punish until We sent a messenger” (Quran 17:15).", arabic: "وَمَا كُنَّا مُعَذِّبِينَ حَتَّىٰ نَبۡعَثَ رَسُولٗا")
                    Text("So the question is not about a label but about knowing the truth and rejecting it. Judgement of individuals belongs to Allah; the Muslim’s duty is to convey the message with wisdom and good instruction (Quran 16:125).")
                        .font(.body)

                    Text("**What did Jesus actually teach?**")
                        .font(.body)
                    Text("The same religion as every prophet. In the Gospels he named the first commandment as the oneness of God (Mark 12:29); said he came to fulfil the Law of Moses, not to destroy it (Matthew 5:17); prayed with his face to the ground (Matthew 26:39); fasted forty days (Matthew 4:2); was circumcised on the eighth day (Luke 2:21); said “my Father is greater than I“ (John 14:28); greeted his disciples with “Peace be unto you“ (John 20:19); and called God “my Father, and your Father; and my God, and your God“ (John 20:17). A man who prostrates, fasts, keeps the Law, avoids pork, and says that God is greater than himself is recognisably a Muslim. The Quran gives his message:")
                        .font(.body)
                    ScriptureQuote(text: "“And [I have come] confirming what was before me of the Torah and to make lawful for you some of what was forbidden to you. And I have come to you with a sign from your Lord, so fear Allah and obey me. Indeed, Allah is my Lord and your Lord, so worship Him. That is the straight path” (Quran 3:50-51).", arabic: "وَمُصَدِّقٗا لِّمَا بَيۡنَ يَدَيَّ مِنَ ٱلتَّوۡرَىٰةِ وَلِأُحِلَّ لَكُم بَعۡضَ ٱلَّذِي حُرِّمَ عَلَيۡكُمۡۚ وَجِئۡتُكُم بِـَٔايَةٖ مِّن رَّبِّكُمۡ فَٱتَّقُواْ ٱللَّهَ وَأَطِيعُونِ ۝ إِنَّ ٱللَّهَ رَبِّي وَرَبُّكُمۡ فَٱعۡبُدُوهُۚ هَٰذَا صِرَٰطٞ مُّسۡتَقِيمٞ")
                    ScriptureQuote(text: "“and has enjoined upon me prayer and zakah as long as I remain alive” (Quran 19:31).", arabic: "وَأَوۡصَٰنِي بِٱلصَّلَوٰةِ وَٱلزَّكَوٰةِ مَا دُمۡتُ حَيّٗا")

                    Text("**Is “Allah“ a different god from the God of the Bible?**")
                        .font(.body)
                    Text("No. Allah is the Arabic word for God, the one Creator. Arabic-speaking Christians and Jews have always said Allah, and Arabic Bibles use the word on every page; the Prophet’s own father was named Abdullah, servant of Allah, before Islam. The language of Jesus, Aramaic, calls God Alaha, and the Hebrew of the Torah uses Eloah and Elohim, all from the same Semitic root. The Quran itself counts churches and synagogues among the places in which the name of Allah is mentioned:")
                        .font(.body)
                    ScriptureQuote(text: "“And were it not that Allah checks the people, some by means of others, there would have been demolished monasteries, churches, synagogues, and mosques in which the name of Allah is much mentioned” (Quran 22:40).", arabic: "وَلَوۡلَا دَفۡعُ ٱللَّهِ ٱلنَّاسَ بَعۡضَهُم بِبَعۡضٖ لَّهُدِّمَتۡ صَوَٰمِعُ وَبِيَعٞ وَصَلَوَٰتٞ وَمَسَٰجِدُ يُذۡكَرُ فِيهَا ٱسۡمُ ٱللَّهِ كَثِيرٗاۗ")
                    Text("The difference is not the name but the description, and the Muslim invites the Christian to describe Him as Jesus did.")
                        .font(.body)
                }

                Section(header: Text("THE INVITATION")) {
                    ScriptureQuote(text: "“Say, ‘O People of the Scripture, come to a word that is equitable between us and you - that we will not worship except Allah and not associate anything with Him and not take one another as lords instead of Allah.’ But if they turn away, then say, ‘Bear witness that we are Muslims [submitting to Him]’” (Quran 3:64).", arabic: "قُلۡ يَٰٓأَهۡلَ ٱلۡكِتَٰبِ تَعَالَوۡاْ إِلَىٰ كَلِمَةٖ سَوَآءِۭ بَيۡنَنَا وَبَيۡنَكُمۡ أَلَّا نَعۡبُدَ إِلَّا ٱللَّهَ وَلَا نُشۡرِكَ بِهِۦ شَيۡـٔٗا وَلَا يَتَّخِذَ بَعۡضُنَا بَعۡضًا أَرۡبَابٗا مِّن دُونِ ٱللَّهِۚ فَإِن تَوَلَّوۡاْ فَقُولُواْ ٱشۡهَدُواْ بِأَنَّا مُسۡلِمُونَ")

                    Text("The Quran also notes what is good in them, that among them are priests and monks who are not arrogant (Quran 5:82), and commands kindness and justice to those who do not fight the Muslims (Quran 60:8). The Muslim invites the Christian to the religion of Jesus himself: one God, worshipped alone, and His messenger obeyed.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Islam gives Jesus his true place: a mighty messenger and the word of Allah, not God and not His son. He ate food, prayed, and called to the worship of his Lord and ours, and he foretold the one who would come after him.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Christianity")
        .selectableArticleList()
    }
}

struct JudaismAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Muslims believe in Musa (Moses), the Torah, and all the prophets of the Children of Israel. The Quran answers the rejection of Jesus and Muhammad, the changing of the scripture, and the claim of a chosen race, and calls the Jews back to the covenant of their own prophets.")
                        .font(.body)
                }

                Section(header: Text("WHAT MUSLIMS BELIEVE")) {
                    Text("Islam affirms **Musa (مُوسَى)** as one of the five greatest messengers, the **Tawrah (التَّورَاة)** as revelation, and Ibrahim, Ishaq, Ya‘qub, Yusuf, Dawud, Sulayman, and the other prophets of the Children of Israel, and it forbids distinguishing between them:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O believers], ‘We have believed in Allah and what has been revealed to us and what has been revealed to Abraham and Ishmael and Isaac and Jacob and the Descendants and what was given to Moses and Jesus and what was given to the prophets from their Lord. We make no distinction between any of them, and we are Muslims [in submission] to Him’” (Quran 2:136).", arabic: "قُولُوٓاْ ءَامَنَّا بِٱللَّهِ وَمَآ أُنزِلَ إِلَيۡنَا وَمَآ أُنزِلَ إِلَىٰٓ إِبۡرَٰهِـۧمَ وَإِسۡمَٰعِيلَ وَإِسۡحَٰقَ وَيَعۡقُوبَ وَٱلۡأَسۡبَاطِ وَمَآ أُوتِيَ مُوسَىٰ وَعِيسَىٰ وَمَآ أُوتِيَ ٱلنَّبِيُّونَ مِن رَّبِّهِمۡ لَا نُفَرِّقُ بَيۡنَ أَحَدٖ مِّنۡهُمۡ وَنَحۡنُ لَهُۥ مُسۡلِمُونَ")

                    ScriptureQuote(text: "“Indeed, We sent down the Torah, in which was guidance and light” (Quran 5:44).", arabic: "إِنَّآ أَنزَلۡنَا ٱلتَّوۡرَىٰةَ فِيهَا هُدٗى وَنُورٞۚ")

                    Text("When the Prophet (peace be upon him) came to Madinah and found the Jews fasting Ashura for the deliverance of Musa, he said, “We have more right to Musa than you,“ fasted it, and commanded fasting it (Sahih al-Bukhari 2004). Moses is a Muslim’s prophet, mentioned in the Quran more than any other.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Yahud (اليَهُود)**: the Jews. Ibn Kathir (may Allah have mercy on him), in his tafsir of 2:62, relates that the name comes from **hada (هَادَ)**, to return and repent, from the words of Musa’s people, “inna hudna ilayk“ (indeed, we have turned back to You); the commentators also mention **Yahudha (يَهُوذَا)**, Judah, the son of Ya‘qub whose tribe gave its name to the kingdom of Judah and then to the whole people:")
                        .font(.body)
                    ScriptureQuote(text: "“And decree for us in this world [that which is] good and [also] in the Hereafter; indeed, we have turned back to You” (Quran 7:156).", arabic: "وَٱكۡتُبۡ لَنَا فِي هَٰذِهِ ٱلدُّنۡيَا حَسَنَةٗ وَفِي ٱلۡأٓخِرَةِ إِنَّا هُدۡنَآ إِلَيۡكَۚ")

                    Text("**Bani Isra’il (بَنُو إِسْرَائِيل)**: the Children of Israel. Isra’il is the prophet Ya‘qub (Jacob), as the Quran shows when it says that Israel forbade a food upon himself before the Torah was revealed (Quran 3:93); Ibn Kathir notes that the name means “servant of Allah.“ His twelve sons became the twelve tribes, the **asbat (الأَسْبَاط)**:")
                        .font(.body)
                    ScriptureQuote(text: "“And We divided them into twelve descendant tribes [as distinct] nations” (Quran 7:160).", arabic: "وَقَطَّعۡنَٰهُمُ ٱثۡنَتَيۡ عَشۡرَةَ أَسۡبَاطًا أُمَمٗاۚ")

                    Text("**Ahl al-Kitab (أَهْلُ الكِتَاب)**: “the People of the Scripture,“ the Jews and the Christians, who received a revealed Book before the Quran. Islam gives them a standing distinct from the idolaters: their slaughtered meat and their chaste women are lawful to Muslims (Quran 5:5), they are argued with in the best manner (Quran 29:46), and they are invited to the common word of worshipping Allah alone (Quran 3:64, quoted below).")
                        .font(.body)

                    Text("**Tawrah (التَّوْرَاة)**: the Hebrew torah, “instruction“: the revelation given to Musa, in which was guidance and light (Quran 5:44, quoted above). Today “Torah“ names the first five books of the Bible, the Pentateuch (Genesis, Exodus, Leviticus, Numbers, Deuteronomy). These contain much of what was revealed, but they were not all written by Musa: Deuteronomy 34 records his death and burial, says that no one knows his grave “unto this day,“ and speaks of him in the past. This is what the Quran means when it says that a portion was forgotten and that men wrote with their own hands (Quran 5:13, 2:79, quoted below).")
                        .font(.body)

                    Text("**Talmud (التَّلْمُود)**: the “oral law“ of the rabbis: the Mishnah, a code compiled around 200 CE, and the Gemara, the commentary on it completed around 500 CE in the Babylonian Talmud. Rabbinic Judaism is built on it as much as on the Torah. For Muslims it is the opinion of scholars, not revelation, and the Quran warns against turning the words of scholars into law beside Allah’s (Quran 9:31, quoted below).")
                        .font(.body)

                    Text("**Zabur (الزَّبُور)**: from **zabara (زَبَرَ)**, to write; the Book given to Dawud (David), corresponding to the Psalms. The Quran mentions it three times (Quran 4:163, 17:55, 21:105). Muslims hold that Dawud was a prophet and a king, not merely a poet:")
                        .font(.body)
                    ScriptureQuote(text: "“and to David We gave the book [of Psalms]” (Quran 4:163).", arabic: "وَءَاتَيۡنَا دَاوُۥدَ زَبُورٗا")

                    Text("**Ahbar (أَحْبَار) and rabbaniyyun (رَبَّانِيُّون)**: the scholars of the Jews. Ahbar is the plural of **habr (حَبْر)**, a learned man; rabbani is from **rabb (رَبّ)**, one who raises people with knowledge, and the title “rabbi“ comes from the Hebrew rav, master. The Quran honours those who judged by the Tawrah (Quran 5:44, quoted above) and condemns those who concealed the truth and sold it (Quran 5:63, 2:174). It then says of their followers:")
                        .font(.body)
                    ScriptureQuote(text: "“They have taken their scholars and monks as lords besides Allah, and [also] the Messiah, the son of Mary. And they were not commanded except to worship one God; there is no deity except Him” (Quran 9:31).", arabic: "ٱتَّخَذُوٓاْ أَحۡبَارَهُمۡ وَرُهۡبَٰنَهُمۡ أَرۡبَابٗا مِّن دُونِ ٱللَّهِ وَٱلۡمَسِيحَ ٱبۡنَ مَرۡيَمَ وَمَآ أُمِرُوٓاْ إِلَّا لِيَعۡبُدُوٓاْ إِلَٰهٗا وَٰحِدٗاۖ لَّآ إِلَٰهَ إِلَّا هُوَۚ")
                    Text("The Salaf explained that taking scholars as lords does not mean bowing to them; it means obeying them when they made lawful what Allah had forbidden and forbade what He had allowed. Hudhayfah and Ibn Abbas (may Allah be pleased with them) said so, as at-Tabari records in his tafsir, and Ibn Taymiyyah explains it at length in Majmu‘ al-Fatawa. The warning applies to Muslims who do the same with their own scholars.")
                        .font(.body)

                    Text("**Sabbath, as-Sabt (السَّبْت)**: Saturday, the day of rest imposed on Bani Isra’il as part of their covenant, on which they were forbidden to work. The Quran recalls the oath they took, the town by the sea whose people fished on the Sabbath and were punished (Quran 7:163, 2:65), and states that the Sabbath was a test for that people, not a law for all:")
                        .font(.body)
                    ScriptureQuote(text: "“and We said to them, ‘Do not transgress on the sabbath’, and We took from them a solemn covenant” (Quran 4:154).", arabic: "وَقُلۡنَا لَهُمۡ لَا تَعۡدُواْ فِي ٱلسَّبۡتِ وَأَخَذۡنَا مِنۡهُم مِّيثَٰقًا غَلِيظٗا")
                    ScriptureQuote(text: "“The sabbath was only appointed for those who differed over it. And indeed, your Lord will judge between them on the Day of Resurrection concerning that over which they used to differ” (Quran 16:124).", arabic: "إِنَّمَا جُعِلَ ٱلسَّبۡتُ عَلَى ٱلَّذِينَ ٱخۡتَلَفُواْ فِيهِۚ وَإِنَّ رَبَّكَ لَيَحۡكُمُ بَيۡنَهُمۡ يَوۡمَ ٱلۡقِيَٰمَةِ فِيمَا كَانُواْ فِيهِ يَخۡتَلِفُونَ")
                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“We are the last but will be the foremost on the Day of Resurrection, though the former nations were given the Scriptures before us. And this was their day, which was made obligatory for them, but they differed about it. So Allah guided us to it, and all the other people are behind us in this respect: the Jews’ is tomorrow and the Christians’ the day after tomorrow” (Sahih al-Bukhari 876).", arabic: "نَحْنُ الآخِرُونَ السَّابِقُونَ يَوْمَ الْقِيَامَةِ، بَيْدَ أَنَّهُمْ أُوتُوا الْكِتَابَ مِنْ قَبْلِنَا، ثُمَّ هَذَا يَوْمُهُمُ الَّذِي فُرِضَ عَلَيْهِمْ فَاخْتَلَفُوا فِيهِ، فَهَدَانَا اللَّهُ، فَالنَّاسُ لَنَا فِيهِ تَبَعٌ، الْيَهُودُ غَدًا وَالنَّصَارَى بَعْدَ غَدٍ", dimmed: true)
                    Text("Islam’s day is Friday, a day of congregational prayer, not of rest.")
                        .font(.body)

                    Text("**The Messiah, al-Masih (المَسِيح), Hebrew Mashiah**: “the anointed one,“ the king from the line of Dawud whom the Jews awaited. The Quran declares that Isa ibn Maryam was that Messiah, and that the Jews rejected him:")
                        .font(.body)
                    ScriptureQuote(text: "“whose name will be the Messiah, Jesus, the son of Mary - distinguished in this world and the Hereafter and among those brought near [to Allah]” (Quran 3:45).", arabic: "ٱسۡمُهُ ٱلۡمَسِيحُ عِيسَى ٱبۡنُ مَرۡيَمَ وَجِيهٗا فِي ٱلدُّنۡيَا وَٱلۡأٓخِرَةِ وَمِنَ ٱلۡمُقَرَّبِينَ")
                    Text("They still await another, and the Prophet (peace be upon him) warned that a false messiah, al-Masih ad-Dajjal, will come before the Hour and that many of them will follow him:")
                        .font(.body)
                    ScriptureQuote(text: "“The Dajjal would be followed by seventy thousand Jews of Isfahan wearing Persian shawls” (Sahih Muslim 2944).", arabic: "يَتْبَعُ الدَّجَّالَ مِنْ يَهُودِ أَصْبَهَانَ سَبْعُونَ أَلْفًا عَلَيْهِمُ الطَّيَالِسَةُ", dimmed: true)

                    Text("**Bayt al-Maqdis (بَيْتُ المَقْدِس) and the Temple of Sulayman**: “the Holy House,“ the sanctuary of Jerusalem, which the Quran calls **al-Masjid al-Aqsa (المَسْجِدُ الأَقْصَى)**, the farthest mosque. It was the first qiblah of the Muslims and the destination of the Prophet’s night journey:")
                        .font(.body)
                    ScriptureQuote(text: "“Exalted is He who took His Servant by night from al-Masjid al-Haram to al-Masjid al-Aqsa, whose surroundings We have blessed, to show him of Our signs. Indeed, He is the Hearing, the Seeing” (Quran 17:1).", arabic: "سُبۡحَٰنَ ٱلَّذِيٓ أَسۡرَىٰ بِعَبۡدِهِۦ لَيۡلٗا مِّنَ ٱلۡمَسۡجِدِ ٱلۡحَرَامِ إِلَى ٱلۡمَسۡجِدِ ٱلۡأَقۡصَا ٱلَّذِي بَٰرَكۡنَا حَوۡلَهُۥ لِنُرِيَهُۥ مِنۡ ءَايَٰتِنَآۚ إِنَّهُۥ هُوَ ٱلسَّمِيعُ ٱلۡبَصِيرُ")
                    Text("The Prophet (peace be upon him) said it was the second mosque built on earth, forty years after the Ka‘bah (Sahih al-Bukhari 3366), and one of only three mosques to which a journey may be undertaken (Sahih al-Bukhari 1189). The prophet Sulayman (Solomon) built its temple, with the jinn Allah had subjected to him working for him (Quran 34:12-13), and when he finished he asked Allah for three things, among them that whoever came to it only to pray there would leave as free of sin as on the day his mother bore him (Sunan an-Nasa’i 693; graded sahih by al-Albani). The Quran records that the Children of Israel were twice punished for corruption by enemies who entered the sanctuary (Quran 17:4-7). Muslims call the city **al-Quds (القُدْس)**, the Holy.")
                        .font(.body)

                    Text("**The Ark, at-Tabut (التَّابُوت)**: the chest of the covenant of the Bible (Exodus 25), which held relics of the family of Musa and Harun. The Quran mentions its return as the sign of the kingship of Talut (Saul):")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, a sign of his kingship is that the chest will come to you in which is assurance from your Lord and a remnant of what the family of Moses and the family of Aaron had left, carried by the angels” (Quran 2:248).", arabic: "إِنَّ ءَايَةَ مُلۡكِهِۦٓ أَن يَأۡتِيَكُمُ ٱلتَّابُوتُ فِيهِ سَكِينَةٞ مِّن رَّبِّكُمۡ وَبَقِيَّةٞ مِّمَّا تَرَكَ ءَالُ مُوسَىٰ وَءَالُ هَٰرُونَ تَحۡمِلُهُ ٱلۡمَلَٰٓئِكَةُۚ")

                    Text("**Circumcision (الخِتَان) and kosher (الكَاشِير)**: two laws Jews and Muslims share. Circumcision is the covenant of Ibrahim, and the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Abraham did his circumcision with an adze at the age of eighty” (Sahih al-Bukhari 3356).", arabic: "اخْتَتَنَ إِبْرَاهِيمُ ـ عَلَيْهِ السَّلاَمُ ـ وَهْوَ ابْنُ ثَمَانِينَ سَنَةً بِالْقَدُّومِ", dimmed: true)
                    Text("Kosher (Hebrew kasher, “fit“) is the Jewish dietary law: no pork, no blood, animals slaughtered by cutting the throat. The halal of Islam is close to it, which is why Allah made the food of the People of the Scripture lawful (Quran 5:5, quoted below). But some Jewish prohibitions were a punishment specific to them, which Jesus was sent to lift in part (Quran 3:50):")
                        .font(.body)
                    ScriptureQuote(text: "“And to those who are Jews We prohibited every animal of uncloven hoof” (Quran 6:146).", arabic: "وَعَلَى ٱلَّذِينَ هَادُواْ حَرَّمۡنَا كُلَّ ذِي ظُفُرٖۖ")

                    Text("**Samaritans (السَّامِرِيُّون)**: a small community, fewer than a thousand people today, that accepts only the Torah (in its own version, the Samaritan Pentateuch), worships on Mount Gerizim rather than in Jerusalem, and has been at odds with the Jews since ancient times (John 4:9). The Quran names **as-Samiri (السَّامِرِيّ)** as the man who made the calf for Bani Isra’il in the absence of Musa; the exegetes differ on his origin, and some said he was of a tribe of that name:")
                        .font(.body)
                    ScriptureQuote(text: "“[Allah] said, ‘But indeed, We have tried your people after you [departed], and the Samiri has led them astray’” (Quran 20:85).", arabic: "قَالَ فَإِنَّا قَدۡ فَتَنَّا قَوۡمَكَ مِنۢ بَعۡدِكَ وَأَضَلَّهُمُ ٱلسَّامِرِيُّ")

                    Text("**Orthodox, Conservative, Reform**: the main branches of Judaism today. Orthodox Jews hold the written and oral law binding in full; Reform Judaism, begun in nineteenth-century Germany, treats the law as adaptable to modern life; Conservative Judaism stands between them. A Muslim finds the Orthodox nearest to what the Quran describes of the religion of Musa, and all of them further from it than Islam is.")
                        .font(.body)

                    Text("**Isra’iliyyat (الإِسْرَائِيلِيَّات)**: reports taken from Jewish sources that found their way into the books of tafsir and history. The Prophet (peace be upon him) permitted narrating them and forbade taking them as truth:")
                        .font(.body)
                    ScriptureQuote(text: "“Convey from me even a single ayah, and narrate from Bani Isra’il, for there is no harm in that; and whoever tells a lie on me intentionally will surely take his place in the Fire” (Sahih al-Bukhari 3461).", arabic: "بَلِّغُوا عَنِّي وَلَوْ آيَةً، وَحَدِّثُوا عَنْ بَنِي إِسْرَائِيلَ وَلاَ حَرَجَ، وَمَنْ كَذَبَ عَلَىَّ مُتَعَمِّدًا فَلْيَتَبَوَّأْ مَقْعَدَهُ مِنَ النَّارِ", dimmed: true)
                    ScriptureQuote(text: "“Do not believe the People of the Scripture and do not disbelieve them, but say, ‘We believe in Allah and what is revealed to us’” (Sahih al-Bukhari 4485).", arabic: "لاَ تُصَدِّقُوا أَهْلَ الْكِتَابِ وَلاَ تُكَذِّبُوهُمْ، وَقُولُوا آمَنَّا بِاللَّهِ وَمَا أُنْزِلَ الآيَةَ", dimmed: true)
                    Text("Ibn Kathir set out the rule in the introduction to his tafsir: what the Quran and Sunnah confirm is accepted, what they contradict is rejected, and what they are silent about is neither believed nor denied, and it is not narrated as religion.")
                        .font(.body)
                }

                Section(header: Text("1. THE COVENANT AND THE PROPHETS WHO CAME AFTER")) {
                    Text("Allah reminds the Children of Israel of His favour upon them and of the covenant they gave, to believe in what He would send after Musa:")
                        .font(.body)
                    ScriptureQuote(text: "“O Children of Israel, remember My favor which I have bestowed upon you and fulfill My covenant [upon you] that I will fulfill your covenant [from Me], and be afraid of [only] Me. And believe in what I have sent down confirming that which is [already] with you, and be not the first to disbelieve in it” (Quran 2:40-41).", arabic: "يَٰبَنِيٓ إِسۡرَٰٓءِيلَ ٱذۡكُرُواْ نِعۡمَتِيَ ٱلَّتِيٓ أَنۡعَمۡتُ عَلَيۡكُمۡ وَأَوۡفُواْ بِعَهۡدِيٓ أُوفِ بِعَهۡدِكُمۡ وَإِيَّٰيَ فَٱرۡهَبُونِ ۝ وَءَامِنُواْ بِمَآ أَنزَلۡتُ مُصَدِّقٗا لِّمَا مَعَكُمۡ وَلَا تَكُونُوٓاْ أَوَّلَ كَافِرِۭ بِهِۦۖ وَلَا تَشۡتَرُواْ بِـَٔايَٰتِي ثَمَنٗا قَلِيلٗا وَإِيَّٰيَ فَٱتَّقُونِ")

                    ScriptureQuote(text: "“And We did certainly give Moses the Torah and followed up after him with messengers. And We gave Jesus, the son of Mary, clear proofs and supported him with the Pure Spirit. But is it [not] that every time a messenger came to you, [O Children of Israel], with what your souls did not desire, you were arrogant? And a party [of messengers] you denied and another party you killed” (Quran 2:87).", arabic: "وَلَقَدۡ ءَاتَيۡنَا مُوسَى ٱلۡكِتَٰبَ وَقَفَّيۡنَا مِنۢ بَعۡدِهِۦ بِٱلرُّسُلِۖ وَءَاتَيۡنَا عِيسَى ٱبۡنَ مَرۡيَمَ ٱلۡبَيِّنَٰتِ وَأَيَّدۡنَٰهُ بِرُوحِ ٱلۡقُدُسِۗ أَفَكُلَّمَا جَآءَكُمۡ رَسُولُۢ بِمَا لَا تَهۡوَىٰٓ أَنفُسُكُمُ ٱسۡتَكۡبَرۡتُمۡ فَفَرِيقٗا كَذَّبۡتُمۡ وَفَرِيقٗا تَقۡتُلُونَ")

                    Text("Believing in Moses and rejecting Jesus and Muhammad is not faith in God; it is choosing among His messengers:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, those who disbelieve in Allah and His messengers and wish to discriminate between Allah and His messengers and say, ‘We believe in some and disbelieve in others,’ and wish to adopt a way in between - Those are the disbelievers, truly” (Quran 4:150-151).", arabic: "إِنَّ ٱلَّذِينَ يَكۡفُرُونَ بِٱللَّهِ وَرُسُلِهِۦ وَيُرِيدُونَ أَن يُفَرِّقُواْ بَيۡنَ ٱللَّهِ وَرُسُلِهِۦ وَيَقُولُونَ نُؤۡمِنُ بِبَعۡضٖ وَنَكۡفُرُ بِبَعۡضٖ وَيُرِيدُونَ أَن يَتَّخِذُواْ بَيۡنَ ذَٰلِكَ سَبِيلًا ۝ أُوْلَٰٓئِكَ هُمُ ٱلۡكَٰفِرُونَ حَقّٗاۚ وَأَعۡتَدۡنَا لِلۡكَٰفِرِينَ عَذَابٗا مُّهِينٗا")
                }

                Section(header: Text("2. MUHAMMAD IS IN THEIR SCRIPTURE")) {
                    ScriptureQuote(text: "“Those to whom We gave the Scripture know him as they know their own sons. But indeed, a party of them conceal the truth while they know [it]” (Quran 2:146).", arabic: "ٱلَّذِينَ ءَاتَيۡنَٰهُمُ ٱلۡكِتَٰبَ يَعۡرِفُونَهُۥ كَمَا يَعۡرِفُونَ أَبۡنَآءَهُمۡۖ وَإِنَّ فَرِيقٗا مِّنۡهُمۡ لَيَكۡتُمُونَ ٱلۡحَقَّ وَهُمۡ يَعۡلَمُونَ")

                    ScriptureQuote(text: "“Those who follow the Messenger, the unlettered prophet, whom they find written in what they have of the Torah and the Gospel” (Quran 7:157).", arabic: "ٱلَّذِينَ يَتَّبِعُونَ ٱلرَّسُولَ ٱلنَّبِيَّ ٱلۡأُمِّيَّ ٱلَّذِي يَجِدُونَهُۥ مَكۡتُوبًا عِندَهُمۡ فِي ٱلتَّوۡرَىٰةِ وَٱلۡإِنجِيلِ")

                    Text("Moses told his people that God would raise up for them “a prophet from among their brethren, like unto you,“ and put His words in his mouth (Deuteronomy 18:18): the brethren of Israel are the children of Ishmael, and the prophet like Moses, with a law, a nation, and victory, is Muhammad (peace be upon him). The rabbi Abdullah ibn Salam recognised him on sight in Madinah, tested him with questions “that only a prophet knows,“ and declared, “I testify that you are the Messenger of Allah“ (Sahih al-Bukhari 3329).")
                        .font(.body)
                }

                Section(header: Text("3. THE SCRIPTURE WAS CHANGED")) {
                    ScriptureQuote(text: "“So for their breaking of the covenant We cursed them and made their hearts hard. They distort words from their [proper] usages and have forgotten a portion of that of which they were reminded” (Quran 5:13).", arabic: "فَبِمَا نَقۡضِهِم مِّيثَٰقَهُمۡ لَعَنَّٰهُمۡ وَجَعَلۡنَا قُلُوبَهُمۡ قَٰسِيَةٗۖ يُحَرِّفُونَ ٱلۡكَلِمَ عَن مَّوَاضِعِهِۦ وَنَسُواْ حَظّٗا مِّمَّا ذُكِّرُواْ بِهِۦۚ")

                    ScriptureQuote(text: "“So woe to those who write the ‘scripture’ with their own hands, then say, ‘This is from Allah,’ in order to exchange it for a small price” (Quran 2:79).", arabic: "فَوَيۡلٞ لِّلَّذِينَ يَكۡتُبُونَ ٱلۡكِتَٰبَ بِأَيۡدِيهِمۡ ثُمَّ يَقُولُونَ هَٰذَا مِنۡ عِندِ ٱللَّهِ لِيَشۡتَرُواْ بِهِۦ ثَمَنٗا قَلِيلٗاۖ")

                    Text("The Torah of Moses was revelation; the text that exists today was written and edited over centuries by hands after him, as its own scholars acknowledge, and it contains the account of Moses’ death and burial. The Quran, by contrast, is guarded by Allah (Quran 15:9), memorised in full by millions, and unchanged since it was revealed.")
                        .font(.body)
                }

                Section(header: Text("4. NO CHOSEN RACE")) {
                    Text("The Children of Israel were favoured with prophets and revelation, and the Quran says so (Quran 2:47). But favour is a trust, not a bloodline, and nobility before Allah is by faith and righteousness alone:")
                        .font(.body)
                    ScriptureQuote(text: "“O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another. Indeed, the most noble of you in the sight of Allah is the most righteous of you” (Quran 49:13).", arabic: "يَٰٓأَيُّهَا ٱلنَّاسُ إِنَّا خَلَقۡنَٰكُم مِّن ذَكَرٖ وَأُنثَىٰ وَجَعَلۡنَٰكُمۡ شُعُوبٗا وَقَبَآئِلَ لِتَعَارَفُوٓاْۚ إِنَّ أَكۡرَمَكُمۡ عِندَ ٱللَّهِ أَتۡقَىٰكُمۡۚ")

                    ScriptureQuote(text: "“Say, ‘O you who are Jews, if you claim that you are allies of Allah, excluding the [other] people, then wish for death, if you should be truthful’” (Quran 62:6).", arabic: "قُلۡ يَٰٓأَيُّهَا ٱلَّذِينَ هَادُوٓاْ إِن زَعَمۡتُمۡ أَنَّكُمۡ أَوۡلِيَآءُ لِلَّهِ مِن دُونِ ٱلنَّاسِ فَتَمَنَّوُاْ ٱلۡمَوۡتَ إِن كُنتُمۡ صَٰدِقِينَ")

                    Text("Ibrahim, whom both peoples claim, was neither a Jew nor a Christian:")
                        .font(.body)
                    ScriptureQuote(text: "“Abraham was neither a Jew nor a Christian, but he was one inclining toward truth, a Muslim [submitting to Allah]. And he was not of the polytheists. Indeed, the most worthy of Abraham among the people are those who followed him [in submission to Allah] and this prophet, and those who believe [in his message]” (Quran 3:67-68).", arabic: "مَا كَانَ إِبۡرَٰهِيمُ يَهُودِيّٗا وَلَا نَصۡرَانِيّٗا وَلَٰكِن كَانَ حَنِيفٗا مُّسۡلِمٗا وَمَا كَانَ مِنَ ٱلۡمُشۡرِكِينَ ۝ إِنَّ أَوۡلَى ٱلنَّاسِ بِإِبۡرَٰهِيمَ لَلَّذِينَ ٱتَّبَعُوهُ وَهَٰذَا ٱلنَّبِيُّ وَٱلَّذِينَ ءَامَنُواْۗ وَٱللَّهُ وَلِيُّ ٱلۡمُؤۡمِنِينَ")
                }

                Section(header: Text("5. WHAT THE QURAN CONDEMNS AND WHAT IT DOES NOT")) {
                    Text("The Quran’s censure is of those who broke the covenant, killed the prophets, and concealed the truth, not of a people as such. It says of the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(text: "“They are not [all] the same; among the People of the Scripture is a community standing [in obedience], reciting the verses of Allah during periods of the night and prostrating [in prayer]. They believe in Allah and the Last Day, and they enjoin what is right and forbid what is wrong and hasten to good deeds. And those are among the righteous” (Quran 3:113-114).", arabic: "لَيۡسُواْ سَوَآءٗۗ مِّنۡ أَهۡلِ ٱلۡكِتَٰبِ أُمَّةٞ قَآئِمَةٞ يَتۡلُونَ ءَايَٰتِ ٱللَّهِ ءَانَآءَ ٱلَّيۡلِ وَهُمۡ يَسۡجُدُونَ ۝ يُؤۡمِنُونَ بِٱللَّهِ وَٱلۡيَوۡمِ ٱلۡأٓخِرِ وَيَأۡمُرُونَ بِٱلۡمَعۡرُوفِ وَيَنۡهَوۡنَ عَنِ ٱلۡمُنكَرِ وَيُسَٰرِعُونَ فِي ٱلۡخَيۡرَٰتِۖ وَأُوْلَٰٓئِكَ مِنَ ٱلصَّٰلِحِينَ")

                    Text("Jews who accepted Islam, such as Abdullah ibn Salam, are among the Companions, and the Prophet (peace be upon him) dealt justly with the Jews of Madinah by treaty, and Umar made fulfilling Allah’s covenant with the People of the Scripture part of his final advice (Sahih al-Bukhari 3162).")
                        .font(.body)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Do Muslims believe in Moses and the Torah?**")
                        .font(.body)
                    Text("Yes, as the ayah of faith in all the prophets (Quran 2:136, quoted above) and the Prophet’s fasting of Ashura for the deliverance of Musa (Sahih al-Bukhari 2004) show. Musa is one of the five messengers of firm resolve, and Allah honoured him by speaking to him directly:")
                        .font(.body)
                    ScriptureQuote(text: "“And Allah spoke to Moses with [direct] speech” (Quran 4:164).", arabic: "وَكَلَّمَ ٱللَّهُ مُوسَىٰ تَكۡلِيمٗا")
                    ScriptureQuote(text: "“And [recall] when We gave Moses the Scripture and criterion that perhaps you would be guided” (Quran 2:53).", arabic: "وَإِذۡ ءَاتَيۡنَا مُوسَى ٱلۡكِتَٰبَ وَٱلۡفُرۡقَانَ لَعَلَّكُمۡ تَهۡتَدُونَ")
                    Text("When a Muslim struck a Jew who had sworn by the one who preferred Musa over all people, the Prophet (peace be upon him) rebuked the Muslim:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not give me superiority over Moses, for on the Day of Resurrection all the people will fall unconscious and I will be one of them, but I will be the first to gain consciousness, and will see Moses standing and holding the side of the Throne” (Sahih al-Bukhari 2411).", arabic: "لاَ تُخَيِّرُونِي عَلَى مُوسَى، فَإِنَّ النَّاسَ يَصْعَقُونَ يَوْمَ الْقِيَامَةِ، فَأَصْعَقُ مَعَهُمْ، فَأَكُونُ أَوَّلَ مَنْ يُفِيقُ، فَإِذَا مُوسَى بَاطِشٌ جَانِبَ الْعَرْشِ", dimmed: true)

                    Text("**Are the Jews the chosen people?**")
                        .font(.body)
                    Text("Allah did favour Bani Isra’il in their time, with prophets, revelation, and kingdom, and the Quran says so plainly, twice in the same surah (Quran 2:47, 2:122):")
                        .font(.body)
                    ScriptureQuote(text: "“O Children of Israel, remember My favor that I have bestowed upon you and that I preferred you over the worlds” (Quran 2:47).", arabic: "يَٰبَنِيٓ إِسۡرَٰٓءِيلَ ٱذۡكُرُواْ نِعۡمَتِيَ ٱلَّتِيٓ أَنۡعَمۡتُ عَلَيۡكُمۡ وَأَنِّي فَضَّلۡتُكُمۡ عَلَى ٱلۡعَٰلَمِينَ")
                    ScriptureQuote(text: "“And We did certainly give the Children of Israel the Scripture and judgement and prophethood, and We provided them with good things and preferred them over the worlds” (Quran 45:16).", arabic: "وَلَقَدۡ ءَاتَيۡنَا بَنِيٓ إِسۡرَٰٓءِيلَ ٱلۡكِتَٰبَ وَٱلۡحُكۡمَ وَٱلنُّبُوَّةَ وَرَزَقۡنَٰهُم مِّنَ ٱلطَّيِّبَٰتِ وَفَضَّلۡنَٰهُمۡ عَلَى ٱلۡعَٰلَمِينَ")
                    Text("But the favour was a trust, conditional on the covenant, and the covenant never included the wrongdoers. When Ibrahim asked that leadership be for his descendants:")
                        .font(.body)
                    ScriptureQuote(text: "“[Allah] said, ‘My covenant does not include the wrongdoers’” (Quran 2:124).", arabic: "قَالَ لَا يَنَالُ عَهۡدِي ٱلظَّٰلِمِينَ")
                    Text("When they claimed to be Allah’s children and beloved:")
                        .font(.body)
                    ScriptureQuote(text: "“But the Jews and the Christians say, ‘We are the children of Allah and His beloved.’ Say, ‘Then why does He punish you for your sins?’ Rather, you are human beings from among those He has created” (Quran 5:18).", arabic: "وَقَالَتِ ٱلۡيَهُودُ وَٱلنَّصَٰرَىٰ نَحۡنُ أَبۡنَٰٓؤُاْ ٱللَّهِ وَأَحِبَّٰٓؤُهُۥۚ قُلۡ فَلِمَ يُعَذِّبُكُم بِذُنُوبِكُمۖ بَلۡ أَنتُم بَشَرٞ مِّمَّنۡ خَلَقَۚ")
                    Text("Nobility before Allah is by piety (Quran 49:13, quoted above), and the nation Allah calls the best is defined by what it does, not by whose son it is:")
                        .font(.body)
                    ScriptureQuote(text: "“You are the best nation produced [as an example] for mankind. You enjoin what is right and forbid what is wrong and believe in Allah” (Quran 3:110).", arabic: "كُنتُمۡ خَيۡرَ أُمَّةٍ أُخۡرِجَتۡ لِلنَّاسِ تَأۡمُرُونَ بِٱلۡمَعۡرُوفِ وَتَنۡهَوۡنَ عَنِ ٱلۡمُنكَرِ وَتُؤۡمِنُونَ بِٱللَّهِۗ")

                    Text("**Is Islam anti-Jewish?**")
                        .font(.body)
                    Text("No. The Quran’s censure is of deeds, breaking covenants, killing prophets, concealing the truth, and taking usury (Quran 4:161), and it praises the believers among the People of the Scripture in the same breath (Quran 3:113-114, quoted above):")
                        .font(.body)
                    ScriptureQuote(text: "“And indeed, among the People of the Scripture are those who believe in Allah and what was revealed to you and what was revealed to them, [being] humbly submissive to Allah. They do not exchange the verses of Allah for a small price. Those will have their reward with their Lord. Indeed, Allah is swift in account” (Quran 3:199).", arabic: "وَإِنَّ مِنۡ أَهۡلِ ٱلۡكِتَٰبِ لَمَن يُؤۡمِنُ بِٱللَّهِ وَمَآ أُنزِلَ إِلَيۡكُمۡ وَمَآ أُنزِلَ إِلَيۡهِمۡ خَٰشِعِينَ لِلَّهِ لَا يَشۡتَرُونَ بِـَٔايَٰتِ ٱللَّهِ ثَمَنٗا قَلِيلًاۚ أُوْلَٰٓئِكَ لَهُمۡ أَجۡرُهُمۡ عِندَ رَبِّهِمۡۗ إِنَّ ٱللَّهَ سَرِيعُ ٱلۡحِسَابِ")
                    Text("Even the ayah that describes the Jews of the Prophet’s time as the most hostile of people to the believers (Quran 5:82) is a report of conduct, not a verdict on descent, which is why the same Quran excepts those among them who believe (Quran 3:113-114). The Prophet’s own life settles the matter. Anas (may Allah be pleased with him) narrated:")
                        .font(.body)
                    ScriptureQuote(text: "“A young Jewish boy used to serve the Prophet, and he became sick. So the Prophet went to visit him. He sat near his head and asked him to embrace Islam. The boy looked at his father, who was sitting there, and he told him to obey Abul-Qasim, and the boy embraced Islam. The Prophet came out saying, ‘Praise be to Allah who saved him from the Fire’” (Sahih al-Bukhari 1356).", arabic: "كَانَ غُلاَمٌ يَهُودِيٌّ يَخْدُمُ النَّبِيَّ صلى الله عليه وسلم فَمَرِضَ، فَأَتَاهُ النَّبِيُّ صلى الله عليه وسلم يَعُودُهُ، فَقَعَدَ عِنْدَ رَأْسِهِ فَقَالَ لَهُ أَسْلِمْ. فَنَظَرَ إِلَى أَبِيهِ وَهْوَ عِنْدَهُ فَقَالَ لَهُ أَطِعْ أَبَا الْقَاسِمِ صلى الله عليه وسلم. فَأَسْلَمَ، فَخَرَجَ النَّبِيُّ صلى الله عليه وسلم وَهْوَ يَقُولُ الْحَمْدُ لِلَّهِ الَّذِي أَنْقَذَهُ مِنَ النَّارِ", dimmed: true)
                    ScriptureQuote(text: "“Allah’s Messenger died while his armour was mortgaged to a Jew for thirty sa‘ of barley” (Sahih al-Bukhari 2916).", arabic: "تُوُفِّيَ رَسُولُ اللَّهِ صلى الله عليه وسلم وَدِرْعُهُ مَرْهُونَةٌ عِنْدَ يَهُودِيٍّ بِثَلاَثِينَ صَاعًا مِنْ شَعِيرٍ", dimmed: true)
                    ScriptureQuote(text: "“A funeral procession passed in front of the Prophet and he stood up. When he was told that it was the funeral of a Jew, he said, ‘Is it not a soul?’” (Sahih al-Bukhari 1312, Sahih Muslim 961).", arabic: "إِنَّ النَّبِيَّ صلى الله عليه وسلم مَرَّتْ بِهِ جَنَازَةٌ فَقَامَ فَقِيلَ لَهُ إِنَّهَا جَنَازَةُ يَهُودِيٍّ. فَقَالَ أَلَيْسَتْ نَفْسًا", dimmed: true)
                    Text("Safiyyah bint Huyayy (may Allah be pleased with her), a Mother of the Believers, was the daughter of the chief of Banu an-Nadir; the Prophet (peace be upon him) freed her and married her (Sahih al-Bukhari 371), and when Hafsah (may Allah be pleased with her) taunted her as “the daughter of a Jew“ he said:")
                        .font(.body)
                    ScriptureQuote(text: "“And you are the daughter of a Prophet, and your uncle is a Prophet, and you are married to a Prophet, so what is she boasting to you about?” (Sunan al-Tirmidhi 3894; graded sahih by al-Albani).", arabic: "إِنَّكِ لاَبْنَةُ نَبِيٍّ وَإِنَّ عَمَّكِ لَنَبِيٌّ وَإِنَّكِ لَتَحْتَ نَبِيٍّ فَفِيمَ تَفْخَرُ عَلَيْكِ", dimmed: true)
                    Text("And the rule Allah laid down for every non-Muslim who is not at war with the Muslims applies to the Jews as to anyone else:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them. Indeed, Allah loves those who act justly” (Quran 60:8).", arabic: "لَّا يَنۡهَىٰكُمُ ٱللَّهُ عَنِ ٱلَّذِينَ لَمۡ يُقَٰتِلُوكُمۡ فِي ٱلدِّينِ وَلَمۡ يُخۡرِجُوكُم مِّن دِيَٰرِكُمۡ أَن تَبَرُّوهُمۡ وَتُقۡسِطُوٓاْ إِلَيۡهِمۡۚ إِنَّ ٱللَّهَ يُحِبُّ ٱلۡمُقۡسِطِينَ")

                    Text("**What happened between the Prophet and the Jewish tribes of Madinah?**")
                        .font(.body)
                    Text("When the Prophet (peace be upon him) arrived in Madinah he made a written covenant with its Jewish tribes, recorded in the Sirah of Ibn Hisham: they kept their religion and property, and each side would defend the city and not aid its enemies. The three main tribes broke it in turn. Banu Qaynuqa broke the peace after Badr and were besieged and expelled. Banu an-Nadir plotted to kill the Prophet, were besieged, and were exiled with what their camels could carry; Surat al-Hashr describes it (Quran 59:2-4):")
                        .font(.body)
                    ScriptureQuote(text: "“That is because they opposed Allah and His Messenger. And whoever opposes Allah - then indeed, Allah is severe in penalty” (Quran 59:4).", arabic: "ذَٰلِكَ بِأَنَّهُمۡ شَآقُّواْ ٱللَّهَ وَرَسُولَهُۥۖ وَمَن يُشَآقِّ ٱللَّهَ فَإِنَّ ٱللَّهَ شَدِيدُ ٱلۡعِقَابِ")
                    Text("Banu Qurayzah were left in place after that, as Ibn Umar (may Allah be pleased with them) reports, until they too fought against him (Sahih al-Bukhari 4028), siding with the Confederates who besieged Madinah in the Battle of the Trench, as Surat al-Ahzab records (Quran 33:26-27). When they surrendered they chose to accept the verdict of Sa‘d ibn Mu‘adh (may Allah be pleased with him), their former ally, who ruled that the fighting men be executed and the rest taken captive, and the Prophet (peace be upon him) said he had judged with the judgement of Allah (Sahih al-Bukhari 4121); the sentence was also what their own Torah prescribes for a city taken in war (Deuteronomy 20:12-14). Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And He brought down those who supported them among the People of the Scripture from their fortresses and cast terror into their hearts [so that] a party you killed, and you took captive a party” (Quran 33:26).", arabic: "وَأَنزَلَ ٱلَّذِينَ ظَٰهَرُوهُم مِّنۡ أَهۡلِ ٱلۡكِتَٰبِ مِن صَيَاصِيهِمۡ وَقَذَفَ فِي قُلُوبِهِمُ ٱلرُّعۡبَ فَرِيقٗا تَقۡتُلُونَ وَتَأۡسِرُونَ فَرِيقٗا")
                    Text("The cause in each case was treachery and war, not religion. The Jews of Khaybar, after their defeat, were left on their land as tenants paying half the harvest (Sahih al-Bukhari 2328), and at the Prophet’s death his armour was still in pledge with a Jew (Sahih al-Bukhari 2916, quoted above).")
                        .font(.body)

                    Text("**Why did most Jews reject Muhammad?**")
                        .font(.body)
                    Text("Not for lack of recognition. The Quran says they knew him as they knew their own sons (Quran 2:146, quoted above), and that they had been praying for his coming:")
                        .font(.body)
                    ScriptureQuote(text: "“but [then] when there came to them that which they recognized, they disbelieved in it; so the curse of Allah will be upon the disbelievers” (Quran 2:89).", arabic: "فَلَمَّا جَآءَهُم مَّا عَرَفُواْ كَفَرُواْ بِهِۦۚ فَلَعۡنَةُ ٱللَّهِ عَلَى ٱلۡكَٰفِرِينَ")
                    ScriptureQuote(text: "“Many of the People of the Scripture wish they could turn you back to disbelief after you have believed, out of envy from themselves [even] after the truth has become clear to them” (Quran 2:109).", arabic: "وَدَّ كَثِيرٞ مِّنۡ أَهۡلِ ٱلۡكِتَٰبِ لَوۡ يَرُدُّونَكُم مِّنۢ بَعۡدِ إِيمَٰنِكُمۡ كُفَّارًا حَسَدٗا مِّنۡ عِندِ أَنفُسِهِم مِّنۢ بَعۡدِ مَا تَبَيَّنَ لَهُمُ ٱلۡحَقُّۖ")
                    ScriptureQuote(text: "“Those to whom We have given the Scripture recognize it as they recognize their [own] sons. Those who will lose themselves [in the Hereafter] do not believe” (Quran 6:20).", arabic: "ٱلَّذِينَ ءَاتَيۡنَٰهُمُ ٱلۡكِتَٰبَ يَعۡرِفُونَهُۥ كَمَا يَعۡرِفُونَ أَبۡنَآءَهُمُۘ ٱلَّذِينَ خَسِرُوٓاْ أَنفُسَهُمۡ فَهُمۡ لَا يُؤۡمِنُونَ")
                    Text("The cause the Quran names is envy that prophethood had passed from Bani Isra’il to the children of Isma‘il (Quran 2:90). The story of Abdullah ibn Salam (may Allah be pleased with him) shows it. Before announcing his Islam he asked the Prophet (peace be upon him) to question the Jews about him; they called him the best of them and the son of the best of them, and when he then declared his faith they called him the worst of them and the son of the worst (Sahih al-Bukhari 3938). The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Had ten of the Jews believed in me, the Jews would have believed in me” (Sahih al-Bukhari 3941).", arabic: "لَوْ آمَنَ بِي عَشَرَةٌ مِنَ الْيَهُودِ لآمَنَ بِي الْيَهُودُ", dimmed: true)

                    Text("**Is the Torah of today preserved?**")
                        .font(.body)
                    Text("Not intact. The Quran says that they distorted words, forgot a portion, and wrote with their own hands (Quran 5:13 and 2:79, quoted above), and that a party of them altered the Torah knowingly:")
                        .font(.body)
                    ScriptureQuote(text: "“Do you covet [the hope, O believers], that they would believe for you while a party of them used to hear the words of Allah and then distort the Torah after they had understood it while they were knowing?” (Quran 2:75).", arabic: "أَفَتَطۡمَعُونَ أَن يُؤۡمِنُواْ لَكُمۡ وَقَدۡ كَانَ فَرِيقٞ مِّنۡهُمۡ يَسۡمَعُونَ كَلَٰمَ ٱللَّهِ ثُمَّ يُحَرِّفُونَهُۥ مِنۢ بَعۡدِ مَا عَقَلُوهُ وَهُمۡ يَعۡلَمُونَ")
                    ScriptureQuote(text: "“O People of the Scripture, there has come to you Our Messenger making clear to you much of what you used to conceal of the Scripture and overlooking much” (Quran 5:15).", arabic: "يَٰٓأَهۡلَ ٱلۡكِتَٰبِ قَدۡ جَآءَكُمۡ رَسُولُنَا يُبَيِّنُ لَكُمۡ كَثِيرٗا مِّمَّا كُنتُمۡ تُخۡفُونَ مِنَ ٱلۡكِتَٰبِ وَيَعۡفُواْ عَن كَثِيرٖۚ")
                    Text("The text itself bears this out. Deuteronomy 34 narrates the death of Musa. Three ancient versions of the Torah survive, the Hebrew Masoretic text, the Samaritan Pentateuch, and the Greek Septuagint, and they differ from one another in thousands of readings; in the ages of the patriarchs in Genesis 5 and 11 the differences add up to more than a thousand years of chronology. The Dead Sea Scrolls show these differing text-types already circulating side by side before the time of Jesus. The oldest complete Hebrew manuscript dates from around 1000 CE. What is true in it is confirmed by the Quran, which Allah Himself has guarded (Quran 15:9).")
                        .font(.body)

                    Text("**Is Muhammad mentioned in the Torah?**")
                        .font(.body)
                    Text("Yes (Quran 7:157, quoted above). Abdullah ibn Amr (may Allah be pleased with them), who had read the earlier scriptures, was asked about the Prophet’s description in the Torah and answered:")
                        .font(.body)
                    ScriptureQuote(text: "“O Prophet, We have sent you as a witness and a giver of glad tidings and a warner, and a guardian of the illiterates. You are My slave and My messenger; I have named you al-Mutawakkil. You are neither discourteous nor harsh, nor a noisemaker in the markets” (Sahih al-Bukhari 2125).", arabic: "يَا أَيُّهَا النَّبِيُّ إِنَّا أَرْسَلْنَاكَ شَاهِدًا وَمُبَشِّرًا وَنَذِيرًا، وَحِرْزًا لِلأُمِّيِّينَ، أَنْتَ عَبْدِي وَرَسُولِي سَمَّيْتُكَ الْمُتَوَكِّلَ، لَيْسَ بِفَظٍّ وَلاَ غَلِيظٍ وَلاَ سَخَّابٍ فِي الأَسْوَاقِ", dimmed: true)
                    Text("In the Torah as it stands, Musa is promised a prophet “like unto“ himself from the “brethren“ of Israel (Deuteronomy 18:18), and the brethren of Israel are the children of Isma‘il, of whom Allah had promised Ibrahim twelve princes and a great nation (Genesis 17:20). The blessing of Musa says the Lord “came from Sinai, and rose up from Seir unto them; he shined forth from mount Paran“ (Deuteronomy 33:2): Sinai is the revelation to Musa, Seir the land of Isa, and Paran the wilderness where Isma‘il settled (Genesis 21:21), that is, the Hijaz. Isaiah 42 foretells a servant who brings law to the nations and calls on Kedar, the son of Isma‘il (Genesis 25:13), to sing a new song. Ibn al-Qayyim gathered these in Hidayat al-Hayara, and Ibn Taymiyyah in al-Jawab as-Sahih.")
                        .font(.body)

                    Text("**Which son did Ibrahim take to sacrifice?**")
                        .font(.body)
                    Text("Isma‘il. The Quran tells the story without naming him, but the order of the narrative settles it:")
                        .font(.body)
                    ScriptureQuote(text: "“And when he reached with him [the age of] exertion, he said, ‘O my son, indeed I have seen in a dream that I [must] sacrifice you, so see what you think.’ He said, ‘O my father, do as you are commanded. You will find me, if Allah wills, of the steadfast’” (Quran 37:102).", arabic: "فَلَمَّا بَلَغَ مَعَهُ ٱلسَّعۡيَ قَالَ يَٰبُنَيَّ إِنِّيٓ أَرَىٰ فِي ٱلۡمَنَامِ أَنِّيٓ أَذۡبَحُكَ فَٱنظُرۡ مَاذَا تَرَىٰۚ قَالَ يَٰٓأَبَتِ ٱفۡعَلۡ مَا تُؤۡمَرُۖ سَتَجِدُنِيٓ إِن شَآءَ ٱللَّهُ مِنَ ٱلصَّٰبِرِينَ")
                    ScriptureQuote(text: "“And We gave him good tidings of Isaac, a prophet from among the righteous” (Quran 37:112).", arabic: "وَبَشَّرۡنَٰهُ بِإِسۡحَٰقَ نَبِيّٗا مِّنَ ٱلصَّٰلِحِينَ")
                    Text("The good news of Ishaq comes after the sacrifice, so the boy of the sacrifice was the son Ibrahim already had, Isma‘il. Moreover Ishaq was announced together with Ya‘qub, his son, to come after him (Quran 11:71), so Ibrahim could not have been commanded to sacrifice him as a boy; and the ransom of the ram is tied to the rites of Makkah, where Isma‘il was raised (Sahih al-Bukhari 3364). This is the view of Ibn Taymiyyah (Majmu‘ al-Fatawa), Ibn al-Qayyim (Zad al-Ma‘ad), and Ibn Kathir (in his tafsir and al-Bidayah wan-Nihayah). The Torah itself supports it: Genesis 22:2 calls the son to be sacrificed “thine only son,“ and Isma‘il was born some fourteen years before Ishaq (Genesis 16:16, 21:5), so for those years he alone was the only son. Ibn Kathir regarded the name of Ishaq in that verse as an insertion.")
                        .font(.body)

                    Text("**Was Ibrahim a Jew?**")
                        .font(.body)
                    ScriptureQuote(text: "“O People of the Scripture, why do you argue about Abraham while the Torah and the Gospel were not revealed until after him? Then will you not reason?” (Quran 3:65).", arabic: "يَٰٓأَهۡلَ ٱلۡكِتَٰبِ لِمَ تُحَآجُّونَ فِيٓ إِبۡرَٰهِيمَ وَمَآ أُنزِلَتِ ٱلتَّوۡرَىٰةُ وَٱلۡإِنجِيلُ إِلَّا مِنۢ بَعۡدِهِۦٓۚ أَفَلَا تَعۡقِلُونَ")
                    Text("The Torah came centuries after Ibrahim, and the very word “Jew“ comes from his great-grandson Yahudha. He was a hanif, a Muslim (Quran 3:67-68, quoted above), and so were his sons:")
                        .font(.body)
                    ScriptureQuote(text: "“When his Lord said to him, ‘Submit’, he said ‘I have submitted [in Islam] to the Lord of the worlds.’ And Abraham instructed his sons [to do the same] and [so did] Jacob, [saying], ‘O my sons, indeed Allah has chosen for you this religion, so do not die except while you are Muslims’” (Quran 2:131-132).", arabic: "إِذۡ قَالَ لَهُۥ رَبُّهُۥٓ أَسۡلِمۡۖ قَالَ أَسۡلَمۡتُ لِرَبِّ ٱلۡعَٰلَمِينَ ۝ وَوَصَّىٰ بِهَآ إِبۡرَٰهِـۧمُ بَنِيهِ وَيَعۡقُوبُ يَٰبَنِيَّ إِنَّ ٱللَّهَ ٱصۡطَفَىٰ لَكُمُ ٱلدِّينَ فَلَا تَمُوتُنَّ إِلَّا وَأَنتُم مُّسۡلِمُونَ")

                    Text("**What laws do Jews and Muslims share?**")
                        .font(.body)
                    Text("A great deal, because the source is one. Circumcision (Sahih al-Bukhari 3356, quoted above). Dietary law: no pork, no blood, no carrion, and slaughter by the throat, so that Allah made their food lawful for Muslims:")
                        .font(.body)
                    ScriptureQuote(text: "“the food of those who were given the Scripture is lawful for you and your food is lawful for them” (Quran 5:5).", arabic: "وَطَعَامُ ٱلَّذِينَ أُوتُواْ ٱلۡكِتَٰبَ حِلّٞ لَّكُمۡ وَطَعَامُكُمۡ حِلّٞ لَّهُمۡۖ")
                    Text("Fasting, which the Torah and Ashura show:")
                        .font(.body)
                    ScriptureQuote(text: "“decreed upon you is fasting as it was decreed upon those before you that you may become righteous” (Quran 2:183).", arabic: "كُتِبَ عَلَيۡكُمُ ٱلصِّيَامُ كَمَا كُتِبَ عَلَى ٱلَّذِينَ مِن قَبۡلِكُمۡ لَعَلَّكُمۡ تَتَّقُونَ")
                    Text("Ritual purity, with washing after impurity and before worship (Leviticus 15, Exodus 30:19-21). Prayer at fixed times, morning, noon and evening (Daniel 6:10, Psalm 55:17), with prostration on the face (Numbers 20:6, Genesis 17:3). Modest dress and the head covering of women (Genesis 24:65). The prohibition of images and of usury among the people (Deuteronomy 23:19-20), which Islam extends to all mankind. A Jew who visits a mosque and a Muslim who visits a synagogue each recognise the other.")
                        .font(.body)

                    Text("**Will the Jews believe in Isa when he returns?**")
                        .font(.body)
                    ScriptureQuote(text: "“And there is none from the People of the Scripture but that he will surely believe in Jesus before his death. And on the Day of Resurrection he will be against them a witness” (Quran 4:159).", arabic: "وَإِن مِّنۡ أَهۡلِ ٱلۡكِتَٰبِ إِلَّا لَيُؤۡمِنَنَّ بِهِۦ قَبۡلَ مَوۡتِهِۦۖ وَيَوۡمَ ٱلۡقِيَٰمَةِ يَكُونُ عَلَيۡهِمۡ شَهِيدٗا")
                    Text("Ibn Kathir explains, following Ibn Jarir at-Tabari, that “before his death“ means before the death of Isa: when he descends, every Jew and Christian who remains will believe in him as he truly is, the servant and messenger of Allah, and Abu Hurayrah (may Allah be pleased with him) recited this ayah after narrating the hadith of his descent (Sahih al-Bukhari 3448). Before that, the Dajjal will claim to be the Messiah and gather followers from among them (Sahih Muslim 2944, quoted above), and Isa will kill him (Sahih Muslim 2937).")
                        .font(.body)

                    Text("**Are Jews disbelievers, and what is owed to them?**")
                        .font(.body)
                    Text("Whoever hears of Muhammad (peace be upon him) and rejects him is a disbeliever in the Quran’s terms, whatever his lineage, just as the Quran says of the Christians who call Allah one of three (Quran 5:73). Surat al-Bayyinah opens by naming “those who disbelieved among the People of the Scripture“ (Quran 98:1) and states their end:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, they who disbelieved among the People of the Scripture and the polytheists will be in the fire of Hell, abiding eternally therein. Those are the worst of creatures” (Quran 98:6).", arabic: "إِنَّ ٱلَّذِينَ كَفَرُواْ مِنۡ أَهۡلِ ٱلۡكِتَٰبِ وَٱلۡمُشۡرِكِينَ فِي نَارِ جَهَنَّمَ خَٰلِدِينَ فِيهَآۚ أُوْلَٰٓئِكَ هُمۡ شَرُّ ٱلۡبَرِيَّةِ")
                    ScriptureQuote(text: "“By Him in whose hand is the life of Muhammad, he who among the community of Jews or Christians hears about me but does not affirm his belief in that with which I have been sent, and dies in this state, shall be but one of the denizens of Hellfire” (Sahih Muslim 153).", arabic: "وَالَّذِي نَفْسُ مُحَمَّدٍ بِيَدِهِ لاَ يَسْمَعُ بِي أَحَدٌ مِنْ هَذِهِ الأُمَّةِ يَهُودِيٌّ وَلاَ نَصْرَانِيٌّ ثُمَّ يَمُوتُ وَلَمْ يُؤْمِنْ بِالَّذِي أُرْسِلْتُ بِهِ إِلاَّ كَانَ مِنْ أَصْحَابِ النَّارِ", dimmed: true)
                    Text("Judgement of individuals belongs to Allah, who does not punish anyone the message never reached (Quran 17:15). What is owed to them in this world is justice, kindness where there is no war (Quran 60:8, quoted above), the honouring of treaties, and the protection of their lives and property:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, be persistently standing firm for Allah, witnesses in justice, and do not let the hatred of a people prevent you from being just. Be just; that is nearer to righteousness. And fear Allah; indeed, Allah is Acquainted with what you do” (Quran 5:8).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ كُونُواْ قَوَّٰمِينَ لِلَّهِ شُهَدَآءَ بِٱلۡقِسۡطِۖ وَلَا يَجۡرِمَنَّكُمۡ شَنَـَٔانُ قَوۡمٍ عَلَىٰٓ أَلَّا تَعۡدِلُواْۚ ٱعۡدِلُواْ هُوَ أَقۡرَبُ لِلتَّقۡوَىٰۖ وَٱتَّقُواْ ٱللَّهَۚ إِنَّ ٱللَّهَ خَبِيرُۢ بِمَا تَعۡمَلُونَ")
                    ScriptureQuote(text: "“Whoever kills a person having a treaty with the Muslims shall not smell the fragrance of Paradise, though its fragrance is perceived from a distance of forty years” (Sahih al-Bukhari 3166).", arabic: "مَنْ قَتَلَ مُعَاهَدًا لَمْ يَرَحْ رَائِحَةَ الْجَنَّةِ، وَإِنَّ رِيحَهَا تُوجَدُ مِنْ مَسِيرَةِ أَرْبَعِينَ عَامًا", dimmed: true)
                    Text("Umar (may Allah be pleased with him) made fulfilling Allah’s covenant with the People of the Scripture part of his final advice (Sahih al-Bukhari 3162, mentioned above).")
                        .font(.body)

                    Text("**Should Muslims hate Jews?**")
                        .font(.body)
                    Text("No. Hatred in Islam is for disbelief and oppression, never for a lineage, and it never licenses injustice. A Jew who accepts Islam is a brother in full, as Abdullah ibn Salam and Safiyyah were, and the Prophet (peace be upon him) rebuked his own wife for a taunt about Safiyyah’s birth (Sunan al-Tirmidhi 3894, quoted above). Allah commands:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not let the hatred of a people for having obstructed you from al-Masjid al-Haram lead you to transgress. And cooperate in righteousness and piety, but do not cooperate in sin and aggression” (Quran 5:2).", arabic: "وَلَا يَجۡرِمَنَّكُمۡ شَنَـَٔانُ قَوۡمٍ أَن صَدُّوكُمۡ عَنِ ٱلۡمَسۡجِدِ ٱلۡحَرَامِ أَن تَعۡتَدُواْۘ وَتَعَاوَنُواْ عَلَى ٱلۡبِرِّ وَٱلتَّقۡوَىٰۖ وَلَا تَعَاوَنُواْ عَلَى ٱلۡإِثۡمِ وَٱلۡعُدۡوَٰنِۚ")
                    ScriptureQuote(text: "“Indeed, Allah orders justice and good conduct and giving to relatives and forbids immorality and bad conduct and oppression” (Quran 16:90).", arabic: "إِنَّ ٱللَّهَ يَأۡمُرُ بِٱلۡعَدۡلِ وَٱلۡإِحۡسَٰنِ وَإِيتَآيِٕ ذِي ٱلۡقُرۡبَىٰ وَيَنۡهَىٰ عَنِ ٱلۡفَحۡشَآءِ وَٱلۡمُنكَرِ وَٱلۡبَغۡيِۚ")
                    Text("Ibn Taymiyyah (may Allah have mercy on him) explains in Majmu‘ al-Fatawa that love and enmity for the sake of Allah follow faith and deeds, so that one person may deserve both in different measures, and that a believer is commanded to be just even to those he opposes. The Muslim rejects what the Jews rejected of the truth and invites them to it; he does not hate them for being Jews.")
                        .font(.body)

                    Text("**What is the Muslim view of the Jewish expectation of a Messiah?**")
                        .font(.body)
                    Text("The Messiah already came. He was Isa ibn Maryam (Quran 3:45, quoted above), and he announced the messenger who would follow him:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention] when Jesus, the son of Mary, said, ‘O children of Israel, indeed I am the messenger of Allah to you confirming what came before me of the Torah and bringing good tidings of a messenger to come after me, whose name is Ahmad.’ But when he came to them with clear evidences, they said, ‘This is obvious magic’” (Quran 61:6).", arabic: "وَإِذۡ قَالَ عِيسَى ٱبۡنُ مَرۡيَمَ يَٰبَنِيٓ إِسۡرَٰٓءِيلَ إِنِّي رَسُولُ ٱللَّهِ إِلَيۡكُم مُّصَدِّقٗا لِّمَا بَيۡنَ يَدَيَّ مِنَ ٱلتَّوۡرَىٰةِ وَمُبَشِّرَۢا بِرَسُولٖ يَأۡتِي مِنۢ بَعۡدِي ٱسۡمُهُۥٓ أَحۡمَدُۖ فَلَمَّا جَآءَهُم بِٱلۡبَيِّنَٰتِ قَالُواْ هَٰذَا سِحۡرٞ مُّبِينٞ")
                    Text("The one who will come claiming to be the awaited Messiah is the Dajjal, of whom every prophet warned his people:")
                        .font(.body)
                    ScriptureQuote(text: "“No prophet was sent but that he warned his followers against the one-eyed liar. Beware! He is blind in one eye, and your Lord is not so, and there will be written between his eyes ‘kafir’” (Sahih al-Bukhari 7131).", arabic: "مَا بُعِثَ نَبِيٌّ إِلاَّ أَنْذَرَ أُمَّتَهُ الأَعْوَرَ الْكَذَّابَ، أَلاَ إِنَّهُ أَعْوَرُ، وَإِنَّ رَبَّكُمْ لَيْسَ بِأَعْوَرَ، وَإِنَّ بَيْنَ عَيْنَيْهِ مَكْتُوبٌ كَافِرٌ", dimmed: true)
                    Text("Then the true Messiah will return (Sahih al-Bukhari 3448, Sahih Muslim 155), and those who have waited for a Messiah will find him to be the one their fathers rejected.")
                        .font(.body)
                }

                Section(header: Text("THE INVITATION")) {
                    ScriptureQuote(text: "“Say, ‘O People of the Scripture, come to a word that is equitable between us and you - that we will not worship except Allah and not associate anything with Him and not take one another as lords instead of Allah’” (Quran 3:64).", arabic: "قُلۡ يَٰٓأَهۡلَ ٱلۡكِتَٰبِ تَعَالَوۡاْ إِلَىٰ كَلِمَةٖ سَوَآءِۭ بَيۡنَنَا وَبَيۡنَكُمۡ أَلَّا نَعۡبُدَ إِلَّا ٱللَّهَ وَلَا نُشۡرِكَ بِهِۦ شَيۡـٔٗا وَلَا يَتَّخِذَ بَعۡضُنَا بَعۡضًا أَرۡبَابٗا مِّن دُونِ ٱللَّهِۚ")

                    Text("The God of Abraham, Isaac, Jacob, and Moses is Allah, and the religion they brought was submission to Him. The Muslim invites the Jew to the last prophet of that same line, foretold by Moses, and to the Book that confirms the truth of what came before it.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Islam honours Moses and the Torah, and asks the Children of Israel to keep the covenant they gave: to believe in the messengers who came after him, whom their own scripture foretold, and to worship the God of Abraham as Abraham did.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Judaism")
        .selectableArticleList()
    }
}

struct HinduismAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Hinduism worships many gods through images and teaches rebirth and caste. The Quran answers with the argument of Ibrahim against idols, the oneness of the Creator, the resurrection instead of reincarnation, and the equality of all people before Allah.")
                        .font(.body)
                }

                Section(header: Text("WHAT HINDUISM TEACHES")) {
                    Text("Hinduism is not one creed but a family of traditions from India. Most Hindus worship many deities (Brahma, Vishnu, Shiva, Krishna, Rama, Ganesha, Durga, and others) through **murtis**, images and statues, in temples and homes; many also speak of one supreme reality, **Brahman**, behind them all, and some hold that the deities are its faces. Central are **karma** and **samsara**, the cycle of rebirth in which the soul returns in a new body according to its deeds, and the ordering of society into hereditary **castes**.")
                        .font(.body)

                    Text("Notably, the oldest Hindu scriptures contain statements of one God without image: “He is One, without a second“ (Chandogya Upanishad 6:2:1), and a verse whose Sanskrit says **na tasya pratima asti**, “there is no pratima of Him“ (Shvetashvatara Upanishad 4:19; Yajurveda 32:3), which Muslims read as “no image“ and many Hindu commentators read as “no likeness“ or “no equal.“ Either reading says the same thing about worship: what has no likeness cannot be represented by a carved one. Islam calls Hindus back to that.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Hindu (هِنْدُوسِيّ)**: not a name from any scripture. It comes from Sindhu, the Sanskrit name of the Indus river; the Persians pronounced it “Hindu” and used it for the land and the peoples beyond that river, and the Arabs took it from them as al-Hind (الهِنْد). “Hinduism” as the name of one religion is a modern usage, gathering under one word many traditions and philosophies that never called themselves by it.")
                        .font(.body)

                    Text("**Sanatana Dharma**: “the eternal order” or “eternal law,” the name many Hindus prefer for their tradition. Islam agrees that the true religion is eternal and one, but says it is the religion Allah gave to every prophet, not a set of rites tied to one land:")
                        .font(.body)
                    ScriptureQuote(text: "“He has ordained for you of religion what He enjoined upon Noah and that which We have revealed to you, [O Muhammad], and what We enjoined upon Abraham and Moses and Jesus - to establish the religion and not be divided therein” (Quran 42:13).", arabic: "شَرَعَ لَكُم مِّنَ ٱلدِّينِ مَا وَصَّىٰ بِهِۦ نُوحٗا وَٱلَّذِيٓ أَوۡحَيۡنَآ إِلَيۡكَ وَمَا وَصَّيۡنَا بِهِۦٓ إِبۡرَٰهِيمَ وَمُوسَىٰ وَعِيسَىٰٓۖ أَنۡ أَقِيمُواْ ٱلدِّينَ وَلَا تَتَفَرَّقُواْ فِيهِۚ")
                    ScriptureQuote(text: "“Indeed, the religion in the sight of Allah is Islam” (Quran 3:19).", arabic: "إِنَّ ٱلدِّينَ عِندَ ٱللَّهِ ٱلۡإِسۡلَٰمُۗ")

                    Text("**Brahman** and **Ishvara**: Brahman is the impersonal absolute of the Upanishads, the one reality behind all things, of which the school of Advaita (“non-duality,” taught by Shankara around the eighth century CE) says that the soul and the world are ultimately not different from it. Ishvara is a personal Lord, worshipped under names such as Vishnu or Shiva. Islam rejects both the impersonal absolute and the many lords: Allah is one personal Lord who knows, hears, sees, speaks, loves, and is pleased and angered, and He is utterly distinct from His creation:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep” (Quran 2:255).", arabic: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ")
                    ScriptureQuote(text: "“There is no one in the heavens and earth but that he comes to the Most Merciful as a servant” (Quran 19:93).", arabic: "إِن كُلُّ مَن فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ إِلَّآ ءَاتِي ٱلرَّحۡمَٰنِ عَبۡدٗا")

                    Text("**Atman**: the self or soul, which Advaita holds to be identical with Brahman (“that thou art,” Chandogya Upanishad 6:8:7). Islam affirms that the soul (**ruh, الرُّوح**) is real, but it is a created thing whose nature Allah has kept mostly hidden (Quran 17:85). Allah breathed into Adam “of My [created] soul” (Quran 15:29); the soul is His creation and His servant, never a part of Him. Ibn Taymiyyah (may Allah have mercy on him) wrote at length against the Sufi doctrine of the “unity of existence” (wahdat al-wujud) precisely because it makes the creature one with the Creator, the same error in a Muslim dress (Majmu‘ al-Fatawa, volume 2).")
                        .font(.body)

                    Text("**Samsara**: the cycle of birth, death, and rebirth in which the soul returns in new bodies. Islam knows one birth, one death, and one resurrection (Quran 23:99-100). The people of Paradise will say to one another:")
                        .font(.body)
                    ScriptureQuote(text: "“Then, are we not to die except for our first death, and we will not be punished?” (Quran 37:58-59).", arabic: "أَفَمَا نَحۡنُ بِمَيِّتِينَ ۝ إِلَّا مَوۡتَتَنَا ٱلۡأُولَىٰ وَمَا نَحۡنُ بِمُعَذَّبِينَ")

                    Text("**Karma**: literally “action”; the law by which deeds bear fruit in this life or the next. Islam affirms that every deed is recorded and repaid in full (Quran 99:7-8), but by a Judge who knows and forgives, not by a blind mechanism:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, Allah does not do injustice, [even] as much as an atom's weight; while if there is a good deed, He multiplies it and gives from Himself a great reward” (Quran 4:40).", arabic: "إِنَّ ٱللَّهَ لَا يَظۡلِمُ مِثۡقَالَ ذَرَّةٖۖ وَإِن تَكُ حَسَنَةٗ يُضَٰعِفۡهَا وَيُؤۡتِ مِن لَّدُنۡهُ أَجۡرًا عَظِيمٗا")

                    Text("**Moksha**: “liberation” from samsara, understood as merging into Brahman or eternal union with the deity. Islam’s salvation is not dissolution but entry into Paradise as a living, conscious person:")
                        .font(.body)
                    ScriptureQuote(text: "“So he who is drawn away from the Fire and admitted to Paradise has attained [his desire]. And what is the life of this world except the enjoyment of delusion” (Quran 3:185).", arabic: "فَمَن زُحۡزِحَ عَنِ ٱلنَّارِ وَأُدۡخِلَ ٱلۡجَنَّةَ فَقَدۡ فَازَۗ وَمَا ٱلۡحَيَوٰةُ ٱلدُّنۡيَآ إِلَّا مَتَٰعُ ٱلۡغُرُورِ")

                    Text("**Dharma**: duty, right order, religion; each caste and stage of life has its own dharma. Islam’s **din (الدِّين)** is one for all, revealed and complete:")
                        .font(.body)
                    ScriptureQuote(text: "“This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as religion” (Quran 5:3).", arabic: "ٱلۡيَوۡمَ أَكۡمَلۡتُ لَكُمۡ دِينَكُمۡ وَأَتۡمَمۡتُ عَلَيۡكُمۡ نِعۡمَتِي وَرَضِيتُ لَكُمُ ٱلۡإِسۡلَٰمَ دِينٗاۚ")

                    Text("**Avatar**: “descent,” a deity taking a body on earth. Vishnu is said to have ten avatars, among them Rama, the hero of the Ramayana, and Krishna, the speaker of the Bhagavad Gita. Islam denies that the Creator ever enters His creation or takes a body:")
                        .font(.body)
                    ScriptureQuote(text: "“[He is] Originator of the heavens and the earth. How could He have a son when He does not have a companion and He created all things? And He is, of all things, Knowing” (Quran 6:101).", arabic: "بَدِيعُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ أَنَّىٰ يَكُونُ لَهُۥ وَلَدٞ وَلَمۡ تَكُن لَّهُۥ صَٰحِبَةٞۖ وَخَلَقَ كُلَّ شَيۡءٖۖ وَهُوَ بِكُلِّ شَيۡءٍ عَلِيمٞ")

                    Text("**Murti** and **puja**: the murti is the image or statue in which the deity is held to be present; puja is the worship offered to it, with flowers, food, lamps, and prostration. This is exactly what Ibrahim (peace be upon him) confronted in his own people (Quran 21:52-54), and what the Quran describes as worshipping what cannot create a fly (Quran 22:73).")
                        .font(.body)

                    Text("**The Vedas, Upanishads, and Gita**: the four Vedas (Rig, Sama, Yajur, Atharva) are the oldest Hindu texts, the Rig Veda dating to roughly 1500-1200 BCE. The Upanishads are the later philosophical texts, and the Bhagavad Gita is Krishna’s discourse to the warrior Arjuna, a part of the epic Mahabharata. The Quran does not name them; the scriptures it names are the Tawrah, the Zabur, the Injil, the scrolls of Ibrahim and Musa (Quran 87:18-19), and itself, while it affirms that Allah sent messengers whose stories He did not relate (Quran 40:78). The Quran is the criterion over every earlier book (Quran 5:48): whatever agrees with it about the One God is truth, and whatever contradicts it is not from Allah.")
                        .font(.body)

                    Text("**Trimurti**: the “three forms,” Brahma the creator, Vishnu the preserver, and Shiva the destroyer. The Quran answers every division of the divine work, and names Allah alone as the Creator, the Inventor, and the Fashioner (Quran 59:24, quoted in the questions below):")
                        .font(.body)
                    ScriptureQuote(text: "“Allah has not taken any son, nor has there ever been with Him any deity. [If there had been], then each deity would have taken what it created, and some of them would have sought to overcome others. Exalted is Allah above what they describe [concerning Him]” (Quran 23:91).", arabic: "مَا ٱتَّخَذَ ٱللَّهُ مِن وَلَدٖ وَمَا كَانَ مَعَهُۥ مِنۡ إِلَٰهٍۚ إِذٗا لَّذَهَبَ كُلُّ إِلَٰهِۭ بِمَا خَلَقَ وَلَعَلَا بَعۡضُهُمۡ عَلَىٰ بَعۡضٖۚ سُبۡحَٰنَ ٱللَّهِ عَمَّا يَصِفُونَ")

                    Text("**Varna** and caste: the four hereditary classes, Brahmin (priests), Kshatriya (rulers and warriors), Vaishya (merchants and farmers), and Shudra (labourers), described in the Rig Veda (10:90) as born from the different limbs of the primal man, and codified in the Laws of Manu; and below them the Dalits, once called untouchables, outside the system altogether. Islam has no priestly class and no hereditary rank; nobility is by piety alone (Quran 49:13), and the Prophet (peace be upon him) said that people are all the children of Adam, and Adam was created from dust (Sunan al-Tirmidhi 3955; graded hasan by al-Albani).")
                        .font(.body)

                    Text("**Yoga**: “yoking” or “union”; in Hindu teaching a discipline of body, breath, and mind whose goal is union with Brahman or the deity. Its physical postures are one thing; its spiritual aim is another (see the questions below).")
                        .font(.body)

                    Text("**Guru**: the teacher, in many traditions treated as a channel of the divine and honoured with rites of devotion. Islam honours scholars but forbids making any human a lord:")
                        .font(.body)
                    ScriptureQuote(text: "“They have taken their scholars and monks as lords besides Allah, and [also] the Messiah, the son of Mary. And they were not commanded except to worship one God; there is no deity except Him. Exalted is He above whatever they associate with Him” (Quran 9:31).", arabic: "ٱتَّخَذُوٓاْ أَحۡبَارَهُمۡ وَرُهۡبَٰنَهُمۡ أَرۡبَابٗا مِّن دُونِ ٱللَّهِ وَٱلۡمَسِيحَ ٱبۡنَ مَرۡيَمَ وَمَآ أُمِرُوٓاْ إِلَّا لِيَعۡبُدُوٓاْ إِلَٰهٗا وَٰحِدٗاۖ لَّآ إِلَٰهَ إِلَّا هُوَۚ سُبۡحَٰنَهُۥ عَمَّا يُشۡرِكُونَ")

                    Text("**OM** and **mantra**: OM is the sacred syllable held to be the sound of Brahman itself, chanted at the start of prayers and meditation; a mantra is a formula repeated for spiritual power. The Muslim’s remembrance is of Allah by His revealed names, in words He taught:")
                        .font(.body)
                    ScriptureQuote(text: "“And to Allah belong the best names, so invoke Him by them” (Quran 7:180).", arabic: "وَلِلَّهِ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰ فَٱدۡعُوهُ بِهَاۖ")

                    Text("**Shirk (شِرْك)**: from sharika, to share; giving any part of what belongs to Allah alone, whether worship, prayer, sacrifice, or lordship, to another. It is the one sin Allah has said He does not forgive for the one who dies upon it (Quran 4:48). Luqman told his son:")
                        .font(.body)
                    ScriptureQuote(text: "“O my son, do not associate [anything] with Allah. Indeed, association [with him] is great injustice” (Quran 31:13).", arabic: "يَٰبُنَيَّ لَا تُشۡرِكۡ بِٱللَّهِۖ إِنَّ ٱلشِّرۡكَ لَظُلۡمٌ عَظِيمٞ")

                    Text("**Tawhid (تَوْحِيد)**: from wahhada, to make one; affirming that Allah alone is the Lord, alone deserves worship, and is alone in His names and attributes. Its clearest statement is Surat al-Ikhlas:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent’” (Quran 112:1-4).", arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ ۝ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ۝ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ")

                    Text("**Fitrah (فِطْرَة)**: from fatara, to originate; the natural disposition on which Allah creates every human being, which knows its Maker and inclines to worship Him alone. The Hindu who looks past the images to a single supreme reality is feeling the pull of that fitrah:")
                        .font(.body)
                    ScriptureQuote(text: "“So direct your face toward the religion, inclining to truth. [Adhere to] the fitrah of Allah upon which He has created [all] people. No change should there be in the creation of Allah. That is the correct religion, but most of the people do not know” (Quran 30:30).", arabic: "فَأَقِمۡ وَجۡهَكَ لِلدِّينِ حَنِيفٗاۚ فِطۡرَتَ ٱللَّهِ ٱلَّتِي فَطَرَ ٱلنَّاسَ عَلَيۡهَاۚ لَا تَبۡدِيلَ لِخَلۡقِ ٱللَّهِۚ ذَٰلِكَ ٱلدِّينُ ٱلۡقَيِّمُ وَلَٰكِنَّ أَكۡثَرَ ٱلنَّاسِ لَا يَعۡلَمُونَ")
                    ScriptureQuote(text: "“Every child is born upon the fitrah, and then his parents make him a Jew, a Christian, or a Magian” (Sahih al-Bukhari 1385).", arabic: "كُلُّ مَوْلُودٍ يُولَدُ عَلَى الْفِطْرَةِ، فَأَبَوَاهُ يُهَوِّدَانِهِ أَوْ يُنَصِّرَانِهِ أَوْ يُمَجِّسَانِهِ", dimmed: true)

                    Text("**Ba‘th (بَعْث)**: “raising”; the resurrection of the body from the grave for judgement, the Islamic answer to rebirth:")
                        .font(.body)
                    ScriptureQuote(text: "“And [that they may know] that the Hour is coming - no doubt about it - and that Allah will resurrect those in the graves” (Quran 22:7).", arabic: "وَأَنَّ ٱلسَّاعَةَ ءَاتِيَةٞ لَّا رَيۡبَ فِيهَا وَأَنَّ ٱللَّهَ يَبۡعَثُ مَن فِي ٱلۡقُبُورِ")
                }

                Section(header: Text("1. THE ARGUMENT OF IBRAHIM")) {
                    Text("Ibrahim (peace be upon him) grew up among a people who carved and worshipped images, and the Quran records his challenge:")
                        .font(.body)
                    ScriptureQuote(text: "“When he said to his father and his people, ‘What are these statues to which you are devoted?’ They said, ‘We found our fathers worshippers of them.’ He said, ‘You were certainly, you and your fathers, in manifest error’” (Quran 21:52-54).", arabic: "إِذۡ قَالَ لِأَبِيهِ وَقَوۡمِهِۦ مَا هَٰذِهِ ٱلتَّمَاثِيلُ ٱلَّتِيٓ أَنتُمۡ لَهَا عَٰكِفُونَ ۝ قَالُواْ وَجَدۡنَآ ءَابَآءَنَا لَهَا عَٰبِدِينَ ۝ قَالَ لَقَدۡ كُنتُمۡ أَنتُمۡ وَءَابَآؤُكُمۡ فِي ضَلَٰلٖ مُّبِينٖ")

                    Text("He broke the idols and left the largest, and when they asked who had done it, he told them to ask the big one, if it could speak. They knew it could not, and he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Then do you worship instead of Allah that which does not benefit you at all or harm you? Uff to you and to what you worship instead of Allah. Then will you not use reason?” (Quran 21:66-67).", arabic: "قَالَ أَفَتَعۡبُدُونَ مِن دُونِ ٱللَّهِ مَا لَا يَنفَعُكُمۡ شَيۡـٔٗا وَلَا يَضُرُّكُمۡ ۝ أُفّٖ لَّكُمۡ وَلِمَا تَعۡبُدُونَ مِن دُونِ ٱللَّهِۚ أَفَلَا تَعۡقِلُونَ")

                    ScriptureQuote(text: "“And when it is said to them, ‘Follow what Allah has revealed,’ they say, ‘Rather, we will follow that which we found our fathers doing.’ Even though their fathers understood nothing, nor were they guided?” (Quran 2:170).", arabic: "وَإِذَا قِيلَ لَهُمُ ٱتَّبِعُواْ مَآ أَنزَلَ ٱللَّهُ قَالُواْ بَلۡ نَتَّبِعُ مَآ أَلۡفَيۡنَا عَلَيۡهِ ءَابَآءَنَآۚ أَوَلَوۡ كَانَ ءَابَآؤُهُمۡ لَا يَعۡقِلُونَ شَيۡـٔٗا وَلَا يَهۡتَدُونَ")
                }

                Section(header: Text("2. THE CREATOR IS ONE, AND HAS NO IMAGE")) {
                    ScriptureQuote(text: "“Had there been within the heavens and earth gods besides Allah, they both would have been ruined. So exalted is Allah, Lord of the Throne, above what they describe” (Quran 21:22).", arabic: "لَوۡ كَانَ فِيهِمَآ ءَالِهَةٌ إِلَّا ٱللَّهُ لَفَسَدَتَاۚ فَسُبۡحَٰنَ ٱللَّهِ رَبِّ ٱلۡعَرۡشِ عَمَّا يَصِفُونَ")

                    ScriptureQuote(text: "“O people, an example is presented, so listen to it. Indeed, those you invoke besides Allah will never create [as much as] a fly, even if they gathered together for that purpose. And if the fly should steal away from them a [tiny] thing, they could not recover it from him. Weak are the pursuer and pursued” (Quran 22:73).", arabic: "يَٰٓأَيُّهَا ٱلنَّاسُ ضُرِبَ مَثَلٞ فَٱسۡتَمِعُواْ لَهُۥٓۚ إِنَّ ٱلَّذِينَ تَدۡعُونَ مِن دُونِ ٱللَّهِ لَن يَخۡلُقُواْ ذُبَابٗا وَلَوِ ٱجۡتَمَعُواْ لَهُۥۖ وَإِن يَسۡلُبۡهُمُ ٱلذُّبَابُ شَيۡـٔٗا لَّا يَسۡتَنقِذُوهُ مِنۡهُۚ ضَعُفَ ٱلطَّالِبُ وَٱلۡمَطۡلُوبُ")

                    ScriptureQuote(text: "“And those they invoke other than Allah create nothing, and they [themselves] are created. They are, [in fact], dead, not alive, and they do not perceive when they will be resurrected” (Quran 16:20-21).", arabic: "وَٱلَّذِينَ يَدۡعُونَ مِن دُونِ ٱللَّهِ لَا يَخۡلُقُونَ شَيۡـٔٗا وَهُمۡ يُخۡلَقُونَ ۝ أَمۡوَٰتٌ غَيۡرُ أَحۡيَآءٖۖ وَمَا يَشۡعُرُونَ أَيَّانَ يُبۡعَثُونَ")

                    Text("A statue is made by a man from stone; the one who made it is greater than it. And Allah has no form to be carved:")
                        .font(.body)
                    ScriptureQuote(text: "“There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).", arabic: "لَيۡسَ كَمِثۡلِهِۦ شَيۡءٞۖ وَهُوَ ٱلسَّمِيعُ ٱلۡبَصِيرُ")

                    Text("If the images are meant only as “aids“ to reach the one Brahman behind them, that is the very excuse of the pagans of Makkah, and the Quran rejected it (Quran 39:3). Allah is reached directly, without images or intermediaries (Quran 2:186).")
                        .font(.body)
                }

                Section(header: Text("3. RESURRECTION, NOT REBIRTH")) {
                    Text("There is no cycle of rebirth. Each soul lives once, dies once, and is raised once to be judged, with full justice and no forgetting:")
                        .font(.body)
                    ScriptureQuote(text: "“[For such is the state of the disbelievers], until, when death comes to one of them, he says, ‘My Lord, send me back that I might do righteousness in that which I left behind.’ No! It is only a word he is saying; and behind them is a barrier until the Day they are resurrected” (Quran 23:99-100).", arabic: "حَتَّىٰٓ إِذَا جَآءَ أَحَدَهُمُ ٱلۡمَوۡتُ قَالَ رَبِّ ٱرۡجِعُونِ ۝ لَعَلِّيٓ أَعۡمَلُ صَٰلِحٗا فِيمَا تَرَكۡتُۚ كـَلَّآۚ إِنَّهَا كَلِمَةٌ هُوَ قَآئِلُهَاۖ وَمِن وَرَآئِهِم بَرۡزَخٌ إِلَىٰ يَوۡمِ يُبۡعَثُونَ")

                    ScriptureQuote(text: "“Does man think that We will not assemble his bones? Yes. [We are] Able [even] to proportion his fingertips” (Quran 75:3-4).", arabic: "أَيَحۡسَبُ ٱلۡإِنسَٰنُ أَلَّن نَّجۡمَعَ عِظَامَهُۥ ۝ بَلَىٰ قَٰدِرِينَ عَلَىٰٓ أَن نُّسَوِّيَ بَنَانَهُۥ")

                    ScriptureQuote(text: "“So whoever does an atom's weight of good will see it, and whoever does an atom's weight of evil will see it” (Quran 99:7-8).", arabic: "فَمَن يَعۡمَلۡ مِثۡقَالَ ذَرَّةٍ خَيۡرٗا يَرَهُۥ ۝ وَمَن يَعۡمَلۡ مِثۡقَالَ ذَرَّةٖ شَرّٗا يَرَهُۥ")

                    Text("The idea of karma reaches for justice, and Islam gives it in full: every deed is recorded and repaid, but by a Judge who knows, not by a blind law, and with a mercy that forgives the one who repents. Nobody is punished for a life he cannot remember.")
                        .font(.body)
                }

                Section(header: Text("4. NO CASTE BEFORE ALLAH")) {
                    ScriptureQuote(text: "“O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another. Indeed, the most noble of you in the sight of Allah is the most righteous of you. Indeed, Allah is Knowing and Acquainted” (Quran 49:13).", arabic: "يَٰٓأَيُّهَا ٱلنَّاسُ إِنَّا خَلَقۡنَٰكُم مِّن ذَكَرٖ وَأُنثَىٰ وَجَعَلۡنَٰكُمۡ شُعُوبٗا وَقَبَآئِلَ لِتَعَارَفُوٓاْۚ إِنَّ أَكۡرَمَكُمۡ عِندَ ٱللَّهِ أَتۡقَىٰكُمۡۚ إِنَّ ٱللَّهَ عَلِيمٌ خَبِيرٞ")

                    ScriptureQuote(text: "“And We have certainly honored the children of Adam and carried them on the land and sea and provided for them of the good things and preferred them over much of what We have created, with [definite] preference” (Quran 17:70).", arabic: "وَلَقَدۡ كَرَّمۡنَا بَنِيٓ ءَادَمَ وَحَمَلۡنَٰهُمۡ فِي ٱلۡبَرِّ وَٱلۡبَحۡرِ وَرَزَقۡنَٰهُم مِّنَ ٱلطَّيِّبَٰتِ وَفَضَّلۡنَٰهُمۡ عَلَىٰ كَثِيرٖ مِّمَّنۡ خَلَقۡنَا تَفۡضِيلٗا")

                    Text("In the Farewell Sermon the Prophet (peace be upon him) declared that no Arab has superiority over a non-Arab, nor a white man over a black man, nor a black man over a white man, except by piety (Musnad Ahmad 23489; graded sahih by al-Albani). Bilal, an Abyssinian former slave, gave the call to prayer from the roof of the Ka‘bah. There is no priestly caste in Islam and no untouchable; all stand shoulder to shoulder in one row.")
                        .font(.body)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Do Hindus and Muslims worship the same God?**")
                        .font(.body)
                    Text("There is only one Creator, and whoever turns to the Maker of the heavens and the earth is turning to Him; the Quran told the Muslims to say to the People of the Scripture:")
                        .font(.body)
                    ScriptureQuote(text: "“And our God and your God is one; and we are Muslims [in submission] to Him” (Quran 29:46).", arabic: "وَإِلَٰهُنَا وَإِلَٰهُكُمۡ وَٰحِدٞ وَنَحۡنُ لَهُۥ مُسۡلِمُونَ")
                    Text("But worship offered to murtis, to avatars, or to a pantheon of devas is not worship of that One; it is what Ibrahim (peace be upon him) rebuked in his father and his people (Quran 21:52-54). Allah accepts worship only when it is His alone:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, Allah does not forgive association with Him, but He forgives what is less than that for whom He wills. And he who associates others with Allah has certainly fabricated a tremendous sin” (Quran 4:48).", arabic: "إِنَّ ٱللَّهَ لَا يَغۡفِرُ أَن يُشۡرَكَ بِهِۦ وَيَغۡفِرُ مَا دُونَ ذَٰلِكَ لِمَن يَشَآءُۚ وَمَن يُشۡرِكۡ بِٱللَّهِ فَقَدِ ٱفۡتَرَىٰٓ إِثۡمًا عَظِيمًا")

                    Text("**Did Hindu scriptures mention Muhammad (peace be upon him)?**")
                        .font(.body)
                    Text("Some Muslims point to passages in the Vedas and Puranas that they read as prophecies of a final messenger. These readings are disputed, and Islam does not rest on them; the Prophet’s truth is proved by the Quran itself. What is certain is that no people was left without a warner, so India too was reached by Allah’s message in its time, whether or not any record of it survives:")
                        .font(.body)
                    ScriptureQuote(text: "“And there was no nation but that there had passed within it a warner” (Quran 35:24).", arabic: "وَإِن مِّنۡ أُمَّةٍ إِلَّا خَلَا فِيهَا نَذِيرٞ")
                    ScriptureQuote(text: "“And We certainly sent into every nation a messenger, [saying], ‘Worship Allah and avoid Taghut’” (Quran 16:36).", arabic: "وَلَقَدۡ بَعَثۡنَا فِي كُلِّ أُمَّةٖ رَّسُولًا أَنِ ٱعۡبُدُواْ ٱللَّهَ وَٱجۡتَنِبُواْ ٱلطَّٰغُوتَۖ")
                    Text("Every messenger spoke the language of his people (Quran 14:4), and Allah has told us the stories of some messengers and not of others (Quran 40:78). We do not put names to the ones He did not name.")
                        .font(.body)

                    Text("**Were Rama or Krishna prophets?**")
                        .font(.body)
                    Text("We do not know, and we neither affirm nor deny it, for Allah has told us of some messengers and not of others (Quran 4:164):")
                        .font(.body)
                    ScriptureQuote(text: "“And We have already sent messengers before you. Among them are those [whose stories] We have related to you, and among them are those [whose stories] We have not related to you” (Quran 40:78).", arabic: "وَلَقَدۡ أَرۡسَلۡنَا رُسُلٗا مِّن قَبۡلِكَ مِنۡهُم مَّن قَصَصۡنَا عَلَيۡكَ وَمِنۡهُم مَّن لَّمۡ نَقۡصُصۡ عَلَيۡكَۗ")
                    Text("What we do know is what every true messenger taught, so if a prophet was sent to India, this was his message:")
                        .font(.body)
                    ScriptureQuote(text: "“And We sent not before you any messenger except that We revealed to him that, ‘There is no deity except Me, so worship Me’” (Quran 21:25).", arabic: "وَمَآ أَرۡسَلۡنَا مِن قَبۡلِكَ مِن رَّسُولٍ إِلَّا نُوحِيٓ إِلَيۡهِ أَنَّهُۥ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعۡبُدُونِ")
                    Text("The stories that make Rama or Krishna an incarnation of God, and the worship offered to their images, cannot come from a prophet, because no prophet is ever worshipped and no prophet ever asked to be:")
                        .font(.body)
                    ScriptureQuote(text: "“It is not for a human [prophet] that Allah should give him the Scripture and authority and prophethood and then he would say to the people, ‘Be servants to me rather than Allah,’ but [instead, he would say], ‘Be pious scholars of the Lord because of what you have taught of the Scripture and because of what you have studied.’ Nor could he order you to take the angels and prophets as lords. Would he order you to disbelief after you had been Muslims?” (Quran 3:79-80).", arabic: "مَا كَانَ لِبَشَرٍ أَن يُؤۡتِيَهُ ٱللَّهُ ٱلۡكِتَٰبَ وَٱلۡحُكۡمَ وَٱلنُّبُوَّةَ ثُمَّ يَقُولَ لِلنَّاسِ كُونُواْ عِبَادٗا لِّي مِن دُونِ ٱللَّهِ وَلَٰكِن كُونُواْ رَبَّٰنِيِّـۧنَ بِمَا كُنتُمۡ تُعَلِّمُونَ ٱلۡكِتَٰبَ وَبِمَا كُنتُمۡ تَدۡرُسُونَ ۝ وَلَا يَأۡمُرَكُمۡ أَن تَتَّخِذُواْ ٱلۡمَلَٰٓئِكَةَ وَٱلنَّبِيِّـۧنَ أَرۡبَابًاۚ أَيَأۡمُرُكُم بِٱلۡكُفۡرِ بَعۡدَ إِذۡ أَنتُم مُّسۡلِمُونَ")
                    Text("This is the same answer Islam gives about Isa (peace be upon him): a true messenger, later raised by his followers to a rank he never claimed.")
                        .font(.body)

                    Text("**Is yoga allowed?**")
                        .font(.body)
                    Text("Stretching, breathing exercises, and postures done purely for the health of the body are permitted, like any exercise, so long as nothing of Hindu belief or ritual is attached to them. What is not permitted is the religious core of yoga: the Sun Salutation (surya namaskar), which is by name and by form a sequence of bowing to the sun; chanting OM or mantras to deities; and the aim of “union” with Brahman or of awakening a divine energy within. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not prostrate to the sun or to the moon, but prostate to Allah, who created them” (Quran 41:37).", arabic: "لَا تَسۡجُدُواْ لِلشَّمۡسِ وَلَا لِلۡقَمَرِ وَٱسۡجُدُواْۤ لِلَّهِۤ ٱلَّذِي خَلَقَهُنَّ")
                    ScriptureQuote(text: "“And [yet], among the people are those who take other than Allah as equals [to Him]. They love them as they [should] love Allah. But those who believe are stronger in love for Allah” (Quran 2:165).", arabic: "وَمِنَ ٱلنَّاسِ مَن يَتَّخِذُ مِن دُونِ ٱللَّهِ أَندَادٗا يُحِبُّونَهُمۡ كَحُبِّ ٱللَّهِۖ وَٱلَّذِينَ ءَامَنُوٓاْ أَشَدُّ حُبّٗا لِّلَّهِۗ")
                    Text("The Muslim who wants stillness and discipline has the prayer, the night prayer, dhikr, and reflection on creation, none of which borrow the rites of another religion. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“He who copies any people is one of them” (Sunan Abi Dawud 4031; graded hasan sahih by al-Albani).", arabic: "مَنْ تَشَبَّهَ بِقَوْمٍ فَهُوَ مِنْهُمْ", dimmed: true)
                    Text("The pagans of Makkah were told: “For you is your religion, and for me is my religion” (Quran 109:6). A Muslim keeps his worship unmixed.")
                        .font(.body)

                    Text("**Why do Muslims eat beef while Hindus revere the cow?**")
                        .font(.body)
                    Text("Because Allah, who created the cattle, made them lawful and named them among His gifts:")
                        .font(.body)
                    ScriptureQuote(text: "“Lawful for you are the animals of grazing livestock except for that which is recited to you [in this Qur'an]” (Quran 5:1).", arabic: "أُحِلَّتۡ لَكُم بَهِيمَةُ ٱلۡأَنۡعَٰمِ إِلَّا مَا يُتۡلَىٰ عَلَيۡكُمۡ")
                    ScriptureQuote(text: "“And the grazing livestock He has created for you; in them is warmth and [numerous] benefits, and from them you eat” (Quran 16:5).", arabic: "وَٱلۡأَنۡعَٰمَ خَلَقَهَاۖ لَكُمۡ فِيهَا دِفۡءٞ وَمَنَٰفِعُ وَمِنۡهَا تَأۡكُلُونَ")
                    Text("The pagan Arabs also set animals apart for their idols: beasts no one might eat but whom they chose, and camels whose backs they forbade, and the Quran rebuked them for it (Quran 6:138-139):")
                        .font(.body)
                    ScriptureQuote(text: "“Allah has not appointed [such innovations as] bahirah or sa'ibah or wasilah or ham. But those who disbelieve invent falsehood about Allah” (Quran 5:103).", arabic: "مَا جَعَلَ ٱللَّهُ مِنۢ بَحِيرَةٖ وَلَا سَآئِبَةٖ وَلَا وَصِيلَةٖ وَلَا حَامٖ وَلَٰكِنَّ ٱلَّذِينَ كَفَرُواْ يَفۡتَرُونَ عَلَى ٱللَّهِ ٱلۡكَذِبَۖ")
                    Text("The Prophet (peace be upon him) himself sacrificed cows. Aishah (may Allah be pleased with her) said of the Farewell Hajj:")
                        .font(.body)
                    ScriptureQuote(text: "“On the day of Nahr beef was brought to us. I asked, ‘What is this?’ The reply was, ‘Allah’s Messenger (peace be upon him) has slaughtered on behalf of his wives’” (Sahih al-Bukhari 1709).", arabic: "فَدُخِلَ عَلَيْنَا يَوْمَ النَّحْرِ بِلَحْمِ بَقَرٍ. فَقُلْتُ مَا هَذَا قَالَ نَحَرَ رَسُولُ اللَّهِ صلى الله عليه وسلم عَنْ أَزْوَاجِهِ", dimmed: true)
                    Text("The Quran also records two warnings about sanctifying an animal: the calf that Bani Isra’il worshipped in Musa’s absence, of which Allah said:")
                        .font(.body)
                    ScriptureQuote(text: "“And he extracted for them [the statue of] a calf which had a lowing sound, and they said, ‘This is your god and the god of Moses, but he forgot.’ Did they not see that it could not return to them any speech and that it did not possess for them any harm or benefit?” (Quran 20:88-89).", arabic: "فَأَخۡرَجَ لَهُمۡ عِجۡلٗا جَسَدٗا لَّهُۥ خُوَارٞ فَقَالُواْ هَٰذَآ إِلَٰهُكُمۡ وَإِلَٰهُ مُوسَىٰ فَنَسِيَ ۝ أَفَلَا يَرَوۡنَ أَلَّا يَرۡجِعُ إِلَيۡهِمۡ قَوۡلٗا وَلَا يَمۡلِكُ لَهُمۡ ضَرّٗا وَلَا نَفۡعٗا")
                    Text("And the cow that Bani Isra’il were commanded to slaughter (Quran 2:67-71), from which the longest surah of the Quran takes its name, al-Baqarah. At the same time Islam commands kindness to every animal; the Prophet (peace be upon him) said that Allah has prescribed ihsan in everything, even in slaughter (Sahih Muslim 1955). A Muslim eats beef with gratitude and never with mockery of his Hindu neighbour.")
                        .font(.body)

                    Text("**Reincarnation or resurrection?**")
                        .font(.body)
                    Text("Resurrection. The soul does not pass from body to body; it is taken at death, held in the barzakh, and returned to its own body on the Day of Judgement (Quran 23:99-100; 39:42). The One who made the body the first time will remake it:")
                        .font(.body)
                    ScriptureQuote(text: "“And he presents for Us an example and forgets his [own] creation. He says, ‘Who will give life to bones while they are disintegrated?’ Say, ‘He will give them life who produced them the first time; and He is, of all creation, Knowing’” (Quran 36:78-79).", arabic: "وَضَرَبَ لَنَا مَثَلٗا وَنَسِيَ خَلۡقَهُۥۖ قَالَ مَن يُحۡيِ ٱلۡعِظَٰمَ وَهِيَ رَمِيمٞ ۝ قُلۡ يُحۡيِيهَا ٱلَّذِيٓ أَنشَأَهَآ أَوَّلَ مَرَّةٖۖ وَهُوَ بِكُلِّ خَلۡقٍ عَلِيمٌ")
                    Text("The same person who acted is the one who answers, and he remembers. Even the punishment of the Fire is described as happening to one continuing body:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, those who disbelieve in Our verses - We will drive them into a Fire. Every time their skins are roasted through We will replace them with other skins so they may taste the punishment. Indeed, Allah is ever Exalted in Might and Wise” (Quran 4:56).", arabic: "إِنَّ ٱلَّذِينَ كَفَرُواْ بِـَٔايَٰتِنَا سَوۡفَ نُصۡلِيهِمۡ نَارٗا كُلَّمَا نَضِجَتۡ جُلُودُهُم بَدَّلۡنَٰهُمۡ جُلُودًا غَيۡرَهَا لِيَذُوقُواْ ٱلۡعَذَابَۗ إِنَّ ٱللَّهَ كَانَ عَزِيزًا حَكِيمٗا")
                    Text("And the people of Paradise die only once:")
                        .font(.body)
                    ScriptureQuote(text: "“They will not taste death therein except the first death, and He will have protected them from the punishment of Hellfire” (Quran 44:56).", arabic: "لَا يَذُوقُونَ فِيهَا ٱلۡمَوۡتَ إِلَّا ٱلۡمَوۡتَةَ ٱلۡأُولَىٰۖ وَوَقَىٰهُمۡ عَذَابَ ٱلۡجَحِيمِ")
                    Text("Reincarnation punishes a person for a life he cannot remember and rewards him for one he cannot recall; the resurrection judges a man for what he knows he did, with his own limbs as witnesses (Quran 36:65).")
                        .font(.body)

                    Text("**Caste or equality?**")
                        .font(.body)
                    Text("Equality of origin and of worth, with rank only by piety (Quran 49:13). The Farewell Sermon abolished the superiority of Arab over non-Arab and of one colour over another (mentioned above). The Prophet (peace be upon him) also said:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed Allah has removed the pride of Jahiliyyah from you, and its boasting about lineage. [Indeed a person is either] a pious believer or a miserable sinner. And people are all the children of Adam, and Adam was [created] from dust” (Sunan al-Tirmidhi 3955; graded hasan by al-Albani).", arabic: "إِنَّ اللَّهَ قَدْ أَذْهَبَ عَنْكُمْ عُبِّيَّةَ الْجَاهِلِيَّةِ إِنَّمَا هُوَ مُؤْمِنٌ تَقِيٌّ وَفَاجِرٌ شَقِيٌّ النَّاسُ كُلُّهُمْ بَنُو آدَمَ وَآدَمُ خُلِقَ مِنْ تُرَابٍ", dimmed: true)
                    Text("When Abu Dharr (may Allah be pleased with him) insulted a man by his mother, the Prophet (peace be upon him) told him:")
                        .font(.body)
                    ScriptureQuote(text: "“O Abu Dhar! Did you abuse him by calling his mother with bad names? You still have some characteristics of ignorance. Your slaves are your brothers and Allah has put them under your command” (Sahih al-Bukhari 30).", arabic: "يَا أَبَا ذَرٍّ أَعَيَّرْتَهُ بِأُمِّهِ إِنَّكَ امْرُؤٌ فِيكَ جَاهِلِيَّةٌ، إِخْوَانُكُمْ خَوَلُكُمْ، جَعَلَهُمُ اللَّهُ تَحْتَ أَيْدِيكُمْ", dimmed: true)
                    Text("Bilal the Abyssinian, Salman the Persian, and Suhayb the Roman (may Allah be pleased with them) sat with the nobles of Quraysh as equals. Zayd ibn Harithah, a freed slave, commanded the army at Mu’tah (Sahih al-Bukhari 4261), and when some criticised the command of his son Usamah, the Prophet (peace be upon him) said that Zayd had deserved the leadership and was among the most beloved of people to him, and that Usamah was so after him (Sahih al-Bukhari 4469). In every mosque the rich man and the poor man stand in one row and prostrate on one floor. No one is born a priest, and no one is born untouchable.")
                        .font(.body)

                    Text("**Is Islam a foreign Arab religion for India?**")
                        .font(.body)
                    Text("Islam came to the Arabs first but was never for them alone:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have not sent you except comprehensively to mankind as a bringer of good tidings and a warner” (Quran 34:28).", arabic: "وَمَآ أَرۡسَلۡنَٰكَ إِلَّا كَآفَّةٗ لِّلنَّاسِ بَشِيرٗا وَنَذِيرٗا")
                    ScriptureQuote(text: "“And We have not sent you, [O Muhammad], except as a mercy to the worlds” (Quran 21:107).", arabic: "وَمَآ أَرۡسَلۡنَٰكَ إِلَّا رَحۡمَةٗ لِّلۡعَٰلَمِينَ")
                    Text("Among the Companions were an Abyssinian, a Persian, and a Roman. When Surat al-Jumu‘ah was revealed and Abu Hurayrah asked who the “others” not yet joined to the Arabs were, the Prophet (peace be upon him) put his hand on Salman al-Farisi and said:")
                        .font(.body)
                    ScriptureQuote(text: "“If faith were at the Pleiades, men, or a man, from these people would attain it” (Sahih al-Bukhari 4897).", arabic: "لَوْ كَانَ الإِيمَانُ عِنْدَ الثُّرَيَّا لَنَالَهُ رِجَالٌ ـ أَوْ رَجُلٌ ـ مِنْ هَؤُلاَءِ", dimmed: true)
                    Text("Muhammad ibn al-Qasim entered Sindh in 92-93 AH (711-712 CE), within a century of the Hijrah (al-Baladhuri, Futuh al-Buldan), and today more Muslims live in South Asia than in all the Arab lands together. A religion is not judged by the land it started in but by whether it is true; Ibrahim, Musa, and Isa (peace be upon them) were none of them Indian, and the truth they brought was for every land.")
                        .font(.body)

                    Text("**What about karma and justice?**")
                        .font(.body)
                    Text("Islam gives everything karma reaches for and more. Every deed is weighed (Quran 99:7-8), no one is wronged, and good is multiplied (Quran 4:40). No soul carries another’s burden:")
                        .font(.body)
                    ScriptureQuote(text: "“And every soul earns not [blame] except against itself, and no bearer of burdens will bear the burden of another” (Quran 6:164).", arabic: "وَلَا تَكۡسِبُ كُلُّ نَفۡسٍ إِلَّا عَلَيۡهَاۚ وَلَا تَزِرُ وَازِرَةٞ وِزۡرَ أُخۡرَىٰۚ")
                    ScriptureQuote(text: "“That no bearer of burdens will bear the burden of another and that there is not for man except that [good] for which he strives and that his effort is going to be seen - then he will be recompensed for it with the fullest recompense” (Quran 53:38-41).", arabic: "أَلَّا تَزِرُ وَازِرَةٞ وِزۡرَ أُخۡرَىٰ ۝ وَأَن لَّيۡسَ لِلۡإِنسَٰنِ إِلَّا مَا سَعَىٰ ۝ وَأَنَّ سَعۡيَهُۥ سَوۡفَ يُرَىٰ ۝ ثُمَّ يُجۡزَىٰهُ ٱلۡجَزَآءَ ٱلۡأَوۡفَىٰ")
                    Text("But the Judge is a Person who sees, not a mechanism that grinds. He can be asked, and He forgives:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful’” (Quran 39:53).", arabic: "قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ")
                    Text("Karma has no one to repent to, no one to pray to, and no mercy; it explains the suffering of a child by a crime the child cannot remember. Islam says the child is innocent, the trial has a purpose, and the account is settled once, in full, before a Lord who is both Just and Merciful.")
                        .font(.body)

                    Text("**Do Muslims believe in an impersonal absolute like Brahman?**")
                        .font(.body)
                    Text("No. Allah is not a force, a principle, or a ground of being; He is a living Lord who describes Himself by name:")
                        .font(.body)
                    ScriptureQuote(text: "“He is Allah, other than whom there is no deity, Knower of the unseen and the witnessed. He is the Entirely Merciful, the Especially Merciful. He is Allah, other than whom there is no deity, the Sovereign, the Pure, the Perfection, the Bestower of Faith, the Overseer, the Exalted in Might, the Compeller, the Superior. Exalted is Allah above whatever they associate with Him. He is Allah, the Creator, the Inventor, the Fashioner; to Him belong the best names. Whatever is in the heavens and earth is exalting Him. And He is the Exalted in Might, the Wise” (Quran 59:22-24).", arabic: "هُوَ ٱللَّهُ ٱلَّذِي لَآ إِلَٰهَ إِلَّا هُوَۖ عَٰلِمُ ٱلۡغَيۡبِ وَٱلشَّهَٰدَةِۖ هُوَ ٱلرَّحۡمَٰنُ ٱلرَّحِيمُ ۝ هُوَ ٱللَّهُ ٱلَّذِي لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡمَلِكُ ٱلۡقُدُّوسُ ٱلسَّلَٰمُ ٱلۡمُؤۡمِنُ ٱلۡمُهَيۡمِنُ ٱلۡعَزِيزُ ٱلۡجَبَّارُ ٱلۡمُتَكَبِّرُۚ سُبۡحَٰنَ ٱللَّهِ عَمَّا يُشۡرِكُونَ ۝ هُوَ ٱللَّهُ ٱلۡخَٰلِقُ ٱلۡبَارِئُ ٱلۡمُصَوِّرُۖ لَهُ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰۚ يُسَبِّحُ لَهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ وَهُوَ ٱلۡعَزِيزُ ٱلۡحَكِيمُ")
                    Text("He is One without parts or equal (Quran 112), nothing is like Him (Quran 42:11), and He is near to whoever calls Him (Quran 2:186). In a hadith qudsi He says:")
                        .font(.body)
                    ScriptureQuote(text: "“I am just as My slave thinks I am, and I am with him if he remembers Me. If he remembers Me in himself, I too remember him in Myself; and if he remembers Me in a group of people, I remember him in a group that is better than they; and if he comes one span nearer to Me, I go one cubit nearer to him; and if he comes one cubit nearer to Me, I go a distance of two outstretched arms nearer to him; and if he comes to Me walking, I go to him running” (Sahih al-Bukhari 7405).", arabic: "أَنَا عِنْدَ ظَنِّ عَبْدِي بِي، وَأَنَا مَعَهُ إِذَا ذَكَرَنِي، فَإِنْ ذَكَرَنِي فِي نَفْسِهِ ذَكَرْتُهُ فِي نَفْسِي، وَإِنْ ذَكَرَنِي فِي مَلأٍ ذَكَرْتُهُ فِي مَلأٍ خَيْرٍ مِنْهُمْ، وَإِنْ تَقَرَّبَ إِلَىَّ بِشِبْرٍ تَقَرَّبْتُ إِلَيْهِ ذِرَاعًا، وَإِنْ تَقَرَّبَ إِلَىَّ ذِرَاعًا تَقَرَّبْتُ إِلَيْهِ بَاعًا، وَإِنْ أَتَانِي يَمْشِي أَتَيْتُهُ هَرْوَلَةً", dimmed: true)
                    Text("An impersonal absolute cannot love you, hear you, or forgive you. Allah does all three.")
                        .font(.body)

                    Text("**Does Islam accept the Vedas or the Gita as revelation?**")
                        .font(.body)
                    Text("We do not know their origin, and we neither declare them revealed nor declare that no revelation ever reached India (Quran 40:78). The rule the Prophet (peace be upon him) gave for the books of others is this:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not believe the people of the Scripture or disbelieve them, but say: ‘We believe in Allah and what is revealed to us’” (Sahih al-Bukhari 4485).", arabic: "لاَ تُصَدِّقُوا أَهْلَ الْكِتَابِ وَلاَ تُكَذِّبُوهُمْ، وَقُولُوا آمَنَّا بِاللَّهِ وَمَا أُنْزِلَ", dimmed: true)
                    Text("The Quran is the guardian and judge over whatever came before:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have revealed to you, [O Muhammad], the Book in truth, confirming that which preceded it of the Scripture and as a criterion over it” (Quran 5:48).", arabic: "وَأَنزَلۡنَآ إِلَيۡكَ ٱلۡكِتَٰبَ بِٱلۡحَقِّ مُصَدِّقٗا لِّمَا بَيۡنَ يَدَيۡهِ مِنَ ٱلۡكِتَٰبِ وَمُهَيۡمِنًا عَلَيۡهِۖ")
                    Text("So the sentences in the Upanishads that say the One has no image and no second are true, and we say so gladly; the hymns to many gods, the caste of the Purusha Sukta, and the avatars are not from Allah, and we say that too.")
                        .font(.body)
                }

                Section(header: Text("THE INVITATION")) {
                    Text("Islam asks the Hindu to keep what the oldest of his scriptures said, that the One has no image and no second, and to leave the many gods for the One who made them all:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Who is Lord of the heavens and earth?’ Say, ‘Allah.’ Say, ‘Have you then taken besides Him allies not possessing [even] for themselves any benefit or any harm?’ Say, ‘Is the blind equivalent to the seeing? Or is darkness equivalent to light?’” (Quran 13:16).", arabic: "قُلۡ مَن رَّبُّ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ قُلِ ٱللَّهُۚ قُلۡ أَفَٱتَّخَذۡتُم مِّن دُونِهِۦٓ أَوۡلِيَآءَ لَا يَمۡلِكُونَ لِأَنفُسِهِمۡ نَفۡعٗا وَلَا ضَرّٗاۚ قُلۡ هَلۡ يَسۡتَوِي ٱلۡأَعۡمَىٰ وَٱلۡبَصِيرُ أَمۡ هَلۡ تَسۡتَوِي ٱلظُّلُمَٰتُ وَٱلنُّورُۗ")

                    ScriptureQuote(text: "“Invite to the way of your Lord with wisdom and good instruction, and argue with them in a way that is best” (Quran 16:125).", arabic: "ٱدۡعُ إِلَىٰ سَبِيلِ رَبِّكَ بِٱلۡحِكۡمَةِ وَٱلۡمَوۡعِظَةِ ٱلۡحَسَنَةِۖ وَجَٰدِلۡهُم بِٱلَّتِي هِيَ أَحۡسَنُۚ")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("One Creator without image, one life followed by judgement, and one humanity ranked only by piety: this is what Ibrahim taught in a land of idols, and what Islam offers in its place.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Hinduism")
        .selectableArticleList()
    }
}

struct PaganismAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: paganism, old and new, worships created things: idols, spirits, ancestors, nature, and stars. The Quran shows where idol worship came from, why the pagans' own admission that Allah is the Creator refutes them, and why nothing created deserves worship.")
                        .font(.body)
                }

                Section(header: Text("WHAT IS PAGANISM?")) {
                    Text("**Shirk (شِرك)** in its oldest form: the worship of many gods, idols carved from stone and wood, spirits of the dead, sacred trees and stones, the sun, moon, and stars, and the spirits of places. The Arabs of Makkah were pagans of this kind, with 360 idols around the Ka‘bah, and the Quran addressed them first. Modern paganism, whether tribal, “new age,“ or a revival of old European and Near Eastern cults, is the same thing with new names.")
                        .font(.body)

                    Text("Ibn Abbas (may Allah be pleased with him) explained how it began. The idols of the people of Nuh, Wadd, Suwa‘, Yaghuth, Ya‘uq, and Nasr, were the names of righteous men:")
                        .font(.body)
                    ScriptureQuote(text: "“When they died, Shaytan inspired their people to set up statues in the places where they used to sit and to name them after them. They did so, and they were not worshipped, until those people died and the knowledge was forgotten; then they were worshipped” (Sahih al-Bukhari 4920).", arabic: "فَلَمَّا هَلَكُوا أَوْحَى الشَّيْطَانُ إِلَى قَوْمِهِمْ أَنِ انْصِبُوا إِلَى مَجَالِسِهِمُ الَّتِي كَانُوا يَجْلِسُونَ أَنْصَابًا، وَسَمُّوهَا بِأَسْمَائِهِمْ فَفَعَلُوا فَلَمْ تُعْبَدْ حَتَّى إِذَا هَلَكَ أُولَئِكَ وَتَنَسَّخَ الْعِلْمُ عُبِدَتْ", dimmed: true)

                    Text("Every idol began as excess in honouring someone or something Allah created. That is why Islam guards so carefully against the veneration of graves and saints: it is the road paganism took.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Paganism / wathaniyyah (الوَثَنِيَّة)**: from **wathan (وَثَن)**, an idol; the scholars of language say a wathan is anything set up to be worshipped, of stone or otherwise, while a **sanam (صَنَم)** is an image carved in a form. The Quran uses both words for what Ibrahim (peace be upon him) rejected:")
                        .font(.body)
                    ScriptureQuote(text: "“So avoid the uncleanliness of idols and avoid false statement” (Quran 22:30).", arabic: "فَٱجۡتَنِبُواْ ٱلرِّجۡسَ مِنَ ٱلۡأَوۡثَٰنِ وَٱجۡتَنِبُواْ قَوۡلَ ٱلزُّورِ")
                    ScriptureQuote(text: "“You only worship, besides Allah, idols, and you produce a falsehood. Indeed, those you worship besides Allah do not possess for you [the power of] provision. So seek from Allah provision and worship Him and be grateful to Him” (Quran 29:17).", arabic: "إِنَّمَا تَعۡبُدُونَ مِن دُونِ ٱللَّهِ أَوۡثَٰنٗا وَتَخۡلُقُونَ إِفۡكًاۚ إِنَّ ٱلَّذِينَ تَعۡبُدُونَ مِن دُونِ ٱللَّهِ لَا يَمۡلِكُونَ لَكُمۡ رِزۡقٗا فَٱبۡتَغُواْ عِندَ ٱللَّهِ ٱلرِّزۡقَ وَٱعۡبُدُوهُ وَٱشۡكُرُواْ لَهُۥٓۖ")

                    Text("**Shirk (شِرْك)**: from sharika, to share; giving to another any of what belongs to Allah alone: worship, prayer, sacrifice, vows, fear, hope, or lordship. It is the essence of every paganism and the one sin not forgiven for the one who dies upon it (Quran 4:48):")
                        .font(.body)
                    ScriptureQuote(text: "“And he who associates with Allah - it is as though he had fallen from the sky and was snatched by the birds or the wind carried him down into a remote place” (Quran 22:31).", arabic: "وَمَن يُشۡرِكۡ بِٱللَّهِ فَكَأَنَّمَا خَرَّ مِنَ ٱلسَّمَآءِ فَتَخۡطَفُهُ ٱلطَّيۡرُ أَوۡ تَهۡوِي بِهِ ٱلرِّيحُ فِي مَكَانٖ سَحِيقٖ")

                    Text("**Taghut (طَاغُوت)**: from tagha, to exceed all bounds; Ibn al-Qayyim (may Allah have mercy on him) defined it as anything by which a servant exceeds his limit, whether something worshipped, followed, or obeyed in place of Allah (I‘lam al-Muwaqqi‘in). Every idol set up to be served in Allah’s place, and every devil who calls people to it, is a taghut; the righteous man venerated without his consent is not one, and he will disown those who worshipped him on the Day of Judgement. Rejecting the taghut is the first half of faith:")
                        .font(.body)
                    ScriptureQuote(text: "“So whoever disbelieves in Taghut and believes in Allah has grasped the most trustworthy handhold with no break in it” (Quran 2:256).", arabic: "فَمَن يَكۡفُرۡ بِٱلطَّٰغُوتِ وَيُؤۡمِنۢ بِٱللَّهِ فَقَدِ ٱسۡتَمۡسَكَ بِٱلۡعُرۡوَةِ ٱلۡوُثۡقَىٰ لَا ٱنفِصَامَ لَهَاۗ")
                    ScriptureQuote(text: "“But those who have avoided Taghut, lest they worship it, and turned back to Allah - for them are good tidings” (Quran 39:17).", arabic: "وَٱلَّذِينَ ٱجۡتَنَبُواْ ٱلطَّٰغُوتَ أَن يَعۡبُدُوهَا وَأَنَابُوٓاْ إِلَى ٱللَّهِ لَهُمُ ٱلۡبُشۡرَىٰۚ")

                    Text("**Jahiliyyah (جَاهِلِيَّة)**: “the age of ignorance,” the state of the Arabs before revelation: idols, blood feuds, burying daughters, usury, boasting of lineage, and omens. The Quran uses the word for the traits themselves, in the zeal of the disbelievers and even in the thoughts and display it warns the believers against (Quran 48:26; 3:154; 33:33); the Prophet (peace be upon him) told Abu Dharr, when he insulted a man by his mother, that he was a man in whom there was still jahiliyyah (Sahih al-Bukhari 30). Allah asks:")
                        .font(.body)
                    ScriptureQuote(text: "“Then is it the judgement of [the time of] ignorance they desire? But who is better than Allah in judgement for a people who are certain [in faith]” (Quran 5:50).", arabic: "أَفَحُكۡمَ ٱلۡجَٰهِلِيَّةِ يَبۡغُونَۚ وَمَنۡ أَحۡسَنُ مِنَ ٱللَّهِ حُكۡمٗا لِّقَوۡمٖ يُوقِنُونَ")

                    Text("**Hubal, al-Lat, al-‘Uzza, and Manat**: the chief idols of the Arabs. Hubal stood at the Ka‘bah itself and was the idol of Quraysh; at Uhud Abu Sufyan, still a pagan, cried out in its name, and the Prophet (peace be upon him) had the Muslims answer him:")
                        .font(.body)
                    ScriptureQuote(text: "Abu Sufyan said, “Superior may be Hubal!” On that the Prophet said, “Reply to him.” They asked, “What may we say?” He said, “Say: Allah is More Elevated and More Majestic!” (Sahih al-Bukhari 4043).", arabic: "قَالَ أَبُو سُفْيَانَ أُعْلُ هُبَلْ. فَقَالَ النَّبِيُّ صلى الله عليه وسلم أَجِيبُوهُ. قَالُوا مَا نَقُولُ قَالَ قُولُوا اللَّهُ أَعْلَى وَأَجَلُّ", dimmed: true)
                    Text("Al-Lat was the idol of Thaqif at Ta’if; al-‘Uzza, the most honoured by Quraysh, was at Nakhlah on the road to Ta’if; and Manat stood at Qudayd by the sea, venerated by the Aws and Khazraj. The Quran named all three and mocked the claim that they were “daughters of Allah” while the pagans themselves wanted only sons:")
                        .font(.body)
                    ScriptureQuote(text: "“So have you considered al-Lat and al-'Uzza? And Manat, the third - the other one? Is the male for you and for Him the female? That, then, is an unjust division. They are not but [mere] names you have named them - you and your forefathers - for which Allah has sent down no authority. They follow not except assumption and what [their] souls desire, and there has already come to them from their Lord guidance” (Quran 53:19-23).", arabic: "أَفَرَءَيۡتُمُ ٱللَّٰتَ وَٱلۡعُزَّىٰ ۝ وَمَنَوٰةَ ٱلثَّالِثَةَ ٱلۡأُخۡرَىٰٓ ۝ أَلَكُمُ ٱلذَّكَرُ وَلَهُ ٱلۡأُنثَىٰ ۝ تِلۡكَ إِذٗا قِسۡمَةٞ ضِيزَىٰٓ ۝ إِنۡ هِيَ إِلَّآ أَسۡمَآءٞ سَمَّيۡتُمُوهَآ أَنتُمۡ وَءَابَآؤُكُم مَّآ أَنزَلَ ٱللَّهُ بِهَا مِن سُلۡطَٰنٍۚ إِن يَتَّبِعُونَ إِلَّا ٱلظَّنَّ وَمَا تَهۡوَى ٱلۡأَنفُسُۖ وَلَقَدۡ جَآءَهُم مِّن رَّبِّهِمُ ٱلۡهُدَىٰٓ")
                    Text("All of them were destroyed in the eighth and ninth years after the Hijrah (see the questions below).")
                        .font(.body)

                    Text("**‘Amr ibn Luhayy**: the chief of Khuza‘ah who, generations before the Prophet (peace be upon him), brought idol worship into the pure religion of Ibrahim and Isma‘il at Makkah. Ibn Ishaq relates, in the Sirah of Ibn Hisham, that he was the first to change the religion of Isma‘il: he brought the idol Hubal from Syria, set it up for the people to worship, and instituted the sacred animals that were dedicated to the gods. The Prophet (peace be upon him) saw his punishment:")
                        .font(.body)
                    ScriptureQuote(text: "“I saw ‘Amr bin ‘Amir bin Luhai al-Khuza‘i dragging his intestines in the Fire, for he was the first man who started the custom of releasing animals (for the sake of false gods)” (Sahih al-Bukhari 3521, Sahih Muslim 2856).", arabic: "رَأَيْتُ عَمْرَو بْنَ عَامِرِ بْنِ لُحَىٍّ الْخُزَاعِيَّ يَجُرُّ قُصْبَهُ فِي النَّارِ، وَكَانَ أَوَّلَ مَنْ سَيَّبَ السَّوَائِبَ", dimmed: true)

                    Text("**The idols of the people of Nuh**: Wadd, Suwa‘, Yaghuth, Ya‘uq, and Nasr (Quran 71:23), which Ibn Abbas (may Allah be pleased with him) explained were the names of righteous men whose statues were later worshipped (Sahih al-Bukhari 4920, quoted above). Ibn Taymiyyah (may Allah have mercy on him) drew from this the rule that shirk first entered mankind through excessive veneration of the righteous and their graves (Iqtida’ as-Sirat al-Mustaqim).")
                        .font(.body)

                    Text("**Tiyarah (طِيَرَة)**: from tayr, a bird; taking omens, originally from the flight of birds, then from any sign, day, number, or event. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Taking omens is polytheism; taking omens is polytheism.” He said it three times (Sunan Abi Dawud 3910; graded sahih by al-Albani).", arabic: "الطِّيَرَةُ شِرْكٌ الطِّيَرَةُ شِرْكٌ", dimmed: true)
                    Text("The narrator, Ibn Mas‘ud (may Allah be pleased with him), added that there is none of us but that something of it touches him, but Allah removes it by reliance on Him. The Prophet (peace be upon him) also said:")
                        .font(.body)
                    ScriptureQuote(text: "“There is no ‘adwa, nor tiyarah, nor hamah, nor safar” (Sahih al-Bukhari 5757).", arabic: "لاَ عَدْوَى، وَلاَ طِيَرَةَ، وَلاَ هَامَةَ، وَلاَ صَفَرَ", dimmed: true)
                    Text("That is: no disease spreads by itself without Allah’s decree, no bird-omen, no owl of the dead calling from a grave, and no ill luck in the month of Safar.")
                        .font(.body)

                    Text("**Kahin (كَاهِن)**: a fortune-teller or soothsayer who claims knowledge of the unseen, in the old Arabia by contact with a jinn. The Quran closes that door:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘None in the heavens and earth knows the unseen except Allah’” (Quran 27:65).", arabic: "قُل لَّا يَعۡلَمُ مَن فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ ٱلۡغَيۡبَ إِلَّا ٱللَّهُۚ")
                    ScriptureQuote(text: "“He who visits a diviner (‘arraf) and asks him about anything, his prayers extending to forty nights will not be accepted” (Sahih Muslim 2230).", arabic: "مَنْ أَتَى عَرَّافًا فَسَأَلَهُ عَنْ شَىْءٍ لَمْ تُقْبَلْ لَهُ صَلاَةٌ أَرْبَعِينَ لَيْلَةً", dimmed: true)

                    Text("**Sihr (سِحْر)**: magic; spells, knots, and the summoning of devils to harm, bind, or separate. The Quran traces it to the devils in the days of Sulayman, who taught people “that by which they cause separation between a man and his wife” (Quran 2:102), and Surat al-Falaq seeks refuge from “the blowers in knots” (Quran 113:4). The Prophet (peace be upon him) counted it second only to shirk among the destroyers:")
                        .font(.body)
                    ScriptureQuote(text: "“Avoid the seven great destructive sins.” They asked, “O Messenger of Allah, what are they?” He said, “To join others in worship along with Allah, to practice sorcery, to kill the life which Allah has forbidden except for a just cause, to eat up riba, to eat up an orphan’s wealth, to flee from the battlefield at the time of fighting, and to accuse chaste women who never even think of anything touching chastity and are good believers” (Sahih al-Bukhari 2766).", arabic: "اجْتَنِبُوا السَّبْعَ الْمُوبِقَاتِ. قَالُوا يَا رَسُولَ اللَّهِ، وَمَا هُنَّ قَالَ الشِّرْكُ بِاللَّهِ، وَالسِّحْرُ، وَقَتْلُ النَّفْسِ الَّتِي حَرَّمَ اللَّهُ إِلاَّ بِالْحَقِّ، وَأَكْلُ الرِّبَا، وَأَكْلُ مَالِ الْيَتِيمِ، وَالتَّوَلِّي يَوْمَ الزَّحْفِ، وَقَذْفُ الْمُحْصَنَاتِ الْمُؤْمِنَاتِ الْغَافِلاَتِ", dimmed: true)

                    Text("**Tanjim (تَنْجِيم)**: from najm, a star; astrology, reading fates and fortunes in the heavens. Astronomy, the study of the stars for calendars, direction, and knowledge, is praised in the Quran; astrology is a branch of magic:")
                        .font(.body)
                    ScriptureQuote(text: "“If anyone acquires any knowledge of astrology, he acquires a branch of magic of which he gets more as long as he continues to do so” (Sunan Abi Dawud 3905; graded hasan by al-Albani).", arabic: "مَنِ اقْتَبَسَ عِلْمًا مِنَ النُّجُومِ اقْتَبَسَ شُعْبَةً مِنَ السِّحْرِ زَادَ مَا زَادَ", dimmed: true)
                    ScriptureQuote(text: "“Whoever said that it rained because of a particular star had no belief in Me but believes in that star” (Sahih al-Bukhari 846).", arabic: "وَأَمَّا مَنْ قَالَ بِنَوْءِ كَذَا وَكَذَا فَذَلِكَ كَافِرٌ بِي وَمُؤْمِنٌ بِالْكَوْكَبِ", dimmed: true)

                    Text("**Nature worship and animism**: worship of the sun, moon, stars, rivers, mountains, trees, and the spirits held to live in them, from the Egyptians and Babylonians to modern “Mother Earth” cults. The Quran presents all of nature as itself a worshipper, never a god:")
                        .font(.body)
                    ScriptureQuote(text: "“Do you not see that to Allah prostrates whoever is in the heavens and whoever is on the earth and the sun, the moon, the stars, the mountains, the trees, the moving creatures and many of the people?” (Quran 22:18).", arabic: "أَلَمۡ تَرَ أَنَّ ٱللَّهَ يَسۡجُدُۤ لَهُۥۤ مَن فِي ٱلسَّمَٰوَٰتِ وَمَن فِي ٱلۡأَرۡضِ وَٱلشَّمۡسُ وَٱلۡقَمَرُ وَٱلنُّجُومُ وَٱلۡجِبَالُ وَٱلشَّجَرُ وَٱلدَّوَآبُّ وَكَثِيرٞ مِّنَ ٱلنَّاسِۖ")

                    Text("**Ancestor worship**: offerings, prayers, and vows to the spirits of the dead, found in the old Roman, Chinese, and African religions and in modern “veneration” of the departed. The Quran shows the dead, the angels, and the righteous disowning such worship on the Day of Judgement:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention] the Day when He will gather them all and then say to the angels, ‘Did these [people] used to worship you?’ They will say, ‘Exalted are You! You, [O Allah], are our benefactor not them. Rather, they used to worship the jinn; most of them were believers in them’” (Quran 34:40-41).", arabic: "وَيَوۡمَ يَحۡشُرُهُمۡ جَمِيعٗا ثُمَّ يَقُولُ لِلۡمَلَٰٓئِكَةِ أَهَٰٓؤُلَآءِ إِيَّاكُمۡ كَانُواْ يَعۡبُدُونَ ۝ قَالُواْ سُبۡحَٰنَكَ أَنتَ وَلِيُّنَا مِن دُونِهِمۖ بَلۡ كَانُواْ يَعۡبُدُونَ ٱلۡجِنَّۖ أَكۡثَرُهُم بِهِم مُّؤۡمِنُونَ")
                    ScriptureQuote(text: "“And there were men from mankind who sought refuge in men from the jinn, so they [only] increased them in burden” (Quran 72:6).", arabic: "وَأَنَّهُۥ كَانَ رِجَالٞ مِّنَ ٱلۡإِنسِ يَعُوذُونَ بِرِجَالٖ مِّنَ ٱلۡجِنِّ فَزَادُوهُمۡ رَهَقٗا")

                    Text("**Hajj and Tawaf**: the rites Allah gave to Ibrahim (peace be upon him) at the House he built for the worship of Allah alone:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention, O Muhammad], when We designated for Abraham the site of the House, [saying], ‘Do not associate anything with Me and purify My House for those who perform Tawaf and those who stand [in prayer] and those who bow and prostrate’” (Quran 22:26).", arabic: "وَإِذۡ بَوَّأۡنَا لِإِبۡرَٰهِيمَ مَكَانَ ٱلۡبَيۡتِ أَن لَّا تُشۡرِكۡ بِي شَيۡـٔٗا وَطَهِّرۡ بَيۡتِيَ لِلطَّآئِفِينَ وَٱلۡقَآئِمِينَ وَٱلرُّكَّعِ ٱلسُّجُودِ")
                    Text("Allah then commanded Ibrahim to proclaim the Hajj, and described its sacrifice, its feeding of the poor, and its tawaf around the ancient House (Quran 22:27-29). The pagans kept the rites but corrupted them: they filled the House with idols, performed tawaf naked, and added a partner to the talbiyah. Ibn Abbas (may Allah be pleased with him) reported:")
                        .font(.body)
                    ScriptureQuote(text: "“During the pre-Islamic days women circumambulated the Ka‘bah nakedly, and said: Who would provide cloth to cover the one who is circumambulating the Ka‘bah so that she would cover her private parts?” (Sahih Muslim 3028).", arabic: "كَانَتِ الْمَرْأَةُ تَطُوفُ بِالْبَيْتِ وَهِيَ عُرْيَانَةٌ فَتَقُولُ مَنْ يُعِيرُنِي تِطْوَافًا تَجْعَلُهُ عَلَى فَرْجِهَا", dimmed: true)
                    ScriptureQuote(text: "“The polytheists used to say: Here I am at Your service, there is no associate with You. The Messenger of Allah (peace be upon him) would say: Woe to you, enough, enough! But they would say: except one associate who is Yours; You possess mastery over him, but he does not possess mastery. They used to say this while they circumambulated the Ka‘bah” (Sahih Muslim 1185).", arabic: "كَانَ الْمُشْرِكُونَ يَقُولُونَ لَبَّيْكَ لاَ شَرِيكَ لَكَ - قَالَ - فَيَقُولُ رَسُولُ اللَّهِ صلى الله عليه وسلم وَيْلَكُمْ قَدْ قَدْ. فَيَقُولُونَ إِلاَّ شَرِيكًا هُوَ لَكَ تَمْلِكُهُ وَمَا مَلَكَ. يَقُولُونَ هَذَا وَهُمْ يَطُوفُونَ بِالْبَيْتِ", dimmed: true)
                    ScriptureQuote(text: "“And their prayer at the House was not except whistling and handclapping. So taste the punishment for what you disbelieved” (Quran 8:35).", arabic: "وَمَا كَانَ صَلَاتُهُمۡ عِندَ ٱلۡبَيۡتِ إِلَّا مُكَآءٗ وَتَصۡدِيَةٗۚ فَذُوقُواْ ٱلۡعَذَابَ بِمَا كُنتُمۡ تَكۡفُرُونَ")

                    Text("**Modern paganism**: neo-paganism and Wicca, which revive the old gods and goddesses and “the Goddess”; crystals and stones believed to carry healing energy; “manifesting,” in which one asks “the universe” for what one wants; and astrology, tarot, and spirit-guides. These are the old shirk in new words: calling on what cannot hear, and attributing giving and healing to what has no power:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not invoke besides Allah that which neither benefits you nor harms you, for if you did, then indeed you would be of the wrongdoers” (Quran 10:106).", arabic: "وَلَا تَدۡعُ مِن دُونِ ٱللَّهِ مَا لَا يَنفَعُكَ وَلَا يَضُرُّكَۖ فَإِن فَعَلۡتَ فَإِنَّكَ إِذٗا مِّنَ ٱلظَّٰلِمِينَ")
                    ScriptureQuote(text: "“And who is more astray than he who invokes besides Allah those who will not respond to him until the Day of Resurrection, and they, of their invocation, are unaware” (Quran 46:5).", arabic: "وَمَنۡ أَضَلُّ مِمَّن يَدۡعُواْ مِن دُونِ ٱللَّهِ مَن لَّا يَسۡتَجِيبُ لَهُۥٓ إِلَىٰ يَوۡمِ ٱلۡقِيَٰمَةِ وَهُمۡ عَن دُعَآئِهِمۡ غَٰفِلُونَ")
                }

                Section(header: Text("1. THE PAGANS ADMIT THE CREATOR")) {
                    Text("The pagans of Makkah did not deny Allah. They believed He created the heavens and the earth, and they turned to Him alone in the storm. Their shirk was to worship others alongside Him:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you asked them who created them, they would surely say, ‘Allah.’ So how are they deluded?” (Quran 43:87).", arabic: "وَلَئِن سَأَلۡتَهُم مَّنۡ خَلَقَهُمۡ لَيَقُولُنَّ ٱللَّهُۖ فَأَنَّىٰ يُؤۡفَكُونَ")

                    ScriptureQuote(text: "“And when they board a ship, they supplicate Allah, sincere to Him in religion. But when He delivers them to the land, at once they associate others with Him” (Quran 29:65).", arabic: "فَإِذَا رَكِبُواْ فِي ٱلۡفُلۡكِ دَعَوُاْ ٱللَّهَ مُخۡلِصِينَ لَهُ ٱلدِّينَ فَلَمَّا نَجَّىٰهُمۡ إِلَى ٱلۡبَرِّ إِذَا هُمۡ يُشۡرِكُونَ")

                    ScriptureQuote(text: "“Say, [O Muhammad], ‘To whom belongs the earth and whoever is in it, if you should know?’ They will say, ‘To Allah.’ Say, ‘Then will you not remember?’ Say, ‘Who is Lord of the seven heavens and Lord of the Great Throne?’ They will say, ‘[They belong] to Allah.’ Say, ‘Then will you not fear Him?’” (Quran 23:84-87).", arabic: "قُل لِّمَنِ ٱلۡأَرۡضُ وَمَن فِيهَآ إِن كُنتُمۡ تَعۡلَمُونَ ۝ سَيَقُولُونَ لِلَّهِۚ قُلۡ أَفَلَا تَذَكَّرُونَ ۝ قُلۡ مَن رَّبُّ ٱلسَّمَٰوَٰتِ ٱلسَّبۡعِ وَرَبُّ ٱلۡعَرۡشِ ٱلۡعَظِيمِ ۝ سَيَقُولُونَ لِلَّهِۚ قُلۡ أَفَلَا تَتَّقُونَ")

                    Text("So the argument of the Quran is: the One you admit created you, provides for you, and saves you at sea is the only One who deserves your worship. Anything else is created like you.")
                        .font(.body)
                }

                Section(header: Text("2. NOTHING CREATED DESERVES WORSHIP")) {
                    ScriptureQuote(text: "“Do they associate with Him those who create nothing and they are [themselves] created? And the false deities are unable to [give] them help, nor can they help themselves” (Quran 7:191-192).", arabic: "أَيُشۡرِكُونَ مَا لَا يَخۡلُقُ شَيۡـٔٗا وَهُمۡ يُخۡلَقُونَ ۝ وَلَا يَسۡتَطِيعُونَ لَهُمۡ نَصۡرٗا وَلَآ أَنفُسَهُمۡ يَنصُرُونَ")

                    ScriptureQuote(text: "“Indeed, those you [polytheists] call upon besides Allah are servants like you. So call upon them and let them respond to you, if you should be truthful” (Quran 7:194).", arabic: "إِنَّ ٱلَّذِينَ تَدۡعُونَ مِن دُونِ ٱللَّهِ عِبَادٌ أَمۡثَالُكُمۡۖ فَٱدۡعُوهُمۡ فَلۡيَسۡتَجِيبُواْ لَكُمۡ إِن كُنتُمۡ صَٰدِقِينَ")

                    ScriptureQuote(text: "“But they have taken besides Him gods which create nothing, while they are created, and possess not for themselves any harm or benefit and possess not [power to cause] death or life or resurrection” (Quran 25:3).", arabic: "وَٱتَّخَذُواْ مِن دُونِهِۦٓ ءَالِهَةٗ لَّا يَخۡلُقُونَ شَيۡـٔٗا وَهُمۡ يُخۡلَقُونَ وَلَا يَمۡلِكُونَ لِأَنفُسِهِمۡ ضَرّٗا وَلَا نَفۡعٗا وَلَا يَمۡلِكُونَ مَوۡتٗا وَلَا حَيَوٰةٗ وَلَا نُشُورٗا")

                    ScriptureQuote(text: "“Say, [O Muhammad], ‘Invoke those you claim [as deities] besides Allah.’ They do not possess an atom's weight [of ability] in the heavens or on the earth, and they do not have therein any partnership [with Him], nor is there for Him from among them any assistant” (Quran 34:22).", arabic: "قُلِ ٱدۡعُواْ ٱلَّذِينَ زَعَمۡتُم مِّن دُونِ ٱللَّهِ لَا يَمۡلِكُونَ مِثۡقَالَ ذَرَّةٖ فِي ٱلسَّمَٰوَٰتِ وَلَا فِي ٱلۡأَرۡضِ وَمَا لَهُمۡ فِيهِمَا مِن شِرۡكٖ وَمَا لَهُۥ مِنۡهُم مِّن ظَهِيرٖ")

                    Text("Ibrahim (peace be upon him) reasoned through the star, the moon, and the sun, and saw that whatever sets and vanishes cannot be a lord:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, I have turned my face toward He who created the heavens and the earth, inclining toward truth, and I am not of those who associate others with Allah” (Quran 6:79).", arabic: "إِنِّي وَجَّهۡتُ وَجۡهِيَ لِلَّذِي فَطَرَ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ حَنِيفٗاۖ وَمَآ أَنَا۠ مِنَ ٱلۡمُشۡرِكِينَ")
                }

                Section(header: Text("3. THE INTERCESSION EXCUSE")) {
                    Text("Pagans in every age say the idols are only a way to reach the High God, or that the spirits carry prayers to Him. The Quran quotes the excuse and rejects it:")
                        .font(.body)
                    ScriptureQuote(text: "“And they worship other than Allah that which neither harms them nor benefits them, and they say, ‘These are our intercessors with Allah.’ Say, ‘Do you inform Allah of something He does not know in the heavens or on the earth?’ Exalted is He and high above what they associate with Him” (Quran 10:18).", arabic: "وَيَعۡبُدُونَ مِن دُونِ ٱللَّهِ مَا لَا يَضُرُّهُمۡ وَلَا يَنفَعُهُمۡ وَيَقُولُونَ هَٰٓؤُلَآءِ شُفَعَٰٓؤُنَا عِندَ ٱللَّهِۚ قُلۡ أَتُنَبِّـُٔونَ ٱللَّهَ بِمَا لَا يَعۡلَمُ فِي ٱلسَّمَٰوَٰتِ وَلَا فِي ٱلۡأَرۡضِۚ سُبۡحَٰنَهُۥ وَتَعَٰلَىٰ عَمَّا يُشۡرِكُونَ")

                    ScriptureQuote(text: "“You worship not besides Him except [mere] names you have named them, you and your fathers, for which Allah has sent down no authority. Legislation is not but for Allah. He has commanded that you worship not except Him. That is the correct religion, but most of the people do not know” (Quran 12:40).", arabic: "إِنِ ٱلۡحُكۡمُ إِلَّا لِلَّهِ أَمَرَ أَلَّا تَعۡبُدُوٓاْ إِلَّآ إِيَّاهُۚ ذَٰلِكَ ٱلدِّينُ ٱلۡقَيِّمُ وَلَٰكِنَّ أَكۡثَرَ ٱلنَّاسِ لَا يَعۡلَمُونَ")
                }

                Section(header: Text("4. THE END OF THE IDOLS")) {
                    Text("When the Prophet (peace be upon him) entered Makkah in 8 AH, he struck the 360 idols around the Ka‘bah with his stick, reciting:")
                        .font(.body)
                    ScriptureQuote(text: "“And say, ‘Truth has come, and falsehood has departed. Indeed is falsehood, [by nature], ever bound to depart’” (Quran 17:81).", arabic: "وَقُلۡ جَآءَ ٱلۡحَقُّ وَزَهَقَ ٱلۡبَٰطِلُۚ إِنَّ ٱلۡبَٰطِلَ كَانَ زَهُوقٗا")

                    Text("The House built by Ibrahim for the worship of Allah alone was cleansed and has remained so (Sahih al-Bukhari 4287). And the Prophet (peace be upon him) sent Ali to leave no image without effacing it and no raised grave without levelling it (Sahih Muslim 969), closing the road by which idols return.")
                        .font(.body)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Were the Arabs always idolaters?**")
                        .font(.body)
                    Text("No. Makkah was founded on tawhid. Ibrahim and Isma‘il (peace be upon them) raised the House for the worship of Allah alone and prayed that their descendants would be Muslims and would be sent a messenger from among themselves (Quran 2:127-129):")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention] when Abraham was raising the foundations of the House and [with him] Ishmael, [saying], ‘Our Lord, accept [this] from us. Indeed You are the Hearing, the Knowing’” (Quran 2:127).", arabic: "وَإِذۡ يَرۡفَعُ إِبۡرَٰهِـۧمُ ٱلۡقَوَاعِدَ مِنَ ٱلۡبَيۡتِ وَإِسۡمَٰعِيلُ رَبَّنَا تَقَبَّلۡ مِنَّآۖ إِنَّكَ أَنتَ ٱلسَّمِيعُ ٱلۡعَلِيمُ")
                    ScriptureQuote(text: "“Indeed, the first House [of worship] established for mankind was that at Mecca - blessed and a guidance for the worlds” (Quran 3:96).", arabic: "إِنَّ أَوَّلَ بَيۡتٖ وُضِعَ لِلنَّاسِ لَلَّذِي بِبَكَّةَ مُبَارَكٗا وَهُدٗى لِّلۡعَٰلَمِينَ")
                    ScriptureQuote(text: "“And [due] to Allah from the people is a pilgrimage to the House - for whoever is able to find thereto a way” (Quran 3:97).", arabic: "وَلِلَّهِ عَلَى ٱلنَّاسِ حِجُّ ٱلۡبَيۡتِ مَنِ ٱسۡتَطَاعَ إِلَيۡهِ سَبِيلٗاۚ")
                    ScriptureQuote(text: "“And [mention, O Muhammad], when Abraham said, ‘My Lord, make this city [Mecca] secure and keep me and my sons away from worshipping idols’” (Quran 14:35).", arabic: "وَإِذۡ قَالَ إِبۡرَٰهِيمُ رَبِّ ٱجۡعَلۡ هَٰذَا ٱلۡبَلَدَ ءَامِنٗا وَٱجۡنُبۡنِي وَبَنِيَّ أَن نَّعۡبُدَ ٱلۡأَصۡنَامَ")
                    Text("The Arabs kept much of that religion for centuries: the Hajj, the tawaf, the sanctity of the House and the sacred months. Idolatry came in later through ‘Amr ibn Luhayy of Khuza‘ah, whom the Prophet (peace be upon him) saw dragging his intestines in the Fire (Sahih al-Bukhari 3521, quoted above), and who, as Ibn Ishaq relates, brought Hubal from Syria and set it up at the Ka‘bah. Some hanifs, seekers of the religion of Ibrahim, still refused the idols in the Prophet’s own generation. Zayd ibn ‘Amr ibn Nufayl would not eat what was slaughtered for the idols (Sahih al-Bukhari 3826), and Asma’ bint Abi Bakr (may Allah be pleased with her) saw him standing with his back against the Ka‘bah, saying:")
                        .font(.body)
                    ScriptureQuote(text: "“O people of Quraish! By Allah, none amongst you is on the religion of Abraham except me” (Sahih al-Bukhari 3828).", arabic: "يَا مَعَاشِرَ قُرَيْشٍ، وَاللَّهِ مَا مِنْكُمْ عَلَى دِينِ إِبْرَاهِيمَ غَيْرِي", dimmed: true)
                    Text("Islam did not bring a new god to the Arabs; it removed the intruders.")
                        .font(.body)

                    Text("**Is the Ka‘bah or the Black Stone idolatry?**")
                        .font(.body)
                    Text("No. Muslims pray toward the Ka‘bah, not to it; it is a direction commanded by Allah, so that the whole Ummah faces one point:")
                        .font(.body)
                    ScriptureQuote(text: "“So turn your face toward al-Masjid al-Haram. And wherever you [believers] are, turn your faces toward it [in prayer]” (Quran 2:144).", arabic: "فَوَلِّ وَجۡهَكَ شَطۡرَ ٱلۡمَسۡجِدِ ٱلۡحَرَامِۚ وَحَيۡثُ مَا كُنتُمۡ فَوَلُّواْ وُجُوهَكُمۡ شَطۡرَهُۥۗ")
                    Text("The House was built by Ibrahim on the condition “do not associate anything with Me” (Quran 22:26). As for the Black Stone, the Muslims kiss it only because the Prophet (peace be upon him) did, and the Companions said so plainly. ‘Umar (may Allah be pleased with him) came to it, kissed it, and said:")
                        .font(.body)
                    ScriptureQuote(text: "“No doubt, I know that you are a stone and can neither benefit anyone nor harm anyone. Had I not seen Allah’s Messenger (peace be upon him) kissing you I would not have kissed you” (Sahih al-Bukhari 1597, Sahih Muslim 1270).", arabic: "إِنِّي أَعْلَمُ أَنَّكَ حَجَرٌ لاَ تَضُرُّ وَلاَ تَنْفَعُ، وَلَوْلاَ أَنِّي رَأَيْتُ النَّبِيَّ صلى الله عليه وسلم يُقَبِّلُكَ مَا قَبَّلْتُكَ", dimmed: true)
                    Text("No Muslim prays to the stone, asks it for anything, or believes it hears. Idolatry is directing worship to a created thing; following a command about where to face is obedience to the Creator.")
                        .font(.body)

                    Text("**Are shrines, relics, and saints’ tombs paganism?**")
                        .font(.body)
                    Text("Praying to the dead, asking them for children or cures, vowing and sacrificing at their graves, and circling their shrines is the same shirk as the idols of Nuh’s people, which began as the honouring of righteous men (Quran 71:23). The Prophet (peace be upon him) warned against the first step on that road even on his deathbed:")
                        .font(.body)
                    ScriptureQuote(text: "“May Allah curse the Jews and Christians, for they built the places of worship at the graves of their Prophets” (Sahih al-Bukhari 435, Sahih Muslim 531).", arabic: "لَعْنَةُ اللَّهِ عَلَى الْيَهُودِ وَالنَّصَارَى اتَّخَذُوا قُبُورَ أَنْبِيَائِهِمْ مَسَاجِدَ", dimmed: true)
                    ScriptureQuote(text: "“Beware of those who preceded you and used to take the graves of their prophets and righteous men as places of worship, but you must not take graves as mosques; I forbid you to do that” (Sahih Muslim 532).", arabic: "أَلاَ وَإِنَّ مَنْ كَانَ قَبْلَكُمْ كَانُوا يَتَّخِذُونَ قُبُورَ أَنْبِيَائِهِمْ وَصَالِحِيهِمْ مَسَاجِدَ أَلاَ فَلاَ تَتَّخِذُوا الْقُبُورَ مَسَاجِدَ إِنِّي أَنْهَاكُمْ عَنْ ذَلِكَ", dimmed: true)
                    Text("He sent ‘Ali to level every raised grave (Sahih Muslim 969), and he forbade plastering graves, sitting on them, and building over them (Sahih Muslim 970). Visiting graves to remember death and to pray for the dead is Sunnah; building shrines over them and praying to their occupants is the very thing the Prophet (peace be upon him) cursed. Ibn al-Qayyim (may Allah have mercy on him) devoted a long section of Ighathat al-Lahfan to showing how the veneration of graves turns into the worship of their occupants.")
                        .font(.body)

                    Text("**Are astrology, fortune-telling, and magic shirk?**")
                        .font(.body)
                    Text("Astrology is a branch of magic (Sunan Abi Dawud 3905) and attributing rain to a star is disbelief in Allah (Sahih al-Bukhari 846), both quoted above. Asking a fortune-teller voids the prayer of forty nights (Sahih Muslim 2230), and believing him is worse; the Prophet (peace be upon him) said that whoever goes to a kahin and believes what he says has nothing to do with what was sent down to Muhammad (Sunan Abi Dawud 3904; graded sahih by al-Albani). Where do the kahins get the occasional truth that impresses their clients? Aishah (may Allah be pleased with her) asked exactly that:")
                        .font(.body)
                    ScriptureQuote(text: "“That is a word pertaining to truth which a jinn snatches and throws into the ear of his friend, and makes an addition of one hundred lies to it” (Sahih Muslim 2228).", arabic: "تِلْكَ الْكَلِمَةُ الْحَقُّ يَخْطَفُهَا الْجِنِّيُّ فَيَقْذِفُهَا فِي أُذُنِ وَلِيِّهِ وَيَزِيدُ فِيهَا مِائَةَ كَذْبَةٍ", dimmed: true)
                    ScriptureQuote(text: "“The angels descend in the clouds and mention this or that matter decreed in the Heaven. The devils listen stealthily to such a matter, come down to inspire the soothsayers with it, and the latter would add to it one hundred lies of their own” (Sahih al-Bukhari 3210).", arabic: "إِنَّ الْمَلاَئِكَةَ تَنْزِلُ فِي الْعَنَانِ ـ وَهْوَ السَّحَابُ ـ فَتَذْكُرُ الأَمْرَ قُضِيَ فِي السَّمَاءِ، فَتَسْتَرِقُ الشَّيَاطِينُ السَّمْعَ، فَتَسْمَعُهُ فَتُوحِيهِ إِلَى الْكُهَّانِ، فَيَكْذِبُونَ مَعَهَا مِائَةَ كَذْبَةٍ مِنْ عِنْدِ أَنْفُسِهِمْ", dimmed: true)
                    Text("Magic is the second of the seven destroyers (Sahih al-Bukhari 2766), and the Quran says of those who buy it that they have no share in the Hereafter (Quran 2:102). Its practice involves serving devils, and that is shirk.")
                        .font(.body)

                    Text("**Are omens and superstitions shirk?**")
                        .font(.body)
                    Text("Omens are shirk by the Prophet’s own words (Sunan Abi Dawud 3910, quoted above), because they attach harm and benefit to something Allah gave no power. Black cats, broken mirrors, unlucky numbers and days, and “touch wood” all fall under it. Islam replaces the omen with the good word:")
                        .font(.body)
                    ScriptureQuote(text: "“No ‘adwa nor tiyarah; but I like the fa’l.” They said, “What is the fa’l?” He said, “A good word” (Sahih al-Bukhari 5776).", arabic: "لاَ عَدْوَى، وَلاَ طِيَرَةَ، وَيُعْجِبُنِي الْفَأْلُ. قَالُوا وَمَا الْفَأْلُ قَالَ كَلِمَةٌ طَيِّبَةٌ", dimmed: true)
                    Text("Even swearing by something other than Allah, as pagans swore by their idols and ancestors, was forbidden as a form of shirk:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever swears by other than Allah, he has committed disbelief or shirk” (Sunan al-Tirmidhi 1535; graded sahih by al-Albani).", arabic: "مَنْ حَلَفَ بِغَيْرِ اللَّهِ فَقَدْ كَفَرَ أَوْ أَشْرَكَ", dimmed: true)
                    Text("The cure the Prophet (peace be upon him) gave is tawakkul, reliance on Allah, which drives the omen out of the heart.")
                        .font(.body)

                    Text("**Is it shirk to seek blessing from a tree, a stone, or a place?**")
                        .font(.body)
                    Text("Yes, if one believes the thing itself gives blessing. On a campaign the Prophet (peace be upon him) passed a tree of the pagans called Dhat Anwat, on which they used to hang their weapons, and some of those with him asked for one like it:")
                        .font(.body)
                    ScriptureQuote(text: "They said, “O Messenger of Allah, make a Dhat Anwat for us as they have a Dhat Anwat.” The Prophet (peace be upon him) said, “Subhan Allah! This is like what Musa’s people said: Make for us a god like their gods. By the One in Whose hand is my soul, you shall follow the way of those who were before you” (Sunan al-Tirmidhi 2180; graded sahih by al-Albani).", arabic: "فَقَالُوا يَا رَسُولَ اللَّهِ اجْعَلْ لَنَا ذَاتَ أَنْوَاطٍ كَمَا لَهُمْ ذَاتُ أَنْوَاطٍ. فَقَالَ النَّبِيُّ صلى الله عليه وسلم سُبْحَانَ اللَّهِ هَذَا كَمَا قَالَ قَوْمُ مُوسَى : (اجْعَلْ لَنَا إِلَهًا كَمَا لَهُمْ آلِهَةٌ ) وَالَّذِي نَفْسِي بِيَدِهِ لَتَرْكَبُنَّ سُنَّةَ مَنْ كَانَ قَبْلَكُمْ", dimmed: true)
                    Text("Blessing (barakah) belongs to Allah, who places it where He wills: in the Quran, in Zamzam, in the sacred places He named. It is not sought from a tree, a wall, a saint’s cloth, or a stone.")
                        .font(.body)

                    Text("**What of nature, “Mother Earth,” the sun and the moon?**")
                        .font(.body)
                    Text("They are creatures and signs. The sun, moon, mountains, and trees prostrate to Allah (Quran 22:18, quoted above); to prostrate to them is to worship a fellow servant, and Allah forbade it in so many words:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not prostrate to the sun or to the moon, but prostate to Allah, who created them” (Quran 41:37).", arabic: "لَا تَسۡجُدُواْ لِلشَّمۡسِ وَلَا لِلۡقَمَرِ وَٱسۡجُدُواْۤ لِلَّهِۤ ٱلَّذِي خَلَقَهُنَّ")
                    Text("Ibrahim (peace be upon him) reasoned from the setting of the star, the moon, and the sun that what vanishes cannot be a lord (Quran 6:76-79). The Quran invites us to look at nature and see the One behind it:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, in the creation of the heavens and earth, and the alternation of the night and the day, and the [great] ships which sail through the sea with that which benefits people, and what Allah has sent down from the heavens of rain, giving life thereby to the earth after its lifelessness and dispersing therein every [kind of] moving creature, and [His] directing of the winds and the clouds controlled between the heaven and the earth are signs for a people who use reason” (Quran 2:164).", arabic: "إِنَّ فِي خَلۡقِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ وَٱخۡتِلَٰفِ ٱلَّيۡلِ وَٱلنَّهَارِ وَٱلۡفُلۡكِ ٱلَّتِي تَجۡرِي فِي ٱلۡبَحۡرِ بِمَا يَنفَعُ ٱلنَّاسَ وَمَآ أَنزَلَ ٱللَّهُ مِنَ ٱلسَّمَآءِ مِن مَّآءٖ فَأَحۡيَا بِهِ ٱلۡأَرۡضَ بَعۡدَ مَوۡتِهَا وَبَثَّ فِيهَا مِن كُلِّ دَآبَّةٖ وَتَصۡرِيفِ ٱلرِّيَٰحِ وَٱلسَّحَابِ ٱلۡمُسَخَّرِ بَيۡنَ ٱلسَّمَآءِ وَٱلۡأَرۡضِ لَأٓيَٰتٖ لِّقَوۡمٖ يَعۡقِلُونَ")
                    ScriptureQuote(text: "“Say, ‘Who provides for you from the heaven and the earth? Or who controls hearing and sight and who brings the living out of the dead and brings the dead out of the living and who arranges [every] matter?’ They will say, ‘Allah,’ so say, ‘Then will you not fear Him?’” (Quran 10:31).", arabic: "قُلۡ مَن يَرۡزُقُكُم مِّنَ ٱلسَّمَآءِ وَٱلۡأَرۡضِ أَمَّن يَمۡلِكُ ٱلسَّمۡعَ وَٱلۡأَبۡصَٰرَ وَمَن يُخۡرِجُ ٱلۡحَيَّ مِنَ ٱلۡمَيِّتِ وَيُخۡرِجُ ٱلۡمَيِّتَ مِنَ ٱلۡحَيِّ وَمَن يُدَبِّرُ ٱلۡأَمۡرَۚ فَسَيَقُولُونَ ٱللَّهُۚ فَقُلۡ أَفَلَا تَتَّقُونَ")
                    Text("Caring for the earth is a duty in Islam; the Prophet (peace be upon him) said that no Muslim plants a tree or sows a crop from which a bird, a person, or an animal eats but that it is counted as charity for him (Sahih al-Bukhari 2320, Sahih Muslim 1553). But the earth is Allah’s creation and our trust, not our mother or our goddess.")
                        .font(.body)

                    Text("**Did Islam keep pagan rites?**")
                        .font(.body)
                    Text("No. Hajj, tawaf, the sacrifice, and the sanctity of the House are older than paganism in Arabia; they are the rites of Ibrahim, whom Allah commanded:")
                        .font(.body)
                    ScriptureQuote(text: "“And proclaim to the people the Hajj [pilgrimage]; they will come to you on foot and on every lean camel; they will come from every distant pass” (Quran 22:27).", arabic: "وَأَذِّن فِي ٱلنَّاسِ بِٱلۡحَجِّ يَأۡتُوكَ رِجَالٗا وَعَلَىٰ كُلِّ ضَامِرٖ يَأۡتِينَ مِن كُلِّ فَجٍّ عَمِيقٖ")
                    ScriptureQuote(text: "“And We charged Abraham and Ishmael, [saying], ‘Purify My House for those who perform Tawaf and those who are staying [there] for worship and those who bow and prostrate [in prayer]’” (Quran 2:125).", arabic: "وَعَهِدۡنَآ إِلَىٰٓ إِبۡرَٰهِـۧمَ وَإِسۡمَٰعِيلَ أَن طَهِّرَا بَيۡتِيَ لِلطَّآئِفِينَ وَٱلۡعَٰكِفِينَ وَٱلرُّكَّعِ ٱلسُّجُودِ")
                    Text("The pagans had corrupted these rites with naked tawaf, whistling and clapping at the House, a partner in the talbiyah (see the key terms above), and tribal privileges. Quraysh, calling themselves al-Hums, would not stand at Arafat with the other Arabs:")
                        .font(.body)
                    ScriptureQuote(text: "“The Quraish people and those who embraced their religion, used to stay at Muzdalifa and used to call themselves al-Hums, while the rest of the Arabs used to stay at ‘Arafat. When Islam came, Allah ordered His Prophet to go to ‘Arafat and stay at it, and then pass on from there” (Sahih al-Bukhari 4520).", arabic: "كَانَتْ قُرَيْشٌ وَمَنْ دَانَ دِينَهَا يَقِفُونَ بِالْمُزْدَلِفَةِ، وَكَانُوا يُسَمَّوْنَ الْحُمْسَ، وَكَانَ سَائِرُ الْعَرَبِ يَقِفُونَ بِعَرَفَاتٍ، فَلَمَّا جَاءَ الإِسْلاَمُ أَمَرَ اللَّهُ نَبِيَّهُ صلى الله عليه وسلم أَنْ يَأْتِيَ عَرَفَاتٍ، ثُمَّ يَقِفَ بِهَا ثُمَّ يُفِيضَ مِنْهَا", dimmed: true)
                    Text("Islam stripped every one of these away and restored the rite of Ibrahim. In the year before the Farewell Hajj Abu Bakr had it proclaimed:")
                        .font(.body)
                    ScriptureQuote(text: "“No pagan is allowed to perform Hajj after this year, and no naked person is allowed to perform Tawaf of the Ka‘bah” (Sahih al-Bukhari 1622).", arabic: "أَلاَ لاَ يَحُجُّ بَعْدَ الْعَامِ مُشْرِكٌ، وَلاَ يَطُوفُ بِالْبَيْتِ عُرْيَانٌ", dimmed: true)
                    Text("And in the Farewell Hajj itself, standing at Arafat, the Prophet (peace be upon him) declared:")
                        .font(.body)
                    ScriptureQuote(text: "“Behold! Everything pertaining to the Days of Ignorance is under my feet completely abolished. Abolished are also the blood-revenges of the Days of Ignorance” (Sahih Muslim 1218).", arabic: "أَلاَ كُلُّ شَىْءٍ مِنْ أَمْرِ الْجَاهِلِيَّةِ تَحْتَ قَدَمَىَّ مَوْضُوعٌ وَدِمَاءُ الْجَاهِلِيَّةِ مَوْضُوعَةٌ", dimmed: true)
                    Text("A rite is pagan by what it is offered to, not by its age. Prostration, fasting, and pilgrimage existed among idolaters too; offered to Allah alone, on His command, they are worship.")
                        .font(.body)

                    Text("**What were al-Lat, al-‘Uzza, and Manat, and what became of them?**")
                        .font(.body)
                    Text("Al-Lat was a white stone at Ta’if, the idol of Thaqif, with a house built over it; al-‘Uzza was a group of trees with a shrine at Nakhlah, the most venerated idol of Quraysh; Manat was a stone at Qudayd on the coast road to Madinah, venerated by the Aws and Khazraj. The Quran named them and stripped them of everything but their names (Quran 53:19-23, quoted above). After the conquest of Makkah in 8 AH the Prophet (peace be upon him) sent Khalid ibn al-Walid to al-‘Uzza, and he destroyed it and its shrine, and he sent Sa‘d ibn Zayd al-Ashhali to Manat; al-Lat was demolished when Thaqif accepted Islam in 9 AH, by al-Mughirah ibn Shu‘bah and Abu Sufyan (Ibn Hisham, as-Sirah an-Nabawiyyah; Ibn Kathir, al-Bidayah wan-Nihayah). He also sent Jarir ibn Abdullah to the idol-house of Khath‘am in the south:")
                        .font(.body)
                    ScriptureQuote(text: "“Will you relieve me from Dhul-Khalasa?” Dhul-Khalasa was a house of an idol belonging to the tribe of Khath‘am called the Yemenite Ka‘bah (Sahih al-Bukhari 3020).", arabic: "أَلاَ تُرِيحُنِي مِنْ ذِي الْخَلَصَةِ. وَكَانَ بَيْتًا فِي خَثْعَمَ يُسَمَّى كَعْبَةَ الْيَمَانِيَةَ", dimmed: true)
                    Text("Jarir went with a hundred and fifty horsemen, tore it down, and burned it. Within two years of the conquest not one of the great idols of Arabia was standing.")
                        .font(.body)

                    Text("**Is asking the jinn or spirits shirk?**")
                        .font(.body)
                    Text("Yes. Seeking refuge with the jinn, asking them for knowledge or help, and making pacts with them was the paganism of the old Arabs (Quran 72:6, quoted above), and the jinn and the angels will disown their worshippers on the Day of Judgement (Quran 34:41). Allah describes the reckoning:")
                        .font(.body)
                    ScriptureQuote(text: "“‘O company of jinn, you have [misled] many of mankind.’ And their allies among mankind will say, ‘Our Lord, some of us made use of others’” (Quran 6:128).", arabic: "يَٰمَعۡشَرَ ٱلۡجِنِّ قَدِ ٱسۡتَكۡثَرۡتُم مِّنَ ٱلۡإِنسِۖ وَقَالَ أَوۡلِيَآؤُهُم مِّنَ ٱلۡإِنسِ رَبَّنَا ٱسۡتَمۡتَعَ بَعۡضُنَا بِبَعۡضٖ")
                    ScriptureQuote(text: "“But they have attributed to Allah partners - the jinn, while He has created them - and have fabricated for Him sons and daughters. Exalted is He and high above what they describe” (Quran 6:100).", arabic: "وَجَعَلُواْ لِلَّهِ شُرَكَآءَ ٱلۡجِنَّ وَخَلَقَهُمۡۖ وَخَرَقُواْ لَهُۥ بَنِينَ وَبَنَٰتِۭ بِغَيۡرِ عِلۡمٖۚ سُبۡحَٰنَهُۥ وَتَعَٰلَىٰ عَمَّا يَصِفُونَ")
                    Text("Spirit-guides, séances, channelling, and “communicating with the departed” are the same thing in modern dress. The one who answers is a jinn, and the price is the servant’s religion. Refuge is sought from the jinn, in Allah, not with the jinn.")
                        .font(.body)

                    Text("**Are crystals, energy healing, and “manifesting” paganism?**")
                        .font(.body)
                    Text("To believe that a stone heals by its own energy, that a ritual draws “abundance” from “the universe,” or that one’s intention bends the cosmos is to attribute Allah’s acts to His creation. It is the intercession excuse in new words (Quran 39:3) and the calling on what cannot answer (Quran 10:106; 7:194):")
                        .font(.body)
                    ScriptureQuote(text: "“To Him [alone] is the supplication of truth. And those they call upon besides Him do not respond to them with a thing, except as one who stretches his hands toward water [from afar, calling it] to reach his mouth, but it will not reach it [thus]. And the supplication of the disbelievers is not but in error [i.e. futility]” (Quran 13:14).", arabic: "لَهُۥ دَعۡوَةُ ٱلۡحَقِّۚ وَٱلَّذِينَ يَدۡعُونَ مِن دُونِهِۦ لَا يَسۡتَجِيبُونَ لَهُم بِشَيۡءٍ إِلَّا كَبَٰسِطِ كَفَّيۡهِ إِلَى ٱلۡمَآءِ لِيَبۡلُغَ فَاهُ وَمَا هُوَ بِبَٰلِغِهِۦۚ وَمَا دُعَآءُ ٱلۡكَٰفِرِينَ إِلَّا فِي ضَلَٰلٖ")
                    ScriptureQuote(text: "“And whatever you have of favor - it is from Allah. Then when adversity touches you, to Him you cry for help” (Quran 16:53).", arabic: "وَمَا بِكُم مِّن نِّعۡمَةٖ فَمِنَ ٱللَّهِۖ ثُمَّ إِذَا مَسَّكُمُ ٱلضُّرُّ فَإِلَيۡهِ تَجۡـَٔرُونَ")
                    Text("Islam has its own healing: medicine, which the Prophet (peace be upon him) commanded, and ruqyah with the Quran and the supplications he taught. When the Companions asked him about the incantations they had used in Jahiliyyah, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Let me know your invocation. There is no harm in the invocation as long as there is no polytheism in it” (Sahih Muslim 2200).", arabic: "اعْرِضُوا عَلَىَّ رُقَاكُمْ لاَ بَأْسَ بِالرُّقَى مَا لَمْ يَكُنْ فِيهِ شِرْكٌ", dimmed: true)
                    Text("And the one who wants provision is told where it comes from:")
                        .font(.body)
                    ScriptureQuote(text: "“And whoever relies upon Allah - then He is sufficient for him” (Quran 65:3).", arabic: "وَمَن يَتَوَكَّلۡ عَلَى ٱللَّهِ فَهُوَ حَسۡبُهُۥٓۚ")
                }

                Section(header: Text("THE INVITATION")) {
                    ScriptureQuote(text: "“And [mention, O Muhammad], when Abraham said to his father and his people, ‘Indeed, I am disassociated from that which you worship except for He who created me; and indeed, He will guide me’” (Quran 43:26-27).", arabic: "وَإِذۡ قَالَ إِبۡرَٰهِيمُ لِأَبِيهِ وَقَوۡمِهِۦٓ إِنَّنِي بَرَآءٞ مِّمَّا تَعۡبُدُونَ ۝ إِلَّا ٱلَّذِي فَطَرَنِي فَإِنَّهُۥ سَيَهۡدِينِ")

                    ScriptureQuote(text: "“Say, ‘O disbelievers, I do not worship what you worship. Nor are you worshippers of what I worship. Nor will I be a worshipper of what you worship. Nor will you be worshippers of what I worship. For you is your religion, and for me is my religion’” (Quran 109:1-6).", arabic: "قُلۡ يَٰٓأَيُّهَا ٱلۡكَٰفِرُونَ ۝ لَآ أَعۡبُدُ مَا تَعۡبُدُونَ ۝ وَلَآ أَنتُمۡ عَٰبِدُونَ مَآ أَعۡبُدُ ۝ وَلَآ أَنَا۠ عَابِدٞ مَّا عَبَدتُّمۡ ۝ وَلَآ أَنتُمۡ عَٰبِدُونَ مَآ أَعۡبُدُ ۝ لَكُمۡ دِينُكُمۡ وَلِيَ دِينِ")

                    Text("Allah is nearer than any idol, hears without any intermediary, and forgives the one who turns to Him. The pagan is invited to worship the One he already knows made him.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Paganism is the worship of created things, born of excess in honouring the dead and the beautiful. The pagans themselves admit that Allah created them, and that admission is the proof that He alone should be worshipped.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Paganism")
        .selectableArticleList()
    }
}

struct BuddhismAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Buddhism seeks escape from suffering through detachment and rebirth, without a Creator. The Quran answers that the world has a purpose and a Maker, that suffering is a test with meaning, that the self is real and accountable, and that salvation is by Allah's mercy, not by extinguishing desire.")
                        .font(.body)
                }

                Section(header: Text("WHAT BUDDHISM TEACHES")) {
                    Text("Buddhism follows Siddhartha Gautama, the Buddha (“the awakened one“), who lived in northern India around the fifth century BCE. Its core is the Four Noble Truths: life is suffering (**dukkha**), suffering comes from craving, it ends by ending craving, and the way is the Eightfold Path of ethics, meditation, and wisdom. It teaches **karma** and rebirth, denies a permanent self (**anatta**), and aims at **nirvana**, the extinction of craving and of rebirth. It has no Creator God; the Buddha did not teach one. In practice most Buddhists bow to and make offerings before images of the Buddha and of bodhisattvas, and some schools venerate many celestial beings.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Buddha**: Sanskrit for “the awakened one,” a title, not a name. It was taken by Siddhartha Gautama, a prince of the Shakya clan born at Lumbini at the foot of the Himalayas, who lived in northern India around the fifth century BCE (the traditional and the modern datings differ by some decades), left his palace and family in search of the end of suffering, and taught for the rest of his life. Buddhists hold that there were Buddhas before him and will be after him. Islam does not know whether any messenger of Allah was sent to that land in that age (Quran 40:78; see the questions below).")
                        .font(.body)

                    Text("**Dharma (Pali: dhamma)**: “the teaching,” the Buddha’s doctrine, and also the law of things. With **sangha**, the community of monks and nuns, and the Buddha himself, it forms the “three jewels” in which a Buddhist “takes refuge.” The Muslim takes refuge in Allah alone, and his religion is what Allah revealed, not what a man discovered.")
                        .font(.body)

                    Text("**The Four Noble Truths**: that life is suffering (dukkha); that suffering arises from craving (tanha); that it ceases when craving ceases; and that the way to that cessation is the Eightfold Path. **The Eightfold Path**: right view, right intention, right speech, right action, right livelihood, right effort, right mindfulness, and right concentration. Much of this is sound conduct that Islam also commands; what is missing is the One who commands it and the One to whom the path leads.")
                        .font(.body)

                    Text("**Dukkha**: suffering, unsatisfactoriness, the ache of existence. The Quran does not deny it:")
                        .font(.body)
                    ScriptureQuote(text: "“We have certainly created man into hardship” (Quran 90:4).", arabic: "لَقَدۡ خَلَقۡنَا ٱلۡإِنسَٰنَ فِي كَبَدٍ")
                    ScriptureQuote(text: "“O mankind, indeed you are laboring toward your Lord with [great] exertion and will meet it” (Quran 84:6).", arabic: "يَٰٓأَيُّهَا ٱلۡإِنسَٰنُ إِنَّكَ كَادِحٌ إِلَىٰ رَبِّكَ كَدۡحٗا فَمُلَٰقِيهِ")
                    Text("But it names its Author and its purpose: a test set by a merciful Creator, ending in a meeting with Him (Quran 67:2, quoted below).")
                        .font(.body)

                    Text("**Tanha**: craving or thirst, the root of suffering in Buddhist teaching. Islam does not command the extinction of desire but its direction: the believer desires Allah, His pleasure, and Paradise more than the world, and enjoys the world within His limits (Quran 7:32, quoted below).")
                        .font(.body)

                    Text("**Anatta**: “no-self”; the teaching that there is no permanent soul, only a passing bundle of processes. **Anicca**: impermanence, the passing of all things. Islam affirms the second and denies the first: everything created passes, but the soul is real, created, accountable, and will return to its Lord (Quran 17:85; see the questions below).")
                        .font(.body)

                    Text("**Karma** and **rebirth**: deeds shaping the next existence, in an endless cycle across human, animal, and celestial births, until release. Islam teaches one life, one death, one resurrection, and one judgement by a Lord who knows, not by an impersonal law (Quran 23:99-100, quoted below).")
                        .font(.body)

                    Text("**Nirvana**: literally “blowing out,” as of a flame; the extinction of craving and of the cycle of rebirth, described in negatives and said to be beyond description. Islam’s goal is the opposite of extinction: a real Paradise for a real person, in the presence of the Lord who made him.")
                        .font(.body)

                    Text("**Theravada, Mahayana, Vajrayana**: the three great branches. Theravada (“the way of the elders”), in Sri Lanka and Southeast Asia, keeps to the Pali canon and the ideal of the monk. Mahayana (“the great vehicle”), in East Asia, added many scriptures, celestial Buddhas, and the bodhisattva ideal. Vajrayana (“the diamond vehicle”), in Tibet and Mongolia, added tantric rites, mantras, and lamas. In all three, bowing before images, offerings, and appeals to Buddhas or bodhisattvas are part of ordinary devotion, though Buddhists usually call this veneration rather than the worship of a god; and none of it is directed to a Creator.")
                        .font(.body)

                    Text("**Bodhisattva**: in Mahayana, a being who has reached the threshold of nirvana but stays to help others, and who is prayed to for aid, such as Avalokiteshvara, who is called Guanyin in East Asia. Prayer to any being other than Allah is shirk, however compassionate that being is held to be (Quran 10:18; 39:3).")
                        .font(.body)

                    Text("**Meditation**: in Buddhism, the disciplined stilling and observation of the mind, sometimes with mantras or visualisation, aimed at insight and release. Islam has its own disciplines of the heart, reflection and remembrance, with Allah as their object (see the questions below).")
                        .font(.body)

                    Text("**Monasticism**: the celibate, propertyless life of the monk, the highest calling in Buddhism. Islam says of the monasticism of the Christians:")
                        .font(.body)
                    ScriptureQuote(text: "“And We placed in the hearts of those who followed him compassion and mercy and monasticism, which they innovated; We did not prescribe it for them except [that they did so] seeking the approval of Allah. But they did not observe it with due observance” (Quran 57:27).", arabic: "وَجَعَلۡنَا فِي قُلُوبِ ٱلَّذِينَ ٱتَّبَعُوهُ رَأۡفَةٗ وَرَحۡمَةٗۚ وَرَهۡبَانِيَّةً ٱبۡتَدَعُوهَا مَا كَتَبۡنَٰهَا عَلَيۡهِمۡ إِلَّا ٱبۡتِغَآءَ رِضۡوَٰنِ ٱللَّهِ فَمَا رَعَوۡهَا حَقَّ رِعَايَتِهَاۖ")

                    Text("**Khaliq (الخَالِق)**: the Creator, from khalaqa, to bring into being by measure. This is the name Buddhism leaves out and the Quran begins with:")
                        .font(.body)
                    ScriptureQuote(text: "“He is Allah, the Creator, the Inventor, the Fashioner; to Him belong the best names. Whatever is in the heavens and earth is exalting Him. And He is the Exalted in Might, the Wise” (Quran 59:24).", arabic: "هُوَ ٱللَّهُ ٱلۡخَٰلِقُ ٱلۡبَارِئُ ٱلۡمُصَوِّرُۖ لَهُ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰۚ يُسَبِّحُ لَهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ وَهُوَ ٱلۡعَزِيزُ ٱلۡحَكِيمُ")

                    Text("**Qadar (قَدَر)**: from qaddara, to measure out; Allah’s decree of all things by His knowledge and will, the Islamic answer to karma. What befalls a person is measured by a Lord who knows him, not by a ledger of past lives:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, all things We created with predestination” (Quran 54:49).", arabic: "إِنَّا كُلَّ شَيۡءٍ خَلَقۡنَٰهُ بِقَدَرٖ")

                    Text("**Ruh (رُوح)**: the soul, which Allah breathes into each person and takes at death; real, single, and known to its Maker, though its nature is hidden from us (Quran 17:85, quoted below).")
                        .font(.body)

                    Text("**Sabr (صَبْر)**: patience, from sabara, to hold firm; the believer’s response to dukkha, which Islam makes a source of reward rather than an occasion for escape:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, seek help through patience and prayer. Indeed, Allah is with the patient” (Quran 2:153).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ ٱسۡتَعِينُواْ بِٱلصَّبۡرِ وَٱلصَّلَوٰةِۚ إِنَّ ٱللَّهَ مَعَ ٱلصَّٰبِرِينَ")
                    ScriptureQuote(text: "“Indeed, the patient will be given their reward without account” (Quran 39:10).", arabic: "إِنَّمَا يُوَفَّى ٱلصَّٰبِرُونَ أَجۡرَهُم بِغَيۡرِ حِسَابٖ")

                    Text("**Tafakkur (تَفَكُّر)**: reflection, from fakkara, to think; the Muslim’s contemplation, whose object is not emptiness but the signs of the Creator:")
                        .font(.body)
                    ScriptureQuote(text: "“Who remember Allah while standing or sitting or [lying] on their sides and give thought to the creation of the heavens and the earth, [saying], ‘Our Lord, You did not create this aimlessly’” (Quran 3:191).", arabic: "ٱلَّذِينَ يَذۡكُرُونَ ٱللَّهَ قِيَٰمٗا وَقُعُودٗا وَعَلَىٰ جُنُوبِهِمۡ وَيَتَفَكَّرُونَ فِي خَلۡقِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ رَبَّنَا مَا خَلَقۡتَ هَٰذَا بَٰطِلٗا")

                    Text("**Dhikr (ذِكْر)**: remembrance of Allah with the tongue and the heart, in the words He and His Messenger taught; it is what gives the heart the peace that meditation seeks:")
                        .font(.body)
                    ScriptureQuote(text: "“Those who have believed and whose hearts are assured by the remembrance of Allah. Unquestionably, by the remembrance of Allah hearts are assured” (Quran 13:28).", arabic: "ٱلَّذِينَ ءَامَنُواْ وَتَطۡمَئِنُّ قُلُوبُهُم بِذِكۡرِ ٱللَّهِۗ أَلَا بِذِكۡرِ ٱللَّهِ تَطۡمَئِنُّ ٱلۡقُلُوبُ")
                    ScriptureQuote(text: "“O you who have believed, remember Allah with much remembrance” (Quran 33:41).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ ٱذۡكُرُواْ ٱللَّهَ ذِكۡرٗا كَثِيرٗا")

                    Text("**Rahbaniyyah (رَهْبَانِيَّة)**: monasticism, from rahiba, to fear; the withdrawal from marriage and the world that the Quran describes as a human invention (Quran 57:27, above) and that the Prophet (peace be upon him) refused for his Ummah (Sahih al-Bukhari 5063, quoted below).")
                        .font(.body)
                }

                Section(header: Text("1. THE WORLD HAS A MAKER AND A PURPOSE")) {
                    Text("A path that begins with suffering but never asks who made the sufferer has left out the first question. The Quran puts it directly:")
                        .font(.body)
                    ScriptureQuote(text: "“Or were they created by nothing, or were they the creators [of themselves]? Or did they create the heavens and the earth? Rather, they are not certain” (Quran 52:35-36).", arabic: "أَمۡ خُلِقُواْ مِنۡ غَيۡرِ شَيۡءٍ أَمۡ هُمُ ٱلۡخَٰلِقُونَ ۝ أَمۡ خَلَقُواْ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۚ بَل لَّا يُوقِنُونَ")

                    ScriptureQuote(text: "“And We did not create the heavens and earth and that between them in play. We did not create them except in truth, but most of them do not know” (Quran 44:38-39).", arabic: "وَمَا خَلَقۡنَا ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ وَمَا بَيۡنَهُمَا لَٰعِبِينَ ۝ مَا خَلَقۡنَٰهُمَآ إِلَّا بِٱلۡحَقِّ وَلَٰكِنَّ أَكۡثَرَهُمۡ لَا يَعۡلَمُونَ")

                    ScriptureQuote(text: "“Then did you think that We created you uselessly and that to Us you would not be returned?” (Quran 23:115).", arabic: "أَفَحَسِبۡتُمۡ أَنَّمَا خَلَقۡنَٰكُمۡ عَبَثٗا وَأَنَّكُمۡ إِلَيۡنَا لَا تُرۡجَعُونَ")

                    Text("Suffering is not the nature of existence; it is a test set by a Creator who made both death and life for a purpose:")
                        .font(.body)
                    ScriptureQuote(text: "“[He] who created death and life to test you [as to] which of you is best in deed - and He is the Exalted in Might, the Forgiving” (Quran 67:2).", arabic: "ٱلَّذِي خَلَقَ ٱلۡمَوۡتَ وَٱلۡحَيَوٰةَ لِيَبۡلُوَكُمۡ أَيُّكُمۡ أَحۡسَنُ عَمَلٗاۚ وَهُوَ ٱلۡعَزِيزُ ٱلۡغَفُورُ")
                }

                Section(header: Text("2. SUFFERING HAS MEANING")) {
                    Text("Islam does not deny suffering; it gives it a reason and an end. It purifies, it is answered by patience, and it is followed by ease:")
                        .font(.body)
                    ScriptureQuote(text: "“And We will surely test you with something of fear and hunger and a loss of wealth and lives and fruits, but give good tidings to the patient, who, when disaster strikes them, say, ‘Indeed we belong to Allah, and indeed to Him we will return.’ Those are the ones upon whom are blessings from their Lord and mercy. And it is those who are the [rightly] guided” (Quran 2:155-157).", arabic: "وَلَنَبۡلُوَنَّكُم بِشَيۡءٖ مِّنَ ٱلۡخَوۡفِ وَٱلۡجُوعِ وَنَقۡصٖ مِّنَ ٱلۡأَمۡوَٰلِ وَٱلۡأَنفُسِ وَٱلثَّمَرَٰتِۗ وَبَشِّرِ ٱلصَّٰبِرِينَ ۝ ٱلَّذِينَ إِذَآ أَصَٰبَتۡهُم مُّصِيبَةٞ قَالُوٓاْ إِنَّا لِلَّهِ وَإِنَّآ إِلَيۡهِ رَٰجِعُونَ ۝ أُوْلَٰٓئِكَ عَلَيۡهِمۡ صَلَوَٰتٞ مِّن رَّبِّهِمۡ وَرَحۡمَةٞۖ وَأُوْلَٰٓئِكَ هُمُ ٱلۡمُهۡتَدُونَ")

                    ScriptureQuote(text: "“For indeed, with hardship [will be] ease. Indeed, with hardship [will be] ease” (Quran 94:5-6).", arabic: "فَإِنَّ مَعَ ٱلۡعُسۡرِ يُسۡرًا ۝ إِنَّ مَعَ ٱلۡعُسۡرِ يُسۡرٗا")

                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“No fatigue, disease, sorrow, sadness, hurt, or distress befalls a Muslim, even the prick of a thorn, except that Allah expiates some of his sins by it” (Sahih al-Bukhari 5641).", arabic: "مَا يُصِيبُ الْمُسْلِمَ مِنْ نَصَبٍ وَلاَ وَصَبٍ وَلاَ هَمٍّ وَلاَ حُزْنٍ وَلاَ أَذًى وَلاَ غَمٍّ حَتَّى الشَّوْكَةِ يُشَاكُهَا، إِلاَّ كَفَّرَ اللَّهُ بِهَا مِنْ خَطَايَاهُ", dimmed: true)

                    ScriptureQuote(text: "“How wonderful is the affair of the believer, for all of it is good, and that is for no one but the believer: if good comes to him he is thankful, and that is good for him, and if harm comes to him he is patient, and that is good for him” (Sahih Muslim 2999).", arabic: "عَجَبًا لأَمْرِ الْمُؤْمِنِ إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ وَلَيْسَ ذَاكَ لأَحَدٍ إِلاَّ لِلْمُؤْمِنِ إِنْ أَصَابَتْهُ سَرَّاءُ شَكَرَ فَكَانَ خَيْرًا لَهُ وَإِنْ أَصَابَتْهُ ضَرَّاءُ صَبَرَ فَكَانَ خَيْرًا لَهُ", dimmed: true)

                    Text("The answer to craving is not to extinguish the self but to direct it: to want Allah and the Hereafter more than the world. The Buddha sought to escape the cycle; the believer is not in a cycle, but on a single road to his Lord.")
                        .font(.body)
                }

                Section(header: Text("3. THE SOUL IS REAL AND RETURNS ONCE")) {
                    Text("Buddhism denies a lasting self, yet speaks of rebirth; what, then, is reborn? The Quran affirms the soul as real, created, and known to its Maker, and affirms one death and one resurrection:")
                        .font(.body)
                    ScriptureQuote(text: "“And they ask you, [O Muhammad], about the soul. Say, ‘The soul is of the affair of my Lord. And mankind have not been given of knowledge except a little’” (Quran 17:85).", arabic: "وَيَسۡـَٔلُونَكَ عَنِ ٱلرُّوحِۖ قُلِ ٱلرُّوحُ مِنۡ أَمۡرِ رَبِّي وَمَآ أُوتِيتُم مِّنَ ٱلۡعِلۡمِ إِلَّا قَلِيلٗا")

                    ScriptureQuote(text: "“Allah takes the souls at the time of their death, and those that do not die [He takes] during their sleep. Then He keeps those for which He has decreed death and releases the others for a specified term. Indeed in that are signs for a people who give thought” (Quran 39:42).", arabic: "ٱللَّهُ يَتَوَفَّى ٱلۡأَنفُسَ حِينَ مَوۡتِهَا وَٱلَّتِي لَمۡ تَمُتۡ فِي مَنَامِهَاۖ فَيُمۡسِكُ ٱلَّتِي قَضَىٰ عَلَيۡهَا ٱلۡمَوۡتَ وَيُرۡسِلُ ٱلۡأُخۡرَىٰٓ إِلَىٰٓ أَجَلٖ مُّسَمًّىۚ إِنَّ فِي ذَٰلِكَ لَأٓيَٰتٖ لِّقَوۡمٖ يَتَفَكَّرُونَ")

                    ScriptureQuote(text: "“[For such is the state of the disbelievers], until, when death comes to one of them, he says, ‘My Lord, send me back that I might do righteousness in that which I left behind.’ No! It is only a word he is saying; and behind them is a barrier until the Day they are resurrected” (Quran 23:99-100).", arabic: "حَتَّىٰٓ إِذَا جَآءَ أَحَدَهُمُ ٱلۡمَوۡتُ قَالَ رَبِّ ٱرۡجِعُونِ ۝ لَعَلِّيٓ أَعۡمَلُ صَٰلِحٗا فِيمَا تَرَكۡتُۚ كـَلَّآۚ إِنَّهَا كَلِمَةٌ هُوَ قَآئِلُهَاۖ وَمِن وَرَآئِهِم بَرۡزَخٌ إِلَىٰ يَوۡمِ يُبۡعَثُونَ")

                    Text("Justice is real too, and exact, but it is the justice of a Judge who knows every deed, not an impersonal karma that punishes a person for a past he cannot recall.")
                        .font(.body)
                }

                Section(header: Text("4. THE MIDDLE WAY IS THE SUNNAH")) {
                    Text("The Buddha left extreme asceticism for a “middle way,“ yet his path still turned monks from marriage, property, and the world. Islam’s middle way is fuller: enjoy what Allah made lawful, in moderation, and worship Him in the midst of life:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Who has forbidden the adornment of Allah which He has produced for His servants and the good [lawful] things of provision?’” (Quran 7:32).", arabic: "قُلۡ مَنۡ حَرَّمَ زِينَةَ ٱللَّهِ ٱلَّتِيٓ أَخۡرَجَ لِعِبَادِهِۦ وَٱلطَّيِّبَٰتِ مِنَ ٱلرِّزۡقِۚ")

                    ScriptureQuote(text: "“And [they are] those who, when they spend, do so not excessively or sparingly but are ever, between that, [justly] moderate” (Quran 25:67).", arabic: "وَٱلَّذِينَ إِذَآ أَنفَقُواْ لَمۡ يُسۡرِفُواْ وَلَمۡ يَقۡتُرُواْ وَكَانَ بَيۡنَ ذَٰلِكَ قَوَامٗا")

                    ScriptureQuote(text: "“Whoever turns away from my Sunnah is not of me” (Sahih al-Bukhari 5063).", arabic: "فَمَنْ رَغِبَ عَنْ سُنَّتِي فَلَيْسَ مِنِّي", dimmed: true)

                    Text("And the goal is not the extinction of the self but its fulfilment: a soul at peace, returning to its Lord, in a Paradise where craving is satisfied, not destroyed.")
                        .font(.body)
                }

                Section(header: Text("5. SALVATION IS BY MERCY, NOT BY SELF-EFFORT ALONE")) {
                    Text("Buddhism has no one to turn to; each person must work out his own release. Islam says the effort is required, but the end is a gift:")
                        .font(.body)
                    ScriptureQuote(text: "“None of you will enter Paradise by his deeds.” They said: Not even you, O Messenger of Allah? He said: “Not even I, unless Allah covers me with His mercy” (Sahih al-Bukhari 5673, Sahih Muslim 2816).", arabic: "لَنْ يُدْخِلَ أَحَدًا عَمَلُهُ الْجَنَّةَ. قَالُوا وَلاَ أَنْتَ يَا رَسُولَ اللَّهِ قَالَ لاَ، وَلاَ أَنَا إِلاَّ أَنْ يَتَغَمَّدَنِي اللَّهُ بِفَضْلٍ وَرَحْمَةٍ", dimmed: true)

                    ScriptureQuote(text: "“The strong believer is better and more beloved to Allah than the weak believer, and in both there is good. Be eager for what benefits you, seek help from Allah, and do not give up” (Sahih Muslim 2664).", arabic: "الْمُؤْمِنُ الْقَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللَّهِ مِنَ الْمُؤْمِنِ الضَّعِيفِ وَفِي كُلٍّ خَيْرٌ احْرِصْ عَلَى مَا يَنْفَعُكَ وَاسْتَعِنْ بِاللَّهِ وَلاَ تَعْجِزْ", dimmed: true)

                    Text("As for the statues and offerings, the Buddha himself, by the Buddhist account, asked to be honoured by following his teaching, not by worship; and the worship of images is the shirk every prophet forbade (Quran 21:52-54).")
                        .font(.body)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Was the Buddha a prophet?**")
                        .font(.body)
                    Text("We do not know. Allah sent messengers whose stories He did not tell us:")
                        .font(.body)
                    ScriptureQuote(text: "“And [We sent] messengers about whom We have related [their stories] to you before and messengers about whom We have not related to you” (Quran 4:164).", arabic: "وَرُسُلٗا قَدۡ قَصَصۡنَٰهُمۡ عَلَيۡكَ مِن قَبۡلُ وَرُسُلٗا لَّمۡ نَقۡصُصۡهُمۡ عَلَيۡكَۚ")
                    ScriptureQuote(text: "“And We certainly sent into every nation a messenger, [saying], ‘Worship Allah and avoid Taghut’” (Quran 16:36).", arabic: "وَلَقَدۡ بَعَثۡنَا فِي كُلِّ أُمَّةٖ رَّسُولًا أَنِ ٱعۡبُدُواْ ٱللَّهَ وَٱجۡتَنِبُواْ ٱلطَّٰغُوتَۖ")
                    Text("So a messenger may well have been sent to the people of the Ganges plain. But every messenger taught one thing above all:")
                        .font(.body)
                    ScriptureQuote(text: "“And We sent not before you any messenger except that We revealed to him that, ‘There is no deity except Me, so worship Me’” (Quran 21:25).", arabic: "وَمَآ أَرۡسَلۡنَا مِن قَبۡلِكَ مِن رَّسُولٍ إِلَّا نُوحِيٓ إِلَيۡهِ أَنَّهُۥ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعۡبُدُونِ")
                    Text("The Buddhism that has come down to us teaches no Creator and directs no worship to Him. So either the Buddha’s teaching was changed after him, as the teaching of Isa (peace be upon him) was changed, or he was not a messenger of Allah. We do not affirm his prophethood, and we do not insult him; we say what we know and stop at what we do not (Quran 40:78).")
                        .font(.body)

                    Text("**Does Buddhism have a God?**")
                        .font(.body)
                    Text("Classical Buddhism has none; it speaks of gods (devas) as beings within the cycle, but of no Creator. The Quran’s answer is the question it puts to every denier: were you created by nothing, or did you create yourselves, or did you create the heavens and the earth? (Quran 52:35-36, quoted above.) The messengers put the same question to their peoples:")
                        .font(.body)
                    ScriptureQuote(text: "“Their messengers said, ‘Can there be doubt about Allah, Creator of the heavens and earth? He invites you that He may forgive you of your sins, and He delays your death for a specified term’” (Quran 14:10).", arabic: "قَالَتۡ رُسُلُهُمۡ أَفِي ٱللَّهِ شَكّٞ فَاطِرِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ يَدۡعُوكُمۡ لِيَغۡفِرَ لَكُم مِّن ذُنُوبِكُمۡ وَيُؤَخِّرَكُمۡ إِلَىٰٓ أَجَلٖ مُّسَمّٗىۚ")
                    Text("Tellingly, Buddhists in practice do bow, make offerings, and ask for help, before the Buddha, before the bodhisattvas, and before local spirits. A religion without a God has not kept its followers from worshipping, because the fitrah demands an object:")
                        .font(.body)
                    ScriptureQuote(text: "“So direct your face toward the religion, inclining to truth. [Adhere to] the fitrah of Allah upon which He has created [all] people. No change should there be in the creation of Allah. That is the correct religion, but most of the people do not know” (Quran 30:30).", arabic: "فَأَقِمۡ وَجۡهَكَ لِلدِّينِ حَنِيفٗاۚ فِطۡرَتَ ٱللَّهِ ٱلَّتِي فَطَرَ ٱلنَّاسَ عَلَيۡهَاۚ لَا تَبۡدِيلَ لِخَلۡقِ ٱللَّهِۚ ذَٰلِكَ ٱلدِّينُ ٱلۡقَيِّمُ وَلَٰكِنَّ أَكۡثَرَ ٱلنَّاسِ لَا يَعۡلَمُونَ")

                    Text("**Is meditation allowed?**")
                        .font(.body)
                    Text("Reflection and remembrance are commanded. The believers are those who “give thought to the creation of the heavens and the earth” (Quran 3:191, quoted above), and Allah asks:")
                        .font(.body)
                    ScriptureQuote(text: "“Do they not contemplate within themselves? Allah has not created the heavens and the earth and what is between them except in truth and for a specified term” (Quran 30:8).", arabic: "أَوَلَمۡ يَتَفَكَّرُواْ فِيٓ أَنفُسِهِمۗ مَّا خَلَقَ ٱللَّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ وَمَا بَيۡنَهُمَآ إِلَّا بِٱلۡحَقِّ وَأَجَلٖ مُّسَمّٗىۗ")
                    Text("The heart finds its rest in dhikr (Quran 13:28), and the Prophet (peace be upon him) himself withdrew to reflect and worship before revelation came. Aishah (may Allah be pleased with her) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Then the love of seclusion was bestowed upon him. He used to go in seclusion in the cave of Hira where he used to worship (Allah alone) continuously for many days before his desire to see his family” (Sahih al-Bukhari 3).", arabic: "ثُمَّ حُبِّبَ إِلَيْهِ الْخَلاَءُ، وَكَانَ يَخْلُو بِغَارِ حِرَاءٍ فَيَتَحَنَّثُ فِيهِ ـ وَهُوَ التَّعَبُّدُ ـ اللَّيَالِيَ ذَوَاتِ الْعَدَدِ قَبْلَ أَنْ يَنْزِعَ إِلَى أَهْلِهِ", dimmed: true)
                    Text("What is not allowed is Buddhist meditation as such: chanting mantras, visualising Buddhas, emptying the self to realise “no-self,” or sitting before a statue in a posture of devotion. Islamic reflection has an object, Allah and His signs; it fills the heart rather than emptying it. The prayer itself, with its stillness, its recitation, and its prostration, is the Muslim’s daily discipline of the mind, and the Sunnah retreat (i‘tikaf) in the mosque is his seclusion.")
                        .font(.body)

                    Text("**Is Islam against desire and pleasure?**")
                        .font(.body)
                    Text("No. Allah rebukes those who forbid His adornment and good provision (Quran 7:32, quoted above), and commands:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, do not prohibit the good things which Allah has made lawful to you and do not transgress. Indeed, Allah does not like transgressors. And eat of what Allah has provided for you [which is] lawful and good. And fear Allah, in whom you are believers” (Quran 5:87-88).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ لَا تُحَرِّمُواْ طَيِّبَٰتِ مَآ أَحَلَّ ٱللَّهُ لَكُمۡ وَلَا تَعۡتَدُوٓاْۚ إِنَّ ٱللَّهَ لَا يُحِبُّ ٱلۡمُعۡتَدِينَ ۝ وَكُلُواْ مِمَّا رَزَقَكُمُ ٱللَّهُ حَلَٰلٗا طَيِّبٗاۚ وَٱتَّقُواْ ٱللَّهَ ٱلَّذِيٓ أَنتُم بِهِۦ مُؤۡمِنُونَ")
                    ScriptureQuote(text: "“But seek, through that which Allah has given you, the home of the Hereafter; and [yet], do not forget your share of the world. And do good as Allah has done good to you” (Quran 28:77).", arabic: "وَٱبۡتَغِ فِيمَآ ءَاتَىٰكَ ٱللَّهُ ٱلدَّارَ ٱلۡأٓخِرَةَۖ وَلَا تَنسَ نَصِيبَكَ مِنَ ٱلدُّنۡيَاۖ وَأَحۡسِن كَمَآ أَحۡسَنَ ٱللَّهُ إِلَيۡكَۖ")
                    Text("The believer’s prayer asks for both worlds:")
                        .font(.body)
                    ScriptureQuote(text: "“Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire” (Quran 2:201).", arabic: "رَبَّنَآ ءَاتِنَا فِي ٱلدُّنۡيَا حَسَنَةٗ وَفِي ٱلۡأٓخِرَةِ حَسَنَةٗ وَقِنَا عَذَابَ ٱلنَّارِ")
                    Text("When Abu ad-Darda’ fasted every day and prayed every night, his brother Salman (may Allah be pleased with them) made him eat and sleep and told him that his Lord, his own self, and his family each had a right over him; the Prophet (peace be upon him) said: “Salman has spoken the truth” (Sahih al-Bukhari 1968). He refused the three men who vowed perpetual fasting, all-night prayer, and celibacy: whoever turns away from my Sunnah is not of me (Sahih al-Bukhari 5063, quoted above). Desire is not the enemy; disobedience is. Pleasure within Allah’s limits is His gift, and gratitude for it is worship.")
                        .font(.body)

                    Text("**Karma or qadar?**")
                        .font(.body)
                    Text("Both say deeds have consequences. The difference is who keeps the account. In Islam it is a Lord who sees:")
                        .font(.body)
                    ScriptureQuote(text: "“So whoever does an atom's weight of good will see it, and whoever does an atom's weight of evil will see it” (Quran 99:7-8).", arabic: "فَمَن يَعۡمَلۡ مِثۡقَالَ ذَرَّةٍ خَيۡرٗا يَرَهُۥ ۝ وَمَن يَعۡمَلۡ مِثۡقَالَ ذَرَّةٖ شَرّٗا يَرَهُۥ")
                    ScriptureQuote(text: "“Indeed, Allah does not do injustice, [even] as much as an atom's weight; while if there is a good deed, He multiplies it and gives from Himself a great reward” (Quran 4:40).", arabic: "إِنَّ ٱللَّهَ لَا يَظۡلِمُ مِثۡقَالَ ذَرَّةٖۖ وَإِن تَكُ حَسَنَةٗ يُضَٰعِفۡهَا وَيُؤۡتِ مِن لَّدُنۡهُ أَجۡرًا عَظِيمٗا")
                    ScriptureQuote(text: "“And every soul earns not [blame] except against itself, and no bearer of burdens will bear the burden of another” (Quran 6:164).", arabic: "وَلَا تَكۡسِبُ كُلُّ نَفۡسٍ إِلَّا عَلَيۡهَاۚ وَلَا تَزِرُ وَازِرَةٞ وِزۡرَ أُخۡرَىٰۚ")
                    Text("Karma has no mercy and no one to ask for it. Allah has both:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful’” (Quran 39:53).", arabic: "قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ")
                    Text("And in a hadith qudsi Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“O My servants, you sin by night and by day, and I forgive all sins, so seek forgiveness of Me and I shall forgive you” (Sahih Muslim 2577).", arabic: "يَا عِبَادِي إِنَّكُمْ تُخْطِئُونَ بِاللَّيْلِ وَالنَّهَارِ وَأَنَا أَغْفِرُ الذُّنُوبَ جَمِيعًا فَاسْتَغْفِرُونِي أَغْفِرْ لَكُمْ", dimmed: true)
                    Text("Qadar also answers the child born blind or poor, for whom karma has only the verdict of a past life: he has done nothing wrong, his trial is measured with mercy, and his patience will be rewarded without account (Quran 39:10).")
                        .font(.body)

                    Text("**Rebirth or resurrection?**")
                        .font(.body)
                    Text("Resurrection. There is no return to this world (Quran 23:99-100, quoted above). What returns is the same person, raised from the dead by the One who made him the first time:")
                        .font(.body)
                    ScriptureQuote(text: "“As We began the first creation, We will repeat it. [That is] a promise binding upon Us. Indeed, We will do it” (Quran 21:104).", arabic: "كَمَا بَدَأۡنَآ أَوَّلَ خَلۡقٖ نُّعِيدُهُۥۚ وَعۡدًا عَلَيۡنَآۚ إِنَّا كُنَّا فَٰعِلِينَ")
                    ScriptureQuote(text: "“How can you disbelieve in Allah when you were lifeless and He brought you to life; then He will cause you to die, then He will bring you [back] to life, and then to Him you will be returned” (Quran 2:28).", arabic: "كَيۡفَ تَكۡفُرُونَ بِٱللَّهِ وَكُنتُمۡ أَمۡوَٰتٗا فَأَحۡيَٰكُمۡۖ ثُمَّ يُمِيتُكُمۡ ثُمَّ يُحۡيِيكُمۡ ثُمَّ إِلَيۡهِ تُرۡجَعُونَ")
                    ScriptureQuote(text: "“Does man not remember that We created him before, while he was nothing?” (Quran 19:67).", arabic: "أَوَلَا يَذۡكُرُ ٱلۡإِنسَٰنُ أَنَّا خَلَقۡنَٰهُ مِن قَبۡلُ وَلَمۡ يَكُ شَيۡـٔٗا")
                    Text("Buddhism itself struggles to say what is reborn if there is no self. Islam has no such puzzle: the soul is one, it lives once, and it will stand once before its Lord.")
                        .font(.body)

                    Text("**Is nirvana the same as Paradise?**")
                        .font(.body)
                    Text("No. Nirvana is named after the going-out of a flame: the end of craving and of rebirth. Buddhists deny that it is simple annihilation and mostly decline to describe it at all; what is not claimed for it is a person living with his Lord, for there is no Lord in it. Paradise is a place, eternal, embodied, personal, and full of delight:")
                        .font(.body)
                    ScriptureQuote(text: "“And you will have therein whatever your souls desire, and you will have therein whatever you request [or wish]” (Quran 41:31).", arabic: "وَلَكُمۡ فِيهَا مَا تَشۡتَهِيٓ أَنفُسُكُمۡ وَلَكُمۡ فِيهَا مَا تَدَّعُونَ")
                    ScriptureQuote(text: "“They will have whatever they wish therein, and with Us is more” (Quran 50:35).", arabic: "لَهُم مَّا يَشَآءُونَ فِيهَا وَلَدَيۡنَا مَزِيدٞ")
                    ScriptureQuote(text: "“And no soul knows what has been hidden for them of comfort for eyes as reward for what they used to do” (Quran 32:17).", arabic: "فَلَا تَعۡلَمُ نَفۡسٞ مَّآ أُخۡفِيَ لَهُم مِّن قُرَّةِ أَعۡيُنٖ جَزَآءَۢ بِمَا كَانُواْ يَعۡمَلُونَ")
                    Text("The Prophet (peace be upon him) said that Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“I have prepared for My pious servants what no eye has ever seen, and no ear has ever heard, and no human heart has ever perceived” (Sahih al-Bukhari 3244, Sahih Muslim 2824).", arabic: "أَعْدَدْتُ لِعِبَادِي الصَّالِحِينَ مَا لاَ عَيْنَ رَأَتْ، وَلاَ أُذُنَ سَمِعَتْ، وَلاَ خَطَرَ عَلَى قَلْبِ بَشَرٍ", dimmed: true)
                    Text("The greatest of its joys is the one Buddhism cannot offer at all: seeing the Face of the Lord (Quran 75:22-23). Islam does not ask a man to stop wanting; it promises him what he wants, and better.")
                        .font(.body)

                    Text("**Should Muslims be vegetarian?**")
                        .font(.body)
                    Text("No, though a Muslim may eat little meat if he likes. Allah made animals lawful and said so (Quran 5:87-88, above):")
                        .font(.body)
                    ScriptureQuote(text: "“And the grazing livestock He has created for you; in them is warmth and [numerous] benefits, and from them you eat” (Quran 16:5).", arabic: "وَٱلۡأَنۡعَٰمَ خَلَقَهَاۖ لَكُمۡ فِيهَا دِفۡءٞ وَمَنَٰفِعُ وَمِنۡهَا تَأۡكُلُونَ")
                    ScriptureQuote(text: "“And the camels and cattle We have appointed for you as among the symbols of Allah; for you therein is good. So mention the name of Allah upon them when lined up [for sacrifice]; and when they are [lifeless] on their sides, then eat from them and feed the needy and the beggar. Thus have We subjected them to you that you may be grateful” (Quran 22:36).", arabic: "وَٱلۡبُدۡنَ جَعَلۡنَٰهَا لَكُم مِّن شَعَٰٓئِرِ ٱللَّهِ لَكُمۡ فِيهَا خَيۡرٞۖ فَٱذۡكُرُواْ ٱسۡمَ ٱللَّهِ عَلَيۡهَا صَوَآفَّۖ فَإِذَا وَجَبَتۡ جُنُوبُهَا فَكُلُواْ مِنۡهَا وَأَطۡعِمُواْ ٱلۡقَانِعَ وَٱلۡمُعۡتَرَّۚ كَذَٰلِكَ سَخَّرۡنَٰهَا لَكُمۡ لَعَلَّكُمۡ تَشۡكُرُونَ")
                    Text("The Prophet (peace be upon him) ate meat, sacrificed animals, and sacrificed cows on behalf of his wives at Hajj (Sahih al-Bukhari 1709). To forbid what Allah allowed is itself a sin. But Islam commands mercy to animals more strictly than any vegetarian creed:")
                        .font(.body)
                    ScriptureQuote(text: "“A woman entered the Fire because of a cat which she had tied, neither giving it food nor setting it free to eat from the vermin of the earth” (Sahih al-Bukhari 3318).", arabic: "دَخَلَتِ امْرَأَةٌ النَّارَ فِي هِرَّةٍ رَبَطَتْهَا، فَلَمْ تُطْعِمْهَا، وَلَمْ تَدَعْهَا تَأْكُلُ مِنْ خِشَاشِ الأَرْضِ", dimmed: true)
                    ScriptureQuote(text: "“Verily Allah has enjoined goodness to everything; so when you kill, kill in a good way and when you slaughter, slaughter in a good way. So every one of you should sharpen his knife, and let the slaughtered animal die comfortably” (Sahih Muslim 1955).", arabic: "إِنَّ اللَّهَ كَتَبَ الإِحْسَانَ عَلَى كُلِّ شَىْءٍ فَإِذَا قَتَلْتُمْ فَأَحْسِنُوا الْقِتْلَةَ وَإِذَا ذَبَحْتُمْ فَأَحْسِنُوا الذَّبْحَ وَلْيُحِدَّ أَحَدُكُمْ شَفْرَتَهُ فَلْيُرِحْ ذَبِيحَتَهُ", dimmed: true)
                    Text("And a man was forgiven his sins for giving water to a thirsty dog; when the Companions asked whether there was reward in serving animals, the Prophet (peace be upon him) said there is a reward for serving any living creature (Sahih al-Bukhari 2363, Sahih Muslim 2244). The animals are communities like us (Quran 6:38); we are permitted to eat them, and forbidden to torment them.")
                        .font(.body)

                    Text("**Is Buddhist compassion the same as Islamic mercy?**")
                        .font(.body)
                    Text("They meet in practice and differ in root. Buddhist compassion (karuna) is a cultivated state of mind; Islamic mercy (rahmah) is an attribute of Allah, ar-Rahman, which He shares with His creatures and commands from them. The Prophet (peace be upon him) was sent as “a mercy to the worlds” (Quran 21:107), and he said:")
                        .font(.body)
                    ScriptureQuote(text: "“He who shows no mercy to the people, Allah, the Exalted and Glorious, does not show mercy to him” (Sahih Muslim 2319, Sahih al-Bukhari 7376).", arabic: "مَنْ لاَ يَرْحَمِ النَّاسَ لاَ يَرْحَمْهُ اللَّهُ عَزَّ وَجَلَّ", dimmed: true)
                    ScriptureQuote(text: "“The Compassionate One has mercy on those who are merciful. If you show mercy to those who are on the earth, He Who is in the heaven will show mercy to you” (Sunan Abi Dawud 4941; graded sahih by al-Albani).", arabic: "الرَّاحِمُونَ يَرْحَمُهُمُ الرَّحْمَنُ ارْحَمُوا أَهْلَ الأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ", dimmed: true)
                    ScriptureQuote(text: "“There are one hundred (parts of) mercy for Allah and He has sent down out of these one part of mercy upon the jinn and human beings and animals and the insects, and it is because of this (one part) that they love one another, show kindness to one another and even the beast treats its young one with affection, and Allah has reserved ninety-nine parts of mercy with which He would treat His servants on the Day of Resurrection” (Sahih Muslim 2752).", arabic: "إِنَّ لِلَّهِ مِائَةَ رَحْمَةٍ أَنْزَلَ مِنْهَا رَحْمَةً وَاحِدَةً بَيْنَ الْجِنِّ وَالإِنْسِ وَالْبَهَائِمِ وَالْهَوَامِّ فَبِهَا يَتَعَاطَفُونَ وَبِهَا يَتَرَاحَمُونَ وَبِهَا تَعْطِفُ الْوَحْشُ عَلَى وَلَدِهَا وَأَخَّرَ اللَّهُ تِسْعًا وَتِسْعِينَ رَحْمَةً يَرْحَمُ بِهَا عِبَادَهُ يَوْمَ الْقِيَامَةِ", dimmed: true)
                    Text("Islamic mercy is also joined to justice: it feeds the poor by law (zakah), protects the weak by law, and punishes the oppressor. A mercy that has no Judge behind it is only a feeling; the mercy of Islam is a command, a promise, and a Name.")
                        .font(.body)

                    Text("**Is monasticism praiseworthy?**")
                        .font(.body)
                    Text("No. Allah called it something people invented and then failed to keep (Quran 57:27, quoted above), and the Prophet (peace be upon him) said that whoever turns away from his Sunnah of marrying, sleeping, and eating is not of him (Sahih al-Bukhari 5063, quoted above). Sa‘d ibn Abi Waqqas (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah’s Messenger (peace be upon him) forbade ‘Uthman bin Maz‘un to abstain from marrying, and if he had allowed him, we would have gotten ourselves castrated” (Sahih al-Bukhari 5073).", arabic: "رَدَّ رَسُولُ اللَّهِ صلى الله عليه وسلم عَلَى عُثْمَانَ بْنِ مَظْعُونٍ التَّبَتُّلَ، وَلَوْ أَذِنَ لَهُ لاَخْتَصَيْنَا", dimmed: true)
                    Text("The Muslim’s asceticism (zuhd) is in the heart, not in the abandonment of duties: he marries, earns, raises children, serves his neighbours, and fights injustice, and in the midst of all that he keeps his heart for Allah and seeks the Hereafter without forgetting his share of the world (Quran 28:77, above). The Companions were traders, farmers, soldiers, and fathers, and they were the best of this Ummah.")
                        .font(.body)

                    Text("**Is the self (nafs) an illusion?**")
                        .font(.body)
                    Text("No. The soul is real, though its nature is known only to its Maker (Quran 17:85, quoted above). Allah swears by it:")
                        .font(.body)
                    ScriptureQuote(text: "“And [by] the soul and He who proportioned it and inspired it [with discernment of] its wickedness and its righteousness, he has succeeded who purifies it, and he has failed who instills it [with corruption]” (Quran 91:7-10).", arabic: "وَنَفۡسٖ وَمَا سَوَّىٰهَا ۝ فَأَلۡهَمَهَا فُجُورَهَا وَتَقۡوَىٰهَا ۝ قَدۡ أَفۡلَحَ مَن زَكَّىٰهَا ۝ وَقَدۡ خَابَ مَن دَسَّىٰهَا")
                    Text("It is the self that will testify on the Day of Judgement:")
                        .font(.body)
                    ScriptureQuote(text: "“Rather, man, against himself, will be a witness” (Quran 75:14).", arabic: "بَلِ ٱلۡإِنسَٰنُ عَلَىٰ نَفۡسِهِۦ بَصِيرَةٞ")
                    Text("And it is the self, purified, that is welcomed home:")
                        .font(.body)
                    ScriptureQuote(text: "“[To the righteous it will be said], ‘O reassured soul, return to your Lord, well-pleased and pleasing [to Him]’” (Quran 89:27-28).", arabic: "يَٰٓأَيَّتُهَا ٱلنَّفۡسُ ٱلۡمُطۡمَئِنَّةُ ۝ ٱرۡجِعِيٓ إِلَىٰ رَبِّكِ رَاضِيَةٗ مَّرۡضِيَّةٗ")
                    Text("If there were no self there would be no one to suffer, no one to be liberated, and no one to be reborn; Buddhists have long debated how to answer that, and the doctrine of no-self sits uneasily with the Four Noble Truths it was meant to serve. Islam says: you are real, your Lord is real, and the road between you is real. Purify the self; do not deny it.")
                        .font(.body)

                    Text("**Are the Buddhist precepts like Islamic law?**")
                        .font(.body)
                    Text("The five precepts for laypeople, not to kill, steal, commit sexual misconduct, lie, or take intoxicants, are all commanded in Islam:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Come, I will recite what your Lord has prohibited to you. [He commands] that you not associate anything with Him, and to parents, good treatment, and do not kill your children out of poverty; We will provide for you and them. And do not approach immoralities - what is apparent of them and what is concealed. And do not kill the soul which Allah has forbidden [to be killed] except by [legal] right. This has He instructed you that you may use reason’” (Quran 6:151).", arabic: "قُلۡ تَعَالَوۡاْ أَتۡلُ مَا حَرَّمَ رَبُّكُمۡ عَلَيۡكُمۡۖ أَلَّا تُشۡرِكُواْ بِهِۦ شَيۡـٔٗاۖ وَبِٱلۡوَٰلِدَيۡنِ إِحۡسَٰنٗاۖ وَلَا تَقۡتُلُوٓاْ أَوۡلَٰدَكُم مِّنۡ إِمۡلَٰقٖ نَّحۡنُ نَرۡزُقُكُمۡ وَإِيَّاهُمۡۖ وَلَا تَقۡرَبُواْ ٱلۡفَوَٰحِشَ مَا ظَهَرَ مِنۡهَا وَمَا بَطَنَۖ وَلَا تَقۡتُلُواْ ٱلنَّفۡسَ ٱلَّتِي حَرَّمَ ٱللَّهُ إِلَّا بِٱلۡحَقِّۚ ذَٰلِكُمۡ وَصَّىٰكُم بِهِۦ لَعَلَّكُمۡ تَعۡقِلُونَ")
                    ScriptureQuote(text: "“O you who have believed, indeed, intoxicants, gambling, [sacrificing on] stone alters [to other than Allah], and divining arrows are but defilement from the work of Satan, so avoid it that you may be successful” (Quran 5:90).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ إِنَّمَا ٱلۡخَمۡرُ وَٱلۡمَيۡسِرُ وَٱلۡأَنصَابُ وَٱلۡأَزۡلَٰمُ رِجۡسٞ مِّنۡ عَمَلِ ٱلشَّيۡطَٰنِ فَٱجۡتَنِبُوهُ لَعَلَّكُمۡ تُفۡلِحُونَ")
                    Text("Notice that the Quran’s list begins with the one precept Buddhism lacks: do not associate anything with Allah. Right conduct is agreed; the question is whom one is right before. A law without a Lawgiver is advice, and Islam gives the moral sense that every sound heart shares its source and its Judge.")
                        .font(.body)
                }

                Section(header: Text("THE INVITATION")) {
                    Text("Islam agrees with the Buddhist that craving for the world enslaves, that compassion is a duty, and that the mind must be disciplined. It adds what he lacks: the One who made him, the reason he suffers, the soul that will meet its Lord, and a mercy to hope in.")
                        .font(.body)
                    ScriptureQuote(text: "“Did I not enjoin upon you, O children of Adam, that you not worship Satan - [for] indeed, he is to you a clear enemy - and that you worship [only] Me? This is a straight path” (Quran 36:60-61).", arabic: "أَلَمۡ أَعۡهَدۡ إِلَيۡكُمۡ يَٰبَنِيٓ ءَادَمَ أَن لَّا تَعۡبُدُواْ ٱلشَّيۡطَٰنَۖ إِنَّهُۥ لَكُمۡ عَدُوّٞ مُّبِينٞ ۝ وَأَنِ ٱعۡبُدُونِيۚ هَٰذَا صِرَٰطٞ مُّسۡتَقِيمٞ")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Buddhism describes suffering and denies the Creator; Islam names the Creator and gives suffering its meaning. There is one life, one soul, one Judge, and one road: worship Allah, be patient, and hope for His mercy.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Buddhism")
        .selectableArticleList()
    }
}

struct AtheismAnswerView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: atheism says there is no God and the universe came from nothing or made itself. The Quran answers with the argument that made a Companion's heart nearly fly: nothing comes from nothing, order does not come from chaos, and the very fitrah of man knows its Maker.")
                        .font(.body)
                }

                Section(header: Text("WHAT ATHEISM CLAIMS")) {
                    Text("Atheism denies that there is a Creator. The universe, in this view, either has no cause, or caused itself, or has always existed, and life, consciousness, and moral law arose from matter without purpose. The Quran met this claim in the Arabs who said:")
                        .font(.body)
                    ScriptureQuote(text: "“And they say, ‘There is not but our worldly life; we die and live, and nothing destroys us except time.’ And they have of that no knowledge; they are only assuming” (Quran 45:24).", arabic: "وَقَالُواْ مَا هِيَ إِلَّا حَيَاتُنَا ٱلدُّنۡيَا نَمُوتُ وَنَحۡيَا وَمَا يُهۡلِكُنَآ إِلَّا ٱلدَّهۡرُۚ وَمَا لَهُم بِذَٰلِكَ مِنۡ عِلۡمٍۖ إِنۡ هُمۡ إِلَّا يَظُنُّونَ")

                    Text("Notice the verdict: “they are only assuming.“ Atheism is not the result of knowledge; it is a claim that cannot be proved, since to know there is no God one would have to know everything.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Atheism / ilhad (إِلْحَاد)**: from lahada, to deviate or lean away; the lahd is the niche in a grave that is cut sideways, away from the straight shaft. Ilhad is thus any leaning away from the truth, and the **mulhid (مُلْحِد)** in later usage is the one who denies the Creator altogether. The Quran uses the root for those who twist Allah’s names and His verses:")
                        .font(.body)
                    ScriptureQuote(text: "“And to Allah belong the best names, so invoke Him by them. And leave [the company of] those who practice deviation concerning His names. They will be recompensed for what they have been doing” (Quran 7:180).", arabic: "وَلِلَّهِ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰ فَٱدۡعُوهُ بِهَاۖ وَذَرُواْ ٱلَّذِينَ يُلۡحِدُونَ فِيٓ أَسۡمَٰٓئِهِۦۚ سَيُجۡزَوۡنَ مَا كَانُواْ يَعۡمَلُونَ")
                    ScriptureQuote(text: "“Indeed, those who inject deviation into Our verses are not concealed from Us” (Quran 41:40).", arabic: "إِنَّ ٱلَّذِينَ يُلۡحِدُونَ فِيٓ ءَايَٰتِنَا لَا يَخۡفَوۡنَ عَلَيۡنَآۗ")

                    Text("**Dahriyyah (الدَّهْرِيَّة)**: from dahr, time; the ancient materialists who held that the world has no beginning and no Judge, only time that wears everything away. The Quran quoted them (Quran 45:24, above), and Ibn Hazm (may Allah have mercy on him) refuted those who say the world is eternal in the opening chapters of al-Fisal fi al-Milal. Since the pagan Arabs blamed “time” for every loss, the Prophet (peace be upon him) taught:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not curse Time, for it is Allah Who is Time” (Sahih Muslim 2246).", arabic: "لاَ تَسُبُّوا الدَّهْرَ فَإِنَّ اللَّهَ هُوَ الدَّهْرُ", dimmed: true)
                    Text("That is, what they call time is Allah’s disposal of affairs: “in My Hands are all things, and I cause the revolution of day and night” (Sahih al-Bukhari 4826).")
                        .font(.body)

                    Text("**Agnosticism**: from the Greek for “not knowing”; the claim that whether God exists cannot be known. The messengers answered it with a question of their own, “Can there be doubt about Allah, Creator of the heavens and earth?” (Quran 14:10, quoted in the questions below).")
                        .font(.body)

                    Text("**Naturalism / materialism**: the belief that matter and its laws are all there is, that the universe caused itself or has no cause, and that mind, purpose, and morality are by-products of matter. The Quran’s three-fold question (Quran 52:35-36, quoted below) is aimed exactly here: created by nothing, self-created, or created by another?")
                        .font(.body)

                    Text("**Scientism**: the belief that the methods of natural science are the only road to knowledge, so that whatever they cannot measure does not exist. The Quran honours knowledge and observation, and describes the limit of a knowledge that stops at the surface:")
                        .font(.body)
                    ScriptureQuote(text: "“They know what is apparent of the worldly life, but they, of the Hereafter, are unaware” (Quran 30:7).", arabic: "يَعۡلَمُونَ ظَٰهِرٗا مِّنَ ٱلۡحَيَوٰةِ ٱلدُّنۡيَا وَهُمۡ عَنِ ٱلۡأٓخِرَةِ هُمۡ غَٰفِلُونَ")
                    ScriptureQuote(text: "“And they have thereof no knowledge. They follow not except assumption, and indeed, assumption avails not against the truth at all” (Quran 53:28).", arabic: "وَمَا لَهُم بِهِۦ مِنۡ عِلۡمٍۖ إِن يَتَّبِعُونَ إِلَّا ٱلظَّنَّۖ وَإِنَّ ٱلظَّنَّ لَا يُغۡنِي مِنَ ٱلۡحَقِّ شَيۡـٔٗا")

                    Text("**Secularism**: the confining of religion to private belief, with life, law, and learning conducted as if there were no God. Islam knows no such division; the whole of a life is offered to its Maker:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Indeed, my prayer, my rites of sacrifice, my living and my dying are for Allah, Lord of the worlds’” (Quran 6:162).", arabic: "قُلۡ إِنَّ صَلَاتِي وَنُسُكِي وَمَحۡيَايَ وَمَمَاتِي لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ")

                    Text("**Humanism**: the creed that makes man the measure of all things and the source of his own values. The Quran’s diagnosis of it is a single sentence:")
                        .font(.body)
                    ScriptureQuote(text: "“No! [But] indeed, man transgresses because he sees himself self-sufficient” (Quran 96:6-7).", arabic: "كـَلَّآ إِنَّ ٱلۡإِنسَٰنَ لَيَطۡغَىٰٓ ۝ أَن رَّءَاهُ ٱسۡتَغۡنَىٰٓ")
                    ScriptureQuote(text: "“O mankind, you are those in need of Allah, while Allah is the Free of need, the Praiseworthy” (Quran 35:15).", arabic: "يَٰٓأَيُّهَا ٱلنَّاسُ أَنتُمُ ٱلۡفُقَرَآءُ إِلَى ٱللَّهِۖ وَٱللَّهُ هُوَ ٱلۡغَنِيُّ ٱلۡحَمِيدُ")

                    Text("**Nihilism**: from the Latin nihil, nothing; the conclusion, drawn honestly by some atheists and resisted by others, that life has no meaning, value, or purpose. The Quran names the alternative:")
                        .font(.body)
                    ScriptureQuote(text: "“Then did you think that We created you uselessly and that to Us you would not be returned?” (Quran 23:115).", arabic: "أَفَحَسِبۡتُمۡ أَنَّمَا خَلَقۡنَٰكُمۡ عَبَثٗا وَأَنَّكُمۡ إِلَيۡنَا لَا تُرۡجَعُونَ")

                    Text("**Deism**: belief in a Creator who made the world and then left it to run by itself, sending no revelation and hearing no prayer. The Quran describes a Lord who is never absent from His creation:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever is within the heavens and earth asks Him; every day He is bringing about a matter” (Quran 55:29).", arabic: "يَسۡـَٔلُهُۥ مَن فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۚ كُلَّ يَوۡمٍ هُوَ فِي شَأۡنٖ")
                    ScriptureQuote(text: "“Indeed, Allah holds the heavens and the earth, lest they cease. And if they should cease, no one could hold them [in place] after Him” (Quran 35:41).", arabic: "إِنَّ ٱللَّهَ يُمۡسِكُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ أَن تَزُولَاۚ وَلَئِن زَالَتَآ إِنۡ أَمۡسَكَهُمَا مِنۡ أَحَدٖ مِّنۢ بَعۡدِهِۦٓۚ")

                    Text("**The fitrah (الفِطْرَة)**: the innate disposition on which every human is born, which knows its Maker before any teaching (Quran 30:30; Sahih al-Bukhari 1385, both quoted below). Ibn Taymiyyah (may Allah have mercy on him) held that the affirmation of the Creator is settled in the fitrah of every person whose nature is sound, and that proofs are needed only to remove what has been laid over it (Dar’ Ta‘arud al-‘Aql wan-Naql).")
                        .font(.body)

                    Text("**The argument from creation**: whatever begins to exist has a cause other than itself; the universe began; therefore it has a Cause that did not begin. This is the argument of Surat at-Tur (Quran 52:35-36, quoted below), and Ibn Kathir (may Allah have mercy on him) notes in his tafsir that the verse is a step-by-step proof: they were not brought into being without a maker, and they did not bring themselves into being, so it is Allah who created them.")
                        .font(.body)

                    Text("**The argument from design**: order, fine-tuning, and law point to a Designer; a text points to an author, and the universe is a text without a misprint (Quran 67:3-4 and 88:17-20, both quoted below). Ibn al-Qayyim (may Allah have mercy on him) filled much of Miftah Dar as-Sa‘adah with the signs of wisdom in the creatures, from the human body to the birds and the bees, as proofs of their Maker.")
                        .font(.body)

                    Text("**The argument from the fitrah**: belief in a Creator is universal, spontaneous, and returns under pressure (Quran 29:65, quoted below); it is the atheism that must be learned and maintained.")
                        .font(.body)

                    Text("**Contingency**: everything we observe depends on something else for its existence and could have been otherwise; a chain of dependent things cannot hold itself up, and must rest on One who is independent, necessary, and self-sufficient. That is the meaning of as-Samad in Surat al-Ikhlas, which Ibn Abbas (may Allah be pleased with him) explained as the Master to whom all creation turns in its needs (Tafsir Ibn Kathir):")
                        .font(.body)
                    ScriptureQuote(text: "“Allah, the Eternal Refuge” (Quran 112:2).", arabic: "ٱللَّهُ ٱلصَّمَدُ")

                    Text("**The Quranic challenge (التَّحَدِّي)**: the Quran’s standing proof of its origin, an open challenge to produce anything like it, never met in fourteen centuries:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you are in doubt about what We have sent down upon Our Servant [Muhammad], then produce a surah the like thereof and call upon your witnesses other than Allah, if you should be truthful” (Quran 2:23).", arabic: "وَإِن كُنتُمۡ فِي رَيۡبٖ مِّمَّا نَزَّلۡنَا عَلَىٰ عَبۡدِنَا فَأۡتُواْ بِسُورَةٖ مِّن مِّثۡلِهِۦ وَٱدۡعُواْ شُهَدَآءَكُم مِّن دُونِ ٱللَّهِ إِن كُنتُمۡ صَٰدِقِينَ")
                    ScriptureQuote(text: "“Say, ‘If mankind and the jinn gathered in order to produce the like of this Qur'an, they could not produce the like of it, even if they were to each other assistants’” (Quran 17:88).", arabic: "قُل لَّئِنِ ٱجۡتَمَعَتِ ٱلۡإِنسُ وَٱلۡجِنُّ عَلَىٰٓ أَن يَأۡتُواْ بِمِثۡلِ هَٰذَا ٱلۡقُرۡءَانِ لَا يَأۡتُونَ بِمِثۡلِهِۦ وَلَوۡ كَانَ بَعۡضُهُمۡ لِبَعۡضٖ ظَهِيرٗا")
                }

                Section(header: Text("1. THE ARGUMENT THAT SHOOK A HEART")) {
                    Text("Jubayr ibn Mut‘im, still a pagan, came to Madinah and heard the Prophet (peace be upon him) recite Surat at-Tur in the Maghrib prayer. He said that when the Prophet reached these verses, his heart nearly flew (Sahih al-Bukhari 4854):")
                        .font(.body)
                    ScriptureQuote(text: "“Or were they created by nothing, or were they the creators [of themselves]? Or did they create the heavens and the earth? Rather, they are not certain” (Quran 52:35-36).", arabic: "أَمۡ خُلِقُواْ مِنۡ غَيۡرِ شَيۡءٍ أَمۡ هُمُ ٱلۡخَٰلِقُونَ ۝ أَمۡ خَلَقُواْ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۚ بَل لَّا يُوقِنُونَ")

                    Text("There are only three possibilities for anything that begins to exist: it came from nothing, it made itself, or something else made it. Nothing produces nothing. A thing cannot make itself before it exists. So the universe, which began, was made by something outside it, uncreated, without beginning, and powerful enough to bring everything into being. That is what Muslims call Allah:")
                        .font(.body)
                    ScriptureQuote(text: "“He is the First and the Last, the Ascendant and the Intimate, and He is, of all things, Knowing” (Quran 57:3).", arabic: "هُوَ ٱلۡأَوَّلُ وَٱلۡأٓخِرُ وَٱلظَّٰهِرُ وَٱلۡبَاطِنُۖ وَهُوَ بِكُلِّ شَيۡءٍ عَلِيمٌ")

                    Text("The question “then who created God?“ does not apply: the argument is that whatever begins needs a maker, and Allah did not begin. The Prophet (peace be upon him) taught that this question comes from Shaytan and is to be cut off:")
                        .font(.body)
                    ScriptureQuote(text: "“Shaytan comes to one of you and says: Who created such and such? Who created such and such? Until he says: Who created your Lord? When he reaches that, let him seek refuge in Allah and stop” (Sahih al-Bukhari 3276, Sahih Muslim 134).", arabic: "يَأْتِي الشَّيْطَانُ أَحَدَكُمْ فَيَقُولُ مَنْ خَلَقَ كَذَا مَنْ خَلَقَ كَذَا حَتَّى يَقُولَ مَنْ خَلَقَ رَبَّكَ فَإِذَا بَلَغَهُ فَلْيَسْتَعِذْ بِاللَّهِ، وَلْيَنْتَهِ", dimmed: true)
                }

                Section(header: Text("2. ORDER POINTS TO A DESIGNER")) {
                    ScriptureQuote(text: "“[And] who created seven heavens in layers. You do not see in the creation of the Most Merciful any inconsistency. So return [your] vision [to the sky]; do you see any breaks? Then return [your] vision twice again. [Your] vision will return to you humbled while it is fatigued” (Quran 67:3-4).", arabic: "ٱلَّذِي خَلَقَ سَبۡعَ سَمَٰوَٰتٖ طِبَاقٗاۖ مَّا تَرَىٰ فِي خَلۡقِ ٱلرَّحۡمَٰنِ مِن تَفَٰوُتٖۖ فَٱرۡجِعِ ٱلۡبَصَرَ هَلۡ تَرَىٰ مِن فُطُورٖ ۝ ثُمَّ ٱرۡجِعِ ٱلۡبَصَرَ كَرَّتَيۡنِ يَنقَلِبۡ إِلَيۡكَ ٱلۡبَصَرُ خَاسِئٗا وَهُوَ حَسِيرٞ")

                    ScriptureQuote(text: "“Then do they not look at the camels - how they are created? And at the sky - how it is raised? And at the mountains - how they are erected? And at the earth - how it is spread out?” (Quran 88:17-20).", arabic: "أَفَلَا يَنظُرُونَ إِلَى ٱلۡإِبِلِ كَيۡفَ خُلِقَتۡ ۝ وَإِلَى ٱلسَّمَآءِ كَيۡفَ رُفِعَتۡ ۝ وَإِلَى ٱلۡجِبَالِ كَيۡفَ نُصِبَتۡ ۝ وَإِلَى ٱلۡأَرۡضِ كَيۡفَ سُطِحَتۡ")

                    ScriptureQuote(text: "“Indeed, in the creation of the heavens and the earth and the alternation of the night and the day are signs for those of understanding. Who remember Allah while standing or sitting or [lying] on their sides and give thought to the creation of the heavens and the earth, [saying], ‘Our Lord, You did not create this aimlessly’” (Quran 3:190-191).", arabic: "إِنَّ فِي خَلۡقِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ وَٱخۡتِلَٰفِ ٱلَّيۡلِ وَٱلنَّهَارِ لَأٓيَٰتٖ لِّأُوْلِي ٱلۡأَلۡبَٰبِ ۝ ٱلَّذِينَ يَذۡكُرُونَ ٱللَّهَ قِيَٰمٗا وَقُعُودٗا وَعَلَىٰ جُنُوبِهِمۡ وَيَتَفَكَّرُونَ فِي خَلۡقِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ رَبَّنَا مَا خَلَقۡتَ هَٰذَا بَٰطِلٗا سُبۡحَٰنَكَ فَقِنَا عَذَابَ ٱلنَّارِ")

                    Text("The constants of physics are balanced so finely that a small change would leave no stars, no chemistry, and no life; a single cell carries a coded library that no chance process writes; and the human eye that reads these words is the product of the very order the atheist says has no author. Ibrahim’s argument, that what sets and vanishes cannot be the lord, is the same argument: the dependent points to the Independent.")
                        .font(.body)

                    ScriptureQuote(text: "“We will show them Our signs in the horizons and within themselves until it becomes clear to them that it is the truth. But is it not sufficient concerning your Lord that He is, over all things, a Witness?” (Quran 41:53).", arabic: "سَنُرِيهِمۡ ءَايَٰتِنَا فِي ٱلۡأٓفَاقِ وَفِيٓ أَنفُسِهِمۡ حَتَّىٰ يَتَبَيَّنَ لَهُمۡ أَنَّهُ ٱلۡحَقُّۗ أَوَلَمۡ يَكۡفِ بِرَبِّكَ أَنَّهُۥ عَلَىٰ كُلِّ شَيۡءٖ شَهِيدٌ")
                }

                Section(header: Text("3. THE FITRAH")) {
                    Text("Belief in a Creator is not taught; it is born in every human being, and atheism is what has to be taught over it:")
                        .font(.body)
                    ScriptureQuote(text: "“So direct your face toward the religion, inclining to truth. [Adhere to] the fitrah of Allah upon which He has created [all] people. No change should there be in the creation of Allah. That is the correct religion, but most of the people do not know” (Quran 30:30).", arabic: "فَأَقِمۡ وَجۡهَكَ لِلدِّينِ حَنِيفٗاۚ فِطۡرَتَ ٱللَّهِ ٱلَّتِي فَطَرَ ٱلنَّاسَ عَلَيۡهَاۚ لَا تَبۡدِيلَ لِخَلۡقِ ٱللَّهِۚ ذَٰلِكَ ٱلدِّينُ ٱلۡقَيِّمُ وَلَٰكِنَّ أَكۡثَرَ ٱلنَّاسِ لَا يَعۡلَمُونَ")

                    ScriptureQuote(text: "“Every child is born upon the fitrah, and then his parents make him a Jew, a Christian, or a Magian” (Sahih al-Bukhari 1385).", arabic: "كُلُّ مَوْلُودٍ يُولَدُ عَلَى الْفِطْرَةِ، فَأَبَوَاهُ يُهَوِّدَانِهِ أَوْ يُنَصِّرَانِهِ أَوْ يُمَجِّسَانِهِ", dimmed: true)

                    ScriptureQuote(text: "“And [mention] when your Lord took from the children of Adam - from their loins - their descendants and made them testify of themselves, [saying to them], ‘Am I not your Lord?’ They said, ‘Yes, we have testified’” (Quran 7:172).", arabic: "وَإِذۡ أَخَذَ رَبُّكَ مِنۢ بَنِيٓ ءَادَمَ مِن ظُهُورِهِمۡ ذُرِّيَّتَهُمۡ وَأَشۡهَدَهُمۡ عَلَىٰٓ أَنفُسِهِمۡ أَلَسۡتُ بِرَبِّكُمۡۖ قَالُواْ بَلَىٰ شَهِدۡنَآۚ")

                    Text("This is why the atheist in the crashing aircraft prays, and why every people in every age has worshipped something. The Quran describes it in the pagans:")
                        .font(.body)
                    ScriptureQuote(text: "“And when they board a ship, they supplicate Allah, sincere to Him in religion. But when He delivers them to the land, at once they associate others with Him” (Quran 29:65).", arabic: "فَإِذَا رَكِبُواْ فِي ٱلۡفُلۡكِ دَعَوُاْ ٱللَّهَ مُخۡلِصِينَ لَهُ ٱلدِّينَ فَلَمَّا نَجَّىٰهُمۡ إِلَى ٱلۡبَرِّ إِذَا هُمۡ يُشۡرِكُونَ")
                }

                Section(header: Text("4. THE RESURRECTION IS NOT HARDER THAN THE FIRST CREATION")) {
                    Text("The atheist says a dead body cannot live again. The Quran answers with the man’s own origin:")
                        .font(.body)
                    ScriptureQuote(text: "“And he presents for Us an example and forgets his [own] creation. He says, ‘Who will give life to bones while they are disintegrated?’ Say, ‘He will give them life who produced them the first time; and He is, of all creation, Knowing’” (Quran 36:78-79).", arabic: "وَضَرَبَ لَنَا مَثَلٗا وَنَسِيَ خَلۡقَهُۥۖ قَالَ مَن يُحۡيِ ٱلۡعِظَٰمَ وَهِيَ رَمِيمٞ ۝ قُلۡ يُحۡيِيهَا ٱلَّذِيٓ أَنشَأَهَآ أَوَّلَ مَرَّةٖۖ وَهُوَ بِكُلِّ خَلۡقٍ عَلِيمٌ")

                    ScriptureQuote(text: "“How can you disbelieve in Allah when you were lifeless and He brought you to life; then He will cause you to die, then He will bring you [back] to life, and then to Him you will be returned” (Quran 2:28).", arabic: "كَيۡفَ تَكۡفُرُونَ بِٱللَّهِ وَكُنتُمۡ أَمۡوَٰتٗا فَأَحۡيَٰكُمۡۖ ثُمَّ يُمِيتُكُمۡ ثُمَّ يُحۡيِيكُمۡ ثُمَّ إِلَيۡهِ تُرۡجَعُونَ")

                    ScriptureQuote(text: "“Does man think that he will be left neglected? Had he not been a sperm from semen emitted? Then he was a clinging clot, and [Allah] created [his form] and proportioned [him] and made of him two mates, the male and the female. Is not that [Creator] Able to give life to the dead?” (Quran 75:36-40).", arabic: "أَيَحۡسَبُ ٱلۡإِنسَٰنُ أَن يُتۡرَكَ سُدًى ۝ أَلَمۡ يَكُ نُطۡفَةٗ مِّن مَّنِيّٖ يُمۡنَىٰ ۝ ثُمَّ كَانَ عَلَقَةٗ فَخَلَقَ فَسَوَّىٰ ۝ فَجَعَلَ مِنۡهُ ٱلزَّوۡجَيۡنِ ٱلذَّكَرَ وَٱلۡأُنثَىٰٓ ۝ أَلَيۡسَ ذَٰلِكَ بِقَٰدِرٍ عَلَىٰٓ أَن يُحۡـِۧيَ ٱلۡمَوۡتَىٰ")

                    Text("And a world without resurrection is a world without justice, where the murderer and the murdered end the same. The moral sense every human has, that this cannot be right, is itself a witness that there is a Day of reckoning.")
                        .font(.body)
                }

                Section(header: Text("5. WHY THE QURAN?")) {
                    Text("To know that God exists is the first step; the second is to know what He wants. The Quran presents itself as His word and gives its proof: recited by an unlettered man fourteen centuries ago, preserved unchanged, without contradiction, describing the origin of the universe and the growth of the embryo in terms no one of that age knew:")
                        .font(.body)
                    ScriptureQuote(text: "“Have those who disbelieved not considered that the heavens and the earth were a joined entity, and We separated them and made from water every living thing? Then will they not believe?” (Quran 21:30).", arabic: "أَوَلَمۡ يَرَ ٱلَّذِينَ كَفَرُوٓاْ أَنَّ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ كَانَتَا رَتۡقٗا فَفَتَقۡنَٰهُمَاۖ وَجَعَلۡنَا مِنَ ٱلۡمَآءِ كُلَّ شَيۡءٍ حَيٍّۚ أَفَلَا يُؤۡمِنُونَ")

                    ScriptureQuote(text: "“Then We made the sperm-drop into a clinging clot, and We made the clot into a lump [of flesh], and We made [from] the lump, bones, and We covered the bones with flesh; then We developed him into another creation. So blessed is Allah, the best of creators” (Quran 23:14).", arabic: "ثُمَّ خَلَقۡنَا ٱلنُّطۡفَةَ عَلَقَةٗ فَخَلَقۡنَا ٱلۡعَلَقَةَ مُضۡغَةٗ فَخَلَقۡنَا ٱلۡمُضۡغَةَ عِظَٰمٗا فَكَسَوۡنَا ٱلۡعِظَٰمَ لَحۡمٗا ثُمَّ أَنشَأۡنَٰهُ خَلۡقًا ءَاخَرَۚ فَتَبَارَكَ ٱللَّهُ أَحۡسَنُ ٱلۡخَٰلِقِينَ")

                    ScriptureQuote(text: "“Then do they not reflect upon the Qur'an? If it had been from [any] other than Allah, they would have found within it much contradiction” (Quran 4:82).", arabic: "أَفَلَا يَتَدَبَّرُونَ ٱلۡقُرۡءَانَۚ وَلَوۡ كَانَ مِنۡ عِندِ غَيۡرِ ٱللَّهِ لَوَجَدُواْ فِيهِ ٱخۡتِلَٰفٗا كَثِيرٗا")
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Who created God?**")
                        .font(.body)
                    Text("No one, and the question misunderstands the argument. The claim is not that everything has a cause but that everything that begins has a cause. The universe began; Allah did not. He is the First, with nothing before Him (Quran 57:3, quoted above), and the Eternal Refuge on whom all depend while He depends on nothing (Quran 112:2). The Prophet (peace be upon him) taught his Companions to say before sleeping:")
                        .font(.body)
                    ScriptureQuote(text: "“O Allah, You are the First, there is nothing before You, and You are the Last, there is nothing after You, and You are the Evident, there is nothing above You, and You are the Innermost, there is nothing beyond You” (Sahih Muslim 2713).", arabic: "اللَّهُمَّ أَنْتَ الأَوَّلُ فَلَيْسَ قَبْلَكَ شَىْءٌ وَأَنْتَ الآخِرُ فَلَيْسَ بَعْدَكَ شَىْءٌ وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَىْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَىْءٌ", dimmed: true)
                    Text("A chain of caused causes must end in an uncaused Cause, or nothing would ever have started; if every cause needed a prior cause the series would never reach the present. The Prophet (peace be upon him) told us that this question is Shaytan’s last move and is to be cut off with refuge in Allah (Sahih al-Bukhari 3276, Sahih Muslim 134, quoted above).")
                        .font(.body)

                    Text("**Why is there evil and suffering?**")
                        .font(.body)
                    Text("Because this life is a test, not the reward:")
                        .font(.body)
                    ScriptureQuote(text: "“[He] who created death and life to test you [as to] which of you is best in deed - and He is the Exalted in Might, the Forgiving” (Quran 67:2).", arabic: "ٱلَّذِي خَلَقَ ٱلۡمَوۡتَ وَٱلۡحَيَوٰةَ لِيَبۡلُوَكُمۡ أَيُّكُمۡ أَحۡسَنُ عَمَلٗاۚ وَهُوَ ٱلۡعَزِيزُ ٱلۡغَفُورُ")
                    ScriptureQuote(text: "“Every soul will taste death. And We test you with evil and with good as trial; and to Us you will be returned” (Quran 21:35).", arabic: "كُلُّ نَفۡسٖ ذَآئِقَةُ ٱلۡمَوۡتِۗ وَنَبۡلُوكُم بِٱلشَّرِّ وَٱلۡخَيۡرِ فِتۡنَةٗۖ وَإِلَيۡنَا تُرۡجَعُونَ")
                    ScriptureQuote(text: "“And We will surely test you with something of fear and hunger and a loss of wealth and lives and fruits, but give good tidings to the patient” (Quran 2:155).", arabic: "وَلَنَبۡلُوَنَّكُم بِشَيۡءٖ مِّنَ ٱلۡخَوۡفِ وَٱلۡجُوعِ وَنَقۡصٖ مِّنَ ٱلۡأَمۡوَٰلِ وَٱلۡأَنفُسِ وَٱلثَّمَرَٰتِۗ وَبَشِّرِ ٱلصَّٰبِرِينَ")
                    ScriptureQuote(text: "“Do the people think that they will be left to say, ‘We believe’ and they will not be tried? But We have certainly tried those before them, and Allah will surely make evident those who are truthful, and He will surely make evident the liars” (Quran 29:2-3).", arabic: "أَحَسِبَ ٱلنَّاسُ أَن يُتۡرَكُوٓاْ أَن يَقُولُوٓاْ ءَامَنَّا وَهُمۡ لَا يُفۡتَنُونَ ۝ وَلَقَدۡ فَتَنَّا ٱلَّذِينَ مِن قَبۡلِهِمۡۖ فَلَيَعۡلَمَنَّ ٱللَّهُ ٱلَّذِينَ صَدَقُواْ وَلَيَعۡلَمَنَّ ٱلۡكَٰذِبِينَ")
                    ScriptureQuote(text: "“But perhaps you hate a thing and it is good for you; and perhaps you love a thing and it is bad for you. And Allah Knows, while you know not” (Quran 2:216).", arabic: "وَعَسَىٰٓ أَن تَكۡرَهُواْ شَيۡـٔٗا وَهُوَ خَيۡرٞ لَّكُمۡۖ وَعَسَىٰٓ أَن تُحِبُّواْ شَيۡـٔٗا وَهُوَ شَرّٞ لَّكُمۡۚ وَٱللَّهُ يَعۡلَمُ وَأَنتُمۡ لَا تَعۡلَمُونَ")
                    Text("Much of the suffering in the world is what human hands have earned (Quran 30:41), and for the believer no pain is wasted; the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“No fatigue, disease, sorrow, sadness, hurt, or distress befalls a Muslim, even the prick of a thorn, except that Allah expiates some of his sins by it” (Sahih al-Bukhari 5641).", arabic: "مَا يُصِيبُ الْمُسْلِمَ مِنْ نَصَبٍ وَلاَ وَصَبٍ وَلاَ هَمٍّ وَلاَ حُزْنٍ وَلاَ أَذًى وَلاَ غَمٍّ حَتَّى الشَّوْكَةِ يُشَاكُهَا، إِلاَّ كَفَّرَ اللَّهُ بِهَا مِنْ خَطَايَاهُ", dimmed: true)
                    ScriptureQuote(text: "“If Allah wants to do good to somebody, He afflicts him with trials” (Sahih al-Bukhari 5645).", arabic: "مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُصِبْ مِنْهُ", dimmed: true)
                    ScriptureQuote(text: "“How wonderful is the affair of the believer, for all of it is good, and that is for no one but the believer: if good comes to him he is thankful, and that is good for him, and if harm comes to him he is patient, and that is good for him” (Sahih Muslim 2999).", arabic: "عَجَبًا لأَمْرِ الْمُؤْمِنِ إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ وَلَيْسَ ذَاكَ لأَحَدٍ إِلاَّ لِلْمُؤْمِنِ إِنْ أَصَابَتْهُ سَرَّاءُ شَكَرَ فَكَانَ خَيْرًا لَهُ وَإِنْ أَصَابَتْهُ ضَرَّاءُ صَبَرَ فَكَانَ خَيْرًا لَهُ", dimmed: true)
                    Text("The Prophet (peace be upon him) himself was orphaned, buried six of his seven children, was driven from his city, and was wounded at Uhud. The atheist’s complaint proves the opposite of what he intends: if there is no God, “evil” is only what one animal dislikes, and there is nothing to complain to. The very sense that suffering ought not to be is a sense of a standard beyond the world, and of a Day when it is set right.")
                        .font(.body)

                    Text("**Why can’t we see God?**")
                        .font(.body)
                    Text("Because the creature cannot bear it in this life. When Musa (peace be upon him) asked to see Him, Allah revealed Himself to the mountain and it crumbled, and Musa fell unconscious (Quran 7:143):")
                        .font(.body)
                    ScriptureQuote(text: "“Vision perceives Him not, but He perceives [all] vision; and He is the Subtle, the Acquainted” (Quran 6:103).", arabic: "لَّا تُدۡرِكُهُ ٱلۡأَبۡصَٰرُ وَهُوَ يُدۡرِكُ ٱلۡأَبۡصَٰرَۖ وَهُوَ ٱللَّطِيفُ ٱلۡخَبِيرُ")
                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“His veil is the light. If He withdraws it, the splendour of His countenance would consume His creation so far as His sight reaches” (Sahih Muslim 179).", arabic: "حِجَابُهُ النُّورُ لَوْ كَشَفَهُ لأَحْرَقَتْ سُبُحَاتُ وَجْهِهِ مَا انْتَهَى إِلَيْهِ بَصَرُهُ مِنْ خَلْقِهِ", dimmed: true)
                    Text("Seeing is promised, in the Hereafter, to those who believed without it:")
                        .font(.body)
                    ScriptureQuote(text: "“[Some] faces, that Day, will be radiant, looking at their Lord” (Quran 75:22-23).", arabic: "وُجُوهٞ يَوۡمَئِذٖ نَّاضِرَةٌ ۝ إِلَىٰ رَبِّهَا نَاظِرَةٞ")
                    ScriptureQuote(text: "“You people will see your Lord as you see this full moon, and you will have no trouble in seeing Him” (Sahih al-Bukhari 7434).", arabic: "إِنَّكُمْ سَتَرَوْنَ رَبَّكُمْ كَمَا تَرَوْنَ هَذَا الْقَمَرَ لاَ تُضَامُّونَ فِي رُؤْيَتِهِ", dimmed: true)
                    Text("Meanwhile no one has seen his own mind, gravity, or the past, and no one doubts them; we know them by their effects. The effects of the Creator are everything that exists.")
                        .font(.body)

                    Text("**Doesn’t science explain everything?**")
                        .font(.body)
                    Text("Science describes how things happen; it cannot say why there is anything at all, why the laws are what they are, or what anything is for. To explain the workings of a machine is not to show that it had no maker. The Quran commands observation, and its first revealed word was “Recite” (Quran 96:1-5); it points to the origin of the cosmos and of life (Quran 21:30) and promises that the signs in the horizons and in ourselves will confirm it (Quran 41:53, both quoted above). Reflection on creation is the mark of “those of understanding” (Quran 3:190-191). Allah asks:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Are those who know equal to those who do not know?’” (Quran 39:9).", arabic: "قُلۡ هَلۡ يَسۡتَوِي ٱلَّذِينَ يَعۡلَمُونَ وَٱلَّذِينَ لَا يَعۡلَمُونَۗ")
                    ScriptureQuote(text: "“Only those fear Allah, from among His servants, who have knowledge” (Quran 35:28).", arabic: "إِنَّمَا يَخۡشَى ٱللَّهَ مِنۡ عِبَادِهِ ٱلۡعُلَمَٰٓؤُاْۗ")
                    Text("Al-Khwarizmi in algebra, Ibn al-Haytham in optics, and az-Zahrawi in surgery were believers who studied creation as a book with an Author. Science answers the “how”; revelation answers the “who” and the “why.” A man who knows only the first has read the footnotes and skipped the title page.")
                        .font(.body)

                    Text("**Isn’t religion the cause of wars?**")
                        .font(.body)
                    Text("Wars are caused by greed, pride, land, and power, in believers and unbelievers alike; men without any religion have fought as fiercely as men with one. Islam’s law of war forbids what the pagans permitted:")
                        .font(.body)
                    ScriptureQuote(text: "“Fight in the way of Allah those who fight you but do not transgress. Indeed. Allah does not like transgressors” (Quran 2:190).", arabic: "وَقَٰتِلُواْ فِي سَبِيلِ ٱللَّهِ ٱلَّذِينَ يُقَٰتِلُونَكُمۡ وَلَا تَعۡتَدُوٓاْۚ إِنَّ ٱللَّهَ لَا يُحِبُّ ٱلۡمُعۡتَدِينَ")
                    ScriptureQuote(text: "“Because of that, We decreed upon the Children of Israel that whoever kills a soul unless for a soul or for corruption [done] in the land - it is as if he had slain mankind entirely. And whoever saves one - it is as if he had saved mankind entirely” (Quran 5:32).", arabic: "مِنۡ أَجۡلِ ذَٰلِكَ كَتَبۡنَا عَلَىٰ بَنِيٓ إِسۡرَٰٓءِيلَ أَنَّهُۥ مَن قَتَلَ نَفۡسَۢا بِغَيۡرِ نَفۡسٍ أَوۡ فَسَادٖ فِي ٱلۡأَرۡضِ فَكَأَنَّمَا قَتَلَ ٱلنَّاسَ جَمِيعٗا وَمَنۡ أَحۡيَاهَا فَكَأَنَّمَآ أَحۡيَا ٱلنَّاسَ جَمِيعٗاۚ")
                    ScriptureQuote(text: "“There shall be no compulsion in [acceptance of] the religion. The right course has become clear from the wrong” (Quran 2:256).", arabic: "لَآ إِكۡرَاهَ فِي ٱلدِّينِۖ قَد تَّبَيَّنَ ٱلرُّشۡدُ مِنَ ٱلۡغَيِّۚ")
                    ScriptureQuote(text: "“Allah does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them. Indeed, Allah loves those who act justly” (Quran 60:8).", arabic: "لَّا يَنۡهَىٰكُمُ ٱللَّهُ عَنِ ٱلَّذِينَ لَمۡ يُقَٰتِلُوكُمۡ فِي ٱلدِّينِ وَلَمۡ يُخۡرِجُوكُم مِّن دِيَٰرِكُمۡ أَن تَبَرُّوهُمۡ وَتُقۡسِطُوٓاْ إِلَيۡهِمۡۚ إِنَّ ٱللَّهَ يُحِبُّ ٱلۡمُقۡسِطِينَ")
                    ScriptureQuote(text: "“O you who have believed, be persistently standing firm for Allah, witnesses in justice, and do not let the hatred of a people prevent you from being just. Be just; that is nearer to righteousness” (Quran 5:8).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ كُونُواْ قَوَّٰمِينَ لِلَّهِ شُهَدَآءَ بِٱلۡقِسۡطِۖ وَلَا يَجۡرِمَنَّكُمۡ شَنَـَٔانُ قَوۡمٍ عَلَىٰٓ أَلَّا تَعۡدِلُواْۚ ٱعۡدِلُواْ هُوَ أَقۡرَبُ لِلتَّقۡوَىٰۖ")
                    Text("The Prophet (peace be upon him) forbade the killing of women and children (Sahih al-Bukhari 3015), forbade treachery and mutilation (Sahih Muslim 1731), and said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever killed a person having a treaty with the Muslims shall not smell the smell of Paradise, though its smell is perceived from a distance of forty years” (Sahih al-Bukhari 3166).", arabic: "مَنْ قَتَلَ مُعَاهَدًا لَمْ يَرَحْ رَائِحَةَ الْجَنَّةِ، وَإِنَّ رِيحَهَا تُوجَدُ مِنْ مَسِيرَةِ أَرْبَعِينَ عَامًا", dimmed: true)
                    Text("Allah even names the protection of monasteries, churches, and synagogues among the reasons He permits the believers to fight (Quran 22:40). Men fight over everything; it was religion that first told them when they may not.")
                        .font(.body)

                    Text("**Can we be good without God?**")
                        .font(.body)
                    Text("A person can do good deeds without believing, because the knowledge of good and evil is planted in every soul by its Maker:")
                        .font(.body)
                    ScriptureQuote(text: "“And [by] the soul and He who proportioned it and inspired it [with discernment of] its wickedness and its righteousness” (Quran 91:7-8).", arabic: "وَنَفۡسٖ وَمَا سَوَّىٰهَا ۝ فَأَلۡهَمَهَا فُجُورَهَا وَتَقۡوَىٰهَا")
                    ScriptureQuote(text: "“Virtue is a kind disposition and vice is what rankles in your heart and that you disapprove that people should come to know of it” (Sahih Muslim 2553).", arabic: "الْبِرُّ حُسْنُ الْخُلُقِ وَالإِثْمُ مَا حَاكَ فِي صَدْرِكَ وَكَرِهْتَ أَنْ يَطَّلِعَ عَلَيْهِ النَّاسُ", dimmed: true)
                    Text("But that is the point: the moral sense is itself evidence of the One who inspired it. Without a Lawgiver, “good” is a preference, binding on no one; without a Judge, no wrong is ever set right, and the tyrant who dies in his bed has won. Islam says neither:")
                        .font(.body)
                    ScriptureQuote(text: "“Is not Allah the most just of judges?” (Quran 95:8).", arabic: "أَلَيۡسَ ٱللَّهُ بِأَحۡكَمِ ٱلۡحَٰكِمِينَ")
                    ScriptureQuote(text: "“And We place the scales of justice for the Day of Resurrection, so no soul will be treated unjustly at all. And if there is [even] the weight of a mustard seed, We will bring it forth. And sufficient are We as accountant” (Quran 21:47).", arabic: "وَنَضَعُ ٱلۡمَوَٰزِينَ ٱلۡقِسۡطَ لِيَوۡمِ ٱلۡقِيَٰمَةِ فَلَا تُظۡلَمُ نَفۡسٞ شَيۡـٔٗاۖ وَإِن كَانَ مِثۡقَالَ حَبَّةٖ مِّنۡ خَرۡدَلٍ أَتَيۡنَا بِهَاۗ وَكَفَىٰ بِنَا حَٰسِبِينَ")
                    Text("And no good deed is lost with Him, even the smallest (Quran 4:40). The atheist who is kind is living on borrowed capital; he acts on a law he says has no Lawgiver.")
                        .font(.body)

                    Text("**Aren’t all religions equally man-made?**")
                        .font(.body)
                    Text("Islam does not say all religions are equal; it says one was sent by Allah to every prophet, and men altered it:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, the religion in the sight of Allah is Islam. And those who were given the Scripture did not differ except after knowledge had come to them - out of jealous animosity between themselves” (Quran 3:19).", arabic: "إِنَّ ٱلدِّينَ عِندَ ٱللَّهِ ٱلۡإِسۡلَٰمُۗ وَمَا ٱخۡتَلَفَ ٱلَّذِينَ أُوتُواْ ٱلۡكِتَٰبَ إِلَّا مِنۢ بَعۡدِ مَا جَآءَهُمُ ٱلۡعِلۡمُ بَغۡيَۢا بَيۡنَهُمۡۗ")
                    ScriptureQuote(text: "“And whoever desires other than Islam as religion - never will it be accepted from him, and he, in the Hereafter, will be among the losers” (Quran 3:85).", arabic: "وَمَن يَبۡتَغِ غَيۡرَ ٱلۡإِسۡلَٰمِ دِينٗا فَلَن يُقۡبَلَ مِنۡهُ وَهُوَ فِي ٱلۡأٓخِرَةِ مِنَ ٱلۡخَٰسِرِينَ")
                    Text("The Quran is the criterion over what came before (Quran 5:48), and it stands apart from every other scripture in two ways that can be tested: it was preserved word for word, as Allah promised, and it has never been matched, as Allah challenged (Quran 2:23; 17:88, quoted above):")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian” (Quran 15:9).", arabic: "إِنَّا نَحۡنُ نَزَّلۡنَا ٱلذِّكۡرَ وَإِنَّا لَهُۥ لَحَٰفِظُونَ")
                    Text("The man-made is many and contradictory; the revealed is one, and the differences between religions are the measure of how far men have drifted from it.")
                        .font(.body)

                    Text("**What about evolution?**")
                        .font(.body)
                    Text("Muslims believe what Allah told us about our origin: Adam (peace be upon him) was created by Allah directly, from clay, shaped by His hands, and given the soul by His breath:")
                        .font(.body)
                    ScriptureQuote(text: "“[So mention] when your Lord said to the angels, ‘Indeed, I am going to create a human being from clay. So when I have proportioned him and breathed into him of My [created] soul, then fall down to him in prostration’” (Quran 38:71-72).", arabic: "إِذۡ قَالَ رَبُّكَ لِلۡمَلَٰٓئِكَةِ إِنِّي خَٰلِقُۢ بَشَرٗا مِّن طِينٖ ۝ فَإِذَا سَوَّيۡتُهُۥ وَنَفَخۡتُ فِيهِ مِن رُّوحِي فَقَعُواْ لَهُۥ سَٰجِدِينَ")
                    ScriptureQuote(text: "“Indeed, the example of Jesus to Allah is like that of Adam. He created Him from dust; then He said to him, ‘Be,’ and he was” (Quran 3:59).", arabic: "إِنَّ مَثَلَ عِيسَىٰ عِندَ ٱللَّهِ كَمَثَلِ ءَادَمَۖ خَلَقَهُۥ مِن تُرَابٖ ثُمَّ قَالَ لَهُۥ كُن فَيَكُونُ")
                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah created Adam, making him sixty cubits tall” (Sahih al-Bukhari 3326).", arabic: "خَلَقَ اللَّهُ آدَمَ وَطُولُهُ سِتُّونَ ذِرَاعًا", dimmed: true)
                    ScriptureQuote(text: "“Indeed Allah Most High created Adam from a handful that He took from all of the earth. So the children of Adam come in accordance with the earth, some of them come red, and white and black, and between that” (Sunan al-Tirmidhi 2955; graded sahih by al-Albani).", arabic: "إِنَّ اللَّهَ تَعَالَى خَلَقَ آدَمَ مِنْ قَبْضَةٍ قَبَضَهَا مِنْ جَمِيعِ الأَرْضِ فَجَاءَ بَنُو آدَمَ عَلَى قَدْرِ الأَرْضِ فَجَاءَ مِنْهُمُ الأَحْمَرُ وَالأَبْيَضُ وَالأَسْوَدُ وَبَيْنَ ذَلِكَ", dimmed: true)
                    Text("That living things vary and adapt is observed, and Islam does not deny it; the colours and forms of the children of Adam are themselves an example, and the hadith just quoted says where they came from. What a Muslim cannot accept is that Adam (peace be upon him) had a human or an animal ancestor, or that man is here with no Creator, no purpose, and no soul. On the first, Allah has told us plainly how Adam was made, and revelation is knowledge; the descent of species is an inference about a past nobody witnessed, however carefully it is drawn from the evidence we do have, and inferences are revised while what Allah said is not. On the second, no fossil and no mechanism can show that nobody made it: to describe how a thing works has never answered who made it, or why. So the believer studies the workings of life closely, as Allah’s handiwork, and holds what Allah said about Adam as certain.")
                        .font(.body)

                    Text("**Isn’t the Quran a man’s book?**")
                        .font(.body)
                    Text("The man it came through could not read or write:")
                        .font(.body)
                    ScriptureQuote(text: "“And you did not recite before it any scripture, nor did you inscribe one with your right hand. Otherwise the falsifiers would have had [cause for] doubt” (Quran 29:48).", arabic: "وَمَا كُنتَ تَتۡلُواْ مِن قَبۡلِهِۦ مِن كِتَٰبٖ وَلَا تَخُطُّهُۥ بِيَمِينِكَۖ إِذٗا لَّٱرۡتَابَ ٱلۡمُبۡطِلُونَ")
                    Text("He had lived forty years among his people without a line of poetry or preaching:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘If Allah had willed, I would not have recited it to you, nor would He have made it known to you, for I had remained among you a lifetime before it. Then will you not reason?’” (Quran 10:16).", arabic: "قُل لَّوۡ شَآءَ ٱللَّهُ مَا تَلَوۡتُهُۥ عَلَيۡكُمۡ وَلَآ أَدۡرَىٰكُم بِهِۦۖ فَقَدۡ لَبِثۡتُ فِيكُمۡ عُمُرٗا مِّن قَبۡلِهِۦٓۚ أَفَلَا تَعۡقِلُونَ")
                    Text("The pagans said it was dictated by a foreigner, and the Quran answered that the man they meant did not even speak Arabic (Quran 16:103). The Book challenged them to produce one surah like it (Quran 2:23) and they never did, though they were the masters of the language and would have given anything to silence him. It contains no contradiction (Quran 4:82, quoted above), it corrects the Prophet himself in places, and it describes what no man of that age knew. No man writes a book that rebukes its author.")
                        .font(.body)

                    Text("**What if I have doubts?**")
                        .font(.body)
                    Text("A passing doubt is not disbelief, and hating it is faith. The Companions came to the Prophet (peace be upon him) troubled by thoughts they were ashamed to speak:")
                        .font(.body)
                    ScriptureQuote(text: "They said, “Verily we perceive in our minds that which every one of us considers too grave to express.” He said, “Do you really perceive it?” They said, “Yes.” He said, “That is the faith manifest” (Sahih Muslim 132).", arabic: "إِنَّا نَجِدُ فِي أَنْفُسِنَا مَا يَتَعَاظَمُ أَحَدُنَا أَنْ يَتَكَلَّمَ بِهِ. قَالَ وَقَدْ وَجَدْتُمُوهُ. قَالُوا نَعَمْ. قَالَ ذَاكَ صَرِيحُ الإِيمَانِ", dimmed: true)
                    Text("Ibrahim (peace be upon him) asked to be shown how the dead are raised, “only that my heart may be satisfied” (Quran 2:260), and the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“We are more liable to be in doubt than Abraham when he said, ‘My Lord! Show me how You give life to the dead.’ He said, ‘Don’t you believe then?’ He said, ‘Yes, but (I ask) in order to be stronger in Faith’” (Sahih al-Bukhari 3372).", arabic: "نَحْنُ أَحَقُّ مِنْ إِبْرَاهِيمَ إِذْ قَالَ رَبِّ أَرِنِي كَيْفَ تُحْيِي الْمَوْتَى قَالَ أَوَلَمْ تُؤْمِنْ قَالَ بَلَى وَلَكِنْ لِيَطْمَئِنَّ قَلْبِي", dimmed: true)
                    Text("Allah addressed His Prophet (peace be upon him) with a condition he never fell into, so that those after him would learn where to take a doubt:")
                        .font(.body)
                    ScriptureQuote(text: "“So if you are in doubt, [O Muhammad], about that which We have revealed to you, then ask those who have been reading the Scripture before you. The truth has certainly come to you from your Lord, so never be among the doubters” (Quran 10:94).", arabic: "فَإِن كُنتَ فِي شَكّٖ مِّمَّآ أَنزَلۡنَآ إِلَيۡكَ فَسۡـَٔلِ ٱلَّذِينَ يَقۡرَءُونَ ٱلۡكِتَٰبَ مِن قَبۡلِكَۚ لَقَدۡ جَآءَكَ ٱلۡحَقُّ مِن رَّبِّكَ فَلَا تَكُونَنَّ مِنَ ٱلۡمُمۡتَرِينَ")
                    Text("Doubts are cured by knowledge, by asking those who know, by looking at the signs (Quran 41:53), and by supplication; the Prophet (peace be upon him) taught that when the whisper reaches “who created your Lord?” one seeks refuge in Allah and stops (Sahih al-Bukhari 3276, above). A doubt examined honestly leads to certainty; a doubt fed in secret leads to the dark.")
                        .font(.body)

                    Text("**If God decreed everything, how am I responsible?**")
                        .font(.body)
                    Text("Because the decree includes your own will and your own choosing. Allah knows and has written what you will do, and nothing at all happens outside His will; but the choice is really yours, and He does not force it upon you:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, We guided him to the way, be he grateful or be he ungrateful” (Quran 76:3).", arabic: "إِنَّا هَدَيۡنَٰهُ ٱلسَّبِيلَ إِمَّا شَاكِرٗا وَإِمَّا كَفُورًا")
                    ScriptureQuote(text: "“For whoever wills among you to take a right course. And you do not will except that Allah wills - Lord of the worlds” (Quran 81:28-29).", arabic: "لِمَن شَآءَ مِنكُمۡ أَن يَسۡتَقِيمَ ۝ وَمَا تَشَآءُونَ إِلَّآ أَن يَشَآءَ ٱللَّهُ رَبُّ ٱلۡعَٰلَمِينَ")
                    ScriptureQuote(text: "“And say, ‘The truth is from your Lord, so whoever wills - let him believe; and whoever wills - let him disbelieve’” (Quran 18:29).", arabic: "وَقُلِ ٱلۡحَقُّ مِن رَّبِّكُمۡۖ فَمَن شَآءَ فَلۡيُؤۡمِن وَمَن شَآءَ فَلۡيَكۡفُرۡۚ")
                    Text("When the Companions asked whether they should stop working and rely on what was written, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Carry on doing deeds, for everybody will find easy to do such deeds as will lead him to his destined place for which he has been created” (Sahih al-Bukhari 4949).", arabic: "اعْمَلُوا فَكُلٌّ مُيَسَّرٌ لِمَا خُلِقَ لَهُ", dimmed: true)
                    Text("You experience your choices as your own, you are praised and blamed for them by everyone including the atheist, and Allah’s foreknowledge no more forces them than a historian’s knowledge forces the past. He inspired the soul with its wickedness and its righteousness and made the purifying or the corrupting of it a man’s own deed, for which he answers (Quran 91:7-10), and He does not burden a soul beyond its capacity (Quran 2:286).")
                        .font(.body)

                    Text("**Does God need our worship?**")
                        .font(.body)
                    Text("No. Worship is for our benefit, not His:")
                        .font(.body)
                    ScriptureQuote(text: "“And I did not create the jinn and mankind except to worship Me. I do not want from them any provision, nor do I want them to feed Me” (Quran 51:56-57).", arabic: "وَمَا خَلَقۡتُ ٱلۡجِنَّ وَٱلۡإِنسَ إِلَّا لِيَعۡبُدُونِ ۝ مَآ أُرِيدُ مِنۡهُم مِّن رِّزۡقٖ وَمَآ أُرِيدُ أَن يُطۡعِمُونِ")
                    ScriptureQuote(text: "“And Moses said, ‘If you should disbelieve, you and whoever is on the earth entirely - indeed, Allah is Free of need and Praiseworthy’” (Quran 14:8).", arabic: "وَقَالَ مُوسَىٰٓ إِن تَكۡفُرُوٓاْ أَنتُمۡ وَمَن فِي ٱلۡأَرۡضِ جَمِيعٗا فَإِنَّ ٱللَّهَ لَغَنِيٌّ حَمِيدٌ")
                    ScriptureQuote(text: "“If you disbelieve - indeed, Allah is Free from need of you. And He does not approve for His servants disbelief. And if you are grateful, He approves it for you” (Quran 39:7).", arabic: "إِن تَكۡفُرُواْ فَإِنَّ ٱللَّهَ غَنِيٌّ عَنكُمۡۖ وَلَا يَرۡضَىٰ لِعِبَادِهِ ٱلۡكُفۡرَۖ وَإِن تَشۡكُرُواْ يَرۡضَهُ لَكُمۡۗ")
                    Text("In a hadith qudsi He says:")
                        .font(.body)
                    ScriptureQuote(text: "“O My servants, you will not attain harming Me so as to harm Me, and will not attain benefitting Me so as to benefit Me. O My servants, were the first of you and the last of you, the human of you and the jinn of you to be as pious as the most pious heart of any one man of you, that would not increase My dominion in anything” (Sahih Muslim 2577).", arabic: "يَا عِبَادِي إِنَّكُمْ لَنْ تَبْلُغُوا ضَرِّي فَتَضُرُّونِي وَلَنْ تَبْلُغُوا نَفْعِي فَتَنْفَعُونِي يَا عِبَادِي لَوْ أَنَّ أَوَّلَكُمْ وَآخِرَكُمْ وَإِنْسَكُمْ وَجِنَّكُمْ كَانُوا عَلَى أَتْقَى قَلْبِ رَجُلٍ وَاحِدٍ مِنْكُمْ مَا زَادَ ذَلِكَ فِي مُلْكِي شَيْئًا", dimmed: true)
                    Text("We are the ones in need (Quran 35:15, above). Worship is the soul finding what it was made for, as the eye was made for light.")
                        .font(.body)

                    Text("**Why would a loving God punish forever?**")
                        .font(.body)
                    Text("Allah’s mercy comes first and reaches everything:")
                        .font(.body)
                    ScriptureQuote(text: "“He has decreed upon Himself mercy” (Quran 6:12).", arabic: "كَتَبَ عَلَىٰ نَفۡسِهِ ٱلرَّحۡمَةَۚ")
                    ScriptureQuote(text: "“My punishment - I afflict with it whom I will, but My mercy encompasses all things” (Quran 7:156).", arabic: "قَالَ عَذَابِيٓ أُصِيبُ بِهِۦ مَنۡ أَشَآءُۖ وَرَحۡمَتِي وَسِعَتۡ كُلَّ شَيۡءٖۚ")
                    ScriptureQuote(text: "“When Allah completed the creation, He wrote in His Book which is with Him on His Throne: My Mercy overpowers My Anger” (Sahih al-Bukhari 3194, Sahih Muslim 2751).", arabic: "لَمَّا قَضَى اللَّهُ الْخَلْقَ كَتَبَ فِي كِتَابِهِ، فَهْوَ عِنْدَهُ فَوْقَ الْعَرْشِ إِنَّ رَحْمَتِي غَلَبَتْ غَضَبِي", dimmed: true)
                    Text("He forgives all sins for whoever turns to Him (Quran 39:53), and He is more merciful to His servants than a mother to her child (Sahih al-Bukhari 5999, Sahih Muslim 2754). No one is punished who was not reached by the truth:")
                        .font(.body)
                    ScriptureQuote(text: "“[We sent] messengers as bringers of good tidings and warners so that mankind will have no argument against Allah after the messengers” (Quran 4:165).", arabic: "رُّسُلٗا مُّبَشِّرِينَ وَمُنذِرِينَ لِئَلَّا يَكُونَ لِلنَّاسِ عَلَى ٱللَّهِ حُجَّةُۢ بَعۡدَ ٱلرُّسُلِۚ")
                    ScriptureQuote(text: "“And never would We punish until We sent a messenger” (Quran 17:15).", arabic: "وَمَا كُنَّا مُعَذِّبِينَ حَتَّىٰ نَبۡعَثَ رَسُولٗا")
                    Text("The Fire is for the one who knew and refused, who was called for a lifetime and turned his back until death closed the door; and its people will themselves confess that a warner came to them and that they denied him (Quran 67:8-11). Rejecting the Creator knowingly is not a small sin against a small being; it is the rejection of the Infinite, and its refusal does not expire because the one who made it dies. Even so, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If a believer were to know the punishment (in Hell) none would have the audacity to aspire for Paradise, and if a non-believer were to know what is there with Allah as a mercy, none would have been disappointed in regard to Paradise” (Sahih Muslim 2755).", arabic: "لَوْ يَعْلَمُ الْمُؤْمِنُ مَا عِنْدَ اللَّهِ مِنَ الْعُقُوبَةِ مَا طَمِعَ بِجَنَّتِهِ أَحَدٌ وَلَوْ يَعْلَمُ الْكَافِرُ مَا عِنْدَ اللَّهِ مِنَ الرَّحْمَةِ مَا قَنِطَ مِنْ جَنَّتِهِ أَحَدٌ", dimmed: true)
                    Text("The door is open until the last breath. Love that never judged would leave every oppressor unpunished and every victim unavenged; that is not love but indifference.")
                        .font(.body)

                    Text("**Is agnosticism (“we cannot know”) reasonable?**")
                        .font(.body)
                    Text("It is not the neutral ground it looks like, because it claims to have no knowledge while setting aside the knowledge every soul was given. Allah created mankind on the fitrah (Quran 30:30) and took their testimony “Am I not your Lord?” (Quran 7:172), and the signs are in the horizons and in ourselves (Quran 41:53), all quoted above. Denial that outruns the heart is described in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And they rejected them, while their [inner] selves were convinced thereof, out of injustice and haughtiness” (Quran 27:14).", arabic: "وَجَحَدُواْ بِهَا وَٱسۡتَيۡقَنَتۡهَآ أَنفُسُهُمۡ ظُلۡمٗا وَعُلُوّٗاۚ")
                    Text("And the messengers’ own question stands:")
                        .font(.body)
                    ScriptureQuote(text: "“Can there be doubt about Allah, Creator of the heavens and earth?” (Quran 14:10).", arabic: "أَفِي ٱللَّهِ شَكّٞ فَاطِرِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ")
                    Text("Not knowing which religion is true is a reason to search, not to stop; not knowing whether there is a Maker, while standing in His creation, is not humility but refusal. The agnostic who prays in the crashing plane knows more than he admits.")
                        .font(.body)
                }

                Section(header: Text("THE INVITATION")) {
                    ScriptureQuote(text: "“And on the earth are signs for the certain [in faith] and in yourselves. Then will you not see?” (Quran 51:20-21).", arabic: "وَفِي ٱلۡأَرۡضِ ءَايَٰتٞ لِّلۡمُوقِنِينَ ۝ وَفِيٓ أَنفُسِكُمۡۚ أَفَلَا تُبۡصِرُونَ")

                    Text("The atheist is asked only to be consistent: to follow the evidence for a cause to its Cause, and to listen to the voice in himself that already knows. Allah does not compel belief (Quran 10:99); He invites to it with reason, and He forgives whoever turns to Him.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Nothing comes from nothing, order does not write itself, and the fitrah knows its Maker. The universe that began was begun by the One who did not, and He sent a Book to say who He is and what He asks.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Atheism")
        .selectableArticleList()
    }
}
