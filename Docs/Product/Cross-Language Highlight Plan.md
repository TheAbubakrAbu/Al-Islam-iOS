# Cross-Language Highlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** carried out on 2026-11-14, all six tasks. What was measured, and where the build differs from this plan, is in the design doc (sections 4, 5 and 10).

**Second pass, 2026-11-15:** Task 1's builder was rebuilt (five steps around a model of the leftovers; the design doc's section 4.2 replaces Step 1 below), and Task 3's fallback changed for Arabic queries (section 4.3). The pack's format, the store and the rows are as planned here.

**Goal:** Light the right words of the other language for a search hit, from a precomputed Quran word alignment (part B) and a dictionary learned from the hadith shelf (part C).

**Architecture:** Two offline Python builders write two small binary packs. At run time `CrossLanguageWordHighlight` asks the pack first and falls back to part A's gloss and lexicon rules, so a missing or stale pack changes nothing. The rows keep calling one entry point each.

**Tech Stack:** Python 3 (builders, no dependencies), Swift (iPhone target, `#if os(iOS)`), XCTest hosted in the app.

**Spec:** `Docs/Product/Cross-Language Highlight Design.md`. Abu approved it on 2026-11-14 ("go do whatever you think is best, I trust you") and left its two open questions to this plan: the pack sizes are accepted, and Khattab's model-only pairs tighten until the hand check passes.

## Global Constraints

- Hafs only; Saheeh International and Mustafa Khattab only.
- A pack that does not line up with the strings on screen returns nil and the row behaves as in part A. Never a wrong word.
- No shipped pack other than the two new ones changes: `PrecomputedPackTests` stays green without a re-export.
- Builders are deterministic (sorted iteration, fixed iteration counts) and have a `--check` mode that rebuilds and compares bytes.
- New files are registered with `Scripts/xcode_register.py`. New Swift goes inside `#if os(iOS)` (WordByWord.swift also compiles into the Watch target).
- No em dashes and no spaced hyphens in comments or docs.
- Nothing is committed, and the sibling sync is never applied.
- Simulator: an iPhone 17 Pro. Tests: `build-for-testing` once, then `test-without-building -only-testing:UnitTests`.

## Review Focus

1. "Hide Tashkeel and Signs" drops the ۞ token from 199 ayahs, so displayed Arabic indices sit one below the pack's. The store must remap, or the neighbouring word lights. Test in Task 2.
2. A translation string that differs from the one the pack was built from (a text update without a rebuild). The store must answer nil. Test in Task 2.
3. An English query that only occurs INSIDE a word ("the" in "father") must not light that word's Arabic. Test in Task 3.
4. A query under Whole Word, Starts With or Ends With. The pack lane follows whatever the base highlighter painted. Test in Task 3.
5. A hadith word that is a key only after a letter is peeled (كتاب must not be read as ك + تاب). The least-peeled key wins. Test in Task 5.

---

### Task 1: The alignment builder and pack

**Files:**
- Create: `Scripts/build_word_alignment.py`
- Create: `Resources/Data/Quran/WordAlignment.bin` (registered like `CrossLanguageLexicon.bin`)

**Interfaces:**
- Produces the pack, little endian: `u32 magic 0x314C4158 ("XAL1")`, `u32 format 1`, `u64 quran.qpk fingerprint (its header bytes 32 to 39)`, `u32 ayah count`, `u32 surah count`, `u32[surah count] first ayah ordinal`, `u32[ayah count + 1] record offsets`, then one record per ayah: `u8 arabic token count`, and per translation (Saheeh, then Khattab) `u16 english token count` and that many bytes, each the RAW Hafs token index or `255`.
- Tokens are split on exactly the characters `WordTokens` splits on: space, tab, LF, CR, U+00A0, U+2009, U+200A, U+202F.

- [x] **Step 1:** Write the builder from the 2026-11-14 prototype: gloss anchors, IBM Model 1 over both translations with lemma units and each word's gloss as a training pair (six iterations), diagonal prior 4.0, a dice gate, at most three English words per Arabic word, insertions and glue words never aligned. Per-translation thresholds are constants at the top of the file.
- [x] **Step 2:** `--check` rebuilds and compares with the file on disk, and asserts: every ayah present, every array as long as its token count, every byte below the Arabic count or 255, agreement with one-to-one gloss anchors at or above 99%, and coverage at or above the floors the first accepted build prints.
- [x] **Step 3:** `--sample 100 --seed N --translation saheeh|mustafa` prints model-only pairs with their ayah for the hand check.
- [x] **Step 4:** Hand check. Read 100 pairs per translation. Below 90 right: tighten that translation's thresholds, rebuild, and read a FRESH sample (another seed). Record the final counts and thresholds in the design doc.
- [x] **Step 5:** Run `--check`: expected `OK`. Register the pack.

### Task 2: `WordAlignmentStore`

**Files:**
- Create: `iPhone/Quran/Words/WordAlignment.swift` (registered like `WordByWord.swift`)
- Test: `UnitTests/WordAlignmentTests.swift` (registered like `LexiconCacheTests.swift`)

**Interfaces:**
- Produces:

```swift
final class WordAlignmentStore: @unchecked Sendable {
    static let shared: WordAlignmentStore
    static let isBundled: Bool
    enum Translation: Int, CaseIterable { case saheeh, mustafa }
    /// One entry per whitespace token of `english`: the index of the DISPLAYED Arabic token it
    /// renders, or nil. Nil overall when the pack is missing, stamped with another text, or its
    /// counts differ from these strings.
    func arabicTokens(surah: Int, ayah: Int, translation: Translation, english: String,
                      rawArabic: String, displayArabic: String) -> [Int?]?
}
```

