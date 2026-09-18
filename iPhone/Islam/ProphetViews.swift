import SwiftUI

/// One page per prophet named in the Quran, opened from the list on `ProphetsView` (Belief in the
/// Prophets). Each page is a full article in the same shape as the pillars around it: a SUMMARY line,
/// an OVERVIEW naming him and the people he was sent to, HIS STORY from the Quran's own account, the
/// LESSONS the Quran draws from it, and an IN SUMMARY close, then its own SOURCES section.
///
/// Every ayah here is a `ScriptureQuote(quran:)` reference and every hadith a `ScriptureQuote(hadith:)`
/// one, never a copy: the words come from the app's own Quran text and hadith shelf as the page renders
/// (Scripts/verify_islam_corpus.py refuses to ship a literal copy or a reference the app cannot render).
///
/// The stories keep to what the Quran and the authentic Sunnah state. Where the well-known detail is
/// Isra'iliyyat (the Torah-and-Talmud material the Salaf neither confirmed nor denied) the page either
/// leaves it out or says plainly that it is not established, because a prophet's story is creed and not
/// folklore. Names, order and the people each was sent to follow the article's own list of the 25.

/// The row that opens a prophet's page from the list on `ProphetsView`: his name in English, his name
/// in Arabic on the trailing side, and the people he was sent to underneath.
struct ProphetLinkRow: View {
    @Environment(\.appearance) private var appearance

    let name: String
    let arabic: String
    let sentTo: String

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(sentTo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            Text(arabic)
                .font(.body)
                .foregroundColor(appearance.accent)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 1. Adam

struct ProphetAdamView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Adam (peace be upon him) is the first man and the first prophet, whom Allah created with His own hand and taught the names of all things.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Adam (آدَم)** is the father of mankind and the first of the prophets. Allah created him from clay, breathed into him of His spirit, and commanded the angels to prostrate to him. He is mentioned by name 25 times in the Quran.")
                        .font(.body)

                    Text(verbatim: "Allah announced his creation before it happened, and the angels asked about it:").font(.body)
                    ScriptureQuote(quran: "2:30-31")

                    Text(verbatim: "The prostration Allah commanded was one of honour to Adam, not of worship: worship belongs to Allah alone. Iblis alone refused out of arrogance, and that refusal is the beginning of his enmity to the children of Adam.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "Allah settled Adam and his wife in the Garden and permitted them everything in it but one tree:").font(.body)
                    ScriptureQuote(quran: "2:35")

                    Text(verbatim: "Shaytan whispered to them until they ate from it. The Quran does not blame the woman for it, as other accounts do: it says they both ate, and in Surah Ta-Ha it is Adam who is addressed.")
                        .font(.body)
                    ScriptureQuote(quran: "20:115")

                    Text(verbatim: "What follows is the point of the whole story. Adam did not argue or persist. He turned back to his Lord, and Allah taught him the very words with which to do it:")
                        .font(.body)
                    ScriptureQuote(quran: "2:37")

                    Text(verbatim: "Allah then sent them down to the earth, and He did not send them down abandoned. He promised guidance, and made the response to it the dividing line:")
                        .font(.body)
                    ScriptureQuote(quran: "20:123-124")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Repentance is the way back.** Adam's sin did not end him; his repentance restored him. The difference between Adam and Iblis is not that one sinned and the other did not, it is that one repented and the other refused.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Knowledge is an honour Allah gave man.** The angels' rank did not include the names Adam was taught. Allah honoured the son of Adam with knowledge before He honoured him with anything else.")
                        .font(.body)

                    Text(articleMarkdown: "3. **The enmity of Shaytan is old and personal.** He refused to prostrate to your father and swore to mislead you. Knowing this is half of guarding against it.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said of the sons of Adam:").font(.body)
                    ScriptureQuote(hadith: "ibnmajah:4251", cite: "Sunan Ibn Majah 4251; graded hasan by al-Albani, da'if by Shu'ayb al-Arna'ut", arabic: 29...35, english: 0...17)

                    Text(verbatim: "The scholars differ over the chain of that narration, so what it means is established here by one whose authenticity no one disputes:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2749", cite: "Sahih Muslim 2749", english: 8...44)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The first man was also the first to sin, the first to repent, and the first to be forgiven: the pattern every one of his children lives by.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetAdamView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetAdamView")
        .navigationTitle("Adam")
    }
}

// MARK: - 2. Idris

struct ProphetIdrisView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Idris (peace be upon him) is praised in the Quran as a man of truth and a prophet whom Allah raised to a high station.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Idris (إِدرِيس)** is named twice in the Quran, and both mentions are praise. Nothing of his story is given in detail, which is itself the lesson: Allah tells us what we need, and what He left out is not needed.")
                        .font(.body)

                    ScriptureQuote(quran: "19:56-57")

                    Text(verbatim: "And Allah names him among those who were patient and righteous:").font(.body)
                    ScriptureQuote(quran: "21:85-86")
                }

                Section(header: ArticleHeader("WHAT IS AND IS NOT ESTABLISHED")) {
                    Text(verbatim: "Idris is commonly identified with Enoch, and he is often said to have been the first to write with the pen, the first to sew garments, and to have been raised alive to the heavens. None of that is established from the Quran or from an authentic narration. It comes from the reports of the People of the Scripture, and the position of the Salaf toward such reports is neither to affirm nor to deny them.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said about these reports:").font(.body)
                    ScriptureQuote(hadith: "bukhari:7362", cite: "Sahih al-Bukhari 7362", english: 28...56)

                    Text(articleMarkdown: "Scholars also differ on whether Idris came **before** Nuh (peace be upon them), as most held, or after him among the Children of Israel. The order in this app's list follows the majority.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Allah's praise is enough.** Two short mentions, and in them Allah calls him truthful, a prophet, patient, and righteous, and says He raised him high. A man needs no longer record than that.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Silence in revelation is deliberate.** Where the Quran is brief, adding detail from elsewhere and teaching it as religion is exactly what the Salaf refused to do.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Idris is named for his truthfulness, his patience, and the high station Allah raised him to, and the rest of his story was not given to us.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetIdrisView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetIdrisView")
        .navigationTitle("Idris")
    }
}

// MARK: - 3. Nuh

