import SwiftUI

// Refuting Religions: other faiths and worldviews, described fairly and answered.
// Written 2026-11-24 (Abu: "Add these new Islamic resources"), Sunni upon the way of the Salaf, and held
// to the app's rules: every ayah a `.ayah(` reference into the bundled Quran, every hadith a `.hadith(`
// reference into the bundled shelf graded sahih or hasan, scholars' words quoted only with their source.
// The chapters are catalog articles (`IslamArticleCatalog`, home `.religions`), drawn by
// IslamLibraryView, so search, the Ask AI corpus and each page's own search reach them.

// MARK: - religions-1

struct ReligionsMethodView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsMethodView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("How the Quran Argues With Other Faiths")
        .englishArticle().selectableArticleList(article: "ReligionsMethodView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran does not only announce its creed; it argues for it, and it teaches its readers how to argue. It calls with wisdom, good counsel and the best kind of debate, asks every claimant for his proof, and offers its own from creation, from reason and from the other side’s own scripture. It forbids compulsion, insult and injustice toward opponents, and the Prophet Muhammad (peace and blessings be upon him) followed the same method in his letters, his debates and his treaties. This chapter sets out that method, which every chapter of this library follows."),
        ]),
        ArticleSection("A BOOK THAT ARGUES", [
            .text("Read any long passage of the Quran and you meet the voices of its opponents. The idolaters of Makkah, the Jews of Madinah, the Christians of Najraan, the deniers of the resurrection and the hypocrites all speak in it, often in their own words, and each is answered. The answer usually begins with one word, qul, “say”, which runs through the Quran hundreds of times: they say this, so say that."),
            .longOnly(.text("It records the arguments themselves, not caricatures of them. The idolaters’ appeal to fate is stated before it is refuted: had Allah willed, they said, neither we nor our fathers would have worshipped others (6:148). The objection to the resurrection is given its most vivid form, a man holding up a crumbling bone and asking who will give life to this (36:78). A book that wanted only obedience would not record its critics so carefully.")),
            .longOnly(.ayah("6:148")),
            .longOnly(.ayah("36:78")),
            .text("The Quran gathers its method into one command:"),
            .ayah("16:125"),
            .markdown("Three tools are named. **Wisdom (hikmah)** is the truth put plainly and in its proper place. **Good instruction (maw‘izah hasanah)** is counsel that reaches the heart: reminder, warning and hope. **Argument in the way that is best (jadal billati hiya ahsan)** is debate that stays courteous and fair. Ibn al-Qayyim (may Allah have mercy on him) observed that the three suit three kinds of listener: the one who wants the truth and accepts it once he sees it needs wisdom; the one who accepts it but is held back by desire or habit needs good counsel; and the one who disputes it needs the best argument."),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) explains under this ayah that whoever needs to be debated should be debated gently, softly and with good speech, and he points to the command given to Moosa and Haaroon (peace be upon them) when they were sent to the worst tyrant of their age:")),
            .shortOnly(.text("The same gentleness was commanded when Moosa and Haaroon (peace be upon them) were sent to the worst tyrant of their age:")),
            .ayah("20:43-44"),
            .callout("If Pharaoh, who called himself a lord, was to be addressed with gentle speech, no opponent today deserves less. Gentleness is the Quran’s instruction, not a concession to the listener.", title: "The Lesson", icon: "lightbulb.fill"),
        ]),
        ArticleSection("BRING YOUR PROOF", [
            .longOnly(.text("Four times the Quran turns to people who make claims about God and gives the same reply: produce your proof, if you are truthful. It says it to the Jews and Christians who each claimed Paradise for themselves alone, to those who took other gods, to those who gave Allah partners in His creation, and, on the Day of Resurrection, to every nation that followed what it had invented (2:111, 21:24, 27:64, 28:75).")),
            .shortOnly(.text("Four times the Quran turns to people who make claims about God and gives the same reply: produce your proof, if you are truthful. It says it first to the Jews and Christians who each claimed Paradise for themselves alone:")),
            .ayah("2:111"),
            .longOnly(.ayah("21:24")),
            .longOnly(.ayah("27:64")),
            .longOnly(.ayah("28:75")),
            .longOnly(.text("The demand is specific. Allah names the two kinds of evidence that could support a claim of other gods: something they created, or a revelation that speaks for them.")),
            .longOnly(.ayah("46:4")),
            .longOnly(.text("Where neither exists, the Quran names what is left. When the idolaters argued from fate, it asked whether they had any knowledge to bring out, and answered that they followed nothing but assumption (6:148). When they defended their worship by the practice of their fathers, it asked whether they would follow their fathers even if their fathers understood nothing (2:170). This is the first rule of the method: whoever makes a claim about God carries the burden of proving it, and custom, opinion and inheritance are not proof.")),
            .shortOnly(.text("When the idolaters defended their worship by the practice of their fathers, the Quran asked whether they would follow them even if their fathers understood nothing (2:170). This is the first rule of the method: whoever makes a claim about God carries the burden of proving it, and custom is not proof.")),
            .ayah("2:170"),
            .text("The rule binds the Muslim as tightly as anyone. He may not say about Allah what he does not know (7:33), and he may not attribute to another religion what its followers do not believe. A refutation of a position no one holds refutes nothing, and the Quran never needs one. That is why this library describes each religion as its own followers would describe it before it gives the answer."),
            .ayah("7:33"),
        ]),
        ArticleSection("REASON AND CREATION", [
            .longOnly(.text("The Quran’s proofs are of kinds any honest person can weigh. It argues from the plain fact that we began, asking whether people were created by nothing or created themselves (52:35-36); a pagan who heard those verses said his heart nearly flew (Saheeh al-Bukhaari 4854).")),
            .shortOnly(.text("The Quran’s proofs are of kinds any honest person can weigh. It argues from the plain fact that we began, asking whether people were created by nothing or created themselves:")),
            .ayah("52:35-36"),
            .longOnly(.hadith("bukhari:4854", cite: "Saheeh al-Bukhaari 4854", arabic: 22...63, english: [0...78])),
            .text("It argues from the order of the world:"),
            .ayah("21:22"),
            .longOnly(.ayah("23:91", words: 10...19)),
            .longOnly(.markdown("The scholars of creed call this the **argument from mutual hindrance (daleel at-tamanu‘)**. Suppose two gods, each with real power, and suppose their wills differ. Either both wills are carried out, which is impossible; or one prevails and the other fails, and the one who fails is no god; or neither prevails, and neither is. A single order running through the heavens and the earth is the mark of a single will behind it.")),
            .shortOnly(.text("If there were two gods with real power and their wills differed, one would prevail and the other would be no god. A single order running through the heavens and the earth is the mark of a single will behind it.")),
            .longOnly(.text("It argues, too, from the weakness of everything worshipped besides Allah. All the idols together could not create a fly, nor take back what a fly steals from them:")),
            .longOnly(.ayah("22:73")),
            .text("None of these arguments asks the listener to accept the Quran first. They start from the world in front of him and the reasoning in his own mind, and the Quran’s repeated question to its opponents is a simple one: will you not reason?"),
        ]),
        ArticleSection("IBRAAHEEM'S DEBATES", [
            .text("The Quran holds up one prophet above all as a model of argument. After telling how Ibraaheem (peace be upon him) reasoned with his people, it says:"),
            .ayah("6:83", words: 0...5),
            .longOnly(.text("Three of his debates are told in detail, and each teaches something different.")),
            .shortOnly(.text("His debate over the heavenly bodies shows the method at its clearest.")),
            .markdown("**Begin from the other side’s premise.** His people venerated the heavenly bodies. On a dark night he saw a star and said, this is my lord; when it set, he said, I do not love things that set. He did the same with the moon, and then with the sun, and when the sun set he declared himself free of everything they worshipped:"),
            .ayah("6:76-79"),
            .longOnly(.text("Ibn Katheer holds that Ibraaheem was not searching for his Lord in these words, since Allah had given him his guidance before (21:51). He was debating his people: taking their own premise, that these lights were lords, and letting it fall by a fact they could all see. What disappears, changes and keeps to a course it cannot leave is not the Lord of the worlds. The next aayaat confirm the setting: his people argued with him, and he answered them (6:80-81).")),
            .shortOnly(.text("Ibn Katheer holds that Ibraaheem was not searching for his Lord here. He was debating his people: taking their own premise, that these lights were lords, and letting it fall by a fact they could all see.")),
            .longOnly(.ayah("21:51")),
            .longOnly(.ayah("6:80-81")),
            .longOnly(.markdown("**Close the door on evasion.** A king, whom the early reports in the tafseer name Namrood, argued with Ibraaheem about his Lord:")),
            .longOnly(.ayah("2:258")),
            .longOnly(.text("The king answered Ibraaheem’s first argument with a trick: he could spare one condemned man and execute another. Ibraaheem did not stop to untangle the confusion in front of the court. He moved to a sign that left no room for the same trick, and the king had nothing to say. The first argument was sound; the second simply made the point too plain to be twisted.")),
            .longOnly(.markdown("**Let them say it themselves.** Ibraaheem broke his people’s idols and left the largest standing. When they questioned him, he told them to ask the idols, if they could speak:")),
            .longOnly(.ayah("21:62-67", words: 26...30)),
            .longOnly(.text("The decisive sentence in the scene is spoken by his opponents: you know very well these do not speak. He did not need to prove that the idols were helpless. He arranged matters so that his people said it, and then asked the one question that remained: do you worship, instead of Allah, what can neither benefit you nor harm you?")),
            .shortOnly(.text("His other debates follow the same line. When he broke his people’s idols and told them to ask the largest one, it was his opponents who spoke the decisive sentence: you know very well these do not speak.")),
            .door(.article("StoryIbrahimView")),
        ]),
        ArticleSection("THE PEOPLE OF THE BOOK", [
            .text("Jews and Christians have a standing in the Quran that idolaters do not: they received revelation, and much of what they believe about Allah, His prophets and the Last Day is shared. So the Quran sets a higher standard of courtesy in arguing with them, and tells the Muslim where to begin:"),
            .ayah("29:46"),
            .longOnly(.text("Begin from what is shared: one God, revelation, the prophets. The ayah makes one exception, those of them who do wrong, whom the exegetes explain as the ones who meet the call with stubborn hostility and aggression instead of argument; with them the matter is no longer one of debate. The exception is about conduct, not belief: a Christian or a Jew who disagrees courteously is owed courtesy.")),
            .longOnly(.text("The common ground is not the goal. It is the place from which the invitation is made:")),
            .shortOnly(.text("Begin from what is shared: one God, revelation, the prophets. The common ground is not the goal, though. It is the place from which the invitation is made:")),
            .ayah("3:64"),
            .text("The last words matter. If they turn away, the Muslim does not blur the difference; he states it: bear witness that we are Muslims. Courtesy and clarity are commanded together, and neither is allowed to cancel the other."),
            .longOnly(.text("The Quran models a striking modesty in the very form of argument. It tells the Prophet to say to the idolaters:")),
            .longOnly(.ayah("34:24-25")),
            .longOnly(.text("He does not say “you are in error”; he says one of the two parties is, and leaves the listener to work out which. He calls the crimes his own side’s and his opponents’ deeds simply what they do. The truth is never in doubt in the passage, but the way it is put leaves the listener his dignity, so that he is free to think.")),
            .longOnly(.text("With the People of the Book the Quran also argues from their own scripture. When some of the Jews of Madinah disputed a law about food, it told the Prophet to say: bring the Torah and recite it, if you are truthful (3:93). He did exactly that when a case of adultery was brought to him. He asked what the Torah said; it was brought, and when its reader covered the verse of stoning with his hand, Abdullah ibn Salaam (may Allah be pleased with him), a former rabbi, told him to lift it (Saheeh al-Bukhaari 3635).")),
            .longOnly(.ayah("3:93")),
            .longOnly(.hadith("bukhari:3635", cite: "Saheeh al-Bukhaari 3635, Saheeh Muslim 1699", arabic: 38...102, english: [24...131])),
            .longOnly(.text("For the many reports of the People of the Book that the Quran neither confirms nor denies, the Prophet set a rule:")),
            .longOnly(.hadith("bukhari:4485", cite: "Saheeh al-Bukhaari 4485", arabic: 47...58, english: [30...52])),
            .longOnly(.text("What the Quran confirms is confirmed, what it denies is denied, and the rest is left without belief or denial. And however deep the difference, the Muslim does not insult what others hold sacred in a way that provokes them to insult Allah:")),
            .longOnly(.ayah("6:108")),
        ]),
        ArticleSection("HOW THE PROPHET ARGUED", [
            .text("The Prophet’s letters to the rulers of his time show the whole method in a few lines. After the truce of al-Hudaybiyah he wrote to Heraclius, the Byzantine emperor. Abu Sufyaan (may Allah be pleased with him), who was still an enemy then, heard it read aloud in the emperor’s court and later narrated it:"),
            .hadith("bukhari:7", cite: "Saheeh al-Bukhaari 7", arabic: 485...552, english: [919...1059]),
            .longOnly(.text("Every phrase is measured. He calls himself the slave of Allah and His messenger, not a king. He gives Heraclius his title. He sends peace to whoever follows guidance, which neither curses the reader nor pretends to agree with him. He promises safety and a double reward, because a Christian who believed in Eesa (peace be upon him) and then believes in Muhammad is rewarded for both (Saheeh al-Bukhaari 97). He warns that the emperor will carry the sin of the subjects he holds back. And he closes with 3:64, the common word.")),
            .longOnly(.hadith("bukhari:97", cite: "Saheeh al-Bukhaari 97", arabic: 33...43, english: [4...10, 12...40])),
            .shortOnly(.text("Every phrase is measured. He calls himself the slave of Allah, not a king, and gives Heraclius his title. He sends peace to whoever follows guidance, which neither curses the reader nor pretends to agree with him, and he closes with 3:64, the common word.")),
            .longOnly(.text("Late in his life a delegation of Christian leaders came from Najraan in southern Arabia and disputed with him in Madinah about Eesa. The Quran answered that the example of Eesa is like that of Aadam, created from dust (3:59).")),
            .longOnly(.ayah("3:59")),
            .longOnly(.text("When the proof had been set out and they still disputed, it gave the Prophet a final step:")),
            .shortOnly(.text("Late in his life a delegation of Christian leaders from Najraan disputed with him in Madinah about Eesa (peace be upon him). When the proof had been set out and they still disputed, the Quran gave the Prophet a final step:")),
            .ayah("3:61"),
            .shortOnly(.text("This is the mubaahalah: both sides call down Allah’s curse on whichever of them is lying. The leaders of Najraan conferred, drew back and chose a treaty instead, keeping their religion. The mubaahalah was the last step of a debate, not the first, and the other side was free to decline it.")),
            .longOnly(.text("This is the mubaahalah: both sides call down Allah’s curse on whichever of them is lying. When the ayah came down, the Prophet called Ali, Faatimah, al-Hasan and al-Husayn (may Allah be pleased with them) and said, O Allah, these are my family (Saheeh Muslim 2404).")),
            .longOnly(.hadith("muslim:2404d", cite: "Saheeh Muslim 2404", arabic: 158...183, english: [207...237])),
            .longOnly(.text("The two leaders of Najraan conferred and drew back:")),
            .longOnly(.hadith("bukhari:4380", cite: "Saheeh al-Bukhaari 4380", arabic: 20...107, english: [0...147])),
            .longOnly(.text("They chose a treaty and kept their religion, and the Prophet sent Abu Ubaydah ibn al-Jarraah (may Allah be pleased with him) back with them. The mubaahalah was the last step of a debate, not the first. It came after the proof had been made clear, and the other side was free to decline it.")),
            .longOnly(.text("His Companions met the same kind of question far from Madinah. When al-Mugheerah ibn Shu‘bah (may Allah be pleased with him) was in Najraan, the Christians there put an objection to him that he could not answer:")),
            .longOnly(.hadith("muslim:2135", cite: "Saheeh Muslim 2135", arabic: 43...79, english: [0...73])),
            .longOnly(.text("The Quran calls Maryam (peace be upon her) the sister of Haaroon (19:28), and the objection assumed it meant Haaroon the brother of Moosa (peace be upon them), who lived many centuries before her. The answer was that her people named their children after their prophets and righteous forebears. Al-Mugheerah did not invent a reply on the spot. He took the question back to knowledge, and the answer was waiting there. Every Muslim who meets an objection he cannot yet answer stands where al-Mugheerah stood, and the right course is the same.")),
            .longOnly(.ayah("19:28")),
        ]),
        ArticleSection("JUSTICE TOWARD OPPONENTS", [
            .text("The method has one more rule, and it is the hardest to keep in the heat of an argument:"),
            .ayah("5:8", words: 8...18),
            .longOnly(.text("The Quran practises what it commands. In the middle of a sharp rebuke of the People of the Book, it stops to say that some of them, if trusted with a fortune, would return it in full, while others would not return a single coin unless pressed (3:75). Opponents are not described as all alike, and their virtues are not hidden.")),
            .longOnly(.ayah("3:75")),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him), author of some of the most searching refutations of other religions in Islamic history, held that justice is owed by everyone to everyone in every situation, and that injustice is forbidden even toward a disbeliever. He acted on it. In a letter to the Christian king of Cyprus he recalled how he had negotiated with the Mongol commander for the release of captives. When the commander offered to free the Muslims alone, Ibn Taymiyyah would not accept until the Christians and Jews living under the Muslims’ protection were freed with them, and many of them were.")),
            .shortOnly(.text("The Quran practises what it commands: opponents are not described as all alike, and their virtues are not hidden. As Ibn Taymiyyah (may Allah have mercy on him) held, justice is owed by everyone to everyone, and injustice is forbidden even toward a disbeliever.")),
            .checklist(["**Describe** the other side as its own followers would.", "**Answer** what it actually holds, at its strongest.", "**Acknowledge** what is good in it.", "**Never insult** what it reveres.", "**State the truth** plainly, without blurring the difference."], title: "The Method in Five Lines", icon: "checkmark.circle.fill"),
        ]),
        ArticleSection("THE GREAT WORKS OF REPLY", [
            .longOnly(.text("Muslim scholars wrote whole books in this spirit. Two stand at the head of the tradition of Ahl as-Sunnah, by a teacher and his student.")),
            .longOnly(.markdown("**Al-Jawaab as-Saheeh li man Baddala Deen al-Maseeh**, “The Correct Answer to Those Who Changed the Religion of the Messiah”, by Ibn Taymiyyah (d. 728 AH, 1328 CE), answers a Christian treatise sent from Cyprus. He quotes its arguments section by section and replies to each from the Quran, from reason and from the Bible itself, and shows that the dispute is over what was changed in the religion of Eesa, not over Eesa himself.")),
            .longOnly(.markdown("**Hidaayat al-Hayaara fi Ajwibat al-Yahood wan-Nasaara**, “Guiding the Perplexed in Answering the Jews and the Christians”, by Ibn al-Qayyim (d. 751 AH, 1350 CE), answers the questions the People of the Book raised in his day, and gathers the glad tidings of the Prophet in their scriptures together with the reasons so many who knew of him still did not follow him.")),
            .longOnly(.text("Both books quote the other side fairly, argue from shared premises, read the opponent’s scripture with care, and state a firm conclusion without contempt. The chapters on Christianity and Judaism draw on them, and the Domino Process sets out the same reasoning as a path an enquirer can walk, step by step, from the existence of God to Islam.")),
            .shortOnly(.text("Ibn Taymiyyah and Ibn al-Qayyim wrote whole books of reply in this spirit, and the chapters on Christianity and Judaism draw on them; the Domino Process sets out the same reasoning as a path from the existence of God to Islam.")),
            .door(.article("ChristianityAnswerView")),
            .door(.article("DominoIntroView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Doesn’t Islam discourage arguing about religion?**"),
            .text("It discourages one kind and commands another. The Prophet promised a house in Paradise to whoever gives up wrangling:"),
            .hadith("abudawud:4800", cite: "Sunan Abi Daawood 4800; graded hasan by al-Albaani", arabic: 34...62, english: [4...60]),
            .longOnly(.text("He also warned that no people went astray after guidance except that they were given to dispute (Jaami‘ at-Tirmidhi 3253; graded hasan by Darussalam). The argument blamed in these narrations is miraa’: disputing to win, to show off, or to push back against a truth that is already clear. The argument commanded in 16:125 is its opposite: argument that makes the truth clear, with knowledge, courtesy and a sincere wish for the other person’s guidance. When a discussion turns into the first kind, the Sunnah is to leave it, even when one is in the right.")),
            .longOnly(.hadith("tirmidhi:3253", cite: "Jaami‘ at-Tirmidhi 3253; graded hasan by Darussalam", arabic: 30...39, english: [7...19])),
            .shortOnly(.text("The argument blamed here is miraa’: disputing to win or to push back against a truth already clear. The argument commanded in 16:125 is its opposite, and when a discussion turns into the first kind, the Sunnah is to leave it.")),
            .longOnly(.markdown("**Should every Muslim debate people of other faiths?**")),
            .longOnly(.text("Every Muslim can pass on what he knows; the Prophet said, convey from me, even a single ayah (Saheeh al-Bukhaari 3461). Debate is a different task. It needs knowledge of Islam and of the other position, and the Quran forbids speaking about Allah without knowledge (7:33). A Muslim who meets an argument he cannot answer should do what al-Mugheerah (may Allah be pleased with him) did: take it to those who know, and come back with the answer.")),
            .longOnly(.hadith("bukhari:3461", cite: "Saheeh al-Bukhaari 3461", arabic: 29...46, english: [4...55])),
            .longOnly(.markdown("**Is the mubaahalah still done today?**")),
            .longOnly(.text("Ibn al-Qayyim, drawing lessons from the delegation of Najraan in Zad al-Ma‘aad, wrote that when the proof of Allah has been established against the people of falsehood and they persist in stubbornness, it is part of the Sunnah to call them to the mubaahalah, since Allah commanded His Messenger to do it and did not say it was for him alone. So it is the end of a debate in which the proof is already clear, undertaken by someone with knowledge and sincerity, never an opening move or a show.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran argues. It quotes its opponents fairly, asks every claimant for proof and holds itself to the same rule, reasons from creation, and meets the People of the Book on shared ground before inviting them further. Ibraaheem began from his people’s premise and let it fall; the Prophet’s letter to Heraclius and his meeting with Najraan held courtesy, clarity and freedom together. Justice, no insult and no compulsion are not tactics in this method but commands."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Jadal", arabic: "جَدَل", meaning: "From the root **ج-د-ل**, to twist a rope tight: **argument** or debate. Praised when it is in the way that is best (16:125, 29:46) and blamed when it is wrangling against a truth already clear (43:58)."),
            .ayah("43:58"),
            .term("Hikmah", arabic: "حِكمَة", meaning: "**Wisdom**: the truth put in its right place, in the right measure, for the right listener. The first of the three tools of dawah named in 16:125."),
            .term("Hujjah", arabic: "حُجَّة", meaning: "A **proof** that settles an argument. The Quran calls Ibraaheem’s reasoning the argument Allah gave him against his people (6:83), and says the messengers were sent so that mankind would have no argument against Allah (4:165)."),
            .ayah("4:165"),
            .term("Munaazarah", arabic: "مُنَاظَرَة", meaning: "A **formal debate** in which each side examines the other’s case. Ibn Katheer describes Ibraaheem’s words about the star, the moon and the sun as munaazarah with his people, not doubt of his own."),
            .term("Mubaahalah", arabic: "مُبَاهَلَة", meaning: "From **بَهلَة**, a curse: the mutual invocation of Allah’s curse on whichever side is lying, offered to the Christians of Najraan in 3:61 after the proof had been set out. They declined it and made a treaty instead (Saheeh al-Bukhaari 4380)."),
        ]),
    ]
}

struct ReligionsOneView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsOneView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("One Religion From Aadam to Muhammad")
        .englishArticle().selectableArticleList(article: "ReligionsOneView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran teaches that there has only ever been one true religion, submission to Allah alone, and that every prophet from Aadam to Muhammad (peace and blessings be upon him) taught it. Mankind began on tawheed; worship of others came later, through exaggeration about righteous people. What changed from prophet to prophet was the law, never the creed, and each prophet was bound to believe in the one who would come after him. That is why the last message is for everyone, and why its followers carry the oldest name of all: Muslims."),
        ]),
        ArticleSection("WHAT THE WORD MEANS", [
            .markdown("**Islam (إِسلَام)** comes from **aslama**, to hand oneself over wholly. It shares a root with salaam, peace, and salamah, safety. In the Quran it is not the name of a nation or the title of a founder. It is an act: the surrender of the whole person to Allah alone. Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) gave its definition in the short creed he wrote for beginners:"),
            .quote(text: "“Islam is submitting to Allah through tawheed, yielding to Him in obedience, and disowning shirk and its people.” (Muhammad ibn Abd al-Wahhaab, Thalaathat al-Usool).", arabic: "الإِسلَامُ: هُوَ الِاستِسلَامُ لِلَّهِ بِالتَّوحِيدِ، وَالِانقِيَادُ لَهُ بِالطَّاعَةِ، وَالبَرَاءَةُ مِنَ الشِّركِ وَأَهلِهِ", dimmed: true),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) drew out what follows from this. Whoever submits to Allah and to something else beside Him is a mushrik, and whoever refuses to submit to Allah at all is too proud to worship Him; both have missed Islam. That is why the word can name the religion of every prophet. In its general sense, Islam is the religion of Nooh, Ibraaheem, Moosa and Eesa (peace be upon them) and all their faithful followers. In its particular sense, it is that same religion in the final form brought by Muhammad, and since he was sent it has no other form.")),
            .shortOnly(.text("In its general sense, then, Islam is the religion of every prophet and all his faithful followers. In its particular sense, it is that same religion in the final form brought by Muhammad, and since he was sent it has no other form.")),
            .longOnly(.text("The Quran even describes the whole creation as submitting to Allah, willingly or unwillingly:")),
            .longOnly(.ayah("3:83")),
            .longOnly(.text("The stars, the seas and the cells of the body obey their Creator without choosing to. Human beings were given the choice, and the one who chooses to submit joins, freely, the obedience of everything around him. In that light the two great statements of the religion read naturally: the religion with Allah is Islam (3:19), and whoever seeks a religion other than Islam will not have it accepted from him (3:85). They do not claim that truth began in seventh-century Arabia. They say that submission to Allah alone is the only religion He has ever accepted.")),
            .shortOnly(.text("Submission to Allah alone is the only religion He has ever accepted, and the Quran says so plainly:")),
            .ayah("3:19", words: 0...4),
            .ayah("3:85"),
        ]),
        ArticleSection("THE FIRST RELIGION WAS TAWHEED", [
            .text("A common account of religion, developed by nineteenth-century writers such as Edward Tylor in Primitive Culture (1871), holds that it evolved: from spirits in trees and rivers, to many gods, and only late, among a few peoples, to one God. The Quran tells the history the other way round:"),
            .longOnly(.ayah("2:213", words: 0...8)),
            .ayah("10:19"),
            .longOnly(.text("Ibn Abbaas (may Allah be pleased with him) explained, in a report that Ibn Katheer cites under 2:213 and that al-Haakim graded saheeh, that ten generations passed between Aadam and Nooh, all upon the law of truth, and then they differed, and Allah sent the prophets. Mankind began as one community on tawheed. Shirk was a fall from it, not the starting point.")),
            .longOnly(.text("The Sunnah describes the same fall from Allah’s side. In a long sermon the Prophet reported his Lord as saying:")),
            .longOnly(.hadith("muslim:2865", cite: "Saheeh Muslim 2865", arabic: 70...94, english: [38...92])),
            .longOnly(.markdown("**Hunafaa’ (حُنَفَاء)** means people inclining to Allah alone and away from everything else. That is the state in which every person is created; the worship of others is something that comes to people afterward, from outside. Ibn Abbaas also described how it first came. The names of the idols of Nooh’s people, Wadd, Suwaa‘, Yaghooth, Ya‘ooq and Nasr, were the names of righteous men:")),
            .shortOnly(.text("Ibn Abbaas (may Allah be pleased with him) described how the worship of others first came. The names of the idols of Nooh’s people, Wadd, Suwaa‘, Yaghooth, Ya‘ooq and Nasr, were the names of righteous men:")),
            .hadith("bukhari:4920", cite: "Saheeh al-Bukhaari 4920", arabic: 60...91, english: [76...152]),
            .text("No one set out to worship stone. Grief for good men turned into statues to remember them, and once the knowledge of why they had been raised was forgotten, remembrance turned into worship. That pattern, exaggeration about the righteous until they are treated as divine, recurs through history, and every later prophet came to undo some form of it."),
            .longOnly(.text("The evolutionary account itself did not go unchallenged. Early in the twentieth century the anthropologist Wilhelm Schmidt gathered reports that many of the most ancient peoples known believed in a single supreme sky god above all lesser spirits. His theory of an original monotheism is still debated, but it showed that the neat ladder from spirits to gods to God was an assumption and not a discovery.")),
            .door(.article("StoryNuhView")),
        ]),
        ArticleSection("THE SAME CONFESSION IN EVERY AGE", [
            .text("The Quran puts the word “Muslim” in the mouths of believers across the whole of sacred history, long before the seventh century. Its most moving scene is a deathbed. Ya‘qoob (peace be upon him), surrounded by his sons, asks what they will worship after him:"),
            .ayah("2:132-133"),
            .longOnly(.text("The same confession appears wherever the Quran shows faith tested. Pharaoh’s magicians, threatened with crucifixion for believing in Moosa’s Lord, prayed to die as Muslims (7:126). When the cities of Loot (peace be upon him) were destroyed, only one house of Muslims was found in them (51:36). The Queen of Saba, after seeing Sulaymaan’s palace, said: I submit with Sulaymaan to Allah, Lord of the worlds (27:44). The disciples of Eesa answered the call to believe in Allah and His messenger with: bear witness that we are Muslims (5:111). And the Quran describes the prophets of Bani Israa’eel who judged by the Torah as those who submitted, alladheena aslamu (5:44).")),
            .shortOnly(.text("The same confession appears wherever the Quran shows faith tested, from Pharaoh’s magicians to the Queen of Saba. The disciples of Eesa answered the call to believe in Allah and His messenger with: bear witness that we are Muslims.")),
            .longOnly(.ayah("7:126")),
            .longOnly(.ayah("51:36")),
            .longOnly(.ayah("27:44", words: 17...27)),
            .ayah("5:111"),
            .longOnly(.ayah("5:44", words: 6...12)),
            .longOnly(.text("The content of that religion was the same, and the Quran gives it in a single ayah about the People of the Book:")),
            .longOnly(.ayah("98:5")),
            .longOnly(.text("Sincere worship of Allah alone, prayer and zakaah: the ayah calls this the correct religion, and it was commanded before the Quran. Ismaa‘eel (peace be upon him) enjoined prayer and zakaah on his family (19:55). Ibraaheem, Loot, Ishaaq and Ya‘qoob were inspired to establish prayer and give zakaah (21:73). Fasting was prescribed for those before the Muslims, as it is for them (2:183). Ibraaheem was commanded to proclaim the Hajj to mankind (22:27). The pillars a Muslim keeps today are older than Makkah’s idols.")),
            .longOnly(.ayah("19:55")),
            .longOnly(.ayah("21:73")),
            .longOnly(.ayah("2:183")),
            .longOnly(.ayah("22:27")),
        ]),
        ArticleSection("BROTHERS OF ONE FATHER", [
            .text("If the religion is one, why do the laws of Moosa and of Muhammad (peace be upon them) differ? The Prophet answered with an image from family life:"),
            .hadith("muslim:2365c", cite: "Saheeh Muslim 2365", arabic: 55...65, english: [32...56]),
            .longOnly(.markdown("The Arabic is **awlaad ‘allaat**: sons of one father by different mothers. The scholars of hadith explain the image: the father is the religion’s foundation, which is one, tawheed and the belief in the unseen it carries; the mothers are the laws, which differ. The Quran says the same in plain words, that to each community it gave a law and a way (5:48), and that it appointed rites for every nation (22:67).")),
            .shortOnly(.markdown("The Arabic is **awlaad ‘allaat**: sons of one father by different mothers. The father is the religion’s foundation, which is one: tawheed and the belief in the unseen it carries. The mothers are the laws, which differ from prophet to prophet.")),
            .longOnly(.ayah("5:48", words: 24...28)),
            .longOnly(.ayah("22:67")),
            .longOnly(.text("The Quran itself shows laws changing between prophets. The Sabbath was laid on those who differed over it (16:124). Certain good foods were forbidden to Bani Israa’eel because of their wrongdoing (4:160); Eesa (peace be upon him) came to make some of them lawful again (3:50), and Muhammad was sent to lift the remaining burdens and shackles (7:157). The parents and brothers of Yoosuf (peace be upon him) bowed down before him in greeting (12:100), and Ibn Katheer explains under that ayah that such a greeting was lawful in their law and was forbidden in this one.")),
            .longOnly(.ayah("16:124")),
            .longOnly(.ayah("4:160")),
            .longOnly(.ayah("3:50")),
            .longOnly(.ayah("7:157", words: 23...29)),
            .longOnly(.ayah("12:100", words: 0...6)),
            .longOnly(.text("The Prophet named some of what is new in his own law:")),
            .longOnly(.hadith("bukhari:335", cite: "Saheeh al-Bukhaari 335", arabic: 43...83, english: [4...128])),
            .callout("What never changes: who Allah is, that He alone is worshipped, the angels, the books, the messengers, the Last Day, the decree, and the core of morality. What changes: the form of prayers and rites, what is lawful to eat, the details of punishments and of daily life. Disagreement in the second never licenses disagreement in the first.", title: "One Religion, Many Laws", icon: "square.stack.3d.up.fill"),
        ]),
        ArticleSection("THE COVENANT OF THE PROPHETS", [
            .text("The line of prophets was not a row of independent teachers, each starting afresh. Each was bound to the one who would come after him:"),
            .ayah("3:81"),
            .text("Every prophet pledged that if the final messenger came in his lifetime he would believe in him and support him. Following Muhammad is therefore not leaving Moosa or Eesa (peace be upon them). It is doing what Moosa and Eesa themselves pledged to do. That is why a Jew or a Christian who believed in his own prophet and then believes in Muhammad receives a double reward:"),
            .hadith("bukhari:97", cite: "Saheeh al-Bukhaari 97", arabic: 33...43, english: [4...10, 12...40]),
            .longOnly(.text("The clearest demonstration is still to come. Eesa (peace be upon him), who was raised alive and will return, will not return with a separate law. When he descends, the Muslims’ leader will invite him to lead the prayer, and he will decline:")),
            .longOnly(.hadith("muslim:156", cite: "Saheeh Muslim 156", arabic: 57...83, english: [30...73])),
            .longOnly(.text("A prophet of Bani Israa’eel praying behind a man of this ummah is the covenant of 3:81 fulfilled in person. The earlier prophets were each sent to their own people (Saheeh al-Bukhaari 335, above); the last was told to say to everyone: O mankind, I am the Messenger of Allah to you all (7:158).")),
            .longOnly(.ayah("7:158", words: 0...7)),
            .shortOnly(.text("The earlier prophets were each sent to their own people; the last was sent to all mankind.")),
            .door(.article("ProvingContinuationView")),
        ]),
        ArticleSection("WHO OWNS IBRAAHEEM?", [
            .text("Jews, Christians and Muslims all trace their faith to Ibraaheem (peace be upon him), and the Quran settles the question with a point of plain history:"),
            .ayah("3:65-66"),
            .longOnly(.text("Judaism, as a name and a body of law, takes its shape from the Torah given to Moosa and from the tribe of Judah; Christianity takes its name from the title of Eesa and its creeds from councils held centuries after him. Ibraaheem lived before all of it. Whatever his religion was, it could not have been a religion defined by books revealed after his death. The Quran gives the answer: he was a hanif, a Muslim, and those with most right to him are those who follow him (3:67-68).")),
            .shortOnly(.text("Judaism takes its shape from the Torah given to Moosa, and Christianity takes its creeds from councils held centuries after Eesa. Ibraaheem lived before all of it, so his religion could not have been one defined by books revealed after his death. The Quran gives the answer:")),
            .ayah("3:67-68"),
            .longOnly(.text("When the People of the Book said, be Jews or Christians and you will be guided, the Quran gave the Muslims their reply, and it is not a rival label:")),
            .longOnly(.ayah("2:135-136")),
            .longOnly(.text("The reply is to believe in every prophet without distinction. A Muslim is the only person who can say that sentence without excluding a single messenger Allah sent.")),
        ]),
        ArticleSection("THE NAME MUSLIM", [
            .longOnly(.text("Most religions are named after a person, a people or a place. Judaism is named after the tribe and kingdom of Judah. Christianity is named after Christ, the Greek title of Eesa, and the book of Acts records that the disciples were first called Christians at Antioch (Acts 11:26), after his time. Buddhism is named after the Buddha, Zoroastrianism after Zoroaster, and Hinduism after the river Indus, a name given to it by outsiders. The Quran names its followers after an act, and it says the name was given by Allah:")),
            .shortOnly(.text("Most religions are named after a person, a people or a place: Judaism after the tribe of Judah, Christianity after Christ, the Greek title of Eesa, Buddhism after the Buddha. The Quran names its followers after an act, and it says the name was given by Allah:")),
            .ayah("22:78", words: 14...23),
            .longOnly(.text("Ibn Katheer explains that the One who named them is Allah, as Ibn Abbaas (may Allah be pleased with him), Mujaahid and others said, since the ayah says the name was given both in the earlier scriptures and in this one, the Quran, which Ibraaheem could not have done. The name belongs to no race and no founder. Anyone of any people who submits to Allah alone takes it, which is why Muslims have always refused the old European name “Mohammedans”: it suggests that they worship the man they follow, which is the one thing he forbade.")),
            .text("So when a person becomes Muslim today, he does not convert in the sense of leaving one tradition for another. He returns to the religion of Aadam, Nooh, Ibraaheem, Moosa and Eesa, in the form its last messenger brought, and to the fitrah he was born with."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Were the followers of Moosa and Eesa Muslims?**")),
            .longOnly(.text("Those who followed their prophet faithfully in his time were Muslims in the general sense: they submitted to Allah alone by the law He had given them, and the Quran calls them so (5:44, 5:111). After Muhammad was sent, submission to Allah takes the form He has now commanded, which is following the final messenger, as every earlier prophet pledged to do (3:81).")),
            .longOnly(.markdown("**If the religion is one, why may I not keep the law of Moosa?**")),
            .longOnly(.text("Because the One who gave that law is the One who replaced it, and He sent the last messenger to all people. Keeping a superseded law in preference to the current one is not loyalty to Moosa; it is disobedience to Moosa’s Lord, who took Moosa’s own pledge to follow Muhammad.")),
            .longOnly(.markdown("**How many prophets were there?**")),
            .longOnly(.text("The Quran names twenty-five and says there were others whose stories it did not tell (4:164, 40:78). Figures such as one hundred and twenty-four thousand prophets and three hundred and some messengers are widely quoted; they come from narrations whose authenticity the scholars of hadith have disputed, so they are best mentioned with that caution. What is certain is that no community was left without a warner (35:24).")),
            .longOnly(.ayah("4:164")),
            .longOnly(.ayah("40:78", words: 0...13)),
            .longOnly(.ayah("35:24", words: 5...11)),
            .markdown("**Does “one religion” mean that all religions today are one?**"),
            .text("No. It means the opposite: there is one true religion, and the others are departures from it at different distances. The prophets were united; their later followers divided after knowledge had come to them, out of rivalry among themselves (3:19). The next chapter takes up the modern claim that every religion is equally a path to God."),
            .door(.article("ReligionsPluralismView")),
        ]),
        ArticleSection("IN SUMMARY", only: .long, [
            .text("Islam is not the youngest of the world’s religions but the oldest: the submission to Allah alone that Aadam’s children kept for ten generations, that Ibraaheem taught his sons and Ya‘qoob asked of his on his deathbed, and that magicians, a queen and the disciples of Eesa confessed. Shirk came later, through reverence for good men turned into worship. The prophets were brothers with one father and different mothers, one creed under different laws, each pledged to the one after him, and the last of them, Muhammad, was sent to all. Eesa himself will pray behind a man of Muhammad’s ummah. The name of the religion is an act anyone can perform, and Allah gave it."),
        ]),
        ArticleSection("IN SUMMARY", only: .short, [
            .text("Islam is not the youngest of the world’s religions but the oldest: the submission to Allah alone that mankind began on, that Ibraaheem taught and Ya‘qoob asked of his sons on his deathbed. Shirk came later, through reverence for good men turned into worship. The prophets were brothers with one father and different mothers, one creed under different laws, each pledged to the one after him, and the last of them, Muhammad, was sent to all. The name of the religion is an act anyone can perform, and Allah gave it."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Islam", arabic: "إِسلَام", meaning: "From **aslama**, to hand oneself over wholly: **submission to Allah alone**. In its general sense the religion of every prophet; in its particular sense that religion in the final form brought by Muhammad (peace be upon him)."),
            .term("Shir‘ah and Minhaaj", arabic: "شِرعَة وَمِنهَاج", meaning: "The **law and the way** given to each community (5:48). They differed between prophets; the deen, the creed and worship of Allah alone, did not."),
            .term("Awlaad Allaat", arabic: "أَولَادُ عَلَّاتٍ", meaning: "**Sons of one father by different mothers**: the Prophet’s image for the prophets, one in religion and different in law (Saheeh Muslim 2365)."),
            .term("Hunafaa’", arabic: "حُنَفَاء", meaning: "Plural of hanif: people **inclining to Allah alone** and away from all else. Allah created His servants hunafaa’, and the devils led them away (Saheeh Muslim 2865)."),
            .term("Meethaaq an-Nabiyyeen", arabic: "مِيثَاقُ النَّبِيِّين", meaning: "The **covenant of the prophets** (3:81): each pledged to believe in and support the messenger who would come after him confirming what he had."),
        ]),
    ]
}

