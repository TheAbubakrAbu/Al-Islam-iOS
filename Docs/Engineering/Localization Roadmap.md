# Localization Roadmap

Which interface languages come next, in what order, and the runbook a session follows to add one. Written
2026-11-21, after the fifth language round (Malayalam, Tamil, Dutch). The same strategy, with a drawing of a
round, is in Abu's Claude doc "Al-Islam: the remaining interface languages"
(https://claude.ai/artifact/7YxEEcRueiruGy8oZMcrJs). The rules every language follows are in
[Localization Guide.md](Localization%20Guide.md); the reusable kit is [Scripts/Localization](../../Scripts/Localization/README.md).

## Where things stand

15 languages: English plus ar, ur, id, ms, tr, fr, bn, ru, hi, de, es, ml, ta, nl, each with every interface
string (about 13,600 keys). Siri phrases exist for ar, ms, tr, fr, ru, de, es, nl. All 14 are machine-translated
and none has had a fluent reviewer. Abu's commit "Version 4.6.7 - Save 6" holds everything through the ml/ta/nl
code; the ml/ta/nl catalog, the catalog tool, the guide, 15 listings and this kit were uncommitted on 2026-11-21.

## How to choose

Five tests, in this order of weight:

1. **Muslims who read it first**: a community whose phones are set to the language, not one that reads Arabic,
   Urdu or English on its phone anyway.
2. **Apple supports it twice**: an iPhone interface language AND an App Store listing language.
3. **Siri speaks it**: a bonus (89 iPhone and 69 Watch phrases); without it the tips quote the English phrases.
4. **Cost of script and grammar**: Latin reuses the de/es/nl rules; a new script needs catalog-tool rules, the
   letter-spacing flag and careful screenshots; few/many plurals need Russian-style forms.
5. **Not already served**: German reaches the Bosnian, Albanian and Kurdish diaspora, Russian Central Asia, Urdu
   Pakistan's Punjabis.

Tie-breaker: App Store Connect > App Analytics, downloads by territory (Mozambique, Brazil, Italy, Sweden, India,
Thailand, Kazakhstan, Bosnia). Check it before each round.

## The order

Apple's lists were checked on 2026-11-21 (App Store Connect's "App Store localizations" reference and
apple.com/ios/feature-availability). Population figures are from memory and approximate.

| Language | Round | Muslims who read it first (approx.) | Siri | Script | Already served by |
| --- | --- | --- | --- | --- | --- |
| Portuguese (Brazil as the base) | 5 | Mozambique ~6M, Guinea-Bissau ~1M (few iPhones); Brazil small | yes (Brazil only) | Latin | nothing |
| Italian | 5 | Italy ~2.5M, a growing second generation | yes | Latin | Arabic, Urdu, Bangla for parents |
| Gujarati | 5 | Gujarat ~6M, nearly all Sunni: Memon, Sunni Vohra, Ghanchi | no | Gujarati (new) | Urdu, in part |
| Swedish | 6 | Sweden ~800K | yes | Latin | Arabic for many parents |
| Thai | 6 | Thailand ~3 to 4M | yes | Thai (no spaces between words) | Malay in the far south |
| Kazakh | 6 if downloads show it | Kazakhstan ~13M; iPhone language, NO App Store listing | no | Cyrillic | Russian |
| Croatian, written for Bosniaks | 6 if downloads show it | Bosnia ~2M, the Sandžak | no | Latin, one/few/other | German (diaspora) |
| Danish, Norwegian, Finnish | on request | ~300K, ~200K, ~100K | yes | Latin | Arabic, Turkish |
| Kannada, Marathi, Telugu | on request | many Muslims there read Urdu | no | three new scripts | Urdu |
| Ukrainian | on request | Crimean Tatars ~250K | no | Cyrillic, few/many | Russian |
| Hebrew | on request | Arab citizens read Arabic | yes | right to left | Arabic |

This replaced the order given on 2026-11-20 (Italian, Swedish, Portuguese, Gujarati): Gujarati moved ahead of
Swedish on first-language readers. Each round pairs Latin-script languages with one new script.