struct ProphetNuhView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Nuh (peace be upon him) called his people to Allah alone for 950 years, and when they refused, Allah saved him and the believers in the ark and drowned the rest.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Nuh (نُوح)**, Noah, is the first messenger Allah sent to the people of the earth after they fell into idolatry, and one of the five messengers of firm resolve, **Ulul-Azm (أُولُو العَزم)**. A whole surah of the Quran carries his name.")
                        .font(.body)

                    ScriptureQuote(quran: "7:59")

                    Text(verbatim: "He was sent with the same message every prophet was sent with, and he gave it for longer than any of them:").font(.body)
                    ScriptureQuote(quran: "71:1")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(articleMarkdown: "He called them for **950 years**, and Nuh himself describes the answer he got:")
                        .font(.body)
                    ScriptureQuote(quran: "71:7")

                    Text(verbatim: "They clung to the idols of their fathers, and Allah names those idols in the Quran. They were the names of righteous men whose images were made after them until they were worshipped:")
                        .font(.body)
                    ScriptureQuote(quran: "71:23")

                    Text(verbatim: "Only at the end, after every approach had failed, did he pray against them:")
                        .font(.body)
                    ScriptureQuote(quran: "71:26-28")

                    Text(verbatim: "Allah commanded him to build the ark, and he built it while his people passed by and laughed:")
                        .font(.body)
                    ScriptureQuote(quran: "23:27")

                    Text(verbatim: "When the command came, the water rose from the earth and fell from the sky, and he called to his own son:")
                        .font(.body)
                    ScriptureQuote(quran: "11:42-43")

                    Text(verbatim: "His son drowned. This is the hardest and most important part of the story: prophethood in a father does not save a son who rejects. Nuh asked his Lord about him, and Allah corrected him plainly, telling him not to ask about what he had no knowledge of.")
                        .font(.body)

                    Text(verbatim: "The believers who boarded with him were few, and from them the earth was repopulated:").font(.body)
                    ScriptureQuote(quran: "23:28")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Shirk begins with exaggerating the righteous.** The idols of Nuh's people started as memorials to good men. This is why Islam closes every door to venerating graves and images of the pious.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Success is not measured in numbers.** After 950 years he had a handful of followers, and he is among the greatest of the messengers. The messenger is asked to convey, not to be accepted.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Faith is not inherited.** His own son drowned with the disbelievers. No lineage, not even a prophet's, stands in place of belief.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Nine and a half centuries of patient calling, a handful of believers, and a son lost to disbelief: Nuh's story is the measure of what a caller owes and what he does not control.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetNuhView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetNuhView")
        .navigationTitle("Nuh")
    }
}

// MARK: - 4. Hud

struct ProphetHudView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Hud (peace be upon him) was sent to the people of 'Aad, who were the strongest of their age, and their strength is what destroyed them.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Hud (هُود)** was sent to **'Aad (عَاد)**, an Arab people of the sand dunes of al-Ahqaf in the south of the Arabian peninsula. A surah of the Quran carries his name. He was one of their own, which is how Allah describes almost every messenger: their brother, from among them.")
                        .font(.body)

                    ScriptureQuote(quran: "7:65-66")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "'Aad were given a physique and a power no people before them had. Hud reminded them whose gift it was:")
                        .font(.body)
                    ScriptureQuote(quran: "7:69")

                    Text(verbatim: "He warned them in the valleys of al-Ahqaf:")
                        .font(.body)
                    ScriptureQuote(quran: "46:21")

                    Text(verbatim: "They answered with the one argument that has never changed: our fathers did this. And they dared him to bring the punishment he warned them of. When it came, it came in the form of the thing they had been waiting for:")
                        .font(.body)
                    ScriptureQuote(quran: "46:24-25")

                    Text(verbatim: "They saw a cloud coming toward their valleys and said it was rain. It was a wind Allah loosed against them for seven nights and eight days, and it left them fallen as though they were hollow trunks of palm trees. Hud and those who believed with him were saved.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Strength is a test, not a proof.** 'Aad measured themselves by what they could build and lift, and asked who was stronger than them. The wind answered.")
                        .font(.body)

                    Text(articleMarkdown: "2. **“Our fathers did it“ is not a reason.** The Quran records this answer from nation after nation. Inheriting a practice does not make it true.")
                        .font(.body)

                    Text(articleMarkdown: "3. **What you long for can be what ruins you.** They welcomed the cloud as rain. Not everything a person hopes for is good for him.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "'Aad were the strongest people of their time and the Quran remembers them only as a warning: power without submission is nothing before Allah.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetHudView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetHudView")
        .navigationTitle("Hud")
    }
}

// MARK: - 5. Salih

struct ProphetSalihView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Salih (peace be upon him) was sent to Thamud with a she-camel as a clear sign, and when they hamstrung her the punishment came.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Salih (صَالِح)** was sent to **Thamud (ثَمُود)**, the people who came after 'Aad and who carved their homes out of the mountains at al-Hijr, in the north-west of the Arabian peninsula. ")
                        .font(.body)

                    ScriptureQuote(quran: "11:61")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "They asked him for a sign, and Allah gave them one they had chosen themselves: a she-camel, with a share of the water on a known day that was hers alone. Salih warned them what touching her would mean:")
                        .font(.body)
                    ScriptureQuote(quran: "7:73")

                    Text(verbatim: "The Quran names the man who did it, and it names him as one man acting for the whole people:").font(.body)
                    ScriptureQuote(quran: "26:155-156")

                    Text(verbatim: "The wretched one among them was roused to it, and they hamstrung her. Salih gave them three days, and on the third the cry seized them and they lay lifeless in their homes:")
                        .font(.body)
                    ScriptureQuote(quran: "11:67")

                    Text(verbatim: "Their dwellings still stand in the rock. When the Prophet (peace and blessings be upon him) passed them with his army on the way to Tabuk, he did not let his companions treat them as a sight to see:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:433", cite: "Sahih al-Bukhari 433", arabic: 33...52, english: 4...21)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **A people carries what its worst member does when it consents to it.** One man hamstrung the camel; the Quran says “they“ hamstrung her, because they were pleased with it.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Signs do not create faith.** They asked for a sign, received exactly what they asked for, and killed it. Whoever has decided not to believe will not be argued into it.")
                        .font(.body)

                    Text(articleMarkdown: "3. **The ruins of the punished are not tourist sites.** The Sunnah is to pass them weeping, in fear of Allah, not to wander them taking in the view.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Thamud carved palaces from mountains and were destroyed over a camel: the sign they demanded became the proof against them.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetSalihView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetSalihView")
        .navigationTitle("Salih")
    }
}

// MARK: - 6. Ibrahim

