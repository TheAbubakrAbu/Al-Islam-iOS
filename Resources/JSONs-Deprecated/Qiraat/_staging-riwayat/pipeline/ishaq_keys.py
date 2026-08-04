#!/usr/bin/env python3
"""Learn the Ishaq/Idris volumes' private glyph keys (~31k unresolved occurrences).

Khalaf al-Ashir's text is overwhelmingly identical to Hamzah's - and we have our own
decoded Khalaf an Hamzah. Align the Ishaq token stream against that text with known
keys pinned by the deterministic map; whatever consistently lands on the unknown keys
is their emission. High-purity results go into manualmap.json (gids are global)."""
import json, math, collections, pathlib, sys
BASE = pathlib.Path(__file__).resolve().parent
DATA = BASE / "data"
sys.path.insert(0, str(BASE))
from final import build_detmap
import hybrid

detmap = build_detmap("kufi")
khalaf = json.loads(pathlib.Path(
    "/Users/theabubakrabu/Library/Mobile Documents/com~apple~CloudDocs/Projects/(1) iOS/Al-Islam-iOS/Resources/JSONs-Deprecated/Qiraat/_staging-riwayat/khalaf.json").read_text())

class _EM:
    def logp(self, key, e):
        v = detmap.get(key)
        if v is not None:
            if e == v: return -0.05
            if v == "" and e == "": return -0.05
            return -14.0
        if key == "sp| ":
            return math.log(0.8) if e == " " else (math.log(0.15) if e == "" else -16.0)
        L = len(e)   # unknown key: open emission, mildly favoring 1-2 chars
        return (-6.0, -2.2, -3.0, -5.0, -8.0)[L] if L <= 4 else -10.0 - L

hybrid.ALIGN_EM = _EM()
seg = json.load(open(DATA / "ishaq.surahs.json"))
obs = collections.defaultdict(collections.Counter)
for sid in range(1, 115):
    vol = seg["data"][sid - 1]
    ref = khalaf[str(sid)]
    if len(vol) != len(ref):
        continue
    for k_i, (glyphs, refa) in enumerate(zip(vol, ref)):
        keys = [("sp| " if f == "sp" else f"{f}|{c}") for f, c in glyphs]
        unknown = [k for k in keys if k not in detmap and k != "sp| "]
        if not unknown:
            continue
        text = refa["text"]
        if k_i == 0 or not text:
            continue
        spans = hybrid.align_surah(keys, text, band=45)
        if spans is None:
            continue
        for i, k in enumerate(keys):
            if k in detmap or k == "sp| ":
                continue
            obs[k][text[spans[i][0]:spans[i][1]]] += 1

manual = json.loads((DATA / "manualmap.json").read_text())
added = 0
report = []
for k, ctr in sorted(obs.items(), key=lambda x: -sum(x[1].values())):
    tot = sum(ctr.values())
    e, n = ctr.most_common(1)[0]
    if tot >= 8 and n / tot >= 0.65:
        manual[k] = e
        added += 1
        report.append((k, e, n, tot))
    else:
        report.append((k, None, ctr.most_common(3), tot))
json.dump(manual, open(DATA / "manualmap.json", "w"), ensure_ascii=False, indent=1)
print(f"learned {added} keys from {len(obs)} unknown; top 20:")
for k, e, n, tot in report[:20]:
    print(f"  ×{tot:<6} {k[:44]:<44} -> {e!r}" + (f" ({n})" if e else ""))
