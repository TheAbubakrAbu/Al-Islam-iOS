# The 12 extra riwayat — extraction record

> **2026-08-24: read [HANDOFF-2026-08-24.md](HANDOFF-2026-08-24.md) first.**
> A correction pass is in progress (Hamzah). Three things in this file are now known to be
> wrong or incomplete:
> * the accuracy table below predates this session's fixes; the Shubah bridge round-trip
>   is now **89.46%**, not 87.4%;
> * **both** volumes mark Hamzah's imalah in full (1,884 each, agreeing on 1,850 words).
>   Khallad draws the dot in `Hamd2` and Khalaf in `MSH-Quraan1`; the extractor was
>   dropping both, Khalaf's as page furniture;
> * `ishaq.json` and `idris.json` are byte-identical **because Islamweb published one body
>   text under both rawi names** (verified: different PDFs, identical glyph streams, pages
>   differing only in the header). This is a source limitation, not a pipeline bug.
>
> Also: do **not** extract from `Resources/Mushaf PDFs/*.pdf.xz`. Those are display-only
> and lose ~12,000 word spaces per volume. See the handoff §1.

Source: Islamweb's 22-volume electronic mushaf series (permission obtained by email,
Aug 2026), via the deterministic pipeline in `pipeline/`. Bundled at
`Resources/Data/Quran/Qiraah*.json.deflate`, gated behind Settings → Quran →
*Beta Qiraat (12 More Riwayat)*. This folder holds the uncompressed reference copies.

## Verified accuracy — measured, not estimated (Aug 3, 2026 final)

Scored by round-tripping riwayat the app already has King Fahd-verified text for
through the *identical* machinery. "ex-pause" excludes waqf pause marks, which the
Madani/Basri volumes' print vintage does not ink at all (an edition difference,
not an extraction error — KFGQPC and Islamweb follow different waqf systems):

| Bridge (family) | ayah-exact | ex-pause | char-acc (ex-pause) |
|---|---|---|---|
| Shu'bah (Kufi — covers 8 of the 12) | 87.4% | 91.3% | **99.89%** |
| Qaloon (Madani — covers Abu Jafar's 2) | 17.2% | 54.8% | **97.44%** |
| Warsh (Madani) | 14.4% | 40.0% | **97.90%** |
| ad-Duri (Basri — covers Yaqub's 2) | 47.5% | 48.2% | **87.72%** |
| as-Susi (Basri) | 37.3% | 37.9% | **87.73%** |

So: the eight Kufi-counted riwayat (Hisham*, Ibn Dhakwan*, Khalaf, Khallad, Abu
al-Harith, ad-Duri al-Kisai, Ishaq, Idris) are near-print-perfect; Ibn Wardan/Ibn
Jammaz are high-90s; Ruways/Rawh are the weakest (high-80s characters) and the top
candidates for holding back. (*Shami pair rides the Kufi glyph family.)

## Hamzatul-wasl repair (Aug 6, 2026)

The extraction under-captured the Maghribi wasl notation (`ا` + haraka + `۬`) in the
Madani/Basri volumes — ~1,300 bare alefs per riwayah against the same-family KFGQPC
bridges. `pipeline/fix_wasl.py` restored them by skeleton-matched copy from the bridges
(Qaloon/Warsh for Abu Jafar's pair, Duri/Susi for Yaqub's), additive-only and asserted
per word: ibnwardan +1,236 · ibnjammaz +1,233 · ruways +1,352 · rawh +1,297. Words whose
skeleton differs were untouched (genuine riwayah orthography), and the carrier guard
correctly refused the two-hamza tas-hil words (`ءَٰا۬نذَرۡتَهُمۡ` is Abu Amr's smoothing —
Yaqub reads the full hamza; rawh's 102 refusals are exactly these). Staging JSONs and the
shipped `.json.deflate` bundles were both rewritten and round-trip-verified.

## Structural invariants — ALL PASS

- Exact canonical ayah counts, all 12: Kufi 6,236 ×6; **Dimashqi 6,226 ×2** (the four
  page-boundary-split markers recovered from their orphaned bracket glyphs);
  Madani 6,214 ×2; Basri 6,204/6,206.
- Zero surah-banner leaks (verified across all 114 × 12).
- Fatiha 1:4 farsh matrix correct from ink alone: مَلِكِ (Hamzah's two) vs مَٰلِكِ
  (al-Kisai's two + Khalaf al-Ashir's two) vs merged numbering (the rest).
- Imalah dots (ٜ) track each reader's profile: DuriKisai 2,358 · Khalaf 2,267 ·
  Ishaq/Idris 2,055 · AbuHarith 1,830 · IbnDhakwan 319 · Khallad 137 · zero for the
  non-imalah readers.
- Ishaq/Idris's private glyph layer decoded (31k unresolved → 1.8k) by aligning
  against our own Khalaf text; Ruways/Rawh 11k → ~700.

## What "100%" means here, honestly

There is no independent digital ground truth for these 12 — that is the entire reason
they were extracted. The numbers above are the strongest verification available:
identical-machinery round-trips against the 8 verified riwayat, plus structural
invariants that cannot be faked. Residual known gaps: pause marks and maddah signs
follow the print (absent in the Madani/Basri volumes' vintage); imalah-dot placement
can hit a neighboring letter inside a word; Wardan/Jammaz retain ~7k unresolved sign
glyphs (dropped, not fabricated). Promotion out of beta = qari word-level review
against nquran.com page images, per riwayah.
