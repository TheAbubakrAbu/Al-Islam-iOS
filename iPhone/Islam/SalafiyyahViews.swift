import SwiftUI

/// The two list sections at the bottom of Pillars & Beliefs: Salafiyyah (the way of the Salaf, the two
/// sources, shirk, kufr, bid'ah, the mawlid) and the "Answering" articles that reply to other paths.
struct SalafiyyahSectionView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Group {
            Section(header: Text("SALAFIYYAH: THE WAY OF THE SALAF")) {
                row("What is Salafiyyah?", destination: SalafiyyahView())
                row("The Quran and the Sunnah", destination: QuranSunnahView())
                row("Shirk: The Unforgivable Sin", destination: ShirkView())
                row("Kufr and What Breaks Islam", destination: KufrView())
                row("Bid'ah (Innovation)", destination: BidahView())
                row("The Mawlid", destination: MawlidView())
            }

            Section(header: Text("ANSWERING OTHER PATHS")) {
                row("Answering Sufism", destination: SufismAnswerView())
                row("Answering the Shia", destination: ShiaAnswerView())
                row("Answering Christianity", destination: ChristianityAnswerView())
                row("Answering Judaism", destination: JudaismAnswerView())
                row("Answering Hinduism", destination: HinduismAnswerView())
                row("Answering Paganism", destination: PaganismAnswerView())
                row("Answering Buddhism", destination: BuddhismAnswerView())
                row("Answering Atheism", destination: AtheismAnswerView())
            }
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

struct SalafiyyahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Salafiyyah is following the Quran and the Sunnah upon the understanding of the Salaf, the first three generations. It is not a new sect or a party; it is the name for the original Islam, and its creed is the Athari creed.")
                        .font(.body)
                }

                Section(header: Text("WHO ARE THE SALAF?")) {
                    Text("**Salaf (سَلَف)** means “those who came before.“ In the religion it means **as-Salaf as-Salih (السَّلَف الصَّالِح)**, the Righteous Predecessors: the Companions (**Sahabah**), their students (**Tabi‘un**), and the students of those (**Atba‘ at-Tabi‘in**), the three generations the Prophet (peace be upon him) praised:")
                        .font(.body)
                    ScriptureQuote(text: "“The best of people are my generation, then those who follow them, then those who follow them” (Sahih al-Bukhari 2652).", arabic: "خَيْرُ النَّاسِ قَرْنِي، ثُمَّ الَّذِينَ يَلُونَهُمْ، ثُمَّ الَّذِينَ يَلُونَهُمْ", dimmed: true)

                    Text("A **Salafi (سَلَفِي)** is simply one who ascribes himself to the Salaf: who takes his creed, worship, and understanding from them rather than from later opinions. **Salafiyyah (السَّلَفِيَّة)** is that way. It is another name for Ahl as-Sunnah wal-Jama‘ah, Ahl al-Hadith, and Ahl al-Athar.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Salaf (سَلَف)**: from the root س-ل-ف, “salafa,” to go before, to precede. Whatever has passed is “salaf,” and a man’s forefathers are his “aslaf.” The Quran uses the word for people who went ahead and became an example for those who came after them:")
                        .font(.body)
                    ScriptureQuote(text: "“And We made them a precedent and an example for the later peoples” (Quran 43:56).", arabic: "فَجَعَلۡنَٰهُمۡ سَلَفٗا وَمَثَلٗا لِّلۡأٓخِرِينَ")

                    Text("The Prophet (peace be upon him) used the same word for himself when he told Fatimah (may Allah be pleased with her) that his death was near:")
                        .font(.body)
                    ScriptureQuote(text: "“So fear Allah and be patient, for I am the best predecessor (salaf) for you” (Sahih al-Bukhari 6285, Sahih Muslim 2450).", arabic: "فَاتَّقِي اللَّهَ وَاصْبِرِي، فَإِنِّي نِعْمَ السَّلَفُ أَنَا لَكَ", dimmed: true)

                    Text("In the religion, “the Salaf” are the Righteous Predecessors named above: the Companions, the Tabi‘un, and their followers, together with every scholar after them who kept to their path.")
                        .font(.body)

                    Text("**Salafi (سَلَفِي)** and **Salafiyyah (السَّلَفِيَّة)**: the ascription (نِسْبَة) to the Salaf, exactly as “Madani” is the ascription to Madinah and “Hanbali” the ascription to Imam Ahmad ibn Hanbal. It names a methodology, not a party: taking the Quran and the Sunnah with the understanding of the first generations. Nobody founded it, nobody owns it, and nobody joins it by registering; a person is Salafi to the extent that he actually follows the Salaf. That is why Ibn Taymiyyah said there is no blame on one who manifests the way of the Salaf and ascribes himself to it, for their way can be nothing but the truth (Majmu‘ al-Fatawa 4/149, quoted later in this article).")
                        .font(.body)

                    Text("**Khalaf (خَلَف)**: from the root خ-ل-ف, to come after, to succeed. The Khalaf are the later generations, and in the books of creed the word usually means those later scholars who left the plain method of the Salaf for the methods of kalam. The saying “the way of the Salaf is safer, but the way of the Khalaf is more knowledgeable and wiser” is the saying Shaykh al-Islam Ibn Taymiyyah (may Allah have mercy on him) refuted in al-Fatwa al-Hamawiyyah: whoever is safest is also the most knowing and the wisest, because safety in the religion comes only from knowledge. The Quran uses the related word “khalf” for successors who went astray:")
                        .font(.body)
                    ScriptureQuote(text: "“But there came after them successors who neglected prayer and pursued desires; so they are going to meet evil” (Quran 19:59).", arabic: "فَخَلَفَ مِنۢ بَعۡدِهِمۡ خَلۡفٌ أَضَاعُواْ ٱلصَّلَوٰةَ وَٱتَّبَعُواْ ٱلشَّهَوَٰتِۖ فَسَوۡفَ يَلۡقَوۡنَ غَيًّا")

                    Text("**Ahl as-Sunnah wal-Jama‘ah (أَهْل السُّنَّة وَالجَمَاعَة)**: “the People of the Sunnah and the Congregation.” Sunnah is the way of the Prophet (peace be upon him); Jama‘ah, from ج-م-ع, to gather, is the body of the Companions and whoever gathers upon what they were upon. The name is taken from the Prophet’s own description of the one group that is saved:")
                        .font(.body)
                    ScriptureQuote(text: "“The Children of Israel split into seventy-one sects, and my nation will split into seventy-two sects, all of them in the Fire except one, and it is the Jama‘ah” (Sunan Ibn Majah 3993; graded sahih by al-Albani).", arabic: "إِنَّ بَنِي إِسْرَائِيلَ افْتَرَقَتْ عَلَى إِحْدَى وَسَبْعِينَ فِرْقَةً وَإِنَّ أُمَّتِي سَتَفْتَرِقُ عَلَى ثِنْتَيْنِ وَسَبْعِينَ فِرْقَةً كُلُّهَا فِي النَّارِ إِلاَّ وَاحِدَةً وَهِيَ الْجَمَاعَةُ", dimmed: true)

                    Text("**Ahl al-Hadith (أَهْل الحَدِيث)** and **Ahl al-Athar (أَهْل الأَثَر)**: “the People of Hadith” and “the People of Narration.” Athar, from أ-ث-ر, is a trace or footprint, and so a transmitted report from the Prophet (peace be upon him) or from the Salaf. These are the names the early imams used for those who built their religion on transmitted reports rather than on opinion. When at-Tirmidhi recorded the hadith of the aided group, he related that his teacher Imam al-Bukhari said, from his own teacher Ali ibn al-Madini (may Allah have mercy on them both):")
                        .font(.body)
                    ScriptureQuote(text: "“They are the people of hadith” (Sunan al-Tirmidhi, the words of al-Bukhari recorded after hadith 2192).", arabic: "هُمْ أَصْحَابُ الْحَدِيثِ", dimmed: true)

                    Text("Imam Ahmad (may Allah have mercy on him) said the same: if the aided group is not the people of hadith, he did not know who they are (al-Hakim, Ma‘rifat Ulum al-Hadith; al-Khatib al-Baghdadi, Sharaf Ashab al-Hadith).")
                        .font(.body)

                    Text("**At-Ta’ifah al-Mansurah (الطَّائِفَة المَنْصُورَة)**: “the Aided Group,” from ta’ifah, a group, and nasr, help and victory. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“There will not cease to be a group of my nation standing upon the command of Allah; they will not be harmed by those who desert them or oppose them, until the command of Allah comes while they are upon that” (Sahih al-Bukhari 3641, Sahih Muslim 1920).", arabic: "لاَ يَزَالُ مِنْ أُمَّتِي أُمَّةٌ قَائِمَةٌ بِأَمْرِ اللَّهِ، لاَ يَضُرُّهُمْ مَنْ خَذَلَهُمْ وَلاَ مَنْ خَالَفَهُمْ حَتَّى يَأْتِيَهُمْ أَمْرُ اللَّهِ وَهُمْ عَلَى ذَلِكَ", dimmed: true)

                    Text("**Al-Firqah an-Najiyah (الفِرْقَة النَّاجِيَة)**: “the Saved Sect,” from faraqa, to split apart, and naja, to be saved. It is the one group of the seventy-three that the Prophet (peace be upon him) called the Jama‘ah in the narration quoted above. Abu Hurayrah (may Allah be pleased with him) narrated the prophecy of the splitting:")
                        .font(.body)
                    ScriptureQuote(text: "“The Jews split into seventy-one or seventy-two sects, and the Christians split into seventy-one or seventy-two sects, and my nation will split into seventy-three sects” (Sunan Abi Dawud 4596; graded hasan sahih by al-Albani).", arabic: "افْتَرَقَتِ الْيَهُودُ عَلَى إِحْدَى أَوْ ثِنْتَيْنِ وَسَبْعِينَ فِرْقَةً وَتَفَرَّقَتِ النَّصَارَى عَلَى إِحْدَى أَوْ ثِنْتَيْنِ وَسَبْعِينَ فِرْقَةً وَتَفْتَرِقُ أُمَّتِي عَلَى ثَلاَثٍ وَسَبْعِينَ فِرْقَةً", dimmed: true)

                    Text("**Al-Ghuraba’ (الغُرَبَاء)**: “the Strangers,” plural of gharib, one who is far from home and unfamiliar to those around him. The Prophet (peace be upon him) foretold that those who hold to the original Islam would one day look like strangers even among the Muslims:")
                        .font(.body)
                    ScriptureQuote(text: "“Islam began as something strange, and it will return to being strange as it began, so glad tidings to the strangers” (Sahih Muslim 145).", arabic: "بَدَأَ الإِسْلاَمُ غَرِيبًا وَسَيَعُودُ كَمَا بَدَأَ غَرِيبًا فَطُوبَى لِلْغُرَبَاءِ", dimmed: true)

                    Text("**Manhaj (مَنْهَج)**: from ن-ه-ج; a “nahj” is a clear, open road. In the religion the manhaj is the method by which a person receives, understands, and practises Islam: where he takes his creed from, how he reads the texts, how he treats rulers, scholars, and opponents. The Salafi manhaj is the Companions’ method. Allah used the word for the path He laid down:")
                        .font(.body)
                    ScriptureQuote(text: "“To each of you We prescribed a law and a method” (Quran 5:48).", arabic: "لِكُلّٖ جَعَلۡنَا مِنكُمۡ شِرۡعَةٗ وَمِنۡهَاجٗاۚ")

                    Text("**Ittiba‘ (اتِّبَاع)**: following, from ت-ب-ع, to walk in someone’s footsteps: accepting a matter of religion because the Prophet (peace be upon him) said it or did it, together with its evidence. Its opposite is ibtida‘, inventing. Allah made ittiba‘ the proof of love for Him:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘If you should love Allah, then follow me, [so] Allah will love you and forgive you your sins. And Allah is Forgiving and Merciful’” (Quran 3:31).", arabic: "قُلۡ إِن كُنتُمۡ تُحِبُّونَ ٱللَّهَ فَٱتَّبِعُونِي يُحۡبِبۡكُمُ ٱللَّهُ وَيَغۡفِرۡ لَكُمۡ ذُنُوبَكُمۡۚ وَٱللَّهُ غَفُورٞ رَّحِيمٞ")

                    Text("**“Wahhabi” (وَهَّابِي)**: a label coined by opponents for the followers of Shaykh Muhammad ibn Abd al-Wahhab (may Allah have mercy on him) (d. 1206 AH), the scholar of Najd who called the people back to the tawhid of the Quran and to the creed of Imam Ahmad. He founded no school and named nothing after himself, and the name is not even his own: Abd al-Wahhab was his father, who was not the caller. Al-Wahhab, “the Bestower,” is one of the names of Allah:")
                        .font(.body)
                    ScriptureQuote(text: "“Or do they have the depositories of the mercy of your Lord, the Exalted in Might, the Bestower?” (Quran 38:9).", arabic: "أَمۡ عِندَهُمۡ خَزَآئِنُ رَحۡمَةِ رَبِّكَ ٱلۡعَزِيزِ ٱلۡوَهَّابِ")

                    Text("**Hizbiyyah (حِزْبِيَّة)**: partisanship, from hizb, a party or faction: loyalty and enmity for the sake of a group, its leader, or its label instead of for the sake of the truth. Allah counted it among the marks of those who divided their religion:")
                        .font(.body)
                    ScriptureQuote(text: "“[Or] of those who have divided their religion and become sects, every faction rejoicing in what it has” (Quran 30:32).", arabic: "مِنَ ٱلَّذِينَ فَرَّقُواْ دِينَهُمۡ وَكَانُواْ شِيَعٗاۖ كُلُّ حِزۡبِۭ بِمَا لَدَيۡهِمۡ فَرِحُونَ")
                    ScriptureQuote(text: "“But the people divided their religion among them into sects - each faction, in what it has, rejoicing” (Quran 23:53).", arabic: "فَتَقَطَّعُوٓاْ أَمۡرَهُم بَيۡنَهُمۡ زُبُرٗاۖ كُلُّ حِزۡبِۭ بِمَا لَدَيۡهِمۡ فَرِحُونَ")

                    Text("The only party a Muslim belongs to is the one Allah named:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah is pleased with them, and they are pleased with Him - those are the party of Allah. Unquestionably, the party of Allah - they are the successful” (Quran 58:22).", arabic: "رَضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُۚ أُوْلَٰٓئِكَ حِزۡبُ ٱللَّهِۚ أَلَآ إِنَّ حِزۡبَ ٱللَّهِ هُمُ ٱلۡمُفۡلِحُونَ")

                    Text("**Bid‘ah (بِدْعَة)**: innovation, from ب-د-ع, to bring something into being with no prior example; Allah is al-Badi‘, “Originator of the heavens and the earth” (Quran 2:117). In the religion, ash-Shatibi (may Allah have mercy on him) defined it in al-I‘tisam as an invented way in the religion that imitates the legislated way and is followed in order to draw near to Allah. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever introduces into this affair of ours what is not in it, it is rejected” (Sahih al-Bukhari 2697, Sahih Muslim 1718).", arabic: "مَنْ أَحْدَثَ فِي أَمْرِنَا هَذَا مَا لَيْسَ فِيهِ فَهُوَ رَدٌّ", dimmed: true)

                    Text("**Sunnah (سُنَّة)**: from س-ن-ن; a way or established practice. In the language it can be good or bad, which is why the Prophet (peace be upon him) spoke of “whoever sets a good sunnah in Islam” and “whoever sets a bad sunnah” (Sahih Muslim 1017). In the religion it is his way: his sayings, actions, and approvals, and, in the books of creed, the whole of Islam as he left it, the opposite of bid‘ah. He said of those who wanted a worship other than his:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever turns away from my Sunnah is not of me” (Sahih al-Bukhari 5063).", arabic: "فَمَنْ رَغِبَ عَنْ سُنَّتِي فَلَيْسَ مِنِّي", dimmed: true)

                    Text("**Al-Qurun ath-Thalathah (القُرُون الثَّلَاثَة)**: “the three generations.” A qarn is the people of one age. The three are the Companions, the Tabi‘un, and the Atba‘ at-Tabi‘in, whom the Prophet (peace be upon him) called the best of people in the hadith quoted above (Sahih al-Bukhari 2652). Their era is the reference point of Salafiyyah: whatever was not religion then is not religion now.")
                        .font(.body)
                }

                Section(header: Text("WHY THE SALAF?")) {
                    Text("Because Allah (Glorified and Exalted be He) made their way the standard, and made following anything else a way to the Fire:")
                        .font(.body)
                    ScriptureQuote(text: "“And whoever opposes the Messenger after guidance has become clear to him and follows other than the way of the believers - We will give him what he has taken and drive him into Hell, and evil it is as a destination” (Quran 4:115).", arabic: "وَمَن يُشَاقِقِ ٱلرَّسُولَ مِنۢ بَعۡدِ مَا تَبَيَّنَ لَهُ ٱلۡهُدَىٰ وَيَتَّبِعۡ غَيۡرَ سَبِيلِ ٱلۡمُؤۡمِنِينَ نُوَلِّهِۦ مَا تَوَلَّىٰ وَنُصۡلِهِۦ جَهَنَّمَۖ وَسَآءَتۡ مَصِيرًا")

                    Text("“The way of the believers“ when this verse came down was the way of the Companions. Allah then declared Himself pleased with them and with those who follow them:")
                        .font(.body)
                    ScriptureQuote(text: "“And the first forerunners among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).", arabic: "وَٱلسَّٰبِقُونَ ٱلۡأَوَّلُونَ مِنَ ٱلۡمُهَٰجِرِينَ وَٱلۡأَنصَارِ وَٱلَّذِينَ ٱتَّبَعُوهُم بِإِحۡسَٰنٖ رَّضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُ")

                    Text("The Prophet (peace be upon him) named the one saved group by exactly this standard:")
                        .font(.body)
                    ScriptureQuote(text: "“The Children of Israel split into seventy-two sects, and my nation will split into seventy-three; all of them will be in the Fire except one.” They said: And which is that, O Messenger of Allah? He said: “What I and my Companions are upon” (Sunan al-Tirmidhi 2641; graded hasan by al-Albani).", arabic: "مَا أَنَا عَلَيْهِ وَأَصْحَابِي", dimmed: true)

                    ScriptureQuote(text: "“Hold fast to my Sunnah and the Sunnah of the rightly guided caliphs after me. Cling to it with your molar teeth, and beware of newly invented matters, for every newly invented matter is an innovation, and every innovation is misguidance” (Sunan Abi Dawud 4607; graded sahih by al-Albani).", arabic: "فَعَلَيْكُمْ بِسُنَّتِي وَسُنَّةِ الْخُلَفَاءِ الْمَهْدِيِّينَ الرَّاشِدِينَ تَمَسَّكُوا بِهَا وَعَضُّوا عَلَيْهَا بِالنَّوَاجِذِ وَإِيَّاكُمْ وَمُحْدَثَاتِ الأُمُورِ فَإِنَّ كُلَّ مُحْدَثَةٍ بِدْعَةٌ وَكُلَّ بِدْعَةٍ ضَلاَلَةٌ", dimmed: true)

                    Text("The Companions received the Quran as it came down, heard the Sunnah from the mouth of the Prophet (peace be upon him), and watched him live it. Nobody who came later can understand revelation better than those it was revealed among. So whoever wants the religion as it was sent must take it through them.")
                        .font(.body)
                }

                Section(header: Text("WHAT THE SALAF SAID ABOUT THEIR WAY")) {
                    Text("Abdullah ibn Mas‘ud (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Follow, and do not innovate, for you have been sufficed” (Sunan al-Darimi 207; al-Haythami: its narrators are those of the Sahih, Majma' az-Zawa'id 1/181).", arabic: "اتَّبِعُوا، وَلَا تَبْتَدِعُوا، فَقَدْ كُفِيتُمْ", dimmed: true)

                    Text("Imam al-Awza‘i (may Allah have mercy on him), the imam of Syria (d. 157 AH), said:")
                        .font(.body)
                    ScriptureQuote(text: "“Hold to the narrations of those who came before, even if the people reject you, and beware of the opinions of men, even if they beautify them for you with speech” (al-Khatib al-Baghdadi, Sharaf Ashab al-Hadith 6; al-Ajurri, ash-Shari'ah 127).", arabic: "عَلَيْكَ بِآثَارِ مَنْ سَلَفَ وَإِنْ رَفَضَكَ النَّاسُ، وَإِيَّاكَ وَآرَاءَ الرِّجَالِ وَإِنْ زَخْرَفُوهُ لَكَ بِالْقَوْلِ", dimmed: true)

                    Text("Imam Abu Hanifah (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Hold to the narrations and the way of the Salaf, and beware of every newly invented matter, for it is an innovation” (as-Suyuti, Sawn al-Mantiq, p. 32).", arabic: "عَلَيْكَ بِالْأَثَرِ وَطَرِيقَةِ السَّلَفِ، وَإِيَّاكَ وَكُلَّ مُحْدَثَةٍ فَإِنَّهَا بِدْعَةٌ", dimmed: true)

                    Text("Imam al-Barbahari (may Allah have mercy on him) (d. 329 AH) opened his creed with:")
                        .font(.body)
                    ScriptureQuote(text: "“Know that Islam is the Sunnah and the Sunnah is Islam, and neither of them stands without the other” (Sharh as-Sunnah 1).", arabic: "اعْلَمُوا أَنَّ الْإِسْلَامَ هُوَ السُّنَّةُ، وَالسُّنَّةُ هِيَ الْإِسْلَامُ، وَلَا يَقُومُ أَحَدُهُمَا إِلَّا بِالْآخَرِ", dimmed: true)

                    Text("And Shaykh al-Islam Ibn Taymiyyah (may Allah have mercy on him) wrote:")
                        .font(.body)
                    ScriptureQuote(text: "“There is no blame on the one who manifests the way of the Salaf, ascribes himself to it, and takes pride in it; rather it is obligatory to accept that from him by agreement, for the way of the Salaf can be nothing but the truth” (Majmu' al-Fatawa 4/149).", arabic: "لَا عَيْبَ عَلَى مَنْ أَظْهَرَ مَذْهَبَ السَّلَفِ وَانْتَسَبَ إِلَيْهِ وَاعْتَزَى إِلَيْهِ، بَلْ يَجِبُ قَبُولُ ذَلِكَ مِنْهُ بِالِاتِّفَاقِ، فَإِنَّ مَذْهَبَ السَّلَفِ لَا يَكُونُ إِلَّا حَقًّا", dimmed: true)

                    Text("The word itself is old. Imam adh-Dhahabi (d. 748 AH) wrote that a hadith master must be “pious, intelligent, a grammarian, a linguist, upright, modest, and **Salafi**“ (Siyar A‘lam an-Nubala’ 13/380), and used “Salafi“ as a description of many scholars in his biographies.")
                        .font(.body)
                }

                Section(header: Text("WHY THE ATHARI CREED IS THE TRUTH")) {
                    Text("The creed of Salafiyyah is the **Athari** creed, the creed of narration (see “The Madhahib of Aqeedah“). It is the truth for four reasons.")
                        .font(.body)

                    Text("**1. Creed can only come from revelation.** Nobody knows about Allah, His names, the unseen, or the Hereafter by reasoning; it is told, or it is not known. So the only sound creed is the one taken from the texts as they are:")
                        .font(.body)
                    ScriptureQuote(text: "“Nor does he speak from [his own] inclination. It is not but a revelation revealed” (Quran 53:3-4).", arabic: "وَمَا يَنطِقُ عَنِ ٱلۡهَوَىٰٓ ۝ إِنۡ هُوَ إِلَّا وَحۡيٞ يُوحَىٰ")

                    Text("**2. The religion was completed in the Companions’ time.** Whatever belief they did not hold was not part of Islam then, and cannot be part of it now:")
                        .font(.body)
                    ScriptureQuote(text: "“This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as religion” (Quran 5:3).", arabic: "ٱلۡيَوۡمَ أَكۡمَلۡتُ لَكُمۡ دِينَكُمۡ وَأَتۡمَمۡتُ عَلَيۡكُمۡ نِعۡمَتِي وَرَضِيتُ لَكُمُ ٱلۡإِسۡلَٰمَ دِينٗاۚ")

                    Text("**3. It is the creed of every prophet.** Allah said the same thing to Nuh, Ibrahim, Musa, Isa, and Muhammad (peace be upon them all): worship Allah alone, believe in what He revealed, without addition:")
                        .font(.body)
                    ScriptureQuote(text: "“And We certainly sent into every nation a messenger, [saying], ‘Worship Allah and avoid Taghut’” (Quran 16:36).", arabic: "وَلَقَدۡ بَعَثۡنَا فِي كُلِّ أُمَّةٖ رَّسُولًا أَنِ ٱعۡبُدُواْ ٱللَّهَ وَٱجۡتَنِبُواْ ٱلطَّٰغُوتَۖ")

                    Text("**4. It is what the four imams believed.** Abu Hanifah, Malik, al-Shafi‘i, and Ahmad all affirmed the attributes as they came, said the Quran is Allah’s uncreated speech, and condemned kalam. Imam al-Shafi‘i (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“I believe in Allah and in what came from Allah as Allah intended, and I believe in the Messenger of Allah and in what came from the Messenger of Allah as the Messenger of Allah intended” (Ibn Qudamah, Lum'at al-I'tiqad).", arabic: "آمَنْتُ بِاللَّهِ وَبِمَا جَاءَ عَنِ اللَّهِ عَلَى مُرَادِ اللَّهِ، وَآمَنْتُ بِرَسُولِ اللَّهِ وَبِمَا جَاءَ عَنْ رَسُولِ اللَّهِ عَلَى مُرَادِ رَسُولِ اللَّهِ", dimmed: true)

                    Text("Every other creed appeared later, is named after a man or a movement, and changes the texts to fit an argument. The way of the Salaf changes nothing and adds nothing.")
                        .font(.body)
                }

                Section(header: Text("WHAT SALAFIYYAH IS NOT")) {
                    Text("It is not a political party, a modern movement, or a school named after a founder; nobody founded it. It is not harshness; the Salaf were the most merciful of people to the believers. It is not takfir of Muslims; that is the way of the Khawarij, whom the Salaf fought. And it is not a claim that a particular group of people are saved by their label; it is a standard that every person, including the one who calls himself Salafi, is measured against.")
                        .font(.body)

                    ScriptureQuote(text: "“Say, ‘This is my way; I invite to Allah with insight, I and those who follow me. And exalted is Allah; and I am not of those who associate others with Him’” (Quran 12:108).", arabic: "قُلۡ هَٰذِهِۦ سَبِيلِيٓ أَدۡعُوٓاْ إِلَى ٱللَّهِۚ عَلَىٰ بَصِيرَةٍ أَنَا۠ وَمَنِ ٱتَّبَعَنِيۖ وَسُبۡحَٰنَ ٱللَّهِ وَمَآ أَنَا۠ مِنَ ٱلۡمُشۡرِكِينَ")
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Is Salafiyyah a new sect or group?**")
                        .font(.body)
                    Text("No. A sect is something that split off from the original; Salafiyyah is the original that the sects split off from. Every sect is named after a man or an idea that appeared after the Companions: the Jahmiyyah after Jahm ibn Safwan (d. 128 AH); the Mu‘tazilah after the withdrawal (i‘tizal) of Wasil ibn Ata from the circle of al-Hasan al-Basri, as ash-Shahrastani relates in al-Milal wan-Nihal; the Ash‘ariyyah after Abu al-Hasan al-Ash‘ari (may Allah have mercy on him), who himself ended upon the creed of Imam Ahmad, as he declared in al-Ibanah. Salafiyyah is named after nobody but the first generations, whom Allah praised in the verses quoted above (Quran 9:100, 4:115). The name is old, as adh-Dhahabi’s use of “Salafi” shows, and it is a description, not a membership, as Ibn Taymiyyah explained above. Allah forbade being like the sects:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not be like the ones who became divided and differed after the clear proofs had come to them. And those will have a great punishment” (Quran 3:105).", arabic: "وَلَا تَكُونُواْ كَٱلَّذِينَ تَفَرَّقُواْ وَٱخۡتَلَفُواْ مِنۢ بَعۡدِ مَا جَآءَهُمُ ٱلۡبَيِّنَٰتُۚ وَأُوْلَٰٓئِكَ لَهُمۡ عَذَابٌ عَظِيمٞ")
                    ScriptureQuote(text: "“Indeed, those who have divided their religion and become sects - you, [O Muhammad], are not [associated] with them in anything. Their affair is only [left] to Allah; then He will inform them about what they used to do” (Quran 6:159).", arabic: "إِنَّ ٱلَّذِينَ فَرَّقُواْ دِينَهُمۡ وَكَانُواْ شِيَعٗا لَّسۡتَ مِنۡهُمۡ فِي شَيۡءٍۚ إِنَّمَآ أَمۡرُهُمۡ إِلَى ٱللَّهِ ثُمَّ يُنَبِّئُهُم بِمَا كَانُواْ يَفۡعَلُونَ")

                    Text("Imam Malik (may Allah have mercy on him) said that the last of this nation will not be rectified except by what rectified its first (related by al-Qadi Iyad in ash-Shifa).")
                        .font(.body)

                    Text("**Is “Salafi” the same as “Wahhabi”?**")
                        .font(.body)
                    Text("“Wahhabi” is not a name anyone chose for himself; it was coined by opponents for the followers of Shaykh Muhammad ibn Abd al-Wahhab (may Allah have mercy on him) (d. 1206 AH). He founded no school and called to nothing of his own. He opened his statement of creed to the people of al-Qasim with these words:")
                        .font(.body)
                    ScriptureQuote(text: "“I call Allah to witness, and the angels present with me, and I call you to witness, that I believe what the Saved Sect, Ahl as-Sunnah wal-Jama‘ah, believes” (ad-Durar as-Saniyyah, vol. 1, his letter of creed to the people of al-Qasim).", arabic: "أُشْهِدُ اللَّهَ وَمَنْ حَضَرَنِي مِنَ الْمَلَائِكَةِ وَأُشْهِدُكُمْ أَنِّي أَعْتَقِدُ مَا اعْتَقَدَتْهُ الْفِرْقَةُ النَّاجِيَةُ أَهْلُ السُّنَّةِ وَالْجَمَاعَةِ", dimmed: true)

                    Text("In his letters he also wrote that he was, by Allah’s grace, a follower and not an innovator, that in the branches of fiqh he was upon the madhhab of Imam Ahmad, and that he did not censure anyone who followed one of the four imams (ad-Durar as-Saniyyah, vol. 1). So what the label points to is simply Salafiyyah: the tawhid of the Quran and the creed of Imam Ahmad. A Salafi still does not accept the label, for two reasons. First, al-Wahhab is a name of Allah (Quran 38:9), and Abd al-Wahhab was the Shaykh’s father, not the caller. Second, Salafiyyah is ascribed to the Salaf, not to any later scholar, however great; a Salafi honours the Shaykh as one of many who revived the call, not as its founder.")
                        .font(.body)

                    Text("**Why not just say “Muslim”?**")
                        .font(.body)
                    Text("“Muslim” is the name Allah gave us, and it comes first:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah named you ‘Muslims’ before [in former scriptures] and in this [revelation]” (Quran 22:78).", arabic: "هُوَ سَمَّىٰكُمُ ٱلۡمُسۡلِمِينَ مِن قَبۡلُ وَفِي هَٰذَا")

                    Text("But every sect also says “Muslim.” The Khawarij who fought Ali, the Jahmiyyah who denied the attributes of Allah, and the Rafidah who curse the Companions all call themselves Muslims. So when the Prophet (peace be upon him) foretold the splitting, he did not say “the saved ones are the Muslims”; he gave a description that separates the truth from the sects:")
                        .font(.body)
                    ScriptureQuote(text: "“Those before you of the People of the Book split into seventy-two sects, and this religious community will split into seventy-three: seventy-two in the Fire and one in Paradise, and it is the Jama‘ah” (Sunan Abi Dawud 4597; graded hasan by al-Albani).", arabic: "أَلاَ إِنَّ مَنْ قَبْلَكُمْ مِنْ أَهْلِ الْكِتَابِ افْتَرَقُوا عَلَى ثِنْتَيْنِ وَسَبْعِينَ مِلَّةً وَإِنَّ هَذِهِ الْمِلَّةَ سَتَفْتَرِقُ عَلَى ثَلاَثٍ وَسَبْعِينَ ثِنْتَانِ وَسَبْعُونَ فِي النَّارِ وَوَاحِدَةٌ فِي الْجَنَّةِ وَهِيَ الْجَمَاعَةُ", dimmed: true)

                    Text("When Hudhayfah (may Allah be pleased with him) asked what to do if he lived to see callers at the gates of Hell who were “of our skin and speak our tongue,” the Prophet (peace be upon him) answered with the same word:")
                        .font(.body)
                    ScriptureQuote(text: "“Hold fast to the Jama‘ah of the Muslims and their imam” (Sahih al-Bukhari 3606, Sahih Muslim 1847).", arabic: "تَلْزَمُ جَمَاعَةَ الْمُسْلِمِينَ وَإِمَامَهُمْ", dimmed: true)

                    Text("And in the narration quoted above he described that group as “what I and my Companions are upon.” “Salafi” is nothing but this description in one word. The Jama‘ah is not a matter of numbers. Abdullah ibn Mas‘ud (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The Jama‘ah is what agrees with the truth, even if you are alone” (quoted by Ibn al-Qayyim in I‘lam al-Muwaqqi‘in; see also al-Lalika’i, Sharh Usul I‘tiqad Ahl as-Sunnah, from Ibn Mas‘ud).", arabic: "الْجَمَاعَةُ مَا وَافَقَ الْحَقَّ وَإِنْ كُنْتَ وَحْدَكَ", dimmed: true)

                    Text("**Do Salafis reject the scholars or the madhhabs?**")
                        .font(.body)
                    Text("No. Following the scholars is a command of Allah:")
                        .font(.body)
                    ScriptureQuote(text: "“So ask the people of the message if you do not know” (Quran 16:43).", arabic: "فَسۡـَٔلُوٓاْ أَهۡلَ ٱلذِّكۡرِ إِن كُنتُمۡ لَا تَعۡلَمُونَ")
                    ScriptureQuote(text: "“O you who have believed, obey Allah and obey the Messenger and those in authority among you. And if you disagree over anything, refer it to Allah and the Messenger, if you should believe in Allah and the Last Day. That is the best [way] and best in result” (Quran 4:59).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ أَطِيعُواْ ٱللَّهَ وَأَطِيعُواْ ٱلرَّسُولَ وَأُوْلِي ٱلۡأَمۡرِ مِنكُمۡۖ فَإِن تَنَٰزَعۡتُمۡ فِي شَيۡءٖ فَرُدُّوهُ إِلَى ٱللَّهِ وَٱلرَّسُولِ إِن كُنتُمۡ تُؤۡمِنُونَ بِٱللَّهِ وَٱلۡيَوۡمِ ٱلۡأٓخِرِۚ ذَٰلِكَ خَيۡرٞ وَأَحۡسَنُ تَأۡوِيلًا")

                    Text("The commentators explained “those in authority” as the scholars and the rulers; both are obeyed in what agrees with Allah and His Messenger, which is why the verse ends by returning every dispute to the two. And the Prophet (peace be upon him) tied the survival of knowledge to the scholars:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah does not take away knowledge by snatching it away from the servants, but He takes away knowledge by taking away the scholars, until, when He leaves no scholar, the people take ignorant heads who are asked and give verdicts without knowledge, so they go astray and lead others astray” (Sahih al-Bukhari 100).", arabic: "إِنَّ اللَّهَ لاَ يَقْبِضُ الْعِلْمَ انْتِزَاعًا، يَنْتَزِعُهُ مِنَ الْعِبَادِ، وَلَكِنْ يَقْبِضُ الْعِلْمَ بِقَبْضِ الْعُلَمَاءِ، حَتَّى إِذَا لَمْ يُبْقِ عَالِمًا، اتَّخَذَ النَّاسُ رُءُوسًا جُهَّالاً فَسُئِلُوا، فَأَفْتَوْا بِغَيْرِ عِلْمٍ، فَضَلُّوا وَأَضَلُّوا", dimmed: true)

                    Text("The great Salafi scholars were themselves men of the madhhabs: Ibn Qudamah, Ibn Taymiyyah, Ibn al-Qayyim, Ibn Rajab, Muhammad ibn Abd al-Wahhab, Ibn Baz, and Ibn al-Uthaymin were Hanbalis; adh-Dhahabi and Ibn Kathir were Shafi‘is. Ibn Taymiyyah even wrote a treatise, Raf‘ al-Malam ‘an al-A’immah al-A‘lam, excusing the imams whenever an authentic hadith seems to contradict one of their opinions. What a Salafi refuses is to put any man’s opinion above an authentic text, and that is exactly what the four imams commanded. Imam al-Shafi‘i (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If the hadith is authentic, then it is my madhhab” (an-Nawawi, al-Majmu‘ 1/63).", arabic: "إِذَا صَحَّ الْحَدِيثُ فَهُوَ مَذْهَبِي", dimmed: true)

                    Text("And Imam Ahmad (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not blindly follow me, nor Malik, nor al-Shafi‘i, nor al-Awza‘i, nor ath-Thawri; take from where they took” (Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "لَا تُقَلِّدْنِي وَلَا تُقَلِّدْ مَالِكًا وَلَا الشَّافِعِيَّ وَلَا الْأَوْزَاعِيَّ وَلَا الثَّوْرِيَّ، وَخُذْ مِنْ حَيْثُ أَخَذُوا", dimmed: true)

                    Text("So a Salafi studies fiqh through the madhhabs, respects their imams, and follows a scholar he trusts; but when the evidence is clear and an opinion contradicts it, the evidence wins, because that is what the imams themselves said.")
                        .font(.body)

                    Text("**Is everyone who is not Salafi a disbeliever?**")
                        .font(.body)
                    Text("No. Whoever testifies that none has the right to be worshipped but Allah and that Muhammad is His Messenger, prays our prayer, and faces our qiblah is a Muslim, and his errors and innovations, however serious, do not put him outside Islam unless they reach clear disbelief and the proof has been established against him. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever prays our prayer and faces our qiblah and eats our slaughtered animals, that is the Muslim who has the protection of Allah and the protection of His Messenger; so do not betray Allah in His protection” (Sahih al-Bukhari 391).", arabic: "مَنْ صَلَّى صَلاَتَنَا، وَاسْتَقْبَلَ قِبْلَتَنَا، وَأَكَلَ ذَبِيحَتَنَا، فَذَلِكَ الْمُسْلِمُ الَّذِي لَهُ ذِمَّةُ اللَّهِ وَذِمَّةُ رَسُولِهِ، فَلاَ تُخْفِرُوا اللَّهَ فِي ذِمَّتِهِ", dimmed: true)
                    ScriptureQuote(text: "“If a man says to his brother, ‘O disbeliever,’ then one of the two has earned it” (Sahih al-Bukhari 6103, Sahih Muslim 60).", arabic: "إِذَا قَالَ الرَّجُلُ لأَخِيهِ يَا كَافِرُ فَقَدْ بَاءَ بِهِ أَحَدُهُمَا", dimmed: true)

                    Text("Allah forbade denying the faith of one who shows Islam, and He named the people of the qiblah brothers even when they fight one another:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not say to one who gives you [a greeting of] peace ‘You are not a believer’” (Quran 4:94).", arabic: "وَلَا تَقُولُواْ لِمَنۡ أَلۡقَىٰٓ إِلَيۡكُمُ ٱلسَّلَٰمَ لَسۡتَ مُؤۡمِنٗا")
                    ScriptureQuote(text: "“The believers are but brothers, so make settlement between your brothers” (Quran 49:10).", arabic: "إِنَّمَا ٱلۡمُؤۡمِنُونَ إِخۡوَةٞ فَأَصۡلِحُواْ بَيۡنَ أَخَوَيۡكُمۡۚ")

                    Text("Shaykh al-Islam Ibn Taymiyyah (may Allah have mercy on him), who refuted every sect of his time, wrote:")
                        .font(.body)
                    ScriptureQuote(text: "“I am among the greatest of people in forbidding that a specific person be charged with disbelief, sin, or disobedience, unless it is known that the proof of the message has been established against him” (Majmu‘ al-Fatawa 3/229).", arabic: "وَأَنَا مِنْ أَعْظَمِ النَّاسِ نَهْيًا عَنْ أَنْ يُنْسَبَ مُعَيَّنٌ إِلَى تَكْفِيرٍ وَتَفْسِيقٍ وَمَعْصِيَةٍ إِلَّا إِذَا عُلِمَ أَنَّهُ قَدْ قَامَتْ عَلَيْهِ الْحُجَّةُ الرِّسَالِيَّةُ", dimmed: true)

                    Text("A Salafi names the error an error and the innovation an innovation, and still calls its holder his brother, prays for him, and hopes for his guidance. Takfir of Muslims for sins and errors is the mark of the Khawarij, not of the Salaf.")
                        .font(.body)

                    Text("**Is Salafiyyah about appearance: the beard, the thawb, the garment above the ankles?**")
                        .font(.body)
                    Text("The Sunnah is followed in everything, and these are part of it. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Oppose the polytheists: leave the beards to grow and trim the moustaches” (Sahih al-Bukhari 5892).", arabic: "خَالِفُوا الْمُشْرِكِينَ، وَفِّرُوا اللِّحَى، وَأَحْفُوا الشَّوَارِبَ", dimmed: true)
                    ScriptureQuote(text: "“Whatever of the lower garment is below the ankles is in the Fire” (Sahih al-Bukhari 5787).", arabic: "مَا أَسْفَلَ مِنَ الْكَعْبَيْنِ مِنَ الإِزَارِ فَفِي النَّارِ", dimmed: true)

                    Text("But they are branches, not the root. The first thing the Prophet (peace be upon him) told Mu‘adh to call to was tawhid, not clothing (Sahih al-Bukhari 1395). A man with a beard and an innovated creed is far from the Salaf, and a man who has just accepted Islam and knows nothing yet of these matters is nearer to them than he. The core of Salafiyyah is the tawhid of Allah and ittiba‘ of His Messenger; appearance follows from that and never replaces it:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, the most noble of you in the sight of Allah is the most righteous of you” (Quran 49:13).", arabic: "إِنَّ أَكۡرَمَكُمۡ عِندَ ٱللَّهِ أَتۡقَىٰكُمۡۚ")
                    ScriptureQuote(text: "“Indeed, Allah does not look at your forms and your wealth, but He looks at your hearts and your deeds” (Sahih Muslim 2564).", arabic: "إِنَّ اللَّهَ لاَ يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ", dimmed: true)

                    Text("**Is Salafiyyah the way of the Khawarij or of extremists?**")
                        .font(.body)
                    Text("It is their opposite. The Khawarij declare Muslims disbelievers for sins and rebel against the rulers; Salafiyyah forbids both. The Prophet (peace be upon him) described the Khawarij:")
                        .font(.body)
                    ScriptureQuote(text: "“There will emerge at the end of time a people young in age, foolish in mind, who will speak with the best speech of creation; their faith will not pass beyond their throats; they will pass out of the religion as the arrow passes out of the game” (Sahih al-Bukhari 6930, Sahih Muslim 1066).", arabic: "سَيَخْرُجُ قَوْمٌ فِي آخِرِ الزَّمَانِ، حُدَّاثُ الأَسْنَانِ، سُفَهَاءُ الأَحْلاَمِ، يَقُولُونَ مِنْ خَيْرِ قَوْلِ الْبَرِيَّةِ، لاَ يُجَاوِزُ إِيمَانُهُمْ حَنَاجِرَهُمْ، يَمْرُقُونَ مِنَ الدِّينِ كَمَا يَمْرُقُ السَّهْمُ مِنَ الرَّمِيَّةِ", dimmed: true)

                    Text("Ibn Umar (may Allah be pleased with them both) considered them the worst of Allah’s creation, and explained their method in words al-Bukhari placed at the head of his chapter on them:")
                        .font(.body)
                    ScriptureQuote(text: "“They went to verses that were revealed about the disbelievers and applied them to the believers” (Sahih al-Bukhari, Kitab Istitabat al-Murtaddin, chapter on killing the Khawarij after the proof is established against them).", arabic: "إِنَّهُمُ انْطَلَقُوا إِلَى آيَاتٍ نَزَلَتْ فِي الْكُفَّارِ فَجَعَلُوهَا عَلَى الْمُؤْمِنِينَ", dimmed: true)

                    Text("Salafiyyah takes the other road: patience with the rulers, advice without rebellion, and no takfir without proof. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever dislikes something from his ruler, let him be patient, for whoever departs from the authority even a handspan dies a death of Jahiliyyah” (Sahih al-Bukhari 7053, Sahih Muslim 1849).", arabic: "مَنْ كَرِهَ مِنْ أَمِيرِهِ شَيْئًا فَلْيَصْبِرْ، فَإِنَّهُ مَنْ خَرَجَ مِنَ السُّلْطَانِ شِبْرًا مَاتَ مِيتَةً جَاهِلِيَّةً", dimmed: true)
                    ScriptureQuote(text: "It was said: O Messenger of Allah, shall we not fight them with the sword? He said: “No, as long as they establish the prayer among you” (Sahih Muslim 1855).", arabic: "قِيلَ يَا رَسُولَ اللَّهِ أَفَلاَ نُنَابِذُهُمْ بِالسَّيْفِ فَقَالَ لاَ مَا أَقَامُوا فِيكُمُ الصَّلاَةَ", dimmed: true)
                    ScriptureQuote(text: "Ubadah ibn as-Samit (may Allah be pleased with him) said: We pledged to the Prophet (peace be upon him) “that we would not dispute the matter with those entitled to it, unless you see open disbelief for which you have a proof from Allah” (Sahih al-Bukhari 7055, Sahih Muslim 1709).", arabic: "وَأَنْ لاَ نُنَازِعَ الأَمْرَ أَهْلَهُ، إِلاَّ أَنْ تَرَوْا كُفْرًا بَوَاحًا، عِنْدَكُمْ مِنَ اللَّهِ فِيهِ بُرْهَانٌ", dimmed: true)

                    Text("When the Khawarij raised their slogan “no judgement but Allah’s” against Ali (may Allah be pleased with him), he said: a word of truth by which falsehood is intended (Sahih Muslim 1066). That is the Salafi reading of every extremist who quotes the Quran: the verse is true, the application is false.")
                        .font(.body)

                    Text("**How should a Salafi treat Muslims who differ with him?**")
                        .font(.body)
                    Text("With justice, gentleness, and brotherhood, and with the truth stated plainly. Allah commanded:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not let the hatred of a people prevent you from being just. Be just; that is nearer to righteousness” (Quran 5:8).", arabic: "وَلَا يَجۡرِمَنَّكُمۡ شَنَـَٔانُ قَوۡمٍ عَلَىٰٓ أَلَّا تَعۡدِلُواْۚ ٱعۡدِلُواْ هُوَ أَقۡرَبُ لِلتَّقۡوَىٰۖ")
                    ScriptureQuote(text: "“Invite to the way of your Lord with wisdom and good instruction, and argue with them in a way that is best” (Quran 16:125).", arabic: "ٱدۡعُ إِلَىٰ سَبِيلِ رَبِّكَ بِٱلۡحِكۡمَةِ وَٱلۡمَوۡعِظَةِ ٱلۡحَسَنَةِۖ وَجَٰدِلۡهُم بِٱلَّتِي هِيَ أَحۡسَنُۚ")
                    ScriptureQuote(text: "“O you who have believed, let not a people ridicule [another] people; perhaps they may be better than them” (Quran 49:11).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ لَا يَسۡخَرۡ قَوۡمٞ مِّن قَوۡمٍ عَسَىٰٓ أَن يَكُونُواْ خَيۡرٗا مِّنۡهُمۡ")

                    Text("The verse before it, quoted above, calls the believers brothers (Quran 49:10), and the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah is in the aid of the servant as long as the servant is in the aid of his brother” (Sahih Muslim 2699).", arabic: "وَاللَّهُ فِي عَوْنِ الْعَبْدِ مَا كَانَ الْعَبْدُ فِي عَوْنِ أَخِيهِ", dimmed: true)
                    ScriptureQuote(text: "“The likeness of the believers in their mutual love, mercy, and compassion is that of one body: when a limb of it complains, the rest of the body responds to it with sleeplessness and fever” (Sahih Muslim 2586).", arabic: "مَثَلُ الْمُؤْمِنِينَ فِي تَوَادِّهِمْ وَتَرَاحُمِهِمْ وَتَعَاطُفِهِمْ مَثَلُ الْجَسَدِ إِذَا اشْتَكَى مِنْهُ عُضْوٌ تَدَاعَى لَهُ سَائِرُ الْجَسَدِ بِالسَّهَرِ وَالْحُمَّى", dimmed: true)

                    Text("Disagreement in a ruling of fiqh is not disagreement in the religion; the Companions differed in such matters and stayed brothers. Where a Muslim has fallen into an innovation, the Salafi way is to clarify the evidence, to hope for him, and never to lie about him or wrong him, because a man who wrongs his opponent has himself left the Sunnah.")
                        .font(.body)

                    Text("**Does Salafiyyah reject reason?**")
                        .font(.body)
                    Text("No. The Quran is full of commands to think, and it counts the people of understanding among the best of the believers:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, in the creation of the heavens and the earth and the alternation of the night and the day are signs for those of understanding” (Quran 3:190).", arabic: "إِنَّ فِي خَلۡقِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ وَٱخۡتِلَٰفِ ٱلَّيۡلِ وَٱلنَّهَارِ لَأٓيَٰتٖ لِّأُوْلِي ٱلۡأَلۡبَٰبِ")
                    ScriptureQuote(text: "“Who remember Allah while standing or sitting or [lying] on their sides and give thought to the creation of the heavens and the earth” (Quran 3:191).", arabic: "ٱلَّذِينَ يَذۡكُرُونَ ٱللَّهَ قِيَٰمٗا وَقُعُودٗا وَعَلَىٰ جُنُوبِهِمۡ وَيَتَفَكَّرُونَ فِي خَلۡقِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ")
                    ScriptureQuote(text: "“Then do they not reflect upon the Qur'an, or are there locks upon [their] hearts?” (Quran 47:24).", arabic: "أَفَلَا يَتَدَبَّرُونَ ٱلۡقُرۡءَانَ أَمۡ عَلَىٰ قُلُوبٍ أَقۡفَالُهَآ")

                    Text("What Salafiyyah rejects is putting reason above revelation. Reason is the tool by which a person recognises that the Quran is from Allah and that Muhammad (peace be upon him) is His Messenger; once it has established that, it submits to what they say, because the One who revealed knows and it does not. Umar (may Allah be pleased with him) showed the balance at the Black Stone:")
                        .font(.body)
                    ScriptureQuote(text: "“I know that you are a stone that neither harms nor benefits; had I not seen the Prophet (peace be upon him) kiss you, I would not have kissed you” (Sahih al-Bukhari 1597).", arabic: "إِنِّي أَعْلَمُ أَنَّكَ حَجَرٌ لاَ تَضُرُّ وَلاَ تَنْفَعُ، وَلَوْلاَ أَنِّي رَأَيْتُ النَّبِيَّ صلى الله عليه وسلم يُقَبِّلُكَ مَا قَبَّلْتُكَ", dimmed: true)

                    Text("His reason told him a stone does nothing; his reason also told him that the Prophet (peace be upon him) is followed. Ibn Taymiyyah devoted his book Dar’ Ta‘arud al-‘Aql wan-Naql to one principle: sound reason never contradicts authentic revelation, so wherever the two seem to clash, either the report is not authentic or the reasoning is not sound.")
                        .font(.body)

                    Text("**Why call to Salafiyyah at all? Why not leave people as they are?**")
                        .font(.body)
                    Text("Because the Prophet (peace be upon him) commanded it precisely for a time of differing:")
                        .font(.body)
                    ScriptureQuote(text: "“I enjoin you to have taqwa of Allah, and to hear and obey, even if it be an Abyssinian slave. Indeed, whoever among you lives will see much differing. Beware of newly invented matters, for indeed they are misguidance” (Sunan al-Tirmidhi 2676; graded sahih by al-Albani).", arabic: "أُوصِيكُمْ بِتَقْوَى اللَّهِ وَالسَّمْعِ وَالطَّاعَةِ وَإِنْ عَبْدٌ حَبَشِيٌّ فَإِنَّهُ مَنْ يَعِشْ مِنْكُمْ يَرَى اخْتِلاَفًا كَثِيرًا وَإِيَّاكُمْ وَمُحْدَثَاتِ الأُمُورِ فَإِنَّهَا ضَلاَلَةٌ", dimmed: true)

                    Text("And then, in the narration quoted above, “hold fast to my Sunnah and the Sunnah of the rightly guided caliphs” (Sunan Abi Dawud 4607). Calling to Salafiyyah is calling to that: not to a group, but to the Quran and the Sunnah as the Companions carried them. Allah made the call an obligation on the nation and an honour for the caller:")
                        .font(.body)
                    ScriptureQuote(text: "“And let there be [arising] from you a nation inviting to [all that is] good, enjoining what is right and forbidding what is wrong, and those will be the successful” (Quran 3:104).", arabic: "وَلۡتَكُن مِّنكُمۡ أُمَّةٞ يَدۡعُونَ إِلَى ٱلۡخَيۡرِ وَيَأۡمُرُونَ بِٱلۡمَعۡرُوفِ وَيَنۡهَوۡنَ عَنِ ٱلۡمُنكَرِۚ وَأُوْلَٰٓئِكَ هُمُ ٱلۡمُفۡلِحُونَ")
                    ScriptureQuote(text: "“And who is better in speech than one who invites to Allah and does righteousness and says, ‘Indeed, I am of the Muslims’” (Quran 41:33).", arabic: "وَمَنۡ أَحۡسَنُ قَوۡلٗا مِّمَّن دَعَآ إِلَى ٱللَّهِ وَعَمِلَ صَٰلِحٗا وَقَالَ إِنَّنِي مِنَ ٱلۡمُسۡلِمِينَ")

                    Text("And the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever calls to guidance has a reward like the rewards of those who follow him, without that diminishing their rewards in the least” (Sahih Muslim 2674).", arabic: "مَنْ دَعَا إِلَى هُدًى كَانَ لَهُ مِنَ الأَجْرِ مِثْلُ أُجُورِ مَنْ تَبِعَهُ لاَ يَنْقُصُ ذَلِكَ مِنْ أُجُورِهِمْ شَيْئًا", dimmed: true)

                    Text("The Prophet (peace be upon him) called with insight, “I and those who follow me,” as the verse quoted above says (Quran 12:108). Whoever follows him carries the same call.")
                        .font(.body)

                    Text("**Is it arrogance to say “I am Salafi”?**")
                        .font(.body)
                    Text("Not when it is said as the Salaf said it: as a statement of whom one follows and a commitment to be held to. The Prophet (peace be upon him) was commanded to say “I and those who follow me” (Quran 12:108), and the caller to Allah says “Indeed, I am of the Muslims” (Quran 41:33); neither is a boast. Ibn Taymiyyah, quoted above, said it is obligatory to accept the ascription from whoever makes it. What is forbidden is claiming purity for oneself:")
                        .font(.body)
                    ScriptureQuote(text: "“So do not claim yourselves to be pure; He is most knowing of who fears Him” (Quran 53:32).", arabic: "فَلَا تُزَكُّوٓاْ أَنفُسَكُمۡۖ هُوَ أَعۡلَمُ بِمَنِ ٱتَّقَىٰٓ")

                    Text("So the name is a claim that deeds must match. Whoever takes pride in the label while opposing the way of the Salaf in creed, worship, or manners has the name without the thing; and whoever follows their way has the thing, whatever he is called.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Salafiyyah is the original Islam: the Quran and the Sunnah as the Companions understood them, the Athari creed, and nothing added. The articles that follow lay out its foundations and answer the paths that departed from it.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Salafiyyah")
        .selectableArticleList()
    }
}

