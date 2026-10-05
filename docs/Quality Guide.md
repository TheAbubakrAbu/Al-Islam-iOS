# Al-Islam Quality Plan

Working document for Claude Code sessions. Not user-facing. Abu asked on 2026-09-28 for a full pass over optimization, bugs, crashes, errors, glitches, accuracy and correctness, and for a plan. A session that hears "do Phase 1" (or "fix the crashes", "now prayer times") reads this file, does that phase, ticks its boxes and appends to the progress log at the bottom.

Nothing in the app was changed when this was written. It is an audit of the 2026-09-28 tree: Save 20 (`02d77a2`) plus the uncommitted work (the Ask AI rebuild, the Chosen Ayah widget and deep links, the Need a Hand? redesign, the pinned switchers, the modal guard). It was built in Debug and Release, run on the iPhone 17 Pro simulator (iOS 27) across 92 cold launches, checked with the repo's verifiers and the app's own DEBUG audits, run under Thread Sanitizer, and read by ten parallel code audits (Ask AI, uncommitted widget and lifecycle work, page mode, the Quran tab and player, prayer times and notifications, Hadith and Islam, Settings and iCloud, Watch and widgets, performance, SwiftUI glitches). Every `file:line` below was read by the auditor that reported it; the runtime items were seen in logs or crash reports.

## How to run a phase session

1. Read "Status", "Decisions pending Abu", "Baseline", the phase Abu named, "Already fine" and Appendix B.
2. Line numbers are from the 2026-09-28 tree, uncommitted diff included. Re-grep the symbol before editing; never trust the number. Ignore `.claude/worktrees/`.
3. Phase 0 is code that is not committed yet and holds a live crash (U1) and a data-loss bug (U3). If Abu names a later phase while Phase 0 is open, say so and offer to do Phase 0 first.
4. Reproduce before fixing. Every item names its repro or its check; the tools are in Appendix A. If an item will not reproduce, write that in its box and move on. A CONFIRMED-by-reading item whose fix is local may be fixed without a repro, but say so.
5. Some items only work together; ship them in one session: the dots cluster (C1, A1, A2), the widget reload plumbing (P8 to P11), the decode-failure policy (U3, C7), the day-key cluster (A10, F3, P4).
6. After each item: Debug build, run its repro, tick the box with a one-line result. End of phase: Release build (the Xcode Cloud trap from 2026-09-06), the sweep over the phase's screens with `analyze.py` showing no new error or fault lines, and the idle counters if the phase touched rendering.
7. Standing rules: no `git commit` or `git push` unless Abu asks in that message; no em dashes and no spaced hyphen standing in for one; a row's `==` folds every Settings field its body reads; never write `@AppStorage` or UserDefaults from a body, timer, playback callback, scroll handler or location update; `confirmationDialog` over `.alert` unless a TextField is needed; every removal asks first; every sheet uses `.sheetDismissToolbar`; the iPhone 17 Pro simulator only; the Watch, Widget and Complication targets compile shared files, so iOS-only code stays fenced.
8. End of session: a progress-log entry (date, phase, items, files touched, how each was verified, what is left), the status table, and a reminder to Abu that the changes are uncommitted with what the commit would contain.

## Status

| Phase | Area | Items | Status |
|---|---|---|---|
| 0 | Uncommitted work: Ask AI, Chosen Ayah widget, lifecycle, Need a Hand? | 24 | done 2026-09-28 |
| 1 | Crashes and data loss in shipped code | 13 | done 2026-09-28 |
| 2 | Accuracy: Quran text, references, calculators, daily picks | 14 | done 2026-09-28 |
| 3 | Prayer times, notifications, widgets, watch | 14 | done 2026-09-28 |
| 4 | Recitation playback | 6 | done 2026-09-28 |
| 5 | Glitches: SwiftUI and navigation | 12 | done 2026-09-28 |
| 6 | Performance | 13 | done 2026-09-28 (F2, F4, F9 measured and left); F13's asset re-encoded 2026-09-29 |
| 7 | Guardrails and tooling | 10 | done 2026-09-29 (T7: the UnitTests and UITests targets) |
| 8 | Accuracy and correctness pass (prayer engine, notifications, tracker, widgets, backup, hadith, calculators, tajweed, word study, search, player, reader) | 98 fixed; then the D10 calls and S6 | done 2026-10-05; not done: D3, M10, M11, G3 (see the phase) |

Order: 0 before the next commit; then 1, 2, 3, which change what users see or lose; then 4 and 5; then 6. Phase 7 can run alongside any of them.

## Decisions pending Abu

Ask at the start of a session whose phase touches one; do everything else meanwhile.

- **D1. Real-device crash data.** The Organizer's crashes, hangs and memory terminations for 4.6.5. Only Abu can pull them. The 92-launch sweep found no crash; the crashes in this plan came from targeted repros, code reading and old reports, so devices are the largest unknown. Abu 2026-09-29: not now; sweep the simulators and the Mac instead (see the 2026-09-29 progress entry: three iPad passes, and the Mac blocked by Gatekeeper).
- **D2. A unit-test target** for the pure logic (T7). DECIDED 2026-09-29 (Abu listed it to do): added, see T7.
- **D3. Juz boundaries** (A4). DECIDED 2026-09-29 (Abu, after checking online): the ۞ marks, 3:93 and 9:93. See Decisions made.
- **D4. Notification budget** (P2). Drop Hijri events beyond the adhan horizon and reserve a floor of adhan slots? Recommended: yes.
- **D5. Polar latitudes** (P6). A nearest-latitude fallback (about 65°) or an explicit "times unavailable" state?
- **D6. Hadith share card** (C4). Cap the height and truncate, or render long cards at a lower scale?
- **D7. Fonts in the Widget and Watch bundles** (A9). Bundle NoStack, Hijazi and Kufi (size cost), or map them to Uthmani there?
- **D8. "Reset Settings, Keep My Content"** (G10). Should it keep device-only state (first launch, one-shot guards, the "never ask" flags)?
- **D10. Phase 8's open calls** (2026-10-04). DECIDED 2026-10-05 (Abu: "yes do all of those"), and done as Phase 8's second round (see there):
  - **T2.** Malaysia (JAKIM) is 18 degrees (the council's 2019 move; e-solat's Kuala Lumpur Subuh agrees within its zone margin). Brunei has its own row at 20 (its published Subuh matches 20 to the minute).
  - **T5.** Automatic applies Seventh of the Night past 66 minus the method's deeper angle: 48 for every 18 degree method (Adhan's own figure), 54 for France's 12, 51 for ISNA's 15. Past that latitude it holds all year, so no night jumps when the angle first fails; short of it the angle is reached every night and its times stand. Taking "only on nights the angle fails" literally would have moved Fajr by hours overnight in Berlin or London under MWL.
  - **T8.** Each time rounds to its safe side: a start up, sunrise (the end of Fajr) down; Islamic Midnight down, Last Third up, Duha from the end of sunrise's minute. The fasting countdowns end a minute before the Fajr shown, which is always before dawn. MUIS keeps its own rounding (all up).
  - **H4, H7, J8, J10, K6:** fixed. **J2 remainder:** kept as it is; the four alefs are read at the stop, which is where each of those ayahs ends.
  - **Displayed times move** (release notes): Turkey's Maghrib +7 min, Dhuhr +1 min for MWL, ISNA, Egypt, Karachi and MUIS, Asr by seconds (T1, T7); Malaysia's Fajr about 8 min later; any start can show a minute later and sunrise a minute earlier than before (T8); and, under Automatic, summer Fajr earlier and Isha later where the method's angle is now left alone: France (12 degrees) everywhere, ISNA between 48 and 51 degrees (Vancouver on 21 June: Fajr 02:37 instead of 04:00, Isha 23:52 instead of 22:28; Winnipeg alike), Russia's 16 between 48 and 50. If that is more than Abu wants for ISNA, keeping ISNA's limit at 48 is a one-line change.
- **D9. More than one window on iPad and Mac** (2026-09-29). The generated scene manifest sets `UIApplicationSupportsMultipleScenes = true`, so Cmd+N on a Mac, or the iPad's window controls, open a second Al-Islam window, and the shared presenters (`FocusOverlayPresenter.shared`, `AppNavigation.shared`, `ScreenAwake.readerVisible`) then drive both, while every window reruns the root's post-reveal tasks (all guarded or idempotent, checked). Nothing crashed with two windows (95 of 95 screens) or with twelve. Keep multi-window, or set it off in Info-Main.plist? Recommended: off, unless a second window is a feature Abu wants.

## Decisions made

Taken by Claude during the 2026-09-28 run so the phases could proceed, each the recommended or the least
surprising choice, each reversible in one place. Abu to confirm or overturn.

- **D3: the ۞ marks (Abu, 2026-09-29; the 09-28 call is overturned).** Juz 4 opens at 3:93 and juz 11 at
  9:93, where the printed Madani mushaf puts its ۞ (page 62, second line; page 201), as Tanzil and
  Quran.com have them. The 09-28 call read the ayah at the TOP of pages 62 and 202 (3:92, 9:94) as the
  start; that is the page's header juz, not the boundary. The popular names Lan Tanaloo and
  Ya'tadhiroon come from the Indo-Pak split; the app names each juz by its opening words (Kullu
  At-Ta'am, Innama As-Sabeel), as it did before 09-28. quran.qpk's per-ayah juz (3:92 in juz 4, 9:93
  in juz 10, the page-top split) was patched to match (A4).
- **D4: yes.** Hijri events only inside the 14-day adhan horizon, and a floor of 20 prayer slots (P2).
- **D5: nearest latitude.** Times above the rule's reach come from the nearest latitude that has them
  (about 65 degrees), not an "unavailable" state (P6).
- **D6: scale, then cap.** Long hadith cards render at a lower scale to fit the pixel budget, capped at
  12,000 pt with "The narration continues in the app." (C4).
- **D7: map to Uthmani.** The Widget and Watch draw NoStack, Hijazi and Kufi selections in Uthmani; no
  fonts added to those bundles (A9).
