# Mushaf page turns: resistance, the black panel, the blank every third page

**Status: FIXED on 2026-09-20 for every run of swipes that lets the pager land between swipes,
which is how a mushaf is read. Reduced, not removed, for a run so fast that a finger is down again
before the previous page has landed; that residual case is explained at the bottom.**

Measured on the iPhone 17 Pro simulator with real swipes (idb) and a frame scan of the screen recording
(recipe at the bottom):

| Run (nine or eight forward swipes from page 3) | Old build | New build |
|---|---|---|
| Reading pace, one swipe every 0.9 s | not recorded (the report was at a brisker pace) | **0 blank frames** in 257 |
| Brisk, one swipe every 0.65 s (the pager still lands for a beat between swipes) | not recorded | **0 blank frames** in 231; every re-centre waited 0.35-0.43 s for that beat |
| Flipping, one swipe every 0.55 s (finger down before the previous slide has landed) | **3 blank events** (frames 90, 140-141, 189: every third swipe, exactly the report) | 2 events, both at the no-slack fallback, see "The residual case" |

**App:** Al-Islam (`Al-Islam-iOS`). Al-Quran carries the same reader and the same defect; port with
`./sync_from_islam.sh quran --apply` once this is committed here.

**File:** [`iPhone/Quran/MushafReader.swift`](../iPhone/Quran/MushafReader.swift):
`SurahPageReader.recentreWindow`, `whenPagerRests`, `MushafPagerProbe`, `MushafPagerProbeView`.

---

## The report

> "Moving pages sometimes it glitches a little bit, like sometimes there's a little resistance, or
> sometimes there is a black that comes from the left and takes it over."

> "every 3 pages there's a weird blank thing on the left or right depending which way I swipe."

All in the page reader (mushaf mode), never in the list reader.

---

## The cause, now measured

`SurahPageReader` does not hand all 604 pages to its `TabView`. It mounts a **window** of them
(`windowRadius = 4`, nine pages) and the window follows the selection (`windowCentre`,
`recentreWindow`, `pageWindow(count:)`). On iOS 26 the pager behind a paged `TabView` is SwiftUI's
`PagingCollectionView` (a paging `UICollectionView`), found by the probe below.

**Any change to the pager's children while a slide is running makes the page being LEFT vanish for
about two frames and reappear.** The pager reloads its children for the change; the outgoing page's
cell is dropped and rebuilt while it is still on screen. That is the blank panel on the side the swipe
heads towards, and the hitch that reads as resistance. It does not matter whether pages were removed or
only added: a grow-only window was tried on 2026-09-20 and blanked exactly the same (three flagged
frames in the brisk run), which also explains why the 2026-09-17 grow-only attempt felt worse rather
than better.

**Why every third page.** The old `recentreWindow` moved the window *immediately* once the selection was
three pages from the centre (`windowRadius - 1`), inside the selection write. The pager writes the
selection when the finger lifts, while its slide is still running, so every third swipe changed the
children mid-slide. The frame scan of the old build shows the blank at exactly that cadence.

**Why the first word card after a page change vanished** (the other half of this story, in
`Docs/Page Mode Sheet Ownership.md`): the *deferred* re-centre, 0.6 s after a swipe, rebuilt the
children under a sheet the page itself owned.

---

## The fix

**Every change to the mounted set waits for the pager to rest.** Rest is read off the pager's own scroll
view: no finger down, and the content sitting on a page boundary. A slide that has already arrived on
its boundary counts as rest even if the scroll view still flags a deceleration, because the outgoing
page is off screen by then and a reload is invisible; in a brisk run that instant is the only rest there
is. Reloads at rest never blanked anything in any recording (the `C:` column of the frame scan, the
visible page, was never flagged).

`recentreWindow(on:)`, by how far the selection has drifted from the centre:

| Drift | What happens |
|---|---|
| `>= recentreLead` (2) | re-centre at the next rest, no settle beat (`whenPagerRests`) |
| `>= windowRadius` (4, no slack) | re-centre NOW, busy or not: the next swipe would otherwise find no page mounted |
| below the lead | the old 0.6 s settle, then re-centre at rest |

