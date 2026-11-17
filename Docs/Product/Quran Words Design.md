# Quran Words: Design

Abu, 2026-11-16, after a reel claimed "77,429 words, 4,700 different ones, 1,641 roots, 376 words are
53.8% of what you recite": "do some research and do something about this in tajweed and arabic and
pillars and beliefs". Scope chosen: both an article and a study tool ("Both, layered"); the study
page's depth was left to Claude ("whatever u think is best"): tiers, mark known, and a quiz per tier.

## What the numbers really are

Checked against the Quranic Arabic Corpus (QAC, the revised morphology file at
github.com/mustafa0x/quran-morphology) and the app's own Hafs text:

| Figure | Value | Notes |
|---|---|---|
| Words | 77,430 | The app's Hafs text, 199 ۞ ornaments left out. QAC counts 77,429: it writes بَعۡدَ مَا as one word (3 places) and joins إِلۡ يَاسِينَ (37:130), but splits لَّوۡمَا and مَالِيَ (2 places). The Qiraat text analysis already uses 77,430. |
| Dictionary words (lemmas) | about 4,800 | 4,763 in the QAC file, 4,817 in QUL's lemma table. Pronoun-only words (هُمۡ, لَهُمۡ) have no lemma in either. |
| Written forms | about 15,000 to 19,000 | 14,972 without vowel marks, 18,993 with. |
| Roots | 1,642 | QUL's root table, the one Word Study uses. The revised QAC file has 1,651. |
| رَبّ / قَالَ | 975 / 1,618 | Every form counted under its dictionary word. Roots: ر ب ب 980, ق و ل 1,722. |
| Used once | about 1,950 | 1,958 QAC lemmas. |
| Coverage | top 10 24.6%, 100 58.1%, 300 74.3%, 500 81.4% | By headword (dictionary words plus the pronoun entries, each Quran word counted once). By bare written form, 376 forms give 53.6% (the reel's 53.8% mixed the two units). |

Why the QAC and not the app's QUL lemma table for counting: QUL leaves about 1,600 content words
without a lemma (كَانَ 290 times, شَيۡء 109, ءَامَنَ 104) and folds مَن into مِن, so its ranks are off.

## The data: `Resources/Data/Quran/QuranVocabulary.json.xz`

Built by `Scripts/build_quran_vocabulary.py` from the QAC file (cached under
`Quran-Tajweed-Engine/sources/QAC/`), the app's Hafs text, `WordByWord.json.xz` (glosses) and the
engine's Hafs tajweed annotations. `--check` rebuilds in memory and fails if the shipped pack differs;
`--draft` writes suggested rows for headwords `Scripts/quran_vocabulary_words.tsv` does not review yet
(the build refuses to run until all 500 are reviewed). Four corpus lemmas that spell two different
words alike (عَصا staff and disobeyed, نَعَم yes and cattle, أَوۡفَىٰ, أَحۡصَىٰ) are split by kind.

- **Headword:** each Quran word belongs to ONE headword: its first stem's lemma, or, when the stem is a
  pronoun (لَهُمۡ, هُوَ, عَلَيۡكُمۡ when the corpus has no other stem), the pronoun entry for its person
  (they, he, you all...). Disjointed letters (الٓمٓ) belong to none. So headword counts add up and the
  coverage meter is a plain sum.
- **Entry:** key (the corpus headword, what a known mark stores), rank, Arabic dictionary form in Uthmani marks, meaning (hand-reviewed for all 500),
  root (Arabic letters, or none), `count` (words it heads), `uses` (every word it appears in, the
  number shown), first occurrence (surah, ayah, display token index) for the Word Study card.
- **Top 500**, five tiers of 100. Cumulative coverage per entry.
- **Totals:** words, lemmas, roots, forms, used-once count, coverage milestones.
- **Tajweed:** count per rule category over the Hafs text, with the app's rule ids.

## Arabic Alphabet: Quran Words (iOS)

- Placement: a QURAN WORDS section after GRAMMAR, one `ArabicTopicLinkLabel` row (the Explore shelf
  stays 3+3). Searchable as an `ArabicTopic` (vocabulary, common words, frequency, lemma, root).
- Page: `ResourceHero` (headline "You do not need all 4,800 words", stats: 77,430 words, 4,800
  dictionary words, 1,642 roots), a coverage meter for the reader's known words, the five tiers as
  `StudyTierRow`s (each shows what it adds), and a door to the article.
- Tier page: rows of Arabic, meaning, root, count and a known toggle; a row opens the Word Study card
  on the word's first occurrence, on its Root tab (every ayah). A "Test this tier" button.
- Quiz: StudyKit session, Arabic to meaning, four choices, 12 questions per tier. Passing
  (`StudyLadderProgress` pass mark) marks the words answered right as known.
- Progress: `QuranWordsProgress` (a `StudyLadderProgress`) plus the known set; both are content keys
  in the iCloud backup tables, like the Reading Test's.

## Tajweed

- Tajweed Foundations: a "How often each rule comes" card, one bar per rule category with its share
  of every coloured mark in Hafs, each opening its rule page.
- Tajweed Course: a closing door, "Understand what you recite", to Quran Words.

## Pillars & Beliefs: "The Words of the Quran"

QURAN & TAFSIR group, article kit: SUMMARY, THE NUMBERS (stat grid), A FEW WORDS CARRY MOST OF IT,
WHY UNDERSTANDING MATTERS (12:2, 38:29, 47:24, 54:17; Bukhari 5027), COMMON QUESTIONS (reward for
reciting without understanding; do I need Arabic to be Muslim), HOW TO START (door to Quran Words),
KEY TERMS, SOURCES. Every ayah by reference into quran.qpk; every hadith from the packs with its
grade (Tirmidhi 2910 sahih per al-Albani, Muslim 798 with Bukhari 4937). WHAT THE SCHOLARS SAID
quotes Ibn Taymiyyah, Iqtida' 1/527 (al-Aql ed.), checked against two editions. Left out: Umar's
"تعلموا العربية فإنها من دينكم" (no sound chain found) and as-Sulami's ten-ayat report (Ahmad
23482: its hasan grading seen only second hand, and Ata ibn as-Sa'ib after his confusion). The
article lives in PillarViews.swift, already in the three script lists; the corpus and the watch's
quotes pack were rebuilt.

## Testing

`UnitTests/QuranVocabularyTests.swift`: the pack loads, 500 entries in five tiers, coverage rises,
known anchors (رَبّ 975, قَالَ 1,618), every first occurrence resolves to a real token, tier shares
add up, quiz questions have four distinct choices with verbs against verbs.

DEBUG launch arguments (with `-launchTabIslam -islamDestination arabicAlphabet -arabicTopic quranWords`):
`-quranWordsKnown <n>`, `-quranWordsSeed <n>`, `-quranWordsTier <n>`, `-quranWordsTest <n>`.
Headless screenshots on the iPhone 17 Pro: the page, a tier, the quiz, the tajweed card, the article.
