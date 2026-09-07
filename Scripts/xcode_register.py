#!/usr/bin/env python3
"""Register a new file in Al-Islam.xcodeproj exactly like an existing sibling.

    ./Scripts/xcode_register.py <new-file> --like <existing-file>

Both paths are repo-relative. The new file joins the sibling's group and every build phase the
sibling is in (Sources for Swift, Resources for data), with fresh UUIDs. Idempotent: a file the
project already references is left alone. The project uses classic groups, not synchronized
folders, so every added source or resource needs this (or Xcode).
"""
import re, sys, uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PBX = ROOT / "Al-Islam.xcodeproj/project.pbxproj"


def new_uuid():
    return uuid.uuid4().hex[:24].upper()


def register(new_path: str, like: str) -> None:
    text = PBX.read_text()
    new_name = Path(new_path).name
    like_name = Path(like).name
    if re.search(r"/\* " + re.escape(new_name) + r" \*/ = \{isa = PBXFileReference", text):
        print(f"{new_name}: already in the project")
        return
    ref = re.search(
        r"^\t\t([0-9A-F]{8,32}) /\* " + re.escape(like_name) + r" \*/ = \{isa = PBXFileReference;(.*)$",
        text, re.M)
    if not ref:
        sys.exit(f"{like_name}: no PBXFileReference to mirror")
    like_ref, ref_tail = ref.group(1), ref.group(2)
    new_ref = new_uuid()
    ref_line = f"\t\t{new_ref} /* {new_name} */ = {{isa = PBXFileReference;{ref_tail.replace(like_name, new_name)}"
    text = text[:ref.end()] + "\n" + ref_line + text[ref.end():]

    # Build files: one per phase the sibling sits in.
    builds = list(re.finditer(
        r"^\t\t([0-9A-F]{8,32}) /\* " + re.escape(like_name) + r" in (Sources|Resources) \*/ = \{isa = PBXBuildFile; fileRef = "
        + like_ref + r" /\* " + re.escape(like_name) + r" \*/;(.*)$", text, re.M))
    if not builds:
        sys.exit(f"{like_name}: no PBXBuildFile entries to mirror")
    additions = []
    for build in reversed(builds):
        like_build, phase, tail = build.group(1), build.group(2), build.group(3)
        new_build = new_uuid()
        line = (f"\t\t{new_build} /* {new_name} in {phase} */ = {{isa = PBXBuildFile; fileRef = {new_ref} "
                f"/* {new_name} */;{tail}")
        text = text[:build.end()] + "\n" + line + text[build.end():]
        additions.append((like_build, new_build, phase))
    # Phase file lists.
    for like_build, new_build, phase in additions:
        entry = re.search(r"^\t\t\t\t" + like_build + r" /\* " + re.escape(like_name) + r" in " + phase + r" \*/,$",
                          text, re.M)
        if not entry:
            sys.exit(f"{like_name}: build file {like_build} is in no {phase} phase list")
        text = text[:entry.end()] + f"\n\t\t\t\t{new_build} /* {new_name} in {phase} */," + text[entry.end():]
    # Group membership.
    child = re.search(r"^\t\t\t\t" + like_ref + r" /\* " + re.escape(like_name) + r" \*/,$", text, re.M)
    if not child:
        sys.exit(f"{like_name}: not a child of any group")
    text = text[:child.end()] + f"\n\t\t\t\t{new_ref} /* {new_name} */," + text[child.end():]
    PBX.write_text(text)
    print(f"{new_name}: registered like {like_name} ({len(additions)} phase(s))")


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 3 or args[1] != "--like":
        sys.exit(__doc__)
    register(args[0], args[2])
