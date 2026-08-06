# Hadith Domain Notes

## RESOLVED: Hadith numbering continuity (idInBook ≠ sunnah.com)

*Status: documented 2026-08-04, fixed 2026-08-04. The fix shipped as a data pipeline in the
Hadith-JSON-Engine repo plus a display-layer change here — not as the renumbering the
original plan sketched, for a reason worth keeping.*

### The problem, as reported

The `idInBook` numbers our packs ship — previously the numbers on every pill, reference
search, bookmark, and citation — do **not** match the standard numbering used by sunnah.com
and print editions. Verified example (user report): **Jami` at-Tirmidhi 2950 on sunnah.com
was hadith 3033 in the app** ("Whoever says something about the Qur'an without
knowledge…"). The drift is progressive, not a constant offset: +83 by the Tafsir chapters,
+97 by the end of the book. Root cause: upstream (`AhmedBaset/hadith-json`) numbers its own
row set, which includes variant rows the standard editions number differently
([hadith-json#11](https://github.com/AhmedBaset/hadith-json/issues/11)).

### Why the fix is a citation FIELD, not a renumbering

The original plan ("renumber `idInBook`, ship an old→new map, migrate bookmarks") turned
out to be wrong by construction once the reference data was in hand:

- **The standard numbering is not a sequence of integers.** Sahih Muslim cites variant
  narrations as **8a/8b/…** — 6,187 of its 7,459 rows carry a letter. An integer
  `idInBook` cannot represent the standard number at all.
- **Some books have no standard number.** Sunnah.com itself has no collection-level
  number for Muwatta Malik (any of it) or for 11 of Bulugh al-Maram's 16 books. There is
  nothing to renumber those rows *to*.
- **Renumbering forces a migration of every bookmark, note, last-read position, and
  HOTD entry** — all keyed `slug + idInBook` — with real corruption risk. A citation field
  leaves the row key untouched and migrates nothing.

So: `idInBook` stays what it always was — the stable internal row key — and every
user-facing surface now shows `citation`, the sunnah.com/Dar-us-Salam number
(`Hadith.displayNumber` = citation, falling back to `idInBook` where none exists, which is
exactly the books where sunnah.com shows no number either).

### What shipped

**Engine repo** (`Hadith-JSON-Engine`):
- `tools/add_citations.py` — content-matches every row (folded Arabic first, English norm
  and the repair-pipeline proof for the tail) against CheeseWithSauce, whose rows carry
  sunnah.com's literal reference lines; row sets match ours book-for-book. A structural
  guard rejects matches that break donor row order (anthology duplicates in Riyad
  as-Salihin were grabbing their far twin's number), and a reconciliation pass adjudicated
  7 scrape-era sunnah.com typos by local sequence + the second donor (fawazahmed0), which
  independently confirms 24,479 citations at 100% final agreement.
- Result: **47,476 of 50,884 rows cited (93.3%)**. Uncited = no standard number exists
  (all of Malik, most of Bulugh, Muslim's 13 unnumbered muqaddimah rows, 15 Ahmad,
  2 Nasa'i, 2 Shama'il, 2 Mishkat).
- **HPK format v3 → v4**: v3 widened the per-row record 15 → 20 bytes (u32 citation base +
  u8 suffix, 0 = none / 1–26 = a–z); v4 added a fourth display string per hadith carrying
  the scholar gradings ("name U+001F grade" joined by U+001E), rendered unconditionally
  under every full hadith. Spec, `read_pack.py`, and conformance vectors updated; packs
  rebuilt into `Resources/Data/Hadith/`.

**App:**
- `HadithPack` reads v4 (rejects earlier versions); `Row.citation` renders "2950" / "8a",
  and `grades(row:)` parses the verdicts shown by `HadithGradeLine`.
- `Hadith.citation` + `Hadith.displayNumber`; `HadithBookData.hadith(referenced:suffix:)`
  resolves citation-first with `idInBook` fallback; `hadiths(citing:)` returns all
  variants of a base ("muslim 8" → 8a…8e).
- Reference search accepts variant letters ("muslim 8a"); bare-number search matches
  citations; number pills, share text/images, Hadith of the Day, chapter ranges, and page
  pickers all show `displayNumber`.
- `HadithBookmark.citation` (optional, back-compatible) so bookmark rows render the
  standard number without loading the book; a one-shot launch migration
  (`hadithCitationRefresh1`) refreshes the frozen `reference` strings and citations on
  existing bookmarks, last-read entries, and HOTD history. No keys change.

### Verify

- Reference search "tirmidhi 2950" lands on the hadith previously numbered 3033
  (conformance spot vector; asserted by `add_citations.py` on every run).
- DEBUG launch args `-launchTabHadith -launchHadithOpen tirmidhi:3033` — the pill must
  read 2950.
- `python3 tools/read_pack.py <pack> --verify` prints per-book cited counts.

### Citation facts that look like bugs but aren't

- **Citations are not monotonic.** Sunnah.com numbers a repeated narration by identity:
  "Sahih Muslim 33c" genuinely sits in Book 5. Muslim has 131 such inversions; Tirmidhi 6.
- **Citations are not unique.** All Muslim variants share their base; Tirmidhi has 54
  genuinely duplicated numbers on sunnah.com.
- **Bulugh shows internal row numbers for most books** — sunnah.com has no standard
  numbers there; interpolating from its other numbering schemes (off by 12–25 where both
  exist) would have injected wrong citations, so those rows deliberately have none.

### Not to be confused with (already diagnosed separately)

- **English half-sentences / merged meanings** — upstream greedy `[...]`-strip corruption
  (see the hadith-data memory / engine repair logs).
- **"Shattered" disconnected Arabic on the longest narrations** — was a *rendering* cliff
  (the custom KFGQPC faces drop contextual shaping on very long single `Text`s), fixed
  2026-08-04 via `Settings.arabicShapingCharacterLimit` fallback to the system face. The
  pack bytes were pristine.