struct ReligionsPluralismView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsPluralismView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Are All Religions the Same?")
        .englishArticle().selectableArticleList(article: "ReligionsPluralismView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: religious pluralism holds that the great religions are equally valid paths to the same ultimate reality. It is usually held for good reasons, humility, peace and respect for good people of every faith, but it cannot be true, because the religions make claims that contradict each other, and pluralism can only reconcile them by telling each that it is wrong about itself. The Quran teaches that there is one straight path; it explains 2:62 and 5:69 by their context; it leaves those whom the message never reached to a test on the Day of Resurrection; and it commands kindness and justice to peaceful people of every faith, without merging the faiths into one."),
        ]),
        ArticleSection("THE CASE FOR PLURALISM", [
            .text("Pluralism deserves to be stated at its best before it is answered. In its popular form it is an image: many paths climbing one mountain, all meeting at the summit. Or an older parable, told in India for centuries, of blind men who each touch one part of an elephant, the trunk, the leg, the ear, and each insists that the whole animal is like the part he holds. Every religion, on this view, has grasped a real piece of the divine and mistaken it for the whole."),
            .longOnly(.text("Its most careful defender was the philosopher John Hick (1922–2012). In God and the Universe of Faiths (1973) he called for a “Copernican revolution” in theology: instead of placing one’s own religion at the centre with the others circling it, place God, or as he later preferred to say, the Real, at the centre, with every religion circling it. In An Interpretation of Religion (1989) he argued that the Real in itself is beyond all human concepts, and that Allah, the Trinity, Brahman and the Buddhist emptiness are different human responses to it, each shaped by its culture. His test of a religion’s validity was whether it turns people from self-centredness toward the Real, and he judged that the great religions do so about equally well.")),
            .shortOnly(.text("Its most careful defender, the philosopher John Hick (1922–2012), argued that the Real in itself is beyond all human concepts, and that Allah, the Trinity, Brahman and the Buddhist emptiness are different human responses to it, each shaped by its culture.")),
            .longOnly(.text("A related school, often called perennialism or traditionalism, says something subtler. René Guénon, Frithjof Schuon (whose book The Transcendent Unity of Religions appeared in 1948) and others held that the religions differ in their outward forms, laws and doctrines, but meet in a hidden inner core that only the spiritual elite perceive. Many Muslims first meet this view in Sufi dress.")),
            .longOnly(.text("The motives behind these views are often admirable: a horror of religious wars, a recognition that some neighbours of other faiths are more honest and generous than some Muslims, a sense that God’s mercy must be wider than any group’s boundaries, and modesty about one’s own understanding. A Muslim answer has to take those motives seriously and show where Islam itself honours them.")),
        ]),
        ArticleSection("WHAT THE RELIGIONS ACTUALLY SAY", [
            .text("Pluralism’s first difficulty is the religions themselves. They do not merely use different words for one thing; they make claims that cannot all be true."),
            .bullet("**About God.** Islam and Judaism say God is one, without partner or son; Christianity says He is one God in three persons; many Hindu traditions accept many gods as forms of the divine; classical Theravada Buddhism does not rest on a creator at all."),
            .bullet("**About Eesa (peace be upon him).** Christianity says he is God the Son, who died on the cross for the sins of the world and rose again. Judaism says he was not the Messiah. Islam says he was the Messiah and a mighty messenger, neither God nor crucified, and that he was raised alive."),
            .bullet("**About the Prophet Muhammad (peace and blessings be upon him).** Islam says he is the final prophet; the other great religions do not accept him as a prophet at all, and newer movements that honour him deny that he was the last."),
            .longOnly(.bullet("**About death.** Islam, Judaism and Christianity teach one life followed by resurrection and judgment; Hinduism and Buddhism teach rebirth through many lives.")),
            .longOnly(.text("Eesa either died on the cross or he did not. He cannot have done both, and no shift of perspective will make both true. The Quran points out that the religions themselves do not accept pluralism:")),
            .shortOnly(.text("Eesa either died on the cross or he did not. He cannot have done both, and no shift of perspective will make both true.")),
            .longOnly(.ayah("2:113")),
            .text("Each tradition, read in its own words, says that something the others hold is false. Pluralism therefore does not stand among the religions as a neutral friend. It is a new position about them, and it disagrees with every one of them about what they mean."),
        ]),
        ArticleSection("THE TROUBLE WITH THE ELEPHANT", [
            .text("Look again at the parable. The blind men are each partly wrong; only the narrator, who sees the whole elephant, knows it. The pluralist casts himself as that narrator. He claims to know that the Real lies behind all the religions, while also saying that the Real is beyond all human knowledge. Both cannot be true. If nothing can be known of it, he cannot know that every religion touches it; if he knows that much, he claims a revelation greater than all the prophets."),
            .longOnly(.text("A god who is neither personal nor impersonal, neither one nor many, who neither speaks nor commands, cannot be prayed to, loved, obeyed or feared. Hick’s Real is not the God of any believer. To embrace it, the Muslim must treat Surat al-Ikhlaas as a cultural myth, the Christian must treat the incarnation the same way, and the Buddhist must accept a Real his tradition never asked for. Pluralism honours every religion by telling each that its central teaching is not literally true.")),
            .shortOnly(.text("To embrace the pluralist’s Real, the Muslim must treat Surat al-Ikhlaas as a cultural myth and the Christian must treat the incarnation the same way. Pluralism honours every religion by telling each that its central teaching is not literally true.")),
            .longOnly(.text("It is also an exclusive claim. It says that those who believe their own religion is true, which is most believers in history, are mistaken. Its humility is a claim to see further than everyone else. And its moral test, a turn from self to the Real, is itself a standard drawn from one particular modern view of what religion is for.")),
            .longOnly(.text("Perennialism has the same problem in a quieter form. To find one hidden core beneath Islam and the Trinity, it must set aside the plain meaning of the Quran, which rejects the Trinity by name (4:171, 5:73). Ideas of this kind appeared in Muslim history among those who held that all existence is one, and some of them said that every religion, idol worship included, worships God in its own way. Ibn Taymiyyah (may Allah have mercy on him) answered them at length, and the scholars of Ahl as-Sunnah have rejected the claim ever since.")),
            .longOnly(.ayah("4:171", words: 28...30)),
        ]),
        ArticleSection("ONE STRAIGHT PATH", [
            .text("The Quran’s own image is not a mountain with many paths but a single path with many turnings off it:"),
            .ayah("6:153"),
            .longOnly(.text("Abdullah ibn Mas‘ood (may Allah be pleased with him) described how the Prophet (peace be upon him) drew that ayah as lines:")),
            .longOnly(.hadith("mishkat_almasabih:166", cite: "Mishkaat al-Masaabeeh 166, from Ahmad, an-Nasaa’i and ad-Daarimi; its chain graded hasan by Zubayr Ali Zai", arabic: 6...36, english: [0...47])),
            .longOnly(.text("The other paths are real paths. People walk them sincerely, and some of them contain much that is true. But they lead away from the destination, and each has someone at its head calling people on. The Quran states the conclusion without softening it:")),
            .shortOnly(.text("The other paths are real paths. People walk them sincerely, and some of them contain much that is true, but they lead away from the destination. The Quran states the conclusion without softening it:")),
            .ayah("3:85"),
            .longOnly(.text("And it rules out the most common middle position, believing in some of Allah’s messengers and not others, by calling those who hold it disbelievers in truth:")),
            .longOnly(.ayah("4:150-152")),
            .text("The Prophet made the same point about the People of the Book in particular:"),
            .hadith("muslim:153", cite: "Saheeh Muslim 153", arabic: 29...54, english: [0...52]),
            .text("Three words in that hadith carry great weight: “hears about me”. The ruling falls on someone who has heard of the Prophet and his message and then rejected it. That condition is the subject of a later section."),
        ]),
        ArticleSection("HOW 2:62 AND 5:69 ARE READ", [
            .text("Pluralists, including some Muslims, point to two aayaat that seem to promise salvation to Jews, Christians and Sabians as well as Muslims:"),
            .ayah("2:62"),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) explains it by the history of revelation. The faith of the Jews was holding to the Torah and the way of Moosa (peace be upon him), until Eesa came; after that, whoever held to the Torah and refused Eesa was lost. The faith of the Christians was holding to the Injeel and the law of Eesa, until Muhammad came; after that, whoever refused Muhammad was lost. The ayah praises those of each community who believed and followed the messenger of their own time. He also cites the report from Ibn Abbaas (may Allah be pleased with him) that Allah sent down after it the ayah that no religion but Islam will be accepted (3:85), and explains it as meaning that since Muhammad was sent no path is accepted except his.")),
            .shortOnly(.text("Ibn Katheer (may Allah have mercy on him) explains it by the history of revelation. The faith of the Jews was holding to the Torah until Eesa came, and the faith of the Christians was holding to the Injeel until Muhammad came; after that, whoever refused the messenger of his own time was lost. The ayah praises those of each community who believed and followed the messenger of their own time.")),
            .longOnly(.text("The wording of the ayah supports this. It promises reward to those who believed in Allah and the Last Day and did righteous deeds. Belief in Allah, in the Quran’s own terms, includes belief in all His messengers and all His books (4:136), and rejecting one messenger is called disbelief in truth (4:150-151). A reading in which belief in Allah leaves out belief in His final messenger has to cut the ayah off from the rest of the Book.")),
            .longOnly(.ayah("4:136")),
            .text("The second ayah, 5:69, makes the point even more sharply, because of what surrounds it. Just before it, the Prophet is told to say:"),
            .ayah("5:68-69", words: 0...14),
            .shortOnly(.text("And just after it the Trinity is named as disbelief. A passage that tells the People of the Book they stand on nothing until they uphold what has now been revealed, and then names the Trinity as disbelief, cannot be read as declaring every religion valid. The ayah in the middle describes the reward of those, from any community, who truly believed.")),
            .longOnly(.text("And just after it come the words: they have certainly disbelieved who say that Allah is the Messiah, son of Maryam, and they have certainly disbelieved who say that Allah is the third of three (5:72-73). A passage that tells the People of the Book they stand on nothing until they uphold what has now been revealed, and then names the Trinity as disbelief, cannot be read as declaring every religion valid. The ayah in the middle describes the reward of those, from any community, who truly believed.")),
            .longOnly(.ayah("5:72-73")),
            .longOnly(.text("And 2:62 itself sits inside a long address to Bani Israa’eel that opens with a command: believe in what I have sent down, confirming what is with you, and do not be the first to disbelieve in it (2:41). The invitation to believe in the Quran is part of the very context of the ayah.")),
            .longOnly(.ayah("2:41")),
        ]),
        ArticleSection("THOSE THE MESSAGE NEVER REACHED", [
            .text("If salvation depends on believing in the final messenger, what of people who never heard of him, or heard only a distorted picture? Here Islam is more merciful than its critics expect, and more careful than many Muslims are. Allah says:"),
            .ayah("17:15", words: 15...20),
            .longOnly(.ayah("4:165")),
            .longOnly(.text("Allah does not punish anyone before the proof has reached him. Ibn Katheer gathers under 17:15 the narrations about those who died without a messenger reaching them, the deaf who heard nothing, the insane, the very old who understood nothing, and those who lived in the gaps between prophets, and he reports from the scholars that such people will be tested on the Day of Resurrection: whoever obeys then enters Paradise, and whoever disobeys enters the Fire. Ibn Taymiyyah and Ibn al-Qayyim (may Allah have mercy on them) held the same view, and Ibn al-Qayyim, in Taariq al-Hijratayn, distinguished two questions that are often confused.")),
            .shortOnly(.text("Allah does not punish anyone before the proof has reached him. Ibn Katheer reports from the scholars that those who died without a messenger reaching them will be tested on the Day of Resurrection: whoever obeys then enters Paradise, and whoever disobeys enters the Fire.")),
            .longOnly(.bullet("**The ruling in this world.** Anyone who has not entered Islam is treated as a non-Muslim in the laws of this life, in marriage, inheritance and funeral prayers, because rulings follow what is outwardly known.")),
            .longOnly(.bullet("**The ruling in the Hereafter.** Punishment depends on the proof having truly reached the person: hearing the message in a form that could be understood, with the ability to understand it. Who that applies to, among the billions of people who have lived, is known to Allah alone. Ibn al-Qayyim also warned that one who hears of the message and turns away from learning it, when he could have learned, is not excused by an ignorance he chose.")),
            .longOnly(.text("The Prophet was asked about the children of the polytheists who died young, and he answered that Allah knows best what they would have done (Saheeh al-Bukhaari 1384). The Muslim is not appointed to divide individual people into Paradise and the Fire. He knows the rule Allah revealed, he states it truthfully, and he leaves each soul to its Lord, who wrongs no one. What he can do is make sure that the message reaches as many people as possible, clearly and undistorted, so that their hearing of it is a real hearing.")),
            .longOnly(.hadith("bukhari:1384", cite: "Saheeh al-Bukhaari 1384, Saheeh Muslim 2659", arabic: 23...39, english: [0...23])),
            .shortOnly(.text("The Muslim is not appointed to divide individual people into Paradise and the Fire. He knows the rule Allah revealed, states it truthfully, and leaves each soul to its Lord, who wrongs no one, while making sure the message reaches as many people as possible, clearly and undistorted.")),
        ]),
        ArticleSection("KINDNESS WITHOUT MERGING", [
            .text("Rejecting pluralism is not rejecting people. The Quran commands justice and kindness toward everyone who does not fight the Muslims over their religion:"),
            .ayah("60:8-9"),
            .longOnly(.text("The Prophet applied it inside his own Companions’ families. Asmaa’ bint Abi Bakr (may Allah be pleased with her) asked him about her mother, who had come to visit her while still a polytheist:")),
            .longOnly(.hadith("bukhari:2620", cite: "Saheeh al-Bukhaari 2620", arabic: 22...55, english: [0...56])),
            .longOnly(.text("Kindness and honesty went together. When a Jewish boy who used to serve the Prophet fell ill, the Prophet visited him, sat at his head and invited him to Islam, and when the boy accepted with his father’s encouragement, the Prophet left praising Allah for saving him from the Fire (Saheeh al-Bukhaari 1356). He did not treat silence about the truth as the kind thing to do. When an-Najaashi, the Christian king of Abyssinia who had sheltered the Muslims and then believed, died, the Prophet told his Companions that a righteous man had died and prayed over him (Saheeh al-Bukhaari 3877).")),
            .longOnly(.hadith("bukhari:1356", cite: "Saheeh al-Bukhaari 1356", arabic: 21...75, english: [0...71])),
            .longOnly(.hadith("bukhari:3877", cite: "Saheeh al-Bukhaari 3877, Saheeh Muslim 952", arabic: 19...37, english: [0...24])),
            .longOnly(.text("Muslims may also cooperate with others in what is good and just. The Prophet said of the alliances made before Islam for righteous ends:")),
            .longOnly(.hadith("muslim:2530", cite: "Saheeh Muslim 2530", arabic: 35...48, english: [0...21])),
            .text("What the Muslim may not do is say that the religions are one. The Quran gave a whole surah to that line, and the Prophet told a Companion to recite it before sleeping:"),
            .ayah("109:1-6", words: 22...25),
            .hadith("abudawud:5055", cite: "Sunan Abi Daawood 5055; graded saheeh by al-Albaani", arabic: 22...36, english: [0...23]),
            .text("The closing ayah of that surah is often cited as if it meant that all religions are equally fine. The surah is, in the Prophet’s words, a declaration of freedom from shirk. It separates the two forms of worship completely, without compulsion and without pretending they are the same."),
        ]),
        ArticleSection("THE CALL TO UNITE THE RELIGIONS", only: .long, [
            .text("In recent decades there have been calls, under the banner of shared Abrahamic roots or universal brotherhood, to bring the religions together into one: joint prayers, a single book binding the Quran with the Torah and the Gospels, a mosque, a church and a synagogue in one compound as signs of one faith."),
            .text("The Permanent Committee for Scholarly Research and Ifta, in a fatwa signed by Shaykh Ibn Baaz (may Allah have mercy on him) and other senior scholars, answered these calls. Among what it said: Islam is the one true religion and abrogated all before it; the Torah and the Gospel in people’s hands have been altered; the call to unite the religions, or to treat them as equal, is a call to disbelief, and a Muslim may not believe in it or take part in it; the Quran may not be printed together with the Torah and the Gospel in one volume; and a Muslim may not answer the call to build a mosque, a church and a temple together in one compound. The same scholars were equally clear that calling Jews and Christians to Islam, and discussing with them in the best manner, remains lawful and commanded."),
            .text("The distinction matters. Peaceful coexistence, just dealings, neighbourliness, honest dialogue and cooperation against injustice are all within what Islam allows and often commands. Merging creeds is not. A Muslim can be the most courteous person in a room of many faiths and still say, when asked, that he believes only one of them is true. That is the honesty the Quran asks of him (3:64)."),
            .ayah("3:64"),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Isn’t it arrogant to say that only one religion is true?**"),
            .text("It would be arrogant to claim the truth as one’s own achievement. The Muslim claims no such thing. He says that Allah revealed the truth, that he is a servant who has been shown it, and that he does not know his own end. To say that a claim is true is not arrogance; every religion and every philosophy, pluralism included, does it. The real question is whether the claim is backed by evidence, and the rest of this library is about that question."),
            .longOnly(.markdown("**What about good people of other religions?**")),
            .longOnly(.text("Allah wrongs no one. A good deed by someone who does not believe is rewarded in this world:")),
            .longOnly(.hadith("muslim:2808", cite: "Saheeh Muslim 2808", arabic: 52...72, english: [31...74])),
            .longOnly(.text("Aa’ishah (may Allah be pleased with her) asked about Ibn Jud‘aan, a famous man of the Jaahiliyyah who kept the ties of kinship and fed the poor. The Prophet said it would not benefit him, because he never once said, my Lord, forgive me my sins on the Day of Judgment (Saheeh Muslim 214). Goodness to people matters greatly, but it is not a substitute for turning to the One who made them. And the judgment of each individual, including whether the message ever truly reached him, rests with Allah.")),
            .longOnly(.hadith("muslim:214", cite: "Saheeh Muslim 214", arabic: 19...49, english: [0...50])),
            .longOnly(.markdown("**Doesn’t the ban on compulsion in religion mean every religion is acceptable?**")),
            .longOnly(.text("It means faith may not be forced (2:256), and the same ayah goes on: the right course has become clear from the wrong. Freedom from compulsion is not the same as equal truth. The Quran says, whoever wills, let him believe, and whoever wills, let him disbelieve (18:29), and then describes what awaits the wrongdoers in the very next words. The choice is real, and so are its consequences.")),
            .longOnly(.ayah("2:256")),
            .longOnly(.ayah("18:29")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Pluralism begins in good instincts and ends by telling every believer that he misunderstands his own faith. The religions contradict each other on God, on Eesa, on Muhammad and on what follows death, and no vantage point above them can make both sides of a contradiction true. The Quran describes one straight path with many turnings off it, explains 2:62 and 5:69 as praise for those who followed the messenger of their own age, and leaves those whom the message never reached to a test before a just Lord. Meanwhile it commands justice, kindness and cooperation in good with peaceful people of every faith, and forbids only the one thing pluralism asks: saying that all the religions are the same."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("At-Ta‘addudiyyah ad-Deeniyyah", arabic: "التَّعَدُّدِيَّة الدِّينِيَّة", meaning: "**Religious pluralism**: the modern view that the great religions are equally valid responses to one ultimate reality, defended most fully by John Hick."),
            .term("Wahdat al-Adyaan", arabic: "وَحدَةُ الأَديَان", meaning: "**The unity of religions**: the call to treat all religions as one or to merge them. The Permanent Committee ruled it a call to disbelief, while affirming that inviting others to Islam and discussing in the best manner remain lawful."),
            .term("Ahl al-Fatrah", arabic: "أَهلُ الفَترَة", meaning: "**The people of the interval**: those who lived where or when no messenger’s message reached them. Allah does not punish before sending a messenger (17:15), and the scholars of the Sunnah hold that they will be tested on the Day of Resurrection."),
            .term("Iqaamat al-Hujjah", arabic: "إِقَامَةُ الحُجَّة", meaning: "**The establishing of the proof**: the message reaching a person in a form he could understand. Punishment in the Hereafter is tied to it (4:165)."),
            .term("Baraa’ah", arabic: "بَرَاءَة", meaning: "**Disavowal**: declaring oneself free of shirk and of worship directed to other than Allah. The Prophet called Surat al-Kaafiroon a baraa’ah from shirk (Sunan Abi Daawood 5055)."),
        ]),
    ]
}

