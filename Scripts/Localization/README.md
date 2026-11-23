# Localization kit

The files the language rounds of 2026-11-19 to 11-21 ran from, saved out of a temporary scratchpad. The runbook
that uses them is [Docs/Engineering/Localization Roadmap.md](../../Docs/Engineering/Localization%20Roadmap.md).
Copy this folder to a scratchpad and run a round there, never here: a round's work folders reach hundreds of MB.

| File | What it is |
| --- | --- |
| `BRIEF.md` | The batch translators' brief, last used for ml/ta/nl: rules, output format, validation. Retarget its language list for a new round. |
| `BRIEF_hideses.md`, `BRIEF_frbnru.md` | The briefs of the hi/de/es and fr/bn/ru rounds (their language-specific rules). |
| `GLOSSARY_<code>.md` | Each language's binding terms (bn de es fr hi id ml ms nl ru ta tr; Arabic and Urdu predate the kit). Also what a fluent reviewer starts from. |
| `labels_todo.json` | The 331 fixed labels (tab, page, button, tone names) with the files and example sentences that name them. |
| `feature_labels.json` | The label keys alone. |
| `labels/<code>.json` | Each language's agreed labels. Copy to `<code>/labels.json` to rerun that language. |
| `make_tasks.py` | Writes `tasks/<code>_NNN.md`, one task file per batch; add the language to `WHO` and `GLOSS`. |
| `notes_<code>.json` | Example per-batch notes for `make_tasks.py` (labels, 010, 016, 017, 019). |
| `assemble.py` | Joins `<code>/out/*.json`, the labels and `overrides/` into `<code>/final.json`; reports coverage. |
| `labelcheck.py` | Sentences that name a label without its agreed wording (accepts ml/ta case endings). |
| `build_merge.py` | `final.json` + `review_patch.json` + the two prophet names into `merge.json`; add the language. |
| `glosscheck.py` | Compares the term tables in store listings with the catalog (edit its `langs`). |
| `REVIEW.md` | The review agent's instructions; `REVIEW_frbnru.md` the earlier version. |
| `REVIEW_NOTES*.md` | What batch translators reported per round: choices and drift, useful to a fluent reviewer. |
| `prompts/` | The exact prompts of the Dutch round's glossary, labels, review, listings and listing-count agents. |
| `siri/` | Siri phrases per language (`<code>.json`), `write_strings.py` (writes the iPhone and Watch AppShortcuts.strings), `check.py`. |

Paths inside the prompts and some scripts point at the old scratchpad or at this checkout: swap them for yours.
