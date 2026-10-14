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
| `AskAIIntent.swift` | `AskAIIntent` (greeting, thanks, farewell, capabilities, smallTalk, sourceQuestion, recap, appHelp, prayerTimes, reference, scripture, hadith, define, howTo, ruling, story, dua, general), each with `retrieves`, token cap, temperature and a task line. `AskAIQuestion.analyze` classifies, detects follow-ups, extracts content words (ruling words such as "haram" steer the intent but never the search), expands synonyms (`AskAILexicon`, English and Arabic terms both ways) and adds phrase hints ("how much" searches as amount, rate, nisab). |
| `AskAIRetrieval.swift` | `AskAIRetriever.retrieve`: the lanes (subject, surahName, carried, prayer, tips, settings, articles, quranSemantic, quranKeyword, quranTopics, hadithSemantic, hadithRanked, hadithTopics, names, duas), reciprocal-rank fusion with per-intent weights, a 60% per-family diversity cap, subjects first. A how-to swaps in the article's step section; a follow-up also searches the sections of the article the previous answer cited; a Name is a subject only when typed with its article ("as-salam") or beside a Names cue ("the name wali"), and a Name-only question skips the hadith lanes. Hadith text blocks are inflated off the main actor before their sources are built; the dua catalogues are folded once. Non-subject sources carry `focusTerms`, so a long one is clipped around the sentence that matched. `prewarm()` readies the indexes on appear. |
| `AskAIEngine.swift` | `AskAIProfile` (per-engine budgets), `AskAIEngine` (session creation, streaming with the repetition cut, error classification for both error families, the cloud offer gate), `AskAIPrompt` (the instructions, the prompt builder, the clipped history, the reference task by subject kind). |
| `AskAIText.swift` | Hygiene (echo labels, markdown, loops, trailing reference lists, copied source lines, em dashes, sentence capitalization with the proper nouns and surah names restored), citation markers (`normalizeMarkers`, `citedSources` by number then by reference or alias), `policeCitations` (recalled parenthetical references), `policeQuotations` (quotes of five or more words not in any source; an elided quote is verified piece by piece in one source), `EchoGuard` (paragraphs that repeat an earlier answer), `attributedAnswer` (markers as raised accent numerals), `shareText`, `suggestions`. |
| `AskAIConversation.swift` | `AskAIConversation.shared`: the messages, ask/cancel/reset/retryLast, the retry policy (leaner on overflow; on a guardrail trip first reframed with four sources, then reframed with no sources and no history and a note saying so; on-device fallback when the cloud fails before its first word), stream coalescing at 0.1 s, persistence in Documents/askai-conversation.json (see "Persistence" below), the `-askAILog` writer. |
| `AskAIChat.swift` | `AskAIChatView`, `AskAIChatSheet(initialQuestion:)` (the entry-point signature every search screen uses), the welcome, the answer card, the source card, the composer, `AskAISourceDestination` (what a card opens). |
| `OnDeviceAsk.swift` | The summarize sheets' model access, `isAvailable`, `supportsArabic`, `repetitionCutoff`. No chat code any more. |

## A turn, step by step

1. `AskAIQuestion.analyze` decides the intent and whether it is a follow-up (a short message with
   fewer than two substantive words, unless shaped like a whole question such as "what is tawhid";
   or a short one that opens like a continuation or leans on a pronoun). A follow-up searches with
   the conversation's topic prepended and keeps the previous turn's sources in the pool, stripped of
   their subject mark.
2. Conversation intents skip retrieval. `sourceQuestion` ("who narrated that?") and `recap`
   ("summarize that") reuse the previous answer's cited sources. Everything else runs
   `AskAIRetriever.retrieve` under the engine's budget (on device: 8 sources of 500 characters,
   subjects 1,400).
3. `AskAIPrompt.build` writes SOURCES, the clipped earlier turns ("context only; never repeat"),
   the task line and the question. Greetings get no history; thanks get the last question only; a
   recap gets the last answer in full. The instructions carry no example narrator or surah: the
   on-device model copied "Abu Hurairah narrated, in Sahih al-Bukhari" from an example into
   answers about verses and about other narrators' hadiths.
4. The answer streams; each flush strips markdown, normalizes markers, drops echoed paragraphs and
   em dashes, and re-parses the citations so the cards track the text.
5. On settle: repetition collapsed, out-of-range markers and recalled references removed and
   counted, unverified quotations marked, trailing reference lists dropped, suggestions built, the
   conversation saved.

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

## Private Cloud Compute

`PrivateCloudComputeLanguageModel` (iOS 27) needs the managed entitlement
`com.apple.developer.private-cloud-compute`. Without it the framework does not throw, it traps the
process ("Fatal error: Missing entitlement"). So every cloud path is behind the compile flag
`HAS_PRIVATE_CLOUD_COMPUTE`, defined nowhere. To enable: request the entitlement at
https://developer.apple.com/contact/request/private-cloud-compute/, add it to the iPhone target's
entitlements, add the flag to `SWIFT_ACTIVE_COMPILATION_CONDITIONS`. The menu then offers "Answer
with: On device / Private Cloud Compute", the profile scales to the reported context size, and a
cloud turn that fails before its first word falls back to the device for the rest of the launch.
