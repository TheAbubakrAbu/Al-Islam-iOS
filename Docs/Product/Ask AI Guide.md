# Ask AI Guide

How the Ask AI chat works after the 2026-09-28 rebuild, where each piece lives, how to test it
headlessly, and what the measurements said. Written for whoever changes it next.

## What it is

A conversation with Apple's foundation model about the Quran, the hadith and Islam, grounded in the
app's own data. The model never quotes scripture from memory: every question is searched across the
app's packs, the best passages are handed to the model as numbered sources with their provenance,
the model cites by number, and the app renders each cited source as a quote card: the app's own text
verbatim, the Arabic where there is one, and a footer saying where it comes from (surah and
translation; collection, compiler, chapter, narrator and grade; tafsir author; article; dua reference;
setting path).

Runs on the on-device model (iOS 26 with Apple Intelligence). Private Cloud Compute (iOS 27, 32k
context) is wired but off: see "Private Cloud Compute" below.

## The files (iPhone/Helpers/, iPhone target only)

| File | Owns |
| --- | --- |
| `AskAISources.swift` | `AskAISource` (kind, reference, title, verbatim text, Arabic, transliteration, provenance facts, aliases, subject flag) and `AskAISourceFactory`, which builds one from an ayah, hadith, tafsir entry, surah background, article section, Name of Allah, dua (app collections and Hisn al-Muslim), tip, settings entry, or today's prayer times. `promptLine` is what the model reads. `clip` cuts at a sentence end. |
| `AskAIIntent.swift` | `AskAIIntent` (greeting, thanks, farewell, capabilities, smallTalk, sourceQuestion, recap, crisis, appHelp, prayerTimes, reference, scripture, hadith, define, howTo, ruling, story, dua, general), each with `retrieves`, token cap, temperature and a task line. `AskAIQuestion.analyze` classifies, detects follow-ups, extracts content words (ruling words such as "haram" steer the intent but never the search), expands synonyms (`AskAILexicon`, English and Arabic terms both ways; `canonicalTopic` gives the head a chip names a topic by) and adds phrase hints ("how much" searches as amount, rate, nisab). |
| `AskAICrisis.swift` | `AskAICrisis`: `isCrisis` (a first-person expression of suicidal intent or self-harm: one English regex over the folded text, and one Arabic and Urdu regex over the same text with the hamza forms folded to the bare letters, since `fold` keeps them), `mentionsSelfHarm` (a question ABOUT it, in the three languages), the reply the app writes itself (translated to Arabic and Urdu in the catalog), `helpLine(regionCode:)` (988 in the US and Canada, Samaritans in the UK and Ireland, Lifeline in Australia, 1737 in New Zealand, Tele-MANAS in India, findahelpline.com elsewhere; digits follow the locale), `helpLineAction(regionCode:)` (the same as a `tel:` or web link with a button label), its two chips (English, like every chip; the Quran one only with `HAS_QURAN`) and its sources (94:5, the Hisn dua for anxiety and sorrow). |
| `AskAIRetrieval.swift` | `AskAIRetriever.retrieve`: the lanes (subject, surahName, carried, prayer, tips, settings, articles, keyEvidence, quranSemantic, quranKeyword, quranTopics, hadithSemantic, hadithRanked, hadithTopics, names, duas), reciprocal-rank fusion with per-intent weights, a 60% per-family diversity cap, subjects first. A how-to swaps in the article's step section; a follow-up also searches the sections of the article the previous answer cited; a Name is retrieved (`exactNames`) or made the subject (`typedNames`) only when typed with its article ("as-salam", "al wadood", "assalam") or beside a Names cue (name, names, husna, asmaul, attribute: "the name wali", "is aziz a good name"), never as a bare English word (spelling-folded, "mother" was Al-Musawwir and "money" Al-Mani), and a Name-only question skips the hadith lanes. `duaTopicWords()` is the set of topics the app has a dua for, for the chips. Hadith text blocks are inflated off the main actor before their sources are built; the dua catalogues are folded once. Non-subject sources carry `focusTerms`, so a long one is clipped around the sentence that matched. `prewarm()` readies the indexes on appear. `keyEvidence` (2026-11-16, the smallest version of the review's rec 10) maps a lexicon canonical topic to the verses (optionally with Ibn Kathir on them) and hadiths a scholar opens first, weighted 8 so they lead every turn on that topic; it holds only "music" so far (Bukhari 5590, 31:6 with Ibn Kathir, Ibn Majah 4020, Bukhari 952), because no search lane ever found 5590 on its own. Add a topic only with sources checked in the app's own text. |
| `AskAIEngine.swift` | `AskAIProfile` (per-engine budgets), `AskAIEngine` (session creation, streaming with the repetition cut, error classification for both error families, the cloud offer gate), `AskAIPrompt` (the instructions, the prompt builder, the clipped history, the reference task by subject kind). |
| `AskAIText.swift` | Hygiene (echo labels, markdown, loops, trailing reference lists, copied source lines, em dashes, sentence capitalization with the proper nouns and surah names restored), citation markers (`normalizeMarkers`, `citedSources` by number then by reference or alias), `policeCitations` (recalled parenthetical references), `policeQuotations` (quotes of five or more words not in any source; an elided quote is verified piece by piece in one source), `EchoGuard` (paragraphs that repeat an earlier answer), `attributedAnswer` (markers as raised accent numerals), `shareText`, `suggestions`. |
| `AskAIConversation.swift` | `AskAIConversation.shared`: the messages, ask/cancel/reset/retryLast, the crisis short circuit, the retry policy (leaner on overflow; a guardrail decline is shown as one, with the sources, and never re-asked from general knowledge; on-device fallback when the cloud fails before its first word), stream coalescing at 0.1 s, persistence in Documents/askai-conversation.json (see "Persistence" below), the `-askAILog` writer. |
| `AskAIChat.swift` | `AskAIChatView`, `AskAIChatSheet(initialQuestion:)` (the entry-point signature every search screen uses), the welcome, the answer card, the source card, the composer, `AskAISourceDestination` (what a card opens). |
| `OnDeviceAsk.swift` | The summarize sheets' model access, `isAvailable`, `supportsArabic`, `repetitionCutoff`. No chat code any more. |

