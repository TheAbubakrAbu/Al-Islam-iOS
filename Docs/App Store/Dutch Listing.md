# App Store Dutch Listing

The **Dutch** (`nl`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. App Store
Connect has one Dutch localization, Dutch, and it serves every Dutch-speaking storefront (the Netherlands and
Belgium among them). Fill Name and Subtitle under App Information and the other four fields on the version
page. Screenshots can stay English: App Store Connect shows the primary language's screenshots for a
localization that has none of its own.
People whose device is set to Dutch see this listing instead of the English one. In the Dutch interface the
app keeps its Latin name, Al-Islam (the home-screen name too), and its tabs are Adhan, Koran, Hadith, Islam and
Instellingen; the listing uses the same words.

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
  file, not the store). The fields hold no no-break space; if one is ever added (before a unit), it counts as
  one character, as it does in App Store Connect. Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Dutch Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Dutch as Apple's own Dutch pages write it**, addressing the reader with "je" and "jouw", never "u", with
  the imperative first (lees, tik, kies, download), in sentence case: only the first word and proper nouns are
  capitalized, never English Title Case (Gebedstijden, qibla, tafsir). The section headers stay ALL CAPS (DE
  GROTE HADITHVERZAMELINGEN), with IJ as one letter if a header ever needs it. The terms are the ones
  Dutch-speaking Muslims use and the app's glossary fixes (gebed, gebedstijden, adhan, qibla, soera with the
  plural soera’s, vers with the plural verzen, juz, mushaf, tajweed, tafsir, khatm, recitator, dua with the
  plural dua’s, hadith with the plural hadiths, leeswijzen for the qiraat, riwayah with the plural riwayat),
  in the respectful register: Allah, de Koran and de Profeet capitalized; de islam, islamitisch and moslim
  lowercase, as Dutch spelling has them; Ramadan capitalized, as Apple's Dutch Hijri calendar writes it. The
  honorific is always spelled out, "(vrede zij met hem)": App Store Connect rejects the one-glyph ligature
  (U+FDFA) as an invalid character. Feature names are the labels the app shows (the Dutch `labels.json` and
  catalog, see the glossary below).
- **A label keeps its exact wording.** A noun label stands bare with its capital, the way Apple's Dutch pages
  write a feature's name (Woordstudie, Testmodus, Koranplanner, Zeurmodus, Woord van de dag, Perfecte dagen).
  Dutch inflects an adjective after "het" (het islamitische dagboek), so a label like Islamitisch dagboek
  stands bare in a list or after "een", where its form does not change. A label that is an imperative verb
  phrase stands in “…” so it reads as a name and not as an instruction, the way the app's own Dutch sentences
  quote it: “Herhaal eindeloos”, “Speel af vanaf vers”, “Blader per thema”, “Vraag AI”. So does a widget's or a
  card's name (“Gekozen vers”, “Herinnering van de dag”), a label that holds an "en" inside a list (“Zuilen en
  geloof”) and a lone adjective (“Volledig”, the Full choice). A label that opens with an article drops its
  capital inside a sentence (de hadithwetenschappen, the label De hadithwetenschappen).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma, a semicolon or a new sentence. A
  leading "- " bullet is fine; the English fields use the same. The hyphens of a Dutch compound after a
  transliterated term, a brand or an abbreviation (Tajweed-cursus, Qibla-kompas, Hijri-kalender,
  dua-verzamelingen, 3D-maan) and of a shared compound part (zakah- en erfeniscalculator, accent- en
  luchtkleuren) are spelling, not dashes.
