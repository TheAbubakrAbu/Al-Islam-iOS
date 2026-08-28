"""Zone-audit the CONTEXT map, not just the detmap.

`zoneaudit.py` checks `detmap`, but `render_det` consults `ctxdet-<family>.json` FIRST, so a
glyph can be zone-correct in the detmap and still render as the wrong mark. That is exactly
what the HQPB4 shadda ladder does:

    مِّن  =  [HQPB4#176 kasra-stroke, ink BELOW]  [HQPB4#75 shadda, ink ABOVE]

The print emits the pair in that order; Unicode writes shadda first. Rather than reorder,
the learner simply **swapped the two emissions** (#176 -> shadda, #75 -> kasra), which
produces the right string for the pair and nonsense for every ladder glyph that appears
without its partner.

This reports, per key, what fraction of its ctx rules emit a mark whose zone contradicts
the glyph's ink.

    python3 zonectx.py            # report
    python3 zonectx.py --write    # write data/zoneflip.json for final.py to consume
"""
import os, sys, io, json, pathlib, collections, unicodedata
import fitz
from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import RecordingPen

HERE = pathlib.Path(__file__).resolve().parent
DATA = HERE / "data"
sys.path.insert(0, str(HERE))
from extract import pdf_path
import zoneaudit

ABOVE, BELOW = zoneaudit.ABOVE, zoneaudit.BELOW
FAM = os.environ.get("QIRAAT_FAMILY", "kufi")
# Run it for EVERY family whose ctx map exists, not just one:
#   for f in kufi madani basri; do QIRAAT_FAMILY=$f python3 zonectx.py --write; done

def zone_of(gsets, font, gid):
    if font not in gsets:
        return None
    b = zoneaudit.bounds(gsets[font], gid)
    if not b:
        return None
    ymin, ymax = b[1], b[3]
    if ymin >= 0:
        return "above"
    if ymax <= 0:
        return "below"
    return "spans"

def mark_zone(emit):
    """above / below / None for a mark-only emission, judged on its VOWELS alone.

    An emission may legitimately carry more than the vowel: `HQPB4#25` draws a kasratain
    together with the small saad-lam-alef pause sign and emits `ٍۖ`. Requiring every
    character to be a vowel called that "not a mark", so it counted neither for nor against
    the key - and the replacement below then picked a bare `ٍ` off some minority rule and
    DELETED the pause sign, 33 words a Madani volume. Non-vowel combining marks are passed
    over; a LETTER still disqualifies the emission, because a glyph that prints a letter is
    not a mark glyph and this audit has nothing to say about it.
    """
    if not emit or any(not unicodedata.combining(c) for c in emit):
        return None
    above = any(c in ABOVE for c in emit)
    below = any(c in BELOW for c in emit)
    if above == below:
        return None      # neither, or mixed (shadda+kasra is legitimately both)
    return "above" if above else "below"

