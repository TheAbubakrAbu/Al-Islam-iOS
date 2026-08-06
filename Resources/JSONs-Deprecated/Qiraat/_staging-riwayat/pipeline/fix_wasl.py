#!/usr/bin/env python3
"""Restore missing hamzatul-wasl marks in the Madani/Basri beta riwayat.

WHY
---
The Islamweb extraction under-captured the Maghribi wasl notation (alef + starting
haraka + U+06EC round mark) that the KFGQPC bridge texts use for the Madani and Basri
families: the Kufi beta texts carry ~13,470 wasl markings (matching their bridge's
13,486), but the Madani/Basri betas carry only ~8,500 against their bridges' ~10,050 -
about 1,500 bare alefs per riwayah where the reader gets no wasl indication at all.
99.7% of the confirmed misses are mid-ayah, the signature of a mechanical extraction
gap, not an edition difference.

Hamzatul wasl is a property of the consonantal skeleton, which is near-identical
across riwayat - so the marking can be copied from the same-family KFGQPC bridge
wherever the skeleton matches, and MUST NOT be touched where it differs (that is a
genuine riwayah difference, e.g. Warsh اَ۬لَانۡهَٰرُ vs Abu Jafar الۡأَنۡهَٰرُ).

RULES - additive only, asserted per word
----------------------------------------
  align   per surah, word stream vs word stream, SequenceMatcher over skeletons
          (immune to the families' differing ayah segmentation)
  copy    only inside `equal` blocks; only when the bridge word carries U+06EC,
          the beta word has neither U+06EC nor U+0671, and both skeletons match
  insert  the bridge alef's haraka+mark cluster after the beta word's SAME-ordinal
          plain alef; if the beta alef already has harakas, only U+06EC is added
  never   delete or replace a single character; a word that cannot satisfy every
          guard is skipped and counted, not guessed at

Usage:  fix_wasl.py [--apply]     (dry run by default; writes staging JSON + the
                                   app's .json.deflate bundles when applied)
"""
import json, re, sys, zlib, difflib, pathlib, collections

BASE = pathlib.Path(__file__).resolve().parent.parent          # _staging-riwayat
QIRAAT = BASE.parent                                           # JSONs-Deprecated/Qiraat
APP_DATA = BASE.parents[2] / "Data" / "Quran"                  # Resources/Data/Quran

WASL = "۬"            # the round wasl mark
ALEF_WASLA = "ٱ"      # ٱ - the Kufi convention; its presence means "already marked"
HARAKAS = "َُِ"                                 # fatha damma kasra
MARKS = re.compile(r"[ً-ٰٟۖ-ۭـࣰ-ٖࣿ-ٟ]")

TARGETS = {
    # beta slug          same-family KFGQPC bridges, first is primary
    "ibnwardan": ["QiraahQaloon", "QiraahWarsh"],
    "ibnjammaz": ["QiraahQaloon", "QiraahWarsh"],
    "ruways":    ["QiraahDuri", "QiraahSusi"],
    "rawh":      ["QiraahDuri", "QiraahSusi"],
}
DEFLATE_NAME = {"ibnwardan": "QiraahIbnWardan", "ibnjammaz": "QiraahIbnJammaz",
                "ruways": "QiraahRuways", "rawh": "QiraahRawh"}

TRANS = str.maketrans({"ٱ": "ا", "أ": "ا", "إ": "ا", "آ": "ا", "ى": "ي"})


def skel(word):
    return MARKS.sub("", word).translate(TRANS)


def surah_words(book, surah):
    """[(ayah index in list, word index in ayah, word)] for one surah, in order."""
    out = []
    for ai, ayah in enumerate(book[str(surah)]):
        for wi, word in enumerate(ayah["text"].split()):
            out.append((ai, wi, word))
    return out


def marked_alef_ordinals(word):
    """{plain-alef ordinal -> haraka cluster} for each wasl-marked alef in a bridge word."""
    out, ordinal = {}, -1
    i = 0
    while i < len(word):
        ch = word[i]
        if ch in "اٱأإآ":
            ordinal += 1
            if ch == "ا":
                j = i + 1
                cluster = []
                while j < len(word) and word[j] in HARAKAS:
                    cluster.append(word[j]); j += 1
                if j < len(word) and word[j] == WASL:
                    out[ordinal] = "".join(cluster)
        i += 1
    return out


