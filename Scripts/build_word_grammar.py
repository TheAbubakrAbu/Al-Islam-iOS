#!/usr/bin/env python3
"""Build Resources/Data/Quran/WordGrammar.json.xz: the grammar of every word of the Quran, split into
its segments (prefix, stem, suffix), for the word card's Grammar page and its segmented hero.

SOURCE
------
The Quranic Arabic Corpus morphology (Kais Dukes, corpus.quran.com), as Tilawa ships it
(~/Downloads/Islam/Tilawa/assets/quran/morphology: signatures.json plus one chunk per surah, built by
Tilawa's scripts/build-word-morphology.mjs). A chunk row is [signatureId, letters]: the signature
"TAG|k|feature|..." says what the segment IS (k = p prefix, s stem, x suffix), and `letters` says how
many BASE letters of the word it covers, or is the segment's text where counting cannot split it.

WORD POSITIONS
--------------
Tilawa keys words by its reader's 1-based positions (its word-by-word files). This app splits an
ayah on whitespace, so every position is mapped onto THIS APP's token index here, through the same
alignment walk Scripts/build_qul_packs.py uses (a token may carry two upstream words, an upstream
word may span two tokens; only the first token of a split carries the segments).

LETTER COUNTS ARE CHECKED AGAINST THIS APP'S TEXT
-------------------------------------------------
The Swift side cuts each segment out of the app's OWN token (WordGrammarStore.slice), so a count is
kept only where the token's base letters add up to exactly the counts' sum. Anywhere else (a token
spelled differently from Tilawa's word, or a segment with no letter of its own) every segment of
that token is stored as text, cut from Tilawa's word with Tilawa's own rule, and the card draws the
word from those pieces.

PACK
----
    {"v": 1, "sig": [signature...], "forms": [text...],
     "w": {"<surah>": [ayah: [token: [sig, n, sig, n, ...]]]}}

`n >= 0` is a base-letter count; `n < 0` is forms[-n - 1]. An empty list = no annotation.

RUN
---
    python3 Scripts/build_word_grammar.py [tilawa-root]

Fails, writing nothing, if an ayah cannot be aligned.
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "Resources" / "Data" / "Quran" / "WordGrammar.json.xz"
DEFAULT_TILAWA = ROOT.parent / "Tilawa"

_spec = importlib.util.spec_from_file_location("build_qul_packs", ROOT / "Scripts" / "build_qul_packs.py")
_qul = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_qul)
_bw = _qul._bw

# Tilawa's rule (src/data/wordMorphology.ts), mirrored exactly here and in WordGrammarStore.slice: a
# base letter is a consonant or long vowel; marks ride on the letter before them; a trailing pause
# mark belongs to no segment.
BASE_LETTER = re.compile("[ء-غف-يٱٮٯی]")
TRAILING_PAUSE = re.compile(r"\s+[ۖ-ۭ]*\s*$")


def core_text(text: str) -> str:
    return TRAILING_PAUSE.sub("", text).strip()


def base_count(text: str) -> int:
    return sum(1 for ch in core_text(text) if BASE_LETTER.match(ch))


def slice_by_letters(text: str, counts: list[int]) -> list[str]:
    cps = list(core_text(text))
    parts: list[str] = []
    i = 0
    for k, count in enumerate(counts):
        start = i
        taken = 0
        while i < len(cps) and taken < count:
            if BASE_LETTER.match(cps[i]):
                taken += 1
            i += 1
        while i < len(cps) and not BASE_LETTER.match(cps[i]) and cps[i] != " ":
            i += 1
        if k == len(counts) - 1:
            i = len(cps)
        parts.append("".join(cps[start:i]).strip())
    return parts


def main() -> None:
    tilawa = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_TILAWA
    morph_dir = tilawa / "assets" / "quran" / "morphology"
    wbw_dir = tilawa / "assets" / "quran" / "word-by-word"
    signatures = json.loads((morph_dir / "signatures.json").read_text(encoding="utf-8"))

    order, texts = _qul.load_quran()
    forms: list[str] = []
    form_ids: dict[str, int] = {}
    out: dict[str, list] = {}
    failures: list[str] = []
    stats = {"tokens": 0, "annotated": 0, "counted": 0, "spelled": 0, "unannotated_words": 0}

    def form_ref(text: str) -> int:
        if text not in form_ids:
            form_ids[text] = len(forms)
            forms.append(text)
        return -(form_ids[text] + 1)

    chunks: dict[int, dict] = {}
    words_by_surah: dict[int, dict] = {}
    for key in order:
        surah = int(key.split(":")[0])
        if surah not in chunks:
            chunks[surah] = json.loads((morph_dir / f"s{surah:03d}.json").read_text(encoding="utf-8"))
            words_by_surah[surah] = json.loads((wbw_dir / f"s{surah:03d}.json").read_text(encoding="utf-8"))
        words = words_by_surah[surah].get(key, [])
        rows_by_word = chunks[surah].get(key, [])
        tokens = _bw.tokens_of(texts[key])
        aligned = _qul.align_positions(tokens, [{"p": w["p"], "a": w["a"]} for w in words])
        if aligned is None:
            failures.append(key)
            continue
        display = {w["p"]: w.get("d") or w["a"] for w in words}

        # Rows per token. An upstream word spread over several tokens (بَعْدَ مَا, إِلْ يَاسِينَ: the
        # walk gives its position to the first token and [] to the rest) hands its segments out by
        # base letters, so each token carries its own part.
        token_rows: list[list[tuple[int, object, str]]] = [[] for _ in tokens]
        index = 0
        while index < len(tokens):
            positions = aligned[index]
            rows: list[tuple[int, object, str]] = []
            for position in positions:
                word_rows = rows_by_word[position - 1] if 0 < position <= len(rows_by_word) else None
                if not word_rows:
                    stats["unannotated_words"] += 1
                    continue
                for signature, letters in word_rows:
                    rows.append((signature, letters, display.get(position, "")))
            followers = 0
            while (len(positions) == 1 and index + followers + 1 < len(tokens)
                   and not aligned[index + followers + 1] and base_count(tokens[index + followers + 1]) > 0):
                followers += 1
            if followers and all(isinstance(letters, int) for _, letters, _ in rows) \
                    and sum(letters for _, letters, _ in rows) == sum(base_count(t) for t in tokens[index:index + followers + 1]):
                target, room = index, base_count(tokens[index])
                for row in rows:
                    while room == 0 and target < index + followers:
                        target += 1
                        room = base_count(tokens[target])
                    token_rows[target].append(row)
                    room -= row[1]
                index += followers + 1
                continue
            token_rows[index] = rows
            index += 1

        ayah_out: list[list] = []
        for index, rows in enumerate(token_rows):
            stats["tokens"] += 1
            if not rows:
                ayah_out.append([])
                continue
            stats["annotated"] += 1

            # Tilawa spells a word out where ITS text cannot be cut by counting (a hamza on a
            # tatweel). This app's text often can: when every piece has a base letter and the pieces'
            # letters add up to the token's, the pieces become counts again.
            if not all(isinstance(letters, int) for _, letters, _ in rows):
                counts = [base_count(str(letters)) if not isinstance(letters, int) else letters for _, letters, _ in rows]
                if all(count > 0 for count in counts) and sum(counts) == base_count(tokens[index]):
                    rows = [(signature, count, text) for (signature, _, text), count in zip(rows, counts)]

            counts_only = all(isinstance(letters, int) for _, letters, _ in rows)
            if counts_only and sum(letters for _, letters, _ in rows) == base_count(tokens[index]):
                stats["counted"] += 1
                flat: list[int] = []
                for signature, letters, _ in rows:
                    flat += [signature, letters]
                ayah_out.append(flat)
                continue

            # Spelled out: Tilawa's own cut of its own word (per upstream word, so a merged token's
            # second word is cut from its own text), or the explicit text the chunk already carries.
            stats["spelled"] += 1
            pieces: list[str] = []
            run: list[tuple[int, object, str]] = []

            def flush() -> None:
                if not run:
                    return
                if all(isinstance(letters, int) for _, letters, _ in run):
                    pieces.extend(slice_by_letters(run[0][2], [letters for _, letters, _ in run]))
                else:
                    pieces.extend(str(letters) for _, letters, _ in run)
                run.clear()

            for row in rows:
                if run and row[2] != run[0][2]:
                    flush()
                run.append(row)
            flush()

            # Tilawa's pieces, counted under this app's rule, usually fit the token after all (the
            # corpus counts a hamza on a tatweel as a letter: ٱلْـَٔايَـٰتِ is [2, 4] there, [2, 3] here).
            # An implied segment (an elided "my": يَٰقَوۡمِ) is an empty piece and counts 0 letters.
            recount = [base_count(piece) for piece in pieces]
            if len(recount) == len(rows) \
                    and all(count > 0 or not piece.strip() for count, piece in zip(recount, pieces)) \
                    and any(count > 0 for count in recount) \
                    and sum(recount) == base_count(tokens[index]):
                stats["spelled"] -= 1
                stats["counted"] += 1
                flat = []
                for (signature, _, _), count in zip(rows, recount):
                    flat += [signature, count]
                ayah_out.append(flat)
                continue

            flat = []
            for (signature, _, _), piece in zip(rows, pieces):
                flat += [signature, form_ref(piece)]
            ayah_out.append(flat)
        out.setdefault(str(int(key.split(":")[0])), []).append(ayah_out)

    if failures:
        raise SystemExit(f"{len(failures)} ayahs could not be aligned: {failures[:10]}")

    pack = {"v": 1, "sig": signatures, "forms": forms, "w": out}
    body = _qul.dumps(pack)
    blob = _qul.xz_compress(body)
    OUT.write_bytes(blob)
    print(f"{OUT.name}: {len(body):,} raw -> {len(blob):,} bytes")
    print(f"  tokens {stats['tokens']:,}, annotated {stats['annotated']:,} "
          f"(counted {stats['counted']:,}, spelled out {stats['spelled']:,}), "
          f"{len(forms):,} distinct spelled forms, {stats['unannotated_words']:,} upstream words without rows")


if __name__ == "__main__":
    main()
