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

Since 2026-11-22 the verses and hadiths that lead a turn are not read alone: each carries NOTES, the
app's own data on that same verse or hadith (its tafsir, the other translation, the readings that
differ in it; the hadith's explanation and the other collections that record it). See "Depth" below.
Every visit to the chat opens a new conversation, and the last two are kept under History.

Runs on the on-device model (iOS 26 with Apple Intelligence). Private Cloud Compute (iOS 27, 32k
context) is wired but off: see "Private Cloud Compute" below.

## The files (iPhone/Helpers/, iPhone target only)

| File | Owns |
| --- | --- |
| `AskAISources.swift` | `AskAISource` (kind, reference, title, verbatim text, Arabic, transliteration, provenance facts, aliases, subject flag) and `AskAISourceFactory`, which builds one from an ayah, hadith, tafsir entry, surah background, article section, Name of Allah, dua (app collections and Hisn al-Muslim), tip, settings entry, or today's prayer times. `promptLine` is what the model reads. `clip` cuts at a sentence end. |
| `AskAIDepth.swift` | `AskAISourceNote` (kind, whose it is, the clipped English, the references it names; `promptLabel`, `promptLine`, `displayLabel`, `quotedAttribution`) and `AskAIDepth.attach`, which gives the best-ranked verses and hadiths of a turn their notes within `Budget.noteCharacters`: the subject's first, then round by round. `speaksToQuestion` gates commentary on a source the question did not name; `readingsText` turns the qiraat table into sentences. See "Depth". |
| `AskAIIntent.swift` | `AskAIIntent` (greeting, thanks, farewell, capabilities, smallTalk, sourceQuestion, recap, crisis, appHelp, prayerTimes, reference, scripture, hadith, define, howTo, ruling, story, dua, general), each with `retrieves`, token cap, temperature and a task line. `AskAIQuestion.analyze` classifies, detects follow-ups, extracts content words (ruling words such as "haram" steer the intent but never the search), expands synonyms (`AskAILexicon`, English and Arabic terms both ways; `canonicalTopic` gives the head a chip names a topic by) and adds phrase hints ("how much" searches as amount, rate, nisab). |
| `AskAICrisis.swift` | `AskAICrisis`: `isCrisis` (a first-person expression of suicidal intent or self-harm: one English regex over the folded text, and one Arabic and Urdu regex over the same text with the hamza forms folded to the bare letters, since `fold` keeps them), `mentionsSelfHarm` (a question ABOUT it, in the three languages), the reply the app writes itself (translated to Arabic and Urdu in the catalog), `helpLine(regionCode:)` (988 in the US and Canada, Samaritans in the UK and Ireland, Lifeline in Australia, 1737 in New Zealand, Tele-MANAS in India, findahelpline.com elsewhere; digits follow the locale), `helpLineAction(regionCode:)` (the same as a `tel:` or web link with a button label), its two chips (English, like every chip; the Quran one only with `HAS_QURAN`) and its sources (94:5, the Hisn dua for anxiety and sorrow). |
| `AskAIRetrieval.swift` | `AskAIRetriever.retrieve`: the lanes (subject, surahName, carried, prayer, tips, settings, articles, keyEvidence, quranSemantic, quranKeyword, quranTopics, hadithSemantic, hadithRanked, hadithTopics, names, duas), reciprocal-rank fusion with per-intent weights, a 60% per-family diversity cap, subjects first. A how-to swaps in the article's step section; a follow-up also searches the sections of the article the previous answer cited; a Name is retrieved (`exactNames`) or made the subject (`typedNames`) only when typed with its article ("as-salam", "al wadood", "assalam") or beside a Names cue (name, names, husna, asmaul, attribute: "the name wali", "is aziz a good name"), never as a bare English word (spelling-folded, "mother" was Al-Musawwir and "money" Al-Mani), and a Name-only question skips the hadith lanes. `duaTopicWords()` is the set of topics the app has a dua for, for the chips. Hadith text blocks are inflated off the main actor before their sources are built; the dua catalogues are folded once. Non-subject sources carry `focusTerms`, so a long one is clipped around the sentence that matched. `prewarm()` readies the indexes on appear. `keyEvidence` (2026-11-16, the smallest version of the review's rec 10) maps a lexicon canonical topic to the verses (optionally with Ibn Kathir on them) and hadiths a scholar opens first, weighted 8 so they lead every turn on that topic; it holds only "music" so far (Bukhari 5590, 31:6 with Ibn Kathir, Ibn Majah 4020, Bukhari 952), because no search lane ever found 5590 on its own. Add a topic only with sources checked in the app's own text. |
| `AskAIEngine.swift` | `AskAIProfile` (per-engine budgets), `AskAIEngine` (session creation, streaming with the repetition cut, error classification for both error families, the cloud offer gate), `AskAIPrompt` (the instructions, the prompt builder, the clipped history, the reference task by subject kind). |
| `AskAIText.swift` | Hygiene (echo labels, markdown, loops, trailing reference lists, copied source lines, em dashes, sentence capitalization with the proper nouns and surah names restored), citation markers (`normalizeMarkers`, `citedSources` by number then by reference or alias), `policeCitations` (recalled parenthetical references), `policeQuotations` (quotes of five or more words not in any source; an elided quote is verified piece by piece in one source), `EchoGuard` (paragraphs that repeat an earlier answer), `attributedAnswer` (markers as raised accent numerals), `shareText`, `suggestions`. |
| `AskAIConversation.swift` | `AskAIConversation.shared`: the messages, ask/cancel/reset/retryLast, the crisis short circuit, the retry policy (leaner on overflow; a guardrail decline is shown as one, with the sources, and never re-asked from general knowledge; on-device fallback when the cloud fails before its first word), stream coalescing at 0.1 s, persistence in Documents/askai-conversation.json (see "Persistence" below), the `-askAILog` writer. Since 2026-11-22 also History: `beginVisit` (a visit opens a new conversation), `startNewChat`, `openRecent`, `deleteRecent`, `recentChats` (the last two, `SavedChat`), `filing` (the pure rule the tests pin). |
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
   length (charging each source what it will actually send, not its ceiling), and where the model's
   own `tokenCount` exists (iOS 26.4+) measures the built prompt from the WHOLE list instead and
   trims until it fits; the RETRIEVAL log line ends `window=4096 instructions=1010`. What goes
   first is in "Depth": a note before a source.
   After the sources are chosen, `AskAIDepth.attach` gives the leading verses and hadiths their
   notes; the log's NOTES line lists them per source with their lengths.
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

