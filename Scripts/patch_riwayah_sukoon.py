#!/usr/bin/env python3
"""Bring the 19 riwayah texts to the app's own sukoon convention (Scripts/sukoon.py).

    python3 Scripts/patch_riwayah_sukoon.py            # patch, rebuild, verify
    python3 Scripts/patch_riwayah_sukoon.py --dry-run  # list what would change

The Hafs text is clean (the proof in sukoon.py). The other riwayah texts each carried one stray:
فَٱدَّٰرَأْتُمۡ at 2:71 (2:72 in the counts that number the basmalah) with U+0652 ARABIC SUKUN on the
hamza where the convention, and the Hafs text of the same word, writes U+06E1; Khalaf and Khallad
also typed a U+06E1 onto the long-vowel waw of وَيَنتَجُونَ (58:8). `normalize_sukoon` is applied to
every word of every text and the changed words are listed, so a run that changes anything else
is a run to look at before committing.

What is rewritten, in place, with the formatting the files already use (compact JSON, UTF-8):
  Resources/Data/Quran/Qiraah*.json.deflate         the 12 beta texts (raw deflate)
  Resources/JSONs-Deprecated/Qiraat/Qiraah*.json    the 7 KFGQPC sources
  Resources/Data/Quran/qiraat.qpk                   the 7 KFGQPC texts as the app reads them
                                                    (through Scripts/reblock_packs.py's Qpk)
and then `Scripts/build_solidpacks.py` rebuilds qiraah.solidpack from the 12 deflates. The run
ends by re-reading qiraat.qpk and checking its seven readings against the seven patched JSONs,
and by running `python3 Scripts/sukoon.py`, which now refuses any stray in the 19 texts.
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import subprocess
import sys
import zlib

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from sukoon import RIWAYAH_TEXTS, normalize_sukoon, riwayah_strays, riwayah_text  # noqa: E402
import reblock_packs  # noqa: E402

ROOT = HERE.parent
DATA = ROOT / "Resources" / "Data" / "Quran"
QIRAAT_QPK = DATA / "qiraat.qpk"
KFGQPC = {"warsh": "QiraahWarsh", "qaloon": "QiraahQaloon", "duri": "QiraahDuri", "susi": "QiraahSusi",
          "bazzi": "QiraahBuzzi", "qunbul": "QiraahQunbul", "shubah": "QiraahShubah"}


def dumps(obj) -> bytes:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


def patch_text(path: pathlib.Path, dry_run: bool) -> list[tuple[str, str, str]]:
    raw = path.read_bytes()
    packed = path.name.endswith(".deflate")
    data = riwayah_text(path)
    if dumps(data) != (zlib.decompressobj(-zlib.MAX_WBITS).decompress(raw) if packed else raw):
        raise SystemExit(f"{path.name}: not the compact JSON this script knows how to rewrite losslessly")
    changed = []
    for surah, ayahs in data.items():
        for ayah in ayahs:
            words = ayah["text"].split(" ")
            fixed = [normalize_sukoon(w) for w in words]
            for w, f in zip(words, fixed):
                if w != f:
                    changed.append((f"{surah}:{ayah['id']}", w, f))
            if fixed != words:
                ayah["text"] = " ".join(fixed)
    if changed and not dry_run:
        payload = dumps(data)
        if packed:
            packer = zlib.compressobj(9, zlib.DEFLATED, -zlib.MAX_WBITS)
            payload = packer.compress(payload) + packer.flush()
        path.write_bytes(payload)
    return changed


def rebuild_qpk(dry_run: bool) -> list[tuple[str, str, str]]:
    pack = reblock_packs.Qpk(QIRAAT_QPK.read_bytes(), "qiraat")
    if len(pack.blocks) != 1:
        raise SystemExit("qiraat.qpk is not one solid block; run Scripts/reblock_packs.py first")
    raw = pack.blocks[0]["raw"]
    c = reblock_packs.Cursor(raw)
    out = bytearray()
    changed = []
    for key, counts, _block in pack.entries:
        key = bytes(key).decode("utf-8") if not isinstance(key, str) else key
        for sid, n in counts:
            for _ in range(n):
                aid = c.u32()
                text = c.string()
                words = text.decode("utf-8").split(" ")
                fixed = [normalize_sukoon(w) for w in words]
                for w, f in zip(words, fixed):
                    if w != f:
                        changed.append((f"{key} {sid}:{aid}", w, f))
                out += aid.to_bytes(4, "little") + reblock_packs.string_field(" ".join(fixed).encode("utf-8"))
    if c.remaining:
        raise SystemExit(f"qiraat.qpk: {c.remaining} bytes past the last reading")
    if changed and not dry_run:
        pack.blocks[0]["raw"] = bytes(out)
        QIRAAT_QPK.write_bytes(pack.serialize())
    return changed


def check_qpk_against_json() -> None:
    pack = reblock_packs.Qpk(QIRAAT_QPK.read_bytes(), "qiraat")
    for key, ayahs in pack.records():
        key = bytes(key).decode("utf-8") if not isinstance(key, str) else key
        source = riwayah_text(ROOT / "Resources" / "JSONs-Deprecated" / "Qiraat" / f"{KFGQPC[key]}.json")
        expected = [(int(s), a["id"], a["text"].encode("utf-8")) for s in sorted(source, key=int) for a in source[s]]
        if [(s, a, t) for s, a, t in ayahs] != expected:
            raise SystemExit(f"qiraat.qpk reading {key} does not match {KFGQPC[key]}.json after the patch")
    print("qiraat.qpk: all seven readings match their JSON sources")


def main() -> None:
    dry_run = "--dry-run" in sys.argv
    total = 0
    for path in RIWAYAH_TEXTS(ROOT):
        for where, word, fixed in patch_text(path, dry_run):
            print(f"  {path.name:34} {where:8} {word} -> {fixed}")
            total += 1
    for where, word, fixed in rebuild_qpk(dry_run):
        print(f"  {'qiraat.qpk':34} {where:14} {word} -> {fixed}")
        total += 1
    print(f"{total} words {'would change' if dry_run else 'changed'}")
    if dry_run:
        return
    before = {p.name: hashlib.md5(p.read_bytes()).hexdigest() for p in DATA.glob("*.solidpack")}
    subprocess.run([sys.executable, str(HERE / "build_solidpacks.py")], check=True)
    for p in DATA.glob("*.solidpack"):
        if p.name != "qiraah.solidpack" and hashlib.md5(p.read_bytes()).hexdigest() != before[p.name]:
            raise SystemExit(f"{p.name} changed but only qiraah.solidpack should have")
    check_qpk_against_json()
    if riwayah_strays(ROOT):
        raise SystemExit("ERROR: strays remain after the patch")
    subprocess.run([sys.executable, str(HERE / "sukoon.py")], check=True)


if __name__ == "__main__":
    main()
