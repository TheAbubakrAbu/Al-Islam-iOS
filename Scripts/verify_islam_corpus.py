#!/usr/bin/env python3
"""Gate the Islam-tab article corpus. Non-zero exit means do not ship the pack.

Checks, in order of what has actually gone wrong while building it:
  1. the pack inflates, parses, and every article has a title and prose;
  2. every article view that the source files expose is IN the pack (a new page
     that never reaches the corpus is the silent failure this exists to catch);
  3. every id in the pack has a case in IslamArticles.destination(for:), so a
     cited article always reopens instead of rendering a dead row;
  4. no article's prose still carries Swift escapes or markdown emphasis, which
     would reach the model as literal "**" and "\\u{2026}".
"""
import json
import re
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT / "Resources/Data/Islam/IslamArticles.json.deflate"
LOADER = ROOT / "iPhone/Islam/IslamArticles.swift"

sys.path.insert(0, str(ROOT / "Scripts"))
sys.argv = ["verify", "--print"]
import io
import contextlib
import importlib.util

spec = importlib.util.spec_from_file_location("build_islam_corpus", ROOT / "Scripts/build_islam_corpus.py")
builder = importlib.util.module_from_spec(spec)
with contextlib.redirect_stdout(io.StringIO()):
    spec.loader.exec_module(builder)

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


check(PACK.exists(), f"{PACK.relative_to(ROOT)} is missing - run ./Scripts/build_islam_corpus.py")
if PACK.exists():
    raw = zlib.decompressobj(-zlib.MAX_WBITS).decompress(PACK.read_bytes())
    pack = json.loads(raw)
    articles = pack["articles"]
    check(pack.get("version") == 1, f"unexpected pack version {pack.get('version')}")
    check(len(articles) >= 45, f"only {len(articles)} articles - the extractor probably stopped matching")

    for a in articles:
        where = a["id"]
        check(bool(a["title"].strip()), f"{where}: empty title")
        check(bool(a["sections"]), f"{where}: no sections")
        for s in a["sections"]:
            check(bool(s["text"].strip()), f"{where}/{s['heading']}: empty section")
            check("**" not in s["text"], f"{where}/{s['heading']}: markdown emphasis survived")
            check("\\u{" not in s["text"], f"{where}/{s['heading']}: unresolved unicode escape")
            check('\\"' not in s["text"], f"{where}/{s['heading']}: unresolved quote escape")

    # 2: the pack must not fall behind the source files.
    fresh = {a["id"] for a in builder.articles()}
    packed = {a["id"] for a in articles}
    check(fresh == packed,
          f"pack is stale - rebuild it (missing {sorted(fresh - packed)}, extra {sorted(packed - fresh)})")

    # 3: every article reopens.
    loader = LOADER.read_text()
    routed = set(re.findall(r'case "(\w+)": return AnyView\(', loader))
    check(packed <= routed, f"no destination case for {sorted(packed - routed)} in IslamArticles.swift")
    check(routed <= packed, f"IslamArticles.swift routes ids that are not in the pack: {sorted(routed - packed)}")

if failures:
    for f in failures:
        print(f"FAIL {f}")
    sys.exit(1)
print(f"islam corpus OK: {len(articles)} articles, "
      f"{sum(len(s['text']) for a in articles for s in a['sections'])} chars, "
      f"{PACK.stat().st_size} bytes packed")
