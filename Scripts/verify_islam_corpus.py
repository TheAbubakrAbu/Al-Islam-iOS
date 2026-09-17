#!/usr/bin/env python3
"""Gate the Islam-tab article corpus. Non-zero exit means do not ship the pack.

Checks, in order of what has actually gone wrong while building it:
  1. the pack inflates, parses, and every article has a title and prose;
  2. every article view that the source files expose is IN the pack (a new page
     that never reaches the corpus is the silent failure this exists to catch);
  3. every id in the pack has a case in IslamArticles.destination(for:), so a
     cited article always reopens instead of rendering a dead row;
  4. no article's prose still carries Swift escapes or markdown emphasis, which
     would reach the model as literal "**" and "\\u{2026}";
  5. every catalog article's view tags its list with its own id
     (`.selectableArticleList(article: "XView")`), which is what gives the page
     its search bar;
  6. every catalog article's view carries exactly one `ArticleSourcesSection`
     naming ITSELF (a 2026-09 injection had shifted them one article along, so
     Shahadah listed Salah's sources);
  7. every Quran quote is a reference (`ScriptureQuote(quran:)` / `.ayah(`) the
     app can render, and none is carried as a literal copy of the ayah;
  8. every hadith reference (`ScriptureQuote(hadith:)` / `.hadith(`) names a row
     of the bundled shelf and its token ranges lie inside that row;
  9. no literal quote (`ScriptureQuote(text:)` / `.quote(`) carries, word for
     word, a narration the shelf holds under its citation (Abu's rule: one copy
     of a hadith, on the shelf; the articles reference it);
 10. the Watch's copy of the referenced rows (HadithQuotes.json.deflate, the
     only target without the .hpk shelf) is byte-identical to a fresh build.
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

# 5/6: the pages themselves - their search tag and their own sources section.
catalog_ids = set(re.findall(r'\("(\w+View)", "', (ROOT / "iPhone/Islam/IslamSearch.swift").read_text()))
check(len(catalog_ids) >= 45, f"only {len(catalog_ids)} catalog ids found in IslamSearch.swift")
struct_re = re.compile(r"^struct (\w+): View \{", re.M)
seen = set()
for path in builder.SOURCES:
    src = path.read_text()
    bounds = [(m.group(1), m.start()) for m in struct_re.finditer(src)] + [("", len(src))]
    for (name, start), (_, end) in zip(bounds, bounds[1:]):
        if name not in catalog_ids:
            continue
        seen.add(name)
        body = src[start:end]
        check(f'.selectableArticleList(article: "{name}"' in body,
              f"{name}: no .selectableArticleList(article:) tag - the page gets no search bar")
        sources = re.findall(r'ArticleSourcesSection\(article: "(\w+)"\)', body)
        check(sources == [name], f"{name}: sources section names {sources}, must be exactly its own")
check(seen == catalog_ids, f"catalog ids without a view struct in the article files: {sorted(catalog_ids - seen)}")

# 7: every Quran quote is a reference the app can render. The articles carry no copy of an ayah
# (`ScriptureQuote(quran:)` / `.ayah(` since 2026-09-16); a reference outside this app's Quran, or
# a `words` range outside the cited ayahs, would render as a bare citation, so it does not ship.
references = builder.quran_references()
check(len(references) >= 700, f"only {len(references)} Quran references found - the article regex probably stopped matching")
for file_name, line, reference, words in references:
    try:
        builder.quran_quote(reference, words)
    except SystemExit as error:
        check(False, f"{file_name}:{line}: {error}")
literal_quran = []
for path in builder.SOURCES:
    src = path.read_text()
    for m in builder.QUOTE_RE.finditer(src):
        if re.search(r"\(Quran\s+\d+:\d+", m.group(1)):
            literal_quran.append(f"{path.name}:{src.count(chr(10), 0, m.start()) + 1}")
check(not literal_quran, f"Quran quotes carried as literals instead of references: {literal_quran[:10]}")

# 8: every hadith reference is a shelf row and its ranges are inside it.
from hadith_spans import shelf_link, match  # noqa: E402

hadith_refs = builder.hadith_references()
check(len(hadith_refs) >= 550, f"only {len(hadith_refs)} hadith references found - the article regex probably stopped matching")
for file_name, line, args in hadith_refs:
    try:
        builder.hadith_quote(args)
    except SystemExit as error:
        check(False, f"{file_name}:{line}: {error}")

# 9: a literal quote must not be a copy of a row the shelf holds under its citation.
LITERAL_RE = re.compile(r"(?:ScriptureQuote|(?<!\w)\.quote)\(\s*text:\s*(" + builder.STR + r")(?:\s*,\s*arabic:\s*(" + builder.STR + r"))?", re.S)
CITE_RE = re.compile(r"\(([^()]*(?:\([^()]*\)[^()]*)*)\)\.?\s*$")
copies = []
for path in builder.SOURCES:
    src = path.read_text()
    for m in LITERAL_RE.finditer(src):
        text = builder.unquote(m.group(1))
        arabic = builder.unquote(m.group(2)) if m.group(2) else ""
        cm = CITE_RE.search(text)
        if not cm:
            continue
        link = shelf_link(cm.group(1).split(";")[0])
        if not link:
            continue
        found = match(link[0], link[1], arabic, text[:cm.start()].strip())
        if found and (found[1] is not None or found[2] is not None):
            copies.append(f"{path.name}:{src.count(chr(10), 0, m.start()) + 1}")
check(not copies, f"literal hadith quotes that are on the shelf word for word (make them references): {copies[:10]}")

# 10: the Watch's derived copy of the referenced rows is what a rebuild produces.
wspec = importlib.util.spec_from_file_location("build_hadith_quotes_pack", ROOT / "Scripts/build_hadith_quotes_pack.py")
watch_pack = importlib.util.module_from_spec(wspec)
with contextlib.redirect_stdout(io.StringIO()):
    wspec.loader.exec_module(watch_pack)
fresh = watch_pack.build()
check(watch_pack.OUT.exists() and watch_pack.OUT.read_bytes() == fresh,
      f"{watch_pack.OUT.relative_to(ROOT)} is stale - run ./Scripts/build_hadith_quotes_pack.py")

if failures:
    for f in failures:
        print(f"FAIL {f}")
    sys.exit(1)
print(f"islam corpus OK: {len(articles)} articles, "
      f"{sum(len(s['text']) for a in articles for s in a['sections'])} chars, "
      f"{PACK.stat().st_size} bytes packed")
