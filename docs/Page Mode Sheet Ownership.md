# Page mode: who presents a sheet, and why it kept breaking

**Status: FIXED on 2026-09-20, for every sheet at once.** A mushaf page no longer presents any sheet.
It reports what it wants (`SurahPageReader.onRequestSheet` / `onShowSurahInfo`) and a host that outlives
every page presents it: `SurahView` for the per-ayah sheets, the reader itself for surah info. The
counter-based mitigation (`AyahSheetPresence`) is no longer consulted by the page reader at all.

Verified on the iPhone 17 Pro simulator with the same headless recipe on the old and the new build
(see "How it was verified" at the bottom): on the old build the actions sheet opened for 2:11 was gone
once a far jump unmounted its page; on the new build the actions sheet, the tafsir sheet and the word
card all stayed up with page 31 behind them.

**App:** Al-Islam (`Al-Islam-iOS`). Al-Quran carries the same reader and the same defect; port with
`./sync_from_islam.sh quran --apply` once this is committed here.

**Files:** [`iPhone/Quran/MushafReader.swift`](../iPhone/Quran/MushafReader.swift),
[`iPhone/Quran/SurahView.swift`](../iPhone/Quran/SurahView.swift),
[`iPhone/Quran/AyahSheets.swift`](../iPhone/Quran/AyahSheets.swift),
[`iPhone/Quran/AyahRow.swift`](../iPhone/Quran/AyahRow.swift) (`AyahSheetPresence`, list reader only now).

---

## The underlying defect

`SurahPageReader` does not hand all 604 pages to its `TabView`. It mounts a **window** of them
(`windowRadius = 4`, so the selected page ± 4) and the window moves as you read. A page outside the
window is **unmounted**.

SwiftUI ties a `.sheet` to the view that declares it. **Unmounting a view that owns a live `.sheet`
takes that sheet down with it.** So any sheet presented *from a page* died when that page left the
window - on a manual swipe, on the automatic turn that follows the recitation, and (the report that
started all this) on the very first word card opened after a page change, because the window's deferred
re-centre landed 0.6 s after the swipe and rebuilt the pager's children under the card.

The list reader never had this problem: it has one host that outlives every row, which is what Phase 5
step 6 established (`AyahRow.onRequestSheet`).

---

## The rule

**A page inside the pager never presents a sheet; it reports, and a host presents.** Any new sheet in
page mode must go through `SurahPageReader.onRequestSheet` (per-ayah sheets, hosted by `SurahView`) or
through a reader-level `@State` like `headerInfoSurah` (surah info). `MushafPageContent` has no `.sheet`
modifier and no sheet state, and a comment beside its `renderTick` says why.

---

## What the fix does (2026-09-20)

| Sheet | Before (page-owned state) | Now |
|---|---|---|
| Actions sheet (long press) | `@State sheetAyah` + `.sheet(item:)` on the page | `onRequestSheet?(.actions, surah, ayah)` -> `SurahView.presentRowSheet` |
| Tafsir / similar / mutashabihat / qiraah / translations / custom range / note / share / select text | `@State secondarySheet`, opened by the page's own `requestSecondarySheet` | the host's actions sheet asks `presentRowSheet(.secondary(kind))`, exactly as in list mode |
| Word card (double tap), Hafs and riwayah | `@State pageTappedWord` / `pageTappedRiwayahWord` | `onRequestSheet?(.word(TappedWord(...)))` / `.riwayahWord(...)` |
| Surah info (tap a heading in the page text) | `@State infoSurah` | `onShowSurahInfo?(surah)` -> the reader's `headerInfoSurah`, the same sheet the pinned header opens |

Around that:

- **The long-press tint.** The page used to tint the ayah whose actions sheet it owned. `SurahView`
  now passes `actionsSheetAyah` (the ayah of its `rowSheet` while that sheet is `.actions`) down through
  `SurahPageReader` to every mounted page, and `sheetAyahTint` tints it only if it is on that page.
