#!/usr/bin/env python3
"""Build the packs derived from the Quranic Universal Library (QUL, qul.tarteel.ai) downloads
kept under Resources/JSONs-Deprecated/QUL/:

    Resources/Data/Quran/Morphology.json.xz     root + lemma of every word (Quranic Arabic Corpus)
    Resources/Data/Quran/Mutashabihat.json.xz   814 repeated phrases with their occurrences
    Resources/Data/Quran/QuranTopics.json.xz    2,512 topics: ontology, thematic (Clear Quran), index
    Resources/Data/Quran/AyahThemes.json.xz     1,049 passage themes (ranges of ayahs)
    Resources/Data/Quran/QuranMetadata.json     hizb, ruku and manzil boundaries

WORD POSITIONS
--------------
QUL keys words by Quran.com position ("2:3:5" = surah 2, ayah 3, word 5). This app splits an
ayah on whitespace and indexes straight in, and the two tokenizings differ on ~205 ayahs (the
rub-el-hizb mark is a token of its own here, a few words are joined or split differently), so
every position is mapped onto THIS APP's token index at build time through the same alignment
walk Scripts/build_wordbyword.py uses, against the same upstream word list (Tilawa's copy of
the Quran.com corpus, whose positions QUL shares). One wrinkle: Quran.com writes بَعْدَ مَا as
ONE word with a space inside, which QUL numbers as two positions; the upstream words are
expanded on that space before aligning, which reproduces QUL's numbering exactly (verified
against the max position of every ayah in the root and lemma tables).

Every pack stores 0-based token indices in this app's own order; the Swift stores never
match, normalize or guess.

RUN
---
    python3 Scripts/build_qul_packs.py [tilawa-root]

Fails, writing nothing, if any ayah cannot be aligned or any reference falls outside this
app's Quran. Scripts/verify_qul_packs.py re-checks the shipped packs and the rebuild.
"""

from __future__ import annotations

import html
import importlib.util
import io
import json
import lzma
import pathlib
import re
import sqlite3
import sys
import tempfile
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
QUL = ROOT / "Resources" / "JSONs-Deprecated" / "QUL"
OUT = ROOT / "Resources" / "Data" / "Quran"
QURAN_JSON = ROOT / "Resources" / "JSONs-Deprecated" / "Quran.json"
DEFAULT_TILAWA = ROOT.parent / "Tilawa"

_spec = importlib.util.spec_from_file_location("build_wordbyword", ROOT / "Scripts" / "build_wordbyword.py")
_bw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_bw)


def xz_compress(body: bytes) -> bytes:
    """Same container the other Data/Quran payloads use (Apple's COMPRESSION_LZMA reads xz)."""
    dict_size = 1 << 16
    while dict_size < len(body) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(body, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)


def dumps(obj) -> bytes:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")


# MARK: - The app's Quran and the position map

def load_quran():
    """(ordered ayah keys, key -> Hafs text)."""
    quran = json.loads(QURAN_JSON.read_text(encoding="utf-8"))
    order, texts = [], {}
    for surah in quran:
        for ayah in surah["ayahs"]:
            key = f"{surah['id']}:{ayah['id']}"
            order.append(key)
            texts[key] = ayah["textArabic"]
    return order, texts


def upstream_words(tilawa_root: pathlib.Path) -> dict[str, list[dict]]:
    """Quran.com's words per ayah, renumbered the way QUL numbers them (see the module doc)."""
    source = tilawa_root / "assets" / "quran" / "word-by-word-en.json"
    if not source.exists():
        raise SystemExit(f"source not found: {source}")
    raw = json.loads(source.read_text(encoding="utf-8"))
    out: dict[str, list[dict]] = {}
    for key, words in raw.items():
        expanded = []
        for word in words:
            # QUL numbers بَعْدَ مَا (2:181, 8:6, 13:37) as TWO positions and every other spaced
            # upstream word as one: a pause sign or the sajdah ornament set off by a space
            # (عَرَبِيًّۭا ۚ, يَسْجُدُونَ ۩), the broken دَآئِرَ ةٌۭ of 5:52, and إِلْ يَاسِينَ of 37:130
            # (which this app writes as two tokens; the walk's split lookahead covers that).
            parts = word["a"].split()
            if len(parts) == 2 and [_bw.norm(part) for part in parts] == ["بعد", "ما"]:
                for part in parts:
                    expanded.append({"p": len(expanded) + 1, "a": part})
            else:
                expanded.append({"p": len(expanded) + 1, "a": word["a"]})
        out[key] = expanded
    return out