## Depth: what a verse or a hadith is read with (2026-11-22)

Abu: "whenever ... it's quoting an ayah or a Hadith look at different riwayaat and tafsir and
translations and explanations to get an all encompassing answer."

**What is attached** (`AskAIDepth.swift`), every piece the app's own data:

| Source | Notes, in the order they are handed out |
| --- | --- |
| A verse | Tafsir Ibn Kathir on it (skipped when that entry is a source of its own, as for the subject); the other translation (`textEnglishMustafa`, "Clear Quran (Mustafa Khattab)"); how the readings differ, only while "Show Riwayah / Qiraah" is on (`QiraatVariantsStore`: each way it is read, transliterated, what it means, who reads it so, the reference's note); then Maarif Ul Quran and Tazkirul Quran as the window grows (the subject gets Maarif on the 4k window too). |
| A hadith | The Hadith Encyclopedia's explanation (the row's own Explanation page, `HadithExplanationStore`); where else it is recorded (`SimilarHadithsStore`: the same text first, then similar wording from score 60, one narration a collection, the six books first); for the subject or a larger window, how the closest other collection words it, and what is drawn from it. |

**Who gets them.** The source the question names (always, everything it has), then the first
`notedSources` verses and hadiths by rank (4 on the 4k window). A retrieved source is read in depth
only when it is ON the question: its text, its other translation or its commentary holds one of
the question's words (`speaksToQuestion`). The ranking puts unrelated verses near the top often
enough that their tafsir was five hundred characters of something else (2:213 and 90:14 led "what
does the Quran say about backbiting").

**The budget.** `noteCharacters` a turn (2,000 on the 4k window, 4,800 from 8k), handed out by
importance: the subject's notes, then every chosen source's first note, then every second one.

**What gives way** (`AskAIPrompt.trim`), in this order: a note on a source the question did not
name (the lowest-ranked source's last note first); then the lowest-ranked sources down to
`noteFloor` (5 of 8) while the subject still has notes; then the subject's notes; then sources
again, never below two. A note never costs a retrieved source its place: the first build let the
top three sources' notes push out sources 6 to 8, and the replay lost Sahih Muslim 2589 (the hadith
that defines backbiting) and Tirmidhi 2884 that way.

**In the prompt** a note is a line under its source: `   With [2], the tafsir Ibn Kathir on this
verse (the commentator's words, not the Quran's): ...`. It is cited by the source's number.
Instruction rule 7 says what the lines are. A wording note (the other translation, another
collection's wording) goes in quotation marks; commentary does not.

**Guards.** The model put the Encyclopedia's explanation of Sahih Muslim 2564a in quotation marks
after "He also explained this as". Three things answer that: the commentary labels say whose words
they are not; rule 7 says a tafsir or an explanation is never the words of Allah or of the Prophet;
and `policeQuotations` follows any quotation that is a commentary note's wording with where it is
from ("(from the Hadith Encyclopedia's explanation, not the hadith itself)"). A paraphrase cannot
be caught that way. `policeCitations` accepts a reference a note names (`AskAISourceNote.references`),
`droppingSourceEchoes` drops a copied note line, and `normalizeMarkers(sources:)` turns a
verse-shaped bracket ("[2:83]", "[3:14]", seen once the prompt carried note lines) into the marker
of the source it means.

**On screen** a source card with notes names them on one line (CLEAR QURAN (MUSTAFA KHATTAB) •
TAFSIR: IBN KATHIR • OTHER QIRAAT) and shows each, exactly as the model was given it, under "Show
the whole text". The welcome's HOW IT WORKS has a row for it (`AskAICopy.readWith`, or
`readWithoutReadings` while the readings are not shown).

**The readings follow "Show Riwayah / Qiraah"** (Abu, 2026-11-22, the same day: "only analyze qiraat
if show qiraat is on"). `AskAIDepth.readsQiraat` is `Settings.showQiraahDetails`, the Quran
settings switch (off by default) that shows the readings everywhere else in the app: the ayah
sheet's OTHER QIRAAT, the Qiraat Explorer. Off, a turn is given nothing about the readings:

- no verse carries a readings note (`attach` reads the setting once a turn; every turn rebuilds
  its notes, so a follow-up after the switch is turned off drops them too);
- rule 7 of the instructions does not name them (`AskAIPrompt.instructions(readsQiraat:)`; the
  two texts differ by those words only, and the window is measured with the longer one);
- the verse task asks for the readings paragraph only when the subject carries a readings note,
  whatever the setting;
- the welcome's row does not promise them.

A conversation saved while the switch was on keeps what it was read with: its cards still list
OTHER QIRAAT, since the answer above them speaks of the readings. Qiraat articles stay searchable
either way, as they are in the Islam tab.

**Also fixed on the way.** `AskAIRetriever.hadithReference(in:)`: a hadith named inside a sentence
("Explain Bukhari 1") is now the subject, and the question a `reference` (`AskAIQuestion.classify`
reads the same finder), so it gets the reference task and lane weights. The parser reads a whole
search field, so the question is tried whole and then as the few words that end at each number;
those words must name exactly one collection ("pray 5 times" names none). Before, that question
opened on Bukhari 4485 with Bukhari 1 second of eight guesses and tied it to 75:16; now it names the
narrator, the parallels in Abu Dawud 2201, an-Nasa'i 75 and Ahmad 168, and the Encyclopedia's
explanation as the Encyclopedia's.

**The readings took three tries.** "What does 1:4 mean?" was answered without a word on Owner and
King while the note read "X, “...”, is read by A; Y, “...”, is read by B" with the readers in the
table's scholarly spelling. What worked: one sentence a reading, who first ("Asim, al-Kisai, Yaqub,
Khalaf read māliki yawmi d-dīni, meaning “Owner of the Day of Judgement”"), the readers' names in
plain letters (the readings keep their marks: māliki and maliki differ by one), and a task line
that asks for a short paragraph on the readings when the line is there.

**Measured (iOS 27 simulator, 4k window, 2026-11-22).** Instructions 1,026 tokens (888 before rule 7).
Every one of the 42 replayed turns kept all its sources. Medians, before to after: the depth set
first token 2.4 s to 2.9 s and total 6.5 s to 9.2 s; the hard set 2.0 to 3.0 and 6.9 to 9.7; the
everyday set 2.1 to 2.6 and 6.1 to 8.3 (the Mac was under heavy load from other sessions during the
after runs, so read the size of the gap loosely; the prompts are longer and so are the answers).
Failures 0, no "scholars generally"; the extra declines the scorer counts are honest ones the old
runs worded differently ("You do not find Istikhara in the sources"). The gains are where the
sources were right ("Explain Ayat al-Kursi" cites Ibn Kathir and Maarif, "What does 1:4 mean?"
gives both readings, "Explain Bukhari 1" is about Bukhari 1), and a wrong retrieval is still a
wrong answer: "What did the Prophet say about kindness to parents?" still opens on the slander
story. Logs: `Scripts/qa/askai/after-2026-11-22/` (`depth-before.txt` is the same eight questions
on the build before this work; `depth.txt` is the final build, the other three the build just
before the reference-intent refinement). Questions: `questions-depth.txt`.

## History: a new conversation each visit (2026-11-22)

Abu: "When I go to ask ai always make a new chat but maybe show the last 2 chats as history."

- `AskAIChatView.onAppear` calls `AskAIConversation.beginVisit(asking:)` once per presentation (the
  same guard as the initial question: a popped source reader is not a visit). The open conversation
  is set aside under History and an empty one opens. Two visits carry on instead: one that finds an
  answer still streaming, and a search sheet reopened on the query it already asked.
- `recentChats` keeps the last two (`recentChatLimit`), newest first. The welcome lists them under
  HISTORY (first question, relative date; hold to delete) and the menu under History. Opening one
  makes it the conversation again, topic and all, so a follow-up works; the open one takes its place.
- The menu: New Conversation (sets aside, no confirmation: nothing is lost but the oldest of the
  kept), Copy Conversation, History, Delete Conversation (clears the open one for good, asks first).
- A conversation with no question in it is never filed; one reopened and set aside again is listed
  once (it keeps its id). "Erase Everything" clears History too.

## Prayer times, dates and the qibla (2026-11-25)

One builder, `AskAISourceFactory.prayerSource(for:place:)`, writes the source for every question the
app computes an answer to. `AskAIPrayerRequest.parse` reads the place, the day and the `Topics` the
question asks for; only what is asked goes into the source, because a small model repeats whatever
sits beside a time (with the rakah counts on every line it gave Isha's counts to iftar).

| Asked | What the source carries |
|---|---|
| any time | the answer in the first sentence, worked out by the app: each prayer the question names (`prayers`) with its time and, today, its countdown ("Isha is at 4:52 PM, in 3 hours 51 minutes", "Dhuhr was at 10:45 AM, 2 hours ago"), else what comes next; then the day's times, bare. The model copies, it never subtracts |
| rakahs, sunnah, fard | the counts beside each time (`.rakahs`); "How many rakahs is Maghrib?" is routed here by `asksRakahCount` (from the library the answer was "two", off a hadith about the sunnah after it) |
| midnight, tahajjud, qiyam, last third, "when does Isha end" | Islamic midnight and the last third (`.night`, `Settings.optionalPrayers`) |
| suhoor, iftar, fasting | suhoor's end at Fajr and iftar at Maghrib (`.fasting`) |
| duha | when Duha opens (`.duha`) |
| method, calculation, madhab | the reader's method and Asr rule (`.method`, here only) |
| "this week", "the next 3 days" | one line a day, up to seven (`.week`) |
| the Hijri date | the day's Hijri date, with the reader's adjustment and the Maghrib switch (`.hijri`) |
| when is Ramadan, an Eid, Arafah, Ashura, Hajj | the next two occurrences of each named date from `Settings.specialEvents`, with the days left (`.events`) |
| the qibla's direction | the bearing from true north and its compass point, here or in a named city (`.qibla`) |

A question that is only about the calendar or the qibla gets no timetable (`wantsTimes`), and
`asksDateOrDirection` sends it to the prayer-times intent only when it asks for the fact itself: "why
did the qibla change" and "when should I fast Arafah" stay with the library.

**Follow-ups inherit.** "Fajr in Makkah tomorrow", then "And in Cairo?", then "What about Maghrib?":
a follow-up straight after a prayer-times answer that names a place, a day, a prayer or a topic is a
prayer-times question (`continuesPrayerTalk`), and takes the place and the day it does not name from
the request before it (`inheriting`, kept in `AskAIConversation.lastPrayerRequest`). Before this the
second question was read as a general one, found no timetable, and the model made a time up.

**The timetable is the whole answer.** When the app has computed the source, it is the only source
of the turn, in every scope: with seven verses and articles beside it ("how long until Asr" pulled
in Surah Al-Asr) the first word took twice as long, and the model looked elsewhere and said the
times were not in its sources.

**A week is written by the app.** Asked for a week's times, the model wrote out the first day and
called it the week. A run of days (`Topics.week`) is a table the app has exact, so `ask` sets the
source's own lines down as the answer and the model is not called. (`-askAILog` prints `RAW:` when
the cleaned answer differs from what the model sent; an answer is several lines long, so read the
whole entry, not its first line.)

**Few lines, one countdown, and the answer first.** What was asked is said in the first sentence,
beside the time of day: under the list, "What is the next prayer?" got the list's first line, and
with a countdown on every line plus "the next one is Asr, in 25 minutes", "How long until Isha?" was
answered "25 minutes". The coming dates are the next occurrence of each named one, or those of the
year asked for (`eventYear`), never six lines (given six, the model picked the last). The task line
says the source is the app's calculation and not scripture: given that one source alone, the model
once opened "The words of Allah in Surah Al-Baqarah, verse 184: Fajr 5:19 AM".
Suhoor is written as a deadline ("must be finished by Fajr"): "suhoor ends at Fajr" came back as
"suhoor begins at Fajr".

**The reader's own record (`Topics.tracker`).** "Did I pray Fajr today?", "Did I miss Dhuhr?",
"Which prayers have I prayed today?" (`AskAIPrayerRequest.asksTracker`) are answered from the Prayer
Tracker's marks and the clock: whether the prayer's time has come, is still on (and until when) or
has ended, and how it is marked. The APP writes the answer (`AskAISource.appAnswer`): asked to say
"Dhuhr's time ended at 1:13 PM; your tracker has no mark for it", the model kept one half and
dropped the other, a different half each run. A question about what to DO stays with the library
("I missed Fajr, what should I do?").

**Two or three places.** "Fajr in Makkah and Cairo" (`AskAIPrayerRequest.places(in:)`, `morePlaces`)
gets one timetable per place and an answer the app writes, the asked prayer's line of each (every
time when no prayer is named), in the order asked. The tagger does not know every city (it left
Cairo and Istanbul untagged), so a capitalised name joined to a place phrase by "and", "or", "vs" or
a comma counts too.

**App-written answers so far:** a week's table, compared places, the tracker. The rule: when every
part of the answer is a fact the app holds, the app sets it down.

**Starters.** The Prayer Times choice has eight, four a day: two about the day's times and two of
"When is Ramadan?", "Which way is the qibla?", "What is the Hijri date today?", "When does the last
third of the night begin?" (catalog keys, translated into the 14 languages with
`Scripts/localize_catalog.py manual` then `merge`).

