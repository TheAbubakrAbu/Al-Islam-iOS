# Copilot and Codex Changes

This document records the changes made in the current working branches of the Al-Islam,
Al-Quran, and Al-Adhan repositories so another engineer or reviewer can verify them later.

## Documentation

- Reorganized the former flat `docs/` directory into:
  - `Docs/App Store/`
  - `Docs/Engineering/`
  - `Docs/Product/`
  - `Docs/Quran/`
  - `Docs/Tilawa/`
- Updated documentation links and references to the new paths.
- Moved the Tilawa licence documentation into `Docs/Tilawa/`.
- Added the Siri list-mode and page-mode behavior to the App Store release notes.
- Documented that Al-Quran and Al-Adhan use ordinary Settings tabs, without `.prominent` or
  `.search` roles.

## Al-Islam

- Added separate Siri/App Intent actions to open a surah in list mode or page mode.
- Kept the existing mode-aware surah-opening behavior for the current Quran reading mode.
- Corrected the App Shortcut design so each phrase has only one parameter. The invalid combined
  `surah` plus `mode` phrase was replaced by two fixed-mode intents.
- Matched the Five Pillars hero width to the surrounding Islam hero content.
- Moved the “Need a Hand?” section above the Prophet Muhammad quote.
- Changed appearance-related Settings, Tips & Tricks, Custom Colors, and Look & Feel tinting
  from fixed purple to the selected accent color.
- Added a default-collapsed “Show More” control to every Hadith book. The collapsed view shows
  the chapter count, hadith count, and compilation date; the expanded view shows the translated
  book name and full description.

## Al-Quran

- Added the same accent-color behavior for appearance-related Settings and Tips & Tricks surfaces.
- Made the Settings tab a normal tab, without `.prominent` or `.search`.
- Updated the splash flow so Al-Quran does not present the Simple Mode choice.
- Fixed the page-mode last-surah persistence path: when a visible mushaf anchor is reported,
  the selected surah and ayah are recorded even if the pager’s page index did not change.

### Quran page bug

The bug was that, after selecting a different surah in page mode, leaving the app could relaunch
Al-Quran at Al-Fatihah. Page mode primarily persisted the position from page-index changes and
used a debounced last-read write. A route change could land on the already-selected page index,
so that persistence hook did not run for the newly selected surah. The reader now persists the
visible surah/ayah anchor whenever it reports that anchor, while retaining the existing debounce
and background flush behavior.

## Al-Adhan

- Added the same accent-color behavior for appearance-related Settings and Tips & Tricks surfaces.
- Made the Settings tab a normal tab, without `.prominent` or `.search`.
- Updated the splash flow so Al-Adhan does not present the Simple Mode choice.
- The Learn section contains three grid tiles: Arabic Alphabet, Tajweed Foundations, and Islamic
  Journal. Al-Adhan does not currently ship the Tajweed Course, and Islamic Journal is not a
  separate full-width Learn banner.

## Validation notes

- `git diff --check` passed in all three repositories.
- Full companion builds remain blocked by existing project issues unrelated to these changes:
  - Al-Quran has an incomplete or invalid `AppIcon Watch` asset.
  - Al-Adhan has pre-existing Complication availability errors involving `WidgetRenderingMode`.
