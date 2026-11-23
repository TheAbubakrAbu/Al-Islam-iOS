import json, re, os, sys
from collections import Counter
src = "/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Resources/ar.lproj/AppShortcuts.strings"
keys = re.findall(r'^"((?:[^"\\]|\\.)*)"\s*=', open(src, encoding="utf-8").read(), re.M)
print("source keys:", len(keys), "unique:", len(set(keys)))
here = os.path.dirname(os.path.abspath(__file__))
tok = re.compile(r"\$\{[A-Za-z]+\}")
ok = True
for lang in ("fr", "ru"):
    d = json.load(open(os.path.join(here, lang + ".json"), encoding="utf-8"))
    missing = [k for k in keys if k not in d]
    extra = [k for k in d if k not in keys]
    badtok = [k for k in keys if k in d and Counter(tok.findall(k)) != Counter(tok.findall(d[k]))]
    dup = [v for v, c in Counter(d.values()).items() if c > 1]
    dash = [v for v in d.values() if "\u2014" in v or "&mdash;" in v or "&#8212;" in v]
    print(lang, "count", len(d), "missing", missing, "extra", extra, "badtok", badtok, "dup", dup, "emdash", dash)
    ok &= not (missing or extra or badtok or dup or dash)
print("OK" if ok else "FAIL")
