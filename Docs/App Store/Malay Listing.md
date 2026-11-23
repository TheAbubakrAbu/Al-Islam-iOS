# App Store Malay Listing

The **Malay (Malaysia)** localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store
Connect, add the Malay localization, then fill Name and Subtitle under App Information and the other four
fields on the version page. Screenshots can stay English: App Store Connect shows the primary language's
screenshots for a localization that has none of its own.
People whose device is set to Malay see this listing instead of the English one. In the Malay interface the
app keeps its Latin name, Al-Islam, and its tabs are Azan, Al-Quran, Hadis, Islam and Seting; the listing
uses the same words.

| Field | Limit | Editable without a new version? |
|---|---|---|
| Name | 30 | No |
| Subtitle | 30 | No |
| Promotional Text | 170 | Yes |
| Description | 4,000 | No |
| What's New | 4,000 | No |
| Keywords | 100 | No |

## Guidelines

- **Counts are Python `len()`** of the exact text inside each code block (the bold tally lines are for this
  file, not the store). Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Malay Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Malaysian Malay as Apple's own Malay pages and JAKIM write it, never Indonesian:** percuma (not gratis),
  muat turun (not unduh), kongsi (not bagikan), ciri (not fitur), sokongan (not dukungan), pembetulan (not
  perbaikan), luar talian, Seting, baharu. The reader is "anda", lowercase, as Apple's Malay writes it.
  The honorific is always spelled out, sallallahu 'alaihi wasallam: App Store Connect rejects the one-glyph
  ligature (U+FDFA) as an invalid character. Feature names are the labels the app shows
  (`Resources/Localizable.xcstrings`, see the glossary below).
- **al-Quran and Al-Quran.** In running text the Quran itself is al-Quran, lowercase, as Malay writes it
  mid-sentence; Al-Quran, capitalized, opens a sentence and is the tab and the start of a label (Perancang
  Al-Quran, Mukjizat Al-Quran).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma or a new sentence. A leading
  "- " bullet is fine; the English fields use the same.
- **Plain ASCII in every field:** straight quotes and apostrophes ("Bukhari 5", as-Sa'di, Kutub Tis'ah), no
  curly quotes and no ligatures, so nothing gives App Store Connect a character to refuse. Western digits with
  the comma for thousands (50,000), as Malaysia writes them. No version numbers.
- **ALL-CAPS section headers,** as the English description has them: the Latin script keeps them, and they
  are the only structure the store renders.
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  iMessage, iOS. Apple's own features take Apple's Malay names: Pusat Kawalan, Aktiviti Langsung, Seting.
- **Malaysian spellings in the name, subtitle and keywords:** solat, azan, kiblat, hadis, doa, zikir, juzuk,
  tajwid, as the app's own labels have them. The Indonesian spellings (sholat, adzan, hadits, dzikir) belong
  to the Indonesian listing.
- **Be honest about what is still English:** the in-depth articles of the Islam tab; AI search by meaning,
  which matches English phrases only; and the Quran, hadith and dua translations, which are English beside
  the Arabic. The description says terjemahan bahasa Inggeris wherever a Malay reader would otherwise expect
  a Malay translation, and the listing never promises one.
- **Siri speaks Malay.** The app's Siri phrases have Malay versions, so the listing invites Malay requests
  (unlike the Urdu listing, which has to send Urdu readers to English or Arabic).
- **The interface languages:** fifteen since 2026-11-21 (Malay, English, Arabic, Urdu, Indonesian, Turkish,
  French, Bangla, Russian, Hindi, German, Spanish, Malayalam, Tamil and Dutch), chosen per app in iOS Settings; the description names three and the count. The Malay interface keeps the Latin surah names (Al-Baqarah) with their meaning in Malay, and the
  58-lesson Tajweed Course is in Malay too.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md` and `Urdu Listing.md`: when a field changes for a feature,
  change it here too.

## 1. Name

Names are unique across the store, so a bare Al-Islam will not be accepted. The name keeps Al-Islam first,
then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Quran, Azan, Hadis
```

**29 / 30 characters.**

The app's three sections as bare words, each a search term of its own: the same shape as the Arabic and Urdu
names. The tab is Al-Quran, but "Al-Quran, Azan, Hadis" would take the name to 32 characters, and the bare
Quran is the word people type after "al" anyway; the keyword field adds the one-word spelling alquran.

## 2. Subtitle

```
Waktu Solat, Kiblat dan Tafsir
```

**30 / 30 characters.**

