# Deprecated JSON sources

**Nothing in this folder ships in the app.** These are the original JSON sources for the
data now shipped as `.qpk` packs in `Resources/Data/`, kept only as a fallback reference
and as the inputs the packs were built (and verified) from.

- `Quran.json` — full Quran (Hafs) with translations/transliteration → `Quran/quran.qpk`
- `SurahInfos.json` — "About this Surah" write-ups → `Quran/surahinfos.qpk`
- `Qiraat/*.json` — the 7 riwayah overlay files → `Quran/qiraat.qpk`
- `NamesOfAllah.json` — the 99 Names → `namesofallah.qpk` (verified with 851 assertions)

The app loads exclusively from the packs (see `iPhone/Quran/QuranPack.swift` and
`QuranPackAdapter.swift`; the loader was verified against these sources with 216,885
equality assertions). If a pack ever needs to be rebuilt or re-verified, these files
are the ground truth. Deleting this folder saves repo space but destroys that ability.