struct ProphetIbrahimView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Ibrahim (peace be upon him) is the friend of Allah and the father of the prophets, who broke his people's idols, was thrown into the fire, and was ready to sacrifice his son.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Ibrahim (إِبرَاهِيم)**, Abraham, is named more often in the Quran than any prophet but Musa. He is one of the five messengers of firm resolve, and Allah took him as **Khalil (خَلِيل)**, an intimate friend, a station given to him and to Muhammad (peace be upon them) alone.")
                        .font(.body)

                    ScriptureQuote(quran: "19:41-42")

                    Text(verbatim: "The prophets who came after him from his line include Ismail, Ishaq, Yaqub, Yusuf, Musa, Harun, Dawud, Sulayman, Zakariya, Yahya, Isa, and Muhammad (peace be upon them all), which is why he is called the father of the prophets.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE IDOLS AND THE FIRE")) {
                    Text(verbatim: "His people, and his own father Azar, carved and worshipped idols. Ibrahim reasoned with them, and when reasoning failed he acted:")
                        .font(.body)
                    ScriptureQuote(quran: "21:51-52")

                    Text(verbatim: "He broke them all but the largest and hung the axe on it. When they accused him, he told them to ask the big one, and they were forced to admit that idols do not speak. Their answer was to build a fire:")
                        .font(.body)
                    ScriptureQuote(quran: "21:68-69")

                    Text(verbatim: "He was thrown in, and the fire was commanded to be cool and safe for him. This is the sign of what tawakkul means: he had no way out and did not need one.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE SACRIFICE")) {
                    Text(verbatim: "In old age Allah gave him a son, and then commanded him in a dream to sacrifice him. He did not hide it from the boy; he asked him:")
                        .font(.body)
                    ScriptureQuote(quran: "37:100-103")

                    Text(verbatim: "The son answered that he would be found, by Allah's will, among the patient. When both had submitted and he had laid him down, Allah called out and ransomed the boy with a great sacrifice:")
                        .font(.body)
                    ScriptureQuote(quran: "37:104-107")

                    Text(articleMarkdown: "This is what Muslims commemorate every year at **Eid al-Adha**. The Quran does not name the son in this passage, and the position of the scholars of the Sunnah, and the stronger view, is that he was **Ismail**: the good news of Ishaq comes after the account is finished.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE KA'BAH AND THE CALL")) {
                    Text(verbatim: "Allah showed him the site of the House and commanded him to purify it and proclaim the pilgrimage:").font(.body)
                    ScriptureQuote(quran: "22:26-27")

                    Text(verbatim: "He left his wife Hajar and the infant Ismail in a barren valley with no crop and no water, and turned back saying:").font(.body)
                    ScriptureQuote(quran: "14:37")

                    Text(verbatim: "Zamzam sprang there, and the valley he left them in is Makkah. Allah also made him an example in tests, and He tested him and he fulfilled them:")
                        .font(.body)
                    ScriptureQuote(quran: "2:124")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Tawhid is worth standing alone for.** He stood against his father, his people and his king, by himself, and Allah calls him a nation in himself.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Submission is tested in what you love most.** The command was not about the knife; it was about whether anything competed with Allah in his heart.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Leave what you love in Allah's care.** He left a wife and a nursing child in an empty valley because he was commanded to, and Allah built a city and a pilgrimage there.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The friend of Allah broke the idols, walked into the fire, and raised the knife: every test asked him for what he loved, and he gave it.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetIbrahimView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetIbrahimView")
        .navigationTitle("Ibrahim")
    }
}

// MARK: - 7. Lut

struct ProphetLutView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Lut (peace be upon him) was sent to a people who invented an obscenity no nation had committed before, and they were destroyed for it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Lut (لُوط)**, Lot, was the **nephew of Ibrahim** (the son of his brother Haran) and believed in him early. He is named 27 times in the Quran. Allah sent him to the people of Sodom, in the cities of the plain.")
                        .font(.body)

                    Text(verbatim: "He named their sin to them plainly, and the Quran records that no people had done it before them:").font(.body)
                    ScriptureQuote(quran: "7:80-81")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "He called them for years, and their answer was to threaten to expel him for the crime of wanting to stay clean. The angels came to him as guests, in the form of young men, and his people came running to the house. He offered every appeal he had, and said:")
                        .font(.body)
                    ScriptureQuote(quran: "11:78-80")

                    Text(verbatim: "That night the angels told him to leave with his family before dawn, and not to look back. His wife was not with him in faith and stayed behind with those who were destroyed:")
                        .font(.body)
                    ScriptureQuote(quran: "11:81")

                    Text(verbatim: "At sunrise the cities were overturned and stones of baked clay rained down on them:")
                        .font(.body)
                    ScriptureQuote(quran: "11:82-83")

                    Text(verbatim: "And Allah left their ruin as a clear sign for people who reason:")
                        .font(.body)
                    ScriptureQuote(quran: "29:35")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **A sin can become a people's identity, and that is when it destroys them.** What was condemned was not only the act but the public, defended, organised practice of it.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Marriage does not transfer faith.** Lut's wife lived in a prophet's house and was destroyed with her people. The Quran gives her and Nuh's wife as the example for this.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Standing alone is not failure.** He said, if only I had against you some power. Allah records the wish, and He sent the angels the same night.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Lut warned a people who had made a sin into a public custom, and Allah overturned their cities and left the ruins as a sign.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetLutView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetLutView")
        .navigationTitle("Lut")
    }
}

// MARK: - 8. Ismail

struct ProphetIsmailView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Ismail (peace be upon him) is the son Ibrahim was commanded to sacrifice, who helped him raise the Ka'bah, and the forefather of Prophet Muhammad.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Ismail (إِسمَاعِيل)**, Ishmael, is the elder son of Ibrahim, born to Hajar. The Arabs of the Hijaz descend from him, and through him, Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text(verbatim: "Allah praises him for the one quality He mentions first about him:").font(.body)
                    ScriptureQuote(quran: "19:54-55")

                    Text(verbatim: "He is named among the patient and the righteous:").font(.body)
                    ScriptureQuote(quran: "21:85")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "As an infant he was left with his mother Hajar in the valley of Makkah, and Zamzam sprang for him there. As a boy he was the one his father saw in the dream, and his answer when told of it is the reason he is honoured:")
                        .font(.body)
                    ScriptureQuote(quran: "37:102")

                    Text(verbatim: "And when he was grown he raised the foundations of the House with his father, and the two of them prayed while they built:")
                        .font(.body)
                    ScriptureQuote(quran: "2:127")

                    Text(verbatim: "The Prophet (peace and blessings be upon him) named his own descent from him:").font(.body)
                    ScriptureQuote(hadith: "muslim:2276", cite: "Sahih Muslim 2276", arabic: 45...64, english: 7...48)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **He was true to his promise.** Of everything that could be said about him, Allah chose this. A man who keeps his word is rare enough that Allah praises it by name.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Obedience is a young man's virtue too.** He was a boy when he told his father to do what he was commanded. Faith is not something that arrives with age.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Build and ask for acceptance.** Father and son laid the stones of the Ka'bah and asked Allah to accept it from them. Doing the work is not the same as having it accepted.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The boy who offered his own neck grew into the man who built the House, and the last of the prophets came from his line.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetIsmailView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetIsmailView")
        .navigationTitle("Ismail")
    }
}

// MARK: - 9. Ishaq

struct ProphetIshaqView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Ishaq (peace be upon him) was the son given to Ibrahim and Sarah in old age as glad tidings, and a prophet from whose line came the prophets of the Children of Israel.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Ishaq (إِسحَاق)**, Isaac, is the second son of Ibrahim, born to Sarah. From his son Yaqub came the twelve tribes and almost every prophet sent to the Children of Israel.")
                        .font(.body)

                    Text(verbatim: "Allah announced him to Ibrahim as glad tidings, and announced his prophethood in the same breath:").font(.body)
                    ScriptureQuote(quran: "37:112-113")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "The angels who were sent to the people of Lut passed by Ibrahim first, and gave the news to Sarah, who was old and barren and laughed in astonishment:")
                        .font(.body)
                    ScriptureQuote(quran: "11:71-73")

                    Text(verbatim: "Allah names Ishaq among those He guided, and joins him to his father and his son as a single line of favour:")
                        .font(.body)
                    ScriptureQuote(quran: "6:84")

                    Text(articleMarkdown: "The Quran gives little of his life beyond this. His importance is in what came through him: **Yaqub**, the twelve tribes, and the long chain of prophets to Bani Israil ending with Isa (peace be upon them all).")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Allah's promise does not answer to age or circumstance.** A barren woman past childbearing was given a son, and a prophet, and a line of prophets after him.")
                        .font(.body)

                    Text(articleMarkdown: "2. **The glad tidings were of a righteous son, not merely a son.** What was announced was his prophethood. A child is a blessing in proportion to what he becomes.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Ishaq was the promise kept to an old man and a barren woman, and the door through which the prophets of Bani Israil came.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetIshaqView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetIshaqView")
        .navigationTitle("Ishaq")
    }
}