**Leave out:** Chinese (Simplified): Apple pulled Quran apps from the China App Store in 2021. Punjabi: Apple's is
Gurmukhi (Sikh readers); Pakistan's Punjabis read Urdu. Japanese, Korean, Traditional Chinese, Vietnamese,
Polish, Czech, Slovak, Hungarian, Romanian, Greek, Bulgarian, Lithuanian, Catalan, Slovenian, Odia: small Muslim
readerships, mostly served by a shipped language. Persian, Pashto, Swahili, Hausa, Somali, Uzbek, Azerbaijani,
Albanian, Bosnian, Kurdish: neither an iPhone language nor an App Store listing language; revisit when Apple adds one.
The app is Sunni-only (no Tehran method), which also rules out an Iran-first Persian.

## Decisions to settle in the glossary, before any batch

- **Portuguese**: one `pt` in Brazilian Portuguese (recommended: Siri speaks Brazil's), or European for
  Mozambique and Guinea-Bissau. First launch the simulator with `-AppleLanguages (pt-PT)` and confirm a Portugal
  phone picks up a Brazilian `pt`. A `pt-PT` slice for the words that differ (ecrã, ficheiro) can follow.
- **Gujarati**: Sunni usage (Memon, Sunni Vohra, Ghanchi), not the Bohras' (Ismaili Shia). Batches can carry the
  reviewed Hindi and Urdu as references, the way Hindi carried the Urdu. Catalog tool: Gujarati letters
  U+0A80 to U+0AFF, Gujarati digits rejected, the Latin full stop. Code: `spacesLetters` and
  `siriSpeaksInterfaceLanguage` false.
- **Thai**: no spaces between words and no sentence-final full stop, so the catalog tool must demand neither; Thai
  digits rejected; one plural form (`other`), so no COUNT_NOUN rule. `spacesLetters` false; screenshots must
  check line breaks inside long words.
- **Kazakh**: Cyrillic (what phones show), not the planned Latin alphabet; reuse the Russian checks with ә ғ қ ң ө
  ұ ү һ і allowed. No store listing: the store page stays Russian.
- **Croatian for Bosniaks**: standard Croatian with the Islamic words Bosnian Muslims use (namaz, abdest, džuma,
  Kur'an); one/few/other plurals need Russian-style forms. Only if Bosnia shows up in downloads.
- **Italian, Swedish**: the Dutch/German pattern (imperative buttons, NOT_ENGLISH words of their own, Siri).

## Runbook for a round

A round of three languages costs about 70 agents. Start early in the usage week, or run two languages. A
killed agent (usage limit, network drop) resumes by SendMessage to its id; it carries on from its own files.

1. **Before anything**: the previous round committed (Abu's call), downloads by territory checked, the language
   decisions above settled.
2. **Kit to the scratchpad**: `cp -R Scripts/Localization "<scratchpad>/l10n"` and work there, never inside the
   repo (the last round's work folder reached 271 MB). Back up `Resources/Localizable.xcstrings`,
   `Resources/InfoPlist.xcstrings`, `Scripts/localize_catalog.py` and the guide into it first.
3. **Catalog tool** (`Scripts/localize_catalog.py`): `LANGUAGES`; `LATIN_LANGUAGES` + `NOT_ENGLISH`, or
   `NATIVE_LETTER` + `SCRIPT_NAME` + `NATIVE_DIGIT`; `PLURAL_FORMS`, `REQUIRED_PLURALS`, `WORD_FORMS`;
   `COUNT_NOUN`; the `--lang` docstring. `validate` must understand the language before any batch is checked.
4. **Code**: `iPhone/Helpers/System/Localization.swift` (`spacesLetters`, `siriSpeaksInterfaceLanguage` and
   their doc comments); `knownRegions` in `Al-Islam.xcodeproj/project.pbxproj`; `UnitTests/LocalizationCoverageTests.swift`
   (languages, the left-to-right surah-meaning list, Siri expectations); `../sync_localization.py` `APP_WORD`.
5. **Kit entries**: `BRIEF.md` (the language list and per-language rules), `make_tasks.py` (`WHO`, `GLOSS`),
   `build_merge.py` (`prophet.idris` / `prophet.ishaq`, article-only keys added by hand), `siri/write_strings.py`
   (`NAMES`).
6. **Glossary**: one agent per language from `prompts/1-glossary.md` writes `GLOSSARY_<code>.md` with binding
   "Fixed terms", letter names and Apple's own terms. Read it before the batches start.
7. **Batches**: `./Scripts/localize_catalog.py todo ~/Library/Developer/Xcode/DerivedData/Al-Islam-<hash>
   "<kit>/<code>/todo" --lang <code> --like-ar --words 8300` after a build of the whole scheme (pass `-` for the
   DerivedData to skip file names). 19 files; 001 to 008 are the lessons.
8. **Labels**: one agent per language from `prompts/2-labels.md` turns `labels_todo.json` (331 items) into
   `<code>/labels.json`. Lesson batches 001 to 008 can start at the same time.
9. **Task files**: `python3 make_tasks.py <code> notes_<code>.json` writes `tasks/<code>_NNN.md` (notes: the
   labels' wider choices, the 010/016/017 notes, the Siri note for 019). One agent per batch, prompt: "Read your
   task file <path> and follow it exactly."
10. **Assemble**: `python3 assemble.py <code>` (coverage per batch), then `python3 labelcheck.py <code>`.
11. **Review**: one agent per language from `prompts/5-review.md` (with `REVIEW.md`) writes
    `<code>/review_patch.json`. Give it the counted variants: quoted controls, terms that drifted between batches.
12. **Merge**: from the kit folder `python3 build_merge.py <code>`, then from the repo
    `./Scripts/localize_catalog.py validate --lang <code> <kit>/<code>/merge.json`, `merge`, and `check` for
    EVERY language (0 problems each).
13. **InfoPlist.xcstrings**: CFBundleDisplayName (Al-Islam), the three location prompts, the photo prompt.
14. **Siri**, if Siri speaks it: `siri/<code>.json` (one phrase per English phrase, `${applicationName}`,
    `${surah}`, `${prayer}` kept), `python3 siri/write_strings.py <code>`, `siri/check.py`; add both
    AppShortcuts.strings (iPhone, Watch) to the variant groups in the pbxproj.
15. **Listings**: per language `prompts/7-listings.md` (Al-Islam in `Docs/App Store/<Language> Listing.md`, the
    siblings in `~/Downloads/Islam/sibling-staging/<App>-iOS/Docs/`), then `prompts/8-listing-count.md` for every
    older listing; `glosscheck.py` compares listing terms with the catalog.
16. **Verify**: build and unit tests (memory `xcode-build-and-sim-workflow`: DEVELOPER_DIR, default DerivedData,
    the iPhone 17 Pro), then screenshots with `-AppleLanguages (<code>)` of the tabs, Settings, Quran settings
    and the letter banner. Launch twice after a fresh install. Look for cut-off labels.
17. **Docs**: the Localization Guide (intro, Where things live, Siri, `--lang`, the check paragraph, a section
    for the round, Still open), a memory file for the round, and this roadmap's tables.
18. **Stop**: report, leave everything uncommitted, and commit only when Abu asks in that message and says yes
    to the summary.

## Lessons from the rounds

- Put every rule that settled mid-run into the brief and glossary up front: a choice made mid-round has to be
  repaired in every finished batch.
- Tips in batches 017 to 019 quote controls whose batches are not done yet; the review aligns every quote with
  the control key's value.
- The tips search reads the DISPLAYED text, so the tip-search hint examples must be in the interface language.
- zsh python3 heredocs reject non-Latin scripts ("Non-UTF-8 code"): write scripts to files with a coding line.
  `cat > file` with no heredoc waits on input forever.
- Every round rewrote the language count in all older listings (34 files last time, 45 next): drop the count
  from What's New, or generate that line.
- Upkeep grows with every language: each new English string needs 14 translations now. Plan a small pass per
  release over every language, glossaries and labels binding.
- The watch app has a size ceiling: App Store Connect refuses one over 75 MB after thinning (ITMS-90389 on
  build 271, 2026-11-23, at 95 MB). The extensions now ship only their share of the catalog (Localization
  Guide, "Each extension's share"): the watch about 54 MB with 14 languages, about 1.9 MB more per language.
  Measure it after each round (a Release build of the WatchOnly scheme, binaries stripped and thinned to one
  architecture).

## Before release

- Fluent reviewers for every shipped language, Arabic and Urdu first: give each the glossary and screenshots,
  not the catalog.
- Apple's Tamil and Malayalam words for "Time Sensitive" and "Spoken Content", checked on a phone.
- The 4.6.7 section of the English `Docs/App Store/Whats New.md` (its top is still 4.6.6).
- The sibling listings in `~/Downloads/Islam/sibling-staging` installed; their catalogs sync.
- Transients to watch: a fresh install's first launch under Malayalam once came up English; a travel
  notification after a quick language switch can name a city in the previous language.
