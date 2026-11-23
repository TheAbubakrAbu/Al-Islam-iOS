# App Store French Listing

The **French** (`fr`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. App Store
Connect has two French localizations, French and French (Canada), and the same text serves both: add each one
and paste the same six fields into both (the Canadian storefront shows French (Canada); France, Belgium,
Switzerland and the other French-speaking storefronts show French). Fill Name and Subtitle under App
Information and the other four fields on the version page. Screenshots can stay English: App Store Connect
shows the primary language's screenshots for a localization that has none of its own.
People whose device is set to French see this listing instead of the English one. In the French interface the
app keeps its Latin name, Al-Islam (the home-screen name too), and its tabs are Adhan, Coran, Hadith, Islam and
Réglages; the listing uses the same words.

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
  file, not the store). Every no-break space counts as one character, as it does in App Store Connect.
  Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/French Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **French as Apple's own French pages write it**, addressing the reader with "vous" (lisez, touchez,
  téléchargez), in sentence case: the name, the subtitle and every line capitalize only their first word and
  proper nouns (Prière, adhan, qibla, tafsir), never English Title Case. The section headers stay ALL CAPS with
  their accented capitals (MÉMORISER, À VOTRE FAÇON). The terms are the ones French-speaking Muslims use and the
  app's glossary fixes (prière, horaires de prière, adhan, qibla, sourate, verset, juz, tajwid, tafsir, khatm,
  récitateur, invocation, hadith with the plural hadiths) in the respectful register (le Coran, le Prophète
  Muhammad). The honorific is always spelled out, "(paix et bénédictions d’Allah sur lui)": App Store Connect
  rejects the one-glyph ligature (U+FDFA) as an invalid character. Feature names are the labels the app shows
  (the French `labels.json` and catalog, see the glossary below).
- **A label keeps its exact wording and its capital inside a sentence** (Mode relance, Jours parfaits,
  l’Explorateur des lectures, with the article elided before it as French requires). A label that is a verb
  phrase stands in guillemets so it reads as a name, the way the app's own French sentences quote it:
  « Écouter à partir du verset », « Demander à l’IA », « Trouver une mosquée ».
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma, a semicolon or a new sentence. A
  leading "- " bullet is fine; the English fields use the same.
- **French punctuation and numbers:** a no-break space (U+00A0) before : ; ? ! and inside « guillemets », and
  as the thousands separator (50 000); the typographic apostrophe ’ throughout (l’app, d’Allah), as the labels
  write it; a lowercase word after a colon, as French writes it. Western digits; a verse reference keeps its
  bare colon (5:27). No version numbers.
- **If App Store Connect refuses a field.** On 2026-10-29 it rejected two of Al-Islam's Urdu fields ("This
  field contains one or more invalid characters"), and « » were among the four suspects, never pinned down
  (`Urdu Listing.md`). They are standard in French store text and Apple's own French pages use them, so they
  stay; if a French field is refused, swap « » for plain "quotes" first, then ’ for ', and re-count.
- **Accents always**, in the keyword field too (prière, mosquée, hégirien): they are the correct spelling, and
  the name and subtitle must show them. The unaccented spellings some people type are listed under Keywords, to
  rotate in from App Analytics.
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  iMessage. Apple's own features take Apple's French names: widget, Centre de contrôle, Activité en direct,
  écran verrouillé, mode paysage, autocollants (iMessage stickers), and Réglages for the Settings app.
