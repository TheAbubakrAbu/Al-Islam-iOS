# Translating Al-Islam's interface

Al-Islam is an iOS app for Muslims: the Quran (reader, mushaf pages, recitation, tajweed colours, qiraat and
riwayat), Hadith collections, prayer times and the adhan, a prayer tracker, and an Islam tab with learning
screens (the Arabic alphabet, a 58-lesson tajweed course, duas, the 99 Names, tips). Its interface already
ships in English, Arabic, Urdu, Indonesian, Malay and Turkish. You are translating it into ONE more language,
named in your task (French `fr`, Bangla `bn` or Russian `ru`), as a professional native translator would for
Apple's App Store: natural, idiomatic, consistent, and faithful to Sunni Islamic terminology as that
language's Muslims write it.

## Input

A JSON array. Each item:

- `key`: the catalog key. Usually it IS the English text.
- `english` (rare): present when the key is a dotted id (`weather.clear`, `surah.meaning.2`); translate THIS
  text, but the output key is still `key`.
- `files`: the Swift files that show it, the context for a short key's sense. "(data shown via
  .localizedDisplay)" means app data (mostly the tajweed course, Arabic grammar, reference tables). For a short
  data key (a quiz option, a table cell) whose sense or gender is unclear, search the data itself:
  /Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Resources/Data/Quran/TajweedLessons.json.xz (xz-compressed
  JSON; ) and the other files under Resources/Data.
- `plural`: the key holds exactly one integer (`%lld`). See Plurals.
- `arabic` (short keys only): the app's Arabic translation, the reference for which SENSE is meant
  ("Light" a theme vs a light letter; "Merge" a backup choice vs idgham). Use it to disambiguate, then
  translate the ENGLISH into your language. Never copy the Arabic.

## Output

One JSON object `{key: translation}` covering EVERY item, keys copied byte for byte from `key` (escape
quotes properly; keep curly quotes, non-breaking spaces and odd characters exactly as in the key). Write it to
the output path in your task. Before validating, put every Arabic run of each key back into your value byte
for byte (a writing tool may have recomposed ا + ٓ into آ): a short script that replaces each Arabic run that
matches the key's after Unicode NFC normalisation with the key's own bytes. If the file would be very large you may write it in parts (`.part1.json`,
`.part2.json`, ...): every key in exactly one part. Write the files with a python3 script (json.dump with
ensure_ascii=False) rather than by hand if you can: some writing tools strip trailing spaces and recompose
Arabic letters, and the validator rejects both.

Then validate every file you wrote, from the repository root:

    cd /Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS
    ./Scripts/localize_catalog.py validate --lang <code> <your file(s)>

It writes nothing. Fix every REJECTED line and run it again until it reports `0 rejected`. Also check that
your output has exactly as many keys as the input (a short python3 one-liner is fine). NEVER run `merge`,
`sync` or anything that writes; never edit anything in the repository. Work only in your output files.

## Hard rules (the validator enforces most)

1. **Placeholders**: keep every `%@`, `%lld`, `%d`, `%.1f`, `%1$@`, `%2$lld` with exactly the same set of
   conversions. To reorder arguments, switch ALL of them to positional form (`%2$@ ... %1$lld`). `%%` is a
   literal percent: keep `%%`. Keep `${applicationName}`, `${surah}`, `${prayer}` exactly.
2. **No em dash (U+2014) anywhere**, in any form, and no en dash or spaced hyphen standing in for one. Russian:
   where grammar would put a dash between subject and predicate (the dash before "это"), rephrase ("X означает Y",
   "X называют Y", "X: Y"). Use a colon, a comma, parentheses, or two sentences. An en
   dash (–) in a range (1–7) and a hyphen are fine. Do not add a spaced hyphen " - " as a dash either,
   except where the English key has one (a "Name - Arabic" label).
3. **No English left**: translate every word, including in long paragraphs. A published English title ("The
   Clear Quran", "Saheeh International", "The Sealed Nectar") stays as a name. If a whole key legitimately
   stays identical and the validator flags it, list it in your final report (it is fine to leave those few).
   Names of people, books and riwayat (a reciter, a scholar, Sahih al-Bukhari, Hafs, Warsh, Ibn Kathir):
   - French: as written in the key.
   - Bangla and Russian: in your script, the way your language's Muslims usually spell them (Russian
     "Сахих аль-Бухари", "Хафс"; Bangla "সহীহ বুখারী", "হাফস"), the same spelling every time. A name the
     labels file fixes (see the end) takes exactly that spelling.