def align_positions(tokens: list[str], words: list[dict]) -> list[list[int]] | None:
    """Per app token, the upstream positions it carries (build_wordbyword's walk, positions instead
    of glosses). Digit-only upstream words (a leaked ayah number) are skipped without a token."""
    words = [w for w in words if not _bw._DIGITS.match(_bw.norm(w["a"]) or "x")]
    out: list[list[int]] = []
    i = j = 0
    while i < len(tokens):
        tok = _bw.norm(tokens[i])
        if not tok:
            out.append([])
            i += 1
            continue
        if j >= len(words):
            return None
        if tok == _bw.norm(words[j]["a"]):
            out.append([words[j]["p"]])
            i += 1
            j += 1
            continue
        merged = None
        for span in range(2, _bw.MAX_SPAN + 1):
            if j + span > len(words):
                break
            if tok == _bw.norm("".join(w["a"] for w in words[j:j + span])):
                merged = span
                break
        if merged:
            out.append([w["p"] for w in words[j:j + merged]])
            i += 1
            j += merged
            continue
        split = None
        for span in range(2, _bw.MAX_SPAN + 1):
            if i + span > len(tokens):
                break
            if _bw.norm("".join(tokens[i:i + span])) == _bw.norm(words[j]["a"]):
                split = span
                break
        if split:
            out.append([words[j]["p"]])
            out.extend([[]] * (split - 1))
            i += split
            j += 1
            continue
        return None
    return out if j == len(words) else None


class PositionMap:
    """key -> {upstream position: app token index}, plus each ayah's token count."""

    def __init__(self, order: list[str], texts: dict[str, str], words: dict[str, list[dict]]):
        self.token_counts: dict[str, int] = {}
        self.word_counts: dict[str, int] = {key: len(items) for key, items in words.items()}
        self.to_token: dict[str, dict[int, int]] = {}
        failures = []
        for key in order:
            tokens = _bw.tokens_of(texts[key])
            aligned = align_positions(tokens, words.get(key, []))
            if aligned is None:
                failures.append(key)
                continue
            self.token_counts[key] = len(tokens)
            mapping: dict[int, int] = {}
            for index, positions in enumerate(aligned):
                for position in positions:
                    mapping.setdefault(position, index)
            self.to_token[key] = mapping
        if failures:
            raise SystemExit(f"{len(failures)} ayahs could not be aligned: {failures[:10]}")

    def token(self, key: str, position: int) -> int | None:
        return self.to_token.get(key, {}).get(position)

    def span(self, key: str, start: int, end: int) -> list[int] | None:
        """A 1-based inclusive upstream range as a 0-based inclusive token range, or None when
        the start names no token (a digit word) or the ayah is unknown. An end past the ayah's
        last word (six mutashabihat ranges overshoot by one or two: QUL's phrase tool counted a
        pause sign) is clamped to the last token - every such phrase runs to the ayah's end."""
        first = self.token(key, start)
        if first is None:
            return None
        last = self.token(key, end)
        if last is None and key in self.word_counts and end > self.word_counts[key]:
            last = self.token_counts[key] - 1
        if last is None or last < first:
            return None
        return [first, last]


# MARK: - Sources

def open_sqlite(path: pathlib.Path) -> sqlite3.Connection:
    """A .db, or a .db.zip holding one (extracted to a temp file - sqlite needs a real path)."""
    if path.suffix == ".zip":
        with zipfile.ZipFile(path) as archive:
            names = [n for n in archive.namelist() if n.endswith(".db")]
            if len(names) != 1:
                raise SystemExit(f"{path.name}: expected one .db inside, found {names}")
            data = archive.read(names[0])
        handle = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
        handle.write(data)
        handle.close()
        return sqlite3.connect(handle.name)
    return sqlite3.connect(path)


def read_zipped_json(path: pathlib.Path):
    with zipfile.ZipFile(path) as archive:
        names = [n for n in archive.namelist() if n.endswith(".json")]
        if len(names) != 1:
            raise SystemExit(f"{path.name}: expected one .json inside, found {names}")
        return json.loads(archive.read(names[0]).decode("utf-8"))


def parse_key(key: str) -> tuple[int, int] | None:
    parts = key.strip().split(":")
    if len(parts) != 2:
        return None
    try:
        return int(parts[0]), int(parts[1])
    except ValueError:
        return None


# MARK: - Morphology

def normalize_root(letters: str) -> str:
    """"ث   و   ي" and "ض ف د ع" both come out as single-spaced letters."""
    return " ".join(letters.split())


