#if os(iOS)
import SwiftUI

// The Sunnahs of the Prophet library's articles, as data (`SignSection` / `SignBlock` in
// SignsAndProphets.swift). The index and the article screen are in SunnahView.swift.
//
// Rules every article here keeps (Scripts/verify_prophecies.py enforces the mechanical ones):
//   * a hadith is a `.hadith(` reference into the bundled shelf, sahih or hasan by the weight of
//     its graders, never retyped; an ayah is a `.quran(` reference;
//   * the rulings are the mainstream Sunni ones as the Salafi scholars state them: a sunnah is
//     recommended, never called obligatory, and nothing is added to what the narrations carry;
//   * no em dash, and no spaced hyphen standing in for one.

extension SunnahView {
    /// The index order: groups in `Entry.Group` order, the day from waking to sleeping.
    static let entries: [Entry] = wakingEntries + purificationEntries + homeEntries + masjidEntries + voluntaryEntries
        + prayerEntries2 + foodEntries + foodEntries2 + companyEntries + dayEntries + weekEntries
        + occasionEntries + nightEntries

    /// The MOST EMPHASISED section, in reading order: the sunnahs he kept to most closely and urged
    /// most, as the scholars count them (the regular prayers around the obligatory ones, Witr, the
    /// siwak, the words on lying down and on waking). The app's own pick.
    static let emphasisedIDs = [
        "rawatib",
        "fajr-two",
        "witr",
        "siwak-every-wudu",
        "waking-praise",
        "sleep-wudu-right-side",
        "eat-bismillah-right",
        "spread-salam",
        "after-salah-dhikr",
        "fast-monday-thursday",
        "hundred-tahlil",
    ]

    // MARK: On waking

    static let wakingEntries: [Entry] = [
        .init(id: "waking-praise", title: "Praise Allah on waking",
              summary: "The first words of the day: praise to Allah who gave us life after taking it, and to Him is the return",
              group: .waking,
              aliases: ["alhamdulillah", "al-hamdu lillah", "ahyana", "nushur", "resurrection", "dhikr", "wake up", "getting up", "sleep", "hudhayfah", "morning"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Sleep takes a person out of the world for a few hours, and the Prophet treated coming back from it as a gift to be acknowledged at once. Hudhayfah, who kept a close watch on his habits, reported the words he said as he lay down and the words he said as he got up. The waking words praise Allah for restoring life after He had taken it, and end by naming where that life is headed."),
                      .hadith("bukhari:6312", cite: "Sahih al-Bukhari 6312", arabic: 34...43, english: 22...30),
                      .text("In Hudhayfah's fuller report the two sets of words stand side by side, the bedtime ones in Allah's name and the waking ones in His praise. Sleep is entrusted to Him and waking is credited to Him, so the day is closed and opened with the same thought, and the second half of each set points past this life to the return and the resurrection."),
                      .hadith("bukhari:6324", cite: "Sahih al-Bukhari 6324", arabic: 17...49, english: 0...69),
                      .text("The words rest on an ayah. The Quran describes sleep as Allah taking the soul and then returning it, in the same breath as He takes it at death, which is why the Prophet could speak of waking as being given life after being made to die:"),
                      .quran("39:42"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Make the words the first thing you do, before you reach for the phone or speak to anyone. Say: Al-hamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur (praise be to Allah who gave us life after He had caused us to die, and to Him is the resurrection). Once is enough, in a low voice, lying down or sitting up; the narration fixes no posture and no count."),
                      .text("Pair it with the words for lying down the night before: Bismika Allahumma amutu wa ahya (in Your name, O Allah, I die and I live). The two are halves of one habit, and the words said at night are what bring the waking words to mind. If you forgot them at night, say the waking words anyway; each stands on its own."),
                      .text("Let the praise lead into the rest of the morning: the washing of the hands, the siwak, wudu and the prayer. The Prophet's mornings ran in that order, and this praise is the first link in the chain. If you wake in the night to pray rather than at dawn, the words are the same, for every waking from sleep."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The waking words answer the ayah: life after a small death, and a reminder that the return is to Him. They are also the first remembrance of the day, and the hadith of the three knots, next in this list, counts remembering Allah on waking as the act that undoes the first of Shaytan's knots. A day that opens with praise has its first act already in the right place, before a single word has been spoken to anyone else."),
                  ]),
              ]),
        .init(id: "waking-knots", title: "Untie the three knots",
              summary: "Shaytan ties three knots on the sleeper; remembering Allah, wudu and prayer undo them one by one",
              group: .waking,
              aliases: ["satan", "devil", "uqad", "lazy", "sluggish", "energetic", "tahajjud", "fajr", "abu hurayrah", "laziness", "good heart", "morning"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet described what happens to a person while he sleeps, and what it takes to undo it. Shaytan ties three knots at the back of the sleeper's head, and at each one he whispers that the night is long. The three acts that loosen them are the three the Prophet's own mornings began with: remembering Allah, wudu, and prayer. Abu Hurayrah narrated it, and both al-Bukhari and Muslim recorded it."),
                      .hadith("bukhari:1142", cite: "Sahih al-Bukhari 1142", arabic: 21...72, english: 0...90),
                      .text("Muslim's wording of the same report has the wudu loosen two knots at once and the prayer the rest, and it ends the same way, with a morning that is either light and glad or heavy and sluggish (Sahih Muslim 776). The hadith gives a cause for something everyone has felt: the weight of a morning that began with nothing, and the ease of one that began with Allah."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("The moment you are awake, remember Allah. The words of praise on waking, the first page of this library, are the natural way, or any dhikr will do: la ilaha illallah (there is no god but Allah), subhanallah (glory be to Allah), astaghfirullah (I seek Allah's forgiveness). The first knot goes before you have left the bed."),
                      .text("Get up and make wudu, washing the hands first and rinsing the nose well, as the pages that follow describe. Do not let the whisper that the night is long decide for you. The hadith names the wudu itself as what loosens the second knot, so the cold water on the face is part of the cure, not a chore before it."),
                      .text("Then pray: the night prayer if you have risen for it, or the two rak'ahs before Fajr and Fajr itself. The narration names the prayer without limiting it, and the third knot goes with it. What follows is the Prophet's own description of the result, a morning begun energetic and with a good heart, which is the test of whether the three were done."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward named in the narration is the morning itself: whoever does the three rises energetic and with a good heart, and whoever does not rises lazy and ill at heart. The scholars draw from it that heaviness in the morning is not only a matter of too little sleep but of Shaytan's work, and that the believer has three plain tools against him, each one already a sunnah in its own right. It also explains why the Prophet's day began with dhikr, wudu and prayer and nothing else before them."),
                  ]),
              ]),
        .init(id: "waking-face-ayat", title: "Wipe the sleep away and recite the end of Al 'Imran",
              summary: "When he woke in the night he wiped his face with his hands and recited the last ten ayahs of Al 'Imran",
              group: .waking,
              aliases: ["ibn abbas", "maymunah", "maimuna", "aal imran", "al-imran", "ulul albab", "inna fi khalqi", "last ten verses", "rubbing", "eyes", "tahajjud", "night prayer"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Ibn 'Abbas was a boy when he spent a night at the house of his aunt Maymunah, the Prophet's wife, so that he could watch how the Prophet prayed at night. He lay across the cushion and the Prophet and his wife lay along it. Around the middle of the night the Prophet woke, sat up, wiped the sleep from his face with his hand, and recited the closing ayahs of Al 'Imran before he went to the water-skin for wudu."),
                      .hadith("bukhari:183", cite: "Sahih al-Bukhari 183", arabic: 47...97, english: 40...112),
                      .text("Other reports of the same night name the passage he began with, the ayah on the creation of the heavens and the earth and the alternation of night and day as signs for people of understanding, and say he recited to the end of the surah (Sahih al-Bukhari 4569, Sahih Muslim 763). So the last ten run from 3:190, the ayah he opened with, to the surah's close:"),
                      .quran("3:190-200"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you wake in the night, sit up and wipe your face with your hands, the way one wipes sleep from the eyes. It is a small act, but it is the first thing Ibn 'Abbas saw him do on waking, and it marks the move from sleep to wakefulness before anything else is said or done."),
                      .text("Recite the last ten ayahs of Al 'Imran, from the ayah on the creation of the heavens and the earth (3:190) to the end of the surah. Learn them by heart if you have not yet; they are a single passage, a reflection on the creation that turns into a prayer, and they take only a few minutes to say."),
                      .text("Then go to the water and make wudu well, and pray what you have risen for. In Ibn 'Abbas's account the recitation came before the wudu, not after it, so the ayahs are said while the night is still quiet and the body is still, and the washing and the prayer follow them."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The ayahs he chose are a reflection and a plea in one. They describe the people of understanding as those who remember Allah standing, sitting and lying on their sides, and think about the creation of the heavens and the earth, and then they ask for forgiveness and for Paradise. To say them on waking is to open the night with the Quran's own description of the person the night prayer is for. The scholars list the wiping and the recitation among the sunnahs of rising at night because he did both before he reached the water."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The report is of his waking in the night for prayer, and that is where the scholars place the recitation. The ten ayahs are counted from 3:190, the ayah he began with, so the passage runs to the end of the surah."),
                  ]),
              ]),
        .init(id: "waking-siwak", title: "The siwak on rising",
              summary: "Whenever he got up at night to pray, he cleaned his mouth with the tooth-stick before wudu",
              group: .waking,
              aliases: ["miswak", "toothbrush", "teeth", "gums", "brushing", "arak", "hudhayfah", "tahajjud", "night prayer", "purify", "pleasing to the lord", "breath"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The siwak, a stick of arak wood chewed soft at one end, was always within the Prophet's reach, and rising from sleep was one of the times he reached for it. Hudhayfah said that whenever he got up at night to pray he scrubbed his mouth with it. Al-Bukhari records the same from Hudhayfah in plainer words, that he used to clean his mouth when he got up at night (Sahih al-Bukhari 889), and in one account of the night at Maymunah's he used the siwak before his wudu as well (Sahih Muslim 763)."),
                      .hadith("muslim:255a", cite: "Sahih Muslim 255a", arabic: 16...29, english: 0...17),
                      .text("'A'ishah reported what the Prophet said of the siwak itself, and the scholars count it among the most emphasised of his habits because of it: it cleans the mouth, and it pleases the Lord. A clean mouth is the worldly part, and any brush can claim it; the pleasure of Allah is the part that makes the stick an act of worship."),
                      .hadith("nasai:5", cite: "Sunan an-Nasa'i 5; graded sahih by al-Albani", arabic: 37...43, english: 13...27),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Keep a siwak where you sleep, on the bedside table or beside the pillow, so that it is the first thing your hand finds. A stick lasts for weeks: cut the frayed end back when it wears out, and keep it in its case or somewhere dry so that it does not go stale."),
                      .text("When you get up, before wudu, wet the end if you like and rub it over the teeth and gums, the outer surfaces and the inner, and over the tongue. The narrations give no count and no order; the aim is a clean mouth, and when it is clean you are done. Rinse the stick afterwards."),
                      .text("Use it again at the other times he reached for it: before each prayer, on coming home, and whenever the mouth has gone stale. The waking siwak is the one Hudhayfah singled out, and it pairs with the wudu that follows it, so the two become one movement, the stick and then the water."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration from 'A'ishah names the two rewards: a mouth made clean, and a Lord made pleased. The Prophet also said that were it not for the hardship on his people he would have ordered the siwak at every prayer (Sahih al-Bukhari 887), which the scholars read as the strongest recommendation short of a command. On waking it has a plain sense too: the mouth changes during sleep, and he met the Quran and the prayer with it clean."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars say the purpose is a clean mouth, so a toothbrush serves where no siwak is at hand; the siwak itself is what he used, and using it is the fuller keeping of the sunnah."),
                  ]),
              ]),
        .init(id: "waking-wash-hands", title: "Wash the hands before dipping them in water",
              summary: "On waking, wash the hands three times before they go into the vessel: no one knows where his hand spent the night",
              group: .waking,
              aliases: ["utensil", "basin", "bowl", "wudu", "ablution", "abu hurayrah", "sleep", "tap", "cleanliness", "hygiene", "rinse", "wrist"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Water in the Prophet's time was kept in a vessel, and wudu began by putting a hand in to scoop it. He told his Companions that a hand just out of sleep should not go into the water until it had been washed, and gave the reason plainly: a sleeper does not know where his hand has been. Abu Hurayrah narrated it, and Muslim's wording fixes the washing at three times."),
                      .hadith("muslim:278a", cite: "Sahih Muslim 278a", arabic: 33...53, english: 0...35),
                      .text("Al-Bukhari's report sets the same rule beside two others of cleanliness, rinsing the nose and using an odd number of stones, and ties the washing to the wudu that follows: the hand is washed before it enters the wudu water. The three times in Muslim's report are a detail that several of the narrators carried, as Muslim himself notes after the hadith, and the scholars keep to it."),
                      .hadith("bukhari:162", cite: "Sahih al-Bukhari 162", arabic: 37...56, english: 36...63),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you rise, pour water over the hands before they touch anything you will wash with: from a jug, or under the tap, letting the water run over them rather than cupping it first. Wash the whole hand to the wrist, three times, the right and then the left, as he began everything with the right."),
                      .text("Only then put the hand into the basin, or begin the wudu proper. If you make wudu from a tap the vessel is gone, but the reason the Prophet gave is not, so the scholars keep the washing: it is about the hand, not the bowl. Wash first, then start the wudu."),
                      .text("Keep the same habit after a daytime nap. The narration speaks of waking from sleep without limiting it, and most scholars apply it to any sleep, while some confine the stronger form of the rule to the night, when a hand is out of sight the longest. Either way, washing first costs a few seconds."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reason the Prophet gave is the whole of the matter: a person asleep has no idea where his hand has been, and so the water for worship is kept clear of whatever it may have touched. The scholars draw from it a rule that runs through the whole of wudu, that what purifies should itself be kept pure, and a habit of care that begins before the first splash of the day. It is the first washing of the morning, and the one he gave a reason for."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Most scholars count this washing as recommended; the Hanbalis hold it obligatory after the night's sleep, since the command is plain, and Ibn 'Uthaymin preferred their view. Washing first is the safe course either way."),
                  ]),
              ]),
        .init(id: "waking-istinthar", title: "Rinse the nose three times",
              summary: "On waking, draw water into the nose and blow it out three times: Shaytan spends the night in the nostrils",
              group: .waking,
              aliases: ["istinthar", "istinshaq", "sniff", "snuff", "devil", "satan", "wudu", "ablution", "abu hurayrah", "khayshum", "blow", "sinus"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Rinsing the nose, drawing water in and blowing it out, is part of every wudu. For the wudu after sleep the Prophet added a number and a reason. Abu Hurayrah reported that he told them to rinse the nose three times on waking, because Shaytan spends the night in the upper part of it. Al-Bukhari placed the same report in his chapter on Iblis and his soldiers (Sahih al-Bukhari 3295), and Muslim gives it in the Book of Purification."),
                      .hadith("muslim:238", cite: "Sahih Muslim 238", arabic: 26...49, english: 0...36),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("After washing the hands and rinsing the mouth, take water in the right hand, draw it up into the nose with a breath, and blow it out, the left hand to the nostrils. That is istinshaq and istinthar together, the drawing in and the blowing out, and it is the part of wudu this hadith is about."),
                      .text("On waking, do it three times, and do it well: draw the water up as far as is comfortable, unless you are fasting, when the scholars say to go gently so that none of it reaches the throat. The Prophet named the number for this wudu in particular, so the three are not the place to economise."),
                      .text("Then carry on with the wudu as usual, the face, the arms, the head and the feet. The nose rinse is where the wudu after sleep differs from any other, so it is the step to be deliberate about; the rest follows the ordinary pattern of his wudu, the same as at any other time of day."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration gives the reason itself: Shaytan spends the night in the nostrils, and the believer washes him out before anything else. The commentators allow that the words may be literal or a figure for the dirt that settles there overnight, and say that either way the believer does what he was told. The hadith also shows the pattern of his care: the parts of the body that sleep leaves least clean, the hands and the nose, are the ones he gave extra rules for."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Rinsing the nose belongs to every wudu: the Hanbalis count it among the obligatory parts and Ibn 'Uthaymin agreed, while most scholars call it a confirmed sunnah. The three times on waking are the Prophet's own instruction."),
                  ]),
              ]),
        .init(id: "waking-morning-adhkar", title: "The morning remembrances",
              summary: "The words he said when morning came: the kingdom is Allah's, and the master supplication for forgiveness",
              group: .waking,
              aliases: ["adhkar", "azkar", "sabah", "asbahna", "amsayna", "sayyid al-istighfar", "sayyidul istighfar", "istighfar", "evening", "ibn mas'ud", "shaddad", "dua"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Morning and evening are the two hinges of the day, and the Quran names them as times to glorify Allah and praise Him. The Prophet filled them with words of his own, said when morning came and again when evening came, which the Companions learned from him and the scholars later gathered under one name, the remembrances of morning and evening, adhkar al-sabah wal-masa:"),
                      .quran("30:17-18"),
                      .text("Ibn Mas'ud reported the evening form in full: the kingdom has entered the evening belonging to Allah, praise is His, there is no god but He, then a request for the good of the night and refuge from its evil, from laziness, from the evil of old age, and from the punishment of the Fire and the grave. The report ends by saying that in the morning he said the same, beginning instead with asbahna, we have entered the morning:"),
                      .hadith("muslim:2723b", cite: "Sahih Muslim 2723b", arabic: 25...117, english: 0...161),
                      .text("He also taught a shorter pair for the two ends of the day: Allahumma bika asbahna wa bika amsayna, wa bika nahya wa bika namut (O Allah, by You we enter the morning and by You the evening, by You we live and by You we die), with the evening form adding wa ilaykal-masir, and to You is the return (Sunan Ibn Majah 3868; graded sahih by al-Albani). And he named one supplication the master of all asking for forgiveness, to be said in the day and in the night, with a reward attached:"),
                      .hadith("bukhari:6306", cite: "Sahih al-Bukhari 6306", arabic: 28...110, english: 0...184),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("After Fajr, before the day's work takes you, say: Asbahna wa asbahal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir (we have entered the morning and the kingdom has entered it belonging to Allah; praise is for Allah; there is no god but Allah alone, without partner; His is the kingdom and His the praise, and He has power over all things). Then ask, as he did, for the good of this day and what follows it, and refuge from its evil, from laziness, the evil of old age, and the punishment of the Fire and the grave."),
                      .text("Then sayyid al-istighfar: Allahumma anta Rabbi, la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya wa abu'u laka bidhanbi, faghfir li, fa innahu la yaghfirudh-dhunuba illa anta (O Allah, You are my Lord, there is no god but You; You created me and I am Your servant, and I keep Your covenant and promise as far as I can; I seek refuge in You from the evil of what I have done; I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You)."),
                      .text("Repeat both in the evening, after 'Asr, with amsayna in place of asbahna (we have entered the evening) and the night in place of the day. The two sets are one habit with two ends, and the Prophet's own report pairs them; keeping the evening makes the morning easier to remember, and the reward of the master supplication is promised for both."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is spelled out in the hadith of Shaddad: whoever says the master supplication in the day, certain of it, and dies before evening is of the people of Paradise, and whoever says it in the night and dies before morning likewise. The morning words put the whole day under Allah's ownership before it begins, and ask Him for its good and against its harm. They take a minute, and the reward attached to one of them is stated in the Prophet's own words."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars place the morning remembrances between Fajr and sunrise and the evening ones between 'Asr and Maghrib, and say that whoever misses the time should still say them after it rather than drop them."),
                  ]),
              ]),
    ]

    // MARK: Wudu and cleanliness

    static let purificationEntries: [Entry] = [
        .init(id: "siwak-every-wudu", title: "The siwak with every wudu",
              summary: "Clean the teeth with the siwak when you make wudu and before every prayer.",
              group: .purification,
              aliases: ["miswak", "tooth-stick", "toothstick", "arak", "mouth", "brush", "istiyak", "pleases the lord", "purifies", "toothbrush"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The siwak, a twig of the arak tree used to clean the teeth, was never far from the Prophet. He used it on waking, on entering his house, and above all when he made wudu and rose to pray. He wanted it for his whole community, and held back from commanding it only because it would weigh on them."),
                      .hadith("bukhari:887", cite: "Sahih al-Bukhari 887", arabic: 31...46, english: 4...30),
                      .text("'A'ishah reported his own reason for it in one line:"),
                      .hadith("nasai:5", cite: "Sunan an-Nasa'i 5; graded sahih by al-Albani", arabic: 37...43, english: 13...27),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Keep a siwak where you make wudu and another in a pocket or bag for the masjid, so the sunnah costs nothing to remember. Chew or cut the tip until the fibres open into a small brush, trim it back when they fray, and soften a dried twig in water before using it."),
                      .text("Use it as part of the wudu itself. The scholars place it at the rinsing of the mouth, so that the mouth is cleaned as the face and hands are, and they say to begin on the right side of the mouth as he began everything on the right. Pass it along the teeth and the gums; no number of strokes is fixed, only a clean mouth."),
                      .text("Use it again when you stand to pray, whether the prayer is obligatory or voluntary, at home or in the masjid. Zayd ibn Khalid, a Companion, kept his siwak behind his ear the way a scribe keeps his pen and used it every time he rose to pray (Sunan Abi Dawud 47), so that it was never missed for want of a stick."),
                      .text("Reach for it too at the other times he did: on waking from sleep, which is the first thing Hudhayfah saw him do at night (Sahih al-Bukhari 245), and on coming into his house, which 'A'ishah said he began with (Sahih Muslim 253). The aim the narration names is a clean mouth and a Lord who is pleased, and both are served whenever it is used."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He wanted this for every prayer, and the only thing that stopped him commanding it was mercy for his followers. The narration names the two rewards: a mouth made clean for the words of the Quran and of dhikr, and a Lord who is pleased. A twig that costs nothing earns both, five times a day and more."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The wording with every wudu is carried by Malik and Ahmad, and al-Bukhari cites it in a chapter heading without its chain; his own text, quoted above, says with every prayer, and the scholars recommend the siwak at both. A fasting person may use it at any hour of the day: Ibn 'Uthaymin held that nothing sound restricts it to the morning."),
                  ]),
              ]),
        .init(id: "wudu-bismillah", title: "Bismillah before wudu",
              summary: "Say the name of Allah as you begin wudu, before the water touches your hands.",
              group: .purification,
              aliases: ["basmalah", "tasmiyah", "tasmiya", "ablution", "opening", "mention", "first words", "wudhu", "wudoo", "start"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Every act of worship has a door, and the door of wudu is the name of Allah. The Prophet tied wudu to it in words strong enough that the scholars still discuss what they require, and the least they require is that it is not left out. Abu Hurayrah reported them:"),
                      .hadith("abudawud:101", cite: "Sunan Abi Dawud 101; graded sahih by al-Albani", arabic: 18...43, english: 0...38),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("As you reach for the water, before it touches your hands, say Bismillah (in the name of Allah). It is said once, at the start, and said aloud enough to hear yourself; no sound narration gives a longer formula for wudu, and nothing is added to it."),
                      .text("If you forget it and remember partway through, say it then and carry on; the scholars do not ask you to begin again, and one who forgets is excused. If you make wudu where the toilet is, say it in your heart or under your breath: the name of Allah is not raised in such a place without need, and this need the scholars allow."),
                      .text("Then go on as he went on: wash the hands, rinse the mouth and nose, wash the face and arms, wipe the head and ears, wash the feet, the right before the left. The name at the start is the frame; everything after it is done in His name, and that is what makes a wash into worship."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration ties wudu itself to the name of Allah, and wudu is the key to the prayer. One word at the tap turns a wash into an act of worship and reminds the one making it that he is about to stand before his Lord. The scholars list it first among the sunnahs of wudu, and it is the easiest of them to keep."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars differ on whether the name of Allah at wudu is obligatory or recommended: Ibn Baz and the Hanbalis read the narration as a command, Ibn 'Uthaymin and the majority as a confirmed sunnah. All of them say the safe course is never to leave it."),
                  ]),
              ]),
        .init(id: "wudu-right-first", title: "Begin with the right",
              summary: "Wash the right hand and foot before the left in wudu, as he began everything honourable on the right.",
              group: .purification,
              aliases: ["tayammun", "right side", "yameen", "yamin", "shoes", "combing", "dressing", "ablution", "order", "sleeve", "toilet"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet began with the right in whatever was done with honour: putting on shoes, combing his hair, washing, dressing. In wudu that means the right hand before the left and the right foot before the left, the face being washed as one. 'A'ishah, who watched him at home, described it as a liking that ran through all of his affairs:"),
                      .hadith("bukhari:168", cite: "Sahih al-Bukhari 168", arabic: 20...34, english: 0...27),
                      .text("He also gave it as an instruction, not only a habit:"),
                      .hadith("abudawud:4141", cite: "Sunan Abi Dawud 4141; graded sahih by al-Albani", arabic: 13...29, english: 0...21),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Wash the right arm to the elbow three times, then the left; at the end, wash the right foot to the ankle, then the left. The mouth, nose, face and head are single parts with no right and left to order; the arms and feet are pairs, and the pair is where the sunnah lives. Keep the order every time until it needs no thought."),
                      .text("Carry the same rule out of the washroom. Put the right arm into a sleeve first and the right foot into a shoe first, and step into the masjid with the right foot. When you take shoes off, begin with the left, as he taught (Sahih al-Bukhari 5855); the scholars extend the same to garments and to leaving the masjid."),
                      .text("Eat and drink with the right hand, give and take with it, and keep the left for what the right is spared: cleaning after the toilet, and the left foot first into it. The foot into the toilet is not in a narration of its own; it is the scholars' reading of a Prophet who liked the right in all of his affairs."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The right is the side of honour in the Quran: the companions of the right, the record handed into the right hand. Beginning with it in wudu trains a person to carry that order into everything else; al-Nawawi explains that the right is used for what is honourable and the left for what is not, and that this is the rule 'A'ishah was describing. A habit of the hands becomes a habit of the heart."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Beginning on the right is recommended, not a condition: wudu in which the left was washed first is still valid by the agreement of the scholars, though a sunnah has been missed."),
                  ]),
              ]),
        .init(id: "wudu-thorough", title: "Perform wudu well, even when it is hard",
              summary: "Make wudu complete and careful, in the cold and in a hurry too; he called it the ribat.",
              group: .purification,
              aliases: ["isbagh", "isbaagh", "thorough", "makarih", "cold water", "sins", "ranks", "heels", "ablution", "guard duty", "frontier", "hardship"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Isbagh al-wudu is wudu made complete: every part reached, nothing hurried, nothing missed. The Prophet named it first among three things by which Allah wipes out sins and raises ranks, and he tied it to the moments it is hardest, al-makarih, the things a person dislikes: cold water, a cold dawn, tiredness, an aching body."),
                      .hadith("muslim:251a", cite: "Sahih Muslim 251a", arabic: 35...71, english: 6...62),
                      .text("He also described what the water carries away:"),
                      .hadith("muslim:244", cite: "Sahih Muslim 244", arabic: 45...115, english: 4...104),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Wash each part fully and in turn: the hands to the wrists, the mouth and the nose, the face from the hairline to the chin and from ear to ear, the arms to the elbows, the head and the ears, the feet to the ankles. Rub the water in rather than letting it run off, and pass wet fingers between the fingers and the toes."),
                      .text("Watch the places the water misses: the heels and the backs of the ankles, the elbows, the corners under the nails, the skin between the toes. He warned of the Fire for heels left dry (Sahih al-Bukhari 165), so it is these edges, not the broad surfaces, that separate complete from careless."),
                      .text("Keep the same care when it costs you: the cold water of a winter dawn, the five minutes you do not think you have, a crowded washroom before the prayer. This is the hardship the narration names, and the reward is attached to the difficulty, not given in spite of it. Make it complete, and no more than complete: three washes is the most, and water is not to be wasted."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He called it the ribat, the word for standing guard on a frontier, and in one narration said it twice. Wudu made well while the body would rather not is a small act of guard duty over the self, and the narrations name its pay: sins wiped out, ranks raised, and the sins of the eyes, the hands and the feet carried off with the last drop of water until a person comes out clean of them."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Hardship here means what is unwelcome, not what is harmful: one who fears that cold water will make him ill warms it, or where no safe water can be had makes tayammum, as the Quran allows the sick (4:43). Complete is not excessive; he made wudu with a mudd of water (Sahih al-Bukhari 201) and washed no part more than three times."),
                  ]),
              ]),
        .init(id: "wudu-testimony", title: "The testimony after wudu",
              summary: "Finish wudu with the shahadah; the eight gates of Paradise are opened for the one who says it.",
              group: .purification,
              aliases: ["shahada", "ashhadu", "dua after wudu", "dhikr", "supplication", "ablution", "la ilaha illallah", "tawwabin", "mutatahhirin", "witness", "uqbah", "umar"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When wudu is done, the Prophet taught words to say over it: the testimony of faith, the same words by which a person enters Islam, said again at the end of each wash. 'Uqbah ibn 'Amir came in late and caught the end of what he was saying; 'Umar, standing in front of him, said that what had come just before was better still, and repeated it:"),
                      .hadith("muslim:234a", cite: "Sahih Muslim 234a", arabic: 111...146, english: 116...171),
                      .text("A second narration of the same report gives the fuller wording:"),
                      .hadith("muslim:234b", cite: "Sahih Muslim 234b", arabic: 52...71, english: 21...54),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Finish the wudu properly first; the narration begins with wudu made complete, and the words are its seal, not a substitute for care. Then, with the water still on your face, say Ashhadu an la ilaha illallah wahdahu la sharika lah, wa ashhadu anna Muhammadan 'abduhu wa rasuluh (I bear witness that there is no god but Allah alone, with no partner, and I bear witness that Muhammad is His servant and His Messenger)."),
                      .text("Say it once, standing or as you are. The narration fixes no posture and no direction; what it asks for is wudu made well and the testimony said after it. Mean the words as you say them: 'Umar called this the better of the two, and it is the whole of the religion in a single breath."),
                      .text("Teach it to the children of the house along with the wudu itself, so that the words and the wash grow up together and every wudu for the rest of a life ends with the gates opened. Keep it in the same place each time, at the end, so that it is never crowded out by the hurry to pray."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward named is among the largest in the Sunnah for so short an act: the eight gates of Paradise opened, with the choice of which to enter. The scholars say the testimony crowns the wudu because the purity of the water is completed by the purity of tawhid; a person washed clean then declares the faith he is about to pray with."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Al-Tirmidhi adds to these words a short prayer for repentance and purity; al-Albani graded his narration sahih, while others, al-Tirmidhi himself among them, found its chain disturbed and graded it weak. The words quoted above from Sahih Muslim are what is certain, so the addition is not quoted here."),
                  ]),
              ]),
        .init(id: "wudu-two-rakahs", title: "Two rak'ahs after wudu",
              summary: "Pray two rak'ahs after each wudu, the deed that put Bilal's footsteps ahead of him in Paradise.",
              group: .purification,
              aliases: ["sunnat al-wudu", "sunnah of wudu", "prayer after ablution", "ablution", "nafl", "voluntary", "sandals", "uqbah", "guaranteed", "wajabat", "rakat", "rakaat"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Wudu is made for prayer, and the Prophet taught that two rak'ahs prayed straight after it, with the heart in them, carry a reward out of all proportion to their length. 'Uqbah ibn 'Amir came in from grazing the camels and caught these words of his:"),
                      .hadith("muslim:234a", cite: "Sahih Muslim 234a", arabic: 65...84, english: 42...70),
                      .text("Bilal kept this so steadily that the Prophet heard his footsteps in Paradise while both of them were still alive:"),
                      .hadith("bukhari:1149", cite: "Sahih al-Bukhari 1149", arabic: 27...74, english: 0...65),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you have finished wudu and said the testimony, do not walk away from it. Pray two rak'ahs wherever you are, at home or in the masjid, with whatever you know of the Quran after al-Fatihah; the narration fixes nothing about their length. Bilal did it by day and by night, whenever he had purified himself."),
                      .text("Pray them with the heart and the face turned to them, as the narration says: facing the qiblah with the body and facing the prayer with the mind, not with one eye on the door. Two short rak'ahs that are present are what is described; two long ones that are absent are not."),
                      .text("If you made wudu for an obligatory prayer that is about to begin, or for one of the regular sunnahs, pray that. The scholars say any prayer offered after wudu fulfils this sunnah, which is what Bilal's own words describe, and a separate pair is not required on top of it. The point is that no wudu goes unused."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Paradise becomes binding for him, the narration says, and Bilal's footsteps were heard there in his own lifetime for nothing more than this. The scholars draw from it that a small deed kept without fail outweighs a large one done once. 'Uqbah called the promise fine, and 'Umar said the testimony before it was finer still, so the two sunnahs stand together at the end of every wudu."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars differ on whether these two rak'ahs may be prayed in the times when voluntary prayer is otherwise held back, after Fajr and after 'Asr: Ibn Taymiyyah and Ibn 'Uthaymin allowed them as a prayer with a cause, and others wait for the time to pass."),
                  ]),
              ]),
        .init(id: "fitrah-grooming", title: "Trim the nails and moustache, let the beard grow",
              summary: "The acts of the fitrah: nails, moustache, armpits and pubic hair kept within forty nights; the beard left to grow.",
              group: .purification,
              aliases: ["fitra", "sunan al-fitrah", "clipping", "cutting", "shaving", "lihyah", "shaarib", "underarm", "hair removal", "hygiene", "circumcision", "khitan"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet counted certain acts of the body as the fitrah, the natural way that every prophet taught: the body kept clean and trimmed where hair and nails grow. He named five of them, and his Companions were given a limit on how long any of them could be left."),
                      .hadith("muslim:257a", cite: "Sahih Muslim 257a", arabic: 40...57, english: 0...32),
                      .hadith("muslim:258", cite: "Sahih Muslim 258", arabic: 29...47, english: 0...33),
                      .text("For the moustache and the beard he gave a direct instruction, and the reason with it:"),
                      .hadith("bukhari:5892", cite: "Sahih al-Bukhari 5892", arabic: 28...34, english: 7...22),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Clip the nails of the hands and the feet whenever they grow long, and never let forty nights pass. Nothing sound fixes a day of the week or an order of the fingers, so choose a rhythm you will keep and keep it, beginning with the right hand as he began on the right. Nails kept short keep the wudu complete, since water reaches what is under them."),
                      .text("Trim the moustache so that the lip shows and nothing hangs over it. The narrations say cut it short and cut it close, and the scholars allow either trimming the edge or cutting it very short, so long as it is not left to grow. Remove the hair of the armpits and the pubic hair on the same forty-night rhythm, by plucking, shaving or whatever means works."),
                      .text("Leave the beard to grow and do not shave it; the instruction is to let it be, and the reason he gave was to be unlike the idolaters. Keep it clean and combed, as he kept his own, so that leaving it is not the same as neglecting it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He called these acts the fitrah, the way human beings were made to be, and the Quran says that Allah loves those who keep themselves pure (2:222). A person who keeps them is clean for prayer, clean for company and distinct from those who let the body go or shape it against the fitrah. The forty nights are a mercy: a limit, not a target."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn Baz, Ibn 'Uthaymin and the Permanent Committee read the words leave the beard as a command that binds, and count shaving it a sin rather than a missed sunnah; Ibn 'Umar took what went beyond his fist at Hajj and 'Umrah, and the scholars differ on whether that was his own practice or a limit for everyone. No sound narration sets a day of the week or an order of the fingers for cutting the nails."),
                  ]),
              ]),
    ]

    // MARK: Dress, home and going out

    static let homeEntries: [Entry] = [
        .init(id: "home-bismillah", title: "Bismillah at the door and at the table",
              summary: "Mention Allah as you step into your home and as you begin to eat, and Shaytan finds no lodging and no supper.",
              group: .home,
              aliases: ["basmalah", "entering the house", "dhikr", "devil", "satan", "lodging", "supper", "evening meal", "jabir", "threshold"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Jabir heard the Prophet describe what happens at a front door. A man comes home and mentions Allah as he steps in, and again as he sits down to his food; the devil who followed him tells his companions that there is nowhere here to sleep tonight and nothing to eat. Leave Allah unmentioned at the door and Shaytan has a bed; leave Him unmentioned at the table and Shaytan has his supper as well."),
                      .hadith("muslim:2018a", cite: "Sahih Muslim 2018a", arabic: 33...73, english: 0...89),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("At the door, as your hand reaches the handle, say Bismillah (in the name of Allah). The narration asks only that Allah be mentioned and fixes no formula, so Bismillah is the least of it; the scholars count the greeting of salam to whoever is inside along with it, and the next page is about that greeting."),
                      .text("At the table, say Bismillah again before the first mouthful, and teach the children to say it with you. The two moments are named together in the narration, and the reward is tied to both: Shaytan is turned away from the bed by the first and from the supper by the second. The eating pages carry the rest of his table manners."),
                      .text("Make it the household's habit rather than one person's. Children who hear Bismillah at the door and at the table every day learn it without a lesson, and a guest who hears it learns what kind of house he has entered. The narration speaks of the man who comes in, but the mention of Allah is for everyone who enters and everyone who eats."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is in the narration itself: a home where Allah is mentioned at its threshold and at its table is a home Shaytan cannot lodge in or eat in. Two words at two moments decide whether the one who whispers quarrels and waste into a family has a place there for the night. Nothing in the day costs less or guards more."),
                  ]),
              ]),
        .init(id: "home-salam", title: "Greet your household",
              summary: "Say as-salamu 'alaykum to whoever is home as you walk in: the greeting the Quran sets at every door.",
              group: .home,
              aliases: ["salam", "assalamu alaykum", "peace", "greeting", "family", "entering", "wife", "children", "tahiyyah", "love one another", "spread the salam"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Quran tells the believer what to do on entering a house: greet those inside with the greeting Allah has blessed. The commentators read it to cover your own home, and an-Nawawi lists greeting your own household among the sunnahs of the salam on the strength of it, so a man who comes in greets his wife and children, and they greet him."),
                      .quran("24:61"),
                      .text("The Prophet set the greeting at the root of something larger. He named it as the one practice that makes believers love one another, and love as the thing without which faith is not whole, and faith as the door of Paradise:"),
                      .hadith("muslim:54a", cite: "Sahih Muslim 54a", arabic: 28...48, english: 12...82),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Say as-salamu 'alaykum (peace be upon you) as you step in, loud enough to be heard, before anything else. Let it be the first thing your family hears from you, ahead of the news of the day and ahead of any complaint; the ayah puts the greeting at the moment of entering, not after you have settled."),
                      .text("Greet whoever is there: your wife or husband, your parents, your children. The young are not left out; Anas passed a group of boys and greeted them, and said the Prophet used to do the same (Sahih al-Bukhari 6247). A child who is greeted every day learns to greet, and learns that he counts."),
                      .text("Answer in full when someone enters upon you: wa 'alaykumus-salam wa rahmatullah (and upon you be peace and the mercy of Allah). The Quran asks that a greeting be returned with a better one or at least its equal (4:86), so the reply is a sunnah of the house as much as the greeting is."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration ties the greeting to love, love to faith, and faith to Paradise, and it names the spreading of salam as the one thing he pointed to when he spoke of how believers come to love one another. The house is where the greeting is spread most often, several times a day for a lifetime, and the Quran calls it a greeting from Allah, blessed and good."),
                  ]),
              ]),
        .init(id: "leaving-home-dua", title: "The words on leaving home",
              summary: "Bismillah, tawakkaltu 'alallah, la hawla wa la quwwata illa billah at the door, and the devils stand aside.",
              group: .home,
              aliases: ["dua", "going out", "exit", "tawakkul", "trust in allah", "la hawla", "protection", "devil", "anas", "doorstep", "errand"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Anas reported a short sentence the Prophet taught for the moment of stepping out of the house. It names Allah, places the outing in His hands, and admits that there is no strength to do any of it except by Him. The reply, he said, comes at once, and the devils stand aside from the one who said it."),
                      .hadith("abudawud:5095", cite: "Sunan Abi Dawud 5095; graded sahih by al-Albani", arabic: 32...72, english: 4...74),
                      .text("At-Tirmidhi carries the same report from Anas with the shorter reply, sufficed and protected, and calls it hasan sahih (Sunan al-Tirmidhi 3426)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Say it on the threshold as you leave: Bismillah, tawakkaltu 'alallah, la hawla wa la quwwata illa billah (in the name of Allah; I have put my trust in Allah; there is no might and no power except by Allah). Once is the sunnah; the narration sets no number and asks for no raised voice."),
                      .text("Mean the middle clause. Tawakkul is the heart leaning on Allah while the hands do their work, so the words fit the walk to the masjid, the drive to work, the school run and the shops alike. Every going out is a step into what only He controls, and the sentence says so before the first step."),
                      .text("Pair it with the sunnahs of coming back: Bismillah and the greeting of salam at the door, on the two pages before this one. Leaving and arriving then both begin with His name, and the hours between them are held inside it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is spelt out in the narration: you are guided, defended and protected, and the devils move away, one of them asking how anyone can get at a man Allah has guided, defended and protected. One sentence at the door, and the one who leaves is under Allah's guard until he returns."),
                  ]),
              ]),
        .init(id: "right-shoe", title: "Right shoe on first, left off first",
              summary: "Right foot first into the shoes, left foot first out of them: he loved to begin with the right in all things.",
              group: .home,
              aliases: ["sandals", "footwear", "tayammun", "right hand", "right side", "left", "shoes", "dressing", "abu hurayrah", "aishah", "beginning with the right"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu Hurayrah reported the rule in the Prophet's own words: the right shoe goes on first and comes off last, so that the right foot is the first to be covered and the last to be bared. It is a small thing, and he put it into words so that it would be kept."),
                      .hadith("bukhari:5855", cite: "Sahih al-Bukhari 5855", arabic: 29...44, english: 4...48),
                      .text("'A'ishah, who saw him at home, set the shoes inside a wider habit:"),
                      .hadith("bukhari:168", cite: "Sahih al-Bukhari 168", arabic: 20...34, english: 0...27),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Putting shoes on: right foot first, then the left. Taking them off: left foot first, then the right. The right shoe is the first on and the last off, exactly as the narration puts it, so that the right foot is never the one left standing bare while the other is shod."),
                      .text("Carry the same order into the rest of dressing: the right sleeve first, the right leg of the trousers, the right side when combing, the right hand and foot in wudu. 'A'ishah's report says he liked beginning with the right in all his affairs, and the shoes are only the easiest place to start."),
                      .text("Keep the left for the opposite, as the scholars derive from the same habit: the left foot steps into the toilet, the left hand cleans, the left shoe comes off first. The right is for what is honoured and the left for what is not, and once the rule is in your feet it runs by itself."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("An-Nawawi called it a settled rule of the Shari'ah: whatever is of the kind of honouring and adorning is begun on the right, and its opposite on the left. A rule that lives in your shoes is remembered every day without effort, and every time it is kept for his sake it is an act of following him that costs nothing at all."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The same chapter forbids walking in one shoe: put on both or take off both (Sahih al-Bukhari 5856, Sahih Muslim 2097). The order is recommended, not required; a shoe put on the other way round first is no sin, only a sunnah missed."),
                  ]),
              ]),
        .init(id: "white-clothes", title: "Wear white",
              summary: "He told us to wear white, the best of our garments and the purest, and to shroud our dead in it.",
              group: .home,
              aliases: ["clothing", "garments", "dress", "colour", "shroud", "kafan", "ibn abbas", "samurah", "thiyab", "bayad", "modesty", "thawb"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Ibn 'Abbas reported his instruction about colour. White, he said, is among the best of our garments, and it serves at both ends of life: it is what the living are told to wear and what the dead are wrapped in. At-Tirmidhi adds that white is the shroud the people of knowledge preferred (Sunan al-Tirmidhi 994)."),
                      .hadith("abudawud:4061", cite: "Sunan Abi Dawud 4061; graded sahih by al-Albani", arabic: 30...39, english: 4...20),
                      .text("Samurah ibn Jundub carries the same instruction with its reason:"),
                      .hadith("ibnmajah:3567", cite: "Sunan Ibn Majah 3567; graded sahih by al-Albani", arabic: 34...40, english: 0...8),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Reach for white first when you have the choice: a white thawb, a white shirt, a white head covering. Keep it clean, since the reason the narration gives is that white is purer and cleaner, and white shows every mark; a grubby white garment keeps the colour and loses the point."),
                      .text("Wear it especially when you stand to pray and on Friday, when the Sunnah asks for your best clothes; a clean white garment answers both at once. Keep the cut and style to the custom of your land, since the instruction is about colour and cleanliness, not a particular dress."),
                      .text("Choose it for the dead too: the shroud is white cloth, as he instructed in the same breath. Keeping white in your own wardrobe keeps the thought of that last garment near. When a Muslim dies, see that the family has white cloth ready rather than something fine and coloured; the Sunnah asks for white, not for cost."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narrations give their own reasons: white is among the best of our garments, and it is purer and cleaner. The scholars count wearing white as recommended, and white as the sunnah of the shroud for every Muslim, and at-Tirmidhi records that it is what the people of knowledge preferred. A colour chosen for his sake is a sunnah worn all day."),
                  ]),
                  SignSection("A NOTE", [
                      .text("White is preferred, not required. He wore other colours too: al-Bara' saw him in a red suit and thought nothing finer (Sahih al-Bukhari 5848), and he addressed the people in a black turban (Sahih Muslim 1359). Any clean, modest garment in your land's custom is permitted; the limits are set by other narrations, silk and gold for men among them, not by colour."),
                  ]),
              ]),
        .init(id: "new-garment", title: "Thank Allah for a new garment",
              summary: "Name the new piece and say Allahumma lakal-hamdu anta kasawtanihi, asking its good and refuge from its harm.",
              group: .home,
              aliases: ["clothes", "dua", "new clothes", "dress", "praise", "abu sa'id", "kasawtanihi", "thawb", "shirt", "turban", "tubli", "gratitude"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu Sa'id al-Khudri watched him put on something new. He would say what it was, a shirt or a turban, and then thank Allah for clothing him with it, ask for its good and the good of what it was made for, and seek refuge from its evil and the evil of what it was made for."),
                      .hadith("abudawud:4020", cite: "Sunan Abi Dawud 4020; graded sahih by al-Albani", arabic: 17...57, english: 0...70),
                      .text("He also taught a shorter praise for any garment, new or old, and named its reward:"),
                      .hadith("abudawud:4023", cite: "Sunan Abi Dawud 4023; graded hasan by al-Albani", arabic: 64...89, english: 44...83),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("As you put on the new piece, name it: this shirt, this scarf, this coat. Then say Allahumma lakal-hamdu, anta kasawtanihi, as'aluka khayrahu wa khayra ma suni'a lahu, wa a'udhu bika min sharrihi wa sharri ma suni'a lahu (O Allah, Yours is the praise; You have clothed me with it; I ask You for its good and the good of what it was made for, and I seek refuge in You from its evil and the evil of what it was made for)."),
                      .text("For any garment you put on, say Alhamdu lillahil-ladhi kasani hadha ath-thawba wa razaqanihi min ghayri hawlin minni wa la quwwah (praise be to Allah who clothed me with this garment and provided it for me without any might or power of my own). The narration promises forgiveness for it, so it is worth the few seconds every morning."),
                      .text("When you see someone else in something new, say what the Companions said to one another: tubli wa yukhlifullah (may you wear it out and may Allah give you another in its place). The same report of Abu Sa'id carries their words, so the sunnah has a side for the wearer and a side for the friend."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The first words turn a purchase into a gift received: the praise goes to the One who clothed you, and the request admits that cloth can be used well or badly and asks that this piece be used well. The second narration names the reward outright: whoever says the praise is forgiven his earlier sins and his later ones. Dressing is a daily thing, and a daily dhikr rides on it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The longer words are for a garment put on new; the shorter praise is for any garment, every time. Neither is required, and the narrations fix no number; what matters is that the first wearing does not pass without thanks."),
                  ]),
              ]),
        .init(id: "privy-dua", title: "Entering and leaving the privy",
              summary: "A'udhu bika minal-khubuthi wal-khaba'ith before you go in, ghufranak as you come out.",
              group: .home,
              aliases: ["toilet", "bathroom", "lavatory", "khala", "dua", "refuge", "devils", "jinn", "forgiveness", "ghufranak", "left foot", "right foot"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Anas said that whenever the Prophet went in to relieve himself he asked Allah's protection first, from the khubth and the khaba'ith: the male and female devils, as the commentators read the two words, or every foul thing. The privy is a place the devils frequent, and he did not enter it without that guard."),
                      .hadith("bukhari:142", cite: "Sahih al-Bukhari 142", arabic: 14...33, english: 0...41),
                      .text("On coming out he said one word, 'A'ishah reported:"),
                      .hadith("abudawud:30", cite: "Sunan Abi Dawud 30; graded sahih by al-Albani", arabic: 29...38, english: 0...16),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Before you step in, at the door, say Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith (O Allah, I seek refuge in You from the devils, male and female). The scholars say the words belong outside: Allah's name is not mentioned inside a toilet, so say them before the threshold, and in the open, as you are about to begin."),
                      .text("Step in with the left foot and out with the right. This is the scholars' derivation from his love of beginning with the right in what is honourable and the left in its opposite, as the page on shoes shows; no narration about the privy itself gives it, so keep it, and know where it comes from."),
                      .text("As you come out, say ghufranak (Your forgiveness, that is: I ask for it). One word, every time, so that the privy is bracketed by a request for protection on the way in and a request for pardon on the way out; then wash the hands, since what comes next is the kitchen, the Quran or the prayer."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The first words put a wall between you and the devils in the one place where the Quran is not recited and Allah's name is not spoken. For ghufranak the scholars offer two readings: he asked pardon for the time inside without Allah's remembrance, or he had been given a blessing, the body relieved of what would harm it, too great to thank properly, and asked forgiveness for falling short."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The left foot in and the right foot out is the scholars' derivation from his habit of beginning with the right in honourable things (Sahih al-Bukhari 168), not a narration about the privy itself. The words themselves are recommended, not required, and they are said at every privy, at home, at work or in the open."),
                  ]),
              ]),
    ]

    // MARK: Prayer and the masjid (the adhan, the walk, the masjid and after the prayer)

    static let masjidEntries: [Entry] = [
        .init(id: "adhan-answer", title: "Answer the adhan",
              summary: "Repeat the call after the mu'adhdhin, send blessings on the Prophet, then ask Allah to grant him the wasilah.",
              group: .prayer,
              aliases: ["athan", "azan", "call to prayer", "muadhdhin", "muezzin", "wasilah", "wasila", "intercession", "shafa'ah", "la hawla", "salawat", "durood"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Five times a day the call goes out, and he gave those who hear it something to do with it. The listener answers the mu'adhdhin phrase by phrase, then sends blessings on the Prophet, then asks Allah to grant him the wasilah, a station in Paradise he hoped would be his. Al-Bukhari (611) and Muslim (383) carry the plain command to say what the mu'adhdhin says; Muslim's fuller report from 'Abdullah ibn 'Amr sets out the whole order and what it earns:"),
                      .hadith("muslim:384", cite: "Sahih Muslim 384", arabic: 43...90, english: 0...74),
                      .text("Jabir reported the words of that request, and the promise attached to them:"),
                      .hadith("bukhari:614", cite: "Sahih al-Bukhari 614", arabic: 29...54, english: 4...88),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the adhan begins, pause and answer each line as the mu'adhdhin finishes it, in his own words: Allahu akbar after his Allahu akbar, the two testimonies after his. At the two summons, hayya 'ala as-salah and hayya 'ala al-falah, say instead La hawla wa la quwwata illa billah (there is no power and no strength except through Allah), as 'Umar reported from him (Sahih Muslim 385)."),
                      .text("When the call ends, send blessings on the Prophet, for instance Allahumma salli 'ala Muhammad (O Allah, send blessings upon Muhammad), or the fuller salah you say in the last sitting of the prayer. He said that whoever sends one blessing on him is blessed by Allah ten times for it."),
                      .text("Then ask for the wasilah in the words he taught: Allahumma rabba hadhihi ad-da'wati at-tammah, was-salatil-qa'imah, ati Muhammadan al-wasilata wal-fadilah, wab'athhu maqaman mahmudan alladhi wa'adtah (O Allah, Lord of this perfect call and of the prayer about to be established, grant Muhammad the wasilah and the distinction, and raise him to the praised station You promised him)."),
                      .text("Finish with a dua of your own, in any language. The time from the adhan to the iqamah is one he named as a time when dua is not turned away, and it has its own page in this library; the answer to the adhan is the natural door into it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Both reports end at the same place: whoever asks for the wasilah for him has the Prophet's intercession on the Day of Resurrection, and 'Umar's report adds that whoever answers the final La ilaha illallah from his heart enters Paradise (Sahih Muslim 385). The scholars point out what it costs: a minute of attention five times a day, and the listener has sent blessings on the Prophet, asked on his behalf, and been promised his help on the day help matters most."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The wording in Sahih al-Bukhari 614 is the one to keep to. The addition some people make, wad-darajata ar-rafi'ah (and the high rank), has no basis in the narrations, as Ibn Hajar noted, and the scholars advise leaving it out."),
                  ]),
              ]),
        .init(id: "adhan-iqamah-dua", title: "Make dua between the adhan and the iqamah",
              summary: "The minutes between the two calls are a time when dua is not turned away: use them to ask.",
              group: .prayer,
              aliases: ["supplication", "du'a", "dua", "iqama", "iqamah", "athan", "azan", "accepted", "answered", "not rejected", "mustajab", "between the two calls"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Between the adhan and the iqamah there is a pause, long enough for people to arrive, make wudu and pray what they wish. He named it as one of the times when a dua is not turned back. Anas reported his words, and Abu Dawud and at-Tirmidhi (212) both record them with the same grading:"),
                      .hadith("abudawud:521", cite: "Sunan Abi Dawud 521; graded sahih by al-Albani", arabic: 26...31, english: 0...11),
                      .text("He prescribed nothing for the moment itself: no fixed words, no number, no posture. What he gave was the time and the promise, and he left the asking to the one who asks, in whatever words and whatever language he has."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("After you have answered the adhan and asked for the wasilah, stay where you are, in the masjid or at home, and turn to dua instead of your phone. Begin as the scholars advise every dua be begun: praise Allah, send blessings on the Prophet, then ask."),
                      .text("Ask in your own words and your own language, for yourself first and then for others: forgiveness, guidance, a good end, your parents, the Muslims. Nothing is prescribed for this moment; the duas that come from the Quran and the Sunnah are the best choice, but any sincere request belongs here."),
                      .text("If there is time, pray two rak'ahs in the gap: he said there is a prayer between every two calls, for whoever wishes (Sahih al-Bukhari 627), and the nearest a servant is to his Lord is in prostration, so ask there too (Sahih Muslim 482)."),
                      .text("When the iqamah is called, stop and stand for the prayer; the asking does not end there. The prayer has its own prostrations, where dua is nearest to being heard, and the remembrances that follow the salam have their own page in this library. Between them, a Muslim who keeps this sunnah is asking Allah for things many times a day."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He said the dua of this moment is not rejected. The scholars explain the pairing: the adhan has just been answered, the heart is turned toward the prayer, and the servant is waiting on Allah rather than on his own business, which is the state in which asking is heard. Five short windows a day, each carrying a promise, make a habit of turning to Allah for everything, large and small."),
                  ]),
                  SignSection("A NOTE", [
                      .text("A longer form of this report adds that the Companions asked what they should say and were told to ask Allah for well-being in this world and the next; that addition (Sunan al-Tirmidhi 3594) is graded munkar by al-Albani and is not relied on."),
                  ]),
              ]),
        .init(id: "walk-calmly", title: "Walk to prayer calmly",
              summary: "Walk with composure even when the iqamah has been called; pray what you catch and complete the rest.",
              group: .prayer,
              aliases: ["sakinah", "tranquillity", "tranquility", "dignity", "waqar", "running", "hurry", "haste", "steps", "footsteps", "congregation", "jama'ah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The natural thing, when the iqamah sounds and you are still outside, is to run. He told the Companions not to. The walk to the masjid is itself worship, and he wanted it done with the composure the prayer asks for, whatever is missed by it. Abu Hurayrah reported:"),
                      .hadith("bukhari:636", cite: "Sahih al-Bukhari 636", arabic: 40...56, english: 4...36),
                      .text("In another report he gave the reason the walk is worth keeping calm: it is counted step by step, after a wudu done well and with nothing in view but the prayer, and the credit goes on while he sits waiting for it:"),
                      .hadith("bukhari:647", cite: "Sahih al-Bukhari 647", arabic: 29...92, english: 4...143),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Make wudu at home, carefully, and leave early enough that the iqamah does not catch you on the road. He counted a thorough wudu, many steps to the masjid and waiting for the next prayer among the things by which Allah wipes out sins and raises ranks (Sahih Muslim 251a)."),
                      .text("Walk at an ordinary pace, with sakinah (composure) and waqar (dignity): no running, no pushing at the door, no calling out to the imam to wait. If the iqamah is called while you are on the way, keep the same pace. He said that a person who is on his way to the prayer is already in prayer (Sahih Muslim 602b)."),
                      .text("When you arrive, join the imam in whatever he is doing, without bowing on the way to the row. When Abu Bakrah bowed before he reached the row, the Prophet said: may Allah increase your eagerness, but do not do it again (Sahih al-Bukhari 783). When the imam gives the salam, stand and complete the rak'ahs you missed."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Every step is a degree raised and a sin removed, and the walker is counted as being in prayer before he has said the takbir. Ibn 'Uthaymin draws out the sense of the command: a person who runs arrives breathless and distracted, and has traded the calm of the prayer for a rak'ah he might have caught anyway. Composure on the way is how the prayer is entered in the state it should be prayed in."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Reaching the imam while he is still bowing catches that rak'ah, with the majority of scholars, so what is completed afterwards is whole rak'ahs. Ibn 'Uthaymin allowed walking a little faster, short of running and without loss of dignity, for someone about to miss the rak'ah."),
                  ]),
              ]),
        .init(id: "masjid-enter", title: "Enter with the dua and pray two rak'ahs before sitting",
              summary: "Ask for the doors of mercy on the way in, pray two rak'ahs before you sit, and ask for His bounty on the way out.",
              group: .prayer,
              aliases: ["tahiyyat al-masjid", "tahiyyatul masjid", "greeting the mosque", "mosque", "entering", "leaving", "right foot", "doors of mercy", "rahmatik", "fadlik", "nafl", "abu qatadah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("He gave the masjid a way in and a way out. On entering, a request for the doors of Allah's mercy; on leaving, a request for His bounty, since the one going out is heading back to the business of earning. And whoever comes in does not sit until he has prayed two rak'ahs, which the scholars call tahiyyat al-masjid, the greeting of the masjid."),
                      .hadith("muslim:713a", cite: "Sahih Muslim 713a", arabic: 38...56, english: 0...36),
                      .hadith("bukhari:444", cite: "Sahih al-Bukhari 444", arabic: 34...42, english: 4...17),
                      .text("He held people to it. When Abu Qatadah came in and sat down among the people, because he saw the Prophet sitting, he was asked what had stopped him from praying two rak'ahs first (Sahih Muslim 714b). On a Friday, in the middle of the khutbah, he told a man who had just sat down to stand and pray (Sahih Muslim 875a)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Step in with the right foot, which the scholars derive from his liking to begin with the right in everything (Sahih al-Bukhari 168), and say: Allahumma-ftah li abwaba rahmatik (O Allah, open for me the doors of Your mercy). He also sought refuge on entering: A'udhu billahil-'Azim wa bi-wajhihil-karim wa sultanihil-qadim min ash-shaytanir-rajim (I seek refuge in Allah the Mighty, in His noble face and His eternal authority, from the accursed Shaytan), after which Shaytan says he is protected from me for the rest of the day (Sunan Abi Dawud 466; graded sahih by al-Albani)."),
                      .text("Before you sit, pray two rak'ahs, at any hour. If the iqamah has been called, join the obligatory prayer instead; it stands in for the greeting, as does the regular sunnah you came to pray, such as the two rak'ahs before Fajr. The greeting is for the one who means to sit; a person passing through the masjid is not asked for it."),
                      .text("Pray them without hurry, and then sit, read or wait for the prayer. If you came in while the khutbah is being given, pray them briefly and sit; that is the one time he had a man stand up again to do it, so the khutbah is no reason to leave them."),
                      .text("On the way out, step out with the left foot and say: Allahumma inni as'aluka min fadlik (O Allah, I ask You of Your bounty). Mercy is what the masjid is entered for; fadl, bounty, is what is sought outside it, in the day's work, so both are asked for from the same Lord."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The two duas frame the visit, and the two rak'ahs keep the masjid a place of prayer in a person's habits rather than a place to sit: whoever enters it has prayed before he has done anything else. Ibn Baz counted the greeting of the masjid a confirmed sunnah for whoever enters to sit, at any time of day, and the question put to Abu Qatadah shows how closely the Prophet watched it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The majority of scholars hold the two rak'ahs a confirmed sunnah, not an obligation; a few held them obligatory, which is one more reason not to leave them. Ibn Taymiyyah, Ibn Baz and Ibn 'Uthaymin prayed them even after Fajr and after 'Asr, since they have a cause; other scholars leave them out at those two times."),
                  ]),
              ]),
        .init(id: "after-salah-dhikr", title: "The remembrances after the prayer",
              summary: "Istighfar, the tahlil, then thirty-three of each: the words he said once the salam was given.",
              group: .prayer,
              aliases: ["adhkar", "dhikr", "tasbih", "tahmid", "takbir", "tahlil", "subhanallah", "alhamdulillah", "allahu akbar", "astaghfirullah", "foam of the sea", "la ilaha illallah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("He did not stand up the moment the salam was given; a set of remembrances followed every obligatory prayer, and the Companions passed them on word for word. Thawban described what came first: forgiveness asked for three times, then a few words of praise."),
                      .hadith("muslim:591", cite: "Sahih Muslim 591", arabic: 24...48, english: 0...34),
                      .text("Warrad, the scribe of al-Mughirah ibn Shu'bah, kept what his master dictated for Mu'awiyah:"),
                      .hadith("bukhari:844", cite: "Sahih al-Bukhari 844", arabic: 19...74, english: 6...108),
                      .text("And he set a count of praise for his Companions to keep, with what it earns:"),
                      .hadith("muslim:597a", cite: "Sahih Muslim 597a", arabic: 45...91, english: 0...73),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("As soon as you have given the salam, say Astaghfirullah (I ask Allah for forgiveness) three times, then: Allahumma anta as-salam wa minka as-salam, tabarakta ya dhal-jalali wal-ikram (O Allah, You are Peace and from You is peace; blessed are You, Owner of majesty and honour). It takes a few seconds, and it is the first thing he said."),
                      .text("Then the tahlil: La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. Allahumma la mani'a lima a'tayt, wa la mu'tiya lima mana't, wa la yanfa'u dhal-jaddi minkal-jadd (none has the right to be worshipped but Allah alone, without partner; His is the dominion and His the praise, and He is able to do all things. O Allah, none can withhold what You give, none can give what You withhold, and the fortune of the fortunate is no use to him against You)."),
                      .text("Then count on your fingers: Subhanallah (glory be to Allah) thirty-three times, Alhamdulillah (praise be to Allah) thirty-three times, Allahu akbar (Allah is greatest) thirty-three times, and as the hundredth: La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. He told the women who asked him to count on their fingers, for the fingers will be questioned and made to speak (Sunan Abi Dawud 1501; graded hasan by al-Albani)."),
                      .text("He also told Mu'adh never to leave, after each prayer, Allahumma a'inni 'ala dhikrika wa shukrika wa husni 'ibadatik (O Allah, help me to remember You, to thank You and to worship You well), and told 'Uqbah ibn 'Amir to recite the three last surahs after every prayer (Sunan Abi Dawud 1522 and 1523; both graded sahih by al-Albani). Add them once the first three are a habit."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The hundred earn forgiveness of sins though they be like the foam of the sea, and it was the poor of the Muhajirin, who could not match the rich in charity, whom he first taught them as the way to catch up (Sahih Muslim 595a). The scholars add that these adhkar are the seal of the prayer: a person leaves it praising Allah rather than rushing for the door, and five times a day a few minutes are spent in the words the Prophet himself chose."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The counts vary between sound reports: thirty-three of each here, ten of each in Sahih al-Bukhari 6329. The scholars say each form is a sunnah and that varying between them is better than fixing on one."),
                  ]),
              ]),
        .init(id: "sit-until-sunrise", title: "Stay seated until the sun rises",
              summary: "After Fajr he kept his place in dhikr until the sun was up, then prayed two rak'ahs.",
              group: .prayer,
              aliases: ["ishraq", "duha", "sunrise", "shuruq", "fajr", "dhikr", "morning", "hajj and umrah", "reward", "musalla", "place of prayer", "jabir ibn samurah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Jabir ibn Samurah sat with him often, and this is what he saw after Fajr: the Prophet stayed where he had prayed until the sun rose, and only then stood. Around him the Companions talked of the days before Islam and laughed, and he smiled."),
                      .hadith("muslim:670a", cite: "Sahih Muslim 670a", arabic: 44...69, english: 27...83),
                      .text("Anas reported the reward he attached to the one who keeps that seat in remembrance of Allah and then prays:"),
                      .hadith("tirmidhi:586", cite: "Sunan al-Tirmidhi 586; graded hasan by al-Albani", arabic: 28...61, english: 5...46),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("After the remembrances that follow the prayer, stay in your place rather than heading for the door. The morning remembrances belong here, the words he said at the start of each day, and so does the Quran; the narration's reward is for the one who sits remembering Allah, so it is not a matter of simply staying put."),
                      .text("Keep to remembrance, recitation and dua, and keep the talk light if there is company; his Companions talked and laughed around him, and he smiled. The scholars count reading the Quran and sitting in a lesson of knowledge as remembrance for this purpose."),
                      .text("When the sun has risen, wait until it is well up, about a quarter of an hour, since he forbade prayer from after Fajr until the sun has risen (Sahih al-Bukhari 581); then pray two rak'ahs. The scholars count them as the Duha prayer at its earliest time, which some call the prayer of Ishraq."),
                      .text("If you cannot stay, because work or sleep is calling, keep what you can: the adhkar after the prayer and the morning remembrances, and go. The sunnah is the sitting and nothing in it is obligatory; the reward named is for the complete form, and whatever is kept of it is kept for Allah."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("A reward like that of a hajj and an 'umrah, complete, complete, complete, for the first half hour or so of the day spent in Allah's remembrance. The scholars read it as a mercy for the ordinary Muslim, who cannot travel to Makkah every morning but can keep his seat. The sitting itself is in Sahih Muslim; the reward is what the hasan report in at-Tirmidhi adds to it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The narration speaks of Fajr in congregation; the scholars say a woman who prays Fajr at home and keeps her place in dhikr until the sun rises may hope for the same reward. Two of the five graders in this app's collection call the Tirmidhi report weak; al-Albani, Ahmad Shakir and Bashar 'Awwad call it hasan, and that is the grading followed here."),
                  ]),
              ]),
    ]

    // MARK: Prayer and the masjid: the voluntary prayers

    static let voluntaryEntries: [Entry] = [
        .init(id: "rawatib", title: "The twelve rak'ahs around the obligatory prayers",
              summary: "Four before Dhuhr, two after it, two after Maghrib, two after 'Isha, two before Fajr: a house in Paradise.",
              group: .prayer,
              aliases: ["rawatib", "sunan rawatib", "sunnah prayers", "nafl", "nawafil", "voluntary", "mu'akkadah", "confirmed", "umm habibah", "rakat", "jannah", "before and after"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Around the five obligatory prayers the Prophet kept a set of voluntary rak'ahs so steadily that the Companions could count them. The scholars call them the sunan rawatib, the regular sunnahs, and the fullest count is twelve in a day and night. Umm Habibah heard him promise a house in Paradise for them and never left them afterwards; the narrators who passed her report down said the same of themselves."),
                      .hadith("muslim:728a", cite: "Sahih Muslim 728a", arabic: 58...87, english: 0...37),
                      .text("Al-Tirmidhi's report from her gives the breakdown, prayer by prayer:"),
                      .hadith("tirmidhi:415", cite: "Sunan al-Tirmidhi 415; graded sahih by al-Albani", arabic: 38...65, english: 0...42),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Pray four rak'ahs before Dhuhr, after the adhan and before the iqamah, and two after it. The two after are the easiest of all to keep: they are prayed where you already are, before you leave the masjid or, better, once you are home."),
                      .text("After Maghrib pray two rak'ahs, and after 'Isha two. Ibn 'Umar noted that the Prophet prayed both of these pairs in his house, so they belong to the moment you return home, before the evening takes over; and they are short enough that time is never the excuse."),
                      .text("Pray two rak'ahs before Fajr, between the adhan and the obligatory prayer. These are the pair he guarded most closely and they have an article of their own; keep them light, and never let the iqamah find you still in them."),
                      .text("Keep the count steady rather than large. Umm Habibah's answer to the promise was not to add to the twelve but never to leave them, and the narrators after her said the same. The same twelve every day, as part of each prayer rather than an occasional effort, is the sunnah."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration names the reward outright: a house built in Paradise for whoever prays these twelve in a day and night. He said that when the deeds are reckoned the voluntary prayers complete whatever was lacking in the obligatory ones (Sunan al-Tirmidhi 413; graded sahih by al-Albani), and the scholars add that a fixed pair around each prayer means the obligatory prayer is never begun cold or left in a hurry: there is a prayer before it to settle the heart and one after it to seal it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn 'Umar counted ten from the Prophet, with two before Dhuhr rather than four (Sahih al-Bukhari 1180). Both reports are sound: he prayed two before Dhuhr at times and four at others, so the twelve of Umm Habibah's report add a second pair before Dhuhr, and the scholars give the fuller count as the one to aim for."),
                  ]),
              ]),
        .init(id: "fajr-two", title: "The two rak'ahs before Fajr",
              summary: "Light and short, and never left: better than the world and everything in it.",
              group: .prayer,
              aliases: ["sunnah of fajr", "sunnat al-fajr", "dawn", "subh", "raghibah", "al-kafirun", "al-ikhlas", "nawafil", "regular", "brief", "iqamah", "'a'ishah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Of all the voluntary prayers, the two short rak'ahs between the Fajr adhan and the obligatory prayer were the ones the Prophet guarded most. 'A'ishah, who saw his prayer at home for years, said so plainly, and she passed on what he said they were worth."),
                      .hadith("muslim:725a", cite: "Sahih Muslim 725a", arabic: 29...35, english: 0...13),
                      .hadith("bukhari:1163", cite: "Sahih al-Bukhari 1163", arabic: 25...41, english: 0...21),
                      .text("He kept them light, so brief that she wondered whether he had recited al-Fatihah at all:"),
                      .hadith("bukhari:1165", cite: "Sahih al-Bukhari 1165", arabic: 62...80, english: 0...24),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Pray them after the Fajr adhan and before the obligatory prayer: two rak'ahs with one tasleem. If you pray Fajr in the masjid, pray them at home before you set out, as he did, or in the masjid before the iqamah; either way they come before Fajr, never after it."),
                      .text("Keep them brief. Recite al-Fatihah and a short surah in each rak'ah: he recited Say, O disbelievers (al-Kafirun) in the first and Say, He is Allah, One (al-Ikhlas) in the second (Sahih Muslim 726). Their lightness is part of the sunnah, so do not stretch them into a long recitation."),
                      .text("Do not let them go when you are rushed. The obligatory prayer is the one that cannot be missed, but these two are the pair he was most careful never to leave, so give them their few minutes in the Fajr routine rather than treating them as an extra for days with time to spare."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He weighed two short rak'ahs against the whole world and everything in it, and the rak'ahs won. The scholars observe that a sunnah he kept this closely, at home and on his journeys, is the first voluntary prayer to secure: it costs a few minutes, it opens the day with prayer before the obligation, and no other voluntary prayer carries a comparison like the one he gave it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Once the iqamah is called, do not begin them: he said that when the prayer is called there is no prayer but the obligatory one (Sahih Muslim 710). On a journey the regular sunnahs may be left, but the scholars note that he kept these two and Witr wherever he was."),
                  ]),
              ]),
        .init(id: "sunnah-at-home", title: "Pray the voluntary prayers at home",
              summary: "The best of a person's prayer is in his house, except the obligatory: keep the sunnahs for home.",
              group: .prayer,
              aliases: ["house", "bayt", "nafl", "nawafil", "graves", "qubur", "masjid", "mosque", "zayd ibn thabit", "ibn 'umar", "sincerity", "family"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("In Ramadan the Prophet set up a small enclosure of matting in the masjid and prayed in it at night. Men gathered to pray behind him. After a few nights he stayed inside, and in the morning he told them why: the voluntary prayer belongs in the house. Muslim's version adds that he feared it would be made obligatory on them (Sahih Muslim 781)."),
                      .hadith("bukhari:731", cite: "Sahih al-Bukhari 731", arabic: 68...81, english: 74...98),
                      .text("He put the same rule as a command, with a warning folded into it:"),
                      .hadith("bukhari:432", cite: "Sahih al-Bukhari 432", arabic: 23...30, english: 5...20),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Pray the obligatory prayers in the masjid, in congregation, as he did and told the men to do. The rule here is for the voluntary prayers, and it does not move the obligatory ones out of the masjid; the narration itself names them as the exception."),
                      .text("Take the regular sunnahs home. The two after Maghrib and the two after 'Isha are the easiest, since you are going home anyway, and Ibn 'Umar remembered the Prophet praying both pairs in his house (Sahih al-Bukhari 1180). The two before Fajr can be prayed at home before you leave for the masjid."),
                      .text("Pray Witr and the night prayer at home, which is where he prayed them. The enclosure of mats in Ramadan was the exception, and he ended it himself; Tarawih in the masjid is the one night prayer the scholars keep in congregation, on the example of the Companions."),
                      .text("Let the house have prayer in it. A house with no voluntary prayer is what he likened to a grave, so give one corner of it to prayer, where the family's sunnahs are prayed and the children see them prayed and learn them without being taught."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration gives the ranking: a person's prayer in his house is the best of his prayer, apart from the obligatory. The scholars give the reasons. At home the voluntary prayer is out of sight and so nearer to sincerity, the house is filled with prayer and remembrance, and the family learns prayer by watching it. The warning not to make houses graves says the same from the other side: a grave is a place where no one prays."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The exceptions the scholars make are the prayers the Sunnah ties to the masjid or to a congregation: the obligatory prayers, Tarawih, the Eid prayers, the greeting of the masjid, and the two rak'ahs after tawaf. Every other voluntary prayer is better at home."),
                  ]),
              ]),
        .init(id: "duha", title: "The Duha prayer",
              summary: "Two rak'ahs or more in the forenoon, once the sun is well up: the charity due on every joint, paid at once.",
              group: .prayer,
              aliases: ["salat al-duha", "dhuha", "chasht", "ishraq", "mid-morning", "awwabin", "penitent", "joints", "sadaqah", "abu dharr", "abu hurayrah", "three counsels"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Each morning, the Prophet said, a charity is owed for every joint in the body. Words of remembrance pay it, enjoining good and forbidding wrong pay it, and so does one short prayer in the forenoon, after the sun is up and before Dhuhr: the prayer of Duha."),
                      .hadith("muslim:720", cite: "Sahih Muslim 720", arabic: 45...77, english: 0...88),
                      .text("Abu Hurayrah counted it among three things the Prophet told him never to leave:"),
                      .hadith("bukhari:1178", cite: "Sahih al-Bukhari 1178", arabic: 25...42, english: 0...37),
                      .text("Its best hour is late in the forenoon, when the ground has grown hot:"),
                      .hadith("muslim:748a", cite: "Sahih Muslim 748a", arabic: 50...54, english: 18...36),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Wait until the sun has fully risen and stands clear of the horizon, about a quarter of an hour after sunrise by the scholars' reckoning. The time then runs until shortly before Dhuhr; it is not prayed at sunrise itself, nor when the sun stands at its height just before Dhuhr."),
                      .text("Pray two rak'ahs at least. 'A'ishah said he prayed four and added what Allah willed (Sahih Muslim 719), and on the day Makkah was opened he prayed eight (Sahih al-Bukhari 357). Two are enough to pay the day's charity; four and eight are also reported from him."),
                      .text("If you can choose the hour, choose the later one. He called it the prayer of those who turn back to Allah and placed it when the young camels feel the heat of the ground: mid to late morning rather than straight after sunrise. A pair prayed early still counts; the later pair is better."),
                      .text("Tie it to something you already do. Abu Hurayrah held to it for the rest of his life; a pair of rak'ahs after breakfast, or before leaving for work or school, keeps it in the day without any planning, and a habit that costs two minutes is one that survives."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is stated as a debt paid: the charity every joint of the body owes each morning is covered by two rak'ahs of Duha. The Prophet counselled it to Abu Hurayrah as one of three things to hold to until death, and named it the prayer of those who turn back to Allah. The scholars count it among the most rewarding of the voluntary prayers for how little it costs."),
                  ]),
                  SignSection("A NOTE", [
                      .text("'A'ishah said she never saw the Prophet pray Duha, though she prayed it herself (Sahih al-Bukhari 1177), while she also reported that he prayed four (Sahih Muslim 719). The scholars reconcile the two: she did not see what he did away from her house, and he left some voluntary acts at times so they would not be taken for obligations."),
                  ]),
              ]),
        .init(id: "witr", title: "Never leave Witr",
              summary: "The odd rak'ah that closes the night's prayer: one at least, after 'Isha and before Fajr.",
              group: .prayer,
              aliases: ["wajib", "hanafi", "qunut", "last prayer", "tahajjud", "three rak'ahs", "jabir", "ibn 'umar", "abu hurayrah", "before sleeping", "end of the night", "salat al-layl"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Witr is the odd rak'ah that closes a night's prayer: one on its own, or three, five or more, always an odd number. The Prophet prayed it every night and told the Companions to make it the last prayer of their night."),
                      .hadith("bukhari:998", cite: "Sahih al-Bukhari 998", arabic: 24...28, english: 4...11),
                      .hadith("muslim:752b", cite: "Sahih Muslim 752b", arabic: 34...38, english: 0...10),
                      .text("He also gave a rule for when to pray it, early for those who fear sleep and late for those who will wake:"),
                      .hadith("muslim:755a", cite: "Sahih Muslim 755a", arabic: 27...51, english: 0...67),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Pray Witr any time after 'Isha and before Fajr. The least is one rak'ah; three is the common habit, prayed as two with a tasleem and then one more, or as three with a single tashahhud at the end; larger odd numbers are reported from him."),
                      .text("Decide at bedtime. If you doubt you will wake before Fajr, pray Witr before you sleep, as the Prophet counselled Abu Hurayrah (Sahih al-Bukhari 1178). If you are confident of waking, leave it for the end of the night, which he said is witnessed and is better."),
                      .text("If you pray Witr early and then wake with time to pray more, pray in pairs and leave Witr where it was. He said there are not two Witrs in one night (Sunan al-Tirmidhi 470; graded sahih by al-Albani), so the scholars rule that it is not repeated; the early Witr stands."),
                      .text("If sleep or illness takes the night, make it up by day: when that happened to him he prayed twelve rak'ahs in the daytime, an even number (Sahih Muslim 746). The scholars say the same of a missed Witr: pray it by day as an even number, three becoming four."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He did not let Witr go, at home or on a journey, and he commanded the Companions to end their night with it; the scholars grade it the most emphasised of the voluntary prayers alongside the two before Fajr, and the Hanafis count it as a duty. A single rak'ah is enough to keep it, so there is no night on which it cannot be prayed."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Witr is a confirmed sunnah with the majority of scholars and wajib with the Hanafis; either way his command was to keep it. Supplication (qunut) in its last rak'ah is sunnah, not a condition, and the words he taught al-Hasan are the ones to learn (Sunan al-Tirmidhi 464, graded sahih)."),
                  ]),
              ]),
        .init(id: "night-prayer", title: "The night prayer",
              summary: "The best prayer after the obligatory: rise for part of the night, pray two by two, and close with Witr.",
              group: .prayer,
              aliases: ["qiyam", "qiyam al-layl", "tahajjud", "salat al-layl", "last third", "descends", "nuzul", "sahar", "before dawn", "istighfar", "eleven rak'ahs", "tarawih"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Quran told the Prophet to rise for part of the night and pray, and he did, standing until his feet swelled (Sahih al-Bukhari 1130). For his followers it is voluntary, and he ranked it first among all the voluntary prayers."),
                      .quran("17:79"),
                      .hadith("muslim:1163a", cite: "Sahih Muslim 1163a", arabic: 34...46, english: 0...23),
                      .text("He told the Companions what happens in the last third of every night:"),
                      .hadith("bukhari:1145", cite: "Sahih al-Bukhari 1145", arabic: 35...60, english: 5...68),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Begin small. Two rak'ahs and then Witr, prayed before you sleep or after you wake, is the night prayer; the amount is not fixed, and what you can keep up matters more than what you can manage once. 'A'ishah said he never prayed more than eleven rak'ahs, in Ramadan or outside it (Sahih al-Bukhari 1147)."),
                      .text("Pray two by two, with a tasleem after each pair, and end with a single rak'ah of Witr; that is how he described it to a man who asked (Sahih al-Bukhari 990). Recite slowly, as the Quran says, and let the prayer be long or short as you can bear."),
                      .text("If you can, rise in the last third of the night: that is the hour he said our Lord descends to the nearest heaven and asks who is calling Him, asking of Him and seeking His forgiveness. Set an alarm for a little before Fajr, pray, and ask; then stay up for the Fajr sunnah and Fajr."),
                      .text("If you sleep through it, do not count the night lost. When sleep or pain kept him from his night prayer he made it up by day (Sahih Muslim 746), and he said that whoever sleeps past his nightly portion and makes it up between Fajr and Dhuhr is written as having done it at night (Sahih Muslim 747)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .quran("51:17-18"),
                      .text("The narrations give it the first rank among voluntary prayers and place it in the hour when Allah Himself calls for those who will ask. The scholars add that it is the prayer with the fewest witnesses, and so the surest sign of sincerity, and that the command to rise at night came at the very beginning of the Prophet's mission, before the five prayers were made obligatory: it was the training of the Companions before it was their reward."),
                  ]),
                  SignSection("A NOTE", [
                      .text("It can be as little as two rak'ahs and Witr: he said the night prayer is two by two and that one rak'ah makes odd what came before (Sahih al-Bukhari 990). The deeds Allah loves most are the ones kept up, even if small (Sahih al-Bukhari 6464, Sahih Muslim 783), so choose a portion you will keep every night over a long one you will abandon."),
                  ]),
              ]),
    ]

    // MARK: Eating and drinking

    static let foodEntries: [Entry] = [
        .init(id: "eat-bismillah-right", title: "Bismillah, the right hand, and what is nearest",
              summary: "Name Allah, eat with the right hand, and take from the side of the dish nearest you.",
              group: .food,
              aliases: ["bismillah", "tasmiyah", "right hand", "yamin", "nearest", "dish", "manners", "adab", "etiquette", "umar ibn abi salamah", "shaytan", "left hand"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("'Umar ibn Abi Salamah was a boy in the Prophet's household, the son of his wife Umm Salamah, and at a meal his hand wandered about the shared dish. The Prophet corrected him with three short instructions, and 'Umar said he ate that way for the rest of his life. They are the whole etiquette of the table in one sentence: name Allah, use the right hand, take what is in front of you."),
                      .hadith("bukhari:5376", cite: "Sahih al-Bukhari 5376", arabic: 24...63, english: 0...62),
                      .text("The right hand is not a courtesy of his time and place. He gave the reason for it himself:"),
                      .hadith("muslim:2020a", cite: "Sahih Muslim 2020a", arabic: 43...69, english: 0...42),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Say Bismillah, in the name of Allah, as you reach for the food and before the first mouthful. That one word is the wording the narrations give for a meal; say it audibly enough that those eating with you are reminded to say it too."),
                      .text("Eat and drink with the right hand, and pass food and drink with it too. The left may help, holding the bread while the right tears it, but the mouthful itself goes to the mouth with the right hand, and so does the cup."),
                      .text("Take from the part of the dish nearest you. Reaching across the plate or picking through it for the best piece is exactly what the boy was corrected for. The scholars allow one exception: a platter of several kinds, such as fruit, where you may reach for the kind you want."),
                      .text("Pass the habit on the way he did. He did not lecture the boy or shame him; one gentle sentence at the dish was enough, and 'Umar remembered it for the rest of his life. A child at your table will learn it the same way."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The name of Allah over food shuts Shaytan out of the meal. The Prophet said that Shaytan counts as lawful for himself any food over which the name of Allah has not been mentioned (Sahih Muslim 2017), and that when a man names Allah on entering his house and on eating, Shaytan tells his companions there is no lodging and no supper for them there (Sahih Muslim 2018). The right hand marks the believer apart from Shaytan, who eats and drinks with his left."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The right hand is more than good manners. The Prophet forbade eating with the left, and a man who refused his instruction out of pride could never again raise his right hand to his mouth (Sahih Muslim 2021); so Ibn Baz and Ibn 'Uthaymin held eating and drinking with the right hand to be obligatory for anyone able to, and the left to be allowed only for a real excuse."),
                  ]),
              ]),
        .init(id: "forgot-bismillah", title: "If you forget bismillah",
              summary: "The words that recover a meal begun without the name of Allah, said the moment you remember.",
              group: .food,
              aliases: ["bismillahi awwalahu wa akhirahu", "forgot", "forgetting", "forgetful", "remember", "tasmiyah", "beginning and end", "awwalihi", "akhirihi", "bedouin", "aishah", "blessing"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("A meal is meant to open with the name of Allah, and everyone forgets it now and then. The Prophet did not leave the forgetful with a meal that was simply lost. He gave words that put the name of Allah over the whole of it, the part already eaten and the part still to come, and 'A'ishah passed them on."),
                      .hadith("abudawud:3767", cite: "Sunan Abi Dawud 3767; graded sahih by al-Albani", arabic: 37...69, english: 0...42),
                      .text("'A'ishah also described what the missing word costs. He was eating with six of his Companions when a Bedouin came in and finished the food in two mouthfuls:"),
                      .hadith("tirmidhi:1858b", cite: "Sunan al-Tirmidhi 1858b; graded sahih by Darussalam", arabic: 5...36, english: 0...43),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("The moment you notice that the meal began without it, say Bismillahi awwalahu wa akhirahu, in the name of Allah at its beginning and its end. Say it then and there, between one mouthful and the next, not once the plate is empty."),
                      .text("It does not matter how far in you are, a first bite or nearly the last. The words are made for exactly this: they cover what has gone before as well as what is left, so that nothing of the meal is outside the name of Allah."),
                      .text("Say it so that those eating with you hear it. It reminds them to check their own start, and the narration of the Bedouin shows that one forgotten bismillah can cost the whole table the blessing of its food, not only the one who forgot."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The blessing of food is tied to the name of Allah over it, not to how much there is. The Bedouin finished in two mouthfuls a meal that seven were sharing, because he did not name Allah, and the Prophet said that one word would have been enough for them all. The remedy spares the believer a meal that Shaytan shared through a lapse of memory, and it teaches a wider lesson: a sunnah forgotten is to be recovered, not written off."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Both wordings are reported and either may be said: Bismillahi awwalahu wa akhirahu, as Abu Dawud has it, or Bismillahi fi awwalihi wa akhirihi, as al-Tirmidhi has it (Sunan al-Tirmidhi 1858)."),
                  ]),
              ]),
        .init(id: "eat-together", title: "Eat together, and from the edge",
              summary: "Gather over the food, name Allah on it, and eat from the sides: the blessing is in company, not in amount.",
              group: .food,
              aliases: ["together", "company", "gather", "sharing", "share", "edges", "sides", "middle", "barakah", "blessing", "satisfied", "food of two"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Some Companions told the Prophet that they ate and were not satisfied. He did not ask what they were eating; he asked whether they ate apart from one another. They said yes, and his remedy was to gather over the food and to mention the name of Allah on it."),
                      .hadith("abudawud:3764", cite: "Sunan Abi Dawud 3764; graded hasan by al-Albani", arabic: 18...56, english: 0...45),
                      .text("He also taught that a shared dish stretches further than its measure:"),
                      .hadith("bukhari:5392", cite: "Sahih al-Bukhari 5392", arabic: 27...44, english: 0...23),
                      .text("And he taught how to eat from the dish once it is shared: from the sides, leaving the middle, where the blessing comes down."),
                      .hadith("tirmidhi:1805", cite: "Sunan al-Tirmidhi 1805; graded sahih by al-Albani", arabic: 26...39, english: 5...26),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Eat with your household rather than each at a different hour. Where the family can sit to one meal at one time, that meal is the sunnah, and most of the other sunnahs of the table follow from it: the name of Allah said together, the dish shared, the thanks said together."),
                      .text("Begin with the name of Allah over the food, and say it so the others hear and remember. The narration ties the blessing to the two things at once, the gathering and the name; one without the other is not the remedy he gave."),
                      .text("When the food is in one dish, take from the edge in front of you and leave the middle until last. The heap at the centre is where the blessing comes down, and the narration says to eat around it, not out of it."),
                      .text("Welcome one more than you planned for. The food of two is enough for three and the food of three for four, so a guest who arrives as the dish is set down is not a problem of quantity. Make room and share what is there."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration of the Companions who ate and were not filled names the cause, eating apart, and the cure, eating together with the name of Allah on the food. The blessing is in the gathering and the name, not in the amount: the food of two is enough for three, and of three for four. The scholars draw from these reports the temper of a Muslim table, shared and generous, with Allah's name over it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Eating alone is not forbidden; the sunnah is to prefer company when it is at hand. Eating from the edge is about a shared dish: on a plate of your own there is no middle to leave for others."),
                  ]),
              ]),
        .init(id: "lick-fingers", title: "Lick the fingers and pick up what falls",
              summary: "Nothing of the meal is wasted: fingers licked, the dish wiped, a dropped morsel cleaned and eaten.",
              group: .food,
              aliases: ["lick", "licking", "fingers", "three fingers", "morsel", "dropped", "fallen", "wipe", "plate", "waste", "barakah", "jabir"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet ate with three fingers, and when he finished he licked them before anything else (Sahih Muslim 2034). He told the Companions to do the same, to wipe the dish clean, and to pick up a morsel that fell, clean it and eat it. The reason he gave is the same every time: no one knows which part of his food holds the blessing."),
                      .hadith("muslim:2033b", cite: "Sahih Muslim 2033b", arabic: 17...56, english: 0...60),
                      .text("Ibn 'Abbas carried the shortest form of it:"),
                      .hadith("bukhari:5456", cite: "Sahih al-Bukhari 5456", arabic: 16...35, english: 0...23),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you have finished, lick your fingers before you reach for the napkin or the tap. The narration of Ibn 'Abbas allows someone else to do it, a child or a spouse who does not mind, but the fingers are not to be wiped with the food still on them."),
                      .text("Wipe the dish and take up what is left in it rather than scraping it into the bin. Anas said the Prophet commanded them to wipe the bowl clean, and gave the same reason: you do not know where in your food the blessing is."),
                      .text("If a morsel falls, pick it up, remove whatever has stuck to it, and eat it. Leaving it is leaving it for Shaytan, in the Prophet's own words, and the morsel on the floor may be the part of the meal that carried its blessing."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reason is in the narration itself: no one knows in which part of his food the blessing lies, so the last trace on the fingers or the morsel on the floor may be the part that was blessed. The habit also leaves nothing for Shaytan, who attends a person at everything he does, his meals included (Sahih Muslim 2033d). The scholars see in it a refusal to treat any of Allah's provision as beneath notice."),
                  ]),
                  SignSection("A NOTE", [
                      .text("If a fallen morsel cannot be cleaned, the scholars say to give it to an animal rather than throw it away, so that it is still not left for Shaytan."),
                  ]),
              ]),
        .init(id: "praise-after-eating", title: "Praise Allah after eating",
              summary: "Alhamdulillah with the last mouthful: the praise that pleases Allah, and the fuller words that earn forgiveness.",
              group: .food,
              aliases: ["alhamdulillah", "hamd", "praise", "thanks", "gratitude", "shukr", "after a meal", "finished", "forgiven", "at'amani", "razaqanihi", "dua after eating"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("A meal ends as it began, with Allah named. The praise after food is one of the smallest deeds of the day, said in a breath between the table and whatever comes next, and the Prophet described how Allah receives it:"),
                      .hadith("muslim:2734a", cite: "Sahih Muslim 2734a", arabic: 35...60, english: 0...18),
                      .text("He also taught a fuller form, with a reward attached to it:"),
                      .hadith("tirmidhi:3458", cite: "Sunan al-Tirmidhi 3458; graded hasan by al-Albani", arabic: 27...60, english: 0...54),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you finish eating or drinking, say Alhamdulillah, all praise is for Allah. Say it after a glass of water as readily as after a feast; the narration names the single mouthful and the single drink, not the banquet, so no meal is too small for it."),
                      .text("When you remember it, say the fuller words: Alhamdu lillahil-ladhi at'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah, all praise is for Allah who fed me this and provided it for me without any power or strength of my own."),
                      .text("Mean it as you say it. The words put the meal down to Allah's provision and not to your wage or your cooking, and holding that in mind as you speak them is what makes the praise thanks rather than a formula said over the plates."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Allah is pleased with a servant who eats a mouthful and praises Him for it, or drinks and praises Him for it. That is the reward the first narration names, and the second adds the forgiveness of past sins for the fuller words. A habit that costs a breath, kept at every meal, becomes a day in which Allah's pleasure is sought several times over."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The one word Alhamdulillah fulfils the sunnah on its own; the fuller wording is a hasan narration to add when you remember it, not a condition. The widely printed wording that ends wa ja'alana muslimin (Sunan Abi Dawud 3850) is graded weak by al-Albani."),
                  ]),
              ]),
        .init(id: "drink-sips", title: "Drink in three breaths, outside the vessel",
              summary: "He drank in three draughts, breathing between them with the cup away from his mouth, never into it.",
              group: .food,
              aliases: ["three sips", "sips", "gulps", "draughts", "breathe", "breathing", "blow", "blowing", "vessel", "cup", "thirst", "anas"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet did not drain a drink in one pull. Anas, who served him for ten years, said he took it in three, breathing between them, and Anas took up the habit himself:"),
                      .hadith("muslim:2028a", cite: "Sahih Muslim 2028a", arabic: 26...38, english: 0...23),
                      .text("The breath is taken with the cup moved from the mouth, because he forbade breathing into the vessel, and blowing into it:"),
                      .hadith("tirmidhi:1888", cite: "Sunan al-Tirmidhi 1888; graded sahih by al-Albani", arabic: 17...31, english: 0...13),
                      .text("A man asked him about something floating in the drink, and said he could not be satisfied in one breath. The answer to both was practical:"),
                      .hadith("tirmidhi:1887", cite: "Sunan al-Tirmidhi 1887; graded hasan by al-Albani", arabic: 39...65, english: 9...47),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Take the drink in three draughts rather than one. Pause after each, take the cup from your lips to breathe, then return to it. The breath is taken between the cup and you, never over the drink, exactly as he told the man who could not finish in one."),
                      .text("Never breathe into the cup or blow across the drink. If it is too hot, wait for it to cool; if there is something floating in it, pour that off, as he told the man who asked, rather than blowing it aside."),
                      .text("Keep the rest of the manner of the table with it: the right hand to hold the cup, Bismillah before the first draught, Alhamdulillah after the last. A drink is a meal in miniature and carries the same sunnahs as the plate does."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Anas reports the Prophet's own reason: drinking this way is more thirst-quenching, healthier and more wholesome (Sahih Muslim 2028b), and Anas took it up himself. The ban on breathing or blowing into the cup keeps whatever leaves the mouth out of what another may drink after you, so a cup passed round a gathering stays clean."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The narration's words, three breaths in the vessel, mean three breaths in the course of the one drink, each with the cup taken from the mouth; read with the prohibition, they cannot mean breathing into it. The three is his habit, not a rule: a drink finished in two draughts, or in one, is no sin."),
                  ]),
              ]),
        .init(id: "no-faulting-food", title: "Never fault a dish",
              summary: "He never criticised food put before him: if he liked it he ate, and if not he left it without a word.",
              group: .food,
              aliases: ["criticise", "criticize", "complain", "complaint", "fault", "dislike", "taste", "cooking", "cook", "host", "abu hurayrah", "lizard"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu Hurayrah, who ate at the Prophet's table and beside him at others', summed up his manner with food in one line. Food that was served was never spoken ill of, whether it was plain or poorly made; it was eaten, or quietly left."),
                      .hadith("bukhari:5409", cite: "Sahih al-Bukhari 5409", arabic: 15...29, english: 0...27),
                      .text("Muslim has the same report with one more detail: if he did not want it, he kept silent (Sahih Muslim 2064d). When a roasted lizard was set before him at Maymunah's house he drew back his hand, and when Khalid ibn al-Walid asked whether it was forbidden he said no, it was not found in the land of his people and he found himself disinclined to it; Khalid ate it as he watched (Sahih al-Bukhari 5537)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When food is put in front of you, look for what you can eat of it. If it is to your liking, eat it and thank the one who made it; if only part of it is, eat that part and say nothing of the rest."),
                      .text("If it is not to your liking, leave it without remarking on it. The salt, the texture, the choice of dish: none of it needs saying, to the cook or to the table. Silence is what he did, and silence is enough."),
                      .text("If you are asked directly, answer honestly and gently, the way he answered Khalid: not forbidden, only not a food of his people's land, so he had no taste for it. A stated preference is not a fault found, and the question deserved a true answer."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The scholars read this as mercy for the one who cooked and gratitude to the One who provided. Food is Allah's provision, and to fault it is to fault a gift; and the cook has usually done what they could. An-Nawawi notes that what is forbidden here is faulting the food itself, as too salty or too thin or undercooked, which is a different thing from declining a lawful dish one does not care for, as the Prophet did with the lizard."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Warning a host that a dish has gone off or will harm someone is advice, not fault-finding; what the narration rules out is disparaging good food over taste."),
                  ]),
              ]),
        .init(id: "host-dua", title: "Pray for your host",
              summary: "A guest leaves a dua behind him: for blessing in what the host was given, and for forgiveness and mercy.",
              group: .food,
              aliases: ["host", "guest", "hospitality", "invitation", "invited", "allahumma barik lahum", "razaqtahum", "aftara indakum", "fasting", "angels", "abdullah ibn busr", "sa'd ibn ubadah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When the Prophet had eaten at someone's house he did not leave with thanks alone. 'Abdullah ibn Busr tells of a visit to his father's house: a meal, then dates, then a drink passed to the one on his right, and at the end his father holding the rein of the Prophet's mount and asking him to pray for them:"),
                      .hadith("muslim:2042a", cite: "Sahih Muslim 2042a", arabic: 78...99, english: 97...138),
                      .text("At the house of Sa'd ibn 'Ubadah, who brought him bread and olive oil, he prayed in other words:"),
                      .hadith("abudawud:3854", cite: "Sunan Abi Dawud 3854; graded sahih by al-Albani", arabic: 28...47, english: 21...48),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you have eaten at someone's table, pray for them before you leave, and in their hearing: Allahumma barik lahum fima razaqtahum waghfir lahum warhamhum, O Allah, bless them in what You have provided them, forgive them and have mercy on them."),
                      .text("Or use the other reported words, the ones he said at the house of Sa'd ibn 'Ubadah: Aftara 'indakumus-sa'imun, wa akala ta'amakumul-abrar, wa sallat 'alaykumul-mala'ikah, may the fasting break their fast with you, may the righteous eat your food, and may the angels pray for you."),
                      .text("Either wording is the sunnah, and so is a sincere prayer for the host in your own words when neither comes to mind. What matters is that the one who fed you is not left without a prayer from the one he fed."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The guest's dua is how hospitality is repaid in the sunnah. The host spent of what Allah gave him, and the dua asks that what he has be blessed, that he be forgiven and shown mercy, and in the second wording that his table be one where the fasting break their fast and the righteous eat, with the angels praying for him. Nothing a guest could carry to the door is worth more, and it costs him nothing."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The second dua is for any host who fed you, in Ramadan or out of it: the mention of the fasting is a prayer that such people eat at his table, not a sign that the words belong to iftar alone."),
                  ]),
              ]),
        .init(id: "drink-sitting", title: "Drink sitting",
              summary: "He disapproved of drinking standing, and still drank Zamzam on his feet: sitting is better, standing is allowed.",
              group: .food,
              aliases: ["standing", "sitting", "sit down", "stand up", "zamzam", "qa'iman", "forbade", "disliked", "makruh", "permitted", "ali", "anas"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Anas reported that the Prophet forbade drinking while standing, and the Companions who passed it on took it seriously: when Qatadah asked Anas what he thought of eating standing, Anas said that was worse still (Sahih Muslim 2024b). The report itself is short and plain:"),
                      .hadith("muslim:2024a", cite: "Sahih Muslim 2024a", arabic: 10...20, english: 0...11),
                      .text("And yet he was seen drinking standing, at the well of Zamzam:"),
                      .hadith("bukhari:5617", cite: "Sahih al-Bukhari 5617", arabic: 14...22, english: 0...7),
                      .text("'Ali did the same in front of people at the gate of the mosque courtyard in Kufah, and gave his reason:"),
                      .hadith("bukhari:5615", cite: "Sahih al-Bukhari 5615", arabic: 13...44, english: 0...42),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Sit to drink when you can. A glass of water at home, tea with a guest, the bottle after prayer: the sunnah is to take it seated, on a chair or on the floor, not on the way out of the door."),
                      .text("When sitting is not practical, at a tap in a crowd, at Zamzam, on the move, drink standing and do not be uneasy about it. He did, and 'Ali drank standing in front of people precisely to show that he had seen the Prophet do it."),
                      .text("Keep the rest of the manner either way: the right hand, Bismillah before, three draughts with the breath taken outside the cup, Alhamdulillah after. Sitting is one sunnah of the drink among several, and the others do not lapse when it does."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The scholars reconcile the two sets of reports by reading the prohibition as disapproval and his own standing as proof of permission. An-Nawawi wrote that the prohibition is one of dislike, that the Prophet's drinking while standing shows it is permitted, and that sitting is the better and more complete way. So a believer who sits has done the better thing, and one who stands has done nothing wrong."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Most scholars, Ibn Baz and Ibn 'Uthaymin among the later ones, hold that drinking standing is permitted and sitting is better. A few read the prohibition strictly and take the Zamzam report as an exception for need, so sitting is also the safer habit."),
                  ]),
              ]),
    ]

    // MARK: Speech and company

    static let companyEntries: [Entry] = [
        .init(id: "spread-salam", title: "Give salam first, and spread it",
              summary: "Greet every Muslim you meet, known or not, and answer a greeting with the same words or better.",
              group: .company,
              aliases: ["assalamu alaikum", "as-salamu alaykum", "greeting", "greet", "peace", "afshu", "ifsha", "tahiyyah", "wa alaykum", "rider", "hello", "stranger"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The greeting of Islam is a dua: peace be upon you, and Allah's mercy, and His blessings. The Prophet made it the first thing between two Muslims who meet, and he tied it to the love between believers, and that love to faith, and faith to Paradise. He gave it to those he knew and those he did not, and he taught who should begin."),
                      .hadith("muslim:54a", cite: "Sahih Muslim 54a", arabic: 28...47, english: 12...82),
                      .text("Asked which part of Islam is best, he put the greeting beside feeding people, and widened it to strangers:"),
                      .hadith("bukhari:6236", cite: "Sahih al-Bukhari 6236", arabic: 18...42, english: 0...29),
                      .text("He also set an order for who greets whom, so that nobody waits on the other:"),
                      .hadith("bukhari:6232", cite: "Sahih al-Bukhari 6232", arabic: 32...41, english: 4...33),
                      .text("The Quran commands the answer: a greeting is returned with a better one, or at least with its like."),
                      .quran("4:86"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Greet first, before anything else is said: as-salamu 'alaykum (peace be upon you). Add wa rahmatullahi wa barakatuh (and Allah's mercy and His blessings) when you can. Three men greeted the Prophet in turn, the first with the short form and the last with the full one, and he counted ten, twenty and thirty rewards (Sunan Abi Dawud 5195, graded sahih by al-Albani)."),
                      .text("Give it to Muslims you know and Muslims you do not: the stranger in the street, the man at the next till, the family passing you in the masjid. He named greeting the unknown as one of the best things in Islam, so a greeting kept for friends is only half the sunnah."),
                      .text("When you are unsure who should begin, follow his order: the one riding greets the one walking, the one walking greets the one sitting, the few greet the many, and the young greet the old (Sahih al-Bukhari 6231). If both of you begin at once, nothing is lost."),
                      .text("Answer every greeting with the same words or more: wa 'alaykumus-salam wa rahmatullahi wa barakatuh (and upon you be peace, and Allah's mercy and His blessings). Beginning the greeting is a sunnah; returning it is a duty the ayah commands, and one of the rights a Muslim has over a Muslim (Sahih Muslim 2162), so never let a salam go unanswered."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He made spreading the greeting the road to loving one another, loving one another the condition of faith, and faith the condition of Paradise, all in one breath. A greeting costs nothing, and it is a dua for the one you meet. Said to everyone, it tells a stranger that he is your brother before you know his name."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The greeting of salam is begun with Muslims: the Prophet told the Companions not to be the first to greet the Jews and Christians with it (Sahih Muslim 2167), and to answer their greeting with wa 'alaykum (Sahih al-Bukhari 6258). Other courteous words, a good morning or a how are you, are open to everyone, as the scholars say."),
                  ]),
              ]),
        .init(id: "smile", title: "Smile",
              summary: "Meet your brother with a cheerful face: he counted a smile as charity.",
              group: .company,
              aliases: ["smiling", "cheerful", "face", "tabassum", "sadaqah", "charity", "countenance", "kindness", "jarir", "wajh"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Companions remembered his face. Jarir said that from the day he became Muslim the Prophet never saw him without smiling at him (Sahih al-Bukhari 6089), and 'Abdullah ibn al-Harith said he had seen nobody who smiled more (Sunan al-Tirmidhi 3641, graded sahih by al-Albani). He taught that this costs nothing and counts for something: a smile in your brother's face is written as charity, and no small kindness is to be looked down on."),
                      .hadith("tirmidhi:1956", cite: "Sunan al-Tirmidhi 1956; graded sahih by al-Albani", arabic: 38...78, english: 0...77),
                      .hadith("muslim:2626", cite: "Sahih Muslim 2626", arabic: 37...47, english: 6...26),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Let your face be the first thing you give. When you meet a Muslim, smile before you speak: at home in the morning, at the door of the masjid, across a counter. The narration says a smile in the face of your brother, so look at the person, not past him."),
                      .text("Keep it on the days it is hard. The second narration is addressed to exactly that moment: do not belittle any good deed, even meeting your brother with a cheerful face. When you are tired or worried, the smile is most clearly a charity, because it is then that it costs something."),
                      .text("Pair it with the greeting and the handshake. A salam given with a smile is two sunnahs in one breath, and it is how the Prophet met Jarir every time he saw him; the people closest to you, who see your face most, have the first claim on it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Charity is usually something taken from what you have. He widened it to something you simply are: a cheerful face turned to another Muslim is charity, with charity's reward, though it takes from nothing. The same narration lists guiding a lost man and lifting a stone from the road, deeds anyone can do, and the smile stands first among them."),
                  ]),
              ]),
        .init(id: "handshake", title: "Shake hands",
              summary: "Take your brother's hand when you meet; two Muslims who do so are forgiven before they part.",
              group: .company,
              aliases: ["musafahah", "handshake", "greeting", "hand", "meeting", "forgiven", "forgiveness", "embrace", "hug", "companions", "anas"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The handshake was the Companions' way of meeting, and Anas, who served the Prophet for ten years, confirmed it when Qatadah asked him. The Prophet tied it to forgiveness: two Muslims who meet and take each other's hand are forgiven before they let go."),
                      .hadith("abudawud:5212", cite: "Sunan Abi Dawud 5212; graded sahih by al-Albani", arabic: 28...38, english: 4...19),
                      .hadith("bukhari:6263", cite: "Sahih al-Bukhari 6263", arabic: 8...21, english: 0...22),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Give the greeting, then your hand. The salam comes first and the handshake follows it; that is the order the Companions kept, and the two together are how a Muslim met a Muslim in Madinah, whether at the door of the masjid or in the market."),
                      .text("Shake the hand of every Muslim you meet in person, friend or stranger, and not only on Eid. The promise is for any two Muslims who meet, so the handshake belongs to the ordinary meeting at the shop or the school gate as much as to the feast."),
                      .text("Meet with the forgiveness in mind. Two people who have taken each other's hand have been promised forgiveness before they part; let that make the handshake a warm one, with a good word or a dua to go with it, rather than a formality got through on the way to something else."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Forgiveness is the heaviest thing a person needs, and he hung it on one of the lightest acts there is: two hands meeting. The narration does not ask for a long visit or a special word, only that two Muslims meet and shake hands, and they are forgiven before they separate. It also keeps the believers close in the plainest way, by touch."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The handshake is a man's with a man and a woman's with a woman: the Prophet took the women's pledge by word alone and told them he did not shake hands with women (Sunan Ibn Majah 2874, graded sahih by al-Albani), so a man gives his hand only to a woman who is his mahram. Zubair 'Ali Za'i grades the forgiveness narration weak where al-Albani and most graders call it sahih."),
                  ]),
              ]),
        .init(id: "sneeze", title: "Yarhamukallah to the one who sneezes",
              summary: "The sneezer praises Allah, the hearer asks mercy for him, and the sneezer prays for the hearer in turn.",
              group: .company,
              aliases: ["sneeze", "sneezing", "alhamdulillah", "yarhamukallah", "yahdikumullah", "tashmit", "bless you", "utas", "mercy", "cold", "praise"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("A sneeze has three sets of words in the Sunnah, one for each side. The one who sneezes praises Allah; whoever hears him asks Allah's mercy for him; and he answers with a prayer for their guidance. The Prophet gave the whole exchange in one narration, and in another he showed that the answer is for the one who praised Allah, by leaving a man who had not praised Him unanswered."),
                      .hadith("bukhari:6224", cite: "Sahih al-Bukhari 6224", arabic: 35...57, english: 5...58),
                      .hadith("bukhari:6225", cite: "Sahih al-Bukhari 6225", arabic: 19...50, english: 0...59),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you sneeze, say alhamdulillah (praise be to Allah), loud enough to be heard. He said that Allah loves the sneeze (Sahih al-Bukhari 6226), and the praise is what the rest of the exchange hangs on: the hearer answers the praise, not the sneeze."),
                      .text("When you hear someone praise Allah after a sneeze, say yarhamukallah (may Allah have mercy on you). He called this a right on every Muslim who hears it (Sahih al-Bukhari 6226) and counted it among the five rights a Muslim has over his brother (Sahih Muslim 2162)."),
                      .text("If you were the one who sneezed, answer the answer: yahdikumullah wa yuslih balakum (may Allah guide you and set your affairs right). The exchange ends with the sneezer praying for the ones who prayed for him, so three duas have passed in the time a sneeze takes."),
                      .text("Leave the one who did not praise Allah unanswered, as the Prophet did, and tell him why if he asks; that is how the Companions learnt the rule. The scholars say it is good to remind him gently to praise Allah, so that he can be answered."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The exchange is three duas in a row, each side praying for the other: praise from the sneezer, mercy asked for him, guidance asked for those who asked. A sneeze is nothing, and he turned it into a reason for Muslims to pray for one another several times a day. It is also one of the rights a Muslim has over a Muslim, named with returning the greeting and visiting the sick."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Because the narration calls the answer a right on everyone who hears, Ibn 'Uthaymin held that answering a sneezer who has praised Allah is a duty on each hearer, while other scholars count one answer from the gathering enough. Answer up to three sneezes; after that he has a cold, as the Prophet said of a man who kept sneezing (Sahih Muslim 2993; Sunan Abi Dawud 5034, graded hasan by al-Albani)."),
                  ]),
              ]),
        .init(id: "yawn", title: "Cover a yawn",
              summary: "Hold a yawn back as far as you can, and put your hand over your mouth.",
              group: .company,
              aliases: ["yawning", "yawn", "tathaub", "mouth", "hand", "shaytan", "satan", "restrain", "suppress", "laughs", "prayer"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("He set the sneeze and the yawn side by side: Allah loves the one and dislikes the other. The yawn is to be held back as far as a person can, and in Sahih Muslim he gave the hand its job in it. A yawn is not a sin, and he did not say that it was; what he asked for is the effort to hold it, and the hand over the mouth when it will not be held."),
                      .hadith("bukhari:6226", cite: "Sahih al-Bukhari 6226", arabic: 25...65, english: 4...64),
                      .hadith("muslim:2995a", cite: "Sahih Muslim 2995a", arabic: 37...46, english: 0...24),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When a yawn comes, hold it back as far as you can: close the lips, breathe through the nose, swallow it down. The narration asks for your best effort, not a guarantee; a yawn that escapes after a real try is not what he disliked."),
                      .text("If it will not be held, put your hand over your mouth. That is the instruction of the Muslim narration in its own words, and it covers the yawn in prayer and out of it; the mouth is not left open."),
                      .text("Keep it silent. He said that when a man lets out a ha with his yawn, Shaytan laughs at him (Sahih al-Bukhari 6223), so a yawn held behind closed lips and without the sound is already most of the sunnah kept."),
                      .text("Mind it most in prayer. One version of the narration speaks of the one who yawns in his prayer (Sahih Muslim 2995c), and a wide-open yawn in the middle of recitation is the very picture of the heaviness he disliked; hold it, cover it, and go on."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Sneezing comes from lightness and alertness, yawning from a heavy, full and slack body; al-Nawawi explains that this is why the yawn is traced to Shaytan, who loves to find a person in that state. Holding it in is a small act of self-command, repeated several times a day, and it keeps Shaytan from laughing at a believer."),
                  ]),
              ]),
        .init(id: "sit-where-it-ends", title: "Sit where the gathering ends",
              summary: "Take the open place when you join a gathering, and never make a man rise so you can sit in his seat.",
              group: .company,
              aliases: ["majlis", "gathering", "circle", "halaqah", "seat", "seating", "make room", "tafassahu", "assembly", "lesson", "mosque", "ibn umar"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet's gatherings had no reserved places. A newcomer took the first space he found, a gap in the circle if there was one and the back of the gathering if there was not, and nobody was made to give up his seat. Al-Bukhari gave this a chapter of its own in the Book of Knowledge, headed: whoever sat where the gathering ended, and whoever saw a gap in the circle and sat in it. The report under it is of three men who came while the Prophet was teaching in the masjid."),
                      .hadith("bukhari:66", cite: "Sahih al-Bukhari 66", arabic: 26...114, english: 0...144),
                      .text("The other side of the same manner is a prohibition, with the alternative he gave in its place:"),
                      .hadith("bukhari:6270", cite: "Sahih al-Bukhari 6270", arabic: 20...32, english: 0...30),
                      .text("The Quran had already told the believers how a gathering makes space for the one who arrives:"),
                      .quran("58:11"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you arrive, take the nearest open place and sit. Do not push to the front, step over people, or hover waiting to be seated; the man the Prophet praised simply saw a gap in the circle and sat in it, and the one he sheltered sat at the back."),
                      .text("Never make a man get up so that you can sit in his place; he forbade it outright. If someone rises for you of his own accord you may still decline: Ibn 'Umar, who narrated the prohibition, would not take a seat that had been left for him."),
                      .text("When someone else arrives, make room: shift along, close the gap, widen the circle. That is what the Prophet told a gathering to do instead of unseating anyone, and it is what the ayah asks of the believers, with a promise attached."),
                      .text("If you leave your place and come back, it is yours: the Prophet said the one who gets up from his seat and returns to it has the most right to it (Sahih Muslim 2179), so nobody should be put out of a seat he stepped away from for a moment."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He read the three men's seating as three attitudes to Allah: one turned to Him and was taken in, one was shy and was sheltered, one turned away and was turned away from. Where a person sits in a gathering of knowledge is a small picture of what he came for, and the ayah promises that whoever makes room is made room for by Allah."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The familiar report that each Companion sat wherever the gathering ended when he came to the Prophet is graded sahih by al-Albani but weak by other graders (Sunan Abi Dawud 4825, Sunan al-Tirmidhi 2725), so this page rests on the Sahih narrations and the ayah."),
                  ]),
              ]),
        .init(id: "kaffarat-majlis", title: "Close a gathering with its expiation",
              summary: "Before you rise from a gathering, say the words that wipe out what was said in it.",
              group: .company,
              aliases: ["kaffarat al-majlis", "kaffarah", "subhanaka allahumma", "wa bihamdika", "astaghfiruka", "atubu ilayk", "majlis", "gathering", "dua", "expiation", "idle talk", "laghat"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Talk runs on in any gathering, and some of it is idle. The Prophet taught a short dua to say before standing up that forgives what happened there, and late in his life his Companions noticed he had taken to saying it himself at the close of his gatherings. When one of them asked about the new habit, he told them what the words were for."),
                      .hadith("tirmidhi:3433", cite: "Sunan al-Tirmidhi 3433; graded sahih by al-Albani", arabic: 46...80, english: 6...80),
                      .hadith("abudawud:4859", cite: "Sunan Abi Dawud 4859; graded hasan sahih by al-Albani", arabic: 32...82, english: 0...83),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("As the gathering breaks up, before you stand, say: Subhanaka Allahumma wa bihamdika, ashhadu an la ilaha illa anta, astaghfiruka wa atubu ilayk (glory be to You, O Allah, and praise; I bear witness that there is no god but You; I seek Your forgiveness and I turn to You in repentance)."),
                      .text("Say it at the end of any sitting, not only one that went badly: a meal with friends, a meeting at work, a lesson, a long evening of talk. The Prophet said it at the close of his own gatherings, which were gatherings of knowledge and remembrance, so no sitting is too good for it."),
                      .text("Learn it until it comes by itself, and teach it to the people you sit with most. The narration promises the forgiveness to the one who says the words, so each person says them for himself; said aloud by one, they remind the rest."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration names the reward exactly: whatever took place in that gathering is forgiven. Abu Barzah's report adds the Prophet's own word for the dua, an expiation for what goes on in a gathering, which is how the scholars came to call it kaffarat al-majlis. It is one sentence, and it closes every sitting of the day with glorification, praise, the testimony of faith, a plea for forgiveness and repentance at once."),
                  ]),
              ]),
        .init(id: "visit-sick", title: "Visit the sick",
              summary: "Go to the one who is ill, say the words he said at the bedside, and ask Allah seven times to cure him.",
              group: .company,
              aliases: ["iyadah", "sick", "ill", "illness", "hospital", "patient", "visiting", "la ba'sa", "tahur", "shifa", "cure", "dua for the sick"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Visiting the sick is one of the five rights a Muslim has over his brother (Sahih Muslim 2162), and the Prophet kept it himself: with a Bedouin, with his Companions, and with the Jewish boy who used to serve him (Sahih al-Bukhari 1356). He named its reward in terms of Paradise, he had words for the bedside, and he taught a dua to be said seven times over the sick."),
                      .hadith("muslim:2568b", cite: "Sahih Muslim 2568b", arabic: 34...43, english: 0...16),
                      .hadith("bukhari:5656", cite: "Sahih al-Bukhari 5656", arabic: 21...80, english: 0...73),
                      .hadith("tirmidhi:2083", cite: "Sunan al-Tirmidhi 2083; graded sahih by al-Albani", arabic: 39...60, english: 0...50),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Go. When you hear that a relative, a neighbour, a friend or a brother from the masjid is ill, make the visit, at home or in hospital, and do not wait to be asked. The reward begins when you set out and lasts until you return."),
                      .text("Sit by him and say what the Prophet said: la ba'sa, tahurun in sha Allah (no harm; it is a purification, if Allah wills). The words tell the sick person what his illness is doing for him, wiping out his sins, which is the meaning of tahur."),
                      .text("Then ask seven times: as'alullahal-'azim rabbal-'arshil-'azim an yashfiyak (I ask Allah the Mighty, Lord of the mighty Throne, to cure you). The narration promises that a sick person whose appointed time has not yet come is cured of that illness."),
                      .text("Keep the visit light. The scholars advise a short stay unless the sick person wants longer company, a time that suits him and his family, and leaving him more at ease than you found him; the visit is for his comfort, not for the visitor's conscience."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The visitor is in the orchard of Paradise until he comes home: that is the reward the narration gives, and when the Prophet was asked what the orchard was, he said its gathered fruit (Sahih Muslim 2568d). On the Day of Resurrection Allah will say to a man, I was sick and you did not visit Me, meaning a servant of His whom the man knew to be ill (Sahih Muslim 2569). Few sunnahs are rewarded so plainly, and few are so easily put off until tomorrow."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The seven-times dua is, in its own words, for one whose appointed time has not come; it is a dua, not a guarantee against death. A sick non-Muslim may be visited too: the Prophet visited the Jewish boy who served him and called him to Islam at his bedside (Sahih al-Bukhari 1356)."),
                  ]),
              ]),
        .init(id: "say-good-or-silent", title: "Say what is good, or keep silent",
              summary: "Speak when the words are good; when they are not, hold your tongue.",
              group: .company,
              aliases: ["tongue", "silence", "silent", "speech", "talk", "liyasmut", "khayran", "backbiting", "ghibah", "gossip", "words", "last day"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Of all the manners of speech, he reduced the rule to one line, and he set it beside the neighbour and the guest as a mark of believing in Allah and the Last Day. He also warned what a single careless word can do, in either direction, and he told Mu'adh that what throws people into the Fire on their faces is the harvest of their tongues (Sunan al-Tirmidhi 2616, graded sahih by al-Albani)."),
                      .hadith("bukhari:6018", cite: "Sahih al-Bukhari 6018", arabic: 26...52, english: 4...50),
                      .hadith("bukhari:6478", cite: "Sahih al-Bukhari 6478", arabic: 36...65, english: 3...58),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Before you speak, ask whether the words are good: true, useful, kind or needed. If they are, say them; the narration does not praise silence for its own sake, and he counted a good word as charity (Sahih al-Bukhari 2989). If they are not, say nothing, and let the moment pass."),
                      .text("Stop the tongue at the things the Quran and Sunnah forbid: backbiting, tale-bearing, lying, mockery, obscenity, and talk of what does not concern you. The test is not whether the words are true but whether they are good; he defined backbiting as mentioning your brother with what he dislikes, and said that if it is true you have backbitten him, and if it is not you have slandered him (Sahih Muslim 2589)."),
                      .text("When the words are neither good nor bad, hold back. Al-Nawawi says of this narration that permitted talk whose two sides are equal is better left, because it slides so easily into the disliked and the forbidden, and a tongue that has learnt to wait is easier to stop when it must."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He guaranteed Paradise to whoever guarantees him the tongue and the private parts (Sahih al-Bukhari 6474), and the second narration shows why the tongue needs guarding: a word the speaker gives no thought to can raise him by degrees or throw him into the Fire. Most of a day's sins pass through the mouth, and this one sentence closes the door on most of them."),
                  ]),
              ]),
        .init(id: "gifts", title: "Give gifts",
              summary: "He accepted a gift however small and gave one back; give, and never belittle what is given.",
              group: .company,
              aliases: ["hadiyyah", "hadiya", "gift", "present", "giving", "accept", "return", "neighbour", "neighbor", "trotter", "generosity", "jazakallahu khayran"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet accepted gifts, answered them with gifts, and did not weigh them. 'A'ishah describes the habit in a line; he himself said he would accept even a sheep's trotter, and he told the women of Madinah not to belittle what a neighbour sends, however small it is."),
                      .hadith("bukhari:2585", cite: "Sahih al-Bukhari 2585", arabic: 18...28, english: 0...13),
                      .hadith("bukhari:2568", cite: "Sahih al-Bukhari 2568", arabic: 32...45, english: 4...38),
                      .hadith("bukhari:2566", cite: "Sahih al-Bukhari 2566", arabic: 29...38, english: 4...33),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Give, and give small things without embarrassment: a dish from your kitchen to the neighbour, fruit, a book, something brought back from a journey. He named a trotter, the least part of a sheep, as a gift he would accept, so the sunnah is in the giving, not in the price."),
                      .text("Accept what you are given, and do not refuse a gift out of politeness; accepting is what he did. Thank the giver with a dua: jazakallahu khayran (may Allah reward you with good), which he said is the fullest thanks a person can give (Sunan al-Tirmidhi 2035, graded sahih by al-Albani)."),
                      .text("Give something back when you can, as he did, without turning it into a trade or a tally; a return gift keeps the giving moving in both directions, and it is the second half of 'A'ishah's description of his habit."),
                      .text("Never look down on a gift, yours or another's. He addressed the women in particular because it is neighbours who exchange food most, and the rule is the same for everyone: no gift is too small to give, or to receive with thanks."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("A gift does what words cannot: it says that the person was thought of. He kept the practice open to the poorest giver by naming the trotter, and he kept it clean of pride by forbidding a neighbour to belittle a neighbour. A gift given and answered keeps a bond alive between two homes in a way that costs little and lasts."),
                  ]),
                  SignSection("A NOTE", [
                      .text("A gift given to an official because of his post is not a gift. When a collector came back saying that part of what he brought had been presented to him, the Prophet asked why he had not sat in his father's or mother's house to see whether anyone gave him presents there (Sahih al-Bukhari 2597)."),
                  ]),
              ]),
    ]

    // MARK: Fasting, charity and Friday

    static let weekEntries: [Entry] = [
        .init(id: "fast-monday-thursday", title: "Fast on Mondays and Thursdays",
              summary: "Two voluntary fasts a week, on the days the deeds are shown to Allah.",
              group: .week,
              aliases: ["ithnayn", "khamis", "nafl fast", "sawm", "deeds presented", "weekly", "born", "revelation", "usamah", "tatawwu"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet kept two voluntary fasts most weeks, on Monday and on Thursday. Usamah ibn Zayd noticed that these were the two days he fasted even in the stretches when he was otherwise not fasting, and asked him about it (Sunan an-Nasa'i 2358). His answer named what happens on those days: deeds are raised to Allah, and he wanted his own to go up while he was fasting."),
                      .hadith("tirmidhi:747", cite: "Sunan al-Tirmidhi 747; graded sahih by al-Albani", arabic: 31...41, english: 5...23),
                      .text("Monday carried a second reason of its own. When he was asked about fasting on that day, he did not speak of deeds being raised but of what the day had held for him: it was the day he was born, and the day the revelation first came down to him. Asked about the Monday fast, he said:"),
                      .hadith("muslim:1162e", cite: "Sahih Muslim 1162e", arabic: 41...45, english: 0...14),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Settle it the night before. A voluntary fast needs no spoken words, only the intention in the heart, and the scholars allow a voluntary fast to begin even during the day for someone who has not eaten since dawn, as he once did when 'A'ishah had nothing to offer him (Sahih Muslim 1154). Still, deciding before you sleep means the suhur gets eaten and the day is planned around the fast."),
                      .text("Take suhur before Fajr, even if it is only dates and water, and keep the fast as in Ramadan: no food, drink or marital relations from the true dawn until the sun sets. Keep the day ordinary. A voluntary fast is between you and Allah and needs no announcement; if someone offers you food, you may simply say that you are fasting."),
                      .text("Break the fast at sunset without delay, as he did, on dates or water, then pray Maghrib. If a Monday turns out to be impossible, through illness, travel or a guest, a voluntary fast may be left or broken without sin, as he broke his when food was brought to him; most scholars say completing it is better and making it up is not required."),
                      .text("Thursday, the same. If two fasts a week are too much at first, keep one and grow into the other; he said the most beloved deeds to Allah are the regular ones, even when they are small (Sahih al-Bukhari 6464). A Monday or Thursday that falls on one of the white days of the month counts for both sunnahs at once."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He gave the reason himself: on these two days the deeds are shown to Allah, and he wanted his presented while he was fasting. Fasting is the one deed Allah has said is for Him, and that He Himself will reward (Sahih al-Bukhari 1904), so the week's record goes up with a fast in it twice. Monday adds the memory of his birth and of the first revelation, honoured the way he honoured it: with a fast, and nothing else added to the day."),
                  ]),
              ]),
        .init(id: "white-days", title: "Three days a month: the white days",
              summary: "Three fasts every month, best on the thirteenth, fourteenth and fifteenth, when the moon is full.",
              group: .week,
              aliases: ["ayyam al-bid", "bid", "beed", "white nights", "monthly", "hijri", "abu hurayrah", "abu dharr", "three counsels", "lunar"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu Hurayrah counted three things the Prophet charged him never to leave, and three fasts a month were the first of them. He urged the same on Abu Dharr and on 'Abdullah ibn 'Amr, and he gave the sum: three days in every month, with each good deed counted ten times over, comes to a year of fasting (Sahih al-Bukhari 1976)."),
                      .hadith("bukhari:1981", cite: "Sahih al-Bukhari 1981", arabic: 22...41, english: 0...34),
                      .text("Which three days? Abu Dharr's report names them: the thirteenth, the fourteenth and the fifteenth of the month, which sit in its middle. The Arabs called their nights white because the moon is full on them and the night is lit from dusk to dawn, so the days can be known from the sky alone."),
                      .hadith("nasai:2422", cite: "Sunan an-Nasa'i 2422; graded hasan by al-Albani", arabic: 24...43, english: 0...17),
                      .text("When a man asked him how he fasted and 'Umar went through the patterns one by one, the Prophet set the three days beside the month of Ramadan and gave the total. The arithmetic is the hadith's own: three days in thirty, ten rewards for each, and the whole month is covered; add Ramadan every year, and the year is covered too."),
                      .hadith("muslim:1162b", cite: "Sahih Muslim 1162b", arabic: 160...169, english: 181...197),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Mark the thirteenth, fourteenth and fifteenth of each Hijri month when the month begins, so that they do not slip past. A Hijri calendar shows the day, and the moon shows it too: it is full on the white nights, which is what they are named for, so a glance at the sky confirms the date."),
                      .text("Fast the three as you would any voluntary day: suhur before Fajr, nothing from dawn to sunset, iftar at once when the sun goes. If one of the three falls on a day you cannot fast, take another day in the month instead; 'A'ishah said he did not mind which days of the month he fasted (Sahih Muslim 1160)."),
                      .text("Let the fasts overlap when they can. A Monday or Thursday inside the three counts for both sunnahs, and nothing needs to be said twice. If three in a row is hard at first, spread them through the month; what matters is that no month passes without its three days, since that is what he asked for."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Three days a month, kept every month, is counted as a lifetime of fasting at the cost of thirty-six days a year: his own reckoning, with every good deed written ten times over. It is also what he pressed on the Companions who wanted something they could keep up, and it arrives with the full moon, so a person can see it coming and plan the week around it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The thirteenth to the fifteenth are the best days for the three, by the hadith of Abu Dharr, not a condition of them: any three days of the month fulfil the sunnah, as 'A'ishah's report shows, and the scholars say a person who fasts them early or late in the month has kept it, though the white days carry the extra merit."),
                  ]),
              ]),
        .init(id: "six-shawwal", title: "Six days of Shawwal",
              summary: "Six fasts in the month after Ramadan, and the year is counted as fasted.",
              group: .week,
              aliases: ["sitt", "six fasts", "after eid", "eid al-fitr", "perpetual", "whole year", "abu ayyub", "thawban", "dahr", "make up days"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When Ramadan ended, his fasting did not end with it. The month that follows, Shawwal, has six days in it that he set beside Ramadan with a reward out of all proportion to their number. Abu Ayyub al-Ansari, in whose house he stayed when he first arrived in Madinah, is the Companion who reports the promise."),
                      .hadith("muslim:1164a", cite: "Sahih Muslim 1164a", arabic: 56...66, english: 0...23),
                      .text("Thawban, who served him, carries the reason in his report of the same promise: a good deed is rewarded ten times over, so a month and six days come to a year. Ramadan counts as ten months, the six as two more, and the year is complete. The hadith closes with the ayah that states the rule of ten (6:160)."),
                      .hadith("ibnmajah:1715", cite: "Sunan Ibn Majah 1715; graded sahih by al-Albani", arabic: 43...57, english: 0...25),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Make up any days of Ramadan you owe first. The hadith speaks of one who has fasted Ramadan and then follows it with six, and the scholars, Ibn 'Uthaymin among them, take that in order: the missed days, then the six. A woman who missed days in her period, or a traveller who broke the fast, begins there."),
                      .text("Fast six days anywhere in Shawwal, from the second of the month onwards, since the day of Eid itself may not be fasted. The six may be taken together in the first week or spread across the month one or two at a time; the hadith fixes the month and the number and nothing else."),
                      .text("Keep each fast as you would any other: suhur before Fajr, nothing until sunset, iftar at once. If the month ends before the six are done, there is nothing to make up; the sunnah belongs to Shawwal, and the next Ramadan brings it round again. Six days out of a month is the whole of what he asked."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He said it is as if the person fasted the whole year, and the hadith of Thawban gives the sum: ten for every good deed, so Ramadan is ten months and six days are two more. The scholars add that following Ramadan with more fasting is one of the signs that Ramadan itself was accepted, since Allah, when He accepts a good deed, guides His servant to another after it. It also keeps the month's habit alive a little longer instead of letting Eid end it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Eid al-Fitr may not be fasted; the six begin from the second of Shawwal at the earliest. Most scholars hold that the make-up days of Ramadan come before the six, by the hadith's wording, so the six follow a completed Ramadan rather than stand in for it."),
                  ]),
              ]),
        .init(id: "arafah-ashura", title: "The day of 'Arafah and 'Ashura",
              summary: "Two single-day fasts a year: the ninth of Dhul-Hijjah, and the tenth of Muharram with the ninth before it.",
              group: .week,
              aliases: ["arafa", "arafat", "ashoora", "dhul hijjah", "tasua", "expiation", "kaffarah", "musa", "jews", "hajj", "two years", "ninth and tenth"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Two single days of the year he set apart for a fast with a reward he named. The first is the day of 'Arafah, the ninth of Dhul-Hijjah, when the pilgrims stand on the plain of 'Arafah. The second is 'Ashura, the tenth of Muharram, which he found the Jews of Madinah fasting in thanks for Musa's rescue; he said the Muslims had more claim to Musa than they did, fasted it, and ordered it (Sahih al-Bukhari 2004)."),
                      .hadith("muslim:1162a", cite: "Sahih Muslim 1162a", arabic: 176...200, english: 224...267),
                      .text("In the last year of his life he resolved to add the ninth of Muharram to the tenth, to be different from the Jews, who kept the tenth alone. Ibn 'Abbas reports the exchange: when he fasted 'Ashura and ordered the Companions to fast it, they said to him:"),
                      .hadith("muslim:1134a", cite: "Sahih Muslim 1134a", arabic: 48...93, english: 0...50),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Note the two dates when the Hijri year begins: 'Ashura is the tenth of Muharram, the first month, and 'Arafah is the ninth of Dhul-Hijjah, the last, the day before Eid al-Adha. Each comes once a year, and each is easily missed when the day is found out only after it has passed."),
                      .text("On 'Arafah, fast if you are not at Hajj; the pilgrims do not fast it, as he did not when he stood there. The first ten days of Dhul-Hijjah, with 'Arafah the ninth of them, are days on which he said no good deed is better than on any other (Sahih al-Bukhari 969), so give the day its due in dua and remembrance as well as the fast."),
                      .text("On 'Ashura, fast the tenth of Muharram and the ninth with it, as he resolved to do. If the ninth is missed, some scholars say to fast the eleventh with the tenth instead, and fasting the tenth alone is also allowed; the fast of the tenth is the sunnah itself, and the ninth is added to it to differ from the Jews."),
                      .text("Keep both like any voluntary fast: suhur before Fajr, nothing from dawn until sunset, iftar at once. Both are single days, so there is little excuse to fall short on them; a Monday or Thursday that coincides with either needs no second intention, since one fast carries both."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("'Arafah wipes out the sins of two years, the one before and the one after, and 'Ashura the year before it: his own words, which the scholars read as the minor sins, the major ones needing a repentance of their own. For one day's fast each, that is a reward no other voluntary fast is given. 'Ashura also keeps the memory of Musa's rescue, which he said the Muslims had the greater claim to, and the ninth beside it keeps the fast distinct from what the Jews kept."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The fast of 'Arafah is for those not at Hajj: the Prophet did not fast it while standing at 'Arafah, and Umm al-Fadl's cup of milk, which he drank on his camel in front of the people, settled the Companions' dispute about it (Sahih al-Bukhari 1988). The pilgrim keeps his strength for the standing and the dua."),
                  ]),
              ]),
        .init(id: "suhur", title: "Take suhur, and take it late",
              summary: "The pre-dawn meal before a fast, eaten close to Fajr, with a blessing in it.",
              group: .week,
              aliases: ["sahur", "sehri", "suhoor", "barakah", "fifty verses", "zayd ibn thabit", "ramadan", "dawn", "adhan", "late night meal"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Before a day of fasting he ate, and he told the Companions to eat, because there is a blessing in that meal. He ate it late. Zayd ibn Thabit, who took suhur with him and then stood with him for the prayer, was asked how long there had been between the two, and measured it in verses of the Quran."),
                      .hadith("bukhari:1923", cite: "Sahih al-Bukhari 1923", arabic: 31...35, english: 4...12),
                      .hadith("bukhari:1921", cite: "Sahih al-Bukhari 1921", arabic: 20...40, english: 0...42),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Get up for it. Set the alarm with enough time to eat without hurry and to stop before the true dawn, the time of the Fajr adhan. A few dates and a glass of water are a suhur; the sunnah is in eating something at that hour, not in the size of the meal, so do not let a small appetite talk you out of it."),
                      .text("Eat towards the end of the night rather than at midnight. The gap he left between finishing and the prayer was the time it takes to recite fifty verses at a measured pace, and the scholars count delaying the suhur to that point among the sunnahs of the fast, as long as the dawn is not in doubt."),
                      .text("Stop at the adhan of Fajr, and plan to be finished before it. If the call begins while the cup is already in your hand, he said not to put it down until you have had your need of it (Sunan Abi Dawud 2350, hasan sahih by al-Albani), but nothing new is begun after it. Then pray Fajr, and the day's fast is under way."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He named the reason himself: there is blessing in it. The scholars count that blessing in several ways: it is his sunnah followed, strength for the day's fast and for the Fajr prayer, and a meal taken in the last part of the night, the hour in which Allah descends to the lowest heaven and asks who is calling on Him (Sahih al-Bukhari 1145). He also said that suhur is what sets the Muslims' fast apart from the fast of the People of the Book (Sahih Muslim 1096)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Suhur is a sunnah, not a condition of the fast: whoever sleeps through it fasts the day as it is, and the fast is valid. The scholars differ on how far the hadith of the cup in hand reaches once the adhan is given at the true dawn itself, so the safe course is to be finished before the call, not to eat through it."),
                  ]),
              ]),
        .init(id: "hasten-iftar", title: "Break the fast at once, with dates",
              summary: "At sunset, break the fast without delay, on fresh dates, dried dates or water, then pray.",
              group: .week,
              aliases: ["iftar", "futoor", "fitr", "maghrib", "rutab", "tamr", "dhahaba az-zama", "thirst has gone", "hasten", "anas", "ibn umar", "ramadan"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When the sun set he broke his fast at once, before the Maghrib prayer, and he tied the good of the whole community to that promptness. He broke it on fresh dates when he had them, dried dates when he did not, and a few mouthfuls of water when he had neither; Anas, who served him for ten years in Madinah, watched him do it."),
                      .hadith("bukhari:1957", cite: "Sahih al-Bukhari 1957", arabic: 24...30, english: 4...21),
                      .hadith("abudawud:2356", cite: "Sunan Abi Dawud 2356; graded hasan sahih by al-Albani", arabic: 20...46, english: 0...41),
                      .text("He had words for the moment too. Ibn 'Umar reports what he said once he had broken the fast: not a dua before eating but a sentence after it, naming the thirst that has gone, the veins that are wet again, and the reward that is now settled with Allah, if He wills."),
                      .hadith("abudawud:2357", cite: "Sunan Abi Dawud 2357; graded hasan by al-Albani", arabic: 39...59, english: 18...46),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Watch for the sunset, not the clock alone: the fast ends when the sun has gone below the horizon, which is the time of the Maghrib adhan. He said that when night comes on from one side, the day departs from the other and the sun has set, the fasting person breaks his fast (Sahih al-Bukhari 1954). Have the dates and water in front of you before it."),
                      .text("Eat first, pray after. Take fresh dates if you have them, dried dates if not, and water if you have neither, as he did, and then go to the Maghrib prayer. A few mouthfuls are enough; the fuller meal can wait until the prayer is done, so that the prayer is not delayed either."),
                      .text("After the first mouthfuls, say the words as the hadith gives them: dhahaba az-zama'u wabtallatil-'uruqu wa thabatal-ajru in sha' Allah (the thirst is gone, the veins are moist, and the reward is settled, if Allah wills). They are said after breaking the fast, not before, since they describe what has just happened."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He put the good of the people on it: they remain in goodness as long as they hasten the iftar, and in another report the religion stays uppermost as long as they do, because the Jews and Christians delay it (Sunan Abi Dawud 2353, hasan by al-Albani). The scholars read in it a servant who fasts for Allah and stops when Allah says stop, taking the ease He has given; and he said the fasting person has two joys, one at the breaking of the fast and one at meeting his Lord (Sahih al-Bukhari 1904)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The dua many recite before eating, Allahumma laka sumtu wa 'ala rizqika aftartu (O Allah, for You I fasted and on Your provision I break my fast), comes through a chain al-Albani graded weak (Sunan Abi Dawud 2358); the words above are the sound ones. Breaking the fast on something else when there are no dates is fine; the order in the hadith is his preference, not a condition."),
                  ]),
              ]),
        .init(id: "daily-charity", title: "Give something every day",
              summary: "A little charity each morning, from honest earnings, so that no day passes without it.",
              group: .week,
              aliases: ["sadaqah", "sadaqa", "alms", "spending", "infaq", "two angels", "miser", "date", "foal", "generosity", "halal", "zakah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("He taught the Companions that every morning opens with two duas from heaven, one for the giver and one against the one who holds back. Two angels come down, and each asks Allah for something: a replacement for the one who spends, and ruin for the one who withholds. Not a morning passes, he said, without the two of them."),
                      .hadith("bukhari:1442", cite: "Sahih al-Bukhari 1442", arabic: 32...52, english: 4...37),
                      .text("The amount is not the point. He spoke of a gift the size of a single date, and of what Allah does with it when it comes from honest earnings: He takes it in His right hand and raises it, the way a man raises a foal, until it stands as large as a mountain. The Quran describes the people who give like this, by night and by day."),
                      .hadith("bukhari:1410", cite: "Sahih al-Bukhari 1410", arabic: 42...70, english: 4...64),
                      .quran("2:274"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Settle a small daily amount you will not miss and give it every day, in the morning if you can, the time the angels make their dua. A coin into a box by the door, a standing payment to a cause you trust, a daily gift to someone you pass: the method matters less than the habit of not letting a day go by without it."),
                      .text("Give from what is lawful, since Allah accepts only what is good, and give decent things, not the worn-out coin or the food you would not take yourself (2:267). Give quietly where you can; the Quran says that concealing charity and giving it to the poor is better for you, though giving openly is good as well (2:271)."),
                      .text("On a day you have nothing to give, give what else counts as sadaqah. He said every joint of the body owes a charity each day the sun rises, and he counted justice between two people, a hand with someone's load, a good word, a step towards the prayer and clearing harm from the road among them (Sahih al-Bukhari 2989)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("A daily gift is small, but it is daily, and he said the most beloved deeds to Allah are the regular ones even when they are little (Sahih al-Bukhari 6464). The angel's dua each morning is for the one who gives today, not the one who gave last year. His promise stands behind it: charity does not decrease wealth (Sahih Muslim 2588), and what is given from honest earnings is raised by Allah until it stands like a mountain."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is the voluntary sadaqah. Zakah on wealth that reaches the threshold and has been held a year is an obligation with its own rates and its own recipients, and a daily gift, however regular, does not stand in for it; the one is the pillar, the other is the sunnah built around it."),
                  ]),
              ]),
        .init(id: "friday", title: "Friday: the ghusl, going early, and the hour of answer",
              summary: "Bathe, go early, send blessings on the Prophet, and seek the hour in which dua is answered.",
              group: .week,
              aliases: ["jumuah", "jumu'ah", "juma", "bath", "wash", "perfume", "khutbah", "sermon", "camel", "salawat", "durood", "asr"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Friday was the week's eid for him, a day he said Allah has made a festival for the Muslims (Sunan Ibn Majah 1098, hasan by al-Albani), and he prepared for it. He ordered the ghusl for whoever comes to the Friday prayer, and he went early and sat for the khutbah. He told the Companions that the day holds an hour in which a Muslim's dua is answered, and he asked them to send blessings on him in abundance on it."),
                      .hadith("bukhari:877", cite: "Sahih al-Bukhari 877", arabic: 30...34, english: 5...15),
                      .text("Going early has its own ladder of reward, counted in sacrifices from a camel down to an egg, hour by hour, and the ladder ends when the imam comes out: after that the angels present themselves to listen to the khutbah. Whoever arrives then has the prayer, but not the hours before it. Then the hour of answer, and the blessings sent on him:"),
                      .hadith("bukhari:881", cite: "Sahih al-Bukhari 881", arabic: 38...88, english: 5...129),
                      .hadith("bukhari:935", cite: "Sahih al-Bukhari 935", arabic: 28...43, english: 9...36),
                      .hadith("abudawud:1047", cite: "Sunan Abi Dawud 1047; graded sahih by al-Albani", arabic: 33...56, english: 4...53),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Before you go, take a full bath as for janabah, then clean the teeth with the siwak and put on perfume and your best clothes; he named the ghusl, the siwak and perfume together for the day (Sahih Muslim 846). The ghusl is for whoever goes to the prayer, so those who pray at home are not asked for it."),
                      .text("Go early, walking if you can, and sit close to the imam. The scholars take the hours in the hadith as the parts of the day from its start to the imam's coming out; the earlier you are within them, the greater the sacrifice counted for you. Pray what you can when you arrive, until the imam comes out."),
                      .text("Listen to the khutbah in silence from the moment the imam begins until the prayer; he said that even telling the person beside you to be quiet during it is idle talk (Sahih al-Bukhari 934). Through the day, send blessings on the Prophet often: Allahumma salli 'ala Muhammad (O Allah, send blessings on Muhammad), in any of the forms he taught."),
                      .text("Seek the hour of answer; he showed with his hand how short it is. The two strongest views place it between the imam's sitting down and the end of the prayer (Sahih Muslim 853), or in the last hour of the day before Maghrib (Sunan an-Nasa'i 1389, sahih by al-Albani). Spend both in dua, and especially the last hour of Friday afternoon, asking Allah for whatever good you need."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Each of these carries a reward he named: a sacrifice for the early comer, an answer for whoever meets the hour, and his own receipt of the blessings sent on him. Together they make the day what he called it, the best day on which the sun rises (Sahih Muslim 854), and he said that whoever bathes, comes, prays what is written for him, keeps silent until the imam finishes and then prays with him, is forgiven what lies between that Friday and the next, and three days more (Sahih Muslim 857)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Most scholars hold the Friday ghusl to be a confirmed sunnah rather than an obligation, since he said that wudu on Friday is fine and the ghusl is better (Sunan Abi Dawud 354, hasan by al-Albani); some held it obligatory from the wording of Sahih Muslim 846, so do not leave it without need. The scholars differ on the hour as above, and many of them, Ibn al-Qayyim among them, favoured the last hour after 'Asr."),
                  ]),
              ]),
    ]

    // MARK: Evening and sleep

    static let nightEntries: [Entry] = [
        .init(id: "evening-adhkar", title: "The evening remembrances",
              summary: "The words he said as evening came, and the refuge in Allah's perfect words that holds until morning.",
              group: .night,
              aliases: ["adhkar", "dhikr", "masa", "amsayna", "evening dua", "supplication", "perfect words", "kalimat", "a'udhu", "scorpion", "sunset", "asr"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Morning and evening framed his day with remembrance. Ibn Mas'ud reported the words he said when evening came: that we and the whole dominion have entered the evening belonging to Allah, that praise is His, and that there is no god but He alone. One of the narrators, Zubayd, preserved the rest of the supplication from Ibrahim an-Nakha'i, and Muslim records the two parts in one report."),
                      .hadith("muslim:2723a", cite: "Sahih Muslim 2723a", arabic: 30...110, english: 0...128),
                      .text("A second evening habit he taught is a short refuge in the perfect words of Allah. When a man came to him in the morning complaining that a scorpion had stung him in the night, he told him the words that would have kept it off:"),
                      .hadith("muslim:2708b", cite: "Sahih Muslim 2708b", arabic: 105...141, english: 48...107),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("After 'Asr, as the day turns, say Amsayna wa amsal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah (we have entered the evening and the dominion has entered the evening belonging to Allah; praise is for Allah; there is no god but Allah alone, who has no partner). Say it as a statement of fact, because it is one: the evening and everything in it are His."),
                      .text("Go on with the rest as Zubayd kept it: lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. Allahumma inni as'aluka khayra hadhihil-laylati wa a'udhu bika min sharri hadhihil-laylati wa sharri ma ba'daha. Allahumma inni a'udhu bika minal-kasali wa su'il-kibar. Allahumma inni a'udhu bika min 'adhabin fin-nari wa 'adhabin fil-qabr (His is the dominion and His the praise, and He has power over all things; O Allah, I ask You the good of this night and seek refuge in You from its evil and the evil after it; from laziness and the evil of old age, or of pride; and from punishment in the Fire and in the grave)."),
                      .text("Add the refuge: A'udhu bikalimatillahit-tammati min sharri ma khalaq (I seek refuge in the perfect words of Allah from the evil of what He has created). The report gives the words once and sets no count, and once fulfils it; say it with the stung man in mind, since that is how it was taught."),
                      .text("Keep the pair at the same turn of the evening each day rather than wherever the day leaves room, so the tongue learns them and the heart has time to mean them. If the evening passed without them, say them when you remember; the scholars allow the evening remembrances to be made up into the night."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Each line of the first supplication is a request fitted to the night ahead: its good, protection from its evil and from what follows it, from the two weaknesses that steal worship, laziness and the failing of age, and from the two punishments. The second carries a promise in his own words: the one who says it as evening comes is not harmed by what Allah has created that night, and he told the stung man as much."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars place the evening remembrances between 'Asr and Maghrib and allow them later into the night if they were missed; the narrations themselves name only the coming of evening, so no minute is fixed. The refuge is also his teaching for anyone who halts at a place on a journey, in the first half of the same report."),
                  ]),
              ]),
        .init(id: "sleep-early", title: "Sleep soon after 'Isha",
              summary: "He disliked sleeping before 'Isha and idle talk after it: an early bed keeps the night prayer and Fajr.",
              group: .night,
              aliases: ["early night", "bedtime", "stay up", "talking", "samar", "conversation", "late", "isha", "night prayer", "tahajjud", "fajr", "abu barzah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("His night had a shape. 'Isha was prayed, the hours after it were for sleep, and the last part of the night was for prayer; 'A'ishah said he slept the first of the night and stood the last of it (Sahih al-Bukhari 1146). Abu Barzah al-Aslami, asked how the Prophet prayed, described the whole day and added this about the night:"),
                      .hadith("bukhari:568", cite: "Sahih al-Bukhari 568", arabic: 19...32, english: 0...14),
                      .text("Muslim's fuller version has him not minding some delay of 'Isha, even to the middle of the night, and still disliking sleep before it and talk after it (Sahih Muslim 647). Al-Bukhari heads later chapters of the same book with the limits: sleep before 'Isha for one overcome by it, and sitting up after it for knowledge, for good, or with a guest or one's family."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Pray 'Isha in its time, in congregation where you can, and treat it as the close of the day's business rather than the opening of an evening. What needs doing after it, a meal, a word with the family, a guest, is done without lingering over it."),
                      .text("Go to bed early enough that the night has a second half left for you. Rising before Fajr is the fruit of this sunnah, and it is won at the hour you lie down, not by willpower when the alarm sounds."),
                      .text("Treat conversation after 'Isha as something that needs a reason. Talk of knowledge, the needs of the household, a guest's company: these the Companions kept up, and al-Bukhari records the Prophet himself delaying 'Isha to midnight and then addressing the people after it (Sahih al-Bukhari 600). An hour lost to idle talk or a screen is what the dislike was for."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The scholars read the two dislikes together: sleep before 'Isha risks missing the prayer or praying it late, and talk after it eats the hours that belong to the night prayer and to a fresh Fajr. The last third of the night is when, in his words, our Lord descends to the lowest heaven and asks who is calling on Him, who is asking, who is seeking forgiveness (Sahih al-Bukhari 1145). Guarding the two ends of the night is how that middle stays within reach."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The dislike is a precaution, not a prohibition: one overcome by sleep before 'Isha, or kept up after it by a need, has done nothing wrong, and al-Bukhari's chapter headings around this report say so."),
                  ]),
              ]),
        .init(id: "sleep-wudu-right-side", title: "Wudu, the right side, and the words of surrender",
              summary: "Make wudu as for prayer, lie on your right side and hand yourself over to Allah in the words he taught al-Bara'.",
              group: .night,
              aliases: ["ablution", "bed", "lying down", "aslamtu", "wajhi", "fitrah", "bara", "sleeping position", "last words", "dua before sleep", "surrender", "nabiyyika"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet gave al-Bara' ibn 'Azib a whole bedtime in one instruction: purify as for prayer, lie on the right side, and say words that hand the self over to Allah. He attached a promise to it and told him to make the words the last he spoke. When al-Bara' repeated them back and changed one word, he was corrected on the spot."),
                      .hadith("bukhari:247", cite: "Sahih al-Bukhari 247", arabic: 22...108, english: 0...200),
                      .text("Muslim's narration adds the morning side of the promise:"),
                      .hadith("muslim:2710b", cite: "Sahih Muslim 2710b", arabic: 45...50, english: 0...14),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Go to bed in wudu. If the wudu you prayed 'Isha with still holds, it serves; if it has gone, renew it as you would for prayer. The instruction is to reach the bed in a state of purity, and it costs a minute at the sink."),
                      .text("Lie on your right side. It is the position he named here and in Abu Hurayrah's report of the bed, and the side al-Bara' describes him lying on himself when he went to his bed (Sahih al-Bukhari 6315). Settle there before you speak."),
                      .text("Then say: Allahumma aslamtu wajhi ilayk, wa fawwadtu amri ilayk, wa alja'tu zahri ilayk, raghbatan wa rahbatan ilayk, la malja'a wa la manja minka illa ilayk, Allahumma amantu bikitabikal-ladhi anzalt, wa binabiyyikal-ladhi arsalt (O Allah, I have turned my face to You and entrusted my affair to You and leaned my back on You, in hope of You and fear of You; there is no refuge and no escape from You except to You; O Allah, I believe in Your Book which You sent down and in Your Prophet whom You sent)."),
                      .text("Let them be the last words of the night. He told al-Bara' to make them the last thing he spoke, so whatever the evening held, nothing follows them but sleep. Keep the wording as he gave it: Your Prophet whom You sent, not Your Messenger."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The promise is in the report itself: whoever dies that night dies upon the fitrah, the natural faith Allah created him on, and whoever wakes, wakes to good. The words are a creed in miniature, trust, hope, fear, refuge, belief in the Book and the Prophet, said at the one moment of the day when a person is most like the dead."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The correction at the end is the lesson the scholars draw: al-Bara' said Your Messenger and was told to say Your Prophet, so the remembrances are passed on in the words he taught and not in a paraphrase, even where the meaning seems the same. Nothing here is a condition: one who sleeps without wudu or on another side has missed a sunnah, not committed a sin."),
                  ]),
              ]),
        .init(id: "dust-the-bed", title: "Dust the bed before lying down",
              summary: "Shake out the bedding three times with the edge of a garment, name Allah, and lie on the right side with his words.",
              group: .night,
              aliases: ["shake", "brush", "bedding", "sheet", "izar", "garment", "bismillah", "wada'tu janbi", "firash", "mattress", "insects", "thrice"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("He did not get into a bed without a look at it. A bed left all day is not the bed you left, and the Prophet gave a plain remedy: brush it down with the edge of your garment before you lie on it, three times, and then say the words."),
                      .hadith("bukhari:7393", cite: "Sahih al-Bukhari 7393", arabic: 23...55, english: 0...44),
                      .text("Muslim's wording gives the reason, adds the name of Allah over the brushing and the right side to lie on, and opens the words with glorification:"),
                      .hadith("muslim:2714a", cite: "Sahih Muslim 2714a", arabic: 23...84, english: 0...145),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Before you get in, brush the bedding down three times with the edge of your clothing, or a cloth, saying Bismillah as you do. The point is the bed and not the garment: whatever has crept onto it since the morning is swept off before you lie where it was."),
                      .text("Lie down on your right side. Muslim's report names it here, between the brushing and the words, and al-Bara' was taught the same side with the words of surrender; it is the side on which the night's remembrances were said. Settle there before you speak."),
                      .text("Say Bismika Rabbi wada'tu janbi wa bika arfa'uh, in amsakta nafsi faghfir laha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin (in Your name, my Lord, I lay down my side, and by You I raise it; if You hold my soul, forgive it, and if You send it back, guard it with what You guard Your righteous servants). Muslim's form begins Subhanaka Allahumma Rabbi, glory be to You, O Allah, my Lord, and al-Bukhari's other route has farhamha, have mercy on it, for faghfir laha (Sahih al-Bukhari 6320); all are his wording, so say the one you have learned."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reason is in the hadith: you do not know what came onto the bed after you left it. The words then put the night in its true light. Lying down is a laying down of the self in Allah's hand, and the sleeper does not know whether that soul will be kept or sent back; he asks forgiveness for the one case and protection for the other, the protection Allah gives His righteous servants."),
                  ]),
              ]),
        .init(id: "ayat-kursi-sleep", title: "Ayat al-Kursi before sleeping",
              summary: "Recite the Throne Verse in bed: a guardian from Allah stays with you and no shaytan comes near until morning.",
              group: .night,
              aliases: ["throne verse", "kursi", "2:255", "baqarah", "guardian", "protection", "shaytan", "satan", "abu hurayrah", "zakat", "thief", "hafiz"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The teaching came by an odd road. Abu Hurayrah was set to guard the Ramadan charity, and three nights running he caught a thief scooping from it and let him go on a plea of need. On the third night the thief bought his release with a lesson instead:"),
                      .hadith("bukhari:2311", cite: "Sahih al-Bukhari 2311", arabic: 205...234, english: 325...371),
                      .text("In the morning the Prophet asked again what the prisoner had done, heard the words, and gave his verdict on them and on the thief:"),
                      .hadith("bukhari:2311", cite: "Sahih al-Bukhari 2311", arabic: 309...338, english: 489...526),
                      .text("The ayah itself, which he called the greatest in the Book of Allah when Ubayy ibn Ka'b named it (Sahih Muslim 810):"),
                      .quran("2:255"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you are in bed and ready for sleep, recite Ayat al-Kursi in full, the two hundred and fifty-fifth ayah of al-Baqarah, from Allahu la ilaha illa huwal-Hayyul-Qayyum to the end of the ayah, wa la ya'uduhu hifdhuhuma wa huwal-'Aliyyul-'Adhim, without stopping short."),
                      .text("Recite it once; the report names no number. If you have not memorised it, read it from the page until you have: it is a single ayah, and a week of nights fixes it in the memory of a child or an adult."),
                      .text("Make it one piece of a single bedtime run each night, with the three Quls and the last two ayahs of al-Baqarah, so that one habit carries the three recitations and none of them depends on being remembered on its own."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The promise was spoken by a shaytan and then confirmed by the Prophet: whoever recites it on going to bed has a guardian from Allah over him, and no shaytan comes near him until morning. He added that the liar had told the truth this once. The scholars connect the protection to what the ayah says: Allah's life and self-subsistence, His knowledge of all that is before and behind His creatures, His Kursi extending over the heavens and the earth, and that guarding them does not tire Him."),
                  ]),
              ]),
        .init(id: "three-quls-sleep", title: "The three Quls into the palms",
              summary: "Cup the hands, recite al-Ikhlas, al-Falaq and an-Nas, blow into them and wipe over the body, three times a night.",
              group: .night,
              aliases: ["mu'awwidhat", "muawwidhat", "ikhlas", "falaq", "nas", "qul", "blow", "nafth", "wipe", "palms", "aisha", "ruqyah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("'A'ishah watched this every night. Before sleep he brought his palms together, recited into them the three surahs that begin with Qul, blew lightly into his hands and passed them over his body as far as they would reach, beginning with the head, the face and the front of him, and he did the whole of it three times."),
                      .hadith("bukhari:5017", cite: "Sahih al-Bukhari 5017", arabic: 15...66, english: 0...61),
                      .text("The three surahs are the last in the Quran and among its shortest:"),
                      .quran("112:1-4"),
                      .quran("113:1-5"),
                      .quran("114:1-6"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("In bed, bring your two palms together and recite into them Surah al-Ikhlas (Qul huwallahu ahad), Surah al-Falaq (Qul a'udhu birabbil-falaq) and Surah an-Nas (Qul a'udhu birabbin-nas), one after the other. Al-Ikhlas is four ayahs, al-Falaq five and an-Nas six, so the three take well under a minute."),
                      .text("Blow into your palms with a light breath, a little moisture with it, which is what the narration's nafth means, and then pass them over as much of your body as you can reach: the head first, then the face, then the front of the body, then the rest."),
                      .text("Do it three times through: recite, blow, wipe; recite, blow, wipe; recite, blow, wipe. The three rounds take about two minutes, and 'A'ishah's word for how often was every night, so make it the fixed close of the bedtime remembrances rather than an extra for bad nights."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Al-Ikhlas is the Quran's statement of who Allah is, and al-Falaq and an-Nas are its two surahs of refuge: from the evil of creation, of the dark, of envy and of the whisperer. 'A'ishah also tells that when he was ill he recited the two of refuge over himself and blew, and in his last illness she did it for him with his own hand (Sahih al-Bukhari 5016). The scholars count this with Ayat al-Kursi among the night's protections."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is the sunnah of the bed, done once there. The same three surahs, said three times each in the morning and the evening, are a separate sunnah with its own report, in which he promised they would suffice against everything (Sunan Abi Dawud 5082; graded hasan by al-Albani)."),
                  ]),
              ]),
        .init(id: "baqarah-last-two", title: "The last two ayahs of al-Baqarah",
              summary: "Whoever recites the last two ayahs of al-Baqarah in a night, they suffice him.",
              group: .night,
              aliases: ["amanar-rasul", "amana rasul", "2:285", "2:286", "baqara", "suffice", "kafatahu", "night recitation", "abu mas'ud", "two lights", "rabbana la tu'akhidhna"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("A short practice with a wide promise. Abu Mas'ud al-Ansari carried it, and when 'Abd ar-Rahman ibn Yazid met him at the Ka'bah and asked whether the hadith was really his, he said yes and repeated it to his face (Sahih Muslim 807a). Al-Bukhari's wording:"),
                      .hadith("bukhari:5009", cite: "Sahih al-Bukhari 5009", arabic: 23...40, english: 0...21),
                      .text("The two ayahs:"),
                      .quran("2:285-286"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Recite the two ayahs, Amanar-rasulu bima unzila ilayhi mir-rabbihi wal-mu'minun to the end of the surah, at some point in the night. The report says in a night and names no hour, so after 'Isha, in bed, or on waking for prayer all fulfil it."),
                      .text("Learn them if you have not. They are two ayahs, the surah's closing creed and its closing prayer, and reading them from the page each night for a week fixes them. Until then, the page counts as much as the memory."),
                      .text("Say the closing prayer as a prayer. Rabbana la tu'akhidhna in nasina aw akhta'na, our Lord, do not take us to task if we forget or err, and the requests after it were each answered by Allah with the words I have done so, as Ibn 'Abbas related (Sahih Muslim 126). The night is the time to mean them."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("They suffice him. The scholars read the promise more than one way and allow them all: an-Nawawi lists that the two ayahs suffice in place of the night prayer, or suffice as protection from every harm and from the Shaytan, or both. Ibn 'Abbas also reported that an angel who had never come down before brought the Prophet news of two lights given to no prophet before him, the opening of the Book and the closing ayahs of al-Baqarah, and that no letter of them is recited without its reward (Sahih Muslim 806)."),
                  ]),
              ]),
        .init(id: "tasbih-before-sleep", title: "Thirty-three, thirty-three, thirty-four",
              summary: "Subhan Allah, al-hamdu lillah and Allahu akbar in bed: what the Prophet gave Fatimah in place of a servant.",
              group: .night,
              aliases: ["tasbih", "tahmid", "takbir", "subhanallah", "alhamdulillah", "allahu akbar", "fatimah", "ali", "servant", "hundred", "khadim", "siffin"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Fatimah's hands were worn from the hand-mill, and when prisoners of war were brought in she went to ask her father for a servant. He did not give her one. That night he came to her house, found her and 'Ali already in bed, told them to stay where they were and sat between them; 'Ali said he felt the cold of his feet on his chest. Then he taught them this, and said it was better for them than a servant (Sahih Muslim 2727a). Al-Bukhari's wording:"),
                      .hadith("bukhari:5362", cite: "Sahih al-Bukhari 5362", arabic: 24...62, english: 0...43),
                      .text("'Ali, who told the story, added what it became for him:"),
                      .hadith("bukhari:5362", cite: "Sahih al-Bukhari 5362", arabic: 71...81, english: 44...76),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you have lain down, say Subhan Allah (glory be to Allah) thirty-three times, al-hamdu lillah (praise be to Allah) thirty-three times, and Allahu akbar (Allah is greatest) thirty-four times: a hundred in all. Count on the fingers; a hundred takes a minute or two."),
                      .text("The order is not fixed. Al-Bukhari's report puts the takbir last and Muslim's puts it first, and both give it the thirty-fourth, so say them in whichever order you learned as long as the three counts are kept and the total comes to a hundred."),
                      .text("Keep it on hard nights too. 'Ali did not leave it even on the night before Siffin, with a battle in the morning. If a day was too full for other remembrances, this one is said lying down and asks nothing of the body."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He called it better for them than a servant. The scholars read that two ways, and both are in the story: the remembrance brings a strength and a help from Allah that outweighs what a servant does, and it is a provision for the next life that no household help could be. 'Ali's keeping it from that night through war and the caliphate is the measure of how he took it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("This is the bedtime set. The count after each obligatory prayer is a separate sunnah with its own reports and its own numbers, and keeping one is not keeping the other."),
                  ]),
              ]),
        .init(id: "bismika-amutu", title: "In Your name I die and I live",
              summary: "Bismika Allahumma amutu wa ahya on lying down, and the praise on waking that answers it.",
              group: .night,
              aliases: ["bismika", "amutu", "ahya", "hudhayfah", "waking", "alhamdulillah alladhi ahyana", "nushur", "resurrection", "death", "sleep dua", "last words", "morning"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Hudhayfah reported the pair of words that opened and closed the Prophet's sleep. On lying down he named Allah and called sleep a dying; on waking he praised Allah for a return to life and named the Resurrection. The two belong together, which is why one report carries both."),
                      .hadith("bukhari:6324", cite: "Sahih al-Bukhari 6324", arabic: 17...49, english: 0...70),
                      .text("The Quran gives the likeness he was using:"),
                      .quran("39:42"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you have settled on your side and said whatever other remembrances you keep, say Bismika Allahumma amutu wa ahya (in Your name, O Allah, I die and I live), and let it be the last thing before sleep. It is five words, short enough for a child, and it is his."),
                      .text("On waking, before you rise, say Al-hamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur (praise be to Allah who gave us life after He had caused us to die, and to Him is the resurrection). The two halves make one practice; keep both."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The Quran says Allah takes the souls at death and takes those that do not die in their sleep, keeps the one whose time has come and sends the other back until its term. The two sayings put that out loud twice a day: lying down in His name as one who may not wake, and waking with praise as one who has been given his life back and will one day be raised. The scholars count the pair among the sunnahs he kept most constantly."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Al-Bukhari carries the shorter form too, Bismika amutu wa ahya without Allahumma (Sahih al-Bukhari 6312); both are his wording and either fulfils the sunnah."),
                  ]),
              ]),
        .init(id: "mulk-at-night", title: "Surah al-Mulk at night",
              summary: "Thirty ayahs that plead for their companion until he is forgiven; the scholars make them part of every night.",
              group: .night,
              aliases: ["tabarak", "mulk", "67", "intercede", "intercession", "shafa'ah", "forgiven", "thirty verses", "sovereignty", "dominion", "night reading", "abu hurayrah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("One surah he singled out by its length and by its name. Abu Hurayrah carried his word that one surah of thirty ayahs pleads for a man until he is forgiven, and he named it by its opening words, the surah that begins Tabarakal-ladhi biyadihil-mulk:"),
                      .hadith("tirmidhi:2891", cite: "Sunan al-Tirmidhi 2891; graded hasan by al-Albani", arabic: 28...46, english: 5...30),
                      .text("Ibn Majah's wording says for whom it pleads, its companion, the one who keeps company with it:"),
                      .hadith("ibnmajah:3786", cite: "Sunan Ibn Majah 3786; graded sahih by al-Albani", arabic: 28...44, english: 0...37),
                      .text("Its opening:"),
                      .quran("67:1-2"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Read the whole surah, all thirty ayahs, once in the night: after 'Isha, or in bed before the sleep remembrances. It takes a few minutes read aloud. The sound reports name no hour; the scholars recommend the night, before sleep, so that it becomes a fixed habit rather than a wish."),
                      .text("Memorise it over time, a few ayahs a night, so that it can be read with the light off and on nights when there is no page to hand; until then read it from the page, which fulfils it just as well. Hearing a recording while following the page is the quickest road to having it by heart."),
                      .text("Let it be a companion and not a visitor. The hadith's word is sahib, companion, and the scholars take it as regular recitation rather than a reading once; the surah pleads for the one who kept it. If a night is missed, the habit is not broken; pick it up the next night."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is intercession: the surah itself pleads for its companion until he is forgiven. The scholars note that the surah's content is why. It is thirty ayahs on Allah's dominion, death and life created as a test, the heavens built without a flaw, the Fire and the regret of its people, the birds held up by nothing but the Merciful, and the closing question of who would bring back water that had sunk into the earth. Read nightly, it keeps the end in view."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The well-known report that he would not sleep until he had recited as-Sajdah and al-Mulk is graded weak by the graders this app's collection lists, so this page rests on the two sound reports above. The scholars still recommend the surah every night, and the sound reports fix no time, so the night is their counsel, not a condition."),
                  ]),
              ]),
        .init(id: "waking-at-night-dua", title: "The words when you stir at night",
              summary: "Wake in the night, say the words he taught, then ask: it is answered; make wudu and pray, and it is accepted.",
              group: .night,
              aliases: ["ta'arra", "taarra", "waking", "night", "la ilaha illallah wahdahu", "tahajjud", "answered dua", "ubadah", "stir", "turn over", "middle of the night", "istighfar"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Not every waking in the night is for prayer; most are a turn in the dark and a return to sleep. The Prophet put something in that moment. 'Ubadah ibn as-Samit reported the words to say on stirring, the promise attached to the supplication that follows them, and the greater promise if the waking goes on to wudu and prayer."),
                      .hadith("bukhari:1154", cite: "Sahih al-Bukhari 1154", arabic: 31...83, english: 3...140),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you wake in the night, before you turn over, say La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir (there is no god but Allah alone, without partner; His is the dominion and His is the praise, and He has power over all things)."),
                      .text("Go on: Al-hamdu lillah, wa subhanallah, wa la ilaha illallah, wallahu akbar, wa la hawla wa la quwwata illa billah (praise be to Allah, glory be to Allah, there is no god but Allah, Allah is greatest, and there is no power and no strength except by Allah)."),
                      .text("Then ask. The report's own example is Allahumma-ghfir li (O Allah, forgive me), and it goes on to say or any supplication; this is the moment the hadith says is answered, so ask for what you need in the words you have."),
                      .text("If you can, get up, make wudu and pray two rak'ahs or more. The prayer of one who woke this way is accepted, the hadith says, and for those who find rising for the night prayer hard this is the door: the words first, and the feet follow."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Two promises sit in one short report: the supplication of the one who wakes and says these words is answered, and the prayer of the one who then makes wudu and prays is accepted. The scholars explain ta'arra as waking in the night with a sound or a word, and read the hadith as a picture of a heart that remembers Allah even half asleep; they count it among the easiest doors to the night prayer, since it begins in bed."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ta'arra in the hadith means to wake at night and stir or speak, not to rise; the words are for the half-awake moment, and the prayer is the extra the report rewards further, not a condition of the first promise."),
                  ]),
              ]),
    ]

    // MARK: More: wudu and the prayer

    static let prayerEntries2: [Entry] = [
        .init(id: "wudu-each-prayer", title: "A fresh wudu for each prayer",
              summary: "He made a fresh wudu for every prayer; one wudu still serves until something breaks it.",
              group: .purification,
              aliases: ["ablution", "renew", "renewal", "tajdid", "tajdeed", "anas", "hadath", "buraydah", "conquest of makkah", "one wudu", "wudhu", "wudoo"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet's habit was a new wudu for every prayer, even when the last one had not been broken. Anas, who served him for ten years, described it, and when he was asked what the Companions themselves did he gave the other half of the rule: one wudu served them for prayer after prayer, as long as nothing broke it. The two halves stand together, his habit and their licence."),
                      .hadith("bukhari:214", cite: "Sahih al-Bukhari 214", arabic: 31...51, english: 0...36),
                      .text("On the day Makkah was opened he did the opposite, on purpose. Buraydah reported that he prayed all the prayers of that day with a single wudu, wiping over his khuffs, and when 'Umar remarked that he had done something he did not usually do, he answered that it was deliberate (Sahih Muslim 277). The scholars read the day as a lesson given in public: the fresh wudu is a merit, and the single wudu is enough."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the time of a prayer comes in and you are still in wudu, make a new one anyway if water is at hand: the full wudu, hands to feet, with Bismillah at the start and the testimony at the end, as the pages before this describe. It takes a minute, and it is prayed with straight away, so the washing and the prayer stay joined."),
                      .text("If water is scarce, or you are between prayers in a place where washing is a trouble, pray with the wudu you have. That is what the Companions did, and what he himself did on the day of the conquest; the one wudu is valid until it is broken by what breaks it, and nothing in the Sunnah asks you to doubt it or to count the prayers it has served."),
                      .text("Make the renewal part of the prayer's preparation rather than a separate chore: on hearing the adhan, go to the water, make wudu, use the siwak, and walk to the prayer. The sunnah is a fresh wudu for a prayer, so renewing it with no prayer in view is not the practice the narration describes, and most scholars tie the merit to a prayer about to be prayed with it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is the reward of wudu itself, earned again: the sins carried off with the water and the ranks raised for wudu made well, five times a day instead of once. The scholars add that a person who stands before Allah in a wudu made for that prayer stands fresher and more attentive, and that the Prophet's own choice, whenever water was at hand, was the new wudu."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Renewing wudu while still in wudu is recommended, not required: Ibn Baz and Ibn 'Uthaymin say the one wudu is valid for as many prayers as a person likes until it is broken, and his single wudu on the day of the conquest was done, in his own words, on purpose, which the scholars read as showing that the renewal is no duty."),
                  ]),
              ]),
        .init(id: "wiping-khuff", title: "Wipe over the khuffs",
              summary: "Socks put on in a state of purity are wiped in wudu, not removed: a day and a night at home, three on a journey.",
              group: .purification,
              aliases: ["mash", "masah", "khuff", "khuffayn", "socks", "jawrab", "leather socks", "boots", "mughirah", "traveller", "journey", "wiping"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("On a journey al-Mughirah ibn Shu'bah poured the water for the Prophet's wudu, and when he bent to pull off the Prophet's khuffs, the leather socks worn under the sandals, he was told to leave them: they had been put on over clean feet. The Prophet then wiped over them with his wet hands and the wudu was complete. It is one of the plainest concessions in the Sunnah, made for the ordinary difficulty of a cold morning on the road."),
                      .hadith("bukhari:206", cite: "Sahih al-Bukhari 206", arabic: 14...36, english: 0...51),
                      .text("The concession has a time limit, and 'Ali gave it when Shurayh ibn Hani came asking. 'A'ishah had sent him on to 'Ali, since he was the one who travelled with the Prophet, and 'Ali reported the two periods, one day for the resident and three for the traveller."),
                      .hadith("muslim:276a", cite: "Sahih Muslim 276a", arabic: 28...67, english: 0...63),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Make a full wudu first, washing the feet, and then put the socks on; the wiping is allowed only over socks put on in a state of purity. From then on, each time you make wudu you wipe over them instead of washing the feet: wet the hands and pass them once over the top of each foot, from the toes towards the shin, the right foot and then the left."),
                      .text("Count the time from the first wipe after the socks went on, as Ibn 'Uthaymin ruled (most scholars count it from the first breaking of wudu after they went on): a day and a night, twenty-four hours, for the resident, and three days and nights for the traveller. When the period ends, take the socks off and wash the feet with the next wudu; then the count can begin again from a new wudu."),
                      .text("The concession is for minor impurity only. If a ghusl is needed, for janabah or at the end of a period, the socks come off and the whole body is washed, feet included, and the wiping starts afresh after the bath. Taking the socks off before the time is up also ends the wiping, so the feet are washed at the next wudu."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sunnah here is an ease the Prophet used himself and kept for his Companions, at home and on the road, and the scholars count taking the concessions Allah has given as part of following the Sunnah rather than a lapse from it. It also keeps the wudu whole on cold mornings and long journeys, where washing the feet would otherwise be hurried or left out, and it saves water and time for the prayer itself."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn Baz, Ibn 'Uthaymin and the Permanent Committee affirm wiping over ordinary socks (jawrab) as well as leather khuffs, under the same three conditions: put on in a state of purity, within the time limit, and for minor impurity only. Al-Mughirah also reported that the Prophet wiped over socks and sandals (Sunan Abi Dawud 159; graded sahih by al-Albani), and Abu Dawud names 'Ali, Ibn Mas'ud, Anas and other Companions who wiped over socks."),
                  ]),
              ]),
        .init(id: "sutrah", title: "Pray towards a sutrah",
              summary: "Put something in front of you when you pray, a wall, a pillar or a bag, and do not mind who passes beyond it.",
              group: .prayer,
              aliases: ["screen", "barrier", "sutra", "passing in front", "spear", "anazah", "saddle", "wall", "pillar", "talhah", "abu juhayfah", "shaytan"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When the Prophet prayed in the open he had something planted in front of him: at al-Batha, outside Makkah, it was a short spear, and the women and the donkeys passed beyond it while he led Dhuhr and 'Asr. The thing in front is the sutrah, the screen, and he told the Companions what it does. Talhah reported his words, which Muslim also records (Sahih Muslim 499):"),
                      .hadith("abudawud:685", cite: "Sunan Abi Dawud 685; graded sahih by al-Albani", arabic: 29...42, english: 0...32),
                      .text("Abu Juhayfah saw the spear in use:"),
                      .hadith("bukhari:501", cite: "Sahih al-Bukhari 501", arabic: 13...29, english: 0...31),
                      .text("And he said to stand close to it:"),
                      .hadith("abudawud:695", cite: "Sunan Abi Dawud 695; graded sahih by al-Albani", arabic: 45...57, english: 4...25),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Before you say the takbir, put something in front of you: a wall, a pillar, the back of a chair, a bag, a stick stood in the ground, anything about the height of the back of a camel saddle, which 'Ata put at a cubit or more (Sunan Abi Dawud 686). Then stand close to it, with no more than about three cubits between your feet and it, so that your forehead comes near it in prostration."),
                      .text("In the masjid, pray towards a wall or a pillar when you pray alone, and let the imam's sutrah serve for the whole congregation; a person praying in the rows needs none of his own. Where the masjid is open and crowded, a bag set on the floor in front of you is enough. Outside, on a journey or in a park, a stick or a stone of some height does what the spear did."),
                      .text("Once the sutrah is set, pray and do not mind who passes beyond it. If someone tries to pass between you and it, hold out a hand to stop him, as he taught and as Abu Sa'id did (Sahih al-Bukhari 509), without leaving the prayer; and never walk in front of a person praying yourself, for he said that if the one who passes knew what he carried he would rather stand forty than pass (Sahih al-Bukhari 510)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narrations name two things the sutrah does: it frees the one praying from minding what moves in front of him, and it keeps Shaytan from cutting into his prayer. The scholars add that it marks out a space that belongs to the prayer, so that others know not to cross it and the heart is not pulled after everything that passes. It is a stick or a wall, it costs nothing, and he kept it even in the open desert."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn Baz and Ibn 'Uthaymin count the sutrah a stressed sunnah that a Muslim should not leave, while al-Albani held it to be obligatory; on every view the prayer without one is valid, and the one who prayed without it has left something the Prophet kept."),
                  ]),
              ]),
        .init(id: "istiftah", title: "The opening supplication",
              summary: "After the first takbir and before al-Fatihah, a short silence filled with words that ask to be set far from sin.",
              group: .prayer,
              aliases: ["dua al-istiftah", "istiftah", "opening dua", "takbir", "silence", "sakta", "allahumma ba'id", "subhanaka allahumma", "thana", "snow and hail", "abu hurayrah", "white garment"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Between the takbir that opens the prayer and the recitation of al-Fatihah there was a pause, short enough that Abu Hurayrah had to ask what filled it. The answer was a supplication, said quietly, before a single ayah: a request to be set as far from sin as east is from west, to be cleaned of it as a white garment is cleaned, and to have it washed away with water, snow and hail. Muslim records the same report (Sahih Muslim 598)."),
                      .hadith("bukhari:744", cite: "Sahih al-Bukhari 744", arabic: 24...85, english: 0...133),
                      .text("He opened with other words too. Abu Sa'id al-Khudri reported the ones he said on rising to pray at night, which the scholars count among the sound openings, and any one of them keeps the sunnah:"),
                      .hadith("abudawud:775", cite: "Sunan Abi Dawud 775; graded sahih by al-Albani", arabic: 21...46, english: 0...49),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Say the opening takbir, fold the hands, and before you begin al-Fatihah say quietly: Allahumma ba'id bayni wa bayna khatayaya kama ba'adta baynal-mashriqi wal-maghrib; Allahumma naqqini min khatayaya kama yunaqqath-thawbul-abyadu minad-danas; Allahumma-ghsil khatayaya bil-ma'i wath-thalji wal-barad (O Allah, set me far from my sins as You have set the east far from the west; O Allah, clean me of my sins as a white garment is cleaned of dirt; O Allah, wash my sins away with water, snow and hail)."),
                      .text("Or say the other opening: Subhanaka Allahumma wa bihamdika, wa tabarakasmuka, wa ta'ala jadduka, wa la ilaha ghayruk (glory be to You, O Allah, and praise; blessed is Your name and exalted is Your majesty, and there is no god but You). Learn both and vary between them, as the scholars advise with every dhikr that has more than one sound form, so that neither is forgotten."),
                      .text("Then seek refuge, A'udhu billahi minash-shaytanir-rajim (I seek refuge in Allah from the accursed Shaytan), and begin al-Fatihah. The opening words are said once, in the first rak'ah, in every prayer, obligatory or voluntary, by the imam, the one praying behind him and the one praying alone; whoever joins late and fears to miss al-Fatihah leaves them and begins with the surah."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The scholars call it the istiftah, the opening, and read its purpose from its content: before a word of the Quran is recited, the one praying asks to be made clean enough to recite it. The three images are of distance, of washing and of the coldest, purest water, and they are asked for in the one posture in which a Muslim stands before his Lord with nothing in his hands. A prayer begun this way begins with repentance."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Several opening supplications are sound, among them the two above and the longer Wajjahtu wajhiya that he said in the night prayer (Sahih Muslim 771); any one of them fulfils the sunnah, and the scholars prefer varying between them to fixing on one. It is a sunnah, not a pillar of the prayer: a prayer begun without it is complete."),
                  ]),
              ]),
        .init(id: "dua-in-sujud", title: "Ask in prostration",
              summary: "The nearest a servant comes to his Lord is in sujud: glorify Him there, then ask for what you need.",
              group: .prayer,
              aliases: ["sujood", "sajdah", "supplication", "du'a", "closest to allah", "prostrating", "subhana rabbiyal a'la", "abu hurayrah", "ibn abbas", "answered", "ruku", "own language"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet taught where in the prayer a request is nearest to being heard. In his last illness he drew back the curtain of his room while the people stood in rows behind Abu Bakr, and told them that he had been forbidden to recite the Quran in bowing and prostration: the bowing is for magnifying the Lord, and the prostration for striving in supplication, since it is likely to be answered there."),
                      .hadith("muslim:479a", cite: "Sahih Muslim 479a", arabic: 66...91, english: 49...98),
                      .text("Abu Hurayrah carried the rule in its shortest form:"),
                      .hadith("muslim:482", cite: "Sahih Muslim 482", arabic: 45...55, english: 6...25),
                      .text("His own words in prostration are recorded too. He would say, O Allah, forgive me all my sins, small and great, first and last, open and secret (Sahih Muslim 483), and in both bowing and prostration, Subbuhun quddus, rabbul-mala'ikati war-ruh, All-Glorious, All-Holy, Lord of the angels and the Spirit (Sahih Muslim 487)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("In each prostration, first say the glorification that belongs to it: Subhana Rabbiyal A'la (glory be to my Lord, the Most High), which is the sujud's own dhikr and is never left for the sake of dua. Then, when the glorification is said, stay down a little longer than habit and ask."),
                      .text("Ask in your own words for what you need: forgiveness, guidance, a parent's health, a debt, a child, the Muslims who are suffering. Nothing is too small. The duas he said in sujud and the ones the Quran teaches are the best, so learn Allahumma-ghfir li dhanbi kullahu, diqqahu wa jillahu, wa awwalahu wa akhirahu, wa 'alaniyatahu wa sirrahu (O Allah, forgive me all my sins, small and great, first and last, open and secret) and use it often."),
                      .text("Keep the balance the hadith sets: the ruku' is for glorifying, so do not turn it into a place of asking, and in the obligatory prayer ask in Arabic, in the words of the Quran and the Sunnah or words of your own, as most scholars require. In the voluntary prayers, and above all at night, the sujud can be made long and the asking wide."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Two narrations carry the promise: the servant is never nearer his Lord than in prostration, and supplication there is likely to be answered. The scholars draw out why: the forehead on the ground is the posture of the lowest servant before the highest Lord, and asking is most fitting from the one who has just placed himself there. The sujud comes twice in every rak'ah, so a Muslim who keeps this sunnah is asking Allah in His nearest place many times a day."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars differ on supplication in a language other than Arabic inside the prayer: the majority require Arabic in the obligatory prayer, while Ibn 'Uthaymin allowed a person who cannot manage Arabic to ask in his own language; outside the prayer every language is the same."),
                  ]),
              ]),
        .init(id: "amin", title: "Say amin with the imam",
              summary: "When the imam finishes al-Fatihah, say amin with him: whoever's amin meets the angels' is forgiven.",
              group: .prayer,
              aliases: ["ameen", "aameen", "ta'min", "fatihah", "wa lad-dallin", "angels", "forgiven", "past sins", "imam", "aloud", "abu hurayrah", "coincides"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Al-Fatihah ends with a request, to be guided along the straight path and kept from the path of those who earned anger and those who went astray, and amin is the word that seals a request: O Allah, answer. The Prophet said it himself at the end of al-Fatihah, he told those praying behind him to say it with the imam, and he told them what is at stake in the timing."),
                      .hadith("bukhari:6402", cite: "Sahih al-Bukhari 6402", arabic: 26...43, english: 4...40),
                      .text("A second report from Abu Hurayrah fixes the moment:"),
                      .hadith("muslim:410f", cite: "Sahih Muslim 410f", arabic: 29...54, english: 6...48),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the imam reaches wa lad-dallin, the last words of al-Fatihah, say Amin (O Allah, answer) as he says it: with him, not before him and not trailing after. In Fajr, Maghrib and 'Isha, where the recitation is aloud, say it aloud too, so that the whole congregation's amin rises together; in Dhuhr and 'Asr it is said quietly, like the recitation."),
                      .text("Say it in your own prayer as well, at the end of your own al-Fatihah when you pray alone, and when you lead others say it aloud so that they can follow: Ibn Shihab added that the Messenger of Allah used to say amin, and the Companions behind him said it with him."),
                      .text("Mean it. The narration ties forgiveness to the amin that coincides with the angels', and the scholars read the coincidence as the timing first, with some adding sincerity and humility to it: said at the moment the imam says it, by a heart that is asking what al-Fatihah asks. Pause, if you need to, to remember what you are saying amin to."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is the one the narration names: past sins forgiven for whoever's amin coincides with the amin of the angels. The scholars observe that the angels in heaven are saying amin to the same request at the same moment, so the congregation on earth joins a congregation above it, and that a word of one breath, said in time, has a promise attached to it that longer acts do not."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The majority of scholars, following the practice of the Companions, say amin aloud behind the imam in the audible prayers and quietly in the silent ones; the Hanafis say it quietly in every prayer. It is a sunnah on every view, and a prayer in which it was left out is complete."),
                  ]),
              ]),
        .init(id: "straight-rows", title: "Straighten the rows and fill the first",
              summary: "Shoulder to shoulder, gaps closed, the first row filled first: people would draw lots for it if they knew.",
              group: .prayer,
              aliases: ["saff", "sufuf", "lines", "taswiyah", "front row", "shoulders", "feet", "gaps", "draw lots", "anas", "nu'man ibn bashir", "congregation"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Before he said the takbir the Prophet turned to the rows behind him and set them straight, and he gave the reason: a straight row is part of the prayer itself. Anas reported the command, and in another report added how the Companions obeyed it, each man's shoulder against the shoulder of the man beside him and his foot against his foot."),
                      .hadith("bukhari:723", cite: "Sahih al-Bukhari 723", arabic: 19...26, english: 4...20),
                      .hadith("bukhari:725", cite: "Sahih al-Bukhari 725", arabic: 20...35, english: 4...39),
                      .text("Of the first row he said that people would draw lots for it if they knew what it holds, naming it beside the adhan, the early coming to Dhuhr, and 'Isha and Fajr in congregation:"),
                      .hadith("bukhari:615", cite: "Sahih al-Bukhari 615", arabic: 29...61, english: 4...90),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the iqamah is called, go to the first row if there is a place in it, and fill each row from the middle outward, behind the imam, rather than from the edge. He said to complete the front row, then the one next to it, and to let any shortfall be in the last row (Sunan Abi Dawud 671; graded sahih by al-Albani), so a new row is not begun while the one in front has room."),
                      .text("Stand so that your shoulder touches your neighbour's shoulder and the side of your foot is near his, without straining or spreading the feet wide; he said to line up the shoulders, close the gaps, be yielding in the hands of your brothers and leave no openings for Shaytan, and that whoever joins a row Allah joins him (Sunan Abi Dawud 666; graded sahih by al-Albani). When the imam says straighten the rows, move rather than nod."),
                      .text("Keep the rows straight for the whole prayer: if the man beside you leaves, close the gap by moving across. Women praying behind the men keep their rows the same way, and for them he said the best row is the last one and the worst the first (Sahih Muslim 440), since it is the farthest from the men; the merit of the first row is for the men's rows and for women praying by themselves."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He made a straight row part of establishing the prayer, and warned the Companions that if they did not straighten their rows Allah would set their faces at odds (Sahih al-Bukhari 717), which the scholars read as division among their hearts following division in their lines. The first row carries a reward he compared to a prize worth drawing lots over, and it is also the row of those who came early and the one nearest the imam's recitation."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn 'Uthaymin held that straightening the rows is obligatory, on the view he preferred from the warning in the hadith, while most scholars count it a stressed sunnah; the first row is a merit, and the one who cannot reach it has lost nothing of his prayer."),
                  ]),
              ]),
        .init(id: "sujud-tilawah", title: "The prostration of recitation",
              summary: "At an ayah of sajdah, in prayer or out of it, say the takbir and prostrate once, as he and the Companions did.",
              group: .prayer,
              aliases: ["sajdah tilawah", "sajdat al-tilawah", "sujood", "sajda", "verse of prostration", "ayat sajdah", "recitation", "an-najm", "ibn umar", "umar", "forehead", "fifteen"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Certain ayahs of the Quran, fifteen on the count most scholars keep, describe prostration or call for it, and when the Prophet recited one of them he went down in prostration where he was, and whoever was listening went down with him. Ibn 'Umar remembered the crowding: so many prostrated around him that some could find no room for their foreheads. In Makkah, when he recited an-Najm, everyone present prostrated except one old man who lifted a handful of earth to his forehead and said it was enough for him (Sahih al-Bukhari 1067)."),
                      .hadith("bukhari:1075", cite: "Sahih al-Bukhari 1075", arabic: 20...38, english: 0...35),
                      .text("Muslim's wording adds that this was outside the prayer, so the prostration follows the ayah wherever it is read:"),
                      .hadith("muslim:575b", cite: "Sahih Muslim 575b", arabic: 21...46, english: 0...55),
                      .text("'Umar showed its standing from the minbar, on two Fridays in a row:"),
                      .hadith("bukhari:1077", cite: "Sahih al-Bukhari 1077", arabic: 55...121, english: 0...108),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you reach an ayah of sajdah in the prayer, say Allahu akbar and go down into a single prostration from standing, say Subhana Rabbiyal A'la (glory be to my Lord, the Most High) as in any sujud, then say Allahu akbar and stand up again and carry on reciting. There is no sitting after it and no tashahhud; it is one prostration inside the rak'ah. Behind an imam, follow him down and up."),
                      .text("Outside the prayer, do the same: on reaching the ayah, prostrate once from where you sit, with the glorification, and sit up; the scholars allow the takbir going down, and no salam follows. The marked ayahs in this app's mushaf show where the places are, and a listener prostrates when the reciter he is listening to prostrates, as the Companions did around him."),
                      .text("Add, if you like, the words 'A'ishah reported from him in this prostration at night: Sajada wajhiya lilladhi khalaqahu wa shaqqa sam'ahu wa basarahu bi-hawlihi wa quwwatih (my face has prostrated to the One who created it and opened its hearing and its sight by His might and His power) (Sunan al-Tirmidhi 580; graded sahih by al-Albani). The glorification alone is enough."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He said that when the son of Adam recites an ayah of sajdah and prostrates, Shaytan withdraws weeping, saying that the son of Adam was commanded to prostrate and did, and Paradise is his, while he himself was commanded and refused, and the Fire is his (Sahih Muslim 81). The prostration answers the ayah with the act it describes, and the scholars count it among the easiest sunnahs of reciting, since the Quran itself tells the reader where to go down."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The prostration of recitation is recommended, not obligatory, as 'Umar's words from the minbar settle: whoever prostrates has done well, and there is no sin on the one who does not. Most scholars require wudu for it as for the prayer; Ibn Taymiyyah and Ibn 'Uthaymin held that it is not a prayer and needs none, so on their view a reader without wudu may still prostrate."),
                  ]),
              ]),
        .init(id: "sujud-shukr", title: "The prostration of thanks",
              summary: "When good news came he fell in prostration, thanking Allah: one sujud, outside the prayer, with praise.",
              group: .prayer,
              aliases: ["sajdah shukr", "sajdat al-shukr", "sujood", "gratitude", "thankfulness", "good news", "glad tidings", "abu bakrah", "ka'b ibn malik", "blessing", "nimah", "relief"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When something came to the Prophet that gladdened him, news of a victory, a tribe's acceptance of Islam, a relief sent down, he did not wait: he went down in prostration where he was, thanking Allah. Abu Bakrah reported it as his settled habit, and Abu Dawud and Ibn Majah both recorded it from him."),
                      .hadith("abudawud:2774", cite: "Sunan Abi Dawud 2774; graded sahih by al-Albani", arabic: 27...39, english: 0...23),
                      .hadith("ibnmajah:1394", cite: "Sunan Ibn Majah 1394; graded hasan by al-Albani", arabic: 30...51, english: 0...36),
                      .text("The Companions learned it from him. When Ka'b ibn Malik, after fifty days cut off from everyone over his absence from Tabuk, heard a voice calling from the hill that his repentance had been accepted, the first thing he did was fall in prostration, knowing that relief had come (Sahih al-Bukhari 4418)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When good news reaches you, a child born, an illness lifted, an exam passed, a debt cleared, a Muslim guided, go down in a single prostration wherever you are, facing the qiblah if you can. Say Allahu akbar as you go down if you wish; there is no tashahhud and no salam after it. It is one prostration, and then you sit up."),
                      .text("In the prostration, praise Allah for the thing itself: Al-hamdu lillah (praise be to Allah), with the glorification of sujud and any words of thanks you have. The narration records the act, not a wording, so thank Him in the words the news brings to mind, and ask Him to bless what He has given and to keep it."),
                      .text("Keep it for what pleases you and, as the scholars add, for a harm turned away, since the Prophet prostrated at glad news of every kind. It is not done inside the prayer: good news that reaches you while praying waits until the salam, and the prostration follows then."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The scholars draw the sense from the act: the right response to a blessing is to acknowledge the One who sent it, and the lowest posture a body can take is the clearest way to say so. A prostration of thanks turns a moment of joy towards Allah before it turns anywhere else, and keeps the one who receives from thinking the good came from his own hand. It was his way, and the way of Ka'b and the Companions after him."),
                  ]),
                  SignSection("A NOTE", [
                      .text("On the stronger view with the scholars, wudu and facing the qiblah are not conditions for the prostration of thanks, since it is not a prayer and good news comes without warning; Ibn 'Uthaymin ruled this way, and the Permanent Committee counted it a sunnah whenever a fresh blessing arrives or a harm is lifted."),
                  ]),
              ]),
        .init(id: "before-maghrib", title: "Two rak'ahs before Maghrib",
              summary: "Between the Maghrib adhan and the iqamah, two light rak'ahs: pray before Maghrib, he said, for whoever wishes.",
              group: .prayer,
              aliases: ["sunset", "before maghrib", "between the two calls", "adhan and iqamah", "pillars", "sawari", "anas", "abdullah al-muzani", "nafl", "light rak'ahs", "two rakat", "whoever wishes"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The gap between the Maghrib adhan and the iqamah is the shortest in the day, and the Prophet asked that it be used. Pray before Maghrib, he said, three times over, and on the third he added for whoever wishes, because he did not want people to take it as a fixed sunnah. 'Abdullah al-Muzani reported it:"),
                      .hadith("bukhari:1183", cite: "Sahih al-Bukhari 1183", arabic: 25...41, english: 4...44),
                      .text("The Companions took him at his word. Anas described the masjid in Madinah at sunset:"),
                      .hadith("muslim:837", cite: "Sahih Muslim 837", arabic: 20...46, english: 0...55),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the Maghrib adhan is called, answer it, then stand and pray two rak'ahs before the iqamah: al-Fatihah and a short surah in each, kept light, since the gap is short and the congregation is about to begin. Pray them in the masjid, towards a pillar or a wall as the Companions did, or at home if you pray Maghrib there."),
                      .text("If the iqamah is called while you are in them, stop and join the obligatory prayer unless you are in the final moments; the two are for whoever wishes, and the congregation is not to be missed for them. Where the masjid gives no gap at all, the sunnah is simply not available that day, and nothing is owed."),
                      .text("Keep them as a habit rather than a rule: he left them to the one who wishes, and the scholars read his reason as a caution against counting them with the regular sunnahs. Pray them most days, leave them without guilt when there is no time, and never let them delay the congregation."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration carries his encouragement three times over, and the sight of the Companions hurrying to the pillars, so many that a stranger thought the prayer had already been prayed, shows how they understood it. He said that there is a prayer between every two calls, for whoever wishes (Sahih al-Bukhari 627), and these two rak'ahs are that prayer at the one time of day when the two calls come closest together."),
                  ]),
                  SignSection("A NOTE", [
                      .text("These two rak'ahs are not among the twelve regular sunnahs, the rawatib, which have their own page: those are the two after Maghrib, not before it. Pray before Maghrib is a recommendation for whoever wishes, and his addition the third time was meant to keep it so."),
                  ]),
              ]),
        .init(id: "four-before-asr", title: "Four rak'ahs before 'Asr",
              summary: "May Allah have mercy on a man who prays four before 'Asr: a voluntary four, prayed two and two.",
              group: .prayer,
              aliases: ["asr", "afternoon", "before asr", "four rakat", "four rak'ahs", "mercy", "rahima allah", "ibn umar", "ali", "nafl", "two and two", "taslim"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The regular sunnahs the Companions counted from the Prophet have no prayer before 'Asr, but he asked for one, and he asked for it with a supplication of his own for whoever keeps it. Ibn 'Umar reported the words, and al-Tirmidhi and Abu Dawud (1271) both record them:"),
                      .hadith("tirmidhi:430", cite: "Sunan al-Tirmidhi 430; graded hasan by al-Albani", arabic: 38...45, english: 4...15),
                      .text("'Ali described how he prayed them himself, with a salam in the middle:"),
                      .hadith("tirmidhi:429", cite: "Sunan al-Tirmidhi 429; graded hasan by al-Albani", arabic: 26...47, english: 0...32),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("After the 'Asr adhan and before the iqamah, pray four rak'ahs as two and two: two rak'ahs with a salam, then two more with a salam, as 'Ali described and as Ibn Baz advised. Keep them unhurried but not long; al-Fatihah and a short passage in each is enough, and the whole takes a few minutes."),
                      .text("Pray them at home before you leave, or in the masjid on arriving, where they also stand in for the greeting of the masjid. If time is short, pray two with one salam; the four are the fuller form the narration names, and the supplication for mercy was made for the one who prays them, so aim at four and keep what you can."),
                      .text("Treat them as a gift to the afternoon rather than a duty. Four rak'ahs before 'Asr bring a person to the congregation early, in wudu and settled, at the hour when work and errands pull hardest. The Companions who kept them did so quietly and steadily, which is how the scholars advise keeping every voluntary prayer."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is the Prophet's own supplication: may Allah have mercy on the one who prays these four. The scholars note that a dua from him is the surest kind of encouragement, and they place these rak'ahs among the voluntary prayers he urged without fixing, like the two before Maghrib. Four short rak'ahs each afternoon put a person under a supplication the Prophet made in person."),
                  ]),
                  SignSection("A NOTE", [
                      .text("These four are not among the rawatib, the twelve regular sunnahs, so leaving them is not like leaving the two before Fajr; and the scholars differ on their form, Ibn Baz holding from 'Ali's report that they are prayed as two and two with two salams, others allowing four with one."),
                  ]),
              ]),
    ]

    // MARK: Through the day

    static let dayEntries: [Entry] = [
        .init(id: "hundred-tahlil", title: "A hundred times: there is no god but Allah",
              summary: "The tahlil a hundred times a day: ten slaves freed, a hundred sins erased, and a guard from Shaytan till evening",
              group: .day,
              aliases: ["la ilaha illallah", "tahlil", "wahdahu la sharika lah", "lahul mulk", "dhikr", "hundred", "100", "abu hurayrah", "manumission", "freeing slaves", "protection", "satan"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Of all the remembrances, the Prophet set the tahlil apart: the plain statement that there is no god but Allah, alone, without partner, that the kingdom and the praise are His and that He has power over all things. Said a hundred times in a day, he attached four rewards and a rank to it: the reward of freeing ten slaves, a hundred good deeds written, a hundred bad deeds wiped away, and a guard against Shaytan until evening. Abu Hurayrah narrated it, and al-Bukhari and Muslim both recorded it."),
                      .hadith("bukhari:3293", cite: "Sahih al-Bukhari 3293", arabic: 33...90, english: 4...112),
                      .text("Muslim's report carries the same words with the same count and the same promises, and joins a second hundred to it, the tasbih that is the next page of this library (Sahih Muslim 2691). The last line of the hadith is the one the scholars dwell on: no one brings anything better on that day than this, except someone who says it more."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Learn the words until they come by themselves: La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu, wa huwa 'ala kulli shay'in qadir (there is no god but Allah alone, without partner; His is the kingdom and His is the praise, and He has power over all things). They are also part of the morning remembrances, so most readers already have them."),
                      .text("Spread the hundred across the day or say it in one sitting; the narration says in a day and fixes no time and no place. Many keep it after Fajr, on the way to work, or while waiting, counted on the fingers of the right hand. The guard from Shaytan runs until evening, which is why the scholars like the morning for it."),
                      .text("Keep the count honest and do not stop at it. The hadith ends by saying that only the one who does more does better, so a hundred is the floor and not the ceiling; and the count is of words said with attention, not of beads passed through the fingers."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is spelled out in his own words: the worth of freeing ten slaves, a hundred good deeds, a hundred sins wiped out, and shelter from Shaytan from morning until evening, with no one doing better that day except the one who says more. The tahlil is the first half of the testimony of faith, and he called it the best of all remembrance (Sunan al-Tirmidhi 3383, graded hasan by al-Albani); a hundred of it takes a few minutes and costs nothing."),
                  ]),
              ]),
        .init(id: "hundred-tasbih", title: "A hundred times: glory and praise to Allah",
              summary: "Subhanallahi wa bihamdihi a hundred times a day wipes out sins even if they are like the foam of the sea",
              group: .day,
              aliases: ["subhanallah", "subhan allah wa bihamdihi", "tasbih", "tahmid", "glorification", "light on the tongue", "heavy on the scale", "foam of the sea", "al-azim", "dhikr", "hundred", "abu hurayrah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Beside the tahlil the Prophet set a second hundred, shorter still: Subhanallahi wa bihamdihi, glory be to Allah and praise to Him. Four words, and for a hundred of them in a day he promised that a person's sins are wiped out even if they are as much as the foam of the sea. Abu Hurayrah narrated it, and al-Bukhari placed it in his chapter on the merit of tasbih."),
                      .hadith("bukhari:6405", cite: "Sahih al-Bukhari 6405", arabic: 30...45, english: 4...32),
                      .text("Muslim's report ties the same hundred to the two ends of the day, morning and evening, and promises that no one comes on the Day of Resurrection with anything better except one who said the same or more:"),
                      .hadith("muslim:2692", cite: "Sahih Muslim 2692", arabic: 31...60, english: 0...53),
                      .text("And he said why these words weigh so much. Two phrases, he said, are light on the tongue, heavy in the balance, and beloved to the Most Merciful:"),
                      .hadith("bukhari:6406", cite: "Sahih al-Bukhari 6406", arabic: 24...39, english: 4...44),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Say Subhanallahi wa bihamdihi (glory be to Allah and praise to Him) a hundred times in the day. The words take a second each; the whole hundred is done in two or three minutes, on the fingers, while walking or waiting, without anyone noticing."),
                      .text("Follow Muslim's report and make it a hundred in the morning and a hundred in the evening, with the other remembrances of those two times. The two hundreds are the same words: a hundred in the day is what al-Bukhari's report promises the forgiveness for, Muslim's report sets it at both ends, and keeping both is the fuller sunnah."),
                      .text("Pair it with its sister phrase, Subhanallahil-'azim (glory be to Allah the Mighty), the other half of the two that are heavy in the balance; and with the tahlil of the page before, which Muslim's report joins to it in one hadith. The three together are the Prophet's own daily set."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He named the reward: sins wiped out even if they were like the foam of the sea, and on the Day of Resurrection nothing better in anyone's hands except the one who said more. The words themselves are praise and glorification at once, Allah declared free of every fault and thanked for every gift, which is why he called them heavy in the balance though they are light on the tongue. Nothing in the day gives so much for so little."),
                  ]),
              ]),
        .init(id: "daily-istighfar", title: "Seek forgiveness through the day",
              summary: "He asked Allah's forgiveness and turned to Him more than seventy times a day, and in another report a hundred",
              group: .day,
              aliases: ["istighfar", "astaghfirullah", "atubu ilayh", "tawbah", "repentance", "forgiveness", "seventy", "hundred", "veil on the heart", "agharr al-muzani", "abu hurayrah", "dhikr"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet's past and future sins were forgiven, and still he sought Allah's forgiveness more often than anyone around him. Abu Hurayrah heard him swear to it: more than seventy times in a day he asked forgiveness and turned in repentance. Al-Agharr al-Muzani reported a second count from him, a hundred, with the reason attached, a veil that comes over the heart."),
                      .hadith("bukhari:6307", cite: "Sahih al-Bukhari 6307", arabic: 28...39, english: 6...25),
                      .hadith("muslim:2702a", cite: "Sahih Muslim 2702a", arabic: 42...52, english: 0...21),
                      .text("The scholars read the veil in Muslim's report as the small dimness that even the business of the day lays over the heart of one used to the presence of Allah, and his istighfar as the wiping of it. The Quran promises the one who seeks forgiveness after a wrong that he will find Allah Forgiving and Merciful:"),
                      .quran("4:110"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Say astaghfirullaha wa atubu ilayh (I seek Allah's forgiveness and I turn to Him in repentance), the words of Abu Hurayrah's report, or astaghfirullah on its own, through the day: after a lapse, after a sharp word, in a queue, between tasks. The narrations fix no time, and his own count was spread across the day rather than said in one sitting."),
                      .text("Say it most of all after the prayers, where it already belongs: three times as the first words after the salam, as the page on the remembrances after the prayer gives. Those three at each of five prayers are fifteen of the seventy before the day's own occasions are counted."),
                      .text("Let the words carry a real turning. Istighfar is asking to be forgiven and tawbah is turning away from the sin, and his report names both. A sin remembered should bring the words at once, and the words should bring a resolve not to go back, or the count is only a count."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("If the one whose sins were forgiven sought forgiveness seventy and a hundred times a day, the scholars say, the rest of us need it more, not less. The reports also show that istighfar is not only for after a sin: he said it against a veil on the heart, a dulling, which makes the words a daily cleaning and not only a remedy. The sayyid al-istighfar of the morning page is the fullest form; this is the short one for every hour between."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Seventy and a hundred are his own practice, reported of him, not a number set for anyone else; the scholars say more is better and no count is required."),
                  ]),
              ]),
        .init(id: "anger-refuge", title: "When anger rises, seek refuge and sit down",
              summary: "Seek refuge from Shaytan, sit if standing, lie down if it stays: the three steps he gave against anger",
              group: .day,
              aliases: ["anger", "angry", "ghadab", "la taghdab", "rage", "temper", "isti'adhah", "a'udhu billah", "sulayman ibn surad", "abu dharr", "calm down", "shaytan"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Sulayman ibn Surad was sitting with the Prophet when two men began to abuse each other, and one of them went red in the face with the veins of his neck standing out. The Prophet said that he knew a word that would take the anger away if the man said it: I seek refuge with Allah from Shaytan. The man, told what the Prophet had said, asked whether anyone thought he was mad; the anger had already closed his ears, which is why al-Bukhari placed the report among the hadiths on Shaytan and his soldiers."),
                      .hadith("bukhari:3282", cite: "Sahih al-Bukhari 3282", arabic: 16...57, english: 0...74),
                      .text("Muslim's report gives the words in full, with the accursed added:"),
                      .hadith("muslim:2610a", cite: "Sahih Muslim 2610a", arabic: 50...63, english: 0...31),
                      .text("Abu Dharr reported a second remedy, for the body rather than the tongue: the angry man who is standing should sit, and if the anger has not left him he should lie down. And when a man asked the Prophet for advice, the whole of it was two words, said over and over."),
                      .hadith("abudawud:4782", cite: "Sunan Abi Dawud 4782; graded sahih by al-Albani", arabic: 32...43, english: 8...32),
                      .hadith("bukhari:6116", cite: "Sahih al-Bukhari 6116", arabic: 26...46, english: 0...36),
                      .text("The Quran names restraining anger among the marks of the people Allah loves:"),
                      .quran("3:134"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("The moment you feel it rising, say a'udhu billahi minash-shaytanir-rajim (I seek refuge with Allah from Shaytan, the accursed). He said it is a word that makes what the angry man feels go away, so say it before you answer, not after, and say it again if the first did not take."),
                      .text("Change your posture. If you are standing, sit; if sitting does not calm you, lie down. Abu Dharr's report is a ladder with two rungs, and each one takes you further from the blow or the step forward that anger wants."),
                      .text("Hold your tongue and your hand until it has passed. Do not get angry, said again and again, is read by the scholars as do not act on it: do not speak, decide, divorce, strike or write while it has you. The thing you were going to say will still be sayable when you are calm, if it was worth saying."),
                      .text("Afterwards, make up what the anger damaged: an apology if a word got out, a kindness to the one it was aimed at. Keeping this sunnah is not never feeling anger, which he felt himself when the limits of Allah were crossed, but never letting it drive."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He showed anger to be the work of Shaytan by giving the refuge-seeking as its cure, and he tied the whole of a man's religion to it when he answered a request for advice with nothing but do not get angry. The scholars note that the three steps rise in cost, a word, a change of seat, a lying down, and that each is cheaper than what anger costs; a man who has sat down has already lost the posture that a blow needs."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The narration that tells the angry man to make wudu because anger is from fire (Sunan Abi Dawud 4784) is graded weak by al-Albani, so it is not among the steps here; wudu does no harm, but the sunnah rests on the refuge, the sitting and the lying down. Anger for the sake of Allah, when His limits are crossed, is not what the advice forbids."),
                  ]),
              ]),
        .init(id: "calamity-dua", title: "The words for a loss",
              summary: "Inna lillahi wa inna ilayhi raji'un, with a plea for reward and for something better: Allah replaces what was lost",
              group: .day,
              aliases: ["istirja", "inna lillahi", "raji'un", "musibah", "calamity", "affliction", "loss", "grief", "umm salamah", "abu salamah", "ajurni", "patience"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When a loss comes the Quran gives the believer his first words, and the Prophet gave a dua to follow them. Umm Salamah heard him promise that any Muslim struck by a calamity who says what Allah commanded, we belong to Allah and to Him we return, and then asks Allah to reward him in it and give him better in its place, will be given better in its place. Then her husband Abu Salamah died, and she tells what happened when she said the words herself."),
                      .hadith("muslim:918a", cite: "Sahih Muslim 918a", arabic: 46...112, english: 0...90),
                      .text("The first half of the dua is the ayah itself. Allah tells the believers they will be tested with fear, hunger and loss, names the patient as those who say these words when a loss strikes, and names what they receive:"),
                      .quran("2:155-157"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When a loss strikes, a death, an illness, a job, a thing broken or stolen, say first what Allah commanded: inna lillahi wa inna ilayhi raji'un (we belong to Allah, and to Him we return). Say it at once, before the complaint forms; the ayah ties it to the moment the calamity strikes."),
                      .text("Then add the Prophet's words: Allahumma'jurni fi musibati wakhluf li khayran minha (O Allah, reward me in my calamity and give me in its place something better than it). The two halves go together: the ayah is submission, the dua is a request, and the promise in the hadith is attached to both."),
                      .text("Say it for small losses too; a musibah is anything that hurts, and the habit built on small ones holds when the great one comes. Umm Salamah said the words over the best of husbands, as she thought, not expecting better; the exchange was Allah's to choose, and so it is for anyone who says them."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The promise is in his words and in hers: Allah gives in exchange something better than what was lost, and Umm Salamah, who could not imagine a better man than Abu Salamah, was married to the Prophet. The ayah adds what the words bring in themselves, blessings from the Lord, mercy, and the name of the rightly guided. The words also set the loss in its place: the thing was Allah's, it has gone back to Him, and so will the one who lost it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The exchange is in Allah's hands, not a promise of the same thing back or of a reward one can name. Muslim's other report (Sahih Muslim 918b) adds that Allah rewards the person in the calamity as well as replacing it, both halves of the dua answered."),
                  ]),
              ]),
        .init(id: "yunus-dua", title: "The dua of Yunus",
              summary: "La ilaha illa anta subhanaka inni kuntu minaz-zalimin: no Muslim calls on Allah with it but is answered",
              group: .day,
              aliases: ["dhun-nun", "dhul nun", "jonah", "whale", "fish", "belly", "zalimin", "subhanaka", "distress", "hardship", "sa'd ibn abi waqqas", "answered dua"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Yunus called to his Lord from inside the fish, in the dark, and the Quran records his words and the answer. The Prophet told Sa'd ibn Abi Waqqas that this dua of Dhun-Nun, the man of the fish, is one that no Muslim ever calls with for anything but Allah answers him, and al-Tirmidhi recorded it."),
                      .hadith("tirmidhi:3505", cite: "Sunan al-Tirmidhi 3505; graded sahih by al-Albani", arabic: 33...64, english: 0...58),
                      .text("The words are the Quran's own, in Surat al-Anbiya, and the ayah after them is the answer: Allah responded and saved him from the distress, and so, it says, does He save the believers."),
                      .quran("21:87-88"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Learn the words exactly as the ayah has them: La ilaha illa anta, subhanaka, inni kuntu minaz-zalimin (there is no god but You; glory be to You; I have been among the wrongdoers). They are three sentences: Allah's oneness, Allah's perfection, and the speaker's own fault."),
                      .text("Say them in any distress, large or small: a debt, an illness, a fear for a child, a wrong you cannot undo. The hadith says for anything, so no matter is too small for it. Say them with the meaning, the way Yunus said them, as a plea rather than a formula, and repeat them as often as the need lasts."),
                      .text("Say them in good times too, as a dhikr. Each of the three sentences is a remembrance in its own right, and the Prophet's words put no limit on when; the one who has the words on his tongue in ease will have them ready in the dark."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He said the answer is promised: no Muslim calls with these words for anything but Allah answers him. The scholars find the reason in the words themselves, which hold tawhid, glorification, and the confession of one's own wrong, the three things a plea needs; and in the ayah's closing line, that as Allah saved Yunus, so He saves the believers. It is a dua that a prophet said in the belly of a fish, in darkness upon darkness, and was heard."),
                  ]),
              ]),
        .init(id: "rain-wind-dua", title: "The words for rain and for wind",
              summary: "At rain: a beneficial downpour, O Allah. At wind: ask its good and seek refuge from its evil, and never curse it",
              group: .day,
              aliases: ["sayyiban nafi'an", "rain dua", "wind dua", "storm", "weather", "rih", "matar", "clouds", "a'ishah", "do not curse the wind", "thunder", "ursilat bihi"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Weather was not a small thing to the Prophet. 'A'ishah said that when he saw rain he prayed for it to be beneficial, and that when the wind blew hard he asked Allah for its good and took refuge from its evil; and that until the rain actually fell a dark sky showed on his face, because he feared it might be a punishment, as the cloud that came to the people of 'Ad had been."),
                      .hadith("bukhari:1032", cite: "Sahih al-Bukhari 1032", arabic: 33...42, english: 0...19),
                      .hadith("muslim:899b", cite: "Sahih Muslim 899b", arabic: 26...79, english: 0...108),
                      .text("He also forbade cursing the wind, because it is sent, and told the Companions what to do instead:"),
                      .hadith("ibnmajah:3727", cite: "Sunan Ibn Majah 3727; graded sahih by al-Albani", arabic: 29...47, english: 0...34),
                      .text("The Quran describes rain as mercy spread after despair:"),
                      .quran("42:28"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When rain falls, say sayyiban nafi'an (a beneficial downpour), the two words of al-Bukhari's report, or with the opening that al-Nasa'i's report carries: Allahummaj'alhu sayyiban nafi'an (O Allah, make it a beneficial downpour; Sunan an-Nasa'i 1523, graded sahih by al-Albani). Say it when you first see or hear the rain, once or a few times."),
                      .text("When the wind is strong, say: Allahumma inni as'aluka khayraha wa khayra ma fiha wa khayra ma ursilat bihi, wa a'udhu bika min sharriha wa sharri ma fiha wa sharri ma ursilat bihi (O Allah, I ask You for its good, the good in it and the good it was sent with, and I seek refuge in You from its evil, the evil in it and the evil it was sent with)."),
                      .text("Never curse the wind, the rain, the cold or the heat; they do what they are sent to do. When the weather is against you, turn the complaint into the dua of the step before, asking Allah for its good and refuge from its harm, which is exactly what he told the Companions to do instead of cursing."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The dua turns a thing everyone talks about into a remembrance, and it keeps the heart where his was: he knew rain could be mercy and wind could be punishment, since the people of 'Ad were destroyed by a wind they took for rain, and he met both with a plea rather than a comment. The prohibition on cursing the wind rests on the same point: it is sent by Allah, bringing mercy or punishment, and a creature under orders is not to be abused."),
                  ]),
                  SignSection("A NOTE", [
                      .text("After rain, he taught the Companions to say that they had been given it by the grace and mercy of Allah, and not to credit it to a star or a season (Sahih al-Bukhari 846). Sayyiban nafi'an is what al-Bukhari's report has; the Allahumma before it is from the other reports, and either is the sunnah."),
                  ]),
              ]),
        .init(id: "rooster-donkey", title: "The rooster and the donkey",
              summary: "A rooster's crow: ask Allah of His bounty, it has seen an angel. A donkey's bray: seek refuge, it has seen a devil",
              group: .day,
              aliases: ["cock", "crowing", "rooster", "donkey", "braying", "angel", "devil", "shaytan", "fadlihi", "bounty", "abu hurayrah", "animals"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Two sounds of the countryside carry a signal from the unseen, and the Prophet told his Companions what each one means and what to say. A rooster crows because it has seen an angel; the one who hears it should ask Allah of His bounty. A donkey brays because it has seen a devil; the one who hears it should seek refuge with Allah from Shaytan. Abu Hurayrah narrated it, and al-Bukhari and Muslim both recorded it (Sahih Muslim 2729)."),
                      .hadith("bukhari:3303", cite: "Sahih al-Bukhari 3303", arabic: 27...48, english: 4...48),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you hear a rooster crow, by day or in the night, ask Allah for something of His bounty. The narration fixes no words, so ask in your own, for instance Allahumma inni as'aluka min fadlik (O Allah, I ask You of Your bounty); the scholars say the moment is one in which an angel is near, and a dua then is hoped to be answered."),
                      .text("When you hear a donkey bray, say a'udhu billahi minash-shaytanir-rajim (I seek refuge with Allah from Shaytan, the accursed). Another report adds the barking of dogs at night to the braying, with the same refuge, because they see what we do not (Sunan Abi Dawud 5103, graded sahih by al-Albani), so the words serve for that too."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration opens a window on what the animals see and we do not: an angel at the rooster's crow, a devil at the donkey's bray. He gave the two sounds two responses, a request at the sign of the angel and a refuge at the sign of the devil, so that a believer's first thought at each is of Allah. It is one of the plainest examples of how he filled the ordinary moments of a day with remembrance."),
                  ]),
              ]),
        .init(id: "seeing-afflicted", title: "On seeing someone afflicted",
              summary: "Praise Allah quietly for sparing you what He tested another with, and that affliction will not strike you",
              group: .day,
              aliases: ["mubtala", "afflicted", "affliction", "bala", "disability", "illness", "misfortune", "afani", "faddalani", "praise", "alhamdulillah", "abu hurayrah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Health, sound limbs and a steady mind are gifts most people notice only when they see someone without them. The Prophet taught words for exactly that moment: on seeing a person afflicted, praise Allah who spared you what He tested him with and favoured you over many of His creatures. He attached a promise to it, that the one who says it will not be struck by that affliction. Abu Hurayrah narrated it and al-Tirmidhi recorded it."),
                      .hadith("tirmidhi:3432", cite: "Sunan al-Tirmidhi 3432; graded sahih by al-Albani", arabic: 39...59, english: 6...61),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you see someone afflicted, a sickness, a disability, a ruin, or an open sin, say: Alhamdulillahil-ladhi 'afani mimma'btalaka bihi wa faddalani 'ala kathirin mimman khalaqa tafdila (praise be to Allah who spared me what He tested you with, and favoured me greatly over many of those He created)."),
                      .text("Say it to yourself, under your breath. The words are addressed to Allah about the person, not to the person, and someone who is already suffering should not have to hear a stranger thanking Allah for not being him; keep it between you and your Lord."),
                      .text("Let it be gratitude and not pride. The words praise Allah for a favour, and a favour can be withdrawn; say them as one who knows that the difference between him and the afflicted is nothing he earned. Then do for the afflicted what you can: a dua for him, a visit, a hand."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He named the reward, protection from that affliction, and the words give the reason: the one who sees his health as Allah's favour and says so is in a different state from the one who takes it for granted. The scholars read it as a sunnah of gratitude, which the Quran promises to answer with more (14:7), and count the affliction as anything Allah has tested a person with, in his body, his wealth or his religion."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The words are said quietly, out of the afflicted person's hearing, so that he is not wounded by them; that is the etiquette the scholars attach to this sunnah, with the one exception of a sin done openly, where saying it within hearing may serve as a warning. Zubair 'Ali Za'i grades the report weak where Ahmad Shakir and al-Albani call it sahih, and al-Tirmidhi called it hasan gharib."),
                  ]),
              ]),
        .init(id: "new-moon-dua", title: "On seeing the new moon",
              summary: "On seeing the crescent: O Allah, bring it over us with blessing and faith, safety and Islam; my Lord and yours is Allah",
              group: .day,
              aliases: ["hilal", "crescent", "new moon", "moon sighting", "month", "ramadan", "shawwal", "ahillahu", "yumn", "talhah", "lunar", "calendar"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The months of Islam begin with the sighting of the crescent, and the Prophet met each one with a dua. Talhah ibn 'Ubaydullah reported the words: that Allah bring the new moon over us with blessing and faith, safety and Islam, and then a sentence addressed to the moon itself, my Lord and your Lord is Allah, which puts the crescent in its place as a creature and not a power. Al-Tirmidhi recorded it."),
                      .hadith("tirmidhi:3451", cite: "Sunan al-Tirmidhi 3451; graded sahih by al-Albani", arabic: 43...52, english: 22...53),
                      .text("The Quran had already answered those who asked what the crescents are for: they are measures of time for people, and for the Hajj."),
                      .quran("2:189"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you see the crescent of a new month, say: Allahumma ahillahu 'alayna bil-yumni wal-iman, was-salamati wal-islam, rabbi wa rabbukallah (O Allah, bring it over us with blessing and faith, with safety and Islam; my Lord and your Lord is Allah)."),
                      .text("Say it for any month, not only Ramadan; the report says the crescent without limiting it. Look for it at sunset on the twenty-ninth of the month, low in the west above where the sun went down, and if you catch it, say the words there. The report ties the words to the seeing, so they belong to the moment you see it."),
                      .text("Let the last sentence land. Rabbi wa rabbukallah is said to the moon: it is a created thing on its course, and the one who greets it with these words closes the door on any fear or honour owed to it. Then begin the month with what it brings: Ramadan with the fast, Dhul-Hijjah with its ten days, any month with its white days."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The dua asks for the four things a month can hold: blessing in it, faith through it, safety from its harms, and Islam kept to its end. The scholars count it among the sunnahs tied to time, like the words of morning and evening, which mark the turning of Allah's calendar with remembrance; and the line to the moon is a small lesson in tawhid said twelve times a year."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The dua is for the crescent of any month, said on seeing it; it is not a ritual of the first night, and there is no separate form for Ramadan. Zubair 'Ali Za'i grades the report weak where Ahmad Shakir and al-Albani call it sahih, and al-Tirmidhi himself called it hasan gharib."),
                  ]),
              ]),
        .init(id: "market-dua", title: "The dua on entering the market",
              summary: "Say the tahlil on entering the market: a million good deeds, a million sins erased, a million ranks raised",
              group: .day,
              aliases: ["suq", "souk", "souq", "market", "bazaar", "shopping", "mall", "shop", "yuhyi wa yumitu", "biyadihil khayr", "ibn umar", "million"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The market is where people are busiest with the world and least mindful of Allah, and the Prophet gave a dua for the door of it. Salim ibn 'Abdullah narrated it from his father Ibn 'Umar, from his grandfather 'Umar: whoever enters the market and says the tahlil in its long form, with He gives life and causes death, He is living and does not die, in His hand is the good, has a million good deeds written for him, a million sins erased, and a million ranks raised. Al-Tirmidhi recorded it and called it gharib, and al-Albani graded it hasan."),
                      .hadith("tirmidhi:3428", cite: "Sunan al-Tirmidhi 3428; graded hasan by al-Albani", arabic: 42...86, english: 6...109),
                      .text("A second chain of the same report, which al-Tirmidhi gives next, ends with a house built for him in Paradise in place of the ranks (Sunan al-Tirmidhi 3429, graded hasan by al-Albani). Either way the reward is out of all proportion to the act, and the scholars explain it by the place: a word of remembrance is dearest where remembrance is rarest."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("As you go into a market, a bazaar, a mall, a supermarket, any place of buying and selling, say: La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu, yuhyi wa yumitu wa huwa hayyun la yamut, biyadihil-khayr, wa huwa 'ala kulli shay'in qadir (there is no god but Allah alone, without partner; His is the kingdom and His the praise; He gives life and causes death, and He is living and does not die; in His hand is all good, and He has power over all things)."),
                      .text("Say it at the entrance, once, as the report has it. The words are the tahlil of the hundred with three clauses added, so if you already keep that sunnah the market dua is learned in a minute; the added clauses are the ones that answer the market, where life, death and wealth seem to be in human hands."),
                      .text("Carry the remembrance in with you. The scholars say the dua is the door to keeping Allah in mind among the stalls: lower the gaze, deal honestly, and do not swear by Allah to sell. He said the markets are the places Allah likes least (Sahih Muslim 671), so the one who remembers Him there is doing something rare."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is stated as the narration states it: a million good deeds, a million sins wiped away, a million ranks, or in the other chain a house in Paradise. The scholars explain the size of it by the place: a word of tawhid said where everyone else is absorbed in buying and selling is worth more than the same word said at ease, because it is harder and rarer. It is also a reminder that a shop can be a place of worship, for the one who remembers."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Al-Albani graded the report hasan, as did Ahmad Shakir and Bashar 'Awwad; Zubair 'Ali Za'i grades it weak, and al-Tirmidhi called it gharib. The reward is given here exactly as the narration gives it, no more and no less."),
                  ]),
              ]),
        .init(id: "remove-harm", title: "Clear what harms from the road",
              summary: "A branch moved aside, a stone, a spill: he counted it charity, and a man was forgiven and entered Paradise for it",
              group: .day,
              aliases: ["imatat al-adha", "adha", "harm", "road", "path", "thorn", "branch", "charity", "sadaqah", "abu barzah", "abu hurayrah", "joints"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu Barzah asked the Prophet to teach him something he could profit by, and the whole answer was: remove what harms from the path of the Muslims. He told the Companions of a man who did exactly that, moved a thorny branch off the road, and Allah thanked him for it and forgave him; in another wording a man was taken into Paradise for a tree he cut from the road because it was hurting people (Sahih Muslim 1914c)."),
                      .hadith("muslim:2618a", cite: "Sahih Muslim 2618a", arabic: 19...34, english: 0...26),
                      .hadith("muslim:1914b", cite: "Sahih Muslim 1914b", arabic: 29...43, english: 0...36),
                      .text("He also placed it in the list of the charities a person owes every day for every joint of his body, beside justice between two people, a hand with a man's load, a good word, and every step to the prayer:"),
                      .hadith("bukhari:2989", cite: "Sahih al-Bukhari 2989", arabic: 27...66, english: 4...106),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Notice the road. A branch, a stone, broken glass, a spill, a nail, a bag of rubbish, anything that could trip a walker or cut a tyre: when you pass it, move it, without waiting for whoever should have. The man in the hadith was simply walking and found a branch; he did not go looking, and neither do you have to."),
                      .text("Make it a habit rather than an event. The narration about the joints counts it among the charities owed every day the sun rises, so the eye that looks for harm on the way to the masjid or the car is keeping a daily sunnah, and the hand that moves it is paying a debt the body owes."),
                      .text("Do not be the harm. Rubbish dropped, a car left across a path, a thing left where someone will fall over it, is the opposite of this sunnah; the scholars draw from the hadith that putting harm in the road is a wrong as surely as removing it is a charity. He counted the removing among the branches of faith (Sahih Muslim 35b)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He named the reward twice: Allah forgave a man for one branch, and another was seen turning about in Paradise for a tree he cut from the road. Of all the branches of faith he called this the lowest, which the scholars take not as the least important but as the floor every believer can reach; it costs a moment and a bend of the back. And a harm removed is a kindness to people who will never know who did it, which is the purest kind."),
                  ]),
              ]),
        .init(id: "dua-absent", title: "Pray for your brother in his absence",
              summary: "Ask for a Muslim behind his back and the angel at your side says: amin, and for you the same",
              group: .day,
              aliases: ["bi zahril ghayb", "absence", "behind his back", "angel", "amin", "ameen", "wa laka bi mithl", "abu al-darda", "umm al-darda", "supplication", "brother", "sister"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu al-Darda' carried a report that his wife Umm al-Darda' passed on to anyone leaving for Hajj: when a Muslim prays for his brother behind his back, in his absence, the dua is answered, and an angel appointed to him says amin and asks the same for the one who prayed. Muslim recorded it in two forms, the shorter from Abu al-Darda' himself and the longer as Umm al-Darda' told it to a visitor."),
                      .hadith("muslim:2732a", cite: "Sahih Muslim 2732a", arabic: 36...48, english: 0...27),
                      .hadith("muslim:2733", cite: "Sahih Muslim 2733", arabic: 65...86, english: 55...97),
                      .text("The Quran gives the believers' dua for one another as a mark of the generations that came after the first:"),
                      .quran("59:10"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Name the person and ask for him by name, in his absence: a brother, a sister, a parent, a friend, a teacher, someone you heard is ill or in debt. Ask for what he needs, guidance, health, relief, forgiveness, a good end; the report says whenever he asks good for his brother, so every request counts."),
                      .text("Do not tell him, or make it a performance. The reward is tied to the absence, bi zahril-ghayb, which the scholars read as sincerity: a dua nobody will thank you for is a dua meant for Allah alone. Keep a few names in your sujud and after the prayers, where dua is answered, and add to them as you hear of needs."),
                      .text("Ask for the Muslims at large as well as the ones you know, as the ayah teaches, forgiveness for the brothers who went before in faith. Umm al-Darda' asked a man leaving for Hajj to pray for her household; ask the same of those who travel to the holy places, and do it for them in turn."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He named the reward and who delivers it: an angel at the head of the one praying says amin to the dua and asks the same for him. So a dua for another is a dua for yourself, carried by an angel, which the scholars say makes it one of the surest ways to be prayed for. It also keeps love between believers alive out of sight, where nobody is watching, and it is a way to help someone you cannot reach."),
                  ]),
              ]),
        .init(id: "jazakallah", title: "Jazakallahu khayran",
              summary: "When someone does you a kindness, say may Allah reward you with good: he called it the utmost in thanks",
              group: .day,
              aliases: ["jazakallah", "jazak allah khair", "jazakumullahu khayran", "thank you", "thanks", "gratitude", "shukr", "usamah ibn zayd", "praise", "ma'ruf", "kindness", "reward"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Thanks in the Sunnah is a dua. Usamah ibn Zayd reported that whoever has a kindness done to him and says to the one who did it jazakallahu khayran, may Allah reward you with good, has reached the utmost in praise. Al-Tirmidhi recorded it and called it hasan jayyid gharib, and al-Albani graded it sahih."),
                      .hadith("tirmidhi:2035", cite: "Sunan al-Tirmidhi 2035; graded sahih by al-Albani", arabic: 40...52, english: 0...26),
                      .text("He also said that whoever does not thank people does not thank Allah (Sunan Abi Dawud 4811, graded sahih by al-Albani), which is where the scholars place this dua: the thanks owed to people, said in words that bring Allah into it."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When someone does you a kindness, large or small, say jazakallahu khayran (may Allah reward you with good) to his face. To a woman the words are jazakillahu khayran, and to more than one person jazakumullahu khayran; the meaning is the same. Say it with the thanks you would have said anyway, not instead of looking at the person."),
                      .text("Say it for the kindnesses that are easy to pass over: the one who held a door, served the food, gave a lift, answered a question, or did his job well for you. The narration says whoever has good done to him, without measuring it, so the dua belongs to the small kindnesses as much as the great."),
                      .text("Mean the dua. Khayran is good without limit, in this world and the next, and the one who says it is asking Allah to repay what he cannot; that is why he called it the utmost in praise. A kindness returned in kind when you can is the second half, as the page on gifts describes."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He said it is the utmost in praise, because the thanks is handed to Allah, who can repay fully, rather than kept to words of one's own. The scholars note that it makes gratitude an act of worship: the one who says it has thanked a person and made dua in one breath, and the one who hears it has been prayed for. A community that thanks in these words is praying for itself all day."),
                  ]),
                  SignSection("A NOTE", [
                      .text("There is no set reply in the Sunnah; wa iyyak (and you too), or a dua in return, is fine, as the scholars say."),
                  ]),
              ]),
        .init(id: "first-fruits", title: "The first fruit to the youngest child",
              summary: "When the first fruit of the season came he prayed for blessing in it, then gave it to the smallest child present",
              group: .day,
              aliases: ["first fruits", "harvest", "season", "fruit", "dates", "children", "youngest", "barik lana", "sa'", "mudd", "madinah", "abu hurayrah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When the first fruit of a season ripened in Madinah the people would bring it to the Prophet. Abu Hurayrah describes what he did with it: he took it and prayed for blessing in the fruit, the city, and the measures it was sold by, the sa' and the mudd, recalling that Ibrahim had prayed for Makkah and asking the like for Madinah and more; then he called the youngest child there and gave the fruit to him."),
                      .hadith("muslim:1373a", cite: "Sahih Muslim 1373a", arabic: 25...98, english: 0...95),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the first of a season's fruit comes into the house, the first dates, the first figs or grapes, whatever your land gives, take it and say: Allahumma barik lana fi thamarina, wa barik lana fi madinatina, wa barik lana fi sa'ina wa barik lana fi muddina (O Allah, bless us in our fruit, bless us in our city, bless us in our sa' and bless us in our mudd). The rest of his dua was his own plea for Madinah; the blessing is what you ask for your fruit and your town."),
                      .text("Then give it to the youngest child present. The narration does not have him eat it; the first of the harvest went to the smallest person in the room, and the child learned that fruit comes with a dua and that the first and best is for giving. Make it a small occasion in the house each year, with the children watching for who is the youngest."),
                      .text("Keep the sense of the dua through the season: the harvest is a gift, the measures it is sold by are to be honest, and the town's provision is in Allah's hands. A family that marks the first fruit this way has turned the start of every season into a remembrance."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration shows a prophet's hands on the ordinary: the first fruit of the year was made an occasion for dua, for the memory of Ibrahim, and for a gift to a child. The scholars count it among the sunnahs of thankfulness for provision, and note that the blessing asked for is in the fruit, the city and the measures together, the harvest, the market and the home at once. And the child who received it remembered, which is how a sunnah lasts."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The sa' and the mudd were the measures of the Madinah market, so the dua asks for blessing in the harvest, the town and its trade at once; the sunnah of the fruit to the youngest child is kept wherever there are seasons and children."),
                  ]),
              ]),
    ]

    // MARK: More: the table, the wardrobe and the night

    static let foodEntries2: [Entry] = [
        .init(id: "third-stomach", title: "A third for food, a third for drink, a third for breath",
              summary: "The stomach is the worst vessel a person fills: a few mouthfuls suffice, and at most a third of it for food.",
              group: .food,
              aliases: ["overeating", "moderation", "stomach", "thirds", "thuluth", "miqdam", "hunger", "diet", "fullness", "gluttony", "appetite", "health"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet set out the whole of eating in one sentence. Al-Miqdam ibn Ma'dikarib heard him say that a person fills no vessel worse than his stomach, that a few mouthfuls are enough to keep him on his feet, and that if he must have more, the stomach is to be divided in three: a third for food, a third for drink, and a third left empty for breath. Ibn Majah and al-Tirmidhi both record it, and al-Tirmidhi called it hasan sahih (Sunan al-Tirmidhi 2380)."),
                      .hadith("ibnmajah:3349", cite: "Sunan Ibn Majah 3349; graded sahih by al-Albani", arabic: 32...53, english: 8...54),
                      .text("The words rest on an ayah. The Quran tells the children of Adam to eat and drink and not to be excessive, and adds that Allah does not love those who are, so the measure the Prophet gave is the measure the Book had already set:"),
                      .quran("7:31"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Stop while you could still eat. The measure he gave first is a few mouthfuls that keep the back straight: enough to work and pray on, not enough to need to lie down afterwards. Learn what that amount is for you and serve it, rather than filling the plate and eating to its edge because it is there."),
                      .text("When a meal is more than that, keep the thirds in mind: a third of the stomach for food, a third for drink, a third left for breath. The test is at the end of the meal. If you can still breathe easily and stand up without discomfort, you have kept to it; if you need to loosen your belt, you have not."),
                      .text("Keep the rest of the table's sunnahs with it: Bismillah, the right hand, the nearest part of the dish, Alhamdulillah at the end. A meal taken slowly and shared is easier to keep small; it is the plate eaten alone and in a hurry that fills the whole vessel before the stomach has had time to say so."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration gives its own reason: of all the vessels a person fills, the stomach is the worst to fill, because a full stomach weighs on the body and dulls the heart for worship. The scholars count this hadith among the foundations of health in the Sunnah, and read it beside the Quran's command to eat and drink without excess. A believer who eats to live, and not the reverse, is lighter for the night prayer and for the fast."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The thirds are a guide for the habit, not a measure to be weighed at every meal. Eating one's fill on occasion is permitted; what the hadith warns against is making a full stomach the rule, and the sick or the labourer who needs more is not under any blame."),
                  ]),
              ]),
        .init(id: "ajwa-dates", title: "Seven 'ajwah dates in the morning",
              summary: "Seven 'ajwah dates taken first thing: no poison or magic harms the one who ate them that day, by Allah's leave.",
              group: .food,
              aliases: ["ajwa", "dates", "tamr", "madinah", "poison", "magic", "sihr", "sa'd", "breakfast", "protection", "lava plains", "seven"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Sa'd ibn Abi Waqqas reported a promise attached to a small breakfast. Whoever begins the day with seven 'ajwah dates, the dark, soft dates of Madinah, is not harmed that day by poison or by magic. The word he used, tasabbaha, means to take something in the morning before anything else, and the count and the kind are both named."),
                      .hadith("bukhari:5445", cite: "Sahih al-Bukhari 5445", arabic: 27...41, english: 4...25),
                      .text("Muslim's first wording names the place instead of the kind: dates from between the two lava plains, which is how the Prophet spoke of Madinah, bounded on two sides by its tracts of black volcanic stone. The two reports together fix what the promise is about, the 'ajwah of Madinah, eaten in the morning."),
                      .hadith("muslim:2047a", cite: "Sahih Muslim 2047a", arabic: 39...52, english: 0...25),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Keep 'ajwah dates in the house. They are sold wherever dates are sold, and a box lasts for weeks; the ones grown in Madinah are what the narration names, so look for those when you can, and a pilgrim returning from the two sanctuaries can bring no better gift."),
                      .text("Eat seven of them in the morning before anything else, with Bismillah before and Alhamdulillah after, as at any meal. The count is the Prophet's and the time is the Prophet's: seven, first thing. Nothing is added to it, no words said over the dates and no particular way of eating them."),
                      .text("Take them as a means and trust Allah for the result. The protection is His, and the dates are the cause He named; the believer eats them the way he keeps any sunnah, obediently and with hope, and not as a charm that works on its own."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is the one the narration names: a day in which poison and magic cannot harm the one who ate them, by the decree of Allah who made the dates a cause. The scholars count it among the few foods the Prophet tied to a particular protection, and Ibn Hajar records al-Khattabi's reading that the benefit is by the blessing of the Prophet's supplication for the dates of Madinah, not by a property of the fruit that could be weighed."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Ibn Baz and Ibn 'Uthaymin took the hadith on its apparent meaning: the promise is for the 'ajwah of Madinah, and other dates, good as they are, do not carry it. The benefit is by Allah's leave, so the dates are eaten with trust in Him, and a person who falls ill still seeks treatment and ruqyah."),
                  ]),
              ]),
        .init(id: "honey-nigella", title: "Honey and the black seed",
              summary: "Two cures he named: honey, in which Allah says there is healing, and the black seed, a cure for all but death.",
              group: .food,
              aliases: ["asal", "habbat al-sawda", "habbatus sawda", "nigella", "black cumin", "kalonji", "medicine", "tibb", "remedy", "stomach", "cure", "prophetic medicine"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Quran names honey before the Prophet did. In Surat an-Nahl, Allah describes the bee, the homes it is inspired to build and the drink of many colours that comes from its belly, and says of that drink that in it is healing for people:"),
                      .quran("16:69"),
                      .text("A man came to the Prophet with a brother whose stomach was troubling him, and the answer was honey. He came back, and the answer was honey; he came back again and said he had done it, and the Prophet answered with a sentence the scholars have never stopped quoting: Allah has told the truth, and your brother's stomach has lied. He gave him honey once more, and the man was cured."),
                      .hadith("bukhari:5684", cite: "Sahih al-Bukhari 5684", arabic: 17...57, english: 0...99),
                      .text("The second cure is a small black seed, habbat as-sawda', known in English as black cumin or nigella, which the Arabs of his time already used in food and in medicine. Abu Hurayrah heard him name it in the widest terms he used for any remedy:"),
                      .hadith("bukhari:5688", cite: "Sahih al-Bukhari 5688", arabic: 33...41, english: 6...16),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Keep honey in the house as a medicine and not only as a sweet. The Prophet's instruction was to give it to drink, so a spoon stirred into warm water or milk is the plain way; take it for a stomach complaint and for general strength, and keep taking it, as he told the man to, rather than judging it by a single dose."),
                      .text("Take the black seed as your land takes it: the whole seeds chewed or ground over food, or the pressed oil by the spoon. The narration fixes no dose and no way of taking it, so there is no sunnah count to keep; a small amount each day is how most Muslims keep the habit."),
                      .text("Say Bismillah over either as over any food, and take them as means with your trust in Allah. See the doctor as well: the Prophet said that Allah sent down no disease without sending down its cure (Sahih al-Bukhari 5678), and honey and the seed are two of the cures, not a reason to refuse the rest."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Honey carries the Quran's own word, healing for people, and the Prophet's reply to the man shows what trust in that word looks like: when the first dose seemed to fail, he did not doubt the revelation, he doubted the stomach. The seed carries his word that its healing reaches every disease but death. Ibn Hajar records that the scholars read this as a general wording with a particular meaning: the seed is a cure for the ailments it suits, taken as it should be, and the healing is Allah's."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars say the hadith of the black seed is general in its wording, and that its benefit comes by Allah's decree through the means taken as the Prophet described; it does not replace treatment. A person with a serious illness takes the seed and the honey alongside the doctor's care, not instead of it."),
                  ]),
              ]),
        .init(id: "talbinah", title: "Talbinah for the sick and the grieving",
              summary: "A thin barley broth he praised: it rests the heart of the sick and takes away some of the grief.",
              group: .food,
              aliases: ["talbina", "barley", "sha'ir", "broth", "porridge", "soup", "grief", "sorrow", "mourning", "illness", "comfort", "aishah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Talbinah is barley flour cooked thin in milk or water until it is pale as milk, which is where its name comes from: laban, milk, as the scholars explain. 'A'ishah used to order it for anyone in the household who was ill and for anyone grieving a death, and she gave the Prophet's own words as her reason."),
                      .hadith("bukhari:5689", cite: "Sahih al-Bukhari 5689", arabic: 25...53, english: 0...49),
                      .text("Muslim records how she kept it. When a death took place in her family and the women who had gathered to console had gone, leaving only the family and those close to them, she had a pot of talbinah cooked, had tharid prepared and the talbinah poured over it, and told the women to eat:"),
                      .hadith("muslim:2216", cite: "Sahih Muslim 2216", arabic: 30...78, english: 0...78),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Learn to make it: a spoonful or two of barley flour stirred into a cup of milk or water and simmered for a few minutes until it thickens a little, then sweetened with honey. It should pour like a thin porridge; the narrations describe something closer to a drink than a dish, and it takes less time than tea."),
                      .text("Give it to the sick, in the house or when visiting. Warm, light and easy on the stomach, it is the food the Prophet named for someone who cannot face a meal, and bringing it along is a way of keeping the sunnah of visiting the sick with something in hand rather than empty-handed."),
                      .text("Give it to the grieving. 'A'ishah's habit was to feed the women who had come to mourn, and the narration names the grieving heart beside the sick one; a bowl of talbinah carried to a house of mourning is a sunnah few people know and every family can keep."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration itself is the reason: it rests the heart of the sick and takes away some of the grief. The Prophet named a food for sorrow, which is a mercy in itself; grief sits in the body as much as in the heart, and a mourner who will not eat is given something he can. The scholars count it among the kindnesses of his medicine, cheap, simple and offered to the two kinds of people who most need to be fed and are least able to ask."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The scholars keep to the word in the narration, some of the grief: talbinah lightens sorrow and is no cure for it, and the sick take it beside the care they need, not in place of it. Nothing in the reports fixes a recipe, so any thin barley porridge keeps the sunnah."),
                  ]),
              ]),
        .init(id: "zamzam", title: "Drink Zamzam for what you need",
              summary: "The water of Zamzam is for whatever it is drunk for: drink it with a need in mind, and drink your fill.",
              group: .food,
              aliases: ["zam zam", "well", "makkah", "mecca", "hajj", "umrah", "abu dharr", "blessed water", "intention", "niyyah", "cure", "nourishing"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Zamzam is the well beside the Ka'bah, and the Prophet spoke of its water as of no other. Jabir heard him say that it is for whatever it is drunk for: a person comes to it with a need, drinks with that need in mind, and asks Allah for it."),
                      .hadith("ibnmajah:3062", cite: "Sunan Ibn Majah 3062; graded sahih by al-Albani", arabic: 37...41, english: 8...18),
                      .text("Abu Dharr learned what the water could do before he had met him. He came to Makkah as a stranger, was beaten for asking after the Prophet, and lived for thirty days and nights on nothing but Zamzam, and grew fat on it. When he told the Prophet, the answer named the water's two qualities:"),
                      .hadith("muslim:2473a", cite: "Sahih Muslim 2473a", arabic: 522...556, english: 894...945),
                      .text("He also drank it himself, standing at the well, as Ibn 'Abbas saw him (Sahih al-Bukhari 5617), which is why the page on drinking sitting makes Zamzam its exception. The water was taken as it came, at the place it came from, with no ceremony around it beyond the name of Allah and the need it was drunk for."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Bring a need to it. Before you drink, decide what you are drinking it for: healing, knowledge, a child, strength for worship, forgiveness, whatever is lawful to ask. Say Bismillah, drink, and ask Allah for that thing by name; the narration ties the water to the intention of the one who drinks it."),
                      .text("Drink your fill. Abu Dharr lived on it, and the Prophet called it nourishing food as well as blessed water; so drink deeply, in the three breaths of any drink with the cup taken from the mouth between them, and praise Allah when you finish, as after any drink."),
                      .text("Drink it wherever it reaches you. Pilgrims carry it home, and the water keeps its blessing in a bottle in your kitchen as at the well; give it to the sick, share it with guests, and keep some for the one who asks for it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Two things the narration of Abu Dharr says of the water: it is blessed, and it is food, enough to keep a man alive for a month and to fatten him. Jabir's hadith adds the third: it answers the need of the one who drinks it, by Allah's leave. The scholars take the promise as it stands and say the drinker's intention and his trust in Allah are the whole of the rite; there is no other water in the world of which the Prophet said as much."),
                  ]),
                  SignSection("A NOTE", [
                      .text("No rite is attached to it beyond the intention: standing or sitting, facing the qiblah or not, are not conditions, and the Prophet drank it standing. Ibn Baz held that Zamzam carried away from Makkah keeps its blessing, so it may be drunk, and drunk for a need, anywhere it is taken."),
                  ]),
              ]),
        .init(id: "milk-dua", title: "The words over milk, and over any food",
              summary: "Allahumma barik lana fihi wa zidna minhu over milk; wa at'imna khayran minhu over other food.",
              group: .food,
              aliases: ["laban", "dua for milk", "dua for food", "barik lana", "zidna", "khayran minhu", "ibn abbas", "maymunah", "khalid", "blessing", "suffices", "drink"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Ibn 'Abbas and Khalid ibn al-Walid went in with the Prophet to Maymunah, and she brought them a bowl of milk. The Prophet drank, then offered the turn to Ibn 'Abbas on his right, saying he could give it to Khalid if he wished; the boy said he would not give anyone preference over what the Prophet had left. Then came the teaching: words for when Allah gives you food, different words for when He gives you milk, and the reason milk has its own."),
                      .hadith("tirmidhi:3455", cite: "Sunan al-Tirmidhi 3455; graded hasan by al-Albani", arabic: 73...123, english: 78...165),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Over milk, say Allahumma barik lana fihi wa zidna minhu (O Allah, bless us in it and give us more of it). The reason is in the Prophet's last sentence: nothing else serves as both food and drink, so over milk you ask for more of the same rather than for something better."),
                      .text("Over any other food, say Allahumma barik lana fihi wa at'imna khayran minhu (O Allah, bless us in it and feed us better than it). The dua asks for the blessing in what is in front of you and for better provision after it, and it fits a plate of rice as well as it fits a feast."),
                      .text("Keep the two beside the ordinary words of the table, not instead of them: Bismillah before the first mouthful, Alhamdulillah after the last. These are an addition for the one who remembers them, and the narration fixes no moment; say them as the dish or the cup is set in front of you."),
                      .text("Pass the cup to the right. The same report shows the Prophet offering the turn to the one on his right and letting him choose whether to yield it, which is the sunnah of a shared drink, and Ibn 'Abbas's answer shows how the Companions prized what the Prophet had left in the cup."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The words ask Allah for the two things a meal can give: blessing in what is there, and provision after it. Milk is singled out because the Prophet said it stands in for both food and drink, so the request over it is for more of it rather than for something better. A table where these words are known has a dua for every dish, and the blessing asked for is barakah, the increase that makes a little go far."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The narration is hasan, and al-Tirmidhi himself called it so; the words are a sunnah to add when you remember them, and a meal is complete with Bismillah and Alhamdulillah alone. Say them in Arabic as he gave them and know what they mean, so that the dua is a request and not a formula."),
                  ]),
              ]),
        .init(id: "not-reclining", title: "Eat sitting up, not reclining",
              summary: "I do not eat reclining, he said: sit upright, on the knees or with the knees drawn up, as he was seen eating dates.",
              group: .food,
              aliases: ["leaning", "reclining", "muttaki", "posture", "sitting", "squatting", "knees", "cushion", "abu juhayfah", "anas", "humility", "arrogance"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu Juhayfah heard the Prophet say how he did not eat: muttaki'an, settled back at ease on a seat or a cushion the way a man does who has made himself comfortable for a long meal. He said it of himself, in the first person, which is how the Companions learned his manner at the table."),
                      .hadith("bukhari:5398", cite: "Sahih al-Bukhari 5398", arabic: 22...24, english: 4...13),
                      .text("Anas describes the posture he was seen in instead: muq'iyan, sitting low on the ground with the knees drawn up and the feet flat, eating dates, the way a person sits who means to eat a little and be gone rather than settle in for a long meal."),
                      .hadith("muslim:2044a", cite: "Sahih Muslim 2044a", arabic: 27...36, english: 0...8),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Sit up to eat. At a table, sit straight in the chair with your back off its rest; on the floor, kneel with the feet beneath you, or sit on one foot with the other knee raised, or sit with both knees drawn up as Anas saw him. The scholars describe these as the ways he sat to eat, and any of them keeps the sunnah."),
                      .text("Do not settle back on cushions, lean on one arm, or eat stretched out on a sofa. The posture he refused is the posture of ease and of long eating, and leaving it is the whole of the sunnah here; there is no one way of sitting that is required, only the reclining that is left."),
                      .text("Let the sitting shape the meal. Upright, a person eats what he needs and gets up; reclined, he eats on. The Prophet's sentence about the stomach, a third for food, a third for drink and a third for breath, is easier to keep in the posture he kept than in the one he refused."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Ibn Hajar explains the word: the one who reclines has settled himself for a large meal, and the Prophet's refusal of it was humility before Allah's provision, eating as a servant eats and not as a king at a banquet. The scholars read in it the manner of a man who sat to eat the way he sat to pray, attentive and brief, and they count eating upright among the sunnahs of the table."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Eating reclining is disliked, not forbidden; a sick person or one who cannot sit otherwise does so without blame. The scholars explain the dislike as the posture of the arrogant and of overeating, and say what matters is to avoid the ease it expresses, not to copy any one way of sitting."),
                  ]),
              ]),
        .init(id: "perfume", title: "Accept scent and wear it",
              summary: "He never refused a scent and said not to refuse one offered: light to carry and sweet in smell.",
              group: .home,
              aliases: ["perfume", "tib", "fragrance", "attar", "oud", "musk", "rayhan", "scent", "smell", "anas", "abu hurayrah", "friday"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Anas served the Prophet for ten years, and one habit he took from him outright: he never turned away a gift of scent, because the Prophet never did. Thumamah, his grandson, passed it on, and al-Bukhari set it in the chapter on perfume in his book of dress."),
                      .hadith("bukhari:5929", cite: "Sahih al-Bukhari 5929", arabic: 21...36, english: 0...24),
                      .text("Abu Hurayrah gives the instruction behind the habit, and its reason. A rayhan, a sweet-smelling plant or flower, is not to be refused when it is offered: it costs nothing to carry and it smells good, so there is no reason to decline it."),
                      .hadith("muslim:2253", cite: "Sahih Muslim 2253", arabic: 48...58, english: 0...20),
                      .text("He also said what scent meant to him, in a sentence Anas carried:"),
                      .hadith("nasai:3939", cite: "Sunan an-Nasa'i 3939; graded hasan sahih by al-Albani", arabic: 37...47, english: 5...24),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When someone offers you scent, take it, and when you have it, wear it. A man puts on perfume for the prayer, for Friday, for a gathering and for his own household; the Prophet named perfume beside the Friday ghusl and the siwak for anyone who can find it (Sahih al-Bukhari 880)."),
                      .text("Keep some at home and offer it to a guest. The one who is offered scent has been told not to refuse it, so the giver does him a kindness twice: a drop of oud or musk on the hand of a visitor is a sunnah in the giving and a sunnah in the accepting."),
                      .text("Choose for a man a scent whose smell carries: the oils and perfumes the air takes, musk, oud, rose. Let it be pleasant to those near you and not overpowering, since the point of the narrations is that scent is a kindness to others as much as to the wearer."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narrations give a plain reason, light to carry and sweet in smell, and a deeper one: perfume was among the things of this world made beloved to the Prophet, named in one breath with the prayer that was the comfort of his eye. Scent is part of the cleanliness the religion asks for, it honours the gathering and the masjid, and the scholars count accepting it and wearing it among the sunnahs of dress."),
                  ]),
                  SignSection("A NOTE", [
                      .text("A woman's perfume is for her home and her husband: the Prophet said severe words of a woman who perfumes herself and passes among men so that they catch her scent (Sunan Abi Dawud 4173, graded hasan by al-Albani), so she goes out without it."),
                  ]),
              ]),
        .init(id: "dye-grey", title: "Dye the grey, but not black",
              summary: "Change grey hair with henna or katam and differ from those who leave it grey: but avoid black.",
              group: .home,
              aliases: ["henna", "hinna", "katam", "khidab", "grey hair", "white hair", "beard", "abu quhafah", "jews and christians", "colour", "dyeing", "shayb"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("On the day Makkah was opened, Abu Bakr brought his old father Abu Quhafah to the Prophet to accept Islam, his head and beard as white as the thaghamah, a plant whose flowers are pure white. The Prophet's instruction to the household was short, and it came with a limit."),
                      .hadith("muslim:2102b", cite: "Sahih Muslim 2102b", arabic: 39...43, english: 0...6),
                      .text("Abu Hurayrah gives the reason the dyeing was urged: the Jews and the Christians did not dye their grey, and the Muslims were to be unlike them in it, as they were told to be unlike them in other matters of appearance and habit."),
                      .hadith("bukhari:3462", cite: "Sahih al-Bukhari 3462", arabic: 42...47, english: 4...31),
                      .text("And Abu Dharr names what to dye with:"),
                      .hadith("tirmidhi:1753", cite: "Sunan al-Tirmidhi 1753; graded sahih by al-Albani", arabic: 29...36, english: 5...19),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the grey comes, in the hair or the beard, dye it. Henna on its own gives red; henna mixed with katam, a plant whose leaves give a dark tint, gives a colour between red and black. Either is the sunnah, and the narration of Abu Dharr calls them the best of what grey is changed with."),
                      .text("Keep away from pure black. The Prophet said it in the same breath as the instruction to dye, and the scholars take it at its word: a colour that leaves the hair plainly dyed and not black is permitted, and black on its own is not, whether on the head or in the beard."),
                      .text("Renew it as it fades, and keep it for the hair of the head and the beard alike. Women dye their grey too, and the limit on black applies to both; the scholars make no difference between a woman's hair and a man's in the ruling, only in who may see it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration gives the reason: it marks the Muslim off from the People of the Book in his appearance, as the other sunnahs of grooming do. The scholars add that a dyed beard honours the old man and makes him look well before his family, and that the choice of henna keeps the change honest: hair that is coloured and known to be coloured, not black that pretends to a youth that is gone."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The stronger view, held by Ibn Baz and Ibn 'Uthaymin, is that dyeing with pure black is forbidden, on the words avoid black; some earlier scholars allowed it, and black mixed with another colour so that it is no longer pure black is permitted. Leaving the grey undyed is also permitted; the dyeing is recommended, not required."),
                  ]),
              ]),
        .init(id: "izar-length", title: "The garment above the ankle",
              summary: "A man's lower garment reaches mid-shin by the sunnah, the ankle at most; what hangs below the ankle is in the Fire.",
              group: .home,
              aliases: ["izar", "isbal", "trousers", "thawb", "hem", "ankles", "ka'bayn", "shin", "pride", "khuyala", "abu sa'id", "abu bakr"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Abu Sa'id al-Khudri was asked how a man should wear his lower garment, and said the questioner had come to the right man. He gave the Prophet's measure in full: mid-shin is the way of the believer; anywhere between that and the ankles is no sin; whatever is below the ankles is in the Fire; and the one who trails it in pride has a threat of his own."),
                      .hadith("abudawud:4093", cite: "Sunan Abi Dawud 4093; graded sahih by al-Albani", arabic: 24...64, english: 22...88),
                      .text("Ibn 'Umar carried the threat for pride, and Abu Bakr's worry about it. One side of his izar would slip down unless he kept hold of it, and the Prophet told him he was not one of those who do it out of pride. Abu Hurayrah's short report fixes the limit without any mention of pride at all: what hangs below the ankles of the izar is in the Fire (Sahih al-Bukhari 5787)."),
                      .hadith("bukhari:5784", cite: "Sahih al-Bukhari 5784", arabic: 28...68, english: 0...64),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Have your thawb, trousers or izar end above the ankle bone. The sunnah is mid-shin, as the narration says; anywhere between there and the ankles is without blame; the ankle itself is the line, and nothing of the garment goes below it."),
                      .text("Have new clothes cut to that length, and take up the hems of the ones you own. Trousers are sold long; a tailor shortens them in minutes, and once a man's wardrobe is right the sunnah keeps itself. Check the back of the hem as well as the front, since it is the back that trails."),
                      .text("Keep it without pride either way. A garment above the ankle is not a badge, and a man who keeps it does not look down on one who does not. If the hem slips as Abu Bakr's did, pull it up and think nothing of it; the threat is for the one who lets it drag."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narrations name two things: the Fire for what hangs below the ankles, and for the one who drags his garment in pride, that Allah will not look at him on the Day of Resurrection. The scholars draw from the exchange with Abu Bakr that the second threat is for pride, and from Abu Hurayrah's report that the first stands on its own. A hem is a small thing, and the Prophet gave it a measure so that a Muslim's dress would be modest without being a display."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The ruling of the Salafi scholars, Ibn Baz and Ibn 'Uthaymin among them, is that for a man letting the garment fall below the ankles is forbidden whether or not it is done out of pride, with the severer threat reserved for pride; some other scholars confine the prohibition to pride. Women do the opposite and lengthen theirs: the Prophet told Umm Salamah a hand-span, and when she said their feet would show, a cubit and no more (Sunan al-Tirmidhi 1731, graded sahih by al-Albani)."),
                  ]),
              ]),
        .init(id: "cover-vessels", title: "Nightfall: the children in, the doors shut, the vessels covered",
              summary: "Keep the children in at dusk, shut the doors with Allah's name, cover the vessels and put out the lamps.",
              group: .night,
              aliases: ["dusk", "doors", "lamps", "candles", "fire", "mouse", "plague", "devils", "jinn", "water-skin", "containers", "jabir"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Jabir reported the Prophet's instructions for the hour the day turns to night. They are a list, and three of the items have Allah's name attached: the children kept in while the devils spread, the doors shut, the water-skins tied, the vessels covered, the lamps put out."),
                      .hadith("bukhari:5623", cite: "Sahih al-Bukhari 5623", arabic: 35...82, english: 4...83),
                      .text("Two shorter reports from Jabir give the plain reason for two of the items. The lamp is put out because of the mouse, which drags the wick and sets the house alight; the vessel is covered because of a night in the year when a sickness comes down into whatever is left open."),
                      .hadith("bukhari:6295", cite: "Sahih al-Bukhari 6295", arabic: 28...41, english: 4...35),
                      .hadith("muslim:2014a", cite: "Sahih Muslim 2014a", arabic: 52...79, english: 0...37),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("As the sun sets, bring the children indoors and keep them in for the first part of the night. The narration names this hour as the one in which the devils spread out, and says they may be let out again once it has passed; an evening playtime is moved by an hour, not cancelled."),
                      .text("Close the doors with Bismillah. Say it as you lock up at night, on the front door and the others; Shaytan, the Prophet said, does not open a closed door, and the name of Allah over it is what makes the closing count."),
                      .text("Cover the food and drink that are left out, with Bismillah: a lid on the jug, a cloth on the bowl, the cap on the bottle. If there is nothing to cover a vessel with, lay something across it, a spoon or a stick, as the narration allows; the point is that nothing is left open to the night."),
                      .text("Put out flames before sleep: candles, oil lamps, the gas, the fire in the grate. Electric light is not a flame and the scholars do not include it; what the Prophet named was the lamp a mouse could drag the wick from, and anything that burns is its modern kin."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narrations give their reasons, and the scholars take them as they stand: the devils spread at nightfall and snatch what they can; the mouse drags the wick and the house burns; a night in the year brings a sickness down into every open vessel. Three of the five items are tied to Allah's name, which is the real guard; the lid and the latch are the means, and the name over them is what shuts out the one the latch cannot stop."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The commands are recommendations with their reasons stated: where the reason holds, the scholars say the practice holds, so a lit flame is put out and an open jug is covered; where it does not, as with an electric light, it does not. The scholars, Ibn 'Uthaymin among them, say electric lights need not be switched off by this hadith, since the reason the Prophet gave does not apply to them."),
                  ]),
              ]),
        .init(id: "no-prone-sleeping", title: "Never sleep on the stomach",
              summary: "He woke a man lying face down in the masjid: a way of lying Allah dislikes, the way the people of the Fire lie.",
              group: .night,
              aliases: ["prone", "face down", "belly", "stomach", "sleeping position", "tikhfah", "abu dharr", "masjid", "nudged", "right side", "back", "posture"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Tikhfah al-Ghifari, one of the poor Companions who slept in the masjid, was found there by the Prophet lying face down. The Prophet woke him with his foot and told him what that way of lying was; his son Qays carried the story on."),
                      .hadith("ibnmajah:3723", cite: "Sunan Ibn Majah 3723; graded sahih by al-Albani", arabic: 23...52, english: 0...39),
                      .text("Abu Dharr tells the same of himself, with the harder word:"),
                      .hadith("ibnmajah:3724", cite: "Sunan Ibn Majah 3724; graded sahih by al-Albani", arabic: 29...53, english: 0...29),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Lie down on your right side, as the pages on the bedtime sunnahs describe, with the words he taught; that is the sleeping position he kept and told al-Bara' to keep. On the back is permitted: he was seen lying on his back in the masjid with one leg over the other (Sahih al-Bukhari 475)."),
                      .text("If you wake and find yourself on your stomach, turn over. The body moves in sleep and no one is blamed for where he wakes; the sunnah is in the position you choose when you lie down and the one you return to when you notice."),
                      .text("Teach it to the children, gently, the way the Prophet did: a nudge and a sentence. A child who learns the right side at five will sleep on it at fifty, and the correction is kinder from a parent at bedtime than from anyone later."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration gives the weight of it: a way of lying that Allah dislikes, and in Abu Dharr's words the lying of the people of the Fire. The scholars count sleeping on the stomach as disliked for that reason alone, and they note the Prophet corrected it in the masjid, in a poor man, with his foot, which is how a thing is corrected when it matters. The right side he taught is a sunnah with a promise attached, and leaving the stomach is its other half."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Sleeping on the stomach is disliked, not forbidden, and a person who must lie that way for an illness or an injury is excused. The right side is the sunnah; the back is permitted; the left is permitted and the right is better."),
                  ]),
              ]),
        .init(id: "bad-dream", title: "What to do after a bad dream",
              summary: "Seek refuge, spit lightly to the left three times, turn over, pray if you will, and tell no one: it will not harm you.",
              group: .night,
              aliases: ["nightmare", "dreams", "ru'ya", "hulm", "shaytan", "spit", "left side", "interpretation", "ta'bir", "abu qatadah", "abu sa'id", "jabir"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet divided dreams in two. A dream a person likes is from Allah: he thanks Him for it and may tell it, to those he loves (Sahih al-Bukhari 7044). A dream he hates is from Shaytan: he seeks refuge from its evil, tells no one, and it will not harm him."),
                      .hadith("bukhari:6985", cite: "Sahih al-Bukhari 6985", arabic: 29...61, english: 4...71),
                      .text("Jabir's report adds two acts to the refuge: spitting lightly to the left three times, and turning over from the side he was sleeping on. The refuge itself is said three times in his wording, so the whole comes to three of each."),
                      .hadith("muslim:2262", cite: "Sahih Muslim 2262", arabic: 28...47, english: 0...41),
                      .text("Abu Hurayrah's report adds a third, and says what dreams are:"),
                      .hadith("muslim:2263a", cite: "Sahih Muslim 2263a", arabic: 49...75, english: 46...112),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("The moment you wake from a dream you hate, seek refuge: a'udhu billahi minash-shaytanir-rajim (I seek refuge in Allah from Shaytan the accursed), and from the evil of what you saw. Jabir's wording has it three times, and the words are said where you lie, before you move."),
                      .text("Spit lightly to your left three times: a dry spitting, barely more than breath, as the word in the narration means. It is done lying where you are, towards the side Shaytan is on, and it takes a moment; no one else need notice it."),
                      .text("Turn over onto your other side and go back to sleep. If the dream has left you awake, get up, make wudu and pray two rak'ahs, as Abu Hurayrah's report says: the prayer is the refuge that Shaytan cannot follow you into."),
                      .text("Tell no one. Not in the morning, not as a story; the narration says the dream will not harm you, and the not-telling is part of the remedy. A good dream you may tell, but only to someone you love or someone wise, as the note below explains."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The promise is in the narrations: it will not harm you. The dream from Shaytan is meant to grieve, the Prophet said, and the whole of the remedy is to deny it that: refuge taken, the dream spat away, the side changed, the prayer prayed, the story untold. Abu Salamah used to be made ill by his dreams until he heard these words from Abu Qatadah (Sahih Muslim 2261), and the believer sleeps knowing that a bad night is a thing with a sunnah for it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("A dream is not told to the first person who asks, and not laid before anyone who will guess at it: the Prophet said a dream hangs on a bird's leg until it is interpreted, and then it falls (Sunan Abi Dawud 5020, graded sahih by al-Albani), so it is told only to one who loves you or one who has judgement, and the interpretation of dreams is a knowledge, not a game."),
                  ]),
              ]),
        .init(id: "olive-oil", title: "Eat the olive and anoint with its oil",
              summary: "Eat olives and rub the oil in, he said, for it is from a blessed tree: the tree the Quran names twice.",
              group: .food,
              aliases: ["zayt", "zaytun", "olives", "oil", "anoint", "blessed tree", "shajarah mubarakah", "skin", "hair", "umar", "sinai", "light"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The olive is the tree the Quran calls blessed. In the ayah of Light it is the oil of a blessed olive tree, neither of the east nor of the west, that all but glows before any fire touches it; and in Surat al-Mu'minun it is the tree of Mount Sinai that gives oil and a relish for those who eat."),
                      .quran("24:35"),
                      .quran("23:20"),
                      .text("'Umar reported the Prophet's instruction about it, in two verbs: eat it, and anoint with it."),
                      .hadith("tirmidhi:1851", cite: "Sunan al-Tirmidhi 1851; graded sahih by Darussalam", arabic: 29...36, english: 7...19),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Eat it. Olives with bread, oil on bread or over a dish; it was the oil Sa'd ibn 'Ubadah set before the Prophet with bread (Sunan Abi Dawud 3854), and it is the oil of the lands of the Quran. Keep a bottle of good olive oil in the kitchen and let it be the oil you reach for first."),
                      .text("Anoint with it: rub it into the skin and the hair, as the Arabs of his time did with oil, and as the narration's second verb says. A little on the hands, the face, the scalp or the beard after washing is the sunnah kept, and it needs nothing added to it."),
                      .text("Do both with the ayah in mind. The Quran called the tree blessed before the Prophet repeated it, so the oil on your bread and in your hair is a thing Allah Himself praised; say Bismillah over it as over any food, and let the blessing be the reason you chose it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The narration gives its reason in one clause: it is from a blessed tree, and the blessing is the Quran's own word. The scholars note that the Prophet attached his instruction to Allah's description, so that eating the olive and using the oil is a way of taking what Allah has called blessed, and the two verbs cover its two uses, food and anointing, which is how the Arabs used oil before Islam and after it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The narration rests on a single chain, and al-Tirmidhi notes that 'Abd al-Razzaq narrated it unevenly, sometimes from 'Umar and sometimes without him; the grading followed here is Darussalam's sahih. The Quran's praise of the tree does not depend on it, and olive oil is a food and not a medicine with a promised cure."),
                  ]),
              ]),
    ]

    // MARK: More: company, the year, and travel, Eid and family

    static let occasionEntries: [Entry] = [
        .init(id: "silat-rahim", title: "Keep the ties of kinship",
              summary: "Keep up with your relatives, even the ones who cut you off; he tied provision and a long life to it.",
              group: .company,
              aliases: ["silat al-rahim", "silah", "rahim", "kinship", "relatives", "family ties", "cousins", "uncle", "aunt", "wasil", "provision", "rizq"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet counted the ties of blood among the things a believer keeps whatever they cost him. He named two rewards for keeping them that people want most, a wider provision and a longer life, and he set the bar higher than most people set it: the one who truly keeps the ties is not the one who answers a visit with a visit, but the one who keeps going when the other side has stopped."),
                      .hadith("bukhari:5986", cite: "Sahih al-Bukhari 5986", arabic: 26...38, english: 4...30),
                      .hadith("bukhari:5991", cite: "Sahih al-Bukhari 5991", arabic: 44...53, english: 4...39),
                      .text("The Quran opens Surat an-Nisa by binding fear of Allah to the wombs, the ties of kinship, in a single ayah, and the Prophet warned that the one who cuts them will not enter Paradise (Sahih al-Bukhari 5984). The scholars read the long life in the hadith as blessing in it, or as a real lengthening in what the angels have written, since Allah knew from the first what the person would do; either way the promise is his."),
                      .quran("4:1"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Know who your relatives are, and keep a list if the family is large: parents first, then brothers and sisters, grandparents, uncles and aunts, cousins and their children, through both your father and your mother. The nearer the relative, the stronger the claim, and parents above all; but the hadith speaks of the rahim as a whole, so the far cousin has a share too."),
                      .text("Keep the tie with whatever reaches them: a call, a message, a visit, a gift, a meal shared, help with money when they need it, and dua for them when you can do no more. Silat is not one act but the habit of not letting the thread go slack, so settle a rhythm, a weekly call to the parents, a visit to the aunt each month, and keep it."),
                      .text("Keep it with the one who has cut you off. This is the whole point of the second narration: answering kindness with kindness is only fairness, and the wasil is the one who goes on greeting, giving and forgiving when nothing comes back. If a quarrel stands between you, be the first to the door, and do not let it pass three days without a greeting (Sahih al-Bukhari 6077)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The two rewards are his own words: a provision made wide and a life made long, and the scholars add that the second may be the blessing in a life, its days filled with what counts, which is a longer life in the only sense that matters. Against them stands the warning that the one who cuts the ties will not enter Paradise, so the matter is not manners but faith. A family kept together by one member who refuses to let go is also the plainest dawah a Muslim ever gives."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Keeping the tie does not mean obeying a relative in what Allah has forbidden or sitting in a gathering of sin; it means the greeting, the visit, the kindness and the dua still go to them. Where a relative's harm is real, the scholars allow keeping to the least that counts as silat, a greeting and a message, with dua for the rest."),
                  ]),
              ]),
        .init(id: "honour-guest-neighbour", title: "Honour the guest and the neighbour",
              summary: "Two marks of faith in Allah and the Last Day: no harm to the neighbour, and a generous welcome for the guest.",
              group: .company,
              aliases: ["jar", "jiran", "dayf", "hospitality", "guest", "neighbour", "neighbor", "jibril", "gabriel", "inherit", "broth", "abu dharr"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Two of the people the Prophet put under the protection of faith itself were the neighbour and the guest. In one sentence he made not harming the first and honouring the second a mark of believing in Allah and the Last Day, beside the rule of the tongue that has its own page in this library. 'A'ishah heard him say how far Jibril had pressed the matter of the neighbour, and Abu Dharr was given the simplest way of keeping it."),
                      .hadith("bukhari:6018", cite: "Sahih al-Bukhari 6018", arabic: 26...42, english: 4...32),
                      .hadith("bukhari:6014", cite: "Sahih al-Bukhari 6014", arabic: 36...44, english: 4...31),
                      .hadith("muslim:2625b", cite: "Sahih Muslim 2625b", arabic: 46...55, english: 0...19),
                      .text("He swore three times that a man whose neighbour is not safe from his harm does not believe (Sahih al-Bukhari 6016), and for the guest he set the measure: a day and a night of the best you have, hospitality for three days, and whatever is beyond that is charity (Sahih al-Bukhari 6135)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Begin with the neighbour by doing him no harm: no noise that disturbs him, no rubbish or car across his door, no eye on his household, no word against him. The hadith starts with harm because that is what neighbours suffer from most, and removing it costs nothing. Then add the good: the greeting, a hand with a load, a visit when he is ill."),
                      .text("Send food. Abu Dharr's instruction is the model: when you cook, make a little more and send a plate next door, to the Muslim neighbour and the non-Muslim alike, since the narration names neighbours without limit. A plate that comes back with something on it is a bond between two homes, and the page on gifts in this library says what to do with it."),
                      .text("Welcome the guest with a cheerful face and the best you have on the first day, and look after him for three; after that he is on your charity, and he should not stay so long that he burdens you. Serve what is in the house without strain and without apology, give him the best seat, and see him to the door when he leaves."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward named is the one that matters most: these two are tied to faith in Allah and the Last Day, so a believer keeps them as part of his belief, not as good manners alone. Jibril's urging shows the neighbour's rank with Allah, and the guest's three days are a measure that protects the host as much as the guest. The scholars count the neighbour's right among the heaviest a Muslim carries, and a street kept this way is a neighbourhood at peace."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The three days are the limit of what a host owes, not of what he may give; a guest who overstays should not be made to feel it, and a host who can do more may. The nearer neighbour has the greater right: when 'A'ishah asked which of two neighbours to send a gift to first, he said the one whose door is nearer (Sahih al-Bukhari 2259)."),
                  ]),
              ]),
        .init(id: "tell-love", title: "Tell your brother that you love him",
              summary: "When you love someone for Allah's sake, say so: uhibbuka fillah, and the reply he taught.",
              group: .company,
              aliases: ["uhibbuka fillah", "ahabbaka", "love for allah", "brotherhood", "friend", "affection", "miqdam", "anas", "inform him", "hubb", "mahabbah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Love between believers was something the Prophet wanted spoken, not left to be guessed. Al-Miqdam ibn Ma'dikarib heard him say that a man who loves his brother should tell him so, and Anas watched him make a man do it on the spot: a man said he loved someone who had just passed by, and the Prophet sent him after him to say it, and the reply came back in the words that have been used ever since."),
                      .hadith("abudawud:5124", cite: "Sunan Abi Dawud 5124; graded sahih by al-Albani", arabic: 29...35, english: 4...17),
                      .hadith("abudawud:5125", cite: "Sunan Abi Dawud 5125; graded hasan by al-Albani", arabic: 15...65, english: 0...64),
                      .text("The love meant is love for Allah's sake, for a person's faith and goodness. The Prophet promised it the shade of Allah on the Day when there is no shade but His (Sahih Muslim 2566), and told of a man who set out to visit a brother in another town and met an angel on the road, sent to tell him that Allah loved him as he loved his brother (Sahih Muslim 2567a)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you find that you love someone for Allah's sake, a friend whose faith draws you, a teacher, a brother in the masjid, tell him plainly: uhibbuka fillah (I love you for Allah's sake); a woman says to a woman uhibbuki fillah. Say it in person if you can. The man in the narration went after him rather than waiting for a better moment."),
                      .text("If someone says it to you, answer as the man answered in front of the Prophet: ahabbakalladhi ahbabtani lahu (may He for whose sake you love me love you). The reply turns the love back into a dua, and both of you leave the exchange having been prayed for."),
                      .text("Let the words lead to the acts that keep love for Allah alive: the greeting, the handshake, the visit, the gift, dua for him in his absence. Love for Allah's sake is tested when the friend is poor, far away or out of favour, and the narration of the angel on the road is about a visit made for nothing but Allah."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He gave the reason to the man he sent: inform him. Love that is spoken grows, and the one who hears it finds his own heart softened towards the speaker; the scholars say this is the wisdom of the command. Love for Allah's sake is also one of the strongest ropes of faith, and he counted loving a person for nothing but Allah among the three things by which a person finds the sweetness of faith (Sahih al-Bukhari 16)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The words are for a brother to a brother and a sister to a sister, or within the family and the mahram circle; they are not said between a man and a woman who are not related, since the scholars close that door to what it leads to."),
                  ]),
              ]),
        .init(id: "istidhan", title: "Ask permission before you enter",
              summary: "Greet, give your name, and ask up to three times; if no one answers, go back without offence.",
              group: .company,
              aliases: ["isti'dhan", "istidhan", "permission", "knock", "door", "doorbell", "visiting", "abu musa", "umar", "jabir", "who is it", "privacy"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("A house is private, and the Quran lays down that nobody enters one not his own until he has asked leave and greeted those inside. The Prophet set the number of times to ask, three, and when 'Umar wanted it confirmed that Abu Musa had the rule from him, Abu Sa'id went with Abu Musa to bear witness. He also disliked the answer that tells the house nothing: when Jabir knocked and answered the question at the door with just me, he repeated it back to him."),
                      .quran("24:27"),
                      .hadith("bukhari:6245", cite: "Sahih al-Bukhari 6245", arabic: 45...67, english: 61...99),
                      .hadith("bukhari:6250", cite: "Sahih al-Bukhari 6250", arabic: 22...48, english: 0...40),
                      .text("His own habit at a door was to stand to the side of it, not facing it, since doors then had no curtains, and to say the greeting twice (Sunan Abi Dawud 5186, graded sahih by al-Albani). A man who called out asking whether he could come in was sent a servant to teach him the form: say as-salamu 'alaykum, may I enter? (Sunan Abi Dawud 5177, graded sahih by al-Albani)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("At the door, knock or ring, and stand to one side so that you do not look in when it opens. Then say the greeting and ask: as-salamu 'alaykum, may I come in? The greeting comes before the request in the ayah and in the form he taught, so it is the first thing the house hears."),
                      .text("When they ask who it is, give your name, or something that identifies you: it is Ahmad, your neighbour. Do not answer with a bare me, which tells them nothing; that is what he disliked in Jabir's answer. On the phone and at an intercom the same manners apply."),
                      .text("Ask up to three times, with a pause between, and if no one answers or you are told to go back, go back without offence, as the next ayah of the passage says (24:28). An unanswered door may mean sleep, prayer, illness or a wish to be alone, and all of those are the household's right."),
                      .text("Inside your own house, the scholars say, ask leave before entering a room where a parent, a grown child or a sibling may be undressed or resting, and teach the children the three times of day the Quran sets for them (24:58). The rule is one of privacy, and privacy begins at home."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The Quran gives the reason itself: the asking and the greeting are better for you, that you may remember. A household that is never walked in on unawares keeps its dignity, and a visitor who leaves after three unanswered knocks has committed no wrong and caused none. The scholars note that 'Umar's demand for a witness was not doubt of Abu Musa but care that nothing be attributed to the Prophet without certainty, and the sunnah came down to us with that care."),
                  ]),
              ]),
        .init(id: "fast-shaban", title: "Fast often in Sha'ban",
              summary: "The month before Ramadan was his month of most voluntary fasting: a month people neglect, in which deeds are raised.",
              group: .week,
              aliases: ["shaban", "sha'ban", "rajab", "before ramadan", "deeds raised", "usamah", "aishah", "fifteenth", "nisf shaban", "voluntary fast", "sawm"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Outside Ramadan the Prophet never fasted a whole month, but there was one month in which he fasted more than any other. 'A'ishah, who saw his fasting from inside his house, set it down, and Usamah ibn Zayd asked him why. His answer named the month as one people pass over between the honoured Rajab and the obligatory Ramadan, and tied his fasting in it to the raising of deeds, as he tied Monday and Thursday to it on another page of this library."),
                      .hadith("bukhari:1969", cite: "Sahih al-Bukhari 1969", arabic: 21...57, english: 0...61),
                      .hadith("nasai:2357", cite: "Sunan an-Nasa'i 2357; graded hasan by al-Albani", arabic: 31...70, english: 0...65),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When Sha'ban begins, fast more than you do in other months: the Mondays and Thursdays, the white days, and as many more as you can carry without harm. 'A'ishah's report fixes no number, and the scholars say the sunnah is in fasting most of the month rather than all of it, since he completed no month except Ramadan."),
                      .text("Keep each day as any voluntary fast: suhur, nothing from dawn to sunset, iftar at once. A woman who has days of Ramadan still to make up should give them priority, and 'A'ishah used to make hers up in Sha'ban (Sahih al-Bukhari 1950), which is another reason the month suits fasting."),
                      .text("Stop before Ramadan arrives: do not fast the last day or two of Sha'ban to meet Ramadan early, unless the day falls on a fast you already keep, such as a Monday (Sahih al-Bukhari 1914). The last days are for the sighting of the moon, and the fasting of Sha'ban is a preparation for Ramadan, not an extension of it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He gave the reason himself, in Usamah's report: the deeds of the year are raised to the Lord of the worlds in Sha'ban, and he wanted his to go up while he was fasting. The scholars add what 'A'ishah's report shows, that a month of frequent fasting trains the body and the soul for Ramadan, so that its first day finds a person already used to the fast. It is also a month most people neglect, and a deed done when others are heedless has a worth of its own."),
                  ]),
                  SignSection("A NOTE", [
                      .text("No fast is singled out for the fifteenth of Sha'ban and no prayer for its night, on the view of the scholars of the Sunnah, since the narrations about them do not stand; and some scholars hold, by the hadith that forbids fasting once Sha'ban reaches its middle (Sunan Abi Dawud 2337, graded sahih by al-Albani), that a person with no habit of fasting should not begin one in the second half, while others read it beside 'A'ishah's report and allow it."),
                  ]),
              ]),
        .init(id: "ten-dhul-hijjah", title: "The first ten days of Dhul-Hijjah",
              summary: "No deeds are better than those done in these ten days: fast the nine, say the takbir, and give the ninth its due.",
              group: .week,
              aliases: ["dhul hijjah", "dhu al-hijjah", "ten days", "ashr", "takbir", "tahlil", "tahmid", "hajj season", "arafah", "jihad", "best days", "fasting nine"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The ten days that open Dhul-Hijjah, the month of Hajj, are the days of the year the Prophet named as the best for good deeds, better even than jihad except for the man who gives everything to it and does not come back. One of his wives reported what he did with them: he fasted the nine days before the Eid, as he fasted 'Ashura and three days of every month."),
                      .hadith("bukhari:969", cite: "Sahih al-Bukhari 969", arabic: 28...54, english: 4...67),
                      .hadith("abudawud:2437", cite: "Sunan Abi Dawud 2437; graded sahih by al-Albani", arabic: 24...46, english: 21...51),
                      .text("The ninth of the ten is the day of 'Arafah, whose fast wipes out two years of sin; it has its own page in this library beside 'Ashura. The tenth is the day of sacrifice, Eid al-Adha, and no fast is kept on it."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Mark the first of Dhul-Hijjah when the moon is sighted, so that the ten do not slip by. Fast the first nine days, or as many of them as you can, and at the least the ninth, the day of 'Arafah, for whoever is not at Hajj. Keep each as any voluntary fast; the tenth is the Eid and is not fasted."),
                      .text("Fill the days with remembrance: Allahu akbar (Allah is the greatest), la ilaha illallah (there is no god but Allah), al-hamdu lillah (praise be to Allah), said often, and aloud by men in the streets and the markets, as the Companions did in these days. The takbir of the Eid, from the Fajr of 'Arafah to the end of the days of tashriq, is the same words raised."),
                      .text("Add the deeds the days are for: the Quran, charity, the night prayer, kindness to parents and kin, repentance; the hadith says no deeds are better in these days, without naming any. Whoever means to sacrifice leaves his hair and nails from the first of the month, as the page on the udhiyah explains, and whoever can go to Hajj goes."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He put the deeds of these days above jihad, and the scholars say it is because the ten gather the great acts of worship in one stretch: the prayer, the fast, the charity, and the Hajj, which comes in no other days. Ibn Hajar gives that as the reason the days are so loved. A fast of nine days and a tongue kept busy with takbir are within reach of everyone, whether they stand at 'Arafah or at home."),
                  ]),
                  SignSection("A NOTE", [
                      .text("'A'ishah said she never saw him fasting in the ten (Sahih Muslim 1176a); the scholars reconcile her report with the others by taking it as what she saw, since he divided his nights among his wives and may have left the fast at times for illness or travel, and the fasting of the nine stands established and recommended, the ninth above all."),
                  ]),
              ]),
        .init(id: "fast-muharram", title: "Fast in Muharram, the month of Allah",
              summary: "The best fasting after Ramadan is in Allah's month, al-Muharram, the first month of the year.",
              group: .week,
              aliases: ["muharram", "shahrullah", "sacred month", "new year", "hijri", "first month", "best fast", "night prayer", "abu hurayrah", "ashura", "voluntary fast"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The year of the Muslims opens with one of the four sacred months, and the Prophet gave it a name no other month carries: the month of Allah. He named fasting in it the best fasting after Ramadan, in the same breath as he named the night prayer the best prayer after the obligatory ones. Abu Hurayrah reported both halves of the sentence."),
                      .hadith("muslim:1163a", cite: "Sahih Muslim 1163a", arabic: 34...46, english: 0...23),
                      .text("'Ashura, the tenth of the month, is the day he fasted and ordered, with the ninth beside it; it has its own page in this library beside the day of 'Arafah. This page is about the month itself, whose other days are fasted on the strength of this one hadith."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When the new year begins with the moon of Muharram, fast more than usual in it: the Mondays and Thursdays, the white days, and the tenth with the ninth. The hadith sets no number, and he fasted no whole month but Ramadan, so the sunnah is in fasting much of the month rather than all of it."),
                      .text("Give the month its other right as a sacred month: the Quran names four months in which wrongdoing is weightier (9:36), and the scholars say good deeds in them are weightier too. Begin the year with repentance, with the ties of kinship kept, and with the night prayer the same hadith praises."),
                      .text("Keep the day of 'Ashura as its own page describes, the tenth and the ninth together, and let the fast of the month surround it. A person who cannot fast much may keep 'Ashura and a day or two around it and still have a share of the month."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The reward is in the ranking: after Ramadan, no fasting is better than this month's. The scholars say the name, the month of Allah, honours it, since Allah attaches to Himself only what He has chosen, and that the sentence pairs it with the night prayer because both are worship done out of sight, the fast by day and the prayer by night. A year begun with fasting and prayer is begun the way he would have begun it."),
                  ]),
                  SignSection("A NOTE", [
                      .text("He fasted most in Sha'ban, not Muharram; the scholars say this hadith may have come late in his life, or that travel and other duties kept him from the month, and what he said carries over what he found time to do. Nothing is singled out in Muharram beyond its fasts; the first of the year has no prayer or gathering of its own."),
                  ]),
              ]),
        .init(id: "itikaf-laylat-qadr", title: "The last ten nights of Ramadan",
              summary: "I'tikaf in the last ten, the nights kept awake, the family woken, and Laylat al-Qadr sought in the odd nights.",
              group: .week,
              aliases: ["itikaf", "i'tikaf", "retreat", "laylat al-qadr", "night of decree", "night of power", "odd nights", "27th", "qadr", "afuwwun", "pardon", "masjid"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When the last ten nights of Ramadan came, the Prophet changed gear. He withdrew into the masjid for i'tikaf, and 'A'ishah describes what the ten were like: he tightened his waist-wrapper, kept the nights alive with prayer, and woke his family so that they would not sleep through them. In those nights lies Laylat al-Qadr, the night better than a thousand months, and he told the Companions where to look for it."),
                      .hadith("bukhari:2025", cite: "Sahih al-Bukhari 2025", arabic: 25...36, english: 0...16),
                      .hadith("bukhari:2024", cite: "Sahih al-Bukhari 2024", arabic: 23...37, english: 0...38),
                      .hadith("bukhari:2017", cite: "Sahih al-Bukhari 2017", arabic: 30...39, english: 4...20),
                      .quran("97:1-5"),
                      .text("'A'ishah asked him what to say if she knew which night it was, and he gave her a dua of a single line, which is the dua of all ten nights for everyone who does not know which night it is; it asks for the one thing the night is for."),
                      .hadith("tirmidhi:3513", cite: "Sunan al-Tirmidhi 3513; graded sahih by al-Albani", arabic: 21...46, english: 0...48),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Enter i'tikaf if you are able: a stay in the masjid, from the evening of the twentieth of Ramadan until the Eid, leaving only for what you must, given to prayer, Quran and remembrance. He entered his place after Fajr on the twenty-first (Sahih al-Bukhari 2041), and the scholars reconcile that with the twentieth night. A shorter i'tikaf of a few days is valid for whoever cannot stay the ten."),
                      .text("Whether in i'tikaf or at home, keep the nights: pray the night prayer at length, recite, give charity, make dua, and wake your household for it as he woke his. All ten are the nights of worship, not only the odd ones, since the sunnah is that he kept them all."),
                      .text("Seek Laylat al-Qadr in the odd nights, the twenty-first, twenty-third, twenty-fifth, twenty-seventh and twenty-ninth, and most of all in the twenty-seventh, which many Companions favoured, without being sure of any. Say often: Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni (O Allah, You are Pardoning, You love to pardon, so pardon me)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Laylat al-Qadr is worth more than a thousand months of worship, by the Quran's own measure, and whoever stands it in faith and hope of reward is forgiven his past sins (Sahih al-Bukhari 1901). Because the night is hidden among the ten, the hiding itself is the reward's door: the one who keeps all ten is sure of it. I'tikaf, the scholars say, is the fuller form of seeking it, since the heart is cut off from everything but Allah for the whole stretch."),
                  ]),
                  SignSection("A NOTE", [
                      .text("A woman may keep i'tikaf in the masjid with her husband's leave where it is safe and proper; his wives did (Sahih al-Bukhari 2041). The night's date is not known and is not announced; the sign reported for its morning, a sun that rises white and without rays (Sahih Muslim 762a), is seen after the fact, and whoever has kept the ten has not missed it."),
                  ]),
              ]),
        .init(id: "umrah-ramadan", title: "'Umrah in Ramadan",
              summary: "An 'umrah made in Ramadan is counted like a Hajj: his word to a woman who had no camel for the Hajj.",
              group: .week,
              aliases: ["umrah", "umra", "ramadan umrah", "equals hajj", "umm sinan", "ansari woman", "camel", "makkah", "tawaf", "sai", "pilgrimage", "lesser pilgrimage"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When the Prophet came back from his Hajj he asked a woman of the Ansar why she had not come. Her husband and son had taken their one riding camel, and the other was needed for the water. He gave her something in its place that has kept its value ever since: an 'umrah in the month of Ramadan, which he set beside a Hajj."),
                      .hadith("bukhari:1782", cite: "Sahih al-Bukhari 1782", arabic: 20...69, english: 5...79),
                      .text("Muslim records the same exchange with the woman named, Umm Sinan, and with the words a Hajj, or a Hajj with me (Sahih Muslim 1256). The scholars say the second wording is the stronger, since a Hajj in his company was the greatest Hajj there could be."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Plan an 'umrah in Ramadan when you can afford it and your duties allow it, and make it with the intention of this hadith: the reward of a Hajj. It may be made on any days of the month, since the whole month carries the promise, so the last ten need not be the time if the crowds are too much."),
                      .text("Perform it as he performed it: ihram from the miqat with the talbiyah, tawaf around the Ka'bah, two rak'ahs behind the Station of Ibrahim, sa'i between Safa and Marwah, and the shaving or shortening of the hair. The fast may be kept through it all, and the traveller may break it and make the days up, as the Quran allows (2:184)."),
                      .text("Give the rest of the stay in Makkah to what the month is for: the prayers in the Sacred Mosque, the Quran, the night prayer, i'tikaf if you can. The promise is for the 'umrah; the days around it are a gift of their own."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("An 'umrah is a few hours of rites, and in Ramadan he made it equal to a Hajj in reward: the scholars say it is the month's blessing poured onto the act, since the reward of a deed rises with the virtue of its time and place, and Ramadan and Makkah are the best of both. For the one who cannot make the Hajj this year, the hadith was given as a consolation, and it is still one."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Equal in reward, not in obligation: an 'umrah in Ramadan does not discharge the Hajj that is due once in a lifetime, by the agreement of the scholars. Repeating the 'umrah from the edge of the sanctuary in a single stay is something the Companions did not do, and Ibn Taymiyyah and Ibn 'Uthaymin advised against it, while other scholars allow it."),
                  ]),
              ]),
        .init(id: "travel-duas", title: "The words of the journey",
              summary: "Takbir and the dua of mounting as you set out, takbir on the rises and tasbih on the descents, and the words of return.",
              group: .occasions,
              aliases: ["safar", "travel", "journey", "dua", "subhanalladhi sakhkhara", "mounting", "car", "plane", "ayibun", "taibun", "uphill", "downhill"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Every setting out had its words. When the Prophet had settled on his camel for a journey he said Allahu akbar three times, then the dua of mounting that Ibn 'Umar taught the people: praise of the One who put the mount under them, a request for righteousness and piety and deeds that please Him, a plea for an easy road and a shortened distance, and refuge from the hardship of travel and from finding ill at home. On the way back he said the same and added four words."),
                      .hadith("muslim:1342", cite: "Sahih Muslim 1342", arabic: 31...112, english: 0...129),
                      .text("The first sentence of the dua is the Quran's own, from the ayahs on the mounts Allah made for people to ride:"),
                      .quran("43:13-14"),
                      .text("On the road itself the Companions had a habit for the rises and the falls of the land, which Jabir describes:"),
                      .hadith("bukhari:2993", cite: "Sahih al-Bukhari 2993", arabic: 27...33, english: 0...25),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you are seated for the journey, in the car, the train or the plane, say Allahu akbar three times, then: Subhanalladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila rabbina la-munqalibun (glory be to Him who subjected this to us, for we could not have done it ourselves, and to our Lord we shall return). The words are the same for any vehicle; the mount is whatever carries you."),
                      .text("Then ask: Allahumma inna nas'aluka fi safarina hadha al-birra wat-taqwa wa minal-'amali ma tarda; Allahumma hawwin 'alayna safarana hadha watwi 'anna bu'dah; Allahumma antas-sahibu fis-safari wal-khalifatu fil-ahl; Allahumma inni a'udhu bika min wa'tha'is-safari wa ka'abatil-manzari wa su'il-munqalabi fil-mali wal-ahl (O Allah, we ask You on this journey for righteousness, piety and deeds You are pleased with; O Allah, make this journey easy for us and fold up its distance; O Allah, You are the Companion on the journey and the Guardian over the family; O Allah, I seek refuge in You from the hardship of the journey, from a grim sight, and from an ill return in wealth and family)."),
                      .text("On the road, say Allahu akbar as the land rises and subhanallah as it falls: on a hill, a flight's climb and descent, a bridge. Keep the voice low; when the Companions raised theirs in takbir he told them to go easy on themselves, since the One they called on was not deaf or absent (Sahih al-Bukhari 2992)."),
                      .text("On the way home say the same dua again, and add: ayibuna, ta'ibuna, 'abiduna, li-rabbina hamidun (returning, repenting, worshipping, praising our Lord). The traveller's dua is answered, he said, like the parent's and the wronged one's (Sunan Abi Dawud 1536, graded hasan by al-Albani), so the journey is also a time to ask."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The dua puts the journey where it belongs: the road is subjected by Allah, the destination is Him, and the family left behind is in His keeping. It asks for what a traveller actually needs, ease, a short road, protection on the way and at home, and for what he most easily forgets, that the journey be one of righteousness. The traveller's dua is among those answered without doubt, and a journey begun and ended with these words is held inside them."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The traveller has the concessions of the road: shortening the four-rak'ah prayers to two, joining Dhuhr with 'Asr and Maghrib with 'Isha, and breaking the fast to be made up; these are sunnahs of travel in their own right, not covered on this page."),
                  ]),
              ]),
        .init(id: "return-two-rakahs", title: "Come home by day, and go to the masjid first",
              summary: "Takbir at the sight of home, two rak'ahs in the masjid before anything else, and no knocking on the family at night.",
              group: .occasions,
              aliases: ["return", "arrival", "coming home", "kab ibn malik", "two rakahs", "masjid first", "homecoming", "night arrival", "tabuk", "ghazwa", "safar"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet's homecomings had a shape. Ka'b ibn Malik, whose account of being left behind from Tabuk is one of the longest in the Sahih, remembered the way he came back: in the forenoon, and to the masjid before his house, where he prayed two rak'ahs before he sat down to receive the people. Ibn 'Umar remembered the words on the road, said on every rise of the ground as Madinah came near."),
                      .hadith("bukhari:3088", cite: "Sahih al-Bukhari 3088", arabic: 37...49, english: 0...21),
                      .hadith("muslim:716", cite: "Sahih Muslim 716", arabic: 57...75, english: 0...39),
                      .hadith("bukhari:1797", cite: "Sahih al-Bukhari 1797", arabic: 26...77, english: 0...90),
                      .text("He also forbade a man away for a long time to come to his family at night without warning (Sahih al-Bukhari 1801), so that the house could be ready and no one be taken unawares; Jabir carried the prohibition, and the scholars read it as a kindness to both sides of the door."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When home comes into view, say Allahu akbar three times, then: la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir; ayibuna ta'ibuna 'abiduna sajiduna li-rabbina hamidun; sadaqallahu wa'dah, wa nasara 'abdah, wa hazamal-ahzaba wahdah (there is no god but Allah alone, without partner; His is the kingdom and His the praise, and He has power over all things; we return, repenting, worshipping, prostrating, praising our Lord; Allah kept His promise, gave His servant victory and routed the confederates alone)."),
                      .text("Go to the masjid before you go home, if you arrive at an hour when you can, and pray two rak'ahs there; the scholars count these the two rak'ahs of arrival, a sunnah of their own apart from the greeting of the masjid. Then go in to your family with the greeting of salam."),
                      .text("Arrive by day where you can, and if you must arrive at night, let the family know you are coming. The prohibition was given so that a wife could make herself ready and no one be surprised, and a message ahead keeps the reason even when the hour cannot be helped."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The two rak'ahs put Allah first at the end of the journey as the dua of mounting put Him first at its start, and the scholars say they are thanks for a safe return and a way of letting the masjid and the brothers know one is back. The words on the rise of the ground confess who the journey belonged to, and the prohibition on arriving at night protects a marriage from a moment that can do lasting harm."),
                  ]),
              ]),
        .init(id: "eid-sunnahs", title: "The day of Eid",
              summary: "Dates before the Fitr prayer, ghusl and best clothes, the takbir, a different road home, and everyone at the prayer.",
              group: .occasions,
              aliases: ["eid", "eid al-fitr", "eid al-adha", "festival", "takbirat", "musalla", "prayer ground", "odd dates", "new clothes", "ghusl", "taqabbal", "greeting"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Eid was the one morning of the year the Prophet broke a habit on purpose. He would not set out for the Fitr prayer until he had eaten dates, an odd number of them, ending the month's fast before the prayer; on the Adha he did the opposite, and ate nothing until he had prayed and his sacrifice could be eaten. He came home by a different road from the one he went out by."),
                      .hadith("bukhari:953", cite: "Sahih al-Bukhari 953", arabic: 24...37, english: 0...18),
                      .hadith("tirmidhi:542", cite: "Sunan al-Tirmidhi 542; graded sahih by al-Albani", arabic: 24...41, english: 0...25),
                      .hadith("bukhari:986", cite: "Sahih al-Bukhari 986", arabic: 20...31, english: 0...25),
                      .text("He wanted everyone at the prayer. Umm 'Atiyyah said the women were ordered out, even the young girls kept at home and the women in their periods, who stood apart from the prayer itself but joined in the takbir and the dua. The takbir is the Quran's own command at the end of the fast:"),
                      .hadith("bukhari:971", cite: "Sahih al-Bukhari 971", arabic: 17...42, english: 0...58),
                      .quran("2:185"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Before you go out, take a full bath and put on the best clothes you have; Malik records in the Muwatta that Ibn 'Umar bathed on the morning of the Fitr before going to the prayer ground, and the scholars list the ghusl and the finest dress among the sunnahs of the day. On the Fitr, eat an odd number of dates, three or five, before you leave. On the Adha, eat nothing until the prayer is over, so that the first food of the day is from the sacrifice."),
                      .text("Say the takbir on the way and at the prayer ground: Allahu akbar, Allahu akbar, la ilaha illallah, wallahu akbar, Allahu akbar, wa lillahil-hamd (Allah is the greatest, Allah is the greatest, there is no god but Allah; Allah is the greatest, Allah is the greatest, and to Allah belongs the praise). On the Fitr it runs from the evening before until the prayer; on the Adha the scholars take it from the Fajr of 'Arafah to the last of the days of tashriq."),
                      .text("Walk to the prayer if you can, as he went out and came back on foot (Sunan Ibn Majah 1294, graded hasan by al-Albani), take the women and children, and go home by a different road from the one you came by. Greet those you meet; the Companions said to one another taqabbalallahu minna wa minkum (may Allah accept from us and from you), and the scholars allow it on that ground."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Each sunnah of the day says something: the dates say the fast is over by Allah's leave; the empty stomach on the Adha says the first meal is from what was given to Allah; the takbir is the thanks the Quran asks for at the end of the month, for having been guided; and the two roads, the scholars say, let both ways bear witness and both sets of neighbours be greeted. The order to bring the women out, even those not praying, shows the day is for the whole community, and Umm 'Atiyyah gives the reason: to hope for its blessing and its purification."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The Eid prayer has no adhan and no iqamah (Sahih Muslim 886a), and no prayer is offered before or after it at the prayer ground (Sahih al-Bukhari 989); the scholars count attending it an emphasised duty, and some an obligation, so do not let the sunnahs around it become a reason to miss it. Fasting on either Eid is forbidden."),
                  ]),
              ]),
        .init(id: "udhiyah", title: "The sacrifice of Eid al-Adha",
              summary: "Two horned rams, slaughtered with his own hand with bismillah and takbir: the udhiyah for whoever can afford it.",
              group: .occasions,
              aliases: ["udhiyah", "qurbani", "sacrifice", "adha", "ram", "sheep", "nahr", "slaughter", "hair and nails", "dhul hijjah", "bismillah", "umm salamah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("On the day of the Adha, after the prayer, the Prophet sacrificed. Anas describes the animals, two horned rams, black and white, and the manner: with his own hand, Allah's name and the takbir spoken over them, his foot set on their flanks. For the one who intends to sacrifice there is a rule that begins ten days before, when the moon of Dhul-Hijjah is sighted, and Umm Salamah carried it."),
                      .hadith("bukhari:5565", cite: "Sahih al-Bukhari 5565", arabic: 10...26, english: 0...36),
                      .hadith("muslim:1977g", cite: "Sahih Muslim 1977g", arabic: 47...66, english: 0...37),
                      .text("The Quran sets the meaning: the animal is not what reaches Allah, but the piety of the one who offers it, and the meat is for eating and for the poor. He also set the time: whoever slaughtered before the Eid prayer had only given meat to his family, and had to slaughter again (Sahih al-Bukhari 955)."),
                      .quran("22:36-37"),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("If you mean to sacrifice, leave your hair and nails untouched from the first of Dhul-Hijjah until the animal is slaughtered; the rule is for the one who offers, not for the household. Choose a sound animal, a sheep of a year or, if that is hard to find, a lamb of six months (Sahih Muslim 1963), free of lameness, blindness, sickness and wasting."),
                      .text("Slaughter after the Eid prayer, on the day of the Eid or in the three days after it, and if you can, with your own hand as he did, facing the qiblah, with a sharp knife and quickly, saying: Bismillah, Allahu akbar (in the name of Allah; Allah is the greatest). One sheep suffices a household, and seven may share a camel or a cow."),
                      .text("Eat from it, give to the poor, and give gifts of it; the Quran names the eating and the feeding, and the scholars like a share for each without making it a rule. You may store what you keep for as long as you like, since he lifted the three-day limit he had once set (Sahih Muslim 1977a)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The sacrifice is the rite of the day; the Quran says to pray and sacrifice to your Lord (108:2) and sets its purpose in piety, not in blood. The scholars say it keeps the memory of Ibrahim's offering of his son and the ram Allah sent in his place, feeds the poor on the one day everyone should eat meat, and lets a family give its wealth to Allah with its own hands. Leaving the hair and nails likens the one who sacrifices, in a small way, to the pilgrim in ihram."),
                  ]),
                  SignSection("A NOTE", [
                      .text("On the majority view the udhiyah is a stressed sunnah for the one who can afford it; Abu Hanifah held it obligatory, and Ibn Taymiyyah and Ibn 'Uthaymin preferred that view for whoever has the means, so the able should not leave it. Nothing of it is sold, not even the skin, and the butcher's fee is not paid from it, as he ordered 'Ali for the sacrificial camels of Hajj (Sahih al-Bukhari 1717)."),
                  ]),
              ]),
        .init(id: "walimah-dua", title: "The dua for the newlywed, and the walimah",
              summary: "Barakallahu laka: his dua for the newly married, and the feast he told the groom to hold, even with one sheep.",
              group: .occasions,
              aliases: ["walimah", "walima", "wedding", "marriage", "nikah", "bride", "groom", "congratulations", "barakallahu laka", "abdur rahman ibn awf", "feast", "invitation"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("When someone married, the Prophet prayed for him in a single sentence, Abu Hurayrah says, and the sentence asks for blessing on each and for good between the two. When 'Abd al-Rahman ibn 'Awf married on what he had earned in the market, after refusing half of Sa'd ibn al-Rabi's wealth, the Prophet asked what he had given as mahr and told him to hold a feast."),
                      .hadith("tirmidhi:1091", cite: "Sunan al-Tirmidhi 1091; graded sahih by al-Albani", arabic: 23...40, english: 0...33),
                      .hadith("bukhari:5167", cite: "Sahih al-Bukhari 5167", arabic: 86...95, english: 134...147),
                      .text("His own walimahs were simple: for Safiyyah it was dates, dried curd and clarified butter spread on a leather mat (Sahih al-Bukhari 5085), and for Zaynab a sheep (Sahih al-Bukhari 5168). The invitation to a walimah is to be answered, he said, by whoever receives it (Sahih al-Bukhari 5173)."),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When you hear of a marriage, or meet the couple, say the dua he said: Barakallahu laka, wa baraka 'alayka, wa jama'a baynakuma fi khayr (may Allah bless you, and send blessings upon you, and join you both in good). It is said to the groom, and to the bride in her form, and it replaces the pre-Islamic wish of harmony and sons: when people said that to 'Aqil ibn Abi Talib he told them to say what the Prophet said instead (Sunan an-Nasa'i 3371, graded sahih by al-Albani)."),
                      .text("If you are the groom, hold a walimah: a meal for family and friends at the wedding or after it, with what you can afford; he said even one sheep, and his own were dates and butter. Invite the poor with the rich; Abu Hurayrah called the worst food the food of a walimah to which the rich are invited and the poor are left out, and said that whoever refuses the invitation has disobeyed Allah and His Messenger (Sahih al-Bukhari 5177)."),
                      .text("If you are invited, go, unless the gathering has in it what you cannot sit with; answering the invitation is a right of the one who gives it, and a person who is fasting may attend and pray for the hosts if he does not eat. Keep the feast free of extravagance and of what Allah forbids, and let the dua be heard in it."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The dua asks for exactly what a marriage needs: blessing on each of the two as a person and good gathered between them, and the scholars say it is the Sunnah's whole wish for a couple in nine words. The walimah announces the marriage, which the Prophet wanted known and not hidden, and gathers the community around it; a feast that costs a sheep and includes the poor does that as well as one that costs a fortune."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Men and women are not mixed at a walimah, and music beyond the daff and the singing of the girls that he allowed at a wedding (Sahih al-Bukhari 5147) is left out; a walimah that takes the guests into what is forbidden is not one the invited must attend."),
                  ]),
              ]),
        .init(id: "aqiqah", title: "The 'aqiqah on the seventh day",
              summary: "Two sheep for a boy and one for a girl on the seventh day, with the head shaved and the child named.",
              group: .occasions,
              aliases: ["aqiqah", "aqeeqah", "newborn", "birth", "seventh day", "shaving", "sheep", "samurah", "umm kurz", "rahinah", "pledge", "silver"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("A child's first week ends, in the Sunnah, with a sacrifice. The Prophet said a boy is held in pledge by his 'aqiqah, slaughtered for him on the seventh day, when his head is shaved and he is named, and Umm Kurz heard him set the number: two sheep for a boy and one for a girl. He did it for his own grandsons, and told Fatimah to shave al-Hasan's head and give the weight of the hair in silver (Sunan al-Tirmidhi 1519, graded hasan by al-Albani)."),
                      .hadith("abudawud:2838", cite: "Sunan Abi Dawud 2838; graded sahih by al-Albani", arabic: 26...35, english: 4...29),
                      .hadith("abudawud:2834", cite: "Sunan Abi Dawud 2834; graded sahih by al-Albani", arabic: 29...35, english: 8...22),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Count seven days from the birth, the day of birth being the first, and on the seventh slaughter two sheep for a boy or one for a girl, of the kind that serves for the udhiyah. The father does it, or whoever stands in for him; the meat is eaten, given away and shared with the poor like the sacrifice of Eid, and it may be cooked and served at a meal for family and neighbours."),
                      .text("On the same day shave the child's head, boy or girl, and give the weight of the hair in silver, or its value, in charity. Give the child a good name on that day if it was not given at birth: the dearest names to Allah are 'Abdullah and 'Abd al-Rahman, then the names of the prophets, and nothing with a bad meaning or a false claim."),
                      .text("If the seventh day is missed, through hardship or ignorance, do it when you can; the scholars say the 'aqiqah is not lost by delay, and a father may offer it for a child already grown. Two sheep for a boy is the sunnah, and one suffices where two cannot be found, since he offered one for al-Hasan by 'Ali's report."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The child is in pledge by his 'aqiqah, in the Prophet's words, which Ahmad ibn Hanbal read as meaning that a child whose 'aqiqah was not offered is held back from interceding for his parents; other scholars read it as the child being withheld from blessing until it is done. Either way the 'aqiqah is thanks to Allah for the child, a meal that announces him to the family, and his first charity, given in the weight of his own hair."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The 'aqiqah is a confirmed sunnah on the majority view, not an obligation, so a family that cannot afford it is not at fault; it is offered for the girl as for the boy, with one sheep, and the name may be given on the day of birth, as the page on the newborn's first day shows, since both are reported."),
                  ]),
              ]),
        .init(id: "tahnik-names", title: "The newborn's first day",
              summary: "A softened date on the palate, a dua for blessing, and a good name: what he did with the newborns brought to him.",
              group: .occasions,
              aliases: ["tahnik", "tahneek", "newborn", "date", "palate", "naming", "abdullah", "abd al-rahman", "abu musa", "abu talhah", "ibrahim", "barakah"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Companions brought their newborns to the Prophet, and the things he did with them became the sunnahs of a child's first day. Abu Musa's son was named Ibrahim, given tahnik with a date, and prayed over; Anas carried Abu Talhah's son to him on the day of his birth and watched him chew dates soft, open the child's mouth and put them in, and give him the name 'Abdullah. The names he loved most he named himself."),
                      .hadith("bukhari:5467", cite: "Sahih al-Bukhari 5467", arabic: 22...40, english: 0...34),
                      .hadith("muslim:2144a", cite: "Sahih Muslim 2144a", arabic: 17...85, english: 0...103),
                      .hadith("muslim:2132", cite: "Sahih Muslim 2132", arabic: 43...51, english: 0...9),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("On the day of the birth, or as soon after as you can, do the tahnik: soften a date in the mouth, or by hand, and rub a little of it on the roof of the child's mouth with a clean finger. The father may do it, or the mother, or a person of goodness whom the family asks, as the Companions asked the Prophet. Dates are what he used; where there are none, the scholars say something sweet serves."),
                      .text("Make dua for the child, as he did for Abu Musa's son: ask Allah for blessing on him, for his guidance and his soundness. The words are not fixed; Allahumma barik fih (O Allah, bless him) is enough, and the same for a girl in her form."),
                      .text("Give the child a good name. The best are 'Abdullah and 'Abd al-Rahman, by his own word, then any name of servitude to one of Allah's names, then the names of the prophets and the righteous. He named on the day of birth and on the seventh, so either is sunnah; what is avoided is a name with an ugly meaning, a name that claims what belongs to Allah, or the name of a wrongdoer."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("The tahnik is a sunnah done for the child before he can do anything for himself, and Ibn Hajar notes that the sweetness of the date was the first taste the Companions' children had, by the Prophet's hand. The dua for blessing asks for the one thing a parent most wants and least controls, and the name is the first gift a child carries all his life; he changed ugly names to good ones, as he changed 'Asiyah, the disobedient, to Jamilah, the beautiful (Sahih Muslim 2139a)."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The adhan in the newborn's ear rests on a narration al-Albani first graded hasan and later weak (Sunan Abi Dawud 5105); Ibn 'Uthaymin and others kept it as a sunnah, so the scholars differ on it, and nothing on this page depends on it. The scholars differ on whether the blessing of the tahnik lay in the Prophet's own saliva or in the act, and most allow a righteous person to do it today."),
                  ]),
              ]),
        .init(id: "follow-janazah", title: "Follow the funeral to the grave",
              summary: "Pray the funeral prayer and stay for the burial: a qirat for the prayer and two for the burial, each like a mountain.",
              group: .occasions,
              aliases: ["janazah", "funeral", "burial", "qirat", "grave", "dead", "death", "uthman", "ask forgiveness", "tathbit", "firmness", "ibn umar"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("The Prophet gave the funeral a reward with a measure. Whoever attends until the prayer has a qirat, and whoever stays until the burial has two, and when he was asked what a qirat was he answered with two great mountains. Ibn 'Umar, who used to pray and leave, said when the report reached him that they had lost many qirats (Sahih Muslim 945a). 'Uthman remembered what he did when the burial was finished: he stood at the grave and told the people what to ask for."),
                      .hadith("bukhari:1325", cite: "Sahih al-Bukhari 1325", arabic: 70...93, english: 6...53),
                      .hadith("abudawud:3221", cite: "Sunan Abi Dawud 3221; graded sahih by al-Albani", arabic: 21...44, english: 0...36),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("When a Muslim dies near you, go to the funeral prayer: it is prayed standing, with four takbirs, al-Fatihah after the first, the blessing on the Prophet after the second, the dua for the dead after the third, and the salam after the fourth. The dua he prayed asks forgiveness, mercy, a wide grave, a washing from sins and a home better than the one left (Sahih Muslim 963a)."),
                      .text("Walk with the body to the grave, or go with it in the car, and stay until it is buried. He said to hurry with the funeral, since a righteous soul is being brought to good and any other is a burden being set down from your necks (Sahih al-Bukhari 1315), so the walk is brisk and quiet, without wailing and without dhikr raised aloud."),
                      .text("At the grave, after the burial, stand a moment and ask for the dead as he asked: Allahummaghfir lahu, Allahumma thabbit-hu (O Allah, forgive him; O Allah, make him firm), for he is being questioned now. Then go to the family, console them, and see that food is sent to them, as he ordered food made for the family of Ja'far (Sunan Abi Dawud 3132, graded hasan by al-Albani)."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("Two qirats, each like a great mountain, for a prayer and a walk: the scholars say this is the largest reward attached to anything so short, and it is given because the dead has no one else now, and the funeral is a right the living owe him. Standing at the grave for his firmness comes at the hour he needs it most, the questioning in the grave, and the Prophet's words tell the living that this is the moment to be there."),
                  ]),
                  SignSection("A NOTE", [
                      .text("Women do not follow the funeral to the grave: Umm 'Atiyyah said they were forbidden it, though not strictly (Sahih al-Bukhari 1278), and the scholars keep the women at home or at the prayer. Following the body with incense, loud recitation or wailing is left out; the sunnah is silence, and dua in the heart."),
                  ]),
              ]),
        .init(id: "visit-graves", title: "Visit the graves",
              summary: "He lifted the ban on visiting graves because they remind of death: the greeting to the dead, and what a visit is for.",
              group: .occasions,
              aliases: ["ziyarah", "graveyard", "cemetery", "maqabir", "ahl al-diyar", "dead", "death", "remembrance", "buraydah", "salam to the graves", "akhirah", "hereafter"],
              sections: [
                  SignSection("WHAT HE DID", [
                      .text("Early in Islam the Prophet forbade the visiting of graves, when the people had only just left the ways of idolatry; later he lifted the ban in a sentence Buraydah reports, and said why on other occasions: the graves remind of the Hereafter. He asked his Lord's leave to visit his own mother's grave and was given it (Sahih Muslim 976a). For those who go out to the graves he taught a greeting, and Buraydah carried that too."),
                      .hadith("muslim:977a", cite: "Sahih Muslim 977a", arabic: 55...59, english: 0...11),
                      .hadith("muslim:975", cite: "Sahih Muslim 975", arabic: 59...75, english: 21...51),
                  ]),
                  SignSection("HOW TO KEEP IT", [
                      .text("Go to the graves from time to time, to the grave of a parent or a friend or to any Muslim graveyard, with the one purpose the Prophet gave: to remember death and the Hereafter, and to pray for the dead. Go quietly, without perfume or finery, and do not walk over the graves or sit on them."),
                      .text("Say the greeting as you enter: as-salamu 'alaykum ahlad-diyari minal-mu'minina wal-muslimin, wa inna in sha' Allahu bikum lahiqun, as'alullaha lana wa lakumul-'afiyah (peace be upon you, people of these dwellings, believers and Muslims; we shall, if Allah wills, join you; I ask Allah for well-being for us and for you). Then make dua for the dead, for forgiveness and mercy, facing the qiblah, with the hands raised if you wish."),
                      .text("Make the visit a reminder for yourself: that the people under the earth were as you are, that you will be as they are, and that what they want most is one more good deed. Leave with a resolve and with dua for them, and do not turn the visit into a ritual of a fixed day."),
                  ]),
                  SignSection("WHY IT MATTERS", [
                      .text("He lifted the ban for a reason he named, remembrance of the Hereafter, and the scholars say nothing softens a hard heart like the sight of a grave. The visit is also a kindness to the dead, who are helped by the dua of the living, and the greeting he taught is itself a dua for them and a reminder for the one who says it: we shall join you."),
                  ]),
                  SignSection("A NOTE", [
                      .text("The visit is for remembrance and for dua for the dead, and nothing else: no journey is undertaken to a grave, since he forbade setting out except for the three masjids (Sahih al-Bukhari 1189), and nothing is asked of the dead, nor of Allah by their standing, which the scholars count as the door to shirk. The scholars differ on women visiting graves: Ibn Baz forbade it by the hadith that curses the women who visit often (Sunan al-Tirmidhi 1056, graded hasan by al-Albani), and others allow a visit without frequenting, by the general permission."),
                  ]),
              ]),
    ]
}
#endif
