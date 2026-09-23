#!/usr/bin/env python3
"""Al-Islam's Tajweed Foundations, merged into the tajweed course lesson by lesson.

The app had two tajweed screens covering one subject: Tajweed Foundations, Al-Islam's own
fourteen topic pages, and the course Jamil Hammoudeh wrote for Tilawa (ported with his
permission). Abu, 2026-09-23: "go one by one and make it joint ... if in mine it is solar laam
and then in tajweed course there is solar laam put that together into one ... if there is
something I don't have then make that its own ... I want all of both in one merged thing", in
the course's design. This module is the Al-Islam half of that merge, as data:
Scripts/build_tajweed_lessons.py evaluates Tilawa's chapters, applies everything here, and
validates and packs the result, so the course keeps rebuilding from Tilawa's source and a
Tilawa content fix still lands.

WHERE EACH FOUNDATIONS TOPIC WENT (the old screen's fourteen topics plus its own overview):

    Overview, Why Learn Tajweed, Applicability  -> what-is-tajweed (body, table, key points, doors)
    How to Start Learning                       -> improving-recitation
    Improving Your Recitation                   -> improving-recitation (NEW LESSON: no counterpart)
    Lip Movement                                -> lips-nasal-passage
    Tajweed Hints in the Mushaf                 -> reading-the-script, tanween-shapes
    Makhaarij                                   -> makharij-overview (diagrams, playlist, practice
                                                   advice), throat-letters, tongue-regions,
                                                   lips-nasal-passage, makharij-table
    Sifaat                                      -> sifat-overview, sifat-standalone (the alphabet's
                                                   qualities shelf as a door, the families as rows)
    Heavy and Light                             -> heavy-light-letters, ra-tafkheem-tarqeeq,
                                                   lafz-al-jalalah
    Shams and Qamar: Al                         -> lam-shamsiyyah-qamariyyah
    Madd                                        -> madd-tabii (tiny madd letters, madd tamkin),
                                                   madd-muttasil, madd-munfasil (munfasil hukmi and
                                                   its eighteen words), madd-badal, madd-iwad,
                                                   madd-leen, madd-arid, madd-lazim, madd-silah,
                                                   mudood-chart (the three teaching rules)
    Qalqalah                                    -> qalqalah
    Noon Sakinah and Tanween                    -> tanween, nun-sakin-overview, idhhar, the two
                                                   idghams, iqlab, ikhfa
    Meem Sakinah                                -> mim-sakin-rules (three playable ayahs)
    4 Sukoon                                    -> sukoon (the four sukoon signals)
    Hamzatul Wasl                               -> hamzat-al-wasl
    Waqf                                        -> waqf-types (the dangerous stop, the stop signs),
                                                   waqf-changes
    Tajweed Legend, Letter Families,
    Sound-Alike Letters, Learn More             -> the course index itself (TajweedLessons.swift)

Two corrections were made on the way in, rather than carried over: the Madd page listed شَيۡءٌ
as a madd muttasil example, but in Hafs its ya is a leen letter (no madd while reading on, madd
leen at a stop), so it now teaches that in madd-leen; and the 4 Sukoon page's video link was
the Meem Sakinah video (MAvDrZgWRTs), so it now points at Arabic 101's four-types-of-sukoon
short.

HOW A MERGE READS. `MERGES[lesson_id]` edits one Tilawa lesson:

* `"field": [...]` for a list field (body, keyPoints, letterSets, mistakes, examples, drills,
  quiz, related) is the WHOLE merged list in order. `"@3"` stands for Tilawa's item 3, and
  `{"@": 3, "wrong": "..."}` is Tilawa's item 3 with those fields replaced. Every Tilawa item must
  be placed exactly once, so nothing of either side can be dropped by accident, and a Tilawa
  update that adds an item fails the build until it is placed.
* `"field+": [...]` appends to Tilawa's list.
* `"table"`: a dict whose `"rows"` follow the same @ rules, other keys replacing Tilawa's; or a
  whole new table on a lesson that had none.
* anything else replaces or adds the field: summary, minutes, and the Al-Islam fields below.

THE AL-ISLAM FIELDS (pack version 5; TajweedLessons.swift renders each):

* `words`   groups of Arabic words with their reading, the way the Foundations pages taught:
            `{"label", "note"?, "items": [(arabic, reading) or (arabic, reading, note)]}`. The
            Arabic goes through the same Quran-reference pass as the drills, so a run that is a
            whole ayah or sits in exactly one ayah is stored as a reference, never a copy.
* `videos`  `{"title", "url", "channel"}` (Arabic 101's lessons, as the Foundations pages linked them).
* `images`  asset-catalog images (the two makharij diagrams).
* `families` LetterTraits family ids shown as "On the Alphabet" rows; the app adds every family
            whose own lesson is this one, so these are the extra ones the Foundations page chose.
* `doors`   screens of the app a lesson opens (`DOORS`).
* `extras`  native blocks drawn inside the lesson (`EXTRAS`).
* `legend`  the reader's tajweed colour the lesson wears (a TajweedLegendCategory raw value),
            so a rule's lesson is painted in the colour the mushaf paints the rule.
"""

from __future__ import annotations

# Screens a lesson can open (TajweedLessons.swift `TajweedLessonDoor`).
DOORS = {
    "quranArticle": "What is the Quran?",
    "tajweedArticle": "What is Tajweed?",
    "ahrufArticle": "What are the 7 Ahruf?",
    "qiraatArticle": "What are the 10 Qiraat?",
    "letterFamilies": "Letter Families",
    "soundAlikes": "Sound-Alike Letters",
    "makharijShelf": "The Seventeen Exits on the Alphabet",
    "sifaatShelf": "Sifaat on the Alphabet",
    "tajweedLegend": "Tajweed Legend",
}

# Native blocks a lesson can carry (TajweedLessons.swift `TajweedLessonExtra`).
EXTRAS = {"waqfSigns"}

# Images a lesson can show, from Resources/Images.xcassets.
IMAGES = {"Makharij1", "Makharij2"}

ARABIC_101 = "Arabic 101"

# The chapter whose name was the old screen's own: the whole course is Tajweed Foundations now.
CHAPTERS = {
    "foundations": {
        "title": "Principles of Tajweed",
        "subtitle": "What tajweed is, where its rules come from, how to sit with it, and how to get better at it",
    },
}

# ---------------------------------------------------------------------------------------------
# The one Foundations topic with no lesson beside it.

