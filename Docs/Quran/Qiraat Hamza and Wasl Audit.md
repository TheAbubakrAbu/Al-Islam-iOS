# Qiraat Hamza and Wasl Audit (2026-10-26)

Two questions, answered against the twenty riwayah texts in `Resources/Data/Quran`, the twenty
Islamweb volumes they are displayed with (`Resources/Mushaf PDFs`, extraction copies in
`~/Downloads/Islam/qiraat-extraction-pdfs`), and the classical sources on each reader's hamza.

1. Khalaf 'an Hamzah sounds hamza-less in recordings, yet our PDF and JSON write every hamza. Which is wrong?
2. Which riwayat write hamzat al-wasl with the small saad, and which with the Maghribi dot?

Short answers: neither is wrong, the recordings are applying Hamzah's pause rule; and every printed page
in the app draws the saad while eight of the twenty texts write the dot.

## 1. Khalaf 'an Hamzah: the hamzas belong in the text

### The rule

Hamzah reads every hamza in full (tahqiq) in continuous reading and lightens it only when he stops.
This is the whole point of the Shatibiyyah's chapter *باب وقف حمزة وهشام على الهمز*, whose opening line
(235) is **وَحَمْزَةُ عِنْدَ الْوَقْفِ سَهَّلَ هَمْزَهُ**. The lightening covers middle and final hamzas by
tashil (between the hamza and the long vowel), ibdal (hamza to alef, waw or ya), naql (the vowel moves onto
the preceding consonant and the hamza drops) or hadhf, following the Uthmani rasm: Ibn al-Jazari says he
"does not fall short, when stopping on a word containing hamza, of following what is written in the
Uthmani mushaf" (*al-Nashr* 1/352). An initial hamza is kept in full. *Al-Budur al-Zahira* gives the
worked case at 2:13 السُّفَهَاءُ: Hamzah and Hisham turn the hamza into an alef at the pause, with the three
madd lengths.

What a listener hears on top of that is Khalaf's own sakt. In continuous reading Khalaf makes a short
breathless pause on the consonant before a hamza in three places:
the lam of أل, the word شيء, and a detached final consonant before a hamza-initial word (الساكن المفصول,
for example قَدۡ أَفۡلَحَ, مِنۡ ءَامَنَ). *Tanqih al-Tahrir* puts it in one line: **وفي أل مع المفصول مع شيء
اسكتن لدى خلف**. Khallad never pauses on the detached consonant, and on أل and شيء both ways are
transmitted from him, with the sakt and without: Abu Shamah, as Ibn al-Qasih quotes him, "ووقفت لخلاد بعدم
السكت في قد أفلح وبالسكت وعدمه في الأرض" (mtafsir.net thread 59487; an earlier draft of this note had
Khallad with no sakt at all, which is one of his two ways, not the rule). A sakt separates the hamza from its
consonant rather than removing it, but to the ear it changes the word just as much.

So a recording of Khalaf 'an Hamzah lightens every hamza in the last word of every ayah (and at every
pause mid-ayah) and detaches the rest. None of that can be carried by a mushaf text, which encodes the
continuous form; Hafs mushafs do not write his four sakts either. A commercial Khalaf mushaf
(ulumalazhar.com) advertises that it "draws the hamzah when pausing according to Hamzah's method", which
is a marginal notation on top of the full hamza, not a replacement for it. The Islamweb volume has no
such layer: it is body text only, no front matter, no waqf forms, no sakt signs.

Two neighbours for comparison. Khalaf al-Ashir (Ishaq, Idris) keeps Hamzah's farsh but reads the hamza in
full at the pause as well, "like Hafs", and the Durrah gives him no sakt (the Mutawalli and al-Dabba'
allow it from Idris through al-Mutawwi'i). Hisham lightens only the final hamza at the pause and reads
the rest in full.

### What our Khalaf data does

The text is a continuous-reading text with Hamzah's farsh and nothing missing:

| Text | Hamza letters (ء أ إ ؤ ئ, U+0654, U+0655) | Against Hafs |
|---|---:|---:|
| Hafs | 19,170 | |
| Khalaf | 19,185 | +15 |
| Khallad | 19,184 | +14 |
| Shubah | 19,194 | +24 |

Khalaf's 75 word-level hamza differences from Shubah are the expected farsh: إِنَّ for أَنَّ (6:54, 10:90,
23:111), زَكَرِيَّا without the hamza, يَاجُوجَ وَمَاجُوجَ, إِمِّهَٰتِكُمۡ, دَكَّآءَ (7:143), شُرَكَآءَ (7:190),
يُضَٰهُونَ, مُرۡجَوۡنَ, لَنُثۡوِيَنَّهُم, إِسۡوَةٌ, تُرۡجِي, ٱلسَّيِّئۡ (35:43), قَالَ ٱعۡلَمۡ (2:259).