**Never a place.** A candidate of filler words alone, or one holding a word from `neverInAPlace`, is
not looked up: "the last third of the night tonight" once left "the" after the date detector took
"night tonight", and Apple Maps found a village for it.

## Summaries read the whole text (2026-11-25)

`SummarizeSheet` used to send the first 6,000 characters of a text and nothing after them. One text
is now read to its end by `OnDeviceAsk.streamTextSummary`:

- up to `singlePassCharacters` (7,000) in one request, as before;
- longer, in parts: a short first part (`firstPartCharacters`, 3,200, so the first words come in
  about a second), then parts of about 6,500 (8,000 at most), each its own request and its own
  paragraph, up to `maximumParts` (10, about 75,000 characters; only a text past that says how far
  the reading went). The card shows a bar for the reading and "Reading the text..." between parts.
- A question afterwards (`streamTextFollowUp`) is answered from the passages of the whole text that
  share its words (`passages(of:for:limit:)`), with the summary beside them for orientation.

Several texts at once ("all tafsirs", a focused Arabic edition) still arrive combined and fitted by
the caller and are sent as they are.

What made it slow to start, measured with `-summaryProbe` on Ibn Kathir's 2:255 (13,809 characters):

| | first word | whole summary | text read |
|---|---|---|---|
| before, first summary of a launch | 5.0 s | 11.0 s | 6,000 characters |
| before, model already loaded | 2.1 s | 8.1 s | 6,000 characters |
| now, model already loaded | 2.0 s | 16 s | all 13,809 |