struct ReligionsSecularismView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsSecularismView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Secular Humanism and Liberalism")
        .englishArticle().selectableArticleList(article: "ReligionsSecularismView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: secular humanism makes human reason and human welfare the final measure of right and wrong, and liberalism makes the individual sovereign over his own life and asks the state to stay neutral about what a good life is. Both defend real goods, and both rest on foundations they cannot supply for themselves: an “ought” that matter cannot produce, a reason that does not agree with itself, and a harm that no one can define without a view of what a human being is for. The Quran grounds human dignity, moral knowledge and justice in the Creator, returns the right to make law to Him, and defines freedom as servitude to Him alone, which frees a person from every lesser master."),
        ]),
        ArticleSection("WHAT THEY HOLD", [
            .text("Secular humanism is the view that human beings can live meaningful, ethical lives without God. Its modern statements, from the first Humanist Manifesto of 1933 to the Amsterdam Declaration of 2002, which the international humanist movement treats as its defining statement, repeat a few convictions: that reliable knowledge comes through reason, observation and science; that ethics should be grounded in human welfare and experience; that the worth, dignity and autonomy of the individual must be affirmed; and that humanity has no need of the supernatural, and must take responsibility for shaping its own life."),
            .longOnly(.text("Liberalism is a political philosophy, and many religious people hold it, but its modern form often travels with humanism. John Locke (1632–1704) argued for natural rights and religious toleration. John Stuart Mill (1806–1873), in On Liberty (1859), proposed that the only justification for using power over someone against his will is to prevent harm to others, and he put the individual’s sovereignty over himself in a famous line:")),
            .longOnly(.quote(text: "“Over himself, over his own body and mind, the individual is sovereign.” (John Stuart Mill, On Liberty, 1859, chapter 1).", dimmed: true)),
            .longOnly(.text("John Rawls (1921–2002) added that a just state should be neutral among the “comprehensive doctrines”, religious or philosophical, that its citizens hold, and should justify its laws only by public reasons that everyone could in principle accept.")),
            .shortOnly(.text("Liberalism, in the line of John Locke, John Stuart Mill and John Rawls, makes the individual sovereign over his own body and mind, allows power over him against his will only to prevent harm to others, and asks the state to stay neutral about what a good life is.")),
            .text("These ideas grew from real suffering. Europe’s wars of religion, which ended with the Peace of Westphalia in 1648, left millions dead, and the conclusion many drew was that no church should hold the sword. A Muslim answer must recognise what humanism and liberalism are trying to protect: people from tyranny, conscience from coercion, the weak from the strong. Islam protects all of these, and the question is not whether they matter but what grounds them."),
        ]),
        ArticleSection("WHERE DOES 'OUGHT' COME FROM?", [
            .longOnly(.text("The Scottish philosopher David Hume observed in his Treatise of Human Nature (1739–1740) that writers on morality slide, without noticing, from statements about what is the case to statements about what ought to be. No list of facts about atoms, brains and societies yields an “ought” on its own. Humanism inherits that gap and does not close it. It affirms that every human being has equal dignity and rights; but if a human being is only an arrangement of matter produced by unguided processes, dignity is not a property found anywhere in that matter. It is a value laid on top of it, and the humanist has no authority above his own preference to say that anyone must accept it.")),
            .longOnly(.text("Friedrich Nietzsche (1844–1900), no friend of religion, saw this more honestly than most of his successors: he warned that those who abandon belief in God have no right to keep the morality that grew from it, and he expected that morality to fall. The values humanists defend most passionately, the equal worth of the weak and the strong, mercy for the defeated, the sanctity of each life, were taught to mankind by the prophets long before any manifesto.")),
            .shortOnly(.text("David Hume observed that no list of facts about what is the case yields an “ought” on its own, and humanism inherits that gap. It affirms that every human being has equal dignity; but if a human being is only an arrangement of matter produced by unguided processes, dignity is a value laid on top of that matter, and the humanist has no authority above his own preference to say that anyone must accept it.")),
            .text("The Quran grounds human dignity in an act of Allah, not in a vote:"),
            .ayah("17:70", words: 1...4),
            .longOnly(.text("It grounds moral knowledge in the fitrah, the nature every person is created with, which recognises good and evil before it is taught (91:7-8; Saheeh al-Bukhaari 1385), and in guidance shown to every soul:")),
            .longOnly(.ayah("90:8-10")),
            .longOnly(.ayah("91:7-8")),
            .longOnly(.hadith("bukhari:1385", cite: "Saheeh al-Bukhaari 1385, Saheeh Muslim 2658", arabic: 31...49, english: [4...44])),
            .shortOnly(.text("It grounds moral knowledge in the fitrah, the nature every person is created with, which recognises good and evil before it is taught.")),
            .text("And it grounds obligation in accountability. A command with no Commander is advice; a law with no Judge is a hope. The Quran asks the question humanism cannot answer:"),
            .ayah("23:115"),
            .ayah("75:36"),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) reports two explanations of suda, being left neglected: that man will not be raised again, and, from Mujaahid, ash-Shaafi‘i and others, this one:")),
            .longOnly(.quote(text: "“Neither commanded nor forbidden.” (ash-Shaafi‘i, as reported by Ibn Katheer in his Tafseer of 75:36).", arabic: "لَا يُؤمَرُ وَلَا يُنهَى", dimmed: true)),
            .longOnly(.text("Ibn Katheer adds that the ayah covers both meanings: man is not left in this world without command and prohibition, nor left in his grave without being raised. A morality without a Commander is exactly the state the ayah describes, and the Quran calls it a mistaken assumption about what man is.")),
            .shortOnly(.text("Ibn Katheer reports from ash-Shaafi‘i and others that being left neglected means being neither commanded nor forbidden. A morality without a Commander is exactly the state the ayah describes.")),
            .door(.article("AtheismAnswerView")),
        ]),
        ArticleSection("WHOSE REASON? WHICH HARM?", [
            .longOnly(.text("Humanism and liberalism both appeal to reason as the common ground everyone can share. But reason is a tool, not a lawgiver: it draws conclusions from premises, and the premises are where people disagree. Secular philosophers who all reject revelation still divide sharply over abortion, euthanasia, the moral standing of animals, what is owed to future generations and what marriage is. The philosopher Alasdair MacIntyre made the point in the title of one of his books, Whose Justice? Which Rationality? (1988): there is no reason floating free of every tradition, and liberalism is itself a tradition with its own premises.")),
            .longOnly(.text("The harm principle has the same weakness. Everyone agrees that harm should be prevented; no one agrees on what harm is. Is pornography harmful to the one who watches it, to the women in it, to the marriages it breaks? Is gambling? Loneliness? A culture that teaches children their bodies are theirs to remake? Each answer requires a view of what a human being is and what he is for, which is precisely what the principle claimed to do without. Mill himself excluded children from his principle, and wrote in the same chapter that despotism is a legitimate way of governing barbarians, which shows how much his “neutral” principle depended on his own judgment of who counted.")),
            .shortOnly(.text("Humanism and liberalism both appeal to reason as common ground, but reason draws conclusions from premises, and the premises are where people disagree: secular philosophers who all reject revelation still divide sharply over abortion, euthanasia and what marriage is. The harm principle has the same weakness. Everyone agrees that harm should be prevented; no one agrees on what harm is, and each answer requires a view of what a human being is and what he is for.")),
            .longOnly(.text("The Quran weighs harm too, but it weighs all of it, including harm to the soul, to society and to a person’s Hereafter:")),
            .longOnly(.ayah("2:219", words: 1...14)),
            .longOnly(.ayah("5:90-91")),
            .longOnly(.text("Notice the harms named: enmity, hatred, and turning people away from the remembrance of Allah and from prayer. A secular calculation sees only the first two, if it sees them at all. And the Quran warns about the two standards that remain when revelation is set aside, human desire and majority opinion:")),
            .longOnly(.ayah("23:71", words: 0...8)),
            .longOnly(.ayah("6:116", words: 0...9)),
            .text("Neutrality, finally, is not neutral. A state that decides what children are taught about marriage, the body and religion has taken a position on the good life. A rule that only “public reasons” may shape law has decided in advance that revelation does not count. Liberalism is one comprehensive view among others, and it should be argued for as one."),
        ]),
        ArticleSection("THE SOVEREIGN SELF", [
            .text("At the centre of liberal thought stands the autonomous individual, sovereign over his body and mind, the author of his own values. The Quran has a precise description of a person who makes his own wishes the final authority:"),
            .ayah("45:23", words: 0...4),
            .markdown("The word is **hawa (هَوَى)**: desire, inclination, what the self wants. The Quran does not say such a person has no god. It says he has one, and it is his own desire. Liberalism promises to free people from every master but themselves; the Quran answers that the self is a master too, and often the cruellest. Allah gives the comparison:"),
            .ayah("39:29"),
            .longOnly(.text("The man owned by quarrelling partners is pulled by every one of them: his appetites, his fears, the market, fashion, the opinion of others. The man who belongs to one master alone is at rest. The Prophet Muhammad (peace and blessings be upon him) described the first kind of servitude:")),
            .longOnly(.hadith("bukhari:2887", cite: "Saheeh al-Bukhaari 2887", arabic: 28...47, english: [5...59])),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) knew prison from the inside; he died in the citadel of Damascus in 728 AH (1328 CE). His student Ibn al-Qayyim recorded what he used to say about freedom:")),
            .longOnly(.quote(text: "“The prisoner is the one whose heart is imprisoned from his Lord, and the captive is the one whose desire has taken him captive.” (Ibn Taymiyyah, as recorded by Ibn al-Qayyim in al-Waabil as-Sayyib).", arabic: "المَحبُوسُ مَن حُبِسَ قَلبُهُ عَن رَبِّهِ تَعَالَى، وَالمَأسُورُ مَن أَسَرَهُ هَوَاهُ", dimmed: true)),
            .shortOnly(.text("The man owned by quarrelling partners is pulled by every one of them: his appetites, his fears, the market, fashion, the opinion of others. The man who belongs to one master alone is at rest.")),
            .markdown("This is freedom in Islam: **‘uboodiyyah (عُبُودِيَّة)**, servitude to Allah alone, which is the only servitude that frees a person from all the others. The more completely a heart belongs to its Creator, the less it can be owned by anything He created (51:56)."),
            .ayah("51:56"),
        ]),
        ArticleSection("JUDGMENT BELONGS TO ALLAH", [
            .text("Secularism, in its political sense, places the right to make law in human hands alone: a legislature, a constitution, the will of the people. The Quran places it with the One who created:"),
            .longOnly(.ayah("7:54", words: 24...31)),
            .ayah("12:40", words: 15...23),
            .longOnly(.ayah("5:50")),
            .longOnly(.text("He who created the human being knows what is good for him (67:14), and His right to command follows from His act of creating. The Quran treats the claim to make lawful what Allah forbade, or forbid what He made lawful, as a claim to His lordship. It said of the People of the Book that they took their rabbis and monks as lords besides Allah (9:31), and the exegetes explain that they did not pray to them; they obeyed them in changing what Allah had made lawful and unlawful. It asks of all such lawgivers: or have they partners who have laid down for them in religion what Allah did not permit (42:21)?")),
            .longOnly(.ayah("67:14")),
            .longOnly(.ayah("9:31", words: 0...6)),
            .longOnly(.ayah("42:21")),
            .shortOnly(.text("The Quran treats the claim to make lawful what Allah forbade, or forbid what He made lawful, as a claim to His lordship: it said of the People of the Book that they took their rabbis and monks as lords besides Allah, because they obeyed them in changing what Allah had made lawful and unlawful.")),
            .longOnly(.text("Ahl as-Sunnah state the ruling on judging by other than what Allah revealed with care. Ibn Abbaas (may Allah be pleased with him) said of the ruling of disbelief in 5:44 that it is a disbelief less than disbelief, not the disbelief that takes a person out of the religion.")),
            .longOnly(.ayah("5:44", words: 32...40)),
            .longOnly(.text("The scholars, among them Ibn Baaz, Ibn al-Uthaymeen and al-Albaani (may Allah have mercy on them), give the detail:")),
            .shortOnly(.text("Ahl as-Sunnah state the ruling on judging by other than what Allah revealed with care, and the scholars give the detail:")),
            .bullet("**Major disbelief.** Whoever holds that a law other than Allah’s is better than it, or equal to it, or that ruling by it is permissible, or who rejects Allah’s ruling, has rejected His lordship and left Islam."),
            .bullet("**Minor disbelief.** Whoever rules by other than it in a particular matter out of desire, bribery, fear or favour, while believing that Allah’s law is the truth and that he himself is sinning, has committed a grave sin that the texts call kufr without meaning apostasy."),
            .longOnly(.text("Two cautions go with this. First, declaring a particular ruler or person a disbeliever is not the business of individuals: it needs knowledge of what he believes, the meeting of conditions and the absence of impediments, and it belongs to qualified scholars. Whoever rushes to it has taken the road of the Khawaarij. Second, a Muslim who lives under laws he did not choose obeys them in what is lawful and refuses only what is sin, as the Prophet commanded:")),
            .longOnly(.hadith("bukhari:7144", cite: "Saheeh al-Bukhaari 7144", arabic: 28...46, english: [4...53])),
            .shortOnly(.text("Declaring a particular ruler or person a disbeliever is not the business of individuals: it needs knowledge of what he believes and belongs to qualified scholars, and whoever rushes to it has taken the road of the Khawaarij.")),
            .door(.article("KufrView")),
        ]),
        ArticleSection("WHY EUROPE CHOSE SECULARISM", only: .long, [
            .text("Secularism was not born from reflection on Islam. It was born from Europe’s experience with its church: clergy who claimed to speak for God, sold indulgences, and made and unmade kings, until Martin Luther’s protest of 1517 split Western Christendom and a century of religious war followed. The remedy Europe found was to remove religion from public authority altogether."),
            .text("The Quran had diagnosed that disease centuries earlier, in the ayah already cited: they took their rabbis and monks as lords besides Allah (9:31). The sickness was not revelation. It was men who claimed the right to legislate in God’s name without revelation. Islam has no church, no priesthood that controls salvation, and no council that can change the religion. Its scholars are explainers of a text that binds them as much as anyone, and a scholar’s word is accepted only when it rests on that text. The cure for a corrupted religion is an uncorrupted revelation, not the abandonment of revelation."),
            .text("John Locke, often called the father of liberal toleration, did not ground it in a world without God. He refused toleration to atheists for exactly that reason:"),
            .quote(text: "“Those are not at all to be tolerated who deny the being of a God. Promises, covenants, and oaths, which are the bonds of human society, can have no hold upon an atheist.” (John Locke, A Letter Concerning Toleration, 1689).", dimmed: true),
            .text("A Muslim does not accept Locke’s theology, and Islam itself gives protection to unbelievers who live in peace under it. But the quotation shows something modern humanism forgets: its own founders assumed God to hold up the very rights and obligations they defended."),
        ]),
        ArticleSection("MERCY AND JUSTICE UNDER ISLAM", [
            .text("Liberals fear that a society governed by revelation will crush those who disagree with it. The Sunnah gives a different picture. Faith itself may not be compelled (2:256)."),
            .ayah("2:256"),
            .text("The law binds the powerful as it binds the weak, as the Prophet (peace be upon him) made plain when the leading families of Quraysh tried to spare a noblewoman of Banu Makhzoom the punishment for theft:"),
            .hadith("bukhari:3475", cite: "Saheeh al-Bukhaari 3475", arabic: 73...100, english: [83...131]),
            .longOnly(.text("Non-Muslims who live under a Muslim covenant have their lives, property and worship protected. Whoever kills one of them will not smell the fragrance of Paradise (Saheeh al-Bukhaari 3166).")),
            .longOnly(.hadith("bukhari:3166", cite: "Saheeh al-Bukhaari 3166", arabic: 32...45, english: [4...31])),
            .longOnly(.text("And the Prophet promised to take up their cause himself against any Muslim who wrongs them:")),
            .longOnly(.hadith("abudawud:3052", cite: "Sunan Abi Daawood 3052; graded saheeh by al-Albaani", arabic: 41...61, english: [31...67])),
            .longOnly(.text("“I shall plead for him” means that the Prophet will argue the wronged man’s case against the Muslim who wronged him. The Quran forbids spying on people’s private lives (49:12), and it commands justice even against oneself, one’s parents and one’s relatives (4:135). Islam does not pretend to be neutral: it says openly that the law is Allah’s. But the law it brings protects the very people liberalism worries about, and its protection does not depend on a majority’s mood.")),
            .longOnly(.ayah("49:12", words: 11...12)),
            .longOnly(.ayah("4:135")),
            .longOnly(.ayah("16:90")),
            .shortOnly(.text("Islam does not pretend to be neutral: it says openly that the law is Allah’s. But the law it brings protects the very people liberalism worries about, and its protection does not depend on a majority’s mood.")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Can a person be good without God?**"),
            .longOnly(.text("A person can do good without believing in God. The fitrah and the moral sense Allah gave every human being see to that, and the Quran acknowledges goodness wherever it is found (3:75). The real question is different: can goodness be owed, binding even on someone who does not feel like it, if there is no one to whom it is owed? A good deed done without faith is rewarded in this world (Saheeh Muslim 2808). What faith adds is not the ability to be kind but the reason kindness is required, and a Judge before whom no cruelty is ever forgotten.")),
            .shortOnly(.text("A person can do good without believing in God; the fitrah Allah gave every human being sees to that. The real question is different: can goodness be owed, binding even on someone who does not feel like it, if there is no one to whom it is owed? What faith adds is not the ability to be kind but the reason kindness is required, and a Judge before whom no cruelty is ever forgotten.")),
            .longOnly(.ayah("3:75")),
            .longOnly(.hadith("muslim:2808", cite: "Saheeh Muslim 2808", arabic: 52...72, english: [31...74])),
            .longOnly(.markdown("**If liberal states protect Muslim minorities, why criticise liberalism?**")),
            .longOnly(.text("A Muslim living in a secular country is grateful for every protection of his religion, keeps his agreements as the Quran commands (5:1), obeys the law in what is lawful, and is a good neighbour. Benefiting from a system’s protections is not the same as accepting its foundations. The critique here is of a belief, that man is the final source of value and law, and not of the safety of a street or the fairness of a court.")),
            .longOnly(.ayah("5:1", words: 0...4)),
            .longOnly(.markdown("**Isn’t “freedom as servitude to Allah” just a play on words?**")),
            .longOnly(.text("Every human being serves something: money, approval, pleasure, a cause, the self. No one is a servant of nothing. The only real question is which master, and whether serving it makes a person smaller or larger. Servitude to the One who created and sustains him, who needs nothing from him and commands only what benefits him, is the one servitude that does not degrade a person, and it releases him from all the others. That is what 39:29 compares: a slave owned by quarrelling partners and a slave who belongs to one.")),
            .door(.article("DominoWorldviewsView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Secular humanism and liberalism defend things Islam also defends: protection from tyranny, freedom of conscience, the rule of law, the dignity of the individual. But they rest on borrowed ground. Matter yields no “ought”; reason without shared premises does not agree with itself; harm cannot be defined without a view of what man is for; and the sovereign self turns out to be a master of its own. The Quran grounds dignity in Allah’s honouring of the children of Aadam, moral knowledge in the fitrah, obligation in a Commander who will judge, law in the One who created, and freedom in servitude to Him alone. Its scholars state the ruling on legislating besides Allah with precision and leave the ruling on individuals to those qualified to give it, and its law protects the very people secular thought fears for."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Almaaniyyah", arabic: "العَلمَانِيَّة", meaning: "**Secularism**. The Arabic word is formed from ‘aalam, the world, not from ‘ilm, knowledge: the ordering of life and law by this world alone, without revelation. Islam knows no such division: my prayer, my sacrifice, my living and my dying are for Allah (6:162)."),
            .ayah("6:162"),
            .term("Hawa", arabic: "هَوَى", meaning: "**Desire**, the inclination of the self. The Quran warns against the one who takes his hawa as his god (45:23), which is the sovereign self of modern thought described in a single phrase."),
            .term("Tashree‘", arabic: "تَشرِيع", meaning: "**Legislation**: making things lawful and unlawful. It belongs to Allah (12:40, 42:21); claiming it for oneself, or obeying another in it against Allah’s law, is what 9:31 calls taking lords besides Him."),
            .term("Uboodiyyah", arabic: "عُبُودِيَّة", meaning: "**Servitude** to Allah: obeying, loving and fearing Him alone. The purpose of creation (51:56), and the freedom that releases a person from servitude to everything created."),
        ]),
    ]
}

// MARK: - religions-2

struct ReligionsSikhismView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsSikhismView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Sikhism")
        .englishArticle().selectableArticleList(article: "ReligionsSikhismView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Sikhism began with Guru Nanak (1469–1539) in the Punjab and grew through ten Gurus into a community with its own scripture, the Guru Granth Saahib, and its own order, the Khalsa. It confesses one Creator in words very close to the Quran’s, rejects idols and caste, and honours honest work and service. Islam welcomes that confession and asks where it leads: to revelation after the Seal of the Prophets, to a cycle of rebirth in place of one resurrection, to a Guru standing between the seeker and God, and to a claim to stand above both Hindu and Muslim. This chapter sets out the faith as Sikhs hold it, then answers it from the Quran and the Sunnah."),
        ]),
        ArticleSection("GURU NANAK AND THE PUNJAB", [
            .longOnly(.text("Nanak was born in 1469 at Talwandi, a village near Lahore now called Nankana Saahib, into a Hindu family of the Khatri caste. The Punjab of his youth was ruled by the Lodi sultans of Delhi, and its people lived between two worlds: Hindu villages, temples and Brahmin priests on one side, Muslim governors, qaadees and Sufi lodges on the other. As a young man he kept the stores of a Muslim nobleman, Daulat Khan Lodi, at Sultanpur Lodhi.")),
            .longOnly(.text("Sikh tradition tells that around 1500, while bathing in the river Bein, he disappeared for three days. When he came back he said, “There is no Hindu and there is no Musalman,” and Sikhs date his mission from that moment: he had been taken, they say, into the presence of God and commanded to teach the Name. He then travelled for many years with a Muslim musician named Mardana, who played the rabab while Nanak sang his hymns. The janamsakhis, life stories of Nanak written down generations later, take him to Hindu holy places, to Baghdaad and to Makkah; historians treat their details with caution.")),
            .longOnly(.text("In his last years he settled at Kartarpur on the river Ravi, where his followers farmed, ate together and sang his hymns morning and evening. He died there in 1539, having named a disciple, Lehna, as his successor under the name Angad.")),
            .shortOnly(.text("Nanak was born in 1469 near Lahore into a Hindu family, in a Punjab that lived between Hindu villages and temples on one side and Muslim governors and Sufi lodges on the other. Sikh tradition tells that around 1500 he disappeared for three days in the river Bein and came back saying, “There is no Hindu and there is no Musalman”, and Sikhs date his mission from that moment. He died at Kartarpur in 1539.")),
            .text("Sikhs see in Nanak neither a Hindu reformer nor a Muslim Sufi, but the founder of a path given directly by God. An honest conversation starts there: the Sikh does not think he has borrowed from either neighbour, and a Muslim who wants to be heard should not begin by telling him that he has."),
        ]),
        ArticleSection("THE TEN GURUS, THE BOOK AND THE KHALSA", [
            .longOnly(.chain([
                ArticleChainLink("Guru Nanak (1469–1539)", "The founder; his hymns open the scripture"),
                ArticleChainLink("Guru Angad (1504–1552)", "Tradition credits him with fixing the Gurmukhi script"),
                ArticleChainLink("Guru Amar Das (1479–1574)", "Had every visitor, high caste or low, eat together in the langar"),
                ArticleChainLink("Guru Ram Das (1534–1581)", "Founded the town that became Amritsar"),
                ArticleChainLink("Guru Arjan (1563–1606)", "Compiled the Adi Granth in 1604; executed at Lahore"),
                ArticleChainLink("Guru Hargobind (1595–1644)", "Wore two swords, for spiritual and worldly authority"),
                ArticleChainLink("Guru Har Rai (1630–1661)", "Kept the community through a quiet reign"),
                ArticleChainLink("Guru Har Krishan (1656–1664)", "Became Guru as a child of five"),
                ArticleChainLink("Guru Tegh Bahadur (1621–1675)", "Executed at Delhi under Aurangzeb"),
                ArticleChainLink("Guru Gobind Singh (1666–1708)", "Founded the Khalsa in 1699; named the scripture Guru after him"),
            ], caption: "The ten Gurus of the Sikhs, with the dates their tradition and historians give")),
            .longOnly(.markdown("The fifth Guru, Arjan, gathered the hymns of the first four Gurus and his own, together with those of earlier Indian saints, and in 1604 installed the collection, the **Adi Granth** (“the first book”), in the Harmandir Saahib at Amritsar, the shrine known in English as the Golden Temple. Guru Gobind Singh later added the hymns of his father, Tegh Bahadur. The finished book runs to 1,430 pages in its standard printing. It is written in the Gurmukhi script in several of the languages of north India, and it is arranged not by subject but by raga, the musical measure in which each hymn is to be sung. Alongside six Gurus it carries the verses of fifteen bhagats (devotees), among them Kabeer, Namdev and Ravidas, and couplets attributed to Baba Fareed, the Chishti Sufi of Pakpattan (d. 1266).")),
            .longOnly(.markdown("Two Gurus died at the hands of Mughal authorities: Arjan at Lahore in 1606 under the emperor Jahangir, and Tegh Bahadur at Delhi in 1675 under Aurangzeb. That memory shaped what followed. On the spring festival of Vaisakhi in 1699, at Anandpur, Guru Gobind Singh called for men ready to give their heads, initiated the five who came forward (the **Panj Pyare**, “the five beloved”) with sweetened water stirred by a double-edged sword, and so founded the **Khalsa**, the order of initiated Sikhs. Its men take the name Singh (“lion”) and its women Kaur, and they keep the five Ks: uncut hair (kesh), a comb (kangha), a steel bracelet (kara), a sword (kirpan) and a cotton undergarment (kachera).")),
            .longOnly(.markdown("Before his death at Nanded in 1708, Guru Gobind Singh declared that there would be no further human Guru. The book itself became the Guru, the **Guru Granth Saahib**, and the community of the Khalsa its living body. Every gurdwara since then is, in Sikh eyes, the court of a living Guru.")),
            .shortOnly(.text("Ten Gurus led the community in turn. The fifth, Arjan, compiled the hymns of the Gurus and of earlier Indian saints into the Adi Granth in 1604. The tenth, Gobind Singh, founded the Khalsa, the order of initiated Sikhs who keep the five Ks, in 1699, and before his death in 1708 declared that there would be no further human Guru: the book itself became the Guru, the Guru Granth Saahib.")),
        ]),
        ArticleSection("WHAT SIKHS BELIEVE", [
            .markdown("The scripture opens with a short creed, the **Mool Mantar**, which Sikhs regard as the root of everything after it. Rendered closely, it says: there is One (**Ik Onkar**); Truth is His Name; He is the Creator, without fear and without enmity; His form is timeless; He is unborn and self-existent; and He is known by the Guru’s grace. Sikhs call God **Waheguru** (“the Wondrous Lord”) and **Akal Purakh** (“the Timeless Being”), and the hymns also call Him by Hindu and Muslim names: Ram, Hari, Allah and Khuda."),
            .longOnly(.bullet("**Hukam.** All things happen by the divine order, and the seeker’s task is to recognise it and submit to it.")),
            .longOnly(.bullet("**Haumai.** The root sickness of the soul is self-centredness, from which grow the “five thieves”: lust, anger, greed, attachment and pride.")),
            .longOnly(.bullet("**Naam simran.** The cure is constant remembrance of God’s Name, in meditation, in the sung hymns and in the daily prayers.")),
            .bullet("**Karma and rebirth.** A soul that does not awaken wanders through the cycle of births, which the hymns count as 8.4 million kinds of life, and its deeds shape the life it is born into next."),
            .bullet("**Mukti.** Liberation is release from that cycle, by God’s grace (nadar), into union with Him."),
            .longOnly(.text("The practice follows from the belief. Sikhs reject the worship of images, the caste system, and ritual pilgrimage and fasting as ways to God. They reject the monk’s withdrawal too: the ideal is a householder who earns honestly (kirat karni), shares what he earns (vand chhakna) and remembers the Name (naam japna). Every gurdwara keeps a free kitchen, the langar, where all sit on the floor and eat together, whatever their caste or religion. The standard Sikh code of conduct, the Rehat Maryada, forbids the initiated four things: cutting the hair, using tobacco, adultery, and eating kutha meat, which it defines as meat slaughtered in the Muslim manner.")),
            .callout("Much of this a Muslim recognises at once: one Creator, no idols, no caste, honest work, and food shared with the poor. The disagreement is not over whether God is One. It is over how He has spoken, what becomes of the soul, and whether anyone stands between the servant and his Lord.", title: "Common Ground", icon: "lightbulb.fill"),
        ]),
        ArticleSection("ONE GOD: WHERE THE CREEDS MEET AND PART", [
            .text("Set beside the Mool Mantar, Surat al-Ikhlaas reads almost like an answer from a friend:"),
            .ayah("112:1-4"),
            .text("Both say He is One, unborn, and owes His being to none. Both refuse the image. The Prophet Muhammad (peace and blessings be upon him) was sent to people who knew of a High God and worshipped others beside Him, and much of the Quran is spent proving what the Mool Mantar already affirms. A Muslim should say so plainly."),
            .longOnly(.text("The creeds part over how the One relates to what He made. Sikh theology speaks of God as nirgun, beyond all qualities, and also sargun, present and manifest in His creation. The hymns often describe Him as pervading every heart and every thing, and liberation as the soul’s light merging into the divine Light, as a drop returns to the ocean. Sikh scholars differ over how literally to take this, and many prefer to say that God is in all things without being identical with them. Still, the hope at the end of the path is a union in which the self is lost.")),
            .shortOnly(.text("The creeds part over how the One relates to what He made. The hymns often describe Him as pervading every heart and every thing, and liberation as the soul’s light merging into the divine Light, as a drop returns to the ocean: a union in which the self is lost.")),
            .text("The Quran draws the line more sharply. Allah is the Creator and everything else is created; He is above His creation, over His Throne, and nothing is like Him:"),
            .ayah("42:11", words: 13...18),
            .ayah("20:5"),
            .longOnly(.text("He is near to those who call on Him, hearing and answering (2:186), but the servant never becomes Him, and He does not dwell in the servant. The scholars of the Sunnah, Ibn Taymiyyah (may Allah have mercy on him) foremost among them, wrote at length against those who spoke of God indwelling His creation (hulool) or of the soul becoming one with Him (ittihaad), because such talk erases the difference between the worshipper and the One worshipped, and with it worship itself.")),
            .shortOnly(.text("He is near to those who call on Him, but the servant never becomes Him, and He does not dwell in the servant. Talk of such a union erases the difference between the worshipper and the One worshipped, and with it worship itself.")),
            .longOnly(.text("The highest joy the Prophet (peace be upon him) promised is not dissolution but sight: the servant, still himself, looking at his Lord.")),
            .longOnly(.hadith("muslim:181a", cite: "Saheeh Muslim 181", arabic: 37...77, english: [0...77])),
            .text("Worship in Islam is love and humility directed to Someone else, and that needs two: the Lord and the servant, for ever."),
        ]),
        ArticleSection("REVELATION AFTER THE SEAL", [
            .markdown("Sikhs hold that the Gurus’ hymns are not human poetry but revelation, **dhur ki bani**, “the Word from the Source”. Guru Nanak says in one hymn that he speaks as the Word of the Lord comes to him (Guru Granth Saahib, page 722). The question for a Muslim is not whether Nanak was sincere, which is for Allah to judge, but whether a revelation could come in his century at all."),
            .text("The Quran answered that question nine centuries before him. It names Muhammad (peace be upon him) the seal of the prophets, and he explained the word himself:"),
            .ayah("33:40", words: 7...11),
            .longOnly(.hadith("muslim:523", cite: "Saheeh Muslim 523", arabic: 35...58, english: [0...70])),
            .longOnly(.text("Two of the six honours bear on this question: he was sent to all mankind, and the line of prophets was closed with him. A message after his has no room to stand in, and the Quran’s warning to those who claim an inspiration that was never given is severe (6:93). This does not make every good thing Nanak said false; truth spoken after the Seal is still true. But it is measured against the revelation, not added to it.")),
            .shortOnly(.text("The line of prophets was closed with him, so a message after his has no room to stand in. This does not make every good thing Nanak said false; truth spoken after the Seal is still true. But it is measured against the revelation, not added to it.")),
            .longOnly(.ayah("6:93", words: 0...14)),
            .longOnly(.text("A scripture is also tested by what it claims for itself. The Quran stakes everything on a challenge that any reader can try:")),
            .longOnly(.ayah("2:23")),
            .longOnly(.text("The Guru Granth Saahib makes no such claim. It is an anthology of devotional hymns by more than thirty contributors across five centuries, Gurus, Hindu saints, Muslim Sufis and court poets, arranged by musical mode, and its beauty is the beauty of sung poetry. Sikhs revere every line as Gurbani, the Guru’s word, but the book does not offer itself as the inimitable speech of God, and it gives no law of worship, trade, marriage or inheritance. The Quran presents itself as the speech of the Lord of the worlds, the criterion between truth and falsehood, kept letter by letter (15:9).")),
            .longOnly(.ayah("15:9")),
            .longOnly(.text("There is a quiet irony inside the collection. The couplets attributed to Baba Fareed sit among its hymns, and Fareed prayed toward Makkah, fasted Ramadan and held the Prophet (peace be upon him) to be the last messenger. The man the Gurus honoured by including him lived by the very revelation that Sikhism set aside.")),
        ]),
        ArticleSection("ONE LIFE, ONE DEATH, ONE RESURRECTION", [
            .longOnly(.text("Sikhism inherited from the religions of India the belief in karma and rebirth: the soul passes from body to body, rising or falling by its deeds, until grace frees it. The answer of Islam is the one it gives the Hindu; here it is enough to show three places where the Quran closes the door on a return.")),
            .shortOnly(.text("Sikhism inherited from the religions of India the belief in karma and rebirth: the soul passes from body to body, rising or falling by its deeds, until grace frees it. The answer of Islam is the one it gives the Hindu.")),
            .door(.article("HinduismAnswerView")),
            .longOnly(.text("First, the Quran counts a person’s states exactly, and the count has two lives and two deaths, not many:")),
            .shortOnly(.text("The Quran closes the door on a return when it counts a person’s states exactly, and the count has two lives and two deaths, not many:")),
            .ayah("2:28"),
            .longOnly(.text("Second, it describes the one who asks at death to be sent back, and refuses him:")),
            .longOnly(.ayah("23:99-100", words: 13...23)),
            .longOnly(.markdown("The barrier, **barzakh**, is the life of the grave, which lasts until the Resurrection. The Prophet (peace be upon him) described it:")),
            .longOnly(.hadith("bukhari:1379", cite: "Saheeh al-Bukhaari 1379, Saheeh Muslim 2866", arabic: 27...59, english: [4...72])),
            .longOnly(.text("Third, it answers the doubt that the same body could ever be raised:")),
            .longOnly(.ayah("36:78-79")),
            .longOnly(.text("There is also a question of justice. A soul punished in its next life for deeds it cannot remember is not being judged; it is being processed. The Quran’s judgment is of the same person who acted, with his record open before him (17:13-14), his own limbs testifying (36:65), and nothing forgotten. Sikh scripture itself speaks of Dharam Raj, the righteous judge who reads each soul’s account after death. Islam keeps that account and removes the wheel: one life in which to act, one death, and one Day on which every account is settled.")),
            .longOnly(.ayah("17:13-14")),
            .longOnly(.ayah("36:65")),
            .shortOnly(.text("There is also a question of justice. A soul punished in its next life for deeds it cannot remember is not being judged; it is being processed. Islam removes the wheel: one life in which to act, one death, and one Day on which every account is settled.")),
        ]),
        ArticleSection("THE GURU BETWEEN THE SEEKER AND GOD", [
            .longOnly(.text("Sikhism rejects idols, and Sikhs are rightly offended when their reverence for the scripture is called idol worship. Yet the Guru stands at the centre of Sikh devotion in a way that raises Islam’s oldest question. The hymns teach again and again that without the Guru no one finds God. The Guru Granth Saahib is treated as a living sovereign: it is carried on the head, installed on a throne under a canopy, fanned with a whisk (chaur) as a king would be, laid to rest at night and opened again at dawn, and every Sikh who enters the hall bows his forehead to the ground before it.")),
            .shortOnly(.text("Sikhism rejects idols, yet the Guru stands at the centre of Sikh devotion. The hymns teach that without the Guru no one finds God, and the Guru Granth Saahib is treated as a living sovereign: it is installed on a throne under a canopy, and every Sikh who enters the hall bows his forehead to the ground before it.")),
            .text("Sikhs explain that the bow is to the Word, not to paper and ink. A Muslim understands honour for a sacred book: he does not touch the mushaf without purity or leave it on the floor. But Islam draws a firm line at the bow itself. Prostration belongs to Allah alone, whatever else is honoured:"),
            .ayah("41:37", words: 6...18),
            .longOnly(.text("Nor is anyone, however beloved, placed between the servant and his Lord in prayer. The Messenger of Allah (peace be upon him) is followed, loved and obeyed, but no Muslim prays to him, and he taught a boy riding behind him to go straight to Allah:")),
            .longOnly(.hadith("tirmidhi:2516", cite: "Jaami‘ at-Tirmidhi 2516; graded saheeh by al-Albaani", arabic: 60...79, english: [10...50])),
            .longOnly(.text("The Quran puts the same thing as a promise:")),
            .shortOnly(.text("Nor is anyone, however beloved, placed between the servant and his Lord in prayer. The Quran puts it as a promise:")),
            .ayah("2:186"),
            .longOnly(.text("A guide shows the road; he is not a door one must bow before to reach God. The Prophet’s authority comes from Allah’s command to obey him (4:80), and his own teaching sends every hand raised in prayer straight to his Lord.")),
            .longOnly(.ayah("4:80")),
        ]),
        ArticleSection("NEITHER HINDU NOR MUSLIM?", [
            .longOnly(.text("The words Sikhs love best from Nanak, that there is no Hindu and no Musalman, were heard as a call beyond the quarrels of two communities. A hymn of Guru Arjan in Raag Bhairo says the same in the first person: the singer keeps neither the Hindu fast nor Ramadan, goes neither on the Hindu pilgrimage nor on the Hajj, and is neither Hindu nor Muslim, for his body and breath belong to the One whom both call by their own names. Older Western scholars often called Sikhism a blend of the two religions. Sikhs reject that description, fairly enough: Sikhism has its own scripture, rites and history, and it sees itself as a third revelation, not a mixture.")),
            .shortOnly(.text("The words Sikhs love best from Nanak, that there is no Hindu and no Musalman, were heard as a call beyond the quarrels of two communities, and Sikhism sees itself as a third revelation, not a mixture of the two.")),
            .text("Islam answers by refusing the frame. If Islam were only the inherited custom of one community, standing above it would be a fair act of peacemaking. But the Quran presents Islam as the submission every prophet taught, the religion of Ibraaheem (peace be upon him) before there were Jews, Christians or Muslims as communities:"),
            .ayah("3:67"),
            .longOnly(.ayah("3:19", words: 0...4)),
            .text("So the question is not which community to join, or whether to rise above both, but whether Allah spoke through Muhammad (peace be upon him). If He did, then the One whom Nanak praised had already sent His final word, and loyalty to the One means accepting it:"),
            .ayah("3:85"),
            .longOnly(.text("Nanak himself, in a verse of his Var Majh, said that it is hard to be called a Muslim, and that only one who truly lives as a Muslim deserves the name. A Muslim can take that as a fair challenge to his own conduct. It is also an invitation, because the name belongs to whoever submits to Allah as He commanded.")),
            .longOnly(.text("History has made this conversation harder. Sikhs remember the execution of two Gurus by Mughal authorities and the killing of Guru Gobind Singh’s two youngest sons at Sirhind; both communities remember the massacres of 1947, when the Punjab was divided. A Muslim does not answer old wounds with excuses. Injustice by a ruler who called himself a Muslim is still injustice, the Quran forbids compelling anyone into the religion (2:256), and it commands justice even toward people one dislikes (5:8). The case for Islam rests on the Quran and the Prophet, not on the record of any empire.")),
            .longOnly(.ayah("2:256")),
            .longOnly(.ayah("5:8", words: 8...18)),
            .door(.article("ReligionsOneView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Do Sikhs and Muslims worship the same God?**"),
            .text("There is only one Creator, and the Mool Mantar describes Him truly in much of what it says. But worship is not only knowing that God is One; it is worshipping Him alone, in the way He revealed, through the messenger He sent last. Where the Sikh affirms the One, he is right. Where he takes a scripture after the Seal as revelation, bows before it, and hopes for release from rebirth, he has left the path the One laid down."),
            .longOnly(.markdown("**Was Guru Nanak a prophet, or a hidden Muslim saint?**")),
            .longOnly(.text("He was not a prophet, because there is no prophet after Muhammad (peace be upon him). Some Muslims have claimed him as a Sufi in secret, but his own hymns and those of his successors set aside the prayer, the fast and the Hajj, so the claim does not fit what was taught in his name. What passed between him and his Lord at the end is not ours to know; we judge teachings, and leave souls to Allah.")),
            .longOnly(.markdown("**What can Muslims and Sikhs do together?**")),
            .longOnly(.text("A great deal. Both honour honest earning: the Prophet (peace be upon him) said that no one has eaten better food than what he earned with his own hands, as the Prophet Daawood (peace be upon him) did (Saheeh al-Bukhaari 2072). Both feed the poor without asking their religion, oppose the pride of caste and race, and refuse idols. Shared good works are fine ground for the conversation that matters more.")),
            .longOnly(.hadith("bukhari:2072", cite: "Saheeh al-Bukhaari 2072", arabic: 29...53, english: [4...38])),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Sikhism began with a man who looked at the idols and castes of his land and said there is One Creator, without fear, without enmity, unborn. Islam agrees, and goes on: the One had already sent His final messenger nine centuries before Nanak, closed prophethood with him, and kept his book word for word. He gave each soul one life, not many, and one Resurrection. And He placed no Guru between Himself and the servant who calls on Him. The invitation to the Sikh is to follow his own first principle to its end."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Wahy", arabic: "وَحي", meaning: "**Revelation**: Allah’s speech conveyed to a prophet. It ended with the Prophet Muhammad (peace be upon him), with whom the line of prophets was closed (33:40); what remains after him is only the true dream, which is not a source of law or creed."),
            .term("Barzakh", arabic: "بَرزَخ", meaning: "A **barrier** between two things. In 23:100 it is the life of the grave between death and the Resurrection, from which no soul returns to the world."),
            .term("Tanaasukh", arabic: "تَنَاسُخ", meaning: "**Transmigration**: the passing of a soul from body to body. The Muslim theologians used this word for the doctrine of rebirth and counted it a denial of the Resurrection."),
            .term("Hulool", arabic: "حُلُول", meaning: "**Indwelling**: the claim that God dwells in a creature or in all things. Ahl as-Sunnah reject it, holding that Allah is above His creation and distinct from it, while near to it in His knowledge, hearing and care."),
        ]),
    ]
}

