# How the mushaf page justifies its lines

The full, current description of how a composed mushaf page (page mode, `MushafReader.swift`)
decides its font size, its line breaks, and its word spacing — for **every** qiraah/riwayah,
at runtime. Nothing here is precomputed for Hafs: the only precomputed inputs are each
riwayah's own ayah→page table (which ayahs live on page N of *its* print), shipped in its
tajweed pack. Everything below runs on the riwayah's actual text, measured with the same
TextKit stack the page renders with.

The goal, in one sentence: **every line — the closing one included — reaches both margins,
with moderate word gaps as even as the words allow, and the leftover height (if any) sits as
a quiet, symmetric band instead of as one exploded line.**

## The pipeline, in order

Each stage's output feeds the next; all of it is a pure function of
(page, width, height budget, settings), which is why the results can be cached and persisted.

### 1. Fit the font size — `fittedSize`

Binary search on the whole composed page: the largest size that does not overflow the height
budget, verified against a real `NSLayoutManager` (not `boundingRect` — the two disagree on
RTL text that mixes fonts). Ceiling: Hafs may grow up to 2.5× the reader's size (its pages
genuinely fill, so growth is uniform); every other riwayah holds the reader's own size —
their text poured into page boundaries can leave pages short, and chasing the page bottom
with type growth made page-to-page sizes visibly uneven (`fitCeiling`).

### 2. Loosen the whole page a little — `balancedSpaceTracking`

Font sizing is quantized by whole lines, so a fitted page can still end short of the budget.
A typesetter's first tool is setting the page slightly looser so words cascade down and the
last line fills. Binary search for the smallest uniform extra advance on every word gap that
makes the page meet its budget — **capped at 0.4× the font size** (≈ two and a half natural
spaces per gap). Pages the cap can't fill keep the cap and leave the rest to stages 5–6;
chasing the budget without the cap is what produced the broken, em-wide gaps on non-Hafs
pages. Skipped entirely when the page already sits within a line and a half of the budget.

### 3. Re-choose the line breaks — `balanceLineBreaks` / `balanceParagraph`

TextKit breaks greedily, so a paragraph's closing line gets the leftovers — three words
where the lines above hold twelve. This pass "takes words from the top and puts them at the
bottom", all at once instead of cascading:

- Model every word's advance width (measured standalone — valid because a space breaks
  Arabic joining) and every gap's advance (space + its tracking).
- A dynamic program picks, among **all** ways of breaking the same words into the **same
  number of lines** (the count is pinned — a different count is a different page height),
  the breaks minimizing the summed *squared* per-gap widening. Squared, so sparseness
  spreads evenly instead of piling anywhere. Lines of one token are inadmissible (nothing
  to stretch — they could never reach the margin).
- The chosen breaks are **forced**: each line's gaps widen until the line is just short of
  the measure, so the greedy layout has no choice but to break where the program chose.
- A probe/verify loop relays out and compares. A line laying out *wider* in context than
  modeled earns a width surcharge (fill backs off); a line laying out *narrower* drives the
  surcharge negative (fill reaches past the nominal measure). Eight rounds; only if it never
  converges does the paragraph keep its greedy breaks.
- Two-line paragraphs skip the DP and keep the print-style break: first line as full as it
  fits, moving a word down only so the closing line holds at least two tokens.

### 4. Top every line up to the exact margins — `spaceJustified`

Per line, measure the real laid-out slack and distribute it across that line's spaces as
`.tracking` (never `.kern`, and never `.justified` — TextKit justifies Arabic with kashidas,
which slide tashkeel off stretched final letters). This is what actually makes every line,
the closing one included, land flush on both margins.

### 5. Spread the leftover height — `fitMetrics`

Whatever height stages 1–2 could not fill is spread between the lines as extra leading,
capped at 0.2× the font size per gap — a subtle settle, not a rhythm change.

### 6. The remainder centers

Any still-unabsorbed height becomes the symmetric top/bottom band of the centered layout.

## Where it deliberately does not run

- English page languages (prose reads on constant leading, natural alignment).
- The Basic face and "Hide Arabic Dots" (`usesSystemFont` — system-font typography).
- The opening spread (pages 1–2 are centered ornaments).

## Per-riwayah caveats that shaped the design

- **Pagination** comes from each riwayah's own print's page table when its pack ships one;
  riwayat without a table fall back to Hafs page boundaries through the ayah alignment.
- Word/gap widths differ per riwayah (orthography, mark stacks, the Warsh face), which is
  why nothing is measured once for Hafs: every stage measures the riwayah's actual text.
- The ayah ornament always uses the Hafs Uthmani face; mixed-font lines are exactly where
  standalone word measurement drifts from in-context layout — the probe loop in stage 3
  exists for that drift.
- Fit numbers are persisted across launches, salted with the fitter version, app build, OS,
  and the byte sizes of every bundled `.ttf`/`.qpk`/`.solidpack`/`.deflate` — any change to
  the algorithm, a font, or a text pack must miss the whole store rather than serve stale
  numbers (bump `fitterVersion` in `MushafReader.swift` when changing the algorithm).