## A turn, step by step

0. Before any analysis, `AskAICrisis.isCrisis` reads the message. A first-person expression of
   suicidal intent or self-harm ("I feel like ending my life", "I want to kill myself") gets the
   app's own reply: no model, no retrieval, a help line for the device's region, two chips, the
   verse 94:5 and the Hisn dua for anxiety as sources. The turn is logged with INTENT `crisis` and
   RETRIEVAL "crisis reply, no model". The crisis ends the thread: `completedTurns(in:)` and
   `previousReply(in:)` start after the last crisis reply and the topic is cleared, so a "why?"
   after it cannot continue the earlier subject (hell, in the review's own order) or carry the
   crisis text to the model. The card has no AI label, engine badge or AI caution: it is the app's
   words, under the app's localized name, with the help line as a button beneath the text
   (`Message.offersHelpLine`: "Call 988" dials, "Find a helpline" opens findahelpline.com). The
   model on its own retrieved 10:7 and Al-Fil and spoke of a "wretched resting place".
   A question ABOUT suicide ("Is suicide haram?", "Is it haram to commit suicide?") is a question:
   answered normally, with the help line as its note and button whether or not the answer came,
   and with the crisis chips instead of templated ones. The shapes that also fit a question (commit
   suicide, self harm, going to die) need a first-person subject; "cut myself shaving" and "cant go
   on Hajj" are excluded. Arabic and Urdu first-person shapes ("أريد أن أموت", "أفكر في الانتحار",
   "میں مرنا چاہتا ہوں", "خودکشی کرنا چاہتا ہوں", "خود کو نقصان پہنچاتا ہوں") are matched the same
   way; "هل الانتحار حرام؟" and "کیا خودکشی حرام ہے؟" are questions. The wording lists are a
   machine pass and need a native reader. Note that with an Arabic or Urdu per-app language the
   whole feature is absent (`SystemLanguageModel.availability` reports `modelNotReady` and
   `supportsLocale(ar)` is false on the iOS 27 simulator; the Ask AI row and screen need
   `OnDeviceAsk.isAvailable`), so the Arabic and Urdu detection serves readers who type those
   languages into an English interface, and the Arabic and Urdu reply strings wait for Apple's
   model to support the languages (`-forceAskAIRow` shows the screen regardless, for a look).
   `AskAICrisisTests` holds the positive and negative tables in all three languages: add every
   new phrasing there first.
