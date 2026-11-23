#!/usr/bin/env python3
"""Sentences that name one of the fixed labels but do not carry its agreed wording, per language."""
import json, re, sys, os
SP = os.path.dirname(os.path.abspath(__file__))
lang = sys.argv[1]
final = json.load(open(f"{SP}/{lang}/final.json", encoding="utf-8"))
final = {k: (" | ".join(v.values()) if isinstance(v, dict) else v) for k, v in final.items()}
labels = json.load(open(f"{SP}/{lang}/labels.json", encoding="utf-8"))
def inflected(agreed, value):
    """Malayalam and Tamil glue a case ending to the label's last word, and the sandhi changes its last letter or
    two (அம்ர் -> அம்ரின், വസ്ല് -> വസ്ലിന്, ആയത്ത് -> ആയത്തിൽ): accept the label with its last word's final
    two letters dropped, when the word keeps at least three."""
    if lang not in ("ml", "ta"):
        return False
    head, _, last = agreed.rpartition(" ")
    if len(last) < 5:
        return False
    stem = (head + " " if head else "") + last[:-2]
    return stem in value
out = {}
for label, agreed in labels.items():
    if len(label.split()) < 2 or label == agreed:
        continue  # one-word labels match ordinary words; names stay as they are
    pat = re.compile(r"(?<![\w])" + re.escape(label) + r"(?![\w])")
    for key, value in final.items():
        if key == label or not pat.search(key):
            continue
        if any(other != label and label in other and other in key for other in labels):
            continue  # a longer label holds it
        if agreed.lower() not in value.lower() and not inflected(agreed, value):
            out.setdefault(label, []).append(key)
n = sum(len(v) for v in out.values())
print(f"[{lang}] {n} sentences miss the agreed wording of {len(out)} labels")
json.dump({"labels": {l: labels[l] for l in out}, "misses": out}, open(f"{SP}/{lang}/label_misses.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
for l, ks in sorted(out.items(), key=lambda x: -len(x[1]))[:12]:
    print(f"  {l!r} -> {labels[l]!r}: {len(ks)}")
