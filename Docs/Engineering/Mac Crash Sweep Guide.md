# Mac Crash Sweep Guide

How to run the crash sweep on Abu's Mac and judge what it finds. Written 2026-10-12 for the Claude session
that runs the next sweep. The tool is `iPhone/Helpers/System/StressWalker.swift`; the drivers are under
`Scripts/qa/`. Read this whole file before the first command. CLAUDE.md stays in force: nothing is
committed, no em dashes, PushNotification when a batch is done.

## 1. What the sweep is

- **The app drives itself.** `StressWalker.swift` (DEBUG only, `#if DEBUG && os(iOS)`, started from the
  `.task` in Al-IslamApp.swift) is an in-process monkey. With `-stressWalk <steps> -stressSeed <n>` it
  enables accessibility for its own process and activates random accessibility elements (rows, buttons,
  links, switches, tiles), pops, switches tabs, dismisses sheets, scrolls, resizes the Mac window, flips
  light/dark and Dynamic Type, storms settings through the real setters, follows deep links, plays audio,
  types hostile text, opens a second window, fakes a memory warning, hides and unhides the app. Every
  step is logged as `STRESS <step> <action> | <screen>`. The same seed gives the same walk.
- **Xcode launches it.** On this Mac every other launcher parks a development build at `_dyld_start`
  forever (xcodebuild test hosts, `open` on a wrapper; a reboot does not clear it). `stress-mac.sh`
  writes the private QA-Mac scheme with the walk's arguments and no debugger, then drives Xcode by
  AppleScript to run it on "My Mac (Designed for iPad)". A crash writes
  `~/Library/Logs/DiagnosticReports/iPhone-<date>.ips`.
- **Abu's data is protected.** The Debug build shares the installed app's container. Before its first
  step the walk snapshots both defaults domains, Documents and Application Support and puts them back
  at the end (StateGuard); automatic iCloud saves are suspended during a walk. A crashed walk leaves a
  `pending` snapshot: the next walk keeps it, and the restore pass (`stress-mac.sh restore restore 0`)
  puts it back.
- **The bar Abu set:** 0 crashes, 0 problems. Every real crash gets a root-cause fix
  (superpowers:systematic-debugging), a regression test where one can be written, and a rerun of the
  seed that found it.

## 2. Before the first run (every line, every session)

1. `cd ~/Downloads/Islam/Al-Islam-iOS`. `git status --short | head` shows Abu's normal uncommitted work.
   Never run git commit, push, reset or checkout.
2. The environment, in every Bash call that runs a script:
   ```
   export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
   export QA_OUT=<your scratchpad>/qa        # results land in $QA_OUT/mac/
   ```
3. **Sandbox off** for every call that runs `stress-mac.sh`, `stress-mac-seeds.sh`, `stress-screens.sh`
   or `sample`: osascript must reach Xcode and `sample` must attach to the process. In Claude Code that
   is `dangerouslyDisableSandbox: true` on the Bash call. Long batches run with `run_in_background: true`;
   read `$QA_OUT/mac/*-run.txt` as they land instead of sleeping.
4. Xcode is running with the project open:
   ```
   osascript -e 'tell application "Xcode" to get path of every workspace document'
   ```
   must list `/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Al-Islam.xcodeproj`. If not:
   `open -a Xcode /Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Al-Islam.xcodeproj` and wait 20 s.
   If osascript answers `-1743` (not authorized), stop and tell Abu: Automation for the shell needs his
   approval in System Settings > Privacy & Security > Automation. It was approved on 2026-10-12.
5. The destination exists (the first line must be `My Mac (Designed for iPad)`):
   ```
   osascript -e 'tell application "Xcode" to tell (first workspace document whose path is "/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Al-Islam.xcodeproj") to get name of every run destination' | tr ',' '\n' | head -3
   ```
   The QA-Mac scheme is rewritten by `write_mac_scheme.py` on every run; it lives in xcuserdata
   (git-ignored) and never needs editing.
6. Nothing stale is running. A leftover Mac instance gets re-activated by Xcode instead of launched, and
   `pgrep -x iPhone` also matches simulator processes:
   ```
   for p in $(pgrep -x iPhone); do ps -o pid=,args= -p $p | grep -q CoreSimulator || kill -9 $p; done
   ```
   Quit the installed /Applications/Al-Islam.app if it is open (same container). Never run two Mac walks
   at once.
