# -*- coding: utf-8 -*-
import json, sys, re, unicodedata
lang = sys.argv[1]
final = json.load(open(f'{lang}/final.json', encoding='utf-8'))
patch = json.load(open(f'{lang}/review_patch.json', encoding='utf-8'))
unknown = [k for k in patch if k not in final]
assert not unknown, unknown[:5]
final.update(patch)
manual = {"hi": {"prophet.idris": "इदरीस", "prophet.ishaq": "इसहाक़"},
          "de": {"prophet.idris": "Idris", "prophet.ishaq": "Ishaq"},
          "es": {"prophet.idris": "Idris", "prophet.ishaq": "Ishaq"},
          "nl": {"prophet.idris": "Idris", "prophet.ishaq": "Ishaq"},
          "ml": {"prophet.idris": "ഇദ്രീസ്", "prophet.ishaq": "ഇസ്ഹാഖ്"},
          "ta": {"prophet.idris": "இத்ரீஸ்", "prophet.ishaq": "இஸ்ஹாக்"}}[lang]
final.update(manual)
if lang == "hi":
    dev = re.compile("[ऀ-ॿ]+")
    nfc = lambda v: dev.sub(lambda m: unicodedata.normalize("NFC", m.group(0)), v)
    final = {k: ({f: nfc(x) for f, x in v.items()} if isinstance(v, dict) else nfc(v)) for k, v in final.items()}
json.dump(final, open(f'{lang}/merge.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(lang, len(final), 'keys,', len(patch), 'from the review')