1. `AskAIQuestion.analyze` decides the intent and whether it is a follow-up (a short message with
   fewer than two substantive words, unless shaped like a whole question such as "what is tawhid";
   or a short one that opens like a continuation or leans on a pronoun). Four things are NOT
   follow-ups: a possessive after a subject ("can a man hit HIS wife"), a demonstrative before a
   word that is not a source noun ("is THIS game allowed", against "is THAT hadith authentic" or
   "the ruling on THIS issue": `sourceNouns` holds verse, hadith, issue, matter, practice, sin...),
   the expletive "is it ... to" ("is it haram to dye my hair"; "is it THE SAME for women" points
   back), and a continuation starter on a message with two or more substantive words ("what did the
   Prophet say about his neighbours"). A follow-up searches with the conversation's topic prepended
   and keeps the previous turn's sources in the pool, stripped of their subject mark. A prayer
   question is today's schedule only when it asks about the clock (when, what time, how long, is
   it ... yet, today, tonight, next) and carries no fiqh word (combine, shorten, missed, travel,
   valid, should, makruh...): "Can I combine prayers when traveling?" is a ruling. A clock opening
   with a day word overrides the fiqh word: "What time should I pray Fajr tomorrow?" wants the time;
   "I missed Isha tonight, can I still pray it?" does not.
2. Conversation intents skip retrieval. `sourceQuestion` ("who narrated that?") and `recap`
   ("summarize that") reuse the previous answer's cited sources. Everything else runs
   `AskAIRetriever.retrieve` under the engine's budget (on device: 8 sources of 500 characters,
   subjects 1,400; 12 of 600 once `SystemLanguageModel.contextSize` reports 8,192 or more).
   `AskAIPrompt.fit` estimates the window at 3.4 characters a token with the instructions' real
   length, then (iOS 26.4+) measures the built prompt with the model's own `tokenCount` and drops
   the lowest-ranked source until it fits; the RETRIEVAL log line ends `window=4096 instructions=895`.
