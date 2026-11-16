# Cross-Language Highlight: an alignment pack and a hadith dictionary

Design written 2026-11-14 (Abu: "How can we make search highlighting better? Especially highlighting Arabic when English is typed or vice versa", then "okay go ahead lets start it", then "go do whatever you think is best, I trust you"). All three parts were built and tested that day, following `Docs/Product/Cross-Language Highlight Plan.md`, and are uncommitted. Section 10 has what was measured after the build; sections 4 and 5 describe what was built, and say where it differs from the first draft of this design.

Second pass, 2026-11-15 (Abu: "anything else? do khattab too, do whatever is best, I want the best we can get"): the alignment builder was rebuilt around a model of the leftovers (section 4.2), which took Khattab's hand check from 89 to 95 in 100 on two thirds more pairs, and the Quran-wide lexicon is no longer asked about a typed Arabic word of a line the pack knows (section 4.3). The same method was tried on the hadith dictionary and did not earn its place (section 5.1). Also uncommitted.

## 1. Why

Typing Arabic lights the matching English words of a result, and typing English lights the Arabic ones. Both directions go through the word-by-word gloss pack (`CrossLanguageWordHighlight`, iPhone/Quran/Words/WordByWord.swift). The gloss is a literal rendering of each word, not the translation the reader sees, and hadith has no gloss at all: it borrows a dictionary derived from the Quran's.

Measured on 2026-11-14 with a script port of the rules, over all 6,236 ayahs and 3,500 sampled hadiths. The number is how often a search hit gets anything lit in the other language's line.

| | Before part A |
|---|---|
| Quran, English typed, Saheeh International | 87% |
| Quran, English typed, Mustafa Khattab | 69% |
| Quran, Arabic typed, Saheeh International | 90% |
| Quran, Arabic typed, Mustafa Khattab | 78% |
| Hadith, English typed | 42% |
| Hadith, Arabic typed | 35%, and 4.5 English words lit per Arabic word |

The causes, in the order they cost:

1. **Gloss wording is not the translation's wording.** The gloss says "All-Aware", "trumpet", "god" where Saheeh says "Acquainted", "Horn", "deity". Khattab is a freer translation and drifts further.
2. **Hadith leans on Quran vocabulary.** Narrator names, وضوء, سواك and every word the Quran does not use light nothing.
3. **An English query ignores where it matched.** The Arabic side re-matches the typed words against glosses, so a phrase or a half-typed word depends on the gloss using the same words.

## 2. Part A: precision fixes (built 2026-11-14)

Rules of the matcher only. No pack changed, so `PrecomputedPackTests` needs no re-export.

| Rule | What it stopped |
|---|---|
| A short word that merely begins a longer term is not that term | "themselves" lit every "the", "Allah" every "all", "forgiving" every "for" (5.4% of lit Quran rows) |
| A glue word is never lit on its own | "our", "your", "most" |
| "Allah" names only the word that is Allah, and that word names nothing else | The pack repeats a phrase gloss on both of its words: يتوب and الله each read "Allah accepts repentance" (6.2% of lit rows) |
| The corpus lexicon fills a translation line only when the word's own gloss found nothing in it | Typing الصراط also lit "straight" |
| Invisible direction marks are dropped before a hadith word is looked up | 13% of Riyad as-Salihin's words and 2.7% of Bukhari's carry one and could never match |
| The modern spelling of the mushaf's waw-for-alif words reaches their key | الصلاة, الزكاة and الحياة lit nothing in hadith |
| The taa marbuta twin is spelled the way the search fold spells it | صلاتهم met صلاة by accident, not by rule |
| A lit hadith word leaves its punctuation unlit | The comma of "بِالصَّلاَةِ،" turned green with the word |

Effect, same script and samples:

| | Before | After |
|---|---|---|
| Saheeh, English words lit per Arabic hit | 1.67 | 1.31 |
| Saheeh, rows with four or more English words lit | 7.0% | 1.8% |
| Saheeh, Arabic typed, rows with anything lit | 90.3% | 88.2% |
| Hadith, English words lit per Arabic hit | 4.68 | 2.56 |

The two points of lost coverage are rows where the only thing lit was a glue word or a leaked "Allah".

