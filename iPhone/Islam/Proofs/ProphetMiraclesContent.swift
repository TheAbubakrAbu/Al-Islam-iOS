#if os(iOS)
import SwiftUI

// The Miracles of the Prophets library's articles, as data (`SignSection` / `SignBlock` in
// SignsAndProphets.swift). The index and the article screen are in ProphetMiraclesView.swift.
//
// The order is the argument (Abu, 2026-09-19: "use this for both a precursor and for Prophet
// Muhammad, as it proves why Prophet Muhammad could have miracles then shows his miracles"): why a
// prophet is given signs at all, the signs of the prophets before him from the Quran, then his own
// from the hadith, every one a row of the bundled shelf (Scripts/verify_prophecies.py).
//
// No em dash, and no spaced hyphen standing in for one.

extension ProphetMiraclesView {
    /// The index order: groups in `Entry.Group` order.
    static let entries: [Entry] = whyEntries + beforeEntries + beforeEntries2 + foretoldEntries + hisEntries + provisionEntries + creationEntries
        + prayerEntries + protectionEntries + hisEntries2

    /// The STRONGEST section, in reading order (Abu, 2026-09-25: "have a strongest tab section").
    ///
    /// Chosen on how hard the report is to explain away: how many people saw it, how many
    /// Companions narrate it, and whether it was put in front of people who wanted it to be false.
    /// The Quran leads because it is the one sign still open to examination; the moon because a
    /// Makkan surah announced it to the city that had watched; then the signs seen by an army or a
    /// crowd of hundreds, and the two whose witness was an outsider or an enemy (the woman with the
    /// water-skins, Abu Jahl). The earlier prophets' signs are not ranked here: they rest on the
    /// Quran's own authority, not on witnesses a reader can weigh.
    static let strongestIDs = [
        "quran", "moon", "water", "trench-feast", "trunk",
        "hudaybiyah-well", "rain-prayer", "water-skins", "abu-jahl-trench", "isra", "ghawrath-sword",
    ]

    // MARK: Why prophets are given signs

    static let whyEntries: [Entry] = [
        .init(id: "why", title: "Why a prophet is given a miracle",
              summary: "A sign is a credential, matched to what the people of that age already prized.",
              group: .why,
              aliases: ["mujizah", "proof", "evidence", "credential", "sign", "purpose"],
              sections: [
                  SignSection("A SIGN IS A CREDENTIAL", [
                      .text("A messenger arrives claiming to speak for God. Anyone can claim that. A miracle is the credential that cannot be forged: something outside the reach of the people being addressed, done openly, in front of those best placed to expose it."),
                      .text("So the sign is always matched to the age. Egypt's court was full of expert magicians, and Moosa was given a staff that swallowed their work. Eesa came to a people who prized healing, and by Allah's permission he healed the blind and the leper and raised the dead. The Arabs had no equal in language, and the sign given to Muhammad (peace and blessings be upon him) was a book."),
                  ]),
                  SignSection("AND WHAT IT CANNOT DO", [
                      .text("A miracle compels no one. The Quran is blunt about this: people watched the sea split and still went back to a calf. A sign removes the excuse of ignorance; it does not remove the choice."),
                      .quran("6:111"),
                  ]),
              ]),
    ]

    // MARK: The prophets before him

