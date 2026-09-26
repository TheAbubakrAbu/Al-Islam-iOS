# Page mode: the page that "randomly shrinks and appears"

**Status: 2026-09-25 (next section): the FOLD and the FIND BAR are both one-step changes, and the room
and the chrome now move in order, so nothing ever draws over the text or squeezes it. The mini player
and the picker still follow the Al-Quran approach (two sections down). The 09-21/22 mechanism at the
bottom (chrome twins, known bands, the destination render, the crossfade) is history.**

## 2026-09-25: the room and the chrome move in order; the find bar joins the fold

> "we have to fix page mode Quran resizing. It's so broken. When I collapse and uncollapse it's okay
> but it can be better. When I click on search please fix that looks awful. Also support dismiss
> keyboard on scroll for page mode" (Abu)

**What the recordings showed** (60 fps, `drive2.py`, iPhone 17 Pro simulator, page 6):

- Fold: the page switched to its big layout on the tap's first frame (good), but the bars were still
  fading, so for five frames their glass faded over the new layout's last lines.
- Unfold: the page switched to its small layout at once and left an empty strip for a few frames
  before the bars faded into it.
- Find bar (Search): it slid in as a top inset with the page riding the sweep (527 to 400 pt over a
  third of a second). Kept at its old layout, the page was scaled down into a column three quarters
  wide with big side margins for the whole sweep, then cut to its new fit, smaller text with new line
  breaks. That is the "awful". The keyboard was never the cause: the reader already ignores it.

What changed (all in [`MushafReader.swift`](../iPhone/Quran/MushafReader.swift)):

- **Room and opacity are separate state.** `bottomBarsCollapsed` is the fold's ROOM, `barsFaded` its
  opacity (and the intent, which the chevron shows); `findBarRoom` / `findBarVisible` do the same for the
  find bar, with `searchActive` as the intent. The room always changes in one step
  (`mushafStillTransaction`, plus `.animation(nil, value:)` on the pager for both), the opacity animates.
- **Chrome that leaves fades out first, then its room goes** (`mushafChromeFadeOut`, 0.14 s): a fold
  fades the header and bars over a page that has not moved, then the page switches once into the whole
  band; closing Search does the same. **Chrome that arrives gets its room first, then fades in**
  (`mushafChromeFadeIn`, 0.2 s): the page switches at the tap and the bars or the find bar fade into the
  room it has left. A generation counter per change lets a quick second tap overtake the delayed half.
- **The find bar has a learned twin, like the fold.** `MushafPageRenderCache.noteTwins(.find, ...)` keeps
  a second store (`mushaf.findTwins`, device-only in `CloudManifest`), and `prewarm` fits the visible
  page at its find twin after the fold twin. So opening Search normally shows the page's new layout on
  the first frame, and closing it the full-band layout. The very first search on a geometry falls back
  for a few frames while its fit lands (marked settled at once, so no debounce).
- **The find field has one height** (`findFieldHeight`, scaled with body text). Focused, it was a point
  taller, so the band followed the keyboard (401 then 400) and every keyboard show or hide refitted the
  page by a point, and the learned twin missed by that point. `recentJump` still ties any one-frame
  settle after a jump back to it.
- **The keyboard is dropped before the close, outside its animation.** Dropped inside the X button's
  `withAnimation` (via the `searchActive` onChange), the chip row's scroll view jumped about 115 pt down,
  over the page's first line, and climbed back while the bar faded (its frame never moved: it was the
  scroll view's content). The X and "Search the whole Quran" now drop focus first, and the onChange drops
  it in `mushafStillTransaction`. Ignoring the keyboard safe area on the chips did NOT help (tried, removed).
  The old slide-away transition had simply hidden this.
