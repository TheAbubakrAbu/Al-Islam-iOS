#!/usr/bin/env python3
"""Score one or more Ask AI headless logs (the -askAILog file) and print one row per log.

Usage: score.py <log.txt> [<log.txt> ...] [--verbose]

Columns, computed exactly as named in Docs/Product/Ask AI Fix Plan.md, Task 0:
  turns              number of "===== Q:" blocks
  failed             turns with "FAILED: true"
  scholars           answers containing "cholars generally"
  declines           answers containing a decline phrase (DECLINE_PHRASES: "does not cover", "none of the
                     sources", "library has nothing", ...)
  names_stray        turns whose RETRIEVAL lanes contain "names=" while the question has none of
                     the words name, names, husna, attribute, attributes and no word starting with
                     al-, ar-, as- or an-
  history_leak       answers that share 3 or more substantive 6-word shingles with one earlier answer of
                     the same log (a shingle is substantive when at least 2 of its words are neither stop
                     words nor citation boilerplate such as "the words of Allah in Surah"; a lone stock
                     phrase is not a leak, copied content is)
  junk_chips         SUGGESTIONS containing any of: feel, ending, happens, stop, pay, go back, save,
                     hurts, "opposite of", or a token also present in the previous turn's question
                     but absent from this one
  followups          the INTENT lines with followUp=true, listed by question
  intents            question to INTENT, listed
  first_token_median median of "first token Ns" over the turns a model answered (not crisis, not failed)
  total_median       median of "total Ns" over the same turns

--verbose lists the offending questions under each count.
"""

import re
import statistics
import sys

CUE_WORDS = {"name", "names", "husna", "attribute", "attributes"}
ARTICLE_PREFIXES = ("al-", "ar-", "as-", "an-")
JUNK_WORDS = ["feel", "ending", "happens", "stop", "pay", "go back", "save", "hurts", "opposite of"]
STOP = {
    "a", "an", "the", "is", "are", "was", "were", "be", "been", "do", "does", "did", "i", "my", "me",
    "we", "you", "it", "its", "this", "that", "these", "those", "what", "who", "how", "when", "where",
    "why", "which", "can", "could", "should", "would", "to", "of", "in", "on", "for", "about", "with",
    "and", "or", "if", "at", "by", "from", "as", "there", "say", "says", "did", "has", "have", "had",
    "many", "much", "good", "like", "allowed", "haram", "halal", "islam", "quran", "muslim", "prophet",
    "dua", "hadith", "allah", "people", "kind", "being", "name", "names", "after", "before", "back",
    "go", "get", "give", "make", "pray", "prayer", "prayers", "allowed", "ramadan", "day", "days",
    "time", "best", "more", "most", "any", "some", "will", "shall", "want", "need", "know", "think",
    "mean", "means", "meaning", "explain", "example", "tell", "evidence", "schools", "thought",
    "differ", "verses", "verse", "surah", "speak", "speaks", "story", "lessons", "teach", "conditions",
    "common", "mistakes", "doing", "said", "life", "exactly", "virtue", "morning", "evening", "adhkar",
    "does", "detail",
}


BOILERPLATE = set("""allah surah words word prophet peace blessings upon him said says scholar scholars
generally explain explains qualified consulted consult personal ruling guidance quran teachings hadith recorded
sahih bukhari muslim narrated verse ayah sunnah 1 2 3 4 5 6 7 8 al s one
consult consulted circumstances situation tailored own personal""".split())
LEAK_SHINGLES = 3
DECLINE_PHRASES = ("does not cover", "not covered", "nothing on", "library has nothing", "library lacks",
                   "do not address", "does not address", "none of the sources", "sources do not answer",
                   "sources provided do not", "no clear instruction", "not in the sources", "nothing in the sources")


def words(text):
    return re.findall(r"[a-z0-9']+", text.lower())


def content_words(text):
    return {w.strip("'") for w in words(text) if w.strip("'") not in STOP and len(w.strip("'")) > 2}


def parse(path):
    raw = open(path, encoding="utf8", errors="replace").read()
    blocks = re.split(r"^===== Q: ", raw, flags=re.M)
    turns = []
    for block in blocks:
        if not block.strip():
            continue
        head, _, rest = block.partition("\n")
        turn = {"q": head.strip(), "answer": "", "intent": "", "followUp": False,
                "retrieval": "", "suggestions": "", "failed": False, "first": None, "total": None}
        answer_match = re.search(r"^A: (.*)\Z", rest, re.S | re.M)
        if answer_match:
            turn["answer"] = answer_match.group(1).strip()
        for line in rest.split("\n"):
            if line.startswith("INTENT: "):
                parts = line[len("INTENT: "):].split()
                turn["intent"] = parts[0] if parts else ""
                turn["followUp"] = "followUp=true" in line
                m = re.search(r"first token ([0-9.]+)s", line)
                if m:
                    turn["first"] = float(m.group(1))
                m = re.search(r"total ([0-9.]+)s", line)
                if m:
                    turn["total"] = float(m.group(1))
            elif line.startswith("RETRIEVAL: "):
                turn["retrieval"] = line[len("RETRIEVAL: "):]
            elif line.startswith("SUGGESTIONS: "):
                turn["suggestions"] = line[len("SUGGESTIONS: "):]
            elif line.startswith("REMOVED: "):
                turn["failed"] = "FAILED: true" in line
            elif line.startswith("A: "):
                break
        turns.append(turn)
    return turns