def build_morphology(order: list[str], positions: PositionMap) -> dict:
    roots_db = open_sqlite(QUL / "word-root.db.zip")
    lemmas_db = open_sqlite(QUL / "word-lemma.db.zip")

    root_rows = roots_db.execute("select id, arabic_trilateral, english_trilateral from roots order by id").fetchall()
    lemma_rows = lemmas_db.execute("select id, text, text_clean from lemmas order by id").fetchall()
    root_dense = {row[0]: index + 1 for index, row in enumerate(root_rows)}
    lemma_dense = {row[0]: index + 1 for index, row in enumerate(lemma_rows)}

    per_token_root: dict[str, list[int]] = {key: [0] * positions.token_counts[key] for key in order}
    per_token_lemma: dict[str, list[int]] = {key: [0] * positions.token_counts[key] for key in order}
    unmapped = []
    phantom = []

    def place(table: dict[str, list[int]], dense: int, location: str) -> None:
        parts = location.split(":")
        if len(parts) != 3:
            unmapped.append(location)
            return
        key = f"{parts[0]}:{parts[1]}"
        if key in positions.word_counts and int(parts[2]) > positions.word_counts[key]:
            # Three lemma rows (13:5:26, 2:275:46, 4:176:51) name a position past the ayah's last
            # word - QUL data slips, not words of the Quran. Ignored, and counted for the report.
            phantom.append(location)
            return
        token = positions.token(key, int(parts[2]))
        if token is None or key not in table:
            unmapped.append(location)
            return
        # A token that carries several upstream words keeps the FIRST one's root/lemma.
        if table[key][token] == 0:
            table[key][token] = dense

    for root_id, location in roots_db.execute("select root_id, word_location from root_words"):
        place(per_token_root, root_dense[root_id], location)
    for lemma_id, location in lemmas_db.execute("select lemma_id, word_location from lemma_words"):
        place(per_token_lemma, lemma_dense[lemma_id], location)
    if unmapped:
        raise SystemExit(f"{len(unmapped)} word locations name no token: {unmapped[:10]}")
    if phantom:
        print(f"  morphology: ignored {len(phantom)} locations past their ayah's last word: {phantom}")

    def by_surah(table: dict[str, list[int]]) -> dict[str, list[list[int]]]:
        out: dict[str, list[list[int]]] = {}
        for key in order:
            surah = key.split(":")[0]
            out.setdefault(surah, []).append(table[key])
        return out

    return {
        "v": 1,
        "roots": [[normalize_root(row[1]), row[2] or ""] for row in root_rows],
        "lemmas": [[row[1], row[2] or ""] for row in lemma_rows],
        "r": by_surah(per_token_root),
        "l": by_surah(per_token_lemma),
    }


# MARK: - Mutashabihat

def build_mutashabihat(positions: PositionMap) -> dict:
    phrases = json.loads((QUL / "mutashabihat" / "phrases.json").read_text(encoding="utf-8"))
    problems = []
    packed: dict[str, list] = {}
    index: dict[str, list[int]] = {}
    for phrase_id, phrase in phrases.items():
        source = phrase["source"]
        span = positions.span(source["key"], source["from"], source["to"])
        if span is None:
            problems.append(f"phrase {phrase_id}: source {source}")
            continue
        occurrences: dict[str, list[list[int]]] = {}
        for key, ranges in phrase["ayah"].items():
            spans = []
            for start, end in ranges:
                mapped = positions.span(key, start, end)
                if mapped is None:
                    problems.append(f"phrase {phrase_id}: {key} {start}-{end}")
                    continue
                if mapped not in spans:
                    spans.append(mapped)
            if spans:
                occurrences[key] = spans
                index.setdefault(key, []).append(int(phrase_id))
        packed[phrase_id] = [source["key"], span[0], span[1], phrase["count"], phrase["ayahs"], phrase["surahs"], occurrences]
    if problems:
        raise SystemExit(f"{len(problems)} mutashabihat references could not be mapped: {problems[:10]}")
    for key in index:
        # Longest phrases first: the fuller repetition is the one a memoriser wants to see first.
        index[key].sort(key=lambda pid: (-(packed[str(pid)][2] - packed[str(pid)][1]), pid))
    return {"v": 1, "phrases": packed, "index": index}


# MARK: - Topics

_TAG = re.compile(r"<[^>]+>")
NAME_FIXES = {
    "Doctraine": "Doctrine",
    "Parabels": "Parables",
    "Other-Stories": "Other Stories",
    "Prophets(25 mentioned by name)": "Prophets (25 mentioned by name)",
}


def plain_description(markup: str) -> str:
    """The description without its markup: <b>, <span class="ar">, and <topic data-id> links all
    collapse to their text (the app renders plain text and links topics by name itself)."""
    text = html.unescape(_TAG.sub("", markup or ""))
    return " ".join(text.split())


def wiki_url(link: str) -> str:
    link = (link or "").strip()
    if not link:
        return ""
    link = link.replace("//wiki/", "/wiki/")
    if not link.startswith("http"):
        link = "https://" + link
    return link