struct ReligionsZoroastrianismView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsZoroastrianismView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Zoroastrianism")
        .englishArticle().selectableArticleList(article: "ReligionsZoroastrianismView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Zoroastrianism is the ancient religion of Iran, traced to the prophet Zarathustra and his hymns, the Gathas. It worships Ahura Mazda, the Wise Lord, and teaches a cosmic struggle between him and a destructive spirit, with fire as the sign of purity and a bridge of judgment after death. The Quran names its followers, al-Majoos, and the Sunnah fixed their place under Muslim rule. Islam answers that light and darkness are both created by one Lord, that Satan is a creature who creates nothing, that no light is to be bowed to, and that the judgment Zoroastrians await is real and is crossed safely only by the way of the last Prophet."),
        ]),
        ArticleSection("ZARATHUSTRA AND HIS HYMNS", [
            .longOnly(.text("Zarathustra, called Zoroaster by the Greeks, was a priest and poet of the ancient Iranian peoples. When he lived is uncertain. Later Zoroastrian tradition placed him in the sixth century BCE, but the language of his hymns is very close to that of the oldest Indian scripture, the Rigveda, and most scholars now place him somewhere between about 1500 and 1000 BCE, in the lands east of modern Iran. Zoroastrians tell that at the age of thirty, beside a river, he was led in a vision into the presence of Ahura Mazda; that he preached for years with little success; and that a king named Vishtaspa finally accepted his message and established the faith.")),
            .longOnly(.markdown("His own words survive in seventeen hymns, the **Gathas**, composed in an archaic language called Old Avestan. They are short, difficult and intensely personal: Zarathustra questions Ahura Mazda, laments his rejection, and calls his hearers to choose between truth (asha) and the lie (druj). Around them grew a larger body of later texts, the **Avesta**: the liturgy of the Yasna, into which the Gathas are set; hymns to lesser divine beings, the Yashts; and a book of purity laws, the Vendidad.")),
            .longOnly(.text("How much of it remains is a question Zoroastrians themselves answer with sorrow. Their tradition, recorded in the ninth and tenth centuries CE, says the Avesta once had twenty-one books (nasks), most of which were lost, a loss they lay at the door of Alexander’s conquest of Persia. For many centuries the texts were carried by the memory of the priests. A special alphabet to write them down was devised only in the Sasanian period, perhaps in the fifth or sixth century CE, and the oldest surviving manuscript of any part of the Avesta was copied in 1323 CE. Scholars estimate that perhaps a quarter of the Sasanian Avesta survives.")),
            .longOnly(.text("The great works of Zoroastrian theology, such as the Bundahishn on creation and the Denkard, were written in Middle Persian two and three hundred years after the rise of Islam. That matters for any comparison: the Gathas are ancient, but most of the detailed doctrine survives in books composed under Muslim rule.")),
            .shortOnly(.text("Zarathustra, called Zoroaster by the Greeks, was a priest and poet of the ancient Iranian peoples; most scholars now place him somewhere between about 1500 and 1000 BCE. His own words survive in seventeen hymns, the Gathas. Most of the larger Avesta that grew around them was lost, the oldest surviving manuscript of any part of it was copied in 1323 CE, and the great works of Zoroastrian theology were written two and three hundred years after the rise of Islam.")),
        ]),
        ArticleSection("THE WISE LORD AND THE DESTRUCTIVE SPIRIT", [
            .longOnly(.markdown("At the centre of the faith is **Ahura Mazda** (later Ohrmazd), the Wise Lord, wholly good and the creator of all that is good. Around him stand the Amesha Spentas, the Bounteous Immortals, six great beings who are at once his aspects and his helpers: Good Mind, Best Truth, Desirable Dominion, Holy Devotion, Wholeness and Immortality. Below them are the yazatas, beings held worthy of worship, among them Mithra and the river goddess Anahita.")),
            .longOnly(.markdown("Opposed to all of it is **Angra Mainyu** (later Ahriman), the destructive spirit, author of death, disease, lies and every foul thing. One of the Gathas speaks of two primal spirits, twins, the one better and the other bad in thought, word and deed, between whom every person must choose (Yasna 30:3). Later theology filled in the picture. In the Bundahishn, Ohrmazd dwells above in endless light and Ahriman below in endless darkness, with a void between them; Ohrmazd makes the world as a battlefield on which to defeat his rival, and history is a war of twelve thousand years that ends with Ahriman’s destruction, the resurrection of the dead and the renewal of the world. Under the Sasanian kings (224–651 CE), who made the faith the religion of their empire, a school called Zurvanism went further and made both spirits the sons of Time.")),
            .longOnly(.text("Many Zoroastrians today, especially the Parsis of India, read their faith differently. Since the nineteenth century, when European scholars and Parsi reformers turned back to the Gathas, they have stressed that Ahura Mazda alone is God, and that the evil spirit is not his equal but a lesser power doomed to defeat, or even a picture of the wrong choice in each human heart. In this form the religion is presented as one God, one moral law and a simple ethic: good thoughts, good words, good deeds (humata, hukhta, hvarshta). Some admirers call it the first monotheism.")),
            .shortOnly(.text("At the centre of the faith is Ahura Mazda, the Wise Lord, wholly good and the creator of all that is good. Opposed to him is Angra Mainyu, later Ahriman, the destructive spirit, author of death, disease and lies, and history is a war between them that ends with Ahriman’s destruction. Many Zoroastrians today, especially the Parsis of India, stress instead that Ahura Mazda alone is God and the evil spirit a lesser power doomed to defeat.")),
            .text("Both readings deserve an answer, because both keep the same instinct. To keep God far from evil, they give evil a source of its own."),
        ]),
        ArticleSection("AL-MAJOOS IN THE QURAN AND THE SUNNAH", [
            .markdown("The Arabs called the followers of this religion **al-Majoos (المَجُوس)**, from the Old Persian magu, the name of its priestly caste: the Magi of the Greek writers, and the wise men from the east in the Gospel of Matthew. The Quran names them once, in a verse that lists the religions of mankind and leaves the verdict between them to the Day:"),
            .ayah("22:17", words: 7...7),
            .longOnly(.text("In the lifetime of the Prophet Muhammad (peace and blessings be upon him) the Majoos were the faith of the Persian Empire, the great power to Arabia’s east, and some of them lived in eastern Arabia, at Haajar in Bahrain. The Prophet wrote to Kisra, the Persian emperor, inviting him to Islam; the emperor tore the letter to pieces, and the Prophet prayed that his kingdom be torn apart in the same way (Saheeh al-Bukhaari 64).")),
            .longOnly(.hadith("bukhari:64", cite: "Saheeh al-Bukhaari 64", arabic: 38...71, english: [0...73])),
            .longOnly(.door(.prophecy("chosroes-torn"))),
            .longOnly(.text("How were Muslims to treat them? They were not People of the Book in the Quran’s sense, yet the Prophet (peace be upon him) accepted the jizyah from them as from Jews and Christians, as Umar (may Allah be pleased with him) learned when the question came before him:")),
            .longOnly(.hadith("bukhari:3156", cite: "Saheeh al-Bukhaari 3156", arabic: 52...82, english: [73...127])),
            .longOnly(.text("The report shows two things. Umar ordered that the marriages of close kin which Zoroastrian custom allowed, and which Sasanian texts even praise as pious, be dissolved among those under Muslim rule. And he would not take the jizyah from them until a Companion testified that the Prophet had done so. On this basis most scholars held that the Majoos are treated like the People of the Book in the jizyah, while Muslims may not marry their women or eat what they slaughter. A report that they once had a scripture which was taken from them is narrated, but its chain is weak, and the rulings were not built on it.")),
            .longOnly(.text("The Prophet (peace be upon him) also foretold the end of their empire while it still stood at its height:")),
            .shortOnly(.text("The Prophet Muhammad (peace and blessings be upon him) foretold the end of their empire while it still stood at its height:")),
            .hadith("bukhari:3618", cite: "Saheeh al-Bukhaari 3618", arabic: 29...49, english: [4...46]),
            .longOnly(.text("Within twenty years of his death the Sasanian armies were broken at al-Qaadisiyyah and Nahavand, and the last king, Yazdegerd III, was killed in 651 CE. Over the following centuries most of Iran became Muslim, largely by gradual conversion. A remnant kept the old faith around Yazd and Kerman, and another group sailed to Gujarat, where their descendants, the Parsis, still live. Zoroastrians worldwide today number perhaps between one and two hundred thousand.")),
            .shortOnly(.text("Within twenty years of his death the Sasanian armies were broken, and over the following centuries most of Iran became Muslim. Zoroastrians worldwide today number perhaps between one and two hundred thousand.")),
            .longOnly(.text("Among the first Persians to find Islam was Salmaan al-Faarisi (may Allah be pleased with him), from Ram-Hurmuz (Saheeh al-Bukhaari 3947), who was raised, as his biographers relate, in the religion of the Majoos. He left it in search of the truth, was sold from master to master more than ten times on the way (Saheeh al-Bukhaari 3946), and reached the Prophet in Madinah. With his hand on Salmaan, the Prophet said that if faith were at the Pleiades, men of his people would reach it (Saheeh al-Bukhaari 4897). Persia went on to give the ummah al-Bukhaari, Muslim and a great many of its scholars.")),
            .longOnly(.hadith("bukhari:3947", cite: "Saheeh al-Bukhaari 3947", arabic: 20...23, english: [0...7])),
            .longOnly(.hadith("bukhari:3946", cite: "Saheeh al-Bukhaari 3946", arabic: 16...23, english: [0...21])),
            .longOnly(.hadith("bukhari:4897", cite: "Saheeh al-Bukhaari 4897, Saheeh Muslim 2546", arabic: 52...80, english: [56...100])),
            .longOnly(.door(.prophecy("persia-faith"))),
            .shortOnly(.text("Among the first Persians to find Islam was Salmaan al-Faarisi (may Allah be pleased with him), who, as his biographers relate, was raised in the religion of the Majoos, left it in search of the truth, and reached the Prophet in Madinah.")),
        ]),
        ArticleSection("ONE CREATOR OF LIGHT AND DARKNESS", [
            .text("The sixth surah of the Quran opens with a sentence that answers dualism in its first line:"),
            .ayah("6:1"),
            .text("Light and darkness are not two eternal principles with two authors. Both are made, by one Maker. The classical commentators saw in the verse an answer to the dualists, who held light and darkness to be two eternal powers, and the point does not depend on their reading: the verse places darkness itself among the things Allah made."),
            .longOnly(.text("A Hebrew prophet once addressed a Persian king in a similar spirit. The Book of Isaiah speaks to Cyrus, who freed the Jews from Babylon, and has God say: “I form the light, and create darkness: I make peace, and create evil: I the LORD do all these things” (Isaiah 45:7, King James Version). Whatever one makes of that book’s history, the thought is clear: there is no second power behind the darkness.")),
            .longOnly(.text("Reason says the same. Two gods, each independent and each creating, would each hold on to what it made and strive against the other, and the single order we see would never have held together:")),
            .longOnly(.ayah("23:91", words: 10...19)),
            .longOnly(.text("The dualist tells the story of exactly such a war, and then lives in a world that is one world, under one set of laws, where the same sun rises on the good and the wicked. A cosmos with two rival authors would show the seam. Ours shows one design (67:3-4).")),
            .longOnly(.ayah("67:3-4")),
            .text("Zoroastrians who say that Ahura Mazda alone is God and the destructive spirit a lesser, doomed power have come a long way toward the answer. The remaining step is to ask where that lesser power came from. If it is uncreated, there are two eternal beings, and the dualism remains. If it was created, it was created by the one Lord, and it acts only within His permission. Islam takes the second path, and the Quran tells the story plainly."),
        ]),
        ArticleSection("SATAN IS A CREATURE, NOT A RIVAL", [
            .text("Iblees is no twin of God. He is one of the jinn, who are made from fire (15:27)."),
            .ayah("15:27"),
            .longOnly(.text("He refused the command to prostrate to Aadam out of pride:")),
            .longOnly(.ayah("18:50", words: 0...14)),
            .text("He asked for respite until the Day of Resurrection and it was granted, so his power is bounded by the One who granted it (7:14-15)."),
            .ayah("7:14-15"),
            .longOnly(.text("He creates nothing: not a disease, not a serpent, not one grain of the darkness the Bundahishn assigns him. All he has is whispering and invitation, and the Quran records his own confession of it on the Day:")),
            .longOnly(.ayah("14:22", words: 12...22)),
            .longOnly(.text("And it limits even that:")),
            .longOnly(.ayah("16:99-100")),
            .shortOnly(.text("He creates nothing: not a disease, not a serpent, not one grain of the darkness the Bundahishn assigns him. All he has is whispering and invitation.")),
            .text("Why, then, does evil exist at all, if one good Lord made everything? Here Islam gives a deeper answer than dualism. The Prophet (peace be upon him) used to say in his night prayer:"),
            .hadith("muslim:771a", cite: "Saheeh Muslim 771", arabic: 111...119, english: [142...161]),
            .longOnly(.markdown("The Arabic goes on: **wash-sharru laysa ilayk**, “and evil is not to be ascribed to You.” Allah creates all things (6:102, 37:96), and among them are pain, loss and the jinn who whisper. But nothing He does is evil. Ibn al-Qayyim (may Allah have mercy on him) explains the distinction in his book on the decree, Shifaa’ al-Aleel: evil lies in certain created things taken on their own, not in Allah’s act of creating them, which is wholly wise and just. A fire that burns a hand harms the hand; a world with fire in it, and with choices that matter, is good. A test needs a tempter (67:2), and the tempter, for all his rebellion, serves a plan he hates.")),
            .shortOnly(.text("The Arabic goes on: “and evil is not to be ascribed to You.” Allah creates all things, but nothing He does is evil. As Ibn al-Qayyim (may Allah have mercy on him) explains, evil lies in certain created things taken on their own, not in Allah’s act of creating them, which is wholly wise and just. A test needs a tempter, and the tempter, for all his rebellion, serves a plan he hates.")),
            .longOnly(.ayah("6:102")),
            .longOnly(.ayah("37:96")),
            .longOnly(.ayah("67:2")),
            .longOnly(.text("Muslims met a version of the same error inside their own community. When some denied that Allah decrees and creates the deeds of His servants, the scholars recalled the Prophet’s words that the Qadariyyah are the Majoos of this community (Sunan Abi Daawood 4691; graded hasan by al-Albaani), because, like the Majoos, they set up a second creator beside Allah.")),
            .longOnly(.hadith("abudawud:4691", cite: "Sunan Abi Daawood 4691; graded hasan by al-Albaani", arabic: 27...30, english: [4...11])),
            .door(.article("QadarView")),
        ]),
        ArticleSection("FIRE, LIGHT AND THE DIRECTION OF PRAYER", [
            .longOnly(.text("Outsiders have long called Zoroastrians fire-worshippers, and Zoroastrians reject the name. They pray facing a source of light, the sun, a hearth or a temple fire, because fire is the purest of Ahura Mazda’s creations and the sign of truth. The fire of the great temples, the Atash Bahram, is consecrated with long rites and kept burning without a break; the one at Udvada in Gujarat is said to have burned for more than a thousand years. In their own understanding they worship Ahura Mazda in the presence of fire, as a Muslim prays toward the Ka‘bah without worshipping its stones.")),
            .shortOnly(.text("Outsiders have long called Zoroastrians fire-worshippers, and Zoroastrians reject the name. They pray facing a source of light because fire is the purest of Ahura Mazda’s creations, and in their own understanding they worship Ahura Mazda in the presence of fire, as a Muslim prays toward the Ka‘bah without worshipping its stones.")),
            .text("The comparison is fair as far as it goes. A Muslim does face a building, and kisses a stone in the Hajj. But Islam surrounds those acts with fences that point away from the object. The qiblah is a direction set by command, not a symbol of the divine nature; the Ka‘bah is not light, nor purity, nor any part of Allah. When Umar (may Allah be pleased with him) kissed the Black Stone, he said so to its face:"),
            .hadith("bukhari:1597", cite: "Saheeh al-Bukhaari 1597, Saheeh Muslim 1270", arabic: 22...46, english: [0...42]),
            .longOnly(.text("With the sun, the brightest of all lights, the Sunnah goes further. It forbids prayer at the very moments when sun-worshippers bow to it:")),
            .longOnly(.hadith("muslim:832", cite: "Saheeh Muslim 832", arabic: 275...297, english: [442...480])),
            .longOnly(.text("A Muslim at sunrise is told to wait, so that not even the outward form of his prayer resembles the worship of light. What the Majoosi treats as a sign of God, the Quran treats as a sign from God, to be looked at and reflected on and never bowed to (41:37).")),
            .shortOnly(.text("What the Majoosi treats as a sign of God, the Quran treats as a sign from God, to be looked at and reflected on and never bowed to:")),
            .ayah("41:37", words: 6...18),
            .longOnly(.text("The verse that follows the mention of the Majoos says that the sun, the moon and the stars themselves prostrate to Allah:")),
            .longOnly(.ayah("22:18", words: 0...14)),
            .longOnly(.callout("The story that the sacred fire of the Persians, kept burning for a thousand years, went out on the night the Prophet (peace be upon him) was born, and that the palace of Kisra cracked, is told in some books of seerah, but its chain is weak, so it is not told here as history.", title: "A Note", icon: "exclamationmark.circle.fill")),
        ]),
        ArticleSection("THE BRIDGE AND THE JUDGMENT, COMPARED FAIRLY", [
            .longOnly(.markdown("Zoroastrianism teaches a judgment after death. On the fourth morning the soul comes to the **Chinvat Bridge**, the Bridge of the Separator. There it meets its own conscience (daena), in the form of a beautiful maiden or a hideous hag according to its deeds; its good and evil are weighed; and the bridge becomes broad for the righteous, who cross to the House of Song, and narrow as a blade for the wicked, who fall into the House of the Lie. At the end of time a saviour, the Saoshyant, will come, the dead will rise, and the world will be made new.")),
            .shortOnly(.text("Zoroastrianism teaches a judgment after death. The soul comes to the Chinvat Bridge, its good and evil are weighed, and the bridge becomes broad for the righteous and narrow as a blade for the wicked, who fall. At the end of time a saviour will come, the dead will rise, and the world will be made new. A Muslim hears echoes here: the Siraat over Jahannam, the scales, the Resurrection.")),
            .longOnly(.text("A Muslim hears echoes here: the Siraat over Jahannam, the scales, the Resurrection. The Prophet (peace be upon him) described the bridge:")),
            .longOnly(.hadith("muslim:183a", cite: "Saheeh Muslim 183", arabic: 386...445, english: [640...761])),
            .longOnly(.text("Abu Sa‘eed al-Khudri (may Allah be pleased with him), who narrated it, added that he had learned the bridge is thinner than a hair and sharper than a sword (Saheeh Muslim 183).")),
            .longOnly(.text("Critics sometimes argue that Islam borrowed these ideas from Persia. Three facts weigh against it. The Prophet lived among Arabs, not Persians, and no one in Makkah was reading Avestan, a language few but Persian priests could read. The detailed pictures of the bridge, the weighing and the renewal of the world come mostly from the Middle Persian books of the ninth and tenth centuries CE, two and three hundred years after the Quran, while the Gathas mention the bridge only in passing. And likeness is exactly what the Quran leads us to expect, because Allah sent a warner to every nation:")),
            .shortOnly(.text("Critics sometimes argue that Islam borrowed these ideas from Persia. But no one in Makkah was reading Avestan, and the detailed pictures of the bridge and the weighing come mostly from Middle Persian books written two and three hundred years after the Quran. Likeness is what the Quran leads us to expect, because Allah sent a warner to every nation:")),
            .ayah("35:24", words: 5...11),
            .longOnly(.text("The memory of a true teaching about judgment can survive among a people long after its source is forgotten and the theology around it has been bent.")),
            .longOnly(.text("That also answers a question Muslims often ask: was Zarathustra a prophet? The honest answer is that we do not know. Neither the Quran nor the authentic Sunnah names him, and a prophet is affirmed only by revelation, since Allah told us of some messengers and not of others (40:78). If he was one, he taught the worship of one Lord, and the dualism of later centuries is what became of his message, as happened to the messages of others. If he was not, whatever rings true in his teaching is a remnant of what true messengers had taught. Either way, the judgment he spoke of is real, and the way to cross the bridge safely is the way the last Prophet taught.")),
            .shortOnly(.text("Was Zarathustra a prophet, then? The honest answer is that we do not know. Neither the Quran nor the authentic Sunnah names him, and a prophet is affirmed only by revelation. If he was one, the dualism of later centuries is what became of his message; if he was not, whatever rings true in his teaching is a remnant of what true messengers had taught. Either way, the judgment he spoke of is real, and the way to cross the bridge safely is the way the last Prophet taught.")),
            .longOnly(.ayah("40:78", words: 0...13)),
            .door(.article("ReligionsMethodView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Why does the Quran list the Majoos apart from the idolaters?**")),
            .longOnly(.text("Because they are a distinct people with a distinct doctrine, neither People of the Book nor the idol-worshippers of Arabia. The verse makes no promise to any of the groups it names; it says only that Allah will judge between them on the Day of Resurrection, and the Quran has already said which religion He accepts (3:85).")),
            .longOnly(.ayah("3:85")),
            .markdown("**May a Muslim celebrate Nowruz?**"),
            .text("Nowruz, the Persian New Year at the spring equinox, is a holy day for Zoroastrians and a national custom for many Iranians and Central Asians. When the Prophet (peace be upon him) came to Madinah he found its people with two days of festival from before Islam, and he replaced them:"),
            .hadith("abudawud:1134", cite: "Sunan Abi Daawood 1134; graded saheeh by al-Albaani", arabic: 11...55, english: [0...71]),
            .text("On this basis Ibn Taymiyyah (may Allah have mercy on him), in Iqtidaa’ as-Siraat al-Mustaqeem, counted Nayrooz and Mihrajaan among the festivals of the Majoos that Muslims do not take as their own. A Muslim may welcome the spring and keep good relations with his neighbours; his festivals are the two that Allah gave him."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Zoroastrianism grew from the hymns of an ancient Iranian prophet and became the faith of an empire, with a good Lord, a destructive spirit, sacred fire and a bridge of judgment. Islam answers that one Lord made the light and the darkness, that Satan is a creature with no power to create and no authority but invitation, that the light is a sign to reflect on and never to bow to, and that the judgment is real. The Prophet (peace be upon him) foretold the fall of Kisra’s empire, and its people, led by Salmaan, found in Islam the one Lord their ancestors’ hymns had reached for."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Al-Majoos", arabic: "المَجُوس", meaning: "The **Zoroastrians**, named after the Magi, their priestly caste. The Quran names them in 22:17; the Prophet (peace be upon him) took the jizyah from the Majoos of Haajar (Saheeh al-Bukhaari 3156)."),
            .term("Ath-Thanawiyyah", arabic: "الثَّنَوِيَّة", meaning: "The **dualists**: those who hold that the world comes from two eternal principles, light and darkness, or good and evil. The opening of Surat al-An‘aam (6:1) answers them: Allah made both."),
            .term("As-Siraat", arabic: "الصِّرَاط", meaning: "The **bridge** set over Jahannam on the Day of Resurrection, which every person must cross, the believers at speeds according to their deeds (Saheeh Muslim 183)."),
            .term("Jizyah", arabic: "جِزيَة", meaning: "A **tax** paid by non-Muslims living under Muslim rule, in return for protection and exemption from military service. The Prophet (peace be upon him) accepted it from the Majoos as from the People of the Book."),
        ]),
    ]
}