- **Books and scholars keep the app's Latin transliterations** (Bukhari, Muslim, Abu Dawud, Ibn Kathir,
  al-Tabari, as-Sa’di, Riyad as-Salihin), as the French interface writes them and as it writes surah names
  (Al-Baqarah), so the reference lookup keeps the spelling the search reads, "Bukhari 5", and a tile the app
  names in Latin keeps that label (Hisn al-Muslim). For room, the nine books drop the Arabic article (Nasa’i,
  Tirmidhi, Darimi, where the English has an-Nasa'i, at-Tirmidhi, ad-Darimi) and Muwatta Malik is Muwatta.
- **Be honest about what is still English:** the in-depth articles of the Islam tab; AI search by meaning,
  which matches English phrases only; and the translations: every Quran translation in the app is English (The
  Clear Quran, Saheeh International and the comparison sheet's editions), and so are the hadith and dua
  translations beside the Arabic. There is no French translation of the Quran, so the description says
  "traduction anglaise" and the keyword field leaves out traduction and français. Siri, unlike in the
  Indonesian listing, does speak French here: the app ships French Siri phrases
  (`fr.lproj/AppShortcuts.strings`).
- **One text for French and French (Canada).** Quebec usage drops the space before ; ? and !, which France
  keeps; the listing keeps the France spacing for both rather than maintain two texts.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md`, `Urdu Listing.md` and `Turkish Listing.md`: when a field changes
  for a feature, change it here too.

## 1. Name

Names are unique across the store, so a bare Al-Islam will not be accepted. The name keeps Al-Islam first,
then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Coran et hadiths
```

**27 / 30 characters.**

The Turkish and Urdu shape, the app's three sections as bare words, does not fit in French: "Coran, Adhan,
Hadith" makes the name 31 characters. The name keeps the two bodies of text the app is built on, the Quran and
the hadith collections, and the prayer side goes to the subtitle. The French Coran matters: a French search
types coran, which nothing Latin in the name matches.

## 2. Subtitle

```
Prière, adhan, qibla, tafsir
```

**28 / 30 characters.**

Four bare search words, the prayer side of the Turkish name and subtitle: prière, with the keyword field's
horaires and heure for "horaires de prière" (the app's own label) and "heure de prière", the two forms French
searches type most; adhan, the tab and the French word for the call to prayer; the qibla; and tafsir.

## 3. Promotional Text

Leads with the French interface. Update it with the next release like the English one.

```
Nouveau : l’app passe entièrement au français, des notifications de prière à Siri. Coran, hadiths et horaires de prière dans une seule app gratuite, sans publicité.
```

**164 / 170 characters.**

## 4. Description

A French rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short French ALL-CAPS headers on their own lines. French runs longer than English, so this is the tersest of
the listings: the bullets drop articles where Apple's French feature lists do, and a few details give way (the
sabr gloss, "in depth" on the 99 Names, "named" on the profiles, and the closing's "deeper understanding of
Islam"); the last header says GRATUIT ET CONFIDENTIEL, and its paragraph still says there are no ads. Three
changes from the English: the translation is called "traduction anglaise"; the language line in À VOTRE FAÇON
says the interface comes in 15 languages, naming French, English and Arabic as the other listings now name
theirs (the fifteen: English, Arabic, Urdu, Indonesian, Malay, Turkish, French, Bangla, Russian, Hindi, German, Spanish, Malayalam, Tamil, Dutch), chosen per app
in iOS Settings, and says the translations and the articles are English; and the Pillars of Islam and Faith
and Hadith & Its Sciences take the app's labels, Piliers et croyances and Les sciences du hadith.

```
Que vous pratiquiez depuis toujours, veniez à l’islam ou le découvriez, Al-Islam vous accompagne. Coran, hadiths, tafsir, horaires et suivi des prières, recherche par IA : une app gratuite, sans publicité et respectueuse de votre vie privée.

LE CORAN COMPLET
- Lisez par sourate, juz ou page, en liste ou en mushaf, avec deux pages en mode paysage.
- Arabe, translittération et traduction anglaise côte à côte, tajwid en couleurs de votre choix.
- Tafsir hors ligne : Ibn Kathir, Maarif Ul Quran et Tazkirul Quran en anglais, Ibn Kathir, al-Tabari et as-Sa’di en arabe.
- Étude du mot : touchez deux fois un mot pour son sens, sa grammaire, sa racine et ses occurrences.
- Plus de 60 récitateurs, écoute hors ligne, « Répéter indéfiniment » et « Écouter à partir du verset » jusqu’à la fin de la page, de la sourate, du juz ou du Coran.
- Hafs et 19 autres riwayat des dix lectures, comparées dans l’Explorateur des lectures.
- Versets similaires, Parcourir par thème, Mot du jour, signets et notes.

MÉMORISER ET RÉVISER
- Planificateur du Coran : date de fin de votre khatm et plan de révision des sourates apprises.
- Le Mode test masque le texte jusqu’à ce que vous touchiez : récitez de mémoire, puis vérifiez chaque verset.

LES GRANDS RECUEILS DE HADITHS
- Les neuf livres (Bukhari, Muslim, Nasa’i, Abu Dawud, Tirmidhi, Ibn Majah, Muwatta, Darimi, Musnad Ahmad), les recueils de quarante hadiths et des classiques comme Riyad as-Salihin.
- Arabe et traduction anglaise, chaînes et pages des rapporteurs, Hadith du jour, signets et recherches comme « Bukhari 5 ».
- Recherche dans un livre ou parmi plus de 50 000 hadiths, tous intégrés et hors ligne.

IA SUR L’APPAREIL
- Recherche par le sens dans le Coran et les hadiths : « patience in hardship » trouve les versets sur la patience. Pour l’instant, en anglais uniquement.
- Avec Apple Intelligence, « Demander à l’IA » répond à partir des versets et hadiths qu’elle cite, jamais par un avis religieux.

HORAIRES, QIBLA ET SUIVI
- Horaires précis calculés sur l’appareil, avec la méthode suggérée pour votre région.
- Un ciel vivant sur vos horaires : soleil sur son arc, étoiles la nuit, lune 3D dans sa vraie phase et météo en option.
- Boussole de la qibla, sons de l’adhan, notifications anticipées, Mode voyage et Mode relance, qui insiste jusqu’à ce que vous priiez.
- Suivi des prières : une touche par prière, avec séries, Jours parfaits et calendrier en couleurs.
- Widgets de prière et Verset choisi, commandes du Centre de contrôle, Activité en direct du Ramadan, Apple Watch.

PRATIQUE ET APPRENTISSAGE
- Aujourd’hui : verset, hadith, invocation et nom d’Allah du jour, carte Rappel du jour et Rappels de la Sunna.
- Adhkar, Hisn al-Muslim et recueils d’invocations avec sources et audio, Compteur de tasbih et Journal islamique.
- Les 99 noms d’Allah, Miracles du Coran, Preuves de l’islam et Les sciences du hadith.
- Alphabet arabe avec un Test de lecture en 21 niveaux, tajwid avec un cours de 58 leçons et un Test de tajwid.
- Guides pratiques, Piliers et croyances, calculateurs de zakat et d’héritage, Calendrier hégirien, « Trouver une mosquée » et « Trouver de la nourriture halal ».

À VOTRE FAÇON
- Interface en 15 langues, dont le français, l’anglais et l’arabe, au choix pour l’app dans Réglages. Les traductions (Coran, hadiths, invocations) et les articles de l’onglet Islam sont en anglais.
- Le Mode simplifié garde l’essentiel ; passez au mode Complet à tout moment.
- Profils sauvegardés dans votre iCloud, restaurables partout.
- Tailles du texte, polices arabes, couleurs d’accentuation et du ciel, recherche dans les réglages.
- iPhone, iPad, Mac, Apple Watch et autocollants islamiques pour iMessage.

GRATUIT ET CONFIDENTIEL
Al-Islam est entièrement gratuit : ni publicité, ni compte, ni abonnement, ni suivi. Rien de ce que vous faites n’est collecté ni partagé.

Le Coran, la prière et les hadiths du Prophète Muhammad (paix et bénédictions d’Allah sur lui) : téléchargez Al-Islam dès aujourd’hui.
```

**3,995 / 4,000 characters.**

## 5. What's New

The release that adds the French interface; the opening line names the other eleven new languages, since
all twelve ship in one release. Only the new interface is here so far.

```
Toute l’app est désormais en français : Adhan, Coran, Hadith, Islam et Réglages. Les interfaces en indonésien, en malais, en turc, en bengali, en russe, en hindi, en allemand, en espagnol, en malayalam, en tamoul et en néerlandais arrivent aussi avec cette version.

Interface en français :
- Tous les écrans, menus, réglages, notifications et widgets sont en français, sur iPhone, iPad, Mac et Apple Watch.
- Les noms des sourates restent en lettres latines (comme Al-Baqarah), avec leur sens en français.
- Les horaires portent les noms que vous connaissez : Fajr, Lever du soleil, Dhuhr, Asr, Maghrib et Isha.
- Le Cours de tajwid en 58 leçons, les Fondements du tajwid et les leçons de l’Alphabet arabe sont en français.
- Les notifications de prière arrivent en français.

Choix de la langue :
- L’app suit la langue choisie pour elle dans Réglages ; la ligne Langue de ses réglages vous y mène.
- Quand vous changez de langue, vos notifications sont reprogrammées dans la nouvelle langue.
- Parlez à Siri en français : ouvrez ou écoutez une sourate par son nom ou son numéro, reprenez la récitation là où vous l’aviez laissée, demandez la prochaine prière.
- Les articles approfondis de l’onglet Islam sont pour l’instant en anglais. La recherche par le sens fonctionne avec des expressions en anglais ; les traductions du Coran, des hadiths et des invocations sont en anglais.
```

**1,383 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Coran :, Adhan :, Hadith :, Outils islamiques :, Réglages :, Corrections de bugs et optimisations :). Keep
the French interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al, Islam, Coran, et, hadiths, Prière,
adhan, qibla, tafsir).

```
horaires,heure,salat,suivi,sourate,tajwid,hifz,doua,dhikr,tasbih,ramadan,mosquée,musulman,bukhari
```

**97 / 100 characters.**

Why these terms:
- **horaires, heure:** with the subtitle's prière, "horaires de prière" (the app's label Horaires de prière)
  and "heure de prière", the two ways French asks for prayer times. Apple does not treat horaire and heure as
  one word, so each needs its own place.
