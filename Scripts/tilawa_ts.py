#!/usr/bin/env python3
"""Evaluate the data literals in a Tilawa TypeScript module with node.

Tilawa (Jamil Hammoudeh, ported with permission) keeps its content as typed object literals in
.ts files. The builders here want the DATA, not a TypeScript toolchain, so this strips the type
dressing (imports, `export type`/`export interface` blocks, `export function` bodies, `as const`,
the annotation on `export const X: T = ...`) and hands the rest to node, which prints the named
constants as JSON. A module whose literals reference helpers would need real transpilation; none
of the corpora ported here do.

    from tilawa_ts import eval_consts
    data = eval_consts(path, ["HADITH_TOPICS", "HADITH_DATABASE"])
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess

_IMPORT = re.compile(r"^import\b[\s\S]*?;\s*$", re.M)
_EXPORT_TYPE = re.compile(r"^export type\b[\s\S]*?;\s*$", re.M)
_EXPORT_INTERFACE = re.compile(r"^export interface\b[\s\S]*?^\}\s*$", re.M)
_EXPORT_FUNCTION = re.compile(r"^export function\b[\s\S]*?^\}\s*$", re.M)
_EXPORT_CONST_TYPED = re.compile(r"^export const (\w+)\s*:[^=]*?=", re.M)
_EXPORT_CONST = re.compile(r"^export const (\w+)\s*=", re.M)
_EXPORT_BRACE = re.compile(r"^export \{[^}]*\}[^\n]*$", re.M)
_AS_CONST = re.compile(r"\s+as const\b")


def strip_ts(source: str) -> str:
    source = _IMPORT.sub("", source)
    source = _EXPORT_TYPE.sub("", source)
    source = _EXPORT_INTERFACE.sub("", source)
    source = _EXPORT_FUNCTION.sub("", source)
    source = _EXPORT_BRACE.sub("", source)
    source = _EXPORT_CONST_TYPED.sub(r"const \1 =", source)
    source = _EXPORT_CONST.sub(r"const \1 =", source)
    source = _AS_CONST.sub("", source)
    return source


def eval_consts(path: pathlib.Path | str, names: list[str], prelude: str = "") -> dict:
    """The named top-level constants of the module, as Python data (a dict keyed by name)."""
    source = pathlib.Path(path).read_text(encoding="utf-8")
    body = prelude + "\n" + strip_ts(source)
    payload = "{" + ",".join(f"{n}: (typeof {n} === 'undefined' ? null : {n})" for n in names) + "}"
    script = body + "\nprocess.stdout.write(JSON.stringify(" + payload + "));\n"
    result = subprocess.run(["node", "-"], input=script.encode("utf-8"), capture_output=True)
    if result.returncode != 0:
        raise SystemExit(f"node failed on {path}:\n{result.stderr.decode('utf-8')[:2000]}")
    return json.loads(result.stdout.decode("utf-8"))


def eval_modules(paths: list[pathlib.Path | str], names: list[str]) -> dict:
    """Several modules concatenated (imports between them removed), then the constants read."""
    body = "\n".join(strip_ts(pathlib.Path(p).read_text(encoding="utf-8")) for p in paths)
    payload = "{" + ",".join(f"{n}: (typeof {n} === 'undefined' ? null : {n})" for n in names) + "}"
    script = body + "\nprocess.stdout.write(JSON.stringify(" + payload + "));\n"
    result = subprocess.run(["node", "-"], input=script.encode("utf-8"), capture_output=True)
    if result.returncode != 0:
        raise SystemExit(f"node failed:\n{result.stderr.decode('utf-8')[:2000]}")
    return json.loads(result.stdout.decode("utf-8"))


def xz_compress(body: bytes) -> bytes:
    """xz stream, preset 9e, dictionary no larger than the payload needs (the app decodes it with
    Apple's Compression framework, COMPRESSION_LZMA, which reads the xz container directly)."""
    import lzma
    dict_size = 1 << 16
    while dict_size < len(body) and dict_size < (1 << 26):
        dict_size <<= 1
    filters = [{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME, "dict_size": dict_size}]
    return lzma.compress(body, format=lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, filters=filters)


def load_softener():
    """`soften(text)` from the Hadith Encyclopedia builder: em dashes and spaced hyphens between
    words re-punctuated (colon, comma, parentheses, sentence break); text in {braces} untouched."""
    import importlib.util
    root = pathlib.Path(__file__).resolve().parent
    spec = importlib.util.spec_from_file_location("henc", root / "build_hadeethenc_pack.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.soften
