# App Store German Listing

The **German** (`de`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. App Store
Connect has one German localization, German, and it serves every German-speaking storefront (Germany, Austria
and Switzerland among them). Fill Name and Subtitle under App Information and the other four fields on the
version page. Screenshots can stay English: App Store Connect shows the primary language's screenshots for a
localization that has none of its own.
People whose device is set to German see this listing instead of the English one. In the German interface the
app keeps its Latin name, Al-Islam (the home-screen name too), and its tabs are Adhan, Koran, Hadith, Islam and
Einstellungen; the listing uses the same words.

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
  file, not the store). The fields hold no no-break space; if one is ever added (before a % or a unit), it
  counts as one character, as it does in App Store Connect. Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/German Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **German as Apple's own German pages write it**, addressing the reader with "du", lowercase (lies, tippe,
  lade, deine), in sentence case: only the first word and the nouns are capitalized, as German writes them
  (Gebetszeiten, Qibla, Tafsir), never English Title Case. The section headers stay ALL CAPS with their
  umlauts, and ß becomes SS (DIE GROSSEN HADITHSAMMLUNGEN). The terms are the ones German-speaking Muslims use
  and the app's glossary fixes (Gebet, Gebetszeiten, Adhan, Qibla, Sure, Vers, Juz, Tajwid, Tafsir, Khatm,
  Rezitator, Dua with the plural Duas, Hadith with the plural Hadithe, Lesarten for the qiraat, Riwaya with the
  plural Riwayat) in the respectful register (der Koran, der Prophet Muhammad). The honorific is always spelled
  out, "(Allahs Segen und Frieden auf ihm)": App Store Connect rejects the one-glyph ligature (U+FDFA) as an
  invalid character. Feature names are the labels the app shows (the German `labels.json` and catalog, see the
  glossary below).
- **A label keeps its exact wording.** German declines adjectives, so a label whose ending would change in a
  sentence (Perfekte Tage, Einfacher Modus, Islamisches Tagebuch) stands bare in a list or before a colon,
  where its form does not change. A label that is a verb phrase or a lone adjective stands in „…“ so it reads
  as a name, the way the app's own German sentences quote it: „Ab diesem Vers anhören“, „Endlos wiederholen“,
  „Nach Themen erkunden“, „KI fragen“, „Moscheen finden“, „Vollständig“ (the Full choice). A label that opens
  with an article drops its capital inside a sentence (die Hadithwissenschaften, the label Die
  Hadithwissenschaften).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma, a semicolon or a new sentence. A
  leading "- " bullet is fine; the English fields use the same. The hyphens of German compounds (Tajwid-Kurs,
  Koran-Planer, 3D-Mond) and of a shared compound part (Zakat- und Erbschaftsrechner, Akzent- und
  Himmelsfarben) are spelling, not dashes.
- **German punctuation and numbers:** the German quotes „…“ (U+201E, U+201C) throughout; the typographic
  apostrophe ’ in transliterations (as-Sa’di, Nasa’i), as the catalog writes them (Jumu’a); after a colon, a
  capital for a full sentence (Wortanalyse: Tippe …) and lowercase for a fragment (Koran-Planer: ein Enddatum
  …), as German writes it. A period as the thousands separator (50.000), Western digits; a verse reference
  keeps its bare colon (5:27). No version numbers.
- **If App Store Connect refuses a field.** On 2026-10-29 it rejected two of Al-Islam's Urdu fields ("This
  field contains one or more invalid characters"), and the curly quotes were among the four suspects, never
  pinned down (`Urdu Listing.md`). „…“ are standard in German store text and Apple's own German pages use them,
  so they stay; if a German field is refused, swap „…“ for plain "quotes" first, then ’ for ', and re-count.
- **Umlauts and ß always**, wherever a word has them (Übersetzung, heißen, DIE GROSSEN): they are the correct
  spelling, in the keyword field too (this one happens to need none).
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  iMessage. Apple's own features take Apple's German names: Widget, Kontrollzentrum (its controls:
  Steuerelemente), Live-Aktivität, Sperrbildschirm, Querformat (landscape), Sticker, Mitteilungen
  (notifications), Account, Abonnement, and Einstellungen for the Settings app, written iOS-Einstellungen where
  it could be read as the app's own Einstellungen tab.
