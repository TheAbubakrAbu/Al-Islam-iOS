# Page mode: "searched 20:6, tapped Go to, the app crashed"

**Status: FIXED on 2026-09-22.** Reproduced on the iPhone 17 Pro simulator with real taps (idb), traced
to a render loop, fixed in two places, re-verified: the jump lands on page 312 with 20:6 lit and the
process idles at under 1% CPU afterwards (it sat at 60 to 100% before, until the watchdog would have
killed it on a device).

**App:** Al-Islam (`Al-Islam-iOS`). Al-Quran carries the same reader; port with
`./sync_from_islam.sh quran --apply` once this is committed here.

**Files:** [`iPhone/Quran/MushafReader.swift`](../iPhone/Quran/MushafReader.swift)
(`SurahPageReader.jumpToReference`, `SurahPageReader.updatePagerSize`, `MushafPageRenderCache.lastGeometry`,
`MushafPageRenderCache.noteVisibleGeometry`, `MushafPageRenderCache.renderedIfAvailable`),
[`iPhone/Settings/Settings.swift`](../iPhone/Settings/Settings.swift) (the `-publishStacks` probe).

---

## The report

> App crashed in mushaf page when u searched up 20:6 then clicked on go to

---

## What actually happened

It was not a crash in the usual sense (no exception, no bad access). It was a SwiftUI render loop that
never returned to the run loop:

1. The find bar's "Go to Taha 20:6" row moved the pager from page 6 to page 312 and closed the find bar.
   The pager keeps the page it is leaving alive for a while after a far jump, and that page was still
   laid out at the band it had with the find bar open (372 pt) while the landing page had the closed
   band (529 pt).
2. Every mounted page's body called `MushafPageRenderCache.renderedIfAvailable`, and that setter
   recorded the page's geometry as the cache's "current geometry" (`lastGeometry`). With two pages a
   point apart in height the value flipped on every pass.
3. `lastGeometry.didSet` persisted the value to UserDefaults **synchronously, inside the render pass**.
4. A UserDefaults write is a SwiftUI publish: every `@AppStorage` inside `Settings` re-publishes the
   whole object on any defaults change (`UserDefaultObserver` -> `objectWillChange`). Every view that
   observes `Settings` re-rendered, both pages included, and step 2 ran again.

`sample` showed one `_UIHostingView.layoutSubviews` that never returned; SwiftUI's own change log
(`Self._logChanges()`) said `MushafPageContent: @self, _settings changed.` 250 times a second; the
`-publishStacks` probe named the key: `mushaf.lastPageGeometry`, written from `renderedIfAvailable`.

A second, slower cycle survived the first fix: the persisted write was gone, but the flip still
cancelled and rescheduled the 0.3 s settle work on every pass, and each settle re-warmed the ring at
the stale 368 pt band and woke the pages again (20 to 30% CPU, forever).

---

## The fix

1. **The reader's band is the one source of the current geometry.** `SurahPageReader.updatePagerSize`
   calls `MushafPageRenderCache.noteVisibleGeometry(band:)` with the band one page gets (half the pager
   across an open spread). `renderedIfAvailable` no longer writes `lastGeometry`, so a page the pager
   has already turned away from cannot feed its stale band into the cache.
2. **Nothing is persisted from a render pass.** The UserDefaults copy of the geometry is written from
   the same debounced settle beat that re-warms the ring, never from the setter.
3. **The Go to row turns the page like every other programmatic jump** (`turnPage`: mount the
   destination, wait for its render, animate the selection on the next tick) and closes the find bar
   in its own transaction, instead of teleporting the window and the selection inside the same animated
   transaction that removed the bar and dropped the keyboard. This alone did not stop the loop, but it
   is the reader's rule for jumps ("as if I was actually swiping") and it keeps the departure page and
   the landing page from being mounted with different bands in the first place.

**The rule:** never write UserDefaults (or anything else that publishes) from inside a view body or a
cache lookup a body makes. Persist from a debounced beat.

---

## How to reproduce and verify

```bash
UDID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
BID=com.Quran.Elmallah.Islamic-Pillars
IDB=~/Library/Python/3.9/bin/idb
xcrun simctl launch $UDID $BID -skipNotificationPrompt -launchTabQuran -quranPageMode -mushafPageLanguage arabic \
  -lastRead 2:30 -travelingMode 0 -pageFitLog -windowTrace
sleep 8
$IDB ui tap --udid $UDID 256 690        # the footer's Search pill
sleep 1.5; $IDB ui text --udid $UDID "20:6"
sleep 1.5; $IDB ui tap --udid $UDID 201 219   # the "Go to Taha 20:6" row
sleep 5
PID=$(ps -axo pid,command | grep -E "$UDID.*iPhone\.app/iPhone" | grep -v grep | awk '{print $1}')
top -l 3 -pid $PID -stats cpu | tail -1       # under 1% when fixed; 60 to 100% when looping
```

Headless alternative without idb: `-mushafFindBar 20:6 -mushafFindJump` taps the row two seconds after
the bar opens (it did NOT reproduce the loop, because no keyboard was up and the bar was already open
when the reader laid out; the real taps did).

**Finding the writer next time.** `-publishStacks` (DEBUG, Settings.swift) logs the call stack of every
40th `Settings` publish, the defaults keys whose values changed between publishes, and, through a
swizzled `-[NSUserDefaults setObject:forKey:]`, the key and stack of every 40th defaults write:

```bash
xcrun simctl spawn $UDID log show --last 3s --predicate 'process == "iPhone" AND eventMessage CONTAINS "DEFAULTS WRITE"'
```

`sample <pid> 2 -file s.txt`, then `grep -oE "[0-9]+ [A-Za-z_.]+\.body\.getter" s.txt | awk '{a[$2]+=$1} END{for(k in a) print a[k],k}' | sort -rn`
names the bodies in the loop, and SwiftUI's change log needs debug level:
`log show --debug --predicate 'subsystem == "com.apple.SwiftUI"'` after a temporary `Self._logChanges()`
(iOS 17.1+) in the suspect body.

---

## Related

- `Docs/Page Mode Chrome Bands.md`: the band bookkeeping this loop ran through.
- `Docs/Mushaf Page Turn Glitch.md`: the pager's window and why it only changes at rest.
