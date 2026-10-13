# QA scripts

The tools behind the 2026-09-28 quality audit (`Docs/Quality Guide.md`, Appendix A), kept so any session
can rerun the baseline. Every script writes under `QA_OUT` (a scratch folder you choose) and targets the
iPhone 17 Pro simulator on the newest runtime (`device.sh`; `QA_UDID` overrides it).

    export QA_OUT=/tmp/al-islam-qa
    Scripts/qa/baseline.sh            # build, sweep, analyze, audits, idle counters, launch stopwatch

One at a time:

| Script | What it does |
| --- | --- |
| `build.sh <tag> [Debug\|Release]` | builds the iPhone scheme, lists errors and Swift warnings, installs a Debug build |
| `sweep.sh <udid> screens.txt <tag>` | one cold launch per screen: full log, screenshot, alive and crash status |
| `analyze.py <tag>` | error and fault lines per screen from a sweep, known noise filtered |
| `audits.sh <udid>` | the in-app DEBUG audits (packs, alignment, rollover, verifiers) |
| `idle.sh <udid>` | 20 s of publish and render counters per screen; the bar is zero publish lines |
| `launch.sh <udid> [runs]` | `-launchTiming` medians per start screen |
| `tripwire.sh <udid>` | lldb backtrace of the first appearance-default read |
| `tsan.sh <udid>` | the Thread Sanitizer flows (needs a TSan build in `$QA_OUT/dd-tsan`) |
| `mac-sweep.sh <tag> [screens.txt]` | the sweep on "My Mac (Designed for iPad)", one hosted `HostSmokeTests` run per screen (held at `_dyld_start` on this Mac since 2026-09-29, see stress-mac.sh) |
| `stress-sim.sh <udid> <tag> <steps> <seed> [args]` | one in-process stress walk (`-stressWalk`, StressWalker.swift) on a simulator: crash reports, HANG markers, the trail |
| `stress-mac.sh <tag> <steps\|restore> <seed> [args]` | the same walk on "My Mac (Designed for iPad)", launched by Xcode through AppleScript (`write_mac_scheme.py` + `xcode-run-mac.scpt`); `restore` puts the container back after a crashed walk |
| `stress-mac-seeds.sh <steps> <seed...>` | consecutive Mac walks, one result line each, then the restore pass |
| `stress-screens.sh <sim\|mac> <udid\|-> <tag> <steps>` | one walk per `screens.txt` line, started with that screen's arguments ("start deep"); on the Mac the lines that write defaults are skipped |
| `ipsreport.py [report.ips ...]` | one crash report in a few lines: where it ran, the message, the crashing thread, StressWalker on a stack or not |

`screens.txt` lines are `name|seconds|launch arguments`; a line starting with `!` runs a shell command with
the app terminated. Set state with launch arguments (`-seedBool`, `-seedString`, `-displayQiraah ""`): on the
iOS 27 runtime `simctl spawn defaults write <bundle id>` writes a domain the app never reads.

`sweep.sh` options: `QA_EXTRA_ARGS` is appended to every launch, and `QA_START_AT=<name>` resumes a list. It
boots the device again and retries a screen once when the simulator went down under it (another session on
this Mac shuts every simulator down now and then). On a fresh simulator seed the first launch off once
(`-seedBool THEfirstLaunch=0`) and grant location, or every screen lands on the splash.

The test targets (Quality Guide T7): `xcodebuild test -scheme iPhone -destination <sim> -only-testing:UnitTests`
for the 81 unit tests; `-only-testing:UITests` for the XCUITest sweep and the seeded monkey, with
`TEST_RUNNER_QA_SCREENS="$(cat Scripts/qa/screens.txt)"`, `TEST_RUNNER_QA_ORIENTATION=landscape` (the app's
own `-landscape` no longer rotates on iPadOS 27) and `TEST_RUNNER_QA_MONKEY_STEPS=150` on the command line.

The stress walk (2026-10-12): `-stressWalk <steps> -stressSeed <n>` makes the app drive itself (accessibility
activations, double taps, pops, tabs, scrolls, Mac window resizes, settings storms, deep links, playback,
hostile text, second windows), logging `STRESS <step> <action> | <screen>`; it snapshots and restores the
container around the walk, so a Mac run leaves the installed app's data as it found it. Add the two arguments
to the Run scheme to watch a walk in Xcode. On this Mac only Xcode's launcher gets a development build past
`_dyld_start`; `stress-mac.sh` strips WeatherKit from the entitlements for the build and restores the file.
The step-by-step procedure for a Mac sweep (checks, batches, how to judge a crash or a HANG, the traps) is
`docs/Mac Crash Sweep Guide.md`.