The Islamweb Khalaf page writes the hamzas in full too. Page 3, first line (2:6):
إِنَّ ٱلَّذِينَ كَفَرُواْ سَوَآءٌ عَلَيۡهُمۡ ءَأَنذَرۡتَهُمۡ أَمۡ لَمۡ تُنذِرۡهُمۡ لَا يُؤۡمِنُونَ, both hamzas of ءَأَنذَرۡتَهُمۡ,
the final hamza of سَوَآءٌ, the seated hamza of يُؤۡمِنُونَ; the only magenta is the damma of عَلَيۡهُمُ.
The small seen (U+06DC) occurs twice in each Hamzah text, over the sad of يَبۡصُۜطُ (2:245) and بَصۜۡطَةٗ
(7:69), so the print carries no sakt sign at all.

Verdict: keep the hamzas. If the app ever wants to show what a reciter does at a pause, that is a new
display layer (the waqf form of the last word of each ayah), not an edit to the text.

## 2. Hamza across all twenty riwayat

The hamza-letter count against Hafs separates the readers whose lightening is written into the text from
those whose lightening exists only in performance.

| Riwayah | In continuous reading | At a pause | Hamza letters vs Hafs | The text shows |
|---|---|---|---:|---|
| Hafs | tahqiq; tashil only at 41:44 ءَا۬عۡجَمِيّٞ | tahqiq | 0 | |
| Shubah | tahqiq | tahqiq | +24 | farsh only (زَكَرِيَّآءَ, يَأۡجُوجَ, جَبۡرَئِلَ, مُرۡجَـُٔونَ) |
| Qaloon | drops the first of two same-vowel hamzas across words; tashil of the second in one word with an inserted alef | tahqiq | -127 | ٱلسَّمَآ۟ إِن, هَٰؤُلَآ۟ إِن, أَٰ۟ذَا, ءَٰا۬نذَرۡتَهُمۡ |
| Warsh | naql (اَ۬لَارۡضَ), ibdal of the sakin hamza (يُومِنُونَ), tashil of the second hamza in one word (ءَآنذَرۡتَهُمۡ) and across words (جَآءَ احَدٞ) | as in wasl | -4,624 | all of it, 4,576 words differ from Qaloon |
| Bazzi | drops the first across words; tashil in one word | tahqiq | -270 | جَا أَحَدٞ, لَا۬عۡنَتَكُمُ |
| Qunbul | tashil of the second across words | tahqiq | -256 | هَٰؤُلَآءِ ا۪ن, جَآءَ ا۬حَدٞ |
| Duri Abu Amr | drops the first across words; tashil in one word; sakin hamza kept | tahqiq | -179 | ءَٰا۬نذَرۡتَهُمۡ |
| Susi | as Duri, plus ibdal of every sakin hamza | as in wasl | -1,301 | يُومِنُونَ, يَاتِي, وَبِيسَ; 1,104 words differ from Duri |
| Hisham | tahqiq; in one-word pairs an inserted alef with tashil of the second (the print's choice) | lightens the FINAL hamza (Shatibiyyah 235) | -17 | ءَٰا۬نتَ at 5:118 only, see defects |
| Ibn Dhakwan | tahqiq | tahqiq | +3 | |
| Khalaf | tahqiq, sakt before the hamza in أل, شيء, the detached consonant | lightens middle and final hamzas | +15 | nothing of either, correctly |
| Khallad | tahqiq; no sakt on the detached consonant, sakt or none on أل and شيء | lightens middle and final hamzas | +14 | nothing of either, correctly |
| Abu al-Harith | tahqiq | tahqiq | -50 | farsh only |
| Duri al-Kisai | tahqiq | tahqiq | -50 | farsh only, identical hamza inventory to Abu al-Harith |
| Ibn Wardan | ibdal of the sakin hamza, Abu Jafar's own drops (إِسۡرَآيلَ) | as in wasl | -1,521 | يُومِنُونَ, المومنين |
| Ibn Jammaz | as Ibn Wardan | as in wasl | -1,514 | 8 words differ from Ibn Wardan (ٱلۡـَٰٔنَ seats, يُوَيِّدُ, مِّلۡءُ) |
| Ruways | tashil of the second hamza across words and in one word | tahqiq | -151 | 109 bare-alef words (اَلَا after ٱلسُّفَهَآءُ, ا۪ن after هَٰؤُلَآءِ, ءَا۬نذَرۡتَهُمۡ), all real |
| Rawh | tahqiq | tahqiq | +14 | |
| Ishaq | tahqiq, no sakt | tahqiq | -2 | |
| Idris | tahqiq, no sakt | tahqiq | -2 | identical to Ishaq (one body text, see the Durrah note) |

The 109 Ruways words were checked one by one: 101 follow a word ending in a hamza (including a hamza
under a silent alef, نَشَٰٓؤُاْ, اَ۬لۡمَلَؤُاْ), one follows an ayah that ends in يَشَآءُ (14:28), one follows
Yaqub's own زَكَرِيَّآءَ (19:2), and 55:52 مِنِ اِسۡتَبۡرَقٖ is Ruways' wasl-hamza reading of the word.

## 3. Hamzat al-wasl: saad on every page, dot in eight texts

### The printed pages the app shows

Page 1 of all twenty Islamweb volumes was rendered at 400 dpi and the line ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ
compared. **Every volume draws the wasl alef with the small saad**, the Madani (Qaloon, Warsh, Ibn
Wardan, Ibn Jammaz) and Basri (Duri, Susi, Ruways, Rawh) volumes included. The generated Hafs facsimile
(`01-asim-hafs.pdf.xz`) draws the saad as well. So in page mode the sign is the saad for all twenty.

### The texts

| Riwayah | U+0671 ٱ (saad) | U+06EC ۬ | U+06EA ۪ | U+06DF ۟ | Convention |
|---|---:|---:|---:|---:|---|
| Hafs | 13,483 | 2 | 1 | 0 | saad |
| Shubah | 13,486 | 3 | 0 | 0 | saad |
| Bazzi | 13,490 | 56 | 57 | 46 | saad (the dots are tashil and dropped-hamza marks) |
| Qunbul | 13,490 | 83 | 72 | 33 | saad (same) |
| Hisham | 13,480 | 2 | 0 | 0 | saad |
| Ibn Dhakwan | 13,481 | 1 | 0 | 0 | saad |
| Khalaf | 13,485 | 1 | 0 | 0 | saad |
| Khallad | 13,486 | 1 | 0 | 0 | saad |
| Abu al-Harith | 13,485 | 1 | 0 | 0 | saad |
| Duri al-Kisai | 13,485 | 1 | 0 | 0 | saad |
| Ishaq | 13,484 | 1 | 0 | 0 | saad |
| Idris | 13,484 | 1 | 0 | 0 | saad |
| Qaloon | 1 | 10,088 | 695 | 177 | dot (one stray saad at 2:186 فَٱلۡـَٰٔنَ) |
| Warsh | 0 | 10,056 | 2,569 | 281 | dot |
| Duri Abu Amr | 0 | 10,052 | 1,312 | 170 | dot |
| Susi | 0 | 10,053 | 1,279 | 170 | dot |
| Ibn Wardan | 0 | 10,110 | 655 | 163 | dot |
| Ibn Jammaz | 0 | 10,110 | 655 | 163 | dot |
| Ruways | 0 | 10,065 | 628 | 161 | dot |
| Rawh | 0 | 10,011 | 625 | 137 | dot |

Twelve texts write the saad. Eight write the Maghribi dot, following the King Fahd Complex editions of
Warsh, Qaloon, Duri and Susi, which are set in Mashriqi script with Maghribi dabt. The four beta texts
among them (Ibn Wardan, Ibn Jammaz, Ruways, Rawh) did not get the dot from their own print, which draws
the saad; the pipeline's `restore_wasl_signs` learns the sign from the KFGQPC bridge text by word skeleton.
That leaves page mode and text mode disagreeing for eight riwayat. Whether to keep the dot (it matches the
official mushafs of those riwayat) or convert the four beta texts to their print's saad is a product
decision this audit does not make.

### How the dot convention reads

The Maghribi scheme marks two things on a wasl alef. The vowel written on the alef is the join: the sound
the previous word ends on (see the wasl-vowel rule in the engineering notes, اِ۬لۡحَمۡدُ after ٱلرَّحِيمِ).
The dot's position is the vowel the word takes when you START on it:

| Sign | Position | Start vowel | Words |
|---|---|---|---|
| U+06EC | filled dot above | fatha | every ال word: اَ۬للَّهُ, اَ۬لَّذِينَ, اَ۬لۡأَرۡضِ (10,000 of the ~10,050 per text) |
| U+06EA | empty circle below | kasra | اِ۪تَّقُواْ, اِ۪بۡنَ, اِ۪تَّخَذُواْ, اِ۪سۡمُ, اِ۪سۡتَكۡبَرُواْ (628 to 692 word-initial per text) |
| U+06DF | small circle above | damma | اُ۟عۡبُدُواْ, اُ۟دۡخُلُواْ, اُ۟نظُرۡ, اُ۟ذۡكُرُواْ, اُ۟دۡعُواْ, اُ۟سۡجُدُواْ (138 to 266 per text) |

Each sign has a second job, which is why the raw counts exceed the wasl counts: U+06EC on a bare alef
marks a lightened qat' hamza (اَ۬لَا after ٱلسُّفَهَآءُ, ءَٰا۬نذَرۡتَهُمۡ, Hafs's own ءَا۬عۡجَمِيّٞ); U+06EA off the
first letter is the taqlil dot (1,834 of Warsh's 2,481, 660 of Duri's); U+06DF off the first letter marks
a dropped first hamza (ٱلسَّمَآ۟ إِن, هَٰؤُلَآ۟ إِن) or Qaloon's tashil'd second hamza (أَٰ۟ذَا, أَٰ۟لَٰهٞ).