IMPROVING_RECITATION = {
    "id": "improving-recitation",
    "titleEn": "Improving Your Recitation",
    "titleAr": "تحسين التلاوة",
    "translit": "Tahsin at-tilawah",
    "minutes": 7,
    "summary": "Knowing the rules is not the same as reciting with them. Three habits carry tajweed from the page into your mouth: practising on your own, listening to skilled reciters, and reciting to someone who can correct you.",
    "definition": {
        "termAr": "التلقي",
        "literal": "to receive, to take something from another",
        "technical": "Taking the recitation directly from a qualified teacher: hearing it from their mouth, reciting it back, and being corrected, the way the Quran has been passed on from the Prophet ﷺ to this day.",
    },
    "body": [
        "This course on its own is not enough to develop strong tajweed and pronunciation. It can introduce the rules and the concepts, but real improvement in recitation comes from consistent practice, careful listening, and guidance from knowledgeable teachers.",
        "Ideally, use it alongside a teacher who can listen to your recitation and correct your mistakes. Tajweed is refined through feedback and repetition, and many pronunciation errors are difficult to notice on your own. To truly benefit, approach the Quran with sincerity, humility and love. Put your trust in Allah and be willing to learn.",
        "Set aside arrogance and ego as well. Even if you believe your tajweed, your voice or your makharij are good, there is always room to improve: the greatest reciters spent years refining their recitation. Three consistent practices will get the most out of this course and out of your learning.",
        "The first is reciting on your own, regularly. It builds reading fluency and speed, familiarity with the words and ayahs, and control of your voice and tone, and it is where you apply the corrections you have been given. But the saying that practice makes perfect is not true. Perfect practice makes perfect. Reciting carelessly, or repeating a pronunciation nobody has checked, reinforces the mistake instead of correcting it. So solo practice should be consistent, careful, and built on corrections you have actually received.",
        "It is like practising a sport alone. Individual practice builds skill and stamina, but without proper technique it only takes you so far. And even the best teacher cannot help you improve if you never put in the hours of practice yourself.",
        "The second is listening to skilled reciters, one of the most powerful ways to improve pronunciation and rhythm. Many students benefit from the classical Egyptian reciters, such as Sheikh Muhammad Siddiq al-Minshawi and Sheikh Mahmoud Khalil al-Husary, both widely respected for their clarity, precision and strong tajweed. Their recordings usually come in two styles: murattal, a steady, clear recitation that is ideal for learning, and mujawwad, a slower, melodic recitation that emphasises precision and beauty.",
        "Find a reciter whose voice you genuinely enjoy: a connection with a reciter often deepens your love for the Quran and your motivation to recite. But do not listen passively. Follow along in the mushaf, read aloud with the reciter, try to match their tajweed and pronunciation, and pay attention to how each letter is articulated, how long each madd is held, and where the pauses fall. It is like studying expert athletes: learning from masters by carefully observing how they perform. Structured lessons, such as the Arabic 101 series linked below, help here too.",
        "The third is reciting to a teacher or a knowledgeable partner, and it is the most effective of the three. Someone trained hears the mistakes you will not notice yourself: an incorrect makhraj, a subtle pronunciation error, an uneven madd, a weak ghunnah, a stop or a restart in the wrong place. Corrections can feel repetitive or strict, but they are extremely valuable. Small refinements add up, and the best recitation is the one that is correct and refined in every aspect, the major and the subtle.",
        "Learning with a teacher is like training with a coach, who watches your technique and gives you corrections no one else can. If a formal teacher is not available, recite to someone with strong tajweed who is willing to listen and correct you. Traditionally tajweed was always learned this way, face to face. Today there are also online classes, videos and books with step-by-step lessons, and a class or study circle adds the feedback and support of others on the same path.",
        "If it all seems a lot at first, start small. Master the basic rules, build gradually, and practise consistently. Recording your own recitation and listening back is one of the simplest ways to catch mistakes you cannot hear while you are reciting.",
    ],
    "keyPoints": [
        "Perfect practice makes perfect: repeating an unchecked mistake only strengthens it.",
        "Listen actively: follow in the mushaf, recite along, and imitate what you hear.",
        "Murattal is steady and clear for learning; mujawwad is slower and melodic.",
        "A teacher hears what you cannot hear in yourself. Nothing replaces that.",
        "Record yourself and listen back.",
    ],
    "table": {
        "title": "Three practices, and what each one gives you",
        "columns": ["Practice", "What it builds", "What it cannot do alone"],
        "rows": [
            ["Reciting on your own", "Fluency, familiarity, stamina and voice control", "Catch the mistakes you cannot hear"],
            ["Listening to skilled reciters", "Pronunciation, rhythm, and the sound of correct tajweed", "Show you where your own recitation differs"],
            ["Reciting to a teacher", "Correct makharij, madd, ghunnah and stops, one correction at a time", "Replace the hours of practice only you can put in"],
        ],
    },
    "mistakes": [
        {
            "wrong": "Repeating a page over and over without ever having it checked.",
            "right": "Practise what a teacher has corrected, and bring the rest back to them.",
            "why": "Practice makes permanent, not perfect. An unchecked mistake repeated a hundred times becomes a habit that takes far longer to undo than it took to learn.",
        },
        {
            "wrong": "Letting a recording play in the background while doing something else.",
            "right": "Follow in the mushaf, recite along, and imitate what you hear.",
            "why": "Passive listening makes the sound familiar, but it does not build the skill of producing it.",
        },
        {
            "wrong": "Waiting until your tajweed is good before reciting to anyone.",
            "right": "Recite to a teacher or a knowledgeable friend from the start.",
            "why": "The errors you most need corrected are the ones you cannot hear in yourself, and nobody can correct what they never hear.",
        },
        {
            "wrong": "Deciding your recitation is already good enough.",
            "right": "Stay humble and keep refining. The greatest reciters spent years on it.",
            "why": "Ego is what stops a reciter from hearing a correction, and the fine points are where good recitation becomes excellent.",
        },
    ],
    "examples": [
        {
            "surahId": 75,
            "ayahNumber": 18,
            "word": "فَإِذَا قَرَأۡنَٰهُ فَٱتَّبِعۡ قُرۡءَانَهُۥ",
            "focus": "Listen first, then follow. The Quran itself was taught by being recited and then followed.",
        },
        {
            "surahId": 54,
            "ayahNumber": 17,
            "word": "وَلَقَدۡ يَسَّرۡنَا ٱلۡقُرۡءَانَ لِلذِّكۡرِ",
            "focus": "Allah has made the Quran easy to remember. The effort you bring to it is met with ease.",
        },
    ],
    "quiz": [
        {
            "prompt": "Which saying describes solo practice correctly?",
            "choices": ["Practice makes perfect", "Perfect practice makes perfect", "Practice is unnecessary once you have a teacher", "Practise only in front of others"],
            "answer": 1,
            "explain": "Repeating an unchecked mistake reinforces it. Solo practice works when it is careful and built on corrections you have actually received.",
        },
        {
            "prompt": "What is a murattal recording?",
            "choices": ["A slow, melodic style that emphasises beauty", "A steady, clear recitation that is ideal for learning", "A recitation from memory only", "A recitation without tajweed"],
            "answer": 1,
            "explain": "Murattal is steady and clear, which is why it suits learners. Mujawwad is the slower, melodic style. Both are recited with full tajweed.",
        },
        {
            "prompt": "Why is reciting to a teacher the most effective of the three practices?",
            "choices": ["A teacher recites faster", "A teacher hears the mistakes you cannot hear in yourself", "It removes the need to practise alone", "It is only needed by beginners"],
            "answer": 1,
            "explain": "Nobody hears their own mouth from the outside. A teacher catches the subtle errors in makharij, madd, ghunnah and stopping that you would never notice, and still needs you to put in the practice.",
        },
    ],
    "videos": [
        {"title": "Why are you still struggling with Quran recitation?", "url": "https://www.youtube.com/watch?v=_acpVGn0ys0", "channel": ARABIC_101},
        {"title": "The best and fastest route to learn Arabic and the Quran", "url": "https://www.youtube.com/watch?v=86qiFqqZSG0", "channel": ARABIC_101},
    ],
    "related": ["what-is-tajweed", "levels-of-recitation", "manners-reading"],
}

NEW_LESSONS = [
    {"chapter": "foundations", "after": "tajweed-principles-errors", "lesson": IMPROVING_RECITATION},
]