struct QuranSunnahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran and the authentic Sunnah are the two sources of Islam; both are revelation, both are binding, and everything else is judged by them.")
                        .font(.body)
                }

                Section(header: Text("THE QURAN")) {
                    Text("The **Quran (القُرآن)** is the speech of Allah, revealed to Muhammad (peace be upon him) through Jibril, preserved letter by letter, and protected by Allah Himself:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian” (Quran 15:9).", arabic: "إِنَّا نَحۡنُ نَزَّلۡنَا ٱلذِّكۡرَ وَإِنَّا لَهُۥ لَحَٰفِظُونَ")

                    ScriptureQuote(text: "“Then do they not reflect upon the Qur'an? If it had been from [any] other than Allah, they would have found within it much contradiction” (Quran 4:82).", arabic: "أَفَلَا يَتَدَبَّرُونَ ٱلۡقُرۡءَانَۚ وَلَوۡ كَانَ مِنۡ عِندِ غَيۡرِ ٱللَّهِ لَوَجَدُواْ فِيهِ ٱخۡتِلَٰفٗا كَثِيرٗا")

                    Text("It is the first source, the criterion, and the thing every Muslim is commanded to follow:")
                        .font(.body)
                    ScriptureQuote(text: "“Follow, [O mankind], what has been revealed to you from your Lord and do not follow other than Him any allies. Little do you remember” (Quran 7:3).", arabic: "ٱتَّبِعُواْ مَآ أُنزِلَ إِلَيۡكُم مِّن رَّبِّكُمۡ وَلَا تَتَّبِعُواْ مِن دُونِهِۦٓ أَوۡلِيَآءَۗ قَلِيلٗا مَّا تَذَكَّرُونَ")
                }

                Section(header: Text("THE SUNNAH")) {
                    Text("The **Sunnah (السُّنَّة)** is the way of the Prophet (peace be upon him): his sayings, actions, and approvals, transmitted in the hadith. It is revelation too, for he did not speak the religion from himself:")
                        .font(.body)
                    ScriptureQuote(text: "“Nor does he speak from [his own] inclination. It is not but a revelation revealed” (Quran 53:3-4).", arabic: "وَمَا يَنطِقُ عَنِ ٱلۡهَوَىٰٓ ۝ إِنۡ هُوَ إِلَّا وَحۡيٞ يُوحَىٰ")

                    Text("Obeying him is obeying Allah, and his rulings are binding exactly like the Quran’s:")
                        .font(.body)
                    ScriptureQuote(text: "“He who obeys the Messenger has obeyed Allah” (Quran 4:80).", arabic: "مَّن يُطِعِ ٱلرَّسُولَ فَقَدۡ أَطَاعَ ٱللَّهَۖ")

                    ScriptureQuote(text: "“And whatever the Messenger has given you - take; and what he has forbidden you - refrain from” (Quran 59:7).", arabic: "وَمَآ ءَاتَىٰكُمُ ٱلرَّسُولُ فَخُذُوهُ وَمَا نَهَىٰكُمۡ عَنۡهُ فَٱنتَهُواْۚ وَٱتَّقُواْ ٱللَّهَۖ إِنَّ ٱللَّهَ شَدِيدُ ٱلۡعِقَابِ")

                    ScriptureQuote(text: "“But no, by your Lord, they will not [truly] believe until they make you, [O Muhammad], judge concerning that over which they dispute among themselves and then find within themselves no discomfort from what you have judged and submit in [full, willing] submission” (Quran 4:65).", arabic: "فَلَا وَرَبِّكَ لَا يُؤۡمِنُونَ حَتَّىٰ يُحَكِّمُوكَ فِيمَا شَجَرَ بَيۡنَهُمۡ ثُمَّ لَا يَجِدُواْ فِيٓ أَنفُسِهِمۡ حَرَجٗا مِّمَّا قَضَيۡتَ وَيُسَلِّمُواْ تَسۡلِيمٗا")

                    ScriptureQuote(text: "“It is not for a believing man or a believing woman, when Allah and His Messenger have decided a matter, that they should [thereafter] have any choice about their affair” (Quran 33:36).", arabic: "وَمَا كَانَ لِمُؤۡمِنٖ وَلَا مُؤۡمِنَةٍ إِذَا قَضَى ٱللَّهُ وَرَسُولُهُۥٓ أَمۡرًا أَن يَكُونَ لَهُمُ ٱلۡخِيَرَةُ مِنۡ أَمۡرِهِمۡۗ")

                    Text("The Sunnah explains the Quran. The Quran commands prayer, zakah, and Hajj; the Sunnah shows how to pray, how much to pay, and what to do at each station. Allah gave the Prophet (peace be upon him) that role:")
                        .font(.body)
                    ScriptureQuote(text: "“And We revealed to you the message that you may make clear to the people what was sent down to them” (Quran 16:44).", arabic: "وَأَنزَلۡنَآ إِلَيۡكَ ٱلذِّكۡرَ لِتُبَيِّنَ لِلنَّاسِ مَا نُزِّلَ إِلَيۡهِمۡ")

                    Text("The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“All of my nation will enter Paradise except those who refuse.” They said: O Messenger of Allah, and who refuses? He said: “Whoever obeys me enters Paradise, and whoever disobeys me has refused” (Sahih al-Bukhari 7280).", arabic: "كُلُّ أُمَّتِي يَدْخُلُونَ الْجَنَّةَ، إِلاَّ مَنْ أَبَى. قَالُوا يَا رَسُولَ اللَّهِ وَمَنْ يَأْبَى قَالَ مَنْ أَطَاعَنِي دَخَلَ الْجَنَّةَ، وَمَنْ عَصَانِي فَقَدْ أَبَى", dimmed: true)
                }

                Section(header: Text("THE TWO ARE NEVER SEPARATED")) {
                    Text("Anyone who says “the Quran is enough“ has rejected the Quran, because the Quran commands obedience to the Messenger in dozens of verses. And anyone who accepts hadith but reinterprets the Quran by opinion has left the Sunnah, because the Sunnah is the explanation of the Quran. The Prophet (peace be upon him) foretold both errors:")
                        .font(.body)
                    ScriptureQuote(text: "“Leave me as I leave you, for those before you were destroyed only by their questioning and their differing with their prophets. So when I forbid you something, avoid it, and when I command you something, do of it what you are able” (Sahih al-Bukhari 7288, Sahih Muslim 1337).", arabic: "دَعُونِي مَا تَرَكْتُكُمْ، إِنَّمَا هَلَكَ مَنْ كَانَ قَبْلَكُمْ بِسُؤَالِهِمْ وَاخْتِلاَفِهِمْ عَلَى أَنْبِيَائِهِمْ، فَإِذَا نَهَيْتُكُمْ عَنْ شَىْءٍ فَاجْتَنِبُوهُ، وَإِذَا أَمَرْتُكُمْ بِأَمْرٍ فَأْتُوا مِنْهُ مَا اسْتَطَعْتُمْ", dimmed: true)

                    Text("Allah tied the answer to every dispute to the two together:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you disagree over anything, refer it to Allah and the Messenger, if you should believe in Allah and the Last Day. That is the best [way] and best in result” (Quran 4:59).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ أَطِيعُواْ ٱللَّهَ وَأَطِيعُواْ ٱلرَّسُولَ وَأُوْلِي ٱلۡأَمۡرِ مِنكُمۡۖ فَإِن تَنَٰزَعۡتُمۡ فِي شَيۡءٖ فَرُدُّوهُ إِلَى ٱللَّهِ وَٱلرَّسُولِ")

                    Text("Referring to Allah is referring to His Book, and referring to the Messenger after his passing is referring to his Sunnah. Whoever has these two, understood as the Companions understood them, has the whole religion.")
                        .font(.body)
                }

                Section(header: Text("HOW A HADITH IS TRUSTED")) {
                    Text("The Sunnah was preserved through chains of narrators (**isnad**) examined man by man. A hadith is **sahih** (authentic) when every narrator is trustworthy and precise, the chain is connected, and the text has no hidden defect or contradiction of stronger reports; **hasan** (good) when slightly below that; **da‘if** (weak) when a condition fails; and **mawdu‘** (fabricated) when it is a lie. Only sahih and hasan reports are evidence. Every hadith quoted in these pages is from those two grades, with the collection and number given so that it can be checked.")
                        .font(.body)

                    ScriptureQuote(text: "“Whoever tells a lie against me intentionally, then (surely) let him occupy his seat in Hell-fire” (Sahih al-Bukhari 108).", arabic: "مَنْ تَعَمَّدَ عَلَىَّ كَذِبًا فَلْيَتَبَوَّأْ مَقْعَدَهُ مِنَ النَّارِ", dimmed: true)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Is the Sunnah revelation?**")
                        .font(.body)
                    Text("Yes. The verse quoted above says the Prophet (peace be upon him) does not speak from inclination (Quran 53:3-4), and he said so himself:")
                        .font(.body)
                    ScriptureQuote(text: "“Beware! I have been given the Book and something like it along with it” (Sunan Abi Dawud 4604; graded sahih by al-Albani).", arabic: "أَلاَ إِنِّي أُوتِيتُ الْكِتَابَ وَمِثْلَهُ مَعَهُ", dimmed: true)

                    Text("The Quran calls this second revelation “wisdom” and mentions it beside the Book:")
                        .font(.body)
                    ScriptureQuote(text: "“And Allah has revealed to you the Book and wisdom and has taught you that which you did not know” (Quran 4:113).", arabic: "وَأَنزَلَ ٱللَّهُ عَلَيۡكَ ٱلۡكِتَٰبَ وَٱلۡحِكۡمَةَ وَعَلَّمَكَ مَا لَمۡ تَكُن تَعۡلَمُۚ")

                    Text("Imam al-Shafi‘i (may Allah have mercy on him) wrote in ar-Risalah that the people of knowledge of the Quran whom he trusted said the “wisdom” here is the Sunnah of the Messenger of Allah; the same pairing of “the Book and wisdom” runs through the Quran (Quran 2:129, 33:34, 62:2). The difference between the two is in the wording, not in the authority: the Quran is the very words of Allah, recited and inimitable; the Sunnah is the meaning from Allah in the words of the Prophet (peace be upon him).")
                        .font(.body)

                    Text("**Can a Muslim follow the Quran alone?**")
                        .font(.body)
                    Text("No, because the Quran itself commands obedience to the Messenger, as the verses quoted above show (Quran 4:80, 59:7, 4:65, 16:44). Whoever drops the Sunnah has disobeyed the Quran. The Prophet (peace be upon him) foretold the very words such a person would use:")
                        .font(.body)
                    ScriptureQuote(text: "“A man full on his couch will soon say: Keep to this Quran; what you find in it as lawful, treat as lawful, and what you find in it as unlawful, treat as unlawful” (Sunan Abi Dawud 4604; graded sahih by al-Albani).", arabic: "يُوشِكُ رَجُلٌ شَبْعَانُ عَلَى أَرِيكَتِهِ يَقُولُ عَلَيْكُمْ بِهَذَا الْقُرْآنِ فَمَا وَجَدْتُمْ فِيهِ مِنْ حَلاَلٍ فَأَحِلُّوهُ وَمَا وَجَدْتُمْ فِيهِ مِنْ حَرَامٍ فَحَرِّمُوهُ", dimmed: true)

                    Text("A woman from Banu Asad once told Abdullah ibn Mas‘ud (may Allah be pleased with him) that she had read the whole Quran and not found in it the curse he narrated. The exchange is the Companions’ answer to the whole idea:")
                        .font(.body)
                    ScriptureQuote(text: "He said: “Why should I not curse those whom the Messenger of Allah (peace be upon him) cursed, and who are in the Book of Allah?” She said: I have read what is between the two covers and I did not find in it what you say. He said: “If you had read it, you would have found it. Have you not read: ‘And whatever the Messenger has given you - take; and what he has forbidden you - refrain from’?” (Sahih al-Bukhari 4886, Sahih Muslim 2125).", arabic: "وَمَا لِي لاَ أَلْعَنُ مَنْ لَعَنَ رَسُولُ اللَّهِ صلى الله عليه وسلم وَمَنْ هُوَ فِي كِتَابِ اللَّهِ فَقَالَتْ لَقَدْ قَرَأْتُ مَا بَيْنَ اللَّوْحَيْنِ فَمَا وَجَدْتُ فِيهِ مَا تَقُولُ. قَالَ لَئِنْ كُنْتِ قَرَأْتِيهِ لَقَدْ وَجَدْتِيهِ، أَمَا قَرَأْتِ وَمَا آتَاكُمُ الرَّسُولُ فَخُذُوهُ وَمَا نَهَاكُمْ عَنْهُ فَانْتَهُوا", dimmed: true)

                    Text("And in practice it cannot be done. The Quran commands prayer but does not give the number of its units, the words of its bowing and prostration, or its times in detail; it commands zakah but not the amounts and thresholds; it commands Hajj but not its rites station by station. All of that is in the Sunnah, and the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“And pray as you have seen me praying” (Sahih al-Bukhari 631).", arabic: "وَصَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي", dimmed: true)
                    ScriptureQuote(text: "“Take your rites [from me], for I do not know; perhaps I will not perform Hajj after this Hajj of mine” (Sahih Muslim 1297).", arabic: "لِتَأْخُذُوا مَنَاسِكَكُمْ فَإِنِّي لاَ أَدْرِي لَعَلِّي لاَ أَحُجُّ بَعْدَ حَجَّتِي هَذِهِ", dimmed: true)

                    Text("A “Quran-only” prayer does not exist.")
                        .font(.body)

                    Text("**How do we know a hadith is authentic?**")
                        .font(.body)
                    Text("By the isnad, the chain of narrators, examined man by man for honesty and precision, and by comparing the text with what the other reliable narrators transmitted. The Salaf treated this as part of the religion itself. Muhammad ibn Sirin (may Allah have mercy on him), the student of the Companions, said:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, this knowledge is religion, so look at whom you take your religion from” (Muqaddimah of Sahih Muslim 26).", arabic: "إِنَّ هَذَا الْعِلْمَ دِينٌ فَانْظُرُوا عَمَّنْ تَأْخُذُونَ دِينَكُمْ", dimmed: true)

                    Text("And Abdullah ibn al-Mubarak (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The isnad is part of the religion; were it not for the isnad, whoever wished would have said whatever he wished” (Muqaddimah of Sahih Muslim 32).", arabic: "الْإِسْنَادُ مِنَ الدِّينِ وَلَوْلَا الْإِسْنَادُ لَقَالَ مَنْ شَاءَ مَا شَاءَ", dimmed: true)

                    Text("The result is the grading described above: sahih, hasan, da‘if, mawdu‘. It is not guesswork; the biographies of many thousands of narrators, with their teachers, students, dates, and travels, were recorded and cross-checked, and a narrator found to lie in hadith was rejected.")
                        .font(.body)

                    Text("**Is a hadith narrated by a single chain (ahad) accepted in creed?**")
                        .font(.body)
                    Text("Yes, when it is authentic. The Prophet (peace be upon him) sent single Companions to teach entire peoples their creed, and the greatest matter of creed first of all:")
                        .font(.body)
                    ScriptureQuote(text: "The Prophet (peace be upon him) sent Mu‘adh to Yemen and said: “Call them to testify that none has the right to be worshipped but Allah and that I am the Messenger of Allah” (Sahih al-Bukhari 1395, Sahih Muslim 19).", arabic: "أَنَّ النَّبِيَّ صلى الله عليه وسلم بَعَثَ مُعَاذًا ـ رضى الله عنه ـ إِلَى الْيَمَنِ فَقَالَ ادْعُهُمْ إِلَى شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ، وَأَنِّي رَسُولُ اللَّهِ", dimmed: true)

                    Text("The Companions acted on a single man’s report in the middle of the prayer:")
                        .font(.body)
                    ScriptureQuote(text: "“While the people were at Quba’ in the Fajr prayer, someone came to them and said: Quran has been revealed to the Messenger of Allah (peace be upon him) tonight, and he has been commanded to face the Ka‘bah, so face it. Their faces were toward Sham, so they turned around to the Ka‘bah” (Sahih al-Bukhari 403).", arabic: "بَيْنَا النَّاسُ بِقُبَاءٍ فِي صَلاَةِ الصُّبْحِ إِذْ جَاءَهُمْ آتٍ فَقَالَ إِنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم قَدْ أُنْزِلَ عَلَيْهِ اللَّيْلَةَ قُرْآنٌ، وَقَدْ أُمِرَ أَنْ يَسْتَقْبِلَ الْكَعْبَةَ فَاسْتَقْبِلُوهَا، وَكَانَتْ وُجُوهُهُمْ إِلَى الشَّأْمِ، فَاسْتَدَارُوا إِلَى الْكَعْبَةِ", dimmed: true)

                    Text("Al-Bukhari gave this its own book in his Sahih, Kitab Akhbar al-Ahad, on accepting the report of a single truthful narrator in the adhan, the prayer, fasting, inheritance, and rulings. The Companions did not divide the Prophet’s words into what binds in action and what may be doubted in belief; whatever was established from him was believed and acted upon. That is the way of the Salaf, and the later distinction is an innovation of the people of kalam.")
                        .font(.body)

                    Text("**Can reason or taste override an authentic hadith?**")
                        .font(.body)
                    Text("No. The verses quoted above leave a believer no choice once Allah and His Messenger have decided (Quran 33:36, 4:65), and Allah warned:")
                        .font(.body)
                    ScriptureQuote(text: "“So let those beware who dissent from the Prophet's order, lest fitnah strike them or a painful punishment” (Quran 24:63).", arabic: "فَلۡيَحۡذَرِ ٱلَّذِينَ يُخَالِفُونَ عَنۡ أَمۡرِهِۦٓ أَن تُصِيبَهُمۡ فِتۡنَةٌ أَوۡ يُصِيبَهُمۡ عَذَابٌ أَلِيمٌ")

                    Text("Imam al-Shafi‘i (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The Muslims are agreed that whoever has a Sunnah of the Messenger of Allah (peace be upon him) made clear to him is not permitted to leave it for the saying of anyone” (Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "أَجْمَعَ الْمُسْلِمُونَ عَلَى أَنَّ مَنِ اسْتَبَانَ لَهُ سُنَّةٌ عَنْ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ لَمْ يَحِلَّ لَهُ أَنْ يَدَعَهَا لِقَوْلِ أَحَدٍ", dimmed: true)

                    Text("And Imam Ahmad (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever rejects a hadith of the Messenger of Allah (peace be upon him) is on the brink of destruction” (Ibn al-Jawzi, Manaqib al-Imam Ahmad).", arabic: "مَنْ رَدَّ حَدِيثَ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ فَهُوَ عَلَى شَفَا هَلَكَةٍ", dimmed: true)

                    Text("A hadith may be examined for authenticity, and its meaning may be understood in the light of other texts; that is scholarship. But “it does not suit my reason” or “it does not suit my taste” is not an argument against revelation; it is a description of the speaker.")
                        .font(.body)

                    Text("**Is the Quran preserved letter by letter?**")
                        .font(.body)
                    Text("Yes, as Allah promised in the verse quoted above (Quran 15:9). It was memorised by the Companions in the Prophet’s lifetime, written down as it came, and reviewed with Jibril every year:")
                        .font(.body)
                    ScriptureQuote(text: "“Jibril used to review the Quran with the Prophet (peace be upon him) once every year, and he reviewed it with him twice in the year in which he died” (Sahih al-Bukhari 4998).", arabic: "كَانَ يَعْرِضُ عَلَى النَّبِيِّ صلى الله عليه وسلم الْقُرْآنَ كُلَّ عَامٍ مَرَّةً، فَعَرَضَ عَلَيْهِ مَرَّتَيْنِ فِي الْعَامِ الَّذِي قُبِضَ", dimmed: true)

                    Text("After the Prophet’s death, Abu Bakr had it collected from the written pieces and the memories of the huffaz, with Zayd ibn Thabit (may Allah be pleased with them) in charge:")
                        .font(.body)
                    ScriptureQuote(text: "“So I searched out the Quran, collecting it from palm-leaf stalks, thin stones, and the breasts of men” (Sahih al-Bukhari 4986).", arabic: "فَتَتَبَّعْتُ الْقُرْآنَ أَجْمَعُهُ مِنَ الْعُسُبِ وَاللِّخَافِ وَصُدُورِ الرِّجَالِ", dimmed: true)

                    Text("Uthman (may Allah be pleased with him) then had that text copied and sent a copy to every region (Sahih al-Bukhari 4987), and every Quran in the world today is that text. The variant readings (qira’at) are not corruption; they are the modes (ahruf) in which it was revealed, each carried by unbroken chains back to the Prophet (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“Jibril recited to me upon one mode, and I kept asking him for more and he increased me, until he reached seven modes” (Sahih al-Bukhari 4991).", arabic: "أَقْرَأَنِي جِبْرِيلُ عَلَى حَرْفٍ فَرَاجَعْتُهُ، فَلَمْ أَزَلْ أَسْتَزِيدُهُ وَيَزِيدُنِي حَتَّى انْتَهَى إِلَى سَبْعَةِ أَحْرُفٍ", dimmed: true)

                    Text("When Umar heard Hisham ibn Hakim (may Allah be pleased with them) recite Surat al-Furqan differently from how he had learnt it, the Prophet (peace be upon him) heard both and said of each, “thus it was revealed,” and told them the Quran was revealed upon seven modes (Sahih Muslim 818).")
                        .font(.body)

                    Text("**What is abrogation (naskh)?**")
                        .font(.body)
                    Text("Abrogation is Allah replacing one ruling with a later one, by His knowledge and wisdom, the way a physician changes the dose as the patient grows. He announced it in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“We do not abrogate a verse or cause it to be forgotten except that We bring forth [one] better than it or similar to it. Do you not know that Allah is over all things competent?” (Quran 2:106).", arabic: "مَا نَنسَخۡ مِنۡ ءَايَةٍ أَوۡ نُنسِهَا نَأۡتِ بِخَيۡرٖ مِّنۡهَآ أَوۡ مِثۡلِهَآۗ أَلَمۡ تَعۡلَمۡ أَنَّ ٱللَّهَ عَلَىٰ كُلِّ شَيۡءٖ قَدِيرٌ")

                    Text("The qiblah was changed from Jerusalem to the Ka‘bah (Quran 2:144), and the Prophet (peace be upon him) abrogated some of his own earlier rulings:")
                        .font(.body)
                    ScriptureQuote(text: "“I had forbidden you from visiting graves, but visit them” (Sahih Muslim 977).", arabic: "نَهَيْتُكُمْ عَنْ زِيَارَةِ الْقُبُورِ فَزُورُوهَا", dimmed: true)

                    Text("Three rules keep it in its place. Only revelation abrogates revelation: no scholar, ruler, or age abrogates anything. Abrogation is known only by a text or by the report of the Companions, never by someone deciding that a ruling is out of date. And abrogation ended with the Prophet’s death, because revelation ended with it.")
                        .font(.body)

                    Text("**What is a hadith qudsi, and how does it differ from the Quran?**")
                        .font(.body)
                    Text("A **hadith qudsi (حَدِيث قُدْسِي)** is a report in which the Prophet (peace be upon him) relates words from his Lord, such as:")
                        .font(.body)
                    ScriptureQuote(text: "“O My servants, I have forbidden oppression for Myself and have made it forbidden among you, so do not oppress one another” (Sahih Muslim 2577).", arabic: "يَا عِبَادِي إِنِّي حَرَّمْتُ الظُّلْمَ عَلَى نَفْسِي وَجَعَلْتُهُ بَيْنَكُمْ مُحَرَّمًا فَلاَ تَظَالَمُوا", dimmed: true)

                    Text("Its meaning is from Allah and it is attributed to Him, but it is not Quran. The Quran is the very words of Allah, transmitted by mass narration with no doubt in a single letter, recited in prayer, a miracle in its wording, and not to be touched without purification. A hadith qudsi is transmitted like any other hadith, through an isnad that is graded sahih, hasan, or weak; it is not recited in prayer and carries no claim of inimitable wording. So the Quran is in a class by itself, and a hadith qudsi is in the class of the Sunnah.")
                        .font(.body)

                    Text("**What is the punishment for fabricating hadith?**")
                        .font(.body)
                    Text("A seat in the Fire. The threat quoted above, that whoever lies upon the Prophet (peace be upon him) intentionally should take his seat in the Fire (Sahih al-Bukhari 108), was narrated by so many Companions that the scholars count it mutawatir. And he (peace be upon him) extended it to whoever passes a lie on:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever narrates a hadith from me thinking it to be false, then he is one of the two liars” (Sunan Ibn Majah 38; graded sahih by al-Albani).", arabic: "مَنْ حَدَّثَ عَنِّي حَدِيثًا وَهُوَ يُرَى أَنَّهُ كَذِبٌ فَهُوَ أَحَدُ الْكَاذِبَيْنِ", dimmed: true)

                    Text("Lying about him is worse than lying about anyone else, because it is a lie about the religion of Allah that misleads everyone who hears it. This is why the scholars of hadith named the fabricators openly in the books of weak narrators, and why the Salaf considered exposing a liar in hadith an act of sincere advice to the Muslims, not backbiting.")
                        .font(.body)

                    Text("**Do the grades (sahih, hasan, da‘if, mawdu‘) mean the Sunnah is uncertain?**")
                        .font(.body)
                    Text("No; they mean the opposite. The grades exist because the Muslims refused to accept anything about their Prophet without proof. Allah commanded that very care:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, if there comes to you a disobedient one with information, investigate” (Quran 49:6).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ إِن جَآءَكُمۡ فَاسِقُۢ بِنَبَإٖ فَتَبَيَّنُوٓاْ")

                    Text("Muhammad ibn Sirin (may Allah have mercy on him) described how the isnad became the standard:")
                        .font(.body)
                    ScriptureQuote(text: "“They did not use to ask about the isnad; but when the fitnah occurred they said: Name your men to us. So the people of the Sunnah were looked at and their hadith was taken, and the people of innovation were looked at and their hadith was not taken” (Muqaddimah of Sahih Muslim 27).", arabic: "لَمْ يَكُونُوا يَسْأَلُونَ عَنِ الْإِسْنَادِ، فَلَمَّا وَقَعَتِ الْفِتْنَةُ قَالُوا سَمُّوا لَنَا رِجَالَكُمْ، فَيُنْظَرُ إِلَى أَهْلِ السُّنَّةِ فَيُؤْخَذُ حَدِيثُهُمْ، وَيُنْظَرُ إِلَى أَهْلِ الْبِدَعِ فَلَا يُؤْخَذُ حَدِيثُهُمْ", dimmed: true)

                    Text("No other nation can trace the words of its prophet man by man back to his mouth; Ibn Hazm wrote that the transmission of a trustworthy narrator from a trustworthy narrator, connected all the way to the Prophet (peace be upon him), is something Allah gave to the Muslims alone among all the religions (al-Fisal), and as-Suyuti gathered such statements in Tadrib ar-Rawi. A weak hadith is not “the Sunnah being uncertain”; it is the Sunnah being guarded, a report that failed the test and was set aside so that what passed could be trusted completely. The authentic Sunnah, preserved through this science, is as certain as the religion itself.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Two sources, both revelation, both binding: the Book of Allah and the Sunnah of His Messenger. Whatever agrees with them is accepted, and whatever contradicts them is rejected, whoever said it.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Quran and Sunnah")
        .selectableArticleList()
    }
}

