# Sibling Sync Guide

How to port Al-Islam's shared code into Al-Quran and Al-Adhan, and get both siblings building again. Written
2026-10-13 for the Claude session that runs the next sync. Read this whole file before the first command.
CLAUDE.md stays in force: nothing is committed, no em dashes, PushNotification when the job is done.

## 1. The three apps

All three checkouts sit side by side in `~/Downloads/Islam/`, and the sync toolchain sits there with them,
one folder up from each repo.

| App | Repo | What it ships | Flags it defines |
|---|---|---|---|
| Al-Islam | `Al-Islam-iOS` | everything: Quran, Hadith, prayer times, Islam tab, iCloud Backup, sky weather, stickers | HAS_QURAN HAS_HADITH HAS_ADHAN HAS_TIPS HAS_ICLOUD_BACKUP HAS_WEATHER |
| Al-Quran | `Al-Quran-iOS` | the Quran side and the shared Islam/Settings screens | HAS_QURAN HAS_TIPS |
| Al-Adhan | `Al-Adhan-iOS` | the prayer side and the shared Islam/Settings screens | HAS_ADHAN HAS_TIPS |

- **Al-Islam is the source of truth.** Shared code is written there first and ported to the siblings by this
  sync, never the other way round. A sibling's copy of a shared file differs only where it strips a feature
  it does not have, or names itself.
- **Deployment floors differ.** Al-Islam is iOS 16.0. Both siblings are iOS 15.0, app AND widget (Al-Quran's
  widget sat at 26.5 by accident until 2026-10-13), watchOS 9.0. Shared code must keep its
  `#available(iOS 16, *)` checks even though Al-Islam no longer needs them.
- **Per-app files are never merged:** the two roots (`iPhone/Al-<App>App.swift`, `Apple Watch/Al-<App>App.swift`),
  `Resources/Entitlements*`, every `PrivacyInfo.xcprivacy`, each repo's `project.pbxproj`, and the store copy
  in the sibling's `Docs/`.

## 2. Ground rules

1. **`--apply` only when Abu asks for it in the message you are answering.** The dry run writes nothing in
   the siblings and is safe any time. A request in an earlier message does not carry forward.
2. Never commit, push, reset, checkout or clean in any of the three repos. Say what is ready instead.
3. Simulators: an iPhone 17 Pro (`xcrun simctl list devices available | grep "iPhone 17 Pro"`), never the one
   Abu has booted. Every `xcodebuild` and `simctl` call needs
   `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
4. Bash in the toolchain is 3.2: no associative arrays, an empty array under `set -u` is unbound.

## 3. The toolchain

| File (in `~/Downloads/Islam/`) | What it does |
|---|---|
| `sync_from_islam.sh <quran\|adhan> [--apply] [--update-base]` | the sync: 3-way merge per file (BASE = Al-Islam at `<sibling>/.sync-base`, OURS = the sibling, THEIRS = Al-Islam's **working tree**), then four checks |
| `sync-manifests/<app>.conf` | `SYNC` prefixes, `EXCLUDE` (never synced), `PER_APP` (never merged), `FLAG` / `FLAG_SKIP`, `ROOT_SKIP` |
| `sync-report-<app>.txt` | the report every run writes; read it, do not trust a summary of an old one |
| `sync_renames.py` | finds files Al-Islam moved since BASE, so a move ports as one file instead of NEW plus DELETE |
| `sync_build_flags.py` | the sibling's project-level compile conditions; `--apply` writes them |
| `check_feature_isolation.py` | the LEAK check (section 4) |
| `check_root_wiring.py` | compares the per-app roots' modifiers with Al-Islam's |
| `register_in_pbxproj.py <sibling> <paths...>` | registers NEW files in the sibling's project (the report prints the exact command); `--move` re-parents moved ones |
| `membership_diff.py <sibling>` | lists files whose target membership differs from Al-Islam's (a widget file also needs the Widget target) |

Report labels: `MOVE`, `NEW`, `UPDATE` (only Al-Islam changed it), `MERGE` (both changed, merged cleanly),
`CONFLICT` (merged with `<<<<<<<` markers left in), `BIN-CONFL` (binary changed on both sides: the sibling's
copy is kept), `DELETE`, `PER-APP`, `FLAG-ADD` / `FLAG-ERROR`, `LEAK`, `ROOT-WARN` / `ROOT-ERROR`. The script
exits 1 while any LEAK, FLAG-ERROR or ROOT-ERROR remains, even after a successful `--apply`.

**`--update-base` only advances `.sync-base` at the end of an `--apply` run.** Never run `--apply` twice
against the same base: the second run 3-way merges your hand-resolved conflict files again and can write
fresh conflict markers over them. Advance the base by hand once a sibling is green (section 5, step 10).

## 4. What a LEAK is

A line that is new in Al-Islam since BASE, that the sibling compiles (its `#if` evaluates true there), and
that names a symbol the sibling will not have, because the symbol lives only in a file the sibling never
receives (`EXCLUDE`, e.g. `iPhone/Adhan` for Al-Quran) or only inside a block it compiles out. Each LEAK
is a compile error waiting to happen. There are three ways to fix one, best first:

1. **Do not send the file at all.** When a NEW file is wholly another app's feature, add
   `EXCLUDE=<path>` to the sibling's manifest and re-run the dry run. One line clears every LEAK in it.
2. **Gate the line in Al-Islam** with the feature's flag (`#if HAS_ADHAN`, `#if HAS_QURAN`,
   `#if HAS_HADITH`, `#if HAS_ICLOUD_BACKUP`, `#if HAS_WEATHER`). Al-Islam defines every flag, so its
   behaviour does not change, the shared file stays identical in all three apps, and future syncs merge
   cleanly. Rebuild Al-Islam after gating.
3. **Strip it in the sibling** only when 1 and 2 do not fit; every later sync then has to merge around it.

Known false positive: a `.sheet(...)` modifier read as a local named `sheet` declared inside a block the
sibling compiles out (`let sheet` in `CarPlayScene.swift`, and `WidgetGalleryView.swift:357`). The report
says "`sheet` (declared in ..., inside a block this app compiles out)". Those lines compile fine; skip them,
or teach `check_feature_isolation.py` that a name after a `.` is a member, not that local.

## 5. The procedure

0. **Before anything, ask Abu two things** (his call, not yours):
   - Commit Al-Islam first? THEIRS is Al-Islam's working tree, so uncommitted Al-Islam work ports too, but
     `.sync-base` records only a commit. A clean Al-Islam makes the recorded base honest.
   - Commit each sibling first? Both carry uncommitted work from 2026-10-13 (privacy manifests, store copy,
     project edits) and Abu's own root edits. A clean start makes the sync one reviewable diff.
1. **Fresh dry run of both:** `cd ~/Downloads/Islam && ./sync_from_islam.sh quran; ./sync_from_islam.sh adhan`.
   Compare against section 6; Al-Islam keeps moving, so the numbers will have drifted.
2. **Shrink the LEAK list before applying.** Read every LEAK cluster (section 6). For each NEW file that
   belongs to another app, add an `EXCLUDE`; for shared lines, gate them in Al-Islam. Re-run the dry run until
   what remains is small and understood. This is cheap and reversible: nothing in a sibling has changed yet.
3. **Apply one sibling at a time**, only with Abu's go-ahead: `./sync_from_islam.sh quran --apply` (no
   `--update-base`). Write down Al-Islam's `git rev-parse HEAD` at that moment; step 10 needs it. Moves and
   their project references are applied by the script.
4. **Resolve every conflict:** `grep -rln '^<<<<<<<' Al-Quran-iOS --include='*.swift' --include='*.plist' --include='*.json'`.
   Take Al-Islam's logic; keep the sibling's own name, strings and stripped features; never bring back a
   feature the sibling withholds. `BIN-CONFL HadithQuotes.json.deflate`: the sibling kept its copy; decide
   whether Al-Islam's newer pack should replace it (it feeds `Islam/Daily/HadithQuote.swift`, the daily quote,
   not the Hadith tab).