def shingles(text, size=6):
    toks = words(text)
    return {" ".join(toks[i:i + size]) for i in range(max(0, len(toks) - size + 1))}


def substantive(shingle):
    return sum(1 for w in shingle.split() if w not in BOILERPLATE and w not in STOP) >= 2


def substantive_shingles(text):
    return {s for s in shingles(text) if substantive(s)}


def score(turns):
    out = {"turns": len(turns), "failed": 0, "scholars": 0, "declines": 0, "names_stray": 0,
           "history_leak": 0, "junk_chips": 0, "followups": [], "intents": [],
           "first_token_median": None, "total_median": None}
    lists = {"scholars": [], "declines": [], "names_stray": [], "history_leak": [], "junk_chips": []}
    earlier_answers = []
    previous_question = None
    firsts, totals = [], []
    for turn in turns:
        q, a = turn["q"], turn["answer"]
        out["intents"].append((q, turn["intent"]))
        if turn["followUp"]:
            out["followups"].append(q)
        if turn["failed"]:
            out["failed"] += 1
        if "cholars generally" in a:
            out["scholars"] += 1
            lists["scholars"].append(q)
        if any(phrase in a.lower() for phrase in DECLINE_PHRASES):
            out["declines"] += 1
            lists["declines"].append(q)
        lanes = turn["retrieval"].split(";")[1] if turn["retrieval"].count(";") >= 1 else ""
        if "names=" in lanes:
            qwords = words(q)
            has_cue = any(w in CUE_WORDS for w in qwords)
            has_article = any(tok.lower().startswith(ARTICLE_PREFIXES) for tok in q.split())
            if not has_cue and not has_article:
                out["names_stray"] += 1
                lists["names_stray"].append(q)
        own = substantive_shingles(a)
        shared = [(len(own & sh), eq) for eq, sh in earlier_answers]
        if shared and max(shared)[0] >= LEAK_SHINGLES:
            out["history_leak"] += 1
            lists["history_leak"].append(f"{q}  <- {max(shared)[0]} shingles from: {max(shared)[1]}")
        earlier_answers.append((q, own))
        chips = turn["suggestions"].lower()
        junk = [w for w in JUNK_WORDS if w in chips]
        if previous_question is not None:
            leaked = (content_words(previous_question) - content_words(q)) & content_words(chips)
            junk += sorted(leaked)
        if junk:
            out["junk_chips"] += 1
            lists["junk_chips"].append(f"{q}  <- {', '.join(junk)}")
        previous_question = q
        # Medians over the turns a model answered: a crisis reply or a failed turn logs 0.0.
        if turn["first"] is not None and turn["first"] > 0 and not turn["failed"] and turn["intent"] != "crisis":
            firsts.append(turn["first"])
        if turn["total"] is not None and turn["total"] > 0 and not turn["failed"] and turn["intent"] != "crisis":
            totals.append(turn["total"])
    if firsts:
        out["first_token_median"] = statistics.median(firsts)
    if totals:
        out["total_median"] = statistics.median(totals)
    return out, lists


def main(argv):
    verbose = "--verbose" in argv
    paths = [a for a in argv if a != "--verbose"]
    if not paths:
        print(__doc__)
        return 2
    header = ["log", "turns", "failed", "scholars", "declines", "names_stray", "history_leak",
              "junk_chips", "first_tok", "total"]
    print("  ".join(f"{h:>12}" if i else f"{h:<28}" for i, h in enumerate(header)))
    details = []
    for path in paths:
        turns = parse(path)
        out, lists = score(turns)
        row = [path[-28:], out["turns"], out["failed"], out["scholars"], out["declines"],
               out["names_stray"], out["history_leak"], out["junk_chips"],
               f"{out['first_token_median']:.1f}s" if out["first_token_median"] is not None else "-",
               f"{out['total_median']:.1f}s" if out["total_median"] is not None else "-"]
        print("  ".join(f"{str(c):>12}" if i else f"{str(c):<28}" for i, c in enumerate(row)))
        details.append((path, out, lists))
    for path, out, lists in details:
        print(f"\n== {path}")
        print("followups: " + (" | ".join(out["followups"]) or "none"))
        print("intents:   " + " | ".join(f"{q} -> {i}" for q, i in out["intents"]))
        if verbose:
            for key, items in lists.items():
                if items:
                    print(f"{key}:")
                    for item in items:
                        print(f"  - {item}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