Code: `quranSpans(...)` is now the one entry point of `AyahSearchRow` and `AyahRow` (they carried the same forty lines each). Tests: `UnitTests/CrossLanguageHighlightTests.swift`, 14 cases. Twelve were written first and watched failing; two pin behaviour the narrower rules had to keep.

Part A does not touch cause 1, 2 or 3. That is what B and C are for.

## 3. Decisions

| Question | Answer |
|---|---|
| What B is | A precomputed alignment of every Arabic word of the Hafs text to the words of each shipped translation, built offline and looked up at run time. |
| What C is | A dictionary learned from the hadith shelf's own Arabic and English, asked first for every hadith word, with the Quran-derived lexicon for the words it has no entry for. |
| Translations covered | Saheeh International and Mustafa Khattab, the two the app ships. |
| Riwayat | Hafs only, as before. Another riwayah's words do not share Hafs's word order. |
| Where the packs are built | Python builders in `Scripts/`, deterministic, each with a `--check` mode. |
| When a pack does not apply | The row falls back to part A's behaviour. A missing or stale pack never lights a wrong word. |
| One source per line | The pack, else the gloss, else the lexicon. Never two together: a looser source added to a line a surer one already lit only adds its mistakes. Since 11-15 an Arabic query reaches the lexicon only on a line the pack cannot follow (section 4.3). |
| Function words | Aligned only where the gloss places them ("except" on إِلَّا). Read by hand, the model's own function-word pairs were the ones it got wrong and the ones nobody searches for. |
| Pack sizes (was open) | Accepted: 368 KB and 155 KB. |
| Khattab under the bar (was open) | Kept on 11-14 at 89 of 100 against a bar of 90, because what lit those words without them, the Quran-wide lexicon, read 42 of 60. Closed on 11-15: the rebuilt pack reads 95 of 100. |
| Paint | Unchanged: one accent for exact and aligned words. |

## 4. Part B: the Quran alignment pack

### 4.1 The pack

`Resources/Data/Quran/WordAlignment.bin`, 367,955 bytes, read through a memory map by `WordAlignmentStore` (iPhone/Quran/Words/WordAlignment.swift).

- Header: magic "XAL1", format, and quran.qpk's own fingerprint (header bytes 32 to 39, what `VerseSearchPack.quranFingerprint` reads). A pack stamped with another text is ignored.
- An offset per ayah, then per ayah: the Arabic word count, and for each translation its word count followed by one byte per English word. The byte is the index of the Arabic word it renders, or 255 for none.
- An Arabic word is a whitespace token (`WordTokens`), counted on the RAW Hafs text, the gloss pack's contract: "Hide Tashkeel and Signs" drops the ۞ word from 199 ayahs and the store shifts the indices to match.
- An English word is what whitespace OR a long dash ends. Khattab joins clauses with an em dash and no space, and the two halves render two Arabic words. (The first draft said whitespace only.)

The store answers nil unless both word counts equal the strings on screen.

### 4.2 The builder

`Scripts/build_word_alignment.py` (30 seconds) reads the engine's Quran.json, the gloss pack and the morphology pack (a lemma and a root per word). It was rebuilt on 2026-11-15. The pack's format did not change, so the app's side did not either.

Five steps, each working only on what the ones before left unexplained:

1. **Gloss.** An English word that is a word of an Arabic word's own gloss is that word's, parenthesised gloss words included ("(belongs) to Allah"). Position picks between two Arabic words with the same gloss. A word the English says as often as the Arabic carries it is paired in order ("you would know them ... you will surely know them ... Allah knows"). Where the gloss pack repeats a phrase gloss on each of its words ("O mankind" on both يَٰٓأَيُّهَا and ٱلنَّاسُ) the word goes to the content word, not to the passenger.
2. **Glossary.** A word the same lemma is glossed with in another ayah (خَبِير is "All-Aware" here and "Acquainted" there), or, more weakly, the same root. A word of the lemma's glossary right beside what an explained word already owns is that word's second word ("knows best" is أَعۡلَمُ whole).
3. **The residue model.** IBM Model 1 in both directions, multiplied, trained only on the words steps 1 and 2 left over, with the lemma as the Arabic unit. Three rounds, each on what the last one left. A pair must have been left over together in two ayahs.
4. **Second words.** The second English word of an Arabic word that already has one, within two tokens of the first, refused while an unexplained Arabic word stands beside it ("eternal home" is دَارُ ٱلۡخُلۡدِ).
5. **The last pair.** One unexplained Arabic word and one unplaced English word, alone between the same explained neighbours on both sides ("the ultimate triumph", ٱلۡفَوۡزُ ٱلۡعَظِيمُ, once "triumph" is placed).