// MARK: - 10. Yaqub

struct ProphetYaqubView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Yaqub (peace be upon him), also called Israil, is the father of the twelve tribes, whose patience at losing Yusuf the Quran holds up as beautiful patience.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Yaqub (يَعقُوب)**, Jacob, is the son of Ishaq and grandson of Ibrahim. Allah gave him the name **Israil (إِسرَائِيل)**, and his twelve sons are the twelve tribes: the **Children of Israel, Bani Israil (بَنِي إِسرَائِيل)**, are his descendants. He is named 16 times in the Quran.")
                        .font(.body)

                    Text(verbatim: "He was given to Ibrahim as an addition beyond what was asked, and made a prophet:").font(.body)
                    ScriptureQuote(quran: "21:72")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "Most of what the Quran tells of him is inside the story of his son Yusuf. When Yusuf told him of the dream, he understood at once what it meant and what his brothers would do:")
                        .font(.body)
                    ScriptureQuote(quran: "12:4-6")

                    Text(articleMarkdown: "When they brought his shirt stained with false blood, he did not scream or curse. He said what the Quran records as his answer, and the phrase in it, **sabrun jamil (صَبرٌ جَمِيل)**, beautiful patience, became the name for grief borne without complaint to anyone but Allah:")
                        .font(.body)
                    ScriptureQuote(quran: "12:18")

                    Text(verbatim: "He wept until his eyes turned white from grief, and he lost his second son too, and still he did not despair:").font(.body)
                    ScriptureQuote(quran: "12:86-87")

                    Text(verbatim: "At the end of his life his concern was not his wealth or his tribe. He gathered his sons and asked them one question:").font(.body)
                    ScriptureQuote(quran: "2:133")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Beautiful patience is not silence about pain.** He said his grief was severe and he wept until he lost his sight. He complained of it to Allah, and to no one else. That is the distinction.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Despair of Allah's mercy is a disbelief of its own.** He sent his sons back to search after years, when everyone else had given up.")
                        .font(.body)

                    Text(articleMarkdown: "3. **The last thing a father should worry about is his children's faith.** On his deathbed he asked them what they would worship after him. Nothing else was worth the question.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Yaqub lost a son, went blind with weeping, never once despaired of Allah, and died asking his children only what they would worship.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetYaqubView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetYaqubView")
        .navigationTitle("Yaqub")
    }
}

// MARK: - 11. Yusuf

struct ProphetYusufView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Yusuf (peace be upon him) was thrown in a well by his brothers, sold as a slave, imprisoned though innocent, raised to authority over Egypt, and then forgave them all.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Yusuf (يُوسُف)**, Joseph, is the son of Yaqub. Surah Yusuf tells his life from beginning to end in one continuous account, which the Quran itself calls **the best of stories**, and it is the only story told this way. He is named 27 times.")
                        .font(.body)

                    ScriptureQuote(quran: "12:3")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "It begins with a dream he told his father, and his father told him to keep it from his brothers. They took him out to play, threw him into the bottom of a well, and came back at nightfall weeping with a false-bloodied shirt.")
                        .font(.body)

                    Text(verbatim: "A caravan drew him out and sold him in Egypt for a trifling price. He grew up in the house of a man of rank, and the man's wife sought to seduce him and locked the doors. His answer was one sentence:")
                        .font(.body)
                    ScriptureQuote(quran: "12:23")

                    Text(verbatim: "He chose prison over her, and asked Allah for it plainly:")
                        .font(.body)
                    ScriptureQuote(quran: "12:33")

                    Text(verbatim: "In prison he called two fellow prisoners to tawhid before he interpreted their dreams, and he stayed there years after he could have left. When the king's dream came and he was summoned, he refused to leave until his innocence was established. The women confessed:")
                        .font(.body)
                    ScriptureQuote(quran: "12:51")

                    Text(verbatim: "He was given authority over the storehouses of Egypt. His brothers came seeking food and did not know him, and when he finally told them, he did not take a single thing back from them:")
                        .font(.body)
                    ScriptureQuote(quran: "12:90-92")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Fleeing sin can cost you, and it is still the cheaper price.** He preferred prison to disobedience, and Allah gave him Egypt.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Clear your name before you accept a position.** He would not walk out of prison under a cloud. Reputation is a trust, not vanity.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Forgiveness is the strongest thing a person in power can do.** He had every legal right and total authority, and he used neither.")
                        .font(.body)

                    Text(articleMarkdown: "4. **Whoever fears Allah and is patient, Allah does not waste his reward.** This is the sentence Yusuf himself gives as the summary of his own life (Quran 12:90).")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "A well, a slave market, a prison, and then a throne: Yusuf's life is the proof that Allah's plan runs underneath what looks like ruin.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetYusufView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetYusufView")
        .navigationTitle("Yusuf")
    }
}

// MARK: - 12. Ayyub

struct ProphetAyyubView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Ayyub (peace be upon him) lost his health, his wealth and his children, and the Quran names him the model of patience because he never complained of his Lord.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Ayyub (أَيُّوب)**, Job, is named 4 times in the Quran. He was given wealth, family and health, and then all of it was taken, and he bore it for years. Allah's verdict on him is the shortest and highest praise in the matter of patience.")
                        .font(.body)

                    ScriptureQuote(quran: "38:44")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "The Quran does not describe his illness in detail. It records the moment he finally called on his Lord, and the wording is the lesson: he did not ask for removal, he did not ask why, and he mentioned Allah's mercy before he mentioned his own need:")
                        .font(.body)
                    ScriptureQuote(quran: "21:83-84")

                    Text(verbatim: "And Allah's answer came with relief for the body and the family both:").font(.body)
                    ScriptureQuote(quran: "38:41-44")

                    Text(articleMarkdown: "The detail of his wife, and the oath he had sworn, ends in mercy: he was told to take a bundle of grass and strike once with it so as not to break his oath. The Quran preserves it as an easing, not a punishment.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Patience is not refusing to ask.** He did call on his Lord. Patience is in how you ask, and in never accusing Allah in your asking.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Allah tests those He loves.** Illness is not a sign of Allah's anger. Ayyub was a prophet through every year of it.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Relief comes, and it comes complete.** He was given his family back and the like of them with them. Allah does not restore by halves.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Ayyub lost everything a man can lose and Allah called him an excellent servant, one who constantly turned back: the whole definition of patience in one verse.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetAyyubView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetAyyubView")
        .navigationTitle("Ayyub")
    }
}

// MARK: - 13. Shu'ayb