One refinement was tried and dropped: with one page of slack left, reloading at the *tail* of the
current slide (outgoing page within 12% of a page of leaving the screen) if rest never came. In every
recording the pager either rested (0.65 s cadence and slower) or never reached the tail before the next
touch halted it (0.55 s), so the path never fired; unverified code in this path is worth less than the
simplicity. The idea is recorded here in case a device recording ever shows a cadence in between.

`turnPage`'s far-jump anchors are released at rest too. `whenPagerRests` polls the probe at frame
rate; its 2 s timeout is a safety net for a probe that misreads the pager, not the answer to a run that
never rests (that is the no-slack row; a 1 s timeout was measured to reload mid-slide every other page
at the brisk cadence, the fallback alone every fourth).

**`MushafPagerProbe`** finds the pager from `MushafPagerProbeView`, an inert `UIViewRepresentable`
planted as the TabView's `.background`: on `didMoveToWindow` it walks up its ancestors and searches each
subtree, nearest first, for a paging `UIScrollView` (`isPagingEnabled`, or a class name containing
`Queuing` for the older `UIPageViewController` implementation), skipping the page's own
`PageZoomScrollView`. If it never finds one, `isTurning` is false and the window logic behaves exactly
as before the probe existed.

**Mounted count is unchanged: nine.** The 2026-09-17 attempt raised it to 11-13 and was worse; that
number matters (the doc comment on `pageWindow` has the 604-page measurement).

---

## The residual case

A run so fast that the finger is down again before the previous page has landed never rests (the touch
halts the deceleration mid-page). The window then cannot follow the selection without a change
mid-slide, and the no-slack row makes that change on the fourth page. It blanks the outgoing page for
two frames, every fourth page instead of every third, and the reader keeps turning (the 0.55 s
recording shows the slide completing after each blank). Nothing cheaper exists for it: growing the
window blanks too, and a bigger window costs on every publish. If it ever matters more than it does,
the lever is `windowRadius`, not the timing. Note that idb's swipe (a 0.2 s constant-speed drag,
released slowly) decelerates longer than a human flick, so a real thumb at the same cadence probably
rests more often than this harness does.

---

## How to reproduce and verify

`simctl` cannot inject touches, but idb can (installed: `~/Library/Python/3.9/bin/idb`, companion at
`/opt/homebrew/bin/idb_companion`). One forward turn is a left-to-right swipe (page 1 sits at the far
right); start it at x = 80, not 40, or the navigation stack's edge-pan eats it.

```bash
UDID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
BID=com.Quran.Elmallah.Islamic-Pillars
IDB=~/Library/Python/3.9/bin/idb
xcrun simctl launch $UDID $BID -launchTabQuran -quranPageMode -lastRead 2:11 -mushafPageLanguage arabic \
  -skipNotificationPrompt -travelingMode 0 -windowTrace
sleep 7
xcrun simctl io $UDID recordVideo --codec h264 --force run.mov &
sleep 1.5
# nine swipes 0.55 s apart; each idb call takes ~0.45 s to start, so fire them from background subshells
for i in $(seq 1 9); do ( sleep $(( (i - 1) * 0.55 )); $IDB ui swipe --udid $UDID --duration 0.2 80 450 340 450 ) & done
sleep 8; kill -INT %1
ffmpeg -i run.mov -vf fps=30 frames/f%04d.png
```

Then scan the frames: crop the page area (rows 13% to 57.5% of the 1206x2622 capture), and flag any
frame whose left 40%, centre 40% or right 40% has an ink fraction (pixels darker than 110) under
0.3%. A slide always shows text on both sides; a flagged `L` or `R` is the outgoing page missing, a
flagged `C` would be the visible page missing. Look at the flagged frames and their neighbours.

`-windowTrace` (DEBUG) logs, via NSLog, the mounted window on every change, the pager class the probe
found, every deferred window change with how long it waited, and every page cell the pager creates:

```bash
xcrun simctl spawn $UDID log stream --predicate 'eventMessage CONTAINS "WINDOWTRACE"' --style compact
```

A healthy reading-pace run shows `apply ... waited=0.00s` (the pager was already at rest when the
settle beat ended) or a short wait, one `mounted=` line per re-centre, and one or two `makeUIView` lines
after each (the new far page, and one rebuilt neighbour), about 30-40 ms of work at rest.

### The trap, still true

The old `-pageTurnScript` harness (programmatic animated turns) never showed the blank: the selection
write it makes is not a finger lift mid-slide. Only real swipes reproduce it, and only the frame scan
catches a two-frame blank reliably. Do not trust a clean trace; trust the flagged-frame count.

---

## 2026-09-26: the gate was off on every iPad and Mac

Abu: "Page scrolling on mac/ipad is laggy and not the greatest and sometimes it jumps back."

**Cause.** `MushafPagerProbe.locate` took the first paging scroll view it found walking up from the probe.
On iPadOS and the Mac (Designed for iPad) the probe can land before the pager's subtree exists, the walk
climbs to the floating tab bar, and its `_UIFloatingTabBarCollectionView` is a paging scroll view:
`-windowTrace` printed `pager=_UIFloatingTabBarCollectionView`. That tab bar never turns, so `isTurning`
was always false and every re-centre ran mid-slide, the exact glitch this document fixed on the iPhone.
Measured on the iPad Pro 13 simulator (8 swipes, 0.7 s apart), with the gate forced off to reproduce it:
seven frames of 140-152 ms, and the reload re-based the offset mid-deceleration so the pager landed a
page off (8 swipes moved 15 pages). **Fix:** only a scroll view laid over the probe's own rect counts
(`MushafPagerProbe.covers`), and the probe retries from its `layoutSubviews`. After: the trace names
SwiftUI's `PagingCollectionView`, re-centres wait 0.35-0.5 s, 8 swipes move 8 pages.

**Two more costs, found with Time Profiler** (`xcrun xctrace record --template 'Time Profiler' --device
<udid> --attach <pid>` works on the simulator once `--device` is given):

- Every freshly mounted page was typeset twice. `updateUIView` set the text into an endless container,
  then `PageZoomScrollView.layoutSubviews` gave the text view its frame, UIKit cut the container to the
  frame's height, and the whole layout (OpenType shaping included) ran again: 241 + 213 ms over 8 swipes.
  `MushafPageTextView` now takes `height` and gives the text view its final box before its text. After:
  one pass, 243 ms total for the same run.
- The last-read settle (0.8 s after a turn) published `ReadingState` five times (three `@AppStorage`
  writes plus echoes), each re-running the Quran tab root, the pushed reader and every mounted page. At a
  one-second flipping pace it landed mid-drag: a 137 ms frame, during which the finger's remaining travel
  applied at once and UIKit paged TWO spreads. `ReadingState` is plain defaults now, `record` publishes once.

Spread run after all three (8 swipes, 0.8 s apart): 8 spreads, zero frames over 50 ms (was 9, worst 137).

`-pagerMotion` (DEBUG) logs one `PAGERMOTION` line per display frame while the pager moves: offset in
pages, delta, the frame's real duration, finger and deceleration flags. A hitch reads as a long `dt`; a
mid-slide reload as a jump in `off` with `dec=1`. A jump of exactly +2.000 with `trk=0 dec=0` is a
re-centre at rest re-basing the offset, which is invisible.

---

## 2026-09-27: the mid-slide reload, measured with the book open

Abu: "there was a pretty annoying bug with scrolling on 2 pages make sure that is fixed."

**What a mid-slide reload does to SwiftUI's paging collection view.** Recorded on the iPhone 17 Pro
simulator in landscape (two-page spread, band 750x111), eight idb swipes 0.6 s apart, `-windowTrace
-pagerMotion` and a 30 fps frame scan:

- The no-slack fallback (drift = radius) reloaded the window with the pager at offset 0.518 of a cell,
  decelerating. The collection view kept its content offset over the NEW cells and re-laid them out half a
  cell off: the pager came to rest showing the right page of one spread beside the left page of the next -
  page 19 on the left, page 18 on the right. Reading order looks plausible, the pairing is wrong, and the
  spine hairline sat at the screen's edge. The next swipe dropped the far cell and blanked the right half
  of the screen for the whole slide (frames 176-178 of the recording).
- A second recording at the same cadence, with a 0.5 s near-edge timeout added: the timeout expired with
  the finger down (offset 0.686, `trk=1`), the reload re-based the offset by +0.27 of a cell, and the
  collection view reported the cell under the old offset as the selection - `select leading=20` from
  `idx=12`, four spreads ahead of the swipe. In portrait the same reload jumped three pages (8 -> 11).
  This is Abu's "sometimes it jumps back" from 2026-09-26 in its other direction.
- Why the rest never came: a landing deceleration creeps up on its boundary (4.6 pt out 34 ms before the
  next touch), and the probe counted "rest" only inside 0.5 pt. Each swipe at that cadence lands on the
  previous one's tail.

**Fix (in `SurahPageReader.recentreWindow` / `whenPagerRests` / `MushafPagerProbe`).**

- The window moves ONLY while the pager rests. The 0.6 s settle path (a reload after every single swipe,
  each rebuilding the visible cell) and the no-slack fallback are gone; a drift of `recentreLead` or more
  re-centres at the next rest, a smaller drift is left alone.
- The 2 s timeout in `whenPagerRests` covers a probe misread only (content off a boundary with nothing
  moving it): it never overrides `isTracking`/`isDragging`/`isDecelerating` (`MushafPagerProbe.isMoving`),
  up to a 20 s hard cap that only a stuck flag could reach.
- Rest tolerance 2 pt instead of 0.5 (`isTurning`): a page 2 pt from its boundary is in place to the eye.
- Rings: 14 pages (seven spreads) to either side with the book open, 6 pages on a phone. In a run of
  swipes that never rests the ring is all the reach there is: past its last mounted cell the swipe
  bounces, the pager rests, the window catches up, the next swipe turns. Measured at a 0.6 s cadence
  (each swipe landing on the previous deceleration) the five-spread ring ran out on the sixth swipe; the
  seven-spread ring covers a longer run, and a real thumb pauses at the bounce.

**After (same harness, rest-only build):** 0.6 s landscape 222 frames, 0.5 s landscape 202 frames,
0.6 s portrait 222 frames, 0.45 s portrait 190 frames: zero blank frames in all four, every selection one
spread (one page) from the last, no jumps. Rotation round trip (`-rotateScript "l@5,p@12,l@19"`) with a
swipe in each state: whole spreads and whole pages every time.

**Cell rebuilds are real, and reuse is not available.** On every window change the collection view rebuilds
the visible cell and the one in the direction of travel (`makeUIView` twice per page in a spread, about
15-20 ms each on the simulator in Debug), and the NEW cell's `makeUIView` runs before the OLD cell's
`dismantleUIView`, so a pool of retired text views cannot hand the typeset view across. Fewer reloads
(no settle path) is the lever that was taken.

**Landscape layout, same session.** The phone's landscape band was 111 pt (two-line title pill, stacked
bars); the title is one line in a compact height, the legend / search row sits beside the footer on any
reader 640 pt or wider (`wideBottomBars`, footer at least 392 pt so its meters never truncate), the find bar
is one row there (and padded 40 pt down while the keyboard holds the navigation bar at its compact height),
and the spread draws a fold shadow down its gutter. Band after: 160 pt with the bars up, 250 folded.

---

## Related

- `Docs/Page Mode Sheet Ownership.md`: the same window churn killed any sheet a PAGE presented; fixed the
  same day by moving every page-mode sheet to the host.
- `Docs/Mushaf Justification.md`: how a page's text is composed and fitted, and why it is expensive.
