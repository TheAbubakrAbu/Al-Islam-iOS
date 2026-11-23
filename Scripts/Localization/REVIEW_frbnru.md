# Consistency review of one language

Twenty translators each translated one batch of the Al-Islam app's ~13,600 interface strings. Each batch is
fine on its own; what no single translator could see is the whole. You review the WHOLE assembled
translation for drift between batches, and fix it.

Files (`<code>` is your language):
- `<scratch>/l10n/<code>/final.json`: every translation, {English key: translation}. READ-ONLY.
- `<scratch>/l10n/<code>/labels.json`: the agreed labels (binding).
- `<scratch>/l10n/<code>/label_misses.json`: sentences that name a label without its agreed wording.
- `<scratch>/l10n/<code>/todo/todo_*.json`: the input items with the `files` that show each key (context).
- `<scratch>/l10n/BRIEF.md` and `GLOSSARY_<code>.md`: the rules every translator followed.

Write ONE file, `<scratch>/l10n/<code>/review_patch.json`: {key: corrected translation} for every value you
change, and nothing else. Never edit final.json or the repository. Validate the patch from
/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS with `./Scripts/localize_catalog.py validate --lang <code>
<patch>` until 0 rejected. Work with python3 scripts (the file is large): search, list, then fix.

## What to do

1. **Label misses.** For each entry in label_misses.json, decide: a real reference to the control (fix the
   sentence so it carries the agreed wording exactly) or the same English word in another sense (leave it).
2. **The terms your task lists below.** Find every variant, choose as instructed, and rewrite each affected
   value so it reads naturally (do not blind-replace: a sentence that uses both senses of a word needs care).
3. **Other drift you find**, within reason: the same short English label or screen name translated two
   different ways across files (for example a settings row and the sentence that tells you to tap it), the
   same recurring phrase translated inconsistently, an obvious typo. Prefer the majority wording or the one
   the label/control itself uses. Do not restyle text that is merely different but fine.
4. Keep every rule of BRIEF.md (placeholders, Arabic byte for byte, no em dash, edge spaces).

Final message: the patch path, how many values it changes, the validator's last line, and a short list of
the decisions you made (term -> chosen wording, with counts). Nothing else.
