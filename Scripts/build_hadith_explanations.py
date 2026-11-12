#!/usr/bin/env python3
"""Link the shelf's narrations to the Hadith Encyclopedia's explanations, ahead of time.

    ./Scripts/build_hadith_explanations.py [--stats] [--inspect bukhari:1 ...]

Abu (2026-11-02): "bring hadith explanation". The Hadith Encyclopedia (hadeethenc.com, 2,328
narrations with a scholarly explanation and benefits; Resources/Data/Hadith/HadeethEnc.henc, see
build_hadeethenc_pack.py) is its own lane in the app; nothing joined it to the six books and the
compilations on the shelf. This script does the join once and ships it as
Resources/Data/Hadith/HadithExplanations.qpk, so a row asks a binary search ("Explanation" in its
menu, HadithExplanations.swift) and the app computes nothing.

How a row is matched (precision over coverage, as for the chains):
- Both texts are folded (marks, tatweel and punctuation out; hamza carriers to alef, ى to ي, ة to ه;
  the honorifics dropped) and cut into word trigrams.
- A shelf row carries an encyclopedia entry when the entry's trigrams are CONTAINED in the row's:
  60% of them for an entry of 8+ trigrams, 85% for a shorter one (4-7). Trigrams found in more than
  DF_CAP rows (the formulas: قال رسول الله ...) never score.
- The entry's takhrij (`reference`, e.g. "صحيح البخاري (2/ 74) (1258 - 1259). صحيح مسلم (2/ 646) (939)")
  names the printed numbers: a row of that book with that sunnah.com number is accepted at 40%.
- A row keeps its best entry only (one explanation per narration); an entry may explain many rows
  (al-Bukhari's, Muslim's and Riyad as-Salihin's copies of one hadith).

Pack (the app's container, QuranPackContainer, the HadithChains.qpk shape, read by `HadithRowBlock`):

  eager (LZFSE)  u32 books, then per book: string slug, u32 rows
  block n (LZMA) book n: u32 idInBook ascending, u32 offsets (rows + 1), the entry ids (ASCII) back to back

Also writes UnitTests/HadithExplanationSamples.swift (a handful of pins the test holds the pack to).
Rerun after any .hpk rebuild or encyclopedia rebuild.
"""
import re
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
import build_hadeethenc_pack as henc  # noqa: E402
import build_hadith_chains as chains  # noqa: E402
from islam_packs import HADITH_DIR, Hadith  # noqa: E402

OUT = ROOT / "Resources/Data/Hadith/HadithExplanations.qpk"
SAMPLES = ROOT / "UnitTests/HadithExplanationSamples.swift"

DF_CAP = 1500
LONG_MIN = 8
SCORE_LONG = 0.60
SCORE_SHORT = 0.85
SCORE_CITED = 0.40

MARKS = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـ]")
NOT_WORD = re.compile(r"[^\w\s]", re.U)
HONORIFICS = re.compile(
    r"صلى الله عليه وسلم|صلى الله عليه واله وسلم|عليه السلام|عليه الصلاه والسلام|رضي الله عنهما|رضي الله عنهم|"
    r"رضي الله عنها|رضي الله عنه|عز وجل|تبارك وتعالى|سبحانه وتعالى|تعالى"
)

BOOK_NAMES = {
    "bukhari": r"البخاري",
    "muslim": r"(?<!ال)مسلم",
    "abudawud": r"أبي داود|أبو داود|ابي داود|ابو داود",
    "tirmidhi": r"الترمذي",
    "nasai": r"النسائي",
    "ibnmajah": r"ابن ماجه|ابن ماجة",
}


def fold(text):
    text = MARKS.sub("", text or "")
    text = (text.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ٱ", "ا")
            .replace("ى", "ي").replace("ة", "ه").replace("ؤ", "و").replace("ئ", "ي"))
    text = NOT_WORD.sub(" ", text)
    text = HONORIFICS.sub(" ", text)
    return text.split()


def shingles(words, n=3):
    return {" ".join(words[i:i + n]) for i in range(len(words) - n + 1)}


def cited_numbers(reference):
    """{slug: {printed numbers}} named by a takhrij line. Volume/page pairs "(2/ 74)" are dropped,
    short ranges "1258 - 1259" expanded, everything else in the book's own line kept."""
    out = defaultdict(set)
    for line in re.split(r"[\n؛;]", reference or ""):
        line = re.sub(r"\(\s*\d+\s*/\s*\d+\s*\)", " ", line)
        for slug, pattern in BOOK_NAMES.items():
            if not re.search(pattern, line):
                continue
            for a, b in re.findall(r"(\d{1,5})\s*[-–]\s*(\d{1,5})", line):
                a, b = int(a), int(b)
                if 0 < b - a <= 6:
                    out[slug].update(range(a, b + 1))
            for number in re.findall(r"\d{1,5}", line):
                out[slug].add(int(number))
    return out


def read_encyclopedia():
    """The app's own pack, as `read_pack` hands it back: {"id", "cats", "ar": {...}, "en": {...}}."""
    entries = []
    for record in henc.read_pack()["full"]:
        entries.append({
            "id": record["id"],
            "body": record["ar"].get("body", ""),
            "intro": record["ar"].get("intro", ""),
            "reference": record["ar"].get("reference", ""),
            "title": record["en"].get("title", ""),
        })
    return entries


def read_shelf():
    rows = []
    for path in sorted(HADITH_DIR.glob("*.hpk")):
        book = Hadith(path.stem)
        for index, row in enumerate(book.rows):
            item = book.item(index)
            rows.append((path.stem, row.idInBook, row.citation, item.arabic))
    return rows


def base_number(citation):
    match = re.match(r"(\d+)", citation or "")
    return int(match.group(1)) if match else None


