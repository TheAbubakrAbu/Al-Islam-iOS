# Tab Tutorials: a full guide for each tab

Design written 2026-10-31; built the same day (Abu: "work on the tutorials"), following `Docs/Product/Tab Tutorials Plan.md`. The code is `iPhone/Settings/Pages/TabTutorials.swift`. The draft cards in section 5 were rewritten from four surveys of the code before they shipped: the shipped copy is the file, not the tables below.

## 1. Why

- Readers complained that the home city is set automatically without them knowing. On 2026-10-31 the Location card started saying so, and it now names the city with a Change button (`PermissionCards`, PermissionsSheet.swift). Abu also wanted the welcome to send people somewhere to learn each tab.
- Tips & Tricks lists what is hard to find: 160 tips, 35 of them in a tour. Nothing teaches the basics. The 2026-10-31 survey of the four tabs found no tip for any of these:
  - the automatic home city;
  - a hadith's chain, its narrators and Similar Hadiths;
  - the Islam tab's text size, its Start Here or its search;
  - bookmarking an ayah from its number pill;
  - the Quran font sizes.

## 2. Decisions

| Question | Answer |
|---|---|
| How many | One tutorial per tab: Adhan, Quran, Hadith, Islam (Abu, 2026-10-31: "one per tab"). |
| Depth | The basics first. The last card points at that tab's Tips & Tricks for everything else. |
| Format | A paged walkthrough like the Tips & Tricks tour, with one idea per card. A card can carry up to two "Show me" buttons that open the real setting. Not coach marks drawn over the live tab: Simple Mode, hidden sections and the iPad layout all move the things they would point at. |
| Home city | The Adhan tutorial has a card about it with two buttons, "Change Home City" (the Set Home City picker) and "Traveling Mode Settings" (Abu, 2026-10-31: "make sure they allow to change in settings for traveling city"). |
| Where it opens | The tab's ⋯ menu, the first row of the tab's Tips & Tricks, the welcome's "A lot to discover" page, and settings search. |

## 3. Rules

1. **True today.** Every card describes what the app does, checked against the code when it is written: the same rule as the tips. A card about something the app does not do is worse than no card. A card changes in the same commit as its feature.
2. **A setting opens as itself.** "Show me" opens the setting as the root of what opens, never its settings root with the page pushed a beat later. That glitch was fixed app-wide on 2026-10-31 (`SettingsSearchDestinationView.view(for:)`). Back returns to the card.
3. **No card for what the reader cannot use.** Simple Mode trims, per-app flags (`HAS_ADHAN`, `HAS_QURAN`, `HAS_HADITH`, `HAS_WEATHER`) and device gates (Apple Intelligence) hide a card through the same `isAvailable` closure the tips use.
4. **Short.** Six to ten cards per tab, one idea per card, at most three sentences of detail.
5. **Copy.**
   - Labels in quotes exactly as the app shows them.
   - No em dashes or spaced hyphens.
   - Every string goes into the catalog with Arabic and Urdu (`Scripts/localize_catalog.py`).
   - Ids and model-facing text stay English (`InterfaceText`, as in `AppTip`).
6. **Shared with the companions.** The file syncs to the sibling apps. Al-Adhan gets the Adhan and Islam tutorials, Al-Quran gets Quran and Islam, gated like `TipArea.offered`.

## 4. Architecture

### 4.1 One file

`iPhone/Settings/Pages/TabTutorials.swift` goes in the iPhone target only, registered beside TipsAndTricks.swift. UnitTests is not synchronized, so its test file needs registering too (`Scripts/xcode_register.py`).