5. **Register the NEW files** with the `register_in_pbxproj.py` command printed under "next steps" in the
   report, then `./membership_diff.py Al-Quran-iOS`. Widget files need the Widget target;
   `Widget/Quran/ResumeListeningIntent.swift` needs the app AND the widget; Control Center control stubs must
   live in a widget-only file.
6. **Fix the remaining LEAKs** (section 4), plus any FLAG-ERROR. `FLAG-ADD` lines are applied by `--apply`
   (Al-Quran has never defined HAS_QURAN until this lands).
7. **ROOT-WARN:** `.adhanBannerHost(...)` is missing from both siblings' iPhone roots. Read
   `iPhone/Helpers/UI/BannerWindow.swift`: it is one window for the adhan banner AND achievement banners, so
   a sibling that shows either needs it. Otherwise add `ROOT_SKIP=adhanBannerHost`. Same for the watch
   root's `.environment(...)`.
8. **DELETE and PER-APP:** the `Palestine Poster` deletes are inside an `.xcassets`, so there is no project
   reference to remove. PER-APP entitlements stay as they are (the siblings have no iCloud, WeatherKit or
   CarPlay keys). The siblings got their own privacy manifests by hand on 2026-10-13; touch them only if
   the sync brings in a new required-reason API (UserDefaults, file timestamps, system boot time, disk
   space, active keyboards).
9. **Build until green**, from the sibling's folder:
   ```
   export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
   xcodebuild -project Al-Quran.xcodeproj -scheme iPhone -configuration Release \
     -destination 'generic/platform=iOS' -derivedDataPath <scratchpad>/dd-quran CODE_SIGNING_ALLOWED=NO build
   xcodebuild -project Al-Quran.xcodeproj -scheme iPhone -configuration Debug \
     -destination 'generic/platform=iOS Simulator' -derivedDataPath <scratchpad>/dd-quran-sim build
   ```
   (`Al-Adhan.xcodeproj` for Al-Adhan; `xcodebuild -list` shows its schemes, and the Watch scheme builds the
   watch app.) Then install on the iPhone 17 Pro simulator, launch, and screenshot every tab. Watch for
   features that compiled but are not wired: a root missing `.appearanceEnvironment()` shows a stale accent.
10. **Advance the base by hand** once the sibling is green and Abu has looked:
    `echo <the Al-Islam HEAD from step 3> > Al-Quran-iOS/.sync-base`. Then repeat steps 3 to 10 for Al-Adhan.
11. **Check the store copy.** The siblings' `Docs/Whats New.md`, `Promotional Text.md` and
    `App Store Description.md` (rewritten 2026-10-13) describe features that only arrive with this sync.
    Al-Quran claims Test Mode, the Revision plan, Word Study, Simple Mode and recitation that plays to the
    end of the juz or the Quran; Al-Adhan claims the 3D moon, the skyline, "Did you pray?" from a prayer
    notification, Simple Mode and the accuracy work. Confirm each one landed and works, or tell Abu which
    line to cut.

## 6. Where things stood on 2026-10-13 (dry run, base `60cd3c0`, 2026-09-16, 24 commits behind)

| | Al-Quran | Al-Adhan |
|---|---:|---:|
| Moved | 111 | 84 |
| New | 62 | 56 |
| Updated | 99 | 70 |
| Merged cleanly | 11 | 13 |
| Conflicts (16 of Al-Quran's and most of Al-Adhan's are moved files) | 24 | 26 |
| Binary conflicts | 1 | 1 |
| Per-app changes to port by hand | 6 | 7 |
| **LEAKs** | **87** | **112** |

