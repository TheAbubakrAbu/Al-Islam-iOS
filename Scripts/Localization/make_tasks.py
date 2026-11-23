# -*- coding: utf-8 -*-
"""Write one task file per batch: tasks/<lang>_<NNN>.md. Usage: make_tasks.py <lang> [extra-notes.json]
extra-notes.json (optional): {"labels": "<choices the labels fixed>", "<NNN>": "<note for that batch>"}"""
import json, os, sys
SP = os.path.dirname(os.path.abspath(__file__))
lang = sys.argv[1]
notes = json.load(open(sys.argv[2], encoding="utf-8")) if len(sys.argv) > 2 else {}
WHO = {
    "ml": "Malayalam (language code `ml`; for Kerala's Muslims first, and the Malayali Muslims of the Gulf: "
          "standard modern written Malayalam, with every Islamic word the one Kerala Muslims use)",
    "ta": "Tamil (language code `ta`; for Tamil-speaking Muslims first, in Tamil Nadu, Sri Lanka, Singapore and "
          "Malaysia: standard modern written Tamil, with every Islamic word the one Tamil Muslims use)",
    "nl": "Dutch (language code `nl`; standard Dutch for the Netherlands and Flanders, addressing the reader "
          "with “je” as Apple's Dutch does)",
}[lang]
GLOSS = {"ml": "terminology and the letter-name list", "ta": "terminology and the letter-name list",
         "nl": "terminology"}[lang]
os.makedirs(f"{SP}/tasks", exist_ok=True)
for n in range(1, 20):
    nnn = f"{n:03d}"
    lesson = n <= 8
    lines = [f"# Task: {lang} batch {nnn}", "",
             f"You are translating one batch of the Al-Islam iOS app's interface strings into {WHO}.", "",
             "Read these first, completely, and follow them exactly:",
             f"- {SP}/BRIEF.md (rules, output format, validation"
             + ("" if lesson else "; its last section on the binding labels applies to this batch") + ")",
             f"- {SP}/GLOSSARY_{lang}.md ({GLOSS}; its \"Fixed terms\" are binding)"]
    if not lesson:
        lines.append(f"- {SP}/{lang}/labels.json (the app's agreed labels and name spellings: BINDING)")
    lines += ["", f"Input batch: {SP}/{lang}/todo/todo_{nnn}.json",
              f"Output: {SP}/{lang}/out/{nnn}.json (create the folder if needed)", ""]
    if lesson:
        lines.append("This batch is lesson content (the tajweed course and Arabic letters)"
                     + (": letter names in running prose are written in your script from the glossary list "
                        "(brief rule 7)." if lang != "nl" else ": letter names keep the key's Latin spelling "
                        "(brief rule 7)."))
        lines.append("")
    if not lesson and notes.get("labels"):
        lines += ["Choices the labels fixed that reach beyond them: " + notes["labels"], ""]
    if not lesson and n >= 13:
        lines += ["Tips, credits and captions that name a control use the control's own wording: before quoting "
                  "a page title, button or tone name (Echo, Takbir, Chime, Ring, Alarm, Serene) that is not in "
                  f"labels.json, look up its key's translation in the finished batches of your language "
                  f"({SP}/{lang}/out/*.json, {{English key: translation}}) and quote exactly that.", ""]
    if notes.get(nnn):
        lines += [notes[nnn], ""]
    lines += ["You may read the Swift files an item names (under /Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS) "
              "when a short key's sense is unclear, but do not edit anything outside your output file(s). Validate "
              f"with `./Scripts/localize_catalog.py validate --lang {lang} <file>` from the repository root until "
              "it reports 0 rejected (apart from keys left identical on purpose, which you list). Final message "
              "as the brief says, plus one or two lines on anything in the brief or the validator that got in "
              "your way."]
    open(f"{SP}/tasks/{lang}_{nnn}.md", "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(f"wrote 19 task files for {lang}")
