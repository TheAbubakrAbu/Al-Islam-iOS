# Licences and conditions of the Tilawa port

What every source behind the features ported from Tilawa (Jamil Hammoudeh's app, ported with his
permission on 2026-09-07) allows, what it asks for, and what the app does about it. The in-screen
footers and the Credits page (Settings › Credits, searchable) carry the user-facing lines; this
file is the record for whoever changes a builder or a screen. Tilawa Guide, Phase 9 step 5.

| Source | What it covers here | Condition | What the app does |
|---|---|---|---|
| Tilawa (Jamil Hammoudeh), github.com/jamilhammoudeh/quran-app | The Reminder of the Day corpus, the Word of the Day curation, the Sunnah reminder presets and the reminder kinds, the 99 Names' themes, roots, explanations and living lines, the hadith topic library, the paired-recording table, the Tajweed course text, the Journal's prompts and kinds, the Miracles capture and image host, the Hisn library capture, the theme wash and share backdrop designs, the two search engines' scoring rules, the Qiraat Explorer's idea | Permission from the author, 2026-09-07, to port wholesale; attribution | A credit line per feature on the Credits page and a footer on each screen; the Quran and hadith text in every ported card is the app's own, never Tilawa's copy |
| hadeethenc.com (the Hadith Encyclopedia), under the Dawah and Guidance Association and the Association for Serving Islamic Content in Languages | The 2,328 narrations with their explanations, lessons, gradings and sources, Arabic and English | Reproduction without modification; credit | The narration itself (title, intro, body) renders exactly as published; only the site's commentary (explanation, benefits) had its em dashes re-punctuated by `soften_dashes` in `Scripts/build_hadeethenc_pack.py`, and that pass is the one to drop if the licence reading ever tightens; the footer names the site and both associations on every encyclopedia screen |
| miracles-of-quran.com | The two hundred articles' own prose | The site's author waived rights on the site's own prose; third-party quotations inside the articles keep their own owners | Third-party excerpts are kept short and attributed to their sources with a link; the credit footer names the site on every Miracles screen; the illustrations stream from Tilawa's copy (miracles.tilawaai.app) rather than shipping in the bundle |
| islamic.app Dhikr API | Hisn al-Muslim texts, transliterations, translations, references | Attribution | Named in the Hisn library's footer and on the Credits page |
| hisnmuslim.com | The Hisn al-Muslim recitations, streamed on demand | Attribution; nothing is redistributed | Streamed from the site; never cached to disk beyond the URL cache; named in the footer and the credit |
| Quran.com (Quran Foundation) QDC content API and the Quranic Arabic Corpus (Kais Dukes) | The Word of the Day glosses (word-by-word English) | Attribution | Named on the Word of the Day screen's footer and the Credits page |
| Quran.com qiraat reference | The readings' meanings the Qiraat Explorer draws on | Attribution | Named on the Credits page; the place index itself is computed from the app's own riwayah texts |
| everyayah.com and mp3quran (reciters as listed in `Resources/Data/Quran/QiraatVariantAudio.json.xz`) | The paired Hafs / riwayah recordings the explorer plays for Warsh, Qalun, ad-Duri and Shubah | The sources' own terms; streamed, not redistributed | One clip at a time from the source URLs; the reciter is named beside every pair |
| The app's own hadith packs (the 9-books engine) | Every hadith text a ported card or topic shows | The app's existing content standard (sahih or hasan, numbered citations) | Cards and topics ship citations only; the builders fail on a citation the shelf lacks; `Scripts/verify_tilawa_packs.py` re-checks every citation |

Rules that follow from the table:

- Never edit a narration's text in the encyclopedia pack, and never edit Quran or hadith text anywhere (the app's standing rule).
- A rebuilt pack keeps its credit: the builders write the source line into the pack (`source` keys) and the screens read the footer from there or carry it verbatim.
- New ported material needs a row here, a `CreditItem` in `iPhone/Settings/CreditsView.swift`, a footer on its screen, and a line in the tilawa-port memory.
