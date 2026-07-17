# App Store Keywords (ASO)

Keyword research and the App Store Connect **Keywords** field for **Al-Islam | Islamic Pillars**.
Keep this in sync whenever a major feature ships (e.g. Hadith, Tafsir).

---

## How the keyword field works

- **100 characters**, comma-separated, entered in App Store Connect (Keywords field, per localization).
- **No spaces after commas** - every space wastes a character. Use `quran,tafsir`, never `quran, tafsir`.
- **Never repeat** words already in the app **name** or **subtitle** - Apple already indexes those. So do **not** spend keyword characters on: `al`, `islam`, `islamic`, `pillars`, or anything in the current subtitle.
- **Apple auto-combines** single keywords into phrases, so `prayer,times` already ranks for "prayer times." Don't waste characters on multi-word phrases like `prayer times`.
- **Apple stems** singular/plural and common variants - pick one form (`surah`, not `surah,surahs`).
- **Alternate spellings matter** - many terms have several common transliterations (`quran`/`koran`, `adhan`/`azan`, `salah`/`salat`/`namaz`, `masjid`/`mosque`, `dhikr`/`zikr`). These are distinct search terms, so it's worth spending characters on the high-value ones.
- The keyword field is **not** shown to users - it is purely for ranking. The name, subtitle, and description do the human-facing work.

---

## Recommended keyword field (primary)

```
quran,tafsir,hadith,sunnah,bukhari,prayer,salah,adhan,namaz,qibla,masjid,dua,dhikr,ramadan,muslim
```

**97 / 100 characters.** Covers the app's five biggest search surfaces - Quran, Tafsir, Hadith, prayer/adhan, and the everyday-tools terms - while avoiding the name/subtitle words.

### Why each term

| Keyword | Reason |
|---|---|
| `quran` | Core term; also auto-combines with others (e.g. `quran` + `arabic`). Covers the largest single audience. |
| `tafsir` | New in this release; Ibn Kathir, al-Tabari, as-Sa'di, Maarif, Tazkirul. Low-competition, high-intent. |
| `hadith` | New Hadith tab; also stems toward "hadiths." |
| `sunnah` | Pairs with Hadith intent; searched by users looking for authenticated narrations. |
| `bukhari` | The single most-searched Hadith collection name; stands in for the whole Nine Books. |
| `prayer` | Auto-combines to "prayer times," "prayer app." Highest-volume prayer term in English. |
| `salah` | The Arabic-transliteration prayer term; distinct search from "prayer." |
| `adhan` | The call to prayer; the app's Adhan tab and notification sounds. |
| `namaz` | Urdu/Persian/Turkish word for prayer - large South-Asian and Turkish audience. |
| `qibla` | Qibla compass feature; high-intent, moderate competition. |
| `masjid` | Masjid Locator; distinct from "mosque" (see alternates). |
| `dua` | Dua collections; very high volume, stems toward "duas." |
| `dhikr` | Adhkar + Tasbih counter. |
| `ramadan` | Seasonal spike; worth holding year-round for the ranking runway before Ramadan. |
| `muslim` | Broad audience term; also the name of a major Hadith collection (Sahih Muslim). |

---

## Alternate fields to A/B test

Swap these in when a term underperforms in App Analytics (Search sources) or seasonally.

**Learning / convert focus** (lean into Beginner Mode + Arabic):
```
quran,tafsir,hadith,arabic,tajweed,learn,convert,prayer,salah,adhan,qibla,dua,dhikr,ramadan,muslim
```

**Recitation / audio focus** (lean into the 60+ reciters):
```
quran,tafsir,hadith,reciter,recitation,mp3,audio,prayer,salah,adhan,qibla,dua,tasbih,ramadan,muslim
```

**Ramadan season push** (weeks before Ramadan):
```
quran,tafsir,hadith,ramadan,fasting,iftar,suhoor,eid,prayer,salah,adhan,qibla,dua,dhikr,muslim
```

---

## Full keyword research (by theme)

Ranked roughly by value to this app. Bold = currently in the primary field.

### Quran
**quran**, **tafsir**, koran, mushaf, surah, ayah, juz, tajweed, transliteration, translation, saheeh, recitation, reciter, quran audio, quran offline, beginner quran

### Hadith / Sunnah (new)
**hadith**, **sunnah**, **bukhari**, muslim (Sahih Muslim), nawawi, tirmidhi, riyad, hadith qudsi, narrations, prophet, muhammad

### Prayer
**prayer**, **salah**, **adhan**, **namaz**, **qibla**, salat, salaat, azan, athan, iqama, prayer times, prayer reminder, prayer tracker, fajr, dhuhr, asr, maghrib, isha

### Places
**masjid**, mosque, kaaba, mecca, madinah, halal, halal food

### Daily worship / tools
**dua**, **dhikr**, **ramadan**, tasbih, zikr, adhkar, supplication, misbaha, tasbeeh, fasting, iftar, suhoor, eid, hijri, calendar

### Identity / audience
**muslim**, deen, iman, faith, sunni, worship, allah, revert, convert

### Arabic learning
arabic, alphabet, letters, harakat, tashkeel, learn arabic

> Terms deliberately **excluded** from the keyword field because they're in the app name/subtitle or category: al, islam, islamic, pillars.

---

## Localization (other App Store storefronts)

Each localization has its **own** 100-character keyword field. High-value additions per market:

- **Arabic (ar)**: قرآن, تفسير, حديث, صحيح البخاري, صلاة, أذان, قبلة, مسجد, دعاء, ذكر, تسبيح, رمضان, مصحف, تجويد, ختمة
- **Urdu / Pakistan, India**: `namaz` is essential (already primary); also `qurban`, `roza`, `ramzan`.
- **Turkish (tr)**: `namaz`, `ezan`, `kuran`, `kible`, `oruc`, `dua`, `zikir`.
- **Indonesian / Malay (id, ms)**: `sholat`, `adzan`, `quran`, `kiblat`, `doa`, `dzikir`, `puasa`, `tafsir`, `hadits`.
- **French (fr)**: `coran`, `priere`, `salat`, `adhan`, `qibla`, `mosquee`, `doua`, `ramadan`, `tafsir`, `hadith`.

Keep the transliteration variants that match how each region actually types - that is where most of the incremental installs come from.

---

## Companion metadata (for reference)

The keyword field is one of three ranking inputs. The others, already written elsewhere, should stay keyword-rich:

- **App name / subtitle** - carry "Islam," "Islamic," "Pillars," "Quran," "Prayer" so the keyword field doesn't have to.
- **Description** - see `App Store Description.md`; leads with Quran, Hadith, tafsir, prayer times.
- **Promotional text** - see `Promotional Text.md`; updated per release, does not affect ranking but drives conversion.

---

## Maintenance checklist

When a major feature ships:
1. Add its highest-intent term to the primary field (trim the weakest current term to stay ≤ 100 chars).
2. Add the feature to `App Store Description.md` and `Promotional Text.md`.
3. Add any new data-source attribution to `CREDITS.md` and the in-app Credits view.
4. After release, watch **App Analytics → Sources → Search** and rotate underperforming keywords using the alternates above.