- **Books and scholars keep the app's Latin transliterations** (Bukhari, Muslim, Abu Dawud, Ibn Kathir,
  al-Tabari, as-Sa’di, Riyad as-Salihin), as the German interface writes them and as it writes surah names
  (Al-Baqarah), so the reference lookup keeps the spelling the search reads, "Bukhari 5", and a tile the app
  names in Latin keeps that label (Hisn al-Muslim). For room, the nine books drop the Arabic article (Nasa’i,
  Tirmidhi, Darimi, where the English has an-Nasa'i, at-Tirmidhi, ad-Darimi) and Muwatta Malik is Muwatta, as
  in the French listing.
- **Be honest about what is still English:** the in-depth articles of the Islam tab; AI search by meaning,
  which matches English phrases only; and the translations: every Quran translation in the app is English (The
  Clear Quran, Saheeh International and the comparison sheet's editions), and so are the hadith and dua
  translations beside the Arabic. There is no German translation of the Quran, so the description says
  "englische Übersetzung" and the keyword field leaves out übersetzung and deutsch. Siri, unlike in the
  Indonesian listing, does speak German here: the app ships German Siri phrases
  (`de.lproj/AppShortcuts.strings`, and the Watch copy).
- **One text for every German-speaking storefront.** Swiss Standard German writes ss for ß; the listing keeps
  the ß of Germany and Austria for all of them rather than maintain two texts, as the French listing keeps the
  France spacing for Quebec.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md`, `Urdu Listing.md`, `Turkish Listing.md` and
  `French Listing.md`: when a field changes for a feature, change it here too.

## 1. Name

Names are unique across the store, so a bare Al-Islam will not be accepted. The name keeps Al-Islam first,
then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Koran und Hadith
```

**27 / 30 characters.**

The French shape: the two bodies of text the app is built on, the Quran and the hadith collections, with the
prayer side in the subtitle. "Koran und Hadith" is how German names the two sources together, and Hadith in
the singular is what German searches type. The Turkish and Urdu shape, the three sections as bare words, does
not fit: "Koran, Gebet, Hadith" makes the name 31 characters. The German Koran matters: a German search types
koran, which nothing Latin in the name matches (the keyword field adds quran, the spelling many German-speaking
Muslims write).

## 2. Subtitle

```
Gebetszeiten, Qibla, Tafsir
```

**27 / 30 characters.**

Three bare search words, all nouns and so all capitalized: Gebetszeiten, the app's own label and the commonest
German search for prayer times (often with a city); the Qibla; and Tafsir. Apple does not reliably find a word
inside a German compound, so the keyword field adds gebet for "Gebet" searches. Tafsir stays here, where a
reader sees it, because it says what sets the app apart from a prayer-times app; adhan, a search word of its
own, goes to the keyword field.

## 3. Promotional Text

Leads with the German interface. Update it with the next release like the English one.

```
Neu: Die ganze App gibt es jetzt auf Deutsch, von den Gebetsmitteilungen bis zu Siri. Koran, Hadithe und Gebetszeiten in einer kostenlosen App ohne Werbung.
```

**156 / 170 characters.**

## 4. Description

A German rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short German ALL-CAPS headers on their own lines. German runs longer than English, so this is as terse as the
French listing: the bullets drop articles where Apple's German feature lists do, and a few details give way
(the sabr gloss, "on-device" in the opening, which the KI AUF DEM GERÄT header covers, "in depth" on the 99
Names, "named" on the profiles, "side by side" in the Qiraat Explorer line, and the closing's prayer times and
"deeper understanding of Islam"); the last header says KOSTENLOS UND PRIVAT, and its paragraph still says there
are no ads. Changes from the English:
- **Translation:** called "englische Übersetzung", because the app's Quran and hadith translations are English.
- **Languages:** the line in NACH DEINEN WÜNSCHEN says the interface comes in 15 languages, naming German,
  English and Arabic as the other listings name theirs (the fifteen: English, Arabic, Urdu, Indonesian, Malay,
  Turkish, French, Bangla, Russian, Hindi, German, Spanish, Malayalam, Tamil, Dutch), chosen per app in the iOS Settings, and says the
  translations and the articles are English, where the English line lists the fifteen and follows the
  iPhone's language.
- **Labels:** the Pillars of Islam and Faith and Hadith & Its Sciences take the app's labels, Säulen & Glaube
  and die Hadithwissenschaften; the Revision plan is a Wiederholungsplan, after the label Wiederholung, and
  "Switch to Full" names the Full choice by its label, „Vollständig“.

```
Ob du schon immer praktizierst, gerade zum Islam gefunden hast oder ihn erst kennenlernst: Al-Islam begleitet dich. Koran, Hadithe, Tafsir, Gebetszeiten, Gebetstracker und KI-Suche in einer App: kostenlos, ohne Werbung und privat.

DER VOLLSTÄNDIGE KORAN
- Lies nach Sure, Juz oder Seite, als Liste oder Mushaf, im Querformat mit zwei Seiten.
- Arabisch, Transliteration und englische Übersetzung nebeneinander, Tajwid in Farben deiner Wahl.
- Tafsir offline: Ibn Kathir, Maarif Ul Quran und Tazkirul Quran auf Englisch, Ibn Kathir, al-Tabari und as-Sa’di auf Arabisch.
- Wortanalyse: Tippe zweimal auf ein Wort für Bedeutung, Grammatik, Wurzel und jede Fundstelle.
- Über 60 Rezitatoren, Offline-Downloads, „Endlos wiederholen“ und „Ab diesem Vers anhören“ bis zum Ende der Seite, der Sure, des Juz oder des Korans.
- Hafs und 19 weitere Riwayat der zehn Lesarten, verglichen im Lesarten-Explorer.
- Ähnliche Verse, „Nach Themen erkunden“, Wort des Tages, Lesezeichen und Notizen.

AUSWENDIG LERNEN UND WIEDERHOLEN
- Koran-Planer: ein Enddatum für deinen Khatm und ein Wiederholungsplan für die Suren, die du kannst.
- Der Testmodus blendet den Text aus, bis du tippst: Rezitiere auswendig und prüfe jeden Vers.

DIE GROSSEN HADITHSAMMLUNGEN
- Die neun Bücher (Bukhari, Muslim, Nasa’i, Abu Dawud, Tirmidhi, Ibn Majah, Muwatta, Darimi, Musnad Ahmad), die Vierzig-Hadith-Sammlungen und Klassiker wie Riyad as-Salihin.
- Arabisch mit englischer Übersetzung, Überlieferungsketten und Seiten der Überlieferer, Hadith des Tages, Lesezeichen und Suchen wie „Bukhari 5“.
- Suche in einem Buch oder in über 50.000 Hadithen: alle integriert und offline verfügbar.

KI AUF DEM GERÄT
- Suche im Koran und in den Hadithen nach Bedeutung: „patience in hardship“ findet Verse über Geduld. Vorerst nur auf Englisch.
- Mit Apple Intelligence antwortet „KI fragen“ anhand zitierter Verse und Hadithe, nie mit einem religiösen Rechtsurteil.

GEBETSZEITEN, QIBLA UND TRACKER
- Genaue Gebetszeiten, auf deinem Gerät berechnet, mit der für deine Region empfohlenen Methode.
- Ein lebendiger Himmel über den Gebetszeiten: die Sonne auf ihrem Bogen, Sterne bei Nacht, ein 3D-Mond in seiner wahren Phase und auf Wunsch das Wetter.
- Qibla-Kompass, Adhan-Töne, Vorab-Mitteilungen, Reisemodus und Nachhak-Modus, der dich erinnert, bis du betest.
- Gebetstracker: Trage jedes Gebet mit einem Tippen ein; dazu Serien, Perfekte Tage und ein Kalender in Farben.
- Widgets für Gebetszeiten und „Vers nach Wahl“, Steuerelemente im Kontrollzentrum, eine Ramadan-Live-Aktivität und Apple Watch.

GLAUBENSPRAXIS UND LERNEN
- Heute: Vers, Hadith, Dua und ein Name Allahs für jeden Tag, die Karte „Erinnerung des Tages“ und Sunna-Erinnerungen.
- Adhkar, Hisn al-Muslim und Dua-Sammlungen mit Quellen und Audio, Tasbih-Zähler und Islamisches Tagebuch.
- Die 99 Namen Allahs, Wunder des Korans, Beweise für den Islam und die Hadithwissenschaften.
- Arabisches Alphabet mit Lesetest in 21 Stufen, Tajwid-Kurs mit 58 Lektionen und Tajwid-Test.
- Anleitungen, Säulen & Glaube, Zakat- und Erbschaftsrechner, Hidschri-Kalender, „Moscheen finden“ und „Halal-Essen finden“.

NACH DEINEN WÜNSCHEN
- Oberfläche in 15 Sprachen, darunter Deutsch, Englisch und Arabisch, für die App wählbar in den iOS-Einstellungen. Die Übersetzungen (Koran, Hadithe, Duas) und die Artikel im Tab „Islam“ sind auf Englisch.
- Einfacher Modus: nur das Wesentliche auf dem Bildschirm; wechsle jederzeit zu „Vollständig“.
- Sichere Profile in deiner iCloud und stelle sie auf jedem Gerät wieder her.
- Textgrößen, arabische Schriftarten, Akzent- und Himmelsfarben, eine Suche in den Einstellungen.
- iPhone, iPad, Mac und Apple Watch, dazu islamische Sticker für iMessage.

KOSTENLOS UND PRIVAT
Al-Islam ist komplett kostenlos: keine Werbung, kein Account, kein Abonnement, kein Tracking. Nichts, was du tust, wird erfasst oder weitergegeben.

Der Koran, das Gebet und die Hadithe des Propheten Muhammad (Allahs Segen und Frieden auf ihm): Lade Al-Islam noch heute.
```

**3,995 / 4,000 characters.**

## 5. What's New

The release that adds the German interface; the opening line names the other eleven new languages, since
all twelve ship in one release. Only the new
interface is here so far.

```
Die ganze App gibt es jetzt auf Deutsch: Adhan, Koran, Hadith, Islam und Einstellungen. Mit diesem Update kommen auch Indonesisch, Malaiisch, Türkisch, Französisch, Bengalisch, Russisch, Hindi, Spanisch, Malayalam, Tamil und Niederländisch dazu.

Deutsche Oberfläche:
- Alle Bildschirme, Menüs, Einstellungen, Mitteilungen und Widgets sind auf Deutsch, auf iPhone, iPad, Mac und Apple Watch.
- Die Namen der Suren bleiben in lateinischer Schrift (wie Al-Baqarah), mit ihrer Bedeutung auf Deutsch.
- Die Gebetszeiten heißen, wie du sie kennst: Fajr, Sonnenaufgang, Dhuhr, Asr, Maghrib und Isha.
- Der Tajwid-Kurs mit 58 Lektionen, die Tajwid-Grundlagen und die Lektionen in „Arabisches Alphabet“ sind auf Deutsch.
- Gebetsmitteilungen kommen auf Deutsch.

Sprache wählen:
- Die App folgt der Sprache, die du in den iOS-Einstellungen für sie wählst; die Zeile „Sprache“ in den Einstellungen der App führt dich dorthin.
- Wenn du die Sprache wechselst, werden deine Mitteilungen in der neuen Sprache neu geplant.
- Sprich mit Siri auf Deutsch: Öffne oder höre eine Sure nach Name oder Nummer, setze die Rezitation fort, wo du aufgehört hast, oder frag nach dem nächsten Gebet.
- Die ausführlichen Artikel im Tab „Islam“ sind vorerst auf Englisch. Die Suche nach Bedeutung funktioniert mit englischen Begriffen; die Übersetzungen von Koran, Hadithen und Duas sind auf Englisch.
```

**1,373 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Koran:, Adhan:, Hadith:, Islamische Werkzeuge:, Einstellungen:, Fehlerbehebungen und Optimierungen:).
Keep the German interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al, Islam, Koran, und, Hadith,
Gebetszeiten, Qibla, Tafsir).