    static let beforeEntries: [Entry] = [
        .init(id: "nuh-ark", title: "Nooh and the ark",
              summary: "Mocked while he built it, the ship carried Nooh and the few who believed through the flood, and was left as a sign.",
              group: .before,
              aliases: ["noah", "ship", "flood", "deluge", "judi", "al-judi", "safinah", "tufan", "950 years", "his son", "planks and nails"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("The Quran says Nooh lived among his people for nine hundred and fifty years, calling them to Allah, and that only a few believed. He was then told to build a ship under Allah's watch and by His instruction. He built it in the open, in front of the people who had refused him."),
                      .quran("11:38-39"),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("They laughed at it until the command came. Rain poured from the sky, springs burst from the ground, and the ship rode waves the Quran likens to mountains. His own son stayed apart, and Nooh called him to come aboard:"),
                      .quran("11:43-44"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The Quran describes the ark plainly, as planks and nails, and says it was left behind as a sign:"),
                      .quran("54:13-15"),
                      .text("It says the same of the rescue, calling it a sign for the worlds (29:15). Some early commentators took this to mean the ship itself was left to be seen; others, that every ship afloat since recalls the first. Either way the sign was not only for the people who drowned. It is told to every audience after them: the few who believed were carried, and the many who laughed were not."),
                      .quran("29:15"),
                  ]),
              ]),
        .init(id: "hud-wind", title: "Hood's challenge, and the wind",
              summary: "One man dared the strongest nation of his time to do their worst and came to no harm; then the wind came.",
              group: .before,
              aliases: ["'ad", "ad", "aad", "iram", "ahqaf", "storm", "dabur", "west wind", "east wind", "saba", "cloud", "hood"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("‘Ad were a people of great stature who asked who could be stronger than they were (41:15)."),
                      .quran("41:15"),
                      .text("When Hood called them to worship Allah alone, they gave him their answer, and he gave them his:"),
                      .quran("11:53-56"),
                      .text("The Quran names no wonder for Hood like the she-camel or the staff. Many commentators point to this instead: one man, alone among a powerful and hostile people, told all of them to plot against him together and give him no respite, and he came to no harm. The proof they said he lacked was standing in front of them."),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("They kept their gods. When a cloud at last came towards their valleys, they welcomed it as rain (46:24)."),
                      .quran("46:24"),
                      .text("It was a wind:"),
                      .quran("69:6-8"),
                      .text("Hood and those who believed with him were saved (11:58)."),
                      .quran("11:58"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The Prophet set the two winds side by side, the one that helped him and the one that ended Ad:"),
                      .hadith("muslim:900a", cite: "Saheeh Muslim 900a", arabic: 41...45, english: 0...16),
                      .text("Al-Bukhaari files the same saying under the Battle of the Trench, where a wind scattered the armies camped around Madinah (33:9). Aa’ishah said that when he saw a dark cloud his face would change and he would come and go until it rained; he told her he feared it might be like the cloud ‘Ad had welcomed (Saheeh al-Bukhaari 3206, Saheeh Muslim 899)."),
                      .quran("33:9"),
                      .hadith("bukhari:3206", cite: "Saheeh al-Bukhaari 3206, Saheeh Muslim 899b", arabic: 17...59, english: 0...120),
                  ]),
              ]),
        .init(id: "salih-camel", title: "Saalih and the she-camel",
              summary: "Thamood demanded a sign and were given a she-camel with terms attached; they killed her, and had three days left.",
              group: .before,
              aliases: ["saleh", "thamud", "naqah", "camel", "hijr", "al-hijr", "madain salih", "hegra", "tabuk", "well", "hamstrung", "shared water"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Thamood carved their houses out of the mountains. When Saalih called them to Allah they told him he was a man like them, and should bring a sign if he was truthful (26:154)."),
                      .quran("26:154"),
                      .text("They were given one, with a warning not to harm it."),
                      .quran("7:73"),
                      .text("It came with terms. The water was to be shared: one day hers, one day theirs."),
                      .quran("26:155-156"),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("Some believed. The arrogant among them did not, and they sent the most wretched of them to kill her:"),
                      .quran("91:13-14"),
                      .text("Saalih gave them a deadline:"),
                      .quran("11:65"),
                      .text("When it passed, the blast seized them in their homes, and Saalih and those who believed with him were saved (11:66-67)."),
                      .quran("11:66-67"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The she-camel was a sign they could watch every day, drinking on her appointed day, not a wonder done once and then remembered. The Quran calls her a visible sign, and says what held back signs of the kind the Quraysh demanded: earlier peoples had been given them and denied them. Such signs, it says, are sent only as a warning (17:59)."),
                      .quran("17:59"),
                      .text("On the march to Tabook in 9 AH the Prophet camped at al-Hijr, the land of Thamood, and the she-camel's well was still known:"),
                      .hadith("bukhari:3379", cite: "Saheeh al-Bukhaari 3379", arabic: 25...67, english: 0...77),
                  ]),
              ]),
        .init(id: "ibrahim-fire", title: "Ibraaheem and the fire",
              summary: "His people threw him into a fire for breaking their idols, and the fire was commanded to be cool and safe for him.",
              group: .before,
              aliases: ["abraham", "khalil", "idols", "statues", "nimrod", "namrud", "burned", "furnace", "hasbunallah", "cool and safe", "bardan wa salaman"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Ibraaheem broke his people's idols and left the largest standing, then told them to ask it who had done it. They admitted their gods could not speak. Having no answer, they built a fire and threw him into it. The command that followed was addressed to the fire itself:"),
                      .quran("21:68-70"),
                      .text("The fire was not put out. It was told to be coolness and safety for one man, and Allah saved him from it (29:24)."),
                      .quran("29:24"),
                  ]),
                  SignSection("WHAT HE SAID", [
                      .text("Ibn Abbaas reported the words Ibraaheem said as he was thrown in, and the day the Prophet said them too:"),
                      .hadith("bukhari:4563", cite: "Saheeh al-Bukhaari 4563", arabic: 20...52, english: 0...68),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("They built the fire as a public verdict on him, and it became a public verdict on them: they intended harm, and were made the losers. The Quran says there are signs in it for people who believe (29:24). Yet the one the Quran names as believing him is Loot (29:26), and the two of them left together for the land Allah had blessed (21:71)."),
                      .quran("29:26"),
                      .quran("21:71"),
                  ]),
              ]),
        .init(id: "ibrahim-birds", title: "Ibraaheem and the four birds",
              summary: "He asked to see how Allah gives life to the dead, and four birds came back to him from the hills.",
              group: .before,
              aliases: ["abraham", "khalil", "resurrection", "revival", "give life to the dead", "hills", "certainty", "yaqin", "doubt", "heart at rest", "itminan"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Ibraaheem had told a king to his face that his Lord is the One who gives life and causes death (2:258)."),
                      .quran("2:258"),
                      .text("He believed it; he asked to see it."),
                      .quran("2:260"),
                      .text("Most commentators explain that he took four birds, slaughtered them and mixed their parts, set a portion on each hill, and called them. They came back to him whole, and in haste."),
                  ]),
                  SignSection("WHAT IT WAS FOR", [
                      .text("Allah asked whether he did not believe, and he said he did: he asked only that his heart be at rest. The Prophet ruled out any reading of doubt:"),
                      .hadith("muslim:151a", cite: "Saheeh Muslim 151a", arabic: 33...57, english: 0...37),
                      .text("An-Nawawi and others explain the words this way: if doubt could have reached Ibraaheem, we would be more open to it than he was; we do not doubt, so neither did he. His question was how, never whether."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Saalih's she-camel and Moosa's staff were shown to people who denied, as proof. This one was shown to a prophet who already believed, and it was for certainty: the difference between knowing a thing and seeing it."),
                  ]),
              ]),
        .init(id: "lut-city", title: "Loot's guests, and the city overturned",
              summary: "Angels came to Loot as guests; by morning his city was turned upside down and left on a road for travellers to see.",
              group: .before,
              aliases: ["lot", "sodom", "gomorrah", "angels", "messengers", "stones", "baked clay", "sijjil", "dead sea", "mutafikat", "his wife", "blinded"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("The angels came first to Ibraaheem, with news of a son, and told him they had been sent to Loot's people. Then they came to Loot as guests. His people came hurrying to take them, and Loot, with no one to defend him, wished aloud for some power against them (11:80)."),
                      .quran("11:80"),
                      .text("His guests then told him who they were:"),
                      .quran("11:81"),
                      .text("When the men still demanded his guests, Allah blinded them (54:37)."),
                      .quran("54:37"),
                      .text("Then the morning came:"),
                      .quran("11:82-83"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The ruin was left where it would be seen, on a road people used:"),
                      .quran("15:75-76"),
                      .quran("29:35"),
                      .text("The Quran tells the Quraysh, whose caravans went north to Syria, that they passed it morning and evening (37:137-138). Commentators have long placed it by the Dead Sea, which Arabic has also called the Sea of Loot. The sign was the destruction and the place together: a site people knew, on a road they used, and a story that explained what they saw."),
                      .quran("37:137-138"),
                  ]),
              ]),
        .init(id: "zamzam", title: "The spring of Zamzam",
              summary: "Left with her infant in a dry valley, Haajar ran between two hills until an angel struck the ground and water rose.",
              group: .before,
              aliases: ["hajar", "hagar", "ismail", "ishmael", "safa", "marwah", "sai", "sa'y", "well", "makkah", "mecca", "angel", "jurhum", "sacred mosque"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Ibraaheem brought Haajar and the infant Ismaa‘eel to the valley of Makkah, where no one lived and there was no water, and left them with a bag of dates and a skin of water. She asked him whether Allah had ordered this. He said yes, and she said that then He would not abandon them."),
                      .text("When the water ran out and the child was thirsty, she climbed as-Safa to look for anyone, crossed the valley to al-Marwah, and went between the two seven times. On the last climb she heard a voice."),
                      .hadith("bukhari:3364", cite: "Saheeh al-Bukhaari 3364", arabic: 281...296, english: 485...510),
                  ]),
                  SignSection("WHAT HE SAID ABOUT IT", [
                      .text("She hurried to hold the water in, making a basin for it with her hands and filling her skin. The Prophet said:"),
                      .hadith("bukhari:3364", cite: "Saheeh al-Bukhaari 3364", arabic: 324...343, english: 554...596),
                      .text("The angel told her not to fear being abandoned: this was where the House of Allah would stand, to be built by this boy and his father, and Allah does not abandon His people."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("What the angel said came to pass: Ibraaheem and Ismaa‘eel later raised the House together (2:127). The Prophet called her running the origin of the walk every pilgrim makes between the two hills, which the Quran names among the symbols of Allah (2:158). The well is still drawn from today, a short distance from the Ka‘bah inside the Sacred Mosque."),
                      .quran("2:127"),
                      .quran("2:158"),
                  ]),
              ]),
        .init(id: "yusuf-dream-shirt", title: "Yoosuf's dream, and the shirt",
              summary: "A boy's dream of eleven stars bowing came true years later in Egypt, and his shirt gave his blind father back his sight.",
              group: .before,
              aliases: ["joseph", "yaqub", "jacob", "eleven stars", "sun and moon", "egypt", "vision", "ruya", "king's dream", "seven cows", "qamis", "interpretation of dreams"],
              sections: [
                  SignSection("THE DREAM", [
                      .text("As a boy, Yoosuf told his father a dream. Ya‘qoob understood it, and told him to keep it from his brothers (12:5)."),
                      .quran("12:4-5"),
                      .text("His brothers threw him into a well, and he was sold into Egypt. He was imprisoned there, and his gift for interpreting dreams brought him out: he read the king's dream of seven fat cows eaten by seven lean ones as seven years of plenty followed by seven of drought, and told Egypt how to live through them (12:43-49). He was put in charge of its stores."),
                      .quran("12:47-48"),
                  ]),
                  SignSection("THE SHIRT", [
                      .text("Ya‘qoob had grieved for him until his eyes turned white (12:84)."),
                      .quran("12:84"),
                      .text("When the famine brought the brothers to Egypt and Yoosuf made himself known, he forgave them and sent his shirt home:"),
                      .quran("12:92-93"),
                      .quran("12:94-96"),
                  ]),
                  SignSection("THE DREAM FULFILLED", [
                      .text("Then the whole family came to Egypt, and the story closed where it began:"),
                      .quran("12:100"),
                      .text("The surah opens on the dream and ends on its meaning. Every hardship in between, the well, the sale and the prison, turns out to have been part of how it came true."),
                  ]),
              ]),
        .init(id: "ayyub-spring", title: "Ayyoob and the spring",
              summary: "Tried in body and family, Ayyoob called on his Lord and was told to strike the ground: a spring rose to heal him.",
              group: .before,
              aliases: ["job", "ayub", "patience", "sabr", "illness", "affliction", "bath", "healing", "golden locusts", "family restored"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Ayyoob was tried in his body and in his family. When he called on his Lord, his prayer was a statement of his state and nothing more: that harm had touched him, and that Allah is the most merciful of those who show mercy (21:83)."),
                      .quran("21:83"),
                      .text("The answer was a spring at his feet:"),
                      .quran("38:41-42"),
                      .text("The commentators say the bath cured what was outside him and the drink what was within. Then what he had lost was given back, and as much again:"),
                      .quran("21:84"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The Quran gives its own verdict on him: 'We found him patient, an excellent servant' (38:44). His name became a byword for patience, and the spring was its reward: not an escape from the trial, but its end, when Allah willed it."),
                      .quran("38:44"),
                      .text("The Prophet told of a day when Ayyoob was bathing and gold fell on him:"),
                      .hadith("bukhari:279", cite: "Saheeh al-Bukhaari 279", arabic: 11...42, english: 4...63),
                      .text("It is the same man on both sides of the trial: patient while he was tried, and still asking for his Lord's blessing when he had more than enough."),
                  ]),
              ]),
        .init(id: "musa-staff-hand", title: "The staff and the white hand",
              summary: "A shepherd's staff became a serpent and swallowed the sorcery of Egypt's best magicians, who believed on the spot.",
              group: .before,
              aliases: ["moses", "musa", "staff", "asa", "serpent", "snake", "yad bayda", "magicians", "sorcerers", "pharaoh", "firaun", "tuwa", "egypt", "harun", "aaron"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("On his way back from Madyan, at the sacred valley of Tuwa, Moosa was asked what was in his right hand. He answered like the shepherd he was: it was his staff, for leaning on and for beating down leaves for his sheep."),
                      .quran("20:19-22"),
                      .text("Both signs came from what he already had: the stick in his hand, and the hand itself. In front of Pharaoh's court he showed them again, in the open:"),
                      .quran("7:107-108"),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("The court called it magic and answered it with magic. Every skilled sorcerer in the land was summoned, and Moosa set the contest for the morning of a festival day, when the whole people would be gathered. The magicians threw their ropes and staffs, and to the crowd they seemed to move."),
                      .quran("20:69-70"),
                      .text("Pharaoh threatened them with severed limbs and crucifixion. They answered him:"),
                      .quran("26:50-51"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Egypt prized sorcery, and its magicians were the people best able to tell a trick from something that was not one. That is why they were the first to believe. The sign was matched to its age and shown to the experts, in public, on a day Moosa chose because the whole people would be there to see it."),
                  ]),
              ]),
        .init(id: "musa-nine-signs", title: "Nine signs to Pharaoh",
              summary: "Flood, locusts, lice, frogs, blood: each plague lifted when they begged Moosa to pray, and each time they broke their word.",
              group: .before,
              aliases: ["moses", "musa", "pharaoh", "firaun", "plagues", "flood", "tufan", "locusts", "lice", "frogs", "blood", "famine", "egypt", "ibn abbas", "bani israel"],
              sections: [
                  SignSection("THE SIGN", [
                      .quran("17:101"),
                      .text("The staff and the hand were the first two. Then came years of drought and failing harvests (7:130), and after them a run of plagues, each one plain to see:"),
                      .quran("7:130-133"),
                      .text("A count reported from Ibn Abbaas and several early commentators makes the nine these: the staff, the hand, the years of famine, the failing fruits, and the five plagues. Other commentators count a little differently."),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("Every plague came with a way out, and they took it every time:"),
                      .quran("7:134-135"),
                      .text("The pattern repeated with each sign. Each plague lifted when they asked Moosa to pray, which showed plainly where it had come from; and once it lifted, the promise to believe and to let the Children of Israel go was forgotten."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The Quran does not present Pharaoh's people as unconvinced. It says the opposite:"),
                      .quran("27:14"),
                      .text("That is the limit of any sign. It can remove every honest doubt, but not pride, and nine of them did not move a court that had already decided."),
                  ]),
              ]),
        .init(id: "musa-sea", title: "The parting of the sea",
              summary: "Trapped between Pharaoh's army and the sea, Moosa struck the water with his staff and it stood apart like mountains.",
              group: .before,
              aliases: ["moses", "musa", "red sea", "parting", "exodus", "pharaoh", "firaun", "drowned", "staff", "ashura", "muharram", "fasting", "children of israel", "bani israel", "egypt"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Moosa led the Children of Israel out of Egypt by night, and Pharaoh's army came after them at sunrise. With the sea in front of them and soldiers behind, his people gave themselves up for lost."),
                      .quran("26:61-63"),
                      .text("The pursuers followed them onto the path. Moosa and everyone with him were brought across, and the sea closed over the others (26:64-66)."),
                      .quran("26:64-66"),
                  ]),
                  SignSection("PHARAOH'S LAST WORDS", [
                      .text("The man who had called himself a god declared his faith only when the water reached him, and was answered with a rebuke:"),
                      .quran("10:90-92"),
                  ]),
                  SignSection("WHAT THE PROPHET SAID", [
                      .text("The day was still being kept when the Prophet reached Madinah:"),
                      .hadith("bukhari:3397", cite: "Saheeh al-Bukhaari 3397", arabic: 25...65, english: 0...81),
                      .text("So Muslims fast Aashoora, the tenth of Muharram, to this day, for the same reason: it is the day Moosa was saved and Pharaoh drowned."),
                  ]),
              ]),
        .init(id: "musa-desert", title: "Twelve springs, manna and quails",
              summary: "Twelve springs gushed from a struck rock, clouds gave shade, and manna and quails fed a whole people in the wilderness.",
              group: .before,
              aliases: ["moses", "musa", "manna", "mann", "salwa", "rock", "stone", "clouds", "shade", "sinai", "wilderness", "tribes", "truffles", "kamah", "bani israel"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("In the wilderness after Egypt, a whole people needed water, food and shelter, and the land gave them none of the three."),
                      .quran("2:60"),
                      .text("Twelve springs, one for each of the twelve tribes (7:160), and every tribe knew its own."),
                      .quran("7:160"),
                      .text("Food and shade came the same way:"),
                      .quran("2:57"),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("The food came without sowing or labour, and in time they tired of it:"),
                      .quran("2:61"),
                  ]),
                  SignSection("WHAT THE PROPHET SAID", [
                      .text("The Prophet tied the manna to something his own people gathered from the desert:"),
                      .hadith("muslim:2049e", cite: "Saheeh Muslim 2049e", arabic: 32...42, english: 0...20),
                      .text("Scholars have read the likeness two ways: that truffles are literally a kind of that provision, or that they are like it, coming up by themselves with no one to plant or water them."),
                  ]),
              ]),
        .init(id: "musa-cow", title: "The cow and the murdered man",
              summary: "Struck with part of a slaughtered cow, a murdered man was brought back to life, and what his killers hid came out.",
              group: .before,
              aliases: ["moses", "musa", "cow", "baqarah", "al-baqarah", "heifer", "yellow cow", "murder", "killer", "slain man", "resurrection", "bani israel", "children of israel"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("A man was killed among the Children of Israel, and each party pushed the blame onto another. Moosa brought them a command they did not expect:"),
                      .quran("2:67"),
                      .text("The command was simply to slaughter a cow. They asked instead about her age, then her colour, then her work, and each answer narrowed the search, until they slaughtered her, the Quran says, but could hardly do it (2:71)."),
                      .quran("2:71"),
                      .text("Then came the point of it:"),
                      .quran("2:72-73"),
                      .text("The commentators report, from the first generations, that the man came back to life for a moment, named the one who had killed him, and died again."),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("They had seen a dead man speak. The very next verse says what followed:"),
                      .quran("2:74"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign did two things at once: it settled a murder no witness would settle, and it showed on a small scale what the verse says it shows, that this is how Allah brings the dead to life. The longest surah of the Quran is named after this cow."),
                  ]),
              ]),
        // From Proving Islam's "The Quran and Earlier Scripture" (2026-10-02), which sets this sign
        // beside the Talmud's memory of it.
        .init(id: "musa-mountain", title: "The mountain raised over them",
              summary: "As the covenant was taken from the Children of Israel, the mountain was raised over them as if it were a cloud, and they were told to hold firmly to what they had been given.",
              group: .before,
              aliases: ["moses", "musa", "mount", "mountain", "sinai", "tur", "at-tur", "covenant", "torah", "bani israel",
                        "children of israel", "canopy", "cloud", "zullah", "talmud", "exodus 19"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("At the foot of the mountain the Children of Israel were given the Torah and a covenant to keep it. The Quran describes what stood over their heads as the covenant was taken:"),
                      .quran("7:171"),
                      .text("Surat al-Baqarah tells the same moment, as part of the covenant itself:"),
                      .quran("2:63"),
                      .text("Ibn Katheer reports from Ibn Abbaas that the mountain was raised when they refused to obey."),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("They had seen the mountain over them, and still, the very next verse says:"),
                      .quran("2:64"),
                      .text("The Quran recalls it again when it lists what they did with the covenant (2:93)."),
                      .quran("2:93"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign did not ask them to believe in Moosa; they already followed him. It made the weight of the covenant plain, so that no one could say afterwards that the command had been light. Jewish tradition kept a memory of the same scene: the Babylonian Talmud (Shabbat 88a) reads Exodus 19:17, where the people stood \"at the nether part of the mount\", as \"beneath the mountain\", with the mountain held over them like an upturned tub."),
                  ]),
              ]),
        .init(id: "dawud-iron", title: "Iron softened for Daawood",
              summary: "The mountains and the birds praised Allah with him, and iron became pliable in his hands so that he could make armour.",
              group: .before,
              aliases: ["david", "dawud", "dawood", "armour", "armor", "chain mail", "coats of mail", "tasbih", "psalms", "zabur", "voice", "abu musa", "mazamir", "recitation"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Daawood (peace be upon him) was given a voice the mountains and the birds answered, and iron that yielded in his hands."),
                      .quran("34:10-11"),
                      .text("Another passage gives the times of that praise:"),
                      .quran("38:18-19"),
                  ]),
                  SignSection("WHAT HE DID WITH IT", [
                      .text("The Quran names what he made with the iron: armour, so that the gift was a trade taught to a prophet and not a spectacle."),
                      .quran("21:80"),
                      .text("He was a king, and still lived by the work of his own hands. The Prophet described how he recited and how he earned his bread:"),
                      .hadith("bukhari:3417", cite: "Saheeh al-Bukhaari 3417", arabic: 29...52, english: 4...48),
                  ]),
                  SignSection("THE VOICE", [
                      .text("His voice stayed a byword. The Prophet said to Abu Moosa al-Ash'ari:"),
                      .hadith("muslim:793e", cite: "Saheeh Muslim 793e", arabic: 28...40, english: 0...35),
                  ]),
              ]),
        .init(id: "sulayman-wind-jinn", title: "The wind, the jinn, and a gnawed staff",
              summary: "The wind covered a month's journey in a morning; the jinn built for Sulaymaan and missed his death until his staff gave way.",
              group: .before,
              aliases: ["solomon", "sulayman", "sulaiman", "wind", "jinn", "devils", "ifrit", "afreet", "copper", "termite", "woodworm", "unseen", "ghayb", "kingdom", "soothsayers"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Daawood's son Sulaymaan asked for a kingdom that would belong to no one after him (38:35), and was given one: the wind under his command, and the jinn working for him."),
                      .quran("38:35"),
                      .quran("34:12-13"),
                      .text("The list ends not with praise of the king but with a command to be grateful, and a warning that few are."),
                  ]),
                  SignSection("WHAT THE JINN DID NOT KNOW", [
                      .text("The jinn laboured for him to the end of his life, and past it:"),
                      .quran("34:14"),
                      .text("He died leaning on his staff, and they worked on until a creature of the earth (a woodworm or termite, the commentators say) had eaten through it and he fell. Soothsayers in Arabia claimed to get their knowledge of hidden things from the jinn. This verse answers them: the jinn could not see that the king in front of them was dead."),
                  ]),
                  SignSection("WHAT THE PROPHET SAID", [
                      .text("The Prophet once had a jinn in his grip, and remembered Sulaymaan:"),
                      .hadith("bukhari:3423", cite: "Saheeh al-Bukhaari 3423", arabic: 25...64, english: 4...84),
                  ]),
              ]),
        .init(id: "sulayman-ant-hoopoe", title: "The ant and the hoopoe",
              summary: "Sulaymaan understood an ant warning her colony, and a hoopoe brought him news of a kingdom that worshipped the sun.",
              group: .before,
              aliases: ["solomon", "sulayman", "sulaiman", "ants", "naml", "an-naml", "hudhud", "birds", "language of birds", "speech of animals", "sheba", "saba", "valley of the ants"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Sulaymaan spoke of his gift openly, as a favour from Allah:"),
                      .quran("27:16"),
                      .text("The most quietly extraordinary of them involves an ant. His army of jinn, men and birds was on the march when he heard her warn her colony, and the Quran preserves what she said:"),
                      .quran("27:18-19"),
                      .text("She excused them even as she warned: if they crushed the ants, it would be without knowing. He smiled, and turned the moment into a prayer of thanks."),
                  ]),
                  SignSection("THE HOOPOE'S NEWS", [
                      .text("Reviewing the birds one day, he found the hoopoe missing and promised it punishment unless it came with a clear excuse. It came back with more than an excuse:"),
                      .quran("27:22-24"),
                      .text("A bird knew what the king did not, and spoke against a people bowing to the sun instead of Allah. Sulaymaan did not take its word on trust; he sent a letter to test it, and the story of Sheba begins there."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Both creatures in this story are among the four the Prophet forbade killing:"),
                      .hadith("ibnmajah:3224", cite: "Sunan Ibn Maajah 3224; graded saheeh by al-Albaani", arabic: 23...40, english: 0...15),
                  ]),
              ]),
        .init(id: "sheba-throne", title: "The throne brought from Sheba",
              summary: "A queen's throne was brought to Sulaymaan in the blink of an eye, and a floor of glass showed her what she had mistaken.",
              group: .before,
              aliases: ["solomon", "sulayman", "saba", "queen", "bilqis", "balqis", "yemen", "glass", "palace", "asif", "ifrit", "jinn", "knowledge of the book", "blink of an eye"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Sheba lay far to the south, in what is now Yemen. Its queen had answered Sulaymaan's letter with a gift, he had sent the gift back, and now she was coming to him herself. Before she arrived, he asked his court:"),
                      .quran("27:38-40"),
                      .text("The Quran does not name the man with knowledge of the Book; many commentators said he was one of Sulaymaan's own court, and the name usually given is Aasif ibn Barkhiya. Sulaymaan's first words on seeing the throne were not about the feat but about gratitude."),
                  ]),
                  SignSection("WHAT SHE SAW", [
                      .text("He had the throne disguised, to see whether she would be guided. She neither claimed it nor denied it, saying only that it was as though it were the same. Then she was shown into his palace:"),
                      .quran("27:44"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("One common reading takes the glass floor as the lesson of the whole story: she had been ruled by how things looked, a sun that seemed worthy of worship and a floor that seemed to be water. Her own words are a confession as much as a surrender. She said she had wronged herself, and she submitted with Sulaymaan, not to him: to Allah, Lord of the worlds."),
                  ]),
              ]),
        .init(id: "yunus-whale", title: "Yoonus in the belly of the fish",
              summary: "Swallowed at sea, he called on Allah from the darkness and was brought out alive. His words are still answered.",
              group: .before,
              aliases: ["jonah", "dhun-nun", "dhu al-nun", "sahib al-hut", "man of the fish", "whale", "ship", "lots", "gourd", "shore", "la ilaha illa anta", "dua", "distress", "yunus ibn matta"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Yoonus left his people in anger, before he had been given leave to go. The Quran tells what followed in three short ayahs:"),
                      .quran("37:140-142"),
                  ]),
                  SignSection("WHAT HE SAID IN THE DARK", [
                      .text("That he lived is the sign; what he said in the dark is why the story is told at all."),
                      .quran("21:87-88"),
                      .text("The Quran then says plainly what would have happened otherwise:"),
                      .quran("37:143-144"),
                      .text("He was cast onto the open shore, sick, and a gourd vine was made to grow over him. Then he was sent to a people of a hundred thousand or more, and they believed."),
                  ]),
                  SignSection("WHAT THE PROPHET SAID ABOUT IT", [
                      .text("He was not saved by the fish letting him go but by the words he said inside it. The Prophet left those words to his ummah with a promise attached:"),
                      .hadith("tirmidhi:3505", cite: "Jaami‘ at-Tirmidhi 3505", arabic: 33...64, english: 0...58),
                      .text("The Quran had said as much in the ayah that closes his dua: 'thus do We save the believers.'"),
                  ]),
              ]),
        .init(id: "zakariya-yahya", title: "A son for Zakariya in old age",
              summary: "An old man with a barren wife asked for an heir, and was given Yahya and a sign in his own tongue.",
              group: .before,
              aliases: ["zechariah", "zakariyya", "zakaria", "john", "john the baptist", "maryam", "mary", "mihrab", "prayer chamber", "barren", "provision", "three nights", "silence", "heir"],
              sections: [
                  SignSection("WHAT MOVED HIM TO ASK", [
                      .text("Zakariya was the guardian of the young Maryam. Whenever he went in to her in the prayer chamber he found food there that no one had brought, and her answer turned him to prayer on the spot:"),
                      .quran("3:37-38"),
                      .text("He was old, his hair white, and his wife was barren. Having watched Allah provide for Maryam from nowhere, he asked for what his age had put out of reach."),
                  ]),
                  SignSection("WHAT HE WAS GIVEN", [
                      .text("The answer came while he was still standing in prayer: a son, with a name no one had carried before."),
                      .quran("19:7-9"),
                      .text("His astonishment is met with an argument: the One who created Zakariya when he was nothing can give him a son at any age."),
                  ]),
                  SignSection("HIS SIGN", [
                      .text("He asked for a sign to hold on to, and was given one in his own body:"),
                      .quran("19:10-11"),
                      .text("For three days and nights a healthy man could not speak to people, yet the account in Al Imraan tells him to remember his Lord much in those days: the silence was toward people, not toward Allah. The boy, Yahya, grew up to be a prophet himself, given judgement while still a child."),
                  ]),
              ]),
        .init(id: "isa-birth-cradle", title: "Born without a father, speaking from the cradle",
              summary: "Maryam's son was announced by an angel, born under a palm tree, and spoke from the cradle to clear his mother.",
              group: .before,
              aliases: ["jesus", "isa", "mary", "maryam", "virgin birth", "annunciation", "jibril", "gabriel", "palm tree", "dates", "stream", "mahd", "infant", "sister of harun", "juraij", "nativity", "messiah"],
              sections: [
                  SignSection("THE ANNOUNCEMENT", [
                      .text("Maryam had withdrawn from her family when an angel came to her in the form of a man, with news of a son. Her question is the obvious one, and so is the answer:"),
                      .quran("3:47"),
                  ]),
                  SignSection("UNDER THE PALM TREE", [
                      .text("She gave birth alone, far from her people. What she needed was provided where she sat:"),
                      .quran("19:23-25"),
                  ]),
                  SignSection("THE CRADLE", [
                      .text("She came back carrying him and was accused at once. She had vowed silence for the day, so she pointed to the child. His first words were a sign in themselves, spoken as an infant in arms in answer to the accusation against his mother:"),
                      .quran("19:29-30"),
                      .text("The Prophet counted him among only three who ever spoke in the cradle:"),
                      .hadith("muslim:2550b", cite: "Saheeh Muslim 2550b", arabic: 27...37, english: 0...19),
                      .text("The narration goes on to tell of Jurayj, a devout man of the Children of Israel whose name an infant cleared, and of a third baby at its mother's breast."),
                  ]),
              ]),
        .init(id: "isa-signs", title: "Clay birds, the blind and the dead",
              summary: "Eesa healed the blind and the leper and raised the dead, and named each one as done by Allah's permission.",
              group: .before,
              aliases: ["jesus", "isa", "messiah", "masih", "clay bird", "healing", "leper", "leprosy", "raised the dead", "children of israel", "bani israil", "gospel", "injil", "physicians", "medicine", "by my permission"],
              sections: [
                  SignSection("WHAT HE WAS GIVEN", [
                      .text("He was given signs of life itself, and the Quran has him name them as things done by Allah's permission, never by his own power."),
                      .quran("3:49"),
                      .text("The last is of a different kind: not a cure but knowledge he had no way of having, of what people had eaten and what they had put away at home."),
                  ]),
                  SignSection("BY WHOSE PERMISSION", [
                      .text("The Quran also records Allah reminding him of the same signs, on the Day the messengers are gathered, and the words 'with My permission' come four times in a single ayah:"),
                      .quran("5:110"),
                      .text("The repetition leaves no room to read them as his own power. Giving life to the dead by another's leave is the work of a messenger, and the same ayah records that those who rejected him called it plain magic."),
                  ]),
                  SignSection("WHY THESE SIGNS", [
                      .text("Ibn Katheer records a view held by many scholars: each prophet was given a sign that answered what his age prided itself on. Moosa was sent to a court of magicians; Eesa came to a time that valued physicians, and brought what no physician could."),
                  ]),
              ]),
        .init(id: "table-spread", title: "The table sent down from heaven",
              summary: "The disciples asked Eesa for a table of food from the sky; it was promised, with a warning attached.",
              group: .before,
              aliases: ["maidah", "al-maidah", "table spread", "hawariyyun", "disciples", "apostles", "jesus", "isa", "feast", "festival", "eid", "surah 5", "food from heaven"],
              sections: [
                  SignSection("WHAT THEY ASKED", [
                      .text("Eesa's disciples had already declared their faith when they asked him for one more sign: a table spread with food, sent down from the sky. He told them to fear Allah, and they explained why they wanted it:"),
                      .quran("5:112-113"),
                  ]),
                  SignSection("WHAT HE PRAYED, AND THE ANSWER", [
                      .text("He made the request his own, and asked that the day it came be a festival for the first of them and the last:"),
                      .quran("5:114-115"),
                      .text("The answer granted the sign and attached a warning to it. A sign that people ask for and receive leaves no excuse behind it, so whoever disbelieved after this one would be punished as no one else in the worlds had been."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Most commentators held that the table did come down, as the promise says. A few early ones, Mujaahid and al-Hasan al-Basri among them, held that the disciples withdrew the request once they heard the condition. Either way, the exchange gave the fifth surah its name: al-Maa’idah, the Table Spread."),
                  ]),
              ]),
    ]

    // MARK: Foretold before him

    /// The earlier scriptures' promises of him (Abu, 2026-11-24: "include some from the bible like the
    /// paraclete will be with you soon (Ahmed) and the prophecy in genesis about making Ishmael a great
    /// nation ... and the Daniel prophecy"). The Bible is quoted as written (`.quote`, King James); the
    /// Quran and hadith by reference as everywhere else.
    ///
    /// 2026-11-25 (Abu: Kedar and the conquest, "another tongue" and the broken letters, the prophet like
    /// Musa and al-Muzzammil, "any other prophecies in the Bible"): nine more, from kedar-flight to
    /// girded-sword. Each says WHO made the reading, checked in the texts themselves (al-Jawab as-Sahih,
    /// Hidayat al-Hayara, al-Mawardi, al-Qarafi, al-Qurtubi, Ibn Kathir, Izhar al-Haqq): classical for the
    /// riders, Isaiah 54 and 60, Psalms 45 and 72 and the rout of Kedar at Badr; nineteenth-century for
    /// Deuteronomy 32:21; modern for Isaiah 28 and 29:12, Baca, the Hijrah in Isaiah 21 and Sela as Sal'.
    /// No source links Isaiah's tsav la-tsav to the opening letters of the surahs, and the entry says so.
    /// Then (Abu: "should include this") Song of Songs 5:16 ("Muhammadim", a plural meaning delightful
    /// things, cautioned against by IslamQA 246893) and Haggai 2:7: both modern and resting on a root
    /// alone, so each carries a WHY IT IS WEAK section and is kept out of `strongestIDs`.
    static let foretoldEntries: [Entry] = [
        .init(id: "paraclete", title: "The Comforter Jesus promised",
              summary: "On his last night Eesa promised another Comforter, who would come only once he had gone, speak only what he heard, and abide for ever.",
              group: .foretold,
              aliases: ["paraclete", "parakletos", "periklytos", "comforter", "faraqlit", "spirit of truth", "ahmad", "gospel of john", "john 14", "john 16", "holy ghost", "holy spirit", "pentecost", "jesus", "injil"],
              sections: [
                  SignSection("WHAT THE QURAN SAYS HE FORETOLD", [
                      .text("The Quran records that Eesa (peace be upon him) came to the Children of Israel confirming the Torah that was before him, and bringing good tidings of a messenger to come after him:"),
                      .quran("61:6"),
                      .text("It also says that those who follow the Prophet Muhammad (peace and blessings be upon him) find him written in what they have of the Torah and the Gospel:"),
                      .quran("7:157"),
                      .text("The scholars who wrote on these glad tidings, Ibn Taymiyyah in al-Jawaab as-Saheeh, his student Ibn al-Qayyim in Hidaayat al-Hayaara and, in the nineteenth century, Rahmatullah al-Kairanawi in Izhar al-Haqq, returned most often to one passage of the Gospel of John: the long talk at Eesa's last meal with his disciples."),
                  ]),
                  SignSection("THE PROMISE", [
                      .quote("“And I will pray the Father, and he shall give you another Comforter, that he may abide with you for ever” (John 14:16, KJV)"),
                      .quote("“Nevertheless I tell you the truth; It is expedient for you that I go away: for if I go not away, the Comforter will not come unto you; but if I depart, I will send him unto you.” (John 16:7, KJV)"),
                      .quote("“I have yet many things to say unto you, but ye cannot bear them now. Howbeit when he, the Spirit of truth, is come, he will guide you into all truth: for he shall not speak of himself; but whatsoever he shall hear, that shall he speak: and he will shew you things to come. He shall glorify me: for he shall receive of mine, and shall shew it unto you.” (John 16:12–14, KJV)"),
                      .text("The word translated Comforter is the Greek parakletos, which the Arabic writers spelled faaraqleet: one called to stand beside another, a helper or an advocate. Its meaning was argued over even in their day, so Ibn Taymiyyah did not rest on the word. He argued from what the Comforter is said to do."),
                  ]),
                  SignSection("WHAT THE COMFORTER WOULD DO", [
                      .text("He is “another” Comforter. A second implies a first of the same kind, and the one who had stood beside the disciples until that night was Eesa himself. What is promised is someone like him, sent after him."),
                      .text("He cannot come until Eesa has gone (John 16:7). Yet in the Gospels' own telling the Holy Spirit was at work long before that night: John the Baptist was to be filled with the Holy Ghost from his mother's womb (Luke 1:15), Elisabeth and Zacharias were filled with it (Luke 1:41, 1:67), and it was upon Simeon in the Temple (Luke 2:25). Ibn Taymiyyah made the same point: the Holy Spirit had always strengthened the prophets and the righteous, before Eesa and after him, and no one had called that the Comforter. A help that was already present cannot be the one that waits on his leaving."),
                      .text("He “shall not speak of himself; but whatsoever he shall hear, that shall he speak”. That is how the Quran describes the Prophet:"),
                      .quran("53:3-4"),
                      .text("It is also how the Torah describes the prophet promised to Moosa (peace be upon him), with God's words put in his mouth:"),
                      .quote("“I will raise them up a Prophet from among their brethren, like unto thee, and will put my words in his mouth; and he shall speak unto them all that I shall command him.” (Deuteronomy 18:18, KJV)"),
                      .text("“He shall glorify me”, and in the chapter before, “he shall testify of me” (John 15:26). Ibn Taymiyyah observed that no one after Eesa bore witness for him in a testimony heard across the earth except Muhammad, who cleared him of the slanders of those who rejected him and of the excess of those who made him a god. The Quran says of him and his mother:"),
                      .quran("5:75"),
                      .text("He will “abide with you for ever”. No man lives for ever, so Ibn Taymiyyah read it of what he would bring: a law never to be replaced, which fits the last of the prophets. And the “many things” the disciples could not yet bear, all truth and things to come, fit a revelation that completed the religion and told of the Hour and what follows it in more detail than any scripture before it."),
                  ]),
                  SignSection("THE CHRISTIAN READING", [
                      .text("Christians read the Comforter as the Holy Spirit, and the Gospel of John names him so in the same talk:"),
                      .quote("“But the Comforter, which is the Holy Ghost, whom the Father will send in my name, he shall teach you all things, and bring all things to your remembrance, whatsoever I have said unto you.” (John 14:26, KJV)"),
                      .text("They hold the promise kept at the feast of Pentecost, when the disciples “were all filled with the Holy Ghost, and began to speak with other tongues” (Acts 2:4). To the point about the Spirit's earlier presence they answer from John itself, which says that before then “the Holy Ghost was not yet given” (John 7:39): what came at Pentecost, on their reading, was a new indwelling, not a first arrival."),
                      .text("The Muslim answer does not depend on removing “the Holy Ghost” from John 14:26. Even with those words, the rest of the description is of someone seen and heard: he speaks only what he hears, he testifies, he will “reprove the world of sin” (John 16:8), and he tells of things to come. These, Ibn Taymiyyah said, are not the marks of something in the hearts of a few that no one sees or hears; they fit one whom people see and whose words they hear. And the Quran names the one Eesa foretold: Ahmad, a messenger."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Some modern writers have suggested that John's Greek once read periklytos, “the praised one”, close in meaning to Ahmad, rather than parakletos. No Greek manuscript of John reads periklytos; every one reads parakletos. The suggestion has no manuscript support, and the argument here does not rest on it. The classical scholars argued from the description, and the description is in every copy."),
                  ]),
              ]),
        .init(id: "ishmael-nation", title: "A great nation from Ismaa‘eel",
              summary: "Genesis promises Ibraaheem a great nation from Ismaa‘eel by name; the Arabs descend from him, and the Prophet from them.",
              group: .foretold,
              aliases: ["ishmael", "ismail", "hagar", "hajar", "great nation", "genesis 17", "genesis 21", "twelve princes", "kedar", "nebaioth", "nebajoth", "ishmaelites", "hagarenes", "saracens", "john of damascus"],
              sections: [
                  SignSection("THE PROMISE, BY NAME", [
                      .text("Genesis tells of Ibraaheem's two sons, Ismaa‘eel, born to Haajar (Hagar), and Ishaaq, born to Saarah, and it records promises for both. Before Ismaa‘eel was born, the angel told his mother that her offspring would be past counting:"),
                      .quote("“I will multiply thy seed exceedingly, that it shall not be numbered for multitude.” (Genesis 16:10, KJV)"),
                      .text("When Ibraaheem prayed for his son, God answered with the promise, and named him in it:"),
                      .quote("“And as for Ishmael, I have heard thee: Behold, I have blessed him, and will make him fruitful, and will multiply him exceedingly; twelve princes shall he beget, and I will make him a great nation.” (Genesis 17:20, KJV)"),
                      .text("It was given again when Haajar and the boy were sent away: to Ibraaheem, that the son of the bondwoman too would be made a nation (Genesis 21:13), and then to Haajar in the wilderness, with the boy dying of thirst:"),
                      .quote("“Arise, lift up the lad, and hold him in thine hand; for I will make him a great nation.” (Genesis 21:18, KJV)"),
                      .text("Genesis says he grew up in the wilderness of Paran (Genesis 21:21), and later it lists his twelve sons:"),
                      .quote("“And these are the names of the sons of Ishmael, by their names, according to their generations: the firstborn of Ishmael, Nebajoth; and Kedar, and Adbeel, and Mibsam” … “These are the sons of Ishmael, and these are their names, by their towns, and by their castles; twelve princes according to their nations.” (Genesis 25:13, 16, KJV)"),
                  ]),
                  SignSection("THE ARABS FROM HIM, AND THE PROPHET FROM THEM", [
                      .text("The Arabs of the north, Quraysh among them, trace their line to Ismaa‘eel, and the Prophet Muhammad (peace and blessings be upon him) placed himself in that line:"),
                      .hadith("muslim:2276", cite: "Saheeh Muslim 2276", arabic: 45...64, english: 7...48),
                      .text("The Quran tells the other half of the story. Ibraaheem and Ismaa‘eel, raising the foundations of the House together in Makkah, asked for a nation submitting to Allah from their descendants, and for a messenger from among them:"),
                      .quran("2:127-129"),
                      .text("After Ismaa‘eel, no prophet arose from his line until one came from the very valley where the two of them had prayed, and the nation that prayer asked for gathered around him."),
                  ]),
                  SignSection("WHAT CHRISTIANS CALLED THE MUSLIMS", [
                      .text("The Christians who first wrote about the Muslims named them after Ismaa‘eel and his mother. Sebeos, an Armenian historian of the later seventh century whose work is the earliest surviving major account of the rise of Islam, opens his account of it with the son of Abraham “born of a serving maid”, about whom, he says, the words of Genesis 16:12 were fulfilled. He calls the Prophet “a man of the sons of Ishmael” who “taught them to recognize the God of Abraham”. A Syriac apocalypse written in northern Syria in the 690s, which goes under the name of Methodius, calls the conquerors “the sons of Ishmael”. Early Syriac, Greek, Coptic and Armenian writers called them Hagarenes, after Haajar: Agarenoi in Greek, Hagraye in Syriac."),
                      .text("John of Damascus, a monk who wrote in Greek in the eighth century under Muslim rule, opened his chapter on Islam with the same genealogy:"),
                      .quote("“There is also the superstition of the Ishmaelites which to this day prevails and keeps people in error, being a forerunner of the Antichrist. They are descended from Ishmael, [who] was born to Abraham of Agar, and for this reason they are called both Agarenes and Ishmaelites.” (John of Damascus, On Heresies, ch. 100 (101 in Migne), tr. F. H. Chase, 1958)"),
                      .text("He then gave the older Greek and Roman name for the Arabs, Saracens, and explained it by a play on words as Sarras kenoi, “destitute of Sara”. His purpose was polemic. But he and the writers before him agree on the one fact this page needs: to their opponents, the people who carried the new religion out of Arabia were the children of Ismaa‘eel."),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("Jewish and Christian readers take the promise as kept, and finished, in the tribes: twelve princes, and the Arab peoples descended from them. The covenant itself, Genesis says in the next verse, was to be established with Ishaaq:"),
                      .quote("“But my covenant will I establish with Isaac, which Saarah shall bear unto thee at this set time in the next year.” (Genesis 17:21, KJV)"),
                      .text("Muslims do not deny the covenant with Ishaaq: the prophets of the Children of Israel came through it, and the Quran honours every one of them. The question is what “a great nation” from Ismaa‘eel amounted to. Ibn Taymiyyah argued that a man is not made great merely by having many descendants, and that a nation of unbelievers is not what God calls great in a promise of blessing. The honour by which the children of Ismaa‘eel came to stand above other peoples, he said, appeared only with the prophethood of Muhammad, and that shows it was true and foretold."),
                      .text("Ibn al-Qayyim records the Jews of his day conceding that Genesis foretells the Arabs' dominion, while denying that it foretells a prophet. His answer was that a liar's empire is not given as good news. A false prophet's kingdom would be a warning, as the Antichrist is a warning, not a blessing promised to Haajar in her distress. Proving Islam's chapter on the Bible sets this promise beside the others the scholars gathered, and argues it at length."),
                  ]),
              ]),
        .init(id: "daniel-stone", title: "The stone that became a mountain",
              summary: "Daniel read a king's dream of a great statue broken by a stone cut out without hands, which became a mountain and filled the earth.",
              group: .foretold,
              aliases: ["daniel", "daniel 2", "nebuchadnezzar", "bukhtnassar", "statue", "image", "four kingdoms", "stone cut without hands", "great mountain", "kingdom of god", "cornerstone", "builders rejected", "psalm 118", "matthew 21", "last brick"],
              sections: [
                  SignSection("THE DREAM", [
                      .text("The Book of Daniel tells of a dream that troubled Nebuchadnezzar, king of Babylon, which Daniel, a young captive from Judah, recounted and interpreted for him. The king had seen a great image:"),
                      .quote("“This image’s head was of fine gold, his breast and his arms of silver, his belly and his thighs of brass, His legs of iron, his feet part of iron and part of clay. Thou sawest till that a stone was cut out without hands, which smote the image upon his feet that were of iron and clay, and brake them to pieces.” (Daniel 2:32–34, KJV)"),
                      .text("The whole image was broken together and blown away like chaff, “and the stone that smote the image became a great mountain, and filled the whole earth” (Daniel 2:35). Daniel told the king that he was the head of gold, that other kingdoms would follow, each of a lesser metal, and then the last:"),
                      .quote("“And in the days of these kings shall the God of heaven set up a kingdom, which shall never be destroyed: and the kingdom shall not be left to other people, but it shall break in pieces and consume all these kingdoms, and it shall stand for ever.” (Daniel 2:44, KJV)"),
                  ]),
                  SignSection("THE CHRISTIAN READING", [
                      .text("The traditional Christian reading takes the four metals as Babylon, Medo-Persia, Greece and Rome, and the stone as the kingdom of God that came with Christ, small at its beginning and spread since through the world. Most modern scholars read the four instead as Babylon, Media, Persia and the Greek kingdoms that followed Alexander."),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("Ibn Taymiyyah in al-Jawaab as-Saheeh and Ibn al-Qayyim in Hidaayat al-Hayaara both count this dream among the glad tidings of the Prophet Muhammad (peace and blessings be upon him). They quote it from an Arabic rendering used by earlier Muslim writers, in which Daniel's interpretation calls the stone a prophet whom God raises up with a strong law, who breaks the kings of the earth and their nations until the earth is filled with him and his nation, and whose rule lasts to the end of the world. Ibn Taymiyyah's verdict on it:"),
                      .quote("“This is the description of Muhammad, not the description of the Messiah. He is the one who was sent with a strong law, and broke all the kings of the earth and its nations, until the earth was filled with him and with his nation in its east and its west. And his rule endures: no one has been able to remove it, as the rule of the Jews was removed, and the rule of the Christians from the best and the middle of the earth.” (Ibn Taymiyyah, al-Jawaab as-Saheeh, vol. 5)"),
                      .text("The Bible as it stands speaks of a kingdom that God sets up, not of a prophet, so the reading has to be argued from the kingdom, and it is the kingdom both scholars point to: one that broke the kings of the earth, and whose rule was not taken away. The details of the dream fit that picture. The stone is “cut out without hands”: it does not grow out of the empires it breaks, as each metal grew out of the one before, but comes from outside them. It strikes while they still stand. And it fills the whole earth and is “not left to other people”. Within a generation of the Prophet's death, the two empires that ruled the Near East, Persia and Rome, had lost to his Companions every land from Iraq to Egypt. He had described what was shown to him:"),
                      .hadith("muslim:2889a", cite: "Saheeh Muslim 2889a", arabic: 38...53, english: 0...37),
                      .text("The kingdom of the Christian reading did not break Rome; within four centuries it had become Rome's own religion. Christians answer that the kingdom is spiritual, and grows in hearts rather than across borders. That is a fair account of their faith, but it is not the picture the dream paints, of a stone that strikes."),
                  ]),
                  SignSection("THE STONE THE BUILDERS REFUSED", [
                      .text("A second stone is read beside it. A psalm speaks of “the stone which the builders refused” that “is become the head stone of the corner” (Psalm 118:22), and in Matthew, Jesus quotes it at the end of a parable of tenants who beat and kill the servants sent to a vineyard for its fruit, and then the owner's son:"),
                      .quote("“Therefore say I unto you, The kingdom of God shall be taken from you, and given to a nation bringing forth the fruits thereof. And whosoever shall fall on this stone shall be broken: but on whomsoever it shall fall, it will grind him to powder.” (Matthew 21:43–44, KJV)"),
                      .text("Ibn Taymiyyah quotes the passage among the glad tidings, and Ibn al-Qayyim explains it: this is the description of Muhammad and of those who opposed and fought him, and it fits no one after the Messiah but him. The stone that grinds to powder whomever it falls on recalls the stone that broke the image. And the Prophet's own picture of his place among the prophets is a building, and the one stone it lacked:"),
                      .hadith("bukhari:3535", cite: "Saheeh al-Bukhaari 3535, Saheeh Muslim 2286b", arabic: 34...67, english: 4...70),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is an interpretation, argued, not a proof text. Daniel's dream names no prophet and no people, and the Arabic rendering the classical scholars quoted says more than the Bible as it stands. What can fairly be said is that the dream describes a kingdom set up by God, from outside the empires, that breaks them, fills the earth and is never handed on to another people; and that the coming of Islam fits it at least as well as any other reading. Christians read the same chapter as glad tidings of their own, and the Jews before them as theirs."),
                  ]),
              ]),
        .init(id: "prophet-like-musa", title: "A prophet like Moosa, from their brethren",
              summary: "The Torah promises a prophet like Moosa, from among the brethren of Israel, with God's words in his mouth.",
              group: .foretold,
              aliases: ["moses", "deuteronomy 18", "deuteronomy 34", "prophet like moses", "like unto thee", "brethren", "my words in his mouth", "that prophet", "torah", "joshua", "esau", "edom", "witness from the children of israel"],
              sections: [
                  SignSection("THE PROMISE", [
                      .text("Near the end of the Torah, Moosa (peace be upon him) tells the Children of Israel that God will raise up for them a prophet like himself (Deuteronomy 18:15), and then gives God's own words to him:"),
                      .quote("“I will raise them up a Prophet from among their brethren, like unto thee, and will put my words in his mouth; and he shall speak unto them all that I shall command him. And it shall come to pass, that whosoever will not hearken unto my words which he shall speak in my name, I will require it of him.” (Deuteronomy 18:18–19, KJV)"),
                      .text("The same passage gives the test of a prophet: if what he says in God's name does not come to pass, God did not send him (Deuteronomy 18:21–22). The Prophecies library is a long record of the other outcome."),
                  ]),
                  SignSection("LIKE MOOSA", [
                      .text("The Torah's last chapter, written after Moosa's death, says that none like him had arisen in Israel:"),
                      .quote("“And there arose not a prophet since in Israel like unto Moses, whom the LORD knew face to face” (Deuteronomy 34:10, KJV)"),
                      .text("Muslim scholars read the promise as the Prophet Muhammad (peace and blessings be upon him), and the Quran describes his sending in the very terms of the comparison:"),
                      .quran("73:15"),
                      .text("The comparison was made early. Al-Muzzammil is among the first surahs revealed in Makkah, when the believers were a handful and nothing of the likeness had happened yet: no emigration, no law, no army, no victory over the men who persecuted them. All that made him like Moosa came after the ayah that said he was."),
                      .text("The likeness is close. Each brought a law from God, not only a message; each led a people, judged between them and fought for them; each led those who believed out of the land that persecuted them; each saw his enemies overthrown, Pharaoh in the sea and the chiefs of Quraysh at Badr, until in the end Makkah opened to the Prophet; and each married, had children, and died a natural death. The prophets of Israel who came after Moosa judged by the Torah rather than bringing a new law of their own, and of the law and the prophets Eesa says, “I am not come to destroy, but to fulfil” (Matthew 5:17). The one like Moosa is the one who brought a law as Moosa did."),
                  ]),
                  SignSection("FROM AMONG THEIR BRETHREN", [
                      .text("The prophet is to come “from among their brethren”, and the Torah uses the word of Israel's kin outside Israel: it calls the Edomites, the descendants of Esau, “your brethren the children of Esau” (Deuteronomy 2:4). Ibn al-Qayyim relates the answer a Muslim scholar of the Maghrib gave a Jew who said the promised prophet was Joshua. That cannot be, he said: the Torah's own last chapter says no prophet like Moosa arose in Israel; and the brethren of Israel are the Arabs, the children of Ismaa‘eel, or the children of Esau, from whose line no prophet came after Moosa. That leaves the children of Ismaa‘eel."),
                      .text("The words “will put my words in his mouth” describe how the Quran came: the Prophet did not compose it, but recited what he was given. And the Quran calls on the learned of the Children of Israel as witnesses. One of them, it says, testified to it and believed:"),
                      .quran("46:10"),
                      .text("Their scholars' knowing it, it says elsewhere, was itself a sign:"),
                      .quran("26:196-197"),
                      .text("Abdullah ibn Amr ibn al-As said that an ayah of the Quran describing the Prophet appears in the Torah in these words:"),
                      .hadith("bukhari:4838", cite: "Saheeh al-Bukhaari 4838", arabic: 30...96, english: 0...156),
                  ]),
                  SignSection("IN MY NAME", [
                      .text("The promise goes on to the test that tells the true prophet from the false, and both halves bear on him. The true one speaks God's words “in my name” (Deuteronomy 18:19); the false one dies:"),
                      .quote("“But the prophet, which shall presume to speak a word in my name, which I have not commanded him to speak, or that shall speak in the name of other gods, even that prophet shall die.” (Deuteronomy 18:20, KJV)"),
                      .text("Muslim writers have noted that every surah of the Quran but one opens with the words “In the name of Allah, the Entirely Merciful, the Especially Merciful”, recited as he was given them. And the Quran gives the same warning the Torah gives against a prophet who invents, and gives it about him:"),
                      .quran("69:44-47"),
                      .text("He was not cut off. He was told that Allah would protect him from the people (5:67), came through the plots in Makkah, the cave and the battles, and died in Madinah in his sixty-third year, after the ayah that told the believers their religion was complete (5:3). By the Torah's own test, a man who presumed would not have lived to finish."),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("Christians read the promise as Jesus, as Peter applies it in Acts 3:22. Jews, following their classical commentators, read it as the line of Israelite prophets who came after Moosa one by one. Yet the Gospel of John has the priests ask John the Baptist whether he is the Christ, or Elias, or “that prophet” (John 1:21), so the Jews of that day awaited the prophet like Moses as someone other than the Messiah. And one prophet like Moosa is promised, while the Torah's last chapter says none like him arose in Israel. Proving Islam's chapter on the Bible gives the full argument."),
                  ]),
              ]),
        .init(id: "paran", title: "He shone forth from Paran",
              summary: "Moosa's last blessing names three mountains, Sinai, Seir and Paran; Muslim scholars read them as the Torah, the Gospel and the Quran.",
              group: .foretold,
              aliases: ["faran", "sinai", "seir", "deuteronomy 33", "habakkuk 3", "teman", "ten thousand", "ten thousands of saints", "conquest of makkah", "fath makkah", "wilderness of paran", "fig and olive", "ibn qutaybah", "mount hira"],
              sections: [
                  SignSection("THREE MOUNTAINS", [
                      .text("Before his death, Moosa (peace be upon him) blessed the Children of Israel. The blessing opens with three places:"),
                      .quote("“And he said, The LORD came from Sinai, and rose up from Seir unto them; he shined forth from mount Paran, and he came with ten thousands of saints: from his right hand went a fiery law for them.” (Deuteronomy 33:2, KJV)"),
                      .text("The prophet Habakkuk uses the same picture in his prayer:"),
                      .quote("“God came from Teman, and the Holy One from mount Paran. Selah. His glory covered the heavens, and the earth was full of his praise.” (Habakkuk 3:3, KJV)"),
                      .text("And Genesis names Paran as the place where Ismaa‘eel grew up, after he and his mother were sent away:"),
                      .quote("“And he dwelt in the wilderness of Paran: and his mother took him a wife out of the land of Egypt.” (Genesis 21:21, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("Ibn Taymiyyah, in al-Jawaab as-Saheeh, gives the reading in the words of Ibn Qutaybah, as many scholars before him had made it, and Ibn al-Qayyim repeats it in Hidaayat al-Hayaara. God's coming from Sinai is His sending down the Torah to Moosa on Sinai, as Muslims and the People of the Book agree. His rising from Seir, a range in the land of Shaam where Eesa's prophethood appeared, is the Gospel. And His shining forth from Paran is the Quran sent down to the Prophet Muhammad (peace and blessings be upon him), for the mountains of Paran are the mountains of Makkah, and among them is Hira, where the first revelation came. The order is the order of time, and Ibn Taymiyyah likened the three to the break of dawn, the sunrise, and the sun high in the sky, since the light of the last spread over the east and the west of the earth."),
                      .text("He set beside it the oath that opens Surat at-Teen, which names the same three places: the fig and the olive of the Holy Land where Eesa was sent, Mount Sinai where Moosa was spoken to, and the secure city where Ibraaheem settled Ismaa‘eel:"),
                      .quran("95:1-3"),
                  ]),
                  SignSection("WHY PARAN IS MAKKAH", [
                      .text("The argument rests on Genesis 21:21. Ismaa‘eel grew up in the wilderness of Paran, and it is known by mass transmission and the agreement of the nations, said Ibn Taymiyyah, that Ismaa‘eel was raised in Makkah and built the House there with his father; so the land of Makkah is Paran. The Quran keeps Ibraaheem's prayer as he left them there:"),
                      .quran("14:37"),
                      .text("The blessing also says he came “with ten thousands of saints”. Al-Qaraafi read those holy myriads at his right hand as the Prophet's Companions, and modern writers set the number beside the conquest of Makkah, when he came to the city of Ismaa‘eel with an army of ten thousand:"),
                      .hadith("bukhari:4276", cite: "Saheeh al-Bukhaari 4276", arabic: 24...54, english: 0...45),
                      .text("“Ten thousands” is a multitude, not a count, so this is a resonance, not the argument. Nor does the argument rest on Habakkuk's “his praise”: the Arabic rendering Ibn al-Qayyim quoted reads that the earth was filled with the praise of Ahmad, which says more than the Bible's text does."),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("Jewish and Christian readers place all three in the south, on the route of the Exodus. Seir is the hill country of Edom, where the Torah itself says “the children of Esau” lived (Deuteronomy 2:4), and Paran is the wilderness between Sinai and Canaan, where the Israelites came after they left Sinai (Numbers 10:12). On this reading the verse describes one event, God's appearing at Sinai, seen blazing over the mountains around it, and the fiery law in His right hand is the Torah."),
                      .text("The Muslim scholars knew this geography. Ibn Taymiyyah himself notes that the wilderness between Makkah and Sinai is called the wilderness of Paran. Their answer is that the name reaches to Makkah, as Genesis shows by settling Ismaa‘eel in Paran; that the three verbs grow brighter one after another, which suits three revelations in sequence better than a single event; and that after Eesa no scripture came down and no prophet was sent anywhere in that land except at Makkah. It is a reading, and it is argued, but it was not invented: it was made from the text of the Torah and the history of Ismaa‘eel."),
                  ]),
              ]),
        .init(id: "kedar-flight", title: "The flight, and Kedar's fall within a year",
              summary: "Isaiah's burden upon Arabia tells of men fleeing the drawn sword, fed by the people of Tema, and of the glory of Kedar failing within a year.",
              group: .foretold,
              aliases: ["isaiah 21", "burden upon arabia", "tema", "tayma", "taima", "dedan", "dedanim", "kedar", "qedar", "qaydar", "hijrah", "hijra", "migration", "emigration", "madinah", "medina", "yathrib", "ansar", "badr", "within a year", "archers", "isaiah 42", "sela", "sal'", "sala", "mount sal", "the rock", "ten thousand", "conquest of makkah"],
              sections: [
                  SignSection("THE BURDEN UPON ARABIA", [
                      .text("Among Isaiah's oracles against the nations is one headed “The burden upon Arabia”. It speaks of caravans sleeping rough in the thickets, of a people who bring water and bread to men in flight, and of a year at whose end the glory of Kedar fails:"),
                      .quote("“The burden upon Arabia. In the forest in Arabia shall ye lodge, O ye travelling companies of Dedanim. The inhabitants of the land of Tema brought water to him that was thirsty, they prevented with their bread him that fled. For they fled from the swords, from the drawn sword, and from the bent bow, and from the grievousness of war.” (Isaiah 21:13–15, KJV)"),
                      .quote("“For thus hath the Lord said unto me, Within a year, according to the years of an hireling, and all the glory of Kedar shall fail: And the residue of the number of archers, the mighty men of the children of Kedar, shall be diminished: for the LORD God of Israel hath spoken it.” (Isaiah 21:16–17, KJV)"),
                      .text("Every name in it is a name of Ismaa‘eel's Arabia. Kedar and Tema are two of Ismaa‘eel's twelve sons (Genesis 25:13–15), and the Bible uses Kedar for the Arabs of the desert as a whole. Tema survives as the oasis of Tayma in the north of the Hijaaz, and Dedan was the old name of al-Oola, on the incense road north of Madinah."),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("Ibn al-Qayyim, in Hidaayat al-Hayaara, quotes from Isaiah the Arabs routed before drawn swords and bent bows, from the severity of the battle, and says what it describes:"),
                      .quote("“This tells of what befell the worshippers of idols at the hands of the Messenger of Allah (peace and blessings be upon him) and his Companions on the day of Badr and the day of Hunayn.” (Ibn al-Qayyim, Hidaayat al-Hayaara)"),
                      .text("Ibn Katheer quotes the same lines in al-Bidaayah wan-Nihaayah. Later Muslim writers carried the reading back to the start of the oracle, to the flight that came before Badr, and line by line it fits."),
                      .text("They fled from the drawn sword. The chiefs of Quraysh met to decide whether to hold him, kill him or drive him out, and he left Makkah by night with Abu Bakr:"),
                      .quran("8:30"),
                      .text("The people of the land he reached took them in, and the Quran praises them for it: they loved those who came to them, and preferred them over themselves even when they were in need:"),
                      .quran("59:9"),
                      .hadith("bukhari:3925", cite: "Saheeh al-Bukhaari 3925", arabic: 62...85, english: 56...86),
                      .text("Then the glory of Kedar failed. Quraysh were of the line of Ismaa‘eel, and Badr was where their chiefs fell: Abu Jahl, Utbah and Shaybah, Umayyah ibn Khalaf and the others whose names Quraysh had been proud of. Al-Baraa’ ibn Aazib gave the count:"),
                      .hadith("bukhari:3986", cite: "Saheeh al-Bukhaari 3986", arabic: 37...54, english: 25...53),
                      .quran("3:123"),
                  ]),
                  SignSection("THE ROCK", [
                      .text("Isaiah names Kedar once more, in the chapter that opens with the servant who brings judgment to the Gentiles. The wilderness and the villages of Kedar are told to lift up their voice:"),
                      .quote("“Let the wilderness and the cities thereof lift up their voice, the villages that Kedar doth inhabit: let the inhabitants of the rock sing, let them shout from the top of the mountains. Let them give glory unto the LORD, and declare his praise in the islands.” (Isaiah 42:11–12, KJV)"),
                      .text("Where the King James has “the rock”, the Hebrew has Sela. The classical scholars read an Arabic version that gave “the dwellers of the caves”, and asked who dwells in those caves and mountains, if not the Arabs. Some later writers have gone further and read Sela as Sal', the mountain that overlooks Madinah; no classical scholar is known to have said so, and it rests on the likeness of a name. Sal' itself is named in the hadith, as the mountain the people of Madinah looked out on:"),
                      .hadith("bukhari:1013", cite: "Saheeh al-Bukhaari 1013", arabic: 81...107, english: 94...136),
                      .text("Proving Islam's chapter on the Bible reads the servant of Isaiah 42 at length. And eight years after the flight, the one who had fled came back to Makkah with an army of ten thousand: the return that the entry “He shone forth from Paran” sets beside Moosa's blessing."),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("Jewish and Christian commentators place the oracle in Isaiah's own century, the eighth before Christ, when the kings of Assyria campaigned against the tribes of north Arabia; Kedar is named among the peoples the Assyrian inscriptions record defeating. On that reading the fugitives are caravans of Dedan caught in those wars, Tema shelters them, and the year is the time left before Assyria broke Kedar's power. The rock of Isaiah 42 is read as Sela, the rock city of Edom (2 Kings 14:7), or simply as the people of the cliffs."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a reading, argued, not a proof text, and it is held at two strengths. That the oracle's rout of Kedar is Badr is the reading of Ibn al-Qayyim; that its fugitives are the Hijrah is a modern one, and the dates fit only loosely: Badr was fought about a year and a half after the Prophet reached Madinah, and Tayma lies some four hundred kilometres north of it. Nor is Kedar certainly the ancestor of Quraysh: Ibn Katheer writes that the Arabs of the Hijaaz trace themselves to Ismaa‘eel's two sons Naabit and Qaydaar, and the genealogists most often trace Adnaan through Naabit. What can fairly be said is that it describes men fleeing the drawn sword into Arabia, fed and sheltered by its people, and the glory and the fighting men of Kedar cut down soon after; and that the history of the Hijrah and Badr matches those lines closely."),
                  ]),
              ]),
        .init(id: "two-riders", title: "A rider on a donkey, and a rider on a camel",
              summary: "Isaiah's watchman sees riders on donkeys and riders on camels, and then hears that Babylon is fallen and its idols broken.",
              group: .foretold,
              aliases: ["isaiah 21", "watchman", "chariot of asses", "chariot of camels", "donkey", "ass", "camel", "two riders", "babylon is fallen", "graven images", "idols", "persia", "chosroes", "kisra", "ctesiphon", "mada'in", "iraq", "jesus", "isa"],
              sections: [
                  SignSection("THE WATCHMAN", [
                      .text("The same chapter of Isaiah opens with a vision in the desert. The prophet is told to set a watchman and have him report what he sees:"),
                      .quote("“For thus hath the Lord said unto me, Go, set a watchman, let him declare what he seeth. And he saw a chariot with a couple of horsemen, a chariot of asses, and a chariot of camels; and he hearkened diligently with much heed.” (Isaiah 21:6–7, KJV)"),
                      .quote("“And, behold, here cometh a chariot of men, with a couple of horsemen. And he answered and said, Babylon is fallen, is fallen; and all the graven images of her gods he hath broken unto the ground.” (Isaiah 21:9, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("This is one of the oldest of the readings. Ibn Taymiyyah relays it from the scholars before him, in the Arabic version they knew, in which the watchman sees two riders coming, one on a donkey and the other on a camel, and one says to the other, Babylon is fallen:"),
                      .quote("“They said: the rider of the donkey is the Messiah, and the rider of the camel is Muhammad (peace and blessings be upon him), and he is better known for riding the camel than the Messiah for riding the donkey. And through Muhammad the idols of Babylon fell.” (Ibn Taymiyyah, al-Jawaab as-Saheeh)"),
                      .text("Ibn al-Qayyim gives the same reading in Hidaayat al-Hayaara, adding that the rider of the donkey is the Messiah by the Christians' own account as well as ours, and that the idols of Babylon fell through Muhammad, not through the Messiah; al-Maawardi, al-Qurtubi and al-Qaraafi quote the passage too. The Gospels tell that Eesa rode into Jerusalem on a donkey (Matthew 21:5–7), and the Prophet was a man of the Arabs, the people of the camel."),
                      .text("That is the order history kept. The empire that ruled from Iraq in his day was Persia, its capital at al-Madaa’in on the Tigris, some seventy kilometres from the ruins of Babylon. He foretold its end and its treasures spent in the cause of Allah:"),
                      .hadith("bukhari:3618", cite: "Saheeh al-Bukhaari 3618", arabic: 29...49, english: 4...46),
                      .text("Within a few years of his death al-Madaa’in fell to the Muslims and the treasures of Chosroes were carried to Madinah, as he had said. And the idols of his own land he broke with his own hand, on the day Makkah opened:"),
                      .hadith("bukhari:4287", cite: "Saheeh al-Bukhaari 4287", arabic: 25...58, english: 0...47),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("The chapter itself opens with “the burden of the desert of the sea” and calls on Elam and Media to go up (Isaiah 21:1–2), so Jewish and Christian commentators read the vision as Babylon's fall to the Medes and the Persians under Cyrus in 539 BC, or to an Assyrian king before him. On that reading the riders on donkeys and camels are the columns of the army, or the messengers who bring the news, and the broken images are Babylon's own gods."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a reading, argued, not a proof text. The Hebrew can be read as troops of riders rather than two men, and the city of Babylon had long been a ruin when the Muslims came to Iraq. What can fairly be said is that the vision pairs a rider of donkeys with a rider of camels and puts the fall of Babylon's kingdom and the breaking of its idols after them; that Eesa is the prophet remembered on a donkey; and that the kingdom which ruled Babylon's land fell, after Muhammad, to the people of the camel."),
                  ]),
              ]),
        .init(id: "another-tongue", title: "Another tongue, line upon line",
              summary: "Moosa warned Israel of a nation that was not a people, and Isaiah of a message in another tongue, given here a little and there a little.",
              group: .foretold,
              aliases: ["deuteronomy 32", "isaiah 28", "not a people", "foolish nation", "jealousy", "stammering lips", "another tongue", "other tongues", "foreign tongue", "arabic", "precept upon precept", "line upon line", "here a little", "tsav", "qav", "huruf muqattaat", "muqatta'at", "disconnected letters", "broken letters", "alif lam mim", "unlettered", "ummi"],
              sections: [
                  SignSection("A NATION THAT WAS NOT A PEOPLE", [
                      .text("In the song Moosa taught the Children of Israel before his death, God says that because they provoked Him with what was not God, He would provoke them with what was not a people:"),
                      .quote("“They have moved me to jealousy with that which is not God; they have provoked me to anger with their vanities: and I will move them to jealousy with those which are not a people; I will provoke them to anger with a foolish nation.” (Deuteronomy 32:21, KJV)"),
                      .text("Rahmatullah al-Kairanawi, the nineteenth-century scholar of India who debated the missionaries, wrote in Izhar al-Haqq that the foolish nation is the Arabs, and rejected Paul's reading of it as the Greeks. The Arabs had no scripture and no prophet of their own since Ismaa‘eel, and it was among them, the unlettered, that the last messenger was raised:"),
                      .quran("62:2"),
                      .text("The Quran states the same rule of replacement in its own words, to those who were given the message and turn away from it:"),
                      .quran("47:38"),
                  ]),
                  SignSection("ANOTHER TONGUE", [
                      .text("Isaiah speaks to leaders who mocked his teaching, and warns them that God would speak to them another way:"),
                      .quote("“For precept must be upon precept, precept upon precept; line upon line, line upon line; here a little, and there a little: For with stammering lips and another tongue will he speak to this people. To whom he said, This is the rest wherewith ye may cause the weary to rest; and this is the refreshing: yet they would not hear.” (Isaiah 28:10–12, KJV)"),
                      .text("Modern Muslim writers, Jamal Badawi among them, read this of the Quran: God would speak to the people of the earlier scripture in another tongue, through a messenger who was not of them, and the Quran calls itself a book in Arabic that confirms the book of Moosa:"),
                      .quran("46:12"),
                      .text("And “here a little, and there a little” is how it came: not as one book handed down whole, but piece by piece over twenty-three years, as events called for it. The Quran answers those who asked why:"),
                      .quran("17:106"),
                      .text("“Yet they would not hear” is what the Quran says of those who knew the promise and refused it when it came:"),
                      .quran("2:89"),
                  ]),
                  SignSection("THE LETTERS", [
                      .text("In Hebrew the words translated “precept upon precept, line upon line” are short and strange: tsav la-tsav, tsav la-tsav, qav la-qav, qav la-qav, ze'er shaam, ze'er shaam. The word tsav occurs nowhere else in the Bible but these two verses. Many commentators hear in it the babble the drunken leaders made of Isaiah's teaching, as if he spoke to infants; others hear the names of two letters of the Hebrew alphabet, tsade and qof, drilled one by one as a child is taught to read."),
                      .text("Some Muslims have set beside these syllables the letters that open twenty-nine surahs of the Quran, each read out letter by letter: Alif. Lam. Meem. It is a recent observation, made by no scholar early or late that we know of, and it is offered here only as a likeness:"),
                      .quran("2:1-2"),
                      .text("What the letters mean, Allah knows best, and the scholars of tafseer held many views. Ibn Katheer, after setting them out, inclined to the view he credits to Ibn Taymiyyah and al-Mizzi: that the letters open the surahs to show that the Quran is made of the very letters the Arabs spoke with, and still they could not bring its like."),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("In its setting, Isaiah 28 is addressed to the drunkards of Ephraim, the priests and prophets who erred through strong drink, and the scoffers who ruled Jerusalem (28:1, 7, 14), and the “stammering lips and another tongue” are read as the Assyrian invaders, whose foreign speech would teach the people what they refused to hear from their own prophet. Paul applies the verse to speaking in tongues (1 Corinthians 14:21), and Deuteronomy 32:21 to the Gentiles who accepted the Gospel (Romans 10:19). Jewish commentators read the foolish nation as the heathen nations God used to chastise Israel."),
                  ]),
                  SignSection("A NOTE", [
                      .text("These are readings, argued, not proof texts, and none of them is classical: Deuteronomy 32:21 was read of the Arabs in the nineteenth century, Isaiah 28 only in modern times, and the link between Isaiah's syllables and the letters that open the surahs is an observation no scholar is known to have made, to be held lightly. Neither passage names a prophet or a people. What can fairly be said is that the Torah threatens Israel with a nation that was not a people, that Isaiah warns of God speaking to them in another tongue, a little here and a little there, and that they would not hear; and that the Quran came in Arabic, to an unlettered nation, piece by piece, and was refused by many of those who had awaited it."),
                  ]),
              ]),
        .init(id: "unlettered-reader", title: "The book given to one who could not read",
              summary: "Isaiah describes a book handed to a man who is not learned, with the words “Read this”, and his answer, “I am not learned”.",
              group: .foretold,
              aliases: ["isaiah 29", "read this", "i am not learned", "iqra", "read", "ma ana bi qari", "unlettered", "ummi", "illiterate", "hira", "first revelation", "jibril", "gabriel", "sealed book"],
              sections: [
                  SignSection("THE SEALED BOOK", [
                      .text("Isaiah compares the people's blindness to a book no one will read. The learned man says it is sealed; then it is given to one who cannot read at all:"),
                      .quote("“And the vision of all is become unto you as the words of a book that is sealed, which men deliver to one that is learned, saying, Read this, I pray thee: and he saith, I cannot; for it is sealed: And the book is delivered to him that is not learned, saying, Read this, I pray thee: and he saith, I am not learned.” (Isaiah 29:11–12, KJV)"),
                  ]),
                  SignSection("THE FIRST NIGHT IN HIRA", [
                      .text("Ahmed Deedat, in his lecture What the Bible Says about Muhammad, set this verse beside the first night of revelation, and many Muslim writers have done so since. Aa’ishah's account of that night, in the cave of Hira:"),
                      .hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 84...92, english: 103...123),
                      .text("The Hebrew of Isaiah's “Read this” is qra na zeh, and qara is the Hebrew form of the Arabic qara’a, the verb of the angel's command, iqra'. The answer, lo yada‘ti sefer, is literally “I do not know a book”, that is, I cannot read. Three times the angel said it and three times he answered, and then came the first words of the Quran:"),
                      .quran("96:1-5"),
                      .text("That he could not read or write is not a weakness Muslims explain away. The Quran calls him the unlettered prophet whom the People of the Book find written in their own books, and gives the reason it matters:"),
                      .quran("29:48"),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("In its setting the passage is a parable, not a prediction of a person. Isaiah tells a people who would not see that the prophetic vision has become to them like a sealed book: the learned will not read it because it is sealed, the unlearned cannot because he does not know how, and so no one reads it at all. The verses that follow rebuke a people who honour God with their lips while their hearts are far from Him (Isaiah 29:13)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a modern reading, not one the classical scholars made, and read in its setting the book is a figure for a vision no one understood. What can fairly be said is that the scene in the second verse, a book handed to a man who cannot read, the words “Read this”, and the answer “I am not learned”, is the scene in the cave of Hira, as Aa’ishah reported it, almost word for word."),
                  ]),
              ]),
        .init(id: "flocks-of-kedar", title: "The flocks of Kedar at the house of glory",
              summary: "Isaiah sees camels covering the land, the flocks of Kedar and the rams of Nebaioth offered at the house of His glory, and gates never shut.",
              group: .foretold,
              aliases: ["isaiah 60", "arise shine", "camels", "dromedaries", "midian", "sheba", "kedar", "nebaioth", "nabit", "flocks", "rams", "sacrifice", "altar", "house of my glory", "kaaba", "hajj", "pilgrims", "gates open", "day and night", "masjid al-haram"],
              sections: [
                  SignSection("ARISE, SHINE", [
                      .text("Isaiah 60 is addressed to a city and a house that God will glorify. The nations come to its light, carried on camels, bringing their flocks to its altar:"),
                      .quote("“Arise, shine; for thy light is come, and the glory of the LORD is risen upon thee. For, behold, the darkness shall cover the earth, and gross darkness the people: but the LORD shall arise upon thee, and his glory shall be seen upon thee. And the Gentiles shall come to thy light, and kings to the brightness of thy rising.” (Isaiah 60:1–3, KJV)"),
                      .quote("“The multitude of camels shall cover thee, the dromedaries of Midian and Ephah; all they from Sheba shall come: they shall bring gold and incense; and they shall shew forth the praises of the LORD. All the flocks of Kedar shall be gathered together unto thee, the rams of Nebaioth shall minister unto thee: they shall come up with acceptance on mine altar, and I will glorify the house of my glory.” (Isaiah 60:6–7, KJV)"),
                      .quote("“Therefore thy gates shall be open continually; they shall not be shut day nor night.” (Isaiah 60:11, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("The classical scholars read this chapter of Makkah. Al-Maawardi in A‘laam an-Nubuwwah, Ibn Taymiyyah in al-Jawaab as-Saheeh, Ibn al-Qayyim in Hidaayat al-Hayaara and al-Qaraafi all quote it, in an Arabic version whose gates “are opened night and day and never shut, and they take you as their qiblah”, and they reach the same verdict:"),
                      .quote("“These attributes, all of them, came to pass in Makkah.” (Ibn Taymiyyah, al-Jawaab as-Saheeh, relaying the scholars before him)"),
                      .text("Nebaioth and Kedar are the first two sons of Ismaa‘eel (Genesis 25:13). Their flocks are offered at a house of God, brought by a multitude of camels from the lands of Arabia. That is the Hajj, as Ibraaheem was told to call it:"),
                      .quran("22:27"),
                      .quran("22:36"),
                      .text("The house is the one Ibraaheem and Ismaa‘eel raised, the first set up for mankind, in the valley where Ibraaheem left his son and prayed that hearts would incline to them:"),
                      .quran("3:96-97"),
                      .text("And its gates are not shut, day or night. The Prophet forbade the guardians of the House to keep anyone from it at any hour:"),
                      .hadith("tirmidhi:868", cite: "Jaami‘ at-Tirmidhi 868", arabic: 32...49, english: 3...27),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("Jewish and Christian readers take the chapter as addressed to Jerusalem, restored after the exile, and the house as the temple there; the chapter itself goes on to call the city “The city of the LORD, The Zion of the Holy One of Israel” (Isaiah 60:14). Christians read it further of the Church, to which the nations come."),
                      .text("The Muslim answer is that the details are Arabian before they are anything else: the camels, the gold and incense of Sheba, the flocks of Ismaa‘eel's own sons offered at the altar. The tribes of Kedar and Nebaioth never brought their flocks to an altar in Jerusalem; their descendants have brought them to Makkah every year for fourteen centuries, and its gates have not been shut."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a reading, argued, not a proof text, and the chapter does name Zion. What can fairly be said is that it describes a house of God to which the nations come on camels, where the flocks of Ismaa‘eel's sons are offered, and whose gates stand open night and day; and that one house on earth has answered to that description, every year, without a break."),
                  ]),
              ]),
        .init(id: "barren-one", title: "Sing, O barren",
              summary: "Isaiah calls on a barren woman to sing, for the children of the desolate one will outnumber the children of the married wife.",
              group: .foretold,
              aliases: ["isaiah 54", "barren", "desolate", "married wife", "hajar", "hagar", "sarah", "makkah", "mecca", "children", "ummah", "followers", "galatians 4", "enlarge thy tent", "inherit the gentiles"],
              sections: [
                  SignSection("THE BARREN ONE", [
                      .quote("“Sing, O barren, thou that didst not bear; break forth into singing, and cry aloud, thou that didst not travail with child: for more are the children of the desolate than the children of the married wife, saith the LORD. Enlarge the place of thy tent, and let them stretch forth the curtains of thine habitations: spare not, lengthen thy cords, and strengthen thy stakes; For thou shalt break forth on the right hand and on the left; and thy seed shall inherit the Gentiles, and make the desolate cities to be inhabited.” (Isaiah 54:1–3, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("Ibn Taymiyyah, Ibn al-Qayyim, al-Qurtubi and Ibn Katheer all read the barren one as Makkah, and Ibn Taymiyyah gives the reason:"),
                      .quote("“By the barren one he means Makkah, for she bore no prophet before ours. And he cannot mean Jerusalem by the barren one, for it is the house of the prophets and the mine of revelation.” (Ibn Taymiyyah, al-Jawaab as-Saheeh)"),
                      .text("Al-Qaraafi read it also of Haajar, the mother of the Arabs, given the good news that her offspring would be greater than Saarah's. Two women stand behind the verse in Genesis, and Paul himself read it of them: Saarah, the wife, from whose line came Israel and prophet after prophet; and Haajar, sent away into the desert with her son, in whose valley no prophet arose after Ismaa‘eel for more than two thousand years, until the last. He hoped that his followers would be the greater number:"),
                      .hadith("bukhari:4981", cite: "Saheeh al-Bukhaari 4981", arabic: 43...49, english: 29...47),
                      .text("“Thy seed shall inherit the Gentiles” is what followed: within a century of his death the religion that began in a barren valley had reached from Spain to India, and the nations it reached became its people."),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("Jewish readers take the barren one as Jerusalem, desolate in exile, promised more children on her return than she had before it. Paul, writing to the Galatians, applies the verse to the Jerusalem above, and in the same passage makes Hagar the figure of Sinai and of bondage, and Saarah the free woman (Galatians 4:22–27)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a reading, argued, not a proof text; the chapter speaks to a woman, not of a prophet, and each reader identifies her by his own faith. What can fairly be said is that it promises a barren, forsaken one more children than the wife, a tent to be widened and a seed to inherit the nations; and that the valley of Haajar, which bore no prophet after Ismaa‘eel for more than two thousand years, now has more people facing it in prayer than any city on earth."),
                  ]),
              ]),
        .init(id: "valley-of-baca", title: "The valley of Baca",
              summary: "A psalm blesses pilgrims who pass through the valley of Baca and make it a well; the Quran names the first House as the one at Bakkah.",
              group: .foretold,
              aliases: ["psalm 84", "baca", "bakkah", "bakka", "makkah", "mecca", "valley", "well", "zamzam", "pilgrims", "pilgrimage", "hajj", "house of god", "dwell in thy house"],
              sections: [
                  SignSection("THE PSALM", [
                      .text("Psalm 84 is a pilgrim's song: it longs for the courts of God's house and blesses those who make the journey to it:"),
                      .quote("“Blessed are they that dwell in thy house: they will be still praising thee. Selah. Blessed is the man whose strength is in thee; in whose heart are the ways of them. Who passing through the valley of Baca make it a well; the rain also filleth the pools.” (Psalm 84:4–6, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("No classical scholar read the psalm this way; it is a modern reading, made by Jamal Badawi and others, from the name. The Quran calls the place of the first House by the same sound:"),
                      .quran("3:96"),
                      .text("The Arabic of that ayah does not say Makkah; it says bi-Bakkah, “at Bakkah”, the name the Quran gives the place of the House. And a well in a dry valley is exactly what Makkah was given, when Haajar ran between the hills looking for water for Ismaa‘eel:"),
                      .hadith("bukhari:3364", cite: "Saheeh al-Bukhaari 3364", arabic: 281...296, english: 485...510),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("Most translators take Baca as a word, not a name: the valley of weeping, from the Hebrew bakah, to weep, or the valley of the balsam trees. On that reading the psalm describes pilgrims going up to Jerusalem, who turn a dry valley into springs by their faith, and the next verse says so: “every one of them in Zion appeareth before God” (Psalm 84:7)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a resonance, not a proof text. The psalm's goal is Zion, and the likeness rests on a single name. What can fairly be said is that it speaks of a house of God, of pilgrims who pass through a valley called Baca and find a well there, and that the Quran calls the valley of the first House Bakkah, where a well was opened in a dry valley and pilgrims have drunk from it ever since."),
                  ]),
              ]),
        .init(id: "praised-continually", title: "Prayer made for him continually",
              summary: "A psalm describes a king who rules from sea to sea, for whom prayer is made continually and who is praised every day.",
              group: .foretold,
              aliases: ["psalm 72", "from sea to sea", "dominion", "prayer made for him", "praised daily", "his name shall endure", "salawat", "salah ala an-nabi", "durood", "blessings on the prophet", "adhan", "name raised", "sheba"],
              sections: [
                  SignSection("THE PSALM", [
                      .text("Psalm 72 is a prayer for a king. It asks that he judge the poor with righteousness, and then describes his reign:"),
                      .quote("“He shall have dominion also from sea to sea, and from the river unto the ends of the earth. They that dwell in the wilderness shall bow before him; and his enemies shall lick the dust.” (Psalm 72:8–9, KJV)"),
                      .quote("“And he shall live, and to him shall be given of the gold of Sheba: prayer also shall be made for him continually; and daily shall he be praised. … His name shall endure for ever: his name shall be continued as long as the sun: and men shall be blessed in him: all nations shall call him blessed.” (Psalm 72:15, 17, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("Al-Maawardi, Ibn Taymiyyah, Ibn al-Qayyim and Ibn Katheer all quote this psalm, in an Arabic version that reads:"),
                      .quote("“He will be given of the gold of the land of Sheba; prayer will be made for him at every time, and he will be blessed every day, and his remembrance will endure for ever.” (al-Maawardi, A‘laam an-Nubuwwah)"),
                      .text("Ibn Taymiyyah explained the prayer as the one Muslims make in every one of the five daily prayers: O Allah, send blessings on Muhammad. Allah commands it of the believers:"),
                      .quran("33:56"),
                      .hadith("bukhari:3370", cite: "Saheeh al-Bukhaari 3370", arabic: 76...96, english: 66...103),
                      .text("Daily he is praised, and his name is continued as long as the sun: the call to prayer names him five times a day, and as the day moves around the earth, it is being called somewhere at every hour:"),
                      .quran("94:4"),
                      .text("And the dominion from sea to sea, with those who dwell in the wilderness bowing before him, is what he was shown of his nation's reach:"),
                      .hadith("muslim:2889a", cite: "Saheeh Muslim 2889a", arabic: 38...53, english: 0...37),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("The psalm is headed “A Psalm for Solomon”, and Jewish readers take it as a prayer for the son of Daawood and the kings of his line, or for the Messiah. Christians read it of Jesus, to whom the wise men brought gold and incense."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a reading, argued, not a proof text; the psalm is a prayer for a king, and each faith reads its king into it. The Arabic version the classical scholars read also differs from the Hebrew in places: it has the kings of Persia where the Hebrew has Tarshish and Sheba. What can fairly be said is that no man has had prayer made for him, by name, by so many people, every day, for fourteen centuries; and that of all the readings, the line “prayer also shall be made for him continually; and daily shall he be praised” is lived out word for word in the prayers of the Muslims."),
                  ]),
              ]),
        .init(id: "girded-sword", title: "The king girded with the sword",
              summary: "A psalm praises one fairer than the children of men, grace on his lips, girded with a sword, whose arrows bring the peoples down under him.",
              group: .foretold,
              aliases: ["psalm 45", "gird thy sword", "sword", "most mighty", "arrows", "grace is poured into thy lips", "fairer than the children of men", "jawami al-kalim", "victorious with awe", "nusirtu bir-ru'b", "after dawud", "after david", "jihad"],
              sections: [
                  SignSection("THE PSALM", [
                      .text("Psalm 45 is addressed to a king. It praises his beauty and his speech, and then arms him:"),
                      .quote("“Thou art fairer than the children of men: grace is poured into thy lips: therefore God hath blessed thee for ever. Gird thy sword upon thy thigh, O most mighty, with thy glory and thy majesty. And in thy majesty ride prosperously because of truth and meekness and righteousness; and thy right hand shall teach thee terrible things. Thine arrows are sharp in the heart of the king's enemies; whereby the people fall under thee.” (Psalm 45:2–5, KJV)"),
                      .quote("“I will make thy name to be remembered in all generations: therefore shall the people praise thee for ever and ever.” (Psalm 45:17, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("The classical scholars quoted it as part of the Zaboor, the book given to Daawood, and argued that its king must be a prophet who came after him. Ibn Taymiyyah relays the argument from the scholars before him, and Ibn al-Qayyim and al-Qurtubi make it too:"),
                      .quote("“They said: no one among the prophets after Daawood girded the sword except Muhammad.” (Ibn Taymiyyah, al-Jawaab as-Saheeh)"),
                      .text("Eesa did not take up the sword; in the Gospels he tells the disciple who drew one to put it back in its place (Matthew 26:52). The prophet after Daawood who rode out because of truth, whose enemies fell before him and whose name the peoples praise in every generation, is the one the Quran describes with his Companions, forceful against the disbelievers and merciful among themselves:"),
                      .quran("48:29"),
                      .text("And the two gifts the psalm begins with, grace on his lips and a right hand that teaches terrible things, are the two he named himself:"),
                      .hadith("bukhari:2977", cite: "Saheeh al-Bukhaari 2977", arabic: 33...37, english: 4...30),
                  ]),
                  SignSection("THE OTHER READING", [
                      .text("The psalm calls itself “a Song of loves” and goes on to a royal wedding, the queen at the king's right hand in gold of Ophir and the princess brought to him (Psalm 45:9–15), so Jewish readers take it as a wedding song for a king of Daawood's line, and in time for the Messiah. Christians read it of Jesus, as the Letter to the Hebrews applies its sixth and seventh verses to him (Hebrews 1:8–9), and take the sword as the word of God."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a reading, argued, not a proof text; the psalm names no one, its own heading gives it to the sons of Korah, and much of it is about a wedding. What can fairly be said is that it praises a king after Daawood for the grace of his speech and arms him with a sword in the cause of truth, with peoples falling before him and his name praised in every generation; and that among the prophets after Daawood, the one whose life matches those lines is Muhammad (peace and blessings be upon him)."),
                  ]),
              ]),
        .init(id: "altogether-lovely", title: "Altogether lovely, the chiefest among ten thousand",
              summary: "The Song of Songs praises a beloved who is white and ruddy, chief among ten thousand, and altogether lovely: in Hebrew, machamaddim.",
              group: .foretold,
              aliases: ["song of songs", "song of solomon", "song 5", "machamaddim", "mahamaddim", "muhammadim", "muhammad by name", "altogether lovely", "white and ruddy", "chiefest among ten thousand", "ten thousand", "conquest of makkah", "beloved", "deedat", "zakir naik"],
              sections: [
                  SignSection("THE SONG", [
                      .text("The Song of Songs is a love poem in which a bride and her beloved praise each other. When the daughters of Jerusalem ask what makes her beloved more than another, she describes him from head to foot:"),
                      .quote("“My beloved is white and ruddy, the chiefest among ten thousand. His head is as the most fine gold, his locks are bushy, and black as a raven.” (Song of Solomon 5:10–11, KJV)"),
                      .quote("“His mouth is most sweet: yea, he is altogether lovely. This is my beloved, and this is my friend, O daughters of Jerusalem.” (Song of Solomon 5:16, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("This is a modern reading. Ahmed Deedat noted it in 1976, and Zakir Naik and others have made it widely known. In Hebrew “he is altogether lovely” is wekhullo machamaddim, and the argument is that machamaddim is the name Muhammad with the Hebrew plural of honour, -im, as Elohim is a plural used of the One God. The root h-m-d is the same root that gives the Arabic Muhammad, Ahmad and hamd."),
                      .text("Those who make it point to the rest of the description too. The beloved is “white and ruddy”, and the Companions described the Prophet (peace and blessings be upon him) as white and handsome of face:"),
                      .hadith("muslim:2340a", cite: "Saheeh Muslim 2340a", arabic: 24...29, english: 11...19),
                      .hadith("bukhari:3549", cite: "Saheeh al-Bukhaari 3549", arabic: 24...35, english: 0...14),
                      .text("And he is “the chiefest among ten thousand”: the Prophet marched on Makkah at the head of ten thousand:"),
                      .hadith("bukhari:4276", cite: "Saheeh al-Bukhaari 4276", arabic: 24...54, english: 0...45),
                  ]),
                  SignSection("WHY IT IS WEAK", [
                      .text("Machamaddim is not a name. It is a plural noun from machmad, a delight or a desirable thing, and the Bible uses the word a dozen times, always as a common noun and never as a name: “all our pleasant things are laid waste” (Isaiah 64:11), “the desire of thine eyes” (Ezekiel 24:16), “the beloved fruit of their womb” (Hosea 9:16). The same verse has another plural of the same kind: “his mouth is most sweet” is chikko mamtaqqim, “his palate is sweetnesses”. The -im is the poem's way of praising qualities, not a plural of honour on a proper name."),
                      .text("The root is shared, but its sense is not. In Hebrew h-m-d is to desire, and it is the verb of the commandment “Thou shalt not covet” (Exodus 20:17); in Arabic it is to praise. A name built from one is not the name built from the other."),
                      .text("Muslim scholars have said as much. A published answer of the IslamQA site (no. 246893) cautions against the argument: machamaddim is not anyone's proper name but means beauty and desirability, and the context does not allow a proper name to be forced into it. No classical scholar used the verse, and al-Kairanawi, who gathered the Bible's glad tidings at length in the nineteenth century, held the Song itself to be of very weak standing."),
                  ]),
                  SignSection("A NOTE", [
                      .text("It is included here because it is so often repeated, so that a Muslim knows what it is before he uses it. It is the weakest of the passages in this group: the word means delightful things, the poem is a love song, and the likeness rests on a root alone. The beloved's being white and ruddy and chief among ten thousand fits the Prophet, but it fits many a praised man. The arguments that do not need it are stronger without it."),
                  ]),
              ]),
        .init(id: "desire-of-nations", title: "The desire of all nations",
              summary: "Haggai promises that the desire of all nations shall come, that the latter house will be more glorious than the former, and that in this place God will give peace.",
              group: .foretold,
              aliases: ["haggai", "haggai 2", "desire of all nations", "chemdah", "hemdah", "himda", "ahmad", "latter house", "this house", "second temple", "in this place will i give peace", "shalom", "salam", "islam", "jerusalem", "bayt al-maqdis", "al-aqsa", "abdul-ahad dawud"],
              sections: [
                  SignSection("THE PROMISE", [
                      .text("Haggai spoke to the Jews who had come back from Babylon and were slow to rebuild the temple. Some still remembered the first house, and beside it the new one was “as nothing” in their eyes (Haggai 2:3). Haggai answered them:"),
                      .quote("“For thus saith the LORD of hosts; Yet once, it is a little while, and I will shake the heavens, and the earth, and the sea, and the dry land; And I will shake all nations, and the desire of all nations shall come: and I will fill this house with glory, saith the LORD of hosts. The silver is mine, and the gold is mine, saith the LORD of hosts. The glory of this latter house shall be greater than of the former, saith the LORD of hosts: and in this place will I give peace, saith the LORD of hosts.” (Haggai 2:6–9, KJV)"),
                  ]),
                  SignSection("THE MUSLIM READING", [
                      .text("This is a modern reading, made by Abdul-Ahad Daawood, a former Catholic priest, in his book Muhammad in the Bible. “The desire” is chemdah in Hebrew, from the root h-m-d, and he read it as Ahmad: “And the Ahmed of all nations will come”. “Peace” is shalom, the Hebrew of the Arabic salaam, the root of Islam; so in that place God would give Islam."),
                      .text("He set beside it what happened in that place. The Prophet was taken there by night and led the prophets in prayer, the scholars say at Bayt al-Maqdis:"),
                      .quran("17:1"),
                      .hadith("muslim:172", cite: "Saheeh Muslim 172", arabic: 129...131, english: 148...156),
                      .text("And in the caliphate of Umar the city was handed to the Muslims by treaty after a siege, and apart from the ninety years of the Crusaders a masjid has stood on the site of that house ever since."),
                  ]),
                  SignSection("WHY IT IS WEAK", [
                      .text("The Hebrew verb “shall come” is plural, u-va'u, “they shall come”, so most modern translations take chemdah as a collective, the precious things of the nations: “the treasures of all nations shall come in”. The next verse supports them: “The silver is mine, and the gold is mine.” The word is the same root as the Hebrew “covet”, and its sense is desirable things, not praise."),
                      .text("Christians read the desire of all nations as the Messiah, who came to the second house before it was destroyed, and Jewish readers as the wealth of the nations brought to adorn it. No classical Muslim scholar used the verse."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is a resonance, not a proof text, and a weak one: it rests on the root of one word and the meaning of another, and the grammar of the verse points to treasures. What can fairly be said is that it promises the house in Jerusalem a greater glory than the first and peace in that place; and that the place has been, for most of the fourteen centuries since, in the hands of those whose religion is named for peace, and the Prophet prayed there at the head of the prophets."),
                  ]),
              ]),
    ]

    // MARK: His greatest signs

    static let hisEntries: [Entry] = [
        .init(id: "quran", title: "The Quran itself",
              summary: "His standing miracle: the only one still open to examination fourteen centuries later.",
              group: .his,
              aliases: ["ijaz", "inimitability", "challenge", "eloquence", "language", "arabic",
                        "poetry", "literary", "muhammad"],
              sections: [
                  SignSection("THE STANDING MIRACLE", [
                      .text("The signs given to the earlier prophets were events: you had to be there. The Quran is the one miracle that did not end with the generation that saw it. The same text is in your hands now, and the challenge it makes is still open."),
                      .quran("2:23"),
                  ]),
                  SignSection("WHY IT LANDED WHERE IT DID", [
                      .text("Pre-Islamic Arabia measured a man by his tongue. Poetry was the currency of status, and the best verses were prized above wealth. The book came to the people least likely to be impressed by language and most able to judge it, and its fiercest opponents, who had every motive to answer it, never produced the three verses asked of them."),
                  ]),
              ]),
        .init(id: "moon", title: "The splitting of the moon",
              summary: "Asked for a sign, he pointed at the moon and it split in two before them.",
              group: .his,
              aliases: ["qamar", "shaqq al-qamar", "quraysh", "mina", "surah 54", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("The Quraysh asked him for a sign. At Mina, before them, the moon split."),
                      .hadith("bukhari:3636", cite: "Saheeh al-Bukhaari 3636", arabic: 27...46, english: 0...24),
                      .quran("54:1"),
                  ]),
                  SignSection("WHY IT IS REPORTED THE WAY IT IS", [
                      .text("The narration is plain to the point of flatness: it happened, and he said bear witness. What makes it hard to dismiss is the setting. It is addressed to hostile eyewitnesses in a Makkan surah, recited publicly to the very people who were there. A claim that a whole city had seen something it had not would have been the easiest of all to refute."),
                  ]),
              ]),
        .init(id: "isra", title: "The night journey and the ascent",
              summary: "Taken by night from Makkah to al-Aqsa and raised through the heavens, and he described a city he had never seen.",
              group: .his,
              aliases: ["isra", "miraj", "mi'raj", "night journey", "ascension", "aqsa", "jerusalem",
                        "buraq", "heavens", "abu bakr", "siddiq", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("In one night he was taken from the sacred mosque in Makkah to al-Masjid al-Aqsa in Jerusalem, and from there raised through the heavens. The Quran opens the surah named after it by glorifying the One who did it, which is the whole framing: the journey is Allah's act, not the Prophet's power."),
                      .quran("17:1"),
                  ]),
                  SignSection("WHAT HE BROUGHT BACK", [
                      .text("He came back with the five daily prayers, which is the reason the night matters to every Muslim after him: the one obligation not delivered by an angel to the earth but given to him above it."),
                      .text("He also came back with a claim the Quraysh could test. They asked him to describe a city he had never travelled to, and he described it. He said afterwards how he was able to:"),
                      .hadith("bukhari:4710", cite: "Saheeh al-Bukhaari 4710", arabic: 35...52, english: 4...44),
                  ]),
                  SignSection("WHY THE TEST MATTERS", [
                      .text("This is the one sign he was made to defend in public, on the spot, to people who wanted him discredited. A liar says as little as possible; he answered a demand for verifiable detail about a place he had no way of having seen. When it was put to Abu Bakr he said that if the Prophet said it then it is true, and he was called as-Siddeeq, the one who affirms (al-Haakim, al-Mustadrak, from Aa’ishah; graded saheeh by al-Albaani in as-Silsilah as-Saheehah)."),
                  ]),
              ]),
        .init(id: "chest-opened", title: "The opening of his chest",
              summary: "Jibreel opened his chest and washed his heart while he played as a boy; Anas later saw the mark of the stitching.",
              group: .his,
              aliases: ["shaqq al-sadr", "sharh al-sadr", "jibril", "gabriel", "zamzam", "heart", "golden basin", "banu sad", "halimah", "wet nurse", "foster mother", "childhood", "stitches", "scar", "anas ibn malik", "al-sharh", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("He spent his early childhood in the care of a wet nurse, as Makkan families then did with their infants. Anas ibn Maalik reports that Jibreel came to him while he was playing with the other boys, took hold of him, laid him down and split open his chest. He took out the heart, drew a clot of blood from it, and said:"),
                      .hadith("muslim:162c", cite: "Saheeh Muslim 162c", arabic: 43...91, english: 0...76),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The other boys ran to his nurse saying he had been killed; they found him alive, his colour changed. The last sentence is Anas's own testimony. He served the Prophet in Madinah for ten years, so the mark he describes was still visible decades after the event."),
                  ]),
                  SignSection("A SECOND TIME", [
                      .text("He described the same washing again on the night of the ascent, before he was taken up:"),
                      .hadith("bukhari:349", cite: "Saheeh al-Bukhaari 349", arabic: 22...56, english: 0...49),
                      .text("Surah ash-Sharh opens with a question put to him:"),
                      .quran("94:1"),
                      .text("Most commentators read it as the opening of his heart to guidance and faith; some held that the physical opening is part of what it means."),
                  ]),
              ]),
        .init(id: "angels-badr", title: "The angels at Badr",
              summary: "Outnumbered three to one, he prayed for the help he was promised; a Companion heard an angel's whip above him.",
              group: .his,
              aliases: ["badr", "malaikah", "angels", "jibril", "gabriel", "haizum", "hayzum", "whip", "third heaven", "ibn abbas", "umar", "abu bakr", "ansar", "ramadan", "2 ah", "624", "quraysh", "anfal", "reinforcement", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("At Badr, in Ramadan 2 AH (624 CE), a little over three hundred Muslims faced a Quraysh army of about a thousand. Umar, who was there, describes what the Prophet did when he saw the two armies:"),
                      .hadith("muslim:1763", cite: "Saheeh Muslim 1763", arabic: 85...134, english: 38...118),
                      .text("Abu Bakr put the mantle back on his shoulders and told him his Lord would keep His promise. The answer came as revelation:"),
                      .quran("8:9"),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("On the day itself he named one of them:"),
                      .hadith("bukhari:3995", cite: "Saheeh al-Bukhaari 3995", arabic: 20...38, english: 0...27),
                      .text("And one of the Ansaar, chasing an enemy fighter, heard another. Ibn Abbaas reported it:"),
                      .hadith("muslim:1763", cite: "Saheeh Muslim 1763", arabic: 187...229, english: 223...307),
                      .text("Haizoom, the commentators explain, was the name of the angel's horse. The man took what he had seen to the Prophet, who said:"),
                      .hadith("muslim:1763", cite: "Saheeh Muslim 1763", arabic: 241...248, english: 323...337),
                  ]),
                  SignSection("WHAT THEY WERE FOR", [
                      .text("The next ayah is careful about the angels' purpose: Allah made them good tidings and reassurance for the believers, and victory comes from Allah alone. The Muslims killed seventy of the enemy that day and captured seventy."),
                  ]),
              ]),
        .init(id: "hunayn-dust", title: "A handful of dust at Hunayn",
              summary: "With his army in flight he threw a handful of dust at the enemy; it filled every man's eyes, and they ran.",
              group: .his,
              aliases: ["hunayn", "hunain", "hawazin", "thaqif", "salamah ibn al-akwa", "al-abbas", "abbas", "pebbles", "white mule", "shahat al-wujuh", "8 ah", "630", "anfal", "you did not throw", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Hunayn was fought in 8 AH (630 CE), weeks after the opening of Makkah, against the tribe of Hawaazin. It was the largest army the Muslims had yet fielded, and it gave way at the first clash. The Quran recalls that day:"),
                      .quran("9:25-26"),
                      .text("He held his ground on his white mule. Salamah ibn al-Akwa', falling back past him, saw him get down, pick up a handful of dust, throw it at their faces and say, 'May these faces be disfigured.' Salamah goes on:"),
                      .hadith("muslim:1777", cite: "Saheeh Muslim 1777", arabic: 140...152, english: 209...231),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("His uncle al-Abbaas was holding the mule's bridle, and describes the same moment from beside him:"),
                      .hadith("muslim:1775a", cite: "Saheeh Muslim 1775a", arabic: 224...270, english: 288...370),
                      .text("Al-Abbaas remembers pebbles and Salamah dust, as two men watching from different places might. Both put the turn of the battle at that throw."),
                  ]),
                  SignSection("THE QURAAN'S WORDS FOR IT", [
                      .text("The Quran does not name the handful at Hunayn. Surah al-Anfaal, revealed about Badr, where most commentators say he threw a similar one, says whose throw such a throw is:"),
                      .quran("8:17"),
                  ]),
              ]),
    ]

    // MARK: Food and water multiplied

    static let provisionEntries: [Entry] = [
        .init(id: "water", title: "Water from between his fingers",
              summary: "At al-Hudaybiyah a whole company drank and made wudu from a small pot.",
              group: .provision,
              aliases: ["hudaybiyah", "jabir", "thirst", "wudu", "vessel", "fifteen hundred",
                        "provision", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("On the day of al-Hudaybiyah the people ran out of water. He put his hand into a small vessel:"),
                      .hadith("bukhari:3576", cite: "Saheeh al-Bukhaari 3576", arabic: 60...85, english: 68...119),
                  ]),
                  SignSection("HOW MANY SAW IT", [
                      .text("This is not a sign reported by one man in private. Jaabir names the crowd that drank from it, fifteen hundred people, and the same thing is reported on other days by Anas and Ibn Mas‘ood."),
                  ]),
              ]),
        .init(id: "hudaybiyah-well", title: "The dry well at al-Hudaybiyah",
              summary: "Fourteen hundred men had drained the well to the last drop; he rinsed his mouth into it, and it watered them all.",
              group: .provision,
              aliases: ["hudaybiyah", "hudaibiya", "well", "bara ibn azib", "salamah ibn al-akwa", "miswar ibn makhramah", "arrow", "quiver", "fourteen hundred", "1400", "treaty", "umrah", "camels", "thirst"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("In 6 AH (628 CE) he set out for Makkah to perform ‘umrah and camped at al-Hudaybiyah, just short of the city, where the Quraysh barred the way. The camp had one well, and fourteen hundred men soon emptied it. Al-Baraa’ ibn Aazib was there:"),
                      .hadith("bukhari:3577", cite: "Saheeh al-Bukhaari 3577", arabic: 17...58, english: 0...85),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Everyone in the camp drank from it, and it is not one man's story. Salamah ibn al-Akwa', another of the fourteen hundred, describes the same well:"),
                      .hadith("muslim:1807a", cite: "Saheeh Muslim 1807a", arabic: 59...101, english: 0...70),
                      .text("The long account of the treaty, which al-Bukhaari gives from al-Miswar ibn Makhramah and Marwan, adds one more detail:"),
                      .hadith("bukhari:2731", cite: "Saheeh al-Bukhaari 2731", arabic: 169...186, english: 272...311),
                      .text("The reports differ on what he did (rinsed his mouth into it, spat, prayed, had an arrow placed in it) and agree on what followed. It is a separate moment of the same campaign from the water that flowed from his fingers into a small pot."),
                  ]),
              ]),
        .init(id: "water-journeys", title: "Water from his fingers, again",
              summary: "It happened more than once: Anas saw it in Madinah with about three hundred people, and Ibn Mas‘ood on a journey.",
              group: .provision,
              aliases: ["anas ibn malik", "ibn masud", "abdullah ibn masud", "zawra", "madinah", "wudu", "ablution", "three hundred", "eighty", "seventy", "stone basin", "qatadah", "tawatur", "mutawatir", "nawawi"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("The water at al-Hudaybiyah was not the only time. Anas ibn Maalik, who served the Prophet for ten years, saw it in Madinah itself, at az-Zawraa’, a spot by the market near the mosque. The man who heard it from him asked the question that matters:"),
                      .hadith("bukhari:3572", cite: "Saheeh al-Bukhaari 3572", arabic: 20...51, english: 0...52),
                      .text("Anas describes other days too: once with a stone basin so small that the Prophet had to draw his fingers together to fit his hand in it, when eighty men made wudu from it; once on a journey, with seventy or so."),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Anas counted the people himself, and the details change from one telling to the next, so the commentators read them as separate occasions. Abdullah ibn Mas‘ood reports it from a journey of his own:"),
                      .hadith("bukhari:3579", cite: "Saheeh al-Bukhaari 3579", arabic: 20...65, english: 0...68),
                      .text("He goes on to say that he saw the water flowing from between the Prophet's fingers. Jaabir reports it at al-Hudaybiyah with fifteen hundred. An-Nawawi, in his commentary on Saheeh Muslim, wrote that these signs of water and food came on many occasions and in different circumstances, and that taken together the reports reach the level of mass transmission (tawaatur)."),
                  ]),
              ]),
        .init(id: "water-skins", title: "The woman with two water-skins",
              summary: "Thirsty travellers drank and filled every skin from a stranger's two, and hers went back fuller than they came.",
              group: .provision,
              aliases: ["imran ibn husayn", "waterskins", "water skins", "mazadah", "journey", "bedouin", "sabi", "magician", "her tribe", "her people", "forty", "thirst", "camel"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("On a journey the travellers overslept past sunrise, and by the time they moved on they were badly thirsty. Men sent ahead to look for water found a woman riding between two water-skins, who told them her people's water was a day and a night's travel away. They brought her to the Prophet. Imraan ibn Husayn was among them:"),
                      .hadith("bukhari:3571", cite: "Saheeh al-Bukhaari 3571", arabic: 185...210, english: 283...347),
                      .text("In another telling, from the same Companion, the call went out to the whole company to drink and water their animals. Imraan swears by Allah that when her skins were handed back they looked fuller than when they began, and the Prophet told her they had taken nothing of her water: it was Allah who had given them to drink (Saheeh al-Bukhaari 344)."),
                      .hadith("bukhari:344", cite: "Saheeh al-Bukhaari 344", arabic: 326...393, english: 563...680),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The woman stood and watched it done with her own water, and she was not a Muslim. What she told her people is the best witness in the story:"),
                      .hadith("bukhari:3571", cite: "Saheeh al-Bukhaari 3571", arabic: 218...242, english: 358...411),
                      .text("Imraan ibn Husayn reports it, and it is in both al-Bukhaari and Muslim."),
                  ]),
              ]),
        .init(id: "trench-feast", title: "A thousand fed at Jaabir's house",
              summary: "During the siege of the Trench, a small goat and a sa' of barley fed the whole army, and the pot was still full.",
              group: .provision,
              aliases: ["trench", "khandaq", "ahzab", "confederates", "jabir ibn abdullah", "barley", "goat", "banquet", "feast", "hunger", "muhajirun", "ansar", "one thousand", "bread", "pot"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("In 5 AH (627 CE) the Muslims dug a trench across the open northern side of Madinah before the army of the allied tribes arrived, and they dug it hungry. Jaabir ibn Abdullah says they had gone three days without tasting food, and he saw a stone tied over the Prophet's belly. He went home, found a small goat and a sa' of barley (four double handfuls), and quietly asked the Prophet to come with one or two others."),
                      .hadith("bukhari:4102", cite: "Saheeh al-Bukhaari 4102", arabic: 114...133, english: 173...193),
                      .text("At the house the Prophet spat into the dough and into the pot and asked Allah to bless them, and told Jaabir's wife to keep baking and keep ladling without taking the pot off the fire."),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Everyone digging the trench came, the Emigrants and the Ansaar together. Jaabir puts them at a thousand, and he swears to what happened:"),
                      .hadith("muslim:2039", cite: "Saheeh Muslim 2039", arabic: 223...244, english: 313...375),
                      .text("A meal meant for two or three men fed an army, in front of that army. A second telling in al-Bukhaari, through a different student of Jaabir, ends the same way: they all ate their fill, and food was left over."),
                  ]),
              ]),
        .init(id: "tabuk-spring", title: "The spring at Tabook",
              summary: "A trickle as thin as a sandal strap gushed for the army, and he told Mu‘aadh the place would one day be full of gardens.",
              group: .provision,
              aliases: ["tabuk", "muadh ibn jabal", "ayn tabuk", "fountain", "trickle", "gardens", "orchards", "farms", "agriculture", "saudi arabia", "prophecy", "expedition", "nawawi", "amwas"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("On the march to Tabook in 9 AH (630 CE), he told the army they would reach the spring of Tabook the next morning and that no one was to touch its water before he came. They found it a thread of water, as thin as a sandal strap. Mu‘aadh ibn Jabal was there:"),
                      .hadith("muslim:706c", cite: "Saheeh Muslim 706c", arabic: 156...218, english: 98...172),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The people who drank were the whole expedition, the largest army he ever led; the early biographers put it at about thirty thousand. Those who reached the spring first had seen how little it gave. The account is Mu‘aadh's own, in Saheeh Muslim."),
                  ]),
                  SignSection("THE GARDENS", [
                      .text("The last sentence is a prophecy, and it was not Mu‘aadh's to see: he died in the plague of Amwaas in 18 AH. An-Nawawi explained 'gardens' as orchards and settled, cultivated land, and counted the saying among the Prophet's miracles."),
                      .text("The Tabook region is now one of Saudi Arabia's main farming areas, with orchards and irrigated fields fed from deep wells. The hadith gives no date and does not say how far 'here' reaches, so the fair claim is a modest one: many Muslims see the words fulfilled in the green land around Tabook today."),
                  ]),
              ]),
        .init(id: "expedition-provisions", title: "Provisions pooled on a leather mat",
              summary: "Scraps of food piled on a mat fed fourteen hundred and filled their bags; at Tabook every vessel in the camp was filled.",
              group: .provision,
              aliases: ["salamah ibn al-akwa", "abu hurayrah", "abu said al-khudri", "tabuk", "umar", "rations", "leather mat", "fourteen hundred", "1400", "vessels", "containers", "shahadah", "testimony", "wudu", "camels"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("On one expedition food ran so short that the men were ready to slaughter their riding camels. The Prophet had them bring whatever each had left and pile it together. Salamah ibn al-Akwa' was there:"),
                      .hadith("muslim:1729", cite: "Saheeh Muslim 1729", arabic: 54...81, english: 37...117),
                      .text("Then he asked for water for wudu. A man brought a skin with a little water in it and emptied it into a bowl."),
                      .hadith("muslim:1729", cite: "Saheeh Muslim 1729", arabic: 105...134, english: 148...187),
                  ]),
                  SignSection("AGAIN AT TABOOK", [
                      .text("On the march to Tabook the army went hungry again, and it was Umar who asked him to gather what was left and pray over it. One man brought a handful of grain, another a handful of dates, another a crust of bread. He prayed for blessing and told them to fill their containers, and not a vessel in the camp was left empty. Then he said:"),
                      .hadith("muslim:27b", cite: "Saheeh Muslim 27b", arabic: 185...212, english: 266...311),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Salamah was one of the fourteen hundred who ate and made wudu. The Tabook account is from Abu Hurayrah or Abu Sa‘eed al-Khudri (a later narrator was unsure which of the two told it), and a second chain in Muslim has it from Abu Hurayrah alone. What the Prophet said at the end shows how he read it: as a sign of his message, given in front of an army."),
                  ]),
              ]),
        .init(id: "abu-talhah-bread", title: "A few loaves in Umm Sulaym's veil",
              summary: "Barley loaves sent to one hungry man fed seventy or eighty, ten at a time, in the house of Abu Talhah.",
              group: .provision,
              aliases: ["abu talhah", "umm sulaym", "anas ibn malik", "barley", "loaves", "bread", "butter", "groups of ten", "seventy", "eighty", "hunger", "veil", "neighbours"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Talhah heard weakness in the Prophet's voice and knew it was hunger. His wife Umm Sulaym wrapped a few barley loaves in part of her veil and sent her son Anas with them to the mosque. The Prophet asked whether Abu Talhah had sent him with food, then told everyone sitting with him to get up. Anas ran ahead to tell Abu Talhah:"),
                      .hadith("bukhari:3578", cite: "Saheeh al-Bukhaari 3578", arabic: 127...149, english: 151...180),
                      .text("The Prophet had the bread broken into pieces, Umm Sulaym squeezed a skin of butter over it, and he said over it what Allah willed. Then he asked for ten men to be let in."),
                      .hadith("bukhari:3578", cite: "Saheeh al-Bukhaari 3578", arabic: 223...272, english: 255...326),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Anas carried the bread himself and watched the men go in ten at a time. He told the story to several of his students, and al-Bukhaari and Muslim have it through many chains. In one of them the Prophet and the household ate afterwards, and there was still enough to send to the neighbours. Seventy or eighty men had eaten from bread sent for one."),
                  ]),
              ]),
        .init(id: "zaynab-feast", title: "The wedding feast of Zaynab",
              summary: "One pot of hays from Umm Sulaym fed about three hundred guests, ten at a time, and Anas could not tell if it had shrunk.",
              group: .provision,
              aliases: ["zaynab bint jahsh", "zainab", "walimah", "wedding", "hays", "hais", "umm sulaym", "anas ibn malik", "three hundred", "groups of ten", "hijab", "dates", "butter", "pot"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("When the Prophet married Zaynab bint Jahsh, Umm Sulaym made hays, a dish of dates, butter and dried curd, and sent it with her son Anas in a small pot as a modest gift. The Prophet told Anas to set it down and go and invite certain men by name, and anyone else he met."),
                      .hadith("muslim:1428g", cite: "Saheeh Muslim 1428g", arabic: 124...133, english: 135...158),
                      .text("They filled the courtyard and the rooms. He told them to sit in circles of ten, each eating from what was nearest him."),
                      .hadith("muslim:1428g", cite: "Saheeh Muslim 1428g", arabic: 173...206, english: 207...283),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Anas carried the pot in and carried it out, and he was the one sent round to fill the house. He gives the number when asked, and he fixes the day: it was the wedding after which the verse telling guests not to linger in the Prophet's house came down (Quran 33:53). Muslim reports it through several chains, and al-Bukhaari cites it too."),
                      .quran("33:53"),
                  ]),
              ]),
        .init(id: "milk-bowl", title: "One bowl of milk for the people of the Suffah",
              summary: "One bowl passed round the poor of the mosque until all were full; then Abu Hurayrah drank, and the Prophet last.",
              group: .provision,
              aliases: ["abu hurayrah", "aba hirr", "suffah", "ahl al-suffah", "people of the bench", "milk", "bowl", "cup", "hunger", "poor", "guests of islam", "mosque"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Hurayrah swore that hunger used to drive him to press his belly to the ground. One day the Prophet saw it in his face, smiled, and took him home, where someone had sent a bowl of milk as a gift. He told Abu Hurayrah to call the people of the Suffah: the poor who lived at the mosque with no family or wealth, whom Abu Hurayrah calls the guests of Islam. He had hoped for a drink himself, and wondered what would be left."),
                      .hadith("bukhari:6452", cite: "Saheeh al-Bukhaari 6452", arabic: 264...291, english: 443...506),
                      .text("When the last of them had drunk, the Prophet took the bowl, looked at him and smiled."),
                      .hadith("bukhari:6452", cite: "Saheeh al-Bukhaari 6452", arabic: 322...339, english: 548...576),
                      .text("He kept telling him to drink until Abu Hurayrah swore he had no room left. Then the Prophet praised Allah, said His name over it, and drank what remained."),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The narration does not count the people of the Suffah that day, but they were many: Abu Hurayrah says elsewhere that he saw seventy of them at once. He opens the story with an oath by Allah, and he was the man it happened to."),
                  ]),
              ]),
        .init(id: "abd-rahman-sheep", title: "One sheep for a hundred and thirty",
              summary: "He gave each of 130 men a piece of one sheep's liver; all ate their fill, and two bowls were still full.",
              group: .provision,
              aliases: ["abd al-rahman ibn abi bakr", "abdur rahman", "abu bakr", "sheep", "liver", "130", "bowls", "wheat", "shepherd", "idolater", "camel", "meat"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abd ar-Rahman, the son of Abu Bakr, was one of a hundred and thirty men with the Prophet when he asked whether anyone had food. One man had about a sa' of wheat, and it was made into dough. A tall man, an idolater, came by driving sheep, and the Prophet bought one from him. Then:"),
                      .hadith("bukhari:2618", cite: "Saheeh al-Bukhaari 2618", arabic: 98...140, english: 90...163),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Abd ar-Rahman was one of those who ate, and he swears to it. One sheep's liver was divided a hundred and thirty ways, with shares kept back for the men who were away, and one sheep's meat, served in two bowls, left all of them full with food still over. Muslim reports it through the same line of narrators."),
                  ]),
              ]),
        .init(id: "jabir-debt", title: "Jaabir's dates and his father's debts",
              summary: "The creditors said the harvest could not cover the debt; he blessed the heaps, all were paid, and they looked untouched.",
              group: .provision,
              aliases: ["jabir ibn abdullah", "abdullah ibn amr ibn haram", "uhud", "debt", "creditors", "dates", "heaps", "ajwa", "wasq", "orchard", "abu bakr", "umar", "sisters", "harvest"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Jaabir's father, Abdullah ibn Amr ibn Haraam, was killed at Uhud in 3 AH, leaving daughters and heavy debts. Jaabir offered the creditors the whole date harvest, and they refused: it would not come near what they were owed, and they would not accept a reduction when the Prophet asked them for one. At harvest time the Prophet told Jaabir to pile each kind of date separately and call him."),
                      .hadith("bukhari:4053", cite: "Saheeh al-Bukhaari 4053", arabic: 78...115, english: 90...164),
                      .text("Jaabir had hoped only to clear the debt, even if nothing came home with him:"),
                      .hadith("bukhari:4053", cite: "Saheeh al-Bukhaari 4053", arabic: 116...149, english: 165...223),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The creditors measured out their own payment from dates they had already judged too few. Abu Bakr and Umar came with the Prophet, and when Jaabir told them what had happened, they said they had known it would once they saw what he did. Jaabir told the story to several of his students and al-Bukhaari gives it through more than one of them; in one telling, thirteen wasqs were left over after every debt was paid."),
                  ]),
              ]),
        .init(id: "abu-hurayrah-dates", title: "Abu Hurayrah's bag of dates",
              summary: "A handful of dates he prayed over fed Abu Hurayrah and others for over twenty years, until the day Uthmaan was killed.",
              group: .provision,
              aliases: ["abu hurayrah", "mizwad", "provision bag", "dates", "tamr", "wasq", "uthman", "barakah", "blessing", "handful"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Hurayrah brought the Prophet a few dates and asked him to pray for blessing in them. He gathered them in his hand, prayed, and told him to keep them in his provision bag, to take from it by putting his hand in, and never to pour it all out."),
                      .hadith("tirmidhi:3839", cite: "Jaami‘ at-Tirmidhi 3839", arabic: 71...97, english: 78...124),
                  ]),
                  SignSection("HOW IT IS REPORTED", [
                      .text("This sign had no crowd. Its witnesses were the people Abu Hurayrah fed from the bag over more than twenty years, since Uthmaan was killed in 35 AH. At-Tirmidhi graded it hasan and noted that it is reported from Abu Hurayrah by other routes as well, and later graders, al-Albaani among them, rate its chain hasan. It is a quieter sign than the others here, told as he told it."),
                  ]),
              ]),
    ]

    // MARK: Creation answered him

    static let creationEntries: [Entry] = [
        .init(id: "trunk", title: "The palm trunk that wept",
              summary: "The stump he used to lean on cried aloud when he moved to a pulpit.",
              group: .creation,
              aliases: ["minbar", "pulpit", "palm", "stump", "wept", "crying", "hasan al-basri",
                        "friday", "khutbah", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("He used to lean on a palm trunk while giving the Friday sermon. When a pulpit was built for him and he stepped onto it instead:"),
                      .hadith("bukhari:3584", cite: "Saheeh al-Bukhaari 3584", arabic: 55...93, english: 37...102),
                  ]),
                  SignSection("WHO HEARD IT", [
                      .text("Those in the mosque heard it, and it is reported by several Companions, among them Jaabir, Ibn Umar and Anas. Al-Hasan al-Basri used to weep at this hadith and say: a piece of wood yearns for the Messenger of Allah, and you have more right to yearn for him than it did (Ibn Katheer, al-Bidaayah wa an-Nihaayah, from al-Baghawi's narration)."),
                  ]),
              ]),
        .init(id: "stone-greeting", title: "The stone that greeted him",
              summary: "A stone in Makkah used to greet him before he was sent, and years later he said he still knew it.",
              group: .creation,
              aliases: ["rock", "hajar", "salam", "salutation", "mecca", "jabir ibn samurah", "before prophethood",
                        "bi'thah", "inanimate", "muhammad"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("Jaabir ibn Samurah heard him speak of the years in Makkah before revelation came to him:"),
                      .hadith("muslim:2277", cite: "Saheeh Muslim 2277", arabic: 33...45, english: 0...23),
                  ]),
                  SignSection("A NOTE", [
                      .text("He does not say which stone it was, and he makes nothing more of it: no crowd, no challenge, no lesson attached. It is a man recalling something from his life before prophethood and saying he would still know it."),
                      .text("The timing is what stands out. The greeting came before he was sent, when to everyone around him he was simply a trusted man of Quraysh. It belongs with the palm trunk in Madinah that wept for him: lifeless things that recognised him."),
                  ]),
              ]),
        .init(id: "food-tasbih", title: "The food that glorified Allah",
              summary: "Ibn Mas‘ood: in his company we heard the food glorifying Allah while it was being eaten.",
              group: .creation,
              aliases: ["tasbih", "subhanallah", "ibn masud", "abdullah ibn masud", "meal", "eating", "glorification",
                        "praise", "water", "fingers", "barakah", "17:44", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abdullah ibn Mas‘ood, one of the earliest Muslims, describes a journey on which the water ran low. The Prophet put his hand into a vessel holding a little water and called the people to the blessed water. Then Ibn Mas‘ood adds a second thing, almost in passing:"),
                      .hadith("bukhari:3579", cite: "Saheeh al-Bukhaari 3579", arabic: 66...85, english: 69...97),
                  ]),
                  SignSection("WHAT IT MEANS", [
                      .text("The Quran says that everything in creation glorifies Allah, though people do not understand how. Ibn Mas‘ood's point is that in the Prophet's company they heard it, and more than once: from the food as it was eaten."),
                      .quran("17:44"),
                      .text("He opened the same narration by correcting the people he was speaking to, who had grown used to thinking of signs as warnings:"),
                      .hadith("bukhari:3579", cite: "Saheeh al-Bukhaari 3579", arabic: 20...26, english: 0...16),
                  ]),
              ]),
        .init(id: "trees-moved", title: "Two trees that moved at his word",
              summary: "In an open valley he led two trees together by their branches to screen him; afterwards they stood apart again.",
              group: .creation,
              aliases: ["jabir ibn abdullah", "jabir", "branch", "twig", "expedition", "privacy", "camel", "nose-string",
                        "obey", "shade", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("On an expedition the army camped in a wide valley, and Jaabir ibn Abdullah followed the Prophet with a vessel of water when he went to relieve himself. There was nothing to screen him but two trees at the far edge of the valley. He took hold of a branch of one of them and said:"),
                      .hadith("muslim:3006", cite: "Saheeh Muslim 3006", arabic: 1007...1056, english: 1740...1826),
                  ]),
                  SignSection("WHAT JAABIR SAW", [
                      .text("Jaabir moved off and sat by himself, afraid the Prophet would sense him close by and go further away. When he next looked up:"),
                      .hadith("muslim:3006", cite: "Saheeh Muslim 3006", arabic: 1085...1106, english: 1862...1889),
                      .text("He tells it inside a long account of that expedition, one event among many. It was not staged for an audience: Jaabir was the only one with him, and it answered the plain need of a man in an open valley."),
                  ]),
              ]),
        .init(id: "camel-complaint", title: "The camel that complained to him",
              summary: "A camel wept when it saw him, and he told its owner it had complained of being starved and overworked.",
              group: .creation,
              aliases: ["abdullah ibn jafar", "ansar", "ansari", "garden", "orchard", "animals", "animal welfare", "hunger",
                        "beast", "tears", "mercy", "taqwa", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abdullah ibn Ja‘far, the son of his cousin Ja‘far, was riding behind him that day:"),
                      .hadith("abudawud:2549", cite: "Sunan Abi Daawood 2549", arabic: 63...88, english: 55...102),
                      .text("He asked whose camel it was, and a young man of the Ansaar came forward to say it was his."),
                      .hadith("abudawud:2549", cite: "Sunan Abi Daawood 2549", arabic: 112...131, english: 132...164),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign is not left as a wonder; it is put to work at once as a rule. The animal is something Allah placed in the man's keeping, and its hunger and exhaustion are a matter of fearing Allah. The same concern runs through his teaching elsewhere: he told of a woman who entered the Fire over a cat she shut away and starved (Saheeh al-Bukhaari 3482, Saheeh Muslim 2242)."),
                      .hadith("bukhari:3482", cite: "Saheeh al-Bukhaari 3482, Saheeh Muslim 2242a", arabic: 33...56, english: 4...51),
                  ]),
              ]),
        .init(id: "apostate-grave", title: "The grave that would not keep him",
              summary: "A scribe who left Islam said Muhammad knew only what he wrote for him; the earth threw his body out three times.",
              group: .creation,
              aliases: ["apostate", "apostasy", "riddah", "christian", "scribe", "writer", "banu najjar", "burial", "corpse",
                        "anas ibn malik", "revelation", "mockery"],
              sections: [
                  SignSection("WHAT HE CLAIMED", [
                      .text("Anas ibn Maalik describes a man who used to write for the Prophet:"),
                      .hadith("bukhari:3617", cite: "Saheeh al-Bukhaari 3617", arabic: 17...42, english: 0...41),
                      .text("Muslim's version, also from Anas, adds that he was of Banu an-Najjaar, and that the People of the Book he joined made much of him as the man who used to write for Muhammad."),
                  ]),
                  SignSection("WHAT HAPPENED", [
                      .text("He died, and they buried him. In the morning his body was lying on the surface. Their first explanation was the natural one: Muhammad's companions had dug him up because he had left them. So they buried him again, deeper, and found the same thing. The third time:"),
                      .hadith("bukhari:3617", cite: "Saheeh al-Bukhaari 3617", arabic: 81...98, english: 153...201),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("The people who concluded that no human hand had done it were his new community, the ones with every reason to blame the Muslims, and they tested that explanation twice before giving it up. His boast was that the revelation came from his pen. The answer did not come as an argument; it came in a form his own side could inspect on three separate mornings."),
                  ]),
              ]),
    ]

    // MARK: Prayers answered

    static let prayerEntries: [Entry] = [
        .init(id: "rain-prayer", title: "Rain from a cloudless sky",
              summary: "Asked for rain in a Friday sermon, he prayed under a clear sky, and it rained before he left the pulpit.",
              group: .prayers,
              aliases: ["istisqa", "drought", "bedouin", "friday", "khutbah", "sermon", "minbar", "anas ibn malik", "madinah", "clouds", "sal", "qanat", "around us not on us", "hawalayna"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("A drought had struck Madinah. During the Friday sermon a Bedouin stood up, told him that their animals were dying and their families were hungry, and asked him to pray for rain. Anas ibn Maalik was in the mosque."),
                      .hadith("bukhari:933", cite: "Saheeh al-Bukhaari 933", arabic: 58...101, english: 51...125),
                  ]),
                  SignSection("THE NEXT FRIDAY", [
                      .text("A week later, during the next Friday sermon, a man stood up, the same Bedouin or another, and said the houses were falling down and the animals drowning. He prayed again, and this time he pointed."),
                      .hadith("bukhari:933", cite: "Saheeh al-Bukhaari 933", arabic: 121...155, english: 157...221),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Both prayers were made from the pulpit before the whole Friday congregation, and both were answered while it was still gathered: the first before he came down, the second as he pointed. In another of his narrations Anas adds that no house stood between them and the hill of Sal', so nothing blocked their view of that part of the sky, and the cloud rose from behind that hill."),
                      .text("The rain did not simply stop, either. The town cleared while the valley of Qanaat ran for a month, which is what 'around us and not on us' had asked for."),
                  ]),
              ]),
        .init(id: "quraysh-famine", title: "Years like Yoosuf's, and then rain",
              summary: "He prayed for a famine on Quraysh when they turned away; when Abu Sufyaan begged for rain, he prayed and it rained.",
              group: .prayers,
              aliases: ["quraysh", "abu sufyan", "famine", "drought", "yusuf", "joseph", "seven years", "mudar", "smoke", "dukhan", "surah ad-dukhan", "ibn masud", "istisqa", "kinship"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("When Quraysh turned their backs on his call, he prayed against them in the terms of the lean years of Yoosuf's Egypt. Abdullah ibn Mas‘ood described what followed:"),
                      .hadith("bukhari:1007", cite: "Saheeh al-Bukhaari 1007", arabic: 27...56, english: 7...89),
                      .text("Then one of the leading men of the people he had prayed against came to him for help:"),
                      .hadith("bukhari:1007", cite: "Saheeh al-Bukhaari 1007", arabic: 57...75, english: 90...132),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("He was surprised by the request, made by an enemy on behalf of Mudar, the tribal family Quraysh belonged to, and he granted it:"),
                      .hadith("bukhari:4821", cite: "Saheeh al-Bukhaari 4821", arabic: 85...92, english: 133...165),
                      .text("Both prayers were answered on a whole people, in the open, and the second was asked for by his opponents themselves."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn Mas‘ood read the verses on the smoke in Surah ad-Dukhaan (44:10-16) as describing this famine, and the great seizure they threaten as Badr. The smoke is also counted among the ten great signs before the Hour in Saheeh Muslim, and many scholars hold that those verses refer to that sign, still to come. Both readings are old; the answered prayers stand on either."),
                      .quran("44:10-11, 16"),
                  ]),
              ]),
        .init(id: "kaaba-seven", title: "The men he named at the Ka‘bah",
              summary: "Mocked in prostration at the Ka‘bah, he prayed against Quraysh's chiefs by name; they died at Badr or as its captives.",
              group: .prayers,
              aliases: ["abu jahl", "utbah ibn rabiah", "shaybah ibn rabiah", "walid ibn utbah", "umayyah ibn khalaf", "uqbah ibn abi muayt", "fatimah", "ibn masud", "badr", "qalib", "camel", "prostration", "sujud", "makkah", "quraysh"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("He was praying at the Ka‘bah while Abu Jahl sat nearby with his companions. One of them fetched the entrails of a slaughtered camel and laid them across his back as he prostrated, and they fell about laughing. Abdullah ibn Mas‘ood watched, unable to do anything. He stayed in prostration until his daughter Faatimah came and threw it off."),
                      .hadith("bukhari:240", cite: "Saheeh al-Bukhaari 240", arabic: 140...195, english: 154...233),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("Years later, in 2 AH, these men marched with Quraysh to Badr. In another of his narrations Ibn Mas‘ood names four of them, Utbah, Shaybah, al-Waleed and Abu Jahl, and says:"),
                      .hadith("bukhari:3960", cite: "Saheeh al-Bukhaari 3960", arabic: 50...60, english: 29...51),
                      .text("Utbah, Shaybah and al-Waleed fell in the single combat that opened the battle, and Abu Jahl in the fighting after it. Umayyah ibn Khalaf was killed there too, and Uqbah ibn Abi Mu‘ayt was taken captive and put to death on the way back. The prayer was made to their faces, by name, when they held all the power in Makkah; the narration says it weighed on them, because they themselves believed a prayer made in that city was answered."),
                  ]),
              ]),
        .init(id: "umar-islam", title: "Islam strengthened through Umar",
              summary: "He asked Allah to strengthen Islam through Abu Jahl or Umar; one died at Badr an enemy, the other became Muslim.",
              group: .prayers,
              aliases: ["umar ibn al-khattab", "abu jahl", "amr ibn hisham", "conversion", "makkah", "ibn masud", "abdullah ibn masud", "said ibn zayd", "izzah", "honour", "strength", "al-faruq", "quraysh", "ibn umar"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("In Makkah, while the Muslims were few and persecuted, two men of Quraysh stood out for their strength and their hostility: Abu Jahl and Umar ibn al-Khattaab. He named both of them in one prayer:"),
                      .hadith("tirmidhi:3681", cite: "Jaami‘ at-Tirmidhi 3681", arabic: 24...54, english: 0...40),
                      .text("The last sentence is the narrator's comment on which of the two it fell on."),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("Umar had been an enemy with his hands as well as his tongue. Sa‘eed ibn Zayd, who was married to Umar's sister, remembered it:"),
                      .hadith("bukhari:3862", cite: "Saheeh al-Bukhaari 3862", arabic: 23...34, english: 15...33),
                      .text("Then Umar accepted Islam, and the Muslims felt the difference. Abdullah ibn Mas‘ood said:"),
                      .hadith("bukhari:3863", cite: "Saheeh al-Bukhaari 3863", arabic: 27...32, english: 0...7),
                      .text("His word for it, a‘izzah, is from the same root as the prayer's a‘izz: the believers described Umar's Islam in the prayer's own terms. Abu Jahl, the other man named, died at Badr fighting against them."),
                  ]),
                  SignSection("A NOTE", [
                      .text("A version in the same collection adds that Umar came the very next morning and accepted Islam. Its chain is weak, so it is left out here; the sound narration above does not need it."),
                  ]),
              ]),
        .init(id: "abu-hurayrah-mother", title: "Abu Hurayrah's mother",
              summary: "She had just insulted the Prophet; he prayed for her, and her son got home to find her bathing to accept Islam.",
              group: .prayers,
              aliases: ["abu hurairah", "abu huraira", "mother", "guidance", "hidayah", "shahadah", "conversion", "polytheist", "dua", "love of the believers", "tears of joy"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Hurayrah's mother was a polytheist, and he kept inviting her to Islam. One day she answered him with words about the Prophet that he hated to hear, and he came to him in tears."),
                      .hadith("muslim:2491", cite: "Saheeh Muslim 2491", arabic: 52...89, english: 37...96),
                      .text("He went home, pleased with the prayer, and found the door shut."),
                      .hadith("muslim:2491", cite: "Saheeh Muslim 2491", arabic: 108...146, english: 121...191),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The answer came in the time it took him to walk home. She had refused him that same day, and she was already bathing to enter Islam before he could tell her anything."),
                      .text("He went back weeping for joy, and in the same sitting asked for a second prayer: that the believers love him and his mother. He said afterwards that no believer who heard of him or saw him failed to love him."),
                  ]),
              ]),
        .init(id: "ibn-abbas-understanding", title: "Ibn Abbaas and the knowledge of the Book",
              summary: "He prayed that a boy be given understanding of the religion and of the Book; Ibn Abbaas became the Quran's interpreter.",
              group: .prayers,
              aliases: ["abdullah ibn abbas", "ibn abbas", "tarjuman al-quran", "hibr al-ummah", "tafsir", "fiqh", "cousin", "umar", "surah an-nasr", "mujahid", "said ibn jubayr", "ikrimah", "wisdom", "scholar"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abdullah ibn Abbaas was his cousin and still a boy when he did him a small service:"),
                      .hadith("bukhari:143", cite: "Saheeh al-Bukhaari 143", arabic: 22...46, english: 0...38),
                      .text("Ibn Abbaas remembered a second prayer for him as well:"),
                      .hadith("bukhari:75", cite: "Saheeh al-Bukhaari 75", arabic: 16...29, english: 0...18),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("He was still young when the Prophet died, yet in Umar's caliphate he sat in council with the senior Companions, the veterans of Badr. Abd ar-Rahman ibn Awf objected that they had sons his age."),
                      .hadith("bukhari:3627", cite: "Saheeh al-Bukhaari 3627", arabic: 39...72, english: 35...95),
                      .text("He came to be called tarjumaan al-Quran, the interpreter of the Quran, and hibr al-ummah, its scholar. His students, Mujaahid, Sa‘eed ibn Jubayr and Ikrimah among them, carried his explanations into the earliest commentaries; Ikrimah and Sa‘eed are the ones who passed on two of the narrations quoted above. The answer took a lifetime to show, and it showed in public, from Umar's council to the circle of students he taught in Makkah."),
                  ]),
              ]),
        .init(id: "anas-blessing", title: "Wealth and children for Anas",
              summary: "His mother asked the Prophet to pray for her young son; Anas lived to count the wealth and the descendants.",
              group: .prayers,
              aliases: ["anas ibn malik", "umm sulaym", "umm sulaim", "unais", "unays", "servant", "ansar", "basra", "hajjaj", "descendants", "offspring", "garden", "orchard", "barakah", "abu al-aliyah"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Umm Sulaym brought her young son Anas to serve the Prophet, dressed in her own headscarf cut in two, and asked him to pray for the boy. Anas narrates it himself:"),
                      .hadith("muslim:2481b", cite: "Saheeh Muslim 2481b", arabic: 34...70, english: 34...90),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("In another narration he gives the scale of it:"),
                      .hadith("bukhari:1982", cite: "Saheeh al-Bukhaari 1982", arabic: 95...111, english: 120...150),
                      .text("Al-Hajjaaj arrived as governor in 75 AH, and Anas lived on for years after that, so the figure counts only the descendants he had already buried. A man of the next generation remembered his orchard as well:"),
                      .hadith("tirmidhi:3833", cite: "Jaami‘ at-Tirmidhi 3833", arabic: 23...48, english: 12...59),
                      .text("The prayer was specific, and its answer was on view for the rest of a very long life. Anas said elsewhere that of the prayers made for him that day he had seen two fulfilled in this world, and hoped for the third in the next."),
                  ]),
              ]),
        .init(id: "abu-hurayrah-memory", title: "The garment and Abu Hurayrah's memory",
              summary: "He complained that he forgot what he heard; after the Prophet scooped his hands into his garment, he never forgot again.",
              group: .prayers,
              aliases: ["abu hurairah", "abu huraira", "memory", "hifz", "forgetting", "rida", "cloak", "sheet", "hadith", "narrator", "suffah", "ahl al-suffah", "ibn umar", "most hadith"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Abu Hurayrah came to Madinah late, at the time of Khaybar in 7 AH, and was poor: one of the people of the Suffah who lived in the mosque. He told the Prophet his difficulty."),
                      .hadith("bukhari:3648", cite: "Saheeh al-Bukhaari 3648", arabic: 23...50, english: 0...58),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("He had about four years with the Prophet, yet more hadith are narrated from him than from any other Companion. People remarked on it in his lifetime, and he answered them:"),
                      .hadith("bukhari:7354", cite: "Saheeh al-Bukhaari 7354", arabic: 15...55, english: 3...65),
                      .text("Abdullah ibn Umar, who had known the Prophet far longer, once doubted a narration of his until Aa’ishah confirmed it. He also said to him:"),
                      .hadith("tirmidhi:3836", cite: "Jaami‘ at-Tirmidhi 3836", arabic: 20...37, english: 1...33),
                      .text("The answer was not one moment but a lifetime of narrating in front of Companions who had heard the same words and could say so."),
                  ]),
              ]),
        .init(id: "jarir-horse", title: "Jareer, who could not stay on a horse",
              summary: "He struck Jareer's chest and prayed that he be made firm; the man who kept falling never fell from a horse again.",
              group: .prayers,
              aliases: ["jarir ibn abdullah", "jarir al-bajali", "bajilah", "ahmas", "dhul-khalasah", "dhu al-khalasah", "yemeni kaaba", "khatham", "horse", "cavalry", "rider", "idol", "yemen", "firm", "guided"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("He asked Jareer ibn Abdullah to rid them of Dhul-Khalasah, an idol house in Yemen known as the Yemeni Ka‘bah. Jareer was to lead a hundred and fifty horsemen of Ahmas, skilled riders, and he had a weakness he could not hide from them."),
                      .hadith("bukhari:4357", cite: "Saheeh al-Bukhaari 4357", arabic: 44...79, english: 39...102),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .hadith("bukhari:4357", cite: "Saheeh al-Bukhaari 4357", arabic: 95...98, english: 131...140),
                      .text("He sent a man of Ahmas back with the news, and the Prophet blessed the horses and riders of Ahmas five times."),
                      .text("The prayer was answered in the one skill he most needed and could least pretend to: a commander who falls from his horse does it in front of his men. Every ride afterwards was a public test of it, and Jareer, who tells us of the weakness himself, says it never failed him."),
                  ]),
              ]),
        .init(id: "urwah-trade", title: "Urwah, who would have profited on dust",
              summary: "Sent with a dinar to buy one sheep, Urwah came back with a sheep and the dinar; the Prophet prayed for his trade.",
              group: .prayers,
              aliases: ["urwah al-bariqi", "urwa", "urwah ibn al-jad", "urwah ibn abi al-jad", "dinar", "sheep", "trade", "business", "profit", "barakah", "horses", "merchant", "shabib ibn gharqadah"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("He sent Urwah al-Baariqi on a small errand."),
                      .hadith("bukhari:3642", cite: "Saheeh al-Bukhaari 3642", arabic: 17...48, english: 0...70),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("The last line is not about one deal but a working life: whatever Urwah bought afterwards, he sold at a profit. Shabeeb ibn Gharqadah, who transmitted the story from Urwah's own people, also heard Urwah himself speak of the good that lies in horses, and said he had seen seventy horses in his house."),
                      .text("Trade is where luck evens out; a merchant wins some deals and loses others. A man whose deals kept coming out ahead for the rest of his life, so plainly that his people described him this way, is an answer everyone who traded with him could see."),
                  ]),
              ]),
    ]

    // MARK: Healing and protection

    static let protectionEntries: [Entry] = [
        .init(id: "suraqah", title: "Suraaqah and the sinking horse",
              summary: "Chasing the Prophet for Quraysh's reward during the Hijrah, Suraaqah felt his horse sink to its belly, and turned back.",
              group: .protection,
              aliases: ["suraqa", "suraqah ibn malik", "ju'shum", "mudlij", "hijra", "migration", "abu bakr", "bounty",
                        "pursuit", "al-bara ibn azib", "do not grieve", "cave", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("When the Prophet and Abu Bakr left Makkah for Madinah, Quraysh offered a reward for either of them, and riders went out looking. Abu Bakr later told the story to Aazib, with his son al-Baraa’ listening:"),
                      .hadith("bukhari:3615", cite: "Saheeh al-Bukhaari 3615", arabic: 245...273, english: 374...422),
                      .hadith("bukhari:3615", cite: "Saheeh al-Bukhaari 3615", arabic: 283...321, english: 438...510),
                  ]),
                  SignSection("WHO HE WAS", [
                      .text("Suraaqah ibn Maalik ibn Ju‘shum, of the tribe of Mudlij, had ridden out for the reward. The man who ran them down became their cover: he sent the other searchers back."),
                      .text("He later became Muslim. At the Farewell Hajj it was Suraaqah who stood and asked the Prophet whether a ruling on ‘umrah was for that year only or for ever. And the words the Prophet answered with on the road, do not grieve, Allah is with us, are the words the Quran records him saying to Abu Bakr in the cave."),
                  ]),
              ]),
        .init(id: "abu-jahl-trench", title: "Abu Jahl and the trench of fire",
              summary: "He came to tread on the Prophet's neck at prayer, then recoiled, saying he saw a trench of fire, terror and wings.",
              group: .protection,
              aliases: ["amr ibn hisham", "prostration", "sujud", "prayer", "quraysh", "angels", "al-alaq", "surah 96",
                        "abu hurayrah", "lat", "uzza", "threat", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("In Makkah, Abu Jahl asked the Quraysh whether Muhammad pressed his face to the dust in front of them. Told that he did:"),
                      .hadith("muslim:2797", cite: "Saheeh Muslim 2797", arabic: 40...100, english: 1...94),
                  ]),
                  SignSection("WHAT HE SAID ABOUT IT", [
                      .hadith("muslim:2797", cite: "Saheeh Muslim 2797", arabic: 101...116, english: 95...118),
                      .text("The narration adds that the closing verses of Surah al-Alaq came down about this, though the narrator is careful to say he does not know whether that part is from Abu Hurayrah or reached him another way. The verses fit the scene: a man threatening someone at prayer, told to call his council, and a servant told to keep prostrating."),
                      .quran("96:17-19"),
                  ]),
                  SignSection("WHY IT IS STRIKING", [
                      .text("The witness to what Abu Jahl saw is Abu Jahl. He was among the Prophet's most determined enemies in Makkah, he never became Muslim, and he died fighting him at Badr. He made the threat in public, came to carry it out in public, and explained his own retreat to the people who watched it."),
                  ]),
              ]),
        .init(id: "poisoned-sheep", title: "The poisoned sheep at Khaybar",
              summary: "Roasted meat given to him at Khaybar was poisoned; he stopped the meal, and those behind it admitted it and why.",
              group: .protection,
              aliases: ["poison", "khaibar", "jews", "gift", "roasted", "lamb", "foreleg", "shoulder", "bishr ibn al-bara",
                        "abu hurayrah", "anas", "abu al-qasim", "muhammad"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("After Khaybar fell in 7 AH, a roasted sheep was sent to the Prophet as a gift. It had been poisoned. He and some of his Companions began to eat, and the narration in Abu Daawood gives what he said next:"),
                      .hadith("abudawud:4512", cite: "Sunan Abi Daawood 4512", arabic: 72...90, english: 76...107),
                      .text("Bishr ibn al-Baraa’, one of those who had eaten, died of it."),
                  ]),
                  SignSection("WHAT THEY ADMITTED", [
                      .text("He had the Jews who were there gathered, and first tested their honesty. He asked who their father was; they named one man, and he told them it was another, which they conceded. They agreed that if they lied again he would know it. Then:"),
                      .hadith("bukhari:3169", cite: "Saheeh al-Bukhaari 3169", arabic: 154...182, english: 205...254),
                  ]),
                  SignSection("WHY IT IS HARD TO EXPLAIN AWAY", [
                      .text("The poison was real: a man who ate with him died of it. He named it at the meal, and the people who had prepared it confirmed it under questioning, giving their reason in their own words."),
                      .text("He lived about four more years and completed his mission. Anas said the trace of the poison could still be seen in his mouth (Saheeh al-Bukhaari 2617), and in his final illness he said he had felt its pain ever since (Saheeh al-Bukhaari 4428)."),
                      .hadith("bukhari:2617", cite: "Saheeh al-Bukhaari 2617", arabic: 25...57, english: 0...50),
                      .hadith("bukhari:4428", cite: "Saheeh al-Bukhaari 4428", arabic: 13...44, english: 0...43),
                  ]),
              ]),
        .init(id: "sees-behind", title: "He saw them from behind",
              summary: "Leading the prayer, he told the rows behind him that their bowing was not hidden from him: I see you behind my back.",
              group: .protection,
              aliases: ["prayer", "salah", "imam", "rows", "saff", "qiblah", "khushu", "humility", "ruku", "anas ibn malik",
                        "abu hurayrah", "vision", "straighten", "al-nawawi"],
              sections: [
                  SignSection("WHAT HE SAID", [
                      .text("He led the prayer facing the qiblah with the rows behind him, and more than once he told them he could see them as well as if they were in front of him. Abu Hurayrah reports:"),
                      .hadith("bukhari:418", cite: "Saheeh al-Bukhaari 418", arabic: 26...42, english: 4...34),
                  ]),
                  SignSection("HOW THEY TOOK IT", [
                      .text("It was not a remark made once. Anas reports him saying it as he told them to straighten their rows, and what they did about it:"),
                      .hadith("bukhari:725", cite: "Saheeh al-Bukhaari 725", arabic: 20...35, english: 4...39),
                      .text("Muslim records a day when he turned from the prayer to rebuke one man by name for praying carelessly, and said he saw behind him as he saw in front."),
                  ]),
                  SignSection("A NOTE", [
                      .text("An-Nawawi, commenting on it, says the scholars took it at face value: Allah gave him a real perception of those behind him, and neither reason nor revelation rules it out. He used it for the purpose he stated himself, to correct how they prayed."),
                  ]),
              ]),
        .init(id: "healing-touch", title: "A wound and a broken leg",
              summary: "Salamah's wound at Khaybar and Abdullah ibn Ateek's broken leg each healed at his touch and never troubled them again.",
              group: .protection,
              aliases: ["healing", "cure", "salamah ibn al-akwa", "ibn atik", "abu rafi", "saliva", "blew", "nafth",
                        "injury", "ali", "eyes", "muhammad"],
              sections: [
                  SignSection("SALAMAH'S WOUND", [
                      .text("Yazeed ibn Abi Ubayd noticed the scar of a blow on Salamah ibn al-Akwa's leg and asked him about it:"),
                      .hadith("bukhari:4206", cite: "Saheeh al-Bukhaari 4206", arabic: 23...46, english: 21...72),
                  ]),
                  SignSection("A BROKEN LEG", [
                      .text("Abdullah ibn Ateek led a small party of the Ansaar against Abu Raafi', who had worked against the Prophet and helped his enemies. Leaving the fortress at night, he took a stair for the ground, fell, and broke his leg. He bound it with his turban and waited until the death was announced at cock-crow. Then:"),
                      .hadith("bukhari:4039", cite: "Saheeh al-Bukhaari 4039", arabic: 304...324, english: 532...580),
                  ]),
                  SignSection("A NOTE", [
                      .text("Both men tell it themselves, and both speak of a lasting cure, not relief for a day: Salamah still had the scar and had never felt pain from it since. At Khaybar he also spat into Ali's sore eyes and they were cured at once; that is told in the Prophecies library, with the banner he gave him."),
                  ]),
              ]),
    ]

    // MARK: More: the prophets before him (second pass, 2026-10-26)

    static let beforeEntries2: [Entry] = [
        .init(id: "ibrahim-guests", title: "The guests of Ibraaheem, and a son in old age",
              summary: "Angels came to Ibraaheem's table with news of a son for his barren old wife, and an errand to the people of Loot.",
              group: .before,
              aliases: ["abraham", "sarah", "isaac", "ishaq", "jacob", "yaqub", "angels", "roasted calf", "barren", "laugh", "glad tidings", "hospitality"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Messengers came to Ibraaheem as travellers and greeted him with peace. He answered the greeting and went straight to bring a roasted calf. When their hands did not reach for it he grew afraid of them, and they told him who they were and where they were going. His wife was standing by, and the news that followed was for her:"),
                      .quran("11:69-73"),
                      .text("Surat adh-Dhaariyaat tells the same scene from where she stood. She came forward with a cry and struck her face, and the answer she was given is the whole of the matter in a line:"),
                      .quran("51:28-30"),
                  ]),
                  SignSection("HIS OWN QUESTION", [
                      .text("Ibraaheem asked the question too. In Surat al-Hijr the tidings come to him first, and his reply is that of a man who knows his own age and still refuses to despair of his Lord:"),
                      .quran("15:52-56"),
                      .text("The Quran records the promise kept, in one line: Ishaaq was given to him, and Ya‘qoob in addition (21:72). When the fear had left him and the tidings had come, Ibraaheem began to plead with the same guests for the people of Loot (11:74), and was told that the command of his Lord had already gone out (11:76). Loot's city has its own article."),
                      .quran("21:72"),
                      .quran("11:74"),
                      .quran("11:76"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign was a promise about a future no one at that table could bring about: a son to a woman past bearing and a man grown old, and after the son a grandson, named before either was born. The guests' question, whether she wondered at the decree of Allah, is the answer to every such wonder. The same messengers went on from his house to overturn a city, so that one visit carried both of the things a prophet is sent with, a mercy and a warning."),
                  ]),
              ]),
        .init(id: "ibrahim-ram", title: "The sacrifice, and the ransom",
              summary: "Told in a dream to sacrifice his son, Ibraaheem and the boy both submitted, and a great sacrifice was sent as ransom.",
              group: .before,
              aliases: ["abraham", "ismail", "ishmael", "isaac", "ishaq", "ram", "dhabih", "udhiyah", "qurbani", "eid al-adha", "dream", "knife"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Ibraaheem had asked his Lord for a righteous son, and was given tidings of a forbearing boy. When the boy was old enough to work beside him, Ibraaheem told him what he had seen in a dream, and asked what he thought. The scholars say a prophet's dream is revelation, and the son answered as one who knew it:"),
                      .quran("37:100-105"),
                      .text("The Quran does not pause on the knife. It names the moment when both of them had submitted and the boy lay face down, and then the call, and the ransom, and the remembrance left among everyone who came after:"),
                      .quran("37:106-111"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign here is not a wonder done before a crowd. It is a command obeyed to the point of the knife by a father and a son who could both see what it would cost, and a ransom that came from outside the story, a sacrifice neither of them had brought. The Quran calls it the clear trial, and the scholars tie the udhiyah of Eid al-Adha to its memory. On that day the Prophet sacrificed two rams with his own hands:"),
                      .hadith("bukhari:5565", cite: "Saheeh al-Bukhaari 5565", arabic: 10...26, english: 0...36),
                  ]),
                  SignSection("A NOTE", [
                      .text("The Quran does not name the son. Ibn Taymiyyah, Ibn Katheer and Ibn Baaz hold that he was Ismaa‘eel, the firstborn, because the tidings of Ishaaq come only after the story is over (37:112) and Ishaaq was promised a son of his own, Ya‘qoob (11:71), so he could not have been the boy laid down to die; some of the Salaf said Ishaaq, and the difference is one of reading, not of faith."),
                      .quran("37:112"),
                      .quran("11:71"),
                  ]),
              ]),
        .init(id: "shuayb-shade", title: "Shu‘ayb, and the day of the shade",
              summary: "Madyan cheated at the scales and dared Shu‘ayb to bring down the sky on them; then the day of the shade came.",
              group: .before,
              aliases: ["jethro", "shuaib", "madyan", "midian", "aykah", "thicket", "scales", "measure", "cloud", "zullah", "earthquake", "blast"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Shu‘ayb was sent to Madyan, the people the Quran also calls the companions of the thicket; the commentators mostly take the two names for one people. His message was the one every messenger brought, worship of Allah alone and obedience to the man He sent, and he asked no payment for it:"),
                      .quran("26:176-180"),
                      .text("Then came the charge that belonged to this people in particular. They cheated at the scales, and what he asked of them was honesty in the market and fear of the One who had made them:"),
                      .quran("26:181-184"),
                  ]),
                  SignSection("WHAT THEY DID WITH IT", [
                      .text("They called him bewitched and a liar, and dared him to make good on his warning by dropping a piece of the sky on them:"),
                      .quran("26:185-189"),
                      .text("Surat al-A‘raaf names the earthquake, and Surat Hood the blast. The commentators reconcile the three as one punishment described three ways, and report that the shade was a cloud they ran to for relief from a burning heat."),
                      .quran("7:91"),
                      .text("Surat Hood sets Madyan beside Thamood, and names the ones who were saved:"),
                      .quran("11:94-95"),
                      .text("Shu‘ayb turned from the dead with a question: he had conveyed his Lord's messages and advised them, so how could he grieve for a people who had disbelieved (7:93)?"),
                      .quran("7:93"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("They asked for a piece of the sky to fall on them, and the punishment came from above them, on the day of the cloud. Shu‘ayb performed no wonder; the Quran names no staff or she-camel for him. His sign was the exactness of the answer to a demand they had made in mockery, and the market they had cheated in left as if no one had ever lived there (7:92). The surah says of it what it says of every people in it: in that is a sign, but most of them were not believers (26:190)."),
                      .quran("7:92"),
                      .quran("26:190"),
                  ]),
              ]),
        .init(id: "musa-river-mother", title: "Moosa on the river, and the promise to his mother",
              summary: "His mother was told to cast him into the river and promised his return; Pharaoh's house raised him and she nursed him.",
              group: .before,
              aliases: ["moses", "umm musa", "basket", "chest", "tabut", "ark", "nile", "pharaoh", "asiya", "wet nurse", "sister", "miriam"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Pharaoh was killing the sons of the Children of Israel. Moosa's mother was told what to do with hers, in words that held a command and a promise together: nurse him, and when you fear for him, put him in the river. She was told not to fear and not to grieve, and given two assurances no mother could check: that he would come back to her, and that he would be a messenger."),
                      .quran("28:7-9"),
                      .text("The river carried him to the one household in Egypt that could keep him safe from Pharaoh, Pharaoh's own. The ayahs that follow stay with the mother, whose heart the Quran says was emptied of everything but him:"),
                      .quran("28:10-13"),
                  ]),
                  SignSection("UNDER MY EYE", [
                      .text("Surat Ta-Ha tells the same favour to Moosa himself, years later, at the fire. It adds what no one on the river bank could see: the love placed on him, and whose eye he was raised under:"),
                      .quran("20:37-39"),
                      .text("The list goes on (20:40): his sister's errand, his return to his mother, the killing he was saved from, the years in Madyan, every one counted to him as a favour before he was sent."),
                      .quran("20:40"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Nothing in this story is a wonder anyone saw. A chest floated, Pharaoh's wife pleaded, an infant refused every breast, a girl offered a suggestion. The sign is in the fit of the parts: a promise made to a frightened woman at the worst moment of her life and kept in every detail, so that the child Pharaoh's men would have killed came back to his mother's arms, with Pharaoh's household none the wiser. The Quran says why it was done that way: so that she would know the promise of Allah is true."),
                  ]),
              ]),
        .init(id: "musa-tur", title: "The mountain that crumbled",
              summary: "Moosa asked to see his Lord; told to look at the mountain instead, he saw it levelled and fell unconscious.",
              group: .before,
              aliases: ["moses", "sinai", "tur", "kalimullah", "kalim allah", "speech", "spoke", "see allah", "ruyah", "tajalli", "forty nights", "tuwa"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Moosa was given an appointment of forty nights at the mountain, and left Haaroon in charge of his people (7:142)."),
                      .quran("7:142"),
                      .text("When he came to it his Lord spoke to him, and he asked for the one thing beyond that:"),
                      .quran("7:143"),
                      .text("He was not rebuked as a man who had asked wrongly. He was shown what a mountain could not bear, and when he came round he turned to his Lord in repentance and called himself the first of the believers. The sign was given to the mountain, and Moosa was its witness."),
                  ]),
                  SignSection("HOW ALLAH SPOKE TO HIM", [
                      .text("Moosa is the prophet the Quran singles out for having been spoken to. It had begun at the fire on the way back from Madyan, when he went to fetch a brand for his family and was called by name:"),
                      .quran("20:11-13"),
                      .text("The Quran states it plainly, with the word for speech doubled so that no one can read it as a figure:"),
                      .quran("4:164"),
                      .text("Surat Maryam names the place, the right side of the mount, and says he was brought near:"),
                      .quran("19:52"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The Quran says that no human being is spoken to by Allah except by revelation, from behind a veil, or through a messenger He sends (42:51). Moosa was spoken to from behind the veil, and when he asked for more than that, the answer was a sign no one could stand under: a mountain that could not hold its place before its Lord. The believers are promised the sight he asked for, but not in this world."),
                      .quran("42:51"),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ahl as-Sunnah hold that Allah spoke to Moosa with real speech that Moosa heard, as the words say, and that no one sees Allah in this world; the believers will see Him in the Hereafter. The Prophet promised it on a full-moon night, with the moon in front of them:"),
                      .hadith("bukhari:7434", cite: "Saheeh al-Bukhaari 7434", arabic: 31...56, english: 21...67),
                  ]),
              ]),
        .init(id: "musa-khidr", title: "Moosa, and the servant he was sent to learn from",
              summary: "Told that a servant of Allah knew more than he did, Moosa sought him out, with a fish that came to life as the sign.",
              group: .before,
              aliases: ["moses", "khidr", "khadir", "kahf", "fish", "two seas", "yusha", "joshua", "ship", "wall", "knowledge", "patience"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("The Prophet told how the journey began. Moosa had been asked who was the most knowledgeable of people and answered that he was, and he was corrected for not returning the knowledge to Allah:"),
                      .hadith("bukhari:4725", cite: "Saheeh al-Bukhaari 4725", arabic: 51...101, english: 45...147),
                      .text("The Quran takes it up from the road. The fish was the appointed mark, carried in a basket for food; the commentators report that it had been salted. At the rock it stirred and slipped into the sea, and the two of them walked on past the place:"),
                      .quran("18:60-65"),
                  ]),
                  SignSection("THE THREE DEEDS", [
                      .text("Moosa asked to follow him and learn. The servant warned him that he would not be able to bear it, since he would see things he had not been told the reason for, and made him promise to ask about nothing until he was told. The promise was tested at once, and twice:"),
                      .quran("18:71-74"),
                      .text("The third time Moosa set his own terms, and the third deed ended the company:"),
                      .quran("18:75-77"),
                  ]),
                  SignSection("THE EXPLANATION", [
                      .text("At the parting the servant gave the reasons, and ended by disclaiming the deeds as his own:"),
                      .quran("18:78-82"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Two things in the story are a sign. The first is the fish, carried for food, that slipped into the sea at the one place Moosa had been told to look for: the mark that he had reached the man. The second is the man himself, given knowledge from Allah that a prophet with the Torah did not have, and able to say that he had done none of it of his own accord. Moosa, spoken to on the mountain, was sent to learn from a servant. The lesson is the one he had missed before his people: knowledge is Allah's to give, and to divide as He wills."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The Quran does not name the servant; the Prophet's narration calls him al-Khidr, and the commentators follow it. The scholars differ on whether he was a prophet or a righteous servant, and the Salafi scholars, following Ibn Taymiyyah, hold that he is dead, as every man of his age is; nothing in the story rests on either question."),
                  ]),
              ]),
        .init(id: "isa-raised", title: "Eesa was not killed: he was raised",
              summary: "They claimed to have crucified the Messiah; the Quran says they did not kill him, and Allah raised him to Himself.",
              group: .before,
              aliases: ["jesus", "messiah", "masih", "crucifixion", "cross", "crucified", "raised", "rafa", "ascension", "alive", "return", "day of judgement"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Those of the Children of Israel who rejected Eesa went on to boast that they had killed him. The Quran answers the boast in one ayah and gives the truth in the next:"),
                      .quran("4:157-158"),
                      .text("The plot is named in Al Imraan, and so is the plan that overruled it. Allah's words to Eesa were a promise of what He would do with him, and of what would become of those who followed him:"),
                      .quran("3:54-55"),
                  ]),
                  SignSection("HIS OWN WORDS ON THAT DAY", [
                      .text("The Quran records a conversation still to come, on the Day of Resurrection, in which Eesa is asked about those who took him and his mother as gods beside Allah. His answer dates his knowledge of his people to the day he was taken up:"),
                      .quran("5:116-117"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign was a rescue no one on the ground could see. The people who wanted him dead were left certain they had succeeded, and the Quran says those who differ over it have nothing but conjecture. It does not say how the resemblance was made, and that is left where the Quran leaves it. The one who raised the dead by Allah's permission was himself taken out of the reach of death, and his enemies' plan was overruled by a plan they could not read. Of all the prophets, he is the one whose story is not yet finished."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ahl as-Sunnah hold that Eesa was raised alive, body and soul, that he is alive now, and that he will descend before the Hour; the commentators read 43:61 as making his descent a sign of the Hour, and the Prophecies library tells of it. The words 'I will take you' in 3:55 are read as his being taken up whole, not as death, since Surat an-Nisa says plainly that they did not kill him and that Allah raised him to Himself."),
                      .quran("43:61"),
                  ]),
              ]),
    ]

    // MARK: More: his signs, creation, prayers and protection

    static let hisEntries2: [Entry] = [
        .init(id: "jibril-true-form", title: "Jibreel in his true form",
              summary: "Twice he saw the angel as he was created, filling the horizon; the Quran records the second at the Lote Tree.",
              group: .his,
              aliases: ["gabriel", "jibreel", "six hundred wings", "600 wings", "najm", "surah 53", "sidrat al-muntaha", "lote tree", "horizon", "two bow lengths", "ibn masud", "aishah"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Jibreel came to him for twenty-three years, usually unseen, sometimes in the shape of a man. Twice he came as he was created. Surah an-Najm, a Makkan surah, describes the first: the angel stood in the highest horizon, then drew near, until he was two bow-lengths away or nearer, and delivered what he delivered."),
                      .quran("53:5-10"),
                      .text("The surah then turns to a second sight, at the Lote Tree of the Utmost Boundary, on the night of the ascent:"),
                      .quran("53:13-18"),
                  ]),
                  SignSection("WHAT HE SAID", [
                      .text("Masrooq asked Aa’ishah about these ayahs, and about the ayah of Surah at-Takweer that says he saw him on the clear horizon. She answered that she had been the first of this community to ask the Prophet himself, and she gave his answer:"),
                      .hadith("muslim:177a", cite: "Saheeh Muslim 177a", arabic: 81...123, english: 115...187),
                      .text("In another sitting she said what the first of the two sights was like:"),
                      .hadith("muslim:177d", cite: "Saheeh Muslim 177d", arabic: 36...62, english: 41...77),
                      .text("Ibn Mas‘ood, asked about the same ayahs, added a detail the Prophet had told him:"),
                      .hadith("bukhari:3232", cite: "Saheeh al-Bukhaari 3232", arabic: 29...38, english: 41...58),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The messenger who carried the revelation was seen as he is, twice, by the man who received it; and the Quran put the first sight in a surah recited to the Quraysh, with a challenge in the ayahs that follow: the heart did not lie about what it saw, so will you dispute with him over what he sees? The Companions knew Jibreel only in the form of a man. The Prophet knew him in both."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Aa’ishah held that what the Prophet saw in these ayahs was Jibreel and not his Lord, whom no eye sees in this life, and most of the Salaf held the same (Saheeh al-Bukhaari 4855, Saheeh Muslim 177); Ibn Abbaas spoke of a seeing with the heart, and the scholars reconcile the two reports that way."),
                      .hadith("muslim:177a", cite: "Saheeh Muslim 177a, Saheeh al-Bukhaari 4855", arabic: 81...121, english: 115...187),
                  ]),
              ]),
        .init(id: "cave-protection", title: "Two in the cave, and Allah the third",
              summary: "The searchers stood at the mouth of the cave; had one looked down at his feet he would have seen them. None did.",
              group: .protection,
              aliases: ["thawr", "ghar", "hijrah", "migration", "abu bakr", "siddiq", "quraysh", "sakinah", "tranquillity", "do not grieve", "la tahzan", "tawbah 40"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("When Quraysh resolved to kill him, in 622 CE, he left Makkah by night with Abu Bakr, and the two hid in a cave on Mount Thawr, south of the city and away from the road to Madinah. Quraysh put a price on each of them and sent searchers along every track."),
                      .text("The searchers reached the cave. Abu Bakr told what happened at its mouth:"),
                      .hadith("bukhari:3653", cite: "Saheeh al-Bukhaari 3653", arabic: 18...46, english: 0...42),
                      .text("The Quran recounts the same moment to the Companions, with what was sent down into the cave:"),
                      .quran("9:40"),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Abu Bakr tells it himself, and the ayah was recited in Madinah to men who had heard it from him. The enemy at the mouth of the cave were the other witnesses: they came close enough to be seen from below, and went away without looking down."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Nothing was put between the two men and the searchers. The protection the Quran names is tranquillity sent down on him, and hosts no one saw; the proof is in what did not happen. The words he said in the cave, do not grieve, Allah is with us, are the words he said again on the road when Suraaqah caught up with them, told in its own entry."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The spider that spun a web over the entrance and the dove that nested there are in reports the hadith scholars grade weak, and the saheeh account has neither. The sign the sources carry is the one Abu Bakr describes: men standing at the mouth who did not look down."),
                  ]),
              ]),
        .init(id: "ghawrath-sword", title: "The sword over him as he slept",
              summary: "A stranger stood over him with his own sword: who will protect you from me? Allah, he said, and the man sat down.",
              group: .protection,
              aliases: ["ghawrath", "ghaurath ibn al-harith", "dhat al-riqa", "najd", "bedouin", "jabir", "acacia", "who will save you", "man yamnauka", "fear prayer", "salat al-khawf"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("On the expedition towards Najd known as Dhaat ar-Riqaa‘, the army halted at midday in a valley of thorn trees and the men scattered for shade. The Prophet lay down under an acacia and hung his sword on a branch. Jaabir says they were asleep when they heard him calling them, and came to find a Bedouin sitting with him. He told them what had happened:"),
                      .hadith("bukhari:4135", cite: "Saheeh al-Bukhaari 4135", arabic: 102...142, english: 100...155),
                      .text("Muslim's narration from Jaabir has the exchange in full, and what followed:"),
                      .hadith("muslim:843a", cite: "Saheeh Muslim 843a", arabic: 75...110, english: 60...105),
                      .text("The call to prayer was then given, and he led the fear prayer, two rak‘ahs with each half of the army, in the enemy's own country."),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Jaabir ibn Abdullah tells it, and the Companions he called came and found the man sitting beside him, disarmed by nothing but an answer. Al-Bukhaari records from Abu Bishr that the man's name was Ghawrath ibn al-Haarith (Saheeh al-Bukhaari 4136)."),
                      .hadith("bukhari:4136", cite: "Saheeh al-Bukhaari 4136", arabic: 95...103, english: 147...163),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("A sleeping man, a drawn sword, and no one within reach: everything a killer needs. He answered the question with one word, and the man who held the blade put it back in its sheath and sat down. The Prophet did not punish him. The Quran had promised the Messenger exactly this:"),
                      .quran("5:67"),
                  ]),
                  SignSection("A NOTE", [
                      .text("Some tellings add that the sword fell from the man's hand and the Prophet took it up and asked him the same question; the saheeh rows from Jaabir say only that he sheathed it, and that is what is quoted here. The year is disputed: Ibn Ishaaq put Dhaat ar-Riqaa‘ in 4 AH, and al-Bukhaari placed it after Khaybar."),
                  ]),
              ]),
        .init(id: "sihr-cured", title: "The spell, and the cure",
              summary: "A spell was worked on him; two came to him in sleep and named the man, the means and the well, and Allah cured him.",
              group: .protection,
              aliases: ["sihr", "magic", "sorcery", "labid ibn al-asam", "banu zurayq", "comb", "hair", "well of dharwan", "dhi arwan", "falaq", "nas", "aishah"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("In Madinah a man of Banu Zurayq, Labeed ibn al-A‘sam, worked a spell on him. Aa’ishah says its effect was that he would imagine he had done a thing he had not done. He prayed, and prayed again, and then told her what he had been shown:"),
                      .hadith("bukhari:5763", cite: "Saheeh al-Bukhaari 5763", arabic: 51...119, english: 36...182),
                      .text("He went to the well with some of his Companions, and came back:"),
                      .hadith("muslim:2189a", cite: "Saheeh Muslim 2189a", arabic: 141...194, english: 227...313),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Aa’ishah tells it, and she was the one who asked him why he did not bring the thing out for people to see. The Companions who went with him to the well saw its water and its palms as he described them. Al-Bukhaari and Muslim both have the story through Hishaam ibn Urwah from his father, and al-Bukhaari gives it in several places."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign is not that a spell could touch him; it is how it ended. He was told in his sleep who had done it, with what, and where it was hidden, and the search bore out every detail. He then chose not to expose the man, because Allah had cured him and he would not stir up harm among the people."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars of Ahl as-Sunnah affirm the event as al-Bukhaari and Muslim report it, and hold that it touched his body, not his message: Ibn al-Qayyim likened it to an illness he was healed of, and Ibn Hajar explains Aa’ishah's words as concerning his household, since no word of revelation was affected. The commentators say the two who came to him were angels."),
                  ]),
              ]),
        .init(id: "two-lights", title: "Two lamps on a dark night",
              summary: "Two Companions left his house in the dark and a light went before each; when they parted, each kept his own.",
              group: .his,
              aliases: ["usayd ibn hudayr", "abbad ibn bishr", "usaid", "abbad", "light", "nur", "lamp", "misbah", "ansar", "anas", "dark night"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Anas tells it in a few words. Two of the Companions had been with the Prophet, and set out for home on a night with no moon:"),
                      .hadith("bukhari:3639", cite: "Saheeh al-Bukhaari 3639", arabic: 18...54, english: 0...61),
                      .text("Al-Bukhaari gives the same report in the merits of the Ansaar, and there Anas names the two: Usayd ibn Hudayr and Abbaad ibn Bishr (Saheeh al-Bukhaari 3805)."),
                      .hadith("bukhari:3805", cite: "Saheeh al-Bukhaari 3805", arabic: 17...70, english: 0...29),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The two men walked home by it, and Anas, who served in the Prophet's house, is the one who tells it. Usayd ibn Hudayr is the Companion whose recitation of Surah al-Baqarah one night drew what looked like a canopy of lamps down over his yard; that is told in its own entry."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Nothing was asked for and nothing was announced. The light appeared for two men going home from him, and it did not stay with him: it went with them, and when their ways divided it divided. A sign given to the Companions on their own doorsteps is the kind of thing a household remembers, and Anas remembered it."),
                  ]),
              ]),
        .init(id: "daws-guided", title: "O Allah, guide Daws",
              summary: "Asked to curse a tribe that had refused him, he prayed for its guidance, and the tribe came to him as Muslims.",
              group: .prayers,
              aliases: ["daws", "dous", "dawsi", "tufayl ibn amr", "tufail", "abu hurayrah", "curse", "guidance", "hidayah", "khaybar", "ihdi dawsan"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("At-Tufayl ibn Amr was a chief of Daws, a tribe of the south, who had accepted Islam and gone home to call his people. He came to the Prophet with the Muslims of his tribe and reported that Daws had refused. Abu Hurayrah, himself a man of Daws, tells what was asked for and what was given:"),
                      .hadith("bukhari:2937", cite: "Saheeh al-Bukhaari 2937", arabic: 19...53, english: 0...62),
                      .text("At-Tufayl went back. In the year of Khaybar, 7 AH, the Daws came to Madinah as Muslims, households of them, and Abu Hurayrah arrived with them: al-Bukhaari notes that he came to the Prophet in the days of Khaybar (Saheeh al-Bukhaari 4137)."),
                      .hadith("bukhari:4137", cite: "Saheeh al-Bukhaari 4137", arabic: 29...40, english: 36...47),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The narrator is one of the people prayed for. Abu Hurayrah, a man of Daws, is the one who passes the prayer on, and he lived its answer: the rest of his life was spent in Madinah among the Companions, and he became the most prolific narrator of the Prophet's words."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The people around him expected a curse, and said so: Daws is finished. He asked instead for their guidance, and for them to be brought to him, and both halves of the prayer were answered within a few years. Of all the ways a prayer can be answered, this is the easiest to check: a whole tribe changed its mind."),
                  ]),
              ]),
        .init(id: "wind-trench", title: "The wind at the Trench",
              summary: "A siege of weeks ended in one night of wind and cold; the Quran calls it a wind, and hosts you did not see.",
              group: .his,
              aliases: ["khandaq", "ahzab", "confederates", "siege", "saba", "east wind", "dabur", "hudhayfah", "abu sufyan", "5 ah", "627", "nusirtu bil-saba"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("In 5 AH (627 CE) Quraysh, Ghatafaan and their allies, some ten thousand men by the seerah's count, camped against Madinah, and the Muslims held them off across a trench for weeks. The Quran recalls how it ended:"),
                      .quran("33:9"),
                      .text("Hudhayfah ibn al-Yamaan was there on the last night, and remembered it as a night of violent wind and severe cold (Saheeh Muslim 1788); the Prophet sent him across the trench to find out what the enemy were doing."),
                      .hadith("muslim:1788", cite: "Saheeh Muslim 1788", arabic: 44...58, english: 55...81),
                      .text("He found Abu Sufyaan warming his back at a fire, and came back with the news. The seerah's record is that the camp could not be held in that wind: the Confederates broke it up that night and went home, and Quraysh never marched on Madinah again."),
                      .text("The Prophet named the wind afterwards, and set it beside the wind that had ended Ad:"),
                      .hadith("bukhari:1035", cite: "Saheeh al-Bukhaari 1035", arabic: 18...26, english: 0...21),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Everyone on both sides of the trench felt the cold; Hudhayfah walked through the enemy's camp in it. Ibn Abbaas carries the saying about the two winds, and al-Bukhaari files it both under the prayer for rain and under the Battle of the Confederates (Saheeh al-Bukhaari 4105)."),
                      .hadith("bukhari:4105", cite: "Saheeh al-Bukhaari 4105", arabic: 30...34, english: 0...26),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sign is in the timing and the naming. An east wind came on the one night it was needed, against an army that had everything else in its favour, and the Prophet called it his victory in the same breath as the wind that destroyed ‘Ad, a wind the Quran describes as sent. The angels of Badr were seen by some; here the hosts were not seen at all, and the Quran says so."),
                  ]),
              ]),
        .init(id: "left-hand", title: "The hand that would not rise",
              summary: "He told a man to eat with his right hand; the man said he could not, out of pride, and never could again.",
              group: .creation,
              aliases: ["left hand", "right hand", "shimal", "yamin", "pride", "kibr", "la istatata", "salamah ibn al-akwa", "eating", "etiquette"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Salamah ibn al-Akwa' saw it at a meal. A man ate in front of the Prophet with his left hand, and was told to use his right:"),
                      .hadith("muslim:2021", cite: "Saheeh Muslim 2021", arabic: 34...59, english: 0...46),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The man was not unable; Salamah says it was pride that kept him. The Prophet answered the excuse in its own words, may you not be able, and from then on the hand did not reach his mouth. It is a small scene with a heavy edge: his words were not his own, and a refusal dressed up as an excuse was taken at its word."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The Sunnahs library has the same narration for the ruling it carries, eating and drinking with the right hand, which Ibn Baaz and Ibn Uthaymeen held to be obligatory for anyone able to do it. Here it stands for the sign alone, and for the weight of his word."),
                  ]),
              ]),
        .init(id: "ali-eyes", title: "Ali's eyes at Khaybar",
              summary: "Ali had stayed behind with sore eyes; he spat in them and prayed, and Ali was well as if he had never been ill.",
              group: .protection,
              aliases: ["ali ibn abi talib", "khaibar", "sore eyes", "ramad", "spat", "saliva", "cured", "healing", "sahl ibn sad", "banner", "7 ah"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("At the siege of Khaybar in 7 AH the Prophet said that in the morning he would give the banner to a man through whom Allah would grant victory. In the morning he asked for Ali, who had stayed behind when the army set out because of his eyes. Sahl ibn Sa‘d tells what happened when he was brought:"),
                      .hadith("bukhari:3701", cite: "Saheeh al-Bukhaari 3701", arabic: 59...95, english: 62...128),
                      .text("Muslim has it from Sahl too, with the same words for the cure:"),
                      .hadith("muslim:2406", cite: "Saheeh Muslim 2406", arabic: 94...136, english: 66...124),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The whole camp was gathered when Ali was led in, with eyes sore enough to have kept him from the march. Sahl ibn Sa‘d tells it, and Salamah ibn al-Akwa' confirms why Ali had stayed behind (Saheeh al-Bukhaari 3702). The man who was cured was sent straight at the fortresses."),
                      .hadith("bukhari:3702", cite: "Saheeh al-Bukhaari 3702", arabic: 12...36, english: 0...34),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The cure was complete and immediate: as if he had never been ill, says the narration, and he was given a banner and a siege the same morning. The banner, and what the Prophet said the night before, are told in the Prophecies library; this entry is the healing, one of several at his hand recorded at Khaybar, with Salamah's wound."),
                  ]),
              ]),
        .init(id: "abu-talhah-night", title: "O Allah, bless them in their night",
              summary: "Umm Sulaym hid her son's death till morning; the Prophet blessed their night, and from it came nine who read the Quran.",
              group: .prayers,
              aliases: ["umm sulaym", "umm sulaim", "abu talhah", "anas", "abdullah ibn abi talhah", "patience", "sabr", "loan", "ariyah", "tahnik", "nine sons", "reciters"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("A son of Abu Talhah fell ill and died while his father was out. Umm Sulaym, his mother and the mother of Anas, laid the boy out, told the family to say nothing, and gave her husband his supper when he came in. Only afterwards did she put a question to him:"),
                      .hadith("muslim:2144d", cite: "Saheeh Muslim 2144d", arabic: 65...88, english: 65...104),
                      .text("Abu Talhah went out angry, and told the Prophet in the morning. Anas tells the rest:"),
                      .hadith("bukhari:1301", cite: "Saheeh al-Bukhaari 1301", arabic: 84...131, english: 102...170),
                      .text("She conceived that night. The boy was Abdullah ibn Abi Talhah; Anas carried him to the Prophet on the morning he was born, and the Prophet softened a date in his mouth, put it on the child's palate, and named him (Saheeh Muslim 2144a)."),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("Anas was in the house: Umm Sulaym was his mother and Abu Talhah his stepfather. The nine are counted by a man of the Ansaar quoted by Sufyaan ibn Uyaynah; the commentators explain that they were the sons of Abdullah, so the blessing ran into the next generation, and one of them, Ishaaq ibn Abdullah, is the narrator through whom al-Bukhaari has this very hadith."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The prayer was a few words, said for a couple who had lost a child the night before, and its answer was counted for two generations: a son, and that son's nine sons, every one a reader of the Quran. Abu Talhah's loaves and Anas's own wealth and children are told in their own entries; this is the night."),
                  ]),
              ]),
        .init(id: "sad-dua", title: "A prayer that Allah would answer Sa‘d",
              summary: "He prayed that Sa‘d's prayers be answered; in Koofah a man who slandered Sa‘d lived to be struck by all three of Sa‘d's.",
              group: .prayers,
              aliases: ["sad ibn abi waqqas", "saad", "mustajab al-dawah", "answered prayer", "kufah", "umar", "usamah ibn qatadah", "abu sadah", "slander", "trials", "fitan"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Sa‘d ibn Abi Waqqaas was among the first to accept Islam and, as he said himself, the first to shoot an arrow for it. The Prophet once asked something for him that the Companions never forgot:"),
                      .hadith("tirmidhi:3751", cite: "Jaami‘ at-Tirmidhi 3751; graded saheeh by al-Albaani", arabic: 32...40, english: 7...16),
                  ]),
                  SignSection("WHAT CAME OF IT", [
                      .text("Years later, under Umar, Sa‘d governed Koofah, and some of its people complained of him, even saying he did not pray properly. Umar sent men to ask about him mosque by mosque, and every gathering praised him until, in the mosque of Banu Abs, a man called Usaamah ibn Qataadah stood and said that Sa‘d did not go out with the troops, did not divide fairly, and did not judge justly. Jaabir ibn Samurah tells what Sa‘d said, and what became of the man:"),
                      .hadith("bukhari:755", cite: "Saheeh al-Bukhaari 755", arabic: 140...171, english: 217...286),
                      .text("Abd al-Malik ibn Umayr, who passed the story on from Jaabir ibn Samurah, said he saw the man himself in old age, his eyebrows fallen over his eyes, poor, and still falling in the streets into the sins Sa‘d had prayed he would be exposed to."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Sa‘d's prayer was conditional, if this servant of Yours is lying, and all three parts of it landed on one man, in front of a city that had heard the charge and the prayer. The Companions knew Sa‘d as a man whose prayers were answered, and this is the row that shows why."),
                  ]),
                  SignSection("A NOTE", [
                      .text("At-Tirmidhi preferred the chain of this hadith that stops short of Sa‘d, while al-Albaani graded it saheeh, and the Koofah story stands in al-Bukhaari on its own. Sa‘d's own long life, foretold in the illness of 10 AH, is told in the Prophecies library."),
                  ]),
              ]),
        .init(id: "jabir-camel", title: "Jaabir's worn-out camel",
              summary: "His camel could not keep up; the Prophet struck it and prayed, and he had to hold it back from outrunning him.",
              group: .creation,
              aliases: ["jabir ibn abdullah", "camel", "jamal", "exhausted", "stick", "mihjan", "uqiyyah", "bilal", "bought", "price", "sale"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Jaabir was riding back from an expedition with the Prophet, and his camel was done. He tells it:"),
                      .hadith("bukhari:2097", cite: "Saheeh al-Bukhaari 2097", arabic: 24...80, english: 0...90),
                      .text("Muslim's narration says the Prophet prayed for the camel and struck it, and that it then went as it had never gone before (Saheeh Muslim 715). On the road the Prophet talked with him about his marriage and his sisters, then asked whether he would sell the camel, and bought it for an ooqiyyah."),
                      .hadith("muslim:715o", cite: "Saheeh Muslim 715", arabic: 29...92, english: 0...89),
                      .text("The Prophet reached Madinah first. When Jaabir arrived in the morning he was told to leave the camel, go into the mosque and pray two rak‘ahs, and Bilaal weighed out the price, with something over. Then he was called back:"),
                      .hadith("bukhari:2097", cite: "Saheeh al-Bukhaari 2097", arabic: 186...209, english: 308...346),
                  ]),
                  SignSection("WHO SAW IT", [
                      .text("The whole column saw a camel that had been left behind come up and have to be held back. Jaabir told the story so often, and to so many students, that al-Bukhaari and Muslim have it through many chains, and the jurists discuss its sale at length."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The animal was finished, and a touch and a prayer made it the fastest in the column. Then the Prophet turned the sign into a kindness: he bought the camel so that he could give it back with its price, to a young man carrying his dead father's debts and his sisters. Those debts, and the dates that paid them, are told in their own entry."),
                  ]),
              ]),
        .init(id: "usayd-cloud", title: "Usayd's recitation, and the canopy of lamps",
              summary: "He recited al-Baqarah at night and his horse shied; a canopy of lamps hung above him. Those were angels, he was told.",
              group: .creation,
              aliases: ["usayd ibn hudayr", "usaid", "baqarah", "recitation", "tilawah", "horse", "canopy", "zullah", "lamps", "angels", "malaikah", "sakinah"],
              sections: [
                  SignSection("WHAT HAPPENED", [
                      .text("Usayd ibn Hudayr, a chief of the Ansaar, was reading Surah al-Baqarah one night in his yard, with his horse tethered beside him and his young son Yahya lying near it:"),
                      .hadith("bukhari:5018", cite: "Saheeh al-Bukhaari 5018", arabic: 14...32, english: 0...42),
                      .text("Afraid the horse would trample the boy, he stopped and went to him, and looking up saw something like a canopy with lamps in it, rising into the sky until it was gone. In the morning he told the Prophet, who said, three times, that he should have kept reading. Usayd explained why he had stopped:"),
                      .hadith("muslim:796", cite: "Saheeh Muslim 796", arabic: 157...201, english: 144...231),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Usayd saw a thing he could not explain; the Prophet named it, and told him it would have stayed until daylight for the whole town to see. The sign was given to a Companion reciting alone, and its reading was given by the Prophet. Al-Baraa’ tells of another man whose recitation of al-Kahf brought a cloud down over him, and the Prophet called that the tranquillity that descends for the Quran (Saheeh al-Bukhaari 5011, 3614)."),
                      .hadith("bukhari:5011", cite: "Saheeh al-Bukhaari 5011, 3614", arabic: 12...47, english: 0...77),
                  ]),
              ]),
        .init(id: "jinn-listened", title: "The jinn who heard him at Nakhlah",
              summary: "A company of jinn heard him recite at Fajr and went back believing; he learned of it only when the Quran told him.",
              group: .his,
              aliases: ["jinn", "nakhlah", "ukaz", "surah 72", "al-jinn", "ahqaf", "shooting stars", "shihab", "ibn abbas", "fajr", "listened"],
              sections: [
                  SignSection("THE SIGN", [
                      .text("Ibn Abbaas tells how the shooting stars that barred the devils from the heavens sent them searching east and west for the cause, and how one party found it:"),
                      .hadith("bukhari:773", cite: "Saheeh al-Bukhaari 773", arabic: 85...159, english: 121...249),
                      .text("The surah that opens with their words:"),
                      .quran("72:1-2"),
                      .text("Surah al-Ahqaaf tells the same: a company of jinn turned to him, listened, and went back to their people as warners:"),
                      .quran("46:29-31"),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He did not see them and did not know they were there; Ibn Abbaas says plainly that what was revealed to him was their conversation. A book that reports a hearing its own reciter could not have witnessed, and names the response of listeners from another creation, puts the knowledge it claims where no human source could reach."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn Mas‘ood tells of a different night, when the Prophet went out to the jinn with an inviter of theirs and recited to them, and the Companions searched for him until dawn (Saheeh Muslim 450); the scholars count that as a later occasion, and this entry is the first, when they came to him unseen."),
                      .hadith("muslim:450a", cite: "Saheeh Muslim 450a", arabic: 51...115, english: 31...162),
                  ]),
              ]),
    ]
}
#endif