- **Keyboard dismiss on scroll.** `MushafPagerProbe` sets the pager's `keyboardDismissMode = .onDrag`
  (a page turn) and adds `MushafKeyboardDismissPan`, which recognizes alongside everything and cancels
  no touches, for a vertical drag (a horizontal pager's own pan never begins on one). Only the keyboard
  goes; the find stays open with its matches lit.
- `jumpToReference` ("Go to 20:6") closes the bar without the fade (`hideFindBar(immediately:)`), so the
  band is settled before the turn's slide starts.
- **The bar's room is one fixed height while you type.** The "Go to ..." rows and the no-matches note
  used to grow the bar, so every keystroke that added or removed one moved the band (402, 331, 366 pt
  typing "2:255") and refitted the page under the keyboard. They now hang below the bar over the page
  (`findResultRows`, on glass). And the bar keeps what it showed through its fade-out (`findShown`,
  the query cleared only when the room goes): keyed on the intent, the close's first pass had the query
  but no matches and the note grew the fading bar by 21 pt for a frame.

DEBUG: `-resetChromeTwins` starts with no fold or find twins learned, for recording a first-ever change.

Verified at 60 fps on the iPhone 17 Pro simulators (iOS 26.5, then iOS 27.0 once the 26.5 one was busy):
a warm Search open switches the page on its first frame and the bar fades in over nothing; the close fades
the bar out in place (chips included) and switches once to the full band; typing a query or a reference
never moves the band; "Go to 2:255" tapped from its hanging row lands on page 42 with the ayah lit; a
vertical drag and a page swipe each dismiss the keyboard with the find still open, and tapping the field
brings it back; a fold fades the bars and then switches, an unfold switches and then fades the bars in; a
first-ever fold or find (`-resetChromeTwins`) shows its fallback for a few frames while its fit lands.

Not verified: a device, an iPad spread, Mac windows, Low Power Mode (no twin prefetch there).

## 2026-09-23 (evening): a fold moves the chrome, never the page

> "collapsing and uncollapsing the animation is horrible for quran page" (Abu)

**What the Al-Quran approach did to a fold** (recorded at 60 fps on the iPhone 17 Pro simulator, page 42,
`-pageFitLog`): the two bands are 527 and 664 pt, and the page's two layouts are genuinely different,
21.9 pt in 15 lines and 24.5 pt in 18 lines, with different line breaks (print-matched lines were
withdrawn on 2026-08-31, so a page always reflows to its band). While the band swept between them:

- Fold: the old layout stayed at its size in the growing band, sliding down with it, over an empty strip
  where the bars had been, for about half a second (220 ms settle debounce plus the fit), then cut to the
  bigger layout with new line breaks.
- Unfold: the old layout was scaled down with the shrinking band into a column about 80% wide, with
  wide side margins, then cut to the full-width layout at the end.

No scale of one layout ever matches the other, so the sweep could only show a wrong-size page and then a
jump. The clean version is ONE switch, at the tap, with only the chrome moving.

What changed (all in [`MushafReader.swift`](../iPhone/Quran/MushafReader.swift)):

- **The pager does not animate through a fold**: `.animation(nil, value: bottomBarsCollapsed)` on the
  TabView. The header and bars still animate (now ease-out 0.25 s, so they arrive or clear at once), but
  the pager and every page in it take the new band in one step. The page switches to its layout for the
  new band on the first frame; on a fold the bars fade off a page that is already full size underneath
  them, on an unfold they fade into the room the page has already left. `applyBarsCollapsed` is the
  fold (the DEBUG `-pageTurnScript` "collapse" step uses it too); `setBarsCollapsed` adds the stored
  preference as before.
- **Fold twins**: `updatePagerSize` sees each fold as one band change (`MushafPagerBandBox.bandBeforeFold`)
  and hands the pair to `MushafPageRenderCache.noteFoldTwins`, which remembers both directions per text
  geometry (persisted under `mushaf.foldTwins`, device-only in `CloudManifest`) and marks the landing
  geometry settled, so a cold landing fits at once instead of waiting out the 220 ms debounce. `prewarm`
  then queues ONE extra fit per ring: the visible page at its twin geometry, after the two nearest
  neighbours, never in Low Power Mode. It is cache-only (`enqueueFit(notesLatest: false)`), so the find
  bar and the mini player keep falling back to this side's layout.

This is not the 09-21/22 twins: one fit for the page on screen, for the fold only, no known bands per
chrome state, no destination render served early, no crossfade.

Result, same recordings: every fold and unfold is one switch on the first frame after the tap, then about
14 frames of chrome and a page that does not move. The first fold ever (no pair learned yet) still switched
on its first frame (the fit landed in 47 ms with no debounce). Relaunched on page 109 with the pair
persisted, the launch ring queued "fold twin 378x660" (landed in 137 ms) and the fold switched on its
first frame. A regression run (fold, unfold, find bar open and close, swipes in both states, a fold and an
unfold on pages reached by swiping) had zero blank frames, and fallbacks appeared only during the find
bar's sweep, always this side's layout.

Not verified: a device, an iPad spread, Mac windows, Low Power Mode (no prefetch there, so a fold right
after a page turn can show the old layout for one fit).

## 2026-09-23: back to Al-Quran's page management

> "I like Al Quran's page management it's less laggy and less weird like where it has to keep
> resizing. That's such an annoying part right now of Al Islam needs to be fixed. Just focus on
> resizing." (Abu)

Al-Quran's reader is Al-Islam's as of the 09-16 sync (`60cd3c0`), so it predates everything in the
sections below. Both apps were built and recorded side by side on the iPhone 17 Pro simulator with the
same scripted taps (`drive2.py --app quran|islam`, `verify2.sh`, `both.sh` in the session scratchpad;
same recipe as below). What differed:

1. **The fold never animated in Al-Islam.** `bottomBarsCollapsed` had become `@AppStorage` on 09-19
   (the persisted-collapse request). Toggled inside `withAnimation`, it still landed with no animation:
   the bars popped in one frame and the page's band jumped 529 -> 665 pt. Al-Quran's `@State` fold sweeps
   the band through about fifteen heights in 0.25 s (the page's `GeometryReader` logs each one) and the
   page rides it.
2. **The twins made the page change size before the chrome moved.** With the destination render
   already cached, every page swapped to it on the first frame of a chrome change, and the snapshot
   crossfade faded two typesettings of different sizes over each other for 0.15 s: a blurred double
   page. Plus the twin fits themselves, up to nine per rest, each with a main-thread compose.
3. **Opening the reader wasted two rings of fits.** The pager reports 749 and then 728 pt before the bars
   mount and settle it at 529. `noteVisibleGeometry` took each at once, and the reader's own opening
   prewarms swept eight pages at each passing height, on every open, landing while the push animated.

What changed (all in [`MushafReader.swift`](../iPhone/Quran/MushafReader.swift)):

- The fold is `@State`, seeded from the stored preference (`mushafBottomBarsCollapsed`, still persisted
  and still in the iCloud manifest) and written back by `setBarsCollapsed` 0.35 s after the fold, so the
  `Settings` republish a defaults write causes never lands inside the fold's frames.
- Removed: the chrome state key, known bands (`Caches/mushaf-known-bands.plist` is no longer read or
  written), twin warming, `expectedGeometry`, the five-budget and sticky fallbacks, the header and bars
  height readers, and the snapshot crossfade. `latestByPage` holds one render per page again and
  `nearestRendered` is Al-Quran's, so during any chrome animation a page keeps the render it was showing
  (scaled into a shorter band, centred in a taller one) and makes ONE clean cut to the exact fit once the
  band settles.
- `renderedPageBody` draws a fitted and a scaled render in ONE branch, so the text view keeps its identity
  while the band sweeps across the render's own height (two branches swapped the view mid-animation).
- The reader keeps no per-frame band state: `spreadRuleMet` changes only when the spread rule flips, and
  the band itself sits in a box.
- `noteVisibleGeometry` commits a band only after 0.2 s of stillness, and seeds from the persisted
  geometry when the reader reports before `prewarmAtLaunch` has run. Opening the reader now warms at 525
  only (zero passing-height fits, measured).
- Kept from 09-21/22: the Now Playing transport row fix (the reader stays 402 pt wide), one text view per
  page across fallback and exact renders (no blank frames on a swap), the 220 ms settle debounce, the
  pager band as the single geometry source and the persisted geometry written at the settled beat (the
  "Go to 20:6" loop fixes).

Result, frame scans of the same scenarios: fold, the page slides with the bars and cuts once to the new
fit (0.24 s after the tap when that fit is cached, about 0.5 s the first time); unfold, the page scales
down smoothly with the bars, then one cut; find bar and mini player, the same smooth follow and one cut;
swipes, picker jumps, the long-press sheet and re-entering the reader unchanged; zero blank frames in all.
Every one of those now matches Al-Quran's recording.

---

## History: the 09-21/22 version (replaced)

**Status then: FIXED on 2026-09-21/22.** Six scripted scenarios on the iPhone 17 Pro simulator (bar fold,
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