- **Dutch punctuation and numbers:** the quotes “…” (U+201C, U+201D) throughout, as the app's Dutch catalog
  writes them (Apple's ‘…’ is not used); the typographic apostrophe of the plural as in Apple's Foto’s
  (soera’s, pagina’s, dua’s, menu’s); a transliteration keeps the straight apostrophe the Dutch catalog gives
  it (as-Sa'di, Nasa'i). After a colon a lowercase letter, as Dutch writes it, unless a name or a quotation
  follows (Woordstudie: tik …; Nieuw: de hele app …). A period as the thousands separator (50.000), Western
  digits; a verse reference keeps its bare colon (5:27). No version numbers.
- **If App Store Connect refuses a field.** On 2026-10-29 it rejected two of Al-Islam's Urdu fields ("This
  field contains one or more invalid characters"), and the curly quotes were among the four suspects, never
  pinned down (`Urdu Listing.md`). “…” and ’ are standard in Dutch store text, so they stay; if a Dutch field
  is refused, swap “…” for plain "quotes" first, then ’ for ', and re-count.
- **Accents always**, wherever a word has them (één, privé, essentiële): they are the correct spelling, in the
  keyword field too (this one happens to need none).
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  iMessage. Apple's own features take Apple's Dutch names, as the app's glossary has them: widget,
  bedieningspaneel (its controls: regelaars), live activiteit (the catalog's spelling), toegangsscherm (Lock
  Screen), liggende stand (landscape), stickers, meldingen (notifications), account, abonnement, and the
  Settings app as "de app Instellingen", Apple's Dutch phrase, which cannot be read as the app's own
  Instellingen tab. A tab is a tabblad (het tabblad “Islam”).
- **Books and scholars keep the app's Latin transliterations** (Bukhari, Muslim, Abu Dawud, Ibn Kathir,
  al-Tabari, as-Sa'di, Riyad as-Salihin), as the Dutch interface writes them and as it writes surah names
  (Al-Baqarah, with its meaning De koe beside it), so the reference lookup keeps the spelling the search reads,
  "Bukhari 5", and a tile the app names in Latin keeps that label (Hisn al-Muslim). For room, the nine books
  drop the Arabic article (Nasa'i, Tirmidhi, Darimi, where the English has an-Nasa'i, at-Tirmidhi, ad-Darimi)
  and Muwatta Malik is Muwatta, as in the German listing.
- **Be honest about what is still English:** the in-depth articles of the Islam tab; AI search by meaning,
  which matches English phrases only; and the translations: every Quran translation in the app is English (The
  Clear Quran, Saheeh International and the comparison sheet's editions), and so are the hadith and dua
  translations beside the Arabic. There is no Dutch translation of the Quran, so the description says
  "Engelse vertaling" and the keyword field leaves out vertaling and nederlands. Siri does speak Dutch here: the
  app ships Dutch Siri phrases (`nl.lproj/AppShortcuts.strings`, and the Watch copy), to open or play a surah,
  resume the recitation and ask for the next prayer.
- **One text for the Netherlands and Flanders.** Standard Dutch in Apple's `nl` wording, nothing regional: "je"
  and not the Flemish "ge", no gsm or mobiel (the listing names the device), and the spelling both share.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `German Listing.md`, `Spanish Listing.md`, `French Listing.md`, `Arabic Listing.md`
  and `Urdu Listing.md`: when a field changes for a feature, change it here too.

## 1. Name

Names are unique across the store, so a bare Al-Islam will not be accepted. The name keeps Al-Islam first,
then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Koran en hadith
```

**26 / 30 characters.**

The German and Spanish shape: the two bodies of text the app is built on, the Quran and the hadith
collections, with the prayer side in the subtitle. "Koran en hadith" is how Dutch names the two sources
together; hadith is lowercase in sentence case (the Hadith tab is capitalized as a label) and singular, as
Dutch searches type it. The Turkish and Urdu shape, the three sections as bare words, does not fit: "Koran,
gebed, hadith" makes the name 31 characters. The Dutch Koran matters: a Dutch search types koran, which nothing
Latin in the name matches (the keyword field adds quran, the spelling many Dutch-speaking Muslims write).

## 2. Subtitle

```
Gebedstijden, qibla, tafsir
```

**27 / 30 characters.**

Three bare search words in sentence case: Gebedstijden, the app's own label and the commonest Dutch search for
prayer times (often with a city: "gebedstijden Rotterdam"); the qibla; and tafsir. Apple does not reliably find
a word inside a Dutch compound, so the keyword field adds gebed for "gebed" searches. Tafsir stays here, where
a reader sees it, because it says what sets the app apart from a prayer-times app; adhan, a search word of its
own, goes to the keyword field.

## 3. Promotional Text

Leads with the Dutch interface. Update it with the next release like the English one.

```
Nieuw: de hele app is nu in het Nederlands, van de gebedsmeldingen tot Siri. De Koran, hadiths en gebedstijden in één gratis app zonder advertenties.
```

**149 / 170 characters.**

## 4. Description

A Dutch rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Dutch ALL-CAPS headers on their own lines, kept as terse as the German listing: the bullets drop
articles where Apple's Dutch feature lists do, and a few details give way (the sabr gloss, "on-device" in the
opening, which the AI OP HET APPARAAT header covers, "in depth" on the 99 Names, "named" on the profiles, "side
by side" in the Qiraat Explorer line, and the closing's prayer times and "deeper understanding of Islam"); the
last header says GRATIS EN PRIVÉ, and its paragraph still says there are no ads. Changes from the English:
- **Translation:** called "Engelse vertaling", because the app's Quran and hadith translations are English.
- **Languages:** the line in OP JOUW MANIER says the interface comes in 15 languages, naming Dutch, English and
  Arabic as the other listings name theirs (the fifteen: English, Arabic, Urdu, Indonesian, Malay, Turkish,
  French, Bangla, Russian, Hindi, German, Spanish, Malayalam, Tamil, Dutch), chosen for the app in the Settings
  app, and says the translations and the articles are English, where the English line lists the fifteen and
  follows the iPhone's language.
- **Labels:** the Pillars of Islam and Faith and Hadith & Its Sciences take the app's labels, “Zuilen en
  geloof” and de hadithwetenschappen; the Revision plan is a herhaalplan, the catalog's word for it ("Dit
  herhaalplan beëindigen?"), after the label Herhaling; and "Switch to Full" names the Full choice by its
  label, “Volledig”.

```
Of je nu je hele leven al praktiseert, net moslim bent geworden of de islam leert kennen: Al-Islam is er voor jou. De Koran, hadiths, tafsir, gebedstijden, een gebedstracker en zoeken met AI in één app: gratis, zonder advertenties en privé.

DE VOLLEDIGE KORAN
- Lees per soera, juz of pagina, als lijst of mushaf, met twee pagina’s naast elkaar in liggende stand.
- Arabisch, transliteratie en Engelse vertaling naast elkaar, met tajweed in kleuren die je zelf kiest.
- Tafsir offline: Ibn Kathir, Maarif Ul Quran en Tazkirul Quran in het Engels, Ibn Kathir, al-Tabari en as-Sa'di in het Arabisch.
- Woordstudie: tik twee keer op een woord voor betekenis, grammatica, wortel en elke vindplaats.
- Meer dan 60 recitatoren, offline downloads, “Herhaal eindeloos” en “Speel af vanaf vers” tot het einde van pagina, soera, juz of Koran.
- Hafs en 19 andere riwayat van de tien leeswijzen, vergeleken in de Leeswijzenverkenner.
- Vergelijkbare verzen, “Blader per thema”, Woord van de dag, bladwijzers en notities.

MEMORISEREN EN HERHALEN
- Koranplanner: kies een einddatum voor je khatm en voeg een herhaalplan toe voor de soera’s die je kent.
- Testmodus verbergt de tekst tot je tikt: reciteer uit het hoofd en controleer elk vers.

DE GROTE HADITHVERZAMELINGEN
- De negen boeken (Bukhari, Muslim, Nasa'i, Abu Dawud, Tirmidhi, Ibn Majah, Muwatta, Darimi, Musnad Ahmad), de verzamelingen van veertig hadiths en klassiekers zoals Riyad as-Salihin.
- Arabisch met Engelse vertaling, overleveringsketens en pagina’s over de overleveraars, Hadith van de dag, bladwijzers en zoekopdrachten zoals “Bukhari 5”.
- Zoek in één boek of in ruim 50.000 hadiths: alles ingebouwd en offline.

AI OP HET APPARAAT
- Zoek in de Koran en de hadiths op betekenis: “patience in hardship” vindt verzen over geduld. Voorlopig alleen in het Engels.
- Met Apple Intelligence antwoordt “Vraag AI” op basis van de verzen en hadiths die het citeert, nooit met een religieus oordeel.

GEBEDSTIJDEN, QIBLA EN TRACKER
- Nauwkeurige gebedstijden, berekend op je apparaat, met de aanbevolen methode voor jouw regio.
- Een levende lucht boven je gebedstijden: de zon op haar baan, sterren in de nacht, een 3D-maan in haar ware fase en desgewenst het weer.
- Qibla-kompas, adhan-geluiden, meldingen vooraf, Reismodus en Zeurmodus, die je herinnert tot je hebt gebeden.
- Gebedstracker: vul elk gebed in met één tik; met reeksen, Perfecte dagen en een kalender in kleuren.
- Widgets voor de gebedstijden en “Gekozen vers”, regelaars in het bedieningspaneel, een live activiteit voor de Ramadan en Apple Watch.

DAGELIJKSE AANBIDDING EN LEREN
- Vandaag: elke dag een vers, hadith, dua en naam van Allah, de kaart “Herinnering van de dag” en Sunnah-herinneringen.
- Adhkar, Hisn al-Muslim en dua-verzamelingen met bronnen en audio, plus Tasbih-teller en Islamitisch dagboek.
- De 99 namen van Allah, Wonderen van de Koran, Bewijzen voor de islam en de hadithwetenschappen.
- Arabisch alfabet met Leestest in 21 niveaus, Tajweed-cursus met 58 lessen en Tajweed-test.
- Handleidingen, “Zuilen en geloof”, zakah- en erfeniscalculator, Hijri-kalender, Moskeezoeker en Halalzoeker.

OP JOUW MANIER
- Interface in 15 talen, waaronder Nederlands, Engels en Arabisch, per app te kiezen in de app Instellingen. De vertalingen (Koran, hadiths, dua’s) en de artikelen op het tabblad “Islam” zijn Engels.
- Eenvoudige modus: alleen het essentiële op het scherm; schakel op elk moment over naar “Volledig”.
- Maak een back-up van profielen in je eigen iCloud en zet ze terug op elk apparaat.
- Tekstgroottes, Arabische lettertypen, accent- en luchtkleuren, en zoeken in de instellingen.
- iPhone, iPad, Mac en Apple Watch, plus islamitische stickers voor iMessage.

GRATIS EN PRIVÉ
Al-Islam is helemaal gratis: geen advertenties, geen account, geen abonnement, geen tracking. Niets van wat je doet, wordt verzameld of gedeeld.

De Koran, het gebed en de hadiths van de Profeet Muhammad (vrede zij met hem): download Al-Islam vandaag nog.
```

**3,986 / 4,000 characters.**

## 5. What's New

The release that adds the Dutch interface; the opening line names the other eleven new languages, since all
twelve ship in one release. Only the new interface is here so far.

```
De hele app is nu in het Nederlands: Adhan, Koran, Hadith, Islam en Instellingen. Met deze update komen er ook Indonesisch, Maleis, Turks, Frans, Bengaals, Russisch, Hindi, Duits, Spaans, Malayalam en Tamil bij.

In het Nederlands:
- Alle schermen, menu’s, instellingen, meldingen en widgets zijn in het Nederlands, op iPhone, iPad, Mac en Apple Watch.
- De namen van de soera’s blijven in het Latijnse schrift (zoals Al-Baqarah), met hun betekenis in het Nederlands.
- De gebedstijden heten zoals je ze kent: Fajr, Zonsopkomst, Dhuhr, Asr, Maghrib en Isha.
- De Tajweed-cursus met 58 lessen, Grondslagen van tajweed en de lessen in “Arabisch alfabet” zijn in het Nederlands.
- Gebedsmeldingen komen in het Nederlands.

Taalkeuze:
- De app volgt de taal die je er in de app Instellingen voor kiest; de rij “Taal” in de instellingen van de app brengt je erheen.
- Als je van taal wisselt, worden je meldingen opnieuw ingepland in de nieuwe taal.
- Praat met Siri in het Nederlands: open of beluister een soera op naam of nummer, hervat de recitatie waar je gebleven was, of vraag naar het volgende gebed.
- De uitgebreide artikelen op het tabblad “Islam” zijn voorlopig in het Engels. Zoeken op betekenis werkt met Engelse woorden; de vertalingen van de Koran, de hadiths en de dua’s zijn in het Engels.
```

**1,302 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Koran:, Adhan:, Hadith:, Islamitische hulpmiddelen:, Instellingen:, Bugfixes en optimalisaties:). Keep
the Dutch interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al, Islam, Koran, en, hadith,
Gebedstijden, qibla, tafsir).

```
gebed,salat,adhan,namaz,tracker,soera,tajweed,hifz,dua,tasbih,ramadan,moskee,moslim,bukhari,quran
```

**97 / 100 characters.**

Why these terms:
- **gebed:** Apple does not reliably find a word inside a Dutch compound, so the subtitle's Gebedstijden does
  not answer "gebed" searches ("gebed app"); with tracker, "gebed tracker".
- **salat, namaz:** the prayer's name for the two largest Muslim communities in the Netherlands and Belgium:
  salat in the Arabic and Tamazight of Moroccan families (the English field's `salah`, in the spelling they
  write), and namaz in the Turkish, Bosnian, Albanian, Kurdish and Urdu of Turkish, Balkan and Surinamese
  families (the English field's `namaz`); with tracker, "namaz tracker".
- **adhan:** the Adhan tab and the call to prayer, in the word Dutch-speaking Muslims use for it (the Dutch
  "oproep tot het gebed" is a phrase, not a search).
- **tracker:** the Prayer Tracker (Gebedstracker), the English field's `tracker`.
- **soera, tajweed, hifz:** a surah as Dutch writes it; the colored tajweed with the 58-lesson course, which is
  in Dutch, in the spelling the app and Dutch-speaking Muslims write (not tadjwied); and memorization (Test
  Mode and the Revision plan, the English `hifz`).
- **dua, tasbih:** the dua collections and the tasbih counter.
- **ramadan, moskee:** the Ramadan Live Activity and its season, and the Masjid Locator (Moskeezoeker).
- **moslim, bukhari:** the broad audience term in its Dutch spelling, and Sahih al-Bukhari, which stands in for
  the nine books.
- **quran:** the spelling many Dutch-speaking Muslims write beside the Dutch Koran of the name, and the English
  field's `quran`.

Left out for room, to rotate in from App Analytics: dhikr (the English field has it; the tasbih counter and the
adhkar still answer for it through tasbih and dua), gebedstracker (the label as one word), gebedsrichting (the
Dutch word for the qibla), azan and ezan (the other spellings of adhan), muslim (the English spelling, and the
name of Sahih Muslim), surah, vers, mushaf, recitator, sunnah, khatm, zakat, hijri and vasten. Deliberately
excluded: vertaling and nederlands ("Koran Nederlands", "Koran vertaling"), since the app has no Dutch
translation of the Quran. If App Analytics shows "gebed" searches finding the app through the subtitle's
Gebedstijden anyway, gebed is redundant and the first to swap, for dhikr.

## Glossary

The Dutch the app shows for the features the listing names (the Dutch `labels.json`, which is binding, and the
catalog, `final.json`). Every label here was checked against `labels.json` and the translated catalog
(2026-11-21), before the merge: re-check them once the merged catalog is built. One label changed in review
and is not named in the fields: Reset All Settings is now Stel alle instellingen opnieuw in (it was Herstel
alle instellingen). Those marked * are not labels in the app: they are Apple's own Dutch names, as the app's
glossary gives them.

| English | Dutch |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Adhan, Koran, Hadith, Islam, Instellingen (the Islam tab: het tabblad “Islam”) |
| Simple Mode / Full | Eenvoudige modus / Volledig (the welcome page asks “Eenvoudig of volledig?”) |
| Prayer Times, Prayer Tracker | Gebedstijden, Gebedstracker |
| Streak, Perfect Days | Reeks, Perfecte dagen |
| Test Mode | Testmodus |
| Quran Planner, Revision, khatm | Koranplanner, Herhaling (the listing: herhaalplan, the catalog's word), khatm |
| Word Study | Woordstudie |
| Qiraat Explorer, the Ten Qiraat, riwayah | Leeswijzenverkenner, de tien leeswijzen, riwayah (plural riwayat) |
| Traveling Mode | Reismodus |
| Nagging Mode | Zeurmodus |
| Prenotification, Qibla Compass, Adhan Sound | Melding vooraf, Qibla-kompas, Adhan-geluid |
| Repeat Forever, Play From Ayah | Herhaal eindeloos, Speel af vanaf vers |
| Similar Ayahs, Browse by Theme, Word of the Day | Vergelijkbare verzen, Blader per thema, Woord van de dag |
| Hadith of the Day, Chain of Narrators, Narrators | Hadith van de dag, Overleveringsketen, Overleveraars |
| Ask AI | Vraag AI |
| Chosen Ayah (widget), Widgets* | Gekozen vers, widgets |
| Today, Name of Allah, Reminder of the Day | Vandaag, Naam van Allah, Herinnering van de dag |
| Sunnah Reminders | Sunnah-herinneringen |
| Transliteration | Transliteratie |
| Reading Test, Tajweed Course, Tajweed Test, Tajweed Foundations | Leestest, Tajweed-cursus, Tajweed-test, Grondslagen van tajweed |
| Arabic Alphabet | Arabisch alfabet |
| 99 Names of Allah, Hisn al-Muslim, Tasbih Counter | 99 namen van Allah, Hisn al-Muslim, Tasbih-teller |
| Proving Islam, Miracles of the Quran, The Sciences of Hadith (Islam tab) | Bewijzen voor de islam, Wonderen van de Koran, De hadithwetenschappen |
| Masjid Locator, Halal Food Locator (Islam tab) | Moskeezoeker, Halalzoeker |
| Zakah Calculator, Inheritance Calculator | Zakah-calculator, Erfeniscalculator |
| Hijri Calendar, Islamic Journal | Hijri-kalender, Islamitisch dagboek |
| How-To Guides, Pillars & Beliefs | Handleidingen, Zuilen en geloof |
| Language (Settings row), Accent Color, Sky Colors | Taal, Accentkleur, Luchtkleuren |
| Text Size, Arabic Font, Prayer Notifications | Tekstgrootte, Arabisch lettertype, Gebedsmeldingen |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Fajr, Zonsopkomst, Dhuhr, Asr, Maghrib, Isha |
| iCloud Backup, Profile | iCloud-back-up, Profiel |
| Live Activity*, Control Center* and its controls, iMessage stickers*, landscape*, Settings app* | live activiteit, bedieningspaneel (regelaars), stickers voor iMessage, liggende stand, de app Instellingen |
