# Qiraat Sources Audit (2026-09-12)

What the three qiraat sources hold, how they were checked against each other, and what came of it.
The three: this app's own corpus, Tilawa's qiraat work (Jamil Hammoudeh, shared both ways), and the
Quran.com qiraat matrix (Quran Foundation), kept at `Resources/JSONs-Deprecated/Qiraat/quran-com-qiraat.json.xz`.

## 1. Who has what

| Layer | Al-Islam | Tilawa | Quran.com matrix |
|---|---|---|---|
| Riwayah texts | 20: Hafs + 7 KFGQPC-verified + 12 beta (Islamweb extraction) | 8: Hafs + 5 official KFGQPC v2.x + Bazzi/Qunbul copied from this app; the 12 beta only feed its examples | none (word forms only) |
| Printed mushafs | 20 facsimiles, per-riwayah page and line tables | KFGQPC page and line data for its 5 | none |
| Who reads what | the matrix pack (1,409 ayahs, 1,634 junctures, 3,503 readings) | none | the source of it |
| Meanings and notes | from the matrix | none | yes |
| Where a riwayah differs | place index for all 19 non-Hafs riwayat, word- and letter-level | word-level index for its 7 | none |
| Hear both readings | 4 riwayat (Tilawa's table) | 4 riwayat | none |
| Worked examples per narrator | added today (see section 5) | 20 per rawi for 18 rawis, with up to 2 clips | none |
| Ayah alignment across counts | runtime count walk + content check | build-time DP table, verified | n/a |
| Narrator and imam profiles | written for this app | ported from this app | ten short reader bios |
| Statistics against Hafs | yes (Riwayah Statistics) | none | none |

Tilawa's qiraat features are otherwise a subset of ours. The one thing it shows that we did not was the
per-narrator "where he differs" list; that is now on every narrator page here, computed from our own texts.

## 2. The Quran.com matrix: what the builder keeps and what it does not

Every field that carries information is already in `QiraatVariants.json.xz`: the word, its category
code, the segments, each reading's text, transliteration, English, explanation, and the reader and
transmitter cells. Fields checked and found empty or redundant across all 1,409 records: `combinedTranslation`
(identical to `commentary` everywhere), `crossVerse` (always false), `verseRange` (always equals `verseKey`),
`translations[]` and `explanations[]` (never differ from the singular fields), `grammaticalForm`, `rootLetters`,
`textImlaei` (always null), `color` (the source's own row tint). Ten reader bios exist; the app's profiles are
written for it, so they are not used.

### The category code, decoded

The source publishes `category` without a legend. The matrix itself fixes it:

| Code | Junctures | Readings render differently in English |
|---|---:|---|
| A | 630 | 630 of 630 |
| B | 900 | 36 of 900 (the rest render alike) |
| AM | 41 | 41 of 41 |
| BM | 43 | 1 of 43 |
| none | 20 | 0 of 20 |

So A marks a difference of sense, B a difference of form or pronunciation only, and the M suffix marks a word
the early codices themselves spell differently (the commentary at those junctures says so: 63 to 93 percent
mention the codices, against 4 to 6 percent elsewhere). The app now shows this as a caption on each juncture
("Differs in sense", "Same sense, another form", "The early codices spell it differently").

### Attribution errors in the matrix

Method: at every juncture whose readings differ in skeleton, and which Hafs's own text passes (507 of 647), each
transmitter's own text was checked for the form the matrix gives him. The verified KFGQPC texts agree with the
matrix at 96 to 97 percent of junctures; what remains is mostly orthography (hamzah seats, dagger alef, a small
seen over the sad for Qunbul's and Ruways's سراط). Eight sites survive every check and are matrix errors:

| Ayah | Matrix says | Texts and the classical record say |
|---|---|---|
| 18:86 حَمِئَةٍ / حَامِيَةٍ | lists swapped | حَمِئَةٍ: Nafi, Ibn Kathir, Abu Amr, Hafs, Yaqub; حَامِيَةٍ: Ibn Amir, Hamzah, al-Kisai, Shubah, Abu Jafar, Khalaf |
| 12:109 تَعْقِلُونَ / يَعْقِلُونَ | Nafi, Ibn Amir on the ya; Hamzah, al-Kisai, Khalaf on the ta | ta: Nafi, Ibn Amir, Asim, Abu Jafar, Yaqub; ya: Ibn Kathir, Abu Amr, Hamzah, al-Kisai, Khalaf (KFGQPC Warsh and Qalun print تعقلون) |
| 31:30 يَدْعُونَ / تَدْعُونَ | Ibn Kathir and Abu Amr swapped | ta: Nafi, Ibn Kathir, Ibn Amir, Shubah, Abu Jafar; ya: the rest (the matrix's own 22:62 has it right) |
| 36:70 لِيُنذِرَ / لِتُنذِرَ | لتنذر for eight imams | لتنذر: Nafi, Ibn Amir, Abu Jafar, Yaqub only (KFGQPC Bazzi, Qunbul, Duri, Susi print لينذر) |
| 30:39 لِيَرْبُوَ / لِتُرْبُوا | Ibn Amir and Yaqub swapped | لتربوا: Nafi, Abu Jafar, Yaqub |
| 57:15 لَا يُؤْخَذُ / لَا تُؤْخَذُ | ta for Abu Jafar alone | ta: Ibn Amir, Abu Jafar, Yaqub |
| 4:162 سَنُؤْتِيهِمْ / سَيُؤْتِيهِمْ | Khalaf on the nun | Khalaf follows Hamzah; the printed Islamweb Khalaf mushaf marks the ya as its reading |
| 46:12 and 48:10 | Ibn Kathir and Yaqub listed whole | al-Bazzi alone reads لِتُنذِرَ at 46:12; Ruways reads فَسَنُؤْتِيهِ and Rawh فَسَيُؤْتِيهِ at 48:10 (the matrix has them the other way round) |

The first seven are reader-level and fit the builder's `VARIANT_READER_ERRATA` table as it stands; the last two
need transmitter cells, which that table cannot yet express. The ready-to-paste block was prepared with this
audit; applying it means editing `Scripts/build_qiraat_variants.py`, rebuilding the pack, and re-running
`Scripts/verify_qul_packs.py`, which was left for a separate go-ahead.

Two more disagreements are turuq, not errors, and the printed mushafs decide them: the Islamweb Qunbul
mushaf reads تَقُولُونَ at 25:19 where the matrix gives Qunbul يَقُولُونَ, and the Islamweb Shubah mushaf reads
وَتَكُونَ at 10:78 where the matrix gives Shubah وَيَكُونَ (its own note says Shubah has another narration).

## 3. Our texts against KFGQPC v2.x

Tilawa holds the official KFGQPC releases (Warsh v2.1, Qalun v2.1, ad-Duri v2.0, as-Susi v2.0, Shubah v2.0).
Compared with this app's copies ayah by ayah, base letters and the multiset of marks per word, after folding the
two editions' encoding conventions (U+06E1 against U+0652, yeh barree, tatweel, zero-width marks):

| Riwayah | Same | Word division only | Marks differ | Letters differ |
|---|---:|---:|---:|---:|
| Warsh | 6,185 | 5 | 22 | 2 (hamzah seat convention) |
| Qalun | 5,964 | 240 | 4 | 6 (hamzah seat convention, and one ۞ missing in v2.1) |
| ad-Duri | 4,999 | 4 | 1,213 (the imalah dot moved codepoint, U+065C to U+06EA, U+06EA to U+06ED) | 1 (hamzah seat) |
| as-Susi | 5,092 | 40 | 1,077 (same codepoint change) | 8 (all word division plus the same marks) |
| Shubah | 6,231 | 3 | 0 | 2 (hamzah seat; v2.0 has a stray ٢٨٦ in 2:286) |

No consonantal difference anywhere. The Duri and Susi "marks" rows are one systematic codepoint change and
mean nothing for the reading. The real list is short and worth taking: v2.1 corrects marks on 22 Warsh words and
4 Qalun words that our copies lack or misplace (in the riwayah's own numbering):

Warsh: 3:60 فَنَجْعَل (missing fatha), 4:19 تَرِثُواْ, 4:76 اُ۬لصَّلَوٰةَ (wasl vowel), 5:59 اُ۬لْكِتَٰبَ, 6:70 مِنْهَآ, 7:153 وَءَامَنُوٓاْ,
8:32 عِندِكَ, 8:55 وَأَغْرَقْنَآ, 9:100 اَ۬لَاعْرَابِ, 10:23 اُ۬لْحَيَوٰةِ, 16:2 اَنذِرُوٓاْ, 18:31 وَحَسُنَتْ, 18:52 أَنَّهُم, 19:88, 20:106
and 34:23 الشَّفَٰعَة (missing shaddah), 27:66 بُرْهَٰنَكُمُ, 33:37 وَاللَّهُ, 33:72 وَأَشْفَقْنَ, 50:2 مُّنذِرٞ, 51:47 بِأَيَيْدٖ, 58:10 وَعَلَى.
Qalun: 9:110 ه۪ارٖ, 33:37 وَاللَّهُ (and v2.1 drops the ۞ there), 34:23 اُ۬لشَّفَٰعَةُ, 51:47 بِأَيَيْدٖ, 58:10 وَعَلَى.

Taking them means editing `Resources/JSONs-Deprecated/Qiraat/QiraahWarsh.json` and `QiraahQaloon.json` and
rebuilding everything downstream (`qiraat.qpk`, the solid packs, the tajweed and line packs), so it was not done
here; the word list above is the whole job.

## 4. The beta texts, graded by an independent source

The same cross-check grades the twelve machine-read texts at the farsh level, which no earlier check could:
after the orthographic noise floor is removed they agree with the matrix at 94 to 97 percent, the same band as
the KFGQPC texts, and every one of their "strong" disagreements turned out to be a matrix error (section 2),
not a text error. Ruways and Qunbul read lower (87 percent) only because the print conveys their سراط with a
small seen over the sad, which a skeleton comparison cannot see.

Sites where a beta text disagrees with the matrix and no verified text can arbitrate were taken to the print
where it was quick: Hisham's 23:72 and Khallad's 22:23 and 35:33 are both right (the print marks the rasm's alef
silent, فَخَرَاجُ and وَلُؤْلُؤٍا۠, and the extraction kept the mark). Still to look at: Ruways 2:164 (الرياح), 17:43,
18:89, 4:90 and 53:55, all places where Yaqub's reading sits on the same rasm and only the marks can tell.

## 5. What changed in the app

- Every narrator page in the Qiraat guide gained "WHERE X DIFFERS FROM HAFS": the count of differing ayahs,
  the classical teaching sites first and then the riwayah's own places, each as a Hafs-reads / he-reads pair
  with the reference's meaning where it has one, a same-reciter recording where one exists, a link into the
  Qiraat Explorer at that place, and the walk of a whole surah. Beta narrators show the gate note until beta
  text is unlocked. (`iPhone/Quran/QiraatNarratorDifferences.swift`, iPhone target only.)
- The category caption on every juncture: the ayah actions sheet, the Readings page, and the explorer.
- Credits: the narrator-page examples follow Tilawa's reference screen, and say so.
- DEBUG launch hooks for headless screenshots: `-openQiraatNarrator "<tag>"` and `-scrollToDifferences`.

## 6. Reconciling the matrix with our texts: the review packet (later on 2026-09-12)

The skeleton cross-check of section 2 could only test the 647 junctures whose readings differ in
letters. A second pass now judges all 1,634 junctures for all 20 texts: each word is reduced to what it
sounds like (letters, short and long vowels, tanween, shaddah), with the Uthmani conventions folded in
(dagger alef, silent-letter circles, tashil dots, small letters, the KFGQPC tanween code points, the small
seen over the sad), the transmitter's ayah is found by a monotonic alignment of the whole surah rather
than by word overlap, and the reading closest to the text at the juncture is compared with the reading
the matrix gives him. Every text agrees with the matrix at 98.7 to 99.7 percent of junctures.

What is left is 108 junctures and 391 narrator rows, laid out for review with the printed line of each
narrator's mushaf beside the claim (page from the Madani division, line from the print-line pack,
band from the page's ink profile; 347 of the 391 lines were found exactly, the rest are placed by
proportion and say so):

| Bin | Sites | Rows | Meaning |
|---|---:|---:|---|
| Whole-imam disagreements | 41 | 186 | both narrators of an imam carry the same form against the matrix; where several imams line up it is the matrix's attribution |
| Single-narrator splits | 40 | 117 | one narrator disagrees while the other matches the matrix: a transmitter-level cell the matrix lacks, or a slip in that one text |
| No exact match | 27 | 88 | the text matches none of the listed forms exactly: notation, a merged juncture, or a real slip |

The packet is `~/Downloads/Islam/qiraat-review/index.html` (the crops in `sprites/`, the data in
`items.json`, the scripts in `work/`), also published as a private artifact at
<https://claude.ai/code/artifact/79148be1-3e13-4554-b7c6-c7f0c55eda27>. Verdicts are kept in the
browser and exported as JSON keyed by `surah:ayah|juncture|transmitter id`, which is what the fixes will
be applied from.

What the packet already shows, before the eye check:

- The whole-imam bin is the matrix's error list. Beyond the eight sites of section 2 it holds, among
  others, 24:6 أَرۡبَعُ (Hafs, Hamzah, al-Kisai, Khalaf on the raf'; the matrix has the lists swapped),
  25:62 يَذۡكُرَ (Hamzah and Khalaf only), 25:49 and 43:11 مَيِّتٗا (Abu Jafar alone), 21:35 and 2:281
  تَرۡجِعُونَ (Yaqub, and Abu Amr at 2:281), 36:55 شُغۡلٖ (Nafi, Ibn Kathir, Abu Amr), 47:26 إِسۡرَارَهُمۡ (Hafs,
  Hamzah, al-Kisai, Khalaf), 19:97 لِتَبۡشُرَ (Hamzah alone), 67:11 فَسُحُقٗا (al-Kisai, Abu Jafar), 73:9 رَبِّ,
  3:188 and 3:169 the تحسبن verbs, 22:15 لِيَقۡطَعۡ, 6:83, 7:25, 35:9, 55:35, 57:15, 59:2, 72:5 to 72:13.
- Two text slips are already visible in the crops: Khallad 29:28 (our أِنَّكُمۡ; the print أَئِنَّكُمۡ)
  and Hisham and Ibn Dhakwan 18:18 (our رُعبُا; the print رُعُبٗا). Candidates the print must settle:
  Ibn Wardan and Ibn Jammaz at 106:1, the two Abu Jafar narrators at 11:116, Khallad 24:35,
  Shubah 10:35 (KFGQPC v2.0 reads as we do), the first word of 6:54, Hisham and Ibn Dhakwan at 3:169,
  the Yaqub pair at 7:25, and 19:19 for Nafi, Abu Amr and Yaqub.
- Three matrix records are wrong in their reading text rather than their attribution: 21:96 (its
  فُتِّحَتۡ يَأۡجُوجُ should be فُتِّحَتۡ يَاجُوجُ), 11:68 (two sites merged, with tanween on لِثَمُودَ for seven
  imams where al-Kisai alone has it) and 7:40 (a stray tatweel).
- Transmitter-level cells the matrix lacks, with our texts and the classical record together:
  Qalun بِيُوت (16:68, 16:80) and وَرِيّٗا (19:74), Ibn Dhakwan تَخۡرُجُونَ (30:19) and تَتَّبِعَانِ
  (10:89), al-Bazzi لِتُنذِرَ (46:12), Ruways and Rawh at 48:10.

Corrections to the notes above: the Qunbul and Ruways texts do carry the small seen on all 38 صراط words,
so the 87 percent figure in section 4 was an artefact of the skeleton comparison, not a text gap. Two
data facts learned on the way: the print-line packs (`Lines<Riwayah>`) store packed integers, `value >> 1`
the word offset at which a printed line starts and `value & 1` whether that line is full; and the
per-riwayah `pages` tables in the tajweed packs (exported to the engine as `data/mushaf/pages/*.json`)
drift by an ayah at page edges (the Shubah table puts 2:94 on page 14; the print has it on page 15), while
the Madani page reached through the Hafs alignment, the route the app's PDF page mode takes, is right.

Applying the verdicts is the same Scripts/ job as before: matrix errata into `Scripts/build_qiraat_variants.py`
and the engine's import script, text slips into the riwayah JSONs with the downstream packs rebuilt.

### 6.1 Second pass (2026-09-13): verdicts in the page store, and a random spot check

Abu reviewed the packet in the artifact and reported that our text is right at almost every flagged row,
with a couple of exceptions. The first version kept his verdicts only in the browser (localStorage), so
they could not be read from here. The artifact was republished at the same address with the `db`
capability: on load the page merges its browser copy with the collection `verdicts` (one document per
row, id = the row id with `|` replaced by `~`, fields `id, narrator, kind, key, verdict, note, t`),
uploads anything newer, and saves every later click to both. Opening the link once is enough to
upload what he already marked; `read_db list verdicts` on the artifact reads them back. `Export` still
works as text.

The same republish added a **spot check** section at the top: 30 rows drawn with seed 20260913 from the
1,479 junctures where every text agrees with the matrix (sirat junctures set aside), one row per narrator
other than Hafs and eleven more; 25 are places where the narrator reads against Hafs (our text must
carry the variant), 5 where the narrator reads like Hafs while other imams differ. Each row shows the
narrator's printed line and asks one question, does the print show what our text shows. Built by
`work/spot_check.py` into `spot.json` and `sprites/spot-check.jpg`; `make_html.py` now merges both files.
The spot verdicts use the values `ok`, `differs`, `other`.

### 6.2 Verdicts read back (2026-09-13), and two false-alarm classes

63 verdict documents were in the store when read: 60 disagreement rows over 13 sites and 3 spot rows.
Tally: 55 "print = our text (matrix wrong)", 0 "print = matrix (our text wrong)", 5 "other / unclear"
(the five non-Qalun rows of 19:19), 3 spot rows "ok" (2:10 ad-Duri, 2:249 Idris, 2:280 Qalun). Sites:
12:109 juncture 1 and 18:86 (12 rows each, disagreements in both directions: the matrix has the two
reader groups swapped, and the prints side with our texts each way), 19:97 (6), 21:35 (4), 8:66 (4),
3:49 (4), 19:19 (6: Qalun "text", the other five "other"), and the two-row sites 2:191, 2:281, 3:169,
4:162, 6:83, 7:25.

Two classes of false alarm surfaced while answering Abu's questions on 3:49 and 19:19:

1. **Wrong occurrence.** When the juncture word repeats inside the ayah, the aligner takes the first
   occurrence. 3:49 has أَنِّي twice; the variant (Nafi, Abu Jafar: إِنِّي) is the second one, before
   أَخْلُقُ. Our Qalun, Warsh, Ibn Wardan and Ibn Jammaz texts carry إِنِّيَ there (word 15 of their ayah
   48), the prints show it in pink, the matrix is right, and the four packet rows compared the first
   أَنِّي, which everyone reads alike. Same at 10:35 (يَهْدِي five times; the variant لَا يَهِدِّي is the
   fourth, the packet looked at the first). 26 of the 1,634 junctures have a repeated span; only these
   two are in the packet, and none of the 30 spot rows. Tool fix: prefer the occurrence at which the
   twenty texts differ from one another.

2. **The Madinah dot on an alif seat.** At 19:19 the Warsh, ad-Duri, as-Susi, Ruways and Rawh prints
   show لِاَ۬هَبَ: lam-alif in pink (the page legend reads "الحرف المخالف لحفص"), a fatha, and a filled
   dot on the alif, no hamza. The same dot marks the lightened hamza at 2:6 ءَٰا۬نذَرۡتَهُمۡ in the ad-Duri
   print. The literature writes this reading as a ya (لِيَهَبَ), which is the matrix's spelling; the
   mushaf keeps the rasm alif and marks the change with the dot. Our ad-Duri and as-Susi texts carry the
   print's spelling with the dot (U+06EC); our Warsh, Ruways and Rawh texts carry it without the dot,
   exactly as KFGQPC's own digital Warsh text (Tilawa's copy) does. No text error: the judge scored the
   dotted alif as a hamza (d = 0.3). Qalun's print has a black لِأَهَبَ with the hamza, as do our text
   and KFGQPC's digital Qalun; the matrix's reader-level Nafi cell does not split Qalun, whose
   transmission is recorded with a khilaf here and whose Madinah print takes the hamza. Candidate
   erratum, not applied: 19:19 R0 gains transmitter 3 (Qalun). Other packet rows on the same notation,
   still to be eye-checked: 36:49 Qalun, ad-Duri, as-Susi يَخ۬صِّمُونَ; 7:98 Warsh أَوَاَمِنَ.

Nothing applied; the packet page was left as it is so the spot check in progress is not disturbed. Next,
after the 30 spot rows: repair the locator, teach the judge the dot, rerun the pipeline, republish.

### 6.3 The packet repaired (2026-09-14)

Abu asked for the packet to be repaired before he went on. Three false-alarm classes had been found by
then (6.2); the rebuild found and fixed several more. Nothing in Al-Islam changed: all of this is in
`qiraat-review/work/` (qlib.py, judge.py, build_packet.py, make_html.py; the old outputs are kept in
`work/prev_v1/`). The page at the same link now carries the rebuilt packet.

**Locator.** A repeated word (أَنِّي twice in 3:49, يَهْدِي five times in 10:35) now resolves to the
occurrence at which the twenty texts differ from one another; a segment that carries a context word
(لَّا يَهِدِّىٓ) is narrowed to the reading's own words. Two-word readings (أَنَّهُ…فَأَنَّهُ) are located
part by part on distinct words, the later part may sit in the next ayah (the second half of 8:65 and
8:66 is one khilaf that the source lists under both ayahs, now one row set), and a Hafs ayah that a
print splits in two (18:86, where the six Ibn Kathir, Abu Amr and Abu Jafar texts had been "unlocated")
is searched across the neighbouring own ayah. A window more than three edits from every form is
unlocated rather than shown as nonsense (11:41 had matched ٱثۡنَيۡنِ).

**Judge.** The small waw and small ya of the silah (كُمُۥ, هُۥ, بِهِۦ) are letters in Unicode, not marks,
so every span containing one had cost a point against the source's plain spelling; that alone made most
of the old "neither" section. The KFGQPC alif notation was decoded from a survey of the texts themselves
(every wasl alif in the Qalun, Warsh, ad-Duri, Ruways and Abu Jafar texts carries a dot or a rounded zero
with its start vowel): an initial alif with vowel and dot is wasl and its start vowel is ignored; with a
vowel and no mark it is a hamzat qat' written without its sign (Warsh's naql: قَرۡيَةً اَمَرۡنَا,
قُرَيۡشٍ اِيلَٰفِهِمۡ); with a dot and no vowel, or plain before a vowelled letter, it is a lightened
hamza (Ruways ا۬مۡوَٰلَكُمُ after ٱلسُّفَهَآءَ); a small waw on an alif is a waw (Abu Amr's اۥُقِّتَتۡ). Inside
a word, a vowelled bare alif is a lightened hamza seat spelt ya or hamza by the books (19:19), a dotted
alif without a vowel, or a second alif after a dagger, is a hamza present but lightened (Abu Jafar's
ءَٰا۬ذۡهَبۡتُمۡ at 46:20, Qalun's هَٰا۬نتُمۡ at 3:66), and a dot on a consonant is a shortened vowel
(يَه۬دِّي, يَخ۬صِّمُونَ). The alif wasla and the silent-letter marks (U+0652, which all twenty texts use only
on silent letters, and the zeros) are honoured, so Ibn Amir's لِإِيْلَٰفِ reads لِإِلَٰفِ. On the source
side: لاَ is normalised, a missing shadda is forgiven only where no shadda khilaf is among the forms
(أَئِن for أَئِنَّ, but not لَوَّوۡا against لَوَوۡا), a dropped final vowel is cheap, اللّٰه with a dagger
matches the prints' fatha, U+0622 is a hamza plus madd except before a hamza, before a doubled letter or
at the end of a word, and cheap variants cover the ibdal of Warsh, as-Susi and Abu Jafar (مُومِنٗا,
يَٰلِتۡكُم), Warsh's naql (أَوَاَمِنَ at 7:98) and a wasl spelt as a hamza (إِصۡطَفَى). A two-word juncture
where the text follows one reading on one word and another on the other is a new status, "mixed"
(3:169: Hisham and Ibn Dhakwan carry تَحۡسَبَنَّ with قُتِّلُواْ).

**Numbers.** Over the 32,000 transmitter-junctures: agreements 31,363 to 31,934, ties 694 to 259,
unlocated 160 to 81, "neither" 97 to 6 (plus 16 mixed). Packet: 391 rows over 108 sites to 334 rows
over 93 sites (40 split sites with 101 rows, 43 whole-imam sites with 212 rows, 10 "no exact match"
sites with 21 rows), every row with a crop. 76 old rows left the list (3:49, the five at 19:19, 8:65
and 8:66, 3:66, 4:94, 7:40, 7:113, 10:35, 18:85, 21:96, 36:49, 37:153, 39:64, 43:68, 106:2 and a few
more); 19 rows are new, all real questions: the six at 18:86 (the swap already known), seven at 6:63
where the texts keep the shadda of the second يُنَجِّيكُم (6:64) that the source lightens for Nafi, Ibn
Kathir, Abu Amr and Ibn Dhakwan, Abu Jafar's mixed 106:1-2, Ibn Dhakwan's ءَان at 68:14, and Rawh's
لَوَوۡاْ at 63:5 (the source has Ruways and Rawh the other way round). 6:54 now reads cleanly and
shows the same shape as 12:109: our Nafi and Abu Jafar texts carry أَنَّهُ…فَإِنَّهُ and our Ibn Kathir,
Abu Amr, Hamzah, al-Kisai and Khalaf texts إِنَّهُ…فَإِنَّهُ, which is al-Tabari's account of the Madinan
and Basran readings, so the source's R1 and R2 attributions look swapped. 1,369 agreements sit at a
phonemic distance of one or more (the source's spelling granularity, e.g. Shubah's يِهِدِّيٓ against the
source's يَهِدِّي); they are not in the packet.

**Verdicts.** Of the 63 stored verdicts, 50 attach to rows that still exist (47 "print = our text", 3
spot rows "ok"); the 13 orphans are exactly the false alarms (3:49 four, 19:19 five, 8:66 four). Five
rows whose located span changed were re-keyed so no old verdict answers a new question (10:78, 11:68,
59:2 j1, 73:9, 81:12). The 30 spot rows are untouched.

**Page.** Sections run spot check, single-narrator splits, whole-imam disagreements, no exact match;
"hide reviewed" is on by default and remembered; each site has a button that marks every row "print =
our text" after one look at one print (and one that clears the site); compound rows show both words
and both print lines; the source's readings are set in Scheherazade New (the KFGQPC faces stack the
hamza of لِأَهَبَ oddly and draw a dotless final ya for modern spelling), the Warsh face is used for
Warsh's own text only.

Nothing applied to Al-Islam; Scripts/ untouched; nothing committed.

## Appendix: the errata block, ready to paste

Additions for `VARIANT_READER_ERRATA` in `Scripts/build_qiraat_variants.py` (keyed by ayah, then by the
reading's exact source text; the value replaces the reading's reader list, transmitter cells are kept;
reader ids: 1 Ibn Amir, 2 Hamzah, 3 Khalaf al-Ashir, 4 al-Kisai, 5 Asim, 6 Abu Jafar, 7 Nafi, 8 Ibn Kathir,
9 Abu Amr, 10 Yaqub). The builder fails loudly if a keyed text no longer matches the source.

```python
    "18:86": {"حَمِئَةٍ": [5, 7, 8, 9, 10], "حَامِيَةٍ": [1, 2, 3, 4, 6]},
    "12:109": {"تَعْقِلُوْنَ": [1, 5, 6, 7, 10], "يَعْقِلُوْنَ": [2, 3, 4, 8, 9]},
    "31:30": {"يَدۡعُونَ": [2, 3, 4, 9, 10], "تَدۡعُونَ": [1, 6, 7, 8]},
    "36:70": {"لِيُنْذِرَ": [2, 3, 4, 5, 8, 9], "لِتُنْذِرَ": [1, 6, 7, 10]},
    "30:39": {"لِيَرۡبُوَ": [1, 2, 3, 4, 5, 8, 9], "لِتُرۡبُوا": [6, 7, 10]},
    "57:15": {"لَا يُؤۡخَذُ": [2, 3, 4, 5, 7, 8, 9], "لَا تُؤۡخَذُ": [1, 6, 10]},
    "4:162": {"سَنُؤْتِيهِمْ": [1, 4, 5, 6, 7, 8, 9, 10], "سَيُؤْتِيهِمْ": [2, 3]},
```

Transmitter-level, needing a small extension of the table (a way to set the `tm` cells too):
46:12 `لِيُنذِرَ` readers [2, 3, 4, 5, 9] + transmitter Qunbul (6), `لِتُنذِرَ` readers [1, 6, 7, 10] + transmitter al-Bazzi (5);
48:10 swap the two transmitter cells so `فَسَيُؤۡتِيهِ` carries Rawh (18) and `فَسَنُؤۡتِيهِ` carries Ruways (17).
The Quran-Tajweed-Engine import script carries its own copy of the errata table and needs the same block.