struct ShirkView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: shirk is giving any of Allah's rights to other than Him. It is the one sin Allah does not forgive if a person dies upon it, and the opposite of the tawhid every prophet called to.")
                        .font(.body)
                }

                Section(header: Text("WHAT IS SHIRK?")) {
                    Text("**Shirk (شِرك)** means “association“: making a partner (**sharik**) for Allah in what belongs only to Him. Its opposite is **tawhid (تَوحِيد)**, singling Allah out. Tawhid has three parts, and shirk can enter each:")
                        .font(.body)

                    Text("• **In lordship (rububiyyah)**: believing that anyone besides Allah creates, provides, or controls the universe.")
                        .font(.body)
                    Text("• **In worship (uluhiyyah)**: directing any act of worship to other than Allah: supplication, sacrifice, vows, prostration, fear, hope, reliance, seeking help from the dead or absent in what only Allah can do.")
                        .font(.body)
                    Text("• **In names and attributes**: giving creation what belongs to Allah alone, such as knowledge of the unseen, or giving Allah the qualities of creation.")
                        .font(.body)

                    Text("The pagans of Makkah already believed Allah was the Creator; their shirk was in worship, praying to others so that they would bring them near to Him:")
                        .font(.body)
                    ScriptureQuote(text: "“And those who take protectors besides Him [say], ‘We only worship them that they may bring us nearer to Allah in position.’ Indeed, Allah will judge between them concerning that over which they differ. Indeed, Allah does not guide he who is a liar and [confirmed] disbeliever” (Quran 39:3).", arabic: "وَٱلَّذِينَ ٱتَّخَذُواْ مِن دُونِهِۦٓ أَوۡلِيَآءَ مَا نَعۡبُدُهُمۡ إِلَّا لِيُقَرِّبُونَآ إِلَى ٱللَّهِ زُلۡفَىٰٓ إِنَّ ٱللَّهَ يَحۡكُمُ بَيۡنَهُمۡ فِي مَا هُمۡ فِيهِ يَخۡتَلِفُونَۗ إِنَّ ٱللَّهَ لَا يَهۡدِي مَنۡ هُوَ كَٰذِبٞ كَفَّارٞ")

                    ScriptureQuote(text: "“And if you asked them, ‘Who created the heavens and earth?’ they would surely say, ‘Allah.’ Say, ‘[All] praise is [due] to Allah’; but most of them do not know” (Quran 31:25).", arabic: "وَلَئِن سَأَلۡتَهُم مَّنۡ خَلَقَ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ لَيَقُولُنَّ ٱللَّهُۚ قُلِ ٱلۡحَمۡدُ لِلَّهِۚ بَلۡ أَكۡثَرُهُمۡ لَا يَعۡلَمُونَ")
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Shirk (شِرك)**: from the root ش-ر-ك, sharika, “to share, to be a partner.” The one who does it is a **mushrik (مُشرِك)**, and what he sets up beside Allah is a **sharik (شَرِيك)**, a partner, or a **nidd (نِدّ)**, a rival. Allah forbade it immediately after the first command in the Quran, to worship Him alone (2:21):")
                        .font(.body)
                    ScriptureQuote(text: "“So do not attribute to Allah equals while you know [that there is nothing similar to Him]” (Quran 2:22).", arabic: "فَلَا تَجۡعَلُواْ لِلَّهِ أَندَادٗا وَأَنتُمۡ تَعۡلَمُونَ")

                    Text("**Tawhid (تَوحِيد)**: the verbal noun of wahhada, “to make one, to single out.” It was the message of every messenger before any other matter:")
                        .font(.body)
                    ScriptureQuote(text: "“And We sent not before you any messenger except that We revealed to him that, ‘There is no deity except Me, so worship Me’” (Quran 21:25).", arabic: "وَمَآ أَرۡسَلۡنَا مِن قَبۡلِكَ مِن رَّسُولٍ إِلَّا نُوحِيٓ إِلَيۡهِ أَنَّهُۥ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعۡبُدُونِ")

                    Text("**Ilah (إِلَه)**: “the one worshipped,” from aliha, “to turn to in devotion, love, and need.” An ilah is whatever hearts take as an object of worship, rightly or wrongly. So the testimony **la ilaha illallah** does not mean only “there is no creator but Allah” (the pagans admitted that) but “there is nothing rightly worshipped except Allah”:")
                        .font(.body)
                    ScriptureQuote(text: "“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).", arabic: "وَإِلَٰهُكُمۡ إِلَٰهٞ وَٰحِدٞۖ لَّآ إِلَٰهَ إِلَّا هُوَ ٱلرَّحۡمَٰنُ ٱلرَّحِيمُ")

                    Text("**Ibadah (عِبَادَة)**: worship, from the root ع-ب-د, which carries the meanings of lowliness and submission; an **‘abd** is a slave. In the religion it is submission to Allah with the utmost love and humility. Ibn Taymiyyah (may Allah have mercy on him) gave the definition the scholars have relied on since:")
                        .font(.body)
                    ScriptureQuote(text: "“Worship is a comprehensive term for everything Allah loves and is pleased with, of words and deeds, inward and outward” (Ibn Taymiyyah, al-Ubudiyyah).", arabic: "الْعِبَادَةُ هِيَ اسْمٌ جَامِعٌ لِكُلِّ مَا يُحِبُّهُ اللَّهُ وَيَرْضَاهُ مِنَ الْأَقْوَالِ وَالْأَعْمَالِ الْبَاطِنَةِ وَالظَّاهِرَةِ", dimmed: true)
                    Text("So prayer, sacrifice, vows, supplication, fear, hope, reliance, love, and seeking help are all worship, and directing any of them to other than Allah is shirk.")
                        .font(.body)

                    Text("**Du‘a (دُعَاء)**: “calling”: asking Allah for what one needs, and calling upon Him in praise. It is the heart of worship. An-Nu‘man ibn Bashir (may Allah be pleased with him) narrated that the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Supplication is itself the worship.” Then he recited: “Your Lord said: Call upon Me; I will respond to you” (Sunan Abi Dawud 1479; graded sahih by al-Albani).", arabic: "الدُّعَاءُ هُوَ الْعِبَادَةُ قَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ", dimmed: true)
                    ScriptureQuote(text: "“And your Lord says, ‘Call upon Me; I will respond to you.’ Indeed, those who disdain My worship will enter Hell [rendered] contemptible” (Quran 40:60).", arabic: "وَقَالَ رَبُّكُمُ ٱدۡعُونِيٓ أَسۡتَجِبۡ لَكُمۡۚ إِنَّ ٱلَّذِينَ يَسۡتَكۡبِرُونَ عَنۡ عِبَادَتِي سَيَدۡخُلُونَ جَهَنَّمَ دَاخِرِينَ")
                    Text("Because du‘a is worship, calling upon other than Allah in what only He can do is the clearest form of shirk.")
                        .font(.body)

                    Text("**Tawassul (تَوَسُّل)**: from wasilah, “a means of nearness.” Allah commanded it:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, fear Allah and seek the means [of nearness] to Him and strive in His cause that you may succeed” (Quran 5:35).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ ٱتَّقُواْ ٱللَّهَ وَٱبۡتَغُوٓاْ إِلَيۡهِ ٱلۡوَسِيلَةَ وَجَٰهِدُواْ فِي سَبِيلِهِۦ لَعَلَّكُمۡ تُفۡلِحُونَ")
                    Text("The Salaf understood the means to be faith and righteous deeds. The Sunnah shows three permitted kinds. First, by Allah’s names and attributes:")
                        .font(.body)
                    ScriptureQuote(text: "“And to Allah belong the best names, so invoke Him by them. And leave [the company of] those who practice deviation concerning His names” (Quran 7:180).", arabic: "وَلِلَّهِ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰ فَٱدۡعُوهُ بِهَاۖ وَذَرُواْ ٱلَّذِينَ يُلۡحِدُونَ فِيٓ أَسۡمَٰٓئِهِۦۚ")
                    Text("Second, by one’s own righteous deeds, as the three men trapped in the cave did. They said to one another:")
                        .font(.body)
                    ScriptureQuote(text: "“Nothing could save you from this rock but to invoke Allah by giving reference to the righteous deeds which you have done” (Sahih al-Bukhari 2272).", arabic: "إِنَّهُ لاَ يُنْجِيكُمْ مِنْ هَذِهِ الصَّخْرَةِ إِلاَّ أَنْ تَدْعُوا اللَّهَ بِصَالِحِ أَعْمَالِكُمْ", dimmed: true)
                    Text("Third, by the du‘a of a living righteous person. When drought struck, Umar (may Allah be pleased with him) did not go to the Prophet’s grave but asked his uncle al-Abbas to pray:")
                        .font(.body)
                    ScriptureQuote(text: "“O Allah! We used to ask our Prophet to invoke You for rain, and You would bless us with rain, and now we ask his uncle to invoke You for rain. O Allah, bless us with rain.” And so it would rain (Sahih al-Bukhari 1010).", arabic: "اللَّهُمَّ إِنَّا كُنَّا نَتَوَسَّلُ إِلَيْكَ بِنَبِيِّنَا فَتَسْقِينَا وَإِنَّا نَتَوَسَّلُ إِلَيْكَ بِعَمِّ نَبِيِّنَا فَاسْقِنَا. قَالَ فَيُسْقَوْنَ", dimmed: true)
                    Text("Ibn Taymiyyah set out these kinds in Qa‘idah Jalilah fi at-Tawassul wal-Wasilah, and al-Albani in at-Tawassul: Anwa‘uhu wa Ahkamuhu. Tawassul by the person, status, or “right” of someone dead is not found in the practice of the Companions, and calling on the dead themselves is shirk.")
                        .font(.body)

                    Text("**Istighathah (اِستِغَاثَة)**: seeking rescue (**ghawth**) from hardship. From Allah it is worship:")
                        .font(.body)
                    ScriptureQuote(text: "“[Remember] when you asked help of your Lord, and He answered you” (Quran 8:9).", arabic: "إِذۡ تَسۡتَغِيثُونَ رَبَّكُمۡ فَٱسۡتَجَابَ لَكُمۡ")
                    Text("Asking a living, present person for help in what he is able to do is ordinary and permitted, as the man of Musa’s people called to him for help (Quran 28:15). But seeking rescue from the dead or the absent, in what only Allah has power over, is major shirk:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not invoke besides Allah that which neither benefits you nor harms you, for if you did, then indeed you would be of the wrongdoers” (Quran 10:106).", arabic: "وَلَا تَدۡعُ مِن دُونِ ٱللَّهِ مَا لَا يَنفَعُكَ وَلَا يَضُرُّكَۖ فَإِن فَعَلۡتَ فَإِنَّكَ إِذٗا مِّنَ ٱلظَّٰلِمِينَ")

                    Text("**Shafa‘ah (شَفَاعَة)**: intercession, from shaf‘, “a pair”: joining one’s request to another’s. It belongs to Allah alone, and no one intercedes except by His permission and for whom He is pleased with:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘To Allah belongs [the right to allow] intercession entirely. To Him belongs the dominion of the heavens and the earth. Then to Him you will be returned’” (Quran 39:44).", arabic: "قُل لِّلَّهِ ٱلشَّفَٰعَةُ جَمِيعٗاۖ لَّهُۥ مُلۡكُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ ثُمَّ إِلَيۡهِ تُرۡجَعُونَ")
                    ScriptureQuote(text: "“Who is it that can intercede with Him except by His permission?” (Quran 2:255).", arabic: "مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ")
                    Text("The Prophet (peace be upon him) will intercede on the Day of Resurrection, and the way to his intercession is tawhid:")
                        .font(.body)
                    ScriptureQuote(text: "“The luckiest person who will have my intercession on the Day of Resurrection will be the one who said sincerely from the bottom of his heart ‘None has the right to be worshipped but Allah’” (Sahih al-Bukhari 99).", arabic: "أَسْعَدُ النَّاسِ بِشَفَاعَتِي يَوْمَ الْقِيَامَةِ مَنْ قَالَ لاَ إِلَهَ إِلاَّ اللَّهُ، خَالِصًا مِنْ قَلْبِهِ أَوْ نَفْسِهِ", dimmed: true)
                    Text("So intercession is asked from Allah (“O Allah, grant me the intercession of Your Prophet”), not from the dead. The pagans of Makkah were condemned precisely for taking their idols as intercessors (Quran 10:18, 39:3).")
                        .font(.body)

                    Text("**Tabarruk (تَبَرُّك)**: seeking blessing (**barakah**) from something. The Companions sought blessing from the Prophet’s body and its traces in his lifetime: his hair, his sweat, and the water left from his wudu (Sahih al-Bukhari 187, Sahih Muslim 2331):")
                        .font(.body)
                    ScriptureQuote(text: "“When Allah’s Messenger (peace be upon him) got his head shaved, Abu Talhah was the first to take some of his hair” (Sahih al-Bukhari 171).", arabic: "أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم لَمَّا حَلَقَ رَأْسَهُ كَانَ أَبُو طَلْحَةَ أَوَّلَ مَنْ أَخَذَ مِنْ شَعَرِهِ", dimmed: true)
                    Text("This was specific to him (peace be upon him): the Companions did not do it with Abu Bakr, Umar, or any of the best of the ummah after him, as ash-Shatibi pointed out in al-I‘tisam. Blessing is also sought from what the texts made blessed, such as the Quran, Zamzam water, and the places and times Allah honoured, in the way the Sunnah shows. Seeking blessing from graves, stones, trees, or the persons of shaykhs has no basis and is the road to shirk.")
                        .font(.body)

                    Text("**Tamimah (تَمِيمَة)**: an amulet, from tamma, “to complete,” because the people of jahiliyyah believed it completed their protection. Hanging it in the belief that it repels harm by itself is major shirk; hanging it as a supposed means is minor shirk. Uqbah ibn Amir (may Allah be pleased with him) narrated that the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever hangs an amulet has committed shirk” (Musnad Ahmad 17422; graded sahih by al-Albani).", arabic: "مَنْ تَعَلَّقَ تَمِيمَةً فَقَدْ أَشْرَكَ", dimmed: true)

                    Text("**Ruqyah (رُقيَة)**: an incantation recited over the sick. It is permitted, and Sunnah, when it is with the Quran, the names of Allah, and the du‘as of the Prophet, and contains no shirk. Awf ibn Malik (may Allah be pleased with him) said: We used to practise ruqyah in jahiliyyah, so we asked the Messenger of Allah about it. He said:")
                        .font(.body)
                    ScriptureQuote(text: "“Show me your incantations. There is no harm in incantations as long as there is no shirk in them” (Sahih Muslim 2200).", arabic: "اعْرِضُوا عَلَىَّ رُقَاكُمْ لاَ بَأْسَ بِالرُّقَى مَا لَمْ يَكُنْ فِيهِ شِرْكٌ", dimmed: true)

                    Text("**Taghut (طَاغُوت)**: from tagha, “to exceed the bounds.” Rejecting it is the negation in the shahadah, la ilaha, and belief in Allah is its affirmation, illallah:")
                        .font(.body)
                    ScriptureQuote(text: "“So whoever disbelieves in Taghut and believes in Allah has grasped the most trustworthy handhold with no break in it” (Quran 2:256).", arabic: "فَمَن يَكۡفُرۡ بِٱلطَّٰغُوتِ وَيُؤۡمِنۢ بِٱللَّهِ فَقَدِ ٱسۡتَمۡسَكَ بِٱلۡعُرۡوَةِ ٱلۡوُثۡقَىٰ لَا ٱنفِصَامَ لَهَاۗ")
                    Text("Ibn al-Qayyim (may Allah have mercy on him) defined it in I‘lam al-Muwaqqi‘in:")
                        .font(.body)
                    ScriptureQuote(text: "“The taghut is everything by which the servant exceeds his limit, whether something worshipped, followed, or obeyed” (Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "الطَّاغُوتُ كُلُّ مَا تَجَاوَزَ بِهِ الْعَبْدُ حَدَّهُ مِنْ مَعْبُودٍ أَوْ مَتْبُوعٍ أَوْ مُطَاعٍ", dimmed: true)
                    Text("He went on to say that the taghut of any people is whoever they take their disputes to instead of Allah and His Messenger, worship instead of Allah, follow without insight from Allah, or obey in what they do not know to be obedience to Allah. Muhammad ibn Abd al-Wahhab (may Allah have mercy on him) summarised its heads as five at the end of al-Usul ath-Thalathah: Iblis; whoever is worshipped and is pleased with it; whoever calls people to worship him; whoever claims any knowledge of the unseen; and whoever judges by other than what Allah revealed.")
                        .font(.body)
                    Text("On the last of these the scholars draw a distinction that must be kept. Ibn Abbas (may Allah be pleased with them) explained the disbelief mentioned in 5:44 as “disbelief less than disbelief” (reported by al-Hakim in al-Mustadrak): it is major kufr when a person holds his own judgement to be lawful in place of Allah’s or better than it, and a lesser kufr when he judges by desire while acknowledging that Allah’s ruling is the truth. Ibn Baz and Ibn al-Uthaymin (may Allah have mercy on them) explained it in this way, and the ruling on any particular person belongs to the people of knowledge, not to individuals.")
                        .font(.body)

                    Text("**Nadhr (نَذر)** is a vow, and **dhabh (ذَبح)** is slaughter. Both are worship, so both are for Allah alone:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever vows that he will be obedient to Allah, should remain obedient to Him; and whoever made a vow that he will disobey Allah, should not disobey Him” (Sahih al-Bukhari 6696).", arabic: "مَنْ نَذَرَ أَنْ يُطِيعَ اللَّهَ فَلْيُطِعْهُ، وَمَنْ نَذَرَ أَنْ يَعْصِيَهُ فَلاَ يَعْصِهِ", dimmed: true)
                    ScriptureQuote(text: "“Allah cursed him who sacrificed for anyone besides Allah” (Sahih Muslim 1978).", arabic: "لَعَنَ اللَّهُ مَنْ ذَبَحَ لِغَيْرِ اللَّهِ", dimmed: true)
                    Text("When a man vowed to slaughter camels at a place called Buwanah, the Prophet (peace be upon him) first asked:")
                        .font(.body)
                    ScriptureQuote(text: "“Did the place contain any idol of the idols of jahiliyyah that was worshipped?” They said: No. He asked: “Was any of their festivals observed there?” They said: No. He said: “Fulfil your vow, for a vow to do an act of disobedience to Allah must not be fulfilled, nor one in what the son of Adam does not own” (Sunan Abi Dawud 3313; graded sahih by al-Albani).", arabic: "هَلْ كَانَ فِيهَا وَثَنٌ مِنْ أَوْثَانِ الْجَاهِلِيَّةِ يُعْبَدُ. قَالُوا : لاَ. قَالَ : هَلْ كَانَ فِيهَا عِيدٌ مِنْ أَعْيَادِهِمْ. قَالُوا : لاَ. قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم : أَوْفِ بِنَذْرِكَ، فَإِنَّهُ لاَ وَفَاءَ لِنَذْرٍ فِي مَعْصِيَةِ اللَّهِ وَلاَ فِيمَا لاَ يَمْلِكُ ابْنُ آدَمَ", dimmed: true)
                    Text("Vowing or slaughtering for a saint, a grave, or a jinn is major shirk, even if the name of Allah is pronounced over the animal.")
                        .font(.body)

                    Text("**Riya’ (رِيَاء)**: from ru’yah, “seeing”: doing an act of worship so that people see it. It is minor shirk that nullifies the deed it enters. In a hadith qudsi Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“I am the One most free of need of partners. Whoever does a deed in which he associates anyone else with Me, I abandon him and his shirk” (Sahih Muslim 2985).", arabic: "أَنَا أَغْنَى الشُّرَكَاءِ عَنِ الشِّرْكِ مَنْ عَمِلَ عَمَلاً أَشْرَكَ فِيهِ مَعِي غَيْرِي تَرَكْتُهُ وَشِرْكَهُ", dimmed: true)
                    ScriptureQuote(text: "“Shall I not tell you of that which I fear more for you than the Dajjal?” We said: Yes. He said: “Hidden shirk: a man stands to pray and beautifies his prayer because he sees a man looking at him” (Sunan Ibn Majah 4204; graded hasan by al-Albani).", arabic: "أَلاَ أُخْبِرُكُمْ بِمَا هُوَ أَخْوَفُ عَلَيْكُمْ عِنْدِي مِنَ الْمَسِيحِ الدَّجَّالِ. قَالَ قُلْنَا بَلَى. فَقَالَ الشِّرْكُ الْخَفِيُّ أَنْ يَقُومَ الرَّجُلُ يُصَلِّي فَيُزَيِّنُ صَلاَتَهُ لِمَا يَرَى مِنْ نَظَرِ رَجُلٍ", dimmed: true)

                    Text("**Jahiliyyah (جَاهِلِيَّة)**: “the state of ignorance”: the condition of the Arabs before the Prophet (peace be upon him), and every state that resembles it in creed, judgement, or conduct. The Quran uses the word four times: the thought of jahiliyyah (3:154), the judgement of jahiliyyah (5:50), the display of jahiliyyah (33:33), and the zealotry of jahiliyyah (48:26):")
                        .font(.body)
                    ScriptureQuote(text: "“Then is it the judgement of [the time of] ignorance they desire? But who is better than Allah in judgement for a people who are certain [in faith]” (Quran 5:50).", arabic: "أَفَحُكۡمَ ٱلۡجَٰهِلِيَّةِ يَبۡغُونَۚ وَمَنۡ أَحۡسَنُ مِنَ ٱللَّهِ حُكۡمٗا لِّقَوۡمٖ يُوقِنُونَ")

                    Text("**Wathan (وَثَن)** and **sanam (صَنَم)**: idols. A sanam is an image carved in a form; a wathan is anything set up to be worshipped, whether an image, a stone, or a grave. Ibrahim (peace be upon him) feared idolatry for himself and his sons:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention, O Muhammad], when Abraham said, ‘My Lord, make this city [Mecca] secure and keep me and my sons away from worshipping idols’” (Quran 14:35).", arabic: "وَإِذۡ قَالَ إِبۡرَٰهِيمُ رَبِّ ٱجۡعَلۡ هَٰذَا ٱلۡبَلَدَ ءَامِنٗا وَٱجۡنُبۡنِي وَبَنِيَّ أَن نَّعۡبُدَ ٱلۡأَصۡنَامَ")
                    ScriptureQuote(text: "“So avoid the uncleanliness of idols and avoid false statement” (Quran 22:30).", arabic: "فَٱجۡتَنِبُواْ ٱلرِّجۡسَ مِنَ ٱلۡأَوۡثَٰنِ وَٱجۡتَنِبُواْ قَوۡلَ ٱلزُّورِ")

                    Text("**Wali (وَلِيّ)**, plural **awliya’ (أَولِيَاء)**: from wala’, closeness and support. The awliya’ of Allah are not a class of miracle-workers; Allah defined them Himself:")
                        .font(.body)
                    ScriptureQuote(text: "“Unquestionably, [for] the allies of Allah there will be no fear concerning them, nor will they grieve. Those who believed and were fearing Allah” (Quran 10:62-63).", arabic: "أَلَآ إِنَّ أَوۡلِيَآءَ ٱللَّهِ لَا خَوۡفٌ عَلَيۡهِمۡ وَلَا هُمۡ يَحۡزَنُونَ ۝ ٱلَّذِينَ ءَامَنُواْ وَكَانُواْ يَتَّقُونَ")
                    ScriptureQuote(text: "“Allah said: ‘I will declare war against him who shows hostility to a wali (pious worshipper) of Mine’” (Sahih al-Bukhari 6502).", arabic: "إِنَّ اللَّهَ قَالَ مَنْ عَادَى لِي وَلِيًّا فَقَدْ آذَنْتُهُ بِالْحَرْبِ", dimmed: true)
                    Text("So every pious believer is a wali of Allah, in proportion to his faith and piety, as Ibn Taymiyyah explained in al-Furqan bayna Awliya’ ar-Rahman wa Awliya’ ash-Shaytan. Loving them is faith; worshipping them, calling on them, or believing they control the universe is shirk, and they are the first to disown it (Quran 46:6).")
                        .font(.body)

                    Text("**Shirk akbar (الشِّرك الأَكبَر)**, major shirk, takes a person out of Islam and is not forgiven if he dies upon it. **Shirk asghar (الشِّرك الأَصغَر)**, minor shirk, does not take one out of Islam, yet it is graver than the major sins. **Shirk khafi (الشِّرك الخَفِيّ)**, hidden shirk, is the name the Prophet (peace be upon him) gave to riya’ because it creeps into the heart unnoticed. The forms of each are set out below.")
                        .font(.body)
                }

                Section(header: Text("THE GRAVEST OF ALL SINS")) {
                    ScriptureQuote(text: "“Indeed, Allah does not forgive association with Him, but He forgives what is less than that for whom He wills. And he who associates others with Allah has certainly fabricated a tremendous sin” (Quran 4:48).", arabic: "إِنَّ ٱللَّهَ لَا يَغۡفِرُ أَن يُشۡرَكَ بِهِۦ وَيَغۡفِرُ مَا دُونَ ذَٰلِكَ لِمَن يَشَآءُۚ وَمَن يُشۡرِكۡ بِٱللَّهِ فَقَدِ ٱفۡتَرَىٰٓ إِثۡمًا عَظِيمًا")

                    ScriptureQuote(text: "“And [mention, O Muhammad], when Luqman said to his son while he was instructing him, ‘O my son, do not associate [anything] with Allah. Indeed, association [with him] is great injustice’” (Quran 31:13).", arabic: "وَإِذۡ قَالَ لُقۡمَٰنُ لِٱبۡنِهِۦ وَهُوَ يَعِظُهُۥ يَٰبُنَيَّ لَا تُشۡرِكۡ بِٱللَّهِۖ إِنَّ ٱلشِّرۡكَ لَظُلۡمٌ عَظِيمٞ")

                    ScriptureQuote(text: "“Indeed, he who associates others with Allah - Allah has forbidden him Paradise, and his refuge is the Fire. And there are not for the wrongdoers any helpers” (Quran 5:72).", arabic: "إِنَّهُۥ مَن يُشۡرِكۡ بِٱللَّهِ فَقَدۡ حَرَّمَ ٱللَّهُ عَلَيۡهِ ٱلۡجَنَّةَ وَمَأۡوَىٰهُ ٱلنَّارُۖ وَمَا لِلظَّٰلِمِينَ مِنۡ أَنصَارٖ")

                    ScriptureQuote(text: "“And it was already revealed to you and to those before you that if you should associate [anything] with Allah, your work would surely become worthless, and you would surely be among the losers” (Quran 39:65).", arabic: "وَلَقَدۡ أُوحِيَ إِلَيۡكَ وَإِلَى ٱلَّذِينَ مِن قَبۡلِكَ لَئِنۡ أَشۡرَكۡتَ لَيَحۡبَطَنَّ عَمَلُكَ وَلَتَكُونَنَّ مِنَ ٱلۡخَٰسِرِينَ")

                    Text("Ibn Mas‘ud (may Allah be pleased with him) asked the Prophet (peace be upon him) which sin is the greatest in the sight of Allah. He said:")
                        .font(.body)
                    ScriptureQuote(text: "“That you set up a rival to Allah while He created you” (Sahih al-Bukhari 4477).", arabic: "أَنْ تَجْعَلَ لِلَّهِ نِدًّا وَهْوَ خَلَقَكَ", dimmed: true)

                    ScriptureQuote(text: "“Whoever dies while invoking anything besides Allah as a rival to Him enters the Fire” (Sahih al-Bukhari 4497).", arabic: "مَنْ مَاتَ وَهْوَ يَدْعُو مِنْ دُونِ اللَّهِ نِدًّا دَخَلَ النَّارَ", dimmed: true)

                    Text("And Jabir (may Allah be pleased with him) narrated:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever meets Allah not associating anything with Him enters Paradise, and whoever meets Him associating anything with Him enters the Fire” (Sahih Muslim 93).", arabic: "مَنْ مَاتَ لاَ يُشْرِكُ بِاللَّهِ شَيْئًا دَخَلَ الْجَنَّةَ وَمَنْ مَاتَ يُشْرِكُ بِاللَّهِ شَيْئًا دَخَلَ النَّارَ", dimmed: true)
                }

                Section(header: Text("THE RIGHT OF ALLAH")) {
                    Text("Mu‘adh ibn Jabal (may Allah be pleased with him) was riding behind the Prophet (peace be upon him) when he asked him:")
                        .font(.body)
                    ScriptureQuote(text: "“O Mu‘adh, do you know what is the right of Allah upon His servants, and what is the right of the servants upon Allah?” I said: Allah and His Messenger know best. He said: “The right of Allah upon His servants is that they worship Him and do not associate anything with Him, and the right of the servants upon Allah is that He does not punish whoever does not associate anything with Him” (Sahih al-Bukhari 2856).", arabic: "يَا مُعَاذُ، هَلْ تَدْرِي حَقَّ اللَّهِ عَلَى عِبَادِهِ وَمَا حَقُّ الْعِبَادِ عَلَى اللَّهِ. قُلْتُ اللَّهُ وَرَسُولُهُ أَعْلَمُ. قَالَ فَإِنَّ حَقَّ اللَّهِ عَلَى الْعِبَادِ أَنْ يَعْبُدُوهُ وَلاَ يُشْرِكُوا بِهِ شَيْئًا، وَحَقَّ الْعِبَادِ عَلَى اللَّهِ أَنْ لاَ يُعَذِّبَ مَنْ لاَ يُشْرِكُ بِهِ شَيْئًا", dimmed: true)

                    Text("This is why every prophet began with tawhid before anything else, and why the Prophet (peace be upon him) told Mu‘adh, when he sent him to Yemen, to make it the first thing he called to (Sahih al-Bukhari 7372).")
                        .font(.body)
                }

                Section(header: Text("FORMS OF SHIRK TODAY")) {
                    Text("**Major shirk (الشِّرك الأَكبَر)** takes a person out of Islam. It includes: calling upon the dead, saints, or prophets for help, rescue, or children; sacrificing or vowing to other than Allah; prostrating to a grave or a shaykh; believing that anyone besides Allah knows the unseen or controls the universe; and giving anyone the right to make lawful and unlawful in place of Allah:")
                        .font(.body)
                    ScriptureQuote(text: "“And who is more astray than he who invokes besides Allah those who will not respond to him until the Day of Resurrection, and they, of their invocation, are unaware” (Quran 46:5).", arabic: "وَمَنۡ أَضَلُّ مِمَّن يَدۡعُواْ مِن دُونِ ٱللَّهِ مَن لَّا يَسۡتَجِيبُ لَهُۥٓ إِلَىٰ يَوۡمِ ٱلۡقِيَٰمَةِ وَهُمۡ عَن دُعَآئِهِمۡ غَٰفِلُونَ")

                    ScriptureQuote(text: "“They have taken their scholars and monks as lords besides Allah, and [also] the Messiah, the son of Mary. And they were not commanded except to worship one God; there is no deity except Him. Exalted is He above whatever they associate with Him” (Quran 9:31).", arabic: "ٱتَّخَذُوٓاْ أَحۡبَارَهُمۡ وَرُهۡبَٰنَهُمۡ أَرۡبَابٗا مِّن دُونِ ٱللَّهِ وَٱلۡمَسِيحَ ٱبۡنَ مَرۡيَمَ وَمَآ أُمِرُوٓاْ إِلَّا لِيَعۡبُدُوٓاْ إِلَٰهٗا وَٰحِدٗاۖ لَّآ إِلَٰهَ إِلَّا هُوَۚ سُبۡحَٰنَهُۥ عَمَّا يُشۡرِكُونَ")

                    Text("**Minor shirk (الشِّرك الأَصغَر)** does not take one out of Islam but is greater than every other sin: showing off in worship (**riya’**), swearing by other than Allah, and saying “what Allah wills and you will.“ The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The thing I fear most for you is minor shirk.” They said: And what is minor shirk, O Messenger of Allah? He said: “Showing off” (Musnad Ahmad 23630; graded sahih by al-Albani, Sahih al-Jami' 1555).", arabic: "إِنَّ أَخْوَفَ مَا أَخَافُ عَلَيْكُمُ الشِّرْكُ الْأَصْغَرُ. قَالُوا: وَمَا الشِّرْكُ الْأَصْغَرُ يَا رَسُولَ اللَّهِ؟ قَالَ: الرِّيَاءُ", dimmed: true)

                    Text("Amulets, charms, omens, and going to fortune-tellers also fall under shirk, because they attach the heart to other than Allah for benefit and protection.")
                        .font(.body)
                }

                Section(header: Text("THE CURE")) {
                    Text("The cure for shirk is knowing Allah: that He alone creates, provides, hears, answers, and is near, so that the heart has no reason to turn to anyone else:")
                        .font(.body)
                    ScriptureQuote(text: "“And when My servants ask you, [O Muhammad], concerning Me - indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. So let them respond to Me [by obedience] and believe in Me that they may be [rightly] guided” (Quran 2:186).", arabic: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌۖ أُجِيبُ دَعۡوَةَ ٱلدَّاعِ إِذَا دَعَانِۖ فَلۡيَسۡتَجِيبُواْ لِي وَلۡيُؤۡمِنُواْ بِي لَعَلَّهُمۡ يَرۡشُدُونَ")

                    ScriptureQuote(text: "“And [He revealed] that the masjids are for Allah, so do not invoke with Allah anyone” (Quran 72:18).", arabic: "وَأَنَّ ٱلۡمَسَٰجِدَ لِلَّهِ فَلَا تَدۡعُواْ مَعَ ٱللَّهِ أَحَدٗا")
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Is calling upon the dead or the saints for help shirk?**")
                        .font(.body)
                    Text("Yes, when it is for what only Allah can give: cure, provision, children, rescue from distress, forgiveness. This is the very shirk of the people of Makkah, who did not believe their idols created the world but called on them as intercessors and helpers (see 39:3 above). Allah described the dead and absent who are called upon:")
                        .font(.body)
                    ScriptureQuote(text: "“And those whom you invoke other than Him do not possess [as much as] the membrane of a date seed. If you invoke them, they do not hear your supplication; and if they heard, they would not respond to you. And on the Day of Resurrection they will deny your association” (Quran 35:13-14).", arabic: "وَٱلَّذِينَ تَدۡعُونَ مِن دُونِهِۦ مَا يَمۡلِكُونَ مِن قِطۡمِيرٍ ۝ إِن تَدۡعُوهُمۡ لَا يَسۡمَعُواْ دُعَآءَكُمۡ وَلَوۡ سَمِعُواْ مَا ٱسۡتَجَابُواْ لَكُمۡۖ وَيَوۡمَ ٱلۡقِيَٰمَةِ يَكۡفُرُونَ بِشِرۡكِكُمۡۚ")
                    ScriptureQuote(text: "“And when the people are gathered [that Day], they [who were invoked] will be enemies to them, and they will be deniers of their worship” (Quran 46:6).", arabic: "وَإِذَا حُشِرَ ٱلنَّاسُ كَانُواْ لَهُمۡ أَعۡدَآءٗ وَكَانُواْ بِعِبَادَتِهِمۡ كَٰفِرِينَ")
                    ScriptureQuote(text: "“Is He [not best] who responds to the desperate one when he calls upon Him and removes evil and makes you inheritors of the earth? Is there a deity with Allah? Little do you remember” (Quran 27:62).", arabic: "أَمَّن يُجِيبُ ٱلۡمُضۡطَرَّ إِذَا دَعَاهُ وَيَكۡشِفُ ٱلسُّوٓءَ وَيَجۡعَلُكُمۡ خُلَفَآءَ ٱلۡأَرۡضِۗ أَءِلَٰهٞ مَّعَ ٱللَّهِۚ قَلِيلٗا مَّا تَذَكَّرُونَ")
                    Text("Allah also commanded, in the ayah quoted above, that no one be invoked with Him (72:18), and the Prophet (peace be upon him) said that whoever dies calling on a rival to Allah enters the Fire (Sahih al-Bukhari 4497, above). It makes no difference whether the one called upon is an idol, a prophet, or a righteous wali: the righteous themselves seek nearness to Allah and hope for His mercy (17:57). A living person may be asked for what he is able to do; the dead can neither hear the request nor answer it.")
                        .font(.body)

                    Text("**Which tawassul is allowed and which is shirk?**")
                        .font(.body)
                    Text("Allowed, as the Key Terms explain: by Allah’s names and attributes, by one’s own faith and righteous deeds, and by asking a living righteous person to make du‘a for you. Forbidden and shirk: calling on the dead or absent themselves, asking them for needs, or making them intermediaries who carry requests to Allah, for that is exactly what the pagans did. Between the two lies asking Allah “by the right” or “by the status” of the Prophet or a saint. The Companions did not do it after his death, the scholars differed over it, and Ibn Taymiyyah in Qa‘idah Jalilah and al-Albani in at-Tawassul held it to be an innovation rather than shirk in itself, while warning that it is the door through which shirk enters. Allah answered those who took the righteous as a means:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Invoke those you have claimed [as gods] besides Him, for they do not possess the [ability for] removal of adversity from you or [for its] transfer [to someone else].’ Those whom they invoke seek means of access to their Lord, [striving as to] which of them would be nearest, and they hope for His mercy and fear His punishment. Indeed, the punishment of your Lord is ever feared” (Quran 17:56-57).", arabic: "قُلِ ٱدۡعُواْ ٱلَّذِينَ زَعَمۡتُم مِّن دُونِهِۦ فَلَا يَمۡلِكُونَ كَشۡفَ ٱلضُّرِّ عَنكُمۡ وَلَا تَحۡوِيلًا ۝ أُوْلَٰٓئِكَ ٱلَّذِينَ يَدۡعُونَ يَبۡتَغُونَ إِلَىٰ رَبِّهِمُ ٱلۡوَسِيلَةَ أَيُّهُمۡ أَقۡرَبُ وَيَرۡجُونَ رَحۡمَتَهُۥ وَيَخَافُونَ عَذَابَهُۥٓۚ إِنَّ عَذَابَ رَبِّكَ كَانَ مَحۡذُورٗا")

                    Text("**Are amulets shirk?**")
                        .font(.body)
                    Text("Yes. The Prophet (peace be upon him) said, as quoted above, that whoever hangs an amulet has committed shirk (Musnad Ahmad 17422), and the Key Terms explain when that is major shirk and when it is minor. Amulets made from the Quran are not excepted: the companions of Ibn Mas‘ud disliked them all (reported by Ibn Abi Shaybah in al-Musannaf), and this is the view chosen by Ibn Baz and Ibn al-Uthaymin (may Allah have mercy on them), because it closes the door to the rest and because the Quran was revealed to be recited, not hung. Protection is sought through the ruqyah the Sunnah taught, the morning and evening remembrances, and reliance on Allah:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Then have you considered what you invoke besides Allah? If Allah intended me harm, are they removers of His harm; or if He intended me mercy, are they withholders of His mercy?’ Say, ‘Sufficient for me is Allah; upon Him [alone] rely the [wise] reliers’” (Quran 39:38).", arabic: "قُلۡ أَفَرَءَيۡتُم مَّا تَدۡعُونَ مِن دُونِ ٱللَّهِ إِنۡ أَرَادَنِيَ ٱللَّهُ بِضُرٍّ هَلۡ هُنَّ كَٰشِفَٰتُ ضُرِّهِۦٓ أَوۡ أَرَادَنِي بِرَحۡمَةٍ هَلۡ هُنَّ مُمۡسِكَٰتُ رَحۡمَتِهِۦۚ قُلۡ حَسۡبِيَ ٱللَّهُۖ عَلَيۡهِ يَتَوَكَّلُ ٱلۡمُتَوَكِّلُونَ")

                    Text("**Is visiting graves shirk?**")
                        .font(.body)
                    Text("No. Visiting graves to remember death and to make du‘a for the dead is Sunnah. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“I forbade you to visit graves, but now visit them” (Sahih Muslim 977).", arabic: "نَهَيْتُكُمْ عَنْ زِيَارَةِ الْقُبُورِ فَزُورُوهَا", dimmed: true)
                    ScriptureQuote(text: "“So visit the graves, for that makes you mindful of death” (Sahih Muslim 976).", arabic: "فَزُورُوا الْقُبُورَ فَإِنَّهَا تُذَكِّرُ الْمَوْتَ", dimmed: true)
                    Text("He taught the visitor to say:")
                        .font(.body)
                    ScriptureQuote(text: "“Peace be upon you, inhabitants of the abodes, from among the believers and Muslims, and God willing we shall join you. I ask Allah for well-being for us and for you” (Sahih Muslim 975).", arabic: "السَّلاَمُ عَلَيْكُمْ أَهْلَ الدِّيَارِ مِنَ الْمُؤْمِنِينَ وَالْمُسْلِمِينَ وَإِنَّا إِنْ شَاءَ اللَّهُ لَلَاحِقُونَ أَسْأَلُ اللَّهَ لَنَا وَلَكُمْ الْعَافِيَةَ", dimmed: true)
                    Text("What is forbidden is what the earlier nations did with graves: building over them, plastering them, and turning them into places of worship:")
                        .font(.body)
                    ScriptureQuote(text: "Allah’s Messenger (peace be upon him) forbade that graves be plastered, sat upon, or built over (Sahih Muslim 970).", arabic: "نَهَى رَسُولُ اللَّهِ صلى الله عليه وسلم أَنْ يُجَصَّصَ الْقَبْرُ وَأَنْ يُقْعَدَ عَلَيْهِ وَأَنْ يُبْنَى عَلَيْهِ", dimmed: true)
                    ScriptureQuote(text: "“Beware: those before you used to take the graves of their prophets and righteous men as places of worship. Do not take graves as places of worship; I forbid you that” (Sahih Muslim 532).", arabic: "أَلاَ وَإِنَّ مَنْ كَانَ قَبْلَكُمْ كَانُوا يَتَّخِذُونَ قُبُورَ أَنْبِيَائِهِمْ وَصَالِحِيهِمْ مَسَاجِدَ أَلاَ فَلاَ تَتَّخِذُوا الْقُبُورَ مَسَاجِدَ إِنِّي أَنْهَاكُمْ عَنْ ذَلِكَ", dimmed: true)
                    Text("He said this five days before he died, and in his final illness he cursed the Jews and Christians for taking the graves of their prophets as places of worship, warning against what they did (Sahih al-Bukhari 435, Sahih Muslim 531). Ali (may Allah be pleased with him) was sent by the Prophet to leave no raised grave without levelling it (Sahih Muslim 969). The scholars therefore distinguish three visits: the visit of the Sunnah, to greet the dead and pray for them; the visit of innovation, to pray or recite at the grave seeking its blessing; and the visit of shirk, to call on the dead, seek their help, or vow or sacrifice to them. The first is worship; the last is what took the nations before us out of tawhid.")
                        .font(.body)

                    Text("**Is the Prophet alive, and can we ask him for our needs?**")
                        .font(.body)
                    Text("The Prophet (peace be upon him) died, as Allah told him he would, and he is alive in his grave the life of the barzakh, which is not the life of this world and whose nature only Allah knows:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, you are to die, and indeed, they are to die” (Quran 39:30).", arabic: "إِنَّكَ مَيِّتٞ وَإِنَّهُم مَّيِّتُونَ")
                    ScriptureQuote(text: "“Allah has angels who travel around on the earth conveying to me the salam of my ummah” (Sunan an-Nasa'i 1282; graded sahih by al-Albani).", arabic: "إِنَّ لِلَّهِ مَلاَئِكَةً سَيَّاحِينَ فِي الأَرْضِ يُبَلِّغُونِي مِنْ أُمَّتِي السَّلاَمَ", dimmed: true)
                    ScriptureQuote(text: "“If any one of you greets me, Allah returns my soul to me and I respond to the greeting” (Sunan Abi Dawud 2041; graded hasan by al-Albani).", arabic: "مَا مِنْ أَحَدٍ يُسَلِّمُ عَلَىَّ إِلاَّ رَدَّ اللَّهُ عَلَىَّ رُوحِي حَتَّى أَرُدَّ عَلَيْهِ السَّلاَمَ", dimmed: true)
                    Text("So sending salam upon him reaches him. But asking him, at his grave or from afar, for provision, cure, children, or forgiveness is the shirk of du‘a. Even in his lifetime he did not own that:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘I hold not for myself [the power of] benefit or harm, except what Allah has willed’” (Quran 7:188).", arabic: "قُل لَّآ أَمۡلِكُ لِنَفۡسِي نَفۡعٗا وَلَا ضَرًّا إِلَّا مَا شَآءَ ٱللَّهُۚ")
                    ScriptureQuote(text: "“Say, ‘Indeed, I do not possess for you [the power of] harm or right direction’” (Quran 72:21).", arabic: "قُلۡ إِنِّي لَآ أَمۡلِكُ لَكُمۡ ضَرّٗا وَلَا رَشَدٗا")
                    Text("The Companions knew him best and loved him most, and when drought came after his death Umar did not go to his grave to ask him for rain; he asked al-Abbas, a living man, to make du‘a (Sahih al-Bukhari 1010, above). Had asking the Prophet after his death been lawful, they would have been the first to do it.")
                        .font(.body)

                    Text("**Is it shirk to praise the Prophet?**")
                        .font(.body)
                    Text("Loving the Prophet (peace be upon him) more than oneself, praising him with what Allah praised him, and sending salawat upon him are worship of Allah and a sign of faith:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, Allah confers blessing upon the Prophet, and His angels [ask Him to do so]. O you who have believed, ask [Allah to confer] blessing upon him and ask [Allah to grant him] peace” (Quran 33:56).", arabic: "إِنَّ ٱللَّهَ وَمَلَٰٓئِكَتَهُۥ يُصَلُّونَ عَلَى ٱلنَّبِيِّۚ يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ صَلُّواْ عَلَيۡهِ وَسَلِّمُواْ تَسۡلِيمًا")
                    Text("What is forbidden is exaggeration (**ghuluw**) that raises him above the station of servant and messenger: attributing to him knowledge of all the unseen, control over creation, or a share in what belongs to Allah. He himself forbade it:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not exaggerate in praising me as the Christians praised the son of Maryam, for I am only His slave. So say: the slave of Allah and His Messenger” (Sahih al-Bukhari 3445).", arabic: "لاَ تُطْرُونِي كَمَا أَطْرَتِ النَّصَارَى ابْنَ مَرْيَمَ، فَإِنَّمَا أَنَا عَبْدُهُ، فَقُولُوا عَبْدُ اللَّهِ وَرَسُولُهُ", dimmed: true)
                    Text("True love of him is following him:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘If you should love Allah, then follow me, [so] Allah will love you and forgive you your sins’” (Quran 3:31).", arabic: "قُلۡ إِن كُنتُمۡ تُحِبُّونَ ٱللَّهَ فَٱتَّبِعُونِي يُحۡبِبۡكُمُ ٱللَّهُ وَيَغۡفِرۡ لَكُمۡ ذُنُوبَكُمۡۚ")

                    Text("**Is swearing by other than Allah shirk?**")
                        .font(.body)
                    Text("Yes, it is minor shirk, because an oath is a form of veneration that belongs to Allah alone. Ibn Umar (may Allah be pleased with him) heard a man say “No, by the Ka‘bah,” and said: Nothing is sworn by other than Allah, for I heard the Messenger of Allah (peace be upon him) say:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever swears by other than Allah has committed disbelief or shirk” (Sunan al-Tirmidhi 1535; graded sahih by al-Albani).", arabic: "مَنْ حَلَفَ بِغَيْرِ اللَّهِ فَقَدْ كَفَرَ أَوْ أَشْرَكَ", dimmed: true)
                    ScriptureQuote(text: "“Verily, Allah forbids you to swear by your fathers. If one has to take an oath, he should swear by Allah or otherwise keep quiet” (Sahih al-Bukhari 6108, Sahih Muslim 1646).", arabic: "أَلاَ إِنَّ اللَّهَ يَنْهَاكُمْ أَنْ تَحْلِفُوا بِآبَائِكُمْ، فَمَنْ كَانَ حَالِفًا فَلْيَحْلِفْ بِاللَّهِ، وَإِلاَّ فَلْيَصْمُتْ", dimmed: true)
                    Text("At-Tirmidhi reported that some of the people of knowledge explained “disbelief or shirk” here as a severe wording rather than apostasy, and the scholars add that it becomes major shirk only when the one swearing venerates what he swears by as Allah is venerated. The remedy is to say la ilaha illallah:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever swears and says in his oath ‘by al-Lat and al-Uzza,’ let him say: none has the right to be worshipped but Allah” (Sahih al-Bukhari 4860).", arabic: "مَنْ حَلَفَ فَقَالَ فِي حَلِفِهِ وَاللاَّتِ وَالْعُزَّى. فَلْيَقُلْ لاَ إِلَهَ إِلاَّ اللَّهُ", dimmed: true)

                    Text("**Are fortune-tellers, astrology, and magic shirk?**")
                        .font(.body)
                    Text("Claiming to know the unseen is a claim to what belongs to Allah alone, and seeking it from a fortune-teller (**kahin**), an astrologer, or a magician attaches the heart to other than Him. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever goes to a diviner and asks him about anything, no prayer will be accepted from him for forty nights” (Sahih Muslim 2230).", arabic: "مَنْ أَتَى عَرَّافًا فَسَأَلَهُ عَنْ شَىْءٍ لَمْ تُقْبَلْ لَهُ صَلاَةٌ أَرْبَعِينَ لَيْلَةً", dimmed: true)
                    ScriptureQuote(text: "“Whoever ... goes to a fortune-teller and believes what he says has disbelieved in that which was revealed to Muhammad” (Sunan Ibn Majah 639; graded sahih by al-Albani).", arabic: "مَنْ أَتَى ... كَاهِنًا فَصَدَّقَهُ بِمَا يَقُولُ فَقَدْ كَفَرَ بِمَا أُنْزِلَ عَلَى مُحَمَّدٍ", dimmed: true)
                    ScriptureQuote(text: "“Whoever acquires a branch of knowledge of the stars acquires a branch of magic; the more he acquires, the more he gets” (Sunan Abi Dawud 3905; graded hasan by al-Albani).", arabic: "مَنِ اقْتَبَسَ عِلْمًا مِنَ النُّجُومِ اقْتَبَسَ شُعْبَةً مِنَ السِّحْرِ زَادَ مَا زَادَ", dimmed: true)
                    Text("Magic itself is counted with shirk among the seven destroyers:")
                        .font(.body)
                    ScriptureQuote(text: "“Avoid the seven destructive sins.” They said: O Messenger of Allah, what are they? He said: “Shirk with Allah, magic, killing the soul which Allah has forbidden except by right, consuming riba, consuming the orphan’s wealth, fleeing on the day of battle, and accusing chaste, unsuspecting, believing women” (Sahih al-Bukhari 2766).", arabic: "اجْتَنِبُوا السَّبْعَ الْمُوبِقَاتِ. قَالُوا يَا رَسُولَ اللَّهِ، وَمَا هُنَّ قَالَ الشِّرْكُ بِاللَّهِ، وَالسِّحْرُ، وَقَتْلُ النَّفْسِ الَّتِي حَرَّمَ اللَّهُ إِلاَّ بِالْحَقِّ، وَأَكْلُ الرِّبَا، وَأَكْلُ مَالِ الْيَتِيمِ، وَالتَّوَلِّي يَوْمَ الزَّحْفِ، وَقَذْفُ الْمُحْصَنَاتِ الْمُؤْمِنَاتِ الْغَافِلاَتِ", dimmed: true)
                    Text("Even attributing rain to a star is a kind of kufr. After a night of rain at al-Hudaybiyyah the Prophet (peace be upon him) said that Allah had said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever said, we were given rain by the bounty of Allah and His mercy, has believed in Me and disbelieved in the star; and whoever said, by such-and-such a star, has disbelieved in Me and believed in the star” (Sahih al-Bukhari 846, Sahih Muslim 71).", arabic: "فَأَمَّا مَنْ قَالَ مُطِرْنَا بِفَضْلِ اللَّهِ وَرَحْمَتِهِ فَذَلِكَ مُؤْمِنٌ بِي وَكَافِرٌ بِالْكَوْكَبِ، وَأَمَّا مَنْ قَالَ بِنَوْءِ كَذَا وَكَذَا فَذَلِكَ كَافِرٌ بِي وَمُؤْمِنٌ بِالْكَوْكَبِ", dimmed: true)
                    Text("Studying the positions of the stars for direction, the qiblah, and the seasons is permitted; claiming that they influence events or reveal the future is the astrology that is forbidden.")
                        .font(.body)

                    Text("**Is shirk forgiven?**")
                        .font(.body)
                    Text("If a person dies upon major shirk it is not forgiven, as 4:48 quoted above states, and Allah repeats the warning in 4:116. But before death, every sin including shirk is wiped out by repentance and entering Islam. After mentioning those who invoke another deity with Allah, Allah said:")
                        .font(.body)
                    ScriptureQuote(text: "“Except for those who repent, believe and do righteous work. For them Allah will replace their evil deeds with good. And ever is Allah Forgiving and Merciful” (Quran 25:70).", arabic: "إِلَّا مَن تَابَ وَءَامَنَ وَعَمِلَ عَمَلٗا صَٰلِحٗا فَأُوْلَٰٓئِكَ يُبَدِّلُ ٱللَّهُ سَيِّـَٔاتِهِمۡ حَسَنَٰتٖۗ وَكَانَ ٱللَّهُ غَفُورٗا رَّحِيمٗا")
                    ScriptureQuote(text: "“Say, ‘O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful’” (Quran 39:53).", arabic: "قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ")
                    Text("When Amr ibn al-As (may Allah be pleased with him) came to give his pledge and held back his hand, wanting the condition that he be forgiven, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Do you not know that Islam wipes out what came before it, that hijrah wipes out what came before it, and that Hajj wipes out what came before it?” (Sahih Muslim 121).", arabic: "أَمَا عَلِمْتَ أَنَّ الإِسْلاَمَ يَهْدِمُ مَا كَانَ قَبْلَهُ وَأَنَّ الْهِجْرَةَ تَهْدِمُ مَا كَانَ قَبْلَهَا وَأَنَّ الْحَجَّ يَهْدِمُ مَا كَانَ قَبْلَهُ", dimmed: true)
                    Text("So the door is open to whoever repents before death, whatever his shirk was; many of the Companions had worshipped idols before Islam.")
                        .font(.body)

                    Text("**Will shirk appear in this ummah?**")
                        .font(.body)
                    Text("Yes. It is not enough to say “we are Muslims, so shirk does not concern us.” The Prophet (peace be upon him) foretold it plainly:")
                        .font(.body)
                    ScriptureQuote(text: "“The Hour will not come until tribes of my ummah join the mushrikin and until tribes of my ummah worship idols” (Sunan Abi Dawud 4252; graded sahih by al-Albani).", arabic: "وَلاَ تَقُومُ السَّاعَةُ حَتَّى تَلْحَقَ قَبَائِلُ مِنْ أُمَّتِي بِالْمُشْرِكِينَ وَحَتَّى تَعْبُدَ قَبَائِلُ مِنْ أُمَّتِي الأَوْثَانَ", dimmed: true)
                    ScriptureQuote(text: "“The Hour will not be established until the buttocks of the women of Daws move around Dhul-Khalasah” (Sahih al-Bukhari 7116).", arabic: "لاَ تَقُومُ السَّاعَةُ حَتَّى تَضْطَرِبَ أَلَيَاتُ نِسَاءِ دَوْسٍ عَلَى ذِي الْخَلَصَةِ", dimmed: true)
                    Text("Dhul-Khalasah was the idol of Daws in jahiliyyah, and Daws had become Muslim. He also said:")
                        .font(.body)
                    ScriptureQuote(text: "“The night and day will not cease until al-Lat and al-Uzza are worshipped” (Sahih Muslim 2907).", arabic: "لاَ يَذْهَبُ اللَّيْلُ وَالنَّهَارُ حَتَّى تُعْبَدَ اللاَّتُ وَالْعُزَّى", dimmed: true)
                    ScriptureQuote(text: "“You will follow the ways of those before you span by span and cubit by cubit, so that if they went into the hole of a lizard you would follow them.” We said: O Messenger of Allah, the Jews and the Christians? He said: “Who else?” (Sahih al-Bukhari 3456).", arabic: "لَتَتَّبِعُنَّ سَنَنَ مَنْ قَبْلَكُمْ شِبْرًا بِشِبْرٍ، وَذِرَاعًا بِذِرَاعٍ، حَتَّى لَوْ سَلَكُوا جُحْرَ ضَبٍّ لَسَلَكْتُمُوهُ. قُلْنَا يَا رَسُولَ اللَّهِ، الْيَهُودَ وَالنَّصَارَى قَالَ فَمَنْ", dimmed: true)
                    Text("The Jews and Christians fell into shirk through exaggeration about their prophets and righteous men and through their graves (Sahih Muslim 532, above). That is why the Salaf treated shirk as a live danger to be learned and guarded against, not a closed chapter of history.")
                        .font(.body)

                    Text("**Is fearing or hoping in other than Allah shirk?**")
                        .font(.body)
                    Text("Fear and hope are worship of the heart, so each has a lawful and an unlawful form. Natural fear, such as fear of an enemy, a beast, or drowning, is not shirk; Musa (peace be upon him) left Egypt in fear (28:21). Fear that stops a person from an obligation or leads him into sin is forbidden. But the fear of worship, fearing that the dead, the jinn, or a saint can harm by their own hidden power so that one dares not displease them, is major shirk, and Allah commanded that this fear be for Him alone:")
                        .font(.body)
                    ScriptureQuote(text: "“That is only Satan who frightens [you] of his supporters. So fear them not, but fear Me, if you are [indeed] believers” (Quran 3:175).", arabic: "إِنَّمَا ذَٰلِكُمُ ٱلشَّيۡطَٰنُ يُخَوِّفُ أَوۡلِيَآءَهُۥ فَلَا تَخَافُوهُمۡ وَخَافُونِ إِن كُنتُم مُّؤۡمِنِينَ")
                    ScriptureQuote(text: "“So do not fear the people but fear Me” (Quran 5:44).", arabic: "فَلَا تَخۡشَوُاْ ٱلنَّاسَ وَٱخۡشَوۡنِ")
                    ScriptureQuote(text: "“[Allah praises] those who convey the messages of Allah and fear Him and do not fear anyone but Allah. And sufficient is Allah as Accountant” (Quran 33:39).", arabic: "ٱلَّذِينَ يُبَلِّغُونَ رِسَٰلَٰتِ ٱللَّهِ وَيَخۡشَوۡنَهُۥ وَلَا يَخۡشَوۡنَ أَحَدًا إِلَّا ٱللَّهَۗ وَكَفَىٰ بِٱللَّهِ حَسِيبٗا")
                    Text("Hope is the same: hoping in a person for what he can do is natural, and hoping in other than Allah for what only He gives, such as Paradise, forgiveness, or provision from the unseen, is shirk:")
                        .font(.body)
                    ScriptureQuote(text: "“So whoever would hope for the meeting with his Lord - let him do righteous work and not associate in the worship of his Lord anyone” (Quran 18:110).", arabic: "فَمَن كَانَ يَرۡجُواْ لِقَآءَ رَبِّهِۦ فَلۡيَعۡمَلۡ عَمَلٗا صَٰلِحٗا وَلَا يُشۡرِكۡ بِعِبَادَةِ رَبِّهِۦٓ أَحَدَۢا")

                    Text("**Is a Muslim who falls into shirk out of ignorance excused?**")
                        .font(.body)
                    Text("Two things must be kept apart. The act itself is shirk whoever does it, and it is called shirk, warned against, and refuted. The person who does it is judged a mushrik who has left Islam only after the proof of the revelation has reached him in a way he can understand and he persists. Allah does not punish before sending the message:")
                        .font(.body)
                    ScriptureQuote(text: "“And never would We punish until We sent a messenger” (Quran 17:15).", arabic: "وَمَا كُنَّا مُعَذِّبِينَ حَتَّىٰ نَبۡعَثَ رَسُولٗا")
                    ScriptureQuote(text: "“And if any one of the polytheists seeks your protection, then grant him protection so that he may hear the words of Allah” (Quran 9:6).", arabic: "وَإِنۡ أَحَدٞ مِّنَ ٱلۡمُشۡرِكِينَ ٱسۡتَجَارَكَ فَأَجِرۡهُ حَتَّىٰ يَسۡمَعَ كَلَٰمَ ٱللَّهِ")
                    Text("The ayah goes on: then deliver him to his place of safety, “That is because they are a people who do not know.” Ibn Taymiyyah (may Allah have mercy on him) wrote:")
                        .font(.body)
                    ScriptureQuote(text: "“I am among the people most forbidding of attributing disbelief, sin, or disobedience to a specific person, unless it is known that the proof of the message has been established against him” (Ibn Taymiyyah, Majmu‘ al-Fatawa 3/229).", arabic: "أَنَا مِنْ أَعْظَمِ النَّاسِ نَهْيًا عَنْ أَنْ يُنْسَبَ مُعَيَّنٌ إِلَى تَكْفِيرٍ وَتَفْسِيقٍ وَمَعْصِيَةٍ، إِلَّا إِذَا عُلِمَ أَنَّهُ قَدْ قَامَتْ عَلَيْهِ الْحُجَّةُ الرِّسَالِيَّةُ", dimmed: true)
                    Text("The scholars differ over the details: who counts as having received the proof, and whether a Muslim living among the Muslims, with the Quran in his hands, can claim ignorance of the tawhid that is its first message. Ibn Baz, al-Albani, and Ibn al-Uthaymin (may Allah have mercy on them) all held that the ruling on a specific person requires the conditions to be met and the impediments (ignorance, mistake, coercion, misinterpretation) to be absent, and that this judgement belongs to the people of knowledge. The duty of the ordinary Muslim is to hate the act, teach the truth gently, and leave the ruling on individuals to those qualified.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Shirk is the one sin that is not forgiven if a person dies upon it, and it is not only bowing to idols: it is every invocation, sacrifice, vow, and hope directed to other than Allah. Tawhid is its cure and the first message of every prophet.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Shirk")
        .selectableArticleList()
    }
}

struct KufrView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: kufr is disbelief, the rejection or denial of what Allah revealed. Some actions and beliefs take a person out of Islam; knowing them is a protection, and judging a specific person by them is the work of the scholars, not of individuals.")
                        .font(.body)
                }

                Section(header: Text("WHAT IS KUFR?")) {
                    Text("**Kufr (كُفر)** means “to cover“: the farmer who covers the seed is called a **kafir** in the Arabic language. In the religion it is covering the truth: rejecting, denying, doubting, or turning away from what the Messenger (peace be upon him) brought. Its opposite is **iman (إِيمَان)**, faith.")
                        .font(.body)

                    ScriptureQuote(text: "“O you who have believed, believe in Allah and His Messenger and the Book that He sent down upon His Messenger and the Scripture which He sent down before. And whoever disbelieves in Allah, His angels, His books, His messengers, and the Last Day has certainly gone far astray” (Quran 4:136).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ ءَامِنُواْ بِٱللَّهِ وَرَسُولِهِۦ وَٱلۡكِتَٰبِ ٱلَّذِي نَزَّلَ عَلَىٰ رَسُولِهِۦ وَٱلۡكِتَٰبِ ٱلَّذِيٓ أَنزَلَ مِن قَبۡلُۚ وَمَن يَكۡفُرۡ بِٱللَّهِ وَمَلَٰٓئِكَتِهِۦ وَكُتُبِهِۦ وَرُسُلِهِۦ وَٱلۡيَوۡمِ ٱلۡأٓخِرِ فَقَدۡ ضَلَّ ضَلَٰلَۢا بَعِيدًا")

                    ScriptureQuote(text: "“And whoever desires other than Islam as religion - never will it be accepted from him, and he, in the Hereafter, will be among the losers” (Quran 3:85).", arabic: "وَمَن يَبۡتَغِ غَيۡرَ ٱلۡإِسۡلَٰمِ دِينٗا فَلَن يُقۡبَلَ مِنۡهُ وَهُوَ فِي ٱلۡأٓخِرَةِ مِنَ ٱلۡخَٰسِرِينَ")
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Kufr (كُفر)**: from the root ك-ف-ر, kafara, “to cover, to conceal.” The Arabs called the night kafir because it covers everything, and the farmer kafir because he covers the seed with soil; the Quran uses the word in that sense when it likens this world to rain whose growth pleases the **kuffar**, the tillers:")
                        .font(.body)
                    ScriptureQuote(text: "“Like the example of a rain whose [resulting] plant growth pleases the tillers; then it dries and you see it turned yellow; then it becomes [scattered] debris” (Quran 57:20).", arabic: "كَمَثَلِ غَيۡثٍ أَعۡجَبَ ٱلۡكُفَّارَ نَبَاتُهُۥ ثُمَّ يَهِيجُ فَتَرَىٰهُ مُصۡفَرّٗا ثُمَّ يَكُونُ حُطَٰمٗاۖ")
                    Text("In the religion, kufr is covering the truth that the Messenger (peace be upon him) brought after it has reached one: by denying it, doubting it, refusing it out of pride, turning away from it, or hiding disbelief behind a show of faith. It is the opposite of iman. Its second meaning, ingratitude, is the opposite of shukr, for the ungrateful person covers the favour he has received.")
                        .font(.body)

                    Text("**Kafir (كَافِر)**, plural **kuffar (كُفَّار)** and **kafirun (كَافِرُون)**: one who covers the truth. In the Shari‘ah it is whoever is not a Muslim: the one to whom the message came and who rejected it, the one born outside Islam who never entered it (**kafir asli**), and the one who left it (**murtadd**). The word describes a person’s religious state; it is not an insult, and Allah commanded fairness and kindness toward disbelievers who do not fight the Muslims (Quran 60:8, quoted below).")
                        .font(.body)

                    Text("**Kufr akbar (الكُفر الأَكبَر)** and **kufr asghar (الكُفر الأَصغَر)**: major kufr, which removes a person from Islam, and minor kufr, which the texts call kufr because it resembles it, without removing one from the religion. Ahl as-Sunnah say that just as there are two shirks, two kinds of nifaq, and two kinds of zulm, so there are two kinds of kufr; the next section explains them.")
                        .font(.body)

                    Text("Ibn al-Qayyim (may Allah have mercy on him) divided major kufr into five kinds in Madarij as-Salikin:")
                        .font(.body)
                    ScriptureQuote(text: "“Major kufr is of five kinds: the kufr of denial, the kufr of arrogance and refusal despite acknowledgement, the kufr of turning away, the kufr of doubt, and the kufr of hypocrisy” (Ibn al-Qayyim, Madarij as-Salikin).", arabic: "الْكُفْرُ الْأَكْبَرُ خَمْسَةُ أَنْوَاعٍ: كُفْرُ تَكْذِيبٍ، وَكُفْرُ اسْتِكْبَارٍ وَإِبَاءٍ مَعَ التَّصْدِيقِ، وَكُفْرُ إِعْرَاضٍ، وَكُفْرُ شَكٍّ، وَكُفْرُ نِفَاقٍ", dimmed: true)
                    Text("**Takdhib (تَكذِيب)** is calling the truth a lie (Quran 29:68). **Istikbar (اِستِكبَار)** is refusing to submit out of pride while knowing the truth, the kufr of Iblis, who did not deny that Allah had commanded him:")
                        .font(.body)
                    ScriptureQuote(text: "“So they prostrated, except for Iblees. He refused and was arrogant and became of the disbelievers” (Quran 2:34).", arabic: "فَسَجَدُوٓاْ إِلَّآ إِبۡلِيسَ أَبَىٰ وَٱسۡتَكۡبَرَ وَكَانَ مِنَ ٱلۡكَٰفِرِينَ")
                    Text("**Shakk (شَكّ)** is doubt about the truth of the message (Quran 14:9). **I‘rad (إِعرَاض)** is turning away from it altogether, neither believing nor denying, neither learning nor acting:")
                        .font(.body)
                    ScriptureQuote(text: "“And who is more unjust than one who is reminded of the verses of his Lord; then he turns away from them?” (Quran 32:22).", arabic: "وَمَنۡ أَظۡلَمُ مِمَّن ذُكِّرَ بِـَٔايَٰتِ رَبِّهِۦ ثُمَّ أَعۡرَضَ عَنۡهَآۚ")
                    Text("**Nifaq (نِفَاق)** is hiding disbelief while displaying Islam (Quran 63:1-3).")
                        .font(.body)

                    Text("**Riddah (رِدَّة)** and **murtadd (مُرتَدّ)**: from radda, “to turn back.” Apostasy is leaving Islam after having entered it, by a belief, a statement, or an action that nullifies it, and the apostate is the murtadd. Allah warned:")
                        .font(.body)
                    ScriptureQuote(text: "“And whoever of you reverts from his religion [to disbelief] and dies while he is a disbeliever - for those, their deeds have become worthless in this world and the Hereafter” (Quran 2:217).", arabic: "وَمَن يَرۡتَدِدۡ مِنكُمۡ عَن دِينِهِۦ فَيَمُتۡ وَهُوَ كَافِرٞ فَأُوْلَٰٓئِكَ حَبِطَتۡ أَعۡمَٰلُهُمۡ فِي ٱلدُّنۡيَا وَٱلۡأٓخِرَةِۖ")
                    Text("Even after apostasy the door of repentance stays open until death:")
                        .font(.body)
                    ScriptureQuote(text: "“Except for those who repent after that and correct themselves. For indeed, Allah is Forgiving and Merciful” (Quran 3:89).", arabic: "إِلَّا ٱلَّذِينَ تَابُواْ مِنۢ بَعۡدِ ذَٰلِكَ وَأَصۡلَحُواْ فَإِنَّ ٱللَّهَ غَفُورٞ رَّحِيمٌ")

                    Text("**Nifaq akbar (النِّفَاق الأَكبَر)** and **nifaq asghar (النِّفَاق الأَصغَر)**: hypocrisy. The scholars of language derive it from the nafiqa’, the hidden second exit of the jerboa’s burrow, because the hypocrite enters the religion by one door and leaves by another. Major hypocrisy, in belief, is concealing kufr behind a show of Islam, and it is worse than open disbelief:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, the hypocrites will be in the lowest depths of the Fire - and never will you find for them a helper” (Quran 4:145).", arabic: "إِنَّ ٱلۡمُنَٰفِقِينَ فِي ٱلدَّرۡكِ ٱلۡأَسۡفَلِ مِنَ ٱلنَّارِ وَلَن تَجِدَ لَهُمۡ نَصِيرًا")
                    Text("Minor hypocrisy, in action, is having the traits of the hypocrites while believing; it does not remove one from Islam but is a grave sin and a road to the greater:")
                        .font(.body)
                    ScriptureQuote(text: "“The signs of a hypocrite are three: whenever he speaks, he tells a lie; whenever he promises, he breaks it; and if you trust him, he proves to be dishonest” (Sahih al-Bukhari 33, Sahih Muslim 59).", arabic: "آيَةُ الْمُنَافِقِ ثَلاَثٌ إِذَا حَدَّثَ كَذَبَ، وَإِذَا وَعَدَ أَخْلَفَ، وَإِذَا اؤْتُمِنَ خَانَ", dimmed: true)

                    Text("**Takfir (تَكفِير)**: declaring someone a kafir. It is a ruling of the Shari‘ah, not a matter of opinion or anger: only Allah and His Messenger decide what is kufr and who is a kafir, and applying that to a specific person has conditions and impediments that the section on the rules of takfir sets out. It is the scholars and the Muslim judge who apply it to a named person, after examining him and establishing the proof; it is never the work of an individual acting on his own.")
                        .font(.body)

                    Text("**Istihlal (اِستِحلَال)**: from halal: treating as lawful what Allah made unlawful, or as unlawful what He made lawful, as a matter of belief. The sinner who knows he is sinning has not left Islam; the one who says that what Allah forbade is permitted has rejected Allah’s ruling. This is how the Salaf explained the Christians’ taking their monks as lords (Quran 9:31): they did not pray to them, but they made lawful what the monks made lawful and unlawful what they made unlawful (Ibn Kathir, Tafsir).")
                        .font(.body)

                    Text("**Juhud (جُحُود)**: denial of what one knows in his heart to be true. Allah said of Pharaoh’s people:")
                        .font(.body)
                    ScriptureQuote(text: "“And they rejected them, while their [inner] selves were convinced thereof, out of injustice and haughtiness” (Quran 27:14).", arabic: "وَجَحَدُواْ بِهَا وَٱسۡتَيۡقَنَتۡهَآ أَنفُسُهُمۡ ظُلۡمٗا وَعُلُوّٗاۚ")
                    Text("And of the Quraysh, that they did not really think the Prophet a liar; it was the verses of Allah that the wrongdoers rejected (Quran 6:33).")
                        .font(.body)

                    Text("**Kufr an-ni‘mah (كُفر النِّعمَة)**: ingratitude for a favour, the kufr that is the opposite of shukr. It is not disbelief unless it is joined to denial of the Giver, but the Quran warns against it and the Prophet (peace be upon him) called it kufr:")
                        .font(.body)
                    ScriptureQuote(text: "“If you are grateful, I will surely increase you [in favor]; but if you deny, indeed, My punishment is severe” (Quran 14:7).", arabic: "لَئِن شَكَرۡتُمۡ لَأَزِيدَنَّكُمۡۖ وَلَئِن كَفَرۡتُمۡ إِنَّ عَذَابِي لَشَدِيدٞ")
                    ScriptureQuote(text: "“I was shown the Hell-fire and that the majority of its dwellers were women who were ungrateful.” It was asked: Do they disbelieve in Allah? He replied: “They are ungrateful to their husbands and are ungrateful for the favours done to them” (Sahih al-Bukhari 29).", arabic: "أُرِيتُ النَّارَ فَإِذَا أَكْثَرُ أَهْلِهَا النِّسَاءُ يَكْفُرْنَ. قِيلَ أَيَكْفُرْنَ بِاللَّهِ قَالَ يَكْفُرْنَ الْعَشِيرَ، وَيَكْفُرْنَ الإِحْسَانَ", dimmed: true)

                    Text("**Zandaqah (زَندَقَة)** and **zindiq (زِندِيق)**: a word of Persian origin which many of the jurists use for the one who conceals disbelief while displaying Islam. Ibn Taymiyyah wrote in as-Sarim al-Maslul that the zindiq in the usage of many of the fuqaha is the munafiq of the Quran: two words for one reality.")
                        .font(.body)

                    Text("**Ahl al-Kitab (أَهل الكِتَاب)**: the People of the Scripture, the Jews and the Christians, to whom the Torah and the Injil were given. The Quran calls them by this name, invites them to the common word of tawhid (Quran 3:64), permits their food and marriage to their chaste women (Quran 5:5), and commands the finest manner in argument with them:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not argue with the People of the Scripture except in a way that is best, except for those who commit injustice among them” (Quran 29:46).", arabic: "وَلَا تُجَٰدِلُوٓاْ أَهۡلَ ٱلۡكِتَٰبِ إِلَّا بِٱلَّتِي هِيَ أَحۡسَنُ إِلَّا ٱلَّذِينَ ظَلَمُواْ مِنۡهُمۡۖ")

                    Text("**Millah (مِلَّة)**: the religion and way a people follow. The millah of Ibrahim is the tawhid Allah commanded the Prophet (peace be upon him) to follow:")
                        .font(.body)
                    ScriptureQuote(text: "“Then We revealed to you, [O Muhammad], to follow the religion of Abraham, inclining toward truth; and he was not of those who associate with Allah” (Quran 16:123).", arabic: "ثُمَّ أَوۡحَيۡنَآ إِلَيۡكَ أَنِ ٱتَّبِعۡ مِلَّةَ إِبۡرَٰهِيمَ حَنِيفٗاۖ وَمَا كَانَ مِنَ ٱلۡمُشۡرِكِينَ")
                    Text("When the scholars say that a kufr “removes one from the millah” they mean it takes him out of Islam, and “a kufr that does not remove one from the millah” is minor kufr.")
                        .font(.body)

                    Text("**Islam (إِسلَام)** and **iman (إِيمَان)**: submission and faith. When the two are mentioned together, Islam is the outward deeds of the limbs and iman the inward belief of the heart, as in the hadith of Jibril (Sahih al-Bukhari 50, Sahih Muslim 8); when either is mentioned alone it includes the other. So every believer is a Muslim, but not every Muslim has reached faith:")
                        .font(.body)
                    ScriptureQuote(text: "“The bedouins say, ‘We have believed.’ Say, ‘You have not [yet] believed; but say [instead], “We have submitted,” for faith has not yet entered your hearts’” (Quran 49:14).", arabic: "قَالَتِ ٱلۡأَعۡرَابُ ءَامَنَّاۖ قُل لَّمۡ تُؤۡمِنُواْ وَلَٰكِن قُولُوٓاْ أَسۡلَمۡنَا وَلَمَّا يَدۡخُلِ ٱلۡإِيمَٰنُ فِي قُلُوبِكُمۡۖ")
                    Text("Ibn Taymiyyah explains this in Kitab al-Iman: the faith that the texts praise is belief, statement, and action, and it increases with obedience and decreases with sin.")
                        .font(.body)

                    Text("**The Khawarij (الخَوَارِج)** and **the Murji’ah (المُرجِئَة)**: the two extremes between which Ahl as-Sunnah stand. The Khawarij, “those who went out,” rebelled against Ali (may Allah be pleased with him) and held that a Muslim who commits a major sin becomes a kafir who will abide in the Fire forever; the Prophet (peace be upon him) foretold them and described them as passing out of the religion as an arrow passes through its prey (Sahih al-Bukhari 6930). The Murji’ah, from irja’, “to defer,” put action outside faith and said that no sin harms one who believes. Ahl as-Sunnah hold that faith is belief, statement, and action, and that a major sin diminishes it without ending it (al-Ash‘ari, Maqalat al-Islamiyyin; Ibn Taymiyyah, Kitab al-Iman).")
                        .font(.body)
                }

                Section(header: Text("MAJOR AND MINOR KUFR")) {
                    Text("**Major kufr (الكُفر الأَكبَر)** takes a person out of Islam. **Minor kufr (الكُفر الأَصغَر)** is a grave sin the texts called “kufr“ without meaning apostasy, such as ingratitude to a husband or fighting a fellow Muslim. Ahl as-Sunnah keep the two apart, unlike the Khawarij, who made every major sin major kufr, and unlike the Murji’ah, who said no action could be kufr at all.")
                        .font(.body)
                }

                Section(header: Text("WHAT BREAKS ISLAM")) {
                    Text("The scholars gathered from the Quran and Sunnah the **nawaqid al-Islam (نَوَاقِض الإِسلَام)**, the nullifiers of Islam. Among the most important:")
                        .font(.body)

                    Text("**1. Shirk in worship**: calling upon, sacrificing to, or prostrating to other than Allah.")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, Allah does not forgive association with Him, but He forgives what is less than that for whom He wills. And he who associates others with Allah has certainly gone far astray” (Quran 4:116).", arabic: "إِنَّ ٱللَّهَ لَا يَغۡفِرُ أَن يُشۡرَكَ بِهِۦ وَيَغۡفِرُ مَا دُونَ ذَٰلِكَ لِمَن يَشَآءُۚ وَمَن يُشۡرِكۡ بِٱللَّهِ فَقَدۡ ضَلَّ ضَلَٰلَۢا بَعِيدًا")

                    Text("**2. Taking intermediaries** between oneself and Allah, calling on them and relying on them, as the pagans did (Quran 39:3, 10:18).")
                        .font(.body)

                    Text("**3. Denying the disbelief of the disbelievers**, or believing that a religion other than Islam is acceptable to Allah (Quran 3:85).")
                        .font(.body)

                    Text("**4. Believing that a guidance other than the Prophet’s is better**, or that the judgement of other than Allah is better than His.")
                        .font(.body)
                    ScriptureQuote(text: "“Legislation is not but for Allah. He has commanded that you worship not except Him. That is the correct religion, but most of the people do not know” (Quran 12:40).", arabic: "إِنِ ٱلۡحُكۡمُ إِلَّا لِلَّهِ أَمَرَ أَلَّا تَعۡبُدُوٓاْ إِلَّآ إِيَّاهُۚ ذَٰلِكَ ٱلدِّينُ ٱلۡقَيِّمُ وَلَٰكِنَّ أَكۡثَرَ ٱلنَّاسِ لَا يَعۡلَمُونَ")

                    Text("**5. Hating any part of what the Messenger brought**, even while acting on it.")
                        .font(.body)

                    Text("**6. Mocking** any part of the religion, its reward, or its punishment.")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Is it Allah and His verses and His Messenger that you were mocking?’ Make no excuse; you have disbelieved after your belief” (Quran 9:65-66).", arabic: "قُلۡ أَبِٱللَّهِ وَءَايَٰتِهِۦ وَرَسُولِهِۦ كُنتُمۡ تَسۡتَهۡزِءُونَ ۝ لَا تَعۡتَذِرُواْ قَدۡ كَفَرۡتُم بَعۡدَ إِيمَٰنِكُمۡۚ")

                    Text("**7. Magic** (sihr), practising it or being pleased with it.")
                        .font(.body)

                    Text("**8. Supporting the disbelievers against the Muslims** out of loyalty to their religion.")
                        .font(.body)

                    Text("**9. Believing that anyone may leave the Shari‘ah of Muhammad** (peace be upon him), as some Sufis claimed of their “saints.“")
                        .font(.body)

                    Text("**10. Turning away from the religion entirely**, neither learning it nor acting on it.")
                        .font(.body)

                    Text("To these the Companions added abandoning the prayer. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Between a man and shirk and disbelief is the abandonment of the prayer” (Sahih Muslim 82).", arabic: "إِنَّ بَيْنَ الرَّجُلِ وَبَيْنَ الشِّرْكِ وَالْكُفْرِ تَرْكَ الصَّلاَةِ", dimmed: true)
                    ScriptureQuote(text: "“The covenant between us and them is the prayer, so whoever abandons it has disbelieved” (Sunan al-Tirmidhi 2621; graded sahih by al-Albani).", arabic: "الْعَهْدُ الَّذِي بَيْنَنَا وَبَيْنَهُمُ الصَّلاَةُ فَمَنْ تَرَكَهَا فَقَدْ كَفَرَ", dimmed: true)

                    Text("Abdullah ibn Shaqiq, a Successor, said: “The Companions of Muhammad did not consider the abandonment of any action to be disbelief except the prayer“ (Sunan al-Tirmidhi 2622). The strongest position, that of Imam Ahmad, is that leaving it entirely is major kufr.")
                        .font(.body)
                }

                Section(header: Text("THE RULES OF TAKFIR")) {
                    Text("Knowing what breaks Islam is one thing; declaring a specific person a disbeliever (**takfir**) is another. The Salaf were the most careful of people in this. A ruling of kufr applies to a person only when the **conditions** are met and the **impediments** are absent: he must know the ruling, intend the act, and be free of coercion, mistake, or a legitimate misunderstanding.")
                        .font(.body)

                    ScriptureQuote(text: "“Whoever disbelieves in Allah after his belief... except for one who is forced [to renounce his religion] while his heart is secure in faith. But those who [willingly] open their breasts to disbelief, upon them is wrath from Allah, and for them is a great punishment” (Quran 16:106).", arabic: "مَن كَفَرَ بِٱللَّهِ مِنۢ بَعۡدِ إِيمَٰنِهِۦٓ إِلَّا مَنۡ أُكۡرِهَ وَقَلۡبُهُۥ مُطۡمَئِنُّۢ بِٱلۡإِيمَٰنِ وَلَٰكِن مَّن شَرَحَ بِٱلۡكُفۡرِ صَدۡرٗا فَعَلَيۡهِمۡ غَضَبٞ مِّنَ ٱللَّهِ وَلَهُمۡ عَذَابٌ عَظِيمٞ")

                    ScriptureQuote(text: "“And do not say to one who gives you [a greeting of] peace ‘You are not a believer’” (Quran 4:94).", arabic: "وَلَا تَقُولُواْ لِمَنۡ أَلۡقَىٰٓ إِلَيۡكُمُ ٱلسَّلَٰمَ لَسۡتَ مُؤۡمِنٗا")

                    Text("The Prophet (peace be upon him) warned:")
                        .font(.body)
                    ScriptureQuote(text: "“If a man says to his brother, ‘O disbeliever,’ then it returns upon one of them” (Sahih al-Bukhari 6103, Sahih Muslim 60).", arabic: "إِذَا قَالَ الرَّجُلُ لأَخِيهِ يَا كَافِرُ فَقَدْ بَاءَ بِهِ أَحَدُهُمَا", dimmed: true)

                    Text("So a Muslim who commits a major sin is a sinful believer, not a disbeliever, unless he declares the sin lawful. And judging that a particular person has left Islam belongs to qualified scholars and the Muslim judge, never to individuals or groups on their own. This is the line between Ahl as-Sunnah and the Khawarij.")
                        .font(.body)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Do we call a specific Muslim a kafir?**")
                        .font(.body)
                    Text("Not on our own. There is a difference between saying “whoever does such-and-such has disbelieved,” which states a ruling of the Shari‘ah, and saying “this person is a kafir,” which is a judgement on an individual. The second requires that the conditions be present, knowledge, intent, and free choice, and that the impediments be absent: ignorance, mistake, coercion, and a misinterpretation the person believes to be the truth. That is why Allah excused the one who is forced while his heart is secure in faith (16:106, quoted above), forbade saying “you are not a believer” to one who offers the greeting of peace (4:94, above), and why the Prophet (peace be upon him) warned that the word “kafir” returns upon the one who says it wrongly (Sahih al-Bukhari 6103, above). He also told of a man who doubted Allah’s power over him and was still forgiven:")
                        .font(.body)
                    ScriptureQuote(text: "“A man used to do sinful deeds, and when death came to him, he said to his sons, ‘After my death, burn me and then crush me, and scatter the powder in the air, for by Allah, if Allah has control over me, He will give me such a punishment as He has never given to anyone else.’ When he died, his sons did accordingly. Allah ordered the earth saying, ‘Collect what you hold of his particles.’ It did so, and behold! There he was standing. Allah asked him, ‘What made you do what you did?’ He replied, ‘O my Lord! I was afraid of You.’ So Allah forgave him” (Sahih al-Bukhari 3481, Sahih Muslim 2756).", arabic: "كَانَ رَجُلٌ يُسْرِفُ عَلَى نَفْسِهِ، فَلَمَّا حَضَرَهُ الْمَوْتُ قَالَ لِبَنِيهِ إِذَا أَنَا مُتُّ فَأَحْرِقُونِي ثُمَّ اطْحَنُونِي ثُمَّ ذَرُّونِي فِي الرِّيحِ، فَوَاللَّهِ لَئِنْ قَدَرَ عَلَىَّ رَبِّي لَيُعَذِّبَنِّي عَذَابًا مَا عَذَّبَهُ أَحَدًا. فَلَمَّا مَاتَ فُعِلَ بِهِ ذَلِكَ، فَأَمَرَ اللَّهُ الأَرْضَ، فَقَالَ اجْمَعِي مَا فِيكِ مِنْهُ. فَفَعَلَتْ فَإِذَا هُوَ قَائِمٌ، فَقَالَ مَا حَمَلَكَ عَلَى مَا صَنَعْتَ قَالَ يَا رَبِّ، خَشْيَتُكَ. فَغَفَرَ لَهُ", dimmed: true)
                    Text("Ibn Taymiyyah (may Allah have mercy on him) wrote:")
                        .font(.body)
                    ScriptureQuote(text: "“No one has the right to declare any of the Muslims a disbeliever, even if he has erred and been mistaken, until the proof has been established against him and the matter made clear to him” (Ibn Taymiyyah, Majmu‘ al-Fatawa 12/466).", arabic: "لَيْسَ لِأَحَدٍ أَنْ يُكَفِّرَ أَحَدًا مِنَ الْمُسْلِمِينَ وَإِنْ أَخْطَأَ وَغَلِطَ حَتَّى تُقَامَ عَلَيْهِ الْحُجَّةُ وَتُبَيَّنَ لَهُ الْمَحَجَّةُ", dimmed: true)
                    Text("So the ordinary Muslim hates the act of kufr, warns against it, and leaves the ruling on the person to the qualified scholars and the judge, who examine him, establish the proof, and call him to repent. Whoever makes takfir of Muslims his habit has taken the road of the Khawarij, whatever he calls himself; and whoever goes to the other extreme, treating the nullifiers as though no belief or deed could ever be kufr, has taken the road of the Murji’ah. The truth is between the two: the nullifiers are real, and the ruling on a named person is not the layman’s to give.")
                        .font(.body)

                    Text("**Is abandoning the prayer kufr?**")
                        .font(.body)
                    Text("The texts quoted above are severe: the Prophet (peace be upon him) placed the abandonment of the prayer between a man and shirk and kufr (Sahih Muslim 82), called the prayer the covenant whose abandoner has disbelieved (Sunan al-Tirmidhi 2621), and his Companions saw no deed whose abandonment is disbelief except the prayer, as Abdullah ibn Shaqiq reported (Sunan al-Tirmidhi 2622). Umar (may Allah be pleased with him) said as he lay wounded: “There is no share in Islam for one who leaves the prayer” (reported by Malik in al-Muwatta). On this basis Imam Ahmad held that whoever abandons the prayer entirely, even while admitting it is obligatory, commits major kufr, and Ibn Baz and Ibn al-Uthaymin (may Allah have mercy on them) held the same. Abu Hanifah, Malik, and ash-Shafi‘i held that he is a grave sinner who has not left Islam unless he denies that it is obligatory, understanding the kufr in these texts as minor kufr, and al-Albani (may Allah have mercy on him) chose this view. Among their proofs is the hadith of Ubadah ibn as-Samit:")
                        .font(.body)
                    ScriptureQuote(text: "“There are five prayers which Allah has prescribed on His servants. If anyone offers them, not losing any of them, and not treating them lightly, Allah guarantees that He will admit him to Paradise. If anyone does not offer them, Allah does not take any responsibility for such a person. He may either punish him or admit him to Paradise” (Sunan Abi Dawud 1420; graded sahih by al-Albani).", arabic: "خَمْسُ صَلَوَاتٍ كَتَبَهُنَّ اللَّهُ عَلَى الْعِبَادِ فَمَنْ جَاءَ بِهِنَّ لَمْ يُضَيِّعْ مِنْهُنَّ شَيْئًا اسْتِخْفَافًا بِحَقِّهِنَّ كَانَ لَهُ عِنْدَ اللَّهِ عَهْدٌ أَنْ يُدْخِلَهُ الْجَنَّةَ وَمَنْ لَمْ يَأْتِ بِهِنَّ فَلَيْسَ لَهُ عِنْدَ اللَّهِ عَهْدٌ إِنْ شَاءَ عَذَّبَهُ وَإِنْ شَاءَ أَدْخَلَهُ الْجَنَّةَ", dimmed: true)
                    Text("Ibn al-Qayyim set out both sides fairly in Kitab as-Salah. All agree that whoever denies the obligation of the five prayers is a disbeliever, that abandoning them is among the gravest of all sins, and that the one who leaves them stands in real danger of dying outside Islam; the difference concerns the one who never denies the obligation yet never prays. Whoever fears for his religion does not gamble it on the milder opinion. And even on the stronger view no one applies that ruling to a particular man he knows: that belongs to the scholars and the judge, as above. What is asked of a Muslim whose brother has left the prayer is that he call him back to it, gently and again.")
                        .font(.body)

                    Text("**Is ruling by other than what Allah revealed kufr?**")
                        .font(.body)
                    Text("Allah said of those who do not judge by what He revealed, in three consecutive ayat:")
                        .font(.body)
                    ScriptureQuote(text: "“And whoever does not judge by what Allah has revealed - then it is those who are the disbelievers” (Quran 5:44).", arabic: "وَمَن لَّمۡ يَحۡكُم بِمَآ أَنزَلَ ٱللَّهُ فَأُوْلَٰٓئِكَ هُمُ ٱلۡكَٰفِرُونَ")
                    ScriptureQuote(text: "“And whoever does not judge by what Allah has revealed - then it is those who are the wrongdoers” (Quran 5:45).", arabic: "وَمَن لَّمۡ يَحۡكُم بِمَآ أَنزَلَ ٱللَّهُ فَأُوْلَٰٓئِكَ هُمُ ٱلظَّٰلِمُونَ")
                    ScriptureQuote(text: "“And whoever does not judge by what Allah has revealed - then it is those who are the defiantly disobedient” (Quran 5:47).", arabic: "وَمَن لَّمۡ يَحۡكُم بِمَآ أَنزَلَ ٱللَّهُ فَأُوْلَٰٓئِكَ هُمُ ٱلۡفَٰسِقُونَ")
                    Text("Ibn Abbas (may Allah be pleased with him), the interpreter of the Quran, said of the first ayah:")
                        .font(.body)
                    ScriptureQuote(text: "“It is a kufr less than kufr” (reported by al-Hakim in al-Mustadrak, who graded it sahih, with adh-Dhahabi agreeing).", arabic: "كُفْرٌ دُونَ كُفْرٍ", dimmed: true)
                    Text("And the Successor Ata’ ibn Abi Rabah said: a kufr less than kufr, a wrongdoing less than wrongdoing, and a disobedience less than disobedience (reported by Ibn Jarir at-Tabari in his Tafsir). So the scholars distinguish. Whoever rules by other than what Allah revealed believing that it is permissible, or that another law is equal or superior to the law of Allah, or rejecting Allah’s ruling, commits major kufr, for legislation belongs to Allah alone (12:40, quoted above). Whoever rules by other than it in some matter out of desire, bribery, fear, or favouritism, while believing that Allah’s law is the truth and that he is sinning, commits minor kufr and a grave sin. This is the detail given by Ibn Baz, al-Albani, and Ibn al-Uthaymin (may Allah have mercy on them), following Ibn Abbas, and it keeps the balance between the Khawarij, who make every sin major kufr, and the Murji’ah, who empty the texts of their weight. Which of the two a particular case falls under is not settled from a page: it needs knowledge of the ruling given, of the man who gave it, and of what he believed when he gave it, and it belongs to the scholars. What is asked of the ordinary Muslim here is that he hold Allah’s law to be the truth and judge his own dealings by it.")
                        .font(.body)

                    Text("**Does ignorance excuse?**")
                        .font(.body)
                    Text("Allah does not punish anyone before the message reaches him (17:15), and He sent the messengers so that no one would have an argument against Him:")
                        .font(.body)
                    ScriptureQuote(text: "“[We sent] messengers as bringers of good tidings and warners so that mankind will have no argument against Allah after the messengers” (Quran 4:165).", arabic: "رُّسُلٗا مُّبَشِّرِينَ وَمُنذِرِينَ لِئَلَّا يَكُونَ لِلنَّاسِ عَلَى ٱللَّهِ حُجَّةُۢ بَعۡدَ ٱلرُّسُلِۚ")
                    Text("The man who ordered his body burned (Sahih al-Bukhari 3481, quoted above) is the clearest example. Ibn Taymiyyah wrote of him:")
                        .font(.body)
                    ScriptureQuote(text: "“This man doubted the power of Allah and His restoring him once he had been scattered; indeed he believed he would not be restored. That is kufr by the agreement of the Muslims, but he was ignorant and did not know it, and he was a believer who feared that Allah would punish him, so he was forgiven for that” (Ibn Taymiyyah, Majmu‘ al-Fatawa 3/231).", arabic: "فَهَذَا رَجُلٌ شَكَّ فِي قُدْرَةِ اللَّهِ وَفِي إِعَادَتِهِ إِذَا ذُرِّيَ، بَلِ اعْتَقَدَ أَنَّهُ لَا يُعَادُ، وَهَذَا كُفْرٌ بِاتِّفَاقِ الْمُسْلِمِينَ، لَكِنْ كَانَ جَاهِلًا لَا يَعْلَمُ ذَلِكَ، وَكَانَ مُؤْمِنًا يَخَافُ اللَّهَ أَنْ يُعَاقِبَهُ فَغُفِرَ لَهُ بِذَلِكَ", dimmed: true)
                    Text("So ignorance is an impediment to takfir of a specific person. But it has limits: the one who is able to learn and turns away is not excused, for turning away is itself a kind of kufr; and what is excused in a new Muslim or one raised far from knowledge is not the same in one who grew up among the Muslims with the Quran in his hands. Weighing where a particular person stands is the work of the scholars, who look at what reached him and how.")
                        .font(.body)

                    Text("**Are the Jews and Christians disbelievers?**")
                        .font(.body)
                    Text("Yes, in the ruling of Allah, because they did not believe in the Messenger He sent to all mankind, and because of what they said about Him:")
                        .font(.body)
                    ScriptureQuote(text: "“They have certainly disbelieved who say, ‘Allah is the third of three.’ And there is no god except one God” (Quran 5:73).", arabic: "لَّقَدۡ كَفَرَ ٱلَّذِينَ قَالُوٓاْ إِنَّ ٱللَّهَ ثَالِثُ ثَلَٰثَةٖۘ وَمَا مِنۡ إِلَٰهٍ إِلَّآ إِلَٰهٞ وَٰحِدٞۚ")
                    ScriptureQuote(text: "“Indeed, they who disbelieved among the People of the Scripture and the polytheists will be in the fire of Hell, abiding eternally therein” (Quran 98:6).", arabic: "إِنَّ ٱلَّذِينَ كَفَرُواْ مِنۡ أَهۡلِ ٱلۡكِتَٰبِ وَٱلۡمُشۡرِكِينَ فِي نَارِ جَهَنَّمَ خَٰلِدِينَ فِيهَآۚ")
                    ScriptureQuote(text: "“By Him in Whose hand is the life of Muhammad, he who among the community of Jews or Christians hears about me but does not affirm his belief in that with which I have been sent, and dies in this state, he shall be but one of the denizens of Hell-Fire” (Sahih Muslim 153).", arabic: "وَالَّذِي نَفْسُ مُحَمَّدٍ بِيَدِهِ لاَ يَسْمَعُ بِي أَحَدٌ مِنْ هَذِهِ الأُمَّةِ يَهُودِيٌّ وَلاَ نَصْرَانِيٌّ ثُمَّ يَمُوتُ وَلَمْ يُؤْمِنْ بِالَّذِي أُرْسِلْتُ بِهِ إِلاَّ كَانَ مِنْ أَصْحَابِ النَّارِ", dimmed: true)
                    Text("The scholars count denying the disbelief of those who rejected the Messenger among the nullifiers of Islam, the third listed above, because it is a denial of the message itself. That is a ruling on the belief; as always, whether a particular person falls under it is weighed by the scholars, after the matter has been made clear to him. As for 2:62, Ibn Kathir explains that it concerns those of each community who followed the messenger of their own time before the next was sent; after Muhammad (peace be upon him) no religion is accepted but his (3:85, above). Their disbelief does not make them all alike in conduct, for the Quran says they are not all the same (3:113) and praises those among them who believed (3:199); nor does it cancel their rights:")
                        .font(.body)
                    ScriptureQuote(text: "“And among the People of the Scripture is he who, if you entrust him with a great amount [of wealth], he will return it to you. And among them is he who, if you entrust him with a [single] silver coin, he will not return it to you” (Quran 3:75).", arabic: "وَمِنۡ أَهۡلِ ٱلۡكِتَٰبِ مَنۡ إِن تَأۡمَنۡهُ بِقِنطَارٖ يُؤَدِّهِۦٓ إِلَيۡكَ وَمِنۡهُم مَّنۡ إِن تَأۡمَنۡهُ بِدِينَارٖ لَّا يُؤَدِّهِۦٓ إِلَيۡكَ")
                    ScriptureQuote(text: "“Allah does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them. Indeed, Allah loves those who act justly” (Quran 60:8).", arabic: "لَّا يَنۡهَىٰكُمُ ٱللَّهُ عَنِ ٱلَّذِينَ لَمۡ يُقَٰتِلُوكُمۡ فِي ٱلدِّينِ وَلَمۡ يُخۡرِجُوكُم مِّن دِيَٰرِكُمۡ أَن تَبَرُّوهُمۡ وَتُقۡسِطُوٓاْ إِلَيۡهِمۡۚ إِنَّ ٱللَّهَ يُحِبُّ ٱلۡمُقۡسِطِينَ")
                    ScriptureQuote(text: "“The food of those who were given the Scripture is lawful for you and your food is lawful for them. And [lawful in marriage are] chaste women from among the believers and chaste women from among those who were given the Scripture before you” (Quran 5:5).", arabic: "وَطَعَامُ ٱلَّذِينَ أُوتُواْ ٱلۡكِتَٰبَ حِلّٞ لَّكُمۡ وَطَعَامُكُمۡ حِلّٞ لَّهُمۡۖ وَٱلۡمُحۡصَنَٰتُ مِنَ ٱلۡمُؤۡمِنَٰتِ وَٱلۡمُحۡصَنَٰتُ مِنَ ٱلَّذِينَ أُوتُواْ ٱلۡكِتَٰبَ مِن قَبۡلِكُمۡ")
                    Text("So a Muslim judges their religion by the Quran while treating their persons with justice and kindness, keeps his word to them, may eat their slaughtered meat and marry their chaste women, and hopes for their guidance, as scholars among them found it, such as Abdullah ibn Salam (may Allah be pleased with him).")
                        .font(.body)

                    Text("**Is one who mocks the religion a kafir?**")
                        .font(.body)
                    Text("Mocking Allah, His verses, or His Messenger is major kufr even when it is said in jest, because it is the opposite of the veneration that faith requires. The ayah quoted above (9:65-66) came down, as Ibn Kathir records in his Tafsir, about a man on the expedition of Tabuk who mocked the reciters among the Companions; when he protested that he was only joking, Allah answered that they had disbelieved after their belief. Allah also forbade sitting with those who ridicule His verses:")
                        .font(.body)
                    ScriptureQuote(text: "“When you hear the verses of Allah [recited], they are denied [by them] and ridiculed; so do not sit with them until they enter into another conversation. Indeed, you would then be like them” (Quran 4:140).", arabic: "إِذَا سَمِعۡتُمۡ ءَايَٰتِ ٱللَّهِ يُكۡفَرُ بِهَا وَيُسۡتَهۡزَأُ بِهَا فَلَا تَقۡعُدُواْ مَعَهُمۡ حَتَّىٰ يَخُوضُواْ فِي حَدِيثٍ غَيۡرِهِۦٓ إِنَّكُمۡ إِذٗا مِّثۡلُهُمۡۗ")
                    Text("The scholars distinguish mocking the religion itself from mocking a religious person in some worldly matter, such as his manner or clothing, which is a sin of the tongue but not kufr. And as with every nullifier, applying the ruling to a specific person is left to those qualified to establish the proof.")
                        .font(.body)

                    Text("**Is a Muslim who commits kufr under compulsion a kafir?**")
                        .font(.body)
                    Text("No, if his heart is at rest with faith, as the ayah quoted above says (16:106). The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah has forgiven my nation for mistakes and forgetfulness, and what they are forced to do” (Sunan Ibn Majah 2045; graded sahih by al-Albani).", arabic: "إِنَّ اللَّهَ وَضَعَ عَنْ أُمَّتِي الْخَطَأَ وَالنِّسْيَانَ وَمَا اسْتُكْرِهُوا عَلَيْهِ", dimmed: true)
                    Text("The mufassirun report that the ayah came down concerning Ammar ibn Yasir (may Allah be pleased with him), whom the pagans of Makkah tortured until he said what they wanted of him. He came to the Prophet (peace be upon him) weeping; the Prophet asked him how he found his heart, he answered that it was at rest with faith, and he was told that if they returned to it he could do the same (Ibn Kathir, Tafsir, under this ayah).")
                        .font(.body)
                    Text("Compulsion (**ikrah**) is real when a person is threatened with death or grievous harm by someone able to carry it out and he has no way out. Ibn Kathir notes that the scholars agreed that the one so compelled may utter the word of kufr to save his life while his heart holds to faith, and that refusing and bearing the harm, as Bilal (may Allah be pleased with him) bore it, is higher. Mere fear for wealth, position, or reputation is not the compulsion the ayah means, and no compulsion ever makes it permissible to kill an innocent person.")
                        .font(.body)

                    Text("**Does a major sin make a Muslim a kafir?**")
                        .font(.body)
                    Text("No. A Muslim who commits a major sin without deeming it lawful is a sinner with deficient faith, not a disbeliever. Allah forgives everything less than shirk for whom He wills (4:48), He called two parties who fight one another believers, and in the law of retaliation He called the killer the brother of the one who may pardon him:")
                        .font(.body)
                    ScriptureQuote(text: "“And if two factions among the believers should fight, then make settlement between the two” (Quran 49:9).", arabic: "وَإِن طَآئِفَتَانِ مِنَ ٱلۡمُؤۡمِنِينَ ٱقۡتَتَلُواْ فَأَصۡلِحُواْ بَيۡنَهُمَاۖ")
                    ScriptureQuote(text: "“But whoever overlooks from his brother anything, then there should be a suitable follow-up and payment to him with good conduct” (Quran 2:178).", arabic: "فَمَنۡ عُفِيَ لَهُۥ مِنۡ أَخِيهِ شَيۡءٞ فَٱتِّبَاعُۢ بِٱلۡمَعۡرُوفِ وَأَدَآءٌ إِلَيۡهِ بِإِحۡسَٰنٖۗ")
                    Text("Abu Dharr (may Allah be pleased with him) narrated that the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“No servant says ‘None has the right to be worshipped but Allah’ and then dies upon that, except that he will enter Paradise.” I said: Even if he had committed illegal sexual intercourse and theft? He said: “Even if he had committed illegal sexual intercourse and theft” (Sahih al-Bukhari 5827).", arabic: "مَا مِنْ عَبْدٍ قَالَ لاَ إِلَهَ إِلاَّ اللَّهُ. ثُمَّ مَاتَ عَلَى ذَلِكَ، إِلاَّ دَخَلَ الْجَنَّةَ. قُلْتُ وَإِنْ زَنَى وَإِنْ سَرَقَ قَالَ وَإِنْ زَنَى وَإِنْ سَرَقَ", dimmed: true)
                    Text("Abu Ja‘far at-Tahawi (may Allah have mercy on him) recorded this as the creed of Ahl as-Sunnah:")
                        .font(.body)
                    ScriptureQuote(text: "“We do not declare anyone of the people of the qiblah a disbeliever because of a sin, as long as he does not deem it lawful” (at-Tahawi, al-Aqidah at-Tahawiyyah).", arabic: "وَلَا نُكَفِّرُ أَحَدًا مِنْ أَهْلِ الْقِبْلَةِ بِذَنْبٍ مَا لَمْ يَسْتَحِلَّهُ", dimmed: true)
                    Text("This was the error of the Khawarij, who made the sinner a disbeliever, and of the Mu‘tazilah, who placed him between the two stations in this world and in the Fire forever in the next. Ahl as-Sunnah say: he is under the will of Allah, forgiven if He wills, punished if He wills, and if he enters the Fire he does not remain in it forever, for the intercession and the mercy of Allah bring out whoever had faith in his heart.")
                        .font(.body)

                    Text("**Can a kafir become Muslim by the shahadah?**")
                        .font(.body)
                    Text("Yes. Whoever testifies that none has the right to be worshipped but Allah and that Muhammad is the Messenger of Allah, understanding it and meaning it, has entered Islam, and everything before it is wiped away:")
                        .font(.body)
                    ScriptureQuote(text: "“Say to those who have disbelieved [that] if they cease, what has previously occurred will be forgiven for them” (Quran 8:38).", arabic: "قُل لِّلَّذِينَ كَفَرُوٓاْ إِن يَنتَهُواْ يُغۡفَرۡ لَهُم مَّا قَدۡ سَلَفَ")
                    Text("The Prophet (peace be upon him) said that whoever testifies to it, establishes the prayer, and gives zakah has made his life and property inviolable except by a right that Islam itself establishes, and his reckoning is with Allah (Sahih al-Bukhari 25, Sahih Muslim 22). And he rebuked Usamah ibn Zayd (may Allah be pleased with him) for killing a man in battle who said it at the last moment:")
                        .font(.body)
                    ScriptureQuote(text: "“O Usamah! Did you kill him after he had said ‘La ilaha illallah’?” I said: But he said so only to save himself. The Prophet kept on repeating it until I wished I had not embraced Islam before that day (Sahih al-Bukhari 4269).", arabic: "يَا أُسَامَةُ أَقَتَلْتَهُ بَعْدَ مَا قَالَ لاَ إِلَهَ إِلاَّ اللَّهُ قُلْتُ كَانَ مُتَعَوِّذًا. فَمَا زَالَ يُكَرِّرُهَا حَتَّى تَمَنَّيْتُ أَنِّي لَمْ أَكُنْ أَسْلَمْتُ قَبْلَ ذَلِكَ الْيَوْمِ", dimmed: true)
                    Text("No ceremony or official is needed for Islam to be valid, though declaring it among Muslims is good; then the new Muslim learns the prayer and takes on the religion step by step. Amr ibn al-As (may Allah be pleased with him) was told that Islam wipes out what came before it (Sahih Muslim 121), so no past sin, however great, bars the door.")
                        .font(.body)

                    Text("**Can a Muslim be a kafir while praying?**")
                        .font(.body)
                    Text("Prayer is the greatest outward mark of Islam, but it is not a guarantee against the nullifiers. The hypocrites of Madinah prayed behind the Prophet (peace be upon him) while Allah counted them among the disbelievers:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, the hypocrites [think to] deceive Allah, but He is deceiving them. And when they stand for prayer, they stand lazily, showing [themselves to] the people and not remembering Allah except a little” (Quran 4:142).", arabic: "إِنَّ ٱلۡمُنَٰفِقِينَ يُخَٰدِعُونَ ٱللَّهَ وَهُوَ خَٰدِعُهُمۡ وَإِذَا قَامُوٓاْ إِلَى ٱلصَّلَوٰةِ قَامُواْ كُسَالَىٰ يُرَآءُونَ ٱلنَّاسَ وَلَا يَذۡكُرُونَ ٱللَّهَ إِلَّا قَلِيلٗا")
                    Text("And another wording of the hadith of the three signs of hypocrisy, quoted above, adds:")
                        .font(.body)
                    ScriptureQuote(text: "“The signs of a hypocrite are three, even if he fasts and prays and claims that he is a Muslim” (Sahih Muslim 59).", arabic: "آيَةُ الْمُنَافِقِ ثَلاَثٌ وَإِنْ صَامَ وَصَلَّى وَزَعَمَ أَنَّهُ مُسْلِمٌ", dimmed: true)
                    Text("Likewise, one who prays but calls upon the dead for what only Allah gives, or practises magic, or mocks the religion, has fallen into what breaks Islam, as the list above shows; shirk voids the deeds it enters (39:65). That is the ruling on the deed itself, and whether a particular person who does it has left Islam still turns on the conditions and impediments already explained, which only the people of knowledge weigh for a given man. In dealing with people the matter is reversed: whoever prays and shows Islam is treated as a Muslim with a Muslim’s full rights, and no one may search his heart:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever prays our prayer, faces our qiblah, and eats our slaughtered animals is a Muslim, and is under the protection of Allah and the protection of His Messenger; so do not betray Allah by betraying those who are in His protection” (Sahih al-Bukhari 391).", arabic: "مَنْ صَلَّى صَلاَتَنَا، وَاسْتَقْبَلَ قِبْلَتَنَا، وَأَكَلَ ذَبِيحَتَنَا، فَذَلِكَ الْمُسْلِمُ الَّذِي لَهُ ذِمَّةُ اللَّهِ وَذِمَّةُ رَسُولِهِ، فَلاَ تُخْفِرُوا اللَّهَ فِي ذِمَّتِهِ", dimmed: true)
                    Text("So the believer worries about his own heart before the hearts of those praying beside him: he guards his prayer from riya’, his creed from shirk, and thinks well of his brothers.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Kufr is covering the truth after it has come. Its nullifiers are known so that they are avoided, not so that Muslims label one another; the door of takfir is guarded by knowledge, conditions, and the scholars.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Kufr")
        .selectableArticleList()
    }
}