- **`enum TutorialTab: String, CaseIterable`** has the cases `adhan`, `quran`, `hadith` and `islam`. Each case carries:
  - its title ("Adhan Tutorial");
  - its tint (the matching `TipArea`'s);
  - its `tipsArea`.

  `static var offered` lists the tabs this app compiles.
- **`struct TutorialStep: Identifiable`** is shaped like `AppTip`:
  - `id` ("adhan.homecity") and `tab`;
  - `systemImage`;
  - `title`, `detail` and `place` (each an `InterfaceText`);
  - `actions: [TutorialAction]` (zero to two);
  - `isAvailable`.
- **`enum TutorialAction`** has three cases:
  - `.setting(SettingsSearchEntry.Destination, label:)` pushes `SettingsSearchDestinationView.view(for:)` inside the tutorial's own stack.
  - `.homeCity` presents `MapView(choosingPrayerTimes: false)` as a sheet. It is the same picker Settings › Prayer Settings › Traveling Mode › Set Home City and the Location card's Change open.
  - `.tips(TipArea)` pushes that area's `TipsView(area:)`.
- **`enum TutorialCatalog`** has `static func steps(for: TutorialTab) -> [TutorialStep]`, already filtered by `isAvailable`.

### 4.2 The view

- **`TabTutorialView(tab:presentedAsSheet:)`.** As a sheet it sits in a `SheetNavigationContainer` with the house X, opening at the large detent because the cards carry buttons. Pushed (from settings search), it has no X.
- **One pager for both tours.** Extract from `TipsTourView` a `TourPager` (the page-style `TabView`, the dots, Next and Finish). Widen `TipTourCard` into a `TourCard`: the icon chip, "N of M", the title, the detail, the place pill, and up to two action buttons. `TipsTourView` becomes a thin caller, so the two tours look and behave alike.
- **Action buttons** are accent capsules like the Location card's Change. The first is filled; the second is plain.

### 4.3 Entry points

1. **The tab's ⋯ menu:** a "Tutorial" item (`graduationcap`) on all four tabs. Simple Mode keeps it, because it is a door, not a detail. The menus are at:
   - AdhanView.swift ~209-235
   - QuranView.swift ~3111-3194
   - HadithView.swift ~1389-1408
   - IslamView.swift ~1420-1439
2. **The first row of the tab's Tips & Tricks section** (`TipsSection(area:)`): "Take the Adhan Tutorial", and so on for each tab.
3. **The welcome's "A lot to discover" page** (`WelcomeDiscoverPage`): a LEARN EACH TAB card under the Tips & Tricks card, with one row per offered tab, and the line "Each tab also has Tips & Tricks in its settings." This is the pointer held back on 2026-10-31.
4. **Settings search:** a new `SettingsSearchEntry.Destination.tutorial(TutorialTab)`, with entries "Adhan Tutorial" and the rest. `view(for:)` maps it to `TabTutorialView(tab:presentedAsSheet: false)`.

### 4.4 Nothing new to store

Version one needs no new key. A first-visit nudge would need one (see 8).

## 5. The four tutorials

These are draft cards. Each claim comes from the 2026-10-31 survey of the code; line numbers there will drift. Final copy is written at build time and checked again.

### 5.1 Adhan (9 cards)

| # | Card | What it teaches | Show me |
|---|---|---|---|
| 1 | Prayer times for where you are | Today's prayers, the current and the upcoming one, and the countdown. Tap a prayer for its details; pull down for a fresh location. | none |
| 2 | How the times are worked out | "Choose Automatically" picks the method customary in your country and asks before it changes. Or choose a method yourself, and the Asr method. | Prayer Calculation (`.prayerPage(.prayerCalculation)`) |
| 3 | Your home city | See 6. | Change Home City (`.homeCity`), Traveling Mode Settings (`.prayerPage(.travelingMode)`) |
| 4 | Traveling Mode | More than 48 mi from home, with "Automatic Traveling Mode" on, it turns on and asks you to confirm. The prayers show shortened and combined, and "View Full Prayers" shows all five. | Traveling Mode (`.prayerPage(.travelingMode)`) |
| 5 | The adhan and reminders | Each prayer's bell: a tap moves between its choices, a hold picks one. The adhan sound and everything else is in Notifications. | Notifications (`.notifications`) |
| 6 | The Qibla and the Hijri date | Tap the compass beside your city to see it large. Tap the date for the Hijri calendar, or hold it to copy. | Manual Offsets (`.prayerPage(.manualOffsets)`, which holds the Hijri offset) |
| 7 | Track your prayers | Tap a prayer's circle to mark it on time; hold it for late or missed. History & Insights shows the record. Hidden in Simple Mode unless something was marked in the last 14 days, so the card hides with it. | Prayer Tracker (`.prayerTracker`) |
| 8 | The sky | Drag the sun to see any moment of the day, and tap the moon. Colours and skyline are in Sky settings. On Al-Islam only, weather is there too, off by default. | Sky (`.prayerPage(.sky)`) |
| 9 | Go further | Nagging Mode helps you pray on time; Tips & Tricks has the rest. | Tips & Tricks (`.tips(.adhan)`), Nagging Mode (`.notificationsPage(.naggingMode)`) |

### 5.2 Quran (10 cards)

| # | Card | What it teaches | Show me |
|---|---|---|---|
| 1 | Your Quran tab | Your Summary (Last Read, Ayah of the Day and more), Bookmarks, Favorites, then every surah. Tap one to read. | none |
| 2 | List or pages | The list reader shows ayah by ayah with the translation; pages show the mushaf. Switch from the reader's title menu or the tab's ⋯ menu. | Quran Settings (`.quranSettings`, whose root has the List/Pages picker) |
| 3 | Moving around | Hold the surah title for Choose Surah. On pages, swipe to turn and use the page pill to jump to a page or juz. The list has a juz rail on its edge. | none |
| 4 | Tap, double tap, hold | Tap an ayah to mark it, double tap to hear it, hold for its actions (tafsir, a note, sharing). Tap its number to bookmark it. | none |
| 5 | Listen | The play button: "Play Surah", "Play Ayah by Ayah", "Choose Reciter". Hold it for a custom range. The Now Playing bar stays while audio plays. | Choose Reciter (`.reciters`) |
| 6 | Tajweed colours | On by default. The Legend pill explains each colour; hold it for a quick look. | Arabic Text (`.quranPage(.arabicText)`) |
| 7 | Translation and transliteration | Saheeh International shows by default. Transliteration is in English Text (Hafs). | English Text (`.quranPage(.englishText)`) |
| 8 | Need help reading? | "Enable Arabic Beginner Mode" puts a space between each Arabic letter. | Arabic Text (`.quranPage(.arabicText)`) |
| 9 | Search | Find a surah or an ayah by its words or by a reference. | none |
| 10 | Go further | Font and size, the riwayat, the planner, and every other tip. | Tips & Tricks (`.tips(.quran)`), Arabic Text |

### 5.3 Hadith (9 cards)

| # | Card | What it teaches | Show me |
|---|---|---|---|
| 1 | The books | 17 collections in four groups: The Six Books, Early Collections, The Forty Collections, Other Books. Tap a book for its chapters. | none |
| 2 | Reading a hadith | Each hadith shows its number and book, the Arabic, the narrator and the English, then its grade. Previous and Next move between chapters; the chapter title opens Choose Chapter. | none |
| 3 | Grades | Scholars' verdicts appear word for word, with the scholar's name. Tap a grade to see the chain. | none |
| 4 | Bookmarks and notes | Tap a hadith's number, or swipe it, to bookmark it. Add a note from its menu. Bookmarks gather on the tab. | none |
| 5 | The hadith menu | Hold a hadith, or tap its ⋯, to copy it, share it as an image or text, select text, or summarize it with AI where the device can. | none |
| 6 | Chains and narrators | Where a hadith has one, Chain of Narrators shows who passed it on; tap a narrator for their page. Same Chain, Tree of Narrators and Similar Hadiths sit beside it. | none |
| 7 | Search | Words in Arabic or English, or a reference such as "bukhari 5103". Filter the results by grade. | none |
| 8 | Arabic, English or both | Read in one language or both; never both off. | Arabic Text (`.hadithPage(.arabicText)`), English Text (`.hadithPage(.englishText)`) |
| 9 | Go further | Every other tip. | Tips & Tricks (`.tips(.hadith)`) |

### 5.4 Islam (9 cards)

| # | Card | What it teaches | Show me |
|---|---|---|---|
| 1 | Start Here | Steps chosen from your About You answer, ticked off as you open them. Hide it, or bring it back from About You. Shown only while Start Here is. | About You (`.aboutYou`) |
| 2 | The library | Resources grouped by subject: Learn, Remembrance, Tools, Faith & Proofs, Ask AI. Grid or list from the ⋯ menu. In Simple Mode, Tools and Ask AI sit behind "More Resources", and the card says so. | none |
| 3 | Favorites | Hold a tile, or tap its star, to favorite it. Favorites sit at the top. | none |
| 4 | Begin with the basics | The Five Pillars and Six Beliefs, and the How-To Guides for wudu, salah and Jumuah. | none (see 8, question 2) |
| 5 | Learn to read Arabic | The Arabic Alphabet, Tajweed Foundations, and the Tajweed Course with a quiz in each lesson (where the app has the Quran). | Arabic Alphabet (`.islamPage(.alphabet)`) |
| 6 | Remember Allah | Duas (Hisn al-Muslim is inside), Morning and Evening Adhkar, the Tasbih counter, the 99 Names. | none |
| 7 | Search | Searches the resources and the text of the articles. | none |
| 8 | Make it readable | The Arabic font, and the text size. | Text Size (`.islamPage(.textSize)`), Arabic Text (`.islamPage(.arabicText)`) |
| 9 | Go further | Every other tip. | Tips & Tricks (`.tips(.islam)`) |

## 6. One card in full: the home city

- **Title:** "Your home city"
- **Detail:** "The first place \(AppIdentifiers.displayName) finds is saved as your home city, and Traveling Mode measures how far you are from it. If that is not where you live, change it."
- **Place:** "Settings › Prayer Settings › Traveling Mode"
- **Buttons:** "Change Home City" (the picker; the city on the card updates when it closes), and "Traveling Mode Settings".

## 7. Testing

- **Unit tests** (`TabTutorialsTests`, registered):
  - ids are unique;
  - each offered tab has six to ten available cards in Full and in Simple;
  - every `.setting` destination is one `SettingsSearchEntry.all` already offers, which catches a renamed page;
  - no copy holds an em dash or a spaced hyphen;
  - the Islam cards stay true without `HAS_QURAN` (Al-Adhan's build).
- **A survey at build time.** Check every card against the code again, the way the tips are audited.
- **Localization:** sync, then todo, validate and merge Arabic and Urdu; `check` in both.
- **Simulator (iPhone 17 Pro):**
  - each tutorial in light and dark, at an accessibility size, and in Arabic;
  - every "Show me" lands on its page as the root, recorded the way the 2026-10-31 Traveling Mode check was;
  - the iPad sheet.
- **QA:** a DEBUG `-tutorial adhan|quran|hadith|islam` launch argument, and lines in `Scripts/qa/screens.txt`.

## 8. Open questions for Abu, answered 2026-10-31

1. First-visit nudge: **yes**, one time per tab (`TutorialNudgeSection`, key `tutorialNudgesSeen`, device-only). It stays until "Take the Tutorial", its close button, the tutorial's Finish, or a welcome row is pressed.
2. "Show me" opens **settings and pickers only**, not the tab's own screens.
3. Need a Hand?: **yes**, "New to This Tab?" leads each tab's run.

What the surveys corrected in the draft cards:

- Adhan: the method switches first and then says so ("Calculation Method Updated", with "Keep" the old one); the tracker's circles are in their own section and only once a prayer's time has begun; the bells sit on the row only in Tiles, Centered Tiles and List; the distance is always written 48 mi. The tip `adhan.autocalc` said "asks you first" and was corrected with the card.
- Quran: double tap plays and the number bookmarks only in the list reader; on pages a double tap opens Word Study; most of the play menu is Hafs only; the juz rail is on the tab, not in the reader, and Simple Mode keeps it only in the Juz sorts, so no card names it.
- Hadith: a grade opens the chain only where the chain icon follows it; "Same Chain of Narrators" and "Tree of Narrators" sit under the chain; "Similar Hadiths" is its own menu item; Bukhari and Muslim carry no grade line.
- Islam: Start Here is offered to everyone not raised Muslim, so a reader who hid it learns how to bring it back; `.islamPage(.alphabet)` is the alphabet's settings, so its button reads "Alphabet Settings"; search covers the articles of Pillars & Beliefs, the How-To Guides and Proving Islam only.

The questions as they were asked:

1. Should each tab show a one-time nudge on its first visit ("New here? Take the tutorial")? It needs one key, for example `tutorialsSeen`.
2. Should "Show me" also open the tab's own screens, beyond settings? Islam resources have no outside route today: `IslamDestination` is private (IslamView.swift ~90), and `IslamOpenTarget` only knows the tab, Duas, Adhkar and Names. A `.resource(String)` target handled by IslamView's existing push would let "Begin with the basics" open Five Pillars directly.
3. Should each tab's Need a Hand? section get a "New to this tab?" door?

## 9. Found while surveying (not part of this design)

- The settings search entry "Reading View (List / Pages)" opens Quran Settings › Reading View, which has no List/Pages picker. The picker is on the Quran Settings root (SettingsQuranView.swift ~1277 against ~128-136).
- Tip `adhan.layouts` says "Four layouts" and names five (TipsAndTricks.swift ~427-428).
- Tip `quran.pdf` calls the menu item "Read Pages as Printed Mushaf (PDF)", but the menu says "Printed Mushaf" (SurahView.swift ~4317-4319).