"Waktu solat" is how Malaysia says prayer times (the app's label Waktu Solat) and the most searched prayer
phrase. With the keyword field's jakim and sembahyang it also answers "waktu solat jakim" and "waktu
sembahyang".

## 3. Promotional Text

Leads with the Malay interface, and names Siri in Malay, as the Arabic text names Siri in Arabic. Update it
with the next release like the English one.

```
Baharu: antara muka penuh dalam bahasa Melayu dan Siri yang memahami bahasa Melayu. Al-Quran, hadis dan waktu solat dalam satu aplikasi percuma, tanpa iklan.
```

**157 / 170 characters.**

## 4. Description

A Malay rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers in
Malay. Four differences from the English, three of them shared with the Urdu listing:
- **Translations:** the Quran line says terjemahan bahasa Inggeris, because the app's Quran translations are
  English.
- **Languages:** the first line of MENGIKUT CITA RASA ANDA gives the count of 15 interface languages (naming Malay, English and Arabic), and
  says the Islam tab's in-depth articles are still English.
- **Tajweed Course:** called dalam bahasa Melayu, since its 58 lessons are translated.
- **JAKIM:** the calculation line names JAKIM as the method suggested in Malaysia (the app's automatic choice
  for the country, `PrayerCalculationMethods.swift`).

Malay runs about a fifth longer than English, so every bullet is cut to its feature names to stay under
4,000, and the field is nearly full: before adding a line for a new feature, shorten one. Lists follow Malay
style, with no comma before the last dan.

```
Al-Islam ialah teman anda untuk mengamalkan Islam, sama ada anda Muslim sejak lahir, mualaf atau baru mengenali agama ini. Al-Quran, hadis, tafsir, waktu solat, penjejak solat dan carian AI pada peranti dalam satu aplikasi ringkas: percuma, tanpa iklan dan peribadi.

AL-QURAN LENGKAP
- Baca mengikut surah, juzuk atau halaman, sebagai senarai atau mushaf, dan dua halaman bersebelahan dalam landskap.
- Teks Arab, transliterasi dan terjemahan bahasa Inggeris, dengan warna tajwid pilihan anda.
- Tafsir setiap ayat: Ibn Kathir, Maarif Ul Quran dan Tazkirul Quran (Inggeris), serta Ibn Kathir, al-Tabari dan as-Sa'di (Arab), di luar talian.
- Kajian Perkataan: ketik perkataan dua kali untuk maksud, tatabahasa, akar kata dan setiap tempat ia muncul.
- Lebih 60 qari, muat turun luar talian, Ulang Tanpa Henti dan Mainkan dari Ayat hingga akhir halaman, surah, juzuk atau al-Quran.
- Hafs dan 19 riwayat lain daripada sepuluh qiraat, dibandingkan dalam Penjelajah Qiraat.
- Ayat Serupa, Semak Imbas Mengikut Tema, Perkataan Hari Ini, penanda buku dan nota.

HAFAZAN DAN ULANG KAJI
- Perancang Al-Quran: tetapkan tarikh khatam dan tambah pelan Ulang Kaji untuk surah hafazan anda.
- Mod Ujian menyembunyikan teks hingga anda mengetik, untuk menguji hafazan setiap ayat.

KITAB HADIS UTAMA
- Kutub Tis'ah (Bukhari, Muslim, an-Nasa'i, Abu Dawud, at-Tirmidhi, Ibn Majah, Muwatta Malik, ad-Darimi, Musnad Ahmad), koleksi 40 hadis serta kitab seperti Riyad as-Salihin.
- Teks Arab dan terjemahan bahasa Inggeris, rantaian perawi, Hadis Hari Ini, penanda buku dan carian rujukan seperti "Bukhari 5".
- Cari dalam satu kitab atau lebih 50,000 hadis, semuanya terbina dan berfungsi di luar talian.

AI PADA PERANTI
- Cari al-Quran dan hadis mengikut makna: "patience in hardship" menemui ayat tentang sabar. Carian makna menggunakan frasa bahasa Inggeris buat masa ini.
- Dengan Apple Intelligence, Tanya AI menjawab daripada ayat dan hadis yang dipetiknya, tanpa memberi fatwa.

WAKTU SOLAT, KIBLAT DAN PENJEJAK
- Waktu solat tepat dikira pada peranti, dengan kaedah dicadangkan bagi kawasan anda, seperti JAKIM di Malaysia.
- Langit hidup di atas waktu solat: matahari pada lengkungnya, bintang malam, bulan 3D pada fasa sebenar serta cuaca pilihan.
- Kompas kiblat, bunyi azan, pemberitahuan awal, Mod Musafir dan Mod Peringatan Berulang yang mengingatkan anda hingga anda solat.
- Penjejak Solat: tandakan solat dengan satu ketikan, dengan rentetan, Hari Sempurna dan kalendar berwarna.
- Widget solat dan Ayat Pilihan, kawalan Pusat Kawalan, Aktiviti Langsung Ramadan dan Apple Watch.

IBADAH HARIAN DAN PEMBELAJARAN
- Hari Ini: ayat, hadis, doa dan nama Allah setiap hari, kad Tazkirah Hari Ini dan Peringatan Sunnah.
- Zikir, Hisn al-Muslim dan koleksi doa dengan sumber dan audio, pengira tasbih dan jurnal.
- Asmaul Husna secara mendalam, Mukjizat Al-Quran, Pembuktian Islam serta ilmu hadis.
- Belajar huruf Arab dengan Ujian Bacaan 21 tahap, serta Kursus Tajwid 58 pelajaran dalam bahasa Melayu dan Ujian Tajwid.
- Panduan Amali, Rukun Islam dan Iman, kalkulator zakat dan faraid, Kalendar Hijrah, serta pencari masjid dan makanan halal.

MENGIKUT CITA RASA ANDA
- Antara muka dalam 15 bahasa, termasuk Melayu, Inggeris dan Arab, mengikut pilihan bahasa aplikasi ini dalam Seting iOS. Artikel mendalam tab Islam masih dalam bahasa Inggeris.
- Mod Ringkas mengekalkan perkara asas sahaja. Tukar ke Penuh pada bila-bila masa.
- Sandarkan profil ke iCloud anda dan pulihkan pada mana-mana peranti.
- Saiz teks, fon Arab, warna aksen dan langit, serta carian pada setiap halaman seting.
- iPhone, iPad, Mac dan Apple Watch, serta pelekat Islam untuk iMessage.

PERCUMA, TANPA IKLAN DAN PERIBADI
Al-Islam percuma sepenuhnya. Tiada iklan, akaun, langganan atau penjejakan: tiada apa-apa yang anda lakukan dikumpul atau dikongsi.

Sama ada anda mencari waktu solat, al-Quran, hadis Nabi Muhammad sallallahu 'alaihi wasallam, atau kefahaman tentang Islam, muat turun Al-Islam hari ini.
```

**3,979 / 4,000 characters.**

## 5. What's New

The release that adds the Malay interface, with the other eleven new languages beside it. Only the interface is here
so far: the Urdu listing's "Urdu interface" and "Choosing the language" sections, adapted. The right-to-left
and digit lines have no Malay counterpart and are gone; the surah-name line says the names stay Latin with a
Malay meaning; and Siri, which the Urdu could only send to English or Arabic, takes Malay requests here, as the
Arabic listing's Siri line does in Arabic. The language section names the other eleven new languages, since all
twelve ship in one release, and says what is still English.

```
Seluruh aplikasi kini dalam bahasa Melayu, daripada Al-Quran, Azan dan Hadis hingga ke Seting.

Antara muka bahasa Melayu:
- Semua skrin, menu, seting, pemberitahuan dan widget dalam bahasa Melayu, pada iPhone, iPad, Mac dan Apple Watch.
- Nama surah kekal dalam ejaan Latin, seperti Al-Baqarah, bersama maknanya dalam bahasa Melayu.
- Seluruh Kursus Tajwid, 58 pelajaran, dalam bahasa Melayu.
- Pemberitahuan solat dalam bahasa Melayu.
- Bercakap dengan Siri dalam bahasa Melayu: mainkan atau buka surah, sambung bacaan dari tempat anda berhenti dan tanya tentang solat seterusnya.

Pilihan bahasa:
- Aplikasi mengikut bahasa yang anda pilih untuknya dalam Seting iOS, dan baris Bahasa dalam Seting aplikasi membawa anda ke sana.
- Apabila anda menukar bahasa, pemberitahuan anda dijadualkan semula dalam bahasa baharu.
- Bahasa Indonesia, Turki, Perancis, Bengali, Rusia, Hindi, Jerman, Sepanyol, Malayalam, Tamil dan Belanda turut tiba dalam versi ini, menyertai bahasa Inggeris, Arab dan Urdu.
- Terjemahan al-Quran, hadis dan doa kekal dalam bahasa Inggeris, bersama teks Arab.
- Buat masa ini, carian mengikut makna menggunakan frasa bahasa Inggeris.
- Artikel mendalam dalam tab Islam masih dalam bahasa Inggeris buat masa ini.
```

**1,234 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Al-Quran:, Al-Adhan:, Al-Hadith:, Alatan Islam:, Seting:, Pembetulan pepijat dan penambahbaikan:). Keep
the Malay interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al, Islam, Quran, Azan, Hadis,
Waktu, Solat, Kiblat, dan, Tafsir); as in the Arabic and Urdu fields, a word in another form (alquran beside
the name's Quran) is a search term of its own.

```
alquran,surah,yasin,tajwid,hafazan,mengaji,doa,zikir,tasbih,bukhari,sunnah,ramadan,sembahyang,jakim
```

**99 / 100 characters.**

Why these terms:
- **alquran:** the one-word spelling many people type for al-Quran; the name has the bare Quran.
- **surah, yasin:** surah searches, and "surah yasin", one of the most searched recitations in Malaysia.
- **tajwid, hafazan, mengaji:** the colored tajweed and the Malay Tajweed Course; hafazan for memorization
  (Test Mode, the Revision plan, the Quran Planner), the Malaysian word for hifz; mengaji, the everyday word
  for learning to recite, with the Reading Test.
- **doa, zikir, tasbih, ramadan:** the daily worship tools, the tasbih counter and the Ramadan season.
- **bukhari, sunnah:** Sahih al-Bukhari, the most searched collection, and the Sunnah.
- **sembahyang, jakim:** with the subtitle's waktu, "waktu sembahyang", the everyday Malaysian word beside
  solat; and "waktu solat jakim", answered by the JAKIM method the app suggests in Malaysia.

Left out for room, to rotate in from App Analytics: juzuk, qari, masjid, puasa, penjejak (for "penjejak
solat", the Prayer Tracker), hadith (the English spelling beside the name's Hadis), zakat, muslim.
Deliberately excluded: terjemahan and melayu (for "al quran terjemahan melayu"), since the app has no Malay
translation of the Quran and those searchers would leave; and the Indonesian spellings (sholat, adzan,
hadits). If Apple's search turns out to treat alquran as the name's Quran, it is the first to swap.

## Glossary

The Malay the app shows for the features the listing names (`Resources/Localizable.xcstrings`; the agreed
labels are in the localization's `labels.json`).

| English | Malay |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Azan, Al-Quran, Hadis, Islam, Seting |
| Simple Mode / Full | Mod Ringkas / Penuh |
| Prayer Tracker, Prayer Times | Penjejak Solat, Waktu Solat |
| Streak, Perfect Days | rentetan, Hari Sempurna |
| Test Mode | Mod Ujian |
| Quran Planner, Revision, khatm | Perancang Al-Quran, Ulang Kaji, khatam |
| Word Study (Meaning, Grammar, Root) | Kajian Perkataan (maksud, Tatabahasa, Akar Kata) |
| Qiraat Explorer, riwayah, Hafs | Penjelajah Qiraat, riwayat, Hafs |
| Traveling Mode | Mod Musafir |
| Nagging Mode | Mod Peringatan Berulang |
| Qibla Compass, Adhan Sound, Prenotification | Kompas Kiblat, Bunyi Azan, Pemberitahuan Awal |
| Repeat Forever, Play From Ayah | Ulang Tanpa Henti, Mainkan dari Ayat |
| Similar Ayahs, Browse by Theme, Word of the Day | Ayat Serupa, Semak Imbas Mengikut Tema, Perkataan Hari Ini |
| Hadith of the Day, Chain of Narrators | Hadis Hari Ini, Rantaian Perawi |
| Ask AI | Tanya AI |
| Chosen Ayah (widget) | Ayat Pilihan |
| Today, Reminder of the Day | Hari Ini, Tazkirah Hari Ini |
| Sunnah Reminders, Daily Reminder | Peringatan Sunnah, Peringatan Harian |
| Transliteration, Bookmarks, Notes | Transliterasi, Penanda Buku, Nota |
| 99 Names of Allah | Asmaul Husna |
| Journal, Tasbih Counter | Jurnal, Pengira Tasbih |
| Reading Test, Tajweed Course, Tajweed Test | Ujian Bacaan, Kursus Tajwid, Ujian Tajwid |
| Proving Islam, Miracles of the Quran | Pembuktian Islam, Mukjizat Al-Quran |
| Pillars & Beliefs (the Pillars of Islam and Faith) | Rukun & Akidah (Rukun Islam dan Rukun Iman) |
| Masjid Locator, Halal Food Locator | Pencari Masjid, Pencari Makanan Halal |
| Zakah Calculator, Inheritance Calculator | Kalkulator Zakat, Kalkulator Faraid |
| Hijri Calendar, How-To Guides | Kalendar Hijrah, Panduan Amali |
| Text Size, Arabic Font, Accent Color, Sky Colors | Saiz Teks, Fon Arab, Warna Aksen, Warna Langit |
| Language (Settings row) | Bahasa |
| Control Center, Live Activities (Apple's names) | Pusat Kawalan, Aktiviti Langsung |
| The Six Books (the Nine follow its form) | Kutub Sittah (Kutub Tis'ah) |