- **salat:** the prayer's Arabic name as French-speaking Muslims write it, a search of its own beside prière.
- **suivi:** with prière, the app's own label Suivi des prières, the English field's `tracker`.
- **sourate, tajwid, hifz:** a surah as French writes it; the colored tajweed with the 58-lesson course, which
  is in French; and memorization (Test Mode and the Revision plan, the English `hifz`).
- **doua, dhikr, tasbih:** the dua collections in the spelling French searches use most, the adhkar, and the
  tasbih counter.
- **ramadan, mosquée:** the Ramadan Live Activity and its season, and the Masjid Locator (Trouver une
  mosquée).
- **musulman, bukhari:** the broad audience term, the English field's `muslim`, and Sahih al-Bukhari, which
  stands in for the nine books.

Left out for room, to rotate in from App Analytics: quran and koran (the English spellings some French searches
type), verset, mushaf, récitateur, sunna, khatm, zakat, hégirien, athan, and the unaccented mosquee and priere
for people who type without accents. Deliberately excluded: traduction and français ("Coran en français",
"traduction du Coran"), since the app has no French translation of the Quran. If App Analytics shows "heure de
prière" searches finding the app through horaires anyway, heure is redundant and the first to swap.

## Glossary

The French the app shows for the features the listing names (the French `labels.json`, which is binding, and
the catalog). Every label here was checked against the merged catalog (2026-11-20). Those marked * are not labels in the app: they are Apple's own French
names.

