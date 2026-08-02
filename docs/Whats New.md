# App Store What's New (Release Notes)

The **What's New in This Version** field in App Store Connect: up to **4,000 characters**, shown on
the product page for the current release. Changing it requires a new build (unlike Promotional Text).

## Guidelines

- **Hard cap 4,000 characters** - count the release section only (the `# Version 4.6.0` heading and
  the `**n / 4,000**` tally line are for this file, not the store). Verify before shipping:
  `awk '/^# Version 4.6.0$/{f=1;next} /^# Version /{f=0} f' "Docs/Whats New.md" | grep -v '^\*\*' | wc -m`
- **Aim for ~2,000-2,500.** Nobody reads a wall of text on a phone; the description sells the app,
  this field just says what changed. Shorter beats complete.
- **One line per bullet, one idea per line.** Cut "now", "new", and every clause after a dash that
  merely restates the first half. Name the feature, say what it does, stop.
- Group under short domain headings (AI Search, Prayer Tracker, Al-Hadith, Widgets, Al-Quran,
  Al-Adhan, Apple Watch, Islamic Tools, Bug fixes and optimizations). Drop a heading with nothing
  new to say rather than padding it.
- Lead with a one-sentence summary of the release, then the biggest feature first.
- Plain text only - no markdown, emoji, or links; the store renders none of it.
- Keep past versions below for reference; only the top section ships.

# Version 4.6.0

The major Hadith collections, on-device AI search, a prayer tracker, tafsir, a living sky over your prayer times, and a gallery of new widgets.

AI Search:
- Search by meaning, not keywords - "patience in hardship" finds ayahs about sabr.
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
- A smaller download and much faster launch - all content ships in a compact binary format.
- Smoother hadith scrolling, lighter widget refreshes, and polish throughout.

**2,612 / 4,000 characters.**


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
- Liquid Glass-style controls across the app - search bars, pickers, and other surfaces updated for a more consistent, modern feel.
- General UI polish throughout for clearer layout and smoother day-to-day use.

Al-Adhan:

- Automatic prayer time calculation that can suggest a method based on your region.
- Adhan sounds for notifications, so alerts can match the tone you prefer.
- Option to advance the Islamic (Hijri) date at Maghrib, when that matches how you count the calendar day.

Al-Quran:

- Tajweed in the Quran: optional color-coded tajweed, and a dedicated Tajweed reference - so rules are easier to notice while you read and listen (in beta).
- Page and Juz structure: new page and Juz dividers, plus an overlay so you always see which Surah and Juz you’re in.
- Smarter search: find ayahs by Juz and page, whether you’re searching within a Surah or across the whole Quran.
- Quran search history for quicker repeat lookups.
- Continue where you left off with your last listened Surah and last read ayah - now with up to 5 recent Surahs and 5 recent ayahs.

Al-Islamic Tools:

- Masjid Locator: a new tool to help you find nearby mosques.
- Improved Arabic View for a clearer, more helpful learning experience.

Bug fixes and optimizations:

- Improved performance, efficiency fixes, and a smoother overall experience.