Rules that hold throughout: function words and "Allah" are placed by the gloss or not at all; steps 2 to 5 place nothing on a particle, a pronoun or a helper word (كَانَ, بَعۡدَ, دُونَ); a hyphenated token is one word; at most three English words per Arabic word; glue words and the translator's insertions never.

**Why the first build's single model was not enough.** Over whole ayahs IBM Model 1 cannot credit a frequent word with a rare rendering. قَالَ is "said" 1,500 times and "responded" 60, so the probability of "responded" given قَالَ is next to nothing, and the rare word standing beside it took "responded" instead. Khattab varies his wording and lost the most to this. Trained on the leftovers alone, the "responded" lines hold a قَالَ that nothing has explained and little else. Three smaller causes were found on the way:

- the builder's stemmer did not equate "tire" with "tires" or "believe" with "believed", so 540 (Saheeh) and 680 (Khattab) true gloss matches were falling through to weaker steps;
- some 1,600 rooted words (كَانَ 102 times) carry no lemma in the morphology pack; each now takes the lemma its spelling has elsewhere;
- a hyphenated token was two words to the model, so the two parts of "alms-tax" could go to two Arabic words and leave "pay" with nowhere to go; a token is now one word.

**Checked two ways.**

- Automatically. Every gloss of a twelfth of the roots is hidden, and the pairs the later steps make for those words are scored against the hidden gloss. Step 3 scores 96 to 99 in 100 across three such twelfths, on both translations. Looser thresholds bought under a point of recall. Pairs seen together only once cost four points of precision, so they are left to step 5.
- By hand. 100 pairs that are not the gloss's own, on a fresh seed after every change:

| Build | Saheeh | Khattab | Pairs sampled from (Saheeh, Khattab) |
|---|---|---|---|
| 11-14, first prototype | 82 | not read | |
| 11-14, final: one model over whole ayahs | 95 | 89 | 6,831 and 8,160 |
| 11-15, five steps, first read | 94 | 94 | 8,561 and 13,834 |
| 11-15, second read | not read | 88 | 13,724 |
| 11-15, final | 98 | 95 | 8,131 and 13,323 |

The 88 is what sent the last three repairs in (the stemmer, "knows best", and step 5 refusing an Arabic word glossed with no word of its own). By step, pooling the reads: glossary by lemma about 97 in 100, the residue model 93 to 95, glossary by root about 89, second words about 88, the last pair about 84. The last pair with only one shared neighbour read 16 of 25 and was cut. Gloss pairs that had a rival Arabic word read 26 of 30 before the in-order rule, which repairs three of those four.

The pack holds 45,474 gloss pairs and 8,410 others for Saheeh, 34,443 and 13,586 for Khattab. Its own coverage report: 91.8% of Saheeh's English words and 92.4% of the Arabic content words aligned (88.4% and 88.1% on 11-14); for Khattab 78.8% and 84.7% (68.7% and 72.9%). What is left unaligned in Khattab is mostly true paraphrase: names he adds where the Arabic has a pronoun, "do" (too short to place), and clauses reworded whole.

### 4.3 Run time

`CrossLanguageWordHighlight.quranSpans(...)` kept its signature; the rows did not change.

