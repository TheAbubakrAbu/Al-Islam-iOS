# App Store What's New (Release Notes)

The **What's New in This Version** field in App Store Connect: up to **4,000 characters**, shown on
the product page for the current release. Changing it requires a new build (unlike Promotional Text).

## Guidelines

- **Hard cap 4,000 characters**: count the release section only (the `# Version 4.6.6` heading and
  the `**n / 4,000**` tally line are for this file, not the store). Verify before shipping:
  `awk '/^# Version 4.6.6$/{f=1;next} /^# Version /{f=0} f' "Docs/App Store/Whats New.md" | grep -v '^\*\*' | wc -m`
- **Aim for ~2,000-2,500.** Nobody reads a wall of text on a phone; the description sells the app,
  this field just says what changed. Shorter beats complete.
- **One line per bullet, one idea per line.** Cut "now", "new", and every clause after a dash that
  merely restates the first half. Name the feature, say what it does, stop.
- Group under short domain headings (AI Search, Prayer Tracker, Al-Hadith, Widgets, Al-Quran,
  Al-Adhan, Apple Watch, Islamic Tools, Bug fixes and optimizations). Drop a heading with nothing
  new to say rather than padding it.
- Lead with a one-sentence summary of the release, then the biggest feature first.
- Plain text only: no markdown, emoji, or links; the store renders none of it.
- Keep past versions below for reference; only the top section ships.

# Version 4.6.6

Arabic and Urdu, chains of narrators for every hadith, a Tajweed Test, and the Islamic date on your prayer sky.

Languages:
- Al-Islam now speaks Arabic and Urdu: the whole app follows your iPhone's language, from the Quran reader to the widgets. The Islam tab's long articles stay English for now.

Al-Quran:
- Hamzat al-Wasl your way: follow the print, or show a saad or a dot, in all 20 riwayat.
- A juz rail on the right edge of the Quran tab, and numbered rails on long lists.
- The Play Range sheet rebuilt: ayahs or pages, repeats or forever, and your reciter in one place.
- Double tap an ayah to play it; the play button opens the playback menu.
- Each riwayah's profile now says what stands out in it.
- Smoother page turns in page mode, and a one-row find bar.
- Tajweed colors fixed inside ligatures and on a final raa.

Al-Hadith:
- Chains of narrators: tap a hadith's isnad to see every narrator in Arabic, then open a narrator's page.
- Tree of Narrators: every chain of a narration and its similar narrations in one diagram.
- Similar Hadiths: the same text through other chains, and close wordings.

Al-Adhan:
- Today's Islamic date, or this week's, under the countdown, with a notice the day before the clocks change.
- "Did you pray?" buttons on every prayer notification.
- Allow Notifications: one switch over everything the app sends.
- Notification, prayer notification and Nagging Mode settings rebuilt, with a page per prayer.
- The in-app adhan respects Silent Mode and offers a Play button instead.
- Weather that moves: rain falls, snow sways, clouds drift.
- Five prayer layouts, including glass tiles and centered tiles.

Islamic Tools:
- Sunnahs of the Prophet: 129 daily sunnahs with their sources.
- Arabic Alphabet: Hamzat al-Wasl, Vowel Letters, Alif Maqsurah or Yaa, and a Grammar section, each with drills.
- Tajweed Test: a 10-chapter ladder of questions generated from the course.
- New guides for the Khutbah and Ruqyah, and a fuller Jumuah guide.
- Fold or hide a tab's sections, and a search bar on every resource.

Settings:
- Every settings page in one grammar, with a caption under each control.
- Islam Settings, with Sunnah Reminders.
- An Update Available notice when a newer version is on the App Store.

Bug fixes and optimizations:
- Faster settings screens, lag-free menus, and about 60 fixes across iPhone, iPad, Mac and Apple Watch.

**2,387 / 4,000 characters.**

# Version 4.6.5

Simple Mode, iCloud Backup, Test Mode and a Revision plan for memorizing, Word Study for every word, and weather on your prayer sky.

