# App Store Indonesian Listing

The **Indonesian** (`id`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App
Store Connect, add the Indonesian localization, then fill Name and Subtitle under App Information and the other
four fields on the version page. Screenshots can stay English: App Store Connect shows the primary language's
screenshots for a localization that has none of its own.
People whose device is set to Indonesian see this listing instead of the English one. In the Indonesian
interface the app keeps its Latin name, Al-Islam (on the Home Screen too), and its tabs are Azan, Al-Qur'an,
Hadis, Islam and Pengaturan; the listing uses the same words.

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
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Indonesian Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Bahasa Indonesia baku as Apple's own Indonesian pages read it**, addressing the reader as "Anda", with
  Islamic terms as KBBI and Kemenag write them (salat, azan, kiblat, hadis, zikir, tajwid, murajaah). The
  honorific is always spelled out, "(shallallahu 'alaihi wa sallam)": App Store Connect rejects the one-glyph
  ligature (U+FDFA) as an invalid character. Feature names are the labels the app shows (the Indonesian
  translation of `Resources/Localizable.xcstrings`, see the glossary below), and Apple's own features take
  Apple's Indonesian names (Pengaturan, Pusat Kontrol, Aktivitas Langsung, Layar Terkunci, Pintasan).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma or a new sentence. A leading
  "- " bullet is fine; the English fields use the same.
- **Plain ASCII in every store field:** straight quotes and the straight apostrophe (Al-Qur'an, "Bukhari 5"),
  as the app's labels write them, never curly ones. On 2026-10-29 App Store Connect refused characters in
  Al-Islam's Urdu fields; none of those can occur in Latin text, and ASCII leaves no doubt. Western digits with
  a dot for thousands (50.000), as Indonesian writes them. No version numbers.
- **App names stay Latin:** Al-Islam, Al-Adhan, Al-Quran. In a sentence the app is plain Al-Islam, as the
  app's own Indonesian strings write it ("Al-Islam menggunakan lokasi Anda"), and "app" is Apple's Indonesian
  word for an app, as in the catalog (Buka App di). Brand names stay Latin too: Apple, iCloud, Siri,
  Apple Watch, Apple Intelligence, iPhone, iPad, Mac, iMessage.
- **Search spellings go in the keyword field only.** The name, subtitle and description write the baku forms
  the app uses (salat, azan, hadis, zikir, Ramadan). The keyword field adds the spellings Indonesians type
  (sholat, adzan, hadits, dzikir, ramadhan): each is a search term of its own.
- **Be honest about what is still English:** the in-depth articles of the Islam tab, AI search by meaning
  (English phrases only), the Quran and hadith translations (English, beside the Arabic), and Siri, which has
  no Indonesian, so its phrases are said in English.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md` and `Urdu Listing.md`: when a field changes for a feature,
  change it here too.

## 1. Name

The name keeps Al-Islam first, then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Al-Qur'an & Hadis
```

**28 / 30 characters.**

The app's Quran and Hadith tabs as the Indonesian interface labels them. The Urdu and Arabic names list three
sections; Al-Islam | Al-Qur'an, Azan, Hadis would make 33, so Azan moves to the subtitle. Al-Qur'an is the
Kemenag spelling the app uses; the keyword field adds quran, the form most people type.

## 2. Subtitle

```
Waktu Salat, Azan & Kiblat
```

**26 / 30 characters.**

Waktu Salat is the app's label for Prayer Times, Azan its Adhan tab, Kiblat the Qibla. With the keyword
field's jadwal and sholat it also answers "jadwal sholat", the usual Indonesian search for prayer times, and
"waktu sholat". Tafsir, which the Urdu and Arabic subtitles carry, moves to the keyword field.

## 3. Promotional Text

Leads with the Indonesian interface. Update it with the next release like the English one.

```
Baru: antarmuka lengkap dalam bahasa Indonesia, dengan nama surah Latin beserta artinya. Al-Qur'an, hadis, dan waktu salat dalam satu app gratis tanpa iklan.
```

**157 / 170 characters.**

## 4. Description

An Indonesian rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers
translated in capitals. Four lines say what is English: the Quran line and the hadith line name an English
translation (terjemahan bahasa Inggris), the AI line says search by meaning still works from English phrases,
and the interface line says the Islam tab's articles are English. Indonesian runs about a fifth longer than
English, so the lines are tighter than the English ones to stay under 4,000: the Nine books go by the name
Indonesian readers know them by, Kitab 9 Imam, with each imam's name, and the locators and calculators are
named generically (as the English names them) rather than by their full labels.

```
Al-Islam menemani Anda menjalankan Islam, baik Anda Muslim sejak lahir, mualaf, maupun sedang mengenal Islam. Al-Qur'an, hadis, tafsir, waktu salat, pelacak salat, dan pencarian AI di perangkat dalam satu app: gratis, tanpa iklan, dan menjaga privasi Anda.

AL-QUR'AN LENGKAP
- Baca per surah, juz, atau halaman, dalam mode daftar atau halaman, dengan dua halaman berdampingan saat lanskap.
- Teks Arab, transliterasi, dan terjemahan bahasa Inggris berdampingan, dengan warna tajwid pilihan Anda.
- Tafsir setiap ayat: Ibn Kathir, Maarif Ul Quran, dan Tazkirul Quran (Inggris), serta Ibn Kathir, al-Tabari, dan as-Sa'di (Arab), tersedia offline.
- Kajian Kata: ketuk dua kali sebuah kata untuk arti, tata bahasa, akar kata, dan setiap kemunculannya.
- Lebih dari 60 qari, unduhan offline, Ulangi Terus, dan Putar dari Ayat Ini hingga akhir halaman, surah, juz, atau Al-Qur'an.
- Hafs dan 19 riwayat lain dari Sepuluh Qiraat, dibandingkan berdampingan di Penjelajah Qiraat.
- Ayat Serupa, Jelajahi Menurut Tema, Kata Hari Ini, penanda, dan catatan.

MENGHAFAL DAN MURAJAAH
- Perencana Al-Qur'an: tentukan tanggal khatam, dan tambahkan rencana Murajaah untuk surah yang Anda hafal.
- Mode Tes menyembunyikan teks sampai Anda mengetuk, untuk menguji hafalan ayat demi ayat.

KITAB HADIS UTAMA
- Kitab 9 Imam (Bukhari, Muslim, an-Nasa'i, Abu Dawud, at-Tirmidhi, Ibn Majah, Malik, ad-Darimi, Ahmad), kitab Arbain, dan kitab seperti Riyad as-Salihin.
- Teks Arab dan terjemahan bahasa Inggris, sanad dan halaman tiap perawi, Hadis Hari Ini, penanda, dan rujukan seperti "Bukhari 5".
- Cari di satu kitab atau di lebih dari 50.000 hadis, semuanya tersedia offline.

AI DI PERANGKAT
- Cari di Al-Qur'an dan hadis menurut makna, bukan kata: "patience in hardship" menemukan ayat tentang sabar. Pencarian makna masih memakai frasa bahasa Inggris.
- Dengan Apple Intelligence, Tanya AI menjawab dari ayat dan hadis yang dikutipnya, tanpa memberi fatwa.

WAKTU SALAT, KIBLAT, DAN PELACAK
- Waktu salat akurat yang dihitung di perangkat, dengan metode yang disarankan untuk wilayah Anda.
- Langit yang hidup di atas waktu salat: matahari di busurnya, bintang di malam hari, bulan 3D sesuai fasenya, dan cuaca bila Anda mau.
- Kompas Kiblat, suara azan, Notifikasi Awal, Mode Musafir, dan Mode Pengingat Berulang, yang mengingatkan sampai Anda salat.
- Pelacak Salat: tandai salat dengan sekali ketuk, beserta runtunan, Hari Sempurna, dan kalender berwarna.
- Widget waktu salat dan Ayat Pilihan, kontrol Pusat Kontrol, Aktivitas Langsung saat Ramadan, dan Apple Watch.

IBADAH HARIAN DAN BELAJAR
- Hari Ini: ayat, hadis, doa, dan Nama Allah harian, kartu Nasihat Hari Ini, dan Pengingat Sunah.
- Zikir, Hisn al-Muslim, dan kumpulan doa dengan sumber dan audio, Penghitung Tasbih, dan Jurnal Islami.
- Asmaul Husna secara mendalam, Mukjizat Al-Qur'an, Bukti Kebenaran Islam, serta Ilmu-Ilmu Hadis.
- Pelajari huruf hijaiah dengan Tes Membaca 21 tingkat, dan tajwid di Kursus Tajwid 58 pelajaran serta Tes Tajwid.
- Panduan Praktis, Rukun Islam dan Iman, kalkulator zakat dan waris, Kalender Hijriah, serta pencari masjid dan makanan halal.

SESUAI CARA ANDA
- Antarmuka dalam 12 bahasa, termasuk Indonesia, Inggris, dan Arab, sesuai pilihan Anda untuk app ini di Pengaturan iOS. Artikel mendalam di tab Islam masih berbahasa Inggris.
- Mode Sederhana menampilkan yang pokok saja. Beralih ke mode Lengkap kapan saja.
- Cadangkan profil bernama ke iCloud Anda dan pulihkan di perangkat mana pun.
- Ukuran teks, font Arab, warna aksen dan langit, serta pencarian di setiap halaman pengaturan.
- iPhone, iPad, Mac, dan Apple Watch, serta stiker Islami untuk iMessage.

GRATIS, TANPA IKLAN, DAN MENJAGA PRIVASI
Al-Islam sepenuhnya gratis. Tanpa iklan, akun, langganan, atau pelacakan: tidak ada aktivitas Anda yang dikumpulkan atau dibagikan.

Baik Anda mencari waktu salat, Al-Qur'an, hadis Nabi Muhammad (shallallahu 'alaihi wa sallam), maupun pemahaman Islam yang lebih dalam, unduh Al-Islam hari ini.
```

**3,985 / 4,000 characters.**

## 5. What's New

The release that adds the Indonesian interface; all nine new languages ship in one release, so the
section Bahasa baru lainnya names the other eight. Only the
interface notes are here so far. The Urdu text's right-to-left and digit lines have no Indonesian counterpart
and are left out; in their place are the Latin surah names with their Indonesian meanings, the Indonesian
prayer names (the catalog's Subuh, Zuhur, Asar, Magrib, Isya), and a line saying the translations are English.

```
Antarmuka Al-Islam kini tersedia dalam bahasa Indonesia, dari Al-Qur'an, Azan, dan Hadis hingga Islam dan Pengaturan.

Antarmuka bahasa Indonesia:
- Semua layar, menu, pengaturan, notifikasi, dan widget dalam bahasa Indonesia, di iPhone, iPad, Mac, dan Apple Watch.
- Nama surah tetap ditulis dalam huruf Latin, seperti Al-Baqarah, disertai artinya dalam bahasa Indonesia.
- Nama salat dalam bahasa Indonesia: Subuh, Zuhur, Asar, Magrib, dan Isya.
- Notifikasi salat tampil dalam bahasa Indonesia.
- Seluruh Kursus Tajwid 58 pelajaran dalam bahasa Indonesia.
- Terjemahan Al-Qur'an dan hadis saat ini tersedia dalam bahasa Inggris, di samping teks Arabnya.

Bahasa baru lainnya:
- Al-Islam kini juga tersedia dalam bahasa Melayu, Turki, Prancis, Bengali, Rusia, Hindi, Jerman, dan Spanyol, di samping bahasa Inggris, Arab, dan Urdu.

Memilih bahasa:
- App ini mengikuti bahasa yang Anda pilih untuknya di Pengaturan iOS, dan baris Bahasa di pengaturan app membawa Anda ke sana.
- Saat bahasa diganti, notifikasi Anda dijadwalkan ulang dalam bahasa yang baru.
- Siri tidak tersedia dalam bahasa Indonesia, jadi bicaralah kepada Siri dalam bahasa Inggris.
- Artikel mendalam di tab Islam dan pencarian berdasarkan makna saat ini masih menggunakan bahasa Inggris.
```

**1,260 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Al-Qur'an:, Azan:, Hadis:, Alat Islami:, Pengaturan:, Perbaikan dan pengoptimalan:). Keep the Indonesian
interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al-Islam, Al-Qur'an, Hadis, Waktu,
Salat, Azan, Kiblat); as in the Urdu and Arabic fields, a spelling of the same word (quran beside Al-Qur'an,
sholat beside Salat, adzan beside Azan, hadits beside Hadis) is a search term of its own.

```
quran,jadwal,sholat,adzan,arah,tafsir,hadits,doa,dzikir,tasbih,tajwid,murottal,hafalan,ramadhan,juz
```

**99 / 100 characters.**

Why these terms:
- **quran:** the name's Al-Qur'an as most people type it, without the apostrophe ("al quran", "quran
  online").
- **jadwal, sholat, arah:** "jadwal sholat", with sholat beside the subtitle's Salat for "jadwal salat" and
  "waktu sholat"; arah for "arah kiblat" with the subtitle's Kiblat.
- **adzan, hadits, dzikir, ramadhan:** the spellings Indonesians type beside the baku azan, hadis, zikir and
  Ramadan the listing writes (adzan pairs with the subtitle's Azan, hadits with the name's Hadis).
- **tafsir:** the tafsir for every ayah, which the subtitle had no room for.
- **doa, tasbih:** the dua collections and Hisn al-Muslim, and the Penghitung Tasbih.
- **tajwid, murottal, hafalan, juz:** the colored tajweed and the Kursus Tajwid; murottal, the Indonesian word
  for recorded recitation (over 60 qari); hafalan for Mode Tes and the Murajaah plan ("hafalan quran"); juz for
  reading by juz and "juz amma".

Left out for room, to rotate in from App Analytics: alquran, asmaul and husna (for Asmaul Husna), yasin,
amma, puasa, masjid, bukhari, sunah, hijriah, kalender, mengaji, tracker. Deliberately excluded: terjemahan,
terjemah and indonesia ("al quran terjemahan" wants an Indonesian translation, and the app's translations are
English), kemenag (another publisher's name), and imsak or imsakiyah (the app shows no imsak time; its
Ramadan countdown runs to the end of suhoor at Subuh). If Apple's search turns out to drop the apostrophe in
Al-Qur'an, quran is redundant and is the first to swap.

## Glossary

The Indonesian the app shows for the features the listing names (the Indonesian translation of
`Resources/Localizable.xcstrings`). The one marked * has no label of its own: Kitab 9 Imam is the name
Indonesian readers know the Nine books by (the catalog's label for the Six Books is Kutubus Sittah).

| English | Indonesian |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Azan, Al-Qur'an, Hadis, Islam, Pengaturan |
| Prayer Times, Qibla Compass, Prenotification | Waktu Salat, Kompas Kiblat, Notifikasi Awal |
| Simple Mode / Full | Mode Sederhana / Lengkap |
| Prayer Tracker, Streak, Perfect Days | Pelacak Salat, runtunan, Hari Sempurna |
| Test Mode | Mode Tes |
| Quran Planner, Revision, Khatm | Perencana Al-Qur'an, Murajaah, khatam |
| List mode, page mode | mode daftar, mode halaman |
| Transliteration | transliterasi |
| Word Study | Kajian Kata |
| Qiraat Explorer, the Ten Qiraat, riwayah | Penjelajah Qiraat, Sepuluh Qiraat, riwayat |
| Traveling Mode | Mode Musafir |
| Nagging Mode | Mode Pengingat Berulang |
| Repeat Forever, Play From Ayah | Ulangi Terus, Putar dari Ayat Ini |
| Similar Ayahs, Browse by Theme, Word of the Day | Ayat Serupa, Jelajahi Menurut Tema, Kata Hari Ini |
| Bookmarks, Notes | penanda, catatan |
| The Nine books*, the forty collections, Chain of Narrators | Kitab 9 Imam, kitab Arbain (KITAB-KITAB ARBAIN), Sanad Perawi |
| Hadith of the Day | Hadis Hari Ini |
| Ask AI, Search by meaning | Tanya AI, Cari berdasarkan makna |
| Chosen Ayah (widget), Control Center, Live Activity | Ayat Pilihan, Pusat Kontrol, Aktivitas Langsung |
| Today, Name of Allah, Reminder of the Day | Hari Ini, Nama Allah, Nasihat Hari Ini |
| Sunnah Reminders, Daily Reminder | Pengingat Sunah, Pengingat Harian |
| Dhikr, Hisn al-Muslim, Tasbih Counter, Islamic Journal | zikir, Hisn al-Muslim, Penghitung Tasbih, Jurnal Islami |
| 99 Names of Allah | Asmaul Husna |
| Miracles of the Quran, Proving Islam, The Sciences of Hadith | Mukjizat Al-Qur'an, Bukti Kebenaran Islam, Ilmu-Ilmu Hadis |
| Arabic Alphabet, Reading Test | Huruf Hijaiah, Tes Membaca |
| Tajweed Course, Tajweed Test | Kursus Tajwid, Tes Tajwid |
| How-To Guides, The Five Pillars and Six Beliefs | Panduan Praktis, Lima Rukun Islam dan Enam Rukun Iman |
| Zakah Calculator, Inheritance Calculator, Hijri Calendar | Kalkulator Zakat, Kalkulator Waris, Kalender Hijriah |
| Masjid Locator, Halal Food Locator | Pencari Masjid, Pencari Makanan Halal |
| Language (Settings row) | Bahasa |
| Fajr, Dhuhr, Asr, Maghrib, Isha | Subuh, Zuhur, Asar, Magrib, Isya |
| surah meanings (surah.meaning.2) | Sapi Betina (Al-Baqarah) |
