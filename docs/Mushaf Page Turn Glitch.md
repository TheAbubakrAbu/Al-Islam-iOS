# Mushaf page turns: resistance and the black panel

**Status: OPEN.** One fix was tried on 2026-09-17 and made things worse; it was reverted. The
diagnosis below is measured and holds. The fix is not written yet.

**App:** Al-Islam (`Al-Islam-iOS`). Al-Quran carries the same reader and the same defect, but fix
and verify in Al-Islam first, then port with `./sync_from_islam.sh quran --apply`.

**File:** [`iPhone/Quran/MushafReader.swift`](../iPhone/Quran/MushafReader.swift)

---

## The report

> "Moving pages sometimes it glitches a little bit, like sometimes there's a little resistance, or
> sometimes there is a black that comes from the left and takes it over."

Two symptoms, one cause. Both happen while swiping through the page reader (mushaf mode), not in the
list reader.

---

## The cause

`SurahPageReader` does not hand all 604 pages to its `TabView`. It mounts a **window** of them, and
the window moves as you read.

| Thing | Where | What it is |
|---|---|---|
| `windowRadius` | line 354 | `4`: the window is the selected page ± 4, so 9 pages |
| `windowCentre` | line 347 | the page the window is centred on |
| `windowAnchors` | line 358 | extra pages pinned during an animated far turn |
| `pageWindow(count:)` | line 525 | builds the mounted index set from those three |
| `TabView` / `ForEach` | lines 566, 573 | mounts exactly `pageWindow(...)`, tagged by real page index |
| `recentreWindow(on:)` | line 504 | moves `windowCentre` to follow the selection |
| called from | line 763 | `.onChange(of: pageIndex)` |

`recentreWindow` has two paths, and the **first one is the bug**:

```swift
if windowCentre < 0 || abs(index - windowCentre) >= windowRadius - 1 {
    windowCentre = index          // IMMEDIATE, inside the animated selection write
    return
}
// otherwise: deferred 0.6 s, after the selection has held still
```

`windowRadius - 1` is 3, so on a run of swipes this fires on **every third turn**, synchronously,
while `UIPageViewController` has a transition in flight. Re-centring does not only add pages ahead,
it **removes** the ones now out of range behind.

Measured on a 7-swipe run (this is the whole bug in two lines):

```
idx=5, centre=2   mounted [0...6] -> [1...9]     page 0 destroyed mid-animation
idx=8, centre=5   mounted [1...9] -> [4...12]    pages 1, 2, 3 destroyed mid-animation
```

- **Resistance** = the pager stumbling when its child set changes underneath a live transition.
- **Black panel from the leading edge** = the slot it was animating toward no longer has a page.

There is a second, smaller instance of the same shape: `turnPage(to:in:)` (line 913) pins
`windowAnchors` for a far jump and releases them on a **0.8 s timer** (line 939), which can also land
mid-animation if the reader is still moving.

---

## What was already tried, and why it failed

**Attempt: let the window only ever GROW during a swipe run.** `windowReachMin/Max` widened to cover
`index ± windowRadius` on every selection change, were unioned into `pageWindow`, and collapsed back
to a plain ring in the existing 0.6 s settle block.

The trace looked perfect: monotonic growth `[0..6] → [0..7] → [0..8] → [0..9] → [0..10]`, collapsing
to 9 once settled, far jumps and backward swipes fine. Both apps built.

**On device it was worse: laggy, and pages stopped halfway between two pages.**

The reason is the thing to carry into any new attempt. **A mushaf page is expensive**: each one is a
full Arabic TextKit layout. Holding 11-13 of them mounted through a run costs far more than the
teardown it was avoiding. The `pageWindow` doc comment (lines 517-524) records why the radius is 4 at all:
handing the `TabView` all 604 pages cost **1,200-2,400 body evaluations per second** while idle and
~900 ms of main thread to realize. Anything that raises the mounted count fights that measurement.

**So: the fix must not increase how many pages are mounted at once.**

---

## Approaches worth trying

None of these has been attempted. Rough order of promise:

1. **Re-centre by one page at a time.** Instead of jumping `windowCentre` to `index`, move it one
   step toward `index`. At most one child is dropped per turn instead of three, and the mounted count
   never changes. Smallest diff, lowest risk; it may reduce the glitch to something invisible even if
   it does not remove the drop entirely.

2. **Defer every re-centre to the end of the transition.** Correct in principle: never touch the
   child set while a turn is animating. The obstacle is that a paged SwiftUI `TabView` exposes no
   "transition ended" hook, so this needs the underlying `UIPageViewController` delegate
   (`didFinishAnimating`), reached through a `UIViewControllerRepresentable` or an introspection
   shim. Bigger change, but it fixes the class of bug rather than one instance, and it would also
   let `turnPage`'s 0.8 s anchor release become event-driven instead of a timer.

3. **Make a dropped page cheap rather than absent.** Keep the radius, but have a page that leaves the
   window render a cached snapshot image instead of a live composed view. The pager then always has
   something to show. Largest change; only worth it if 1 and 2 both fail.

Whatever you pick: **the mounted count must stay at ~9, and the child set must not shrink while
`pageIndex` is moving.**

---

## How to reproduce and verify

There is **no tap or swipe injection** on this machine (`simctl` cannot send touches, `idb` is not
installed). Page turns are driven by a DEBUG launch argument instead.

Build and install:

```bash
cd ~/Downloads/Islam/Al-Islam-iOS
UDID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
xcodebuild -scheme iPhone -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath build/dd build
xcrun simctl install "$UDID" build/dd/Build/Products/Debug-iphonesimulator/iPhone.app
```

Drive a run of swipes (`+1@3` means "turn one page forward, 3 s after the reader appears"):

```bash
xcrun simctl launch --console-pty "$UDID" com.Quran.Elmallah.Islamic-Pillars \
  -launchTabQuran -quranPageMode -lastRead "2:11" \
  -pageTurnScript "+1@3,+1@3.5,+1@4.0,+1@4.5,+1@5.0,+1@5.5,+1@6.0"
```

`-pageTurnScript` also takes `=N@t` (jump to page index N, the picker's path), `-1@t` (backward),
`picker@t` / `pick=N@t` / `confirm@t` (the page wheel), `collapse@t` (fold the bottom chrome).

**To see the window churn**, add a temporary probe inside `pageWindow(count:)` just before
`return indices.sorted()`:

```swift
#if DEBUG
if ProcessInfo.processInfo.arguments.contains("-windowTrace") {
    print("WINDOWTRACE mounted=\(indices.sorted()) idx=\(pageIndex)")
}
#endif
```

Run with `-windowTrace` and watch for a line where the set **loses** an index. Remove the probe
before committing.

### The trap

**The harness never reproduced the visual glitch.** It only ever showed the window churn. A trace
that "looks right" proves nothing here: the reverted attempt had a perfect trace and was worse in
the hand. **Verify on a device or the simulator by actually swiping** before believing a fix, and
watch for the two things the previous attempt caused: general lag, and a page coming to rest
halfway between two pages.

---

## Related

- `Docs/Mushaf Justification.md`: how a page's text is composed and fitted, and why it is expensive.
- The same window teardown killed an open word card; that one was fixed separately by moving the
  sheet off the page and onto `SurahView` (search `onRequestSheet`). Worth reading as precedent: the
  cure there was to stop depending on the page staying mounted, not to keep it mounted.
