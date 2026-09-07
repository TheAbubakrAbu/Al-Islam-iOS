#!/usr/bin/env python3
"""Gate for the QUL-derived packs and the qiraat variants pack. Must pass before they ship.

Checks the packs ON DISK against the app's own Quran text:
  1. each decodes (xz, or plain JSON for the metadata) and carries its version;
  2. Morphology: every surah present, every ayah's root and lemma arrays exactly as long as
     the ayah's whitespace token count, every index inside the root/lemma tables;
  3. Mutashabihat: every phrase's source span and every occurrence span inside its ayah's
     tokens, the index consistent with the occurrences;
  4. QuranTopics: every ayah key a real ayah, every parent and related id a real topic;
  5. AyahThemes: ranges inside their surah, no duplicates, in order;
  6. QuranMetadata: 60 hizb, 558 ruku, 7 manzil boundaries in mushaf order from 1:1;
  7. QiraatVariants: every ayah key real, every placed segment inside its ayah's tokens, every
     reader/transmitter id in the tables, every transmitter tag one of the app's riwayat;
  8. rebuilding from source reproduces every pack byte for byte.

Run:  python3 Scripts/verify_qul_packs.py [tilawa-root]
"""

from __future__ import annotations

import importlib.util
import json
import lzma
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "Resources" / "Data" / "Quran"

_spec = importlib.util.spec_from_file_location("build_qul_packs", ROOT / "Scripts" / "build_qul_packs.py")
_qul = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_qul)
_vspec = importlib.util.spec_from_file_location("build_qiraat_variants", ROOT / "Scripts" / "build_qiraat_variants.py")
_variants = importlib.util.module_from_spec(_vspec)
_vspec.loader.exec_module(_variants)


def load(name: str):
    path = DATA / name
    if not path.exists():
        raise SystemExit(f"pack missing: {path}")
    blob = path.read_bytes()
    raw = lzma.decompress(blob) if name.endswith(".xz") else blob
    return json.loads(raw.decode("utf-8")), raw


