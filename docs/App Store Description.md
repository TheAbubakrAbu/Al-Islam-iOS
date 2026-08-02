# App Store Description

The **Description** field in App Store Connect: up to **4,000 characters**, shown on the product page
under the screenshots. Changing it requires a new build (unlike Promotional Text).

## Guidelines

- **Hard cap 4,000 characters** - everything below the `## Description` heading ships (the `**n /
  4,000**` tally line does not). Verify before submitting:
  `awk '/^## Description$/{f=1;next} f' "Docs/App Store Description.md" | grep -v '^\*\*' | wc -m`
- **Aim for ~3,800** so a new feature can be added later without a rewrite.
- Only the first ~3 lines show before "more" - the opening paragraph has to sell the app alone.
- **One line per bullet.** Cut "Fully", "complete", "at once", and any clause after a dash that
  restates the first half. Name the feature, say what it does, stop.
- Keep the ALL-CAPS section headers; they are the only structure the store renders.
- Proper nouns earn their length (Bukhari, Ibn Kathir, as-Sa'di, Riyad as-Salihin) - they are what
  people search for. Generic adjectives do not.
- Plain text only - no markdown, emoji, or links.
- Keep in sync with `Keywords.md`, `Promotional Text.md`, and `Whats New.md` whenever a feature ships.

## Description

Al-Islam is your complete companion for practicing Islam, whether you are a lifelong believer, a new convert, or exploring the faith. The Quran, the major Hadith collections, tafsir, prayer times, a prayer tracker, and on-device AI search in one simple app - completely free, ad free, and private.

ON-DEVICE AI SEARCH
- Search the Quran and Hadith by meaning, not keywords: "patience in hardship" finds ayahs about sabr.
- It runs everywhere: the Quran, any hadith book, the 99 Names, duas, adhkar, and even Settings.
- Fully on-device: private, offline, and free. With Apple Intelligence, Ask AI answers from the ayahs and hadiths it cites, never with a religious ruling.

PRAYER TRACKER
- Mark each prayer with a tap - streaks, perfect days, and a calendar heatmap.
- Jumuah and combined traveling prayers count correctly, and a menstruation and postpartum pause protects your streak.
- Nagging Mode reminds you every 15 minutes until you pray - answer right from the notification.

UNIQUE FEATURES
- Traveling Mode: shorten prayers while traveling, automatically or manually, synced to your Watch.
- Arabic Beginner Mode: spaces out letters so they are easier to recognize as you learn.
- Verse Sharing: share any verse as clean text or a beautiful image.
- Siri Shortcuts: play any surah, resume your last listen, or ask "When is Maghrib?" in English or Arabic.

THE COMPLETE QURAN
- Read by Surah, Juz, or page, with dividers and a marker that always shows where you are.
- Arabic, transliteration, and translation side by side, with optional color coded tajweed and a reference.
- Tafsir for any ayah: Ibn Kathir, Maarif Ul Quran, and Tazkirul Quran in English, plus Ibn Kathir, al-Tabari, and as-Sa'di in Arabic - saved offline.
- Find any verse by Surah:Ayah (like 5:27), page, Juz, or keyword.
- Listen to over 60 reciters, with full Surah and verse by verse playback, offline.

THE MAJOR HADITH COLLECTIONS
- All the major books: the Nine (Bukhari, Muslim, an-Nasa'i, Abu Dawud, at-Tirmidhi, Ibn Majah, Muwatta Malik, ad-Darimi, Musnad Ahmad), the forty-hadith collections, and classics like Riyad as-Salihin.
- Arabic with English translation and narrator chains, a Hadith of the Day, bookmarks, favorites, and lookups like "Bukhari 5".
- Search one book or all 50,000+ hadiths at once. Every collection is built in and works offline.

PRAYER TIMES AND QIBLA
- Accurate prayer times calculated privately on your device, with a method suggested for your region.
- A living sky above your prayer times: a real sun arc, night stars, and the true moon phase - drag to preview any moment.
- Qibla compass, adhan sounds, pre alerts, and an At a Glance board with distance to Makkah, daylight, and your fasting window.
- A full widget gallery: every prayer widget in a standard look and a Sky twin, plus Solar Arc, Moon Phase, and Day & Night - with full Apple Watch support.
- A Rakaah Guide with every prayer's fard and sunnah counts.

ESSENTIAL TOOLS AND LEARNING
- Hijri date and Islamic calendar with events like Ramadan and Eid, plus date notifications.
- Authenticated adhkar and dua collections, with Listen buttons that read the Arabic aloud.
- Tasbih counter, the 99 Names of Allah, Masjid and Halal Food locators, a Hijri converter, and Islamic wallpapers.
- Learn the Arabic alphabet, the Five Pillars, the Six Pillars of Faith, and core beliefs - explained simply for beginners.

MADE YOUR WAY
- Customize text sizes, Arabic fonts, accent and sky colors - settings search jumps to any option.

FREE, AD FREE, AND PRIVATE
Al-Islam is completely free. No ads, no fees, and no subscriptions. Your data never leaves your device.

Whether you seek prayer times, the Quran, the Hadith of the Prophet Muhammad (peace be upon him), or a deeper understanding of Islam, download Al-Islam today.

**3,805 / 4,000 characters.**