4. **Arabic stays Arabic**: copy any Arabic-script text in a key (words, letters, ayahs between ﴿ ﴾, ﷺ,
   harakat) exactly, never retyped or "corrected". Never write Quranic text from memory. Transliterated
   Arabic examples in a lesson (kataba, katabtu, -tu) stay as written in Latin letters: they show the sounds.
   Sound examples ("Like the b in “book”"): you may give a word of your language when it has exactly the
   same sound (« bateau », «бок»); otherwise keep the English word, marked as English ("le th de l’anglais
   « this »", "как английское th в «three»"). A STATEMENT about English ("No English equivalent", "English
   has none of them", "an English word beginning with a") stays about English: never rewrite it as a claim
   about your language, which may well have the sound (French r, Russian х).
5. **Digits**: Western digits 0-9 only, in every language (Bangla too: the app turns them into the locale's
   digits where the reader's settings ask for that). Never Arabic-Indic or Bengali digits unless the key has them.
6. **Names that stay**: Al-Islam, Al-Adhan, Al-Quran (the app names, always Latin, never translated),
   Apple, iPhone, iPad, Mac, Apple Watch, iCloud, Siri, CarPlay, AirPlay, Apple Intelligence, Dynamic Island,
   Quran.com, Tilawa, GitHub, KFGQPC, Uthmani, IndoPak, PDF, GPS, and every website and font name. Apple's
   own features take Apple's name for them in your language (glossary).
7. **Surah names and Arabic letter names**: keep the app's own Latin transliteration exactly as the key
   writes it (Al-Fatihah, Al-Kahf, Yaseen; Alif, Baa, Taa, Thaa, Jeem, Haa, Khaa, ...) in every language,
   inside your sentences too ("сура Al-Kahf", "সূরা Al-Kahf", "la sourate Al-Kahf"), because the surah list
   and the letter cards beside the text show exactly those spellings, and a reader must be able to find them
   there. Russian and Bangla only: a letter named as a word inside running lesson prose ("the noon", "a sakin
   meem", "the heavy letters ص ض ط ظ") is written in your script from the glossary's letter list (нун, мим;
   নূন, মীম), with the Arabic letter beside it when the key gives it; a letter card's or list's own title stays
   as the key writes it. Tajweed rule names: see your glossary.
8. **Islamic honorifics** stay: ﷺ after the Prophet's name, and translate "(peace be upon him)",
   "may Allah be pleased with him" with your language's standard formula (glossary). "Allah" is always
   Allah (Аллах, আল্লাহ).

## Style

- Match the English register: buttons and titles short; sentences as sentences.
- Capitals: French and Russian write titles and buttons in SENTENCE case, as Apple's French and Russian do
  ("Ajouter une note", "Добавить заметку"), never English Title Case; proper names keep their capitals.
  A key in ALL CAPS (a section header) is ALL CAPS in French and Russian too. Bangla has no capitals: write
  those normally.
- Address the reader as your glossary says (polite, warm, never stiff legalese).
- Punctuation natural for your language (glossary: French spacing, Russian «» quotes, the Bangla danda ।);
  keep a trailing colon, ellipsis or question mark when the English has one; do not add a full stop the
  English does not have.
- Consistency matters more than variety: the same English term gets the same translation everywhere, and a
  feature name quoted in a sentence ("Turn on Hide Arabic Dots") is translated exactly as that label is.
  When you meet a label that you translated earlier in your batch, reuse your wording.
- Long lesson paragraphs (tajweed, Arabic grammar): translate fully and accurately, as a teacher writing in
  your language would. Keep technical Arabic terms (sukoon, shaddah, fatha, kasra, damma, tanween, madd,
  ghunnah, qalqalah, idgham, ikhfa, iqlab, izhar, waqf, ...) in your language's usual form from the glossary.
- The content follows the majority Sunni position (Ahl as-Sunnah); keep the meaning exactly, add nothing,
  soften nothing, explain nothing that the English does not explain.

## Plurals

An item with `"plural": true` holds one integer. Answer with a plain string when no word agrees with the
number, or an object of plural forms when one does:

- **French**: {"one": ..., "other": ...} where a noun or participle agrees ("one" is used for 0 and 1:
  "%lld verset" / "%lld versets"). The validator rejects a plain string that puts the number before a plural
  noun ("%lld versets"). Omit "many" (it is only for round millions).
- **Russian**: {"one": ..., "few": ..., "many": ..., "other": ...} for every count beside a noun:
  one = 1, 21, 31 ("%lld аят"), few = 2-4, 22-24 ("%lld аята"), many = 0, 5-20, 25-30 ("%lld аятов"),
  other = fractions ("%lld аята"). All four are required. The validator rejects a plain string with the
  number before a Cyrillic word. A plain string is right only when nothing agrees ("Аяты: %lld", "%lld%%").
- **Bangla**: nouns do not change after a number: give a plain string ("%lldটি আয়াত" or "%lld আয়াত").
- No form may write the number as a word (a "one" form covers 21 in Russian and 0 in French).

## When done

Your final message: the output file path(s), the number of keys written, the validator's last line, the
keys you left identical on purpose, and any items you were genuinely unsure of (key + your choice + why),
at most 15. Nothing else.

## The app's labels are fixed (interface batches 009-019)

`<scratchpad>/l10n/<code>/labels.json` holds the agreed translation of 331 of the app's own labels: feature
names, settings rows, screen titles and buttons that other strings name ("Turn on Simple Mode", "Open Quran
Settings", "tap “Add Note”"). It is BINDING:
- An item whose key IS one of those labels gets exactly that translation.
- A sentence that names or quotes one uses exactly that wording (Russian may inflect the label's noun for
  case where grammar requires it and it is not in quotes; Bangla may add a case ending after it; otherwise
  nothing changes).
- Before you finish, search your output: for each label key that occurs inside one of your English keys,
  check that its agreed translation occurs in your value.
Labels not in the file: translate them as the glossary and the brief say, and quote them in sentences
exactly as you translated the label itself in your batch.