## 4. Defects found, and fixed the same day

Found by the sister-rawi test restricted to the hamza inventory (strip every character except
ء أ إ ؤ ئ U+0654 U+0655 from each word, align ayah then word index, list the pairs that differ). Every
one was traced to its glyph in the extraction pipeline (`_staging-riwayat/pipeline`, `dumpword.py` and
`findglyph.py`), fixed in the pipeline's tables rather than in the shipped text, and the four affected
volumes re-rendered with `build.py --emit-only`; the other eight came back byte-identical to the
2026-10-14 reference build. `expected-sha256.txt` carries the new hashes.

| Where | Text | Had | Now | Root cause and fix |
|---|---|---|---|---|
| 4:11 (two words) | Khalaf | فَمِّهِ | فَلِإِمِّهِ | the volume draws the لِإِ ligature as Hamd2#105, which `fixdrops.py` had listed as a piece of the decorative basmalah and put on the droplist. Mapped in `manualmap.json` (kufi-scoped), removed from `droplist.json` and from `FURNITURE_GIDS` |
| 4:11 (two words) | Khallad | فِلِإِمِّهِ | فَلِإِمِّهِ | the page draws the lam's kasra (HQPB4#175) before the ligature (HQPB2#96), so it landed on the fa and the vowel collapse kept it over the fatha. Two pinned context rules in `final.py` |
| 12:47 | Khallad | دَٱلۡبٗا | دَأۡبٗا | a print error: the page sets دَاْبًا with a magenta sukoon and no hamza (page 241, line 4, checked at 700 dpi) while Khalaf's page sets دَأۡبٗا. Row in `sitepatch.json` |
| 24:35 | Khallad | دُرِّيٓٞ | دُرِّيٓءٞ | the volume's hamza here is Hamd2#193, also droplisted as basmalah furniture. Mapped and un-droplisted as above |
| 29:28 | Khallad | أِنَّكُمۡ | أَءِنَّكُمۡ | the same glyph |
| 22:23, 35:33 | Khallad | وَلُؤۡلُؤٖا۠ | وَلُؤۡلُوٕٖاْ | the KFGQPC spelling of a kasratain hamza on a waw seat, which Khalaf's page and all seven other Kufi and Shami volumes already produce (QiraahDuri writes the same jarr reading exactly so). Rows in `sitepatch-audit.json`; Khalaf's وَّ keeps its print shadda |
| 21 words | Hisham | ءَٰانذَرۡتَهُمۡ | ءَٰا۬نذَرۡتَهُمۡ | the magenta dot is MSH-Quraan1#40, one glyph with two jobs: the ishmam dot on قِيلَ-words (resolved to a kasra, see `ishmam_dot`) and the tashil sign on the softened second hamza, which was being resolved to nothing. A pinned rule emits U+06EC when the dot follows the alef, its magenta copy (HQPB7#7) or the idkhal dagger (HQPB2#165); 25 Hisham ayahs and 6 Ibn Dhakwan ayahs changed (ءَاٰ۬مَنتُم at 7:122, 20:75, 26:48, ءَاٰ۬لِهَتُنَا 43:57 and Ibn Dhakwan's ءَا۬عۡجَمِيّٞ 41:42 and ءَا۬ن 68:14 among them) |
| 2:186 | Qaloon | فَٱلۡـَٰٔنَ | فَالۡـَٰٔنَ | the only U+0671 in a dot text; patched in `Quran-Tajweed-Engine/sources/Qiraat/QiraahQaloon.json`, the engine's `data/qiraat/qiraah-qaloon.json` and `qiraat.qpk` (verified against the JSON afterwards) |