| English | French |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Adhan, Coran, Hadith, Islam, Réglages (the Islam tab: l’onglet Islam) |
| Simple Mode / Full | Mode simplifié / Complet |
| Prayer Times, Prayer Tracker | Horaires de prière, Suivi des prières |
| Streak, Perfect Days | Série, Jours parfaits |
| Test Mode | Mode test |
| Quran Planner, Revision, khatm | Planificateur du Coran, Révision, khatm |
| Word Study | Étude du mot |
| Qiraat Explorer, the Ten Qiraat, riwayah | Explorateur des lectures, les dix lectures, riwaya (plural riwayat) |
| Traveling Mode | Mode voyage |
| Nagging Mode | Mode relance |
| Prenotification, Qibla Compass, Adhan Sound | Notification anticipée, Boussole de la qibla, Son de l’adhan |
| Repeat Forever, Play From Ayah | Répéter indéfiniment, Écouter à partir du verset |
| Similar Ayahs, Browse by Theme, Word of the Day | Versets similaires, Parcourir par thème, Mot du jour |
| Hadith of the Day, Chain of Narrators, Narrators | Hadith du jour, Chaîne de transmission, Rapporteurs |
| Ask AI | Demander à l’IA |
| Chosen Ayah (widget), Widgets | Verset choisi, widgets |
| Today, Name of Allah, Reminder of the Day | Aujourd’hui, Nom d’Allah, Rappel du jour |
| Sunnah Reminders | Rappels de la Sunna |
| Transliteration | Translittération |
| Reading Test, Tajweed Course, Tajweed Test, Tajweed Foundations | Test de lecture, Cours de tajwid, Test de tajwid, Fondements du tajwid |
| Arabic Alphabet | Alphabet arabe |
| 99 Names of Allah, Hisn al-Muslim, Tasbih Counter | Les 99 noms d’Allah, Hisn al-Muslim, Compteur de tasbih |
| Proving Islam, Miracles of the Quran, The Sciences of Hadith (Islam tab) | Preuves de l’islam, Miracles du Coran, Les sciences du hadith |
| Masjid Locator, Halal Food Locator (Islam tab) | Trouver une mosquée, Trouver de la nourriture halal |
| Zakah Calculator, Inheritance Calculator | Calculateur de zakat, Calculateur d’héritage |
| Hijri Calendar, Islamic Journal | Calendrier hégirien, Journal islamique |
| How-To Guides, Pillars & Beliefs | Guides pratiques, Piliers et croyances |
| Language (Settings row), Accent Color, Sky Colors | Langue, Couleur d’accentuation, Couleurs du ciel |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Fajr, Lever du soleil, Dhuhr, Asr, Maghrib, Isha |
| Live Activity*, Control Center*, iMessage stickers* | Activité en direct, Centre de contrôle, autocollants iMessage |