struct ProphetShuaybView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Shu'ayb (peace be upon him) was sent to Madyan, a people who cheated in weights and measures, and he tied honest trade directly to faith.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Shu'ayb (شُعَيب)** was sent to **Madyan (مَديَن)**, a trading people of the north-west of Arabia, and to the Companions of the Wood. He is named 11 times in the Quran. He is often called the orator of the prophets for the clarity with which he argued.")
                        .font(.body)

                    ScriptureQuote(quran: "7:85")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "Their sin was not idolatry alone. They short-changed people in the scales, and Shu'ayb made the connection that the Quran keeps making: worship and honest dealing are one religion, not two.")
                        .font(.body)
                    ScriptureQuote(quran: "26:181-183")

                    Text(verbatim: "They answered him with the argument of every people who want religion kept out of their business:").font(.body)
                    ScriptureQuote(quran: "11:87")

                    Text(verbatim: "He told them plainly that he was not asking them for anything, and that he did not want to do himself what he forbade them from. When they refused, the punishment took them:")
                        .font(.body)
                    ScriptureQuote(quran: "11:94")

                    Text(articleMarkdown: "Madyan is also where **Musa** (peace be upon him) fled after leaving Egypt, where he watered the flocks of two women and married one of them, and served their father ten years. The Quran does not name that father, and the common identification of him as Shu'ayb is not established.")
                        .font(.body)
                    ScriptureQuote(quran: "28:27")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Cheating in trade is a matter of creed.** A whole nation was destroyed over weights and measures. Islam does not separate the prayer mat from the marketplace.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Practise before you preach.** He said he did not want to contradict himself by doing what he forbade. A caller is measured against his own words first.")
                        .font(.body)

                    Text(articleMarkdown: "3. **“Our wealth is our own business“ is an old objection.** They mocked him for thinking prayer had anything to do with their money. It had everything to do with it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Shu'ayb told a nation of traders that a crooked scale and a sound faith cannot live in the same man, and they refused to believe him.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetShuaybView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetShuaybView")
        .navigationTitle("Shu'ayb")
    }
}

// MARK: - 14. Musa

struct ProphetMusaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Musa (peace be upon him) is the prophet Allah spoke to directly, who confronted Pharaoh, brought the Children of Israel out of Egypt, and received the Torah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Musa (مُوسَى)**, Moses, is named 136 times in the Quran, more than any other prophet. He is one of the five messengers of firm resolve, and Allah gave him a distinction He gave to no one else in the same way: He spoke to him directly, which is why he is called **Kalimullah (كَلِيمُ اللَّه)**.")
                        .font(.body)

                    ScriptureQuote(quran: "4:164")
                }

                Section(header: ArticleHeader("EGYPT AND THE FLIGHT")) {
                    Text(verbatim: "He was born while Pharaoh was killing the newborn sons of the Children of Israel. His mother was inspired to put him in the river, and Allah returned him to her arms to be nursed, raised in Pharaoh's own house:")
                        .font(.body)
                    ScriptureQuote(quran: "28:7-13")

                    Text(verbatim: "As a young man he struck an Egyptian in defence of an Israelite and the man died. He did not excuse it. He called it what it was and asked forgiveness:")
                        .font(.body)
                    ScriptureQuote(quran: "28:15-16")

                    Text(verbatim: "He fled to Madyan, watered the flocks of two women, married, and served ten years. On the way back, at the mountain, he saw a fire.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE CALL AND PHARAOH")) {
                    Text(verbatim: "At the valley of Tuwa, Allah spoke to him and appointed him:").font(.body)
                    ScriptureQuote(quran: "20:9-14")

                    Text(verbatim: "He was afraid, and he asked for his brother Harun to be sent with him, and he asked for something else first, which is one of the most quoted duas in the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "20:25-28")

                    Text(verbatim: "Pharaoh had claimed divinity outright. Allah sent Musa to him with a specific instruction about how to speak to him:").font(.body)
                    ScriptureQuote(quran: "20:43-44")

                    Text(verbatim: "The magicians were gathered and Musa's staff swallowed what they had made. They knew at once that it was not magic, and they believed on the spot. Pharaoh threatened to crucify them, and their answer is one of the great statements of faith in the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "20:72-73")
                }

                Section(header: ArticleHeader("THE SEA AND THE TORAH")) {
                    Text(verbatim: "He led the Children of Israel out at night. With the sea ahead and Pharaoh's army behind, his people said they were caught, and he answered:")
                        .font(.body)
                    ScriptureQuote(quran: "26:61-63")

                    Text(verbatim: "The sea parted, they crossed, and Pharaoh drowned in it. Allah says his body was preserved as a sign. Musa went to the mountain for forty nights and was given the Torah, and while he was away his people made the calf.")
                        .font(.body)

                    Text(verbatim: "He asked to see his Lord, and was answered:").font(.body)
                    ScriptureQuote(quran: "7:143")

                    Text(articleMarkdown: "The Prophet (peace and blessings be upon him) fasted **Ashura** for the same deliverance, and claimed Musa as his own:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:2004", cite: "Sahih al-Bukhari 2004", english: [48...55, 56...71])
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Speak gently, even to a tyrant.** The instruction to Musa and Harun before Pharaoh was to speak a gentle word. If that was the manner with Pharaoh, harshness has no excuse anywhere else.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Ask Allah to open your chest before you ask Him for the task.** His dua at Tuwa asked for ease in himself first, and for a helper, before anything else.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Certainty is not the absence of a visible way out.** With the sea in front and the army behind, he said his Lord was with him and would guide him, and the sea was not yet open when he said it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Raised in the tyrant's house to bring down the tyrant, Musa was given the Torah, the sea, and the one honour of being spoken to by Allah directly.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetMusaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetMusaView")
        .navigationTitle("Musa")
    }
}

// MARK: - 15. Harun

struct ProphetHarunView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Harun (peace be upon him) was the brother Musa asked for, sent with him to Pharaoh, and left in charge when Musa went to the mountain.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Harun (هَارُون)**, Aaron, is the elder brother of Musa and a prophet in his own right. He is the answer to a dua: Musa asked for him by name, and Allah granted it.")
                        .font(.body)

                    ScriptureQuote(quran: "20:29-32")

                    Text(verbatim: "Allah records the granting of that request as a mercy, and calls Harun a prophet in the same verse:").font(.body)
                    ScriptureQuote(quran: "19:53")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "He was more eloquent than Musa, and Musa said so when he asked for him. The two went to Pharaoh together and were told together not to fear.")
                        .font(.body)

                    Text(verbatim: "When Musa went to the mountain for forty nights he left Harun over his people, and in his absence as-Samiri made the calf. Harun warned them and they would not listen:")
                        .font(.body)
                    ScriptureQuote(quran: "20:90-91")

                    Text(verbatim: "Musa returned in fury and seized his brother by the head and beard. Harun's answer shows what he had been weighing:").font(.body)
                    ScriptureQuote(quran: "20:94")

                    Text(verbatim: "He had feared that acting against them would split the people, and he had chosen to hold them together and wait. Musa then prayed for them both.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Ask Allah for the help you need, by name.** Musa asked for his brother specifically, and Allah gave him a prophet as his helper.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Unity is weighed against correction, and it is a real weight.** Harun feared dividing the people. The Quran records his reasoning without condemning it.")
                        .font(.body)

                    Text(articleMarkdown: "3. **A deputy is answerable.** He was left in charge and he was questioned about what happened on his watch, though he had warned them.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Harun was given to Musa as an answered prayer, stood beside him before Pharaoh, and held a people together while they turned to a calf.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetHarunView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetHarunView")
        .navigationTitle("Harun")
    }
}