def match(entries, rows):
    row_shingles = []
    index = defaultdict(set)
    for r, (slug, id_in_book, citation, arabic) in enumerate(rows):
        s = shingles(fold(arabic))
        row_shingles.append(s)
        for sh in s:
            index[sh].add(r)
    df = {sh: len(ids) for sh, ids in index.items()}

    best = {}      # row index -> (score, entry id, how)
    linked_entries = set()
    for entry in entries:
        words = fold(entry["intro"] + " " + entry["body"]) if entry["intro"] else fold(entry["body"])
        s_entry = {sh for sh in shingles(words) if df.get(sh, 0) <= DF_CAP}
        cited = cited_numbers(entry["reference"])
        if len(s_entry) < 4 and not cited:
            continue
        counts = Counter()
        for sh in s_entry:
            for r in index.get(sh, ()):
                counts[r] += 1
        threshold = SCORE_LONG if len(s_entry) >= LONG_MIN else SCORE_SHORT
        candidates = set(counts)
        # Cited rows join the candidates even when they share few trigrams.
        if cited:
            for r, (slug, id_in_book, citation, arabic) in enumerate(rows):
                if slug in cited and base_number(citation) in cited[slug]:
                    candidates.add(r)
        for r in candidates:
            slug, id_in_book, citation, arabic = rows[r]
            shared = counts.get(r, 0)
            score = shared / len(s_entry) if s_entry else 0.0
            is_cited = slug in cited and base_number(citation) in cited[slug]
            if is_cited and score >= SCORE_CITED:
                how = "cited"
            elif score >= threshold and len(s_entry) >= 4:
                how = "text"
            else:
                continue
            current = best.get(r)
            if current is None or (score, how == "cited") > (current[0], current[2] == "cited"):
                best[r] = (score, entry["id"], how)
                linked_entries.add(entry["id"])
    return best, linked_entries


def write_pack(rows, best):
    books = defaultdict(dict)
    for r, (score, entry_id, how) in best.items():
        slug, id_in_book, _, _ = rows[r]
        books[slug][id_in_book] = (entry_id,)
    order = sorted(books)
    eager = bytearray(struct.pack("<I", len(order)))
    blocks = []
    total = 0
    for slug in order:
        raw, packed_rows = chains.book_block(books[slug])
        blocks.append(raw)
        eager += chains.packed_string(slug) + struct.pack("<I", len(packed_rows))
        total += len(packed_rows)
    chains.write_container(OUT, eager, blocks, len(order), total)
    # Read back as the app will.
    eager_back, blocks_back, _ = chains.read_container(OUT)
    (count,) = struct.unpack_from("<I", eager_back, 0)
    assert count == len(order), count
    for slug, raw in zip(order, blocks_back):
        n = len(books[slug])
        ids = struct.unpack_from(f"<{n}I", raw, 0)
        offsets = struct.unpack_from(f"<{n + 1}I", raw, 4 * n)
        payload = raw[4 * n + 4 * (n + 1):]
        for i, id_in_book in enumerate(ids):
            assert payload[offsets[i]:offsets[i + 1]].decode("ascii") == books[slug][id_in_book][0]
    return order, total


def write_samples(rows, best, order):
    picks = []
    by_slug = defaultdict(list)
    for r, (score, entry_id, how) in sorted(best.items()):
        slug, id_in_book, _, _ = rows[r]
        by_slug[slug].append((id_in_book, entry_id))
    for slug in order:
        for id_in_book, entry_id in sorted(by_slug[slug])[:2]:
            picks.append((slug, id_in_book, entry_id))
    lines = [
        "// Generated by Scripts/build_hadith_explanations.py. Do not edit.",
        "// A few of the shelf's narrations and the encyclopedia entry that explains each, exactly as",
        "// HadithExplanations.qpk holds them (HadithExplanationsTests).",
        "enum HadithExplanationSamples {",
        "    static let picks: [(slug: String, idInBook: Int, entry: String)] = [",
    ]
    for slug, id_in_book, entry_id in picks:
        lines.append(f'        (slug: "{slug}", idInBook: {id_in_book}, entry: "{entry_id}"),')
    lines += ["    ]", f"    static let linkedRows = {len(best)}", "}", ""]
    SAMPLES.write_text("\n".join(lines), encoding="utf-8")


def main():
    args = sys.argv[1:]
    entries = read_encyclopedia()
    rows = read_shelf()
    best, linked_entries = match(entries, rows)
    if "--inspect" in args:
        wanted = set(args[args.index("--inspect") + 1:])
        for r, (score, entry_id, how) in best.items():
            slug, id_in_book, citation, arabic = rows[r]
            if f"{slug}:{id_in_book}" in wanted:
                entry = next(e for e in entries if e["id"] == entry_id)
                print(f"{slug}:{id_in_book} ({citation}) -> {entry_id} {how} {score:.2f}")
                print("  row  :", " ".join(fold(arabic))[:160])
                print("  entry:", " ".join(fold(entry['body']))[:160])
        return
    per_book = Counter(rows[r][0] for r in best)
    how = Counter(v[2] for v in best.values())
    print(f"entries {len(entries)}, linked entries {len(linked_entries)}, shelf rows {len(rows)}, linked rows {len(best)} ({dict(how)})")
    for slug, n in sorted(per_book.items(), key=lambda kv: -kv[1]):
        print(f"  {slug:24} {n}")
    if "--stats" in args:
        return
    order, total = write_pack(rows, best)
    write_samples(rows, best, order)
    print(f"wrote {OUT.name}: {OUT.stat().st_size:,} bytes, {len(order)} books, {total} rows; samples -> {SAMPLES.name}")


if __name__ == "__main__":
    main()
