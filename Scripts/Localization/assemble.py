#!/usr/bin/env python3
"""Assemble one language's translation: every finished batch (out/NNN.json or out/NNN.partK.json), then the
binding labels and the overrides on top. Writes <lang>/final.json and reports coverage against the todo."""
import json, glob, os, re, sys
SP = os.path.dirname(os.path.abspath(__file__))
lang = sys.argv[1]
todo = {}
for f in sorted(glob.glob(f"{SP}/{lang}/todo/todo_*.json")):
    n = re.search(r"todo_(\d+)", f).group(1)
    for it in json.load(open(f, encoding="utf-8")):
        todo[it["key"]] = n
out, seen_batches, dupes = {}, {}, 0
for f in sorted(glob.glob(f"{SP}/{lang}/out/*.json")):
    n = os.path.basename(f).split(".")[0]
    try:
        d = json.load(open(f, encoding="utf-8"))
    except ValueError:
        print(f"skip {os.path.basename(f)}: not valid JSON yet"); continue
    if not isinstance(d, dict) or any(k not in todo for k in list(d)[:5]):
        print(f"skip {os.path.basename(f)}: not keyed by catalog keys (work in progress?)"); continue
    for k, v in d.items():
        if k in out and out[k] != v: dupes += 1
        out[k] = v
    seen_batches.setdefault(n, 0); seen_batches[n] += len(d)
labels = json.load(open(f"{SP}/{lang}/labels.json", encoding="utf-8"))
relabeled = sum(1 for k, v in labels.items() if k in out and out[k] != v)
out.update({k: v for k, v in labels.items() if k in todo})
for f in glob.glob(f"{SP}/overrides/*.{lang}.json"):
    out.update(json.load(open(f, encoding="utf-8")))
# Hindi: one spelling of each nukta letter (base + U+093C, Unicode's NFC), whatever a batch's tools wrote. The
# Devanagari runs only: NFC on a whole value would recompose its Arabic, which must stay as the key has it.
if lang == "hi":
    import unicodedata
    dev = re.compile("[\u0900-\u097F]+")
    nfc = lambda v: dev.sub(lambda m: unicodedata.normalize("NFC", m.group(0)), v)
    out = {k: ({f: nfc(x) for f, x in v.items()} if isinstance(v, dict) else nfc(v)) for k, v in out.items()}
missing = {}
for k, n in todo.items():
    if k not in out: missing.setdefault(n, []).append(k)
json.dump(out, open(f"{SP}/{lang}/final.json", "w", encoding="utf-8"), ensure_ascii=False, indent=0)
print(f"[{lang}] {len(out)} of {len(todo)} keys; {relabeled} label values replaced by labels.json; "
      f"{dupes} keys translated twice differently")
for n in sorted(set(todo.values())):
    tot = sum(1 for v in todo.values() if v == n)
    print(f"  batch {n}: {tot - len(missing.get(n, []))}/{tot}")