# ---------------------------------------------------------------------------------------------
# The merges, in course order.

MERGES: dict[str, dict] = {}

# ---- Reading Foundations ----------------------------------------------------------------------

MERGES["sukoon"] = {
    # 4 Sukoon: the four sukoon-like signals of the Uthmani script.
    "summary": "A sukoon is the absence of a vowel. The letter is made and released with nothing after it, and almost every rule in this course is triggered by a letter in that state. The mushaf also has three other sukoon-like signals, and telling the four apart is half of reading the page.",
    "minutes": 8,
    "body": [
        "@0", "@1", "@2", "@3", "@4",
        "The mushaf uses four sukoon-like signals, and each one tells you something different. Telling them apart is what lets you read a letter correctly before you have thought about any rule at all.",
        "The first is the ordinary sukoon (ۡ) this lesson has been about: the letter has no vowel, and it is still pronounced clearly. In رَزَقۡنَٰهُمۡ the ق and the م both carry it. Say them, and add nothing after them. The ق also bounces, because qalqalah is the one rule with no mark of its own: you know it by the rule, or by the tajweed colours in the reader.",
        "The second is a small round zero (ْ), and it sits on a letter that is written but never pronounced, whether you read on or stop. The ya of بِأَيۡيْدٖ is written twice and read once, and the alif closing قَالُواْ or كَانُواْ is never sounded. The spelling keeps the letter; the mark tells you to skip it.",
        "The third is a small upright zero (۠), on a letter that is skipped while you read on and pronounced only when you stop on the word. أَنَا۠ ends in a short a when you carry on into the next word, and in its alif when you stop on it. قَوَارِيرَا۠, closing 76:15, ends in an alif only at the stop.",
        "The fourth is no mark at all. A letter with neither a vowel nor a sukoon is either a madd letter, stretched for two counts like the و and ي of يُقِيمُونَ, or a letter a rule is changing, like the noon of يُنفِقُونَ, hidden by ikhfa before the ف. Either way, a bare letter is never a printing slip: something is happening to it.",
    ],
    "keyPoints+": [
        "Four signals: the sukoon, say the letter with no vowel; the round zero, never say it; the upright zero, say it only at a stop; no mark, a madd letter or a rule at work.",
    ],
    "table": {
        "title": "The four sukoon signals",
        "arabicFirstColumn": True,
        "columns": ["Mark", "What it tells you", "Example"],
        "rows": [
            ["قۡ", "An ordinary sukoon: say the letter, with no vowel after it", "رَزَقۡنَٰهُمۡ"],
            ["يْ", "The round zero: written, never pronounced", "بِأَيۡيْدٖ"],
            ["ا۠", "The upright zero: silent when you read on, pronounced when you stop", "أَنَا۠"],
            ["no mark", "A madd letter, or a letter a rule is changing", "يُنفِقُونَ"],
        ],
    },
    "mistakes+": [
        {
            "wrong": "Pronouncing a letter that carries the round zero, like the alif closing قَالُواْ.",
            "right": "Skip it, whether you read on or stop. The round zero means written and never sounded.",
            "why": "Sounding it adds a letter to the word that the recitation has never had.",
        },
        {
            "wrong": "Sounding the alif of أَنَا۠ while reading on into the next word.",
            "right": "Read on with a short a, and sound the alif only when you stop on the word.",
            "why": "The upright zero marks a letter that exists only at a stop. Joined, it is not read.",
        },
    ],
    "examples+": [
        {"surahId": 2, "ayahNumber": 3, "word": "رَزَقۡنَٰهُمۡ يُنفِقُونَ", "focus": "Ordinary sukoons on the ق and the م of رَزَقۡنَٰهُمۡ, and no mark at all on the noon of يُنفِقُونَ, which ikhfa is hiding."},
        {"surahId": 51, "ayahNumber": 47, "word": "بِأَيۡيْدٖ", "focus": "The second ya carries the round zero: written, never read."},
        {"surahId": 18, "ayahNumber": 110, "word": "أَنَا۠ بَشَرٞ مِّثۡلُكُمۡ", "focus": "Read on, and أَنَا۠ ends in a short a. Stop on it, and its alif is sounded."},
        {"surahId": 76, "ayahNumber": 15, "word": "قَوَارِيرَا۠", "focus": "The upright zero on the last alif: say it if you stop here, drop it if you carry on into the next ayah."},
    ],
    "quiz+": [
        {
            "prompt": "A letter carries a small upright zero (۠). When do you pronounce it?",
            "choices": ["Always", "Never", "Only when you stop on the word", "Only when you read on"],
            "answer": 2,
            "explain": "The upright zero marks a letter that is silent while you read on and pronounced when you stop. The round zero is the one that is never pronounced at all.",
        },
    ],
    "videos": [
        {"title": "The four types of sukoon in the Quran", "url": "https://www.youtube.com/shorts/ZlMsseUu7hU", "channel": ARABIC_101},
    ],
    "related+": ["reading-the-script", "special-words-hafs"],
}

MERGES["tanween"] = {
    # Noon Sakinah and Tanween: tanween pronunciation.
    "words": [
        {
            "label": "Tanween is said as a noon",
            "items": [("بًا", "بَنۡ, ban"), ("بٌ", "بُنۡ, bun"), ("بٍ", "بِنۡ, bin")],
        },
    ],
    "keyPoints+": ["Tanween is not a vowel. It is a hidden noon sound in disguise."],
}

MERGES["madd-letters"] = {"legend": "maddNatural"}

# ---- Principles of Tajweed ----------------------------------------------------------------------