The wait is the model reading the prompt (about a millisecond a token on the simulator) plus 2.9 s
when it has to be loaded first. `prewarmSummaries` starts that load as the sheet rises. The tokenizer
is asked only about a part long enough to overflow (`fitting`), since its first count of a launch
takes up to a second.

### What Abu meant by "laggy" (the same day, second pass)

He meant the app dropping frames while the summary is written, worst while scrolling, not the wait.
What the simulator can and cannot show of that:

- **The app's own main thread** is measurable, and the first fix made it worse. `StreamReveal` first
  published the text thirty times a second and SwiftUI redrew `SelectableProse` each time: the whole
  string built again, set on the text view, and measured through `UITextView.sizeThatFits`, which
  typesets the whole text. 4.5 ms a redraw, 133 ms of main thread a second against 29 for drawing the
  model's lumps as they came. The simulator draws 60 frames a second, so nothing was late there; the
  phone draws 120, 8.3 ms each. `-summaryProbe` now counts run-loop passes longer than that (`over8`,
  `over16`, `longest`), and `-summaryScroll` scrolls the sheet while the summary is written:

  | drawing | main thread | passes over 8.3 ms, still | scrolled |
  |---|---|---|---|
  | each lump set whole (before 2026-11-25) | 29 ms/s | 2 | 4 |
  | 30 Hz reveal through SwiftUI (first fix) | 133 ms/s | 14 | 42 |
  | words appended to the text view (now) | 21 ms/s | 0 | 0 |

  Now: `StreamReveal` writes into the text view itself (`StreamedTextView`, a TextKit stack on an
  `OwnedTextContainer`), a word or two twelve times a second, appended to the storage, and SwiftUI
  hears of it only when the text takes another line. The sheet's own body is no longer evaluated per
  snapshot (`summary` and a turn's `answer` are set once, at the end). While the reader scrolls by
  hand nothing is written at all (`ScrollingByHand`, four seconds at most); the words catch up when
  the scroll rests.
- **The old sheet fought the finger during an answer**: every snapshot animated a scroll to the
  foot. A scroll by hand now stops the follow until the next question.
- **The model sharing the phone's graphics chip with the screen** is not measurable here. A screen
  recording of a steady scroll on the Mac (`-summaryScrollTail`, frames counted with ffprobe) missed
  no frame with the model writing or stopped, but the Mac is not the phone. This is the likeliest
  cause of "it lagged the whole app" on the old build, whose main thread was already light, and the
  app cannot change it: it can only ask for less drawing while the model works, which is what the
  above does. Check on a phone with Instruments (Animation Hitches) before claiming more.
- **No model work nobody asked for.** For a day the model was also loaded when a tafsir or a surah's
  background opened (a reader who had summarized lately). Taken out: a model starting up under a
  screen where nobody asked for it is the complaint itself. The first summary of a launch waits
  about 3 s longer for its first word because of it.

A real drag between the sheet's half and full heights showed one more stall, up to 41 ms: the Quran
reader UNDER the sheets building a row (`UICollectionView` prefetch, `WordByWordTextView`), not the
summary. Left alone; it belongs to the reader.

`-summaryProbe` logs one `SUMMARYPROBE request` line per model request (prompt tokens, wait, total)
and one line for the whole summary (wait, total, redraws, hitch ms/s, worst frame, main-thread ms/s,
and the run-loop passes over one and two of the phone's frames), and writes the summary to
Documents/summary-probe.txt. `-summarizeDelay <s>` holds the tafsir open first; `-summaryScroll`
scrolls the sheet while it writes; `-summaryDrawAsItComes` draws each lump whole, to compare. An
article page: `-launchTabIslam -islamOpenArticle QiraatView -articleSummarize -summaryProbe` (19,736
characters, four parts, 21 s, checked 2026-11-25). Real swipes work on the simulator through idb
(`idb ui swipe`), and are the only way to see the sheet change height.
`-summaryAsk "<question>"` asks a question once the summary is written (answer in
Documents/summary-answer.txt): "What does it say about the Throne and the Kursi?" is answered from
the end of that tafsir, 8,000 characters past where the old summary stopped reading.

## Finding a passage from its description (2026-11-25)

Abu: "if I tell you verse about fathers killing their children out of shame you find nothing, but
Google or ChatGPT would be able to find it." The verses meant (16:58-59, 81:8-9) share no word with
that sentence, the search field's engines score typed words, and the meaning search is word vectors
(`NLEmbedding`), where "shame" sits nearest "disgust" and "killing" nearest "shooting".

**What does not work on the 3B model** (each tried from a Mac command line against the same model,
`SystemLanguageModel` in a small Swift script, seconds a try):
- asking which verse it is: a confident reference and a made-up quotation;
- asking for search words: noise ("Imam of Najaf", "Goliath, Solomon");
- handing it twelve candidates to choose from: it passed over the first three, which were the
  passage, for one that shared a word, and explained it with a practice it does not mention;
- telling it to present the first candidate: a hadith introduced as "the words of Allah in the surah
  of Al-Ma'idah, verse 11", provenance lines pasted in.

**What is built** (`AskAIPassageSearch.swift`):
- `AskAIWords`: a tokenizer, a small stemmer, and a thesaurus of about 210 concepts, one line each
  (shame, disgrace, humiliation, dishonor; child, daughter, baby, infant, girl; kill, slay, bury).
- `QuranDescribedSearch`: each word of the description is a concept; each ayah is scored (BM25) on
  its two translations, on its neighbours (0.35), on what the three English tafsirs say about it
  (TafsirKeywords.bin, each passage's 120 most telling words, 0.25 each), and on the topic index's
  names for it (`QuranTopicsStore`, 0.8: "burying daughters alive" lists 16:58-59). Concepts that
  sit together count for more, and so does a run of the reader's own words found verbatim ("a
  garment for you").
- `HadithDescribedSearch`: the same scoring over the eight major collections (HadithSearchWords.bin),
  the same narration told in several collections kept once.
- `AskAIQuestion.findsPassage`: "verse about ...", "which hadith ...", "where does the Quran say
  ...". The lane's first hit leads when it carries enough of the description (`Hit.coverage`), with
  the verse beside it when the two are one sentence (81:8-9) or share the description.
- The APP writes the answer's head (`AskAIConversation.PassageAnswer`): the reference and the words,
  on screen before the model has read anything; the model then explains that one passage under plain
  instructions of its own (`AskAIPrompt.passageInstructions`), and the app adds what else is close
  (quoted, when the second match scored within a fifth of the first). When nothing carries the
  description the model is told to say so (`missedTask`).

**Measured in the app, search only** (`-askAIRetrieveOnly`, 40 described verses and 15 described
hadiths; `-askAINoDescribed` is the search as it was):

| | reaches the model | first source |
|---|---|---|
| verses, before | 31 of 40 | 25 |
| verses, now | 40 of 40 | 34 |
| hadiths, before | 7 of 15 | 5 |
| hadiths, now | 15 of 15 | 12 |

A found passage answers in about 1.5 s (first words 0.5 s), where the same question took 9 s.
Abu's own example now leads with 6:151 ("do not kill your children out of poverty") and quotes 81:8
beneath it, with 16:59 fourth in the lane: "shame" is in no verse's words, and the search cannot
weigh the reason over the act. Not built: a real sentence-embedding model.

**The packs.** `Scripts/build_tafsir_keywords.py` (1.6 MB shipped) and
`Scripts/build_hadith_search_words.py` (1.9 MB shipped), both `--check`able, both LZFSE through
`compress_shipped.py`. Rebuild the hadith one after any .hpk rebuild: the app checks each
collection's row count and leaves a mismatched collection out rather than cite the wrong narration.

**Also fixed on the way.** "Hadith about ..." pulled Surah 88 into every such question (its other
name opens "hadith"), and the surah-name fold read "road" as Ar-Ra'd, "water" as Wat-Tur and "man"
as Al-Mani'ah: an ordinary English word (one the translations use) now names a surah only when it IS
the surah's name. A line that says where a passage is and quotes it is no longer dropped as a copied
source line (`droppingSourceEchoes`).

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

A replay has the readings (qiraat) OFF, the app's default: `run.sh` seeds the switch off so the
run does not depend on what the simulator was left with. `SEED=showOtherQiraatReciters=1
Scripts/qa/askai/run.sh ...` turns "Show Riwayah / Qiraah" on for the run (the script folds SEED
into its one `-seedBool`; the app reads only the first). The `depth.txt` log of 2026-11-22 predates
the switch and was made with the readings always read; `depth-qiraat-off.txt` and
`depth-qiraat-on.txt` beside it are the two states after it (off: the eight depth questions, no
readings note and not a word on the readings in any answer; on: "What does 1:4 mean?" carries the
note and gives the Owner and King readings their paragraph).

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
- Saves run on one serial queue, in order; "New Conversation" and "Delete Conversation" stop an
  answer without saving it, then save once (two racing saves brought the old transcript back on the
  next launch).
- The most recent 40 messages of each conversation are kept, and a saved source's text is clipped
  to 2,400 characters (memory keeps the full text for the cards of the current session). Notes are
  saved as they are (already clipped to what the model read); a note kind a later build adds drops
  that source's notes, never the source.
- The file holds the open conversation (`messages`, `topic`, `id`, `updated`) and `recent`, the
  conversations before it; a file saved before History existed reads as an open conversation with
  no history. It is removed only when both are empty.

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