7. The entitlements file is clean: `git status --short Resources/Entitlements-Main.entitlements` prints
   nothing. The driver strips `com.apple.developer.weatherkit` for each build (the local profile lacks
   it) and copies the original back. If a killed run left it stripped, put the key back; the file
   round-trips through plistlib byte for byte:
   ```
   python3 - <<'PY'
   import plistlib; p='Resources/Entitlements-Main.entitlements'
   d=plistlib.load(open(p,'rb')); d['com.apple.developer.weatherkit']=True; plistlib.dump(d,open(p,'wb'))
   PY
   ```
   then check `git status --short` again (empty).
8. The sources compile. Xcode compiles the live tree before every run; an edit that does not compile
   fails every remaining run of a batch (`status: failed at 5 s` in xcode.log). Prove it with a simulator
   build before a batch:
   ```
   UDID=$(xcrun simctl list devices available | grep "iPhone 17 Pro (Claude Al-Islam)" | grep -oE '[0-9A-F-]{36}' | head -1)
   xcodebuild -project Al-Islam.xcodeproj -scheme iPhone -configuration Debug -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$QA_OUT/dd" build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
   ```
9. Never edit a source file while a batch runs (Xcode builds it), and never edit a script that a batch
   is running (bash reads scripts incrementally). Copy the script to a new name and switch.
10. Never pass `-seedBool`, `-seedInt`, `-seedString`, `-travelingMode`, `-lastRead`, page or list mode or
    riwayah arguments on the Mac. They land before the snapshot and would be restored into Abu's real
    data. `stress-screens.sh mac` skips those screens by itself.

## 3. One walk: the smoke test (about 5 minutes)

```
Scripts/qa/stress-mac.sh smoke 60 99
```

`<tag> <steps> <seed>`. The tag names the output folder `$QA_OUT/mac/smoke/` and the run token; keep
tags unique within a day. What you see (a real run on 2026-10-12 through `stress-mac-seeds.sh 60 99`, so the
tag is `w60-99`; the smoke command above prints the same with the tag `smoke`):

```
=== w60-99: -skipNotificationPrompt -stressTag w60-99 -stressWalk 60 -stressSeed 99 -stressGap 0.3 -stressExit  (cap 360s)
app pid 56508 after 42s: /private/var/folders/.../Wrapper/iPhone.app/iPhone -skipNotificationPrompt -stressTag w60-99 -stressWalk 60 ...
+6s: rss=238816 frame:     + 565 start  (in dyld) + 6688  [0x193a13e80]
=== result w60-99: ran 20s alive=0 hung=0 crashes=0 hangs=0 trail=      67 lines
  HANG markers: 0
--- xcode
23:34:19 destination set
23:34:24 status: running at 5 s
23:35:24 status: succeeded at 65 s
--- trail tail
... STRESS 59 done 60 steps, 2 activations, 3 unresolved
... STRESS state restored from /Users/theabubakrabu/Library/Containers/<uuid>/Data/Library/stress-backup
... STRESS 59 restore: done
... STRESS exiting
```

And the top of `$QA_OUT/mac/w60-99/trail.log`:

```
... STRESS 0 accessibility bridge: was 0 now 1 +init
... STRESS 0 start steps=60 seed=99 gap=0.3 mix=all audio=true mac=true idiom=1 guard=snapshot taken
... STRESS 0 tap "Jumada I 1, 1448 AH, ..." @334,102 of 27 | UIHostingController<ModifiedContent<Lazy "Al-Adhan"
```

- `app pid ... after Ns`: Xcode's build took N seconds (about 40 s when nothing changed, most of it the
  project closing and reopening; 1 to 3 minutes after a source change). The launched process carries this
  run's `-stressTag`.
- `stale launch (...) killed at Ns`: Xcode launched with the previous scheme contents; the driver kills
  it and tries again. Harmless once. Three in a row: see section 7.
- `=== result`: `alive=0` the process exited by itself (`-stressExit`); `hung=0` the watchdog never
  fired; `crashes=0` no new Mac `.ips` (`ipsmatch.py mac`, by path); `hangs=0` no new `.hang` under
  /Library/Logs/DiagnosticReports; `trail=` the STRESS lines pulled from the unified log (the container
  cannot be read from outside the app).
- The trail's first lines must say `accessibility bridge: was 0 now 1` (or `was 1`) and `guard=snapshot taken`;
  `was 0 now 0` means the walk cannot see SwiftUI's elements and every tap will be `unresolved`.
