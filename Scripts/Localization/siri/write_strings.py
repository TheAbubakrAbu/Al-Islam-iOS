#!/usr/bin/env python3
"""Write Resources/<lang>.lproj/AppShortcuts.strings and the Watch copy from siri/<lang>.json, in the French
files' key order (the Watch copy takes exactly the Watch French keys)."""
import json, os, re, sys
REPO = "/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS"
HERE = os.path.dirname(os.path.abspath(__file__))
NAMES = {"de": "German", "es": "Spanish", "nl": "Dutch"}
def keys(path):
    return re.findall(r'^"((?:[^"\\]|\\.)*)"\s*=', open(path, encoding="utf-8").read(), re.M)
def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')
for lang in sys.argv[1:]:
    d = json.load(open(os.path.join(HERE, lang + ".json"), encoding="utf-8"))
    for watch in (False, True):
        src = os.path.join(REPO, "Resources", "Watch" if watch else "", "fr.lproj", "AppShortcuts.strings")
        ks = keys(src)
        assert all(k in d for k in ks), [k for k in ks if k not in d]
        head = ("/* Siri and Shortcuts phrases in %s: one per English phrase in iPhone/Settings/System/AppIntents.swift\n"
                "   (the key). ${applicationName}, ${surah} and ${prayer} stay as written. A .strings file, not a String\n"
                "   Catalog: AppShortcuts.xcstrings needs iOS 17 and watchOS 10, above this app's floor.%s */\n\n") % (
                NAMES[lang], " The Watch copy leaves\n   out the Open Surah phrases, whose intents are iPhone only." if watch else "")
        body = "".join('"%s" = "%s";\n' % (esc(k), esc(d[k])) for k in ks)
        out = os.path.join(REPO, "Resources", "Watch" if watch else "", lang + ".lproj", "AppShortcuts.strings")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        open(out, "w", encoding="utf-8").write(head + body)
        print(out, len(ks))
