# Design Grammar

How every screen of Al-Islam is built from the same few parts, the way Apple's own apps are. The rules
below are the ones the 2026-10-26 consistency pass applied across the app; a new screen follows them,
and a screen that needs something the grammar does not have gets a new shared part, never a one-off.

The parts live in `iPhone/Helpers/ViewExtensions.swift` (headers, chips, badges), `iPhone/Settings/SettingsControls.swift`
(switches, captions, sliders) and `iPhone/Settings/SettingsSearch.swift` (the row label). All three compile
into every target, so a part may not need UIKit outside `#if os(iOS)`.

## 1. Section headers

| Where | What | Part |
| --- | --- | --- |
| A tab root (Adhan, Quran, Hadith, Islam, Settings) | Uppercase title with a leading SF Symbol | `SectionIconHeader(title, icon:)` |
| A tab root section with a count, a shuffle, a search or a fold | The same, plus the trailing cluster | `SectionPillHeader(title:count:icon:...)` |
| Any header that carries its own control (Clear All, Attach, Listen All, a count as text, a star) | Title at the leading edge, the controls trailing, stacking on two lines where they do not fit | `SectionHeaderLine(title, icon:) { controls }` |
| Every other screen: sub-pages, sheets, settings pages, article sections | A plain uppercase `Text` header in the List's own gray | `Section(header: Text("TITLE"))` |
| A learning stage (a lesson's part, a test's chapter) | Heavy headline with a symbol and a blurb | `StudyStageHeader` (`TajweedLessonHeader` is it in the lesson's colour) |

Rules:

- Icon headers belong to tab roots only. A settings page or a sub-page never puts a symbol on its header.
- Accent title and icon only for a section that is YOURS (Your Summary, Favorites, Bookmarks, Saved Reflections,
  Last Read, Khatm Progress, the Prayer Tracker, Start Here, Need a Hand?). Catalogs, settings, search results and
  Ask AI stay gray. The icon follows its title.
- The trailing cluster's order is fixed: count pill, search, shuffle, trash, chevron. Header buttons are glass
  circles the height of the count pill; a header's text action is `SectionHeaderAction("Clear All")` (caption
  semibold, accent, title case).
- Never `.font(...)` or `.textCase(nil)` on a plain header. The List sets the size and the case.
- Ask AI's header is `SectionIconHeader("ASK AI", icon: "sparkles")` on all three tabs.

## 2. Footers and captions

- A note that closes a section is its `footer:`, as a plain `Text`. Never `.font(.caption)` or `.font(.caption2)`
  or a `.foregroundStyle(.secondary)` on it: the List already sets the footer's size and colour, and the smaller
  overrides gave the app three footer sizes. Credits and source lines at the bottom of a screen are ordinary
  footers too.
- A note under one control that has more controls after it stays in the card as `SettingsCaption(text)`,
  padded `.vertical, 2` as its own row.
- A caption inside a control's label (under a switch's title) is `SettingsToggle(_, caption:)`; never a
  free-standing caption `Text` under a `Toggle`.

## 3. Rows

| Row | Part |
| --- | --- |
| A door: a row that opens another screen and carries a caption, a value or an accessory | `SettingsRowLabel(title:systemImage:subtitle:value:)`: the accent chip, a body title, a one-line caption (two on a content row: `subtitleLineLimit: 2`), a trailing read-out. `chip:` takes a chip of the row's own (the theme legend), `accessory:` a count pill or an Arabic title. |
| A switch | `SettingsToggle(title, caption:, systemImage:, isOn:)`: body title, caption inside the label, accent tint, haptic, the flagged page animation. Never a `Toggle` with `.font(.subheadline)` or `.font(.caption)`, never `.scaleEffect` on it (the share sheets' secondary options were 0.8 until 2026-10-26), never `.animation()` on its binding, never a second haptic in the binding's setter. The Adhan tab's optional-prayer switches keep the tab's second accent as their tint. The share sheets' switches are plain accent `Toggle`s at full size in their scroll view, every one padded the same. |
| A text size | `FontSizeSlider` (one write on release). |
| An action row (Set Home City, Preview Sound, Restore Default Colors) | Accent text, body size, default button style. Destructive: `role: .destructive`. |
| A content row (a surah, a book, a chapter, a theme, a name) | One family across the tabs (section 3a): a glass number pill, a `.subheadline.weight(.semibold)` title, `.caption2` captions in `.secondaryOnGlass`, the Arabic name in the primary colour with its number in the accent. |

Rules:

- Row titles are body size. Subheadline semibold is for an eyebrow over Arabic content, not for a navigable
  row's title.
- A count beside a row or in a header is `CountPill` (glass), never a hand-drawn capsule. A read-out that is
  not a number ("12 of 40", "Page 2 • 7 Ayahs") goes in the same pill through `countText:`.
- Secondary text on a glass tile is `.secondaryOnGlass`, never `.secondary` (3.1:1 there).
- A door drawn as a `Button` (one that pushes through state because its row cannot hold a link) passes
  `showsChevron: true` so it still reads as a door.

### 3a. Content rows: the surah row is the family

The Quran tab's surah row (`SurahRow`) is the content row every catalog in the app follows; the Hadith tab's
book rows, book tiles, chapter rows and chapter tiles were brought to it on 2026-10-26, so the two tabs read
as one app:

| Part | List row | Grid tile |
| --- | --- | --- |
| Number | A glass pill the row's height, caption bold on the accent, tinted when favorited; the star in its corner | The tile's corner star |
| Title | `.subheadline.weight(.semibold)` primary (two lines for a book) | "1: Title", the number `.subheadline` bold on the accent |
| Captions | `.caption2` in `.secondaryOnGlass`: "286 Ayahs", "97 Chapters • 7,277 Hadiths", the era | The same lines, centered |
| Arabic name | At the trailing edge, `.title3` in the primary colour, its number beside it in the accent (the Arabic face draws the digits in the ayah ring) | The top line, number first |
| Counts of the thing's own children | `CountPill` at the trailing edge (a chapter's hadiths) | "Hadiths 1-7 • 7" as a caption |