MERGES["what-is-tajweed"] = {
    # The Foundations overview: what tajweed, recitation and pronunciation are; why learn it; how the
    # rules apply to the other qiraat; and the four articles it pointed to.
    "minutes": 8,
    "body": [
        "@0",
        "Recitation has two names. قِرَاءَة, qira'ah, simply means reading. تِلَاوَة, tilawah, carries more: reciting with attentiveness, reflection and adherence to a proper method. And Quranic recitation is not only reading a text. It is the transmission of a preserved oral tradition, passed down from the Prophet ﷺ through every generation since.",
        "@1",
        "Pronunciation in that tradition is governed by two things: makharij (مَخَارِجُ الحُرُوفِ), the points of articulation where each letter is made in the throat or mouth, and sifat (صِفَاتُ الحُرُوفِ), the characteristics it is made with, such as heaviness (tafkhim), lightness (tarqiq) or the echo of qalqalah. Together they keep every letter distinct, and they matter because even a slight change in pronunciation can change a meaning. That is why tajweed preserves the accuracy and the integrity of the Quran as well as its beauty. The Quran was revealed to be recited, and Allah commands: and recite the Quran with measured recitation (tartil), 73:4.",
        "@2",
        "@3",
        "The Prophet ﷺ encouraged reciting the Quran beautifully, saying: \"He is not one of us who does not recite the Quran melodiously\" (Sahih al-Bukhari 7527). Beauty of voice is a sunnah of its own, and it rests on the correctness this course teaches: a beautiful voice on a broken letter is still a broken letter.",
        "@4",
        "Hafs an Asim is the most widely recited riwayah in the world today, and the standard riwayah of most printed mushafs. Other riwayat, such as Warsh an Nafi and Khalaf an Hamzah, differ in places in how they apply the rules: the lengths of the madd, the treatment of the hamzah, and some finer points of pronunciation. These differences are authentic. They are rooted in the dialects of classical Arabic, they were recited and approved by the Prophet ﷺ, and they have been preserved exactly through continuous chains of recitation. So a rule in this course may not apply identically in another riwayah, and that reflects the richness, flexibility and authenticity of the recitation tradition rather than any contradiction in it.",
    ],
    "keyPoints+": [
        "Pronunciation rests on makharij (where a letter is made) and sifat (how it is made).",
        "Other riwayat apply some rules differently, and they are just as authentic as Hafs.",
    ],
    "table": {
        "title": "Why learn tajweed",
        "columns": ["Reason", "What it means"],
        "rows": [
            ["Honoring the Quran", "It is the final revelation from Allah. Reciting it with care and precision is a form of reverence, following the Prophet ﷺ, who recited with the utmost clarity and eloquence."],
            ["Preventing misunderstandings", "Changing a single sound, or stretching the wrong vowel, can produce an entirely different meaning."],
            ["A deeper connection", "The attention tajweed asks for draws you into the meaning, and many find their recitation becomes more mindful, more reflective and more moving."],
            ["Following the Sunnah", "The Prophet ﷺ encouraged reciting the Quran beautifully, and learning tajweed follows his teaching and example."],
        ],
    },
    "quiz+": [
        {
            "prompt": "A reciter of Warsh an Nafi lengthens a madd differently from this course. What does that mean?",
            "choices": ["They are making a mistake", "Warsh is a later invention", "Each riwayah was transmitted with its own authentic way of applying some rules", "Tajweed rules are a matter of personal taste"],
            "answer": 2,
            "explain": "The riwayat differ in places such as madd lengths and the treatment of the hamzah. Each difference was recited and approved by the Prophet ﷺ and reached us through continuous transmission, so none of them is a mistake.",
        },
    ],
    "related": ["tajweed-principles-errors", "improving-recitation", "levels-of-recitation", "manners-reading"],
    "doors": ["tajweedArticle", "quranArticle", "ahrufArticle", "qiraatArticle"],
}

MERGES["tajweed-principles-errors"] = {
    "related": ["what-is-tajweed", "improving-recitation", "levels-of-recitation", "nun-sakin-overview"],
}

# ---- Articulation Points ----------------------------------------------------------------------

MERGES["makharij-overview"] = {
    # Makhaarij: the diagrams, the playlist, awareness over memorisation, and the practice advice.
    "minutes": 7,
    "body": [
        "@0",
        "Correct makharij are the foundation of tajweed: if a letter does not come from its proper place, no amount of rules will fix the sound. The aim of this chapter is awareness rather than memorisation, to know where each sound comes from and what moves to produce it.",
        "@1",
        "If five is too many to start with, begin with three. For learning purposes the throat, the tongue and the lips carry every consonant, and the empty space and the nose can come in once those three feel familiar.",
        "@2", "@3", "@4",
        "Makharij are learned by sound, not by sight. Use the diagrams above as references rather than something to stare at while reciting; over time the right positions become muscle memory. The method is always the same: listen, imitate, repeat aloud, with isolated letter sounds, minimal exaggeration and clear mouth positions. Silent learning does not work for makharij. If you cannot hear a difference, slow down and exaggerate slightly while practising, then return to natural recitation.",
        "@5",
    ],
    "keyPoints+": [
        "Tajweed rules refine the sound. Makharij create it.",
        "Listen, imitate, repeat aloud: silent study does not train a makhraj.",
        "Correct makharij preserve the Quran exactly as it was revealed.",
    ],
    "mistakes+": [
        {
            "wrong": "Studying the diagrams silently and expecting the letters to follow.",
            "right": "Say every letter aloud from its place, listening and imitating, until the position is muscle memory.",
            "why": "Makharij are learned by sound, not by sight. A diagram tells you where; only your own mouth can learn it.",
        },
    ],
    "images": [
        {"name": "Makharij1", "caption": "The articulation points, from the throat to the lips"},
        {"name": "Makharij2", "caption": "Where each letter is made"},
    ],
    "videos": [
        {"title": "Makharij and sifaat, the full playlist", "url": "https://www.youtube.com/watch?v=-YrfRpwFMe8&list=PL6TlMIZ5ylgpmlnN3EpkOec0tJ8OJZ5re", "channel": ARABIC_101},
    ],
    "families": ["jawf", "halq", "aqsaLisan", "wasatLisan", "haffatLisan", "tarafLisan", "shafatan"],
    "doors": ["makharijShelf", "letterFamilies"],
}

MERGES["throat-letters"] = {
    "body": [
        "@0", "@1",
        "Whatever their depth, the throat letters are clear and open. None of them is nasal, and none is forced out of a strained throat: even the narrowing of the ح is a narrowing, not a squeeze of effort.",
        "@2", "@3", "@4", "@5", "@6", "@7",
    ],
    "words": [
        {
            "label": "Throat letters in words",
            "items": [("أَحَد", "ahad"), ("نَعۡبُدُ", "na'-bu-du"), ("غَفُور", "ghafur"), ("خَالِد", "khalid")],
        },
    ],
}

MERGES["tongue-regions"] = {
    "keyPoints+": ["Small shifts in tongue position matter. Aim for accuracy, not strength."],
    "mistakes+": [
        {
            "wrong": "Letting neighbouring tongue letters collapse into one sound.",
            "right": "Give each letter its own distinct articulation.",
            "why": "Ten exits sit close together on the tongue, and a letter that lands one step off is a different letter.",
        },
        {
            "wrong": "Forcing pressure on the tongue letters to make them sound strong.",
            "right": "Put the tongue in the right place, lightly. Accuracy matters more than force.",
            "why": "Extra pressure makes a letter tense and heavy without moving it to its exit, and the exit is what makes the letter.",
        },
    ],
    "words": [
        {
            "label": "Tongue letters in words",
            "items": [("قُلۡ", "qul"), ("سَمِيع", "samee'"), ("نُور", "nur"), ("رَبِّ", "rabbi")],
        },
    ],
}

MERGES["lips-nasal-passage"] = {
    # Lip Movement (natural recitation, the damma, the folding mim) and the lips of the Makhaarij page.
    "minutes": 7,
    "body": [
        "@0",
        "The mirror is also where the most common lip fault shows: overemphasis. Exaggerating the mouth, stretching the lips sideways, or forcing a sound in a way that is unnatural to Arabic makes the recitation less correct, not more. As a general rule the lips move up and down, not sideways; they are never stretched into exaggerated shapes; and the tongue and the throat do most of the work. Recited correctly, the Quran sounds smooth, balanced and natural, like careful classical Arabic speech.",
        "@1", "@2",
        "There is exactly one time the lips clearly point outward: the sounds of the damma. For a damma (ـُ), a dammatayn (ـٌ), and a waw sakinah after a damma (ـُو), the lips round and project slightly forward to make a true u. Everywhere else they stay relaxed. And for the م, think of the lips as folding together, not squeezing.",
        "@3", "@4", "@5", "@6", "@7",
    ],
    "keyPoints+": [
        "Lips move up and down, never stretched sideways. The tongue and throat do most of the work.",
        "Only the damma sounds push the lips forward: ـُ, ـٌ, and the waw after a damma.",
    ],
    "mistakes+": [
        {
            "wrong": "Exaggerating the mouth: stretching the lips sideways or forcing sounds to make the recitation sound more correct.",
            "right": "Keep the movement natural: lips up and down, with the tongue and throat doing the work.",
            "why": "Overemphasis is one of the most common faults in recitation. It distorts the letters instead of clarifying them.",
        },
        {
            "wrong": "Weak, lazy lip contact, so ب and م come out soft and blurred.",
            "right": "Gentle, controlled movement: a full closure for each, firm for the ب and light for the م.",
            "why": "A closure that never quite happens loses the letter, and one that is squeezed hard cuts the sound short.",
        },
    ],
    "words": [
        {
            "label": "Lip letters in words",
            "items": [("بَصِير", "basir"), ("أَمۡر", "amr"), ("فِيهِ", "fihi")],
        },
    ],
    "families": ["ghunnah"],
}