// MARK: - 16. Dhul-Kifl

struct ProphetDhulKiflView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Dhul-Kifl (peace be upon him) is named twice in the Quran, both times among the patient and the excellent, and nothing more of his story is given.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Dhul-Kifl (ذُو الكِفل)** is one of the briefest entries in the Quran. He is named twice, each time in a list of prophets Allah praises, and no episode of his life is related.")
                        .font(.body)

                    ScriptureQuote(quran: "21:85-86")

                    Text(verbatim: "And again among the excellent:").font(.body)
                    ScriptureQuote(quran: "38:48")
                }

                Section(header: ArticleHeader("WHAT IS AND IS NOT ESTABLISHED")) {
                    Text(articleMarkdown: "His name is often explained as “the one of the portion“ or “the one who took on a guarantee,“ from **kifl (كِفل)**, a share or a pledge, and he is commonly identified with Ezekiel. He is also said to have pledged to fast by day, stand by night and judge without anger, and to have kept it.")
                        .font(.body)

                    Text(verbatim: "None of that is established from the Quran or from an authentic narration. Scholars even differed over whether he was a prophet at all or a righteous man, though the apparent meaning of the verses, since he is listed among prophets, is that he was one.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) gave the rule for reports like these:").font(.body)
                    ScriptureQuote(hadith: "bukhari:7362", cite: "Sahih al-Bukhari 7362", english: 28...56)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Allah's testimony is the whole record.** Patient, righteous, among the excellent: that is what Allah chose to preserve about him, and it is more than a biography.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Do not fill Allah's silences.** The honest answer about his life is that we do not know, and saying so is part of knowledge.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Two verses, both of them praise, and no story: Dhul-Kifl is remembered for his patience and for nothing we were told to add to it.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetDhulKiflView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetDhulKiflView")
        .navigationTitle("Dhul-Kifl")
    }
}

// MARK: - 17. Dawud

struct ProphetDawudView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Dawud (peace be upon him) killed Jalut as a young man, was given kingship and the Zabur, and the mountains and birds joined him when he praised Allah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Dawud (دَاوُود)**, David, is both a prophet and a king, which the Quran notes as a combined gift. He was given the **Zabur (زَبُور)**, the Psalms. He is named 16 times.")
                        .font(.body)

                    ScriptureQuote(quran: "2:251")

                    Text(verbatim: "He was a youth in the army of Talut when he killed Jalut, the giant, and Allah gave him kingship and wisdom afterwards.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT HE WAS GIVEN")) {
                    Text(verbatim: "Allah subjected the mountains and the birds to praise along with him, and softened iron in his hands:").font(.body)
                    ScriptureQuote(quran: "34:10-11")

                    Text(verbatim: "He made his own armour and ate from the work of his hands. The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(hadith: "bukhari:2073", cite: "Sahih al-Bukhari 2073", english: 4...19)

                    Text(verbatim: "His worship was the measure the Prophet (peace and blessings be upon him) held up as the best, precisely because it was sustainable:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1131", cite: "Sahih al-Bukhari 1131", english: 5...57)

                    Text(verbatim: "He judged between people, and Allah taught him and his son in a case where they ruled differently and praised them both:").font(.body)
                    ScriptureQuote(quran: "21:78-79")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Eat from the work of your own hands.** A prophet and a king made armour for a living. Work is not beneath anyone.")
                        .font(.body)

                    Text(articleMarkdown: "2. **The best worship is what you can keep up.** Half the night in prayer, a day of fasting and a day off: the Prophet called this the most beloved to Allah, not the most extreme.")
                        .font(.body)

                    Text(articleMarkdown: "3. **A sincere judge who errs is not condemned.** Allah gave understanding to Sulayman in that case and praised both of them for judgement and knowledge.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Dawud was given a kingdom, a scripture, a voice the mountains answered, and a trade he lived from: worship and work in one life.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetDawudView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetDawudView")
        .navigationTitle("Dawud")
    }
}

// MARK: - 18. Sulayman

struct ProphetSulaymanView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Sulayman (peace be upon him) was given a kingdom like no one after him, understood the speech of birds and ants, and ruled over the jinn and the wind.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Sulayman (سُلَيمَان)**, Solomon, is the son of Dawud and inherited his prophethood and his kingdom. He asked Allah for a kingdom that would belong to no one after him, and it was given:")
                        .font(.body)

                    ScriptureQuote(quran: "38:35-36")

                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "He was taught the speech of the birds, and the Quran records him overhearing an ant warn her colony to get out of the way of his armies. His reaction was not pride at the power but gratitude for it:")
                        .font(.body)
                    ScriptureQuote(quran: "27:16-19")

                    Text(verbatim: "The hoopoe brought him news of a queen in Saba whose people prostrated to the sun. He did not act on the report until he had checked it:")
                        .font(.body)
                    ScriptureQuote(quran: "27:27-28")

                    Text(verbatim: "And the letter he sent called her to Islam, not to submission to himself:")
                        .font(.body)
                    ScriptureQuote(quran: "27:30-31")

                    Text(verbatim: "Her throne was brought to him in the time it takes to blink, by one who had knowledge of the Scripture, and again his response was about himself and not about the marvel:")
                        .font(.body)
                    ScriptureQuote(quran: "27:40")

                    Text(verbatim: "She came, saw, and declared her faith along with him. And when Sulayman died, the jinn who had been made to labour for him did not know it until a worm ate through his staff and he fell, which the Quran gives as proof that they do not know the unseen:")
                        .font(.body)
                    ScriptureQuote(quran: "34:14")
                }

                Section(header: ArticleHeader("MAGIC IS NOT HIS")) {
                    Text(verbatim: "Sulayman is falsely associated with magic and with talismans bearing his name. The Quran answers this charge directly and clears him of it:")
                        .font(.body)
                    ScriptureQuote(quran: "2:102", words: 0...23)

                    Text(articleMarkdown: "Magic is **kufr**, disbelief, and Sulayman did not disbelieve. Any amulet, seal or ring sold in his name is a lie against a prophet.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **The greater the blessing, the greater the gratitude owed.** At every marvel in his story, Sulayman's first words are about thanking Allah and about his own soul.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Verify a report before you act on it.** He told the hoopoe he would see whether it had told the truth, and this from a bird that had never lied to him.")
                        .font(.body)

                    Text(articleMarkdown: "3. **The jinn do not know the unseen.** They laboured on for a dead king leaning on a staff. This one verse closes the door on every claim built on their supposed knowledge.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Given wind, jinn, and the speech of animals, Sulayman's recorded reaction to all of it was to ask Allah to let him be grateful.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetSulaymanView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetSulaymanView")
        .navigationTitle("Sulayman")
    }
}

// MARK: - 19. Ilyas