Two conventions were settled on the way. The tashil dot sits BEFORE the dagger on an alef (ءَاٰ۬مَنتُم,
six verified texts, never the reverse) but AFTER it on Qaloon's ra (أَرَٰ۬يۡتَكُمۡ, 34 words), so
`reorder_dagger` swaps the pair on an alef only; a blanket swap moved 34 ayahs in each Abu Ja'far
volume and was reverted. And Khalaf's print shadda on وَّلُؤۡلُوٕٖاْ (the idgham of the preceding
tanween) is kept, as it is on his يُّوصِيكُمُ and every other such word.

Rebuilt from the corrected texts: the four `Qiraah*.json.deflate` packs, `TajweedKhalaf.json.deflate`,
`qiraah.solidpack`, `tajweed.solidpack`, `qiraat.qpk`. `TajweedRuways.json.deflate` also changed:
its khilaf-marker list still carried 5:92 from before the vocative was moved into 5:93 on 2026-09-06,
and the rebuild (run twice, byte-identical) dropped it. The sukoon gate passes on all 19 texts.

Pairs with a clean hamza inventory: Abu al-Harith / Duri al-Kisai (0 differences), Ishaq / Idris (0),
Ibn Wardan / Ibn Jammaz (8, all real: ٱلۡـَٰٔنَ seats and two words), Hisham / Ibn Dhakwan (30, of which
the 21 above were the lost dot and the rest real: هِئۡتَ, وَنَـَٔا, وَرِءۡيٗا).

## 5. Method