MERGES["makharij-table"] = {
    "doors": ["makharijShelf"],
}

# ---- Letter Qualities --------------------------------------------------------------------------

MERGES["sifat-overview"] = {
    # Sifaat: the alphabet's qualities shelf, every family named in Arabic and English.
    "doors": ["sifaatShelf", "letterFamilies"],
}

MERGES["sifat-standalone"] = {
    "families": ["qalqalah", "leen"],
}

MERGES["heavy-light-letters"] = {
    "legend": "tafkhim",
    "minutes": 7,
    "body": [
        "@0", "@1",
        "A heavy letter is said with the back of the tongue raised and a full, deep sound, and it is never thinned, even under a kasrah. A light letter is the opposite: the tongue relaxed and low, with no back-tongue elevation, and a clear, sharp articulation.",
        "@2", "@3", "@4", "@5",
    ],
    "keyPoints+": ["Alif follows, never leads: it takes the weight of the letter before it."],
    "mistakes+": [
        {
            "wrong": "Making an alif heavy by itself, after a light letter.",
            "right": "Let the alif follow the letter before it: full after قَ, thin after كَ.",
            "why": "Alif has no weight of its own. A heavy alif after a light letter thickens a word that should stay thin.",
        },
    ],
    "words": [
        {
            "label": "Always heavy",
            "items": [("قَالَ", "qala"), ("صِرَٰط", "sirat"), ("طَبَعَ", "ta-ba-'a"), ("غَفُور", "ghafur"), ("خَالِد", "khalid")],
        },
        {
            "label": "Always light",
            "items": [("بِسۡم", "bism"), ("نَعِيم", "na-'eem"), ("سَبِيل", "sabil"), ("يَوۡم", "yawm"), ("فِيهِ", "fihi")],
        },
        {
            "label": "Alif follows the letter before it",
            "items": [("قَالَ", "qala", "heavy, after ق"), ("صَادِق", "sadiq", "heavy, after ص"), ("كَانَ", "kana", "light, after ك"), ("نَاس", "nas", "light, after ن")],
        },
    ],
    "families": ["heavy", "light", "conditionalWeight", "followsPrevious", "istila", "itbaq"],
}

MERGES["ra-tafkheem-tarqeeq"] = {
    "legend": "tafkhim",
    "keyPoints+": ["Rule of thumb: if the ra carries a vowel, look at that vowel. If it is sakin, look at the letter before it, and at what follows it for the isti'la exception."],
    "words": [
        {"label": "Heavy ra: fatha or damma", "items": [("رَبِّ", "rabbi"), ("رُزِقُوا", "ruziqu"), ("قَرَأَ", "qaraa")]},
        {"label": "Light ra: kasrah, or sakin after an original kasrah", "items": [("فِرۡعَوۡن", "firawn"), ("رِجَال", "rijal"), ("شِرۡعَة", "shirah")]},
    ],
}

MERGES["lafz-al-jalalah"] = {
    "legend": "tafkhim",
    "words": [
        {"label": "Heavy: after a fatha or a damma, or starting on the name", "items": [("ٱللَّهُ", "Allahu"), ("قَالَ ٱللَّهُ", "qala Allahu"), ("نَصۡرُ ٱللَّهِ", "nasru Allahi")]},
        {"label": "Light: after a kasrah", "items": [("بِٱللَّهِ", "billahi"), ("لِلَّهِ", "lillahi")]},
    ],
}

# ---- Nun Sakin & Tanween ------------------------------------------------------------------------

MERGES["nun-sakin-overview"] = {
    "keyPoints+": ["The rule is decided by the next letter, never by which vowel the tanween carries."],
    "related+": ["tanween-shapes"],
    "families": ["idhaar", "idghamGhunnah", "idghamBilaGhunnah", "iqlaab", "ikhfaa"],
}

MERGES["idhhar"] = {
    "words": [{"label": "Clear, before a throat letter", "items": [("مِنۡ هَادٍ", "min hadin")]}],
}

MERGES["idgham-with-ghunnah"] = {
    "legend": "idghamGhunnah",
    "words": [{"label": "Merged, with a hum", "items": [("مَن يَقُولُ", "may-yaqul")]}],
}

MERGES["idgham-without-ghunnah"] = {
    "words": [{"label": "Merged, with no hum", "items": [("مِّن رَّبِّهِمۡ", "mir-rabbihim")]}],
}

MERGES["iqlab"] = {
    "legend": "iqlaab",
    "words": [{"label": "The noon becomes a hidden mim", "items": [("سَمِيعُۢ بَصِيرٌ", "sami'um-basir")]}],
}

MERGES["ikhfa"] = {
    "legend": "ikhfaaLight",
    "words": [{"label": "Hidden, with a hum", "items": [("مِن شَرِّ", "min-sharri, nasal")]}],
}

# ---- Mim Sakin & Ghunnah --------------------------------------------------------------------------

MERGES["mim-sakin-rules"] = {
    # Meem Sakinah: its three worked ayahs, now playable, and its video.
    "keyPoints+": ["Shafawi comes from shafah, the lip: all three rules happen at the lips."],
    "examples+": [
        {"surahId": 34, "ayahNumber": 8, "word": "أَم بِهِۦ", "focus": "Ikhfa shafawi: the mim of أَم meets the ب of بِهِۦ. The lips rest together and the nose hums for two counts: am-bihi."},
        {"surahId": 16, "ayahNumber": 57, "word": "وَلَهُم مَّا", "focus": "Idgham shafawi: the mim of لَهُم merges into the doubled mim of مَّا, one mim held with its hum: lahum-maa."},
        {"surahId": 34, "ayahNumber": 45, "word": "ءَاتَيۡنَٰهُمۡ فَكَذَّبُواْ", "focus": "Idh-har shafawi: a full closure on the mim of ءَاتَيۡنَٰهُمۡ before the ف, one of the two letters this rule warns you to guard."},
    ],
    "words": [
        {"label": "Clear before any other letter", "items": [("لَكُمۡ فِيهَا", "lakum fiha"), ("عَلَيۡكُمۡ سَلَامٌ", "alaykum salamun")]},
    ],
    "videos": [
        {"title": "How to pronounce meem sakinah properly", "url": "https://www.youtube.com/watch?v=MAvDrZgWRTs", "channel": ARABIC_101},
    ],
    "families": ["ghunnah"],
}

MERGES["noon-mim-mushaddad"] = {"legend": "generalGhunnah"}
MERGES["ghunnah"] = {"legend": "generalGhunnah"}
MERGES["ghunnah-ranks"] = {"legend": "generalGhunnah"}

# ---- Madd ------------------------------------------------------------------------------------------