```
gebet,adhan,namaz,tracker,sure,tajwid,hifz,dua,dhikr,tasbih,ramadan,moschee,muslim,bukhari,quran
```

**96 / 100 characters.**

Why these terms:
- **gebet:** Apple does not reliably find a word inside a German compound, so the subtitle's Gebetszeiten does
  not answer "Gebet" searches ("Gebet App"); with tracker, "Gebet Tracker".
- **adhan:** the Adhan tab and the call to prayer, in the word German-speaking Muslims use for it (German
  Gebetsruf is rarer).
- **namaz:** the prayer's name in Turkish, Bosnian, Albanian, Kurdish and Persian, the family languages of most
  Muslims in Germany, Austria and Switzerland, and the English field's `namaz`; with tracker, "Namaz Tracker".
- **tracker:** the Prayer Tracker (Gebetstracker), the English field's `tracker`.
- **sure, tajwid, hifz:** a surah as German writes it; the colored tajweed with the 58-lesson course, which is
  in German; and memorization (Test Mode and the Revision plan, the English `hifz`).
- **dua, dhikr, tasbih:** the dua collections, the adhkar, and the tasbih counter.
- **ramadan, moschee:** the Ramadan Live Activity and its season, and the Masjid Locator (Moscheen finden).
- **muslim, bukhari:** the broad audience term, the same word in German and English, and Sahih al-Bukhari,
  which stands in for the nine books.