* Texts: inflate `Qiraah*.json.deflate` (raw deflate, wbits -15) and the seven verified JSONs in
  `Quran-Tajweed-Engine/sources/Qiraat`; Hafs from `Quran-Tajweed-Engine/sources/Quran.json`.
* Census: count the hamza letters and the sign codepoints per text; group each sign by the word that
  carries it and by the vowel beside it.
* Pages: `pdftoppm` page 1 of each extraction PDF at 220 and 400 dpi, crop the measured body lines, tile.
* Sources: Shatibiyyah 235 with Kanz al-Ma'ani; Ibn al-Jazari, al-Nashr 1/352 (quoted on mtafsir.net);
  al-Badur al-Zahira (shamela.ws/book/923/78); Tanqih al-Tahrir, chapter on Khalaf and Khallad
  (quranpedia.net/book-attachment/20899/93778); the Khalaf al-Ashir sakt threads on mtafsir.net
  (threads 44571 and 18771); the Mashriqi-versus-Maghribi dabt thread on mtafsir.net (thread 62631);
  ulumalazhar.com product page for the Khalaf mushaf.

## 6. qiraatbooks.com, checked 2026-10-26

Abu asked whether the Khalaf 'an Hamzah guide on qiraatbooks.com (a Mississauga bookshop) carries
anything the app's reader and narrator pages lack. The site has four reference pages: the Khalaf 'an
Hamzah guide, "What are the ten qira'at?", a student's guide to the Matn ash-Shatibiyyah, and "Warsh vs
Hafs", plus category and product blurbs for the Damrah margin mushafs. No dates, chains or usul tables:
the biographical facts it gives (Hamzah of Kufa, one of Ibn Mujahid's seven; Khalaf ibn Hisham al-Bazzar
of Baghdad and Khallad ibn Khalid of Kufa, both through Sulaym; Khalaf al-Ashir through ad-Durrah with
Ishaq al-Warraq and Idris al-Haddad; ad-Duri the same man under Abu Amr and al-Kisai) were already in
`QiraatProfiles.swift` and `QiraatIsnad.swift`, with death years and the Sulaym link.

What the app did not say, and now does:

* **Hear versus read.** The Hamzah page explains that every hamza is pronounced while reading on and
  eased at a stop, so recordings end each ayah hamza-less while the mushaf keeps it, with 23:1 and the
  mid-ayah test at 4:92. The Khalaf and Khallad pages carry the sakt rule above, each from its own side,
  and the Khalaf page the "two mushafs, one name" warning (Khalaf 'an Hamzah via ash-Shatibiyyah against
  Khalaf al-Ashir via ad-Durrah). The Khalaf al-Ashir page says where the two readings part company (full
  hamza at a stop, no sakt).
* **The texts students memorise**, a new section of the Qiraat guide (`QiraatView`): ash-Shatibiyyah
  (Hirz al-Amani, 1,173 lines, al-Lamiyyah, ash-Shatibi d. 590 AH, its four parts), ad-Durrah (about 240
  lines) and the Sughra, Tayyibat an-Nashr (about 1,015 lines) and the Kubra with its extra turuq, Ibn
  al-Jazari's three conditions, and that the app's twenty follow the Sughra.
