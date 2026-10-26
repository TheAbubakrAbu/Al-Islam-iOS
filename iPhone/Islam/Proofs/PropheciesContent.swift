#if os(iOS)
import SwiftUI

// The Prophecies of the Prophet library's articles, as data (`SignSection` / `SignBlock` in
// SignsAndProphets.swift). The index and the article screen are in PropheciesView.swift.
//
// Rules every article here keeps (Scripts/verify_prophecies.py enforces the mechanical ones):
//   * a hadith is a `.hadith(` reference into the bundled shelf, sahih or hasan by the weight of
//     its graders, never retyped; an ayah is a `.quran(` reference;
//   * "WHAT HAPPENED" states only what the historians agree on, and says so where a fulfilment is
//     a reading of the text rather than a plain match to it; a sign still to come is called that;
//   * no em dash, and no spaced hyphen standing in for one.

extension PropheciesView {
    /// The index order: groups in `Entry.Group` order, and within a group roughly the order in which
    /// the prophecies were fulfilled, so each section reads as history.
    static let entries: [Entry] = quranEntries + empireEntries + companionEntries + moreEntriesA + ummahEntries + moreEntriesB
        + endTimesEntries + toComeEntries

    /// The STRONGEST section, in reading order (Abu, 2026-09-25: "have a strongest tab section").
    ///
    /// Chosen on one test: how easily the words could have failed. A prophecy scores highly when it
    /// names a person, a place, a number or an order; when it was said publicly, to people who
    /// wrote it down and wanted it to fail; and when its fulfilment is a matter of record rather
    /// than a reading. The open-ended signs of the Hour are strong for believers but weak as an
    /// argument, so none of them is here.
    static let strongestIDs = [
        "byzantines", "abu-lahab", "fatimah-first", "badr-places", "security-hira", "six-signs",
        "mutah-martyrs", "nahrawan", "thaqif-liar", "hasan-reconciles", "caliphate-thirty", "uwais",
        "two-bracelets",
    ]

    // MARK: Foretold in the Quran