struct ReligionsEastAsiaView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsEastAsiaView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering Confucianism, Taoism and Shinto")
        .englishArticle().selectableArticleList(article: "ReligionsEastAsiaView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the religions of China and Japan grew without a founder who claimed a revelation from the Creator. Confucius taught a humane ethics rooted in Heaven, family and rite; Taoism sought harmony with the nameless Way and, in its religious form, bodily immortality; Shinto honours countless kami at its shrines and once made the emperor divine. Islam shares their reverence for parents and for order, and answers that Heaven and the Way have a Maker who has names and speaks, that the dead are prayed for and not prayed to, that ethics needs a Lawgiver and a Day of account, and that immortality lies beyond death, not before it. Islam itself reached China within decades of the Prophet."),
        ]),
        ArticleSection("CONFUCIUS AND HEAVEN", [
            .longOnly(.markdown("Kong Qiu, honoured as Kongzi or Kong Fuzi (“Master Kong”) and known in the West as **Confucius**, lived from 551 to 479 BCE in the small state of Lu, in what is now Shandong. He was a teacher and minor official in an age of warring states, and he believed the cure for disorder lay in the ways of the early Zhou kings: rulers who governed by virtue, sons who honoured fathers, and rites performed with sincerity. His sayings were gathered by his disciples into the **Analects**.")),
            .longOnly(.text("His key ideas are few and deep. Ren, humaneness, is the virtue of a fully human person. Li, ritual propriety, is the outward form that trains it, from the bow of greeting to the sacrifices for the dead. Xiao, filial piety, is its root: love and service of parents in life, mourning and offerings after death. Society rests on five relationships, ruler and subject, father and son, husband and wife, elder and younger brother, friend and friend, each with its duties. The ideal is the junzi, the noble person, made noble by character rather than birth. And he summed up much of it in a rule that Muslims will recognise: what you do not want done to yourself, do not do to others (Analects, book 15).")),
            .longOnly(.text("Confucius spoke of Heaven (Tian) with reverence. He said that Heaven had produced the virtue in him (Analects, book 7), and that one who offends against Heaven has no one left to pray to (book 3). Under the earlier Shang kings the high god had been called Shangdi, the Lord on High, and the Zhou kings ruled by the Mandate of Heaven, which passed to a new dynasty when a ruler lost his virtue. Yet Confucius would not be drawn into speaking of the unseen. When a disciple asked about serving the spirits of the dead, he replied, in James Legge’s translation, “While you are not able to serve men, how can you serve their spirits?”, and when asked about death, “While you do not know life, how can you know about death?” (Analects, book 11).")),
            .longOnly(.text("After him, Mencius (c. 372–289 BCE) taught that human nature is good, and the Neo-Confucian Zhu Xi (1130–1200) gave the tradition a metaphysics built on principle and vital energy rather than on a personal God. For two thousand years Confucian learning was the curriculum of China’s officials, until the imperial examinations ended in 1905. The emperor offered sacrifice to Heaven at the winter solstice at the Temple of Heaven in Beijing, and every family honoured its ancestors with tablets, incense and offerings, as many still do at the Qingming festival, when the graves are swept.")),
            .shortOnly(.text("Confucius (551–479 BCE) was a teacher in an age of warring states who believed the cure for disorder lay in the ways of the early Zhou kings. His key ideas are humaneness (ren), ritual propriety (li) and filial piety (xiao), and he summed up much of them in a rule Muslims will recognise: what you do not want done to yourself, do not do to others. He spoke of Heaven (Tian) with reverence, yet would not be drawn into speaking of the unseen or of death. For two thousand years his learning was the curriculum of China’s officials, and every family honoured its ancestors with tablets, incense and offerings.")),
        ]),
        ArticleSection("LAOZI, THE WAY AND THE SEARCH FOR IMMORTALITY", [
            .longOnly(.markdown("Taoism (also spelled Daoism) traces itself to **Laozi**, the “Old Master”, said to have been an archivist at the Zhou court and an older contemporary of Confucius. Whether he lived at all is uncertain, and the book under his name, the **Tao Te Ching**, about five thousand Chinese characters in eighty-one short chapters, was probably compiled over time; the oldest copies, on bamboo slips found at Guodian, date from about 300 BCE. Beside it stands the Zhuangzi, the playful and searching book of Zhuang Zhou (fourth century BCE).")),
            .longOnly(.markdown("The **Tao** means “the Way”. It is the source and pattern of all things, prior to Heaven and Earth, and it cannot be named or grasped: the book opens by saying that the Way which can be spoken of is not the constant Way, and later says that its author does not know its name and calls it the Way for want of one. It acts without striving, and the sage imitates it through **wu wei**, non-forcing action, yielding like water, which wears away the hard by giving way. The book teaches simplicity, humility and few desires, and treats the interplay of opposites, later pictured as yin and yang, as the rhythm of the world. One chapter says that Heaven and Earth are not humane, and treat the ten thousand things as straw dogs: the straw figures used in a sacrifice and then thrown away.")),
            .longOnly(.text("Religious Taoism grew out of this and differs from the philosophy as a church differs from a book. From the second century CE, when Zhang Daoling founded the Way of the Celestial Masters, it had priests, scriptures, temples and a vast heaven of deities, headed in popular belief by the Jade Emperor and the Three Pure Ones. It also had a goal the philosophers did not: to escape death. Adepts sought to become immortals (xian) through breathing exercises, diet, meditation and alchemy, and emperors chased the same prize. Qin Shi Huang, the first emperor of China, sent expeditions across the eastern sea for the herb of immortality and died in 210 BCE, at forty-nine. Several emperors of the Tang dynasty are recorded to have died after taking elixirs made with mercury and lead.")),
            .shortOnly(.text("Taoism traces itself to Laozi, the “Old Master”, and the book under his name, the Tao Te Ching. The Tao means “the Way”: the source and pattern of all things, which cannot be named or grasped, and which the sage imitates through wu wei, non-forcing action. One chapter says that Heaven and Earth are not humane, and treat the ten thousand things as straw dogs. Religious Taoism added priests, temples and a vast heaven of deities, and a goal the philosophers did not have: to escape death through breathing, diet and alchemy. Several emperors are recorded to have died after taking elixirs made with mercury and lead.")),
        ]),
        ArticleSection("SHINTO, THE KAMI AND THE EMPEROR", [
            .longOnly(.markdown("Shinto, “the way of the kami”, is the native religion of Japan. It has no founder, no single scripture and no fixed creed. Its centre is the **kami**: powers held worthy of reverence that dwell in mountains, rivers, great trees and rocks, in the sun and the rain, in the ancestors of clans, and in great men after their death. The Japanese speak of “eight million kami”, meaning countless. They are honoured at shrines marked by the torii gate, with purification by water, offerings of rice and sake, bows and clapping, and seasonal festivals in which the kami is carried through the streets. Many homes keep a small shelf shrine, the kamidana.")),
            .longOnly(.markdown("The oldest written accounts, the **Kojiki** (712 CE) and the **Nihon Shoki** (720 CE), tell how the divine pair Izanagi and Izanami formed the islands of Japan, and how the sun goddess Amaterasu sent her grandson down to rule them. The imperial house traced its descent from her through a first emperor, Jimmu, whom the chronicles date to 660 BCE, and her shrine at Ise remains the holiest in the land. From the Meiji restoration of 1868 the state organised shrine worship into a national cult with the emperor at its head, and soldiers died believing him a living god. On 1 January 1946, after Japan’s defeat, Emperor Hirohito issued a rescript rejecting the idea that the emperor is divine.")),
            .longOnly(.text("Shinto today lives alongside Buddhism. Most Japanese visit a shrine at the New Year and for births and weddings, and a Buddhist temple for funerals, and many would not call themselves religious at all.")),
            .shortOnly(.text("Shinto, “the way of the kami”, is the native religion of Japan, with no founder, no single scripture and no fixed creed. The kami are powers held worthy of reverence in mountains, rivers, the sun and the ancestors, honoured at shrines with purification, offerings and bows. The imperial house traced its descent from the sun goddess Amaterasu, and from 1868 the state made the emperor a living god, until Emperor Hirohito rejected the idea in 1946.")),
            .door(.article("BuddhismAnswerView")),
        ]),
        ArticleSection("HEAVEN HAS A MAKER, AND HE HAS NAMES", [
            .text("Each of these traditions reaches toward something above the world: Heaven, the Way, the kami of the sun. Islam’s first answer is that the highest thing they name is either a creature, or the Creator described too vaguely to be known and worshipped. Heaven, the sky above us, is made, and will be rolled up like a scroll (21:104)."),
            .ayah("21:104", words: 0...5),
            .longOnly(.text("The sun is a sign, not a goddess:")),
            .longOnly(.ayah("41:37")),
            .longOnly(.text("The Way, if it means the order of the world, is real and beautiful, and the Quran calls on us to study it. But an order does not order itself. The Quran names the One it comes from:")),
            .longOnly(.ayah("6:101-102")),
            .shortOnly(.text("The Way, if it means the order of the world, is real and beautiful. But an order does not order itself.")),
            .text("The Tao Te Ching says the true Way has no name. The Quran says the true Lord has the most beautiful names, and has made them known so that we can call on Him by them:"),
            .ayah("7:180", words: 0...4),
            .text("That is the gap between the sage and the prophet. The sage looks at the world, sees its pattern, and admits he cannot name its source. The prophet is told the name by the Source Himself. A Way that does not hear, see, speak or show mercy cannot be thanked or asked. Allah is ar-Rahman, and His mercy is the very thing the chapter of the straw dogs denies to Heaven and Earth:"),
            .hadith("bukhari:6000", cite: "Saheeh al-Bukhaari 6000, Saheeh Muslim 2752", arabic: 26...54, english: [6...62]),
            .longOnly(.text("Nor was East Asia left without the truth. The Quran says that a warner came to every nation (35:24), and it is not far-fetched that the reverence for Heaven and the Lord on High in China’s oldest records is a memory of a message its people once received. A Muslim need not claim Confucius or Laozi as prophets, and should not, since revelation does not name them. It is enough to say that every human being was made to know his Lord (30:30), and that the purest parts of these traditions are reaching for Him.")),
            .longOnly(.ayah("35:24", words: 5...11)),
            .longOnly(.ayah("30:30", words: 4...9)),
            .shortOnly(.text("Nor was East Asia left without the truth. A Muslim need not claim Confucius or Laozi as prophets, and should not, since revelation does not name them; it is enough to say that the purest parts of these traditions are reaching for the Lord every human being was made to know.")),
        ]),
        ArticleSection("ANCESTORS, KAMI AND INTERCESSION", [
            .text("Few practices are as moving, or as widespread in East Asia, as the honouring of ancestors. Before a family altar or a grave the living bow, burn incense, set out food, report the family’s news and ask the dead for protection. Many Confucians say these rites are memory and gratitude, not worship, and some of them are no more than that. But when the dead or the kami are asked to grant help, protection, healing or children, the act has crossed into dua, and dua is worship."),
            .text("The Quran describes this crossing in the words of those who made it:"),
            .ayah("39:3", words: 4...15),
            .longOnly(.ayah("10:18")),
            .longOnly(.text("And it says what the invoked can do for those who call on them:")),
            .longOnly(.ayah("46:5-6")),
            .longOnly(.text("The Prophet Muhammad (peace and blessings be upon him) explained how this begins, in the story of the first idols on earth, which were memorials to good men:")),
            .longOnly(.hadith("bukhari:4920", cite: "Saheeh al-Bukhaari 4920", arabic: 60...91, english: [76...152])),
            .longOnly(.text("The same path appears in every culture: love for the righteous dead, then images to remember them, then requests, then worship. It is why the Prophet (peace be upon him) warned against building places of worship over the graves of the righteous and painting their pictures inside (Saheeh al-Bukhaari 427), and against making his own grave a place of festival (Sunan Abi Daawood 2042; graded saheeh by al-Albaani).")),
            .longOnly(.hadith("bukhari:427", cite: "Saheeh al-Bukhaari 427, Saheeh Muslim 528", arabic: 14...56, english: [0...69])),
            .longOnly(.hadith("abudawud:2042", cite: "Sunan Abi Daawood 2042; graded saheeh by al-Albaani", arabic: 30...44, english: [4...33])),
            .shortOnly(.text("The same path appears in every culture: love for the righteous dead, then images to remember them, then requests, then worship.")),
            .longOnly(.text("Islam does not ask anyone to forget his parents. It makes honouring them the next duty after worshipping Allah (17:23-24).")),
            .longOnly(.ayah("17:23-24")),
            .longOnly(.text("And it gives the living a way to keep serving them after death that never turns into worship of them:")),
            .shortOnly(.text("Islam does not ask anyone to forget his parents. It makes honouring them the next duty after worshipping Allah, and it gives the living a way to keep serving them after death that never turns into worship of them:")),
            .hadith("muslim:1631", cite: "Saheeh Muslim 1631", arabic: 37...58, english: [0...30]),
            .longOnly(.text("The Prophet (peace be upon him) himself visited the grave of his mother and wept there:")),
            .longOnly(.hadith("muslim:976b", cite: "Saheeh Muslim 976", arabic: 25...60, english: [0...65])),
            .longOnly(.text("He was allowed to visit and to grieve, though not to ask forgiveness for her, and a Muslim whose parents died outside Islam may likewise visit their graves to remember death, without praying for their forgiveness (9:113). So the Muslim stands at a grave as a Confucian son does, with grief, gratitude and remembrance. But he faces the qiblah, not the tombstone, and he asks Allah, never the dead.")),
            .longOnly(.ayah("9:113")),
            .shortOnly(.text("So the Muslim stands at a grave as a Confucian son does, with grief, gratitude and remembrance. But he faces the qiblah, not the tombstone, and he asks Allah, never the dead.")),
            .door(.article("PaganismAnswerView")),
        ]),
        ArticleSection("ETHICS WITHOUT A LAWGIVER", [
            .text("Confucian ethics is one of the great moral achievements of humanity, and a Muslim should say so. Its love of parents, its respect for learning, its insistence that a ruler must be virtuous, and its rule of reciprocity all have their counterparts in Islam. The Prophet (peace be upon him) put reciprocity at the heart of faith itself:"),
            .hadith("bukhari:13", cite: "Saheeh al-Bukhaari 13, Saheeh Muslim 45a", arabic: 39...47, english: [4...21]),
            .longOnly(.text("But Confucius described himself as a transmitter and not a maker, one who believed in and loved the ancients (Analects, book 7). His authority is the authority of the past and of the sage’s example. Ask why one ought to honour one’s parents, and the Confucian answers that this is the way of Heaven and of the former kings, that it makes families and states flourish, and that the noble person feels it. Those are good reasons, but they leave two questions open. Who decides when the traditions disagree, as Mencius and Xunzi disagreed about human nature itself? And what of the man who does wrong in secret and dies unpunished, or the son who honours his parents and dies poor and forgotten?")),
            .shortOnly(.text("But Confucius described himself as a transmitter and not a maker. Ask why one ought to honour one’s parents, and the Confucian answers that this is the way of Heaven and of the former kings. That leaves two questions open: who decides when the traditions disagree, and what of the man who does wrong in secret and dies unpunished?")),
            .text("Islam answers both. The command comes from the One who made human nature and knows it, and the account is settled on a Day when nothing is hidden and nothing is too small to be weighed:"),
            .ayah("99:7-8"),
            .text("Confucius was silent about death because he did not know, and he was honest to say so. The Quran is not silent, because its Author does know. The question the Master turned aside is the question the Quran answers on almost every page."),
        ]),
        ArticleSection("THE ELIXIR AND THE DEATH OF DEATH", [
            .text("The Taoist search for immortality is one of history’s saddest quests, and one of its most human. The Quran meets it with a plain fact and a greater promise. The fact is this:"),
            .ayah("21:34-35", words: 0...13),
            .longOnly(.text("The Prophet (peace be upon him) made the same point about medicine, which he told his followers to use:")),
            .longOnly(.hadith("abudawud:3855", cite: "Sunan Abi Daawood 3855; graded saheeh by al-Albaani", arabic: 45...60, english: [45...73])),
            .longOnly(.text("Old age is the one disease no elixir cures, because death is not an accident of the body but a decree of its Maker, created for a purpose:")),
            .longOnly(.ayah("67:2", words: 0...7)),
            .longOnly(.text("The promise is that immortality is real, but it lies on the far side of death, not on this side of it. On the Day of Resurrection death itself will be brought out and ended:")),
            .longOnly(.hadith("bukhari:4730", cite: "Saheeh al-Bukhaari 4730, Saheeh Muslim 2849", arabic: 31...86, english: [4...140])),
            .shortOnly(.text("The promise is that immortality is real, but it lies on the far side of death, not on this side of it.")),
            .markdown("The emperors who drank mercury wanted the right thing in the wrong place. **Al-khuld**, eternity, is the name of the garden promised to the righteous (25:15), and the road to it runs through the grave, the Resurrection and the mercy of Allah, not through an alchemist’s furnace."),
            .ayah("25:15"),
            .longOnly(.text("The sage’s wu wei has an Islamic counterpart too, and a correction. The believer trusts Allah completely (tawakkul) and accepts His decree, but he does not stop acting: when a man asked whether he should tie his camel or leave it loose and trust in Allah, the Prophet told him to tie it and trust (Jaami‘ at-Tirmidhi 2517; graded hasan by al-Albaani). Submission in Islam is to a Lord who commands, not to a current that carries.")),
            .longOnly(.hadith("tirmidhi:2517", cite: "Jaami‘ at-Tirmidhi 2517; graded hasan by al-Albaani", arabic: 23...37, english: [0...24])),
        ]),
        ArticleSection("ISLAM IN CHINA AND JAPAN", [
            .text("Islam reached China early. The dynastic history of the Tang records an embassy from the Arabs, whom the Chinese called the Dashi, in 651 CE, during the caliphate of Uthmaan (may Allah be pleased with him). Arab and Persian merchants settled in the southern ports, above all Guangzhou and Quanzhou, where they built mosques, and a ninth-century Arabic account describes a Muslim judge appointed among them with the emperor’s permission."),
            .longOnly(.text("Under the Mongol Yuan dynasty (1271–1368), Muslims from Central Asia served as officials across China; Sayyid Ajall Shams ad-Deen, governor of Yunnan, is remembered there for his justice. Ibn Battootah visited Quanzhou in the 1340s and found Muslims living in their own quarter with mosques and a qaadi. Under the Ming, the Muslim admiral Zheng He (1371–1433) led seven great voyages across the Indian Ocean. Chinese-speaking Muslims, the Hui, took Chinese names and dress, and from the seventeenth century scholars such as Wang Daiyu and Liu Zhi wrote books explaining Islam in the vocabulary of Chinese learning. In the late nineteenth century Ma Wanfu, returning from study in Makkah, began a movement calling Chinese Muslims back to the Quran and the Sunnah and away from customs borrowed from their neighbours.")),
            .longOnly(.text("Today China has more than twenty million Muslims, chiefly the Hui and the Turkic-speaking Uyghurs and Kazakhs of the northwest, and in recent decades they have faced severe restrictions on their religious life. In Japan the story is short and recent: a few Japanese embraced Islam around the turn of the twentieth century, the first mosque opened at Kobe in 1935, and the community has grown since through students, workers and converts.")),
            .longOnly(.callout("The saying “Seek knowledge, even in China” is often quoted in this connection, but the hadith critics judged it false: Ibn al-Jawzi listed it among fabricated reports, and al-Albaani called it baseless. It is not attributed to the Prophet (peace be upon him) here.", title: "A Note", icon: "exclamationmark.circle.fill")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**May a Muslim bow at a shrine or a family altar out of courtesy?**"),
            .text("No. Bowing to a kami, an altar, an ancestral tablet or an image as part of its rite is an act of worship directed to other than Allah, even when it is meant as politeness. Respect is shown to the people, by good manners, kindness and attending to their needs, not by joining their rite. A Muslim can stand with a grieving family and comfort them without taking part in it."),
            .longOnly(.markdown("**Was Confucius a prophet?**")),
            .longOnly(.text("Nothing in the Quran or the Sunnah names him, so a Muslim neither affirms nor denies it. Allah sent messengers to every nation and told us of only some of them (40:78). Confucius himself claimed no revelation; he called himself a transmitter of the ancients. Whatever is true in his teaching agrees with what the prophets brought, and what the prophets brought, he lacked: the names of the Lord he called Heaven, and knowledge of what comes after death.")),
            .longOnly(.ayah("40:78", words: 0...13)),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Confucius honoured Heaven and the family, Laozi sought the nameless Way, and Shinto bows to the kami and once to the emperor. Islam honours what is true in all of them, the duty to parents, the order of the world, the reverence for what is above us, and completes it: Heaven has a Creator, and He has told us His names; the dead are prayed for, not prayed to; right and wrong are commanded by the Lawgiver and settled on the Day; and eternity is found after death, by His mercy. The way to it reached China within a generation of the Prophet, and it is still open."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Dua", arabic: "دُعَاء", meaning: "**Supplication**: calling on Allah for help, forgiveness or any need. The Quran counts it as worship (40:60), so asking the dead, the kami or any creature for what only Allah can give is worship directed to other than Him."),
            .ayah("40:60"),
            .term("Shafaa‘ah", arabic: "شَفَاعَة", meaning: "**Intercession**: a request on behalf of another. It belongs wholly to Allah (39:44) and happens only with His permission (2:255); it is sought from Him, not from those who are hoped to intercede."),
            .ayah("39:44"),
            .ayah("2:255", words: 19...25),
            .term("Birr al-Waalidayn", arabic: "بِرّ الوَالِدَين", meaning: "**Kindness and duty to parents**, which the Quran places next to the worship of Allah (17:23). After their death it continues as prayer for them, charity on their behalf and keeping their ties of kinship."),
            .term("Al-Khuld", arabic: "الخُلد", meaning: "**Eternity**, life without end. Allah gave it to no human in this world (21:34); it is the name of the garden promised to the righteous (25:15)."),
        ]),
    ]
}