- **Arabic typed.** The Arabic words the query matched (the literal match plus the same-family words, `matchedArabicTokens`) are looked up, and the English words that point at them are lit in each translation line, joined across glue. A line the pack leaves empty falls back to the gloss. The lexicon is asked only where the pack cannot follow: a row found by its meaning (no word of the ayah was typed) or a line the pack does not line up with. Where the pack knows the line and has no word for the typed one, the translation paraphrased it away (4:84, Khattab: "far superior in might and in punishment" has no word the pack may light for the first noun, "might" being a glue word), and what the lexicon lit there read right 11 times in 40 on 11-15 ("punishment", the other noun's word).
- **English typed.** The spans the base highlighter painted in either translation line are turned into words, and the Arabic words they point at are lit. A word counts when the match begins at or before its first letter, so letters found only inside a word light nothing; under Whole Word, Starts With or Ends With any overlap counts. This is what makes a phrase and a half-typed word work ("straight pa").
- An English query still falls through to the lexicon. What is left for it there is mostly function words, which the pack never aligns, and it read right 17 times in 30 ("perhaps", "never", "within" on their particles).
- One row's whole answer is cached by content.

## 5. Part C: the hadith dictionary

### 5.1 What it is

`Resources/Data/Hadith/HadithLexicon.bin`, 155,127 bytes: 7,659 folded Arabic words, each with up to four English words (9,141 pairs).

`Scripts/build_hadith_lexicon.py` (about three and a half minutes) trains the same translation model on the 47,295 rows of the shelf that carry both languages.

- Key: the app's search fold of the word with the article and what is written onto it off (`key_of`; `CrossLanguageWordHighlight.hadithKey` is the same rule).
- A first English word needs 30% of the model's weight for the Arabic word, further ones 20%. The words of every chain (in more than 15% of all rows: قال, عن, حدثنا) need 50%.
- The translators' scaffolding ("said", "narrated", "peace") stays in the training, so قال has somewhere to go, and is never a value.

Read by hand: at the prototype's 12% for every word about half of a random sample was right (rare words collect whatever stands beside them); at these thresholds 63 of 70.

Tried on 2026-11-15 and not shipped: the Quran builder's method (the Quran glossary as anchors, a two-way model over the residue, entries kept by how often each explains the other). Alone it covered 40.5% and 37.3% of the 800 held-out rows against 36.0% and 32.0%. Inside the app's chain, where the Quran lexicon already answers the anchored words, the variant of equal precision lit 43.3% and 54.4% of the sample against the shipped dictionary's 44.9% and 56.0%, and the second training round, which bought the difference back, read 34 of 45 right. The hadith side is held back by something a better dictionary does not fix: one row is one long pair with no word-by-word gloss to pin it.

### 5.2 Run time

`CrossLanguageWordHighlight.hadithSpans(...)` is the one entry point of `HadithRow`. Each word, typed or in the text, is looked up as written and then in each form the matcher peels (a و or ف off the front, a pronoun off the end), and the FIRST form that is a key answers: كتاب is a key, so it is never read on as ك + تاب. A word with no entry is answered by the Quran-derived lexicon. "Allah" lights only the Name.

Differences from the first draft: the fallback is per word, not per line; and the lane still sits behind `HAS_QURAN`, because the engine lives in the Quran's word-by-word file. A sibling app without the Quran does not get it yet.

## 6. What does not change

- The base highlighter: a match paints exactly the letters it matched.
- The guards: Hafs display, no beginner spacing, pack bundled.
- The word-by-word renderers and the mushaf page reader, which take the same spans.
- The search itself: which rows are hits is untouched.
- Every pack that shipped before: `PrecomputedPackTests` passes with no re-export.

## 7. Tests and gates

1. **Builders.** `--check` rebuilds and compares bytes. The alignment builder also asserts its coverage floors and 99% anchor agreement; the dictionary builder its pins (الوضوء, عائشة, الجنة, الصلاة, رمضان). Both rebuilt byte identical under two hash seeds.
2. **`UnitTests/WordAlignmentTests.swift`** (7): the pack lines up with the live texts for all 6,236 ayahs in both translations; pinned pairs, and since 11-15 the Khattab pairs the first build missed ("responded", "ultimate triumph", "arrogance", "pay alms-tax"); a changed translation, a changed Arabic text and an ayah out of range are refused; hidden signs shift the indices; English words end at a long dash.
3. **`UnitTests/CrossLanguageHighlightTests.swift`** (30): part A's 14, the pack lane's 8, the hadith lane's 8. Of the first 27, eighteen were written first and watched failing, six pin behaviour that had to stay, and three (the dictionary's codec, key and presence) were written beside the code. On 11-15: the lexicon rule's test was written first and watched failing (it lit "punishment"); its guard (a row found by meaning still asks the lexicon) pins what stays; and the 3:58 test was split when the rebuilt pack began to light Saheeh's own "precise" where the gloss word "wise" used to.
4. **Whole suite**: 697 tests, 0 failures, on a fresh iPhone 17 Pro simulator on 11-14; 701 tests, 4 skipped, 0 failures on 11-15.
5. **On the simulator**: خبير, "Acquainted", الوضوء and "ablution" each light the other language as section 10 describes. On 11-15: Khattab's phrase "ultimate triumph" lights both words of the Arabic in 4:13 and 5:119 (in 57:12 the first build had "ultimate" on the noun and nothing for "triumph").