* **The four shadh readings** named in OTHER REPORTED QIRAAT (al-Hasan al-Basri, Ibn Muhaysin, Yahya
  al-Yazidi, al-A'mash; with the ten, the fourteen).
* **The usual road** through the readings (Hafs, then a second riwayah or the seven with the Shatibiyyah,
  then the Sughra with ad-Durrah, then the Kubra) replaces the old "begin with one riwayah" bullet, and
  the margin mushaf (a second narrator's variants beside the text) is explained next to the explorer door.

### What stands out in each reading

Abu then asked for the site's "What stands out in Hamzah's reading" shape for every reading. Each of the
ten imam pages and twenty narrator pages now carries a WHAT STANDS OUT list in place of the old two-line
KNOWN FOR, five or six features for an imam and three or four for a narrator, each a sentence with the
word as the app's own text writes it, and a footer saying a mushaf shows only part of it. Every Arabic
example was checked against the twenty texts first (scratchpad `look.py` over the census `texts.json`):

| Reading | Feature in the list | Checked in the text |
|---|---|---|
| Nafi | Warsh naql قَدَ اَفۡلَحَ, ibdal يُومِنُونَ; Qalun يُؤۡمِنُونَ, جَا أَحَدٞ, هَٰؤُلَآ۟ إِن; Warsh taqlil مُوس۪ىٰ, ٱلنّ۪ارِ; mim عَلَيۡهِمُۥٓ before a hamzah only (Warsh 127, Qalun 0) | Warsh 23:1, 2:3, 2:5; Qaloon 4:43, 2:30 |
| Ibn Kathir | فِيهِۦ, مِنۡهُۥ, عَنۡهُۥ (115, 50, 35 ayahs); mim رَزَقۡنَٰهُمُۥ (919 words); Bazzi تَّفَرَّقُواْ, جَا; Qunbul ٱلصِّۜرَٰطَ | Buzzi 2:2, 3:103, 4:43; Qunbul 1:6 |
| Abu Amr | Susi idgham kabir قَال رَّبُّكَ, رَبِحَت تِّجَٰرَتُهُمۡ (1,046 bare-plus-shadda pairs outside ن م ل; Duri none); imalah ٱلنَّٜاسِ, ٱلۡكَٰٜفِرِينَ, أُخۡرٜىٰ; taqlil ٱلدُّنۡي۪ا, مُوس۪ىٰ; يَأۡمُرۡكُمۡ, بَارِئۡكُمۡ; هَٰٓؤُلَآ إِن; Susi تُومَرُونَ | Duri 2:66, 2:53, 2:6, 2:30; Susi 2:67 |
| Ibn Amir | سَارِعُوٓاْ, فَلَا يَخَافُ; Ibn Dhakwan جٜآءَ ×56, شٜآءَ ×55; Hisham's marks only الٓرٜ, كٓهيٜعٓصٓ, عٰٜبِدُونَ | Hisham/IbnDhakwan 3:133, 91:15; mark census |
| Asim | Hafs مَجۡرٜىٰهَا, ءَا۬عۡجَمِيّٞ, the four sakts; Shu'bah أَدۡرٜىٰكَ, رٜءَا, حٜمٓ, الٓرٜ | Shubah mark census |
| Hamzah | عَلَيۡهُمۡ; هَل ثُّوِّبَ; مُوسٜىٰ, ٱلۡهُدٜىٰ, ٱلدُّنۡيٜا, جٜآءَ, شٜآءَ | Khalaf 1:7, 83:36, 2:87, census |
| al-Kisai | مُوسٜىٰ ×56, ٱلدُّنۡيٜا ×110, بَلٜىٰ, وَكَفٜىٰ; هَل ثُّوِّبَ; no جٜآءَ (Hamzah only); the feminine ta at a pause is NOT marked (0 words) | AbuHarith 83:36, census |
| Abu Ja'far | يُومِنُونَ; قُلُوبِهِمُۥ (924); ءَٰا۬نذَرۡتَهُمُۥ; مِن غَيۡرِ with no sukun (5 ayahs; خَيۡرٖ not found with its shadda); إِسۡرَآيلَ (44 ayahs); no imalah marks | IbnWardan 2:3, 2:6, 2:5, 5:108, 2:39 |
| Ya'qub | عَلَيۡهُمۡ (Ruways, Rawh); Ruways ٱلۡكَٰٜفِرِينَ (92), صِۜرَٰطَ; Rawh no marks | Ruways/Rawh 1:7, 1:6, census |
| Khalaf al-Ashir | عَلَيۡهِمۡ kasra; مُوسٜىٰ, ٱلدُّنۡيٜا, جٜآءَ, شٜآءَ (Ishaq census, 1,871) | Ishaq 1:7, census |

Features the page cannot show are said to be oral: Khalaf's sakt and his ishmam of الصراط, al-Kisai's
tilted feminine ta at a pause, Abu Ja'far's pause after each opening letter, al-Bazzi's takbir, Ya'qub's
soft ha on هُوَ and هِيَ, Warsh's thick lam and thin ra. Madd counts and the basmalah between surahs are the
Shatibiyyah and Durrah usul (Warsh and Hamzah six, Asim, Ibn Amir, al-Kisai and Khalaf al-Ashir four,
the rest short; Hamzah no basmalah; Warsh, Abu Amr and Ibn Amir three ways). Not verified in the texts
and therefore left out: the opened ya of the first person (إِنِّيَ) for the Hijazi readers, and the idgham
of ذ in ٱتَّخَذتُّم.

`Resources/Data/Islam/IslamArticles.json.deflate` was rebuilt with `Scripts/build_islam_corpus.py` so Ask
AI sees the new guide text. The profile strings are `String(localized:)`, so the Arabic and Urdu catalogs
need the usual `localize_catalog.py sync` pass before the next translation batch.

## 7. The Hamzat al-Wasl setting: either notation on every text (2026-10-26)

Abu: "could we have a toggle that makes it where Hafs an Asim can switch to the dot version? Would have
to make it preprocessed though and part of the JSON. And should we have an option to switch between for
all qiraat?" Both, and preprocessed. Settings > Quran > Arabic Text > LETTERS AND MARKS now carries a
three-way picker, **Follow the Print** (the default: every text as section 3 describes it) / **Saad** /
**Dot**, applied to all twenty texts in the list reader, the composed text pages, the ayah sheets, the
share cards and every card that goes through `displayArabicText`. The PDF facsimiles are pictures and
cannot follow; the watch and the widgets keep the print form.

### What the engine decides, and what the app does

`Quran-Tajweed-Engine/scripts/al-islam/build_wasl_signs.py` reads the twenty shipped texts straight out
of the app's packs (`quran.qpk`, `qiraat.qpk`, the twelve beta deflates) and writes, for every word of
every ayah, one code character:

| Code | Text | Meaning |
|---|---|---|
| `.` | any | unchanged |
| `0` | saad text | the word's first U+0671 becomes a bare alef (a prefixed wasl, Madani style) |
| `1`-`9` | saad text | the first U+0671 becomes alef + join vowel + start sign, `1 + 3*join + start`, a/i/u = 0/1/2 |
| `A`-`J` | dot text | the alef at letter index 0-9 becomes U+0671 and up to two following vowels/signs go |
| `T` | dot text | letters 0 and 2 both (49:11 al-ismu) |

The app (`iPhone/Quran/Models/WaslSigns.swift`) only applies the code: `WaslSignTransform.apply` is the
script's `splice` in Swift, the tajweed painter's projection expands the same way, and
`UnitTests/WaslSignSamples.swift` (generated) pins 150 ayahs of the engine's own output that
`WaslSignTests` replays. Nothing linguistic runs on the phone. The sidecar is
`Resources/Data/Quran/WaslSigns.json.xz` (49 KB; 2.1 MB of JSON); the readable variants are in the
engine under `data/wasl/texts/` (29 MB, one JSON per text) and the decision log is `data/wasl/wasl-audit.md`.

Per Hafs ayah: 13,482 wasl alefs, 2,710 of them prefixed (bare in the dot form), 9,991 / 644 / 137
word-initial ones starting with fatha / kasra / damma. Every dot text comes out with 13,480 to 13,497
collapse sites, which is the same inventory from the other side.

### The rules, and where they came from

* **Start sign** (lexical): learned from the four verified dot texts (Qaloon, Warsh, Duri, Susi), keyed
  by the vocalized word so the passive اُتُّبِعُوا (2:166) and the active اِتَّبَعُوا part ways, and so
  Hafs' active اِسۡتَحَقَّ (5:107) does not inherit the passive the others read. A word no dot text spells
  (the article with a new noun, ٱحۡشُرُواْ, Shu'bah's ٱءۡتُونِي) falls to the classical rule: the article
  (a lam with no vowel, or a doubled lam) starts with a fatha; a verb with a damma on its third radical
  (or on its doubled second letter) starts with a damma, otherwise a kasra. One override: `اتوني` = kasra
  (a defective verb; the plural's damma sits on the written letter, like ٱبۡنُواْ).
* **Join vowel** (contextual): the pipeline's `carried_vowel` (the previous word's final sound, a tanween
  joins on a kasra, a silent alef is what precedes it, a dagger alef is a fatha, the Basri ya-for-maqsura
  is a fatha after a fatha or the imalah dot), reaching into the previous ayah, into the basmalah at a
  surah start (surah 9 joins on al-Anfal's last word), and past a rub' marker. After the muqatta'at
  (3:2 ٱللَّهُ after الٓمٓ) and four defective words (ending in a bare ة, م or ء) the start vowel is written.
* **The tanween before a damma-start wasl** (فَتِيلًا ٱنظُرۡ 4:50, بَعۡضٍ ٱنظُرۡ 6:65, مُتَشَٰبِهٍ ٱنظُرُواْ 6:99,
  بِرَحۡمَةٍ ٱدۡخُلُواْ 7:49, مُّبِينٍ ٱقۡتُلُواْ 12:9, خَبِيثَةٍ ٱجۡتُثَّتۡ 14:26, وَعُيُونٍ ٱدۡخُلُوهَا 15:46,
  مَّحۡظُورًا ٱنظُرۡ 17:21, مَّسۡحُورًا ٱنظُرۡ 25:9, وَعَذَابٍ ٱرۡكُضۡ 38:42, مُّنِيبٍ ٱدۡخُلُوهَا 50:34): measured in
  the dot texts, Warsh, Qaloon, Ibn Wardan and Ibn Jammaz write the damma (itba'), Duri, Susi, Ruways
  and Rawh the kasra. So the dot form of Bazzi, Qunbul, Hisham, Ibn Dhakwan, Abu al-Harith and Duri
  al-Kisai takes the damma from their readers (Ibn Kathir, Ibn Amir, al-Kisai); Hafs, Shu'bah, Khalaf
  and Khallad keep the kasra. **Khalaf al-Ashir (Ishaq, Idris) is set to kasra, Hamzah's way, as a
  judgement from his usul and not from a text: verify.**
* **Which alef collapses** (dot to saad): the alef at the letter index the saad texts put the wasla at,
  for that word's skeleton (so Warsh's اَبِاللَّهِ 9:65, whose question hamza is a bare alef, collapses
  its THIRD letter). A skeleton a hamza word shares (ٱللَّهُ / أَللَّهُ was a false one: the question
  hamza before the article is excluded from the hamza inventory) is settled by shape and vocabulary:
  a lam with no vowel or a doubled lam is the article, a sign on a bare alef is a lightened hamza
  (ا۟مِرُوٓاْ), a lam with a plain vowel is إلى/أليم/ألا unless only the wasl vocabulary knows the
  vocalized word (Warsh's naql اُ۬لَٰنَ), and one manual exclusion: `اشهدوا|-i`, Nafi's passive
  أَءُشۡهِدُوا 43:19 written اَ۟شۡهِدُواْ. An alef carrying a madd (آٰللَّهُ 10:59) or opening the muqatta'at
  never collapses.

### Verification

The dot form of every saad text collapses back to the shipped text byte for byte (asserted in the
script). The dot texts' round trip (collapse, then regenerate with the rules above) reproduces their
word-initial signs with **zero** differences on all four verified texts; the join vowel differs in
10 Warsh words, 1 Qaloon, 0 Duri, 1 Susi, every one of them the print's own: Warsh writes a fatha on
five surah-initial words (21:1 اَ۪قۡتَرَبَ, 47:1, 54:1, 69:1, 96:1) where Qaloon and Duri write the
basmalah's kasra, and odd vowels at 4:77, 5:59, 9:101 and 10:23; Warsh 3:1-2 writes a fatha on ٱللَّهُ
after الٓمٓ where its own mīm carries a kasra. None of this touches the Hafs output.

**The beta dot texts, repaired (2026-10-27, Abu: "fix those").** The first pass found Ibn Wardan and
Ibn Jammaz carrying a fatha dot on about forty kasra-start words ending in the sila mīm
(اِ۬سۡتَطَعۡتُمُۥ, اَ۬نقَلَبۡتُمُۥ, اُ۬سۡتَكۡبَرۡتُمُۥ...), Ruways and Rawh the same on اِ۬فۡتَرَىٰ (26 words) and
a handful more, and every one of the four writing a guessed join vowel on 62 to 64 ayah-initial wasl
alefs (اَ۬لذِينَ after a tanween, اِ۬لذِي after a fatha) plus the kasra at the Abu Jafar pair's
itbaʿ junctures (6:66, 6:100, 7:48, 14:28). All of it was the bridge in the extraction pipeline
(`final.py`): `fix_wasl_vowels` worked one ayah at a time, so an ayah-initial alef never saw the
previous ayah, and `restore_wasl_signs` fell back to U+06EC on a skeleton it did not know. Every
disagreement was read against the four verified texts first (`scripts/al-islam/build_wasl_signs.py`'s
round trip lists them); the engine was right in all of them but two, which were fixed on its side:

* 53:49 عَادًا ٱلُّولَىٰ (Nafi, Abu Jafar, Yaqub): the tanween's nūn is assimilated into the doubled lam,
  so the join is the tanween's own vowel (a fatha), which all eight dot texts write; the rule had
  said kasra. `lam_doubled` + `tanween_vowel` in the engine, keyed on the doubled lam followed by the
  dropped hamza's bare seat (the Basri texts' doubled lam in الَّذِينَ does not qualify).
* Ibn Wardan 12:51 اِ۬لَٰنَحَصۡحَصَ: a segmentation defect (two words glued), split by a
  `sitepatch-audit.json` row. Ibn Wardan's own naql form of الآن (as at 4:18, 10:51, 10:91) is kept;
  Ibn Jammaz writes ٱلۡـَٰٔنَ.

The fix is the engine's `normalize_dot_text` (dot to saad to dot, letters and prefixed sites never
touched), which the pipeline's emit now runs on the four dot volumes (`normalize_wasl_signs` in
`final.py`), so `build.py --emit-only` reproduces the shipped bytes again (`expected-sha256.txt`
updated for the four). 124 words changed in each Abu Jafar text, 90 in Ruways, 84 in Rawh; after it
the four texts round-trip with **zero** sign and join differences (the Yaqub pair's prefixed vowels
stay, by design). Two of the changes are judgements to verify: Abu Jafar's اضطِرّ (2:172, 5:4,
6:146, 16:115) now starts on a kasra ring, by the rule that the start follows the third letter's
vowel (the bridge had copied Hafs's damma circle), and the eleven ibdal words the bridge wrote with
no join vowel at all (ا۪ىُتُونِي 12:50) now carry it like every verified text does (اُ۪يتُونِي in Susi).
The tajweed packs key by word index, so none needed a rebuild (12:51's one rule sits on the word
that kept its index).

### Rebuild

    python3 ~/Downloads/Islam/Quran-Tajweed-Engine/scripts/al-islam/build_wasl_signs.py

reads the app's packs, rewrites `Resources/Data/Quran/WaslSigns.json.xz` and
`UnitTests/WaslSignSamples.swift`, and the engine's `data/wasl/`. Run it after any change to a shipped
text (the codes are one per word and would misalign), then `xcodebuild test -only-testing:UnitTests/WaslSignTests`.

The four beta dot texts come out of the extraction pipeline already normalized: in
`sources/Qiraat/_staging-riwayat/pipeline`, `python3 build.py --emit-only ibnwardan ibnjammaz ruways
rawh` writes `emit/Qiraah<Name>.json.deflate` (its emit step imports the wasl engine and learns its
tables from this checkout's shipped packs); copy the four into `Resources/Data/Quran`, run
`python3 Scripts/build_solidpacks.py`, then the wasl build above. The pipeline's hashes
(`expected-sha256.txt`) say `same` when nothing moved.