def main():
    gsets = zoneaudit.glyphsets()
    ctx = json.loads((DATA / f"ctxdet-{FAM}.json").read_text())
    rows = []
    for key, rules in ctx.items():
        body = key[3:] if key.startswith("CL|") else key
        if "||" in body:
            continue
        head = body.rsplit("|", 1)[0]
        if "#" not in head:
            continue
        font, gid = head.split("#", 1)
        if not gid.isdigit():
            continue
        z = zone_of(gsets, font, int(gid))
        if z in (None, "spans"):
            continue
        bad = collections.Counter()
        good = 0
        for _, emit in rules.items():
            mz = mark_zone(emit)
            if mz is None:
                continue
            if mz != z:
                bad[emit] += 1
            else:
                good += 1
        if bad:
            rows.append((font, int(gid), key, z, sum(bad.values()), good, dict(bad)))
    rows.sort(key=lambda r: -r[4])
    print(f"keys whose ctx emits a zone-contradicting mark: {len(rows)}")
    for font, gid, key, z, nbad, ngood, bad in rows:
        print(f"  {font}#{gid:<4} ink {z:5}  {nbad:4} contradicting / {ngood:4} consistent  {bad}")
    if "--write" not in sys.argv:
        return
    # Resolve each contradicting key to ONE zone-consistent emission.
    #
    #   ink above -> the bare shadda. Every ink-above row here is the same shadda outline
    #                drawn at a different stack height (rendered and eyeballed, all 15).
    #   ink below -> that key's own majority zone-consistent emission, which is the kasra
    #                it really is; the shadda votes are the paired-context flip.
    # MERGE, never overwrite. `zoneflip.json` holds every family's rungs, and each run
    # can only see the ctx map of the family it was given: the six kasra rungs of §3g are
    # contradicted in the BASRI map and nowhere else, so a kufi-only run that overwrote the
    # file would drop them - and an incomplete kasra ladder silently deletes kasras, which
    # is the 1,076-word failure that pass was written to fix.
    # The bare shadda, read off the outline in §3b. Everything the ink-above shortcut
    # claims is "the same shadda outline at a different stack height" is measured
    # against this one.
    SHADDA_REF = ("HQPB4", 75)
    DIM_TOL = 4
    zf_path = DATA / "zoneflip.json"
    out = json.loads(zf_path.read_text()) if zf_path.exists() else {}
    skipped = []
    # The ink-above shortcut is NOT general. §3b verified by eye that every ink-above row
    # it saw was the one bare-shadda outline at a different stack height - but that was
    # true of the fifteen HQPB4 rungs it looked at, not of ink-above glyphs at large, and
    # running this for madani and basri turned up ink-above rows that are nothing like a
    # shadda: `HQPB5#48` is 1692x823 against the shadda's 402x397 and its own other key
    # emits a maddah, `HQPB5#69` emits an alef. Forcing those to a shadda cost 133 Madani
    # words, `بِالۡإِثۡمِ` shipping as `بِالۡإّثۡمِ`. So the shortcut now has to earn itself:
    # the glyph must be the same SIZE as the verified bare shadda. Anything else takes the
    # ordinary treatment - its own majority zone-consistent emission, or nothing at all.
    ref = zoneaudit.bounds(gsets.get(SHADDA_REF[0], []), SHADDA_REF[1]) if SHADDA_REF[0] in gsets else None
    ref_dim = (round(ref[2] - ref[0]), round(ref[3] - ref[1])) if ref else None

    def is_shadda_outline(font, gid):
        if not ref_dim or font not in gsets:
            return False
        b = zoneaudit.bounds(gsets[font], gid)
        if not b:
            return False
        w, h = round(b[2] - b[0]), round(b[3] - b[1])
        return abs(w - ref_dim[0]) <= DIM_TOL and abs(h - ref_dim[1]) <= DIM_TOL

    for font, gid, key, z, nbad, ngood, bad in rows:
        if z == "above" and is_shadda_outline(font, gid):
            out[key] = "\u0651"
            continue
        good = collections.Counter()
        for _, emit in ctx[key].items():
            if mark_zone(emit) == z:
                good[emit] += 1
        if not good:
            skipped.append(f"{font}#{gid}")
            continue
        out[key] = good.most_common(1)[0][0]
    # ---- positional entries -------------------------------------------------------
    # One outline, two jobs, split by where in the word it falls. `zone_of` cannot express
    # that and neither can a flat value, so these are stated - `final.render_det` reads a
    # dict value keyed "$" (word-final) and "*" (anywhere else). See §3g of the handoff:
    # adjudicated over both Yaqub volumes against the verified Duri text, all 1,620
    # occurrences split perfectly with no context seeing both answers.
    #
    # They live here rather than only in the JSON so that a regeneration reproduces them.
    # The Yaqub session left this one in `zoneflip.json` alone and a later `--write` from
    # another family dropped it silently.
    POSITIONAL = {
        # word-final: the alef of `لَا` / `إِلَّا` (1,475 occurrences)
        # elsewhere:  the shadda + fatha of `فَضَّلۡتُكُمۡ` / `اَ۬لضَّآلِّينَ` (145)
        "CL|HQPB5#128|\uf09e": {"$": "\u0627", "*": "\u064e\u0651"},
    }
    for key, val in POSITIONAL.items():
        if out.get(key) != val:
            out[key] = val
            print(f"  POSITIONAL {key} -> {val}")

    # ---- ladder-identity pass ----------------------------------------------------
    # The zone test above cannot adjudicate a glyph whose ink SPANS the baseline, and it
    # returns "spans" for exactly the rungs drawn nearest the line. `HQPB4#158` is one:
    # ink -181..166, so neither above nor below, and it emitted a shadda in every family
    # while its own ladder emitted the kasra. That cost the kasra of `يُؤَخِّرُهُمۡ` and
    # seven more words per Kufi volume, in the same way §3g's six missing rungs did - the
    # shadda beside it folds the pair into one and the vowel is simply gone.
    #
    # A ladder is ONE mark drawn at many stack heights, so the group's own zone-decided
    # majority names the rungs geometry could not. Only "spans" members are ever
    # overridden - where the zone test DID decide, it wins.
    #
    # A ladder is one mark drawn at many stack heights, so its members share a bounding
    # box to within a unit or two while sitting at quite different heights. Exact path
    # identity is too strict - the font carries several bezier variants of the same stroke,
    # which split the kasra ladder into four - and quantising the path is not monotone, so
    # cluster on the box itself with a small tolerance. On HQPB4 that recovers exactly the
    # ladders the earlier passes found by hand: 402x397 the bare shadda (§3b), 510x347 the
    # kasra (§3g), 493x971 shadda+damma, 681x722 shadda+fatha, 508x631 the plain damma.
    import final as _final
    detmap = _final.build_detmap(FAM)
    eff, keys_of = {}, collections.defaultdict(list)
    for key, emit in detmap.items():
        body = key[3:] if key.startswith("CL|") else key
        if "||" in body or "#" not in body:
            continue
        head = body.rsplit("|", 1)[0]
        font, _, gid = head.partition("#")
        if not gid.isdigit():
            continue
        keys_of[(font, int(gid))].append(key)
        eff.setdefault((font, int(gid)), out.get(key, emit))
    dims = {}
    for font, gid in eff:
        b = zoneaudit.bounds(gsets.get(font, []), gid) if font in gsets else None
        if b:
            dims[(font, gid)] = (round(b[2] - b[0]), round(b[3] - b[1]))
    groups = []
    for m in sorted(dims, key=lambda k: (k[0], dims[k])):
        w, h = dims[m]
        for grp in groups:
            w0, h0 = dims[grp[0]]
            if grp[0][0] == m[0] and abs(w - w0) <= DIM_TOL and abs(h - h0) <= DIM_TOL:
                grp.append(m)
                break
        else:
            groups.append([m])
    nlad = 0
    for members in groups:
        if len(members) < 3:
            continue                      # a ladder, not a coincidence of two
        votes = collections.Counter()
        for font, gid in members:
            e = eff[(font, gid)]
            if mark_zone(e) is not None and zone_of(gsets, font, gid) != "spans":
                votes[e] += 1
        if not votes:
            continue
        want, n = votes.most_common(1)[0]
        if n < 2 or n < sum(votes.values()) * 0.75:
            continue                      # the group does not agree with itself
        for font, gid in members:
            if zone_of(gsets, font, gid) != "spans":
                continue
            # Pin it when its own detmap disagrees with its ladder, and ALSO when the
            # detmap agrees but the CONTEXT map carries a contradicting rule: ZONEFLIP is
            # consulted after ctx and overrides it, so without an entry those rules still
            # win at render time. `HQPB4#171` is exactly that - detmap `ِ`, and two shadda
            # rules in every family's ctx.
            bad_ctx = False
            for key in keys_of[(font, gid)]:
                rules = ctx.get(key) or {}
                for _, emit in rules.items():
                    if mark_zone(emit) is not None and emit != want:
                        bad_ctx = True
            if eff[(font, gid)] == want and not bad_ctx:
                continue
            for key in keys_of[(font, gid)]:
                out[key] = want
                nlad += 1
                print(f"  LADDER {font}#{gid:<4} spans the baseline; its ladder reads "
                      f"{want!r}, it read {eff[(font, gid)]!r}  {key}")
    if nlad:
        print(f"  ladder-identity pass fixed {nlad} keys")
    zf_path.write_text(json.dumps(out, ensure_ascii=False, indent=1, sort_keys=True))
    print(f"wrote {zf_path} ({len(out)} keys)")
    if skipped:
        print(f"  no zone-consistent evidence, left alone: {', '.join(skipped)}")

if __name__ == "__main__":
    main()
