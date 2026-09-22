# Page mode: the page that "randomly shrinks and appears"

**Status: FIXED on 2026-09-21/22.** Six scripted scenarios on the iPhone 17 Pro simulator (bar fold,
mini player mount / expand / stop, a swipe run, page-picker jumps, the find bar, the long-press sheet,
plus leaving and re-entering the reader) show zero blank frames and no page sitting at the wrong size.
Every chrome change is now a cache hit at its final band, and the animation between two bands is one
render scaling with the band, or one crossfade.

**App:** Al-Islam (`Al-Islam-iOS`). Al-Quran carries the same reader; port with
`./sync_from_islam.sh quran --apply` once this is committed here. Note: `04c159d` (Save 15) was committed
mid-work and holds an intermediate version (an `anticipateBand` mechanism that was later removed, and a
fold estimate with its sign inverted); the working tree after it is the finished one.

**Files:** [`iPhone/Quran/MushafReader.swift`](../iPhone/Quran/MushafReader.swift) (`SurahPageReader`'s
chrome-state block, `MushafPageContent.body`, `MushafPageRenderCache`'s fallback and twin sections,
`MushafPageTextView.updateUIView`), [`iPhone/Quran/NowPlayingView.swift`](../iPhone/Quran/NowPlayingView.swift)
(`transportRowWithProgress`).

---

## The report

> "page mode. so many tiny bugs and quirks where it randomly shrinks and appears. i want it to be
> airtight no bugs no lag no glitches"

---

## What was actually happening (measured)

A mushaf page is typeset to the band the pager gives it, and the band changes whenever the reader's
chrome does. Every one of those changes had its own defect:

| Change | Old behaviour (frame scan of a recording) |
|---|---|
| Folding the bottom bars (chevron), first time | the old 525 pt render sat CENTRED in the new 661 pt band for ~0.3 s (a 150 ms settle debounce + the fit), then cut to the new fit: "shrinks, then appears" |
| Expanding the mini player to the big card | the card's transport row had a minimum width of ~323 pt but the phone offers it 314, so it pushed the WHOLE reader out to 411 pt on a 402 pt screen; every page composed 9 pt wider than the screen (text ran off the edge), every cached render missed (width is in the cache key) and the page showed a spinner for ~0.3 s |
| Stopping playback while the big card was up | same width change back, same spinner |
| The find bar opening / closing | the band sweeps through intermediate heights over ~0.35 s; the fallback picker hopped between several cached renders and crossfaded on each hop, and the SwiftUI identity crossfade left 2-3 fully blank frames (worst with the keyboard coming up) |
| Mini player mounting / stopping | a refit after the animation, with the old render shown at the wrong size until it landed |

Swipes, picker jumps, the long-press sheet and leaving / re-entering the reader were already clean.

---

## The fix, in five parts

1. **The player's transport row can compress** (`NowPlayingView.transportRowWithProgress`): the time
   labels are `minWidth: 0, maxWidth: 40`, the spacers `Spacer(minLength: 0)`, the icon gap 14. The
   reader's band stays 402 pt wide with the big card up.

2. **Chrome twins are kept warm.** `SurahPageReader` names its chrome state
   (`chromeStateKey`: band width, bars folded, mini player none / small / big, find bar, select bar)
   and records the band it rests at under that key (`noteBandState`, 0.45 s after the band last
   moved, persisted in `Caches/mushaf-known-bands.plist`). From those it lists the bands one tap
   away (`refreshTwinBands`) and hands them to `MushafPageRenderCache.twinBands`; `warmTwins` fits the
   visible page and its two neighbours at each of them, 1 s after the reader's last movement, on the
   prewarm lane under the current generation (a swipe retires unstarted twin fits). The fold twin is
   also ESTIMATED before it has ever happened: `band + header + bars - 2` (the header and bars are
   measured inside the collapse frame; the 2 is what the chevron strip gains when folded, measured:
   529 expanded, 665 folded, header 21 + bars 117). So the very first fold is a cache hit too.

3. **The fallback shows the render the band is heading to.** `latestByPage` now holds up to five
   renders per page (different budgets). When the chrome changes, the reader sets
   `MushafPageRenderCache.expectedGeometry` to the known band of the new state; `nearestRendered`
   returns that render through the whole sweep, scaled into each intermediate band by
   `renderedPageBody`'s scaled branch, so the sweep ends with no swap at all (the exact hit is the same
   object). Without a known destination the choice is sticky (the render shown last, as long as it
   covers 97% of the band), then the nearest budget above the band, then the nearest below.

4. **Render swaps crossfade in UIKit.** A different render for the same page (a refit, the exact fit
   replacing a fallback) reaches `MushafPageTextView.updateUIView`, which snapshots the text view,
   assigns the new text underneath and fades the snapshot out over 0.15 s. The SwiftUI version of this
   (`.id` + `.transition(.opacity)`) was tried first and removed: the old view was gone a frame or two
   before the new `UITextView` had drawn, a blank blink on every re-wrap.

5. **The settle debounce is 220 ms** for a geometry nothing has ever been fitted at (the find bar's
   slide eases in so gently that a transient height survived 150 ms), and a band the reader is known
   to rest at in some chrome state skips it (`hasSettledRender` consults the known bands).

Tried and removed: telling every page the destination band up front so it could typeset for it while
the pager's frame animated (`targetBand`). The logs showed the pages already receive their final band at
the START of a fold (SwiftUI lays out the final state and animates presentation), and the estimate fired
after the band had arrived, typesetting the page for a bogus 801 pt band. Not needed.

---

## How it was verified

`scratchpad/drive.py` launches the app in page mode, starts `simctl io recordVideo`, fires idb taps and
swipes on a schedule, stops, extracts frames at 30 fps and runs `frames.py`, which prints one line per
frame where anything changed in the page band: the line pitch (autocorrelation of the row ink profile,
so a scaled page reads as a pitch change), the first and last ink rows, and the ink fraction of the
left / centre / right thirds (under 0.2% = blank or spinner). `verify.sh <n>` runs the six scenarios
and greps each `-pageFitLog` trace for `STALE` (a fallback served), `TASK` (a fit requested by a page),
`CHROME` / `BAND` / `TWINS` (the state bookkeeping). `coldrun.sh` wipes the persisted fit store and
known bands first, for the first-time paths.

Positions on the iPhone 17 Pro (points): chevron strip 201,783; footer play button 347,744; "Play Surah"
253,745 and "Play Ayah by Ayah" 253,705 in its menu; big-card toggle 354,625; "Search this page" 256,690;
find bar close 359,139; a long press is `idb ui tap --duration 0.8`.

Final pass (run 7): blank frames 0 / 0 / 0 / 0 / 0 / 0; `STALE` lines only where a band was mid-sweep
(find bar 34, mini player 11), never at rest; every fold a single crossfaded frame.

---

## Related

- `docs/Mushaf Page Turn Glitch.md`: the pager's window and why it only changes at rest.
- `docs/Page Mode Sheet Ownership.md`: why a page never presents a sheet.
- `docs/Mushaf Justification.md`: how a page is composed and fitted.