3. `AskAIPrompt.build` writes SOURCES, the task line and the question. The earlier turns
   ("context only; never repeat") go in ONLY for a follow-up, a thanks, a goodbye or a recap
   (`sendsHistory`): sent on every turn, the hell answer leaked into the suicide turn and the socks
   answer into a question about a gift. The instructions carry no example narrator, surah or
   phrase: the on-device model copied "Abu Hurairah narrated, in Sahih al-Bukhari" from an example
   into answers about verses, wrote "scholars generally explain" (from rule 3's old sample) in 25 of
   38 review answers with invented content behind it, and ended 5 of 6 answers with "the app's
   library has nothing on this" when that sentence was offered as the way to decline. Rule 3 now
   describes the decline (one sentence of its own, no filling from memory, no view attributed to
   scholars unless a source states it) and says to add no such remark when the sources do answer.
4. The answer streams; each flush strips markdown, normalizes markers, drops echoed paragraphs and
   em dashes, and re-parses the citations so the cards track the text.
5. On settle: repetition collapsed, out-of-range markers and recalled references removed and
   counted, unverified quotations marked, trailing reference lists dropped, suggestions built, the
   conversation saved. The chips (`AskAIText.suggestions`) name the topic by its synonym HEAD
   (`AskAILexicon.canonicalTopic(in:)`: "zakat" is charity, "mother" is parents; a word that IS a
   head beats one that only belongs to a row, so "celebrating Eid" is about Eid and not birthdays;
   `displayTopic` capitalizes proper nouns and names the prophets by their Quranic names, Musa and
   Ayyub) or say "this" when the question's words are outside the table; they never reuse the
   previous turn's topic, offer a dua only when `AskAIRetriever.duaTopicWords()` holds the TOPIC
   (its head or one of its two synonyms, not any word of the question: "prophet" is in dozens of
   Hisn titles), never ask for an "opposite", and for a greeting show the day's starters
   (`AskAIStarters.forDay`, the same pool as the empty screen).
   Before this the chips were templates over leftover words ("Is there a dua about punishment zina?",
   "What is the opposite of mahr?") and a misread follow-up carried "go back sleep after fajr" into
   a question about hair dye.

## Headless testing

Use the iOS 27 iPhone 17 Pro simulator. The iOS 26.5 runtime's model fails every generation under
Xcode 27 (measured 2026-09-28).

```
xcrun simctl launch <udid> com.Quran.Elmallah.Islamic-Pillars \
  -launchTabIslam -islamDestination askAI -askAILog -askAIReset \
  -skipNotificationPrompt -travelingMode 0 \
  -askAI "hello||What does the Quran say about patience?||why?||who narrated that hadith?"
```

`-askAI "q1||q2"` asks the questions in turn as each answer settles; `-askAIReset` starts from an
empty transcript (the conversation persists otherwise); `-askAILog` appends every finished turn to
the container's Documents/askai-log.txt with intent, follow-up flag, engine, retrieval timing and
lane counts, the fused ranking, the sources, the citations, the removed and flagged counts, the
suggestions and the answer; `-askAILogPrompt` also writes the last prompt to Documents/askai-prompt.txt.
Read the log, not the screen: it is where the fabricated references and echoed answers show.

`Scripts/qa/askai/run.sh <questions.txt> <out.txt>` does the launch above for a file of questions
(one per line) on the iOS 27 iPhone 17 Pro, waits for every turn and copies the log out;
`Scripts/qa/askai/score.py <log> [<log>...]` prints one row per log: turns, failed, scholars
("cholars generally"), declines, names_stray (the Names lane fired with no cue word and no article),
history_leak (three or more substantive six-word shingles shared with an earlier answer), junk_chips,
plus the follow-up flags and intents per question (`--verbose` lists the offenders). The review's
38 questions are `questions-hard.txt`, `questions-everyday.txt` and `questions-collide.txt`, with
their 2026-11-05 logs in `baseline-2026-11-05/` and the post-fix logs in `after-2026-11-07/` (the
evening's minors pass, chips and routing, in `after-2026-11-07b/`). The timing medians count only
the turns a model answered (a crisis reply and a failed turn log 0.0). Run the harness on a
simulator of its own: a unit-test run reinstalls the app and kills a replay. The model varies run
to run, so compare counts over a whole set, never one answer.

`-askAIForceDecline` (DEBUG) makes every generation fail the way a guardrail decline does, so the
decline card (the decline sentence, then SOURCES THE APP FOUND in the open, retry in the header)
can be looked at: the permissive model declined none of the questions tried, so nothing else
shows it. `-forceAskAIRow` lists the screen where Apple Intelligence is missing (an Arabic or
Urdu per-app language, say), and a crisis turn renders there since it needs no model.

`-askAITextProbe` runs the pure text functions (markers, citation policing, the clock-time mask,
intent routing, the focus clip, lenient decoding) on the inputs that broke them, with no model and
no retrieval, and logs one `ASKAI PROBE PASS|FAIL` line per case and a final failure count:
`log stream --predicate 'process == "iPhone" AND eventMessage CONTAINS "ASKAI PROBE"'` started
before the launch. Add a case there for every new bug in `AskAIText`, `AskAIIntent` or the source
model. With `-renderCounter`, a turn's hadith text blocks log `HADITH BLOCK ... bg`; a `MAIN` there
is a regression.

## What the measurements said (2026-09-28, on device, iOS 27 simulator)

- Before the rebuild: "hello" retrieved five hadiths, "how do I change the reciter" retrieved
  Taraweeh, and the one answer that generated quoted a verse from memory with no citation.
- After seven rounds, a 15-turn regression (greetings, patience and its "why?", "who narrated that
  hadith?", "bukhari 1", tawhid, the reciter setting, the story of Yusuf, thanks, salam, a dua for
  anxiety, today's Maghrib, 2:255, bye) settled with zero removed citations, zero unverified
  quotations, no guardrail refusal, every intent routed as intended, and 2 to 12 seconds a turn.
- "who narrated that hadith?" answers from the provenance beside the cited source ('Amr bin Taghlib
  for Bukhari 923); "bukhari 1" names 'Umar; "when is maghrib today?" reads the app's own
  timetable; "what breaks wudu?" answers from the wudhu article's own "What breaks wudhu" section;
  "how much is it?" after "what is zakat" pulls the zakat guide's "Calculate 2.5%" section to the
  top and answers with the rate above the nisab; "who has to pay it?" answers from the same guide.
- A bare "why?" used to come back with the same two verses re-quoted: sources the previous answer
  cited are marked "you already quoted this: build on it" and the follow-up task asks for the
  reasoning or a source not yet used; verified, the follow-up cited the Yaqub article and two
  hadiths instead. The Eid singing hadith was once read backwards ("leave them" as rejecting
  instruments): the instructions now say to read a hadith whole, since a phrase inside it may be a
  Companion's objection the Prophet answered; verified. The first token still takes 10 to 20
  seconds when two simulators share the host model. The source cards under every answer are what
  make the remaining slips checkable.
- Traps found on the way: the model copies an example narrator from the instructions into every
  answer (the instructions now carry no example); it pastes the SOURCES block into an answer when
  a how-to asks for numbered steps (`droppingSourceEchoes`); short quotations mispaired the quote
  regex; a citation marker at position 0 with no sources built a negative range and crashed the
  app mid-stream (the location check in `normalizeMarkers`).
- That check did NOT fix the other crash on the same line: `(1...sourceCount).contains(n)` traps
  whenever `sourceCount` is 0, which is every sourceless turn (a greeting, thanks, the second
  guardrail retry, a recap after a sourceless turn) that writes "[1]" anywhere. Both crash reports
  of 2026-09-28 (10:29 and 10:49) were this. The test is now `n >= 1, n <= sourceCount`; never
  build a closed range from a count that can be zero.

## Hardening pass (2026-09-28, Quality Guide Phase 0)

What changed, and the questions that now route or render correctly. Keep these in the regression
batch (`-askAI`) and in `-askAITextProbe`:

- Zero sources: "hello", "thanks", "[1] Wa alaikum assalam!" as a reply. No crash; the marker goes.
- A reply that stops early keeps its "(The answer stopped early...)" line: the failure path flushes
  what streamed, and `finishReply` stops the trailing flush first, so no flush lands after it.
- "repeat that", "say it again": a recap and a source question get an empty echo guard (it used to
  erase the whole rework), and an answer that polices down to nothing is a failure with Ask Again,
  never an empty card reading "Thinking..." for good.
- App help is decided by whole words: words only the app's features use ("reciter", "widget",
  "settings"), or an everyday verb ("share", "copy", "turn off") beside a thing the app shows
  ("share an ayah"). "How do I get closer to Allah?", "Where is the Kaaba?", "...charitable
  donations...", "...compassion...", "How do I share inheritance...?" are religious questions.
- "Who narrated the hadith of Jibril?" is a new question; only "who narrated THAT" (a
  back-reference) is a source question.
- Times of day are not verses: "I prayed isha at 11:30, is that ok?" and "Is 11:30 too late for
  isha?" (`AskAILexicon.maskingClockTimes`: h:mm with am/pm, after at/by/until/around, or in a
  message that names a prayer; "prayer" alone needs a clock word, since "what does 2:45 say about
  prayer" names a verse). The same mask keeps "Pray Asr (4:45 PM)" out of `policeCitations`.
- `policeCitations` compares through `AskAIText.citationKey` (the normalization `citedSources` uses,
  plus "2: 153" closed to "2:153"), so "(Sahih al-Bukhari, 6114)" and "(Bukhari no. 6114)" count as
  the source they name.
- A recap or a source question renumbers the previous sources by first appearance and rewrites the
  previous answer's markers to match (`renumberingMarkers`); every other earlier answer is re-sent
  without markers (`AskAIPrompt.Turn.keepsMarkers`).
- A long source is clipped around its best-matching sentence ("beautiful patience" deep in Bukhari
  4750, not its opening about drawing lots). A subject keeps its opening.
- The surah chips name the surah ("What are the main themes of Surah Al-Kahf?"), and "surah 18"
  resolves too. One-word article titles ("Salah", "Hajj") are no longer citation aliases.
- "How should I reply to salam?" and "What is a wali?" no longer make a Name of Allah the subject.

## Persistence

- `AskAISource.wasQuotedBefore` and `focusTerms` are per turn and never saved (they are outside
  `CodingKeys`); a required new field once made every transcript saved by the previous build fail
  to decode, and the next save overwrote it.
- `Message`, `AskAISource` and the store decode leniently: a missing field takes its default, an
  unknown intent or engine reads as nil, an unreadable message is dropped. A file that does not
  decode at all is moved aside as `askai-conversation.json.corrupt-<time>` (`UserDataRescue`,
  Globals.swift) and never saved over.
- Saves run on one serial queue, in order; "New Conversation" asks first, stops an answer without
  saving it, then saves once (two racing saves brought the old transcript back on the next launch).
- The most recent 40 messages are kept, and a saved source's text is clipped to 2,400 characters
  (memory keeps the full text for the cards of the current session).

## The sibling apps (Al-Quran, Al-Adhan)

The six files compile in every app from one source. Three compile flags decide what each app
carries, declared project-wide in Al-Islam and decided per sibling in `sync-manifests/*.conf`:

| Flag | Gates | Al-Islam | Al-Quran | Al-Adhan |
| --- | --- | --- | --- | --- |
| `HAS_QURAN` | ayah, tafsir and surah sources and lanes, the reader destinations, surah-name tokens | on | on | off |
| `HAS_HADITH` | the hadith source, the three hadith lanes, hadith reference parsing, the chapter destination | on | off | off |
| `HAS_ADHAN` | today's prayer-times source and the prayer-times intent | on | off | on |
| `HAS_TIPS` | the Tips & Tricks lane and destination (the settings index lane stays everywhere) | on | off | off |

`./sync_from_islam.sh quran` and `adhan` (dry runs) report no leaks for these files, list the six
as NEW with the register command, and one conflict each: the sibling's hand-adapted
`AskAIChat.swift` (Al-Quran's `OnDeviceAsk.swift` too) against the rewrite. Resolve it by taking
Al-Islam's version: the flags now do what the hand-stripping did. A card whose kind the app does
not ship (a hadith card in Al-Quran) still shows its quote and provenance, without a chevron.
Give locals near a gated block distinctive names: the leak checker matches identifier names
across files, so a `partial` loop variable in the engine matched a `partial` inside a hadith block.

## When the model cannot answer

The iOS 26.5 simulator under Xcode 27 fails every turn because the framework's safety model cannot
load (SensitiveContentAnalysisML 15 over ModelManagerError 1001). On a device that shape of error
means the model is not ready (still downloading after Apple Intelligence was turned on).
`AskAIEngine.classify` maps it, and `.assetsUnavailable`, to `.modelUnavailable`, and the reply
says so instead of the generic line. With `-askAILog` every failed turn also logs ERROR: with the
framework's own words.

The on-device session uses `SystemLanguageModel(guardrails: .permissiveContentTransformations)`:
the default guardrails declined 5 of 11 ordinary religious questions (fighting, zina, hitting a
wife, homosexuality, hell), on the retrieved passage as often as on the question; the permissive
setting declined 0 of 16, and again 0 of 6 twice after the change. A decline that does come
through is shown as one (`Message.declined`): "Apple Intelligence declined to write about this.
The sources the app found are shown below so you can read them yourself.", the source cards listed
in the open, the Retry button. The old ladder (re-ask "as an educational question" with four
sources, then with none and a note) is gone: it wrote unsourced answers to the hardest questions.

## Private Cloud Compute

`PrivateCloudComputeLanguageModel` (iOS 27) needs the managed entitlement
`com.apple.developer.private-cloud-compute`. Without it the framework does not throw, it traps the
process ("Fatal error: Missing entitlement"). So every cloud path is behind the compile flag
`HAS_PRIVATE_CLOUD_COMPUTE`, defined nowhere. To enable: request the entitlement at
https://developer.apple.com/contact/request/private-cloud-compute/, add it to the iPhone target's
entitlements, add the flag to `SWIFT_ACTIVE_COMPILATION_CONDITIONS`. The menu then offers "Answer
with: On device / Private Cloud Compute", the profile scales to the reported context size, and a
cloud turn that fails before its first word falls back to the device for the rest of the launch.