struct ProphetIlyasView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Ilyas (peace be upon him) was sent to a people who worshipped an idol called Ba'l, and he called them back to Allah alone.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Ilyas (إِليَاس)**, Elias, is named twice in the Quran. He was sent to a people of the Children of Israel who had taken an idol named **Ba'l (بَعل)** beside Allah.")
                        .font(.body)

                    ScriptureQuote(quran: "37:123-126")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "The Quran's account is short. He called them, they denied him, and Allah records the outcome and the reason for it:").font(.body)
                    ScriptureQuote(quran: "37:127-132")

                    Text(verbatim: "Allah also names him among the guided, in the line of Ibrahim:").font(.body)
                    ScriptureQuote(quran: "6:85")

                    Text(verbatim: "Beyond this the Quran and the authentic Sunnah give nothing. The many stories told of him, including that he is still alive, are not established.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Every idol has a name, and naming it is part of the call.** He did not speak about shirk in the abstract. He asked them why they called on Ba'l.")
                        .font(.body)

                    Text(articleMarkdown: "2. **“Will you not fear Allah?“ is the whole message.** His opening question is the same one Nuh, Hud, Salih and Shu'ayb opened with.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Ilyas asked a people worshipping an idol why they had left the best of creators, and Allah preserved his name among the believers.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetIlyasView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetIlyasView")
        .navigationTitle("Ilyas")
    }
}

// MARK: - 20. Alyasa

struct ProphetAlyasaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Alyasa (peace be upon him) is named twice in the Quran, both times among the chosen and the excellent, with no episode of his life related.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Alyasa (اليَسَع)**, Elisha, was a prophet of the Children of Israel. Like Dhul-Kifl and Idris, the Quran names him in praise and tells no story about him.")
                        .font(.body)

                    ScriptureQuote(quran: "6:86")

                    Text(verbatim: "And among the excellent:").font(.body)
                    ScriptureQuote(quran: "38:48")
                }

                Section(header: ArticleHeader("WHAT IS AND IS NOT ESTABLISHED")) {
                    Text(verbatim: "He is commonly said to have been the companion and successor of Ilyas. That comes from the reports of the People of the Scripture and is not established from the Quran or an authentic narration, so it is neither affirmed nor denied.")
                        .font(.body)

                    Text(verbatim: "What Allah does state is his rank, and He states it twice: chosen above the worlds, and among the excellent.").font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Being counted among them is the honour.** Allah lists him beside Ismail and Yunus and says He preferred them above the worlds. No further detail is needed for that to mean something.")
                        .font(.body)

                    Text(articleMarkdown: "2. **A believer accepts the limits of what was revealed.** Belief in the prophets includes believing in those whose names and stories we were never given at all.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Alyasa is named among those Allah chose above the worlds, and that is the entire record we were given of him.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetAlyasaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetAlyasaView")
        .navigationTitle("Alyasa")
    }
}

// MARK: - 21. Yunus

struct ProphetYunusView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Yunus (peace be upon him) left his people without permission, was swallowed by the whale, and the dua he made in that darkness is answered for anyone who says it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Yunus (يُونُس)**, Jonah, was sent to the people of Nineveh. He is named 4 times and a surah carries his name. He is also called **Dhun-Nun (ذُو النُّون)**, the one of the whale, and **Sahib al-Hut**, the companion of the fish.")
                        .font(.body)

                    ScriptureQuote(quran: "37:139-141")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "He called his people and they did not answer, and he left them in anger before he was given permission to. He boarded a ship, lots were drawn, and he was thrown into the sea and swallowed by the whale.")
                        .font(.body)

                    Text(verbatim: "In three layers of darkness he called out, and the Quran preserves the exact words:").font(.body)
                    ScriptureQuote(quran: "21:87-88")

                    Text(articleMarkdown: "This is the **Dua of Yunus**, and the Prophet (peace and blessings be upon him) said of it:").font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3505", cite: "Jami' at-Tirmidhi 3505; graded sahih by al-Albani", english: 0...58)

                    Text(verbatim: "Allah says that had he not been of those who exalt Him, he would have stayed in the whale's belly until the Day of Resurrection. He was cast onto the open shore, ill, and a gourd plant was made to grow over him.")
                        .font(.body)

                    Text(verbatim: "And his people, alone among all the nations the Quran mentions, believed before the punishment fell:").font(.body)
                    ScriptureQuote(quran: "10:98")

                    Text(verbatim: "The Prophet (peace and blessings be upon him) also forbade anyone to claim superiority over him:").font(.body)
                    ScriptureQuote(hadith: "bukhari:3416", cite: "Sahih al-Bukhari 3416", english: 4...14)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Begin with tawhid, then admit the wrong.** His dua declares Allah's oneness and perfection first and only then confesses. That order is why it is answered.")
                        .font(.body)

                    Text(articleMarkdown: "2. **No darkness is outside Allah's reach.** Inside a whale, inside the sea, inside the night, and he was heard.")
                        .font(.body)

                    Text(articleMarkdown: "3. **A caller does not get to quit on his own timing.** His leaving was before permission, and the Quran never hides it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Yunus walked away, was swallowed by the sea, and called on Allah in a way that has been answering his descendants ever since.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetYunusView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetYunusView")
        .navigationTitle("Yunus")
    }
}

// MARK: - 22. Zakariya

struct ProphetZakariyaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Zakariya (peace be upon him) was an old man with a barren wife who asked Allah for an heir in private, and was given Yahya.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Zakariya (زَكَرِيَّا)**, Zachariah, was a prophet of the Children of Israel and the guardian of **Maryam**. He is named 7 times in the Quran. He worked as a carpenter, and the Prophet (peace and blessings be upon him) mentioned it:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2379", cite: "Sahih Muslim 2379", english: 0...7)

                    Text(verbatim: "He was appointed over Maryam, and what he saw in her chamber is what moved him to ask:").font(.body)
                    ScriptureQuote(quran: "3:37")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(verbatim: "He was old, his bones had weakened, his head was aflame with grey, and his wife had been barren all her life. He did not ask loudly:")
                        .font(.body)
                    ScriptureQuote(quran: "19:2-6")

                    Text(verbatim: "Allah answered him with the news of a son and even named the child Himself, and said He had given that name to no one before:")
                        .font(.body)
                    ScriptureQuote(quran: "19:7")

                    Text(verbatim: "He asked for a sign and was given one: he would not speak to people for three nights though he was sound. And the Quran sums up why such people are answered:")
                        .font(.body)
                    ScriptureQuote(quran: "21:89-90")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Call on Allah in secret.** The Quran points out that he called his Lord a private call. The best dua has no audience.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Nothing is too late to ask for.** An old man with a barren wife asked for a child, and the Quran preserves both the impossibility and the answer.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Ask for what will outlast you.** He wanted an heir to the religion, not to an estate. He said he feared for what would come after him.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "A private prayer from an old man who had every reason not to bother, and Allah named the child before he was born.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetZakariyaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetZakariyaView")
        .navigationTitle("Zakariya")
    }
}

// MARK: - 23. Yahya