- [x] **Step 1: Failing tests.** `testEveryAyahLinesUp` (all 6,236 ayahs, both translations, non-nil with the live texts); `testPinnedPairs` (57:10 خَبِيرٞ is what "Acquainted" points at, 23:101 ٱلصُّورِ what "Horn" points at, 1:6 "straight" at token 2 and "path" at token 1); `testAChangedTranslationIsRefused` (one word appended to the English gives nil); `testHiddenSignsShiftTheIndices` (2:26 with the ۞ stripped from the display text: every index is one lower than with the raw text, and none points at the dropped token).
- [x] **Step 2:** Run them: expected compile failure, then (with an empty store) four failures.
- [x] **Step 3:** Implement: map the file, check magic, format and fingerprint once, index by `first ordinal + ayah - 1`, compare both counts, remap raw to displayed indices the way `WordByWordStore.entries` drops sign-only tokens.
- [x] **Step 4:** Run them: expected pass.

### Task 3: The pack lane in `quranSpans`

**Files:**
- Modify: `iPhone/Quran/Words/WordByWord.swift` (`CrossLanguageWordHighlight`)
- Test: `UnitTests/CrossLanguageHighlightTests.swift`

**Interfaces:**
- Consumes: `WordAlignmentStore.shared.arabicTokens(...)`.
- Produces: `quranSpans(...)` unchanged in signature. New inside the enum: `matchedArabicTokens(query:displayText:wordRule:) -> [Int]` (the literal match's tokens plus the same-family tokens, extracted from `englishTermsForArabicMatch`).

- [x] **Step 1: Failing tests.** Arabic typed: 57:10 "خبير" lights "Acquainted" in Saheeh (the gloss "All-Aware" lit nothing); 1:6 "الصراط" still lights exactly "path". English typed: 1:6 "straight path" lights tokens 1 and 2; 1:6 "straight pa" the same; a query that occurs only inside a word lights no Arabic through the pack (Review Focus 3); 1:6 "path" under Whole Word lights token 1 (Review Focus 4). Fallbacks: 1:2 "العالمين" still lights "worlds"; an English query with no literal match falls back to the gloss lane.
- [x] **Step 2:** Run them: the new assertions fail.
- [x] **Step 3:** Implement. Arabic typed, per line: the English tokens pointing at a matched Arabic token, trimmed and bridged across glue; empty falls back to the gloss terms, then the lexicon. English typed: for each line, the tokens the base highlighter's ranges cover count when the range starts at or before the token's first letter (any overlap under a word rule other than Anywhere); their Arabic tokens are lit; none falls back to the gloss lane, then the lexicon.
- [x] **Step 4:** Run the class, then the whole suite: expected pass.

### Task 4: The hadith dictionary builder and pack

**Files:**
- Create: `Scripts/build_hadith_lexicon.py`
- Create: `Resources/Data/Hadith/HadithLexicon.bin` (registered like `HadithTopics.json.xz`)

**Interfaces:**
- Produces a table in the lexicon's record layout (`u32 key count`, then per key `u16 key bytes`, key, `u8 word count`, per word `u8 word bytes`, word) behind its own header: `u32 magic 0x31584C48 ("HLX1")`, `u32 format 1`.
- Key: the folded word (search fold, direction marks dropped) with the article and its prefixes off (`وال فال بال كال ولل فلل لل ال`, three letters must remain). Value: up to four English words, each the most frequent surface form of its stem.

- [x] **Step 1:** Write the builder: rows of every book with both languages, Model 1 (five iterations), entries need the key seen in at least three rows, probability at or above 0.12 and a dice gate; glue words dropped; "allah" kept only on a key that is the Name.
- [x] **Step 2:** It prints held-out coverage (800 rows, fixed seed) beside the Quran lexicon's. `--check` rebuilds and compares bytes and asserts the pins: الوضوء has "ablution", عائشة "aisha", الجنة "paradise", الصلاة "prayer".
- [x] **Step 3:** Run it and `--check`: expected `OK`. Register the pack.

### Task 5: The hadith lane

**Files:**
- Modify: `iPhone/Quran/Words/WordByWord.swift`, `iPhone/Hadith/Views/HadithComponents.swift`
- Test: `UnitTests/CrossLanguageHighlightTests.swift`

**Interfaces:**
- Produces: `CrossLanguageWordHighlight.hadithSpans(query: String, arabic: String, narrator: String, text: String) -> (arabic: [NSRange], narrator: [NSRange], text: [NSRange])`, called by `HadithRow.crossLanguageSpans` in place of its two lexicon calls.

- [x] **Step 1: Failing tests.** Arabic "الوضوء" lights "ablution" in an English line; English "ablution" lights الْوُضُوءَ; English "Aisha" lights عَائِشَةَ; "كتاب" is looked up as itself, never as تاب (Review Focus 5); a word the dictionary lacks but the Quran lexicon has still lights (fallback); "Allah" still lights only the Name.
- [x] **Step 2:** Run them: fail.
- [x] **Step 3:** Implement: load the table once (lock, off the main thread on first use), look a word up under its match variants in order with the article stripped and stop at the first that is a key, and fall back to the Quran-derived lexicon per line (Arabic typed) or per row (English typed).
- [x] **Step 4:** Run the class, then the whole suite: expected pass.

### Task 6: Verify and record

- [x] **Step 1:** Whole unit suite on the simulator: 0 failures.
- [x] **Step 2:** Screenshots: Quran "خبير", "straight path"; Hadith "الوضوء", "ablution".
- [x] **Step 3:** Update the design doc (what was built, the hand-check counts, final coverage, anything that differs from the design) and the session memory.
