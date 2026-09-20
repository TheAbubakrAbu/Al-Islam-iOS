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

## Related

- `Docs/Page Mode Sheet Ownership.md`: the same window churn killed any sheet a PAGE presented; fixed the
  same day by moving every page-mode sheet to the host.
- `Docs/Mushaf Justification.md`: how a page's text is composed and fitted, and why it is expensive.
