# Islamweb mushaf PDFs — extraction input

The 22-volume electronic mushaf series published by **Islamweb (Qatar Ministry of Awqaf)**,
used with permission obtained by email (Aug 2026). These are the raw input `pipeline/extract.py`
reads (`PDFS = BASE.parent / "pdfs"`, opened as `<slug>.pdf`).

Re-downloaded 2026-08-06 from the Internet Archive mirror of the series:
<https://archive.org/details/quran-islamweb.net> — 22 files, 225 MB, each verified against the
item metadata's byte size and a `%PDF-` header.

Filenames are **`NN-<qiraah>-<riwayah>`** — the imam first, then his narrator, numbered in the
app's own `Settings.Riwayah` order (Asim first, since Hafs is the default). The folder therefore
sorts into the ten readings with their two riwayat together:

```
01-asim-hafs              01-asim-shubah
02-nafi-warsh             02-nafi-qalun          02-nafi-warsh-tariq-al-asbahani
03-ibn-kathir-al-bazzi    03-ibn-kathir-qunbul
04-abu-amr-ad-duri        04-abu-amr-as-susi
05-ibn-amir-hisham        05-ibn-amir-ibn-dhakwan
06-hamzah-khalaf          06-hamzah-khallad
07-al-kisai-abu-al-harith 07-al-kisai-ad-duri
08-abu-jafar-ibn-wardan   08-abu-jafar-ibn-jammaz   08-abu-jafar-ibn-jammaz-second-copy
09-yaqub-ruways           09-yaqub-rawh
10-khalaf-al-ashir-ishaq  10-khalaf-al-ashir-idris
```

Names use the app's own spellings (`Settings.Riwayah` labels and `teacher` strings). The archive's
own filenames are the Arabic titles (`القرآن الكريم برواية <riwayah>.pdf`).

The pipeline still speaks its short internal slugs; `extract.pdf_path()` maps slug → filename
(falling back to `<slug>.pdf` for older layouts), so nothing downstream had to change.

## The 17 the pipeline already consumes

`shubah` `qaloon` `duriabiamr` `susi` `warsh` — the five **bridges** (riwayat the app has
KFGQPC-verified text for, used to learn the glyph→Unicode map), and the twelve beta riwayat:
`hisham` `ibndhakwan` `khalaf` `khallad` `abuharith` `durikisai` `ibnwardan` `ibnjammaz`
`ruways` `rawh` `ishaq` `idris`.

## The 5 extra volumes in the series (not previously used)

| Slug | What it is | Why it might matter |
|---|---|---|
| `hafs` | Hafs an Asim | A **sixth bridge**, and the one with the strongest ground truth — the app's Hafs text is KFGQPC-verified. Best available calibration for the glyph decoder. |
| `bazzi` | al-Bazzi an Ibn Kathir | Bridge (app has verified text). Makki family — no Makki bridge existed before. |
| `qunbul` | Qunbul an Ibn Kathir | Bridge, Makki family. |
| `ibnjammaz-alt` | Ibn Jammaz, "نسخة اخرى" (another copy), 50.6 MB | An **independent second scan** of a riwayah the pipeline scored in the high-90s — usable as a cross-check on that text rather than only a bridge round-trip. |
| `warsh-asbahani` | Warsh via **al-Asbahani** | A different tariq of Warsh from the al-Azraq one the app ships. Not represented in the app at all. |

Nothing here is bundled into any app target; this folder is extraction input and reference only.