- **quran:** the spelling many German-speaking Muslims write beside the German Koran of the name, and the
  English field's `quran`.

Left out for room, to rotate in from App Analytics: gebetstracker (the label as one word), gebetsrichtung (the
German word for the qibla, "Gebetsrichtung Mekka"), ezan and azan (the other spellings of adhan), salah, vers,
mushaf, rezitator, sunna, khatm, zakat, hidschri, and fasten. Deliberately excluded: übersetzung and deutsch
("Koran auf Deutsch", "Koran Übersetzung"), since the app has no German translation of the Quran. If App
Analytics shows "Gebet" searches finding the app through the subtitle's Gebetszeiten anyway, gebet is redundant
and the first to swap.

## Glossary

The German the app shows for the features the listing names (the German `labels.json`, which is binding, and
the catalog). Every label here was checked against `labels.json` and the translated catalog batches
(2026-11-20), before the merge: re-check them once the merged catalog is built. Those marked * are not labels
in the app: they are Apple's own German names.

| English | German |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Adhan, Koran, Hadith, Islam, Einstellungen (the Islam tab: der Tab „Islam“) |
| Simple Mode / Full | Einfacher Modus / Vollständig (the welcome page asks „Einfach oder vollständig?“) |
| Prayer Times, Prayer Tracker | Gebetszeiten, Gebetstracker |
| Streak, Perfect Days | Serie, Perfekte Tage |
| Test Mode | Testmodus |
| Quran Planner, Revision, khatm | Koran-Planer, Wiederholung (the listing: Wiederholungsplan), Khatm |
| Word Study | Wortanalyse |
| Qiraat Explorer, the Ten Qiraat, riwayah | Lesarten-Explorer, die zehn Lesarten, Riwaya (plural Riwayat) |
| Traveling Mode | Reisemodus |
| Nagging Mode | Nachhak-Modus |
| Prenotification, Qibla Compass, Adhan Sound | Vorab-Mitteilung, Qibla-Kompass, Adhan-Ton |
| Repeat Forever, Play From Ayah | Endlos wiederholen, Ab diesem Vers anhören |
| Similar Ayahs, Browse by Theme, Word of the Day | Ähnliche Verse, Nach Themen erkunden, Wort des Tages |
| Hadith of the Day, Chain of Narrators, Narrators | Hadith des Tages, Überlieferungskette, Überlieferer |
| Ask AI | KI fragen |
| Chosen Ayah (widget), Widgets | Vers nach Wahl, Widgets |
| Today, Name of Allah, Reminder of the Day | Heute, Name Allahs, Erinnerung des Tages |
| Sunnah Reminders | Sunna-Erinnerungen |
| Transliteration | Transliteration |
| Reading Test, Tajweed Course, Tajweed Test, Tajweed Foundations | Lesetest, Tajwid-Kurs, Tajwid-Test, Tajwid-Grundlagen |
| Arabic Alphabet | Arabisches Alphabet |
| 99 Names of Allah, Hisn al-Muslim, Tasbih Counter | 99 Namen Allahs, Hisn al-Muslim, Tasbih-Zähler |
| Proving Islam, Miracles of the Quran, The Sciences of Hadith (Islam tab) | Beweise für den Islam, Wunder des Korans, Die Hadithwissenschaften |
| Masjid Locator, Halal Food Locator (Islam tab) | Moscheen finden, Halal-Essen finden |
| Zakah Calculator, Inheritance Calculator | Zakat-Rechner, Erbschaftsrechner |
| Hijri Calendar, Islamic Journal | Hidschri-Kalender, Islamisches Tagebuch |
| How-To Guides, Pillars & Beliefs | Anleitungen, Säulen & Glaube |
| Language (Settings row), Accent Color, Sky Colors | Sprache, Akzentfarbe, Himmelsfarben |
| Text Size, Arabic Font, Prayer Notifications | Textgröße, Arabische Schriftart, Gebetsmitteilungen |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Fajr, Sonnenaufgang, Dhuhr, Asr, Maghrib, Isha |
| Live Activity*, Control Center* and its controls, iMessage stickers*, landscape* | Live-Aktivität, Kontrollzentrum (Steuerelemente), iMessage-Sticker, Querformat |