- **D8: keep device-only state.** "Reset Settings, Keep My Content" spares the whole device-only class
  (first launch, About You's version, the one-shot guards, the "never ask" flags, the iCloud claim) (G10).

Still open: D1 (device crash data) and D2 (the test target, T7).

---

## Baseline (2026-09-28)

| Check | Result |
|---|---|
| Debug build, scheme `iPhone` | passes; 5 Swift warnings (T1) |
| Release build, scheme `iPhone` (iPhone, Watch, Widget, Complication) | passes; the same 5 warnings (zero on 2026-09-06) |
| Runtime sweep: 92 cold launches over every tab, reader, sheet, search and probe | 92 alive, 0 new crash reports |
| Known crash: page mode with Hide Arabic Dots | reproduced, aborts within 15 s (C1) |
| Crash reports on this Mac | 3 of C1 (2026-09-23, Al-Islam and Al-Quran), 2 of U1 (2026-09-28), 1 of C5 (2026-09-21), 1 FoundationModels assertion (2026-09-28 01:33; most likely the Private Cloud Compute entitlement trap the Ask AI Guide says is fenced since), 1 debugger artifact (2026-09-27, no frames) |
| Data verifiers (`Scripts/verify_*.py`, quote auditor) | 6 pass; the quote auditor dies halfway (T2) |
| `-auditPacks` | every pack decodes through the app's readers: 17 hadith books with no empty rows, Quran 6,236 of 6,236, 6 tafsirs complete, the encyclopedia 2,328 of 2,328 |
| `-auditSemanticPacks` | both packs VALID |
| `-auditQiraahAlignment` | 2,166 surah and riwayah pairs, worst 0.936, 140 repaired by the word check, 0 below 0.75 |
| `-dailyRolloverProbe` | the app and the widget's Fajr table agree |
| `-cloudKeyAudit` | 79 live keys, 2 unclassified (T4) |
| Idle counters, 9 screens, 20 s after a 14 s settle | 0 Settings publishes anywhere; one late render burst on the Quran screens (F12) |
| Cold launch to reveal, Debug, median of 5 | iOS 27: Adhan 4.3 s, Quran list 5.3 s, Quran page 5.3 s. iOS 26.5 (the 2026-09-04 runtime), same build: Adhan 5.6 s. 2026-09-04 recorded 3.3 to 3.6 s (Xcode 26.6) on the same stopwatch, and the launch cover now comes up at +1.1 s instead of +0.58 s. Not the runtime; code or toolchain (F1) |
| Thread Sanitizer, 7 flows (launch, hadith search, hadith book, duas, word card, page mode, Ask AI) | 0 reports; the `-tsanSelfTest` race was reported, so the sanitizer was live |

Runtime faults the sweep logged (each is an item): the lazy-container push destination (G2), the AttributeGraph cycle in printed-mushaf mode (G4), the find-jump size churn and invalid screen conversions (G5), the failed pixel buffer on Wallpapers (F12), 61 notification requests built without authorization (P14). The appearance tripwire fired on every launch (G11). Everything else in the 92 logs was system noise (listed in Appendix A).

---

## Phase 0: the uncommitted work (before the next commit)

### Ask AI (`iPhone/Helpers/AskAI*.swift`, see `Docs/Ask AI Guide.md`)

- [x] **U1. Crash on any answer with zero sources.** `AskAIText.swift:328` evaluates `(1...sourceCount).contains(n)`, which traps when `sourceCount` is 0. It is reached from `AskAIConversation.swift:378-379` (every flush) and `:412` (finish) whenever a sourceless turn contains a marker such as "[1]" (the instructions show "like [1] or [2][4]", `AskAIEngine.swift:292`): greetings and chit-chat, the second guardrail retry (`:284` sets sources to []), a source question or recap after a sourceless turn, app help with no match (U6). Both crash reports of 2026-09-28 (10:29, 10:49) are this line; the guard at `:343` fixed a different crash (an index at position 0), so the guide's "guarded in normalizeMarkers" is wrong. Fix: `if n >= 1, n <= sourceCount`. Verify: a script that runs a verbatim copy of `normalizeMarkers` with sourceCount 0 and "[1]" at position 0, mid-sentence and as "(source 1)"; then `-askAI "hello||thanks||hello"` with `-askAILog`. CONFIRMED (proved with a verbatim copy). DONE: `n >= 1, n <= sourceCount`; `-askAITextProbe` passes all four zero-source shapes, and a live `-askAI "hello||thanks||...||hello"` ran six turns with no crash.
- [x] **U2. A late flush overwrites a failed reply (and is a second route into U1).** The final failure path (`AskAIConversation.swift:299`) never calls `resetStream()`; a flush armed at `:360-366` fires up to 0.1 s later and `:382-386` replaces the text, erasing the "(The answer stopped early…)" line from `:408`, so the screen no longer matches what `:426` saved. Crash report 2's `closure #1 in receiveStreamed` is this path. Fix: `resetStream()` first thing in `finishReply`. CONFIRMED (code path). DONE: the failure path flushes what streamed, then `finishReply` calls `resetStream()` first. By reading (no model failure could be forced).
- [x] **U3. Transcripts saved by the committed build no longer load, and the next save deletes them.** The new stored `var wasQuotedBefore = false` (`AskAISources.swift:71`) is required by the synthesized decoder (keyNotFound at `messages[0].sources[0]`); `AskAIConversation.swift:522-523` swallows the error and the next save overwrites the file. Its comment "Never persisted as true" (`:70`) is also false. Fix: leave it out of `CodingKeys`; decode `Message` and `Store` leniently; never overwrite a file that failed to decode (see C7). CONFIRMED. DONE: `wasQuotedBefore` (and the new `focusTerms`) left out of `CodingKeys`; `AskAISource`, `Message` and `Store` decode leniently (an unreadable message is dropped); an undecodable file is moved aside by `UserDataRescue` (Globals.swift). Verified: a transcript with a message of role "robot" and sources missing `maxCharacters` loaded and showed; the probe decodes an old-format source and message.
- [x] **U4. "New Conversation" tapped mid-answer comes back on the next launch.** `reset()` (`AskAIConversation.swift:491-498`) calls `cancel()`, which saves the old transcript (`:488`), then saves the empty one; each save is its own `Task.detached` (`:537`) and the removal lands before the old encode and write (30 of 30 runs in a harness with `save()`'s shape). The menu item stays enabled while answering (`AskAIChat.swift:94`) and has no confirmation. Fix: serialize saves (one actor or serial queue with a generation counter), skip the save in `cancel()` when `reset()` calls it, confirm before resetting. CONFIRMED (simulated). DONE: saves on one serial queue in order; `reset()` cancels without saving; "New Conversation" asks first (confirmationDialog). By reading.
- [x] **U5. An empty reply shows "Thinking…" forever; the echo guard erases recaps.** The guard is built for every intent (`AskAIConversation.swift:128`) and applied at `:380` and `:411`; "repeat that" or "say it again" (`AskAIIntent.swift:446`) reproduce paragraphs that are substrings of the previous answer (`AskAIText.swift:193`), so all are dropped, the reply settles empty but not failed, and `AskAIChat.swift:461-464` shows "Thinking…" with no spinner. Fix: an empty guard for `.recap` and `.sourceQuestion`; an empty cleaned answer is a failure. CONFIRMED for verbatim repeats. DONE: empty echo guard for `.recap` and `.sourceQuestion`; an answer that polices down to nothing becomes a failure with Ask Again. Live: "repeat that" after the patience answer produced a full rework.
- [x] **U6. Religious questions are routed to app help.** `AskAIIntent.swift:139` matches app words as raw substrings and `:242` accepts any "how do i", "can i" or "where is": "How do I get closer to Allah?", "Where is the Kaaba?", "…charitable donations…" ("tab"), "…compassion…" ("compass"), "How do I share inheritance…" all become `.appHelp`, retrieve only settings and tips (`AskAIRetrieval.swift:151-160`) and are told to answer only from those (`AskAIIntent.swift:75`). Fix: match on token boundaries; take the question shapes out of `appWords`. CONFIRMED. DONE: `AskAILexicon.mentionsApp` matches whole words; the question shapes left `appWords`; everyday verbs ("share", "copy", "turn off") count only beside an app object ("share an ayah"). Probe: the five religious questions route as scripture/general, the reciter and share-an-ayah questions as appHelp.
- [x] **U7. "Who narrated…" questions skip retrieval.** `AskAIIntent.swift:223` with the unanchored regex at `:448`: "Who narrated the hadith of Jibril?" after any turn becomes `.sourceQuestion` and is answered from the previous turn's sources (`AskAIConversation.swift:161-167`). Fix: require a back-reference (that, this, it) for the narrator forms. CONFIRMED. DONE: the narrator forms need a back-reference. Probe: "Who narrated the hadith of Jibril?" routes as hadith, "who narrated that?" as sourceQuestion.
- [x] **U8. Clock times are read as verse references.** `AskAIIntent.swift:444`, `AskAIRetrieval.swift:432, 476`: "I prayed isha at 11:30, is that ok?" misses the prayer-times gate (`AskAIIntent.swift:236`), becomes `.reference`, injects Hud 11:30 and its tafsir as the subject and asks the model to "Explain that verse" (`AskAIEngine.swift:390-392, 412`). In Al-Quran (no `HAS_ADHAN`) any h:mm does this. Fix: skip h:mm followed by am/pm, preceded by at, by or until, or in a sentence with a prayer word. CONFIRMED. DONE: `AskAILexicon.maskingClockTimes` (length-preserving) before `referenceRegex` and the retrieval's ayah regex; "is (that|this) ok" joined the ruling words. Probe: the isha questions route as ruling and prayerTimes, "What does 2:45 say about prayer?" stays a reference.
- [x] **U9. `policeCitations` deletes legitimate text and calls it recalled.** `AskAIText.swift:433-438` matches the raw parenthetical while `citedSources` normalizes first (`:382-384`): "(Sahih al-Bukhari, 6114)", "(Bukhari no. 6114)" and "(2: 153)" are removed although the source is in the pool, and "Pray Asr (4:45 PM) before Maghrib (7:12 PM)" loses both times. Fix: reuse `citedSources`' normalization, collapse spaces around ":", exempt h:mm am/pm. CONFIRMED. DONE: `AskAIText.citationKey` on both sides, the clock mask over the whole text. Probe: the four legitimate parentheticals kept, two recalled ones removed.
- [x] **U10. Recap and source questions renumber the sources but keep the old markers.** `AskAIConversation.swift:164-166` passes cited sources in first-appearance order while `AskAIEngine.swift:378-381` pastes the previous answer with its old numbers and the recap task says "keeping its citations by number" (`AskAIIntent.swift:73`): "…[3]…[1]…" becomes sources [C, A], the old [3] is removed as recalled and [1] now shows card C. `clippedHistory` (`AskAIEngine.swift:424-429`) re-sends old markers under every new numbering. Fix: keep the previous sources in their original order (or rewrite the markers); strip markers from history. CONFIRMED (code path). DONE: the previous answer's markers renumbered to the new list (`renumberingMarkers`, `Turn.keepsMarkers`); other history re-sent without markers. Live: the recap's [3] and [5] pointed at 16:127 and 2:45 as the original did.
- [x] **U11. Long sources are clipped from the start, so the model quotes the wrong part.** Seen at runtime (`-askAILog`, this audit): "What does the Quran say about patience?" cited Sahih al-Bukhari 4750 and quoted its opening ("he used to draw lots among his wives…") as a lesson in patience; the passage that matched (the "beautiful patience" words deep in the narration) was cut by the 500-character clip (`AskAISources.swift:129`, budget at `AskAIEngine.swift:57`). Fix: clip a window around the best-matching sentence (the retriever knows the matched terms), keeping the opening only when it matches. Verify: re-ask and read `Documents/askai-log.txt`. CONFIRMED (runtime). DONE: non-subject sources carry `focusTerms` and `clip(_:to:around:)` windows the best-matching sentence. Probe passes; the live patience turn no longer quoted Bukhari 4750's opening.
- [x] **U12. Retrieval stalls the main thread.** `AskAIRetriever` is `@MainActor` (`AskAIRetrieval.swift:21-22`). Building up to 16 hadith sources decompresses cold text blocks on main through `hadith.allText` (`AskAISources.swift:198`, `HadithModels.swift:408-411`, `HadithPack.swift:536-551`; about 130 ms per block on the simulator), and `duaSources` (`AskAIRetrieval.swift:791-824`) re-folds every dua and Hisn entry per question (about 60 ms per 900 folds on the Mac). Fix: `prefetchText(rows:)` or build the sources inside the background lane tasks; fold the dua catalogs once. Verify: `-renderCounter -askAI "…"` logs no `HADITH BLOCK … MAIN`. CONFIRMED. DONE: hadith text blocks inflated off the main actor for all four hadith paths (the ranked lane inside its detached task, the others through `prewarmHadithText`); Hisn parsed off main; the dua catalogues folded once. Live with `-renderCounter`: every `HADITH BLOCK text` line of a turn read "bg", none "MAIN".
- [x] **U13. Surah suggestion chips cannot resolve their own subject.** `AskAIText.swift:591-593` emits "What are the main themes of surah 18?", but `AskAIIntent.swift:444` and `AskAIRetrieval.swift:435-436` accept only letters after surah or chapter, and `:507` skips short tokens: no subject, the `.define` intent, noise retrieval. Fix: accept `\d{1,3}` there, or put the surah's name in the chip. CONFIRMED. DONE: the chips name the surah ("Surah Al-Kahf"), and both surah regexes accept a number. Probe: "surah 18" and "Surah Al-Kahf" route as reference.
- [x] **U14. One-word article titles over-claim citations.** `AskAISources.swift:309` adds `article.title.lowercased()` as an alias; 41 of 121 titles are one word (Salah, Hajj, Shirk…), so `citedSources` (`AskAIText.swift:385-404`) marks every pooled section of that article as cited wherever the word appears, and the follow-up then flags them "already quoted" (`AskAIRetrieval.swift:299-314`). Fix: drop one-word title aliases. CONFIRMED. DONE: a one-word title is no longer an alias.
- [x] **U15. Common words become a Name of Allah subject.** `typedNames` (`AskAIRetrieval.swift:568-579`) includes salam, mumin, malik, wali, haqq and karim: "How should I reply to salam?" makes As-Salam the subject and skips every hadith lane (`:122-123`); "What is a wali?" is told to "Explain that Name". Fix: require the article form ("as-salam") or a Names cue. PLAUSIBLE (spellings from the deprecated JSON; check the live pack). DONE: a Name is a subject only in its article form ("as-salam", "assalam") or beside a Names cue. By reading.
- [x] **U16. The transcript grows without limit and loads on the main thread.** `load()` runs in `init` (`AskAIConversation.swift:93`); messages are never trimmed and every answer stores full source texts, whole Ibn Kathir entries included (`AskAISources.swift:245`). Fix: cap the turns kept, store clipped text or source ids, load off main. PLAUSIBLE. DONE (bounded rather than moved off main): 40 messages kept in memory and on disk, saved source text clipped to 2,400 characters; the load stays in `init` (the chat's first open), now bounded.

Quick wins found on the way (do them with the items above): precompile the 21 regexes `capitalizing` rebuilds on every flush; skip `AskAIRetriever.prewarm()` when Apple Intelligence is unavailable; "ablution" is listed twice in `synonymPairs`; `fold` keeps harakat and tatweel. DONE 2026-09-28: all four.

### Chosen Ayah widget, deep links, lifecycle, Need a Hand?

- [x] **U17. A cold launch from a widget tap lands on the launch tab, not the ayah.** `Al-IslamApp.swift:701` picks the final tab from `AppNavigation.shared.pendingQuran != nil`, but `openPendingQuranTarget` (`QuranView.swift:864-865`) clears it during step 2's `waitUntilQuranTabLaidOut`, so step 3 falls back to `launchTab`. Repro: kill the app, `xcrun simctl openurl <udid> alislam://ayah/2/255`: the app reveals on the Adhan tab with 2:255 pushed on the hidden Quran tab. Warm opens are correct. The Sunnah-reminder notification's cold launch uses the same check. Fix: a "land on Quran" flag owned by the warm walk (set in MainTabView's `.onReceive($pendingQuran)` when non-nil, cleared at step 3). CONFIRMED (reproduced). DONE: `landOnQuranAfterWarm` set by MainTabView's `.onReceive($pendingQuran)` before the warm finishes, read at step 3. Verified: cold `simctl openurl alislam://ayah/2/255` revealed on the Quran tab at Ayat al-Kursi.
- [x] **U18. The picker turns "Name S:A" into S:S.** `Widget/Quran/ChosenAyahIntent.swift:248-249` takes `numbers.first` (the surah number) as the ayah. `-chosenAyahProbe`: "Baqarah 2:255" and "Al-Baqarah 2:255" (the widget's own title format) give 2:2, "Yaseen 36:9" gives 36:36, "An-Nas 114:1" gives nothing. Fix: when a name resolves and there are two numbers, use the second (or the last); strip digits before the surah-name fallback in `entities(matching:)`. CONFIRMED. DONE: two numbers after a name take the last as the ayah; the name fallback strips digits. `-chosenAyahProbe`: "Baqarah 2:255" and "Al-Baqarah 2:255" give 2:255, "Yaseen 36:9" 36:9, "An-Nas 114:1" 114:1.
- [x] **U19. `.inactive` is treated as leaving the app.** `AppLifecycle.swift:152-161, 216`: pulling down Notification or Control Center, or opening the app switcher, runs `refreshQuranWidgets(.all)` (now also a card for every bookmark, up to 12 tajweed-painted chosen cards and a full re-encode on main, `SettingsQuran.swift:1540-1544`) plus the iCloud background pass; a real backgrounding runs both twice. It drains the per-widget reload budget (Last Read and Chosen Ayah go stale by evening) and hitches each pull. Fix: the widget refresh and the iCloud pass on `.background` only; rebuild bookmark and chosen cards only when the bookmark list or the placed widgets changed. CONFIRMED. DONE: the widget write and the iCloud pass run on `.background` only (after the flushes); a new `.backgrounding` refresh rebuilds the bookmark mirror and chosen cards only when `widgetCardsSignature` moved and reloads only kinds whose card changed (the snapshot types became Equatable). By reading.
- [x] **U20. "Need Help Getting Started?" closes its own sheet on the first tap.** The door exists only while `!StartHere.isShown` (`HelpDoors.swift:313`) and the card owns the sheet (`:469`); choosing Revert, Just getting started or Learning about Islam sets `startHereHidden = false` (`AboutYouView.swift:584-585`), the door leaves the `ForEach` and the sheet vanishes, so its "Show the Start Here Guide" section and "Replay the Welcome Tutorial" are unreachable from this door. Fix: keep the presented door in `HelpDoorsSection` state until the sheet is dismissed (or keep the door with a state pill). CONFIRMED (reproduced). DONE: the section owns `openDoor` and presents the one sheet from its single row; the open door stays listed until dismissed. Verified with idb: Revert chosen inside the door's sheet, the sheet stayed.
- [x] **U21. The bookmark mirror copies notes uncapped.** `SettingsQuran.swift:1585` clips the translation to 90 characters but copies `note` whole (notes are unlimited, `:1127`); the widget decodes the whole snapshot per timeline and per keystroke in Edit Widget (`ChosenAyahIntent.swift:284-286`). Fix: clip notes to about 150 characters in the mirror. CONFIRMED. DONE: notes clipped to 150 characters in the mirror.
- [x] **U22. Ayah of the Day fallback cards never get a deep link.** `SettingsQuran.swift:1528, 1568` rebuild the random pool only when it is empty or a card lacks `fontName`; pools written before 2026-09-28 have no surah or ayah, so the fallback card (`Widget/Quran/QuranProvider.swift:191-194`) has no `widgetURL`. Fix: also rebuild when any card lacks `surah`. CONFIRMED. DONE: `randomPoolIsStale` also rebuilds a pool whose cards lack surah or ayah (both refresh paths).
- [x] **U23. The containing-app pack fallback applies to every extension caller.** `QuranPackAdapter.swift:67-68`: nothing in the Widget or Complication touches `QuranData.shared` today, but one future call would start a whole-Quran load inside a 30 MB process. Measured on the no-card path: +0.7 MB to open, +3.4 MB after the first ayah, a 6 to 7 MB ceiling. Fix: an opt-in `url(_:allowContainingApp:)` used only by `ChosenAyahText`; release `ChosenAyahText.pack` after a read. PLAUSIBLE (latent). DONE: `QuranPackLoader.url(_:allowContainingApp:)`, opt-in, used only by `ChosenAyahText`, which now opens the pack per read.
- [x] **U24. Correct the Ask AI Guide.** `Docs/Ask AI Guide.md` says the marker crash is guarded in `normalizeMarkers`; it is not (U1). After U1, add the zero-source case and the U6 to U11 questions to its regression list. DONE: the guide corrected (both marker crashes), a Hardening pass section with these questions, a Persistence section, and `-askAITextProbe`.

---

## Phase 1: crashes and data loss in shipped code

- [x] **C1. Page mode crashes with Hide Arabic Dots (reproduced 2026-09-28).** Conditions: Hafs, tajweed on (the default), Hide Arabic Dots on, Hide Tashkeel off, page mode. The measured plain compose (`justification()`, `MushafReader.swift:4011-4020`, through `ayahText` at `:3523` with `choice.dots` from `:3357`) stays dotted, but the Hafs tajweed branch of the coloured compose passes no `removeDots:` (`:3532`), so `vocalized` (`QuranData.swift:294, 299`) falls back to the global flag and dot-strips it. `removingArabicDots` (`Globals.swift:921-929`) maps whole Characters, so every alef+maddah collapses and loses one UTF-16 unit (2,872 across 2,005 ayahs; 592 of 604 pages; page 3 loses 8), and `finalize` transplants the plain page's tracking runs onto the shorter string (`:5642-5643`): NSRangeException, abort. The launch warm lands through the same path, so it can abort before the reader is on screen. Fix: pass `removeDots: choice.dots` at `:3532` and at `:3556-3557` (the riwayah `fullText`); in `finalize`, skip the transplant (or recompose justified) when the lengths differ, so a future drift cannot abort. Ship with A1 and A2. Verify: `-launchTabQuran -quranPageMode -mushafPageLanguage arabic -displayQiraah "" -lastRead 2:11 -seedBool removeArabicDots=1,cleanArabicText=0` stays alive (today it aborts within 15 s at `:5643`); reset with `-seedBool removeArabicDots=0`, because the seed persists and every later launch would abort. CONFIRMED (reproduced; crash reports 2026-09-23 and 2026-09-28). DONE (with A1, A2): `choice.dots` no longer requires clean; the tajweed branch and the riwayah `fullText` get the RAW text (`Ayah.rawArabicText`, dotted, never reading the setting); `finalize` draws unjustified (DEBUG log "MUSHAF FINALIZE") instead of aborting if the lengths ever differ; `fitterVersion` 12. Verified: the guide's repro stays alive and renders page 3 dotless with tashkeel, maddah and tajweed; the fallback never fired. Seeds reset.
- [x] **C2. Integer overflow in the Custom Range sheet.** `CustomRangeSheet.swift:267-269` multiplies `ayahCount * repeatPerAyah * repeatSection`; while a repeat field is focused the typed value is stored unclamped (`:325-328`) and the ayah fields feed `ayahCount` the same way (`:296-299`), so typing a long number crashes on the next render. Fix: clamp while typing, or `multipliedReportingOverflow`. CONFIRMED. DONE: the focused fields clamp the stored value while the text stays as typed; `totalPlayCount` multiplies with overflow reporting. By reading.
- [x] **C3. Hadith reference parsing slices one string with another's range.** `HadithModels.swift:885-886` finds "sunnah.com/" in `lowered` and slices `text` with that range; "İ" lowercases to two scalars, so the indices shift: "İİİİ sunnah.com/bukhari:1" silently fails and 16 of them before the link traps (reproduced with a compiled test). It runs on every Hadith search keystroke and every Ask AI question (`AskAIRetrieval.swift:545`). Fix: `text.range(of: "sunnah.com/", options: .caseInsensitive)`. CONFIRMED. DONE: `text.range(of: "sunnah.com/", options: .caseInsensitive)`. `-askAITextProbe` case: 16 "İ" before the link now canonicalise to "bukhari 1".
- [x] **C4. The hadith share image has no height cap.** `HadithComponents.swift:2376` sizes the canvas to the text and draws it twice at screen scale (`:2378`, `:2392`) as soon as the sheet opens (`:2003`): Muslim 6843 (31.7k characters) makes a card about 20,000 pt tall, about 250 MB per bitmap and 0.5 to 0.75 GB at peak, gigabytes at accessibility sizes. A jetsam kill. Fix: per D6, cap (for example 12,000 pt) and end with "continues in the app", or render at scale 1 past a threshold. PLAUSIBLE. DONE (my call on D6, see Decisions): drawn once instead of twice, at a scale that keeps the bitmap under 24 M pixels (about 96 MB), and past 12,000 pt of text the card stops at a line with "The narration continues in the app." An ordinary hadith is unchanged. By reading (the share sheet needs a tap).
- [x] **C5. The heap-corruption suspect behind the 2026-09-21 crash.** That report is EXC_BAD_ACCESS with a pointer-authentication failure in `objc_retain`, copying `(book, idInBook)` inside `HadithStore.resolveDaily` on the main thread. Nothing in the hadith pack or store can corrupt the heap (the block cache is locked, packs are immutable, the decoder is bounded), so the crash is a victim. The likely source is background reads of `QuranData`'s arrays while the main thread reassigns them (`QuranData.swift:3913-3920`, at load and in `reloadForQiraahAvailabilityChange()`): `WordByWord.swift:604, 630` from the detached tasks at `HadithView.swift:2072, 2212` and `HadithBookView.swift:362, 375, 2004`; `DuaView.swift:165` through `QuranQuoteSource.swift:9-19` into `QuranData.ayah()` (`:4394`); and the word card's `WordAcrossRiwayat` and `QiraahAyahResolver` (`WordByWord.swift:2077-2085`, `ComparisonSheets.swift:1251, 1957`), main-actor by annotation but called from `Task.detached` (the three compiler warnings; a real race only if Show Qiraah is toggled mid-comparison). Fix: take the snapshot on the main actor and pass it in; `lexiconIfReady` returns nil off main; resolve Quran quotes on main; mark the two enums `nonisolated` and pass the two Settings bits in. Verify: T5 (Address Sanitizer first, then Thread Sanitizer). PLAUSIBLE. DONE: `QuranData.ayah(surah:ayah:)` and `surah(_:)` read one `Lookup` value published under a lock in the load's main-actor step; the lexicon's first snapshot hops to main when asked off main; the dua library resolves its Quran quotes on the main actor; `WordAcrossRiwayat`, `QiraahAyahResolver` and `QiraahComparison` are no longer `@MainActor` (their caches were already lock-protected; the statics are `nonisolated(unsafe)` behind `cacheLock`). This also removed three of T1's five warnings. The sanitizer runs of T5 are still to do.
- [x] **C6. A race in the widget previews.** `Widget/Adhan/PrayersProvider.swift:231, 234-236, 476` call `sampleEntry()` from `placeholder` and the preview `getSnapshot` on WidgetKit's background threads, and it reads and writes the unsynchronized `skyGradientOverridesCache` (`iPhone/Adhan/SkyPalette.swift:53, 70, 80`). The gallery asking 37 kinds at once can collide: a rare EXC_BAD_ACCESS in the extension (the watch face editor too, through the Complication). Fix: route it through the same main hop as `makeTimelineEntries`, or lock the cache the way `customColorLock` is locked. PLAUSIBLE. DONE: `skyGradientOverridesLock` around the memo, the `customColorLock` pattern.
- [x] **C7. A decode failure silently wipes user data.** `JournalView.swift:280` returns on a failed decode with `entries` empty, and the next edit writes the empty journal over the file; U3 is the same pattern for Ask AI. Fix: on a decode failure keep the bytes (rename to `<name>.corrupt-<date>` and log), decode leniently (`decodeIfPresent` with defaults), and sweep every user-data store for the pattern: bookmarks and notes, tracker marks, planner, reflections, history, tasbih, favorites. CONFIRMED (journal); the sweep is part of the item. DONE (with U3): `UserDataRescue` in Globals.swift: `loadList(file:)` (lossy per entry, the file copied or moved aside), `decode`/`decodeList(from:key:)` for defaults blobs (the bytes kept under "<key>.corrupt", written on the next main-queue turn so no body writes defaults). Applied to: journal (and `JournalEntry`/`JournalAttachment` decode leniently), reflections, activity log (both files), Ask AI, Quran bookmarks and notes, khatm progress, tracker marks (both shapes tried first) and exempt days, planner, the three Quran histories, hadith bookmarks, hadith last-read and viewed log, the seven favorites lists, custom and extra reminders, Sunnah reminder configs, the reading test, theme highlights, letter favorites. Tasbih stores plist-native types and has no decode to fail. Verified: an unreadable journal.json was moved to `journal.json.corrupt-<time>` and nothing overwrote it.
- [x] **C8. Arabic letter favorites point at different letters across launches.** `ArabicLetters.swift:66-72` hands out ids from a global counter that three lazily built tables consume in first-touch order; favorites store the whole `LetterData` and match by id (`:33, 449`). On a fresh launch straight into Settings, Favorites, Letters, the row body touches the non-Arabic table first (`SettingsQuranView.swift:1376`) and those six letters take ids 1 to 6: saved ا ب ت ث ج ح render as non-Arabic letters, stars light on پ and چ, and favoriting ب again saves a second ب. Fix: fixed ids or key by `letter`, store favorites as letter strings, migrate existing favorites by `letter`. CONFIRMED. DONE: favorites match and dedupe by `letter` and render this launch's table entry; the later tables touch the earlier ones first, so ids are always standard 1-28, other 29-40, non-Arabic 41-46; swipe removal keys on the letter. The stored format is unchanged (the backup and merge rules still apply). By reading.
- [x] **C9. iCloud's automatic backup ignores most changes.** `CloudBackupManager.swift:254-260, 512`: the "changed" flag is armed only by `ActivityLog.didChangeNotification` and by restores, so bookmarks, notes, favorites, tracker marks, journal and reflections, calculators and every setting never trigger the leaving-foreground backup. A lost phone loses that day while History says "Backed up automatically". Fix: also arm on `Settings.shared.objectWillChange` and the Documents stores' writes, or drop the flag and rely on the existing digest skip. CONFIRMED. DONE: the flag is gone; every automatic pass captures and compares the digest locally BEFORE the account and zone calls, and uploads only a changed snapshot. By reading (CloudKit is not exercised headlessly).
- [x] **C10. A failed restore claim stops automatic backups on the new phone.** `CloudBackupManager.swift:402-417` (with `:526, 556`): if the first claim save fails (offline, rate limited, zone busy) the claim stays set and `expectOwner` is lost; the next automatic save sees the old phone's `ownerDeviceID`, throws `.takenOver`, persists `cloudBackup.takenOver`, and automatic saves stop on the phone the user just moved to. If a save is already running, `save` returns at `guard !isBusy` without throwing, restore logs "switched", and the in-flight save (old `profileID`, new `nickname`) can overwrite and rename this device's previous profile. Fix: `clearClaim()` on failure as `createProfile` does (`:366`), or persist `expectOwner` until the first successful save; a busy `save` waits or throws. CONFIRMED (failure path), PLAUSIBLE (busy race). DONE: `cloudBackup.pendingTakeoverOwner` persists the owner a restore-and-switch takes over from until a save lands; a busy non-automatic save waits for the one in flight; the nickname is read once per save. By reading.
- [x] **C11. The leaving-foreground backup can be suspended mid-flight.** `CloudBackupManager.swift:516, 526` runs it in a bare `Task` and there is no `beginBackgroundTask` anywhere in the app: the upload suspends with `isBusy == true`, the next foreground's passes and Back Up Now return silently, and the late completion clears the new session's `contentChangedSinceSave`. Fix: wrap it in a background task; Back Up Now waits for or reports the running save; clear only the changes that were captured. Also delete the temp `profile-*.aib` that `fill()` writes on every save (`:700`). PLAUSIBLE. DONE: the leaving-foreground pass runs inside `beginBackgroundTask`, ended once by the save or the expiration; the temp `profile-*.aib` is removed after every upload. With the flag gone there is nothing to clear wrongly. By reading.
- [x] **C12. Dictionary inits that trap on a duplicate key.** `ComparisonSheets.swift:881` builds `Dictionary(uniqueKeysWithValues:)` from server data (`:1487` already uses `uniquingKeysWith`); `SettingsView.swift:226` does the same over static paths and titles. Fix: `uniquingKeysWith`. CONFIRMED (pattern). DONE: both sites use `uniquingKeysWith` (first wins).
- [x] **C13. Small traps to harden.** `MiraclesView.swift:158` `first...last` needs the clamp `:860` already has (only bad article data reaches it, and the data verifies clean); clamp the `acos` argument in `MoonPhase.compute` (`illuminationPercent` would trap on NaN); guard `IshaRule.format` against infinity. CONFIRMED (patterns). DONE: `first...max(first, last)` in the Miracles share text; the moon's `acos` argument clamped and `illuminationPercent` NaN-safe; `IshaRule.format` takes the Int path only for a finite value under a million.

---

## Phase 2: accuracy (Quran text, references, calculators, daily picks)

- [x] **A1. Hide Arabic Dots alters the Quran text.** `removingArabicDots` (`Globals.swift:921-929`) maps whole Characters through a `[Character: Character]` table, so on vocalized text only letters without a harakah change: 110,383 of 124,850 dotted letters (88.4%) keep their dots, and every alef+maddah (U+0627 U+0653, canonically equal to the key "آ") becomes a bare alef, deleting the maddah 2,872 times. This is what the list reader draws today with dots hidden and tashkeel shown (`QuranData.swift:299`). Fix: map unicode scalars with the same table as `dotlessArabicScalar` (`QuranData.swift:1023`): length-preserving, and the lockstep twin by construction (memory "dotless-rasm-all-riwayat"). Ship with C1 and A2. Verify: a script over the Hafs text asserting equal UTF-16 length before and after and zero dotted letters left. CONFIRMED (measured). DONE (with C1, A2): `ArabicRasm.dotless` (Globals.swift) is the ONE table; `removingArabicDots` maps scalars through it and `dotlessArabicScalar` calls it. Verified over the source text of quran.qpk: 124,850 dotted letters become 0, no ayah changes length, all 5,652 maddahs survive.
- [x] **A2. Hide Arabic Dots is still tied to Hide Tashkeel.** The switches became independent on 2026-09-11 (`SettingsQuranView.swift:836-866`), but the display resolvers still require tashkeel: `SurahView.swift:120` (`AyahDisplayOverride.resolved`: `tashkeel && (hideDots ?? removeArabicDots)`), `:201` (`appValue(.hideDots)`), `MushafReader.swift:3357` (`choice.dots = clean && …`), `:2896`, `AyahSheets.swift:375`, and TajweedStore's defaults (`QuranData.swift:611, 637, 674`). With tashkeel shown every riwayah stays dotted (seen at runtime on Warsh, list and page), while Hafs with tajweed goes dotless by accident because `AyahRow.swift:415` reads the global flag, so one surah can mix dotted and dotless ayahs; `prewarmArabicDisplay` keys by `clean && removeArabicDots` (`AyahRow.swift:275`) but computes with the global flag (`:285`), poisoning its cache; the word card reads the global flag (`WordByWord.swift:1807`). Fix: drop the coupling at each site, pass `removeDots:` explicitly at `AyahRow.swift:285, 415`, fix the TajweedStore defaults. Only together with A1 and C1. Verify: screenshots of list and page, Hafs and Warsh, tajweed on and off, tashkeel on and off, dots on and off. CONFIRMED. DONE: decoupled in `AyahDisplayOverride.resolved`, `appValue(.hideDots)`, MushafReader's `choices`, the TajweedStore defaults (all three) and its projection (`displayScalars` no longer requires clean), `AyahRow.prewarmArabicDisplay` (key and text now use the same bit), the search rows' tajweed (and their animation key), the share card's projection (its own switch only). Every "raw" caller of `displayArabicText(clean: false)` (tajweed, glosses, word cards, alignments, lessons, journal attachments, comparison rows) moved to `rawArabicText`. Verified: the list reader (Hafs) and a Warsh page render dotless with tashkeel and colors.
- [x] **A3. Al-Fatihah 1:1 becomes the basmala when Hide Tashkeel is on.** `QuranData.swift:359-363` swaps in the basmala when the cleaned text does not start with "بسم": for riwayat whose 1:1 is al-hamd (Warsh, and the Madani, Basri and Shami counts) al-Fatihah loses its first ayah and page 1 shows the basmala twice; under Hafs with dots also hidden, the dotless "ٮسم" fails the test and the dotted basmala comes back. Fix: drop the special case, or apply it only to a ta'awwudh prefix tested on the raw text, as the composer's own check does (`MushafReader.swift:3780`). CONFIRMED. DONE: only a 1:1 that opens with the ta'awwudh (`Ayah.opensWithTaawwudh`, raw text with the signs stripped) gives way to the basmala, in `displayArabicText`, the share card and Select Text. Verified: Warsh al-Fatihah with Hide Tashkeel shows al-hamd as 1:1.
- [x] **A4. Juz boundaries disagree inside the app.** `QuranData.juzList` (`QuranData.swift:4894-4955`, and QuranMetadata.json's hizbs 7 and 21) opens juz 4 at 3:93 and juz 11 at 9:93; quran.qpk's per-ayah `juz` puts 3:92 in juz 4 and 9:93 in juz 10, which matches the printed page tops of pages 62 and 202. The reader's dividers and the "juz N" jump use the pack; the Juz tab rows (`:4316`) and the Juz filter chips (`QuranSearchFilterModel.swift:445`) use `juzList`. So the reader labels 3:92 "Juz 4", the Juz tab opens juz 4 at 3:93, and the filter drops 3:92. Fix: one source per D3, plus a DEBUG check that compares them. CONFIRMED. DONE 2026-09-29 (D3 decided by Abu: the ۞ marks, see Decisions): `juzList` and QuranMetadata.json are back to 3:93 and 9:93 (the 09-28 move to the page tops, 3:92 and 9:94, is undone), and quran.qpk's per-ayah juz for 3:92 (4 to 3) and 9:93 (10 to 11) was patched in place (its xz eager section recompressed, block offsets shifted by 72 bytes, all four text blocks byte-identical), with the same two fields in Resources/JSONs-Deprecated/Quran.json for a future rebuild. Checked against the printed pages 62 and 201 (android.quran.com's Madani images: the ۞ precedes 3:93 and 9:93) and Quran.com's per-verse juz. DEBUG `-auditJuzTables`: "JUZ AUDIT DONE: 0 of 30 juz disagree"; `JuzTableTests` pins it.
- [x] **A5. Ayah-level play options in a non-Hafs display highlight the wrong ayah.** `SurahView.swift:3586, 3600, 3652` offer Custom Range, Random Ayah and Ayah by Ayah in a non-Hafs display, but ayah audio is Hafs-numbered (`QuranPlayer.swift:2265-2276`) and the highlight compares `currentAyahNumber` with the row ids (`SurahView.swift:1445`): Warsh 2:1 is Hafs 2:1 and 2:2, so Warsh al-Baqarah highlights one ayah ahead for the whole surah, and Warsh 1:1 (al-hamd) plays the basmala. `ContextMenu.swift:711` already gates these on `isHafsDisplay`. Fix: the same gate here. CONFIRMED (against qiraat.qpk). DONE: Custom Range, Random Ayah and Ayah by Ayah show only in a Hafs display in the list reader's play menu, the page reader's, the surah context menu's random ayah; the random picks skip the textless ids minted for the beta riwayat. By reading.
- [x] **A6. Page mode's "Go to" validates against Hafs.** `MushafReader.swift:1635, 1643, 1656` check `quranData.ayah`, so in Warsh (285 ayahs in al-Baqarah) "2:286" passes and `pageIndex` (`:220`) silently lands on al-Baqarah's first page with a non-existent ayah marked. Fix: accept only references found in `pages`, or check `existsInQiraah`. CONFIRMED. DONE: the three "Go to" checks ask whether the ayah exists in the DISPLAYED riwayah (`existsInQiraah`). By reading.
- [x] **A7. Beta riwayah state is missing from the page caches.** Neither `paginationKey`, `computeSettingsSignature` (`MushafReader.swift:5021`) nor `metricsKey` includes the beta flag (`:1322, 80-82`; `QuranData.swift:244, 323`): after "Use Beta Text" (`SurahView.swift:3896`) the reader reuses the Hafs-fallback pagination (merged rows show Hafs words, minted rows are empty) and serves cached Hafs-text renders; turning beta off while fits are queued can compose Hafs text against a beta justification, the same exception as C1. Fix: add the beta flag for beta tags to the three keys. CONFIRMED by reading (the crash half PLAUSIBLE). DONE: `MushafPagination.betaMark` ("|beta" or "|locked" for a beta tag, empty otherwise) in `paginationKey`, `computeSettingsSignature` and `metricsKey`. By reading.
- [x] **A8. The watch shows Hafs text labelled as a beta riwayah.** `displayQiraah` syncs raw to the watch (`WatchConnectivity.swift:508`, applied at `:668`) and the watch's picker offers beta tags (`SettingsQuran.swift:289-291`, `SettingsQuranView.swift:2494`); `BetaQiraatStore` is iOS-only, so `textArabic(for:)` falls back to `textHafs` (`QuranData.swift:242-248, 254`) under "Current Riwayah: Hisham" with the translation hidden (`SurahView.swift:1833-1835, 2915-2933`): the silent Hafs stand-in that `SettingsQuran.swift:243-246` forbids. Fix: on watchOS reduce a beta tag to Hafs in `applyWatchSyncSnapshot` and `displayQiraahForArabic`, or keep beta tags out of the watch picker. CONFIRMED. DONE: the phone sends a beta tag as Hafs (sanitized at send and at the watch's apply, the reading themes' pattern), `displayQiraahForArabic` reduces a stored beta tag on watchOS (and `isHafsDisplay` now derives from it), `textOptions` never offers beta tags on the watch. Watch target builds; not run (the watch sim's permission sheet).
- [x] **A9. Widgets and the watch fall back to the system font.** The Widget bundles only Uthmani, Indopak and QuranCommon (`Resources/Info-Widget.plist:5-10`), but the Name of Allah widget's default face is `KFGQPCHAFSUthmanicScript-Regula-NoStack` (`DailyReminders.swift:378`, `Settings.swift:2820`), which lives only in Uthmani-NoStack.ttf, so every user on defaults sees the system font (`DailyWidgets.swift:286-289`); Hijazi and Kufi Quran faces fall back too (`SettingsQuran.swift:1681`, `QuranProvider.swift:294-296`). Watch.app ships no Kufi or Hijazi files although its picker offers them (`SettingsQuranView.swift:895-897`) and `THEfontArabic` syncs (`WatchConnectivity.swift:507`). Fix per D7. CONFIRMED (from the built bundles). DONE (D7 taken as the no-size-cost option, see Decisions): `Settings.drawableArabicFontName` maps a face this process cannot draw to the Hafs Uthmani face (memoized, locked); used by the Reminder and Name widgets' Arabic, the Quran widgets' Arabic, and `quranArabicFontName` on watchOS; the watch picker drops Hijazi and Kufi and shows a synced one as Uthmani. By reading.
- [x] **A10. Daily picks use the calendar day before Fajr.** The Hadith of the Day shuffle is stored under `Settings.dayKey()` (`HadithStore.swift:929`) while `resolveDaily` compares `dailyDayKey()` (`:859, 863`; the Fajr rollover is on by default): between midnight and Fajr Shuffle does nothing, after Fajr the stale shuffle replaces the new day's hadith, and `:888` picks by the calendar-day number, so a first resolve before Fajr files today's pick under yesterday's key and the hadith repeats. The same bug is in Hide for Today (`ContextMenu.swift:604`). Fix: `dailyDayKey()` and `dailyDayIndex()`, as the Ayah of the Day shuffle does (`SettingsQuran.swift:1430`). CONFIRMED. DONE (with F3, P4): the hadith shuffle is filed under `dailyDayKey()`, the deterministic pick uses `dailyDayIndex()`, and the Ayah of the Day's Hide for Today writes `dailyDayKey()`. By reading.
- [x] **A11. The calculators read Arabic-Indic digits as zero.** `ZakahView.swift:84`, `InheritanceView.swift:632`, `ZakatAlFitrView.swift:26`: `amount()` keeps any numeric character but `Double("١٢٣٤٥")` is nil, so on a device typing Eastern Arabic or Persian digits every field is 0 (zakah asks the user to enter what they own; inheritance hides its money column), and a pasted "1.234,56" parses as 1.23456, a zakah 1,000 times too low. Fix: `normalizingArabicIndicDigitsToWestern` (the hadith search has it), map U+066B and U+066C, parse with a locale `NumberFormatter` first. CONFIRMED. DONE: `TypedAmount.parse` (Globals.swift) for all three calculators: Arabic-Indic and Persian digits, U+066B/066C/060C, the device locale's formatter first, then last-separator-is-decimal. Probe: "١٢٣٤٥", "1.234,56", "1,234.56", "٣٫٥", "$ 2,500", "۱۰۰۰" all parse right.
- [x] **A12. Inheritance gives the wrong reason for an exclusion.** `InheritanceView.swift:556`: daughter, full sister and paternal half-brother get the right shares (1/2, 1/2, 0), but the half-brother's reason says the fixed shares used up the estate; he is excluded by the full sister, who inherits as 'asabah ma'a al-ghayr. Fix: when the residuary is `.fullSisters`, block the paternal brothers with that reason. CONFIRMED. (The shares match four textbook cases worked by hand; the `precondition` at `:23` is unreachable.) DONE: with the full sister as residuary, the paternal half-brothers are "blocked by the full sister, who inherits here as a residuary alongside the daughter (‘asabah ma‘a al-ghayr)". The shares were already right.
- [x] **A13. The Reminder widget can keep a stale card all day.** `DailyReminders.swift:381, 412` against `:319`: `refreshWidgets` captures the resolved card before its background build and then saves a whole new snapshot, so a `writeResolvedWidgetCard` landing in that window is overwritten, and `publish` (`:622`) never rewrites an unchanged card. Fix: reload the blob inside the save and keep the newer `resolved` card. PLAUSIBLE. DONE: a resolved-card generation (bumped on main, recorded on the widget queue); the full rebuild keeps the on-disk resolved card when a newer one landed after its capture. By reading.
- [x] **A14. The streak freeze shows as used when it was not.** `ActivityLog.swift:340-348` spends the month's freeze on the missed day that ends the run and then breaks, so `freezeUsed` is true whenever the run began this month (a first active day, or a run starting the day after a miss); the dashboard (`ProfileDashboard.swift:134, 472`) says "Freeze: Used / 0 left". The streak count itself is right. Fix: hold the freeze tentatively and commit it only when an earlier active day continues the run. CONFIRMED. DONE: freezes are pending until an earlier active day continues the run, then committed; `freezeUsed` reads committed freezes only. The count itself is unchanged.

---

## Phase 3: prayer times, notifications, widgets, watch

- [x] **P1. The launch time zone is frozen into the prayer day and the time strings.** `SettingsAdhan.swift:1432` (`static let gregorian = Calendar(identifier: .gregorian)`, used for the day components at `:1639` and Jumu'ah at `:1695`) and `AdhanStructs.swift:113` (`formatter.timeZone = .current` behind the static `timeEN` and `timeAR`, `:122-123`) keep the zone of first use (verified with a Swift script: `Calendar.current` moved, these did not). Launched in Tokyo and landed in Los Angeles: from 08:00 local the app builds tomorrow's table as today; the time-zone-change refetch (`AppDelegate.swift:86`) schedules D+1 to D+14 and prunes today's remaining adhans; Jumu'ah shows on Thursday afternoon (westward) or Saturday morning (eastward); notification bodies ("Time for Dhuhr at 4:05 AM"), the sky card's labels (`SkyView.swift:570, 579`), the calendar and the Siri answers print the departure zone's clock. Fix: `timeZone = .autoupdatingCurrent` on that calendar and the formatters (or `Calendar.current` per call), and the same for `hijriCalendarAR` (`:1410`) and `Settings.hijriCalendar`. Verify: a DEBUG time-zone override mid-session, then today's table, Jumu'ah and one notification body. CONFIRMED. DONE: the prayer-day Gregorian calendar, the Umm al-Qura calendars (SettingsAdhan, Settings.hijriCalendar, CalendarView), both Hijri formatters, the time formatters behind `timeEN`/`timeAR`, the two tracker day-key formatters and the tracker's display calendar are all in `.autoupdatingCurrent`; `Settings.dayKey` too (F3). Verified the mechanism with a Swift script: after a system zone change the auto-updating calendar moved to the new zone while a `.current` one stayed put. (Setting `NSTimeZone.default` in-process is not honored by this Foundation, so a DEBUG override would not test it.)
- [x] **P2. The 60-request budget goes to events months away, and has no floor.** `SettingsAdhan.swift:2738-2743` (the cap), `:2814` (events), `:2857-2861` (tier order): 23 Hijri-event requests (12 events and 11 day-before reminders), on by default and with no horizon, sit in tier 3 ahead of every near nag, reminder and extended adhan. Counted from the code: on defaults at noon they take 46 slots and adhan coverage ends around day 6 instead of 14; with nagging on, no adhan is scheduled past tomorrow; with nagging, 9 Sunnah presets, 8 duas and 6 nudges, `maxPending` is 37 and leaves about 3 slots, so today's cascades mostly vanish and nagging silently does nothing. Custom reminders are uncapped (`ReminderKinds.swift:127`): past 60 enabled slots `maxPending` reaches zero or below, nothing is added, and the prune deletes every pending adhan. Fix per D4: drop events beyond the adhan horizon (or rank them after tier 5) and clamp `maxPending` to at least about 20. Verify: a DEBUG dump of the planned requests by tier with nagging on and 20 custom reminders. CONFIRMED (counted from code). DONE (D4 taken as recommended): Hijri events are queued only inside the 14-day adhan horizon (`adhanHorizonDays`), and the prayer scheduler keeps at least 20 requests (`minimumPrayerNotificationBudget`) whatever the reminders hold. Verified with `-dumpNotifications` on defaults: 60 of 60 planned, no far events, at-time adhans for 12 days (the audit counted about 6).
- [x] **P3. The scheduler adds before it prunes.** `SettingsAdhan.swift:2925-2950`: a traveling-mode flip (the `~t` signature, "Dhuhr/Asr") or the English-names switch changes every identifier, so the new set is added while the old is still pending; over 120 requests exist for a moment, iOS keeps the soonest 64 (events and far adhans go first), then the prune removes the old set, leaving about half a schedule. The automatic flip runs from a background location wake, so no quick second pass repairs it. Fix: read the pending list, remove the stale ids this scheduler owns, then add; re-check `isCurrentNotificationPass` inside the prune callback. PLAUSIBLE. DONE: the build queue reads the pending list, removes the stale owned ids, THEN adds; the pass generation is re-checked inside the callback. By reading.
- [x] **P4. The tracker card files Isha by the civil day.** `PrayerTrackerView.swift:496` (`trackableSlots(for: Date())`) and `:576` (`date: Date()`): at 00:30 the card shows the new day, so tapping Isha marks tonight's; last night's stays unmarked and the streak resets. Where Isha starts after midnight (high-latitude summers, the Middle of the Night rule) the right Isha can never be marked. The countdown, the scrubber and the "Did you pray X?" question file by the prayer's day. Fix: before today's Fajr, bind the card (or its Isha slot) to yesterday. CONFIRMED. DONE (with A10): the tracker card binds to `trackerDay`, yesterday until today's Fajr (from the live list when it is today's, else computed), for its slots, exempt check, count, marks and toggles; the label reads "Yesterday, until Fajr". By reading.
- [x] **P5. Two prayers can share one notification id.** `SettingsAdhan.swift:4004, 4024` stamp ids with the trigger's date; when a time drifts back across midnight between consecutive days (Islamic Midnight in London around October 20: 00:00:30 one night, 23:59:30 the next; a Middle of the Night Isha; a large offset), the second add replaces the first and that night's notification is lost. Fix: stamp the prayer's own computation day, as the follow-ups do, and update `cancelPendingNags` to match. CONFIRMED. DONE (narrower than restamping every id, which the nag cancel logic depends on): when two requests of one pass share an id, the later-firing takes a stable "#2" after the signature; `cancelPendingNags` accepts that form; the tap parser reads only the first two fields. By reading.
- [x] **P6. Polar latitudes get no times and a stale countdown.** At about 67.4° and above, during polar day and night, `SolarTime` returns nil; the `PrayerTimes` guard (`SettingsAdhan.swift:1677-1682`) returns an empty list with no notifications and no explanation, the failure is not cached (the solar math reruns on every call), and `updateCurrentAndNextPrayer` returns early (`:2098`), keeping the previous location's current and next prayer. Fix per D5, plus clear current and next and cache the failure. CONFIRMED. DONE (D5 taken as the nearest-latitude fallback, see Decisions): above 65 degrees, when the solar math has no answer, the times of 65 degrees on the same meridian stand in (`polarFallbackTimes`); a failure is cached (and ordered for eviction); an empty list clears the current and next prayer. By reading.
- [x] **P7. The fasting Live Activity is never dismissed in the background.** `FastingActivityController.swift:43, 63` set only a `staleDate`, and `refresh()` runs on foreground only, never from the background task (`AppDelegate.swift:252-300`): after iftar or Fajr the card sits at 0:00 on the Lock Screen for hours. Fix: draw an ended state when `context.isStale`, call `refresh()` from `handleAppRefresh`, schedule an end at the deadline plus 5 minutes. CONFIRMED. DONE: `FastingActivityController.refresh()` runs in `handleAppRefresh`; the Lock Screen card and the compact island show an ended state ("Maghrib has begun, at 6:42 PM in ...") once `context.isStale`. By reading (Live Activities are not exercised headlessly).
- [x] **P8. Four date lock-screen widgets are never reloaded.** `Settings.swift:721-737, 777`: `adhanWidgetKinds` lists 33 kinds; `HijriDateLockWidget`, `HijriDateArabicLockWidget`, `DualCalendarLockWidget` and `NextPrayerDateLockWidget` (`Widget/Adhan/DateLockWidgets.swift:83, 98, 152, 219`) came later and were never added, so a new city, method, offset or Hijri offset leaves them on old values for up to about 30 hours (`.all` fires only from the accent's didSet, `:1247`). `PrayersProvider.swift:177` still says "37 on iOS". Fix: add them, and derive the list from one table that `Widgets.swift` also uses, with a DEBUG check that every provider kind is in it. CONFIRMED. DONE: `AdhanWidgetKind` (Settings.swift), one case per Adhan widget; all 37 widgets take `kind` from it and `adhanWidgetKinds` is its `allCases` (the four date lock widgets included). A new widget that names its kind through the enum is reloaded automatically.
- [x] **P9. "Switch Hijri Date at Maghrib" reloads no widget.** `Settings.swift:1567-1576` mirrors the value to the App Group but never reloads, and built entries carry the old flag (`PrayersProvider.swift:371`). Fix: `reloadWidgets(deferred: true)` after the mirror. CONFIRMED. DONE: the didSet reloads the Adhan widgets after mirroring.
- [x] **P10. Widgets cannot see the traveling "View Full Prayers" flag.** It lives in standard defaults (`Settings.swift:1891-1896`, read at `SettingsAdhan.swift:2084`), is not mirrored (`Settings.swift:1004-1008`) and triggers no reload, so past Asr the app says "Asr" while widgets and the complication say "Dhuhr/Asr", breaking the promise at `PrayersProvider.swift:285-286`. Fix: mirror it, re-seed it in `makeEntryOnMain`, add it to `Inputs`, reload `.adhan` from its didSet. CONFIRMED. DONE: mirrored to the App Group in its didSet (seeded once when absent, and in the restore's remirror), re-seeded into the extension's defaults in `makeEntryOnMain`, part of `Inputs`, and the didSet reloads `.adhan`.
- [x] **P11. Extension processes keep stale settings.** The accent and custom hex are cached in `static let`s (`Globals.swift:332-337`, `Widget/Quran/DailyWidgets.swift:38-40`, `QuranProvider.swift:58-60`); `highLatitudeRule` and `customPrayerNames` are read only in `Settings.init` (`Settings.swift:251-252`) and are missing from the provider's `Inputs` memo (`PrayersProvider.swift:183-216, 384-419`). A reused extension process paints the previous accent and builds tomorrow's table with the old rule. Fix: read them from the suite on each timeline build, re-seed, add to `Inputs`. PLAUSIBLE (depends on process reuse). DONE: the extension's custom hex and both Quran widget accents are read from the App Group per use; `highLatitudeRule` and `customPrayerNames` are re-seeded on every build and are part of `Inputs`.
- [x] **P12. A standalone watch retries a failing sync on every change.** `WatchConnectivity.swift:242-247, 298-307`: only iOS checks that the counterpart app is installed; on a watch without the phone app `updateApplicationContext` throws, `lastPushedFields` never advances, so every debounced publish rebuilds the 122-key snapshot, throws, and writes two plist blobs. Fix: on watchOS `guard session.isCompanionAppInstalled`, and persist only when the stamps changed. PLAUSIBLE. DONE: on watchOS the publish returns without the companion app; state is persisted only when a stamp moved or a push landed.
- [x] **P13. The watch receives keys it cannot honour.** `quranPageMode` and `mushafPageLanguage` sync (`WatchConnectivity.swift:510`) and break the watch's jump back to the playing ayah (`SurahView.swift:3549, 4185`). Fix: one watchOS filter in `applyWatchSyncSnapshot` for page mode, beta riwayat (A8) and unbundled fonts (A9). CONFIRMED (low impact). DONE (with A8): "quranPageMode" and "mushafPageLanguage" left the watch-synced list (both stay in the backup's hand-kept preference list), and the watch removes any value an older build synced. By reading.
- [x] **P14. Notifications are built when they cannot be delivered.** Runtime: with notifications not authorized (every headless run), one traveling flip built and added 61 requests that all failed ("Source is not authorized"). Fix: skip the build while authorization is denied and rebuild when it is granted. CONFIRMED (runtime; cost only). DONE: `Settings.notificationsDeliverable` (set by every authorization check); while false the scheduler builds nothing (DEBUG `-dumpNotifications` still plans), and the first check that finds permission again reschedules. The final sweep showed the gate missed launch (a traveling flip schedules before any check has run, so it was still nil and 61 failing requests went out); the scheduler now reads the status first, without prompting, when nothing is known. Rerun with permission switched off in Settings: the flip adds 1 request (the traveling banner's own one-shot, left alone) instead of 61.

Quick wins: delete the uncalled one-shot `scheduleNotification(for:)` helpers; silence the watchOS warning at `SettingsAdhanView.swift:1283` (T1). DONE 2026-09-28: both helpers deleted; the watch warning gone (`smallButtonsStack`).

---

## Phase 4: recitation playback

- [x] **R1. A failed Play leaves the previous recitation playing while the UI shows it stopped.** `QuranPlayer.swift:1132-1142` change state, then return early at `:1157` or `:1189`, before `:1195` pauses the old player; `presentPlaybackFailure` (`:602`) clears `isPlaying` and `isPaused`, so the bar disappears while the audio continues, the lock screen's pause returns `.commandFailed` (`:824`), and when the old surah ends playback continues from the failed surah plus one (`:1367`) with the repeat count reset. Repro: offline, playing a downloaded surah, tap Play on one not downloaded for the reciter, or one a partial reciter lacks (Hazza, Islam Sobhi, Minshawi 1387, Dibirov). Fix: run every guard before changing state; pause or stop the current player before presenting a failure. CONFIRMED. DONE: `playSurah` runs every guard (reciter, recorded surah, URL, the offline offer) before any state changes, and `presentPlaybackFailure` calls `stop()` first, so the audio stops with the bar and the old surah's position is saved. Smoke test: `-playSurah 1` plays normally. The failure paths by reading.
- [x] **R2. Interruptions resume audio the user had paused.** `QuranPlayer.swift:744-761`: `.began` always pauses and `.ended` with `.shouldResume` always plays, so a paused recitation starts by itself after a call. The observer also sees interruptions of the shared session used by the adhan player, the adhan preview, `QiraatVariantAudio` and `ArabicSpeech`, setting `isPaused` with no player, after which the bar comes back on the retained context (`NowPlayingView.swift:49`) and `.ended` flips it to playing over silence; `playCommand` (`:810-821`) sets `isPlaying` with no player loaded. Fix: record `wasPlaying = isPlaying && player != nil` at `.began`, ignore interruptions when nothing is loaded, resume only if it was playing. CONFIRMED (the call case), PLAUSIBLE (the shared-session case). DONE: `.began` records whether THIS player was sounding (loaded, playing, not paused) and pauses only then; `.ended` resumes only that; the remote Play command refuses when nothing is loaded. By reading.
- [x] **R3. Random picks ignore reciter coverage.** `playRandomReciter` (`SurahView.swift:3718`) saves the random reciter before playing; the Random Reciter setting (`QuranPlayer.swift:1107`) and "Play Random Surah" (`QuranView.swift:2384`) share the gap: Dibirov (24 surahs) or Minshawi 1387 (26) produce "has not recorded this surah" and leave the user on a partial reciter. Fix: filter by `carriesSurah`, and by the displayed riwayah. CONFIRMED. DONE: `QuranPlayer.randomReciter(recording:displayQiraah:)`: reciters who recorded the surah, of the displayed riwayah when any carry it; used by the Random Reciter setting, the reader's Play Random Reciter, and Play Random Surah (which picks among the chosen reciter's surahs). By reading.
- [x] **R4. Custom-range downloads are not tied to their range.** `QuranPlayer.swift:1908-1921`: a late fetch from the previous range clears the new range's `customRangeAwaitedPosition` and the empty-queue branch calls `stop()`, ending the range early on a slow network; the ran-dry path calls `q.play()` without checking `isPaused`, so a range paused while loading resumes by itself. Fix: carry a range token and check it, and `!isPaused`. PLAUSIBLE. DONE: `customRangeToken` renewed per range and by `stop()`; a fetch or insert from another range is ignored; a range that ran dry resumes only when not paused. By reading.
- [x] **R5. Late status callbacks act on a player that is no longer current.** `QuranPlayer.swift:1284, 1805, 2063` hop to main without checking the item: if surah A's ready callback is queued when B starts, A retitles Now Playing, enters history and is saved as last listened. Fix: `guard item === self.player?.currentItem` inside the hop. PLAUSIBLE (narrow window). DONE: the four status observers check the item is still the current one (surah, single ayah) or still in the queue (custom range, ayah queue). By reading.
- [x] **R6. Leftovers.** `PlaybackAudioCache.prefetch` keeps downloading the whole range after stop; `insertTimeRange` runs synchronously on main for every ayah cut from a downloaded surah (`QuranPlayer.swift:3757`). Fix: cancel prefetch on stop; cut off main. CONFIRMED (code). DONE (the cut stays synchronous, it is now paid once per file): `PlaybackAudioCache.cancelPrefetch()` (a prefetch generation) from `stop()`; `makeSegmentItem` reuses one parsed `AVURLAsset` per surah file (NSCache of 4). By reading.

---

## Phase 5: glitches (SwiftUI and navigation)

- [x] **G1. The Dua of the Day card pushes two screens on one tap.** `DuaView.swift:1687, 1718`: `HisnDuaOfTheDayCard` is one List row (`:424-426`) holding two NavigationLinks, the hidden `chevronlessLink { DailyHubView() }` on the Today pill and "More duas for this situation" (memory "one-link-per-list-row"). Tapping anywhere on the card pushes both; Back reveals the second. Repro: Islam, Duas, tap the card. Fix: two plain Buttons writing one `@State` enum, and one `.pushDestination` on DuaView's List (the Reminder of the Day card's pattern once G2 moves it). CONFIRMED. DONE: the card's two links became buttons that set a `HisnDuaCardDoor`, and one `pushDestination` on the card resolves it, so a tap pushes one screen. By reading.
- [x] **G2. Push destinations inside lazy containers.** Runtime fault on the Islam tab, "Do not put a navigation destination modifier inside a lazy container", from `DailyReminders.swift:1034`: the Reminder of the Day card (a List row, also mounted in `DailyHub.swift:39`) carries its own `.pushDestination`, so a resolver publish that removes or re-keys the card (`DailyReminders.swift:597-622`, for example at the daily rollover) pops a pushed Saved Reflections or Today screen by itself. `SignsAndProphets.swift:457` hangs `.pushDestination` on a Section inside each prophet page's List (landed in `02d77a2`), so up to seven `navigationDestination(isPresented:)` copies (header, footer, rows) share one Bool: a double push, or a push dropped or popped. Repro: `-launchTabIslam -islamScrollToReminder` (the fault); Pillars and Beliefs, Musa, HIS MIRACLES, tap a row. Fix: hoist the state and one `.pushDestination` to the host List (IslamView's `islamList`, DailyHub's List, the prophet page's List). Every other `pushDestination` site was checked and is correctly placed. CONFIRMED (runtime and structure). DONE: the Reminder of the Day card takes an `openDoor` binding and its destination sits on the list itself (IslamView, DailyHub); the prophet-miracle doors go through `ProphetMiraclesHost` on each page. The lazy-container fault is gone from the Islam tab run.
- [x] **G3. Changing "Default List View" rebuilds every List.** `ViewExtensions.swift:1259` returns `AnyView(content)` or `AnyView(content.listStyle(.plain))` depending on `defaultView`, so the flip (`SettingsView.swift:1405`) destroys and rebuilds all 277 styled Lists: no animation, and every mounted List loses its scroll position and `@State` (the Quran reader in another tab comes back at the top of its surah, since its re-anchor is guarded by `didScrollDown`). Fix: latch the style per List at first appear, so a flip restyles lists as they next open. CONFIRMED. DONE: `applyConditionalListStyle` latches Default List View on appear (`followsListViewLive` only on the Look and Feel page), so flipping it no longer swaps every List's identity; the rest pick it up on their next appearance. By reading.
- [x] **G4. A layout cycle in printed-mushaf page mode.** Runtime: nine "AttributeGraph: Cycle detected through attribute" errors with `-launchTabQuran -quranPageMode -mushafPageLanguage pdf -lastRead 36:1`. No SwiftUI measurement loop exists there; the likely source is `FitFlooredPDFView.layoutSubviews` (`MushafPDFReader.swift:195-201`) rewriting `minScaleFactor`, `maxScaleFactor` and `scaleFactor` inside its own layout pass for every mounted page (up to 13), plus the forced `layoutIfNeeded` in `install` (`:267-270`). Fix to try: give the representable a `sizeThatFits` that returns the proposal, and pin the zoom floor on a bounds change instead of inside `layoutSubviews`. Verify: the cycle count in that screen's log goes to zero (`analyze.py`). PLAUSIBLE. DONE: the PDF view's document install is deferred to the next run-loop turn (`coordinatedInstall`), and the floor pins only on a size or document change; lldb showed `PDFDocumentView` becoming first responder inside SwiftUI's update. Cycles 9 to 0 with the page rendering.
- [x] **G5. Page-mode find jump: size churn and invalid screen conversions.** Runtime, `-mushafFindBar "20:6" -mushafFindJump`: "onChange(of: CGSize) action tried to update multiple times per frame" and six UIScreen coordinate-conversion faults. The only `onChange(of: CGSize)` is `MushafReader.swift:1111`; it does not feed itself, the band simply takes several sizes in one frame (the find bar closing, the keyboard leaving, the page turn). The conversion faults come from `MushafPagerProbe.locate` (`:5971`) calling `convert(_:to: nil)` before its `window != nil` guard, from `layoutSubviews` and `updateUIView`, while the pager is rebuilt. Fix: coalesce the size to the next runloop turn (or `onGeometryChange` on iOS 18+); move the guard above the convert. CONFIRMED (runtime); the fix is PLAUSIBLE. DONE: `MushafPagerSizeReader` reads the band with `onGeometryChange` on iOS 16+ (the GeometryReader pair stays for 15); the CGSize fault is gone (two reports 50 ms apart, 622.3 then 600.7, the bar's room then the keyboard). The probe now checks for a window before converting. The seven UIScreen faults are NOT the probe: the same three rects appear on the Zakah screen with its keyboard up, so they are the system keyboard's (Appendix A).
- [x] **G6. Surah-wide find matches bypass `turnPage`.** `MushafReader.swift:1583, 1601` (`syncMatch`, `goToMatch`) write `pageIndex` with an animation; a match outside the mounted window (radius 6, or 14 in a spread) selects an unmounted tag while `recentreWindow` moves the window in the same pass, the pattern `jumpToReference`'s comment blames for the 20:6 loop. At least a snap or a blank page. Fix: route both through `turnPage(to:in:suppressClear: true)`. PLAUSIBLE. DONE: `syncMatch` and `goToMatch` turn through `turnPage(to:in:suppressClear: true)`. New DEBUG hook `-mushafFindStep <n>`: `-mushafFindBar الله -mushafFindStep -1` from 2:1 wraps to match 165 of 165, the reader lands on page 49 with 2:286 lit.
- [x] **G7. Removals that skip the confirmation rule.** Multi-select "Unbookmark" (`SurahView.swift:3306-3314`) removes every selected bookmark and its highlight without asking unless a note is attached; unfavoriting a letter or a Name skips it (`ArabicLetterViews.swift:690, 2820, 2907, 3192, 3342`; `NamesView.swift:1254`); Ask AI's "New Conversation" has no confirmation (U4). Fix: always confirm with a `confirmationDialog` (memory "unmark-confirmation-and-summary-grid"). CONFIRMED. DONE: multi-select Unbookmark always confirms (the message names notes only when some would go); `toggleLetterFavoriteOrConfirm` and `toggleNameFavoriteOrConfirm` (RemovalConfirmation.swift, plain toggles on the watch) at all five letter sites and six Name sites. Simulator: favoriting Al-Hayy is instant, unfavoriting asks "Remove from favorites?". U4 was done in Phase 0.
- [x] **G8. Animated picker bindings.** `ThemeHighlightsView.swift:133` binds `$surahID.animation(.easeInOut)` (added 2026-09-16, after the 2026-09-07 strip), so the menu picker's label lags; `TafsirSheets.swift:209` puts `.animation(.easeInOut, value: selectedAuthor)` on the segmented picker, so the indicator slides, snaps back and slides again. Fix: plain bindings; animate the content below with `.animation(_:value:)` on it (memory "picker-no-animated-binding"). CONFIRMED (the first), PLAUSIBLE (the second). DONE: plain `$surahID` on the themes picker; the tafsir segmented picker lost its `.animation(value:)`. By reading (the rule's own repro is in memory "picker-no-animated-binding").
- [x] **G9. Rows that bake Dynamic Type into fixed fonts never resize live.** `SurahRows.swift:394, 405, 428, 435, 743, 1406, 1480`, `WordOfDay.swift:271`, `HadithComponents.swift:329, 333` build a fixed font from `UIFont.preferredFont(...)` in body without reading `dynamicTypeSize`, and nothing publishes a text-size change: after a Control Center size change the Arabic surah names, search and bookmark Arabic and compact hadith text stay at the old size while the English resizes, until the rows scroll off. Fix: read `@Environment(\.dynamicTypeSize)` in these rows (or fold it into `==`), or use `.custom(_:size:relativeTo:)`. PLAUSIBLE. DONE: the five rows (SurahRow, SurahAyahRow, AyahSearchRow, HadithRow, SummaryWordTile) declare `@Environment(\.dynamicTypeSize)` and read it through `textStyleSize(_:)`, so a text-size change re-renders them. Watch build green. By reading (no headless text-size switch).
- [x] **G10. "Reset Settings, Keep My Content" also resets device-only state.** `Settings.swift:1128-1133` wipes `THEfirstLaunch` among others: the root flips to the splash over the Settings tab (`Al-IslamApp.swift:71`), About You treats the user as new (its suggestions default on), and one-shot guards run again (`extraRemindersArmedSignature`, `didAdoptMinshawiAdhanDefault`, the permission "never ask" flags). Fix per D8: spare device-only keys the way `resetSparedPrefixes` spares `cloudBackup.`. PLAUSIBLE (the intent is not documented). DONE (D8 taken as: keep device-only state): the device-only list moved from CloudManifest to `Settings.deviceOnlyStorageKeys`/`deviceOnlyStoragePrefixes` (the manifest reads them), and a keep-content reset spares them (`Settings.isResetSpared`, which also covers the `<key>.corrupt` rescue copies). `-cloudResetProbe keep`: THEfirstLaunch 0 and aboutYouVersionSeen 1 survive, 37 device-only keys spared, bookmarks 208/208, the app stays on Settings with no splash. `check_cloud_manifest.py` reads the new home and passes.
- [x] **G11. The appearance tripwire fires on every launch, so it can no longer catch a real miss.** Every one of the 92 sweep launches logged "APPEARANCE ENV default read". An lldb breakpoint on `AppearanceDefaultTripwire.note` (`ViewExtensions.swift:177`) shows the read comes from the root injector's own write, `.environment(\.appearance, environment)` (`:321`): writing a computed `EnvironmentValues` property through a WritableKeyPath calls its getter first, while the key is still absent (`ChildEnvironment.updateValue`, `swift_setAtWritableKeyPath`). The one-shot log is spent at launch, so a genuinely missing root (the sibling apps' stale-accent bug, memory "sibling-root-wiring") would go unreported. Fix (DEBUG only): ignore reads whose stack contains `swift_setAtWritableKeyPath`, or arm the tripwire after the injector's first pass; then rerun the sweep to see whether any real default read remains. CONFIRMED. DONE: the key stores an Optional; readers go through `appearance` (injected value, or the fallback that trips the wire), injectors write `injectedAppearance`, whose getter never builds the fallback. Zero tripwire lines on all five tabs; a live `-settingsProbe accentColor=red@2` still recolours the chrome.
- [x] **G12. Small ones.** `TafsirSheets.swift:551` calls `scrollTo` in `onAppear` without deferring (the Surah Info source chip strip may open uncentred); `IslamView.swift:1319` puts `.contextMenu` on the ProphetQuote Section, so the header lifts with the card; `-launchHadithSettings` presents a sheet before its presenter is in the window (DEBUG hook only). Fix each in place. CONFIRMED or PLAUSIBLE as noted. DONE: the tafsir source strip scrolls on the next turn; the Farewell Sermon card's context menu moved from the Section to the card. The `-launchHadithSettings` hook: my first check grepped for "not in the window" and missed SwiftUI's "not yet in the window"; the final sweep caught it. The hook now lands on the Hadith tab by itself (`MainTabView.launchTab`; the sweep line passes no `-launchTabHadith`, so the sheet's presenter sat on a tab that was not showing), fires once, and waits for the warm walk as well as the reveal. Rerun: 0 lines, the sheet presents.

---

## Phase 6: performance

The idle bar from the Performance Guide still holds (the baseline: zero Settings publishes on every tab). What regressed is launch, and a few hot paths added after 2026-09-04.

- [x] **F1. Launch is about 1 to 2 s slower than on 2026-09-04: bisect it.** Same stopwatch (`-launchTiming`), same simulator model: reveal 3.3 to 3.6 s then, 4.3 s today on iOS 27 and 5.6 s on iOS 26.5; the launch cover now comes up at +1.1 s instead of +0.58 s, before any data loads. The runtime is not the cause (26.5 is slower still); the code or the toolchain is (Xcode 27.0 today, 26.6 then). Step 1: build `5bc8d3b` (2026-09-05, after the Performance plan) with today's Xcode into a scratch derived-data folder and time it the same way; if it reads about 3.4 s, bisect the saves since; if it reads about 5 s, it is the toolchain and the Debug numbers are not comparable (measure an optimized Debug build, memory "xcode-build-and-sim-workflow", and a Release build via Instruments). Suspects on the code side: F5, the Chosen Ayah work on the lifecycle path (U19), and anything added under the launch cover since 2026-09-05. Watch for the prewarm artifact in T9. PLAUSIBLE (measured, cause unknown). DONE (step 1 and the first-frame fix): today's Xcode on the 2026-09-05 code (`5bc8d3b`, `git archive` into a scratch folder) reveals at 3.9 to 4.0 s with the cover at +1.05 s, so most of the regression is the toolchain and runtime, not the code; the code since then added about 0.3 s in Debug (4.2 to 4.35 s). A Debug build with `ENABLE_DEBUG_DYLIB=NO` reads 3.9 s, and `sample` puts about a quarter of the launch's main thread in `swift_conformsToProtocolMaybeInstantiateSuperclasses` (SwiftUI's `DynamicPropertyCache.fields` checking each new view type), which the debug dylib makes worse. A run-loop stall watch (`-launchTiming` now logs "stall a-b ms") showed the opening Adhan tab built inside the cover's first transaction (+0.58 to +1.36 s); `MainTabView.adhanTab` now waits for the cover's first frame like the warm walk does. Result: cover up at +0.47 to 0.51 s (was +1.1 s), reveal 3.8 to 4.1 s (was 4.2 to 4.35 s). Not done: a Release measurement in Instruments.
- [x] **F2. The Quran tab's grid rebuilds 114 hidden menus on every root pass.** `QuranView.swift:3642-3689` puts a LazyVGrid of 114 `GridTileMenu { SurahContextMenu }` tiles in one List row (a lazy grid inside a List row realizes every tile, as the app's own note at `PrayerTrackerView.swift:1296` says), and every bookmark is a tile carrying the full ayah menu (`:2816-2831, 2862`, `ContextMenu.swift:838-840`, about 60 items); each tile holds a hidden `Menu` plus a hold layer with three recognizers (`ViewExtensions.swift:1586-1598`). Menus build with their host's body (`ViewExtensions.swift:1501-1507`), the root body runs on every Settings publish, reading settle and player publish (`QuranView.swift:197-204`), and each `SurahContextMenu` observes the whole `QuranPlayer` (`ContextMenu.swift:169-171`): about 5 publishes per ayah advance re-run 114 menus. `gridMode` and `showBookmarks` are on by default (`Settings.swift:2759, 2176`). Fix: mount the anchor Menu only for the pressed tile (`performPrimaryAction` on the next runloop) or build a deferred UIKit menu in the hold layer; pass `canAddToQueue` in instead of observing the player. Verify: `-renderCounter` during playback with the Quran root mounted under another tab. CONFIRMED (path; cost not measured). NO CHANGE NEEDED (measured): with `-renderCounter` and a DEBUG counter in `SurahContextMenu`, the grid on screen and two Settings publishes re-running `QuranView`, the menu body ran 0 times on iOS 27 and on iOS 26.5 (both iPhone 17 Pro); holding a tile to open its menu logged 1. SwiftUI builds a Menu's content when it opens, so the 114 hidden menus cost nothing per pass. iOS 17.4 to 18 was not measured (no 17 Pro runtime for it).
- [x] **F3. `Settings.dayKey` builds a new DateFormatter on every call.** `SettingsQuran.swift:1311-1317`. `ActivityLog.makeSummary` (`ActivityLog.swift:289-306`, from `:183-197` and `:277`) calls it 91 times in `recentDayKeys` (`:258-264`) and once per day in both streak walks (`:334, 359`): 31 ms per pass with a 180-day log, measured at -O (110 µs per new formatter against 1.6 µs shared), two to three times that on older phones, on every tasbih tap (`TasbihView.swift:648, 229`), each batch of automatic khatm marks, each hadith chapter open and each surah play; the first touch comes 1.5 s after the reveal. `QuranView.swift:2594`, `HadithView.swift:269` and `HadithStore.swift:777` build one per render through `dailyDayKey()`. Fix: one static POSIX formatter or integer keys (as `date(fromKey:)` already does); walk streaks by day index; recompute only when the day or today's flag changes. CONFIRMED (measured). DONE (with A10): `Settings.dayKey` builds the key from components of one Gregorian calendar in the auto-updating zone, no formatter (the ~110 µs per call is gone for all callers, including the per-render `dailyDayKey()` sites and the activity summary's walks).
- [x] **F4. Every ayah row builds two full menus per body.** `AyahRow.swift:896-926`: a play Menu and an ellipsis Menu with about 26 top-level items (`:1673`) and nested menus (`:1711, 1524`); rows observe Settings (`:32`), which bypasses `==`, so every Settings publish rebuilds the menus of every visible row, and each row pays it again as it scrolls in. Fix: one Button that opens the actions sheet the host already has, or a deferred menu. PLAUSIBLE. NO CHANGE (by F2's measurement): the menus' item views build when a menu opens; a row body only constructs the builder's values. Not measured on the row itself.
- [x] **F5. Topics and morphology are parsed for every user under the launch cover.** `QuranView.swift:1194-1195` (added 2026-09-07) parses 574 KB of topics JSON and 835 KB of morphology JSON and builds a root and lemma index of about 77k word locations (`Morphology.swift:173-198`) at utility priority on every tier and launch, competing with the Quran decode and staying resident. Fix: load on first use, or after the reveal on the full tier only. First suspect for F1. PLAUSIBLE. DONE: `QuranLaunchWarmup.scheduleStudyPacksAfterReveal` (QuranView's task, so Al-Quran gets it too) parses both packs 5 s after the reveal on the full tier only; the Quran search field's focus warms them on the reduced tier. The log shows "PACK PARSE QuranTopics 33.5 ms bg" and "Morphology 68.2 ms bg" after the reveal instead of under the cover.
- [x] **F6. Reciter download progress publishes on every network chunk.** Each `didWriteData` writes the published `statesByReciterID` (`QuranPlayer.swift:3304-3321`, property at `:2830`) and the reciter list loops over every reciter per pass (`SettingsQuranView.swift:1614, 2938-2945`); opening the list scans every reciter folder synchronously (`:2906`, `QuranPlayer.swift:3411-3434`: a listing and 114 `fileExists` calls per reciter, one publish each). Fix: publish on a 1% change or at most 4 Hz; scan on a utility queue with one publish. CONFIRMED (path; only while the list is open). DONE: `didWriteData` publishes at most once per 1% and a quarter second (a new surah, an error cleared, a finished file or a state that was not downloading always publishes); `downloadedStats` counts from its one directory listing instead of 114 `fileExists` calls; the list's appear loads every reciter's state in one publish (`ensureStatesLoaded`). By reading (no headless download run).
- [x] **F7. `QuranFontCache` grows without bound.** `Globals.swift:1406-1420` keys on the exact CGFloat size and never evicts ("a few dozen entries" says its comment); each page fit's bisections probe about 29 sizes for 2 to 5 faces (`MushafReader.swift:3385-3394, 4760, 4896-4930`), roughly a hundred UIFonts per fitted page, and no memory-warning purge clears it (`AppLifecycle.swift:197-205`). Every build bump reruns every fit, since the salt includes `CFBundleVersion`. Fix: round the key to the 0.01 pt the fit already rounds to, or a count-limited NSCache purged in `MemoryTrim`. CONFIRMED (mechanism), PLAUSIBLE (magnitude). DONE: `QuranFontCache` is bounded (600 fonts, then it starts over) and `MemoryTrim` purges it. Exact-size keys kept on purpose: a rounded key would hand word-by-word a font a hair off the size SwiftUI draws the same word at.
- [x] **F8. Printed-mushaf page mode still runs the text fit ring.** `MushafReader.swift:1322`: when page mode resolves to the facsimile (a beta riwayah without accepted text, or anyone who picked the printed mushaf), every turn still runs 11 to 13 fits plus main-thread composes. Fix: `guard !Settings.shared.resolvedMushafPageLanguage.isPDF` at the top of `prewarm` and `renderAsync` (with A7). CONFIRMED (by reading). DONE (with A7): `MushafPageRenderCache.prewarm` and `renderAsync` return at once while the page language resolves to the printed facsimile.
- [x] **F9. The highlight memo pays a full walk on every pass.** `Highlighted.swift:99-150` builds its cache key from `"\(font)"`, `"\(accent)"`, `"\(fg)"` and `renderDigest` (`:1313-1331`), which copies the string and resolves a colour per tajweed run, so every visible ayah or search row pays it on every pass, hit or miss. Fix: key on surah, ayah, riwayah and the paint generation. PLAUSIBLE. NO CHANGE (measured): a DEBUG timer around `memoKey` in the tajweed list reader at 2:255 read 0.19 to 0.38 ms per render pass for 6 or 7 rows (about 0.05 ms a row) after a one-time 42 ms first second. Not worth the caller-provided key.
- [x] **F10. Per-pass folding and decoding.** Settings search re-folds its whole index per body pass (`SettingsSearch.swift:439-466`, called from `SettingsView.swift:625-627` and `SettingsSearch.swift:640-641`); the in-surah "Search In" filter folds two texts per ayah per pass, about 5 times per ayah advance during playback (`SurahView.swift:2250-2256`); `favoriteNameNumbers` decodes JSON per `isNameFavorite` call, per row (`Settings.swift:3038`); `QuranView.swift:2452` builds a DateFormatter per access; `QuranPlannerView.swift:228` caches `todaySpan` by count only, so it can go stale. Fix: fold once statically; memoize per surah, lane and riwayah; memoize the favorites; one static formatter; key the span by day. CONFIRMED (low). DONE: Settings search folds each entry once (`SettingsSearch.folded`); the in-surah Search In lane folds each ayah once per lane (`SurahLaneBlobs`); `favoriteNameNumbers` is memoized (Phase 1); the Ayah of the Day history has one static auto-updating formatter; the planner's Today span is keyed by `Settings.khatmRevision` (bumped on every change to the completed set) instead of the count.
- [x] **F11. Cold riwayah alignments on the main actor.** `QiraatExplorer.swift:1773` `warmNextSurah` aligns up to 19 riwayat on the main actor; the word card moved the same work off main after measuring 550 ms for al-Baqarah. Fix: run it detached, like the word card. PLAUSIBLE. DONE: `warmNextSurah` aligns the next surah in a detached utility task (the tables are behind `cacheLock` since C5; the DEBUG phase timer now takes the lock too).
- [x] **F12. Startup and idle leftovers.** `Settings.init`'s `loadKhatmProgressCacheFromStorage` decodes up to 6,236 keys into three sets on main (defer to the first read of khatm progress). In the idle run, the Quran root rendered twice while the Adhan and Settings tabs were showing, and the list and page readers had one late render burst, all between 14 and 34 s after launch: identify the late task and confirm it is expected. PLAUSIBLE. DONE: the khatm cache loads on first use (`ensureKhatmCacheLoaded` guards every reader, the persist path included, so a save can never write an unloaded empty set). The late render burst in both readers (+16 s after the reveal in a Debug run) is the ayah search index landing (`isVerseSearchReady`, one QuranData publish) plus four off-main tajweed paints: one-shot and expected. The idle run: zero publish lines on all nine screens, and the Quran root no longer renders under the other tabs.
- [x] **F13. Wallpapers still hands a full-size image to CoreVideo.** Runtime: `CVPixelBufferCreate returned err -6680` for a 1893 x 4097 RGBA buffer on opening Islamic Wallpapers, the asset size the Phase 6 thumbnail work (`ImageThumbnails`, `ViewExtensions.swift:331-345`) was meant to keep from being decoded whole. Find the path that still does it (a preview, share or save renderer, or an un-thumbnailed `.resizable()`), route it through `ImageThumbnails`, and check the footprint on open. PLAUSIBLE. NOT THE APP'S PATH (investigated): the only decode is `ImageThumbnails`, and it produces 1086x2351, not the full image. The -6680 comes from ImageIO's own JPEG path on the OC Ummah wallpaper during that downsample (RGBA is not a CVPixelBuffer format on the simulator), with a transient +19 MB: a 57% JPEG downscale cannot subsample, so the source decodes whole first. Abu's option: re-encode that asset like the other four (JFIF), or accept it. DONE 2026-09-29 (Abu asked): it was the only baseline, non-JFIF file and the only one 4097 px tall. `jpegtran -copy icc -optimize -progressive -crop 1893x4096+0+0` rewrote it losslessly as progressive JFIF at 1893 x 4096, like the others (455 KB to 389 KB; the first 4096 rows decode pixel-identical, and the dropped row was the partial last MCU row). Opening Islamic Wallpapers no longer logs the -6680.

U12 (Ask AI's main-thread decompression) and U19 (the lifecycle rebuilds) are performance items too; they sit in Phase 0 because the uncommitted diff added or worsened them.

---

## Phase 7: guardrails and tooling

- [x] **T1. Zero Swift warnings again.** Five today (zero on 2026-09-06), in both Debug and Release: `WordByWord.swift:2079, 2083, 2084` (main-actor statics called from `Task.detached`; the `nonisolated` part of C5 removes them); `SettingsAdhanView.swift:1283` "will never be executed" (the watchOS compile of a shared file, where `stacks` is the constant false at `:1269`: put the stacking modifiers under `#if os(iOS)`); `SettingsQuranView.swift:2901` (unused `withAnimation` result: `_ =`). Verify: the Release build log has no Swift `warning:` line. DONE: the final Debug builds of the iPhone and Watch schemes and the final Release build of the iPhone scheme (Widget and Complication extensions included) log no Swift `warning:` line.
- [x] **T2. Fix the quote auditor.** `Scripts/audit_islam_quotes.py:79` calls `builder.hadith_references()` but the module it loaded is `_corpus`, so it dies with a NameError halfway and its hadith half has not been running. With that one word fixed (run in memory for this audit): 924 of 924 Quran references and 635 of 635 hadith references render; flagged are 6 Musnad Ahmad numbers the partial Ahmad pack lacks and one elided quote (Ibn Majah 639), both benign. DONE: `_corpus.hadith_references()`/`hadith_quote()`. The run: 924 of 924 Quran references and 635 of 635 hadith references render; flagged are the 6 Musnad Ahmad numbers and the elided Ibn Majah 639, as predicted.
- [x] **T3. Retire `-auditPrintLines`.** `MushafComposeConfig.printLines` is nil by design (print matching now means page boundaries; `MushafReader.swift:3305, 3332`), so the audit always prints "no table" and returns. Delete it and the inert table machinery if nothing else reads it, or point it at the page-boundary check (memory "print-matched-lines" records why the line tables were withdrawn on 2026-08-31). DONE: the `-auditPrintLines` hook and `MushafPageRenderCache.auditPrintLines` are deleted. The inert table machinery stays, as its own comment and memory "print-matched-lines" decided.
- [x] **T4. Close the backup manifest gaps.** `Scripts/check_cloud_manifest.py` (read-only) reports 12 unclassified keys. Device-only: `advancedSettingsPerScreenMigrated`. Real backup gaps: `shareNameArabic`, `shareNameTransliteration`, `shareNameTranslation`, `shareNameOtherNames`, `shareNameFirstFound`, `shareNameDescription`, `shareNameFontFace`, `shareNameLastActionMode` (`ShareName.swift:56-66`; their hadith and ayah twins are backed up), `arabicShelfAxisQualities`, `arabicShelfAxisRules` (`ArabicView.swift:112-113`), `askAIEngine` (`AskAIEngine.swift:90`, safe to restore). Invisible to the script: 8 of the 10 `advancedSettings_<screen>` switches (`Settings.swift:3372`, built by interpolation) and `shouldShowRateAlert` (`AppReview.swift:36`, device-only). The in-app `-cloudKeyAudit` also lists `arabicGridMode`, a pre-4.6.0 key the per-screen `gridModeArabicRaw` replaced (classify it as legacy, or migrate it). Fix: add them to `listedPreferenceKeys` or `deviceOnlyKeys`, derive the Advanced keys from `AdvancedScreen.allCases`, and bump `CloudSnapshot.currentSchemaVersion` whenever a stored format changes. DONE: the twelve keys classified (the eight `shareName*`, both `arabicShelfAxis*` and `askAIEngine` as preferences; `advancedSettingsPerScreenMigrated` device-only), the Advanced switches derived from `AdvancedScreen.allCases` in `CloudManifest.preferenceKeys`, `shouldShowRateAlert` and `arabicGridMode` listed as retired device-only keys, and the `<key>.corrupt` rescue copies treated as device-only (`UserDataRescue.rescueSuffix`). The device-only list moved to `Settings.deviceOnlyStorageKeys` (G10); the script reads it there. `check_cloud_manifest.py`: every key classified. No schema bump: the change is additive, and a bump would make older builds refuse newer backups.
- [x] **T5. A sanitizer pass on the suspect flows.** Thread Sanitizer over seven flows reported nothing today (see the baseline). Still to run, for C5: Address Sanitizer with "Detect use of stack after return", then Thread Sanitizer, each over `-launchTabHadith`, five Hadith of the Day shuffles, background and foreground twice, an all-books search right after launch (before the Quran loads), a search inside a book, Duas; then one build with `SWIFT_STRICT_CONCURRENCY=complete` to list every main-actor read inside `Task.detached`. Record the reports here. DONE: Thread Sanitizer and then Address Sanitizer (`detect_stack_use_after_return=1`, the runtime linked) over nine flows each: launch, Hadith with background and foreground twice, all-books search, in-book search, Duas, the word card, the page reader, the Qiraat explorer (its next-surah warm is detached since F11), Ask AI: 0 reports in both; `-tsanSelfTest`'s deliberate race was reported with app frames, so the zeros count. `SWIFT_STRICT_CONCURRENCY=complete` builds with 514 unique diagnostics, mostly Swift 6 global-state and sendability notes; no main-actor read inside a `Task.detached` closure is flagged. The "Sendable closure" hits are QuranPlayer's `NotificationCenter` observers on `queue: .main` (main thread at run time); the share renderers (ShareAyah, ShareName, HadithComponents) run on a global queue by design with main-thread snapshots. Limit: types that are not `@MainActor` (Settings among them) never produce this diagnostic, so the sanitizer runs remain the real check. Hadith of the Day shuffles were not driven (no headless hook).
- [x] **T6. Keep the QA scripts.** The tools behind this audit (Appendix A) lived in a session scratchpad. Save them as `Scripts/qa/` (sweep, analyze, audits, idle, launch, tsan, tripwire, and the screen list) so any session can rerun the baseline in one command. DONE: `Scripts/qa/` holds sweep, analyze, audits, idle, launch, tsan, tripwire, the screen list, plus `device.sh` (the booted iPhone 17 Pro on the newest runtime), `build.sh`, `baseline.sh` (the whole baseline in one command) and a README. Everything writes under `QA_OUT`.
- [x] **T7. Unit tests for the pure logic (D2).** The app has no test target, and the pure functions that crashed or misparsed here are cheap to pin: `AskAIText.normalizeMarkers` (U1), `QuranDeepLink.parseAyah` and `ChosenAyahReference.parse` (U18), `HadithReferenceParser` (C3), `removingArabicDots` against `dotlessArabicScalar` (A1: equal length, lockstep maps), the al-Fatihah special case (A3), the two juz tables (A4), the notification budget planner (P2), `DailyRollover` across DST, the faraid textbook cases (A12), calculator parsing (A11). PENDING D2 (adding a test target is Abu's call). The DEBUG probes cover part of it meanwhile: `-askAITextProbe` (U1, U3, U8 to U11, A11, C3) and `-auditJuzTables` (A4). DONE 2026-09-29: two targets in the iPhone scheme's Test action, both Xcode 16 synchronized folders (a file dropped in the folder is in the target). `UnitTests/` (hosted by the app, `@testable import iPhone`): 81 tests in ten files, one per item above, all passing on the iPhone 17 Pro (iOS 27). They found one real bug, fixed: a paternal half-sister beside a half-brother, a daughter and a full sister was told "the fixed shares use up the whole estate" instead of "blocked by the full sister" (InheritanceView.swift, the A12 twin). P2 is pinned only at its constants and inputs: the planner is inline in `schedulePrayerTimeNotifications`, not a pure function. `UnitTests/HostSmokeTests` (skipped unless `TEST_RUNNER_QA_SMOKE_SECONDS` is set) is the Mac crash sweep's probe, see `Scripts/qa/mac-sweep.sh`. `UITests/`: `ScreenSweepTests` (the screens.txt list via `TEST_RUNNER_QA_SCREENS`, optional `QA_ORIENTATION=landscape`) and `MonkeyTests` (seeded random walk, off-limits list for anything that leaves the app, spends data or deletes). Run: `xcodebuild test -scheme iPhone -destination <sim> -only-testing:UnitTests`.
- [x] **T8. A Release build before every push.** Standing rule since 2026-09-06; today it passes with the five warnings of T1. DONE for this session: the final Release build is green with no Swift warnings. The rule stands for every push.
- [x] **T9. The launch stopwatch can start early.** `LaunchClock.start` is set at the App struct's init, which iOS prewarming can run long before the launch: one of five Quran list runs today read "stores ready +67,517 ms". Measure from `didFinishLaunching` or the process start, or drop runs whose first mark is late. DONE: `LaunchClock.rebaseIfPrewarmed()` in `didFinishLaunching` (never prewarmed) restarts the clock when the app struct was initialized more than a second earlier, and logs that it did. A normal launch reaches it at about +190 ms and keeps its start.
- [x] **T10. Record the simulator defaults trap.** On the iOS 27 runtime, `xcrun simctl spawn <udid> defaults write <bundle id> …` wrote a simulator-global domain the app never reads (a reset between sweep screens silently did nothing). The app's real domain is its container path: `defaults read|write "$(xcrun simctl get_app_container <udid> <bid> data)/Library/Preferences/<bid>" <key> …`, which goes through cfprefsd (the plist file on disk can lag). Launch arguments (`-seedBool`, `-seedString`, `-displayQiraah ""`) remain the dependable way to set state. (Recorded in memory "xcode-build-and-sim-workflow" on 2026-09-28.) DONE (already in memory "xcode-build-and-sim-workflow", 2026-09-28 correction); `Scripts/qa/README.md` repeats it.

---

## Phase 8: accuracy and correctness (2026-10-04)

Abu asked for a maximal pass on accuracy and correctness ("no errors no bugs no problems no glitches"). Fourteen
audits read the app area by area (each with a harness against the shipped data where one could be built),
then the findings were fixed and pinned by unit tests. Ids are the audits' own; the files are named once.

**Prayer times** (vendored adhan-swift, `PrayerCalculationMethods.swift`, `SettingsAdhan.swift`; `PrayerTimesTests`)
- [x] T1. The catalog built every method from `.other.params` and lost each body's minute adjustments and rounding (since 4.6.0): Dhuhr +1 for MWL, ISNA, Egypt, Karachi, MUIS; Diyanet -7/+5/+4/+7; UAE -3/+3; MUIS rounds up. Carried in the rows; a test compares each row with the engine's own table over a year.
- [x] T3. Jordan: Isha 18 degrees, Maghrib +5 min.
- [x] T4. Beside polar night the engine returns days out of order (Tromso: Asr two days early, 34 days): `isChronological`, and those days take the nearest-latitude stand-in.
- [x] T5 (part). `HighLatitudeRule.recommended` reads `abs(latitude)`, so the far south gets the high-latitude rule. The clamp itself: round 2.
- [x] T6. "Last 10 Nights" and "27th Night" reminded a night late: a night event fires on the civil day whose Maghrib begins it, in the Gregorian calendar, worded "Tonight at Maghrib".
- [x] T7 and T9. Asr took the noon shadow from the 0h UT declination and corrected the crossing once: interpolated at transit and iterated (up to 3 passes). Against an independent solver over 1,968 city-days: mean error 24.9 s to 0.71 s, worst 307 s to 2.6 s.

**Notifications and tracker** (`SettingsAdhan.swift`, `PrayerTrackerView.swift`, `PrayerList.swift`, `ActivityLog.swift`)
- [x] N1. Yesterday's still-future entries (after midnight) were never scheduled nor offered to the foreground adhan.
- [x] N2. Day walks lost a day in zones whose DST gap is at midnight (three walks).
- [x] N3. A nag sharing its minute with the pre-notification survived marking the prayer; marking reschedules.
- [x] N4. Event triggers carry the Gregorian calendar.
- [x] N5. The Isha midnight deadline scheduled an Islamic Midnight alert nobody asked for.
- [x] N8. A mark was filed under the civil date of the prayer's time, not the list's day (Isha after midnight).
- [x] N9. Period totals counted days before tracking began.
- [x] N10. Fajr's "ends at sunrise" read the stored day's sunrise.
- [x] N11. "Mark Only After the Time Begins" was bypassed in the week grid for Jumuah and combined prayers.
- [x] D1 (N7). The canonical-marks memo survived Erase and restore: `bumpTrackerGeneration()` on content replacement.

**Widgets** (`PrayersProvider.swift`, `SettingsQuran.swift`, `DailyWidgets.swift`, `ChosenAyahWidget.swift`, `FastingActivityController.swift`)
- [x] W1. The empty Adhan entry used Hijri offset 0 and no midnight entry. W2. A cleared Last Listened stayed on the widget. W3. Sky gradients reloaded no widget. W4. A fasting Live Activity could start past its deadline. W5. The first backgrounding after a cold launch dropped the chosen cards. W6. The rollover-at-Fajr switches refreshed only one screen's widgets. W7. A raw font name. W8. The Chosen Ayah accent cached per process.

**Backup and data** (`CloudMergeRules.swift`, `CloudBackupManager.swift`, `CloudManifest.swift`, `Settings.swift`, `AskAIConversation.swift`)
- [x] S1. Reading-history rows got new ids and dates on every load. S2. Erase Everything left the Ask AI transcript (now in `deviceOnlyDocumentFiles`, and the chat resets). S3. A merge dropped incoming data when the local value was empty Data. S4. The unchanged-digest shortcut ran before the account check. S5. Three keys unclassified. S7 (part). The surah open and play counts decode through `UserDataRescue`.
- [x] S6. Tasbih day keys used `Calendar.current`: round 2.

**Hadith and calculators** (`HadithModels.swift`, `HadithView.swift`, `HadithBookView.swift`, `DailyReminders.swift`, `InheritanceView.swift`, `ZakahView.swift`, `ZakatAlFitrView.swift`; `FaraidTests`)
- [x] H1. 'Umariyyatan was skipped with exactly one sibling. H2. A citation miss fell back to an unrelated row with the same number (`hadith(uncitedRow:)`). H3. Read the Hadith reopened by citation, which is not unique (120 of 12,043 rows): rows now travel by position. H5. The all-books number sweep matched chapter ids, not positions. H6. The Mushtarakah note fired without a full brother. H8. A rollover with the app open showed yesterday's hadith. H9. One stored metal price served gold and silver (two keys, migrated, backed up). H10. A debt that takes wealth under the nisab now explains why. H11. Em dashes in two calculators.

**Navigation and search** (`OpenScreens.swift`, `IslamSearch.swift`, `QuranRankedSearch.swift`, `QuranData.swift`, `VerseSearchPack.swift`, `SurahRows.swift`, `QuranView.swift`, `Highlighted.swift`; `SearchFixTests`)
- [x] G1. Article doors had no open-screen guard (18 two-way pairs, hub loops). G4. A spaced hyphen in copied word text.
- [x] F1. A Caches search pack built from a locked beta riwayah's Hafs fallback was served after unlocking: the file name carries a fingerprint of the indexed text. F2. The clean lane followed Hide Dots. F3. Ayah of the Day admitted riwayah-only ayahs. F4. The ayah-count cache was purged before the reload published. F5. An unchecked capacity read from the lexicon file.
- [x] Q1. Seated hamzas: شيئا, إسرائيل, يسألونك found nothing (the mushaf seats that hamza on a tatweel or on nothing). Q5. Final ya and alef maqsura: موسي found nothing. Both by `SearchFoldTables.arabicQuerySpellings`, a fallback in both lanes, only when the typed spelling occurs nowhere.
- [x] Q2. الصلاة showed two hellfire ayahs (a stem inside يصلاها) and no prayer ayah. Q3. Under another riwayah the index paired its ayah N with Hafs ayah N's translation and listed ayahs the riwayah lacks. Q4. ماء ranked the particle ما first (the hamza filter now applies per row). Q6. Ranked rows' translations went unpainted. Q7. "baqarah 255", "2 255", "2: 255". Q8. An em dash glued two words ("sabr" matched inside "forefathers" and "Abraham" joined by one, 2:133). Q9. Load More cancelled the ranked results. Q10. Bookmark edits did not re-run a scoped search.
- `VerseSearchPack.format` is 2 and the shipped `quran-search.qsp` was re-exported; the lexicon did not change.

**Tajweed** (`QuranData.swift` painter; `TajweedPaintTests`; whole-Quran diffs per fix)
- [x] J1 and J3. Madd badal (277 sites) and 20:92 painted Madd Lazim; hiding Munfasil or Muttasil repainted those Lazim. Lazim sites 426 to 148.
- [x] J2. 62 alefs under U+06E0 greyed. J4. Saakin raa after hamzatul-wasl is heavy (12 sites). J5. After a kasra it is heavy before an open isti'la letter in its word (5 sites; 26:63 stays light). J6. The plural waw before hamzatul-wasl is dropped (495). J7. A dagger alif before an ayah's last letter is Ending Madd (55 ayahs). J11. 44:33's idgham; 7:176's merged ث and 334 tanween alifs at pause marks; 26 ayah-final silah marks unpainted.

**Word study and qiraat** (`WordByWord.swift`, `QiraatVariants.swift`, `QiraatExplorer.swift`, `ComparisonSheets.swift`, `QiraatTextAnalysis.swift`, `RiwayatDifferencesView.swift`; `WordStudyTests`)
- [x] K1. The Other Qiraat block looked up a Hafs-keyed pack with the riwayah's own number. K2. Variant audio played the origin riwayah's number. K3. The word card's tap index followed the global Hide Tashkeel, not the ayah's own. K4. Spellings compared byte for byte, and only Hafs keeps the silent-letter ring: `QiraahSpelling.key`, used by the card, the explorer and the sheet. K5. The Qiraat tab kept the previous word's readings. K7. Under Hide Tashkeel the card's own riwayah always "differed". K8. The comparison resolver followed Hide Dots. K9. Roots and Words rows opened a Hafs number under another riwayah. K10. Tokens and ranges disagreed on ad-Duri's and as-Susi's 4:44. K11. A split ayah's note under the sheet's Hide toggles. K12. Four figures in the riwayat statistics.

**Recitation** (`QuranPlayer.swift`, `CarPlayScene.swift`, `QuranHistoryRows.swift`, `QuranShortcuts.swift`)
- [x] P1. A surah or ayah started over a running range kept the range's state (Next restarted the old range). P2. The playback cache downloaded without the islamweb Referer and stored the landing page; a failed copy is now deleted. P3. The adhan's hand-back resumed a stopped recitation and left the session on `.ambient`. P4. A header's Bismillah overwrote Last Listened Ayah with 1:1. P5. A fetch-first start left the old audio playing. P6. A finished surah was saved at full length, so every resume ended at once. P7. Resuming a history entry lost the displaced surah. P8. CarPlay read the failure flag a turn too early (`playSurah`/`playAyah` now return whether they started). P9. Random Surah in CarPlay and Siri ignored the reciter's coverage. P10. A QDC timing table outlived a fallback to the mp3quran encode. P11. A stale queue callback could stop or advance a new recitation. D2. The cache trim deleted from a stale date snapshot.

**Readers** (`MushafReader.swift`, `SurahView.swift`, `AyahRow.swift`, `Settings.swift`)
- [x] M1. A second settings change during an in-flight fit was never rendered (spinner or stale page). M2. A riwayah switch re-seeded by ayah number and moved a page (92 of 604 pages Hafs to Warsh). M3. A page's juz came from the Hafs juz of a riwayah row (Go to Juz landed a page late). M4. A swipe forward and back recorded the page left. M5. The list caches mixed a beta riwayah's locked and unlocked texts. M6. Hide Dots put the basmala header above al-Fatihah. M7. The page find flag outlived page mode (a dead Search button). M8. The arrival highlight returned on every appear. M9. The top search hit was saved as the last-read ayah.
- [ ] M10, M11. PLAUSIBLE only (a programmatic turn under a finger; the pager probe shared by two windows): not changed without proof.

- [x] G2. At the largest accessibility size the resource hero's eyebrow truncated ("THE FOUNDATI...": one word wider than the card cannot wrap); it shrinks first now (`ResourceHero`, ArticleDesign.swift). Checked on the simulator before and after.

**Round 2 (2026-10-05): the D10 calls, decided by Abu, and S6** (`PrayerTimesTests`, `ArabicDotsTests`, `TajweedPaintTests`, the new `HadithNumberingTests`)
- [x] T2. Malaysia's row is 18 degrees; Brunei (`BN`) has its own row at 20.
- [x] T5. `Settings.highLatitudeRuleUnderAutomatic`: Seventh of the Night past 66 minus the method's deeper angle (an Isha set in minutes has no angle), Middle of the Night short of it. Paris under Musulmans de France keeps its 12 degree dawn in June (04:03:30 against the clamp's 04:40). The settings caption names the rule for the current method.
- [x] T8. The catalog hands the engine `.none` unless the body rounds (MUIS); `PrayerMinute.rounded` takes each time to its safe side in `_computeRawPrayers` and the other-madhab Asr; Islamic Midnight rounds down after taking off a minute (its ends are rounded up), Last Third up, Duha counts from the end of sunrise's minute. `PrayerMinute.suhoorEnd(forFajr:)`: the Live Activity counts to a minute before Fajr and still names Fajr at its own minute (`ContentState.prayerTime`); the widget's countdown holds at 0:00 for that minute instead of counting back up.
- [x] H4. In a book that cites its other rows, an uncited row is named by its place, "C:N" (217 rows: Bulugh al-Maram 197, Ahmad 14, an-Nasa'i, ash-Shama'il and Mishkat 2 each), so it can never read as another row's citation, and the search resolves it back. The chapter ranges count cited rows only, and the row's pill shows the "C:N" alone (it already says the position). The saved-reference refresh runs again (`hadithCitationRefresh2`) for bookmarks, last read and the Hadith of the Day history. Muwatta Malik, which cites nothing, keeps its row numbers.
- [x] H7. The introduction (chapter id 0) that Sahih Muslim, Ibn Majah, ad-Darimi, Riyad as-Salihin and Mishkat store last leads its book at position 0 (`HadithPack.introductionChapterIndex`, `HadithBookData.position(of:)`); every numbered chapter keeps its number, so "C:N" references do not move. The forty-hadith books, whose one chapter is id 0, keep it at 1.
- [x] J8. Hide Arabic Dots keeps the seat of a seated hamza: ؤ to و, ئ to ى (it wrote a detached ء, 1,613 times). Still one scalar for one scalar; `audit_quran_font_coverage.py`'s copy of the table follows.
- [x] J10. `TajweedRuleAlias`: the noon or tanween merged with ghunnah into م ي و keeps its grey and is named Merge with Ghunnah (3,664 sites); the meem hidden before ب keeps iqlab's color and is named Hidden Meem, Ikhfaa Shafawi (496). The word card lists `TajweedStore.wordRules`; the legend explains both shared colors.
- [x] K6. `build_qul_packs.py` moves 158 lemmas QUL filed under a neighbouring word back onto their own word (a lemma whose dominant root is not its carrier's, with exactly one lemma-less word of that root within three tokens), plus three hand errata (59:9, 64:16, 4:129) that stop the build if they no longer find their words. 4:106 غَفُورٗا no longer reads "Dictionary form كَانَ". Foreign-root lemmas 192 to 32 (16 real homographs, 7 particles, 9 left with reasons in the builder). `verify_qul_packs.py` checks the pattern and the four ayahs; the other packs rebuild byte for byte.
- [x] S6. Tasbih day keys are Gregorian in the device's time zone; keys a non-Gregorian device calendar wrote ("1448-04-23") are rewritten once, so the streak survives a calendar change or a restore on another phone.
- J2 remainder kept, as decided.

Not done: D3 (the altitude row prints feet and metres from one stored reading; not a defect), M10, M11, and G3 (the help door's sheet sits on a list row whose identity a banner inserted above does not change, by reading; the trigger, traveling mode switching on while the sheet is open, could not be driven headlessly).

---

## Already fine (do not spend time here)

Checked by the audits and clean on 2026-09-28:

- No crash-level force unwrap, `try!` on non-literal input, reachable `precondition` or unguarded closed range beyond the items above; every stored raw value has a default; no launch-argument read outside `#if DEBUG`.
- Pack readers: version gates match the shipped files (QRPK v1, HDPK v4 for all 17 books, TFPK v1, SEM4, the JSON packs); every reader bounds-checks and returns nil on bad data; resident pack memory is bounded and trimmed on memory warnings.
- The Chosen Ayah widget's memory (6 to 7 MB ceiling), its `containingAppBundle` walk, its 114-surah catalog (6,236 ayahs), the deep-link parser's rejects, `refreshChosenAyahWidgets` (no reload loop), `ModalPresence` (main thread; it also counts popovers and dialogs, which only stops the mushaf re-open), the Need a Hand? parsing, the pinned-switcher bands (no layout loop), and the iOS 17 `#available` in the widget bundle at the iOS 15 target.
- The faraid shares (four textbook cases by hand), the prophecies and miracles references (`verify_prophecies.py`: 222 hadith, 87 Quran), the sajdah list (15), the tajweed lesson ids, the 17 hadith packs (no duplicate ids, no empty chapters).
- Notification sound cuts are at most 29.47 s (IMA4); triggers carry a time zone; widget and complication timer ranges are guarded; the sky card ticks once a minute and its stars pause off screen.
- The Watch compiles no iOS-only symbol in a live branch; WatchConnectivity payloads are property-list types and its callbacks hop to main; `sendMessage` is gated on reachability; the widgets clamp tajweed colour runs.
- The idle counters (zero publishes), the riwayah alignment (0 pairs below 0.75), the daily rollover (the app and the widget agree), the semantic packs (valid), the article corpus (121 articles), QUL, themes, similar ayahs, tajweed lessons and word by word verifiers.
- Of the 17 SwiftUI glitch rules, zero violations of: Toggle-in-Menu style, one-sided transitions, onChange loops, stale init-seeded state, per-render ids, alerts where a dialog belongs, missing sheet toolbars, nested lists, double pushes, keyboard toolbars, modifier order. The 26 Equatable views fold what they read (the only gap is G9).

---

## Appendix A: the tools

Everything below ran on 2026-09-28 from a session scratchpad; T6 saves them as `Scripts/qa/`. Set `QA_OUT` to a scratch folder first. Use the iPhone 17 Pro simulator (`xcrun simctl list devices available | grep "iPhone 17 Pro"`); every `xcrun` call needs `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, because `xcode-select` points at the Command Line Tools on this Mac.

**Builds** (into scratch derived-data folders, so the normal DerivedData stays untouched):

```
xcodebuild -project <abs>/Al-Islam.xcodeproj -scheme iPhone -configuration Debug \
  -destination 'platform=iOS Simulator,id=<udid>' -derivedDataPath "$QA_OUT/dd" build
xcodebuild ... -configuration Release -derivedDataPath "$QA_OUT/dd-release" build      # about 8 min
xcodebuild ... -configuration Debug -derivedDataPath "$QA_OUT/dd-tsan" -enableThreadSanitizer YES build
xcrun simctl install <udid> "$QA_OUT/dd/Build/Products/Debug-iphonesimulator/iPhone.app"
```

Pipe build logs to a file and read the exit code; `| tail` swallows it. Before trusting a run, prove the installed binary is the new one (memory "xcode-build-and-sim-workflow": the Debug code lives in `iPhone.debug.dylib`).

**Order of a full baseline:** sweep (about 20 minutes), `analyze.py`, `audits.sh`, `idle.sh`, `launch.sh`, `tripwire.sh`, then `tsan.sh` last (it swaps the installed build and puts the Debug build back). Run `-tsanSelfTest` once on the sanitized build: a zero only counts if the self-test race is reported.

**Noise to ignore** (seen on most screens, not the app's): CoreAnimation "cannot add handler to 0 from 0", AVSystemController "Failed to allocate", GeoServices "default.csv", app-launch-measurement CA events, keyboard rendering and haptic pattern library errors on the simulator, the seven UIKit "Invalid UIScreen coordinate space conversion" faults whenever a keyboard comes up (rects {0,0,402,62}, {0,62,402,54}, {0,781,402,93} on the 17 Pro; the Zakah calculator's `-focusAmount` logs the same seven as the mushaf find bar, 2026-09-28), the BGTaskScheduler, WCSession and FigFilePlayer lines listed in memory "bug-sweep-runtime-issues". `analyze.py` filters them.

<details><summary>screens.txt: the 94 screens of the sweep</summary>

```text
# name|seconds|args   (a line starting with ! runs a shell command with the app terminated)
# Resets use launch arguments: simctl spawn defaults <bundle id> does not reach the app's domain on iOS 27.
adhan|9|
adhan-tracker|8|-openPrayerTracker
adhan-city|8|-openCityPrayerTimes
adhan-qibla|8|-showBigQibla
adhan-glance-calc|7|-glanceAction calculation
adhan-glance-prayercal|7|-glanceAction prayerCalendar
adhan-glance-hijri|7|-glanceAction hijriCalendar
adhan-glance-home|7|-glanceAction home
adhan-travel|8|-travelingMode 1
adhan-travel-off|6|-travelingMode 0
adhan-catchup|8|-adhanCatchUpProbe
adhan-daily-rollover|8|-dailyRolloverProbe
quran-list|8|-launchTabQuran -quranListMode -noAutoOpenMushaf
quran-list-surah|9|-launchTabQuran -quranListMode -lastRead 2:255
quran-page|10|-launchTabQuran -quranPageMode -lastRead 2:255
quran-page-arabic|10|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 18:1
quran-page-pdf|10|-launchTabQuran -quranPageMode -mushafPageLanguage pdf -lastRead 36:1
quran-page-warsh|10|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -displayQiraah "Warsh an Nafi" -lastRead 2:1
reset-hafs|8|-launchTabQuran -quranListMode -lastRead 1:1 -displayQiraah "" -seedBool removeArabicDots=0,cleanArabicText=0
# EXPECTED to crash until C1 is fixed:
quran-page-dotless|15|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -displayQiraah "" -lastRead 2:11 -seedBool removeArabicDots=1,cleanArabicText=0
reset-dots|8|-launchTabQuran -quranListMode -lastRead 1:1 -displayQiraah "" -seedBool removeArabicDots=0,cleanArabicText=0
quran-page-findjump|10|-launchTabQuran -quranPageMode -lastRead 2:1 -mushafFindBar "20:6" -mushafFindJump
quran-page-collapsed|8|-launchTabQuran -quranPageMode -lastRead 55:1 -mushafCollapseBars
quran-page-picker|8|-launchTabQuran -quranPageMode -lastRead 1:1 -openSurahPicker
quran-page-sheet-range|9|-launchTabQuran -quranPageMode -lastRead 2:1 -openPageSheet customRange
quran-row-sheet-range|9|-launchTabQuran -quranListMode -lastRead 2:1 -openRowSheet customRange
quran-row-sheet-word|9|-launchTabQuran -quranListMode -lastRead 2:1 -openRowSheet word -wordIndex 1
quran-search|9|-launchTabQuran -quranListMode -noAutoOpenMushaf -quranSearch "mercy"
quran-search-arabic|9|-launchTabQuran -quranListMode -noAutoOpenMushaf -quranSearch "الرحمن"
quran-search-ref|9|-launchTabQuran -quranListMode -noAutoOpenMushaf -quranSearch "2:255"
quran-surah-search|8|-launchTabQuran -quranListMode -noAutoOpenMushaf -surahSearch "yaseen"
quran-settings|8|-launchQuranSettings
quran-reader-settings|9|-launchTabQuran -quranListMode -lastRead 2:1 -launchReaderSettings
quran-history|8|-openQuranHistory
quran-themes|8|-openThemes
quran-surah-info|9|-launchTabQuran -quranListMode -lastRead 2:1 -openSurahInfo
quran-word-of-day|8|-openWordOfDay
quran-play|12|-launchTabQuran -quranListMode -lastRead 1:1 -playSurah 1:1
quran-qiraat-analysis|9|-launchTabQuran -quranListMode -lastRead 2:1 -showQiraatAnalysis
quran-comparison|9|-launchTabQuran -quranListMode -lastRead 2:1 -qiraatComparisonMode
quran-custom-range|8|-showCustomRangeSheet
hadith|8|-launchTabHadith
hadith-book|9|-launchTabHadith -launchHadithBook bukhari
hadith-open|9|-launchTabHadith -launchHadithOpen bukhari:1
hadith-search|9|-launchTabHadith -hadithSearch "patience"
hadith-search-ref|9|-launchTabHadith -hadithSearch "1:4"
hadith-search-arabic|9|-launchTabHadith -hadithSearch "الصبر"
hadith-topics|8|-launchHadithTopics
hadith-enc|8|-launchHadithEncyclopedia
hadith-history|8|-launchHadithHistory
hadith-settings|8|-launchHadithSettings
islam|8|-launchTabIslam
islam-arabicAlphabet|8|-launchTabIslam -islamDestination arabicAlphabet
islam-tajweedFoundations|8|-launchTabIslam -islamDestination tajweedFoundations
islam-tajweedCourse|8|-launchTabIslam -islamDestination tajweedCourse
islam-namesOfAllah|8|-launchTabIslam -islamDestination namesOfAllah
islam-commonAdhkar|8|-launchTabIslam -islamDestination commonAdhkar
islam-commonDuas|8|-launchTabIslam -islamDestination commonDuas
islam-tasbihCounter|8|-launchTabIslam -islamDestination tasbihCounter
islam-zakahCalculator|8|-launchTabIslam -islamDestination zakahCalculator
islam-inheritanceCalculator|8|-launchTabIslam -islamDestination inheritanceCalculator
islam-hijriCalendarConverter|8|-launchTabIslam -islamDestination hijriCalendarConverter
islam-masjidLocator|8|-launchTabIslam -islamDestination masjidLocator
islam-halalFoodLocator|8|-launchTabIslam -islamDestination halalFoodLocator
islam-journal|8|-launchTabIslam -islamDestination journal
islam-pillarsAndBasics|8|-launchTabIslam -islamDestination pillarsAndBasics
islam-howToGuides|8|-launchTabIslam -islamDestination howToGuides
islam-islamicWallpapers|8|-launchTabIslam -islamDestination islamicWallpapers
islam-miraclesOfQuran|8|-launchTabIslam -islamDestination miraclesOfQuran
islam-propheciesOfProphet|8|-launchTabIslam -islamDestination propheciesOfProphet
islam-miraclesOfProphets|8|-launchTabIslam -islamDestination miraclesOfProphets
islam-search|9|-launchTabIslam -islamSearch "wudu"
islam-reminder|8|-launchTabIslam -islamScrollToReminder
islam-askai|90|-launchTabIslam -islamDestination askAI -askAIReset -askAILog -askAI "hello||What does the Quran say about patience?||who narrated that hadith?||how do I change the reciter"
settings|8|-launchTabSettings
settings-search|8|-launchTabSettings -settingsSearch "font"
settings-prayer|8|-launchTabSettings -settingsOpen prayer
settings-prayerSky|8|-launchTabSettings -settingsOpen prayerSky
settings-notifications|8|-launchTabSettings -settingsOpen notifications
settings-nagging|8|-launchTabSettings -settingsOpen nagging
settings-quran|8|-launchTabSettings -settingsOpen quran
settings-hadith|8|-launchTabSettings -settingsOpen hadith
settings-islam|8|-launchTabSettings -settingsOpen islam
settings-islamArabic|8|-launchTabSettings -settingsOpen islamArabic
settings-appearance|8|-launchTabSettings -settingsOpen appearance
settings-appearanceLook|8|-launchTabSettings -settingsOpen appearanceLook
settings-tips|8|-launchTabSettings -settingsOpen tips
settings-cloudBackup|8|-launchTabSettings -settingsOpen cloudBackup
settings-aboutYou|8|-showAboutYou
settings-credits|8|-showCredits
settings-widget-gallery|8|-widgetGallery
settings-profile|8|-openProfile
settings-daily-hub|8|-openDailyHub
settings-learn-more|8|-openLearnMore
settings-cloud-offer|8|-showCloudOffer
```

</details>
<details><summary>sweep.sh</summary>

```zsh
#!/bin/zsh
# sweep.sh <udid> <screens.txt> <tag>: one cold launch per line "name|seconds|args" ("!cmd" lines run a shell
# command with the app terminated). Per screen: the full app log, a screenshot, alive and crash-report status.
# Needs QA_OUT (a scratch folder). zsh: never name a variable `status` (read-only).
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; LIST="$2"; TAG="$3"; BID=com.Quran.Elmallah.Islamic-Pillars
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"; mkdir -p "$OUT/logs/sweep" "$OUT/shots"
SUMMARY="$OUT/logs/sweep/$TAG-summary.txt"; : > "$SUMMARY"
CRASHDIR="$HOME/Library/Logs/DiagnosticReports"
while IFS='|' read -r name secs args; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  if [[ "$name" == \!* ]]; then
    xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1; sleep 1; eval "${name#!}"; continue
  fi
  before=$(ls "$CRASHDIR" | grep -c '^iPhone-')
  xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1; sleep 1
  LOG="$OUT/logs/sweep/$TAG-$name.log"
  xcrun simctl spawn "$UDID" log stream --style compact --predicate 'process == "iPhone"' > "$LOG" 2>&1 &
  LP=$!; sleep 1.5
  eval xcrun simctl launch "$UDID" "$BID" -skipNotificationPrompt $args >/dev/null 2>&1
  sleep "$secs"
  xcrun simctl io "$UDID" screenshot "$OUT/shots/$TAG-$name.png" >/dev/null 2>&1
  kill "$LP" 2>/dev/null; wait "$LP" 2>/dev/null
  after=$(ls "$CRASHDIR" | grep -c '^iPhone-')
  alive=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BID")
  st="ok"; (( after > before )) && st="CRASH(+$((after - before)))"; [[ "$alive" == 0 ]] && st="$st DEAD"
  echo "$name: $st" | tee -a "$SUMMARY"
done < "$LIST"
xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1
```

</details>
<details><summary>analyze.py</summary>

```python
#!/usr/bin/env python3
"""analyze.py <tag>: error and fault lines per screen from $QA_OUT/logs/sweep/<tag>-*.log, noise filtered.
Lines seen on 3+ screens are ambient; app NSLog warnings are listed separately; the rest is per screen."""
import sys, re, glob, os, collections
tag = sys.argv[1]
SCR = os.environ["QA_OUT"]
files = sorted(glob.glob(f"{SCR}/logs/sweep/{tag}-*.log"))
# compact style: "2026-09-28 16:27:03.146 E  iPhone[pid:tid] [subsystem:category] message"
line_re = re.compile(r'^\S+ \S+ (\w+)\s+iPhone\[\d+:\w+\] (?:\[([^\]]*)\] )?(.*)$')
SIGNAL = re.compile(r'runtime issue|Modifying state during view update|tried to update multiple times per frame|'
                    r'Publishing changes from (background|within view updates)|NSRangeException|NSInternalInconsistency|'
                    r'Fatal error|Unexpectedly found nil|precondition|AttributeGraph: cycle|Bound preference|'
                    r'onChange\(of: .*\) action tried to update|invalid (frame|sample|value)|NaN|'
                    r'Unable to simultaneously satisfy|Invalid .* dimension|UICollectionView.*(invalid|inconsistent)|'
                    r'Accessing StateObject|Accessing State\'s value outside|FAILED|failed|error', re.I)
NOISE = re.compile(r'BackgroundTask|BGTaskScheduler|wcd|WCSession|coreaudio|CFBundle|TextKit 1|FigFilePlayer|'
                   r'NavigationRequestObserver|OnScrollGeometryChange|kCLErrorDomain|modelmanager|ModelManager|'
                   r'SensitiveContent|RTIInputSystemClient|UIKeyboard|LoadedFontManager|sandbox|nw_|tcp_|'
                   r'SensorKit|BackBoardServices|BoardServices|PointerUI|[Ss]iri|assistant|AudioSession|HALC|'
                   r'com\.apple\.Metal|ViewServiceBridge|LaunchServices|RBSAssert|dyld|MPRemoteCommand|SecTask|'
                   r'CTTelephony|carrier|xctest|DataDeliveryServices|MobileAsset|CoreAnalytics|AppleTypeCString|'
                   r'Received port for identifier|mediaremote|RemoteControl|CFNetwork|BackgroundSession|'
                   r'LinguisticData|com\.apple\.runningboard|TCC|AXRuntime|accessibility|com\.apple\.xpc|'
                   r'CoreData|cloudkit|CloudKit|ubiquity|FrontBoard|UIScene|SpringBoard|BiomeLibrary|'
                   r'com\.apple\.defaults|cfprefsd|IOSurface|CAMetalLayer|PlugInKit|pkd|chronod|WidgetKit|'
                   r'SwiftUI.*Toolbar|IconServices|NLEmbedding|GenerativeModels|FoundationModels|TextComposer|'
                   r'com\.apple\.photos|Photos|Location|locationd|CoreLocation|geocod', re.I)
per_screen = {}
global_counts = collections.Counter()
app_logs = collections.defaultdict(collections.Counter)   # app NSLog lines, "(Foundation) ..."
APP_WARN = re.compile(r'APPEARANCE ENV|WARN|ERROR|FAIL|MISSING|STALE|LOOP|INVALID|UNEXPECTED|mismatch|not found|could not|couldn\'t|refused|dropped', re.I)
for f in files:
    name = os.path.basename(f)[len(tag)+1:-4]
    hits = collections.Counter()
    for raw in open(f, errors='replace'):
        m = line_re.match(raw.rstrip('\n'))
        if not m: continue
        level, subsys, msg = m.group(1), m.group(2) or '', m.group(3)
        text = f"[{subsys}] {msg}"
        if msg.startswith('(Foundation)'):
            if APP_WARN.search(msg):
                k = re.sub(r'0x[0-9a-f]+', '0x…', msg[13:]); k = re.sub(r'\d{3,}', '#', k)[:200]
                app_logs[k][name] += 1
            continue
        if NOISE.search(text): continue
        if level in ('E', 'F') or SIGNAL.search(msg):
            key = re.sub(r'0x[0-9a-f]+', '0x…', text)
            key = re.sub(r'\d{3,}', '#', key)[:260]
            hits[(level, key)] += 1
    per_screen[name] = hits
    for k in hits: global_counts[k] += 1
print(f"{len(files)} screen logs")
print("\n=== lines seen on 3+ screens (likely ambient)")
for (lvl, k), n in global_counts.most_common():
    if n >= 3: print(f"  {n:3d} screens  {lvl}  {k}")
print("\n=== app NSLog warnings (message -> screens)")
for k, scr in sorted(app_logs.items(), key=lambda kv: -len(kv[1])):
    print(f"  {len(scr):3d} screens  {k}")
    print(f"             e.g. {', '.join(list(scr)[:6])}")
print("\n=== per-screen lines seen on fewer than 3 screens")
for name, hits in per_screen.items():
    rare = [(lvl, k, c) for (lvl, k), c in hits.items() if global_counts[(lvl, k)] < 3]
    if rare:
        print(f"-- {name}")
        for lvl, k, c in sorted(rare, key=lambda x: -x[2])[:12]:
            print(f"    {c:3d}x {lvl}  {k}")
```

</details>
<details><summary>audits.sh: the in-app DEBUG audits</summary>

```zsh
#!/bin/zsh
# audits.sh <udid>: run each in-app DEBUG audit with a console pty capture, wait for its "done" marker or a time cap.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/audits
run() {  # name cap marker args...
  local name=$1 cap=$2 marker=$3; shift 3
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  local out=$SCR/logs/audits/$name.log
  xcrun simctl launch --console-pty $UDID $BID -skipNotificationPrompt "$@" > $out 2>&1 &
  local lp=$!
  local t=0
  while (( t < cap )); do
    sleep 2; t=$((t+2))
    [[ -n "$marker" ]] && grep -q "$marker" $out && break
  done
  sleep 1
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1
  kill $lp 2>/dev/null; wait $lp 2>/dev/null
  echo "$name: ${t}s, $(wc -l < $out | tr -d ' ') lines, marker $( [[ -n "$marker" ]] && (grep -q "$marker" $out && echo seen || echo MISSING) || echo n/a)"
}
run alignment         300 "ALIGNMENT AUDIT: done"    -launchTabQuran -quranListMode -auditQiraahAlignment
run semantic          120 "SEMANTIC PACK hadith"     -launchTabQuran -quranListMode -auditSemanticPacks
run packs             300 "PACK AUDIT DONE"          -auditPacks
run cloudkeys          40 ""                         -cloudKeyAudit
run rollover           25 ""                         -dailyRolloverProbe
echo AUDITS DONE
```

</details>
<details><summary>idle.sh: the idle publish and render counters</summary>

```zsh
#!/bin/zsh
# idle.sh <udid>: per screen, launch with -publishCounter -renderCounter, let it settle 14 s, then record 20 s of
# "PUBLISH COUNT" / "RENDER COUNT" / "WIDGET RELOAD" lines. Zero lines while idle is the Performance Guide's bar.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/idle
while IFS='|' read -r name args; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  eval xcrun simctl launch $UDID $BID -skipNotificationPrompt -publishCounter -renderCounter $args >/dev/null 2>&1
  sleep 14
  out=$SCR/logs/idle/$name.log
  xcrun simctl spawn $UDID log stream --style compact --predicate 'process == "iPhone" AND (eventMessage CONTAINS "COUNT" OR eventMessage CONTAINS "WIDGET RELOAD")' > $out 2>&1 &
  lp=$!
  sleep 20
  kill $lp 2>/dev/null; wait $lp 2>/dev/null
  p=$(grep -c "PUBLISH COUNT" $out); r=$(grep -c "RENDER COUNT" $out); w=$(grep -c "WIDGET RELOAD" $out)
  echo "$name: publish-lines=$p render-lines=$r widget-reloads=$w"
  grep -E "PUBLISH COUNT|RENDER COUNT|WIDGET RELOAD" $out | sed -E 's/^.*\(Foundation\) //' | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /'
done <<'LIST'
adhan|
adhan-sky-off|-seedBool showSkyView=0
adhan-sky-on|-seedBool showSkyView=1
quran-list-reader|-launchTabQuran -quranListMode -lastRead 2:255
quran-page-reader|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 2:255
quran-root|-launchTabQuran -quranListMode -noAutoOpenMushaf
hadith|-launchTabHadith
islam|-launchTabIslam
settings|-launchTabSettings
LIST
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
echo IDLE DONE
```

</details>
<details><summary>launch.sh: the cold-launch stopwatch</summary>

```zsh
#!/bin/zsh
# launch.sh <udid> <runs>: cold launches with -launchTiming per start screen; prints each milestone's median ms.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; RUNS="${2:-5}"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/launch
while IFS='|' read -r name args; do
  [[ -z "$name" ]] && continue
  : > $SCR/logs/launch/$name.txt
  for i in $(seq 1 $RUNS); do
    xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 2
    out=$SCR/logs/launch/$name-$i.log
    xcrun simctl spawn $UDID log stream --style compact --predicate 'process == "iPhone" AND eventMessage CONTAINS "LAUNCH TIMING"' > $out 2>&1 &
    lp=$!; sleep 1
    eval xcrun simctl launch $UDID $BID -skipNotificationPrompt -launchTiming $args >/dev/null 2>&1
    sleep 9
    kill $lp 2>/dev/null; wait $lp 2>/dev/null
    grep -oE "LAUNCH TIMING .* \+[0-9]+ ms" $out >> $SCR/logs/launch/$name.txt
  done
  echo "== $name ($RUNS runs)"
  python3 - $SCR/logs/launch/$name.txt <<'PY'
import sys, re, collections, statistics
d = collections.defaultdict(list); order = []
for line in open(sys.argv[1]):
    m = re.match(r'LAUNCH TIMING (.*) \+(\d+) ms', line.strip())
    if not m: continue
    k = m.group(1)
    if k not in d: order.append(k)
    d[k].append(int(m.group(2)))
for k in order:
    v = d[k]; print(f"   {k:40s} median {int(statistics.median(v)):6d} ms  (n={len(v)}, min {min(v)}, max {max(v)})")
PY
done <<'LIST'
adhan|
quran-list|-launchTabQuran -quranListMode -lastRead 2:255
quran-page|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 2:255
LIST
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
echo LAUNCH DONE
```

</details>
<details><summary>tripwire.sh and tripwire.lldb: a backtrace of the first appearance-tripwire hit</summary>

```zsh
#!/bin/zsh
# tripwire.sh <udid>: launch paused for the debugger, attach lldb with a breakpoint on AppearanceDefaultTripwire.note,
# print the backtrace of the first hit, detach.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
pid=$(xcrun simctl launch --wait-for-debugger $UDID $BID -skipNotificationPrompt | awk -F': ' '{print $2}')
echo "pid=$pid"
xcrun lldb -p $pid -s "${0:A:h}/tripwire.lldb" > $SCR/logs/tripwire.txt 2>&1 &
lp=$!
for i in $(seq 1 60); do sleep 1; grep -q "frame #1" $SCR/logs/tripwire.txt && break; done
sleep 3
kill $lp 2>/dev/null
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
grep -E "frame #" $SCR/logs/tripwire.txt | grep -vE "libswift|SwiftUICore|SwiftUI\`|AttributeGraph|UIKitCore|CoreFoundation|libdispatch|GraphicsServices|dyld|libsystem" | head -25 | cut -c1-220
echo "--- raw head"; grep -E "frame #[0-9]+:" $SCR/logs/tripwire.txt | head -45 | cut -c1-200
```

```
settings set target.process.stop-on-exec false
breakpoint set -r "AppearanceDefaultTripwire.*note"
breakpoint command add 1
bt 45
detach
quit
DONE
continue
```

</details>

<details><summary>tsan.sh: seven flows under Thread Sanitizer</summary>

```zsh
#!/bin/zsh
# tsan.sh <udid>: install the TSan build, run flows with console capture, count ThreadSanitizer reports, reinstall Debug.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/tsan
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
xcrun simctl install $UDID $SCR/dd-tsan/Build/Products/Debug-iphonesimulator/iPhone.app || { echo INSTALL FAILED; exit 1; }
run() { # name secs args...
  local name=$1 secs=$2; shift 2
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  local out=$SCR/logs/tsan/$name.log
  xcrun simctl launch --console-pty $UDID $BID -skipNotificationPrompt "$@" > $out 2>&1 &
  local lp=$!
  sleep $secs
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1
  kill $lp 2>/dev/null; wait $lp 2>/dev/null
  echo "$name: $(grep -c 'WARNING: ThreadSanitizer' $out) TSan reports, $(wc -l < $out | tr -d ' ') lines"
}
run launch-adhan       40
run hadith-search      50 -launchTabHadith -hadithSearch "patience"
run hadith-book        40 -launchTabHadith -launchHadithOpen bukhari:1
run islam-duas         40 -launchTabIslam -islamDestination commonDuas
run quran-word-card    50 -launchTabQuran -quranListMode -lastRead 2:1 -openRowSheet word -wordIndex 1
run quran-page         45 -launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 18:1
run askai              90 -launchTabIslam -islamDestination askAI -askAIReset -askAI "What does the Quran say about patience?||who narrated that hadith?"
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
xcrun simctl install $UDID $SCR/dd/Build/Products/Debug-iphonesimulator/iPhone.app && echo "REINSTALLED DEBUG"
echo TSAN DONE
```

</details>

---

## Appendix B: acceptance checklist per phase

Paste into the closing report, each box ticked or marked with why not.

- [ ] Every item touched has its repro run before and after, with the result in its box.
- [ ] Debug and Release builds of the `iPhone` scheme pass, with no new Swift warning.
- [ ] The sweep over the phase's screens: every screen alive, no new crash report, `analyze.py` shows no new error or fault line against the baseline.
- [ ] If rendering was touched: the idle counters still read zero publishes; `-renderCounter` shows no new steady renders.
- [ ] If a Settings field was added or a row's body changed: its `==` or signature folds the new field.
- [ ] If a persisted format changed: a file written by the previous build still decodes (C7's rule), and `CloudSnapshot.currentSchemaVersion` moved if the backup carries it.
- [ ] Watch, Widget and Complication still build (shared files, fences).
- [ ] Simulator state restored (`-seedBool` and `-displayQiraah` seeds persist; the dotless seed makes every later launch abort until C1 is fixed).

---

## Progress log

Append one entry per session, newest last: date, phase, items, files touched, verification, what is left, and any decision Abu made.

- 2026-09-28: audit only, no code changes. This guide written from: Debug, Release and Thread Sanitizer builds; a 92-screen runtime sweep on the iPhone 17 Pro simulator (iOS 27) with per-screen log analysis; the dotless crash reproduced; seven data verifiers; the in-app pack, alignment, semantic, rollover and cloud-key audits; idle counters on nine screens; cold-launch timing on iOS 27 and 26.5; an lldb trace of the appearance tripwire; the crash reports on this Mac; and ten code audits. Simulator state after the audit: Hafs, dots shown, list mode, the Debug build of this tree installed on the "iPhone 17 Pro (Claude)" and "iPhone 17 Pro" (26.5) simulators; one audit also installed it on the spare "iPhone 17 Pro (iOS 27)" simulator, restored the About You values it changed, and left that simulator's notification permission denied.
- 2026-09-28 (the run, Abu: "run it", "keep going"): Phases 0 to 7 executed in one session. 105 of 106 items ticked in their boxes with the result; open: T7 (waits on D2), and D1. D3 to D8 taken by Claude as flagged, reversible calls (see "Decisions made"). Nothing committed.
  - **Files** (on top of the uncommitted Ask AI, Chosen Ayah, lifecycle and Need a Hand? work Phase 0 hardened): the six AskAI*.swift files; Globals.swift (`UserDataRescue`, `TypedAmount`, `ArabicRasm`, `QuranFontCache` bound, `LaunchClock` marks, stall watch and prewarm rebase); QuranData.swift, MushafReader.swift, MushafPDFReader.swift, SurahView.swift, AyahRow.swift, SurahRows.swift and most of iPhone/Quran; QuranPlayer.swift (R1 to R6, F6); Settings.swift, SettingsQuran.swift, SettingsAdhan.swift, SettingsView.swift, CloudManifest.swift, CloudBackupManager.swift, WatchConnectivity.swift, ArabicLetters.swift, ActivityLog.swift; the Adhan widgets (`AdhanWidgetKind`), PrayersProvider, FastingLiveActivity, the Quran widgets; iPhone/Islam (DuaView, DailyReminders, IslamView, SignsAndProphets, ProphetViews, the calculators, JournalView, NamesView, ArabicLetterViews); HelpDoors.swift, ViewExtensions.swift, RemovalConfirmation.swift; Al-IslamApp.swift, AppDelegate.swift, AppLifecycle.swift, LaunchScreen.swift; QuranMetadata.json (hizb 7 and 21); Scripts/audit_islam_quotes.py, Scripts/check_cloud_manifest.py, new Scripts/qa/; Docs/Ask AI Guide.md, Docs/iCloud Sync Guide.md, this guide.
  - **New DEBUG hooks:** `-askAITextProbe`, `-auditJuzTables`, `-mushafFindStep <n>`, `-cloudResetProbe` now prints the device-only keys it spared; `-launchTiming` gained first-body, on-appear, did-finish-launching marks and a run-loop stall watch.
  - **Verification:** every item's repro before and after, as its box says; Debug builds of iPhone and Watch with zero Swift warnings; the final Release build (Widget and Complication included) green with zero Swift warnings; Thread Sanitizer and Address Sanitizer over nine flows each (launch, Hadith background and foreground twice, all-books search, in-book search, Duas, word card, page reader, Qiraat explorer, Ask AI): 0 reports, the `-tsanSelfTest` race caught; a strict-concurrency build read for detached main-actor reads (none flagged); the end-of-session sweep over all 96 screens with `Scripts/qa/sweep.sh`: every screen alive and no crash report (five Hadith screens first read DEAD because the simulator itself went down for six minutes, "device is not booted"; they pass on rerun), and the analysis found two leftovers, both fixed and rerun clean (G12's Hadith settings hook, P14's first-launch gap); idle counters on nine screens: zero publish lines; `check_cloud_manifest.py` clean; the quote auditor 924/924 and 635/635.
  - **Left:** D1 (device crash data), D2 and T7; a Release launch measurement in Instruments (F1); re-encoding the OC Ummah wallpaper is optional (F13). Al-Quran and Al-Adhan get the shared-file fixes only through `sync_from_islam.sh`, which this session did not run.
  - **Simulator state:** the "iPhone 17 Pro (Claude)" (iOS 27) simulator ran "Reset Settings, Keep My Content" (G10's check), so its preferences are defaults again (accent set back to green); content, first-launch and About You state kept. The iOS 26.5 iPhone 17 Pro was booted for F2 and seeded `quranPageMode=0`, `THEfirstLaunch=0`, `aboutYouVersionSeen=9`, then shut down. The Debug build of this tree is installed on both. The 27 simulator's notification permission was denied by the U17 cold-launch test (a "Don't Allow" tap) and is now switched on in Settings > Apps > Al-Islam, so the app's "Notifications Off" dialog no longer collides with the sweep's sheet hooks.

- 2026-09-29 (Abu: juz boundaries, D1 as simulator and Mac crash tests "especially mac and ipad", D2, F13, and "make the quran share ayah different backgrounds look nicer" with no ink mismatching its ground). Nothing committed.
  - **D3 overturned (A4):** Abu's table said 3:93 and 9:93; the printed pages 62 and 201 put the ۞ there, as Tanzil and Quran.com do. `juzList` and QuranMetadata.json are back to their committed values, and quran.qpk's per-ayah juz for 3:92 and 9:93 is patched to match (plus Resources/JSONs-Deprecated/Quran.json). `-auditJuzTables`: 0 of 30 disagree.
  - **Share card:** one composer for the sheet and Copy Image (`ShareAyahSheet.composeCard`; the Copy Image copy had drifted); Frosted's words on a milky panel with dark inks, Nature's scene a fixed band with the words on the sea, Geometric's lattice faded inside its frame, Editorial's watermark centered; each palette carries its ground, appearance and Allah ink, and `ShareInk` lifts any run under 3:1 (the accent under 4.5:1). Classic's caption was `.secondaryLabel` (dark gray on black). `-shareCardGallery <tag>` renders 4 samples x 5 designs and logs every accent's contrast (was ~4.2:1 on black, now 5.8 to 14.9:1).
  - **T7 (D2):** the UnitTests and UITests targets; 81 unit tests pass and found one bug, fixed (the faraid half-sister reason). **F13:** the wallpaper re-encoded losslessly; no -6680 on open.
  - **Crash sweeps (D1 in lieu of device data):** iPad Pro 13-inch (M5, iOS 27) 95 of 95 alive, twice; iPad mini (A17 Pro) 95 of 95; iPad Pro 13-inch in real landscape through XCUITest 95 of 95, and a 150-step seeded monkey walk with rotations, 0 crashes; iPad Pro 11-inch (M5) with a second window open (`-openSecondWindow`) 95 of 95. No new crash report in DiagnosticReports all session. The DEBUG `-landscape` argument no longer rotates on iPadOS 27 (use XCUITest). A 37-second iPad launch was host load (load average ~150), not the app: a fresh install on a calm host revealed at 6.1 s.
  - **Mac:** the Designed-for-iPad build and its tests compile and sign, but no launch got past `_dyld_start`: macOS's syspolicyd (Gatekeeper) was wedged ("Unable to initialize qtn_proc: 3" ~8 a second) and held every new executable, and driving Xcode needs Abu's Automation approval (a prompt may be waiting on screen). `Scripts/qa/mac-sweep.sh` is ready. A static Mac audit found no crash; fixed from it: a Mac window left open behind another app now keeps the in-app adhan armed (it disarmed at `.inactive`, and late notifications go silent), `topmostViewController()` falls back to a visible inactive scene (with none active, a removal went ahead without asking), and About You says "Mac" on a Mac. To verify on a Mac: the share sheets (`ActivityView` embeds `UIActivityViewController` in a SwiftUI sheet, reported blank on Mac), and D9.
  - **Files:** QuranData.swift, QuranMetadata.json, quran.qpk, Resources/JSONs-Deprecated/Quran.json; ShareAyah.swift, ShareBackdrop.swift; InheritanceView.swift; AppLifecycle.swift, ForegroundAdhanPlayer.swift, RemovalConfirmation.swift, AboutYouView.swift; Al-IslamApp.swift (`-shareCardGallery`, `-openSecondWindow`); the OC Ummah wallpaper; project.pbxproj and the iPhone scheme (two test targets); new UnitTests/ and UITests/; Scripts/qa (sweep.sh retry, resume and extra arguments; mac-sweep.sh; README). Xcode 27's xcodebuild also created `Al-Islam.xcodeproj/xcshareddata/xcodecloud/manifest.json`, which the app does not need.
  - **Verification:** Debug, Release and Watch builds green with zero Swift warnings; 82 unit tests (81 pass, the Mac probe skips by design); the sweeps above; the gallery renders before and after.
  - **Left:** D1 (device data), D9, the Mac run (after a restart un-wedges Gatekeeper, or from Xcode), the sidebar cosmetics seen in iPad landscape (Hadith's "YOUR SUMMARY" and its Today chip break mid-word, some Quran shortcut tiles too), `sync_from_islam.sh` for Al-Quran and Al-Adhan.

- 2026-10-04 (Abu: "do hardcore optimizations and efficiencies for accuracy and correctness ... no errors no bugs no problems no glitches"): Phase 8, written and executed in one session. Nothing committed.
  - **How:** fourteen audits (prayer-time accuracy against an independent solar solver, notifications and tracker, widgets, backup and data, hadith and Islam logic, Quran text and tajweed with a compiled copy of the painter over the whole Quran, word study and qiraat, search with a harness over the shipped pack, player and CarPlay, reader and page mode, plus diff, concurrency and SwiftUI-rule reviews). Five implementer agents were stopped by a usage limit mid-run; every edit they made was read back from their transcripts and the half-finished ones completed (memory "subagent-partial-edits-recovery").
  - **Items:** 98 fixed (see Phase 8); D10 lists the calls left for Abu; D3, S6, M10, M11 and G3 not done, with reasons.
  - **Files:** the vendored adhan-swift (SolarTime, Astronomical, HighLatitudeRule); PrayerCalculationMethods, SettingsAdhan, PrayerTrackerView, PrayerList, ActivityLog, FastingActivityController; Settings, SettingsQuran, CloudMergeRules, CloudBackupManager, CloudManifest, ContentCategories, AskAIConversation; PrayersProvider, DailyWidgets, ChosenAyahWidget; HadithModels, HadithView, HadithBookView, DailyReminders, InheritanceView, ZakahView, ZakatAlFitrView, OpenScreens, IslamSearch, ArticleDesign, SettingsQuranView, SettingsIslamView, HelpDoors; QuranData (painter and index), QuranRankedSearch, VerseSearchPack, Highlighted, SurahRows, QuranView; WordByWord, QiraatVariants, QiraatExplorer, ComparisonSheets, QiraatTextAnalysis, RiwayatDifferencesView, QiraahTajweed (a comment); QuranPlayer, CarPlayScene, QuranHistoryRows, QuranShortcuts; MushafReader, SurahView, AyahRow; quran-search.qsp re-exported (format 2); Scripts/qa/screens.txt (five search screens); new UnitTests PrayerTimesTests, TajweedPaintTests, WordStudyTests, SearchFixTests, new cases in FaraidTests; this guide and Docs/iCloud Sync Guide.md (the Ask AI transcript is kept on the device and erased with it).
  - **Verification:** Debug build and the UnitTests target: 197 tests, 0 failures (2 skipped by design; 171 at the start of the pass), zero Swift warnings. Release build of the iPhone scheme (iPhone, Watch, Complication, Adhan, Widget, Stickers): zero warnings of any kind. PrecomputedPackTests confirm the re-exported pack against a live build; the lexicon's bytes did not change. `check_cloud_manifest.py`: every key classified. The sweep over 100 screens: all alive, no crash report, and `analyze.py` shows no new error or fault line against this morning's baseline (two system-noise lines fewer). Idle counters on nine screens: zero publish and render lines, as at baseline. The tajweed fixes were each diffed over all 6,236 ayahs (with Munfasil and Muttasil hidden too), and the Asr change measured over 1,968 city-days.
  - **Left:** the D10 calls; M10 and M11 need a repro first; G3 needs its trigger driven by hand; `sync_from_islam.sh` for Al-Quran and Al-Adhan (the shared files changed).
  - **Simulator state:** "iPhone 17 Pro (Claude Al-Islam)" holds the final Debug build, Hafs, list mode, default settings after the sweep's resets.
- 2026-10-05 (Abu: "yes do all of those", the D10 calls): Phase 8, round 2. Nothing committed.
  - **Items:** T2, T5, T8, H4, H7, J8, J10, K6 and S6 done (see Phase 8, round 2); J2's remainder kept as decided. K6 ran as a background agent (pack builder and verifier only).
  - **Files:** PrayerCalculationMethods, AdhanStructs (`PrayerMinute`), SettingsAdhan, SettingsAdhanView, FastingActivityController, FastingAttributes, FastingLiveActivity, PrayerProgressWidgets; HadithPack, HadithModels, HadithBookView, HadithComponents, HadithStore, Settings (one device-only key); Globals (`ArabicRasm`), TajweedRules, QuranData (paint ops carry a name), WordByWord; TasbihView; Scripts/build_qul_packs.py, verify_qul_packs.py, audit_quran_font_coverage.py; Resources/Data/Quran/Morphology.json.xz rebuilt; UnitTests PrayerTimesTests, ArabicDotsTests, TajweedPaintTests (new cases), HadithNumberingTests (new).
  - **Verification:** UnitTests 205, 0 failures (2 skipped by design), zero Swift warnings. Release build of the iPhone scheme: zero warnings. `check_cloud_manifest.py`: every key classified. `verify_qul_packs.py`: OK, every other pack byte-identical. A sweep of the 27 screens these files draw (Adhan, prayer settings, Hadith, the word card, Tasbih): all alive, no app warning, no crash report (the one report of the day was a unit test of this round overflowing `NSNotFound` before it was guarded). Screenshots: the word card names Merge with Ghunnah on 2:8's مَن and Hidden Meem on هُم; Sahih Muslim lists 0: Introduction before 1: The Book of Faith; Bulugh al-Maram's formerly colliding row reads 2:353.
  - **Left:** D3, M10, M11, G3 as before; `sync_from_islam.sh` for Al-Quran and Al-Adhan.