The accent carries the NUMBER, never the name: an Arabic title painted in the accent (the Hadith tab until
2026-10-26) reads as a control, and the Quran's names never were.

### 3b. The two tab roots

The Quran and Hadith roots are the same screen with different content, and share every part: `YOUR SUMMARY`
is `SectionHeaderLine` with the accent sparkles and the Today pill, each tile carries its own +/- that
unfolds that tile's recents under the grid (the Quran's four, the Hadith of the Day's earlier days and
where each book was left), `NEED A HAND?` / `BOOKMARKS` / `FAVORITES` are `SectionPillHeader`, the catalog
headers are the icon header with the count pill and the shuffle, search results are `SectionPillHeader`
with the magnifier, and a section the other tab lacks (ABOUT HADITH & THE SUNNAH) is still an icon header
over door rows with a footer, never a card of its own. The sub-screens pair the same way: both History
screens open with the article kit's lead card, Browse by Theme and Browse by Topic with a `ResourceHero`.

## 4. Buttons and chips

| Control | Part |
| --- | --- |
| A chip inside a row or a card (Hear Hafs, a goal preset, Hear It, a quick filter) | `.buttonStyle(.accentChip)`: caption semibold on the accent at 12%, capsule. `.accentChip(filled: true)` for the active state (white on the accent), `tint:` for a rule's own colour. |
| A header accessory (count, shuffle, search, trash, fold) | Glass pill or glass circle (`conditionalGlassEffect`). |
| A grid tile (Settings, the profile tiles, the Explore shelf) | `SettingsGridTile`: a 32 pt chip, the title, a one-line caption in `.secondaryOnGlass` (`captionLines: 2` where the caption is an answer the reader gave). |
| A floating bar (search, Now Playing, the reader's legend) | Glass, `BottomBarCushion.standard` under it, `adaptiveSafeArea`. |
| A full-width call to action in a notice or a welcome page | The system `.borderedProminent` (primary) tinted the accent (`WelcomeActionBar`, `BetaTextConsentCard`); a second full-width choice is `.bordered`; a text link under the primary ("Skip", "Back") is `.subheadline.weight(.medium)` on the accent. |
| A toolbar button | A bare symbol, `.body.weight(.semibold)`, tinted the accent; a menu of options is `slider.horizontal.3`. |

Never `.bordered` for a small chip in a row, and never a hand-drawn capsule at 0.08, 0.14 or 0.15: the chip style is
the one tint strength.

## 5. Colour

- The accent is `appearance.accent` (or the equivalent `settings.accentColor.color`): the user's choice, already
  moved to read 4.5:1 per appearance. The Adhan tab's second accent is `accent2`.
- Semantic colours mean one thing each: red is destructive or wrong, green is right or done, orange is beta or a
  warning (`BetaBadge`), the tajweed and theme colours are their rule's or their meaning's. Nothing else is a
  literal system colour.
- Glass tints follow the reading theme at a quarter strength or less (`Settings.themeGlassTint`).

## 6. Sheets and screens

- A sheet is `SheetNavigationContainer` with `sheetDismissToolbar` (X at the leading edge), an inline title, the
  app's own bottom `SearchBar` where it searches, and `accentWashedBackground`.
- A screen with modes shows them as a segmented control: in the toolbar's principal slot when the screen's band
  already says where you are (the Qiraat Explorer), or at the top of the pinned band when the title carries the
  context (the Qiraah Comparison sheet). Options go in the toolbar menu, never in single-switch sections above
  the content.
- A resource's opening is a `ResourceHero`; an article's parts use the article kit (`ArticleDesign.swift`).
- Dialogs are confirmation dialogs, not alerts (except the two that take text).

## 7. Checklist for a new screen

1. Headers: icon header on a tab root, plain `Text` everywhere else, `SectionHeaderLine` if it carries a control.
2. Every switch is a `SettingsToggle`; every text size is a `FontSizeSlider`.
3. Every door row is a `SettingsRowLabel`; counts are `CountPill`.
4. Footers are plain `Text`; captions under one control are `SettingsCaption`.
5. In-row chips are `.accentChip`; header accessories are glass.
6. Options live in a toolbar menu; modes in a segmented control.
7. Nothing reads smaller than `.caption`; no literal colour outside the semantic set.
