# Notes for the fr/bn/ru review pass (collected from batch reports)
## fr
- 004 and 006 localized ENGLISH sound comparisons into French ("Pas d’équivalent en français", king -> « kilo », cup -> « patte »; 006 items about "an English word beginning with a" -> "un mot français", "English has none of them" -> "le français n’en possède aucun"). Restore: the comparison stays about English (brief rule 4, added after those batches).
- 004/006 ran before fr/labels.json existed: Nagging Mode "mode Rappel insistant" (label: Mode relance), Arabic Beginner Mode, Play Custom Range « Lire une plage personnalisée » (label: Écouter une plage personnalisée), Islamic Journal, Quran Settings: align with labels.json.
- Letter names noon/nun, mim/meem mixed with rule names "noun sakina" (glossary): fine per brief, but no paragraph should spell the same letter two ways within itself.
- idh-har kept in 006 vs izhar elsewhere: unify on izhar in prose.
## ru
- 005 wrote letter names in prose in Cyrillic (нун, лям, ра, вав, йа): the brief now says so for ru/bn with a fixed list (GLOSSARY_ru); batches 001-004 may have kept Latin: unify prose letter names on the glossary list.
- 005: Highlight Themes "Выделение тем", Test Mode "Режим проверки" chosen before labels: align with labels.json.
- 005 item 303 (shiddah/jahr reversed) translated as written: pre-existing English error, leave.
- fr003, ru003 used native example words for "Like the X in “word”" (allowed now); fr004/fr006 rewrote STATEMENTS about English into French ones: revert those statements only.
- ru002 wrote the developer's name in Cyrillic (Абубакр Эльмаллах) in the two "Created by" keys; ru002 fixed the mojibake Ø· / Øª to ط / ت (good).
- ru: "Explore › Word of the Day" (ru002 "Обзор › Слово дня"), "Hadith Settings › On the Hadith Tab › Narrators" (ru003): align with labels.json.
- ru001 kept LATIN letter names in prose ("Буква ra с сукуном"); ru002-005 used Cyrillic: convert ru001 prose letter names to the glossary list (and fix the gender agreement it improvised).
- ru001/ru004 chose labels before labels.json (Need Help Praying?, Nagging Mode, Arabic Beginner Mode, Play Custom Range, Prayer Settings, At a Glance, Prayer Tracker, Optional Prayers): align.
- ru001 spellings: silah сыла (ru003 wrote силя): unify; "Хафс по пути аш-Шатыбийи / ат-Таййибы".
- fr001 labels pre-labels: Nagging Mode "Mode rappels insistants" (label Mode relance), Articulation Points; align.
- ru006 ALSO kept Latin letter names in prose (noon, lam, hamzah, «соединительная hamzah», «кинжальный alif»): convert like ru001. dagger alif: unify on «малый алиф». sila: ru006 сыля, ru001 сыла, ru003 силя: pick one (сыля).
## bn
- bn004 items 134-138 rewrote "No English equivalent" as "বাংলায় এর সমতুল্য ধ্বনি নেই": revert the statement to English ("ইংরেজিতে এর সমতুল্য ধ্বনি নেই"); native example words for identical sounds may stay.
- bn004 labels pre-labels (Play Custom Range কাস্টম রেঞ্জ চালান vs label কাস্টম পরিসর..., Prayer Tracker, At a Glance...): align with labels.json.
- bn004: dagger alif খাড়া যবর; madd names "মাদ + name" vs labels "মাদ্দে মুত্তাসিল": labels win (মাদ্দে ...) in prose too.
- fr: unify leen (lîn 11 / lin 7 / leen 18 -> lin), hamzah -> hamza, doublé/redoublé -> redoublé, sortie -> point de sortie where it means makhraj. fr005 provisional labels (Sky Fills the Screen « Ciel en plein écran », Highlight Themes « Surlignage des thèmes », Test Mode, Reset All Settings): align.
- bn001 kept LATIN letter names in prose ("তাশদীদযুক্ত noon"): convert to the glossary's Bangla letter list, like the later batches.
- bn001 provisional labels (Need Help Praying?/Reading?, Nagging Mode, Arabic Beginner Mode, Articulation Points): align. basmalah বিসমিল্লাহ.
- bn002 ALSO Latin letter names in prose: convert (bn001, bn002). bn002 'Explore' অন্বেষণ; tanween দুই যবর/দুই পেশ/দুই যের; developer's name আবুবকর এলমাল্লাহ.
- fr: hamzah/hamza both used (my early prompts said 'hamzah de liaison'): unify on hamza (« hamza de liaison »). voiced: voisé vs sonore: unify on voisé.
- fr009: 'Open Prayer Times' « Ouvrir Horaires de prière » / « Ouvrir Qibla » (copied the Ouvrir Réglages pattern): make natural (« Ouvrir les horaires de prière », « Ouvrir la qibla ») unless a label binds it.
- bn009: widget prayer abbreviations (FJR, SHQ...) became full names; SHQ সূর্যোদয় is long for a narrow widget: check widths in the simulator / shorten. fr008: shadeed/majhoor (fr006) vs shadid (fr001): unify on shadid, majhour? pick one.
- ru: Шатибия spelling (по пути аш-Шатыбийи vs по тарику аш-Шатибии), муттасыль/муттасиль: unify per GLOSSARY_ru 'Fixed' section. due: права vs должное.
- ru009: widget abbreviations ФДЖ/ВСХ/ЗХР/АСР/МГБ/ИША/ДХА/ДЖМ coined: check in widgets. Next: «Далее:» for prayers.
- bn004 partly Latin letter names + 'মাদ আরিদ' forms: convert to মাদ্দে ... and Bangla letter names.
- bn005: hum গুঞ্জন (others গুন্নাহ), bounce ঝাঁকুনি (others ঝাঁকি): unify per GLOSSARY_bn Fixed section.
- fr011 'Tashkeel par défaut' vs fr012 'tachkil': unify on tachkil (« Tachkil par défaut »).
- ru: Ибн Кясир (label) vs Ибн Касир in 002/003/006: use the label. ru014 'Narrated by %@' = «Передатчики: %@», '%@ an %@' = «%@ · имам %@».
- fr: tier palier (fr013) vs niveau (fr012, glossary): unify on niveau (glossary) unless it clashes with Find My Level; Sound-Alikes page name and Quran Words name: match fr012's titles.
- bn013: Sound-Alikes “সদৃশ ধ্বনি”, Quran Words “কুরআনের শব্দ”, iCloud Backup: match the screens' own titles (bn012 'সদৃশ ধ্বনির হরফ'). tier স্তর (bn013) vs ধাপ (bn012): unify (ধাপ, since level=স্তর).
- ru019 quoted tone names «Эхо», «Такбир», «Перезвон», «Звонок», «Тревога», iCloud Backup page «Резервная копия iCloud», Replace/Merge, Custom method «Другой»: align with batch 017's labels (all languages: tone names in tips/credits must match the sound picker).
- fr019: labels owned by 013-018 guessed (Reveal as It's Recited « Révéler au fil de la récitation », Mark as Revised, Play from Beginning « Écouter depuis le début », Speed « Vitesse », tones « Écho », « Takbir », « Carillon », « Sonnerie », « Alarme »): align. Check the French host of 'Ask AI answers from %@' does not write « de %@ » (the argument starts « le Coran »: « de le Coran »).
