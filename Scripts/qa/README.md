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
| `mac-sweep.sh <tag> [screens.txt]` | the sweep on "My Mac (Designed for iPad)", one hosted `HostSmokeTests` run per screen |

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