Conflicts outside the moves, both siblings: `Settings/SettingsView.swift` (11 and 12 hunks),
`Settings/SettingsSearch.swift` (9 and 13), `AppLifecycle.swift`, `LaunchScreen.swift`, `AppDelegate.swift`,
`Widget/Widgets.swift`, `Resources/Info-Main.plist`, `Resources/Data/Hadith/manifest.json`; Al-Adhan also
`Islam/IslamView.swift` (7).

**Al-Quran's LEAKs are prayer code reaching Quran-only builds.** 60 of 87 name symbols from
`Settings/Model/SettingsAdhan.swift`. By file: `Settings/Pages/NaggingModeView.swift` 24 (a NEW, prayer-only
page: the first `EXCLUDE` candidate), `Settings/Model/Settings.swift` 18, `AppDelegate.swift` 14 (prayer
notification actions, the foreground adhan player, the fasting Live Activity), `Settings/SettingsSearch.swift` 7,
`Settings/Pages/HelpDoors.swift` 6, `Settings/SettingsView.swift` 4, then 1 to 3 each in `DailyReminders`,
`AppLifecycle`, `TasbihView`, `DateView`, `Widget/ControlWidgets.swift` (`PrayersProvider`), `SettingsQuran`,
`QuranPlayer`.

**Al-Adhan's LEAKs are Quran code reaching prayer-only builds,** and 16 of the 112 are the `sheet` false
positive (section 4), so about 96 are real. Sources: `QuranData` 14, `QuranPlayer` 13, `SettingsQuran` 10,
`ShareAyah` 8, `SunnahReminders` 7, tajweed 8. By file (false positives included):
`Helpers/System/StressWalker.swift` 22 (the DEBUG-only crash walker: exclude it from the siblings or gate its
Quran steps), `Settings/Model/Settings.swift` 11, `Islam/Names/ShareName.swift` 10, `Settings/SettingsView.swift` 9,
`AppLifecycle.swift` 8, `HelpDoors` 6, `Tajweed/TajweedCourse` 6, `Daily/DailyReminders` 6,
`Settings/System/ControlIntents.swift` 4, `Tajweed/TajweedView` 4, `Helpers/ViewExtensions` 4, and a long tail
of 1 to 3.

Both: `HAS_TIPS` (and Al-Quran's `HAS_QURAN`, Al-Adhan's `HAS_ADHAN`) are pending `FLAG-ADD`s; two
`ROOT-WARN`s each (step 7); 0 FLAG-ERRORs and 0 ROOT-ERRORs.

## 7. Traps from earlier syncs

- **Moves.** Al-Islam's 2026-10-07 subfolder move would have made ~150 files NEW beside the siblings' old
  copies; the sync has been move-aware since 2026-10-11. If a moved file shows up as NEW plus DELETE, the
  rename was not detected: fix `sync_renames.py`, do not copy by hand.
- **Shared files compile in several targets.** In Al-Islam, `Settings.swift`, `SettingsQuran.swift` and
  `QuranData.swift` compile in four targets (app, watch, widget, complication). A symbol they use must exist in
  every target that compiles them, in each sibling too.
- **iOS 15.** Anything Al-Islam calls without an availability check because its floor is 16 fails to build in
  a sibling. Add the `#available` check in Al-Islam, not a sibling-only patch.
- **iCloud Backup, Hadith and weather are Al-Islam only.** Their files are excluded and their flags are
  `FLAG_SKIP`; a LEAK naming `CloudBackupManager`, a hadith model or `SkyWeather` means a missing gate.
- **Exit 1 is normal** until the last LEAK is gone; read the report, not the exit code.

## 8. Done means

Both siblings build for device (Release) and simulator with 0 errors, launch on the iPhone 17 Pro simulator
with every tab working, `sync-report-<app>.txt` shows 0 LEAKs, 0 FLAG-ERRORs and 0 ROOT-ERRORs, `.sync-base`
is advanced, and the store copy matches what shipped. Then tell Abu what changed in each repo, uncommitted.