- The trail's last lines must say `done <steps> steps` and `restore: done`. `restore: nothing pending`
  after a walk means the snapshot was never taken: stop, read `$QA_OUT/mac/<tag>/trail.log` from the
  top (the `start` line's `guard=` must say `snapshot taken` or `kept pending snapshot`).
- Files per run: `$QA_OUT/mac/<tag>/xcode.log` (the AppleScript's status lines), `osascript.out`,
  `sample-start.txt`, `trail.log`, and on a hang `sample-hang.txt` and `sample-hang2.txt`.

Time per walk: the build, plus steps x gap, plus about 30 s. 400 steps at 0.3 s is about 2.5 minutes.

## 4. The sweep (what "hardcore" means)

Run each batch in the background and read the `-run.txt` files as they land. The three batches take
about three hours in all.

1. **Twenty seeds, 400 steps** (about one hour):
   ```
   GAP=0.3 Scripts/qa/stress-mac-seeds.sh 400 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
   ```
   One line per seed, then the restore pass. Folders `$QA_OUT/mac/w400-<seed>/`.
2. **Churn, 800 steps with no taps**: settings storms, resizes, hides, deep links and playback every
   0.1 s (10 minutes). `GAP` is the only way to set the gap; a `-stressGap` in the extra arguments is
   ignored because the driver's own comes first.
   ```
   GAP=0.1 Scripts/qa/stress-mac.sh churn-a 800 30 -stressMix nav
   GAP=0.1 Scripts/qa/stress-mac.sh churn-b 800 31 -stressMix nav
   Scripts/qa/stress-mac.sh restore restore 0
   ```
   Expect `hung=1` here: the main thread saturates (section 6). On its own that is not a failure.
3. **Start deep**: one 120-step walk per screen of `screens.txt`, launched with that screen's own
   arguments, so the walk begins on that screen (about one and a half hours for the Mac-safe screens):
   ```
   GAP=0.3 Scripts/qa/stress-screens.sh mac - S 120
   ```
   One line per screen, then the restore pass.
4. **Replays and variations** when something showed up: the same seed again
   (`Scripts/qa/stress-mac.sh again 400 5`), a longer walk (`2000`), a slower one (`GAP=0.6`), or a
   fixed sequence with `-stressScript` (section 5).

"Done" means: every result line `alive=0 crashes=0`; `HANG markers: 0`, or each HANG classified as
saturation (section 6); every trail ends in `done` and `restore: done`; the final restore pass says
`nothing pending`; `git status --short Resources/Entitlements-Main.entitlements` is empty; no `iPhone`
process is left (step 2.6).

## 5. A crash showed up (`crashes=1`, `NEW REPORT: iPhone-....ips`)

1. **Read it:**
   ```
   python3 Scripts/qa/ipsreport.py ~/Library/Logs/DiagnosticReports/iPhone-2026-10-12-183912.ips
   ```
   The first line says `MAC APP` (path `/Volumes/VOLUME/*/iPhone.app/iPhone`) or `SIMULATOR`. A
   simulator report carries the host's macOS version, so only the path tells them apart. The `message`
   line holds the Swift trap ("Fatal error: Index out of range") or the ObjC exception; the crashing
   thread's frames are symbolised for the app (`iPhone.debug.dylib`). The last line says whether a
   StressWalker frame is on any stack.
2. **Find the step.** The report's capture time against `$QA_OUT/mac/<tag>/trail.log`: the last
   `STRESS` line before it is the trigger, the ten before it are the state. Also
   `grep -n "Fatal error" $QA_OUT/mac/<tag>/trail.log`.
3. **Decide whether a person could do it.** A crash counts against the app only when the triggering
   action is one a person can perform on a Mac.
   - Walker-only (fix the walker, not the app): typing or activating while a context menu or a native
     Mac menu is open (`menu:` lines just before), a window below 668x414 (the floor), scrolling a
     picker's inner table, a StressWalker frame doing the harm itself (its own logging, its own
     synthesised events), anything no hand can do in one run-loop turn.
   - Real: a tap, a pop, a sheet dismissal, a resize at a legal size, a settings change, a Dynamic Type
     change, a deep link, a memory warning, playback, hostile text, and a double tap (`double` lines),
     since two clicks in one frame happen.
   - Also real: a crash inside SwiftUI or UIKit whose trigger was legal. The Jump-to wheel crash of
     2026-10-12 was inside SwiftUI's picker coordinator; the app's live row count was the cause.
4. **Reproduce before fixing.** The same seed, steps and start screen is deterministic enough most of
   the time:
   ```
   Scripts/qa/stress-mac.sh again 400 5
   ```
   If not, replay the shape with a script: steps separated by `;`, an underscore stands for a space
   inside a label, `-stressScript` wins over the `-stressWalk` the driver adds, and the `<steps>`
   argument only sizes the time cap.
   ```
   Scripts/qa/stress-mac.sh replay 60 0 -stressScript 'wait:3;tap:Ask_AI;wait:2;tap:Play;dismiss;resize:1600x900;wait:3;release'
   ```
   Steps: `wait:<s>`, `tap:<label part>` (the first on-screen element whose label contains it),
   `double:<label part>`, `back`, `dismiss`, `tab:<adhan|quran|hadith|islam|settings>`, `resize:WxH`,
   `release`, `hide`, `appearance:<dark|light|system>`,
   `deeplink:<quran|surah:n|ayah:s:a|duas|adhkar|names|qibla|hadith|search:q>`, `play:<surah>`,
   `playayah:<s:a>`, `stop`, `type:<text>`, `memory`, `window`, `scroll:<top|bottom>`, `dump`. The trail
   says `activated`, `UNRESOLVED` or `NOT FOUND` for each tap, so a replay that never found its label is
   not a pass.
5. **Fix the root cause** in the app (superpowers:systematic-debugging), never a guard around the
   walker. Add a unit test when the failure can be expressed, run UnitTests on the iPhone 17 Pro
   simulator, rerun the seed that found it, then the batch.
6. **Log it** in `Docs/Engineering/Quality Guide.md` (Progress log) in the shape of the 2026-10-12 entry: the tool,
   the runs, fixed, not the app, open.

## 6. A HANG showed up (`hung=1` or `HANG markers: n`)

The walk's watchdog logs `STRESS n HANG main thread silent for N s` after 12 s without a step. The
driver samples the process at the first HANG line (`sample-hang.txt`, 3 s), waits 20 s, samples again
(`sample-hang2.txt`) and kills it. Read the main thread in the sample (the first thread, `com.apple.main-thread`):

- Deepest frames in SwiftUI, AttributeGraph, CoreText, UIKit layout, `os_log`, CFPreferences: the main
  thread is BUSY, not stuck. Every sampled Mac HANG on 2026-10-12 was this (98 to 100% in render and
  layout under settings storms and resizes every 0.1 to 0.3 s in a Debug build). Not a crash, not a
  deadlock: note it, and only chase it if a person's pace reproduces it (`GAP=0.6 -stressMix ax`).
- Deepest frames in `__psynch_mutexwait`, `semaphore_wait_trap`, `__ulock_wait`, or `mach_msg2_trap`
  under anything other than the run loop's idle wait, and the same picture in `sample-hang2.txt` 20 s
  later: a DEADLOCK. Find the thread holding the lock, then fix (memories `viewedlog-ioqueue-deadlock`
  and `mac-defaults-notification-deadlock` are the two found so far).
- The trail's last line before the HANG says what was running. `menu: native menu open, waiting` is a
  native Mac menu owning the run loop (the walker waits; not a hang). Actions that leave the app
  ("Directions" opened Maps and the app was suspended) are off limits for this reason.
- `/Library/Logs/DiagnosticReports/iPhone_*.hang` and `.cpu_resource.diag` are root-owned and unreadable
  from the harness; the driver only counts them. Ask Abu for the file if one matters. `spindump` needs
  root and writes empty files; `sample` is the tool.

## 7. Traps (each one cost time on 2026-10-12)

| Symptom | Cause and what to do |
| --- | --- |
| `stale launch (-stressTag <old>) killed`, three times in a row | Xcode kept the scheme it read when the project opened. The driver closes and reopens the project before each run (`open -a Xcode`; AppleScript `open` times out). If it still happens, close the project in Xcode yourself and rerun. |
| `the AppleScript ended before issuing the run` | Xcode was mid-reload; the driver starts the script again, up to four times. |
| Two `start` lines in `xcode.log`; every run fails at 5 s on WeatherKit | Two AppleScripts in flight (a stray launch outside the retry loop). `pkill osascript`, restore the entitlements (step 2.7), rerun. |
| `status: failed at 5 s` on every run | A compile error in the live sources. Build for the simulator (step 2.8), fix, rerun. |
| `no Mac process after 300s` | Read `$QA_OUT/mac/<tag>/xcode.log` and `osascript.out`. "project did not open": quit and reopen Xcode. `-1743`: Automation not approved. |
| Process suspended, 96K footprint, one frame at `_dyld_start` | A non-Xcode launcher. Only Xcode's launcher works on this Mac; do not try `open` or xcodebuild again. |
| `restore: nothing pending` right after a full walk | The snapshot was never taken, so the walk ran on Abu's live state. Read the trail's `start` line (`guard=`). |
| `pgrep -x iPhone` finds a pid that is not the app | A simulator process; filter on `CoreSimulator` in `ps -o args=`. |
| AttributeGraph `value_set_internal` SIGSEGV with the window at 400x400 | Walker-only. The floor is 668x414; the walk clamps to it now. |
| AttributeGraph abort right after a `type` or a tap with `menu:` lines before it | Walker-only. The walk now only picks a menu item or waits while a menu is up. |
| A crash with StressWalker in its stack | The walker's own bug (its logging once trapped on `Int(CGFloat.greatestFiniteMagnitude)`); fix the walker. |
| The installed app at /Applications/Al-Islam.app misbehaves while the walk is clean | It is build 241 (2026-10-06, `defaults read /Applications/Al-Islam.app/Wrapper/iPhone.app/Info.plist CFBundleVersion`), without the 10-09 and 10-12 fixes. The walker only exists in Debug builds. Tell Abu a new TestFlight build is needed to judge the Mac. |

## 8. When the batch is done

1. The restore pass: `Scripts/qa/stress-mac.sh restore restore 0` (the batch scripts run it); its trail
   says `restore pass: restored` or `restore pass: nothing pending`.
2. `git status --short Resources/Entitlements-Main.entitlements` is empty; no `iPhone` process is left;
   `git status --short` shows only Abu's work plus your fixes.
3. Record the runs, the fixes and the open items in `Docs/Engineering/Quality Guide.md` (Progress log), and anything
   non-obvious in memory (`stress-walker.md`, `mac-launch-only-through-xcode.md`).
4. Report to Abu: the runs (seeds x steps), real crashes fixed with file names, walker-induced crashes
   explained, HANGs classified, open items, the UnitTests result, and that nothing is committed (say what
   the commit would contain).
5. `PushNotification` with `Completed in ~/Islam/Al-Islam-iOS`.

## Appendix A: launch arguments (StressWalker.swift)

| Argument | Meaning |
| --- | --- |
| `-stressWalk [steps]` | run the walk (default 400 steps) |
| `-stressSeed <n>` | the random seed (default 2026); same seed, same walk |
| `-stressGap <s>` | seconds between steps (default 0.35; the drivers set it from `GAP`) |
| `-stressMix ax|nav|all` | `ax`: taps, pops, tabs, dismissals, scrolls only; `nav`: everything but taps; `all` (default) |
| `-stressNoAudio` | no playback or speech |
| `-stressExit` | exit 0 when the walk ends (the drivers wait on the process) |
| `-stressDump` | log the first 40 accessibility elements at the start (tuning) |
| `-stressRestore` | put a pending snapshot back and exit (the restore pass) |
| `-stressScript '<steps>'` | a fixed sequence instead of a walk (section 5) |
| `-stressTag <tag>` | the driver's run token; the walker ignores it |

To watch a walk in Xcode: add `-stressWalk 2000 -stressSeed 7` to the iPhone scheme's Run arguments,
pick "My Mac (Designed for iPad)", Run. The trail is in the console and in the container's
`Library/stress/trail-7.log`. A crash stops in lldb there (the QA-Mac scheme runs without a debugger so
that a crash writes an .ips instead).

## Appendix B: the scripts

| Script | Role |
| --- | --- |
| `stress-mac.sh <tag> <steps\|restore> <seed> [args]` | one Mac walk through Xcode, or the restore pass |
| `stress-mac-seeds.sh <steps> <seed...>` | consecutive walks, one line each, then the restore pass |
| `stress-screens.sh mac - <tag> <steps>` | one walk per `screens.txt` line, started on that screen |
| `write_mac_scheme.py "<args>"` | writes the QA-Mac scheme (called by the driver) |
| `xcode-run-mac.scpt <project> <log>` | the AppleScript that closes, reopens and runs (called by the driver) |
| `ipsmatch.py mac <since-epoch>` | the new Mac crash reports since a time, by path |
| `ipsreport.py [report.ips ...]` | one crash report in a few readable lines |
| `stress-sim.sh <udid> <tag> <steps> <seed> [args]` | the same walk on a simulator (the iPhone 17 Pro; the phone "almost never crashes", the Mac is the target) |