struct BidahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: bid'ah is a newly invented matter in the religion, done as worship, that the Prophet and his Companions did not do. Every bid'ah is misguidance, however good it looks, because the religion was completed.")
                        .font(.body)
                }

                Section(header: Text("WHAT IS BID'AH?")) {
                    Text("**Bid‘ah (بِدعَة)** comes from **bada‘a**, to originate something without precedent; Allah is **al-Badi‘**, the Originator of the heavens and the earth. In the religion, a bid‘ah is a newly invented way in worship, intended to draw near to Allah, that has no basis in the Quran, the Sunnah, or the practice of the Companions. Imam al-Shatibi defined it as “an invented way in the religion, resembling the Shari‘ah, by which drawing near to Allah is intended“ (al-I‘tisam 1/37).")
                        .font(.body)

                    Text("It is not about cars, phones, or medicine; those are worldly matters, and the default in worldly things is permission. Bid‘ah is about **worship**, where the default is prohibition until the text permits. Worship is what Allah legislated, not what people find beautiful:")
                        .font(.body)
                    ScriptureQuote(text: "“This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as religion” (Quran 5:3).", arabic: "ٱلۡيَوۡمَ أَكۡمَلۡتُ لَكُمۡ دِينَكُمۡ وَأَتۡمَمۡتُ عَلَيۡكُمۡ نِعۡمَتِي وَرَضِيتُ لَكُمُ ٱلۡإِسۡلَٰمَ دِينٗاۚ")
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Bid‘ah (بِدْعَة)**: from the root ب-د-ع, **bada‘a**, to originate a thing with no prior example. From the same root Allah is named **al-Badi‘ (البَدِيع)**, who brought the heavens and the earth into being with no model before Him:")
                        .font(.body)
                    ScriptureQuote(text: "“Originator of the heavens and the earth” (Quran 2:117).", arabic: "بَدِيعُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ")

                    Text("The Quran uses the same root for the Prophet (peace be upon him) only to deny it of him: he was not a novelty among the messengers, and he followed revelation alone:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘I am not something original among the messengers, nor do I know what will be done with me or with you. I only follow that which is revealed to me’” (Quran 46:9).", arabic: "قُلۡ مَا كُنتُ بِدۡعٗا مِّنَ ٱلرُّسُلِ وَمَآ أَدۡرِي مَا يُفۡعَلُ بِي وَلَا بِكُمۡۖ إِنۡ أَتَّبِعُ إِلَّا مَا يُوحَىٰٓ إِلَيَّ")

                    Text("So the very word carries the idea: originating in the religion belongs to Allah, and the Messenger himself only followed. The religious definition of bid‘ah is the one given in the section above.")
                        .font(.body)

                    Text("**Sunnah (سُنَّة)**: from **sanna**, to lay down a way, and the **sunnah** of a people is their trodden path. In the Shari‘ah it is the way of the Prophet (peace be upon him): his sayings, actions, and approvals. It is revelation, not opinion:")
                        .font(.body)
                    ScriptureQuote(text: "“Nor does he speak from [his own] inclination. It is not but a revelation revealed” (Quran 53:3-4).", arabic: "وَمَا يَنطِقُ عَنِ ٱلۡهَوَىٰٓ ۝ إِنۡ هُوَ إِلَّا وَحۡيٞ يُوحَىٰ")

                    Text("When the Salaf said “Sunnah” as the opposite of “bid‘ah,” they meant the whole way of the Prophet and his Companions in belief and worship, which is why the people of that way are called **Ahl as-Sunnah**.")
                        .font(.body)

                    Text("**Muhdath (مُحْدَث)** and **ahdatha (أَحْدَثَ)**: from **hadatha**, to come into being anew. A **muhdath** is a newly brought thing, and **ahdatha** is to introduce it. This is the very verb of the hadith quoted below, “whoever introduces (ahdatha) into this matter of ours what is not from it, it is rejected” (Sahih al-Bukhari 2697, Sahih Muslim 1718), and the Prophet (peace be upon him) called the worst of matters their **muhdathat**, their newly invented things.")
                        .font(.body)

                    Text("**Bid‘ah lughawiyyah (بِدْعَة لُغَوِيَّة)** and **bid‘ah shar‘iyyah (بِدْعَة شَرْعِيَّة)**: the linguistic and the religious senses of the word. Linguistically, anything not seen before is a bid‘ah, even a revived Sunnah; religiously, only what has no basis in the Shari‘ah is a bid‘ah. This distinction is the key to two famous statements. The first is Umar’s “what an excellent bid‘ah this is” about Tarawih (Sahih al-Bukhari 2010), explained in its own section below. The second is the saying of Imam ash-Shafi‘i (may Allah have mercy on him):")
                        .font(.body)
                    ScriptureQuote(text: "“Innovation is of two kinds: praiseworthy innovation and blameworthy innovation. What agrees with the Sunnah is praiseworthy, and what opposes the Sunnah is blameworthy” (Abu Nu'aym, Hilyat al-Awliya' 9/113).", arabic: "الْبِدْعَةُ بِدْعَتَانِ: بِدْعَةٌ مَحْمُودَةٌ، وَبِدْعَةٌ مَذْمُومَةٌ، فَمَا وَافَقَ السُّنَّةَ فَهُوَ مَحْمُودٌ، وَمَا خَالَفَ السُّنَّةَ فَهُوَ مَذْمُومٌ", dimmed: true)

                    Text("Ibn Rajab al-Hanbali (may Allah have mercy on him) explains, under hadith 28 of Jami‘ al-Ulum wal-Hikam, that ash-Shafi‘i meant by the praiseworthy kind what has a basis in the Shari‘ah to return to, and that such a thing is a bid‘ah only in the language, not in the religion:")
                        .font(.body)
                    ScriptureQuote(text: "“As for what occurs in the words of the Salaf of approving some innovations, that is only in the linguistic sense of innovation, not the religious sense” (Ibn Rajab, Jami' al-Ulum wal-Hikam, hadith 28).", arabic: "وَأَمَّا مَا وَقَعَ فِي كَلَامِ السَّلَفِ مِنِ اسْتِحْسَانِ بَعْضِ الْبِدَعِ، فَإِنَّمَا ذَلِكَ فِي الْبِدَعِ اللُّغَوِيَّةِ لَا الشَّرْعِيَّةِ", dimmed: true)

                    Text("So there is no contradiction between ash-Shafi‘i and the hadith “every innovation is misguidance”: every religious bid‘ah is misguidance, and what agrees with the Sunnah is not a religious bid‘ah at all.")
                        .font(.body)

                    Text("**Bid‘ah mukaffirah (بِدْعَة مُكَفِّرَة)** and **bid‘ah mufassiqah (بِدْعَة مُفَسِّقَة)**: an innovation whose content is itself disbelief, such as denying that Allah knew and decreed all things before they happen, and an innovation that is a sin short of disbelief, such as an invented form of dhikr. When the first deniers of the Decree appeared, Ibn Umar (may Allah be pleased with them both) said:")
                        .font(.body)
                    ScriptureQuote(text: "“When you meet those people, tell them that I am free of them and they are free of me. By the One by whom Abdullah ibn Umar swears, if one of them had the like of Uhud in gold and spent it, Allah would not accept it from him until he believes in the Decree” (Sahih Muslim 8).", arabic: "فَإِذَا لَقِيتَ أُولَئِكَ فَأَخْبِرْهُمْ أَنِّي بَرِيءٌ مِنْهُمْ وَأَنَّهُمْ بُرَآءُ مِنِّي وَالَّذِي يَحْلِفُ بِهِ عَبْدُ اللَّهِ بْنُ عُمَرَ لَوْ أَنَّ لأَحَدِهِمْ مِثْلَ أُحُدٍ ذَهَبًا فَأَنْفَقَهُ مَا قَبِلَ اللَّهُ مِنْهُ حَتَّى يُؤْمِنَ بِالْقَدَرِ", dimmed: true)

                    Text("Judging an innovation to be kufr is one thing; judging a particular person to have left Islam is another, and the second requires that the proof reach him and that no excuse of ignorance, misinterpretation, or compulsion stand in the way. Ahl as-Sunnah are careful here, as the questions below explain.")
                        .font(.body)

                    Text("**Bid‘ah haqiqiyyah (بِدْعَة حَقِيقِيَّة)** and **bid‘ah idafiyyah (بِدْعَة إِضَافِيَّة)**: ash-Shatibi’s division in al-I‘tisam. The **real** innovation has no basis in the Shari‘ah at all, like the monasticism of the Christians:")
                        .font(.body)
                    ScriptureQuote(text: "“and monasticism, which they innovated; We did not prescribe it for them except [that they did so] seeking the approval of Allah. But they did not observe it with due observance” (Quran 57:27).", arabic: "وَرَهۡبَانِيَّةً ٱبۡتَدَعُوهَا مَا كَتَبۡنَٰهَا عَلَيۡهِمۡ إِلَّا ٱبۡتِغَآءَ رِضۡوَٰنِ ٱللَّهِ فَمَا رَعَوۡهَا حَقَّ رِعَايَتِهَاۖ")

                    Text("The **relative** innovation is legislated in its origin but invented in its manner, time, number, or place: dhikr is legislated, but dhikr chanted in unison at a fixed count on a fixed night is not. Most innovations in the Muslim world are of this second kind, and ash-Shatibi explains that they are still innovations, because the added specification is itself a claim about the religion that the Lawgiver never made.")
                        .font(.body)

                    Text("**Maslahah mursalah (مَصْلَحَة مُرْسَلَة)**: an unrestricted benefit, a means that the texts neither commanded nor forbade in particular, adopted to protect what the Shari‘ah does demand. Ash-Shatibi separates it from bid‘ah in al-I‘tisam: it belongs to means, not to worship, and it serves an established objective. The clearest example is the gathering of the written Quran into one Mushaf under Abu Bakr and Uthman, explained in the questions below. Another is that when the people became many, Uthman (may Allah be pleased with him) added a call before the Friday prayer:")
                        .font(.body)
                    ScriptureQuote(text: "“The call on Friday used to begin when the imam sat on the pulpit, in the time of the Prophet, Abu Bakr, and Umar. Then in the time of Uthman, when the people became many, he added the third call at az-Zawra'” (Sahih al-Bukhari 912).", arabic: "كَانَ النِّدَاءُ يَوْمَ الْجُمُعَةِ أَوَّلُهُ إِذَا جَلَسَ الإِمَامُ عَلَى الْمِنْبَرِ عَلَى عَهْدِ النَّبِيِّ صلى الله عليه وسلم وَأَبِي بَكْرٍ وَعُمَرَ ـ رضى الله عنهما ـ فَلَمَّا كَانَ عُثْمَانُ ـ رضى الله عنه ـ وَكَثُرَ النَّاسُ زَادَ النِّدَاءَ الثَّالِثَ عَلَى الزَّوْرَاءِ", dimmed: true)

                    Text("That was the act of a rightly guided caliph whose Sunnah we were commanded to hold to, done as a means of gathering people for a legislated prayer. It is not a licence to invent worship.")
                        .font(.body)

                    Text("**Sunnah hasanah (سُنَّة حَسَنَة)**: a good practice, from the hadith “whoever starts in Islam a good practice” (Sahih Muslim 1017). Its context settles its meaning: a Companion of the Ansar was the first to bring a purse of silver in charity after the Prophet (peace be upon him) had urged the people, and the rest followed him. So the good practice was the reviving of a legislated act, charity, not the invention of a new one. The hadith is quoted and explained in the questions below.")
                        .font(.body)

                    Text("**Ahl al-Bid‘ah (أَهْل البِدْعَة)**: the people of innovation, those whose way in belief or worship departs from the way of the Prophet and his Companions, in contrast to Ahl as-Sunnah wal-Jama‘ah. The Salaf used the term for groups like the Khawarij, the Qadariyyah, and the Murji’ah, while still distinguishing between a caller to innovation and an ordinary Muslim who fell into something without knowing.")
                        .font(.body)

                    Text("**The three praised generations (القُرُون المُفَضَّلَة)**: the Companions, the Tabi‘un, and those who followed them. The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The best of people are my generation, then those who follow them, then those who follow them” (Sahih al-Bukhari 2652).", arabic: "خَيْرُ النَّاسِ قَرْنِي، ثُمَّ الَّذِينَ يَلُونَهُمْ، ثُمَّ الَّذِينَ يَلُونَهُمْ", dimmed: true)
                    ScriptureQuote(text: "“And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).", arabic: "وَٱلسَّٰبِقُونَ ٱلۡأَوَّلُونَ مِنَ ٱلۡمُهَٰجِرِينَ وَٱلۡأَنصَارِ وَٱلَّذِينَ ٱتَّبَعُوهُم بِإِحۡسَٰنٖ رَّضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُ")

                    Text("Their practice is the measure of the Sunnah, and their leaving of a thing, when they could have done it, is itself a proof that leaving it is the Sunnah. This is the principle Ibn Taymiyyah built on in Iqtida’ as-Sirat al-Mustaqim.")
                        .font(.body)

                    Text("**Ittiba‘ (اتِّبَاع)**: following, from **tabi‘a**, to walk behind. It is the opposite of **ibtida‘**, innovating. Allah commanded:")
                        .font(.body)
                    ScriptureQuote(text: "“Follow, [O mankind], what has been revealed to you from your Lord and do not follow other than Him any allies” (Quran 7:3).", arabic: "ٱتَّبِعُواْ مَآ أُنزِلَ إِلَيۡكُم مِّن رَّبِّكُمۡ وَلَا تَتَّبِعُواْ مِن دُونِهِۦٓ أَوۡلِيَآءَۗ")

                    Text("**Istihsan (اسْتِحْسَان)**: deeming a thing good. Among the jurists it is a technical term for preferring one ruling over an apparent analogy because of a stronger proof, and its scope is disputed. In the mouth of the innovator it means “I see this as good,” the very word Imam Malik answered in the section “Why it is so serious” below. Ash-Shafi‘i (may Allah have mercy on him) said, as al-Ghazali reports in al-Mustasfa:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever deems a thing good has legislated” (ash-Shafi'i, as reported by al-Ghazali in al-Mustasfa).", arabic: "مَنِ اسْتَحْسَنَ فَقَدْ شَرَّعَ", dimmed: true)
                    Text("In worship, what is good is what Allah and His Messenger called good, and nothing else.")
                        .font(.body)
                }

                Section(header: Text("EVERY BID'AH IS MISGUIDANCE")) {
                    Text("The Prophet (peace be upon him) used to say in his sermons:")
                        .font(.body)
                    ScriptureQuote(text: "“The best speech is the Book of Allah, and the best guidance is the guidance of Muhammad. The worst of matters are the newly invented ones, and every innovation is misguidance” (Sahih Muslim 867).", arabic: "فَإِنَّ خَيْرَ الْحَدِيثِ كِتَابُ اللَّهِ وَخَيْرُ الْهُدَى هُدَى مُحَمَّدٍ وَشَرُّ الأُمُورِ مُحْدَثَاتُهَا وَكُلُّ بِدْعَةٍ ضَلاَلَةٌ", dimmed: true)

                    ScriptureQuote(text: "“Whoever introduces into this matter of ours what is not from it, it is rejected” (Sahih al-Bukhari 2697, Sahih Muslim 1718).", arabic: "مَنْ أَحْدَثَ فِي أَمْرِنَا هَذَا مَا لَيْسَ فِيهِ فَهُوَ رَدٌّ", dimmed: true)

                    ScriptureQuote(text: "“Hold fast to my Sunnah and the Sunnah of the rightly guided caliphs after me. Cling to it with your molar teeth, and beware of newly invented matters, for every newly invented matter is an innovation, and every innovation is misguidance” (Sunan Abi Dawud 4607; graded sahih by al-Albani).", arabic: "فَعَلَيْكُمْ بِسُنَّتِي وَسُنَّةِ الْخُلَفَاءِ الْمَهْدِيِّينَ الرَّاشِدِينَ تَمَسَّكُوا بِهَا وَعَضُّوا عَلَيْهَا بِالنَّوَاجِذِ وَإِيَّاكُمْ وَمُحْدَثَاتِ الأُمُورِ فَإِنَّ كُلَّ مُحْدَثَةٍ بِدْعَةٌ وَكُلَّ بِدْعَةٍ ضَلاَلَةٌ", dimmed: true)

                    Text("Note the word **every**. The Prophet (peace be upon him) did not divide innovations in worship into good and bad; he said every one is misguidance. The Companions understood him that way. Ibn Umar (may Allah be pleased with them both) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Every innovation is misguidance, even if the people see it as good” (al-Lalaka'i, Sharh Usul I'tiqad Ahl as-Sunnah 126; Ibn Battah, al-Ibanah 205).", arabic: "كُلُّ بِدْعَةٍ ضَلَالَةٌ وَإِنْ رَآهَا النَّاسُ حَسَنَةً", dimmed: true)

                    Text("Ibn Mas‘ud (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Follow, and do not innovate, for you have been sufficed” (Sunan al-Darimi 207; al-Haythami: its narrators are those of the Sahih, Majma' az-Zawa'id 1/181).", arabic: "اتَّبِعُوا، وَلَا تَبْتَدِعُوا، فَقَدْ كُفِيتُمْ", dimmed: true)

                    Text("Hudhayfah ibn al-Yaman (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Every act of worship that the Companions of the Messenger of Allah did not perform, do not perform it” (Ibn Battah, al-Ibanah al-Kubra; Abu Dawud, az-Zuhd).", arabic: "كُلُّ عِبَادَةٍ لَمْ يَتَعَبَّدْهَا أَصْحَابُ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ فَلَا تَعَبَّدُوهَا", dimmed: true)
                }

                Section(header: Text("THE COMPANIONS IN ACTION")) {
                    Text("Abu Musa al-Ash‘ari (may Allah be pleased with him) came to Ibn Mas‘ud and told him he had seen, in the mosque of Kufah, circles of people sitting with pebbles in their hands while a man said, “Say Allahu akbar a hundred times,“ “Say la ilaha illallah a hundred times,“ “Say subhanallah a hundred times.“ Ibn Mas‘ud went to them and said:")
                        .font(.body)
                    ScriptureQuote(text: "“Count your sins, and I guarantee that nothing of your good deeds will be lost. Woe to you, O nation of Muhammad, how quickly is your destruction! These are the Companions of your Prophet, plentiful; these are his garments not yet worn out and his vessels not yet broken. By the One in whose hand is my soul, either you are upon a religion more guided than the religion of Muhammad, or you are opening a door of misguidance.” They said: By Allah, O Abu Abd al-Rahman, we intended nothing but good. He said: “How many intend good and never reach it” (Sunan al-Darimi 206; graded sahih by al-Albani, as-Silsilah as-Sahihah 2005).", arabic: "فَعُدُّوا سَيِّئَاتِكُمْ، فَأَنَا ضَامِنٌ أَنْ لَا يَضِيعَ مِنْ حَسَنَاتِكُمْ شَيْءٌ، وَيْحَكُمْ يَا أُمَّةَ مُحَمَّدٍ، مَا أَسْرَعَ هَلَكَتَكُمْ ! هَؤُلَاءِ صَحَابَةُ نَبِيِّكُمْ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ مُتَوَافِرُونَ، وَهَذِهِ ثِيَابُهُ لَمْ تَبْلَ، وَآنِيَتُهُ لَمْ تُكْسَرْ، وَالَّذِي نَفْسِي بِيَدِهِ، إِنَّكُمْ لَعَلَى مِلَّةٍ هِيَ أَهْدَى مِنْ مِلَّةِ مُحَمَّدٍ، أَوْ مُفْتَتِحُو بَابِ ضَلَالَةٍ، قَالُوا : وَاللَّهِ يَا أَبَا عَبْدِ الرَّحْمَنِ، مَا أَرَدْنَا إِلَّا الْخَيْرَ، قَالَ : وَكَمْ مِنْ مُرِيدٍ لِلْخَيْرِ لَنْ يُصِيبَهُ", dimmed: true)

                    Text("They were saying words of remembrance, in a mosque, intending good, and a Companion called it a door of misguidance, because the **manner** was invented. This is the measure: sincerity is not enough; the act must also be according to the Sunnah.")
                        .font(.body)
                }

                Section(header: Text("“BUT UMAR CALLED TARAWIH A GOOD BID'AH”")) {
                    Text("When Umar (may Allah be pleased with him) gathered the people behind one reciter in Ramadan, he said, “What an excellent bid‘ah this is“ (Sahih al-Bukhari 2010). This is the usual argument for “good innovation,“ and it fails, because the Prophet (peace be upon him) had himself led the people in Tarawih for three nights and then stopped only for fear it would be made obligatory:")
                        .font(.body)
                    ScriptureQuote(text: "“I saw what you did, and nothing prevented me from coming out to you except that I feared it would be made obligatory upon you” (Sahih al-Bukhari 1129, Sahih Muslim 761).", arabic: "قَدْ رَأَيْتُ الَّذِي صَنَعْتُمْ وَلَمْ يَمْنَعْنِي مِنَ الْخُرُوجِ إِلَيْكُمْ إِلاَّ أَنِّي خَشِيتُ أَنْ تُفْرَضَ عَلَيْكُمْ", dimmed: true)

                    Text("Once revelation ended, that fear was gone, so Umar revived a Sunnah the Prophet (peace be upon him) had established. He called it a bid‘ah in the **linguistic** sense, something not seen for a while, not in the religious sense. The Prophet’s words “every innovation is misguidance“ are not contradicted by a Companion reviving the Prophet’s own practice.")
                        .font(.body)
                }

                Section(header: Text("WHY IT IS SO SERIOUS")) {
                    Text("Imam Malik (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever innovates in Islam an innovation that he sees as good has claimed that Muhammad betrayed the message, for Allah says, ‘This day I have perfected for you your religion.’ So whatever was not religion that day is not religion today” (al-Shatibi, al-I'tisam 1/64).", arabic: "مَنِ ابْتَدَعَ فِي الْإِسْلَامِ بِدْعَةً يَرَاهَا حَسَنَةً فَقَدْ زَعَمَ أَنَّ مُحَمَّدًا صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ خَانَ الرِّسَالَةَ، لِأَنَّ اللَّهَ يَقُولُ: ﴿الْيَوْمَ أَكْمَلْتُ لَكُمْ دِينَكُمْ﴾ فَمَا لَمْ يَكُنْ يَوْمَئِذٍ دِينًا فَلَا يَكُونُ الْيَوْمَ دِينًا", dimmed: true)

                    Text("Sufyan al-Thawri (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Innovation is more beloved to Iblis than sin, for sin is repented from, and innovation is not repented from” (Abu Nu'aym, Hilyat al-Awliya' 7/26; al-Lalaka'i 238).", arabic: "الْبِدْعَةُ أَحَبُّ إِلَى إِبْلِيسَ مِنَ الْمَعْصِيَةِ، الْمَعْصِيَةُ يُتَابُ مِنْهَا، وَالْبِدْعَةُ لَا يُتَابُ مِنْهَا", dimmed: true)

                    Text("The sinner knows he is sinning and may repent; the innovator thinks he is worshipping, so he never repents. And an innovation always crowds out a Sunnah: the effort and love that should have gone to what the Prophet (peace be upon him) taught go to what he never taught.")
                        .font(.body)
                }

                Section(header: Text("EXAMPLES")) {
                    Text("Celebrating the Prophet’s birthday (see “The Mawlid“); set congregational dhikr chanted in unison or with movements; fixing acts of worship to times and numbers the Sunnah did not fix, such as special prayers for the night of the fifteenth of Sha‘ban; building over graves and travelling to them for blessing; reciting the intention aloud before prayer; and adding words to the adhan. Each was measured by the Salaf against the same question: did the Prophet and his Companions do it, when they could have?")
                        .font(.body)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Are cars, phones, microphones, and printed Mushafs bid‘ah?**")
                        .font(.body)
                    Text("No. Bid‘ah is in the religion, in what is done to draw near to Allah. Worldly means are judged by a different rule. When the Prophet (peace be upon him) gave the people of Madinah an opinion about pollinating their date palms and the crop failed, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“You have better knowledge of the affairs of your world” (Sahih Muslim 2363).", arabic: "أَنْتُمْ أَعْلَمُ بِأَمْرِ دُنْيَاكُمْ", dimmed: true)
                    Text("Ibn Taymiyyah (may Allah have mercy on him) set out the rule in Majmu‘ al-Fatawa: in acts of worship the default is restriction, so nothing is legislated except what Allah legislated, while in customs and worldly dealings the default is permission, so nothing is forbidden except what Allah forbade. A microphone carries the adhan; it does not add to it. A printed Mushaf carries the Quran; it does not add to it. The test of bid‘ah is whether the **act of worship** itself has been changed, not whether the tools around it are new.")
                        .font(.body)

                    Text("**Was compiling the Quran into one book a bid‘ah?**")
                        .font(.body)
                    Text("No, and the objection was raised by the Companions themselves, twice, and answered twice. After many reciters were killed at al-Yamamah, Umar urged Abu Bakr to gather the Quran. Abu Bakr later told Zayd ibn Thabit (may Allah be pleased with them all) what had passed between them:")
                        .font(.body)
                    ScriptureQuote(text: "“I said to Umar, ‘How can you do something which the Messenger of Allah did not do?’ Umar said, ‘By Allah, it is good.’ Umar kept urging me until Allah opened my chest to it, and I saw in it what Umar saw” (Sahih al-Bukhari 4986).", arabic: "قُلْتُ لِعُمَرَ كَيْفَ تَفْعَلُ شَيْئًا لَمْ يَفْعَلْهُ رَسُولُ اللَّهِ صلى الله عليه وسلم قَالَ عُمَرُ هَذَا وَاللَّهِ خَيْرٌ. فَلَمْ يَزَلْ عُمَرُ يُرَاجِعُنِي حَتَّى شَرَحَ اللَّهُ صَدْرِي لِذَلِكَ، وَرَأَيْتُ فِي ذَلِكَ الَّذِي رَأَى عُمَرُ", dimmed: true)
                    Text("Then Abu Bakr charged Zayd, who had been one of the Prophet’s scribes of revelation, with the task, and Zayd raised the same objection:")
                        .font(.body)
                    ScriptureQuote(text: "“I said, ‘How will you do something which the Messenger of Allah did not do?’ He said, ‘By Allah, it is good.’ Abu Bakr kept urging me until Allah opened my chest for that for which He had opened the chests of Abu Bakr and Umar. So I searched out the Quran, gathering it from palm stalks, thin stones, and the memories of men” (Sahih al-Bukhari 4986).", arabic: "قُلْتُ كَيْفَ تَفْعَلُونَ شَيْئًا لَمْ يَفْعَلْهُ رَسُولُ اللَّهِ صلى الله عليه وسلم قَالَ هُوَ وَاللَّهِ خَيْرٌ فَلَمْ يَزَلْ أَبُو بَكْرٍ يُرَاجِعُنِي حَتَّى شَرَحَ اللَّهُ صَدْرِي لِلَّذِي شَرَحَ لَهُ صَدْرَ أَبِي بَكْرٍ وَعُمَرَ ـ رضى الله عنهما ـ فَتَتَبَّعْتُ الْقُرْآنَ أَجْمَعُهُ مِنَ الْعُسُبِ وَاللِّخَافِ وَصُدُورِ الرِّجَالِ", dimmed: true)
                    Text("Three things make this a preservation and not an invention. First, the Prophet (peace be upon him) had the Quran written down in his own lifetime by his scribes, of whom Zayd was one, as the same hadith says (“you used to write the revelation for the Messenger of Allah”), and he forbade writing anything else so that the Quran would stand alone:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not write from me; and whoever has written from me anything other than the Quran, let him erase it” (Sahih Muslim 3004).", arabic: "لاَ تَكْتُبُوا عَنِّي وَمَنْ كَتَبَ عَنِّي غَيْرَ الْقُرْآنِ فَلْيَمْحُهُ", dimmed: true)
                    Text("Second, what Abu Bakr did was gather those already written pieces into one place, checked against the memories of the Companions, so that an obligation, guarding the Quran, would be fulfilled. Third, the Mushaf is not itself an act of worship: no one prays to it, reads it on an appointed night, or believes the codex brings reward. It is a means, and a means takes the ruling of its aim. This is exactly the **maslahah mursalah** described in the key terms, and ash-Shatibi uses it as the example that shows the difference between a means and a bid‘ah.")
                        .font(.body)

                    Text("**What about Umar and Tarawih?**")
                        .font(.body)
                    Text("Umar (may Allah be pleased with him) gathered the people behind one reciter for a prayer the Prophet (peace be upon him) had himself led in congregation and left only for fear of its being made obligatory, so he called it a bid‘ah in the linguistic sense, as the section above explains.")
                        .font(.body)

                    Text("**What about “whoever starts a good sunnah”?**")
                        .font(.body)
                    Text("The full hadith, with its context, is the answer. Some poor Bedouins came to the Prophet (peace be upon him); he urged the people to give charity and they were slow, until a man of the Ansar brought a purse of silver, then another, then the rest followed and his face lit up. Then he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever starts in Islam a good practice and it is acted upon after him, there is written for him a reward like that of those who act upon it, without their rewards being diminished in anything; and whoever starts in Islam an evil practice and it is acted upon after him, there is written upon him a burden like that of those who act upon it, without their burdens being diminished in anything” (Sahih Muslim 1017).", arabic: "مَنْ سَنَّ فِي الإِسْلاَمِ سُنَّةً حَسَنَةً فَعُمِلَ بِهَا بَعْدَهُ كُتِبَ لَهُ مِثْلُ أَجْرِ مَنْ عَمِلَ بِهَا وَلاَ يَنْقُصُ مِنْ أُجُورِهِمْ شَىْءٌ وَمَنْ سَنَّ فِي الإِسْلاَمِ سُنَّةً سَيِّئَةً فَعُمِلَ بِهَا بَعْدَهُ كُتِبَ عَلَيْهِ مِثْلُ وِزْرِ مَنْ عَمِلَ بِهَا وَلاَ يَنْقُصُ مِنْ أَوْزَارِهِمْ شَىْءٌ", dimmed: true)
                    Text("The “good practice” was charity, which Allah had already legislated; the man was the first to act, and the others followed. So **sanna** here means to be the first to do, or to revive, a legislated deed. Three points confirm it. The hadith says “in Islam,” and an innovation is not from Islam. The same hadith speaks of an “evil practice,” so the Prophet (peace be upon him) is not authorising whatever people call good; the Shari‘ah is what decides which is which. And the same Prophet said “every innovation is misguidance” in the same religion; his words do not contradict each other, so the one is understood in the light of the other. Ibn al-Uthaymin (may Allah have mercy on him) explains the hadith this way in al-Ibda‘ fi Kamal ash-Shar‘.")
                        .font(.body)

                    Text("**Is celebrating the Prophet’s birthday, the night of Isra’ and Mi‘raj, or the middle of Sha‘ban a bid‘ah?**")
                        .font(.body)
                    Text("Yes, as festivals and as gatherings of appointed worship, because no act of worship was legislated for those nights. The Mawlid has its own page. For the night of the Isra’, Ibn al-Qayyim writes in Zad al-Ma‘ad that no established report fixes its month, its ten-day period, or its night, and the Companions, who knew the event best, singled out no night for it with any worship. For the middle of Sha‘ban, Ibn Rajab records in Lata’if al-Ma‘arif that some of the Tabi‘un of Syria revered the night with their own worship, while most of the scholars of the Hijaz, among them Ata’ and Ibn Abi Mulaykah, and the jurists of Madinah and the companions of Malik, rejected gathering in the mosques for it and called all of that an innovation; and no particular prayer or gathering for it is established from the Prophet (peace be upon him) or his Companions. Whatever is said about the reports of Allah’s forgiveness on that night, none of them contains a command to gather, to pray a particular prayer, or to fast that day in particular. Fasting in Sha‘ban generally, and praying at night generally, are Sunnah on every night of the year.")
                        .font(.body)

                    Text("**Is group dhikr in unison, or dhikr with beads, bid‘ah?**")
                        .font(.body)
                    Text("Dhikr chanted together at a set count is the very thing Ibn Mas‘ud condemned in the Kufah mosque, as related above, and he did not accept “we intended nothing but good” as an answer. What the Prophet (peace be upon him) taught was counting on the fingers:")
                        .font(.body)
                    ScriptureQuote(text: "“The Prophet (peace be upon him) commanded them to be constant in takbir, taqdis, and tahlil, and to count on the fingers, for they will be questioned and made to speak” (Sunan Abi Dawud 1501; graded hasan by al-Albani).", arabic: "أَنَّ النَّبِيَّ صلى الله عليه وسلم أَمَرَهُنَّ أَنْ يُرَاعِينَ بِالتَّكْبِيرِ وَالتَّقْدِيسِ وَالتَّهْلِيلِ وَأَنْ يَعْقِدْنَ بِالأَنَامِلِ فَإِنَّهُنَّ مَسْئُولاَتٌ مُسْتَنْطَقَاتٌ", dimmed: true)
                    Text("The report praising the rosary is not authentic; al-Albani judged it fabricated (as-Silsilah ad-Da‘ifah 83). The gatherings of remembrance that the Prophet (peace be upon him) praised are real, but they are gatherings of the Quran, of knowledge, and of each person remembering Allah as he taught, not invented chants:")
                        .font(.body)
                    ScriptureQuote(text: "“No people sit remembering Allah, the Mighty and Majestic, but the angels surround them, mercy covers them, tranquillity descends upon them, and Allah mentions them to those who are with Him” (Sahih Muslim 2700).", arabic: "لاَ يَقْعُدُ قَوْمٌ يَذْكُرُونَ اللَّهَ عَزَّ وَجَلَّ إِلاَّ حَفَّتْهُمُ الْمَلاَئِكَةُ وَغَشِيَتْهُمُ الرَّحْمَةُ وَنَزَلَتْ عَلَيْهِمُ السَّكِينَةُ وَذَكَرَهُمُ اللَّهُ فِيمَنْ عِنْدَهُ", dimmed: true)
                    Text("The Companions sat in such gatherings, and none of them swayed, chanted a fixed number in one voice, or appointed a leader to call out the count. Remember Allah as much as you can, in your own voice, and you have the whole of that reward.")
                        .font(.body)

                    Text("**Is the one who innovates a disbeliever?**")
                        .font(.body)
                    Text("No, unless the innovation is itself disbelief and the conditions of takfir are met in his case. Ahl as-Sunnah are the most careful of people about this, because the Prophet (peace be upon him) warned:")
                        .font(.body)
                    ScriptureQuote(text: "“If a man says to his brother, ‘O disbeliever,’ then one of the two returns with it” (Sahih al-Bukhari 6103).", arabic: "إِذَا قَالَ الرَّجُلُ لأَخِيهِ يَا كَافِرُ فَقَدْ بَاءَ بِهِ أَحَدُهُمَا", dimmed: true)
                    Text("Imam Ahmad, who was imprisoned and beaten by rulers calling to the innovation that the Quran is created, prayed for them, sought forgiveness for them, and did not declare them disbelievers as individuals, as Ibn Taymiyyah records in Majmu‘ al-Fatawa. But not being a disbeliever is not the same as being safe. The Prophet (peace be upon him) described people driven away from his Pool on the Day of Judgement:")
                        .font(.body)
                    ScriptureQuote(text: "“I will say: They are of me. It will be said: You do not know what they innovated after you. So I will say: Away, away with those who changed after me” (Sahih al-Bukhari 6584, Sahih Muslim 2290).", arabic: "فَأَقُولُ إِنَّهُمْ مِنِّي. فَيُقَالُ إِنَّكَ لاَ تَدْرِي مَا أَحْدَثُوا بَعْدَكَ. فَأَقُولُ سُحْقًا سُحْقًا لِمَنْ غَيَّرَ بَعْدِي", dimmed: true)
                    Text("So the innovator is a Muslim who has been warned, and we hope for his repentance and pray for him; we do not take his innovation, and we do not make him a disbeliever.")
                        .font(.body)

                    Text("**Is every voluntary act of worship the Prophet did not do a bid‘ah?**")
                        .font(.body)
                    Text("No. The Shari‘ah contains general commands: pray extra, fast extra, give charity, recite the Quran, remember Allah, and it left the amount open. The Prophet (peace be upon him) said to Rabi‘ah ibn Ka‘b, who asked to be his companion in Paradise:")
                        .font(.body)
                    ScriptureQuote(text: "“Help me for yourself with much prostration” (Sahih Muslim 489).", arabic: "فَأَعِنِّي عَلَى نَفْسِكَ بِكَثْرَةِ السُّجُودِ", dimmed: true)
                    Text("And when he heard Bilal’s footsteps in Paradise and asked him about his most hopeful deed, Bilal said:")
                        .font(.body)
                    ScriptureQuote(text: "“I have not done any deed more hopeful to me than that I never purified myself at any hour of the night or day except that I prayed with that purification what was written for me to pray” (Sahih al-Bukhari 1149).", arabic: "مَا عَمِلْتُ عَمَلاً أَرْجَى عِنْدِي أَنِّي لَمْ أَتَطَهَّرْ طُهُورًا فِي سَاعَةِ لَيْلٍ أَوْ نَهَارٍ إِلاَّ صَلَّيْتُ بِذَلِكَ الطُّهُورِ مَا كُتِبَ لِي أَنْ أُصَلِّيَ", dimmed: true)
                    Text("Bilal chose to pray after every wudu, and the Prophet (peace be upon him) approved it, because voluntary prayer after wudu is legislated in general and Bilal added no new form, number, or claim to it. Bid‘ah begins when a person **specifies** what the Shari‘ah left open, or opens what the Shari‘ah restricted: a prayer on a fixed night with a fixed number of rak‘ahs and a fixed recitation, a dhikr with a fixed count in a fixed gathering, a fast tied to a date the Sunnah never tied it to. Ibn al-Uthaymin (may Allah have mercy on him) summarised the conditions of following in al-Ibda‘ fi Kamal ash-Shar‘: the act must agree with the Shari‘ah in its cause, kind, amount, manner, time, and place. Where all six are as the Sunnah left them, the act is Sunnah; where one is invented, the act is bid‘ah even if its origin is legislated.")
                        .font(.body)

                    Text("**Why is bid‘ah worse than an ordinary sin?**")
                        .font(.body)
                    Text("Sufyan ath-Thawri’s words above give the reason: the sinner knows he is disobeying and may repent, while the innovator thinks he is obeying and therefore never turns back. Allah described such people:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘Shall we [believers] inform you of the greatest losers as to [their] deeds? [They are] those whose effort is lost in worldly life, while they think that they are doing well in work’” (Quran 18:103-104).", arabic: "قُلۡ هَلۡ نُنَبِّئُكُم بِٱلۡأَخۡسَرِينَ أَعۡمَٰلًا ۝ ٱلَّذِينَ ضَلَّ سَعۡيُهُمۡ فِي ٱلۡحَيَوٰةِ ٱلدُّنۡيَا وَهُمۡ يَحۡسَبُونَ أَنَّهُمۡ يُحۡسِنُونَ صُنۡعًا")
                    Text("A bid‘ah also does what a sin does not: it changes the religion itself for those who come after.")
                        .font(.body)

                    Text("**Is following a madhhab or a scholar a bid‘ah?**")
                        .font(.body)
                    Text("No. Learning the religion from those who know it is commanded:")
                        .font(.body)
                    ScriptureQuote(text: "“So ask the people of the message if you do not know” (Quran 16:43).", arabic: "فَسۡـَٔلُوٓاْ أَهۡلَ ٱلذِّكۡرِ إِن كُنتُمۡ لَا تَعۡلَمُونَ")
                    Text("The Companions themselves followed the verdicts of the scholars among them, and the four imams are trusted inheritors of the Sunnah whose schools preserved the fiqh of the Salaf. What the imams forbade was clinging to a man’s opinion after the Prophet’s word is known to oppose it. Ash-Shafi‘i (may Allah have mercy on him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If the hadith is authentic, then it is my madhhab” (an-Nawawi, al-Majmu', introduction).", arabic: "إِذَا صَحَّ الْحَدِيثُ فَهُوَ مَذْهَبِي", dimmed: true)
                    Text("Similar statements from Abu Hanifah, Malik, and Ahmad are gathered by al-Albani in the introduction to Sifat Salat an-Nabi. So follow a madhhab or a scholar as a way of reaching the Sunnah, and let the Sunnah, not the man, be the final word.")
                        .font(.body)

                    Text("**How do I avoid bid‘ah?**")
                        .font(.body)
                    Text("Learn the Sunnah, for a person avoids what he can recognise. Take the Quran and the authentic hadith as the reference in every dispute:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you disagree over anything, refer it to Allah and the Messenger, if you should believe in Allah and the Last Day” (Quran 4:59).", arabic: "فَإِن تَنَٰزَعۡتُمۡ فِي شَيۡءٖ فَرُدُّوهُ إِلَى ٱللَّهِ وَٱلرَّسُولِ إِن كُنتُمۡ تُؤۡمِنُونَ بِٱللَّهِ وَٱلۡيَوۡمِ ٱلۡأٓخِرِۚ")
                    Text("Ask of every act of worship one question: did the Prophet (peace be upon him) and his Companions do it, when they could have? If they did not, leave it, as Hudhayfah said above. Remember that the religion was completed in the Prophet’s lifetime, as the verse quoted at the top of this page says, so nothing that came later can be part of it. Hold to the counsel of Sunan Abi Dawud 4607 quoted above, to beware of newly invented matters, and keep to one path:")
                        .font(.body)
                    ScriptureQuote(text: "“And, [moreover], this is My path, which is straight, so follow it; and do not follow [other] ways, for you will be separated from His way” (Quran 6:153).", arabic: "وَأَنَّ هَٰذَا صِرَٰطِي مُسۡتَقِيمٗا فَٱتَّبِعُوهُۖ وَلَا تَتَّبِعُواْ ٱلسُّبُلَ فَتَفَرَّقَ بِكُمۡ عَن سَبِيلِهِۦۚ")
                    Text("Keep the company of people of the Sunnah, take knowledge from scholars known for it, and ask Allah every day in al-Fatihah for the straight path of those He favoured, not the path of those who went astray.")
                        .font(.body)

                    Text("**Is Salah in a new mosque, or using a printed calendar for prayer times, bid‘ah?**")
                        .font(.body)
                    Text("No. Both are means, and a means takes the ruling of what it serves, as Ibn al-Qayyim explains in I‘lam al-Muwaqqi‘in. Umar and Uthman extended and rebuilt the Prophet’s own mosque, changing its pillars and roof (Sahih al-Bukhari 446), and no Companion called that a bid‘ah, because the prayer inside it was unchanged. A calendar calculates the times that the Shari‘ah fixed by the sun; the Companions measured them by shadows, and calculation is a more precise tool for the same legislated times. Bid‘ah would be to move the prayer to a time or a form the Shari‘ah did not set, not to use a better way of knowing the time it did set.")
                        .font(.body)

                    Text("**How should I speak to someone who does a bid‘ah?**")
                        .font(.body)
                    Text("With knowledge, gentleness, and proof, remembering that most people do it out of love for Allah and His Messenger and simply have not been taught. Allah commanded:")
                        .font(.body)
                    ScriptureQuote(text: "“Invite to the way of your Lord with wisdom and good instruction, and argue with them in a way that is best” (Quran 16:125).", arabic: "ٱدۡعُ إِلَىٰ سَبِيلِ رَبِّكَ بِٱلۡحِكۡمَةِ وَٱلۡمَوۡعِظَةِ ٱلۡحَسَنَةِۖ وَجَٰدِلۡهُم بِٱلَّتِي هِيَ أَحۡسَنُۚ")
                    Text("Ibn Mas‘ud rebuked the people of the circles firmly, but he first heard them out, and they were Muslims who intended good. Firmness against the innovation and kindness toward the person go together; harshness that drives a person away from the Sunnah defeats its own purpose.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Worship is what Allah legislated. Anything added to it, however sincere, is a claim that the religion was incomplete, and the Prophet said every such addition is misguidance. The safe road is the one he and his Companions walked.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Bid'ah")
        .selectableArticleList()
    }
}