struct ProphetYahyaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Yahya (peace be upon him) was given wisdom as a child, and Allah greeted him with peace on the day he was born, the day he dies, and the day he is raised.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Yahya (يَحيَى)**, John the Baptist, is the son of Zakariya, the answer to his father's private prayer. Allah named him Himself and gave him qualities in a single verse that few others are given.")
                        .font(.body)

                    ScriptureQuote(quran: "19:12-15")
                }

                Section(header: ArticleHeader("HIS STORY")) {
                    Text(articleMarkdown: "He was given the Scripture and told to take it **with strength** while still a boy, and he was given wisdom as a child. Allah describes him as dutiful to his parents and says plainly that he was not arrogant or disobedient.")
                        .font(.body)

                    Text(verbatim: "He confirmed Isa (peace be upon him) and was among the first to do so:").font(.body)
                    ScriptureQuote(quran: "3:39")

                    Text(verbatim: "He and his family are described as those who hurried to good deeds and called on Allah in hope and fear (Quran 21:90). The greeting of peace given to him is the same threefold greeting given to Isa.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Take the Book with strength.** Not casually, not as decoration. The command to Yahya was to hold it firmly, and it was given to him as a child.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Youth is no excuse for shallowness.** Allah gave him judgement while he was still young. Age is not the qualification.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Chastity and kindness to parents are named beside prophethood.** Allah lists them among his honours, which tells you what Allah counts as an honour.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Named by Allah, given wisdom as a boy, dutiful to his parents, and greeted with peace at birth, at death, and at the resurrection.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetYahyaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetYahyaView")
        .navigationTitle("Yahya")
    }
}

// MARK: - 24. Isa

struct ProphetIsaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Isa (peace be upon him) was born to Maryam without a father, given the Injil, raised up by Allah before he could be killed, and will return before the Hour. He is a servant of Allah, not His son.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Isa ibn Maryam (عِيسَى ابنُ مَريَم)**, Jesus son of Mary, is one of the five messengers of firm resolve. He is named 25 times in the Quran, given the **Injil (إِنجِيل)**, the Gospel, and is called the **Masih (مَسِيح)**, the Messiah. His mother Maryam is the only woman named in the Quran, and a surah carries her name.")
                        .font(.body)

                    ScriptureQuote(quran: "3:45-47")
                }

                Section(header: ArticleHeader("HIS BIRTH AND SIGNS")) {
                    Text(verbatim: "He was created without a father, and the Quran compares that creation to Adam's, who had neither father nor mother:").font(.body)
                    ScriptureQuote(quran: "3:59")

                    Text(verbatim: "Maryam was told to withdraw, and she bore him alone under a palm tree. When she brought him to her people and they accused her, she pointed to the infant, and he spoke from the cradle:")
                        .font(.body)
                    ScriptureQuote(quran: "19:29-33")

                    Text(articleMarkdown: "His first recorded words are **“Indeed, I am the servant of Allah“**, which is the answer to everything later claimed about him. Allah gave him signs by His permission: he formed a bird from clay and breathed into it, healed the blind and the leper, and revived the dead, and the Quran attaches **by Allah's permission** to each one:")
                        .font(.body)
                    ScriptureQuote(quran: "3:49")

                    Text(verbatim: "And he foretold the Messenger to come after him:").font(.body)
                    ScriptureQuote(quran: "61:6")
                }

                Section(header: ArticleHeader("HE WAS NOT CRUCIFIED")) {
                    Text(verbatim: "The Quran states directly that he was neither killed nor crucified, and that Allah raised him to Himself:").font(.body)
                    ScriptureQuote(quran: "4:157-158")

                    Text(verbatim: "He will return before the Day of Judgement, break the cross, and rule by the Sharia of Muhammad (peace and blessings be upon them both). The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3448", cite: "Sahih al-Bukhari 3448", english: 4...46)
                }

                Section(header: ArticleHeader("WHAT MUSLIMS DO NOT BELIEVE")) {
                    Text(articleMarkdown: "Loving and honouring Isa is part of Islam. Claiming he is Allah, or the son of Allah, or one of three, is **shirk**, and the Quran answers it explicitly:")
                        .font(.body)
                    ScriptureQuote(quran: "4:171")

                    Text(verbatim: "And Allah will ask him on the Day of Judgement, and his answer clears him of all of it:").font(.body)
                    ScriptureQuote(quran: "5:116")

                    Text(verbatim: "The Prophet (peace and blessings be upon him) warned against excess in praising him specifically:").font(.body)
                    ScriptureQuote(hadith: "bukhari:3445", cite: "Sahih al-Bukhari 3445", english: 6...35)
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **Every miracle was by Allah's permission.** The Quran repeats the phrase each time. The one who performs a sign is not the one who owns it.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Love without exaggeration.** A Muslim who denies Isa is not a Muslim, and a Muslim who deifies him is not either. The Sunnah is the middle.")
                        .font(.body)

                    Text(articleMarkdown: "3. **He called to the same thing every prophet called to.** Worship Allah, my Lord and your Lord. That sentence is in his mouth in the Quran twice.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Born of a virgin, speaking in the cradle, raising the dead by Allah's leave, and saying of himself only that he was the servant of Allah.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetIsaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetIsaView")
        .navigationTitle("Isa")
    }
}

// MARK: - 25. Muhammad

struct ProphetMuhammadView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Muhammad (peace and blessings be upon him) is the final Messenger, sent to all of humanity, given the Quran, and the example every Muslim follows.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Muhammad (مُحَمَّد)** is the last of the prophets and the only one sent to all people rather than to one nation. He was born in Makkah in the year 570 CE, received revelation at forty, and died in Madinah in 11 AH. He is named 4 times in the Quran by this name.")
                        .font(.body)

                    ScriptureQuote(quran: "33:40", words: 0...11)

                    Text(verbatim: "After him there is no prophet. Anyone claiming prophethood after him is a liar, and this is a matter of creed, not opinion.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT ALLAH SAYS OF HIM")) {
                    Text(verbatim: "Allah describes his character in a single verse:").font(.body)
                    ScriptureQuote(quran: "68:4")

                    Text(verbatim: "And names the purpose he was sent for:").font(.body)
                    ScriptureQuote(quran: "21:107")

                    Text(verbatim: "And makes him the standard to follow:").font(.body)
                    ScriptureQuote(quran: "33:21")

                    Text(verbatim: "And states that he does not speak from himself:").font(.body)
                    ScriptureQuote(quran: "53:3-4")
                }

                Section(header: ArticleHeader("LOVE WITHOUT EXCESS")) {
                    Text(verbatim: "A Muslim must love him more than his own family and himself. The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(hadith: "bukhari:15", cite: "Sahih al-Bukhari 15", english: 4...22)

                    Text(articleMarkdown: "And that love is shown by **following him**, not by exceeding the bounds in praising him. He forbade that himself, in the clearest terms:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3445", cite: "Sahih al-Bukhari 3445", english: 6...35)

                    Text(verbatim: "So he is never called upon, never asked for help, and never sought for rescue: those belong to Allah alone. He is loved, obeyed, and sent blessings upon, and Allah commands that:")
                        .font(.body)
                    ScriptureQuote(quran: "33:56")
                }

                Section(header: ArticleHeader("LESSONS")) {
                    Text(articleMarkdown: "1. **He is the seal.** Belief in his finality is part of the Shahadah. No revelation, no prophet, and no new law comes after him.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Following is the proof of loving.** Allah tied His own love to it: say, if you love Allah, then follow me, and Allah will love you (Quran 3:31).")
                        .font(.body)

                    Text(articleMarkdown: "3. **Honour him as Allah honoured him, and no further.** Servant and Messenger. He chose those two words for himself, and so should we.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The last Messenger, sent as a mercy to all the worlds, whose example is the way and whose finality is part of the creed.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetMuhammadView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "ProphetMuhammadView")
        .navigationTitle("Muhammad")
    }
}