Al-Quran:
- Ask Siri to open any surah in its current reading mode, or say “list mode” or “page mode” to choose.
- Test Mode hides the text until you tap, so you can recite from memory and check each ayah.
- The Quran Planner adds a Revision plan: a juz range or chosen surahs, revised every few days.
- Word Study: double tap any word for its meaning, grammar, root, themes, tajweed and qiraat.
- Play From Ayah now plays to the end of the page, surah, juz, or the whole Quran.
- Repeat Forever for an ayah, a surah or a custom range, downloaded once and replayed offline.
- Two mushaf pages side by side in landscape, and both readers use the full width.
- Tajweed colors the heavy and light laam in the name of Allah, and you can pick your own color for every rule.
- A rebuilt Qiraat Explorer: see every riwayah at once, or compare two.

Al-Adhan:
- Weather on the sky: clouds, rain, snow and fog, with temperature, UV and wind. Optional and off by default.
- Tap the moon for a 3D moon you can turn, at its true phase, above a skyline of pyramids and a mosque.
- Tapping a prayer notification asks "Did you pray?", and Nagging Mode has its own settings.
- More accurate times for many calculation methods, and a Qibla needle that turns smoothly at every size.

Al-Hadith:
- Filter rows over search results, and chapter lookups like "1:4" inside a book.
- Hadith & Its Sciences: how the hadith were preserved, checked and graded.

Widgets and Controls:
- Chosen Ayah widget: pin any ayah or bookmark to your Home or Lock Screen.
- Control Center controls to resume a recitation, see prayer times, or find the Qibla.
- Islamic stickers for iMessage.

Islamic Tools:
- Today: the ayah, hadith, dua and Name of the day on one screen.
- A Reading Test with 21 levels, from single letters to text without vowels.
- Tajweed Foundations is now a 58-lesson course with quizzes and Quran examples.
- New libraries: Proving Islam, Miracles of the Prophets, and Prophecies of the Prophet.

Settings:
- Simple Mode keeps only the essentials on screen. Switch to Full any time.
- iCloud Backup saves named profiles to your own iCloud, ready to restore on any device.
- A search bar on every settings page, and 150 Tips & Tricks.

Bug fixes and optimizations:
- Faster search, smoother playback, and dozens of crash fixes across iPhone, iPad, Mac and Apple Watch.

**2,384 / 4,000 characters.**


# Version 4.6.0

The major Hadith collections, on-device AI search, a prayer tracker, tafsir, a living sky over your prayer times, and a gallery of new widgets.

AI Search:
- Search by meaning, not keywords: "patience in hardship" finds ayahs about sabr.
- Works across the Quran, Hadith, 99 Names, duas, adhkar, and Settings.
- Private, offline, and free. With Apple Intelligence, Ask AI answers from the ayahs and hadiths it cites, never with a ruling.

Prayer Tracker:
- Mark each prayer with a tap, then watch streaks, perfect days, and a calendar heatmap grow.
- Jumuah and combined traveling prayers count correctly, and an exemption pause protects your streak.
- Nagging Mode: mark a prayer straight from the notification.

Al-Hadith:
- A Hadith tab with the Nine books, the forty-hadith collections, and classics like Riyad as-Salihin.
- Arabic with translation and narrator chains, list or page view, Hadith of the Day, bookmarks, and lookups like "Bukhari 5".
- Search one book or all 50,000+ hadiths. Everything is built in and works offline.

Widgets:
- Every prayer widget gains a Sky twin painted with the current prayer's gradient.
- New Solar Arc, Moon Phase, and Day & Night widgets.
- Widgets, the lock screen, and the Watch follow your manual time adjustments.

Al-Quran:
- Quran Planner: pick a finish date and get a daily amount that adjusts when you miss a day.
- Tafsir for any ayah: three English and three Arabic works, saved offline.
- Search the whole Quran while reading, and ask Siri in English or Arabic.
- Offline ayah-by-ayah audio in the reciter's own voice for a dozen reciters.
- A retypeset mushaf: pages open and flip faster with even spacing.

