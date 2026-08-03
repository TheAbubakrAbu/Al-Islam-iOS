# The 12 extra riwayat — extraction record

Source: Islamweb's 22-volume electronic mushaf series (permission obtained by email,
Aug 2026). Extracted by the pipeline in `pipeline/` (see also the project memory note
`riwayat-extraction-pipeline`).

**These are now SHIPPED as beta**, bundled at `Resources/Data/Quran/Qiraah*.json.deflate`
and gated behind Settings → Quran → *Beta Qiraat (12 More Riwayat)*. The JSONs in this
folder are the uncompressed reference copies + the pipeline that made them.

## Verified accuracy (measured, not estimated)

The pipeline is scored by round-tripping a riwayah the app ALREADY has verified text for
(Shu'bah) through the identical machinery and diffing against the King Fahd text:

| Metric | Result |
|---|---|
| Character accuracy | **99.80%** |
| Ayahs byte-identical | 87.3% |
| Ayahs identical ignoring pause-mark style | 91.2% |

The residual is dominated by **pause marks** (ۖ ۚ ۛ): Islamweb's waqf system differs from
the King Fahd Complex's, so those differences are edition-authentic, not extraction
errors. The rest are individual tashkeel marks.

**Structure is exact for all 12**: 114 surahs each, at their own canonical ayah counts —
Kufi 6236 (Khalaf, Khallad, Abu al-Harith, ad-Duri al-Kisai, Ishaq, Idris), Madani 6214
(Ibn Wardan, Ibn Jammaz), Basri 6204/6206 (Ruways, Rawh), Dimashqi 6222 for Hisham and
Ibn Dhakwan (4 short of the expected 6226 — four markers lost to cross-page splits).

**Independent farsh check passes**: Fatiha 1:4 renders مَلِكِ for Hamzah's two riwayat and
مَٰلِكِ for al-Kisai's — the textbook difference between those readers, reproduced from the
glyphs alone.

Relative text volume vs Hafs: 99–101% for ten of the twelve; **Ishaq and Idris sit at
95.3%** (their volumes lean on a font layer with more unresolved glyphs), so those two
are the weakest of the set.

Post-ship fix: the printed surah banners («سُورَةُ … وَءَايَاتُهَا …») that leaked into
ayah 1 of most surahs are now stripped (skeleton-stream matcher in
`pipeline/extract.py::strip_surah_header`); verified zero leaks across all 12 payloads,
with an-Nur's genuine «سُورَةٌ أَنزَلۡنَٰهَا» opening preserved.

## Remaining work to promote out of beta

1. Pause-mark policy: decide whether to keep Islamweb's waqf marks or normalize them.
2. Ishaq/Idris: resolve the extra unresolved-glyph classes (~31k occurrences each).
3. Hisham/Ibn Dhakwan: recover the 4 cross-page markers.
4. Word-level review against nquran.com page images / the Quran.com qiraat matrix, then
   a qari's sign-off — after which the beta flag and warnings can be removed.