struct MawlidView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Prophet, his Companions, the Successors, and the four imams never celebrated his birthday. The mawlid appeared centuries later, so it is an innovation, and love for the Prophet is shown by following him.")
                        .font(.body)
                }

                Section(header: Text("WHAT IS THE MAWLID?")) {
                    Text("The **Mawlid (المَولِد)** is the celebration of the Prophet’s birthday (peace be upon him), usually on the twelfth of Rabi‘ al-Awwal, with gatherings, poems in his praise, food, and sometimes standing when his birth is mentioned.")
                        .font(.body)

                    Text("Loving him is an obligation and a condition of faith:")
                        .font(.body)
                    ScriptureQuote(text: "“None of you believes until I am more beloved to him than his father, his child, and all of mankind” (Sahih al-Bukhari 15, Sahih Muslim 44).", arabic: "لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى أَكُونَ أَحَبَّ إِلَيْهِ مِنْ وَالِدِهِ وَوَلَدِهِ وَالنَّاسِ أَجْمَعِينَ", dimmed: true)

                    Text("The question is not whether to love him, but whether this celebration is part of the religion he brought.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Mawlid (مَوْلِد)**: from **walada**, to give birth. The **mawlid** is the time or place of a birth, so the Prophet’s mawlid is simply his birth-day; the plural is **mawalid (مَوَالِد)**. The word later came to mean the celebration held for it, and the poems and gatherings of that celebration.")
                        .font(.body)

                    Text("**Rabi‘ al-Awwal (رَبِيع الأَوَّل)**: the third month of the Hijri year, named in the old Arabian calendar for the first spring. The Prophet (peace be upon him) was born in it, arrived at Madinah in it after the Hijrah, and died in it in the eleventh year after the Hijrah.")
                        .font(.body)

                    Text("**Sirah (سِيرَة)**: from **sara**, to travel, so a person’s sirah is the course of his life. The Prophet’s sirah is his biography, preserved by Ibn Ishaq (d. 150 AH) as edited by Ibn Hisham, and studied by later imams such as Ibn Kathir in al-Bidayah wan-Nihayah and Ibn al-Qayyim in Zad al-Ma‘ad. Studying it is worship at any time of the year, because Allah made him the pattern to follow:")
                        .font(.body)
                    ScriptureQuote(text: "“There has certainly been for you in the Messenger of Allah an excellent pattern for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).", arabic: "لَّقَدۡ كَانَ لَكُمۡ فِي رَسُولِ ٱللَّهِ أُسۡوَةٌ حَسَنَةٞ لِّمَن كَانَ يَرۡجُواْ ٱللَّهَ وَٱلۡيَوۡمَ ٱلۡأٓخِرَ وَذَكَرَ ٱللَّهَ كَثِيرٗا")

                    Text("**The Fatimids (الفَاطِمِيُّون)**, called by the scholars **the Ubaydiyyun (العُبَيْدِيُّون)** after their founder Ubaydullah: Isma‘ili Shia rulers of Egypt from 358 to 567 AH, and the first to institute the Mawlid, as The History below sets out from al-Maqrizi. They claimed descent from Fatimah (may Allah be pleased with her), but the scholars of lineage denied it; in 402 AH the leading scholars and genealogists in Baghdad, including the Alawi sharifs ar-Radi and al-Murtada, signed a written declaration that the claim was false, as Ibn Kathir records in al-Bidayah wan-Nihayah under the events of that year. So the yearly birthday celebration began neither among the Companions nor among the imams, but in a state whose rulers made festivals of their own, the caliph’s own birthday among them.")
                        .font(.body)

                    Text("**Irbil and al-Muzaffar (إِرْبِل)**: Irbil is a town in the north of Iraq. Its ruler, al-Malik al-Muzaffar Kokburi ibn Zayn ad-Din Ali (d. 630 AH), brother-in-law of Salah ad-Din, was the first Sunni ruler known to hold a public Mawlid, with lavish feasts and gifts, as The History below records from Ibn Kathir and as Ibn Khallikan, who was born in Irbil, describes at length in Wafayat al-A‘yan. The scholar Ibn Dihyah composed a book for him on the Prophet’s birth, at-Tanwir fi Mawlid as-Siraj al-Munir, and was rewarded with a thousand dinars, as Ibn Khallikan records. So the celebration entered the Sunni world in the seventh century, by the choice of a king, six hundred years after the Prophet (peace be upon him).")
                        .font(.body)

                    Text("**Madih (مَدِيح)** and **qasidah (قَصِيدَة)**: praise, and the ode in which it is sung. Praising the Prophet (peace be upon him) truthfully is permissible and was done in his presence by Hassan ibn Thabit (may Allah be pleased with him). The bound is the hadith quoted below forbidding the exaggeration the Christians fell into with the son of Maryam, and the Mawlid odes very often cross it.")
                        .font(.body)

                    Text("**The Burdah (البُرْدَة)**: the most famous Mawlid ode, by al-Busiri (d. around 695 AH). It contains beautiful lines and it contains this: “O noblest of creation, I have none to seek refuge with but you at the coming of the all-encompassing calamity.” To seek refuge in a created being from the calamities of the Day of Judgement is a request that belongs to Allah alone, and the Quran forbids it in the plainest words:")
                        .font(.body)
                    ScriptureQuote(text: "“And [He revealed] that the masjids are for Allah, so do not invoke with Allah anyone” (Quran 72:18).", arabic: "وَأَنَّ ٱلۡمَسَٰجِدَ لِلَّهِ فَلَا تَدۡعُواْ مَعَ ٱللَّهِ أَحَدٗا")

                    Text("**Qiyam (قِيَام)**: standing up when the moment of his birth is mentioned in the recitation of the Mawlid, often with a chant of greeting, as if he were entering the room. There is no basis for it in the Sunnah or in the practice of the Companions. Ibn al-Hajj (d. 737 AH), who wrote at length against the Mawlid in al-Madkhal, criticised the singing, the instruments, and the mixing of men and women in the gatherings of his time as evils added to the innovation.")
                        .font(.body)

                    Text("**Salawat (صَلَوَات)**: sending blessings upon him, the honouring that Allah Himself legislated, for all times and places:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, Allah confers blessing upon the Prophet, and His angels [ask Him to do so]. O you who have believed, ask [Allah to confer] blessing upon him and ask [Allah to grant him] peace” (Quran 33:56).", arabic: "إِنَّ ٱللَّهَ وَمَلَٰٓئِكَتَهُۥ يُصَلُّونَ عَلَى ٱلنَّبِيِّۚ يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ صَلُّواْ عَلَيۡهِ وَسَلِّمُواْ تَسۡلِيمًا")

                    Text("**“Bid‘ah hasanah” (بِدْعَة حَسَنَة)**: a “good innovation,” the justification usually given for the Mawlid: that it is new, but good. Ahl as-Sunnah answer that there is no good innovation in worship, because the Prophet (peace be upon him) said every innovation is misguidance, and Ibn Umar said the same even if the people see it as good (al-Lalaka’i 126, quoted on the Bid‘ah page). The full discussion is on that page.")
                        .font(.body)

                    Text("**‘Id (عِيد)**: a festival, from **‘ada**, to return, because it returns every year. Ibn Taymiyyah explains in Iqtida’ as-Sirat al-Mustaqim that an ‘id in the Shari‘ah is any recurring gathering fixed to a time, and that festivals are part of the religion, so no one may add one. That is why a yearly celebration tied to the twelfth of Rabi‘ al-Awwal is a religious matter even when it is called a custom.")
                        .font(.body)

                    Text("**Monday fasting (صَوْم الاثْنَيْن)**: the one act the Prophet (peace be upon him) connected to his birth, weekly and by fasting, in the hadith quoted below (Sahih Muslim 1162). It is the Sunnah of honouring his birth, and it is what the Companions did.")
                        .font(.body)
                }

                Section(header: Text("THE HISTORY")) {
                    Text("For more than three hundred years after the Prophet’s passing, no Muslim celebrated his birthday: not the Companions who loved him most, not the Tabi‘un, not Abu Hanifah, Malik, al-Shafi‘i, or Ahmad. The first to hold it were the **Fatimids (the Ubaydi Isma‘ili Shia)** who ruled Egypt in the fourth century AH; the historian al-Maqrizi lists the mawlid of the Prophet among the festivals they instituted alongside mawlids for Ali, Fatimah, and their own ruler (al-Khitat 1/490). It reached the Sunni world when the ruler of Irbil, al-Muzaffar (d. 630 AH), began holding lavish yearly public celebrations early in the seventh century AH, which Ibn Kathir describes in al-Bidayah wan-Nihayah (13/137).")
                        .font(.body)

                    Text("The Maliki jurist Taj al-Din al-Fakihani (d. 734 AH) wrote a treatise on it and said:")
                        .font(.body)
                    ScriptureQuote(text: "“I know of no basis for this mawlid in the Book or the Sunnah, and its practice is not reported from any of the scholars of the nation who are the examples in the religion” (al-Fakihani, al-Mawrid fi Amal al-Mawlid).", arabic: "لَا أَعْلَمُ لِهَذَا الْمَوْلِدِ أَصْلًا فِي كِتَابٍ وَلَا سُنَّةٍ، وَلَا يُنْقَلُ عَمَلُهُ عَنْ أَحَدٍ مِنْ عُلَمَاءِ الْأُمَّةِ الَّذِينَ هُمُ الْقُدْوَةُ فِي الدِّينِ", dimmed: true)

                    Text("Shaykh al-Islam Ibn Taymiyyah made the decisive point: the Salaf had every reason and every ability to celebrate it, and did not, so leaving it must be the Sunnah (Iqtida’ as-Sirat al-Mustaqim 2/123).")
                        .font(.body)
                }

                Section(header: Text("THE EVIDENCE")) {
                    Text("An act of worship needs a proof; the mawlid has none. And the Prophet (peace be upon him) closed the door to it in advance:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever introduces into this matter of ours what is not from it, it is rejected” (Sahih al-Bukhari 2697, Sahih Muslim 1718).", arabic: "مَنْ أَحْدَثَ فِي أَمْرِنَا هَذَا مَا لَيْسَ فِيهِ فَهُوَ رَدٌّ", dimmed: true)

                    ScriptureQuote(text: "“The worst of matters are the newly invented ones, and every innovation is misguidance” (Sahih Muslim 867).", arabic: "وَشَرُّ الأُمُورِ مُحْدَثَاتُهَا وَكُلُّ بِدْعَةٍ ضَلاَلَةٌ", dimmed: true)

                    Text("The date itself is not even certain. What is established is the day of the week: Monday. And the Prophet (peace be upon him) told us what to do about it, and it was not a festival:")
                        .font(.body)
                    ScriptureQuote(text: "He was asked about fasting on Monday, and he said: “On it I was born, and on it revelation came down to me” (Sahih Muslim 1162).", arabic: "فِيهِ وُلِدْتُ وَفِيهِ أُنْزِلَ عَلَىَّ", dimmed: true)

                    Text("So the Sunnah of honouring his birth is to fast on Mondays, every week of the year. Whoever wants to mark his birth has been shown how.")
                        .font(.body)

                    Text("The Muslims have two festivals only. When the Prophet (peace be upon him) came to Madinah and found the people celebrating two days from before Islam, he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah has replaced them for you with two better than them: the day of al-Adha and the day of al-Fitr” (Sunan Abi Dawud 1134; graded sahih by al-Albani).", arabic: "إِنَّ اللَّهَ قَدْ أَبْدَلَكُمْ بِهِمَا خَيْرًا مِنْهُمَا يَوْمَ الأَضْحَى وَيَوْمَ الْفِطْرِ", dimmed: true)
                }

                Section(header: Text("HOW TO LOVE HIM")) {
                    Text("Allah told the one who claims to love Him how that love is proven, and the same measure applies to loving His Messenger:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘If you should love Allah, then follow me, [so] Allah will love you and forgive you your sins. And Allah is Forgiving and Merciful’” (Quran 3:31).", arabic: "قُلۡ إِن كُنتُمۡ تُحِبُّونَ ٱللَّهَ فَٱتَّبِعُونِي يُحۡبِبۡكُمُ ٱللَّهُ وَيَغۡفِرۡ لَكُمۡ ذُنُوبَكُمۡۚ")

                    Text("The Companions loved him more than anyone ever will, and they showed it by following him, learning his Sunnah, spreading his religion, and sending blessings upon him. Whoever does that every day has honoured his birth more than any gathering could. And the Prophet (peace be upon him) warned against the very exaggeration in praising him that the mawlid poems tend toward:")
                        .font(.body)
                    ScriptureQuote(text: "“Do not exaggerate in praising me as the Christians exaggerated in praising the son of Maryam, for I am only a servant; so say, the servant of Allah and His Messenger” (Sahih al-Bukhari 3445).", arabic: "لاَ تُطْرُونِي كَمَا أَطْرَتِ النَّصَارَى ابْنَ مَرْيَمَ، فَإِنَّمَا أَنَا عَبْدُهُ، فَقُولُوا عَبْدُ اللَّهِ وَرَسُولُهُ", dimmed: true)
                }

                Section(header: Text("COMMON QUESTIONS")) {
                    Text("**Is the Mawlid not simply love of the Prophet?**")
                        .font(.body)
                    Text("Love of him is obligatory, and the measure of love is following, as the verse quoted above says: if you love Allah, follow the Messenger. The Prophet (peace be upon him) made his love the first of the three things that give faith its sweetness:")
                        .font(.body)
                    ScriptureQuote(text: "“Three things, whoever has them will find the sweetness of faith: that Allah and His Messenger are more beloved to him than anything besides them, that he loves a person only for Allah, and that he hates to return to disbelief as he hates to be thrown into the Fire” (Sahih al-Bukhari 16).", arabic: "ثَلاَثٌ مَنْ كُنَّ فِيهِ وَجَدَ حَلاَوَةَ الإِيمَانِ أَنْ يَكُونَ اللَّهُ وَرَسُولُهُ أَحَبَّ إِلَيْهِ مِمَّا سِوَاهُمَا، وَأَنْ يُحِبَّ الْمَرْءَ لاَ يُحِبُّهُ إِلاَّ لِلَّهِ، وَأَنْ يَكْرَهَ أَنْ يَعُودَ فِي الْكُفْرِ كَمَا يَكْرَهُ أَنْ يُقْذَفَ فِي النَّارِ", dimmed: true)
                    Text("Nobody loved him more than the Companions, who gave their wealth and blood for him and wept at his mention, and not one of them held a birthday for him in the decades they lived after his death. Their love went into obedience, learning, and spreading his religion. Ibn Taymiyyah was fair here: he wrote in Iqtida’ as-Sirat al-Mustaqim that some who hold the Mawlid may be rewarded for their good intention and their veneration of the Messenger, but not for the innovation itself, and that the Salaf, who loved him more, did not do it though they could have. So the question is not whether you love him, but whether you love him in the way he asked to be loved.")
                        .font(.body)

                    Text("**Did the Prophet not mark his birthday by fasting on Monday?**")
                        .font(.body)
                    Text("Yes, and that is the whole point: he marked it weekly, by fasting, as quoted above (Sahih Muslim 1162). That is the Sunnah for the day of his birth, and it is available every week. The Mawlid replaces it with a yearly festival on which no fast is prescribed; it takes the day he honoured with worship and honours it with a feast he never held.")
                        .font(.body)

                    Text("**Did some scholars, like as-Suyuti and Ibn Hajar, not permit it?**")
                        .font(.body)
                    Text("Yes, and honesty requires saying so. As-Suyuti wrote a treatise, Husn al-Maqsid fi Amal al-Mawlid, in which he counted it a good innovation if it is free of evils, and he quoted a verdict of Ibn Hajar to the same effect, reasoned from the Prophet’s fasting of Ashura in gratitude for the saving of Musa. Ahl as-Sunnah answer with respect for both men and with the proofs. There is no good innovation in worship, by the Prophet’s own words and by Ibn Umar’s. The three best generations, who had every reason to do it, did not. Imam Malik’s words quoted on the Bid‘ah page apply exactly: what was not religion on the day the religion was completed is not religion today. The analogy with Ashura fails, because the Ashura fast is itself an act the Prophet legislated, while gratitude for his birth was expressed by him in the Monday fast, and we cannot legislate a second expression he did not. And this is not a new position: it is the verdict of al-Fakihani quoted above, of Ibn al-Hajj in al-Madkhal, of ash-Shatibi, and of Ibn Taymiyyah, and in our era of Ibn Baz, al-Albani, and Ibn al-Uthaymin (may Allah have mercy on them all).")
                        .font(.body)

                    Text("**Is the date of his birth even known?**")
                        .font(.body)
                    Text("It is not. Ibn Kathir gathers the reports in al-Bidayah wan-Nihayah: the second of Rabi‘ al-Awwal, the eighth, the tenth, the twelfth, and other dates were all said, while the year of the Elephant is the established view. What the most widespread report does place on the twelfth of Rabi‘ al-Awwal is his death, in the eleventh year after the Hijrah. So the Mawlid gathers people in celebration on a date that is uncertain for his birth and widely reported for his passing.")
                        .font(.body)

                    Text("**Is attending a Mawlid haram, and is it shirk?**")
                        .font(.body)
                    Text("Attending it as a religious celebration is taking part in an innovation, and that is forbidden, though it is not shirk in itself. It becomes shirk in what is often said and sung there: when the Prophet (peace be upon him) is called upon, asked for refuge, help, or forgiveness, as in the line of the Burdah quoted in the key terms. Allah forbade invoking anyone alongside Him in the verse quoted there, and He said:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not invoke besides Allah that which neither benefits you nor harms you, for if you did, then indeed you would be of the wrongdoers” (Quran 10:106).", arabic: "وَلَا تَدۡعُ مِن دُونِ ٱللَّهِ مَا لَا يَنفَعُكَ وَلَا يَضُرُّكَۖ فَإِن فَعَلۡتَ فَإِنَّكَ إِذٗا مِّنَ ٱلظَّٰلِمِينَ")
                    Text("So there are degrees: a sirah lesson held on that day with no rites is a lesser matter than a gathering built around the date, and both are far from the poems that call upon him. The Muslim avoids all of it and keeps the Prophet’s honour where he placed it.")
                        .font(.body)

                    Text("**Is it a bid‘ah to study the sirah, or to recite poetry praising him?**")
                        .font(.body)
                    Text("No. Both are good at any time of the year, and both were done in his presence. Hassan ibn Thabit recited poetry in the Prophet’s mosque, and when Umar looked at him with disapproval, Hassan said:")
                        .font(.body)
                    ScriptureQuote(text: "“I used to recite in it when one better than you was in it.” Then he turned to Abu Hurayrah and said: “I adjure you by Allah, did you hear the Messenger of Allah say: ‘Reply on my behalf. O Allah, support him with the Holy Spirit’?” He said: “Yes” (Sahih al-Bukhari 3212, Sahih Muslim 2485).", arabic: "كُنْتُ أُنْشِدُ فِيهِ، وَفِيهِ مَنْ هُوَ خَيْرٌ مِنْكَ، ثُمَّ الْتَفَتَ إِلَى أَبِي هُرَيْرَةَ، فَقَالَ أَنْشُدُكَ بِاللَّهِ، أَسَمِعْتَ رَسُولَ اللَّهِ صلى الله عليه وسلم يَقُولُ أَجِبْ عَنِّي، اللَّهُمَّ أَيِّدْهُ بِرُوحِ الْقُدُسِ. قَالَ نَعَمْ", dimmed: true)
                    Text("The bid‘ah is not the sirah and not the poetry; it is the yearly festival, its fixed date, and its rites, and the exaggeration in the poems that turns praise into invocation.")
                        .font(.body)

                    Text("**Do we have festivals?**")
                        .font(.body)
                    Text("Two, given by Allah in place of the festivals of the days of ignorance, as the hadith of Sunan Abi Dawud 1134 above says. When Abu Bakr objected to two girls singing in the Prophet’s house on the day of Eid, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“O Abu Bakr, every people has a festival, and this is our festival” (Sahih al-Bukhari 952).", arabic: "يَا أَبَا بَكْرٍ إِنَّ لِكُلِّ قَوْمٍ عِيدًا، وَهَذَا عِيدُنَا", dimmed: true)
                    Text("A festival is a mark of a people’s religion, and ours were fixed by revelation. Adding a third, whatever it is named after, is adding to the religion.")
                        .font(.body)

                    Text("**What about the dream of Abu Lahab being relieved for freeing Thuwaybah?**")
                        .font(.body)
                    Text("Some cite a report in Sahih al-Bukhari: Urwah said that Thuwaybah was a slave of Abu Lahab whom he freed, and she suckled the Prophet (peace be upon him); after Abu Lahab died, one of his family saw him in a dream in a wretched state, and he said:")
                        .font(.body)
                    ScriptureQuote(text: "“I have not found any rest since I left you, except that I have been given to drink in this (the hollow between his thumb and fingers) because of my freeing Thuwaybah” (Sahih al-Bukhari 5101).", arabic: "لَمْ أَلْقَ بَعْدَكُمْ غَيْرَ أَنِّي سُقِيتُ فِي هَذِهِ بِعَتَاقَتِي ثُوَيْبَةَ", dimmed: true)
                    Text("Ibn Hajar notes in Fath al-Bari that this is a mursal report from Urwah, and in any case it is a dream about a disbeliever, and a dream is not a proof of legislation. Allah says of the deeds of those who died in disbelief:")
                        .font(.body)
                    ScriptureQuote(text: "“And We will regard what they have done of deeds and make them as dust dispersed” (Quran 25:23).", arabic: "وَقَدِمۡنَآ إِلَىٰ مَا عَمِلُواْ مِنۡ عَمَلٖ فَجَعَلۡنَٰهُ هَبَآءٗ مَّنثُورًا")
                    Text("And even taken at face value, the report is about freeing a slave in joy at a birth, once, in the days of ignorance; it says nothing about a yearly festival, and the first generations never drew that from it.")
                        .font(.body)

                    Text("**Is it not just a gathering with food and the sirah, not worship?**")
                        .font(.body)
                    Text("If it were purely a custom, no one would tie it to that date, count it a religious occasion, hope for reward in it, or call the one who leaves it deficient in love. Those are the marks of worship, and worship needs a proof. Ibn Taymiyyah notes in Iqtida’ as-Sirat al-Mustaqim that taking the Prophet’s birthday as a festival also resembles the Christians in what they made of the birth of Isa (peace be upon him), and he explains there that a recurring gathering fixed to a date is an ‘id in the Shari‘ah whatever it is called. Food and sirah are good on any day; it is the appointment that makes the innovation.")
                        .font(.body)

                    Text("**What if my family or community holds it?**")
                        .font(.body)
                    Text("Keep your ties and your kindness, and keep away from the rites. Allah commanded the child of parents who even call to shirk:")
                        .font(.body)
                    ScriptureQuote(text: "“but accompany them in [this] world with appropriate kindness” (Quran 31:15).", arabic: "وَصَاحِبۡهُمَا فِي ٱلدُّنۡيَا مَعۡرُوفٗاۖ")
                    Text("Do not attend the gathering as a religious celebration and do not join its chants or its standing; but visit, help, and explain gently when the door opens. Show them the Sunnah in your own practice: fast on Mondays, send blessings upon him often, and study his life with them at other times, so that they see that leaving the Mawlid is not leaving his love.")
                        .font(.body)

                    Text("**How do we honour him correctly?**")
                        .font(.body)
                    Text("By the four things Allah and His Messenger prescribed. Loving him above all people, as in the hadith quoted at the top of this page (Sahih al-Bukhari 15). Following him, as the verse quoted above commands (Quran 3:31). Sending blessings upon him, as Allah commanded in the verse quoted in the key terms (Quran 33:56), which carries a reward he described himself:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever sends one blessing upon me, Allah sends ten blessings upon him for it” (Sahih Muslim 384).", arabic: "مَنْ صَلَّى عَلَىَّ صَلاَةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا", dimmed: true)
                    Text("And defending and spreading his Sunnah, so that people worship Allah as he taught. Whoever keeps these four has given him his right in the way he himself prescribed, and has stayed on the road his Companions walked.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Not one of the first three generations celebrated the mawlid; it came from the Fatimids centuries later. Love of the Prophet is proven by following him, and he himself showed how to mark the day of his birth: by fasting on Mondays.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Mawlid")
        .selectableArticleList()
    }
}
