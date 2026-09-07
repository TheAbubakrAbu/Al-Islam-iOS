# Deprecated JSON sources

**Nothing in this folder ships in the app.** These are the original JSON sources for the
data now shipped as `.qpk` packs in `Resources/Data/`, kept only as a fallback reference
and as the inputs the packs were built (and verified) from.

- `Quran.json`: full Quran (Hafs) with translations/transliteration → `Quran/quran.qpk`
- `SurahInfos.json`: "About this Surah" write-ups → `Quran/surahinfos.qpk`
- `Qiraat/*.json`: the 7 riwayah overlay files → `Quran/qiraat.qpk`
- `NamesOfAllah.json`: the 99 Names → `namesofallah.qpk` (verified with 851 assertions)

The app loads exclusively from the packs (see `iPhone/Quran/QuranPack.swift` and
`QuranPackAdapter.swift`; the loader was verified against these sources with 216,885
equality assertions). If a pack ever needs to be rebuilt or re-verified, these files
are the ground truth. Deleting this folder saves repo space but destroys that ability.

- `Qiraat/_staging-riwayat/`: the 12 BETA riwayat (machine-extracted; ship as
  `Resources/Data/Quran/Qiraah*.json.deflate`) + the extraction pipeline. See its own
  README for measured accuracy and the promote-out-of-beta checklist.

## Data sources & attribution

- **Hafs + the 7 verified riwayah overlays**: King Fahd Glorious Quran Printing
  Complex texts (https://qurancomplex.gov.sa), as distributed for development use
  (see also https://qul.tarteel.ai).
- **The 12 beta riwayat**: extracted from Islamweb's electronic mushaf series
  (Islamweb / Qatar Ministry of Awqaf, https://www.islamweb.net), with permission
  obtained by email (Aug 2026). PDF set mirror used for extraction:
  https://archive.org/details/quran-islamweb.net
- Review references for the beta texts: https://nquran.com (page images per riwayah)
  and the Quran.com qiraat data (https://qul.tarteel.ai / QUL).
- Extraction research log: https://claude.ai/code/artifact/bf305992-d071-4108-92f1-323eae033f4a

## QUL (Quranic Universal Library) sources

`QUL/` holds the qul.tarteel.ai downloads the `Resources/Data/Quran/` packs of 2026-09-07 are
built from (`Scripts/build_qul_packs.py`, gated by `Scripts/verify_qul_packs.py`):

- `word-root.db.zip`, `word-lemma.db.zip` (Quranic Arabic Corpus morphology) → `Morphology.json.xz`
- `mutashabihat/phrases.json` + `phrase_verses.json` → `Mutashabihat.json.xz`
- `topics.db` (Clear Quran thematic index, Corpus ontology, general index) → `QuranTopics.json.xz`
- `ayah-themes.db` → `AyahThemes.json.xz`
- `quran-metadata-{hizb,ruku,manzil}.json.zip` → `QuranMetadata.json`
- `matching-ayah.json` → the spans and extra pairs merged into `SimilarAyahs.json.xz`
  (`Scripts/build_similar_ayahs.py`)
- `english-transliteration-tajweed.json.zip` → the ayah transliteration inside `quran.qpk` and
  `Quran.json` (`Scripts/swap_transliteration.py`)

`Qiraat/quran-com-qiraat.json.xz` is the Quran.com qiraat matrix (Quran Foundation), fetched
2026-09-06 from the page data of quran.com/<surah>:<ayah>/qiraat and compacted; it builds
`QiraatVariants.json.xz` (`Scripts/build_qiraat_variants.py`). Not a published API: clear the
English renderings and explanations with the Quran Foundation before a release.

QUL word positions are Quran.com's; the builders map them onto this app's own tokens (see the
module doc of `build_qul_packs.py` for the two numbering quirks).