- **"Keep Sheet Open"** (2026-09-19) needed no page-side guard any more: the host's `presentRowSheet`
  already stacks a secondary over the actions sheet through `AyahSheetStack`, and page mode now goes
  through the same call. Verified: with the setting on, See Tafsir from the page's actions sheet
  stacks the tafsir sheet and the page keeps the 2:11 tint (the actions sheet is still up beneath).
- **Word by Word pin.** The shared `AyahRowSheetContent` builds the actions sheet for both readers now,
  so it passes `offersWordByWord: !settings.quranPageMode` (the page has no inline study layout).
- **Follow the recitation.** The two follow-page-turn handlers in `SurahPageReader` no longer consult
  `AyahSheetPresence`. Turning the page under a host-owned sheet dismisses nothing, so the reader keeps
  following the reciter behind an open tafsir, which is what the feature promises. (The LIST reader
  still holds its follow-scroll while a sheet is up; that is its own choice, left alone.)
- **`-openPageSheet`** (DEBUG) routes through the host too, and gained `word` (`-wordIndex <n>`) and
  `share`.

Deleted from `MushafPageContent`: five `.sheet(item:)` hosts, `anyPageSheetOpen`, the `.onChange` /
`.onDisappear` pair that drove the presence counter (the double-decrement bug and the per-page cost went
with them), `requestSecondarySheet`, `secondarySheetContent`, `TappedAyahRef`, `SecondarySheetRequest`,
`PageTappedWord`, `PageTappedRiwayahWord`.

---

## History, kept so nobody repeats it

**Attempt 1 - `AyahSheetPresence` (4.6.2, `2fd68d7`).** A global open-sheet counter that stopped the
*automatic* follow-the-recitation turn while a sheet was up. It never stopped a manual swipe from
killing the sheet, and its page-side hooks had a double decrement (`.onChange` and `.onDisappear` both
released) plus a computed property watched on every mounted page. The class stays, for the list
reader's follow-scroll, driven from one stable host (`SurahView.rowSheet`); the page reader ignores it.

**Attempt 2 - hoist only the word card (4.6.5, `f8a369f`), reverted 2026-09-19.** The right idea
applied to one sheet: the word card survived, the actions sheet, the secondaries and surah info still
died, and the page reader got laggier because the counter kept being driven by the sheets left behind.
Abu's report was exact: "it only fixed it for the double tap, it's still broken for every other sheet."
The 2026-09-20 fix is that attempt finished for every sheet, with attempt 1 removed from the page side.

---

## How it was verified

Headless, on the iPhone 17 Pro simulator, old build against new build:

```bash
UDID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
BID=com.Quran.Elmallah.Islamic-Pillars
# opens the sheet 1.5 s after the page appears, jumps to page index 30 at 4 s (the presenting page
# leaves the window ~1.2 s later), screenshot before and after
xcrun simctl launch $UDID $BID -launchTabQuran -quranPageMode -lastRead 2:11 -mushafPageLanguage arabic \
  -skipNotificationPrompt -travelingMode 0 -openPageSheet actions -pageTurnScript "=30@4"
sleep 4;  xcrun simctl io $UDID screenshot before.png
sleep 6;  xcrun simctl io $UDID screenshot after.png
```

Old build: `after.png` shows page 31 and no sheet. New build: page 31 with the actions sheet for 2:11
still up; the same for `-openPageSheet tafsir` and `-openPageSheet word -wordIndex 3`. The real
gestures were checked with idb (`~/Library/Python/3.9/bin/idb ui tap --udid $UDID x y`): a tap on the
Al-Baqarah heading of page 2 (`-lastRead 2:1`, tap 330 179) opens the surah info sheet, and See Tafsir
inside the page's actions sheet with `-seedBool keepAyahSheetOpen=1` stacks the tafsir sheet.

---

## Related

- `Docs/Mushaf Page Turn Glitch.md`: the swipe resistance / blank panel defect, fixed the same day by
  making window changes wait for the pager to rest. The two share a root (the moving window) and were
  fixed together; a sheet no longer depends on the window at all.
- `Docs/Mushaf Justification.md`: how a page's text is composed and fitted, and why it is expensive.