Not done: the measurement script was not moved into `Scripts/`. It is a second copy of the Swift rules and would rot. The builders print their own coverage, and the numbers in section 10 are dated measurements.

## 8. Not in this design

- A quieter paint for aligned words than for the exact match.
- Lighting الصبر when "sabr" is typed, through the gloss pack's per-word transliteration.
- Other riwayat, and the Arabic and Urdu interface languages.
- A per-hadith alignment pack.
- The sibling apps: `WordAlignment.swift` and the two packs are new files the next sync will list.

## 9. Maintenance

- Rerun `Scripts/build_word_alignment.py` after any change to the Hafs text, either translation, the gloss pack or the morphology pack. Until then `WordAlignmentTests` fails and the app falls back to part A.
- Rerun `Scripts/build_hadith_lexicon.py` after a hadith book is added or retranslated.
- A builder that bumps its format must be answered in `WordAlignmentStore.acceptedFormats` or `hadithDictionaryFormats`. The file is refused whole until it is, and a hosted test says so.

## 10. Results

Same script port and samples as section 1 (1,800 ayahs, 1,300 hadiths). "Lit" is the share of search hits where the other language's line has anything lit; it is not a precision number. Precision is the hand check in section 4.2.

| Quran | Before | After A | 11-14 | 11-15 |
|---|---|---|---|---|
| Saheeh, English typed: lit | 82.7% | 82.6% | 87.6% | 89.7% |
| Saheeh, English typed: rows with three or more Arabic words lit | 7.8% | 2.1% | 1.0% | 1.1% |
| Saheeh, Arabic typed: lit | 90.3% | 88.2% | 92.2% | 93.4% |
| Saheeh, Arabic typed: English words lit per hit | 1.67 | 1.31 | 1.24 | 1.23 |
| Khattab, English typed: lit | 64.0% | 63.3% | 69.7% | 76.4% |
| Khattab, Arabic typed: lit | 77.9% | 74.4% | 80.5% | 86.8% |
| Khattab, Arabic typed: English words lit per hit | 1.67 | 1.27 | 1.21 | 1.20 |
| Hand check, pairs that are not the gloss's own: Saheeh | | | 95 of 100 | 98 of 100 |
| Hand check: Khattab | | | 89 of 100 | 95 of 100 |

The English typed rows count the translator's bracketed insertions, which correctly light nothing, so they cannot reach 100%.

The 11-15 column is with the lexicon no longer asked about a typed Arabic word of a line the pack knows. With it still asked the two Arabic typed rows read 94.8% and 88.5%: the 1.4 and 1.7 points it added were right 11 times in 40, so they were given up. Of the lit rows, 99% now come from the pack when Arabic is typed. When English is typed, 92% to 95% come from the pack, 1% to 3% from the gloss and 4% to 5% from the lexicon, mostly function words.

| Hadith | Before | After A | As built |
|---|---|---|---|
| English typed: lit | 42.1% | 41.9% | 56.0% |
| Arabic typed: lit | 33.6% | 31.7% | 44.9% |
| Arabic typed: English words lit per hit | 4.68 | 2.56 | 2.11 |

The hadith sample is part of the shelf the dictionary was trained on, so its column is a little generous. On 800 rows held out of the training, the dictionary alone lit an Arabic word for 36% of typed English words and an English word for 32% of typed Arabic ones. The hadith numbers did not change on 11-15 (section 5.1 says what was tried).

The first prototype promised about 95% for Saheeh with model pairs that were right 82 times in 100. The 11-14 build traded coverage for precision. The 11-15 build got most of that coverage back with better precision than either, because the gain came from giving the model an easier question, not from loosening it.