def build_topics(valid_keys: set[str]) -> dict:
    db = open_sqlite(QUL / "topics.db")
    rows = db.execute(
        "select topic_id, name, arabic_name, parent_id, thematic_parent_id, ontology_parent_id, "
        "description, wiki_link, thematic, ontology, ayahs, related_topics from topics order by topic_id"
    ).fetchall()
    ids = {row[0] for row in rows}
    dropped_refs = 0
    topics = []
    for (topic_id, name, arabic, parent, thematic_parent, ontology_parent,
         description, wiki, thematic, ontology, ayahs, related) in rows:
        keys = []
        for part in (ayahs or "").split(","):
            key = part.strip()
            if not key:
                continue
            if key in valid_keys:
                if key not in keys:
                    keys.append(key)
            else:
                dropped_refs += 1
        related_ids = []
        for part in (related or "").split(","):
            part = part.strip()
            if part.isdigit() and int(part) in ids and int(part) != topic_id:
                related_ids.append(int(part))
        clean_name = " ".join((name or "").split())
        clean_name = NAME_FIXES.get(clean_name, clean_name)
        topics.append({
            "id": topic_id,
            "n": clean_name,
            "ar": " ".join((arabic or "").split()),
            "p": parent if parent in ids else None,
            "tp": thematic_parent if thematic_parent in ids else None,
            "op": ontology_parent if ontology_parent in ids else None,
            "d": plain_description(description),
            "w": wiki_url(wiki),
            "t": 1 if thematic else 0,
            "o": 1 if ontology else 0,
            "ay": keys,
            "rel": related_ids,
        })
    if dropped_refs:
        print(f"  topics: dropped {dropped_refs} ayah references outside this app's Quran")
    return {"v": 1, "topics": topics}


# MARK: - Ayah themes

def build_themes(counts: dict[int, int]) -> dict:
    db = open_sqlite(QUL / "ayah-themes.db")
    rows = db.execute("select theme, surah_number, ayah_from, ayah_to, keywords from themes").fetchall()
    seen = set()
    per_surah: dict[str, list[list]] = {}
    problems = []
    for theme, surah, start, end, keywords in rows:
        entry = (surah, start, end, " ".join((theme or "").split()))
        if entry in seen:
            continue  # the QUL export lists every row twice
        seen.add(entry)
        if surah not in counts or not 1 <= start <= end <= counts[surah]:
            problems.append(entry)
            continue
        words = [w.strip() for w in (keywords or "").split(",") if w.strip()]
        per_surah.setdefault(str(surah), []).append([start, end, entry[3], ",".join(words)])
    if problems:
        raise SystemExit(f"{len(problems)} theme rows fall outside the Quran: {problems[:5]}")
    for rows_ in per_surah.values():
        rows_.sort(key=lambda r: (r[0], r[1]))
    return {"v": 1, "themes": per_surah}


# MARK: - Metadata

def build_metadata(order: list[str]) -> dict:
    position = {key: index for index, key in enumerate(order)}

    def boundaries(name: str, number_field: str) -> list[str]:
        table = read_zipped_json(QUL / f"quran-metadata-{name}.json.zip")
        entries = sorted(table.values(), key=lambda e: e[number_field])
        keys = [entry["first_verse_key"] for entry in entries]
        expected = list(range(1, len(entries) + 1))
        if [entry[number_field] for entry in entries] != expected:
            raise SystemExit(f"{name}: numbers are not 1..{len(entries)}")
        if any(key not in position for key in keys):
            raise SystemExit(f"{name}: a boundary names an ayah this app does not have")
        if any(position[a] >= position[b] for a, b in zip(keys, keys[1:])):
            raise SystemExit(f"{name}: boundaries are not in mushaf order")
        if keys[0] != "1:1":
            raise SystemExit(f"{name}: does not start at 1:1")
        return keys

    return {
        "v": 1,
        "hizb": boundaries("hizb", "hizb_number"),
        "ruku": boundaries("ruku", "ruku_number"),
        "manzil": boundaries("manzil", "manzil_number"),
    }


# MARK: - Driver

def build_all(tilawa_root: pathlib.Path) -> dict[str, bytes]:
    order, texts = load_quran()
    counts: dict[int, int] = {}
    for key in order:
        surah = int(key.split(":")[0])
        counts[surah] = counts.get(surah, 0) + 1
    positions = PositionMap(order, texts, upstream_words(tilawa_root))
    return {
        "Morphology.json.xz": dumps(build_morphology(order, positions)),
        "Mutashabihat.json.xz": dumps(build_mutashabihat(positions)),
        "QuranTopics.json.xz": dumps(build_topics(set(order))),
        "AyahThemes.json.xz": dumps(build_themes(counts)),
        "QuranMetadata.json": dumps(build_metadata(order)),
    }


def main() -> None:
    tilawa_root = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_TILAWA
    bodies = build_all(tilawa_root)
    for name, body in bodies.items():
        blob = xz_compress(body) if name.endswith(".xz") else body
        (OUT / name).write_bytes(blob)
        print(f"{name}: {len(body):,} raw -> {len(blob):,} bytes")


if __name__ == "__main__":
    main()