MERGES["madd-tabii"] = {
    "legend": "maddNatural",
    "minutes": 6,
    "body": [
        "@0", "@1", "@2",
        "The dagger alif is one of three small madd letters the mushaf writes above or below the line. The small waw (ۥ) and the small ya (ۦ) work the same way: each is a full two-count madd letter even though it is written tiny, most often after the pronoun ha, as in لَهُۥ and بِهِۦ. When one of these small letters also carries the maddah sign and a hamzah follows it, the madd becomes a separated one, which the munfasil lesson covers.",
        "@3",
        "One named case is still a natural madd: madd at-tamkin, the madd of firmness. It happens where a ya carrying a shadda and a kasra meets a madd ya, as in ٱلنَّبِيِّـۧنَ and حُيِّيتُم. It is two counts like any natural madd; the name is a reminder to say both yas firmly, without swallowing either one.",
        "@4",
    ],
    "keyPoints+": [
        "The small waw and small ya are full madd letters too: two counts.",
        "Madd tamkin, a doubled ya meeting a madd ya, is still two counts.",
    ],
    "words": [
        {"label": "Natural madd, two counts", "items": [("قَالَ", "qa-la"), ("يَقُولُ", "ya-qu-lu"), ("فِيهِ", "fi-hi"), ("نُور", "nur")]},
        {"label": "Madd tamkin: both yas said firmly", "items": [("ٱلنَّبِيِّـۧنَ", "an-nabiy-yiin"), ("حُيِّيتُم", "huy-yi-tum")]},
    ],
}

MERGES["madd-muttasil"] = {
    "legend": "maddConnected",
    "body": [
        "@0",
        "A dagger alif can carry a muttasil as well. When the small alif and the hamzah sit inside one true word, as in أُوْلَٰٓئِكَ, ٱلۡمَلَٰٓئِكَةُ and إِسۡرَٰٓءِيلَ, it is an ordinary joined madd of 4 or 5 counts. The look-alike to set apart is a joined يَٰٓ or هَٰٓ, where the hamzah really begins a separate word; that case belongs to the next lesson.",
        "@1", "@2", "@3", "@4",
    ],
    "words": [
        {"label": "Madd letter, then a hamzah in the same word", "items": [("جَآءَ", "jaaa"), ("ٱلسَّمَآءِ", "as-samaaa"), ("سُوٓءَ", "suuu")]},
        {"label": "True muttasil on a dagger alif", "items": [("أُوْلَٰٓئِكَ", "ula-aa-ika"), ("مَلَٰٓئِكَةِ", "mala-aa-ikah")]},
    ],
}

MERGES["madd-munfasil"] = {
    # Madd Munfasil Hukmi: the joined يا and ها particles, and the eighteen words.
    "legend": "maddSeparated",
    "minutes": 8,
    "body": [
        "@0", "@1",
        "One kind of munfasil hides inside a single written word: munfasil hukmi, the separated madd by ruling. In يَٰٓأَيُّهَا the madd letter is the tail of the vocative يَا, O, and the hamzah begins the word after it, أَيُّهَا, even though the script joins the two. The demonstrative هَا works the same way: هَٰٓأَنتُمۡ is هَا plus أَنتُمۡ, here you are. It looks like a joined madd and is recited as a separated one, at your munfasil length.",
        "To spot it, look for a small madd letter (the dagger alif, a small waw or a small ya) carrying the maddah sign, followed at once by a hamzah in the same written word, where that small letter is the end of a joined يَا or هَا. Only that sequence is hukmi. The word هَٰٓؤُلَآءِ holds both kinds at once: هَٰٓؤُ is munfasil hukmi, from the joined هَا, while لَآءِ is a true muttasil, a real alif and a hamzah inside one word. Every other madd in such a word follows the ordinary rules.",
        "@2", "@3", "@4",
    ],
    "keyPoints+": ["Munfasil hukmi: a joined يَٰٓ or هَٰٓ before a hamzah is still two words, read at your munfasil length."],
    "letterSets+": [
        {
            "label": "Every munfasil hukmi word",
            "letters": ["هَٰٓأَنتُمۡ", "هَٰٓؤُلَآءِ", "أَهَٰٓؤُلَآءِ", "وَهَٰٓؤُلَآءِ", "يَٰٓـَٔادَمُ", "وَيَٰٓـَٔادَمُ", "يَٰٓأَبَانَا", "يَٰٓأَبَتِ", "يَٰٓإِبۡرَٰهِيمُ", "يَٰٓإِبۡلِيسُ", "يَٰٓأُخۡتَ", "يَٰٓأَرۡضُ", "يَٰٓأَسَفَىٰ", "يَٰٓأَهۡلَ", "يَٰٓأُوْلِي", "يَٰٓأَيَّتُهَا", "يَٰٓأَيُّهَ", "يَٰٓأَيُّهَا"],
            "note": "Counting spelling variants such as يَٰٓأَبَانَآ and the forms that carry pause marks, 21 written words in the Hafs mushaf.",
        },
    ],
    "quiz+": [
        {
            "prompt": "Why is يَٰٓأَيُّهَا read as a separated madd although it is written as one word?",
            "choices": ["Because it is at the start of an ayah", "Because its madd letter ends the particle يَا and the hamzah begins the next word", "Because a dagger alif is never lengthened", "Because it is always read at two counts"],
            "answer": 1,
            "explain": "The script joins the vocative يَا to the word after it, but in meaning they are two words. The madd letter ends one and the hamzah begins the other, which makes it munfasil hukmi, read at your munfasil length.",
        },
    ],
    "words": [
        {"label": "Madd letter ending one word, hamzah beginning the next", "items": [("فِيٓ أَنفُسِكُمۡ", "fi an-fu-si-kum"), ("قَالُوٓاْ إِنَّا", "qalu in-na"), ("إِنَّآ أَعۡطَيۡنَٰكَ", "in-naa a'-tay-naa-ka")]},
        {"label": "Joined in writing, separated in ruling", "items": [("يَٰٓأَيُّهَا", "ya + ayyuha", "O you"), ("هَٰٓأَنتُمۡ", "ha + antum", "here you are"), ("يَٰٓإِبۡرَٰهِيمُ", "ya + Ibrahim", "O Abraham"), ("يَٰٓـَٔادَمُ", "ya + Adam", "O Adam")]},
    ],
}

MERGES["madd-badal"] = {
    "legend": "maddNatural",
    "words": [{"label": "Hamzah first, two counts", "items": [("ءَامَنُواْ", "aa-manu"), ("ءَادَمَ", "aa-dama")]}],
}

MERGES["madd-iwad"] = {
    "keyPoints+": ["It is not madd arid: the alif stands in for the tanween's noon, it is not a madd letter meeting a sukoon."],
    "words": [{"label": "Stopped on, the tanween becomes an alif", "items": [("عَلِيمًا", "stop: a-li-maa"), ("غَفُورًا", "stop: gha-fu-raa")]}],
}

MERGES["madd-leen"] = {
    # The correction: شَيۡءٌ is madd leen in Hafs, not muttasil.
    "legend": "maddSukoon",
    "body": [
        "@0", "@1", "@2",
        "A hamzah after a leen letter changes nothing in Hafs. شَيۡءٌ read on has no madd at all, however it looks; stopped on, it is a madd leen like any other, at 2, 4 or 6 counts. Riwayat such as Warsh lengthen it even while reading on, which is where the habit of stretching it comes from, but that is not the reading of Hafs.",
        "@3", "@4",
    ],
    "keyPoints+": ["Madd leen is never held longer than your madd arid."],
    "mistakes+": [
        {
            "wrong": "Stretching the ya of شَيۡءٌ while reading on, as if it were a joined madd.",
            "right": "In Hafs it is a leen letter: no length while reading on, and 2, 4 or 6 counts only at a stop.",
            "why": "The hamzah after it does not make a muttasil, because a leen letter is not a madd letter. The long wasl reading belongs to Warsh, not Hafs.",
        },
    ],
    "words": [{"label": "Leen letters, lengthened only at a stop", "items": [("خَوۡف", "khawf"), ("بَيۡت", "bayt"), ("قُرَيۡش", "quraysh"), ("شَيۡءٌ", "shay'")]}],
}