struct ReligionsNewProphetsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ReligionsNewProphetsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering the Ahmadiyyah, the Baha’is and the Nation of Islam")
        .englishArticle().selectableArticleList(article: "ReligionsNewProphetsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: three movements of the last two centuries call themselves Islamic, or the fulfilment of Islam, while claiming a prophet, a new Manifestation of God, or God in person after the Prophet Muhammad (peace and blessings be upon him). The Ahmadiyyah follow Mirza Ghulam Ahmad of Qadian as the promised Messiah and, most of them, as a prophet; the Baha’is follow Baha’u’llah as the latest Manifestation of God, with a new book of laws; the Nation of Islam taught that Allah appeared as a man in Detroit and that Elijah Muhammad was His messenger. The Quran’s word that Muhammad is the Seal of the Prophets, the Prophet’s own explanation of it, and his description of the return of Eesa answer all three, and the scholars of Islam are agreed that each of these beliefs lies outside the religion."),
        ]),
        ArticleSection("THE SEAL, AS THE PROPHET EXPLAINED IT", [
            .text("Every one of these movements has to deal with one verse:"),
            .ayah("33:40", words: 7...11),
            .text("The Ahmadiyyah read khaatam as a seal of authentication: Muhammad is the best of the prophets, whose stamp makes later prophets genuine. The Baha’is accept that he was the last prophet, but say that a new age has begun beyond prophethood, with a messenger of a different kind. Neither reading survives the Prophet’s own words. He described his place in the line with a parable:"),
            .hadith("bukhari:3535", cite: "Saheeh al-Bukhaari 3535, Saheeh Muslim 2286", arabic: 34...67, english: [4...70]),
            .text("A brick that completes a wall does not stamp further bricks; it closes the gap, and after it there is no gap. He also answered in advance the precise claim the Ahmadiyyah make, that a prophet could still come who brings no new law and only follows the old one:"),
            .hadith("bukhari:3455", cite: "Saheeh al-Bukhaari 3455, Saheeh Muslim 1842", arabic: 34...50, english: [4...40]),
            .longOnly(.text("The prophets who followed one another among Bani Israa’eel, such as Daawood, Sulaymaan, Zakariya and Yahya (peace be upon them), brought no new law; they judged by the Torah of Moosa (peace be upon him). That is exactly the kind of prophet he said would not come after him. When he left Ali (may Allah be pleased with him) in charge of Madinah, he compared him to Haaroon, Moosa’s helper, a prophet without a law of his own, and excluded even that:")),
            .longOnly(.hadith("bukhari:4416", cite: "Saheeh al-Bukhaari 4416, Saheeh Muslim 2404", arabic: 34...47, english: [31...53])),
            .longOnly(.text("What remains of prophethood after him, he said, is only the good dream:")),
            .longOnly(.hadith("bukhari:6990", cite: "Saheeh al-Bukhaari 6990", arabic: 24...37, english: [6...28])),
            .longOnly(.text("And he foretold that men would claim it anyway. The Hour will not come, he said, until about thirty liars appear, each claiming to be a messenger of Allah (Saheeh al-Bukhaari 3609); in Thawbaan’s narration he added that he is the seal of the prophets and there is no prophet after him (Sunan Abi Daawood 4252; graded saheeh by al-Albaani). Two of them, Musaylimah in al-Yamaamah and al-Aswad al-Ansi in Yemen, rose before he died.")),
            .longOnly(.hadith("bukhari:3609", cite: "Saheeh al-Bukhaari 3609, Saheeh Muslim 157", arabic: 41...55, english: [43...67])),
            .longOnly(.hadith("abudawud:4252", cite: "Sunan Abi Daawood 4252; graded saheeh by al-Albaani", arabic: 156...171, english: [230...265])),
            .longOnly(.door(.prophecy("false-prophets"))),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) drew the conclusion in his commentary on the verse:")),
            .longOnly(.quote(text: "“This verse is a clear text that there is no prophet after him. And if there is no prophet after him, then all the more so there is no messenger after him, because the station of messengership is more particular than the station of prophethood: every messenger is a prophet, and not the reverse. … Allah has told in His Book, and His Messenger in the mutawaatir Sunnah from him, that there is no prophet after him, so that people would know that everyone who claims this station after him is a liar, a fabricator, a deceiver, astray and leading others astray.” (Ibn Katheer, Tafseer al-Quran al-Azeem, on 33:40)", arabic: "فَهَذِهِ الآيَةُ نَصٌّ فِي أَنَّهُ لَا نَبِيَّ بَعدَهُ، وَإِذَا كَانَ لَا نَبِيَّ بَعدَهُ فَلَا رَسُولَ بَعدَهُ بِطَرِيقِ الأَولَى وَالأَحرَى؛ لِأَنَّ مَقَامَ الرِّسَالَةِ أَخَصُّ مِن مَقَامِ النُّبُوَّةِ، فَإِنَّ كُلَّ رَسُولٍ نَبِيٌّ، وَلَا يَنعَكِسُ … وَقَد أَخبَرَ تَعَالَى فِي كِتَابِهِ، وَرَسُولُهُ فِي السُّنَّةِ المُتَوَاتِرَةِ عَنهُ: أَنَّهُ لَا نَبِيَّ بَعدَهُ؛ لِيَعلَمُوا أَنَّ كُلَّ مَنِ ادَّعَى هَذَا المَقَامَ بَعدَهُ فَهُوَ كَذَّابٌ أَفَّاكٌ، دَجَّالٌ ضَالٌّ مُضِلٌّ", dimmed: true)),
            .door(.article("ProvingContinuationView")),
        ]),
        ArticleSection("MIRZA GHULAM AHMAD AND THE AHMADIYYAH", [
            .longOnly(.text("Mirza Ghulam Ahmad was born in 1835 at Qadian, in the Punjab, to a family of landed gentry. He first became known as a defender of Islam against Christian missionaries and the Hindu reform movement Arya Samaj, in a long work, Baraaheen-e-Ahmadiyyah (1880–1884). He claimed that God spoke to him and had made him the renewer (mujaddid) of the fourteenth Islamic century, and on 23 March 1889, at Ludhiana, he took the first oaths of allegiance: the founding of his movement.")),
            .longOnly(.text("His claims then grew. In 1891 he announced that Eesa (peace be upon him) had died a natural death, and that the Messiah whose return the Prophet foretold was not Eesa son of Maryam himself but one like him: Mirza Ghulam Ahmad. He claimed to be that promised Messiah and the Mahdi in one person, and later, in a lecture at Sialkot in 1904, the Krishna awaited by Hindus. He taught that Eesa had survived the cross, travelled to Kashmir and died there, and identified his grave with a shrine in Srinagar, the Roza Bal, which local tradition assigns to a saint named Yuz Asaf. In 1901, in a tract titled Ek Ghalati ka Izala (“Correction of an Error”), he stated that he was a prophet, though one without a new law: a prophet, he said, by perfect following of Muhammad.")),
            .longOnly(.text("He died at Lahore in 1908, and in 1914 his followers split. The majority, centred at Qadian, later at Rabwah in Pakistan and since 1984 in Britain, hold that he was a prophet and follow a line of caliphs; the fifth, Mirza Masroor Ahmad, has led them since 2003. A minority, the Lahore Ahmadiyyah Movement, hold that he was the promised Messiah but not a prophet. Ahmadis pray five times a day, fast Ramadan, read the Quran and call themselves Muslims, and they are known for their discipline, their missionary work and their motto, “Love for all, hatred for none”.")),
            .longOnly(.text("The scholars of Islam did not accept them as Muslims. In April 1974 a conference of the Muslim World League in Makkah declared the movement outside Islam, and that September Pakistan’s parliament amended its constitution to the same effect. In 1985 the Islamic Fiqh Academy of the Organisation of the Islamic Conference ruled that his claim to prophethood and revelation denies what is known of the religion by necessity, that those who follow him in it have left Islam, and that the Lahori branch shares the ruling, although it calls him only a reflection of the Prophet. The Permanent Committee, Shaykh Ibn Baaz and the great scholars of the subcontinent gave the same verdict.")),
            .shortOnly(.text("Mirza Ghulam Ahmad was born in 1835 at Qadian, in the Punjab, and first became known as a defender of Islam against Christian missionaries. In 1889 he founded his movement, and his claims then grew: that Eesa (peace be upon him) had died a natural death, that he himself was the promised Messiah and the Mahdi in one person, and in 1901 that he was a prophet, though one without a new law. After his death in 1908 his followers split: the majority hold that he was a prophet, while the Lahore branch hold that he was the Messiah but not a prophet. In 1974 a conference of the Muslim World League declared the movement outside Islam, and the great scholars gave the same verdict.")),
        ]),
        ArticleSection("ANSWERING THE AHMADIYYAH", [
            .text("The answer begins where his claims began, with Eesa (peace be upon him). The Quran says that he was neither killed nor crucified but raised to Allah, and that the People of the Book will all believe in him before his death, a death that has not yet come:"),
            .ayah("4:157-159", words: 34...50),
            .longOnly(.text("The Ahmadiyyah argue from the verb tawaffa in 3:55 and 5:117, which they take to mean death. But the Quran uses the same verb for sleep (6:60, 39:42), and its root sense is to take something in full; Ibn Katheer reports under 3:55 that most of the commentators understood it there as the taking of sleep, not death.")),
            .longOnly(.ayah("3:55", words: 0...7)),
            .longOnly(.ayah("5:117", words: 18...19)),
            .longOnly(.ayah("6:60", words: 0...3)),
            .longOnly(.ayah("39:42", words: 0...9)),
            .text("The Prophet (peace be upon him) then described the return in terms that leave no room for a metaphor:"),
            .hadith("bukhari:3448", cite: "Saheeh al-Bukhaari 3448, Saheeh Muslim 155", arabic: 34...65, english: [4...83]),
            .longOnly(.text("In another sound narration he said that Eesa will descend at the white minaret in the east of Damascus and kill the Dajjaal at the gate of Lud (Saheeh Muslim 2937).")),
            .longOnly(.hadith("muslim:2937a", cite: "Saheeh Muslim 2937", arabic: 318...364, english: [506...621])),
            .longOnly(.text("In another, he said that he will decline to lead the Muslims in prayer:")),
            .longOnly(.hadith("muslim:156", cite: "Saheeh Muslim 156", arabic: 42...83, english: [8...73])),
            .longOnly(.text("The one who descends is the son of Maryam, not someone like him. He descends; he is not born in Qadian to another mother. He breaks the cross, ends the jizyah and kills the Dajjaal. And he and the Muslims’ commander are two men, which answers the claim that the Messiah and the Mahdi are one person. The narration Ahmadis cite for that, “There is no Mahdi except Eesa”, was judged munkar and very weak by the hadith critics. The authentic Mahdi is a man of the Prophet’s family who bears his name and his father’s name:")),
            .shortOnly(.text("The one who descends is the son of Maryam, not someone like him. He descends; he is not born in Qadian to another mother. And the authentic Mahdi is a man of the Prophet’s family who bears his name and his father’s name:")),
            .hadith("abudawud:4282", cite: "Sunan Abi Daawood 4282; graded hasan saheeh by al-Albaani", arabic: 70...126, english: [4...65]),
            .longOnly(.text("Mirza Ghulam Ahmad’s name was not Muhammad, his father was Ghulam Murtaza and not Abdullah, and no part of the earth was filled with justice by him. The tomb in Kashmir rests on a medieval tale: the name Yuz Asaf comes from the legend known in Arabic as Bilawhar and Budhasaf, and in Europe as Barlaam and Josaphat, which scholars trace back through Persian and Arabic retellings to the life of the Buddha.")),
            .longOnly(.text("His own predictions gave his contemporaries a further test. On 15 April 1907 he published an announcement addressed to Maulana Thanaullah Amritsari, a scholar of the Ahl al-Hadith who opposed him, praying that whichever of the two was the liar would die in the lifetime of the other. Mirza Ghulam Ahmad died in 1908; Thanaullah lived until 1948. Ahmadis reply that it was a challenge to mutual prayer which Thanaullah declined. But the Quran needs no such contest: a man who claims revelation after the Seal has already contradicted the revelation he says he follows.")),
            .longOnly(.text("Ahmadis also argue from 69:44-47, where Allah says that had Muhammad invented sayings about Him, He would have seized him, and reason that a false claimant would be destroyed quickly. The verse speaks of the Prophet himself; it is not a rule that every liar dies young. And it proves too much: Baha’u’llah, whom they reject, taught for nearly thirty years after his claim, and Elijah Muhammad for over forty.")),
            .longOnly(.ayah("69:44-47")),
            .shortOnly(.text("Mirza Ghulam Ahmad’s name was not Muhammad, his father was Ghulam Murtaza and not Abdullah, and no part of the earth was filled with justice by him.")),
            .door(.prophecy("isa-descends")),
        ]),
        ArticleSection("THE BAB, BAHA'U'LLAH AND THE BAHA’I FAITH", [
            .longOnly(.text("The Baha’i faith grew out of Twelver Shi‘ism in Iran. Twelvers await the return of a hidden twelfth imam, and in the nineteenth century a school called the Shaykhiyyah taught that a living gate to him would appear. On 23 May 1844, in Shiraz, a young merchant named Sayyid Ali Muhammad declared that he was that gate, the Bab. Within a few years he claimed more: that he was the awaited Qaa’im himself, and that he brought a new scripture, the Bayaan, which abrogated the law of the Quran. At a gathering at Badasht in 1848 his follower Tahirih appeared unveiled to announce that the Sharee‘ah had ended. Uprisings and battles with government troops followed, and the Bab was executed by firing squad at Tabriz on 9 July 1850.")),
            .longOnly(.markdown("One of his followers, Mirza Husayn Ali Nuri (1817–1892), took the title **Baha’u’llah**, “the Glory of God”. Imprisoned in Tehran in 1852 after some Babis tried to kill the Shah, and exiled to Baghdaad, he announced in April 1863 that he was the one the Bab had foretold, “Him whom God shall make manifest”. The Ottomans moved him to Istanbul, then Edirne, and finally the prison city of Akka in Palestine, where around 1873 he wrote his book of laws, the **Kitaab-i-Aqdas** (“the Most Holy Book”), in Arabic. It gives the Baha’is their own obligatory prayer, a nineteen-day fast in March, a calendar of nineteen months of nineteen days, and laws of marriage, inheritance and punishment.")),
            .longOnly(.text("He died near Akka in 1892, and Baha’is turn toward his shrine at Bahji when they pray: it is their qiblah. Leadership passed to his son Abdu’l-Baha, then to Shoghi Effendi, and since 1963 to an elected council, the Universal House of Justice, at Haifa. Baha’is teach the oneness of God, of religion and of humanity. God, they say, sends Manifestations age after age, among them Abraham, Moses, Krishna, Zoroaster, the Buddha, Jesus, Muhammad, the Bab and Baha’u’llah, each suited to his time. Baha’u’llah is for them the promised one of every faith, the Mahdi and Messiah of the Muslims and the returning Christ of the Christians.")),
            .shortOnly(.text("The Baha’i faith grew out of Twelver Shi‘ism in Iran. In 1844 a young merchant of Shiraz declared that he was the Bab, the gate to the hidden twelfth imam, and soon claimed a new scripture that abrogated the law of the Quran; he was executed in 1850. One of his followers took the title Baha’u’llah, “the Glory of God”, announced in 1863 that he was the one the Bab had foretold, and wrote a new book of laws, the Kitaab-i-Aqdas, with its own prayer, fast and calendar. Baha’is turn toward his shrine at Bahji when they pray, and teach that God sends Manifestations age after age, of whom Baha’u’llah is the latest.")),
        ]),
        ArticleSection("ANSWERING THE BAHA'IS", [
            .longOnly(.text("The Baha’i reading of the Seal is that Muhammad closed the age of prophecy and Baha’u’llah opened an age of fulfilment beyond it. But this changes the name of the thing, not the thing. A man who receives revelation, issues a new law and abrogates the old one is a prophet and a messenger by every meaning the Quran gives those words, and the Prophet (peace be upon him) said there is no prophet after him. The religion was completed in his lifetime:")),
            .longOnly(.ayah("5:3", words: 39...49)),
            .longOnly(.text("A religion completed does not await its replacement. The message was sent to all people (34:28), so there is no later people for whom another is needed. And the Prophet’s own description of the end of time leaves no space for a new law: Eesa descends to judge by the law of Islam, breaking the cross and ending the jizyah (Saheeh al-Bukhaari 3448), not to bring a Bayaan or an Aqdas.")),
            .longOnly(.ayah("34:28")),
            .shortOnly(.text("The Baha’i reading of the Seal is that Muhammad closed the age of prophecy and Baha’u’llah opened an age beyond it. But this changes the name of the thing, not the thing: a man who receives revelation, issues a new law and abrogates the old one is a prophet and a messenger by every meaning the Quran gives those words, and the Prophet (peace be upon him) said there is no prophet after him. His description of the end of time leaves no space for a new law either: Eesa descends to judge by the law of Islam, breaking the cross and ending the jizyah, not to bring a Bayaan or an Aqdas.")),
            .text("The whole Baha’i structure, moreover, stands on the Twelver belief in a hidden imam whose gate the Bab claimed to be. Ahl as-Sunnah do not accept that such an imam was born and went into hiding; the Mahdi of the sound hadith is a man still to come. The Bab’s first claim stood on ground that was never there, and every later claim stands on the Bab."),
            .door(.article("ShiaAnswerView")),
            .longOnly(.text("Baha’i teaching also makes all religions one, by making their founders mirrors of one another. The Quran agrees that the true prophets taught one religion (42:13). But the religions as they now stand contradict each other on the most basic things: whether God is one or three, whether there is a Creator at all, whether the soul is reborn or resurrected. Islam’s answer is sharper and kinder: the prophets did teach one religion, and the contradictions are what later hands added, which the last Prophet came to correct.")),
            .longOnly(.ayah("42:13", words: 1...23)),
            .text("Finally, the qiblah. In his final illness the Prophet (peace be upon him) warned against those who took the graves of their prophets as places of worship (Saheeh al-Bukhaari 1330). A religion whose daily prayer is said facing the tomb of its founder has done exactly what he warned against."),
            .hadith("bukhari:1330", cite: "Saheeh al-Bukhaari 1330, Saheeh Muslim 529", arabic: 22...44, english: [0...28]),
        ]),
        ArticleSection("THE NATION OF ISLAM", [
            .longOnly(.text("In July 1930 a peddler of silks named Wallace D. Fard began teaching in the Black neighbourhoods of Detroit. He told his listeners that they were the original people of the earth, whose true religion was Islam, and that the white race was a race of devils, made six thousand years ago by an evil scientist named Yakub. His background is unclear, and he disappeared in 1934. His chief disciple, Elijah Poole (1897–1975), renamed Elijah Muhammad, led the movement for forty years. He taught that Fard was Allah in person, the awaited Messiah and Mahdi, and that he himself was the Messenger of Allah. The Nation denied the bodily resurrection, which it called the mental resurrection of a sleeping people, and kept its fast in December instead of Ramadan.")),
            .longOnly(.text("For all that, the Nation did real good in a hard place. It reached men in prisons and slums whom no one else reached, demanded discipline, sobriety and work, and gave a humiliated people dignity. Its most famous convert was Malcolm Little, who joined it in prison and became, as Malcolm X, its national spokesman.")),
            .longOnly(.text("Then Malcolm (may Allah have mercy on him) learned what Islam itself teaches. He broke with the Nation in March 1964 and in April performed the Hajj. In letters home from Makkah he described eating and praying beside pilgrims of every colour, from blue-eyed blonds to black-skinned Africans, and said that what he saw made him rethink what he had believed about race. He returned as el-Hajj Maalik el-Shabazz, a Sunni Muslim, and was assassinated in New York on 21 February 1965. When Elijah Muhammad died ten years later, his son Waarith Deen Mohammed (1933–2008) took the leadership and led most of its members to Sunni Islam. In the late 1970s Louis Farrakhan rebuilt a Nation of Islam on Elijah Muhammad’s teachings, and it continues today.")),
            .shortOnly(.text("In 1930 a peddler of silks named Wallace D. Fard began teaching in Detroit that Black Americans were the original people, whose true religion was Islam, and that the white race was a race of devils. His disciple Elijah Muhammad led the movement for forty years, teaching that Fard was Allah in person and that he himself was the Messenger of Allah. The Nation reached men in prisons and slums whom no one else reached. Its most famous convert, Malcolm X, broke with it in 1964, performed the Hajj, prayed beside pilgrims of every colour, and returned a Sunni Muslim; after Elijah Muhammad’s death his son Waarith Deen Mohammed led most of its members to Sunni Islam.")),
        ]),
        ArticleSection("ANSWERING THE NATION OF ISLAM", [
            .text("What Malcolm found at Makkah is the answer. First, Allah is not a man, and He did not appear as one in Detroit or anywhere else:"),
            .ayah("42:11", words: 13...18),
            .ayah("112:1-4"),
            .longOnly(.text("A man who eats, sleeps, is born of a mother and disappears is a creature. The Quran makes this very argument against those who deified Eesa: he and his mother both used to eat food (5:75). If Eesa, born of a virgin and given clear miracles, was only a servant of Allah, what of a peddler of silks? To believe that a man is God is the gravest error there is, and to call Elijah Muhammad a messenger after the Seal adds a second.")),
            .longOnly(.ayah("5:75")),
            .shortOnly(.text("A man who eats, sleeps, is born of a mother and disappears is a creature. To believe that a man is God is the gravest error there is, and to call Elijah Muhammad a messenger after the Seal adds a second.")),
            .text("Second, no race is chosen and none is satanic:"),
            .ayah("49:13"),
            .hadith("muslim:2564c", cite: "Saheeh Muslim 2564", arabic: 28...39, english: [0...20]),
            .longOnly(.text("The Prophet (peace be upon him) made Bilaal, a freed Abyssinian slave, the caller to prayer, and heard his footsteps ahead of him in Paradise (Saheeh al-Bukhaari 1149). He told his people that Allah had removed the pride of the Age of Ignorance and its boasting in ancestors, that a person is only a pious believer or a wretched sinner, and that all people are children of Aadam, and Aadam was from dust (Sunan Abi Daawood 5116; graded hasan by al-Albaani). A theology that makes one colour divine and another devilish is that Age of Ignorance returned in a new form. The white supremacy it reacted against was evil, and its mirror image is evil too.")),
            .longOnly(.hadith("bukhari:1149", cite: "Saheeh al-Bukhaari 1149, Saheeh Muslim 2458", arabic: 21...49, english: [0...33])),
            .longOnly(.hadith("abudawud:5116", cite: "Sunan Abi Daawood 5116; graded hasan by al-Albaani", arabic: 44...64, english: [4...41])),
            .longOnly(.text("Third, the resurrection is bodily and real (75:3-4, 36:78-79), not a figure of speech for a people’s awakening, and the fast is the fast of Ramadan (2:183-185). Wherever the Nation departed from Islam, the Quran it carried contradicted it, and that is how many of its members found their way out: they read the book.")),
            .longOnly(.ayah("75:3-4")),
            .longOnly(.ayah("36:78-79")),
            .longOnly(.ayah("2:185", words: 0...16)),
            .shortOnly(.text("A theology that makes one colour divine and another devilish is the Age of Ignorance returned in a new form. The white supremacy it reacted against was evil, and its mirror image is evil too.")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Are Ahmadis and Baha’is Muslims?**"),
            .text("No. Baha’is themselves call their faith a new religion, and the scholars of Islam agree that whoever believes in a prophet or a new revelation after Muhammad (peace be upon him) has left Islam, because he denies what is known of it by necessity. That is a ruling on a belief, stated without hatred. The individual Ahmadi or Baha’i is owed justice, courtesy and an invitation made with wisdom; many were born into these movements and have never heard the case against them."),
            .longOnly(.markdown("**Why do such movements keep appearing?**")),
            .longOnly(.text("Because the hope of a deliverer is strong in hard times, and the figures the Sunnah foretells for the end of time are open to anyone willing to claim them. The Prophet (peace be upon him) gave his ummah the means to test every claimant: the Mahdi bears his name and his father’s name and fills the earth with justice; Eesa descends over Damascus, kills the Dajjaal and rules by Islam. No claimant has matched the description.")),
            .longOnly(.door(.prophecy("mahdi"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Mirza Ghulam Ahmad claimed to be the Messiah and a prophet; Baha’u’llah claimed to be a Manifestation of God who replaced the law of the Quran; the Nation of Islam claimed that Allah walked the streets of Detroit and sent a messenger after Muhammad (peace be upon him). The Quran closes all three doors with one verse, and the Prophet explained it so that no reading could reopen them: the last brick is laid, no prophet comes after him, even one without a law, and the Eesa who returns is the son of Maryam himself, coming to rule by Islam. Malcolm’s journey to Makkah shows the way out: back to the Quran and the Sunnah as the Prophet left them."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Khaatam an-Nabiyyeen", arabic: "خَاتَم النَّبِيِّين", meaning: "The **Seal of the Prophets** (33:40): the last of them, after whom no prophet comes, with or without a law, as he himself explained (Saheeh al-Bukhaari 3455, 3535)."),
            .term("Dajjaal", arabic: "دَجَّال", meaning: "From **د-ج-ل**, to cover over or deceive: a great liar. The Prophet (peace be upon him) used the word for the false claimants to prophethood after him, and above all for the Dajjaal of the end of time, whom Eesa (peace be upon him) will kill."),
            .term("Nuzool Eesa", arabic: "نُزُول عِيسَى", meaning: "The **descent of Eesa**, son of Maryam, from the heaven to which he was raised, before the Hour (43:61). Ahl as-Sunnah hold it by consensus, on the strength of mutawaatir narrations."),
            .ayah("43:61"),
            .term("Al-Mubashshiraat", arabic: "المُبَشِّرَات", meaning: "**Glad tidings**: the true good dream, the only part of prophethood that remains after the Prophet (peace be upon him) (Saheeh al-Bukhaari 6990). It brings no law and no creed."),
        ]),
    ]
}