    static let quranEntries: [Entry] = [
        .init(id: "byzantines", title: "The Byzantines would win within a few years",
              summary: "Beaten by Persia, the Byzantines would overcome within three to nine years: said in Makkah, while Persia was winning.",
              group: .quran,
              aliases: ["rome", "romans", "rum", "ar-rum", "surah 30", "persia", "sasanian", "heraclius", "chosroes", "khosrow", "nineveh", "abu bakr", "wager", "bid", "badr"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("Early in the seventh century Persia overran the Byzantine East: Damascus fell in 613 CE and Jerusalem in 614, and a Persian army reached the shore facing Constantinople itself. In those years, in Makkah, these verses came down:"),
                      .quran("30:2-5"),
                      .text("The span, bid' in Arabic, is a small number: three to nine. Ibn 'Abbas describes how Makkah took it:"),
                      .hadith("tirmidhi:3193", cite: "Sunan al-Tirmidhi 3193; graded sahih by al-Albani", arabic: 45...86, english: 34...95),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("From 622 CE, the year of the Hijrah, the emperor Heraclius turned the war. By 624, the year of Badr, he was fighting inside Persia; in December 627 he destroyed a Persian army near Nineveh, and Persia sued for peace and gave back the lands it had taken."),
                      .text("Abu Bakr had staked a wager on it with some of Quraysh, before wagering was forbidden. The narrations say the term he named was too short, and that the victory still came within the three to nine years. Sufyan, a narrator of the report above, heard that it came on the day of Badr, and many scholars read 'that day the believers will rejoice' as the two victories arriving together."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It named the losing side of a war between two empires as the winner, with a span of years, when nothing pointed that way. And it was said publicly, to people who bet against it."),
                  ]),
              ]),
        .init(id: "abu-lahab", title: "Abu Lahab would die a disbeliever",
              summary: "A surah said of his living uncle that he would burn in the Fire; he had years to refute it and never did.",
              group: .quran,
              aliases: ["abu lahab", "uncle", "surah 111", "al-masad", "tabbat", "lahab", "safa", "quraysh", "fire", "abd al-uzza"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("Abu Lahab was the Prophet's own uncle and one of his loudest opponents. When the Prophet climbed a hill in Makkah and called out to Quraysh to warn them, it was his uncle who answered:"),
                      .hadith("bukhari:4972", cite: "Sahih al-Bukhari 4972", arabic: 37...81, english: 15...93),
                      .quran("111:1-3"),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The surah says of a living man, by name, that he would end in the Fire: that he would die without believing. It was recited in Makkah for years while he was alive to hear it. He died there shortly after the battle of Badr, in 2 AH, still an idolater."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("Refuting it would have cost him one sentence. Had he declared himself a Muslim, even without meaning it, the verses would have been shown false in front of everyone. Many of the Prophet's fiercest enemies did later accept Islam; the one man the Quran had named never did."),
                  ]),
              ]),
        .init(id: "return-to-makkah", title: "He would be brought back to Makkah",
              summary: "Forced out of his city, he was told he would be returned to it; eight years later he entered Makkah as its ruler.",
              group: .quran,
              aliases: ["makkah", "mecca", "hijrah", "emigration", "conquest", "fath makkah", "al-qasas", "surah 28", "maad", "place of return", "hazwarah", "ibn abbas"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("Surah al-Qasas is Makkan: the promise was made before the Hijrah, while he was still a persecuted man in his own city. Near its end comes this:"),
                      .quran("28:85"),
                      .text("Some early commentators understood the place of return as the Hereafter. The reading al-Bukhari preserves from Ibn 'Abbas is plainer:"),
                      .hadith("bukhari:4773", cite: "Sahih al-Bukhari 4773", arabic: 14...19, english: 0...7),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He left Makkah in 622 CE at night, hiding in a cave with a price on his head. He loved the city; 'Abdullah ibn 'Adi heard him address it, standing on his camel at al-Hazwarah in Makkah:"),
                      .hadith("ibnmajah:3108", cite: "Sunan Ibn Majah 3108", arabic: 52...67, english: 17...49),
                      .text("In Ramadan of 8 AH he came back at the head of ten thousand men. Makkah was taken with little fighting, its people were declared safe, and the idols around the Kaaba were broken. The man who had been driven out returned as the ruler of the city that drove him out."),
                  ]),
              ]),
        .init(id: "badr-assembly", title: "Their host would be routed",
              summary: "A Makkan surah said Quraysh's host would be routed and turn their backs; at Badr he went out reciting it.",
              group: .quran,
              aliases: ["badr", "al-qamar", "surah 54", "quraysh", "army", "multitude", "turn their backs", "aishah", "tent", "abu bakr", "2 ah"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("Surah al-Qamar was revealed in Makkah, when the Muslims were a persecuted minority with no army at all. Of Quraysh and their boast that they stood together, it says:"),
                      .quran("54:44-45"),
                      .text("'A'ishah remembered the verse that follows being revealed while she was still a little girl in Makkah, long before any fighting:"),
                      .hadith("bukhari:4993", cite: "Sahih al-Bukhari 4993", arabic: 105...130, english: 175...231),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("In Ramadan of 2 AH, at Badr, about three hundred Muslims faced a Qurayshi army roughly three times their size. Before the fighting he prayed in his tent; then he came out reciting the verse:"),
                      .hadith("bukhari:3953", cite: "Sahih al-Bukhari 3953", arabic: 18...49, english: 0...75),
                      .text("The army of Quraysh broke and fled. Seventy of them were killed, their leaders among them, and seventy were taken captive. The words had waited years in a Makkan surah for the day they described."),
                  ]),
              ]),
        .init(id: "hudaybiyah-victory", title: "A treaty called a clear victory",
              summary: "A truce that grieved the Muslims was named a clear victory on the road home; within two years Makkah was theirs.",
              group: .quran,
              aliases: ["hudaybiyah", "hudaibiya", "al-fath", "surah 48", "truce", "treaty", "umar", "fath", "conquest", "khaybar", "6 ah", "makkah"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("In 6 AH about fourteen hundred Muslims set out to perform the 'Umrah, and Quraysh stopped them at al-Hudaybiyah. The treaty that followed looked one-sided: they were to go home without visiting the Kaaba, and to send back any Makkan who came to them as a Muslim. On the road home a surah was revealed that began:"),
                      .quran("48:1"),
                      .text("Anas describes the moment it came:"),
                      .hadith("muslim:1786a", cite: "Sahih Muslim 1786a", arabic: 22...63, english: 0...65),
                      .text("'Umar had protested the terms openly. When the surah came, the Prophet sent for him:"),
                      .hadith("muslim:1785a", cite: "Sahih Muslim 1785a", arabic: 199...228, english: 256...306),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The truce ended the state of war, and with it the barrier between Islam and the rest of Arabia. Tribes and envoys came and went, and people who had only fought the Muslims now heard them. Khaybar fell early in 7 AH. When Quraysh's allies broke the truce, the Prophet marched on Makkah in 8 AH with ten thousand men, where two years earlier he had come with fourteen hundred. 'Abdullah ibn Mughaffal watched him enter:"),
                      .hadith("bukhari:4281", cite: "Sahih al-Bukhari 4281", arabic: 16...32, english: 0...22),
                  ]),
              ]),
        .init(id: "enter-masjid-haram", title: "You will enter the Sacred Mosque",
              summary: "They would enter the Sacred Mosque in safety with heads shaved: turned back in 6 AH, they did so a year later.",
              group: .quran,
              aliases: ["masjid al-haram", "sacred mosque", "kaaba", "umrah", "umrat al-qada", "vision", "dream", "umar", "hudaybiyah", "shaved", "7 ah", "tawaf"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("The Prophet had told his Companions that they would come to the Kaaba and circle it, and in 6 AH they set out for Makkah to do so. When they were turned back at al-Hudaybiyah, 'Umar went to him:"),
                      .hadith("bukhari:2731", cite: "Sahih al-Bukhari 2731", arabic: 1214...1233, english: 1982...2018),
                      .text("He told 'Umar that he would yet come to it and circle it. The surah revealed on the way home confirmed it, and called it a vision he had been shown:"),
                      .quran("48:27"),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Ibn 'Umar describes the year after:"),
                      .hadith("bukhari:4252", cite: "Sahih al-Bukhari 4252", arabic: 69...85, english: 82...119),
                      .text("That was Dhu al-Qa'dah of 7 AH. They entered in safety, under a treaty their enemies kept, circled the Kaaba, and shaved or shortened their hair, as the verse had described them. Many commentators read the 'conquest near at hand' it mentions as the truce itself, or as Khaybar, both of which came first."),
                  ]),
              ]),
        .init(id: "protected-from-people", title: "Protected from the people",
              summary: "Allah will protect you from the people: he sent his guards away, and no attempt on his life succeeded.",
              group: .quran,
              aliases: ["protection", "ismah", "guards", "al-maidah", "surah 5", "assassination", "sword", "najd", "bedouin", "aishah", "hijrah plot"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("The verse orders him to deliver everything revealed to him, and in the same breath promises that people would not stop him:"),
                      .quran("5:67"),
                      .text("Until then men had stood guard over him. 'A'ishah describes what he did when it came:"),
                      .hadith("tirmidhi:3046", cite: "Sunan al-Tirmidhi 3046", arabic: 23...61, english: 0...41),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He had enemies in Makkah, among the tribes, and among the hypocrites of Madinah, and there were real attempts on his life. Quraysh plotted to kill him on the eve of the Hijrah; at Khaybar he was served poisoned meat. On an expedition to Najd, a man took his sword from a tree while he slept:"),
                      .hadith("bukhari:4135", cite: "Sahih al-Bukhari 4135", arabic: 102...142, english: 100...155),
                      .text("None of them succeeded. He delivered the message to the end, performed the Farewell Hajj before a vast crowd, and died of an illness in 11 AH, in his own house in Madinah."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Scholars understand the promise as protection from being killed or stopped before the message was complete, not from every hurt: he was wounded at Uhud, and he wore armour in battle. What it ruled out was the one thing any determined enemy could have done."),
                  ]),
              ]),
        .init(id: "promise-of-succession", title: "After their fear, security",
              summary: "Rule in the land, an established religion, security after fear: promised to the believers, and theirs within a generation.",
              group: .quran,
              aliases: ["istikhlaf", "khilafah", "caliphate", "succession", "an-nur", "surah 24", "trench", "khandaq", "ahzab", "security", "abu bakr", "umar", "uthman", "ibn kathir"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("Surah al-Nur is from the middle years in Madinah, when the Muslims were a small community surrounded by enemies. It makes them a promise in three parts:"),
                      .quran("24:55"),
                      .text("The Quran itself describes the fear it speaks of. At the siege of the Trench in 5 AH, an alliance of Arab tribes surrounded Madinah:"),
                      .quran("33:10-11"),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("All three parts came within a generation. Before the Prophet died, Makkah and most of Arabia had accepted Islam. Under Abu Bakr, 'Umar and 'Uthman the believers came to rule from Egypt to Khurasan, the religion was practised openly across that whole land, and the town that had once been besieged became the capital of a state."),
                      .text("The promise carries a condition, and the commentators read it with its condition: it is made to those who believe, do good, and worship Allah alone. Ibn Kathir, explaining the verse, traced its fulfilment step by step, from the Prophet's own lifetime through the caliphates that followed."),
                  ]),
              ]),
        .init(id: "challenge-never-met", title: "And you will never be able to",
              summary: "Produce one surah like it, and you never will: a prediction made to the best judges of Arabic, and never answered.",
              group: .quran,
              aliases: ["challenge", "tahaddi", "inimitability", "ijaz", "surah like it", "al-baqarah", "surah 2", "eloquence", "poetry", "arabic", "jubayr ibn mutim", "at-tur"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("The Quran challenged its opponents several times to produce its like: a discourse like it, ten surahs like it, a single surah like it. The shortest surah is three verses long. In al-Baqarah the challenge carries a prediction:"),
                      .quran("2:23-24"),
                      .text("The words 'and you will never be able to' are the prophecy. A challenge alone invites an answer; this clause said in advance that none would come."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The people it addressed were the most exacting judges of Arabic there have been: poetry was their record, their honour and their weapon. They opposed him for some twenty years with boycott, exile and war, at the cost of their wealth and their leaders. A single surah would have ended the argument, and they never produced one."),
                      .text("Jubayr ibn Mut'im, a nobleman of Quraysh, came to Madinah about the prisoners of Badr while still an unbeliever. He later said:"),
                      .hadith("bukhari:4854", cite: "Sahih al-Bukhari 4854", arabic: 22...63, english: 0...78),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("Unlike a prophecy about a battle, this one is still open. Anyone can test it today, and one convincing surah would refute it. It has stood for fourteen centuries."),
                  ]),
              ]),
        .init(id: "quran-preserved", title: "The Quran would be kept",
              summary: "Allah would guard the Quran, said while it lived in the memories of a persecuted few. It is recited today as then.",
              group: .quran,
              aliases: ["preservation", "hifz", "hafiz", "memorisation", "memorization", "al-hijr", "surah 15", "zayd ibn thabit", "abu bakr", "uthman", "mushaf", "birmingham", "manuscript", "radiocarbon", "yamamah"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("Surah al-Hijr is Makkan. When this verse came down, the Quran was not yet complete; it lived in the memories of a small, persecuted community and on whatever could be written on, in a city ruled by its enemies."),
                      .quran("15:9"),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Soon after the Prophet's death, many of the Companions who knew the Quran by heart were killed fighting at al-Yamamah. 'Umar urged Abu Bakr to gather it into one volume, and Abu Bakr gave the task to Zayd ibn Thabit, who had written down revelation for the Prophet. Zayd said:"),
                      .hadith("bukhari:4986", cite: "Sahih al-Bukhari 4986", arabic: 131...146, english: 219...247),
                      .text("He gathered it from palm stalks, flat stones and the memories of men. Under 'Uthman that collection was copied into standard copies, one sent to each province."),
                      .text("It has been memorised whole in every generation since, in every Muslim land, and a slip in public recitation is corrected by the people praying behind. The physical record agrees. In 2015 the University of Birmingham announced that two leaves in its collection, holding parts of Surahs 18 to 20, were written on parchment radiocarbon-dated to 568–645 CE, a span that includes the Prophet's lifetime. Their words follow the standard text read today."),
                  ]),
              ]),
    ]

    // MARK: Empires and conquests

    static let empireEntries: [Entry] = [
        .init(id: "sanaa-hadramawt", title: "From San'a to Hadramawt, fearing only Allah",
              summary: "Told to men being tortured in Makkah: this religion would prevail until a rider crossed Yemen fearing none but Allah.",
              group: .empires,
              aliases: ["khabbab", "khabbab ibn al-aratt", "sanaa", "hadramaut", "hadramout", "persecution", "torture", "kaaba", "rider", "traveller", "wolf", "sheep", "security", "patience", "wail ibn hujr"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Khabbab ibn al-Aratt, a blacksmith, was one of the first to believe and one of those made to suffer most for it. In Makkah, while Quraysh were persecuting the Muslims, he and others came to the Prophet."),
                      .hadith("bukhari:6943", cite: "Sahih al-Bukhari 6943", arabic: 13...34, english: 0...37),
                      .text("He sat up, his face reddened, and reminded them of believers before them who were sawn in two and had their flesh torn with iron combs without leaving their faith. Then he said:"),
                      .hadith("bukhari:6943", cite: "Sahih al-Bukhari 6943", arabic: 69...88, english: 114...153),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("San'a and Hadramawt lie in Yemen, far to the south of Makkah. Within about ten years of the Hijrah the tribes of Yemen had accepted Islam, and Wa'il ibn Hujr, one of the nobles of Hadramawt, came to Madinah and reported:"),
                      .hadith("abudawud:3058", cite: "Sunan Abi Dawud 3058", arabic: 14...22, english: 0...8),
                      .text("By his death in 11 AH, most of Arabia was under one authority for the first time in its history. Khabbab lived to see far more: he died in Kufa in 37 AH, when the religion he had been tortured for ruled from Egypt to Persia."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It was said to men asking only for a prayer, when the Muslims could not keep their own people safe in their own city. He answered with a safety that would reach the far end of Yemen, and told them their only fault was impatience."),
                  ]),
              ]),
        .init(id: "security-hira", title: "A woman travelling alone, and the treasures of Persia",
              summary: "Safety from al-Hira to the Kaaba and the treasures of Chosroes opened, foretold to a man who lived to see both.",
              group: .empires,
              aliases: ["persia", "chosroes", "khosrow", "kisra", "hira", "kaaba", "kabah", "woman travelling", "safety", "security", "adi ibn hatim", "treasure", "poverty"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("'Adi ibn Hatim was sitting with him when a man complained of poverty and another of highway robbery. Arabia at that time was not a place where a woman travelled alone, and Persia was the superpower on its border."),
                      .hadith("bukhari:3595", cite: "Sahih al-Bukhari 3595", arabic: 56...72, english: 56...91),
                      .hadith("bukhari:3595", cite: "Sahih al-Bukhari 3595", arabic: 88...94, english: 120...135),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("'Adi lived to see it, and he says so at the end of the same narration:"),
                      .hadith("bukhari:3595", cite: "Sahih al-Bukhari 3595", arabic: 192...212, english: 308...349),
                      .text("Both halves were fulfilled in the lifetime of the man who heard them."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("The prophecy is specific in a way that could have failed: a named road, a named empire, a named man told he would live to see it. It is reported by that same man against himself, which is the opposite of how invented stories are told."),
                  ]),
              ]),
        .init(id: "trench-rock", title: "The rock at the Trench",
              summary: "Under siege, he struck a rock and saw the cities of Chosroes and Caesar; Ctesiphon and Damascus fell within twelve years.",
              group: .empires,
              aliases: ["khandaq", "ahzab", "confederates", "siege", "salman", "salman al-farisi", "kisra", "persia", "byzantines", "syria", "madain", "abyssinia", "ethiopia", "pickaxe", "flash of light"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In 5 AH an alliance of Quraysh and the tribes marched on Madinah, and the Muslims dug a trench across its open side. A rock blocked the digging. He took the pickaxe and struck it three times, and each blow broke off a third of it with a flash of light."),
                      .hadith("nasai:3176", cite: "Sunan an-Nasa'i 3176", arabic: 153...210, english: 206...284),
                      .text("Those present asked him to pray that Allah would give them those lands, and he did. Then he told them of the second blow:"),
                      .hadith("nasai:3176", cite: "Sunan an-Nasa'i 3176", arabic: 242...254, english: 331...359),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The words for 'the cities of Kisra' are mada'in Kisra, and al-Mada'in was the Arabs' name for Ctesiphon, his capital. It was taken in 16 AH. Caesar's cities nearest to Arabia, those of Syria, fell in the same years: Damascus in 14 AH, and most of the rest after the battle of Yarmuk in 15 AH. All of it came about a decade after the siege."),
                      .text("The Quran records what some inside the city were saying during that same siege:"),
                      .quran("33:12"),
                  ]),
                  SignSection("A NOTE", [
                      .text("The third blow was different. He was shown Abyssinia, whose king had sheltered the first Muslim emigrants, and this time he said something else:"),
                      .hadith("nasai:3176", cite: "Sunan an-Nasa'i 3176", arabic: 281...315, english: 400...463),
                  ]),
              ]),
        .init(id: "after-the-trench", title: "Now we go to them",
              summary: "As the Confederates withdrew from Madinah he said they would not attack again. Quraysh never again marched on the city.",
              group: .empires,
              aliases: ["trench", "khandaq", "ahzab", "confederates", "clans", "sulayman ibn surad", "siege", "hudaybiyah", "conquest of makkah", "fath", "turning point", "uhud"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In 5 AH the largest army yet raised against him, Quraysh and their allies among the tribes, besieged Madinah for weeks and was held off by the trench. Then it broke up and went home. As it left, he said:"),
                      .hadith("bukhari:4110", cite: "Sahih al-Bukhari 4110", arabic: 20...39, english: 0...37),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Quraysh never again marched on Madinah. The next time the two sides met, it was the Muslims who travelled: to al-Hudaybiyah in 6 AH, and to Makkah itself in 8 AH, which opened to him with almost no fighting."),
                      .text("Uhud and the Trench had both been armies of Quraysh marching on Madinah. He said the pattern had turned on the day the siege lifted, when no one could yet know it."),
                  ]),
              ]),
        .init(id: "chosroes-torn", title: "The letter Chosroes tore",
              summary: "Chosroes tore up the Prophet's letter and he prayed they be torn apart; within years the Persian empire was in pieces.",
              group: .empires,
              aliases: ["kisra", "khosrow", "khosrow ii", "parviz", "persia", "sasanian", "abdullah ibn hudhafah", "bahrain", "kavad", "shiruyah", "boran", "yazdegerd", "said ibn al-musayyab", "invocation", "prayer answered"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("After al-Hudaybiyah he wrote to the rulers around Arabia inviting them to Islam. Ibn 'Abbas described what became of the letter to Chosroes:"),
                      .hadith("bukhari:7264", cite: "Sahih al-Bukhari 7264", arabic: 27...52, english: 0...38),
                      .text("Al-Zuhri, who passed the report on, added what he believed Sa'id ibn al-Musayyab, the leading scholar of the next generation, had told him:"),
                      .hadith("bukhari:7264", cite: "Sahih al-Bukhari 7264", arabic: 58...69, english: 46...59),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The Chosroes who tore it was Khosrow II, whose armies had taken Jerusalem and Egypt in a war with Byzantium that had lasted more than twenty years. In 628 CE, with the Byzantine army inside Persia, he was overthrown and put to death by his own son, Kavad II."),
                      .text("Kavad died within months. Over the next four years the throne passed from hand to hand, to a child, a general, two of Khosrow's daughters and others, several of them killed. News that the Persians had crowned Khosrow's daughter reached Madinah in the Prophet's lifetime."),
                      .text("When Yazdegerd III took the throne in 632 CE the empire was exhausted and divided. Within twenty years it had fallen to the Muslims, and he was the last of its kings."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Strictly this is a prayer answered, not a prophecy, and the report of the prayer comes from Sa'id ibn al-Musayyab rather than a Companion. Al-Bukhari recorded it, and the empire that tore the letter was itself torn apart within a few years."),
                  ]),
              ]),
        .init(id: "end-of-empires", title: "The last Chosroes, the last Caesar",
              summary: "When these two perish there will be no more after them, said while both empires ruled the world.",
              group: .empires,
              aliases: ["rome", "byzantine", "caesar", "persia", "sasanian", "yazdegerd", "heraclius", "empire", "emperor", "no chosroes"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Rome and Persia had divided the known world between them for centuries. He said each would have a last ruler."),
                      .hadith("bukhari:3618", cite: "Sahih al-Bukhari 3618", arabic: 29...49, english: 4...46),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Yazdegerd III was the last Sasanian emperor; the dynasty ended with his death in 651 and no Chosroes followed. Caesar is the subtler half. Al-Shafi'i and other early scholars read it as Caesar's rule over Syria, and Heraclius was the last emperor to hold it: within a few years of Yarmuk in 636 he had lost Syria, Palestine and Egypt, and Damascus, Jerusalem and Egypt never returned to lasting Roman rule. The Muslims did spend the treasures of both, as the same narration says they would."),
                  ]),
              ]),
        .init(id: "white-palace", title: "The white palace of Chosroes",
              summary: "A band of Muslims would take Chosroes' treasure in the White Palace; Ctesiphon fell to Sa'd ibn Abi Waqqas in 16 AH.",
              group: .empires,
              aliases: ["kisra", "khosrow", "persia", "sasanian", "madain", "al-madain", "saad", "sad ibn abi waqqas", "jabir ibn samurah", "amir ibn sad", "qadisiyyah", "yazdegerd", "tigris", "abyad", "iwan"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Jabir ibn Samurah heard him say this when Persia was one of the two great powers of the world and the Muslims were a small state in Arabia."),
                      .hadith("muslim:2919b", cite: "Sahih Muslim 2919b", arabic: 30...42, english: 7...35),
                      .text("The word he used, 'isabah, means a band or company, and he named the building where the treasure would be. Jabir later wrote a version of the same saying in a letter to 'Amir, a son of Sa'd ibn Abi Waqqas, the commander whose army took it."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The White Palace stood at Ctesiphon on the Tigris, the Persian capital, which the Arabs called al-Mada'in, 'the cities'. In 16 AH (637 CE), after the Persian defeat at al-Qadisiyyah, the Muslim army under Sa'd ibn Abi Waqqas crossed the Tigris and entered it. Yazdegerd III had fled, the royal treasury fell to them, and the share owed to the state was sent to 'Umar in Madinah."),
                      .text("The historians report that when Sa'd entered the palace he prayed there and recited these verses about Pharaoh's people:"),
                      .quran("44:25-28"),
                  ]),
              ]),
        .init(id: "yemen-sham-iraq", title: "Yemen, Syria and Iraq, and the people who would leave",
              summary: "Three lands would be opened and people would leave Madinah for them, though Madinah was better for them.",
              group: .empires,
              aliases: ["sham", "medina", "sufyan ibn abi zuhayr", "damascus", "hims", "kufa", "basra", "ctesiphon", "migration", "conquests", "capital", "ali ibn abi talib", "muawiyah", "order of conquests"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Sufyan ibn Abi Zuhayr heard him name three lands, each with the same words attached."),
                      .hadith("bukhari:1875", cite: "Sahih al-Bukhari 1875", arabic: 40...54, english: 6...42),
                      .text("He said the same of Sham, the land of Syria, and then of Iraq:"),
                      .hadith("bukhari:1875", cite: "Sahih al-Bukhari 1875", arabic: 70...84, english: 81...117),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Yemen came into Islam in his last years. Syria and Iraq were opened after his death, under Abu Bakr and 'Umar. Khalid ibn al-Walid campaigned in Iraq in 12 AH, before the Syrian campaign began, but Damascus fell in 14 AH, two years before Ctesiphon, the Persian capital in Iraq."),
                      .text("People left. Companions settled in Damascus and Hims, and in the new garrison cities of Kufa and Basra, and many are buried there rather than in Madinah. Within twenty-five years of his death the caliphate itself had left: 'Ali governed from Kufa, and after him Mu'awiyah from Damascus. Madinah was never the capital again."),
                      .text("Al-Nawawi, commenting on this hadith, recorded the scholars' view that it holds several signs at once: the lands were opened, people did move to them with their families, and the conquests came in the order given."),
                  ]),
              ]),
        .init(id: "egypt-conquest", title: "Egypt, and how to treat its people",
              summary: "You will conquer Egypt; be good to its people, for they have kinship and a covenant.",
              group: .empires,
              aliases: ["egypt", "misr", "copts", "coptic", "amr ibn al-as", "umar", "hajar", "kinship", "covenant", "abu dharr", "conquest"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("muslim:2543b", cite: "Sahih Muslim 2543b", arabic: 39...55, english: 0...42),
                      .text("The instruction that follows the prediction is the remarkable part: he told them how to behave in a country they did not yet rule, because its people had a claim of kinship on them through Hajar, the mother of Isma'il."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Egypt was opened under 'Amr ibn al-'As in the caliphate of 'Umar. The same narration ends with a smaller prophecy, fulfilled for the man who narrated it: he had been told to leave when he saw two men quarrelling over the space of a brick, and he did."),
                      .hadith("muslim:2543b", cite: "Sahih Muslim 2543b", arabic: 75...90, english: 65...95),
                  ]),
              ]),
        .init(id: "umm-haram-sea", title: "Umm Haram and the first fleet",
              summary: "He saw his followers sail to war like kings on thrones, and told Umm Haram she would be with the first, not a later army.",
              group: .empires,
              aliases: ["umm haram bint milhan", "ubadah ibn al-samit", "cyprus", "larnaca", "hala sultan tekke", "navy", "naval", "ships", "muawiyah", "uthman", "constantinople", "caesar", "abu ayyub", "anas ibn malik", "dream"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He took a midday rest in the house of Umm Haram bint Milhan, the aunt of Anas ibn Malik, and woke up smiling. The Muslims of Madinah had no ships, and the Arabs of the Hijaz were not a seafaring people."),
                      .hadith("bukhari:2894", cite: "Sahih al-Bukhari 2894", arabic: 41...72, english: 22...76),
                      .text("She reported a second saying as well, which set her apart from a later army:"),
                      .hadith("bukhari:2924", cite: "Sahih al-Bukhari 2924", arabic: 78...104, english: 80...117),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("'Umar would not let the Muslims campaign by sea. Under 'Uthman, Mu'awiyah, then governor of Syria, took the first Muslim fleet in the Mediterranean to Cyprus in 28 AH (649 CE). Umm Haram sailed with it, alongside her husband 'Ubadah ibn al-Samit."),
                      .hadith("tirmidhi:1645", cite: "Sunan al-Tirmidhi 1645", arabic: 166...183, english: 222...253),
                      .text("Abu Dawud, recording the same narration, notes that she died on Cyprus. The shrine near Larnaca now called Hala Sultan Tekke is held to be her grave."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("The first campaign against Constantinople, Caesar's city, came about twenty years later, in Mu'awiyah's own caliphate; Abu Ayyub al-Ansari died on it and was buried by its walls. Umm Haram had been told she would sail with the first army and would not be with the second. Both halves could have failed, and neither did."),
                  ]),
              ]),
        .init(id: "persia-faith", title: "Faith at the Pleiades",
              summary: "With his hand on Salman, he said that if faith were at the Pleiades, men of Persia would still reach it.",
              group: .empires,
              aliases: ["salman al-farisi", "persians", "faris", "thurayya", "jumuah", "abu hurayrah", "bukhari", "muslim ibn al-hajjaj", "abu dawud", "tirmidhi", "nasai", "ibn majah", "abu hanifah", "khurasan", "scholars"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("When Surat al-Jumu'ah was revealed, Abu Hurayrah asked who were the 'others' in this verse, the ones who had not yet joined the believers:"),
                      .quran("62:3"),
                      .hadith("bukhari:4897", cite: "Sahih al-Bukhari 4897", arabic: 52...80, english: 56...100),
                      .text("Another narration names the land outright:"),
                      .hadith("muslim:2546a", cite: "Sahih Muslim 2546a", arabic: 38...56, english: 0...29),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Persia was conquered within a generation of his death, and by the third Islamic century Persia and the lands east of it had become a centre of Muslim learning. The compilers of the six major hadith collections all came from there: al-Bukhari from Bukhara, Muslim ibn al-Hajjaj from Nishapur, Abu Dawud from Sijistan, al-Tirmidhi from Tirmidh, al-Nasa'i from Nasa and Ibn Majah from Qazvin. So did Sibawayh, author of the founding work of Arabic grammar, and al-Tabari, the historian and commentator on the Quran."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a reading of the words, and scholars have made it for centuries. Al-Suyuti applied the hadith to Abu Hanifah, whose family was Persian; others saw it in the scholars of Persia and Khurasan as a whole. The words themselves were specific: of all the peoples he might have named, he put his hand on Salman."),
                  ]),
              ]),
        .init(id: "turks-mongols", title: "Faces like hammered shields",
              summary: "He described a people the Muslims would fight before the Hour; many scholars read it as the Mongol invasions.",
              group: .empires,
              aliases: ["turks", "tatars", "tartars", "baghdad", "656", "1258", "genghis khan", "hulagu", "abbasid", "al-nawawi", "small eyes", "flat noses", "shoes of hair", "sign of the hour"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Among the events he said would come before the Hour, he described one people closely:"),
                      .hadith("bukhari:2928", cite: "Sahih al-Bukhari 2928", arabic: 30...53, english: 4...50),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The Muslims met Turkic peoples in Central Asia within a few decades of his death, but many scholars have read the hadith above all as the Mongol invasions. From 616 AH (1219 CE) the armies of Genghis Khan, with the Turkic tribes they had absorbed, swept across the Muslim east and destroyed its great cities, Bukhara, Samarkand and Nishapur among them. In 656 AH (1258 CE) his grandson Hulagu sacked Baghdad and put the 'Abbasid caliph to death."),
                      .text("Al-Nawawi, who was in his twenties when Baghdad fell, wrote in his commentary on Sahih Muslim that a people with every one of these features had appeared in his own time, and that the Muslims had fought them more than once and were fighting them still."),
                  ]),
                  SignSection("A NOTE", [
                      .text("He listed this among the signs before the Hour. He did not say when it would come, and he did not say it would come only once. Nor is it a judgment on a people: within forty years of the fall of Baghdad, Ghazan, the Mongol ruler of Persia, had accepted Islam."),
                  ]),
              ]),
        // From provingislam.com's "Siege of Baghdad Prophecy" (Mohammad Baqer), 2026-09-29. Abu Dawud 4306
        // is graded hasan by al-Albani on the shelf; the reading as Baghdad is 'Awn al-Ma'bud's.
        .init(id: "basrah-qantura", title: "The city on the Tigris, and the sons of Qantura'",
              summary: "A great city of the Muslims by the Tigris, with a bridge, overrun by broad-faced, small-eyed invaders: read as Baghdad and the Mongols.",
              group: .empires,
              aliases: ["baghdad", "basrah", "basra", "tigris", "dijlah", "bridge", "qantura", "banu qantura", "mongols", "tatars", "hulagu", "656", "1258", "abbasid", "siege of baghdad", "bab al-basrah", "awn al-mabud"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Bakrah (may Allah be pleased with him) heard him describe a city that did not yet exist:"),
                      .hadith("abudawud:4306", cite: "Sunan Abi Dawud 4306; graded hasan by al-Albani", arabic: 36...56, english: 6...47),
                      .text("One narrator’s wording has “one of the capital cities of the Muslims.” Then he said what would become of it:"),
                      .hadith("abudawud:4306", cite: "Sunan Abi Dawud 4306; graded hasan by al-Albani", arabic: 70...108, english: 68...144),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("No great Muslim city stood on the Tigris in his lifetime. In 145 AH (762 CE) the 'Abbasid caliph al-Mansur founded Baghdad on its banks, and it became the capital of the caliphate and one of the largest cities in the world, its two halves joined by bridges across the river. One of its quarters took its name from the gate that faced Basrah, Bab al-Basrah."),
                      .text("In Safar 656 AH (February 1258 CE) the Mongol army of Hulagu, whose ranks were full of Turkic peoples, came down on the city and camped along the river. Baghdad fell, the caliph was put to death, and a great part of its people were killed; its libraries and its place as the capital of the Muslim world did not survive the siege."),
                      .text("Al-'Azimabadi, commenting on this narration in 'Awn al-Ma'bud, wrote that the city meant is Baghdad, which the Prophet named by one of its parts, that Banu Qantura' is the name of the forefather of the Turks, and that this came to pass in Safar 656."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The narration names al-Basrah, and some read it of Basrah itself; the reading as Baghdad is the commentators', built on the river, the bridge and the quarter that bore Basrah's name. It is quoted here as that reading, alongside “Faces like hammered shields” in this library, which describes the same people from a stronger chain."),
                  ]),
              ]),
    ]

    // MARK: The Companions and his household

    static let companionEntries: [Entry] = [
        .init(id: "badr-places", title: "Where each man would fall at Badr",
              summary: "The day before Badr he marked the ground where each leader of Quraysh would die; not one fell anywhere else.",
              group: .companions,
              aliases: ["badr", "masari", "places of death", "abu jahl", "umar", "anas ibn malik", "battle", "2 ah", "the well", "qalib", "so and so"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("On the eve of Badr in 2 AH, the army of Quraysh was camped close by and outnumbered the Muslims about three to one. Anas ibn Malik narrates what the Prophet did that evening:"),
                      .hadith("muslim:1779", cite: "Sahih Muslim 1779", arabic: 185...221, english: 283...338),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Years later, on a journey between Makkah and Madinah, 'Umar told the story to Anas and others, and swore to it:"),
                      .hadith("muslim:2873", cite: "Sahih Muslim 2873", arabic: 87...127, english: 89...157),
                      .text("Seventy of Quraysh were killed that day, Abu Jahl among them. Any commander might hope to win a battle. He said, the day before, where each named man would fall, and Anas and 'Umar both report that not one of them fell anywhere else."),
                  ]),
              ]),
        .init(id: "umayyah-khalaf", title: "Umayyah ibn Khalaf, warned in Makkah",
              summary: "Told in Makkah that the Muslims would kill him, a chief of Quraysh tried not to march; he was killed at Badr.",
              group: .companions,
              aliases: ["umayyah", "umaiya", "umayya", "sad ibn muadh", "abu jahl", "abu safwan", "badr", "umrah", "kaaba", "abd al-rahman ibn awf", "bilal", "never lies", "yathrib"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Sa'd ibn Mu'adh, chief of the Aws in Madinah, and Umayyah ibn Khalaf, a chief of Quraysh, were old friends who lodged with each other on their travels. After the Hijrah, Sa'd went to Makkah for 'umrah and stayed with Umayyah. At the Kaaba he quarrelled with Abu Jahl, and Umayyah kept trying to quiet him."),
                      .hadith("bukhari:3632", cite: "Sahih al-Bukhari 3632", arabic: 132...157, english: 183...227),
                      .text("In another narration of the same account in al-Bukhari, Sa'd's words are 'they will kill you', meaning the Muslims."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Umayyah swore he would never leave Makkah. When Quraysh marched to Badr in 2 AH, Abu Jahl shamed him into coming, and he agreed to go only a short way. On the march he kept his camel close, ready to turn back:"),
                      .hadith("bukhari:3950", cite: "Sahih al-Bukhari 3950", arabic: 313...331, english: 493...520),
                      .text("He was killed at Badr by a party of the Ansar whom Bilal had called to him, although 'Abd al-Rahman ibn 'Awf tried to shield him with his own body, as 'Abd al-Rahman himself narrates. The verdict on the warning was Umayyah's own, given in Makkah before any of it happened: when Muhammad says a thing, he does not lie."),
                  ]),
              ]),
        .init(id: "quzman", title: "The man who fought hardest",
              summary: "The Companions praised the day's bravest fighter; he said the man was of the people of the Fire, and was proved right.",
              group: .companions,
              aliases: ["quzman", "people of the fire", "hellfire", "brave", "bravest", "battle", "suicide", "sahl ibn sad", "deeds", "appearances", "sword"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In one of his battles, a man among the Muslims fought harder than anyone, hunting down every enemy fighter who strayed from the line. Sahl ibn Sa'd narrates what was said about him that evening:"),
                      .hadith("bukhari:2898", cite: "Sahih al-Bukhari 2898", arabic: 30...85, english: 12...79),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The Companions were taken aback. One of them decided to see for himself, and stayed at the man's side through the rest of the fighting, stopping when he stopped and running when he ran."),
                      .hadith("bukhari:2898", cite: "Sahih al-Bukhari 2898", arabic: 104...136, english: 117...180),
                      .text("The Prophet drew the lesson himself: a man may seem to people to be doing the deeds of the people of Paradise while he is of the people of the Fire, and the reverse. The prediction concerned the one thing nobody on the field could see."),
                  ]),
              ]),
        .init(id: "khaybar-banner", title: "The banner at Khaybar",
              summary: "Tomorrow the banner goes to a man through whom Allah gives victory: it went to 'Ali, and Khaybar was opened.",
              group: .companions,
              aliases: ["khaibar", "ali", "ali ibn abi talib", "flag", "standard", "rayah", "sore eyes", "spat", "cured", "umar", "sahl ibn sad", "salamah ibn al-akwa", "7 ah", "fort", "loves allah and his messenger"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In 7 AH the Muslims besieged the fortified settlements of Khaybar, north of Madinah. One evening he said:"),
                      .hadith("bukhari:4210", cite: "Sahih al-Bukhari 4210", arabic: 22...48, english: 0...40),
                      .text("He gave no name. The Companions spent the night guessing, and 'Umar said afterwards that it was the only day he ever wished for command:"),
                      .hadith("muslim:2405", cite: "Sahih Muslim 2405", arabic: 44...52, english: 25...38),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .hadith("bukhari:4210", cite: "Sahih al-Bukhari 4210", arabic: 71...112, english: 76...136),
                      .text("'Ali had stayed behind when the army set out, because of his eyes, and followed it later. Salamah ibn al-Akwa', who was there, ends his account:"),
                      .hadith("bukhari:3702", cite: "Sahih al-Bukhari 3702", arabic: 86...103, english: 107...134),
                      .text("Three things were fixed the night before: the banner would be given the next day, to one man, and victory would come through him. It went to the man the camp least expected to see that morning, and the victory came under his command."),
                  ]),
              ]),
        .init(id: "hatib-letter", title: "The letter hidden at Rawdat Khakh",
              summary: "He sent three riders to a named place to take a secret letter from a woman; she was there, and so was the letter.",
              group: .companions,
              aliases: ["hatib ibn abi baltaah", "hatib", "rawdat khakh", "khakh", "ali", "zubayr", "miqdad", "letter", "spy", "conquest of makkah", "fath", "mumtahanah", "quraysh", "8 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In 8 AH, as he prepared the march on Makkah without announcing it, he sent 'Ali, al-Zubayr and al-Miqdad out of Madinah in haste. 'Ali narrates:"),
                      .hadith("bukhari:4274", cite: "Sahih al-Bukhari 4274", arabic: 29...53, english: 0...28),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .hadith("bukhari:4274", cite: "Sahih al-Bukhari 4274", arabic: 54...90, english: 29...94),
                      .text("The letter was from Hatib ibn Abi Balta'ah, a veteran of Badr, telling Quraysh what the Prophet intended. Hatib explained that he had no tribe in Makkah to protect his family there and had wanted a favour owed to him. The Prophet accepted his explanation and would not let 'Umar punish him, because he had fought at Badr. The opening of Surah al-Mumtahanah (60:1) was revealed about this letter."),
                      .text("Nothing about it was public: not that the letter existed, who carried it, or where she would be. The woman herself denied having it until they said they would search her."),
                  ]),
              ]),
        // From Proving Islam's "Where Could He Have Learned It?" (2026-10-02): knowledge he could not
        // have had, the same kind as the hidden letter above and the Negus below.
        .init(id: "ibn-salam", title: "Three questions only a prophet could answer",
              summary: "The most learned man among the Jews of Madinah came with three questions only a prophet could answer, heard the answers, and testified on the spot.",
              group: .companions,
              aliases: ["abdullah ibn salam", "abdullah bin salam", "ibn salam", "jews of madinah", "rabbi", "three questions",
                        "first portent of the hour", "food of paradise", "fish liver", "resemblance", "jibril", "gabriel", "anas", "medina"],
              sections: [
                  SignSection("WHAT HE WAS ASKED", [
                      .text("When the Prophet arrived in Madinah, 'Abdullah ibn Salam, whom the Jews of the city called the most learned among them, came to test him. Anas narrates:"),
                      .hadith("bukhari:3329", cite: "Sahih al-Bukhari 3329", arabic: 16...74, english: 0...81),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He answered all three, and 'Abdullah ibn Salam testified then and there that he was the Messenger of Allah. Knowing his people, he asked the Prophet to question them about him before they heard of his Islam, and hid in the house while they came:"),
                      .hadith("bukhari:3329", cite: "Sahih al-Bukhari 3329", arabic: 162...184, english: 246...283),
                      .text("When he came out and declared his faith in front of them, the same men called him the worst of them and the son of the worst."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He came as an examiner, not as a student, and he chose questions whose answers were not to be had in Makkah or among the Arabs. The answer came, the Prophet said, from Jibril that very moment. The story is told three times in Sahih al-Bukhari (3329, 3938 and 4480), each through Anas."),
                  ]),
              ]),
        .init(id: "mutah-martyrs", title: "Three deaths, six hundred miles away",
              summary: "He announced Zayd, Ja'far and Ibn Rawahah's deaths at Mu'tah as they happened, from Madinah.",
              group: .companions,
              aliases: ["mutah", "zayd", "jafar", "ibn rawahah", "khalid ibn al-walid", "jordan", "battle", "martyrs", "banner", "sword of allah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("The army had gone to Mu'tah, in what is now Jordan: about six hundred miles from Madinah, and weeks away by the communications of the time. He stood and announced the battle as it was happening."),
                      .hadith("bukhari:1246", cite: "Sahih al-Bukhari 1246", arabic: 30...65, english: 4...68),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He named the three commanders in the order they fell (Zayd, then Ja'far, then 'Abdullah ibn Rawahah), and his eyes filled with tears as he spoke. Then he said the banner was taken by a man no one had appointed, and victory came through him: Khalid ibn al-Walid, who brought the army out. The news reached Madinah afterwards, and it matched."),
                  ]),
              ]),
        .init(id: "najashi", title: "The death of the Negus, announced the same day",
              summary: "He announced the death of the king of Abyssinia on the very day it happened, and led the funeral prayer for him.",
              group: .companions,
              aliases: ["negus", "najashi", "an-najashi", "ashamah", "ashama", "abyssinia", "ethiopia", "habasha", "funeral prayer", "janazah", "in absentia", "salat al-ghaib", "red sea", "abu hurayrah", "jabir ibn abdullah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Al-Najashi, whose name was Ashamah, was the king of Abyssinia who had sheltered the first Muslim emigrants when Quraysh were persecuting them. His kingdom lay across the Red Sea from Madinah. Jabir ibn 'Abdullah narrates:"),
                      .hadith("bukhari:3877", cite: "Sahih al-Bukhari 3877", arabic: 18...38, english: 0...24),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Hurayrah, who was also there, fixes the day:"),
                      .hadith("bukhari:1245", cite: "Sahih al-Bukhari 1245", arabic: 20...40, english: 0...40),
                      .text("No rider or ship could have carried that news from Abyssinia to Madinah in a day, yet the Companions who narrate it say it was the very day he died. He called the king 'your brother', and the prayer he led over a man buried far away is the main precedent jurists cite for the funeral prayer in absentia."),
                  ]),
              ]),
        .init(id: "tabuk-wind", title: "The wind at Tabuk",
              summary: "A violent wind would strike that night; the man who stood up in it was carried off.",
              group: .companions,
              aliases: ["tabuk", "wind", "storm", "camels", "tayyi", "expedition"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("bukhari:1481", cite: "Sahih al-Bukhari 1481", arabic: 68...81, english: 87...107),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The wind came that night as he said. A man who stood up in it was carried away and thrown onto the two mountains of Tayyi'."),
                  ]),
              ]),
        .init(id: "farewell-hajj", title: "Learn your rites from me",
              summary: "At his one Hajj from Madinah he said he might not perform another; he died about three months later.",
              group: .companions,
              aliases: ["hajj", "hajjat al-wada", "farewell pilgrimage", "day of sacrifice", "yawm al-nahr", "stoning", "jamarat", "rites", "manasik", "jabir ibn abdullah", "ibn umar", "10 ah", "mina"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In 10 AH he led a vast crowd on pilgrimage: the only Hajj he performed after the emigration to Madinah. On the Day of Sacrifice, Jabir ibn 'Abdullah watched him stone the pillar from his camel."),
                      .hadith("muslim:1297", cite: "Sahih Muslim 1297", arabic: 29...54, english: 0...43),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He returned to Madinah and died in Rabi' al-Awwal 11 AH, about three months later. There was no second Hajj. Ibn 'Umar recalls that the name had come before its meaning was clear:"),
                      .hadith("bukhari:4402", cite: "Sahih al-Bukhari 4402", arabic: 25...40, english: 0...18),
                      .text("He put it as a possibility ('I do not know'), not a certainty. But he said it in public, to the people he was teaching the rites to, and he did not live to see another pilgrimage season."),
                  ]),
              ]),
        .init(id: "fatimah-first", title: "Two secrets told to Fatimah",
              summary: "He told his daughter he would die of his illness and that she would be the first of his family to follow him. She was.",
              group: .companions,
              aliases: ["fatimah", "fatima", "zahra", "daughter", "last illness", "aishah", "ahl al-bayt", "household", "secret", "wept", "laughed", "six months", "11 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In his last illness he called his daughter Fatimah and spoke to her privately, twice. 'A'ishah saw her weep at the first and laugh at the second, and asked her why."),
                      .hadith("bukhari:3715", cite: "Sahih al-Bukhari 3715", arabic: 40...68, english: 35...100),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He died of that illness in Rabi' al-Awwal 11 AH. Fatimah, still a young woman, died about six months later: the first of his household to follow him. His wives, his uncle al-'Abbas and her husband 'Ali all outlived her, most of them by decades."),
                      .text("Both halves could have failed: nothing in an illness tells a man it will be his last, and nothing marked his daughter out to die before older members of his family. Another of 'A'ishah's narrations orders the two secrets differently, but it carries the same prediction."),
                  ]),
              ]),
        .init(id: "abu-bakr-succession", title: "Allah and the believers will accept only Abu Bakr",
              summary: "In his last illness he decided not to write down his successor, saying the believers would accept no one but Abu Bakr.",
              group: .companions,
              aliases: ["abu bakr", "siddiq", "caliph", "khalifah", "caliphate", "succession", "saqifah", "banu saidah", "bayah", "pledge", "ansar", "umar", "aishah", "11 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In his last illness he thought of putting his successor in writing, so that no one could claim the office afterwards, and then decided against it. 'A'ishah reports:"),
                      .hadith("bukhari:5666", cite: "Sahih al-Bukhari 5666", arabic: 58...96, english: 69...128),
                      .text("In Muslim's narration from 'A'ishah he asked her to call her father and her brother so that he could write it, fearing that someone would wish for the office and say:"),
                      .hadith("muslim:2387", cite: "Sahih Muslim 2387", arabic: 51...59, english: 0...22),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He left nothing in writing, and died in Rabi' al-Awwal 11 AH. That same day the Ansar gathered in the hall of Banu Sa'idah and proposed a leader of their own beside one from the Emigrants: the very kind of claim he had foreseen. The meeting ended with 'Umar taking Abu Bakr's hand in pledge. Anas ibn Malik was in the mosque the next day:"),
                      .hadith("bukhari:7219", cite: "Sahih al-Bukhari 7219", arabic: 131...147, english: 152...183),
                      .text("No other candidate was accepted. 'Ali, who held back at first, gave his own pledge some months later."),
                  ]),
              ]),
        .init(id: "longest-arm", title: "The wife with the longest arm",
              summary: "The first of his wives to join him would be the one with the longest arm: it was Zaynab bint Jahsh, for her charity.",
              group: .companions,
              aliases: ["zaynab bint jahsh", "zainab", "wives", "mothers of the believers", "longest hand", "long hand", "charity", "sadaqah", "aishah", "20 ah", "umar"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He told his wives which of them would be the first to follow him in death, in words they did not understand at first. 'A'ishah narrates:"),
                      .hadith("muslim:2452", cite: "Sahih Muslim 2452", arabic: 35...39, english: 0...12),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("They took it literally and compared the length of their arms. 'A'ishah continues:"),
                      .hadith("muslim:2452", cite: "Sahih Muslim 2452", arabic: 42...59, english: 13...60),
                      .text("Zaynab bint Jahsh died in 20 AH, in the caliphate of 'Umar: the first of his wives to die after him. The long hand was the open one. The prediction does not clash with the one given to Fatimah, since these words were spoken to his wives."),
                  ]),
              ]),
        .init(id: "uwais", title: "Uwais of Qaran",
              summary: "A man from Yemen, described to 'Umar down to a healed patch of skin, who would come with the reinforcements.",
              group: .companions,
              aliases: ["uwais", "uways", "uwais al-qarani", "qaran", "murad", "yemen", "reinforcements", "tabiin", "successors", "mother", "leprosy", "baras", "forgiveness", "kufa", "usayr ibn jabir"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Uwais lived in Yemen and never met the Prophet. 'Umar heard the Prophet describe him, down to his clan and a mark on his skin:"),
                      .hadith("muslim:2542c", cite: "Sahih Muslim 2542c", arabic: 104...141, english: 84...170),
                      .text("Another narration in the same chapter has him call Uwais the best of the Successors, the generation after the Companions."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Years later, as caliph, 'Umar asked every contingent of reinforcements that reached him from Yemen whether Uwais ibn 'Amir was among them, until one day he was:"),
                      .hadith("muslim:2542c", cite: "Sahih Muslim 2542c", arabic: 51...92, english: 0...74),
                      .text("Every detail matched: the name, the clan of Murad and then Qaran, the healed skin with one patch the size of a dirham, and the mother he cared for. 'Umar asked him to pray for his forgiveness, and he did. Then Uwais turned down a letter to the governor of Kufa and went to live there among the poor."),
                  ]),
              ]),
        .init(id: "sad-lives", title: "The sick man who would live",
              summary: "Sa'd thought he was dying; perhaps you will live until some benefit from you and others are harmed, he was told.",
              group: .companions,
              aliases: ["sad ibn abi waqqas", "saad", "farewell hajj", "illness", "one third", "bequest", "will", "qadisiyyah", "iraq", "kufa", "madain", "ctesiphon", "persia", "long life", "amir ibn sad"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In the year of the Farewell Hajj (10 AH), Sa'd ibn Abi Waqqas fell so ill in Makkah that he expected to die. The Prophet visited him, and Sa'd asked how much of his wealth he could give away, since he had only one daughter to inherit. Then he asked whether he would be left behind to die in Makkah, the city he had emigrated from:"),
                      .hadith("bukhari:1295", cite: "Sahih al-Bukhari 1295", arabic: 107...137, english: 142...201),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Sa'd recovered. He went on to have many children, and this hadith reached us through one of them, his son 'Amir. In 15 AH he commanded the Muslim army at al-Qadisiyyah, which broke the Persian army in Iraq; he went on to take the Persian capital, al-Mada'in, and to found Kufa."),
                      .text("Many scholars read the two halves plainly: the Muslims who gained through the conquests he led, and the Persian armies he defeated. He died in about 55 AH (675 CE), some forty-five years after the illness he expected to die of, and is usually counted the last of the ten promised Paradise to die."),
                  ]),
              ]),
        .init(id: "uhud-martyrs", title: "A prophet, a siddiq and two martyrs",
              summary: "Uhud shook beneath him, Abu Bakr, 'Umar and 'Uthman; he said two were martyrs, and 'Umar and 'Uthman were both killed.",
              group: .companions,
              aliases: ["uhud", "mountain", "shook", "tremble", "abu bakr", "umar", "uthman", "siddiq", "shahid", "martyrdom", "anas ibn malik", "assassination", "23 ah", "35 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He once climbed Mount Uhud, outside Madinah, with Abu Bakr, 'Umar and 'Uthman, and the mountain trembled beneath them. Anas ibn Malik narrates:"),
                      .hadith("bukhari:3699", cite: "Sahih al-Bukhari 3699", arabic: 17...46, english: 0...59),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Bakr, the Siddiq, died of illness in 13 AH. The other two were killed. 'Umar was stabbed while leading the dawn prayer in the mosque of Madinah and died of the wound in 23 AH (644 CE). 'Uthman was killed in his own house by rebels who had besieged it, in 35 AH (656 CE)."),
                      .text("Neither died in battle, where a martyr's death would be looked for. Both were killed in Madinah itself, far from any front, and 'Umar had asked Allah for exactly that: martyrdom, and a death in the city of the Prophet (Sahih al-Bukhari 1890)."),
                  ]),
              ]),
        .init(id: "umar-door", title: "The door that would be broken",
              summary: "Between the Muslims and the great trials stood a closed door that would be broken, and the door was 'Umar.",
              group: .companions,
              aliases: ["umar", "hudhayfah", "hudhaifa", "fitnah", "fitan", "trials", "closed door", "waves of the sea", "abu lulu", "assassination", "masruq", "tribulation", "civil war"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Hudhayfah ibn al-Yaman was known among the Companions for what he had kept of the Prophet's words about the trials to come. 'Umar, by then caliph, asked him about the great one, the trial that would surge like the sea."),
                      .hadith("bukhari:3586", cite: "Sahih al-Bukhari 3586", arabic: 81...116, english: 78...153),
                      .text("His students later asked him what the door meant:"),
                      .hadith("bukhari:3586", cite: "Sahih al-Bukhari 3586", arabic: 117...142, english: 154...214),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("A door that is opened can be shut again; one that is broken cannot. At the end of 23 AH (644 CE), 'Umar was stabbed by Abu Lu'lu'ah, a Persian slave, while leading the dawn prayer in the Prophet's mosque, and he died of his wounds days later. He did not die in his bed. Many scholars read the breaking of the door as exactly this: his killing, as against a natural death."),
                      .text("What followed is what 'Umar feared. Twelve years later 'Uthman was besieged and killed in his own house, and the battles of the Camel and Siffin set Muslim armies against each other. The unity of 'Umar's time did not return in the same form."),
                  ]),
              ]),
        .init(id: "uthman-calamity", title: "Paradise, and a calamity first",
              summary: "Three men came to a garden gate; the third, 'Uthman, was promised Paradise with a calamity that would befall him.",
              group: .companions,
              aliases: ["uthman", "uthman ibn affan", "abu musa", "abu musa al-ashari", "bir aris", "well", "garden", "glad tidings", "abu bakr", "siege", "martyrdom", "baqi", "said ibn al-musayyib"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Musa al-Ash'ari was keeping the gate of a walled garden in Madinah where the Prophet sat by the well. Abu Bakr asked to come in and was given the glad tidings of Paradise; then 'Umar came, and was given the same."),
                      .hadith("bukhari:3693", cite: "Sahih al-Bukhari 3693", arabic: 98...128, english: 128...190),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("'Uthman became the third caliph after 'Umar. In his last years, rebels from Egypt, Kufa and Basra came to Madinah with grievances against his governors, surrounded his house for weeks, and in Dhu al-Hijjah 35 AH (656 CE) broke in and killed him."),
                      .text("'Umar had been killed too, but suddenly, at prayer. 'Uthman's trial was of another kind: accusation from his own people, a long siege in his own house, and a death at the hands of men who called themselves Muslims. He met it as he met the news that day, with praise of Allah and patience."),
                  ]),
                  SignSection("A NOTE", [
                      .text("In a longer narration, Abu Bakr and 'Umar sat on either side of the Prophet on the edge of the well. Sa'id ibn al-Musayyib, of the next generation, saw more in where 'Uthman sat:"),
                      .hadith("bukhari:3674", cite: "Sahih al-Bukhari 3674", arabic: 336...353, english: 526...565),
                      .text("Abu Bakr and 'Umar were buried beside the Prophet; 'Uthman was buried apart from them, in al-Baqi'. That is Sa'id's reading, and it is given here as his."),
                  ]),
              ]),
        .init(id: "uthman-shirt", title: "The shirt 'Uthman would not take off",
              summary: "If they want you to take off the shirt Allah has clothed you with, do not: said long before he refused to abdicate.",
              group: .companions,
              aliases: ["uthman", "caliphate", "abdicate", "abdication", "step down", "qamis", "garment", "siege", "day of the house", "yawm al-dar", "aishah", "abu sahlah", "covenant"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("'A'ishah reported that the Prophet said this to 'Uthman during his own lifetime, when 'Uthman held no office at all:"),
                      .hadith("ibnmajah:112", cite: "Sunan Ibn Majah 112", arabic: 23...57, english: 0...51),
                      .text("Al-Tirmidhi records the same words from 'A'ishah by another chain, and the graders of both books call it sahih."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("In 35 AH the rebels who surrounded his house in Madinah pressed one demand above the rest: that he step down. He refused. Companions offered to fight them off, and he forbade them, so that no blood would be shed on his account. His freedman Abu Sahlah heard what he said on the day of the house:"),
                      .hadith("tirmidhi:3711", cite: "Sunan al-Tirmidhi 3711", arabic: 25...43, english: 0...27),
                      .text("He was killed still holding the office. The instruction had assumed three things that were not yet true when it was given: that 'Uthman would rule, that people would try to make him give it up, and that he would be in a position to refuse."),
                  ]),
              ]),
        .init(id: "khawarij", title: "Worshippers who would leave the religion",
              summary: "They would out-pray you, recite the Quran, and pass through Islam like an arrow: the Khawarij, who broke away in 37 AH.",
              group: .companions,
              aliases: ["khawarij", "kharijites", "haruriyyah", "harura", "dhul-khuwaysirah", "arbitration", "tahkim", "no judgment but allah", "iraq", "kufa", "shaven heads", "arrow", "sahl ibn hunayf", "abu said al-khudri", "ibn muljam"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("A man once told the Prophet to his face to be just, as he was dividing some wealth. When 'Umar asked permission to kill him, the Prophet refused, and said this of the man's kind:"),
                      .hadith("bukhari:3610", cite: "Sahih al-Bukhari 3610", arabic: 79...90, english: 76...100),
                      .text("Sahl ibn Hunayf, asked long afterwards whether he had heard anything about the Khawarij, remembered the direction he pointed in, and the mark he gave them:"),
                      .hadith("bukhari:6934", cite: "Sahih al-Bukhari 6934", arabic: 30...54, english: 17...64),
                      .hadith("muslim:1068c", cite: "Sahih Muslim 1068c", arabic: 44...49, english: 0...10),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("In 37 AH, after Siffin, 'Ali agreed to settle his dispute with Mu'awiyah by arbitration. Thousands of his own soldiers, many known for their prayer and recitation, rejected it and withdrew to Harura', near Kufa in Iraq. They declared that anyone who accepted arbitration had left Islam, 'Ali included, and went on to kill Muslims who disagreed with them."),
                      .hadith("muslim:1066g", cite: "Sahih Muslim 1066g", arabic: 38...79, english: 0...62),
                      .text("History calls them the Khawarij, 'those who went out'. One of them killed 'Ali in 40 AH."),
                  ]),
                  SignSection("WHO WOULD FIGHT THEM", [
                      .text("He had also said when they would appear, and who would fight them:"),
                      .hadith("muslim:1065c", cite: "Sahih Muslim 1065c", arabic: 31...42, english: 0...37),
                      .text("They broke away while the Muslims were divided between 'Ali and Mu'awiyah, and it was 'Ali's side that fought them. The hadith places both of the two groups within his ummah and calls 'Ali's the nearer to the truth, which is how Ahl al-Sunnah have understood that war."),
                  ]),
              ]),
        .init(id: "ammar-killed", title: "'Ammar and the transgressing party",
              summary: "He will be killed by the transgressing party: said of 'Ammar as he built the mosque, fulfilled at Siffin in 37 AH.",
              group: .companions,
              aliases: ["ammar", "ammar ibn yasir", "siffin", "baghiyah", "rebellious group", "ali", "muawiyah", "mosque", "bricks", "abu said al-khudri", "sumayyah", "civil war", "fitnah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In the first year in Madinah the Companions built the Prophet's mosque with their own hands. Abu Sa'id al-Khudri remembered one moment from it:"),
                      .hadith("bukhari:2812", cite: "Sahih al-Bukhari 2812", arabic: 39...68, english: 62...121),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("'Ammar ibn Yasir was one of the earliest Muslims; his mother Sumayyah had been killed for her faith in Makkah. He lived to be very old, over ninety by most reports. In Safar 37 AH (657 CE), at Siffin on the Euphrates, he was fighting in 'Ali's army against the army of Syria, and he was killed there."),
                      .text("The words were known long before the battle. They are one of the main proofs Ahl al-Sunnah give for holding that 'Ali was in the right at Siffin."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The word he used, baghiyah, comes from the root the Quran uses for a party of believers that wrongs another:"),
                      .quran("49:9"),
                      .text("The ayah still calls both parties believers, and the Prophet said al-Hasan would reconcile two great parties of Muslims. So Ahl al-Sunnah hold that the Companions on the other side were Muslims who acted on their own judgment and erred, and they speak of both sides with respect."),
                  ]),
              ]),
        .init(id: "nahrawan", title: "What 'Ali found at al-Nahrawan",
              summary: "Before the battle 'Ali described a man among the Khawarij with a maimed arm; afterwards they found him among the dead.",
              group: .companions,
              aliases: ["nahrawan", "ali", "khawarij", "kharijites", "dhul-thudayyah", "mukhdaj", "maimed arm", "zayd ibn wahb", "abidah al-salmani", "abu said al-khudri", "ubaydullah ibn abi rafi", "iraq", "sign"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In 38 AH (658 CE) the Khawarij had begun shedding blood in Iraq, and 'Ali turned his army against them at al-Nahrawan. Zayd ibn Wahb was in that army. He heard 'Ali tell them what the Prophet had said about these people, and then give them the sign by which they would know them:"),
                      .hadith("muslim:1066f", cite: "Sahih Muslim 1066f", arabic: 101...137, english: 88...171),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The fighting was brief; Zayd says only two of 'Ali's men were killed. Then 'Ali ordered them to look among the dead for the man he had described."),
                      .hadith("muslim:1066f", cite: "Sahih Muslim 1066f", arabic: 242...274, english: 374...451),
                      .text("'Abidah al-Salmani, one of the leading scholars of Kufa, then asked him to swear by Allah that he had heard this from the Prophet himself. He asked three times, and three times 'Ali swore."),
                  ]),
                  SignSection("OTHER WITNESSES", [
                      .text("Abu Sa'id al-Khudri had heard the same description from the Prophet decades earlier, and he was at al-Nahrawan:"),
                      .hadith("bukhari:3610", cite: "Sahih al-Bukhari 3610", arabic: 165...203, english: 242...306),
                      .text("'Ubaydullah ibn Abi Rafi', who was also there, adds in Sahih Muslim that when the first search found nothing, 'Ali sent them back, saying he had not lied and had not been lied to. He had staked his word, in front of an army, on a detail the field would either confirm or refute."),
                  ]),
              ]),
        .init(id: "hasan-reconciles", title: "The grandson who would reconcile two armies",
              summary: "This son of mine is a chief, and perhaps Allah will reconcile two great parties of Muslims through him.",
              group: .companions,
              aliases: ["hasan", "al-hasan", "muawiyah", "year of unity", "am al-jamaah", "caliphate", "grandson", "civil war", "reconcile"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He took his grandson al-Hasan up onto the pulpit beside him and said of a child who was then very young:"),
                      .hadith("bukhari:3629", cite: "Sahih al-Bukhari 3629", arabic: 41...52, english: 18...41),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("About thirty years later, in 41 AH, with two Muslim armies facing each other, al-Hasan gave up the caliphate to Mu'awiyah and ended the war. The year is still called the Year of Unity. The prophecy named the child, the act, and that both sides would be Muslims: the detail that makes it hard to read backwards."),
                  ]),
              ]),
        .init(id: "thaqif-liar", title: "A liar and a destroyer from Thaqif",
              summary: "Thaqif would produce a great liar and a great destroyer; Asma' bint Abi Bakr told al-Hajjaj which one he was.",
              group: .companions,
              aliases: ["thaqif", "taif", "hajjaj", "al-hajjaj ibn yusuf", "mukhtar", "al-mukhtar al-thaqafi", "asma bint abi bakr", "abdullah ibn al-zubayr", "ibn zubayr", "mubir", "kadhdhab", "two belts", "iraq", "umayyad"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Thaqif was the tribe of al-Ta'if, east of Makkah. Asma' bint Abi Bakr heard him say it would produce two men:"),
                      .hadith("muslim:2545", cite: "Sahih Muslim 2545", arabic: 219...234, english: 433...451),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("In 73 AH (692 CE) al-Hajjaj ibn Yusuf of Thaqif, commanding for the Umayyad caliph 'Abd al-Malik, took Makkah, killed Asma's son 'Abdullah ibn al-Zubayr, and left his body hanging by the road. He sent for Asma', and when she refused to come, he went to her:"),
                      .hadith("muslim:2545", cite: "Sahih Muslim 2545", arabic: 169...181, english: 318...348),
                      .text("She reminded him that she was the woman of the two belts, who had used one to carry food for the Prophet and her father. Then she gave him the prophecy, and named him in it:"),
                      .hadith("muslim:2545", cite: "Sahih Muslim 2545", arabic: 237...252, english: 452...485),
                  ]),
                  SignSection("WHO THEY WERE", [
                      .text("The liar was already dead. Al-Mukhtar ibn Abi 'Ubayd, also of Thaqif, had seized Kufa in 66 AH and, as the historians report, claimed that Jibril came to him; he was killed the next year. Al-Hajjaj went on to govern Iraq for twenty years, and his killing became a byword."),
                      .text("Al-Tirmidhi, recording the same prophecy, notes that the liar is said to be al-Mukhtar and the destroyer al-Hajjaj, and reports that those al-Hajjaj put to death in captivity were counted at 120,000. Asma' named him while he held power over her city."),
                  ]),
              ]),
    ]

    // MARK: The ummah after him

    static let ummahEntries: [Entry] = [
        .init(id: "six-signs", title: "Six signs, in order",
              summary: "His death, Jerusalem, a plague, overflowing wealth, a tribulation: five came in that order, and one is still awaited.",
              group: .ummah,
              aliases: ["six signs", "awf ibn malik", "jerusalem", "plague", "amwas", "uthman", "tribulation", "truce", "wealth", "order", "byzantines", "banu al-asfar"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("At Tabuk, sitting in a leather tent, he told 'Awf ibn Malik to count six things."),
                      .hadith("bukhari:3176", cite: "Sahih al-Bukhari 3176", arabic: 46...98, english: 21...115),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Five came in the order given, inside one generation. He died in 11 AH. Jerusalem was opened under 'Umar a few years later. The plague of 'Amwas struck Syria in 18 AH and took tens of thousands, Abu 'Ubaydah and Mu'adh ibn Jabal among them. Wealth poured in with the conquests until, under 'Uthman, a hundred dinars could leave a man dissatisfied. Then 'Uthman was killed in 35 AH, and the civil strife that followed reached every Arab household."),
                  ]),
                  SignSection("THE SIXTH", [
                      .text("The last, a truce with the Byzantines that they break before marching under eighty banners, is one scholars such as Ibn Hajar held had not yet happened. It is left here as he left it: a sign still to come."),
                  ]),
              ]),
        .init(id: "globalization", title: "Its east and its west",
              summary: "He saw the earth's east and west; his ummah's rule would reach them, and no outside enemy would destroy it.",
              group: .ummah,
              aliases: ["thawban", "spread of islam", "expansion", "al-andalus", "spain", "china", "sind", "central asia", "mongols", "baghdad", "ayn jalut", "famine", "red and white treasure", "dominion", "global"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Thawban, a freed servant of the Prophet, reports this from a time when Muslim rule did not reach beyond Arabia."),
                      .hadith("muslim:2889a", cite: "Sahih Muslim 2889a", arabic: 38...57, english: 0...48),
                      .text("He then asked his Lord two things for his ummah, and was told they were granted:"),
                      .hadith("muslim:2889a", cite: "Sahih Muslim 2889a", arabic: 89...126, english: 103...181),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Within about a century of his death, Muslim rule ran from al-Andalus in the west to Sind and Central Asia, on the borders of China, in the east. Al-Nawawi, commenting on this hadith, read the naming of east and west as the direction of that reach, and observed that the expansion did run mostly east and west, and far less north and south."),
                  ]),
                  SignSection("THE PROMISE", [
                      .text("Famines have struck Muslim lands, but none has taken the whole ummah. The nearest an outside enemy came was the Mongol invasion: Baghdad fell in 656 AH (1258 CE) and the caliph was put to death. Two years later the Mamluks stopped the Mongols at 'Ayn Jalut, and within forty years the Mongol rulers of Persia had themselves become Muslim."),
                      .text("The narration also says where the harm would come from instead: Muslims killing and imprisoning one another. That part, too, is a matter of record."),
                  ]),
              ]),
        .init(id: "caliphate-thirty", title: "Thirty years of caliphate, then kingship",
              summary: "The caliphate of prophethood would last thirty years, then kingship; the four caliphs and al-Hasan come to thirty.",
              group: .ummah,
              aliases: ["khilafah", "khilafah rashidah", "rightly guided caliphs", "rashidun", "safinah", "abu bakr", "umar", "uthman", "ali", "muawiyah", "mulk", "monarchy", "umayyad", "sa'id ibn jumhan", "41 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Safinah, a freed servant of the Prophet, reports a saying with a number in it:"),
                      .hadith("abudawud:4647", cite: "Sunan Abi Dawud 4647", arabic: 26...40, english: 0...24),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Safinah counted it out for his student Sa'id ibn Jumhan:"),
                      .hadith("tirmidhi:2226", cite: "Sunan al-Tirmidhi 2226", arabic: 40...63, english: 27...72),
                      .text("By the historians' dates, Abu Bakr ruled a little over two years, 'Umar ten and a half, 'Uthman twelve and 'Ali nearly five: about twenty-nine and a half years from the Prophet's death in 11 AH. Al-Hasan's six months as caliph complete the thirty, ending in 41 AH when he handed rule to Mu'awiyah. Scholars such as Ibn Kathir counted them this way."),
                      .text("Then came kingship. Mu'awiyah, a Companion, was the first to name his own son as his successor, and from then on rule passed within dynasties. Sunni scholars read the word as a description of the kind of rule that followed, not as a verdict on him."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("A number is the easiest kind of prophecy to get wrong. Abu Bakr died of illness, and 'Umar, 'Uthman and 'Ali were all killed, at times no one could have planned; the reigns still add up to the thirty years he gave."),
                  ]),
              ]),
        .init(id: "unforgettable-sermon", title: "A sermon about everything to come",
              summary: "He told them what would happen until the Hour; later Hudhayfah recognised events like a face he had forgotten.",
              group: .ummah,
              aliases: ["hudhayfah", "hudhayfah ibn al-yaman", "amr ibn akhtab", "abu zayd", "khutbah", "speech", "fitan", "trials", "tribulations", "future events", "pulpit", "minbar", "memory"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("'Amr ibn Akhtab describes a day given over to it:"),
                      .hadith("muslim:2892", cite: "Sahih Muslim 2892", arabic: 37...60, english: 0...51),
                      .text("He spoke again until sunset. In 'Amr's words, he told them of what had been and what would be, and the most knowledgeable of them afterwards was the one who remembered it best. Hudhayfah ibn al-Yaman describes an address of the same kind:"),
                      .hadith("bukhari:6604", cite: "Sahih al-Bukhari 6604", arabic: 19...41, english: 0...35),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Hudhayfah's testimony is about what followed. He does not claim to have kept every detail; he says that the events, when they came, were ones he had been told of:"),
                      .hadith("bukhari:6604", cite: "Sahih al-Bukhari 6604", arabic: 42...56, english: 36...83),
                      .text("When 'Umar later asked who remembered what the Prophet had said about the trials to come, it was Hudhayfah who answered. He lived to see the killing of 'Uthman, and died soon after, in 36 AH."),
                  ]),
              ]),
        .init(id: "false-prophets", title: "Thirty liars claiming prophethood",
              summary: "About thirty liars would each claim to be a messenger of Allah; the first two rose before he died.",
              group: .ummah,
              aliases: ["false prophet", "dajjal", "dajjalun", "kadhdhab", "musaylimah", "al-aswad al-ansi", "yamamah", "yemen", "tulayhah", "sajah", "riddah", "apostasy wars", "seal of the prophets", "bracelets", "fayruz"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("bukhari:3609", cite: "Sahih al-Bukhari 3609", arabic: 41...55, english: 43...67),
                      .text("He also told of a dream in which two gold bracelets were placed on his arms:"),
                      .hadith("bukhari:3620", cite: "Sahih al-Bukhari 3620", arabic: 118...141, english: 130...187),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The first two did not wait for his death. Musaylimah of Banu Hanifah, in al-Yamamah, claimed a share in prophethood and came to Madinah asking to be named his successor; the Prophet told him he would not give him even the palm stalk in his hand. Al-Aswad al-'Ansi took control of much of Yemen and was killed there by Fayruz al-Daylami around the time of the Prophet's death. The narrators of the dream name these two as its bracelets."),
                      .text("Musaylimah was killed at the battle of al-Yamamah in the caliphate of Abu Bakr. Tulayhah ibn Khuwaylid of Banu Asad and Sajah of Banu Tamim made the same claim and led forces in the wars of apostasy that followed his death."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The Quran calls him the last of the prophets, which makes every later claim of prophethood the kind of lie this hadith describes."),
                      .quran("33:40"),
                      .text("Claimants have kept appearing since. Commentators such as Ibn Hajar understood 'about thirty' to mean those whose claim gathered a real following, not every individual who has made one."),
                  ]),
              ]),
        .init(id: "liars-narrations", title: "Liars with narrations no one had heard",
              summary: "Liars would bring narrations unknown to anyone; forgers came, and the science of the isnad grew up to catch them.",
              group: .ummah,
              aliases: ["fabrication", "forged hadith", "mawdu", "isnad", "chain of narration", "ibn sirin", "muhammad ibn sirin", "ibn al-mubarak", "hadith criticism", "abu hurayrah", "dajjalun", "muqaddimah", "imam muslim"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Imam Muslim opened his Sahih with an introduction on why a narration must be tested before it is believed. Among the reports he placed there is this one, from Abu Hurayrah:"),
                      .hadith("muslim:7", cite: "Muqaddimah of Sahih Muslim 7", arabic: 44...64, english: 0...32),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Forgery began within the first century and grew after it. Partisans of rival political and sectarian causes put sayings into the Prophet's mouth, and storytellers and some misguided ascetics invented narrations to stir their audiences."),
                      .text("The answer was the isnad, the chain of narrators. Muhammad ibn Sirin (d. 110 AH), one of the leading Successors in Basra, described the change:"),
                      .hadith("muslim:27", cite: "Muqaddimah of Sahih Muslim 27", arabic: 17...41, english: 0...44),
                      .text("From that demand grew a whole discipline: the study of narrators' lives and reliability, the grading of chains, and the sound collections themselves. The same introduction records 'Abdullah ibn al-Mubarak's summary of it: without the isnad, anyone could say whatever he wished."),
                  ]),
              ]),
        .init(id: "charity-refused", title: "Charity with no one to take it",
              summary: "A time would come when a man carries his charity about and finds no one who needs it.",
              group: .ummah,
              aliases: ["sadaqah", "zakah", "zakat", "harithah ibn wahb", "umar ibn abd al-aziz", "umayyad", "wealth", "poverty", "prosperity", "adi ibn hatim", "gold", "no taker"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Harithah ibn Wahb heard him urge people to give while there was still someone to give to:"),
                      .hadith("bukhari:1411", cite: "Sahih al-Bukhari 1411", arabic: 23...47, english: 6...66),
                      .text("It was said to people among whom hunger was common and the poor were never hard to find."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("'Adi ibn Hatim was given the same promise alongside two others. He lived to see those two, a woman travelling safely from al-Hira to the Kaaba and the treasures of Chosroes opened, and told his listeners that this third one was still to come."),
                      .text("The historians report that it came within a century. In the short caliphate of 'Umar ibn 'Abd al-'Aziz (99–101 AH), the accounts describe a zakah collector who could find no one poor enough to take it, and men who brought wealth to be given to the poor and carried it home again. These reports come from the early accounts of his reign, and are given here as the historians give them."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Commentators have also held that the saying will be fulfilled more fully near the end of time, when wealth overflows again. The words set no date, and both readings can stand."),
                  ]),
              ]),
        .init(id: "follow-previous", title: "Span by span, into a lizard's hole",
              summary: "His ummah would follow the ways of the nations before it so closely that it would follow them into a lizard's hole.",
              group: .ummah,
              aliases: ["imitation", "jews and christians", "persians", "byzantines", "sunan", "dabb", "mastigure", "abu said al-khudri", "abu hurayrah", "graves", "tashabbuh", "customs", "cubit"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("bukhari:7320", cite: "Sahih al-Bukhari 7320", arabic: 33...57, english: 4...61),
                      .text("In a similar narration from Abu Hurayrah, the nations named are the Persians and the Byzantines:"),
                      .hadith("bukhari:7319", cite: "Sahih al-Bukhari 7319", arabic: 24...49, english: 4...63),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("A lizard's burrow is narrow and cramped: no one would follow another into it except out of pure imitation, and the commentators took the image that way. Al-Nawawi explained that the following meant is in sins and departures from the religion, not in disbelief itself."),
                      .text("Scholars have pointed to its fulfilment in practices taken over from the religious life of earlier communities, and many today also read it in the wholesale adoption of other peoples' customs in the modern age."),
                  ]),
              ]),
        .init(id: "quran-only", title: "The man on his couch who wants only the Quran",
              summary: "A comfortable man would say 'keep to the Quran' and set the Sunnah aside; the view has had followers in several ages.",
              group: .ummah,
              aliases: ["sunnah", "hadith rejection", "hadith rejecters", "quranist", "quraniyyun", "ahl al-quran", "miqdam ibn madikarib", "couch", "reclining", "al-shafii", "obey the messenger", "authority of hadith"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Al-Miqdam ibn Ma'dikarib reports:"),
                      .hadith("abudawud:4604", cite: "Sunan Abi Dawud 4604", arabic: 37...64, english: 4...55),
                      .text("In the same breath he gave examples of rulings that come from his Sunnah and are not spelled out in the Quran: the meat of domestic donkeys, and of predators with fangs, is unlawful."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The view has had advocates in more than one age. Al-Shafi'i (d. 204 AH) recorded his debate with a man of his own time who rejected reports from the Prophet altogether. In British India around the turn of the twentieth century, a movement calling itself Ahl al-Qur'an, 'the people of the Quran', took the same line, and today there are Muslims who describe themselves as Quran-only. The argument each time is the one the hadith puts into the man's mouth: the Book is enough."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The Quran itself tells its readers to obey the Messenger, and the form of the prayer, the rates of zakah and the rites of Hajj are known in detail only through his Sunnah."),
                      .quran("4:80"),
                  ]),
              ]),
        .init(id: "nations-dish", title: "Nations called to a dish",
              summary: "Nations would call each other against the ummah like diners to a meal, while Muslims were many but weightless as froth.",
              group: .ummah,
              aliases: ["thawban", "wahn", "weakness", "love of the world", "hatred of death", "colonialism", "sykes-picot", "mandates", "ottoman", "caliphate abolished", "1924", "scum", "flood", "torrent"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Thawban reports:"),
                      .hadith("abudawud:4297", cite: "Sunan Abi Dawud 4297", arabic: 28...68, english: 4...79),
                      .text("Asked what that weakness, wahn, would be, he named two things:"),
                      .hadith("abudawud:4297", cite: "Sunan Abi Dawud 4297", arabic: 79...82, english: 92...99),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The hadith gives no date, and its words have fitted more than one period. Many modern scholars see it most clearly in the colonial age. By the early twentieth century most Muslim lands, from Morocco to Indonesia, were ruled or controlled by European powers. After the First World War the Arab provinces of the Ottoman Empire were divided between Britain and France, broadly along the lines of the secret Sykes-Picot agreement of 1916, and in 1924 the caliphate itself was abolished."),
                      .text("Through all of it the Muslims numbered in the hundreds of millions. That is the hadith's point: it places the weakness in the heart, not in the count."),
                  ]),
              ]),
        .init(id: "wine-renamed", title: "Wine by another name",
              summary: "Some of his ummah would drink wine while calling it by a different name.",
              group: .ummah,
              aliases: ["khamr", "alcohol", "intoxicant", "intoxicants", "every intoxicant", "bit", "mizr", "tila", "nabidh", "abu malik al-ashari", "abd al-rahman ibn ghanm", "drinks"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("The prophecy is not simply that people would drink wine. It is that some of his own ummah would drink it while calling it something else."),
                      .hadith("nasai:5658", cite: "Sunan an-Nasa'i 5658", arabic: 43...50, english: 4...15),
                      .text("The name was never what made it forbidden. He had already defined wine by what it does:"),
                      .hadith("muslim:2003b", cite: "Sahih Muslim 2003b", arabic: 35...40, english: 0...8),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The renaming began early. In his own lifetime he was asked about bit', made from honey, and mizr, made from barley, and he answered that every intoxicant is forbidden (Sahih al-Bukhari 4343). Later, 'Abd al-Rahman ibn Ghanm, who also narrated this hadith from Abu Malik al-Ash'ari, recalled it when the people he was sitting with began discussing tila', a drink of cooked grape juice."),
                      .text("Today intoxicants circulate under more names than ever, from trade names to the language of medicine and recreation, and the word wine is seldom the one used. What intoxicates has not changed; the names have, as he said they would."),
                  ]),
              ]),
        .init(id: "four-made-lawful", title: "Four things considered lawful",
              summary: "Some of his followers would consider lawful four things he had forbidden, not merely commit them.",
              group: .ummah,
              aliases: ["istihlal", "yastahillun", "zina", "fornication", "silk", "khamr", "alcohol", "music", "musical instruments", "maazif", "abu amir al-ashari", "abu malik al-ashari", "abd al-rahman ibn ghanm"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("'Abd al-Rahman ibn Ghanm heard this from Abu 'Amir or Abu Malik al-Ash'ari (the report does not settle which), and swore that the Companion had not lied to him."),
                      .hadith("bukhari:5590", cite: "Sahih al-Bukhari 5590", arabic: 48...56, english: 7...38),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The verb is yastahillun: they will consider these things lawful. Sins are committed in every generation, and that needed no foretelling. What he foretold was a change of judgment: that people from among his own followers would come to treat these four as permitted."),
                      .text("All four are now openly accepted in much of the world, and treated as lawful by some who count themselves among his followers. The narration continues with a warning of punishment for some of them; this article quotes only its first sentence."),
                  ]),
              ]),
        .init(id: "money-lawful-or-not", title: "Not caring where money comes from",
              summary: "A time would come when people would not care whether their money came by lawful or unlawful means.",
              group: .ummah,
              aliases: ["halal", "haram", "earnings", "income", "livelihood", "wealth", "trade", "riba", "interest", "kasb", "abu hurayrah", "business"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah reported it, and the Arabic opens with the emphasis of an oath: a time will certainly come."),
                      .hadith("bukhari:2083", cite: "Sahih al-Bukhari 2083", arabic: 21...35, english: 4...27),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He did not say that people would take unlawful wealth; people had always done that. He said they would stop asking. The question of where money came from would drop out of how a living is judged."),
                      .text("That outlook is now common everywhere: a living is measured by how much it brings in, and its source is treated as a private matter. Interest and speculation run through ordinary finance, so that even a person who does care can find the question hard to answer."),
                  ]),
              ]),
        .init(id: "mosques-adorned", title: "Vying with one another over mosques",
              summary: "The Hour would not come until people competed with one another in their mosques.",
              group: .ummah,
              aliases: ["masjid", "masjids", "yatabaha", "boasting", "decoration", "adornment", "minaret", "dome", "architecture", "anas ibn malik", "ibn umar", "prophets mosque", "sign of the hour"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Anas ibn Malik reported it. The verb, yatabaha, means to boast and try to outdo one another."),
                      .hadith("abudawud:449", cite: "Sunan Abi Dawud 449", arabic: 29...36, english: 4...17),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("His own mosque in Madinah was as plain as a building can be. 'Abdullah ibn 'Umar described it:"),
                      .hadith("bukhari:446", cite: "Sahih al-Bukhari 446", arabic: 27...43, english: 0...27),
                      .text("Building a mosque is itself a virtue: he promised whoever builds one for Allah the like of it in Paradise (Sahih al-Bukhari 450, Sahih Muslim 533). What he foretold was the rivalry. Mosques are now among the grandest buildings of many cities, and it has become common to describe one by the record it holds: the tallest minaret, the widest dome, the largest carpet."),
                  ]),
              ]),
        .init(id: "whips-and-clothed", title: "Two kinds he had never seen",
              summary: "Men with whips beating people, and women clothed yet naked: two kinds that did not exist in his time.",
              group: .ummah,
              aliases: ["whips", "cattle", "ox", "flogging", "kasiyat", "ariyat", "clothed yet naked", "humps", "bukht", "abu hurayrah", "oppression", "dress", "people of the fire"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah reported it. What makes it a prophecy is in the opening words: he had seen neither kind. Both belonged to a time after his, and he described them."),
                      .hadith("muslim:2128", cite: "Sahih Muslim 2128", arabic: 23...45, english: 0...70),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Al-Nawawi, who died in 676 AH, counted this hadith among the miracles of prophethood, because in his day both kinds had already appeared. He took the first to be the men who beat people with whips in the service of the authorities."),
                      .text("For the second, the commentators gave several readings: clothing that covers part of the body and leaves part bare, or clothing so thin that it shows what it covers. The heads like camels' humps they understood as hair or wrappings built up high. Both descriptions are more familiar now than when al-Nawawi wrote."),
                  ]),
              ]),
        .init(id: "obesity", title: "Fatness would appear among them",
              summary: "After the best generations would come people of broken trust and vows, and fatness would appear among them.",
              group: .ummah,
              aliases: ["obesity", "overweight", "siman", "weight", "health", "generations", "qarn", "best generation", "imran ibn husayn", "testimony", "witness", "nawawi"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("'Imran ibn Husayn heard him say that the best people were his own generation, then those after them ('Imran was unsure whether he named two generations after his own or three). Then he said:"),
                      .hadith("bukhari:6428", cite: "Sahih al-Bukhari 6428", arabic: 60...75, english: 52...98),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Fatness is set beside broken trust and broken vows, as a mark of people given over to ease. For most of history it was rare, the condition of the few who could eat without limit. It is now common enough to rank among the world's major health problems: the World Health Organization reported that in 2022 one person in eight was living with obesity."),
                      .text("Al-Nawawi recorded the scholars' explanation that the blame falls on fatness a person brings on through excess, not on a build someone was born with."),
                  ]),
              ]),
        .init(id: "knowledge-taken", title: "Knowledge taken with its scholars",
              summary: "Knowledge would not be snatched from hearts but taken by the deaths of scholars, leaving the ignorant to give rulings.",
              group: .ummah,
              aliases: ["ilm", "ulama", "fatwa", "fatwas", "verdicts", "muftis", "ignorance", "jahl", "abdullah ibn amr", "religious leaders", "misguidance", "sign of the hour"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("'Abdullah ibn 'Amr ibn al-'As heard him describe how knowledge would leave the world, and it was not the way one might expect."),
                      .hadith("bukhari:100", cite: "Sahih al-Bukhari 100", arabic: 32...60, english: 6...71),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The mechanism is the striking part: knowledge would not vanish from the page, it would leave with the people who carried it. The texts of Islamic learning are now more available than at any time in history, printed, translated and searchable on any phone, yet a sound verdict still needs a person who has mastered them. Rulings are given freely today by people without that training, to audiences larger than any scholar of the past addressed."),
                  ]),
                  SignSection("A NOTE", [
                      .text("In its full form, a world with no scholar left in it, this is a sign still to come. Scholars remain, and the hadith describes a process, one death at a time, rather than a single event."),
                  ]),
              ]),
        .init(id: "authority-unfit", title: "Authority in unfit hands",
              summary: "When trust is lost, wait for the Hour; and it is lost when authority is given to those unfit for it.",
              group: .ummah,
              aliases: ["amanah", "honesty", "leadership", "appointment", "competence", "positions", "responsibility", "bedouin", "abu hurayrah", "wusida al-amr", "sign of the hour"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("A Bedouin came into a gathering and asked when the Hour would be. He finished what he was saying, then asked where the questioner was, and answered him:"),
                      .hadith("bukhari:59", cite: "Sahih al-Bukhari 59", arabic: 92...96, english: 95...104),
                      .text("The man asked how it would be lost. He said:"),
                      .hadith("bukhari:59", cite: "Sahih al-Bukhari 59", arabic: 103...110, english: 117...134),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The word translated as honesty is amanah: trust in its widest sense, including every charge placed in someone's hands. He gave the Bedouin no date. He gave him a sign, and then defined it: the loss of trust would show itself when positions go to people unfit to hold them."),
                      .text("Appointment by family, loyalty or money rather than fitness is now a complaint heard in almost every country, and in every kind of institution, from governments to small offices. The hadith names no place and no people; it describes a pattern, and the pattern is easy to find."),
                  ]),
              ]),
        .init(id: "ruwaybidah", title: "The years of deceit",
              summary: "Years would come when the liar is believed, the honest man doubted, and the ruwaybidah speaks on public affairs.",
              group: .ummah,
              aliases: ["ruwaibidah", "ruwaybida", "rabidah", "deception", "treachery", "liars", "traitor", "trustworthy", "abu hurayrah", "public opinion", "khaddaat", "sign of the hour"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("ibnmajah:4036", cite: "Sunan Ibn Majah 4036; graded sahih by al-Albani", arabic: 38...57, english: 0...49),
                      .text("He was asked who the ruwaybidah were, and said:"),
                      .hadith("ibnmajah:4036", cite: "Sunan Ibn Majah 4036; graded sahih by al-Albani", arabic: 62...66, english: 59...69),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Ruwaybidah is a diminutive of rabidah, one who lies down, and the lexicographers explained it as a person who sits back from lofty matters. The verb in the Arabic is 'speaks', where the translation has 'decide', and his definition is the insignificant man who holds forth on the affairs of the public."),
                      .text("Each clause is an inversion: trust placed in the wrong people, and the least qualified speaking on the public's affairs. A world where any voice can address millions on matters of state, and where the honest and the dishonest are hard to tell apart, fits these words closely."),
                  ]),
              ]),
    ]

    // MARK: Signs before the Hour

    static let endTimesEntries: [Entry] = [
        .init(id: "fire-hijaz", title: "A fire out of the Hijaz",
              summary: "A fire lighting the necks of camels in Busra; in 654 AH a volcano beside Madinah did exactly that.",
              group: .endTimes,
              aliases: ["fire", "hijaz", "volcano", "busra", "madinah", "654", "1256", "harrat", "rahat", "lava", "eruption", "camels", "end times", "hour"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("bukhari:7118", cite: "Sahih al-Bukhari 7118", arabic: 24...36, english: 4...33),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("In 654 AH (1256 CE) a volcanic fissure opened in the lava field east of Madinah and erupted for weeks. Al-Nawawi, who was alive that year, wrote that knowledge of it was mass-transmitted across Syria and that people from Madinah who saw it told him of it. The historians who followed, Ibn Kathir among them, recorded reports that its glow was seen at Busra in Syria, hundreds of miles to the north. Geologists count it as the most recent eruption of Harrat Rahat, and its lava flow is still there."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is one of the few signs of the Hour with a date attached to it by people who watched it happen and knew the hadith. It is quoted here as they reported it, not as proof that the Hour is near: he himself said no one knows when that is."),
                  ]),
              ]),
        // From provingislam.com's "Dhul-Khalasa Prophecy" (Mohammad Baqer), 2026-09-29.
        .init(id: "dhul-khalasa", title: "The idol of Daws, worshipped again",
              summary: "An idol-house destroyed at his command would draw worshippers again before the Hour; in 1925 it had to be pulled down a second time.",
              group: .endTimes,
              aliases: ["dhul khalasa", "dhu al-khalasa", "dhil khalasa", "daws", "daus", "khath'am", "tabalah", "jarir", "kaaba of yemen", "idol", "idolatry", "shirk", "1344", "1925", "thuruq"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Dhul-Khalasa was an idol-house in the mountains south of Makkah, called before Islam the Kaaba of Yemen. In his own lifetime he sent Jarir ibn 'Abdullah (may Allah be pleased with him) to destroy it:"),
                      .hadith("bukhari:4355", cite: "Sahih al-Bukhari 4355", arabic: 11...47, english: 0...48),
                      .text("With the idol in ruins and Arabia turning to Islam, he said it would be worshipped again:"),
                      .hadith("bukhari:7116", cite: "Sahih al-Bukhari 7116", arabic: 30...40, english: 4...25),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("For centuries the words looked impossible: the peninsula was Muslim and the house was rubble. In later centuries the veneration of stones, trees and graves returned to parts of the southern highlands, and with it the old site."),
                      .text("In Rabi' al-Thani 1344 AH (late 1925 CE) an expedition sent under King 'Abd al-'Aziz reached the mountains of Daws. A first-hand account printed in a note to the modern edition of al-Azraqi's Akhbar Makkah records that at Thuruq the walls of the house of Dhul-Khalasa were standing, beside a tree the people venerated; the expedition burned the tree, pulled the building down and threw its stones into the valley. One who went with it said a single stone of it could not be moved by fewer than forty men."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Many scholars hold that the sign in its fullest sense comes near the Hour itself, when the religion has been forgotten; what happened at Thuruq shows how such a return begins, in a land where tawhid had once seemed secure. Proving Islam drew attention to this account."),
                  ]),
              ]),
        .init(id: "shepherds-buildings", title: "Barefoot shepherds and tall buildings",
              summary: "Destitute herders competing to build higher: a sign of the Hour, now plain on the skylines of Arabia.",
              group: .endTimes,
              aliases: ["jibril", "gabriel", "hadith of jibril", "umar", "skyscrapers", "towers", "burj khalifa", "dubai", "gulf", "bedouin", "herders", "slave woman", "signs of the hour", "portents"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Jibril came to him in the form of a man and questioned him, in front of his Companions, about Islam, faith and excellence. Then he asked about the Hour."),
                      .hadith("muslim:8a", cite: "Sahih Muslim 8a", arabic: 310...346, english: 490...565),
                      .text("He gave signs instead of a time. The first, the slave woman giving birth to her mistress, was read in several ways by the classical commentators; one reading is that children would come to command their mothers as an owner commands a servant."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The second is plainer: the poorest people of the desert, barefoot and poorly clothed, one day competing over who can build higher. Its weight is in the reversal."),
                      .text("For centuries much of Arabia lived by herding, fishing, pearling and trade, and within living memory its towns were built of mud brick, coral stone and palm frond. Oil changed that inside a single lifetime. The tallest building in the world, the Burj Khalifa in Dubai (828 metres, opened in 2010), stands on that coast, and a tower in Jeddah was announced with the stated aim of overtaking it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("In the same answer he said he knew no more of the Hour's time than the one asking. A fulfilled sign is a mark of his truthfulness, not a clock."),
                  ]),
              ]),
        .init(id: "arabia-meadows", title: "Arabia, returning to meadows and rivers",
              summary: "The land of the Arabs will return to meadows and rivers: geology found it was green once, and parts are green again.",
              group: .endTimes,
              aliases: ["arabia", "green arabia", "desert", "irrigation", "center pivot", "centre pivot", "farming", "wheat", "paleolakes", "empty quarter", "rub al-khali", "groundwater", "abu hurayrah", "muruj", "wealth"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He joined two signs in one sentence: wealth so abundant that charity finds no taker, and a change in the land itself."),
                      .hadith("muslim:157c", cite: "Sahih Muslim 157c", arabic: 30...52, english: 0...43),
                      .text("The verb he used is ta'uda. It can mean to return, and Arabic also uses it simply for to become; many modern writers take it in the first sense, that the land would go back to something it had once been."),
                  ]),
                  SignSection("WHAT IS SEEN NOW", [
                      .text("Both sides of that word can now be seen. Geologists have found the dry beds of ancient lakes, some of them in the Empty Quarter holding the fossils of hippopotamus and water buffalo, and satellite imaging has traced the courses of rivers long buried under the sand. Arabia passed through several wet phases over hundreds of thousands of years; the last ended some thousands of years ago."),
                      .text("Since the 1980s, center-pivot irrigation has laid thousands of green circles, visible from orbit, across the northern deserts, fed by deep groundwater that fell as rain in those wetter ages. For a time Saudi Arabia grew enough wheat to export it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Whether these fields are what he meant, or only the beginning of something still to come, the hadith does not say. What the first sense of the verb implies, that Arabia had once been meadows and rivers, agrees with what geology has found. Like every sign of the Hour, it tells what will come, not when."),
                  ]),
              ]),
        .init(id: "killing-increase", title: "Killing that has lost its reason",
              summary: "A time will come when the killer does not know why he killed, nor the one killed why he died.",
              group: .endTimes,
              aliases: ["harj", "al-harj", "murder", "violence", "war", "civil war", "bloodshed", "abu musa", "neighbour", "neighbor", "fitnah", "camel", "siffin", "abu hurayrah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("muslim:2908a", cite: "Sahih Muslim 2908a", arabic: 29...49, english: 0...34),
                      .text("Abu Musa al-Ash'ari heard him describe the same thing by its Arabic name, harj. The Companions at first took it to mean the fighting they already knew, and he corrected them."),
                      .hadith("ibnmajah:3959", cite: "Sunan Ibn Majah 3959", arabic: 29...91, english: 0...76),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The first part came early. About twenty-five years after his death, Muslim armies met each other at the Camel and at Siffin (36–37 AH), and Abu Musa himself served as one of the two arbiters after Siffin."),
                      .text("The fuller description, killing whose purpose neither side can name, many read in the modern age: two world wars that between them killed tens of millions, most of them civilians; weapons that kill, at a distance, people the killer never sees; and civil wars on several continents in which neighbours killed neighbours."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The hadith names no century and dates nothing. It is here because a description that was strange when he gave it has become familiar."),
                  ]),
              ]),
        .init(id: "time-and-earthquakes", title: "Time passing quickly, and earthquakes",
              summary: "Knowledge taken, earthquakes many, time passing quickly: signs listed together, some seen and some awaited.",
              group: .endTimes,
              aliases: ["time", "barakah", "blessing", "earthquake", "quake", "seismic", "zalazil", "afflictions", "fitan", "wealth", "knowledge", "abu hurayrah", "anas ibn malik", "year like a month"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("bukhari:1036", cite: "Sahih al-Bukhari 1036", arabic: 26...49, english: 4...46),
                      .text("Anas ibn Malik reported him describing the passing of time in more detail:"),
                      .hadith("tirmidhi:2332", cite: "Sunan al-Tirmidhi 2332", arabic: 34...54, english: 0...46),
                  ]),
                  SignSection("TIME", [
                      .text("Classical scholars read this in more than one way. A common reading is that time would lose its blessing, so that days pass with little to show for them. Many today also see it in how travel and communication have compressed time: a journey that took a month now takes hours, and news crosses the world in seconds."),
                  ]),
                  SignSection("THE EARTHQUAKES", [
                      .text("This part needs care. Seismologists at the US Geological Survey report that large earthquakes have held roughly steady worldwide, and that what has grown is the number recorded, as seismograph networks have multiplied. What has plainly grown is the number of people living where earthquakes strike. So it is held here as he gave it: a sign, not one this article can date."),
                      .text("He gave the whole list without dates, and said elsewhere that the time of the Hour is known to Allah alone."),
                  ]),
              ]),
        .init(id: "unknown-diseases", title: "Diseases their forebears never knew",
              summary: "Where immorality is done openly, plagues and diseases unknown to earlier generations will spread.",
              group: .endTimes,
              aliases: ["plague", "disease", "epidemic", "pandemic", "illness", "infection", "immorality", "fahishah", "ibn umar", "muhajirun", "emigrants", "new diseases", "taun", "five things"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He turned to the Emigrants and named five things they would be tested with, praying that they would not live to see them. The first:"),
                      .hadith("ibnmajah:4019", cite: "Sunan Ibn Majah 4019", arabic: 53...74, english: 34...63),
                      .text("The claim is specific in one respect: not more of the old illnesses, but diseases that had never been known among those who came before."),
                  ]),
                  SignSection("WHAT IS SEEN NOW", [
                      .text("Medicine in the last half century has described one new disease after another. The World Health Organization reported in 2007 that nearly forty diseases then known had been unknown a generation earlier, some of them sexually transmitted. Many Muslims read the hadith in that light."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The hadith describes what happens to a society, not a verdict on anyone who falls ill: disease reaches the innocent with everyone else. He also said:"),
                      .hadith("bukhari:2830", cite: "Sahih al-Bukhari 2830", arabic: 31...34, english: 4...17),
                  ]),
              ]),
        .init(id: "wish-grave", title: "Wishing to be in the grave",
              summary: "A man will pass a stranger's grave and wish he were in its place, out of hardship, not devotion.",
              group: .endTimes,
              aliases: ["grave", "death", "despair", "calamity", "hardship", "bala", "tribulation", "trials", "wish for death", "abu hurayrah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .hadith("bukhari:7115", cite: "Sahih al-Bukhari 7115", arabic: 21...32, english: 4...28),
                      .text("Another narration of Abu Hurayrah, which Muslim also records, gives the reason:"),
                      .hadith("ibnmajah:4037", cite: "Sunan Ibn Majah 4037", arabic: 31...56, english: 0...60),
                  ]),
                  SignSection("WHAT IT DESCRIBES", [
                      .text("The words are carefully chosen. He taught his followers not to wish for death because of hardship:"),
                      .hadith("bukhari:5671", cite: "Sahih al-Bukhari 5671", arabic: 24...49, english: 4...51),
                      .text("The man in the prophecy is not longing for the next life. He is at another man's grave, envying its occupant because this world has become too heavy to carry."),
                  ]),
                  SignSection("WHAT IS SEEN NOW", [
                      .text("This is a sign of a state of mind rather than an event, so it has no date. It is recognisable all the same: people who lived through the sieges, famines and wars of recent history have described this, envying the dead. He gave it as a sign of the Hour, and left the Hour's time with Allah."),
                  ]),
              ]),
    ]

    // MARK: Still to come

    /// The greater signs of the Hour that have not yet come, believed as part of faith in the Last
    /// Day (Ibn Kathir's al-Nihayah, Ibn Hajar, Ibn Baz, Ibn 'Uthaymin on al-Wasitiyyah) and kept out
    /// of `strongestIDs` on purpose: a sign still to come proves nothing yet.
    static let toComeEntries: [Entry] = [
        .init(id: "ten-signs", title: "Ten signs before the Hour",
              summary: "Ten great signs before the Hour, named in one sitting: none has yet come, and all are believed as part of faith.",
              group: .toCome,
              aliases: ["major signs", "greater signs", "ashrat", "ashrat al-saah", "hudhayfah ibn usayd", "smoke", "dukhan", "landslides", "khasf", "fire from yemen", "gathering", "mahshar"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Hudhayfah ibn Usayd was sitting with a group of Companions when the Prophet came out to them and asked what they were discussing. They were talking about the Hour. He did not give them a time; he told them what they would see before it, and counted ten signs."),
                      .hadith("muslim:2901a", cite: "Sahih Muslim 2901a", arabic: 59...105, english: 38...124),
                      .text("Ten things in one sentence: a smoke; Dajjal; a beast out of the earth; the sun rising in the west; the descent of 'Isa son of Maryam; Gog and Magog; three sinkings of the earth, one in the east, one in the west and one in Arabia; and, last of them, a fire out of Yemen that drives people toward the place of their gathering. Each has its own article in this group where the shelf carries more on it."),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ahl al-Sunnah hold these as the greater signs, the ones that change the world rather than its habits. All are believed because he said them, and belief in them is part of belief in the Last Day, as Ibn 'Uthaymin sets out in his commentary on al-'Aqidah al-Wasitiyyah. Ibn Kathir gathers the narrations in al-Nihayah and Ibn Hajar discusses their order in Fath al-Bari: the hadith does not rank them, and the order the scholars draw from other texts is Dajjal, then 'Isa, then Gog and Magog, then the sun from the west and the beast close together, with the fire the last of all."),
                      .text("On the smoke, the scholars record a disagreement among the Companions themselves. Ibn Mas'ud read the smoke of Surah al-Dukhan (44:10) as the famine that struck Quraysh in the Prophet's lifetime, when a hungry man looked at the sky and saw it as smoke; Hudhayfah's narration counts a smoke still to come. Ibn Kathir takes both to be true: one smoke seen, and one awaited."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This group gathers the signs the Prophet said would come before the Hour that have not yet come: they are believed as part of faith in the Last Day, and they are kept out of this library's strongest list because a sign still to come proves nothing yet. What is known of the ten is what the narrations say; what is not known is when any of them begins. He said more than once that the Hour's time is with Allah alone."),
                  ]),
              ]),
        .init(id: "dajjal", title: "Dajjal, the one-eyed liar",
              summary: "A man, one-eyed, with kafir written between his eyes: every prophet warned of him, and he has not come.",
              group: .toCome,
              aliases: ["dajjal", "antichrist", "masih ad-dajjal", "one eyed", "kafir", "kahf", "surah al-kahf", "ludd", "trial", "fitnah", "madinah", "refuge"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He spoke of Dajjal more than of any other sign, and he made sure his Companions could recognise him. Anas heard him describe the mark by which every believer will know him:"),
                      .hadith("muslim:2933a", cite: "Sahih Muslim 2933a", arabic: 31...52, english: 0...34),
                      .text("Hudhayfah heard which eye, and what he brings with him:"),
                      .hadith("muslim:2934a", cite: "Sahih Muslim 2934a", arabic: 37...49, english: 0...31),
                      .text("Hisham ibn 'Amir heard him say there is no trial like him between the creation of Adam and the Hour:"),
                      .hadith("muslim:2946a", cite: "Sahih Muslim 2946a", arabic: 72...82, english: 61...81),
                      .text("Two cities are closed to him:"),
                      .hadith("bukhari:1881", cite: "Sahih al-Bukhari 1881", arabic: 29...58, english: 4...68),
                      .text("And he taught the ummah to ask for protection from him in every prayer, in the tashahhud before the salam:"),
                      .hadith("muslim:588a", cite: "Sahih Muslim 588a", arabic: 57...83, english: 10...68),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ahl al-Sunnah hold that Dajjal is a real man of the children of Adam, not a symbol of an age or a system. Ibn 'Uthaymin explains the name as the one who deceives most. The narrations describe him: one-eyed, with a mark every believer reads whether or not he can read; a garden that is a fire and a fire that is a garden; rain and crops for those who follow him and drought for those who refuse; forty days on the earth, the first of them like a year; and death at the hand of 'Isa at the gate of Ludd."),
                      .text("The defence he gave is small and specific: seek refuge from Dajjal's trial in prayer, and, as the long narration of al-Nawwas ibn Sam'an quoted under the descent of 'Isa says, recite the opening verses of Surah al-Kahf over him and hold firm. Ibn Baz counted the hadiths about him as mutawatir, Ibn Kathir devotes the longest section of al-Nihayah to them, and Ibn Hajar gathers them in the book of tribulations in Fath al-Bari."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is what the narrations give: who he is, what he looks like, what he will do, how long he stays and how he dies. What is not known is when he comes, or where he is now; the narration of Tamim al-Dari in Sahih Muslim describes a chained man on an island, and the scholars leave it there. Guesses that name him in a living person, a nation or a machine are not the reading of Ahl al-Sunnah. He is believed as part of faith in the Last Day, not offered as a sign already fulfilled."),
                  ]),
              ]),
        .init(id: "isa-descends", title: "The descent of 'Isa son of Maryam",
              summary: "'Isa will descend as a just ruler, break the cross, end the jizyah and kill Dajjal; held by consensus of Ahl al-Sunnah.",
              group: .toCome,
              aliases: ["isa", "jesus", "son of mary", "ibn maryam", "descent", "nuzul", "cross", "swine", "jizyah", "damascus", "white minaret", "ludd"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("The Quran says that 'Isa was neither killed nor crucified but raised to Allah (4:157–158). The Prophet told his Companions what comes after that, and swore to it:"),
                      .hadith("bukhari:3448", cite: "Sahih al-Bukhari 3448", arabic: 34...65, english: 4...83),
                      .text("Abu Hurayrah, who narrated it, would then recite the verse he read as speaking of that day; and in Surah al-Zukhruf 'Isa is called a sign of the Hour:"),
                      .quran("4:159"),
                      .quran("43:61"),
                      .text("The long narration of al-Nawwas ibn Sam'an gives the moment itself: the place he comes down, what he wears, and what he does with Dajjal:"),
                      .hadith("muslim:2937a", cite: "Sahih Muslim 2937a", arabic: 297...364, english: 440...621),
                      .text("Abu Hurayrah also recorded how he is to be recognised, what he does, and how his stay ends:"),
                      .hadith("abudawud:4324", cite: "Sunan Abi Dawud 4324; graded sahih by al-Albani", arabic: 27...84, english: 4...107),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ibn Kathir writes that the hadiths of his descent are mutawatir, and Ibn Baz and Ibn 'Uthaymin say the same: it is established by the Quran, the Sunnah and the agreement of Ahl al-Sunnah. He descends as a man of this ummah, not with a new law: he rules by the Shari'ah of Muhammad, and when he comes down the Muslims' commander invites him to lead the prayer and he declines (Sahih Muslim 156, under the Mahdi). Breaking the cross and killing the swine end the claims made in his name; ending the jizyah means that in his time no religion but Islam is accepted."),
                      .text("He kills Dajjal, lives among the Muslims, and Gog and Magog are released in his time; after they perish the earth is restored, as the same narration of al-Nawwas describes. The narration of Abu Dawud gives forty years for his stay, then his death and the Muslims' prayer over him. Ibn Kathir reads the verse of Surah al-Nisa' as every one of the People of the Book believing in him before his death, that is, at his descent."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is what the texts give: that he will come, where, in what state, and what he will do. What is not known is when. Ibn Kathir, who lived in Damascus, noted a white minaret standing in his day on the eastern side of the Umayyad Mosque and read the hadith of it; the hadith does not depend on which building it is. This sign is believed as part of faith in the Last Day and in the Prophet's truthfulness, not offered as a proof already fulfilled."),
                  ]),
              ]),
        .init(id: "gog-magog", title: "Gog and Magog, behind the barrier",
              summary: "Two peoples walled in by Dhul-Qarnayn will break out near the end; he saw the first opening in the wall.",
              group: .toCome,
              aliases: ["gog", "magog", "yajuj", "majuj", "dhul qarnayn", "dhu al-qarnayn", "barrier", "wall", "radm", "zaynab bint jahsh", "tiberias", "tur"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Surah al-Kahf tells of Dhul-Qarnayn, who reached a people between two mountains and built an iron barrier between them and Gog and Magog, and said that it would stand until his Lord's promise came:"),
                      .quran("18:93-99"),
                      .text("Surah al-Anbiya' places their release among the last things:"),
                      .quran("21:96-97"),
                      .text("Zaynab bint Jahsh, his wife, saw him come in frightened one day:"),
                      .hadith("bukhari:3346", cite: "Sahih al-Bukhari 3346", arabic: 46...86, english: 15...86),
                      .text("The narration of al-Nawwas ibn Sam'an, quoted under the descent of 'Isa, gives their release after Dajjal is killed, and their end:"),
                      .hadith("muslim:2937a", cite: "Sahih Muslim 2937a", arabic: 404...461, english: 691...803),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ahl al-Sunnah hold that Gog and Magog are real peoples of the children of Adam, shut behind a real barrier, and that their breaking out is one of the ten great signs. Ibn Kathir in al-Nihayah and Ibn Hajar in Fath al-Bari gather the texts: they come out after 'Isa has killed Dajjal, in such numbers that the first of them drink Lake Tiberias dry; 'Isa and the believers take refuge on al-Tur, and Allah ends them with a worm in their necks in a single night. The Hajj continues after them, as Abu Sa'id's narration quoted under the Ka'bah says."),
                      .text("Ibn Hajar reads the hole the Prophet showed with his fingers as the beginning of a breach that widens until the appointed time, and his answer to Zaynab as a rule that holds in every age: ruin comes when wickedness abounds, even with the righteous present. The commentators report sayings of the Salaf on whom they descend from; Ibn Kathir gives them as reports, not as hadith."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is what the Quran and the narrations give: that they exist, that they are held back, and what their release will look like. What is not known is where the barrier stands; the early geographers' guesses and the modern ones are not part of the creed, and no sound text names the place. Believed as part of faith in the Last Day; not a sign already fulfilled."),
                  ]),
              ]),
        .init(id: "mahdi", title: "The Mahdi",
              summary: "A man of his household, bearing his name, will fill the earth with justice before the descent of 'Isa; he has not come.",
              group: .toCome,
              aliases: ["mahdi", "al-mahdi", "ahl al-bayt", "household", "fatimah", "justice", "caliph", "handfuls", "ibn masud", "umm salamah", "hidden imam", "twelfth imam"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Ibn Mas'ud heard him make a promise about the last day of this world. Abu Dawud's text keeps each narrator's wording and says where they agree:"),
                      .hadith("abudawud:4282", cite: "Sunan Abi Dawud 4282; graded hasan sahih by al-Albani", arabic: 70...126, english: 4...71),
                      .text("Umm Salamah heard which line of his family he comes from:"),
                      .hadith("abudawud:4284", cite: "Sunan Abi Dawud 4284; graded sahih by al-Albani", arabic: 42...47, english: 4...15),
                      .text("Abu Sa'id heard of a caliph whose giving will not be counted. The hadith does not name him; Ibn Kathir reads it of the Mahdi, and it is given here as his reading:"),
                      .hadith("muslim:2914", cite: "Sahih Muslim 2914", arabic: 43...51, english: 0...21),
                      .text("Jabir heard what happens when 'Isa comes down and finds the Muslims under a commander. Again the hadith gives no name; Ibn Kathir is among the scholars who read the commander as the Mahdi:"),
                      .hadith("muslim:156", cite: "Sahih Muslim 156", arabic: 42...83, english: 8...73),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("The Mahdi of Ahl al-Sunnah is a righteous ruler, not a prophet and not a hidden man: a descendant of the Prophet through Fatimah, bearing his name and his father's name, who appears at the end of time, rules the Muslims with justice, and is alive when Dajjal comes out and 'Isa descends. Ibn Baz said the hadiths about him are sound and mutawatir in meaning, and the Permanent Committee and Ibn 'Uthaymin affirm the same; Ibn Kathir lists the narrations in al-Nihayah and Ibn Hajar accepts them in Fath al-Bari."),
                      .text("That is also what he is not. He is not the twelfth imam of the Shi'ah, said to have gone into hiding as a child in the third century and to be alive still; the Sunni texts describe a man born and raised among his people. And he is not any of the men who have claimed the title since, whose claims ended with them; the narrations make his sign his justice and his time, not his announcement."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is his name, his line, his justice and his place in the order of the signs. What is not known is when he comes or how he is recognised, and the scholars warn that much of what circulates about him beyond this rests on weak or invented reports. Believed as part of faith in what the Prophet foretold; not a sign already fulfilled, and not a man to be sought out."),
                  ]),
              ]),
        .init(id: "sun-from-west", title: "The sun rising from the west",
              summary: "The sun will rise where it sets, everyone will believe, and belief will no longer count; the door of repentance closes.",
              group: .toCome,
              aliases: ["sun", "west", "sunrise", "maghrib", "repentance", "tawbah", "door of repentance", "6:158", "al-anam", "signs of your lord", "abu hurayrah", "faith no longer avails"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Surah al-An'am warns of a day when some of the signs of the Lord come and faith is accepted no longer. Abu Hurayrah heard the Prophet say which sign that is, and then recite the verse:"),
                      .hadith("bukhari:4636", cite: "Sahih al-Bukhari 4636", arabic: 27...46, english: 4...49),
                      .quran("6:158"),
                      .text("Muslim's wording spells out whose faith will not avail:"),
                      .hadith("muslim:157a", cite: "Sahih Muslim 157a", arabic: 41...71, english: 0...59),
                      .text("And he tied the door of repentance to it:"),
                      .hadith("muslim:2703", cite: "Sahih Muslim 2703", arabic: 71...81, english: 0...26),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ahl al-Sunnah take this as it reads: the sun will rise one morning from the place of its setting, by Allah's command over His creation, and everyone alive will believe at the sight of it. Ibn Kathir in his tafsir of the verse gathers the narrations and the words of the Companions that this is the sign the verse means, and al-Nawawi, Ibn Hajar and Ibn 'Uthaymin follow them. From that day a person who had not believed before gains nothing by believing, and a sinner gains nothing by repenting; faith and repentance are accepted until then and sealed with it."),
                      .text("The narration of 'Abdullah ibn 'Amr, quoted under the beast in this group, makes it the first of the signs in the heavens, with the beast coming out close behind it. Ibn Hajar reads the two sets of signs together: Dajjal, 'Isa and Gog and Magog change the earth first; the sun and the beast then close the door."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is that it will happen, what it means, and what follows it. What is not known is when, nor how it will look beyond the words of the hadith, and the scholars do not describe it in terms of the motions of the heavens. It is believed as part of faith in the Last Day; a sign not yet seen is not offered here as proof."),
                  ]),
              ]),
        .init(id: "the-beast", title: "The beast that speaks to people",
              summary: "A creature from the earth will speak to people; the Quran names it, the hadith sets it beside the sun from the west.",
              group: .toCome,
              aliases: ["beast", "dabbah", "dabbat al-ard", "creature", "earth", "27:82", "an-naml", "speak", "abdullah ibn amr", "forenoon", "staff of musa", "ring of sulayman"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Surah al-Naml says what comes out of the earth when people have stopped being certain of the signs:"),
                      .quran("27:82"),
                      .text("'Abdullah ibn 'Amr memorised one hadith from the Prophet that he never forgot, and it places the beast beside the sun that rises from the west. It is also the third of the ten signs Hudhayfah ibn Usayd counted, quoted at the head of this group."),
                      .hadith("muslim:2941a", cite: "Sahih Muslim 2941a", arabic: 44...65, english: 25...73),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ahl al-Sunnah hold that the beast is a real animal that Allah brings out of the earth near the end, and that it speaks to people. Ibn Kathir in his tafsir of the verse and in al-Nihayah, Ibn Hajar in Fath al-Bari, and Ibn 'Uthaymin in his commentary on al-Wasitiyyah count it among the great signs, from the Quran and from the hadith of the ten."),
                      .text("The commentators report sayings of the Salaf about what it says and that it marks believer and disbeliever apart; Ibn Kathir gives these as reports. The narration that gives it the staff of Musa and the ring of Sulayman is graded weak by al-Albani and by every grader the shelf lists, so it is not quoted here."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is the verse and the two sound hadiths: a creature, from the earth, speaking, near the sun's rising from the west. What is not known is its form, where it comes out, or what exactly it says; readings that make it a machine or a disease are guesses the scholars do not make. Believed as part of faith in the Last Day; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "jews-and-stones", title: "The stone and the tree",
              summary: "The stone and the tree will give the Jews away, in a battle the scholars place in the age of Dajjal and 'Isa.",
              group: .toCome,
              aliases: ["jews", "yahud", "stone", "tree", "gharqad", "boxthorn", "fight", "dajjal", "isa", "isfahan", "abu hurayrah", "battle"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah heard him describe a battle at the end of time in which even the ground takes the Muslims' side:"),
                      .hadith("bukhari:2926", cite: "Sahih al-Bukhari 2926", arabic: 31...47, english: 4...39),
                      .text("Muslim's wording adds the tree, and the one tree that stays silent:"),
                      .hadith("muslim:2922", cite: "Sahih Muslim 2922", arabic: 29...65, english: 0...70),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("The scholars place this in the age of Dajjal and 'Isa, not before it. Sahih Muslim records that seventy thousand Jews of Isfahan follow Dajjal when he comes out, and the long narration of al-Nawwas has 'Isa kill him and then pursue those who stood with him; Ibn Kathir and al-Nawawi read the stone and the tree as the end of that battle, when the earth itself is made to speak for the believers. It is a thing Allah will bring about on that day, in that war, under that prophet. It is not a programme, and it was never given as one."),
                      .text("Al-Nawawi notes that the gharqad is a kind of thorn tree known in the land of Bayt al-Maqdis; the hadith says only that it stays silent, and the scholars draw from it nothing more than the measure of that day's help."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is that it will happen and roughly when: at the end, around Dajjal and 'Isa. What is not known is anything beyond that; the hadith names no nation, no century and no battlefield. It describes what Allah will do, not what anyone is told to do, and the scholars have never read it as a licence against a people. Believed as part of faith in the Last Day; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "kaaba-demolished", title: "The Ka'bah demolished",
              summary: "A thin-legged man from Abyssinia will pull the Ka'bah down stone by stone, after Gog and Magog, when no one says Allah.",
              group: .toCome,
              aliases: ["kaaba", "ka'bah", "house", "demolish", "dhul suwayqatayn", "dhu al-suwayqatayn", "abyssinia", "ethiopia", "habashah", "hajj", "qarmatians", "black stone"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah heard it in a single sentence, which al-Bukhari records twice and Muslim three times:"),
                      .hadith("bukhari:1591", cite: "Sahih al-Bukhari 1591", arabic: 34...39, english: 3...15),
                      .text("Ibn 'Abbas heard him say he could almost see the man at it:"),
                      .hadith("bukhari:1595", cite: "Sahih al-Bukhari 1595", arabic: 34...40, english: 4...25),
                      .text("But the House is visited until then, through the greatest of the signs:"),
                      .hadith("bukhari:1593", cite: "Sahih al-Bukhari 1593", arabic: 35...41, english: 4...23),
                      .text("And the Hour itself comes only on people who have forgotten Allah:"),
                      .hadith("muslim:148a", cite: "Sahih Muslim 148a", arabic: 22...31, english: 0...13),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ibn Hajar and Ibn Kathir place this near the very end: after 'Isa, after Gog and Magog, after the good wind that takes every believer's soul, in the time when, as Anas heard, no one on earth says Allah. Until then the Hajj goes on; Abu Sa'id's narration says it continues even after Gog and Magog, and Ibn Hajar reconciles the two texts by their order. Dhul-Suwayqatayn is a description, the man with two thin shanks; the hadith names him by it and by his land, and by nothing else."),
                      .text("History has seen the House attacked without this coming true. In 317 AH (930 CE) the Qarmatians sacked Makkah during the Hajj and carried the Black Stone away for about twenty years, and the building has been damaged and rebuilt more than once; each time it was restored and the Hajj resumed. The sign the hadith describes, a demolition stone by stone in an age when the House is no longer visited, has not happened."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is the man's description, his land, and his place at the end of the order. What is not known is when, or who; no one in history has been him, and the scholars do not name a people or a state as his. Believed as part of faith in the Last Day; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "euphrates-gold", title: "The Euphrates and the mountain of gold",
              summary: "The river will uncover a mountain of gold and people will die fighting over it; whoever is there must take nothing.",
              group: .toCome,
              aliases: ["euphrates", "furat", "al-furat", "gold", "treasure", "mountain", "river", "iraq", "syria", "ninety-nine", "abu hurayrah", "dam"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah heard it with a command attached:"),
                      .hadith("bukhari:7119", cite: "Sahih al-Bukhari 7119", arabic: 35...48, english: 4...29),
                      .text("Muslim's wording tells what the gold does to people:"),
                      .hadith("muslim:2894a", cite: "Sahih Muslim 2894a", arabic: 30...57, english: 0...49),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ibn Hajar and al-Nawawi take the words as they stand: the river's water draws back from a real mass of gold, people hear of it and fight, and nearly all who fight die. The command is the point of the hadith for a believer: whoever is present should not take any of it, and a narrator of Muslim's text adds that his father told him not even to go near it. Ibn Kathir lists it among the signs in al-Nihayah without a date; the scholars do not say whether it comes before or after the greater signs."),
                      .text("The Euphrates has been dammed and has run low in living memory, and people have pointed at each drought. The scholars do not: the hadith's sign is the gold and the killing, and until both are seen nothing has been fulfilled."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is the river, the gold, the fighting and the command. What is not known is when, or what the gold is beyond gold. Reading it into any present event, a dam, a drought or an oilfield, is a guess the scholars do not make. Believed as part of faith in the Last Day; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "qahtan", title: "A man from Qahtan",
              summary: "A man of Qahtan will drive the people with his staff before the Hour: a ruler near the end, and nothing more is known.",
              group: .toCome,
              aliases: ["qahtan", "qahtani", "al-qahtani", "yemen", "yemeni", "staff", "stick", "asa", "ruler", "abu hurayrah", "mahdi", "end times"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Qahtan is the ancestor of the Arabs of the south, the tribes of Yemen. Abu Hurayrah heard this in one line, which al-Bukhari records twice:"),
                      .hadith("bukhari:7117", cite: "Sahih al-Bukhari 7117", arabic: 26...36, english: 4...21),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ibn Hajar reads the staff as an image: driving the people with it is a way of saying they obey him and gather to him, and the hadith does not say whether his rule is just. He places the man near the end, and records reports from the early generations that he comes after the Mahdi and walks in the Mahdi's way; he gives them as reports, not as hadith. Ibn Kathir lists him among the signs in al-Nihayah with the same caution."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is his tribe and that he will rule. What is not known is his name, his time beyond the words before the Hour, or his character; the texts give nothing more, and the scholars add nothing more. Believed as part of faith in what the Prophet foretold; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "jahjah", title: "Al-Jahjah",
              summary: "Night and day will not end until a man of the freed slaves called al-Jahjah rules; nothing else is said of him.",
              group: .toCome,
              aliases: ["jahjah", "al-jahjah", "jahjaah", "mawali", "freed slaves", "ruler", "king", "throne", "abu hurayrah", "end times", "tirmidhi"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah heard a name and a promise:"),
                      .hadith("muslim:2911", cite: "Sahih Muslim 2911", arabic: 37...46, english: 0...19),
                      .text("Al-Tirmidhi's wording keeps one more detail: he is of the mawali, the freed slaves and their descendants, not of the Arab tribes:"),
                      .hadith("tirmidhi:2228", cite: "Sunan al-Tirmidhi 2228; graded sahih by al-Albani", arabic: 32...43, english: 0...17),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("The scholars pass this on as it stands. Al-Nawawi explains the name and the word mawali and goes no further; Ibn Kathir lists the hadith among the signs; Ibn Hajar notes it beside the man from Qahtan without joining the two. No one in the record has borne the name and ruled, and the texts give neither a time nor a place."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is the name, his origin among the mawali, and that he will rule. Nothing else is known, and nothing else is claimed here. Believed because the Prophet said it, as part of faith in what he foretold; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "constantinople-takbir", title: "The city on land and sea, taken with takbir",
              summary: "Seventy thousand of the sons of Ishaq take the city by takbir alone, and Dajjal appears while they divide the spoils.",
              group: .toCome,
              aliases: ["constantinople", "istanbul", "qustantiniyyah", "bani ishaq", "banu ishaq", "isaac", "takbir", "seventy thousand", "spoils", "dajjal", "1453", "muhammad al-fatih"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He asked his Companions whether they had heard of a city with one side on land and one on the sea; they had. Then he told them how it would be taken:"),
                      .hadith("muslim:2920a", cite: "Sahih Muslim 2920a", arabic: 34...139, english: 0...188),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("The commentators take the city to be Constantinople, which sits on the sea on one side and on land on the other. Al-Nawawi records that the text in every copy reads the sons of Ishaq, and that al-Qadi 'Iyad thought the sense wanted the sons of Isma'il, the Arabs; Ibn Kathir in al-Nihayah keeps Ishaq and reads them as Romans who have entered Islam by then. The details are what mark the event: no weapon, no arrow, the walls falling at the takbir, and the cry that Dajjal has come out while the spoils are being shared."),
                      .text("The scholars differ on whether the conquest of 857 AH (1453 CE) by Muhammad al-Fatih, with cannon and after a siege, was the conquest of this hadith. Some count it a first conquest and expect a second; most of the Salafi scholars, reading the details, hold the hadith's conquest to be still to come, since none of its marks was present in 1453. Ibn Kathir, who died before it, expected the city's conquest to come shortly before Dajjal, as the narrations order it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What is known is the manner of the taking and what follows it. What is not known is when, and whether the city is the one taken in 1453 or that city in a later age; the scholars say both, and this entry says both and stops. Believed as part of faith in what the Prophet foretold; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "beasts-speak", title: "When the beasts of prey speak",
              summary: "Wild beasts will speak to people, and a man's whip, sandal strap and thigh will tell him what his family did.",
              group: .toCome,
              aliases: ["beasts", "predators", "animals speak", "wolf", "whip", "sandal", "strap", "thigh", "family", "abu said", "wild beasts", "signs of the hour"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Sa'id al-Khudri heard him swear to it:"),
                      .hadith("tirmidhi:2181", cite: "Sunan al-Tirmidhi 2181; graded sahih by al-Albani", arabic: 28...51, english: 0...49),
                      .text("It was not the first time his Companions heard of an animal speaking. One morning after Fajr he told them of a cow and a wolf, and when they were astonished he said he believed it, and so did Abu Bakr and 'Umar:"),
                      .hadith("bukhari:3471", cite: "Sahih al-Bukhari 3471", arabic: 75...120, english: 81...180),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("The scholars read the hadith as it stands: a sign in which Allah makes animals and lifeless things speak, as He made the wolf speak to the shepherd and as the stone and the tree will speak on the day of 'Isa. Ibn Kathir lists it in al-Nihayah among the signs still to come, and the commentators on al-Tirmidhi explain the whip, the strap and the thigh as things of a man's own that will tell him, by Allah's power, what was done in his absence. None of them reads it as a figure of speech."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Modern readers have made the whip a telephone, the strap a camera, the thigh a message on a screen. The scholars do not; the hadith says the things themselves speak, and the Prophet swore to it in those words. What is known is what it says. What is not known is when, and the scholars leave the how to Allah. Believed as part of faith in what he foretold; not offered as a sign fulfilled."),
                  ]),
              ]),
        .init(id: "how-sudden", title: "How suddenly the Hour comes",
              summary: "It comes between a hand and a mouth, a bargain and its close; the right answer is the question he asked the Bedouin.",
              group: .toCome,
              aliases: ["sudden", "baghtatan", "hour", "qiyamah", "milk", "garment", "trough", "prepared", "love", "bedouin", "anas", "7:187"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("The Quran says the Hour comes without warning, and in less than the blink of an eye:"),
                      .quran("7:187"),
                      .quran("16:77"),
                      .text("Abu Hurayrah heard it in three pictures from ordinary life:"),
                      .hadith("muslim:2954", cite: "Sahih Muslim 2954", arabic: 26...52, english: 0...82),
                      .text("Anas was there when a man of the desert asked the only question people ever ask about it, and got a different question back:"),
                      .hadith("bukhari:6167", cite: "Sahih al-Bukhari 6167", arabic: 10...49, english: 0...63),
                  ]),
                  SignSection("WHAT THE SCHOLARS SAY", [
                      .text("Ibn Hajar and al-Nawawi read the three pictures literally: the Hour will open on people in the middle of what they are doing, with no time to finish it. Ibn Kathir in al-Nihayah closes the signs with this, as the texts do: once the last of them has come, the end comes in an instant. The scholars take the reply to the Bedouin as the rule for every question about timing: he was not told when, he was asked what he had prepared, and what he had prepared was love of Allah and His Messenger, which was enough."),
                      .text("This is why the group is here. Ahl al-Sunnah believe the signs because the Prophet gave them, and do not spend them on calculation: Ibn Baz and Ibn 'Uthaymin both warned against fixing dates and against naming the people of the signs among the living. What the signs ask for is what the Bedouin had: faith, repentance before the door closes, and deeds that are ready to be interrupted."),
                  ]),
                  SignSection("A NOTE", [
                      .text("No one knows when the Hour comes, and the Prophet said he did not either. The signs still to come are believed as part of faith in the Last Day; none of them is offered here as fulfilled, and none is offered as a clock. What is known is that it comes, and suddenly; what is not known is the day, and that is by design."),
                  ]),
              ]),
    ]

    // MARK: More: the ummah after him (B)

    static let moreEntriesB: [Entry] = [
        .init(id: "best-generations", title: "The best generations, then the eager swearers",
              summary: "His generation was the best, then the next two; then people whose testimony runs ahead of their oath.",
              group: .ummah,
              aliases: ["qarn", "khayr al-qurun", "sahabah", "companions", "tabiin", "successors", "atba al-tabiin", "salaf", "oath", "testimony", "ibn masud", "mihnah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Ibn Mas'ud heard him rank the generations of his ummah, and then describe the people who would come after them:"),
                      .hadith("bukhari:2652", cite: "Sahih al-Bukhari 2652", arabic: 29...46, english: 4...47),
                      .text("Muslim's wording makes the first of them the generation nearest to him:"),
                      .hadith("muslim:2533a", cite: "Sahih Muslim 2533a", arabic: 32...51, english: 0...40),
                      .text("The Quran had already set the first two side by side, the Companions and those who followed them in good:"),
                      .quran("9:100"),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Qarn, the word translated as generation, means the people of one age. Ibn Hajar, commenting on this hadith, takes the three as the Companions, the Successors who learned from them, and the Successors' students, and that is how the scholars of hadith have ranked the first three generations ever since. By his reckoning the age of the Companions closed around 110 AH, when the last of them died, and the third generation was ending by about 220 AH."),
                      .text("Ibn Hajar then describes what followed the third generation: innovations appeared and spread openly, the Mu'tazilah loosened their tongues, the philosophers raised their heads, and the people of knowledge were put on trial to make them say the Quran is created. That trial, the mihnah, began under the caliph al-Ma'mun in 218 AH, and Ahmad ibn Hanbal was imprisoned and flogged for refusing it."),
                      .text("The second half of the saying was the part the narrators themselves took hardest. Ibrahim al-Nakha'i, a scholar of Kufa in the second generation, adds in al-Bukhari's text that as boys they were beaten for taking oaths and giving testimony lightly. A witness who swears before he is asked, and takes an oath as readily as he gives evidence, is a man who has stopped weighing his words, and that habit has been common in every age since."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("He ranked three generations while only the first was alive, and the ranking held: the ummah's own scholars, counting back centuries later, drew the line where he had drawn it. Then he described what the fourth would bring, and the historians of his community wrote it down as it happened."),
                  ]),
              ]),
        .init(id: "seventy-three-sects", title: "Seventy-three sects, and one of them saved",
              summary: "His ummah would split into seventy-three sects, as the nations before it had, and one of them would be saved.",
              group: .ummah,
              aliases: ["firqah", "firaq", "sects", "iftiraq", "division", "jamaah", "ahl al-sunnah", "saved sect", "firqah najiyah", "khawarij", "qadariyyah", "mutazilah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah reports it in the form the Sunan carry most often:"),
                      .hadith("abudawud:4596", cite: "Sunan Abi Dawud 4596; graded hasan sahih by al-Albani", arabic: 26...47, english: 4...35),
                      .text("'Awf ibn Malik heard it with its end: the fate of the sects, and the name of the one that is safe."),
                      .hadith("ibnmajah:3992", cite: "Sunan Ibn Majah 3992; graded sahih by al-Albani", arabic: 38...90, english: 0...78),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The sects came, and they came early. The Khawarij broke away in 37 AH and have two articles of their own in this library. Before the first century was out, Ma'bad al-Juhani was denying the divine decree in Basra, the dispute that opens the hadith of Jibril in Sahih Muslim, and the Murji'ah, who set deeds apart from faith, had appeared in Kufa."),
                      .text("The second century added the Rafidah, who took their name in Kufa in 122 AH when they deserted Zayd ibn 'Ali for refusing to curse Abu Bakr and 'Umar; the Jahmiyyah of Jahm ibn Safwan, who denied the attributes of Allah; and the Mu'tazilah of Wasil ibn 'Ata', who set reason over the texts and said the Quran was created. Each is a matter of record, with a named founder and a date, and each has its chapter in the books the ummah's scholars wrote to catalogue them."),
                      .text("The one he called the Jama'ah is, as the scholars of the Sunnah have always explained it, the body that holds to what he and his Companions were upon: Ahl al-Sunnah wal-Jama'ah. It is a description, not the name of a party, and whoever matches it belongs to it."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("He said it when his followers were one body, praying behind one man in one mosque, and he gave the splitting a shape: many groups, one of them right, the rest in danger. The groups that appeared did so with the mark he had given them, each taking a part of the religion and leaving the rest."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The number is not a tally to be ticked off. Scholars from Ibn Taymiyyah onward have warned against naming sects to make the count come out, and they read 'in the Fire' as a threat these groups have earned, not a ruling that they are outside Islam: the ones that remain within the ummah are Muslims who have gone astray."),
                  ]),
              ]),
        .init(id: "strangers", title: "Islam began as a stranger",
              summary: "Islam began as something strange and would return to being strange as it began; blessed are the strangers.",
              group: .ummah,
              aliases: ["ghurabaa", "ghuraba", "gharib", "tuba", "strange", "strangeness", "abu hurayrah", "ibn masud", "nuzza", "tribes", "sunnah", "ibn rajab"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah reports a saying with the shape of a prophecy: Islam had begun one way, and it would end the same way."),
                      .hadith("muslim:145", cite: "Sahih Muslim 145", arabic: 39...47, english: 0...21),
                      .text("Ibn Mas'ud's narration adds a question and its answer:"),
                      .hadith("ibnmajah:3988", cite: "Sunan Ibn Majah 3988; graded sahih by al-Albani", arabic: 31...48, english: 0...34),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The beginning is a matter of record. In Makkah the believers were a handful, hiding their prayer, tortured for it, driven out to Abyssinia and then to Madinah. The Arabic word gharib means a foreigner, someone with no people around him, and that is what a Muslim was in his own city. Within the Prophet's lifetime all of Arabia had entered Islam, and the strangeness seemed to have ended for good."),
                      .text("The return is the part the scholars read with care. Al-Nawawi read it as a dwindling: Islam would be held by few again, as at the start. Ibn Rajab, writing in the eighth century AH, gave the strangers a treatise of their own and described them as the people who hold to the Sunnah as the Companions knew it when their own people have left it: strangers not among unbelievers, but among Muslims."),
                      .text("The word in Ibn Mas'ud's narration, nuzza', is those who pull away from their tribes. The commentators took it in two ways that do not conflict: the first Muslims, who left their tribes for the religion, and anyone since who leaves what his people are on in order to hold to it."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It was said when Islam was winning. Its shape is a circle, and history has drawn one: a Muslim can live today in a city of Muslims and still be a stranger for keeping to what the first Muslims kept to. The saying does not complain about that; it congratulates the strangers."),
                  ]),
              ]),
        .init(id: "victorious-group", title: "A group that never stops",
              summary: "A group of his ummah would stay on the truth, unharmed by those who forsake them, until the command of Allah comes.",
              group: .ummah,
              aliases: ["taifah mansurah", "al-taifah al-mansurah", "victorious group", "ahl al-hadith", "people of knowledge", "muawiyah", "thawban", "mughirah", "sham", "ibn baz", "ahmad ibn hanbal", "nawawi"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Mu'awiyah heard it from him. In al-Bukhari's text he repeats it, and Malik ibn Yukhamir, who was there, adds what he had heard from Mu'adh ibn Jabal: that they would be in Sham."),
                      .hadith("bukhari:3641", cite: "Sahih al-Bukhari 3641", arabic: 26...47, english: 6...53),
                      .text("Thawban's narration says what they stand on:"),
                      .hadith("muslim:1920", cite: "Sahih Muslim 1920", arabic: 37...54, english: 0...50),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The saying is a guarantee with one end date, the command of Allah. Fourteen centuries have passed since, with civil wars, the Mongol sack of Baghdad in 656 AH, the loss of al-Andalus, the colonial age and the abolition of the caliphate in 1924, and at no point has the religion been without people who held to it, taught it and defended it. Communities that seemed finished produced scholars again within a generation."),
                      .text("The scholars identified the group by what it does, not where it sits. Ahmad ibn Hanbal said that if they were not the people of hadith he did not know who they were. Al-Bukhari himself said they are the people of knowledge. Al-Nawawi allowed that they might be scattered: some fighters, some jurists, some hadith scholars, some callers to good. Ibn Baz, in our time, described them as the people of knowledge and faith who hold to the truth and act on it, wherever they are found."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("Religions and empires have gone out, and the one that said of itself that it would never go out was, when he said it, a few thousand people in one town. He added that abandonment would not harm them, which rules out the easy reading that the group is whoever happens to be strong."),
                  ]),
              ]),
        .init(id: "mujaddid", title: "A renewer at the head of every century",
              summary: "Allah would send this ummah, at the head of every hundred years, one who renews its religion for it.",
              group: .ummah,
              aliases: ["mujaddid", "tajdid", "renewal", "reviver", "century", "hundred years", "umar ibn abd al-aziz", "al-shafii", "abu hurayrah", "revive", "sunan abi dawud"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah reports it, and Abu Dawud opened his chapters on the battles and trials of the last days with it:"),
                      .hadith("abudawud:4291", cite: "Sunan Abi Dawud 4291; graded sahih by al-Albani", arabic: 36...49, english: 4...25),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The scholars took the saying as a promise and looked for its people. From early on they named 'Umar ibn 'Abd al-'Aziz, the caliph who died in 101 AH after restoring justice and the Sunnah in a reign of under three years, as the renewer of the first century, and al-Shafi'i, who died in 204 AH after setting out the principles of the law, as the renewer of the second. Later centuries have their own candidates, and the lists disagree."),
                      .text("That is where the record stops. The hadith promises a renewer; it does not name one, and no narration says who any of them was. The identifications are the scholars' reading of their own history, offered with respect and sometimes with disagreement, and they are given here as that and nothing more."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("The religion was new and its people few; nothing suggested it would need reviving, let alone a hundred years at a time. The saying assumes a long future in which the religion wears down and is restored again and again, and that is the shape its history has taken."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars differ on whether the head of the century is its beginning or its end, and on whether the renewer must be one person; Ibn Hajar and others allowed that it may be several people in different fields and lands. None of this is settled by the text."),
                  ]),
              ]),
        .init(id: "twelve-caliphs", title: "Twelve rulers, all of Quraysh",
              summary: "Islam would stand strong under twelve rulers, all from Quraysh; the Sunni scholars count them among the early caliphs.",
              group: .ummah,
              aliases: ["twelve caliphs", "ithna ashar", "khalifah", "quraysh", "jabir ibn samurah", "umayyads", "abd al-malik", "ibn kathir", "ibn hajar", "qadi iyad", "imams", "rulers"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Jabir ibn Samurah heard it as a boy, with his father beside him to catch the words he missed:"),
                      .hadith("muslim:1821a", cite: "Sahih Muslim 1821a", arabic: 58...88, english: 16...65),
                      .text("Another of his narrations gives the condition the twelve are tied to:"),
                      .hadith("muslim:1821b", cite: "Sahih Muslim 1821b", arabic: 24...33, english: 8...27),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The one detail no reading disputes is the tribe. Every caliph from Abu Bakr to the fall of Baghdad in 656 AH, Rightly Guided, Umayyad and Abbasid, was a man of Quraysh, across six centuries and three dynasties that had little else in common."),
                      .text("The Sunni reading starts from the wording: the people's affairs would run well, and the religion stand strong, so long as these twelve ruled. Ibn Hajar, following al-Qadi 'Iyad, counted the rulers under whom the ummah was one body and Islam held its strength: the four Rightly Guided caliphs, then Mu'awiyah and the Umayyads after him, up to the civil war that broke the dynasty in 126 AH, after which that unity never returned. He leaned toward this reading over the others."),
                      .text("Ibn Kathir agrees that the twelve are not a list of appointed imams and need not rule in succession. He counts the four Rightly Guided and 'Umar ibn 'Abd al-'Aziz among them, allows for some of the Abbasids, and holds that the number is not yet complete, with the Mahdi among those to come. The scholars differ on the count; what they share is the kind of ruler meant, one under whom the religion stands strong and the community is one."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ahl al-Sunnah do not read this hadith as naming twelve infallible imams: its subject is rule, its condition is that the people's affairs run well under them, and Jabir heard it with no names attached. Where the count falls is a matter on which the scholars differ, and this article leaves it there."),
                  ]),
              ]),
        .init(id: "slave-girl-mistress", title: "When the slave-girl gives birth to her mistress",
              summary: "The first sign Jibril was given: a slave woman bearing her own master or mistress, read two ways by the scholars.",
              group: .ummah,
              aliases: ["amah", "rabbatuha", "rabbaha", "hadith of jibril", "gabriel", "signs of the hour", "disobedience", "uquq", "parents", "mothers", "slave woman", "concubine"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In al-Bukhari's text Jibril asks about the Hour, and the Prophet answers that the one asked knows no more than the asker, but that he will tell him its portents, the first of which is:"),
                      .hadith("bukhari:50", cite: "Sahih al-Bukhari 50", arabic: 95...98, english: 154...162),
                      .text("In Muslim's text, which 'Umar reports, the word is rabbatahā, her mistress, and the second sign follows at once:"),
                      .hadith("muslim:8a", cite: "Sahih Muslim 8a", arabic: 325...345, english: 527...565),
                      .text("The second sign has an article of its own in this library, among the signs before the Hour. This one is about the first."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The classical commentators read it in two main ways, and allow both. Ibn Hajar leaned toward the reading that it foretells the spread of disobedience to parents: a son or daughter ordering a mother about as an owner orders a servant, until the child is in effect her master. The hadith is giving signs of a world turned upside down, and nothing turns it over more plainly than that."),
                      .text("The other reading goes back to al-Khattabi: with the conquests, captive women bore children to their Muslim masters, and a child born free of a bondwoman stood to her as her master. That was already true within a generation of the saying, in the households of the Companions, and al-Nawawi gave it as the first explanation. On this reading the sign came quickly; on Ibn Hajar's it is the long decline of respect for parents, which no one now needs to be shown."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars allow both readings and do not force a choice, and this article does not either. What is not in doubt is the setting: he was asked for the Hour's time, said he did not know it, and gave signs instead. Everything in the hadith turns on that honesty."),
                  ]),
              ]),
        .init(id: "rulers-after-me", title: "Rulers after me, and what to do with them",
              summary: "He warned Ka'b of rulers who would lie and oppress, and told Hudhayfah to hear and obey even when his back was beaten.",
              group: .ummah,
              aliases: ["umara", "rulers", "kings", "tyranny", "oppression", "kab ibn ujrah", "hudhayfah", "hawd", "obedience", "rebellion", "khuruj", "patience"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Ka'b ibn 'Ujrah heard a warning addressed to him by name, and a line drawn through it:"),
                      .hadith("tirmidhi:614", cite: "Sunan al-Tirmidhi 614; graded sahih by al-Albani", arabic: 45...93, english: 7...107),
                      .text("Hudhayfah, who made a habit of asking about the evil to come, was told what the rulers of that time would be like:"),
                      .hadith("muslim:1847b", cite: "Sahih Muslim 1847b", arabic: 92...109, english: 86...123),
                      .text("He asked what to do if he lived to see it:"),
                      .hadith("muslim:1847b", cite: "Sahih Muslim 1847b", arabic: 124...133, english: 143...169),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The caliphate of the four lasted thirty years, as he had said it would, and kingship followed; that story is told in the article on the thirty years of caliphate. What this saying foretells is the character of much of the rule that came after: rulers who lied, who oppressed, and who gathered men to their doors to approve of both. The histories of the Umayyads, the Abbasids and the dynasties after them are full of such courts, and of scholars asked to lend them their standing."),
                      .text("The line he drew held too. The scholars who refused those doors, or entered them and spoke the truth there, are the ones the ummah remembers, Sa'id ibn al-Musayyib and Ahmad ibn Hanbal among many. The hadith made the test one of lies and oppression, not of attendance: a man could enter and keep his place with the Prophet, or stay away and still lose it."),
                      .text("The duty it carries is the part Ahl al-Sunnah have held to. Hudhayfah was told to hear and obey even when his back was beaten and his wealth taken, and in the other narration to cling to the body of the Muslims and their leader. From this and its like the scholars drew the rule that a Muslim does not rebel against a ruler who still prays and shows no open disbelief, however much he wrongs, because the blood that rebellion spills is the greater harm. Ibn Baz and Ibn 'Uthaymin stated it in those terms in our time."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("He ruled a state whose governors he appointed himself, and he described the rulers of his people as liars and oppressors in the same breath as he gave the rule for living under them. A founder who expects his successors to be good does not leave instructions for when they are not."),
                  ]),
              ]),
        .init(id: "fitan-dark-night", title: "Trials like pieces of a dark night",
              summary: "Trials like the dark of night: a believer at dawn, a disbeliever by dusk, his religion sold for a scrap of the world.",
              group: .ummah,
              aliases: ["fitan", "fitnah", "tribulations", "dark night", "badiru", "hasten", "good deeds", "apostasy", "riddah", "abu hurayrah", "civil war", "nawawi"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah reports a command with its reason attached:"),
                      .hadith("muslim:118", cite: "Sahih Muslim 118", arabic: 37...57, english: 0...63),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The first of those nights fell within a generation. 'Uthman was killed in his own house in 35 AH, and the battles of the Camel and Siffin followed, then the Khawarij, who declared Muslims disbelievers and killed them, then Karbala in 61 AH and the sack of Madinah at al-Harrah in 63 AH. Men who had sat with the Prophet found themselves on opposite sides of a battlefield, and many could not tell which side was right."),
                      .text("Al-Nawawi explains the image: trials so dark that a man cannot see his way in them, and so fast that his state changes between morning and evening. The selling is the point. A religion given up not for an argument but for a price: a post, a payment, safety. The scholars read the hadith as a description of every age of trial since, not of one, and as the reason for the command that opens it."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It was said to people who had paid for their faith with their homes and were not about to sell it. He told them a time would come when faith changed hands in a day, and the first such time came while some of them were still alive to see it."),
                  ]),
              ]),
        .init(id: "horn-of-the-east", title: "The horn of Shaytan rises in the east",
              summary: "He blessed Sham and Yemen and left out Najd: there were the earthquakes, the trials, and the horn of Shaytan.",
              group: .ummah,
              aliases: ["najd", "qarn al-shaytan", "horn of satan", "east", "iraq", "kufa", "basra", "sham", "yemen", "ibn umar", "salim", "khawarij"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Ibn 'Umar remembered a prayer he made more than once, and what he said when the people asked him to add a third land to it:"),
                      .hadith("bukhari:7094", cite: "Sahih al-Bukhari 7094", arabic: 25...69, english: 4...88),
                      .text("Ibn 'Umar's son Salim quoted his father's narration of it to the people of Iraq in his own day, and added what he saw them doing:"),
                      .hadith("muslim:2905f", cite: "Sahih Muslim 2905f", arabic: 35...84, english: 0...66),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Najd is high land, and whose Najd is meant depends on where the speaker stands. Ibn Hajar, following al-Khattabi, explains that Madinah's Najd, the high country to its east, is the land of Iraq and what lies beyond it, and in Muslim's narrations the Prophet points east as he speaks. Ibn Baz and Ibn 'Uthaymin read it the same way. The hadith marks a direction, not a people."),
                      .text("What rose in that direction is a matter of record. The Khawarij gathered at Harura' near Kufa in 37 AH and were fought at al-Nahrawan the next year; 'Ali was killed in Kufa in 40 AH; al-Husayn was killed at Karbala in 61 AH. The first man to deny the divine decree did so in Basra, as the hadith of Jibril in Sahih Muslim records, and the Jahmiyyah and the Mu'tazilah took shape in the same lands. Salim's words to the people of Iraq, quoted above, were spoken into the middle of it."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("Iraq was under Persian rule when he said it. He blessed two lands that became the first homes of Islam outside Arabia, set a third apart as the source of trials, and the first great trials of the ummah rose where he had pointed."),
                  ]),
              ]),
        .init(id: "wealth-trial", title: "The trial of this ummah is wealth",
              summary: "Every ummah has its trial, and the trial of his would be wealth; he feared it for them more than poverty.",
              group: .ummah,
              aliases: ["mal", "money", "fitnah", "riches", "dunya", "bahrain", "jizyah", "abu ubaydah", "khabbab", "kab ibn iyad", "competition", "conquests"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Ka'b ibn 'Iyad heard it in a single sentence:"),
                      .hadith("tirmidhi:2336", cite: "Sunan al-Tirmidhi 2336; graded sahih by al-Albani", arabic: 40...46, english: 0...15),
                      .text("When Abu 'Ubaydah brought the tribute of Bahrain, the Ansar gathered after Fajr in the hope of a share. He smiled at them and said why the money worried him:"),
                      .hadith("bukhari:6425", cite: "Sahih al-Bukhari 6425", arabic: 129...152, english: 148...209),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The Bahrain money was the first of it. Within twenty years of his death the treasuries of Persia and the revenues of Syria and Egypt were flowing into Madinah, and ordinary soldiers came home with sums their fathers had never seen. The Companions felt the change in themselves and said so. Qays ibn Abi Hazim found Khabbab ibn al-Aratt, one of the first Muslims, tortured for his faith in Makkah, building a wall:"),
                      .hadith("bukhari:6431", cite: "Sahih al-Bukhari 6431", arabic: 11...37, english: 0...46),
                      .text("Khabbab died in 37 AH, in the years when the ummah's first war with itself was being fought, and the grievances that led to it included who held the wealth the conquests had brought. The scholars read the two sayings together: wealth was the trial because it was the one thing the ummah was certain to be given, and it has gone on being given. The history of the Muslims since is in large part a history of what wealth did to rulers, to scholars and to ordinary believers, and the complaint is made in every century."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("He said it to people who were poor, and he said poverty was not what he feared for them. The threat he named was the one thing they wanted, and it arrived in the lifetime of the people he said it to."),
                  ]),
              ]),
    ]

    // MARK: More: foretold in the Quran, the empires, and the Companions

    static let moreEntriesA: [Entry] = [
        .init(id: "kawthar-abtar", title: "Cut off: the taunt the Quran turned back",
              summary: "Quraysh called him abtar, cut off with no sons to carry his name; the surah said his hater was the one cut off.",
              group: .quran,
              aliases: ["kawthar", "al-kawthar", "surah 108", "abtar", "cut off", "al-as ibn wail", "as ibn wail", "qasim", "sons", "adhan", "renown", "shani"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("His sons died in childhood: al-Qasim and 'Abdullah in Makkah, and Ibrahim later in Madinah. In Makkah, Quraysh made that a taunt. A man whose sons had died was abtar, cut off: a line that ended with him and a name no one would carry. The commentators report that it was al-'As ibn Wa'il who said it of him. The answer came in the shortest surah of the Quran:"),
                      .quran("108:1-3"),
                      .text("The word is shani', the one who hates. The surah did not name him, and it did not answer the taunt by promising sons. It promised him al-Kawthar, abundance, and turned the word back on the man who had used it: whoever hates you, he is the one cut off."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The men who said it are remembered today, where they are remembered at all, because of him. Al-'As ibn Wa'il's name survives in the books largely as the father of 'Amr ibn al-'As, who became a Muslim, commanded the Prophet's armies and conquered Egypt: the taunter's line continued inside the religion of the man he had taunted."),
                      .text("The Prophet left no son who lived to manhood, and no man's name is spoken more often. It is called from every minaret in every adhan, five times a day; it is said in every prayer at the tashahhud; and it is answered with blessings wherever it is heard. Another Makkan surah had promised exactly that:"),
                      .quran("94:4"),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It was said to a man with no living son, in a city that measured a man by his sons, and it staked the opposite claim: that his mention would last and his enemy's would not. Nothing in his situation in Makkah pointed that way. Fourteen centuries later the claim can be checked against any adhan."),
                  ]),
              ]),
        .init(id: "one-of-two-groups", title: "One of the two groups",
              summary: "Promised the caravan or the army, they hoped for the caravan; the promise was kept with the army, at Badr.",
              group: .quran,
              aliases: ["badr", "caravan", "abu sufyan", "al-anfal", "surah 8", "two parties", "taifatayn", "sad ibn ubadah", "consultation", "2 ah", "abu jahl", "water carriers"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("In Ramadan of 2 AH the Prophet went out from Madinah with about three hundred men, lightly armed, to meet a Qurayshi caravan coming home from Syria under Abu Sufyan. Quraysh marched out of Makkah with about a thousand men to protect it. Abu Sufyan turned the caravan down to the coast and slipped past. The Muslims, who had come for a caravan, found an army. Surah al-Anfal came down after the battle, and it records a promise made before it:"),
                      .quran("8:5-8"),
                      .text("Anas describes the march, and the moment the Muslims learned which of the two they had been given:"),
                      .hadith("muslim:1779", cite: "Sahih Muslim 1779", arabic: 79...121, english: 111...173),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The caravan was gone and the army was there, camped across the wells of Badr. On the morning of 17 Ramadan the two sides met. Quraysh broke; seventy of them were killed, Abu Jahl among them, and seventy were taken captive. What the ayahs say Allah intended by the choice, that the truth be established and the root of the disbelievers cut off, was done by nightfall."),
                      .text("The men who set out had hoped for the group that carried goods and no weapons; the ayah says so plainly. Of the two outcomes the promise allowed, Allah chose the one they feared, and it was the one that mattered. The caravan would have fed Madinah for a season. Badr changed what the Muslims were."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("The promise was one of two, and it would have been kept by either. It was kept by the harder one, and the surah says why. Quraysh, who lost that day, could not say afterwards that the Muslims had gone out looking for a battle: all of Arabia knew they had gone out for a caravan."),
                  ]),
              ]),
        .init(id: "promised-spoils", title: "Many spoils, and this one hastened",
              summary: "Many spoils were promised to the men who pledged under the tree: one hastened, Khaybar, and others not yet within reach.",
              group: .quran,
              aliases: ["hudaybiyah", "bayat al-ridwan", "pledge of the tree", "al-fath", "surah 48", "khaybar", "booty", "ghanaim", "maghanim", "persia", "byzantium", "7 ah"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .text("At al-Hudaybiyah in 6 AH, when word came that 'Uthman had been killed in Makkah, about fourteen hundred Muslims pledged to the Prophet under a tree that they would fight to the death. The report proved false and the truce was signed instead. On the road home Surah al-Fath spoke of that pledge, and of what it would be paid with:"),
                      .quran("48:18-21"),
                      .text("Three things are promised in order: many spoils, one of them hastened, and others the Muslims could not yet reach but which Allah had already encompassed. The men who heard it had just agreed to go home with nothing, under a truce that denied them even the pilgrimage that year."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Khaybar, the richest Jewish settlement in the Hijaz, fell early in 7 AH, within months of the surah. Its lands and date groves were the first great wealth of the Muslim state. The hands held back from them were those of Khaybar's allies in Ghatafan, who never came to its aid, and of Quraysh, bound by the truce they had just signed."),
                      .text("The others came within fifteen years. Damascus fell in 14 AH; Ctesiphon, with the treasury of Persia, and Jerusalem in 16; Egypt by 21 AH. By the end of 'Umar's caliphate the Muslims held land and revenue that no one at al-Hudaybiyah could have reached or imagined."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn Kathir reads 'this one He has hastened for you' as Khaybar, and reports the commentators divided over the 'others': Persia and Byzantium according to al-Hasan and al-Dahhak, Makkah according to Qatadah, and every conquest until the Day of Judgement according to Mujahid. The general reading takes the words at their widest, and the record does not make it choose: all three came."),
                  ]),
              ]),
        .init(id: "nasr-crowds", title: "In crowds, and then his death",
              summary: "People would enter the religion in crowds, and, as Ibn 'Abbas read it, the Prophet would die: both within two years.",
              group: .quran,
              aliases: ["an-nasr", "surah 110", "nasr", "conquest", "afwaj", "delegations", "wufud", "year of delegations", "ibn abbas", "umar", "death of the prophet", "11 ah"],
              sections: [
                  SignSection("WHAT THE QURAN SAID", [
                      .quran("110:1-3"),
                      .text("Ibn 'Abbas said that it was the last surah to come down whole:"),
                      .hadith("muslim:3024a", cite: "Sahih Muslim 3024a", arabic: 39...66, english: 0...50),
                      .text("Years later 'Umar, by then caliph, put the surah to the veterans of Badr with the young Ibn 'Abbas sitting among them, and asked what it meant:"),
                      .hadith("bukhari:4294", cite: "Sahih al-Bukhari 4294", arabic: 57...140, english: 83...269),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The crowds came first. Before the conquest, the tribes of Arabia had held back; 'Amr ibn Salimah, a boy at the time, remembered why:"),
                      .hadith("bukhari:4302", cite: "Sahih al-Bukhari 4302", arabic: 64...91, english: 87...150),
                      .text("Makkah was taken in Ramadan of 8 AH, and 9 AH is remembered as the Year of Delegations: tribe after tribe sent its envoys to Madinah to accept Islam, from Najd, from Yemen, from Bahrain and from Oman. People who had come one at a time for twenty years now came as whole peoples."),
                      .text("Then the second thing. The surah told him, on the day of that help and that conquest, to glorify his Lord and ask His forgiveness: the words of a man whose work is done. The commentators report that it came down in the last months of his life. He died in Rabi' al-Awwal of 11 AH, less than three years after the conquest it names. The old men of Badr had read the surah as a thanksgiving; the boy had read it as a farewell, and 'Umar said he knew nothing in it but what the boy had said."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("A surah of three verses carried two forecasts: a change in the whole of Arabia, and the end of the life of the man reciting it. Ibn 'Abbas took the second from the words themselves, and 'Umar, who knew the Prophet as well as any man alive, agreed with him."),
                  ]),
              ]),
        .init(id: "iraq-withholds", title: "Iraq, Syria and Egypt, and what they would withhold",
              summary: "Iraq, Syria and Egypt named by their coins and measures before the Muslims held any; the withholding is a reading.",
              group: .empires,
              aliases: ["iraq", "sham", "egypt", "misr", "dirham", "dinar", "qafiz", "mudd", "irdabb", "kharaj", "land tax", "nawawi"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah accepted Islam in 7 AH, so this was said in the Prophet's last four years, when Iraq belonged to Persia and Syria and Egypt to the Byzantines, and the Muslim state did not hold one village of any of them."),
                      .hadith("muslim:2896", cite: "Sahih Muslim 2896", arabic: 44...76, english: 0...66),
                      .text("The qafiz, the mudd and the irdabb were the dry measures of those three countries, and the dirham and the dinar their coins: the units in which, under 'Umar, their land tax would come to be assessed. To speak of what the three lands would withhold is to assume that they would first be paying."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The first part came within a decade of his death. Iraq was taken between 14 and 16 AH, Syria between 13 and 16, Egypt by 21 AH, and their revenue, assessed in exactly those coins and measures, became the income of the state in Madinah."),
                  ]),
                  SignSection("A NOTE", [
                      .text("What the withholding means is not a matter of record. Al-Nawawi gives the readings: that the peoples of those lands would stop paying what they owed, whether by accepting Islam, so that the tax lapsed, or by refusing it; or that the Muslims would lose those lands near the end of time and be driven back to where they began. The hadith is given here for what it assumed and for what the scholars say of it, not as a fulfilment claimed."),
                  ]),
              ]),
        .init(id: "land-of-palms", title: "A land of palms, and a notched sword",
              summary: "One dream, two fulfilments: the city of the Hijrah he had guessed wrongly, and the losses of Uhud he had been shown.",
              group: .companions,
              aliases: ["dream", "palm trees", "nakhl", "yamamah", "hajar", "yathrib", "hijrah", "uhud", "sword", "cows", "abu musa", "3 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Before the Hijrah, in Makkah, he was shown in a dream the land he would migrate to. He did not know its name; he knew only that it had palms, and he guessed at two famous date countries. Abu Musa al-Ash'ari transmits the dream, together with the Prophet's own account of how each part of it was answered:"),
                      .hadith("bukhari:3622", cite: "Sahih al-Bukhari 3622", arabic: 35...115, english: 4...142),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The guess was wrong and the dream was right. Al-Yamamah lies east in Najd and Hajar on the Gulf coast; both were known for their dates. The land that opened to him was neither: the men of Yathrib, a palm oasis to the north, met him at al-'Aqabah, and in 622 CE he migrated there, and it became Madinah."),
                      .text("The sword and the cows were answered at Uhud, in Shawwal of 3 AH. Ibn Hajar notes that before the battle, while the Companions were deciding whether to go out to meet Quraysh, he told them he had seen cows being slaughtered and a notch in his sword. At Uhud the Muslims were struck hard: seventy were killed, Hamzah among them, and the Prophet himself was wounded. Muslim's wording of the cows is the plainer:"),
                      .hadith("muslim:2272", cite: "Sahih Muslim 2272", arabic: 96...125, english: 110...161),
                      .text("The blade restored was the recovery that followed: the Muslims regathered, and the victories came. The commentators read the victory it names as the conquest of Makkah or the openings before it, and the gathering of the believers as the unity that returned after the division of Uhud."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("A dream he reported without understanding it is the hardest kind to fake. He guessed al-Yamamah or Hajar and was wrong, and said so; history answered with a city he had not thought of. And he spoke of a notched sword and slaughtered cows before a battle, to the men about to fight it, at a council where any commander would have promised a win."),
                  ]),
              ]),
        .init(id: "two-bracelets", title: "Two bracelets, two liars",
              summary: "Two gold bracelets blown away in a dream: the liars of San'a and al-Yamamah, both alive and in power when he said it.",
              group: .companions,
              aliases: ["bracelets", "bangles", "siwaran", "dream", "al-aswad al-ansi", "musaylimah", "musailima", "sanaa", "yamamah", "fayruz", "liar", "abu hurayrah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("In the last months of his life two men in Arabia claimed to be prophets beside him, each with a following and an army. Al-Aswad al-'Ansi had seized San'a and most of Yemen to the south; Musaylimah of Banu Hanifah held al-Yamamah to the east. Madinah lay between them. Abu Hurayrah heard him tell a dream about the two:"),
                      .hadith("bukhari:4375", cite: "Sahih al-Bukhari 4375", arabic: 30...58, english: 4...73),
                      .text("Muslim has the same dream from Abu Hurayrah, with one more word about how the bracelets weighed on him:"),
                      .hadith("muslim:2274b", cite: "Sahih Muslim 2274b", arabic: 39...68, english: 0...82),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He blew on the bracelets and they were gone: no campaign, no army, no hand of his. That is how both men ended. Al-Aswad was killed inside his own palace in San'a by Fayruz al-Daylami and other men of the city who had kept their Islam, at the very end of the Prophet's life; the historians say the news reached Madinah in the days around his death."),
                      .text("Musaylimah lived about a year longer. In 12 AH, in the caliphate of Abu Bakr, the army of Khalid ibn al-Walid met the forces of Banu Hanifah at al-Yamamah, in the fiercest battle of the wars of apostasy, and Musaylimah was killed there. The Prophet had been dead a year, and had led no campaign against either man."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("The dream fixed a number, two, and a place for each, and it was told while both men ruled, in the last months of the Prophet's life. Either could have outlived the Muslim state, which many in Arabia expected to break up at his death. Neither outlived the year, and he had not lifted a hand against them."),
                  ]),
              ]),
        .init(id: "ibn-salam-handhold", title: "The handhold he would not let go",
              summary: "To 'Abdullah ibn Salam: you will hold to Islam until you die. He lived thirty more years, through every trial, and did.",
              group: .companions,
              aliases: ["abdullah ibn salam", "ibn salam", "dream", "meadow", "rawdah", "pillar", "handhold", "urwah al-wuthqa", "firmest handhold", "qays ibn ubad", "people of paradise", "43 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("'Abdullah ibn Salam had been the leading scholar of the Jews of Madinah before he accepted Islam. Long after the Prophet's death, Qays ibn 'Ubad watched him walk into the Prophet's mosque, heard the people say of him that he was a man of Paradise, and followed him out to ask why:"),
                      .hadith("bukhari:3813", cite: "Sahih al-Bukhari 3813", arabic: 53...158, english: 66...254),
                      .text("The handhold is the one the Quran names, al-'urwah al-wuthqa, the firmest handhold that never breaks:"),
                      .quran("2:256"),
                      .text("Muslim's wording of the Prophet's answer:"),
                      .hadith("muslim:2484a", cite: "Sahih Muslim 2484a", arabic: 186...209, english: 317...359),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He was told one thing about his future: that he would die on Islam. He did not take it as a licence to be called a man of Paradise, and he corrected the people who said so. No one should say what he does not know, he told Qays; he knew the dream, and he knew what he had been told."),
                      .text("He lived on in Madinah through the apostasy wars, the siege of 'Uthman and the wars that followed, and died there in 43 AH, in the caliphate of Mu'awiyah, a Muslim as he had been since the days of the Hijrah. The promise had been kept across three decades of trial."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("A promise about a man's last state is the kind a prophet alone can make, because no one else knows it. Hearts turn, and Islam does not call a man saved on the strength of his present state. It was made to a convert whose own people had called him the worst of them on the day he believed, and his end came as it was promised."),
                  ]),
              ]),
        .init(id: "ansar-after-me", title: "After me, others will be preferred over you",
              summary: "The Ansar would be passed over after his death and should be patient till the Pool; under the Umayyads they were.",
              group: .companions,
              aliases: ["ansar", "helpers", "atharah", "preference", "favouritism", "bahrain", "hawd", "pool", "kawthar", "harrah", "anas", "al-walid"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("The Ansar of Madinah had taken him in, fought his battles and asked for nothing. When he offered to grant them the land of Bahrain, they refused it unless the Muhajirun were given the same. Anas heard what he told them then:"),
                      .hadith("bukhari:3793", cite: "Sahih al-Bukhari 3793", arabic: 21...38, english: 0...37),
                      .text("Once a man of the Ansar took him aside and asked for a post:"),
                      .hadith("muslim:1845a", cite: "Sahih Muslim 1845a", arabic: 37...54, english: 0...40),
                      .text("Atharah is others being preferred over you: in office, in wealth, in the share of what you helped to win. He did not tell them it would be put right. He told them to bear it and to look for him at the Pool."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The caliphate went to Quraysh from the first day, and no Ansari ever held it. Under the Rightly Guided caliphs the Ansar were honoured and consulted. From 41 AH the Umayyads ruled from Damascus, and the governorships, the army commands and the treasury went to their own kin and clients. Ibn Hajar notes that what the Prophet had foretold came to pass in their time."),
                      .text("In 63 AH the army of Yazid sacked Madinah itself after the battle of al-Harrah, and many of the Ansar were killed in the city they had given him. Anas ibn Malik, one of the last of them, was still repeating the words decades later. Yahya ibn Sa'id heard him on the road to the caliph al-Walid ibn 'Abd al-Malik:"),
                      .hadith("bukhari:3794", cite: "Sahih al-Bukhari 3794", arabic: 25...58, english: 14...70),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It is a prophecy against the interest of the people it was told to, delivered to their faces, and it asked them to accept it in advance. A man seeking a following flatters his supporters; he told his that they would be set aside, and they stayed loyal. And they kept the words: the narrators who carry them, Anas and Usayd ibn Hudayr, were Ansar themselves."),
                  ]),
              ]),
        .init(id: "prayer-delayed", title: "Rulers who would delay the prayer",
              summary: "Abu Dharr was told of rulers who would delay the prayer past its time, and what to do then; al-Hajjaj was one of them.",
              group: .companions,
              aliases: ["abu dharr", "prayer times", "salah", "rulers", "umara", "hajjaj", "al-hajjaj", "jabir", "anas", "damascus", "nafilah", "voluntary"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Dharr al-Ghifari was one of the earliest Muslims and died in 32 AH, before any ruler had done what this describes. The Prophet put the case to him as a question:"),
                      .hadith("muslim:648a", cite: "Sahih Muslim 648a", arabic: 38...70, english: 8...80),
                      .text("The instruction is as exact as the forecast: pray at the time, then pray with them, and count the second as voluntary. It assumes that the prayer would be delayed by the men leading it, not by the people, and that the people would still be praying behind them."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Al-Hajjaj ibn Yusuf governed the Hijaz for the Umayyads from 73 AH and then Iraq for twenty years, and he delayed the prayers. Sahih Muslim records it in the words of the man who went to ask Jabir ibn 'Abdullah, the Companion, about the Prophet's own times:"),
                      .hadith("muslim:646b", cite: "Sahih Muslim 646b", arabic: 20...31, english: 0...21),
                      .text("Al-Zuhri found Anas ibn Malik, the Prophet's servant, in tears in Damascus. The historians place the visit in the caliphate of al-Walid ibn 'Abd al-Malik, when Anas had gone to the capital to complain of al-Hajjaj:"),
                      .hadith("bukhari:530", cite: "Sahih al-Bukhari 530", arabic: 25...48, english: 0...51),
                      .text("Abu Dharr passed the instruction on, and the scholars take the ruling from his hadith to this day: the prayer at its time, and then the congregation behind such a ruler, counted as voluntary, so that neither the time nor the community is abandoned."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It foretold a corruption from the top, in the one duty every Muslim performs five times a day, within a community that then prayed exactly as he prayed; and it gave the remedy before the disease. No preacher inventing prophecies for his movement would have told it that its own rulers would neglect the prayer."),
                  ]),
              ]),
        .init(id: "young-quraysh", title: "Young men of Quraysh",
              summary: "The ruin of my ummah at the hands of young men of Quraysh: Abu Hurayrah repeated it to Marwan, and could name them.",
              group: .companions,
              aliases: ["ghilmah", "boys", "youths", "marwan", "umayyads", "banu umayyah", "yazid", "karbala", "husayn", "harrah", "abu hurayrah", "destruction"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Abu Hurayrah said it in the hearing of Marwan ibn al-Hakam, the Umayyad who governed Madinah for Mu'awiyah and later took the caliphate for his house. Sa'id ibn 'Amr, himself an Umayyad, was there:"),
                      .hadith("bukhari:3605", cite: "Sahih al-Bukhari 3605", arabic: 15...51, english: 0...64),
                      .text("Al-Bukhari gives it again in the Book of Trials (7058). There the grandson who carried it from Sa'id adds that Marwan cursed the boys, and that he himself used to go with Sa'id to the court of Banu Marwan when they ruled in Syria; when Sa'id saw them as young boys he would say, perhaps these are among them."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Hurayrah died in 57 or 59 AH, and the reign of Yazid ibn Mu'awiyah began in 60. Ibn Hajar reads the hadith on those years: the killing of al-Husayn and his family at Karbala in 61 AH, the sack of Madinah after al-Harrah in 63, and the siege of Makkah in 64, in which the Kaaba itself was damaged by fire, all in the reign of a caliph who came to power at about thirty-four."),
                      .text("Sa'id ibn 'Amr, who had heard Abu Hurayrah, watched the boys of Banu Marwan grow up in Syria and pointed at them. Abu Hurayrah had said he could name the clans and did not, which is how the Companions spoke of what they knew: enough to be understood, not enough to be a weapon."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("It was said when Quraysh was the Prophet's own tribe and his enemies were mostly its old men. It named the young as the danger and a tribe as the source, and an Umayyad narrator carried it to an Umayyad prince and was not contradicted. Marwan's response was a curse, not a denial."),
                  ]),
              ]),
        .init(id: "fitan-like-rain", title: "Trials falling like rain",
              summary: "From a rooftop he saw trials falling among their houses like rain; the first fell on 'Uthman's house in Madinah, 35 AH.",
              group: .companions,
              aliases: ["fitan", "fitnah", "afflictions", "raindrops", "qatr", "rooftop", "utum", "usamah ibn zayd", "madinah", "uthman", "civil war", "35 ah"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("The utum were the fortified houses of Madinah, the tallest buildings in the town. Usamah ibn Zayd, whom the Prophet had raised almost as a son, was with him on top of one of them:"),
                      .hadith("bukhari:7060", cite: "Sahih al-Bukhari 7060", arabic: 30...59, english: 0...40),
                      .text("Al-Bukhari records it also in the Book of the Virtues of Madinah (1878), with the wording that he saw the places where the trials would fall, among their houses, like the places where drops of rain fall. He was looking down at the Companions' own homes."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("The first drop fell on a house he could have pointed to. In Dhu al-Hijjah of 35 AH, rebels from Egypt, Kufa and Basra besieged 'Uthman in his home in Madinah and killed him there. Ibn Hajar counts his killing as the first of the trials the hadith foresaw, and the one from which the rest flowed."),
                      .text("The rest followed as rain follows the first drop: the battle of the Camel in 36 AH, Siffin in 37, al-Nahrawan in 38, the killing of 'Ali in 40, and in 63 the sack of Madinah itself after al-Harrah, when the trials came into those very houses."),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("He said it in Madinah at the height of its unity, about Madinah, to men who could not see what he saw and said so. He did not name a culprit or take a side; he described the pattern, many trials, close together, falling among the houses of his own Companions, and that is the pattern the next thirty years took."),
                  ]),
              ]),
    ]
}
#endif