def main() -> None:
    order, texts = _qul.load_quran()
    tokens = {key: len(texts[key].split()) for key in order}
    valid = set(order)
    problems: list[str] = []

    morphology, _ = load("Morphology.json.xz")
    if morphology.get("v") != 1:
        problems.append("Morphology: not version 1")
    roots, lemmas = morphology["roots"], morphology["lemmas"]
    for layer, table in (("r", roots), ("l", lemmas)):
        rows = morphology[layer]
        for key in order:
            surah, ayah = key.split(":")
            values = rows.get(surah, [])
            if int(ayah) > len(values):
                problems.append(f"Morphology {layer}: {key} missing")
                continue
            entry = values[int(ayah) - 1]
            if len(entry) != tokens[key]:
                problems.append(f"Morphology {layer}: {key} has {len(entry)} entries for {tokens[key]} tokens")
            if any(not 0 <= v <= len(table) for v in entry):
                problems.append(f"Morphology {layer}: {key} index out of range")
    filled_roots = sum(1 for key in order for v in morphology["r"][key.split(":")[0]][int(key.split(":")[1]) - 1] if v)
    filled_lemmas = sum(1 for key in order for v in morphology["l"][key.split(":")[0]][int(key.split(":")[1]) - 1] if v)

    mutashabihat, _ = load("Mutashabihat.json.xz")
    phrases = mutashabihat["phrases"]
    index = mutashabihat["index"]
    rebuilt_index: dict[str, set[int]] = {}
    for phrase_id, row in phrases.items():
        source_key, start, end = row[0], row[1], row[2]
        if source_key not in valid or not 0 <= start <= end < tokens[source_key]:
            problems.append(f"Mutashabihat {phrase_id}: bad source span")
        for key, spans in row[6].items():
            if key not in valid:
                problems.append(f"Mutashabihat {phrase_id}: unknown ayah {key}")
                continue
            for span in spans:
                if len(span) != 2 or not 0 <= span[0] <= span[1] < tokens[key]:
                    problems.append(f"Mutashabihat {phrase_id}: bad span {span} in {key}")
            rebuilt_index.setdefault(key, set()).add(int(phrase_id))
    if {k: set(v) for k, v in index.items()} != rebuilt_index:
        problems.append("Mutashabihat: index disagrees with the occurrences")

    topics, _ = load("QuranTopics.json.xz")
    ids = {t["id"] for t in topics["topics"]}
    topic_refs = 0
    for topic in topics["topics"]:
        for field in ("p", "tp", "op"):
            if topic[field] is not None and topic[field] not in ids:
                problems.append(f"QuranTopics {topic['id']}: {field} names no topic")
        if any(r not in ids for r in topic["rel"]):
            problems.append(f"QuranTopics {topic['id']}: related id unknown")
        if any(k not in valid for k in topic["ay"]):
            problems.append(f"QuranTopics {topic['id']}: ayah outside the Quran")
        if not topic["n"]:
            problems.append(f"QuranTopics {topic['id']}: empty name")
        topic_refs += len(topic["ay"])

    themes, _ = load("AyahThemes.json.xz")
    theme_rows = 0
    for surah, rows in themes["themes"].items():
        count = sum(1 for key in order if key.startswith(surah + ":"))
        previous = None
        for row in rows:
            theme_rows += 1
            if not 1 <= row[0] <= row[1] <= count:
                problems.append(f"AyahThemes {surah}: range {row[:2]} outside the surah")
            if previous is not None and (row[0], row[1]) < previous:
                problems.append(f"AyahThemes {surah}: rows out of order at {row[:2]}")
            previous = (row[0], row[1])
    if len({(s, r[0], r[1], r[2]) for s, rows in themes["themes"].items() for r in rows}) != theme_rows:
        problems.append("AyahThemes: duplicate rows")

    metadata, _ = load("QuranMetadata.json")
    position = {key: i for i, key in enumerate(order)}
    for name, expected in (("hizb", 60), ("ruku", 558), ("manzil", 7)):
        keys = metadata[name]
        if len(keys) != expected:
            problems.append(f"QuranMetadata {name}: {len(keys)} boundaries, expected {expected}")
        if keys[:1] != ["1:1"] or any(k not in position for k in keys):
            problems.append(f"QuranMetadata {name}: bad boundary keys")
        elif any(position[a] >= position[b] for a, b in zip(keys, keys[1:])):
            problems.append(f"QuranMetadata {name}: not in mushaf order")

    variants, _ = load("QiraatVariants.json.xz")
    tags = set(_variants.TRANSMITTER_TAGS.values())
    reader_ids = set(variants["readers"])
    transmitter_ids = set(variants["transmitters"])
    if any(t["tag"] not in tags for t in variants["transmitters"].values()):
        problems.append("QiraatVariants: a transmitter carries an unknown riwayah tag")
    junctures = readings = 0
    for key, rows in variants["ayahs"].items():
        if key not in valid:
            problems.append(f"QiraatVariants: unknown ayah {key}")
            continue
        for juncture in rows:
            junctures += 1
            for seg_key, start, end in juncture["seg"]:
                if seg_key not in valid:
                    problems.append(f"QiraatVariants {key}: segment in unknown ayah {seg_key}")
                elif start != -1 and not 0 <= start <= end < tokens[seg_key]:
                    problems.append(f"QiraatVariants {key}: segment {start}-{end} outside {seg_key}")
            for reading in juncture["readings"]:
                readings += 1
                if any(str(r) not in reader_ids for r in reading["rd"]) or any(str(t) not in transmitter_ids for t in reading["tm"]):
                    problems.append(f"QiraatVariants {key}: reading names an unknown reader or transmitter")
                if not reading["t"]:
                    problems.append(f"QiraatVariants {key}: empty reading text")

    # 8. Rebuild and compare.
    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else _qul.DEFAULT_TILAWA
    rebuilt = _qul.build_all(tilawa)
    for name, body in rebuilt.items():
        _, on_disk = load(name)
        if on_disk != body:
            problems.append(f"{name}: the shipped pack differs from a fresh build")
    result = subprocess.run([sys.executable, str(ROOT / "Scripts" / "build_qiraat_variants.py")],
                            capture_output=True, text=True)
    if result.returncode != 0:
        problems.append(f"QiraatVariants: rebuild failed: {result.stderr.strip()[:200]}")

    if problems:
        print(f"FAILED: {len(problems)} problem(s)", file=sys.stderr)
        for line in problems[:30]:
            print(f"  {line}", file=sys.stderr)
        raise SystemExit(1)
    print(f"OK: morphology {len(roots)} roots / {len(lemmas)} lemmas over {sum(tokens.values()):,} tokens "
          f"({filled_roots:,} rooted, {filled_lemmas:,} lemmatised); {len(phrases)} phrases over {len(index)} ayahs; "
          f"{len(ids)} topics with {topic_refs:,} ayah references; {theme_rows} passage themes; "
          f"{junctures} junctures / {readings} readings over {len(variants['ayahs'])} ayahs")


if __name__ == "__main__":
    main()