MERGES["madd-arid"] = {
    "legend": "maddSukoon",
    "keyPoints+": ["The reader's colour legend calls madd arid and madd leen together Ending Madd."],
    "words": [{"label": "Stopped on, 2, 4 or 6 counts", "items": [("ٱلۡعَٰلَمِينَ", "stop: a temporary sukoon on the ن"), ("ٱلرَّحِيمِ", "stop: ٱلرَّحِيمۡ"), ("نَسۡتَعِينُ", "stop: a temporary sukoon on the ن")]}],
}

MERGES["madd-lazim"] = {
    "legend": "maddNecessary",
    "words": [
        {"label": "In the letter names (harfi)", "items": [("الٓمٓ", "Alif, no madd; Laaaaaam, 6; Miiiiiim, 6"), ("كٓهيعٓصٓ", "Kaaaaaaf, 6; Haa, 2; Yaa, 2; 'Ayyyn, 4 or 6; Saaaaaad, 6"), ("حمٓ", "Haa, 2; Miiiiiim, 6")]},
        {"label": "In a word (kalimi)", "items": [("ٱلضَّآلِّينَ", "ad-daaallin"), ("ٱلطَّآمَّةُ", "at-taaammah")]},
    ],
}

MERGES["madd-silah"] = {
    "legend": "maddNaturalMiniature",
    "words": [{"label": "The pronoun ha, joined", "items": [("إِنَّهُۥ كَانَ", "sughra: in-na-hu"), ("بِهِۦٓ أَحَدٗا", "kubra: bi-hii, before a hamzah")]}],
}

MERGES["mudood-chart"] = {
    "keyPoints+": [
        "Madd is measured, not emotional. Never stretch because it sounds nice.",
        "Consistency matters more than length: four everywhere is better than a random two to six.",
        "Never break a madd in the middle: one smooth airflow from start to finish.",
    ],
    "table": {"rows": ["@0", ["مدّ التمكين", "A doubled ya meeting a madd ya", "2"], "@1", "@2", "@3", "@4", "@5", "@6", "@7", "@8", "@9", "@10"]},
    "families": ["maddLetters", "leen", "openersSix", "openersTwo"],
}

# ---- Letter Rules -------------------------------------------------------------------------------

MERGES["qalqalah"] = {
    "legend": "qalqalah",
    "body": [
        "@0", "@1", "@2",
        "Qalqalah is a sound, not a vowel, and not silence either. Think of it as releasing the letter, not opening the mouth: a slight echo, natural and effortless, never exaggerated. It exists because Arabic does not let these five letters die silently. Without it they would sound cut off and unclear, and the bounce preserves their clarity, their identity and the flow of the speech.",
        "@3", "@4", "@5",
    ],
    "keyPoints+": ["If the bounce sounds like an a, it is wrong. If it disappears, it is also wrong."],
    "mistakes+": [
        {
            "wrong": "Letting a sakin qalqalah letter die with no release, so the letter is swallowed.",
            "right": "Release it with a slight bounce: ya(j)-'al, not yaj'al with a silent ج.",
            "why": "These five letters cannot be heard at all when they carry sukoon, which is the whole reason for the rule. A missing bounce loses the letter.",
        },
        {
            "wrong": "Exaggerating the bounce into a loud pop or a jolt of the jaw.",
            "right": "A slight, natural echo. Release the letter; do not throw it.",
            "why": "Qalqalah is effortless by definition. An exaggerated bounce draws attention to itself and starts to sound like an extra syllable.",
        },
    ],
    "words": [
        {"label": "A sakin qalqalah letter, bounced", "items": [("أَحَدۡ", "aha(d)"), ("يَجۡعَل", "ya(j)-'al"), ("أَجۡر", "a(j)r"), ("يَقۡطَع", "ya(q)ta'"), ("يَبۡتَغُون", "ya(b)taghun")]},
    ],
    "families": ["shiddah", "jahr"],
}

MERGES["hamzat-al-wasl"] = {
    "examples+": [
        {"surahId": 2, "ayahNumber": 2, "word": "ذَٰلِكَ ٱلۡكِتَٰبُ", "focus": "Joined, the hamza of ٱلۡكِتَٰبُ is not heard at all: dhalikal-kitab. Begin on the word, and it returns with a fatha: al-kitab."},
        {"surahId": 19, "ayahNumber": 7, "word": "بِغُلَٰمٍ ٱسۡمُهُۥ", "focus": "A tanween meets a hamzat al-wasl, so its noon takes a kasra to carry you over: bighulaaminismuhu."},
    ],
    "words": [
        {"label": "With the article: start with a fatha", "items": [("ٱلۡكِتَٰبُ", "al-kitab"), ("ٱلرَّحۡمَٰنُ", "ar-rahman"), ("ٱلصَّمَدُ", "as-samad"), ("ٱللَّهُ", "Allah")]},
        {"label": "The nouns: start with a kasra", "items": [("ٱسۡم", "ism"), ("ٱبۡن", "ibn"), ("ٱبۡنَيۡ", "ibnay")]},
        {"label": "A verb with an original damma: start with a damma", "items": [("ٱتۡلُ", "utlu", "joined: watlu")]},
        {"label": "A borrowed damma: still start with a kasra", "items": [("ٱمۡشُواْ", "imshu"), ("ٱقۡضُوٓاْ", "iqdu"), ("ٱبۡنُواْ", "ibnu"), ("ٱئۡتُواْ", "iitu", "the sakin hamza becomes a long i"), ("ٱئۡتُونِي", "iituni", "the same long i")]},
    ],
    "videos": [
        {"title": "How to pronounce words with no tashkeel", "url": "https://www.youtube.com/shorts/SpA7EtX3jMA", "channel": ARABIC_101},
        {"title": "Hamzat al-wasl and hamzat al-qat'", "url": "https://www.youtube.com/shorts/xNn-pR4eoHM", "channel": ARABIC_101},
        {"title": "Alif and hamzah", "url": "https://www.youtube.com/shorts/79Ku0wSKf9Q", "channel": ARABIC_101},
    ],
}