def add_wasl(beta_word, ordinals):
    """The beta word with haraka+mark inserted after the given plain-alef ordinals.
    Returns None when any guard fails - the caller skips, never guesses."""
    chars, ordinal, done = list(beta_word), -1, 0
    i = 0
    while i < len(chars):
        if chars[i] in "اٱأإآ":
            ordinal += 1
            if ordinal in ordinals:
                if chars[i] != "ا":
                    return None                     # carrier isn't a plain alef here
                j = i + 1
                had_haraka = False
                while j < len(chars) and chars[j] in HARAKAS:
                    had_haraka = True; j += 1
                if j < len(chars) and chars[j] == WASL:
                    i += 1; continue                # already marked (second-bridge pass)
                insert = WASL if had_haraka else ordinals[ordinal] + WASL
                chars[j:j] = list(insert)
                done += 1
                i = j + len(insert)
                continue
        i += 1
    return "".join(chars) if done == len(ordinals) else None


def repair(beta, bridge, stats):
    """One bridge pass over one beta book, in place on the parsed dict."""
    for surah in range(1, 115):
        bw = surah_words(bridge, surah)
        tw = surah_words(beta, surah)
        sm = difflib.SequenceMatcher(None, [skel(w) for _, _, w in bw],
                                     [skel(w) for _, _, w in tw], autojunk=False)
        edits = collections.defaultdict(dict)      # ayah idx -> {word idx: new word}
        for tag, b0, b1, t0, t1 in sm.get_opcodes():
            if tag != "equal":
                continue
            for k in range(b1 - b0):
                _, _, bword = bw[b0 + k]
                ai, wi, tword = tw[t0 + k]
                if WASL not in bword or WASL in tword or ALEF_WASLA in tword:
                    continue
                if skel(bword) != skel(tword):     # belt over SequenceMatcher's braces
                    stats["skel_mismatch"] += 1; continue
                ordinals = marked_alef_ordinals(bword)
                if not ordinals:
                    stats["carrier_not_plain"] += 1; continue
                fixed = add_wasl(tword, ordinals)
                if fixed is None:
                    stats["guard_failed"] += 1; continue
                edits[ai][wi] = fixed
                stats["repaired"] += 1
                stats["marks_added"] += fixed.count(WASL) - tword.count(WASL)
        for ai, per_word in edits.items():
            ayah = beta[str(surah)][ai]
            words = ayah["text"].split()
            for wi, new in per_word.items():
                old = words[wi]
                # the one invariant that matters: additive-only, same skeleton
                assert skel(new) == skel(old) and len(new) > len(old) \
                    and WASL in new and WASL not in old, (surah, ayah["id"], old, new)
                words[wi] = new
            ayah["text"] = " ".join(words)


def main():
    apply = "--apply" in sys.argv
    print(f"{'riwayah':12}{'before':>8}{'after':>8}{'repaired':>10}{'added':>7}"
          f"{'skel≠':>7}{'guard':>7}")
    for slug, bridges in TARGETS.items():
        path = BASE / f"{slug}.json"
        beta = json.loads(path.read_text())
        before = sum(a["text"].count(WASL) for v in beta.values() for a in v)
        counts_before = [len(beta[str(s)]) for s in range(1, 115)]
        stats = collections.Counter()
        for bridge_name in bridges:
            bridge = json.loads((QIRAAT / f"{bridge_name}.json").read_text())
            repair(beta, bridge, stats)
        after = sum(a["text"].count(WASL) for v in beta.values() for a in v)
        assert [len(beta[str(s)]) for s in range(1, 115)] == counts_before
        assert after - before == stats["marks_added"]
        print(f"{slug:12}{before:>8}{after:>8}{stats['repaired']:>10}"
              f"{stats['marks_added']:>7}{stats['skel_mismatch']:>7}{stats['guard_failed']:>7}")
        if apply:
            blob = json.dumps(beta, ensure_ascii=False)
            path.write_text(blob)
            co = zlib.compressobj(9, zlib.DEFLATED, -15)
            deflated = co.compress(blob.encode()) + co.flush()
            out = APP_DATA / f"{DEFLATE_NAME[slug]}.json.deflate"
            # prove the app-side round trip before touching the bundle
            assert json.loads(zlib.decompress(deflated, -15)) == beta
            out.write_bytes(deflated)
            print(f"{'':12}  wrote {path.name} + {out.name} ({len(deflated):,} bytes)")
    if not apply:
        print("\nDRY RUN - pass --apply to write")


if __name__ == "__main__":
    main()