Al-Adhan:
- A living sky: the sun on its true arc, stars at night, the real moon phase. Drag to preview any moment and pick your own colors.
- An At a Glance board: Qibla, distance to Makkah, daylight, fasting window, and more.
- A Rakaah Guide with every prayer's fard and sunnah counts.
- Browse calculation methods by region with their angles shown.

Apple Watch:
- Full-surah recitation plays on the watch in every reciter's voice.
- Traveling Mode and settings sync more reliably, including after pairing.

Islamic Tools:
- A Halal Food Locator beside the Masjid Locator.
- Eight dua collections with sources, and Listen buttons across duas, adhkar, and the alphabet.
- Settings split into Adhan, Quran, and Hadith screens, with search.

Bug fixes and optimizations:
- A smaller download and much faster launch: all content ships in a compact binary format.
- Smoother hadith scrolling, lighter widget refreshes, and polish throughout.

**2,610 / 4,000 characters.**


# Version 4.5.3

A fresh new look, powerful Quran additions, smarter prayer features, and clearer, more accurate recitations across the app.

New look:
- A Liquid Glass redesign across iOS, iPadOS, macOS, and watchOS 26, with a refreshed launch experience and polished controls throughout.

Al-Quran:
- Color coded Tajweed with a dedicated Tajweed reference, so the rules are easy to notice while you read and listen.
- Read by page and Juz with new dividers and a marker that always shows the Surah and Juz you are in.
- Smarter search: find ayahs by Juz, by page, or by keyword across the whole Quran, with search history for quick repeat lookups.
- Pick up right where you left off, with your recent read and listened Surahs and ayahs saved.
- Added true verse by verse audio for more reciters so they play in their own voice instead of falling back to another.

Al-Adhan:
- Automatic prayer time calculation that suggests the right method for your region, and City Prayer Times that use each city's own method.
- See the other Asr time, Hanafi or standard, right inside the Asr details.
- Choose the adhan or notification sound you prefer.
- Option to advance the Islamic (Hijri) date at Maghrib.
- Updated prayer time engine for better accuracy, along with a more precise Qibla.

Tools and Learning:
- Masjid Locator to help you find nearby mosques.
- Improved Arabic Alphabet with a new size slider to make the letters as large and clear as you like.

Bug fixes and optimizations:
- Faster Quran loading at launch, plus performance improvements, reliability fixes, and polish throughout.


# Version 4.0.0

Introducing the new Liquid Glass look, designed to complement the UI across iOS, iPadOS, macOS, and watchOS 26.

Liquid Glass & UI:

- Refreshed launch and splash experience for a clearer, more polished first impression.
- Liquid Glass-style controls across the app: search bars, pickers, and other surfaces updated for a more consistent, modern feel.
- General UI polish throughout for clearer layout and smoother day-to-day use.

Al-Adhan:

- Automatic prayer time calculation that can suggest a method based on your region.
- Adhan sounds for notifications, so alerts can match the tone you prefer.
- Option to advance the Islamic (Hijri) date at Maghrib, when that matches how you count the calendar day.

Al-Quran:

- Tajweed in the Quran: optional color-coded tajweed, and a dedicated Tajweed reference, so rules are easier to notice while you read and listen (in beta).
- Page and Juz structure: new page and Juz dividers, plus an overlay so you always see which Surah and Juz you’re in.
- Smarter search: find ayahs by Juz and page, whether you’re searching within a Surah or across the whole Quran.
- Quran search history for quicker repeat lookups.
- Continue where you left off with your last listened Surah and last read ayah, now with up to 5 recent Surahs and 5 recent ayahs.

Al-Islamic Tools:

- Masjid Locator: a new tool to help you find nearby mosques.
- Improved Arabic View for a clearer, more helpful learning experience.

Bug fixes and optimizations:

- Improved performance, efficiency fixes, and a smoother overall experience.
