"""Blame the exact glyph for each character-level difference.

render_det returns a flat string, so re-render token by token, keep a char->glyph map,
then align got vs expected and attribute every insertion/replacement to the glyph whose
emitted span covers that offset. Aggregates by glyph key so the real culprits rank first.
"""
import sys, json, collections, difflib
sys.path.insert(0, ".")
import final, extract

FAM = "kufi"

def render_spans(glyphs, detmap, ctx):
    """Same emission as render_det, but per-token so offsets stay attributable."""
    spans = []
    for i in range(len(glyphs)):
        one = final.render_det(glyphs[i:i + 1], detmap, None, FAM, ctx)
        f, c = glyphs[i]
        key = "sp| " if f == "sp" else f"{f}|{c}"
        spans.append((key, one))
    return spans

def main():
    detmap = final.build_detmap(FAM)
    ctx = json.loads(open(f"data/ctxdet-{FAM}.json").read())
    seg = json.loads(open("data/shubah.surahs.json").read())
    truth = extract.overlay(extract.BRIDGES["shubah"])
    blame = collections.Counter()
    samples = collections.defaultdict(list)
    for sid in range(1, 115):
        vol = seg["data"][sid - 1]
        app = truth[sid]
        if len(vol) != len(app):
            continue
        for k, (glyphs, (aid, text)) in enumerate(zip(vol, app)):
            if k == 0:
                continue
            got = final.render_det(glyphs, detmap, None, FAM, ctx)
            if got == text:
                continue
            spans = render_spans(glyphs, detmap, ctx)
            joined = "".join(s for _, s in spans)
            if joined.replace(" ", "") != got.replace(" ", ""):
                continue  # post-passes rewrote it; not attributable token-wise
            owner, pos = [], 0
            for key, s in spans:
                for _ in s:
                    owner.append(key)
                pos += len(s)
            sm = difflib.SequenceMatcher(None, joined, text, autojunk=False)
            for op, i1, i2, j1, j2 in sm.get_opcodes():
                if op == "equal":
                    continue
                idx = min(i1, len(owner) - 1)
                if idx < 0:
                    continue
                key = owner[idx]
                blame[key] += 1
                if len(samples[key]) < 2:
                    samples[key].append((f"{sid}:{aid}", joined[max(0,i1-6):i2+6], text[max(0,j1-6):j2+6]))
    print("glyphs ranked by attributed character errors:")
    for key, n in blame.most_common(18):
        print(f"  x{n:<5} {key!r:44} -> {detmap.get(key)!r}")
        for loc, g, e in samples[key][:1]:
            print(f"          {loc}  {g!r} => {e!r}")

if __name__ == "__main__":
    main()