MERGES["lam-shamsiyyah-qamariyyah"] = {
    # Shams and Qamar: Al. Abu's worked example of the merge.
    "minutes": 6,
    "body": [
        "@0", "@1",
        "The classic moon list opens with an alif. It is really the hamza, as in ٱلۡأَرۡض: no word begins with a bare alif, which is why the moon set above starts with ء.",
        "@2", "@3",
        "Two things keep the rule in its place. It is idgham of the lam, not deletion: the lam is absorbed into the letter after it, and the shadda on that letter is where it went. And it applies only to the lam of the definite article ٱلۡ. Every other lam in the language is read clear, which is the subject of the next lesson.",
        "@4",
    ],
    "keyPoints+": [
        "Only the lam of the definite article ٱلۡ follows this rule, not every lam.",
        "It is idgham, not deletion: the lam is absorbed into the doubled letter.",
    ],
    "mistakes": [
        {"@": 0, "wrong": "Saying the lam before a sun letter, al-shams, or leaving a trace of it: al-shshams."},
        "@1",
        {
            "wrong": "Dropping a moon lam, so ٱلۡقَمَر comes out as a-qamar.",
            "right": "Say the lam: al-qamar. A sukoon on the lam means it is read.",
            "why": "Only the fourteen sun letters absorb the lam. Treating a moon letter as a sun letter deletes a letter the word keeps.",
        },
        "@2",
    ],
    "words": [
        {"label": "Moon letters: the lam is read", "items": [("ٱلۡقَمَر", "al-qamar"), ("ٱلۡكِتَٰب", "al-kitab"), ("ٱلۡحَقّ", "al-haqq"), ("ٱلۡغَفُور", "al-ghafur"), ("ٱلۡيَوۡم", "al-yawm")]},
        {"label": "Sun letters: the lam merges", "items": [("ٱلشَّمۡس", "ash-shams"), ("ٱلنَّاس", "an-nas"), ("ٱلرَّحۡمَٰن", "ar-rahman"), ("ٱلصِّرَٰط", "as-sirat"), ("ٱلتَّوۡبَة", "at-tawbah")]},
    ],
}

# ---- Reading the Page ---------------------------------------------------------------------------

MERGES["reading-the-script"] = {
    # Tajweed Hints in the Mushaf: letters without a sukoon, and the lam of al-.
    "body": [
        "@0", "@1", "@2",
        "The same instinct works beyond the noon. If a letter has no sukoon and is not a madd letter (ا و ي), the sound does not simply pass: the letter is being held, merged, hidden or converted, and some rule applies. That is why a bare مَن before يَقُولُ merges into it, while a مِنۡ carrying its sukoon is simply said.",
        "@3", "@4", "@5", "@6",
    ],
    "keyPoints+": ["Any letter with no sukoon that is not a madd letter: slow down, a rule is at work."],
    "words": [
        {"label": "Sukoon or no sukoon", "items": [("مِنۡ", "min", "sukoon on the noon: say it clearly"), ("مَن يَقُولُ", "may-yaqul", "no sukoon: merge (idghaam)"), ("عَلِيمٌ", "'alimun", "tanween, no visible sukoon: apply the rule")]},
        {"label": "Sukoon on the lam: read it", "items": [("ٱلۡقَمَر", "al-qamar"), ("ٱلۡكِتَٰب", "al-kitab"), ("ٱلۡهُدَىٰ", "al-huda")]},
        {"label": "No sukoon on the lam: it is not read", "items": [("ٱلشَّمۡس", "ash-shams"), ("ٱلنَّاس", "an-nas"), ("ٱلرَّحۡمَٰن", "ar-rahman")]},
    ],
    "related+": ["sukoon"],
}

MERGES["tanween-shapes"] = {
    "examples+": [
        {"surahId": 2, "ayahNumber": 143, "word": "أُمَّةٗ وَسَطٗا", "focus": "The slanted fathatayn meets a و, so the hidden noon merges into it with a hum: ummataw-wasatan."},
    ],
    "words": [
        {"label": "Stacked: the hidden noon is said clearly", "items": [("بًا", "ban"), ("بٌ", "bun"), ("بٍ", "bin"), ("قُرۡءَانًا عَرَبِيًّا", "quraanan arabiyyan")]},
        {"label": "Staggered: do not pronounce the noon normally", "items": [("أُمَّةٞ قَدۡ", "ummatun(g) qad", "hidden, with a hum"), ("صِرَٰطٖ مُّسۡتَقِيمٖ", "siraatim-mustaqeem", "merged into the mim"), ("أُمَّةٗ وَسَطٗا", "ummataw-wasatan", "merged into the waw, with a hum")]},
    ],
}

# ---- Stopping & Starting ------------------------------------------------------------------------

MERGES["waqf-types"] = {
    # Waqf: why it matters, the dangerous stop, and the stop signs.
    "minutes": 8,
    "body": [
        "@0",
        "Waqf is not random breathing. It is a deliberate pause guided by the mushaf and by the meaning of the ayah. Stopping in the wrong place can change the meaning of an ayah, produce a theological error, break its grammar, or mislead whoever is listening; stopping in the right place preserves the meaning, keeps the recitation clear, reflects understanding, and shows respect for the words of Allah. That is why Ali ibn Abi Talib (may Allah be pleased with him) defined tartil as the tajweed of the letters and knowledge of the places of stopping.",
        "@1", "@2", "@3",
        "The classic warning is 4:43. Stop after لَا تَقۡرَبُواْ ٱلصَّلَوٰةَ and you have said: do not approach prayer. The ayah goes on, وَأَنتُمۡ سُكَٰرَىٰ, while you are intoxicated, and only with that is the command what Allah said. A reader who runs out of breath there goes back and takes the phrase again.",
        "@4", "@5", "@6",
    ],
    "keyPoints+": [
        "Waqf is about meaning, not breath: stop where the meaning stops, not where the lungs give up.",
        "Tam is the best place to stop, kafi is a fine one, hasan is for when your breath forces it, and qabih is never chosen.",
        "A reader trained in waqf reads with understanding, not just sound: the signs, the ayah ends and the sense of the sentence all say where to stop.",
    ],
    "examples+": [
        {"surahId": 4, "ayahNumber": 43, "word": "لَا تَقۡرَبُواْ ٱلصَّلَوٰةَ", "focus": "A stop after ٱلصَّلَوٰةَ says do not approach prayer. The ayah continues: while you are intoxicated. That stop is qabih."},
    ],
    "extras": ["waqfSigns"],
}

MERGES["waqf-changes"] = {
    "body": [
        "@0", "@1", "@2",
        "Long vowels do not shorten at a stop. A word ending in a madd letter, like فِي, keeps it exactly as it is, and in يَقُولُ only the final damma goes: the long u before the ل stays, yaqool.",
        "@3", "@4", "@5",
    ],
    "words": [
        {"label": "The last vowel drops", "items": [("ٱلۡعَٰلَمِينَ  ->  ٱلۡعَٰلَمِينۡ", "al-'alamina -> al-'alamin"), ("نَسۡتَعِينُ  ->  نَسۡتَعِينۡ", "nasta'inu -> nasta'in"), ("ٱلۡكِتَٰبِ  ->  ٱلۡكِتَٰبۡ", "al-kitabi -> al-kitab")]},
        {"label": "Tanween at a stop", "items": [("بَصِيرٌ  ->  بَصِيرۡ", "dammatayn: dropped"), ("عَلِيمٍ  ->  عَلِيمۡ", "kasratayn: dropped"), ("كِتَٰبًا  ->  كِتَٰبَا", "fathatayn and alif: the alif stays"), ("رَحۡمَةً  ->  رَحۡمَهۡ", "fathatayn on ة: a sakin ha, no alif")]},
        {"label": "Ta marbutah becomes a ha", "items": [("رَحۡمَةٌ  ->  رَحۡمَهۡ", "rahmah"), ("جَنَّةٍ  ->  جَنَّهۡ", "jannah")]},
        {"label": "Long vowels stay", "items": [("فِي  ->  فِي", "unchanged"), ("يَقُولُ  ->  يَقُولۡ", "the final vowel drops, the long u stays")]},
    ],
}
