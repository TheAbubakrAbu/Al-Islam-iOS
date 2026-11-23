# App Store Spanish Listing

The **Spanish** (`es`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. App Store
Connect has two Spanish localizations, Spanish (Mexico) and Spanish (Spain), and the same text serves both: add
each one and paste the same six fields into both (Spain shows Spanish (Spain); Mexico, the other Latin American
storefronts and the United States show Spanish (Mexico)). Fill Name and Subtitle under App Information and the
other four fields on the version page. Screenshots can stay English: App Store Connect shows the primary
language's screenshots for a localization that has none of its own.
People whose device is set to Spanish see this listing instead of the English one. In the Spanish interface the
app keeps its Latin name, Al-Islam (the home-screen name too), and its tabs are Adhan, Corán, Hadices, Islam and
Ajustes; the listing uses the same words.

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
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Spanish Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Spanish as Apple's own Spanish pages write it**, addressing the reader with "tú" (lee, toca, descarga),
  never "vosotros", in sentence case: the name, the subtitle and every line capitalize only their first word and
  proper nouns, never English Title Case. The section headers stay ALL CAPS with their accented capitals
  (EL CORÁN COMPLETO, PRÁCTICA DIARIA). The terms are the ones Spanish-speaking Muslims use and the app's
  glossary fixes (oración for the prayer and rezar for the verb, as the app asks "¿Rezaste?"; horarios de
  oración, adhan, qibla, sura, aleya, juz, tajwid, tafsir, khatm, recitador, dua with the plural duas, hadiz
  with the plural hadices) in the respectful register (el Corán, el Profeta Muhammad). Islam keeps its capital
  (el Islam), as the app's Spanish writes it and as its label Pruebas del Islam shows. The honorific is always
  spelled out, "(la paz y las bendiciones de Allah sean con él)": App Store Connect rejects the one-glyph
  ligature (U+FDFA) as an invalid character. Feature names are the labels the app shows (the Spanish
  `labels.json` and catalog, see the glossary below).
- **A label keeps its exact wording and its capital inside a sentence** (Modo insistente, Días perfectos, el
  Explorador de lecturas, Las ciencias del hadiz). A label that is a verb phrase stands in “comillas” so it
  reads as a name, the way the app's own Spanish sentences quote it: “Reproducir desde la aleya”, “Repetir
  indefinidamente”, “Preguntar a la IA”. The two locators are nouns in Spanish (Buscador de mezquitas, Buscador
  de comida halal), so unlike the French they need no quotes.
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma, a semicolon or a new sentence. A
  leading "- " bullet is fine; the English fields use the same.
- **Spanish punctuation and numbers:** ¿ and ¡ always open a question or an exclamation; no space before a
  colon (unlike French); “curly quotes”, as the catalog writes them; the typographic apostrophe ’ in
  transliterations (as-Sa’di, Nasa’i, Jumu’a), as the labels write it; a lowercase word after a colon; and y
  becomes e before an i sound (Maghrib e Isha). Thousands take a no-break space (50 000), the RAE and
  ASALE recommendation and the one form both storefronts read without a clash (Spain writes 50.000, Mexico
  50,000). Western digits; a verse reference keeps its bare colon (5:27). No version numbers.
- **If App Store Connect refuses a field.** On 2026-10-29 it rejected two of Al-Islam's Urdu fields ("This
  field contains one or more invalid characters"), and the typographic quotes were among the four suspects,
  never pinned down (`Urdu Listing.md`). Apple's own Spanish pages use “ ”, so they stay; if a Spanish field is
  refused, swap “ ” for plain "quotes" first, then ’ for ', and re-count.
- **Accents always**, in the keyword field too (ramadán, musulmán): they are the correct spelling, and the name
  and subtitle must show them. The unaccented spellings some people type are listed under Keywords, to rotate in
  from App Analytics.
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  iMessage. Apple's own features take Apple's Spanish names, as the app's glossary has them: widget, centro de
  control, Actividad en directo, pantalla bloqueada, en horizontal (landscape), stickers (iMessage stickers).
- **One text for Spain and Latin America.** Where the two differ, the listing takes a word both read the same
  way, or the app's own word. The Settings app is Ajustes on a Spanish iPhone and Configuración on a Mexican
  one, so the listing says "los ajustes de iOS" (a description, lowercase) rather than naming it; the app's
  own tab is Ajustes in both. Countdown is cuenta atrás in Spain and cuenta regresiva in Latin America, so the
  listing says neither. Live Activity is Actividad en directo in Spain and Actividad en vivo in Mexico: the
  listing keeps the app's glossary word, en directo, which both read; change it with the catalog if the catalog
  changes. Nothing regional: no móvil or celular, no ordenador or computadora (the listing names the device), no
  "mantén pulsado" or "presionado" (it says toca), and no vosotros.
- **Books and scholars keep the app's Latin transliterations** (Bukhari, Muslim, Abu Dawud, Ibn Kathir,
  al-Tabari, as-Sa’di, Riyad as-Salihin), as the Spanish interface writes them and as it writes surah names
  (Al-Baqarah, with its meaning La vaca beside it), so the reference lookup keeps the spelling the search
  reads, "Bukhari 5", and a tile the app names in Latin keeps that label (Hisn al-Muslim). For room, the nine
  books drop the Arabic article (Nasa’i, Tirmidhi, Darimi, where the English has an-Nasa'i, at-Tirmidhi,
  ad-Darimi) and Muwatta Malik is Muwatta.
- **Be honest about what is still English:** the in-depth articles of the Islam tab; AI search by meaning,
  which matches English phrases only; and the translations: every Quran translation in the app is English (The
  Clear Quran, Saheeh International and the comparison sheet's editions), and so are the hadith and dua
  translations beside the Arabic. There is no Spanish translation of the Quran, so the description says
  "traducción al inglés" and the keyword field leaves out traducción and español. Siri does speak Spanish here:
  the app ships Spanish Siri phrases (`es.lproj/AppShortcuts.strings`), to open or play a surah, resume the
  recitation and ask for the next prayer.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `French Listing.md`, `Arabic Listing.md` and `Urdu Listing.md`: when a field changes
  for a feature, change it here too.

## 1. Name

Names are unique across the store, so a bare Al-Islam will not be accepted. The name keeps Al-Islam first,
then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Corán y hadices
```

**26 / 30 characters.**

The French shape: the two bodies of text the app is built on, the Quran and the hadith collections, with the
prayer side in the subtitle. The Turkish and Urdu shape, the three sections as bare words, does not fit:
"Corán, adhan, hadices" makes the name 32 characters. The Spanish Corán matters: a Spanish search types corán,
which nothing Latin in the name matches. Hadices is the plural the Hadith tab shows; the keyword field adds the
singular hadiz, which Apple may not stem from it (z to ces is not a regular plural).

## 2. Subtitle

```
Oración, adhan, qibla, tafsir
```

**29 / 30 characters.**

Four bare search words, the prayer side of the French subtitle: oración, with the keyword field's horarios and
hora for "horarios de oración" (the app's own label) and "hora de oración", the two forms Spanish searches type
most; adhan, the tab and the word Spanish-speaking Muslims use for the call to prayer; the qibla; and tafsir.

## 3. Promotional Text

Leads with the Spanish interface. Update it with the next release like the English one.

```
Novedad: toda la app en español, desde las notificaciones de oración hasta Siri. El Corán, los hadices y los horarios de oración en una sola app gratuita y sin anuncios.
```

**169 / 170 characters.**

## 4. Description

A Spanish rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Spanish ALL-CAPS headers on their own lines, kept as terse as the French listing: the bullets drop
articles where Apple's Spanish feature lists do, and a few details give way (the sabr gloss, "in depth" on the
99 Names, "named" on the profiles, and the closing's "deeper understanding of Islam"). Three changes from the
English: the translation is called "traducción al inglés"; the language line in A TU MANERA says the interface
comes in 15 languages, naming Spanish, English and Arabic as the other listings name theirs (the fifteen:
English, Arabic, Urdu, Indonesian, Malay, Turkish, French, Bangla, Russian, Hindi, German, Spanish, Malayalam, Tamil, Dutch), chosen per
app in iOS Settings, and says the translations and the articles are English; and the Pillars of Islam and Faith
and Hadith & Its Sciences take the app's labels, Pilares y creencias and Las ciencias del hadiz. The English
line and the other listings give the same fifteen.

```
Tanto si practicas desde siempre como si acabas de abrazar el Islam o lo estás descubriendo, Al-Islam te acompaña. Corán, hadices, tafsir, horarios y registro de oraciones, búsqueda con IA: una app gratuita, sin anuncios y que respeta tu privacidad.

EL CORÁN COMPLETO
- Lee por sura, juz o página, en lista o en mushaf, con dos páginas en horizontal.
- Árabe, transliteración y traducción al inglés en paralelo, con tajwid en los colores que elijas.
- Tafsir sin conexión: Ibn Kathir, Maarif Ul Quran y Tazkirul Quran en inglés; Ibn Kathir, al-Tabari y as-Sa’di en árabe.
- Estudio de la palabra: toca dos veces una palabra para ver su significado, gramática, raíz y apariciones.
- Más de 60 recitadores, escucha sin conexión, “Repetir indefinidamente” y “Reproducir desde la aleya” hasta el final de la página, la sura, el juz o el Corán.
- Hafs y otras 19 riwayat de las diez lecturas, comparadas en el Explorador de lecturas.
- Aleyas similares, Explorar por tema, Palabra del día, marcadores y notas.

MEMORIZAR Y REPASAR
- Planificador del Corán: fecha de fin de tu khatm y plan de repaso de las suras que ya sabes.
- El Modo examen oculta el texto hasta que lo tocas: recita de memoria y comprueba cada aleya.

LAS GRANDES COLECCIONES DE HADICES
- Los nueve libros (Bukhari, Muslim, Nasa’i, Abu Dawud, Tirmidhi, Ibn Majah, Muwatta, Darimi, Musnad Ahmad), las colecciones de cuarenta hadices y clásicos como Riyad as-Salihin.
- Árabe y traducción al inglés, cadenas de transmisión y páginas de transmisores, Hadiz del día, marcadores y búsquedas como “Bukhari 5”.
- Busca en un libro o entre más de 50 000 hadices, todos integrados y sin conexión.

IA EN EL DISPOSITIVO
- Busca por significado en el Corán y los hadices: “patience in hardship” encuentra las aleyas sobre la paciencia. Por ahora, solo en inglés.
- Con Apple Intelligence, “Preguntar a la IA” responde a partir de las aleyas y hadices que cita, nunca con un dictamen religioso.

HORARIOS, QIBLA Y REGISTRO
- Horarios precisos calculados en el dispositivo, con el método sugerido para tu región.
- Un cielo vivo sobre tus horarios: el sol en su arco, estrellas de noche, una luna 3D en su fase real y, si quieres, el clima.
- Brújula de la qibla, sonidos del adhan, notificaciones previas, Modo viaje y Modo insistente, que insiste hasta que reces.
- Registro de oraciones: un toque por oración, con rachas, Días perfectos y un calendario de colores.
- Widgets de oración y de Aleya elegida, controles para el centro de control, Actividad en directo de Ramadán y Apple Watch.

PRÁCTICA DIARIA Y APRENDIZAJE
- Hoy: aleya, hadiz, dua y nombre de Allah del día, tarjeta Recordatorio del día y Recordatorios de la Sunna.
- Adhkar, Hisn al-Muslim y colecciones de duas con fuentes y audio, Contador de tasbih y Diario islámico.
- Los 99 nombres de Allah, Milagros del Corán, Pruebas del Islam y Las ciencias del hadiz.
- Alfabeto árabe con una Prueba de lectura de 21 niveles, y tajwid con un curso de 58 lecciones y una Prueba de tajwid.
- Guías prácticas, Pilares y creencias, calculadoras de zakat y herencias, Calendario de la hégira, Buscador de mezquitas y Buscador de comida halal.

A TU MANERA
- Interfaz en 15 idiomas, entre ellos español, inglés y árabe, a elegir para la app en los ajustes de iOS. Las traducciones (Corán, hadices, duas) y los artículos de la pestaña Islam están en inglés.
- El Modo sencillo muestra solo lo esencial; cambia al modo Completo cuando quieras.
- Perfiles guardados en tu iCloud, restaurables en cualquier dispositivo.
- Tamaños de texto, tipos de letra árabes, colores de acento y del cielo, y búsqueda en los ajustes.
- iPhone, iPad, Mac, Apple Watch y stickers islámicos para iMessage.

GRATIS, SIN ANUNCIOS Y PRIVADA
Al-Islam es totalmente gratis: sin anuncios, cuentas, suscripciones ni rastreo. Nada de lo que haces se recopila ni se comparte.

El Corán, la oración y los hadices del Profeta Muhammad (la paz y las bendiciones de Allah sean con él): descarga Al-Islam hoy mismo.
```

**3,991 / 4,000 characters.**

## 5. What's New

The release that adds the Spanish interface; the opening line names the other eleven new languages, since
all twelve ship in one release. Only the new interface is here so far.

```
Toda la app ya está en español: Adhan, Corán, Hadices, Islam y Ajustes. Con esta versión llegan también las interfaces en indonesio, en malayo, en turco, en francés, en bengalí, en ruso, en hindi, en alemán, en malayalam, en tamil y en neerlandés.

Interfaz en español:
- Todas las pantallas, menús, ajustes, notificaciones y widgets están en español, en iPhone, iPad, Mac y Apple Watch.
- Los nombres de las suras se mantienen en letras latinas (como Al-Baqarah), con su significado en español.
- Los horarios llevan los nombres que conoces: Fajr, Salida del sol, Dhuhr, Asr, Maghrib e Isha.
- El Curso de tajwid de 58 lecciones, los Fundamentos del tajwid y las lecciones del Alfabeto árabe están en español.
- Las notificaciones de oración llegan en español.

Elección del idioma:
- La app sigue el idioma que elijas para ella en los ajustes de iOS; la fila Idioma de sus ajustes te lleva allí.
- Si cambias de idioma, tus notificaciones se reprograman en el nuevo idioma.
- Habla con Siri en español: abre o reproduce una sura por su nombre o su número, retoma la recitación donde la dejaste y pregunta por la próxima oración.
- Por ahora, los artículos detallados de la pestaña Islam están en inglés. La búsqueda por significado funciona con frases en inglés, y las traducciones del Corán, los hadices y las duas están en inglés.
```

**1,334 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Corán:, Adhan:, Hadices:, Herramientas islámicas:, Ajustes:, Corrección de errores y optimizaciones:).
Keep the Spanish interface first, and keep the whole field near the English length (2,000 to 2,500
characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al, Islam, Corán, y, hadices, Oración,
adhan, qibla, tafsir).

```
horarios,hora,salat,rezar,registro,sura,tajwid,hifz,dua,dhikr,tasbih,ramadán,mezquita,musulmán,hadiz
```

**100 / 100 characters.**

Why these terms:
- **horarios, hora:** with the subtitle's oración, "horarios de oración" (the app's label Horarios de oración)
  and "hora de oración", the two ways Spanish asks for prayer times. Apple does not treat horario and hora as
  one word, so each needs its own place.
- **salat:** the prayer's Arabic name as Spanish-speaking Muslims write it, a search of its own beside oración.
- **rezar:** the verb Spanish prays with, in "hora de rezar" and "horarios para rezar". Converts also type
  "cómo rezar", which the How-To Guides answer, but those guides are among the English articles: if App
  Analytics shows those searchers leaving, rezar is the first word to swap.
- **registro:** with oración, the app's own label Registro de oraciones, the English field's `tracker`.
- **sura, tajwid, hifz:** a surah as Spanish writes it; the colored tajweed with the 58-lesson course, which is
  in Spanish; and memorization (Test Mode and the Revision plan, the English `hifz`).
- **dua, dhikr, tasbih:** the dua collections, the adhkar, and the tasbih counter.
- **ramadán, mezquita:** the Ramadan Live Activity and its season, and the Masjid Locator (Buscador de
  mezquitas).
- **musulmán, hadiz:** the broad audience term, the English field's `muslim`; and the singular of the name's
  hadices ("hadiz del día", the app's label Hadiz del día).

Left out for room, to rotate in from App Analytics: quran and coran (the spellings without the accent some
Spanish searches type), hadith (the English spelling many Spanish-speaking Muslims also use), bukhari, aleya,
mushaf, recitador, sunna, khatm, zakat, hégira, azan, and the unaccented ramadan, musulman and oracion for
people who type without accents. Deliberately excluded: traducción and español ("Corán en español",
"traducción del Corán"), since the app has no Spanish translation of the Quran. If App Analytics shows "hora de
oración" searches finding the app through horarios anyway, hora is redundant and the next to swap.

## Glossary

The Spanish the app shows for the features the listing names (the Spanish `labels.json`, which is binding, and
the catalog). Every label here was checked against `labels.json` and the catalog batches finished by 2026-11-20.
Those marked † were not yet in a finished batch: the word is the app's glossary's (Idioma, Color de acento,
Racha, which the catalog already uses in "Día %lld de racha") or the plain sense of the English (Completo, for
the Full mode): check them against the merged catalog before this ships. Those marked * are not labels in the
app: they are Apple's own Spanish names, as the app's glossary writes them.

| English | Spanish |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Adhan, Corán, Hadices, Islam, Ajustes (the Islam tab: la pestaña Islam) |
| Simple Mode / Full | Modo sencillo / Completo† |
| Prayer Times, Prayer Tracker | Horarios de oración, Registro de oraciones |
| Streak, Perfect Days | Racha†, Días perfectos |
| Test Mode | Modo examen |
| Quran Planner, Revision, khatm | Planificador del Corán, Repaso, khatm |
| Word Study | Estudio de la palabra |
| Qiraat Explorer, the Ten Qiraat, riwayah | Explorador de lecturas, las diez lecturas, riwaya (plural riwayat) |
| Traveling Mode | Modo viaje |
| Nagging Mode | Modo insistente |
| Prenotification, Qibla Compass, Adhan Sound | Notificación previa, Brújula de la qibla, Sonido del adhan |
| Repeat Forever, Play From Ayah | Repetir indefinidamente, Reproducir desde la aleya |
| Similar Ayahs, Browse by Theme, Word of the Day | Aleyas similares, Explorar por tema, Palabra del día |
| Hadith of the Day, Chain of Narrators, Narrators | Hadiz del día, Cadena de transmisión, Transmisores |
| Ask AI | Preguntar a la IA |
| Chosen Ayah (widget), Widgets | Aleya elegida, widgets |
| Today, Name of Allah, Reminder of the Day | Hoy, Nombre de Allah, Recordatorio del día |
| Sunnah Reminders | Recordatorios de la Sunna |
| Transliteration | Transliteración |
| Reading Test, Tajweed Course, Tajweed Test, Tajweed Foundations | Prueba de lectura, Curso de tajwid, Prueba de tajwid, Fundamentos del tajwid |
| Arabic Alphabet | Alfabeto árabe |
| 99 Names of Allah, Hisn al-Muslim, Tasbih Counter | Los 99 nombres de Allah, Hisn al-Muslim, Contador de tasbih |
| Proving Islam, Miracles of the Quran, The Sciences of Hadith (Islam tab) | Pruebas del Islam, Milagros del Corán, Las ciencias del hadiz |
| Masjid Locator, Halal Food Locator (Islam tab) | Buscador de mezquitas, Buscador de comida halal |
| Zakah Calculator, Inheritance Calculator | Calculadora de zakat, Calculadora de herencias |
| Hijri Calendar, Islamic Journal | Calendario de la hégira, Diario islámico |
| How-To Guides, Pillars & Beliefs | Guías prácticas, Pilares y creencias |
| Language (Settings row), Accent Color, Sky Colors, Arabic Font | Idioma†, Color de acento†, Colores del cielo, Tipo de letra árabe |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Fajr, Salida del sol, Dhuhr, Asr, Maghrib, Isha |
| Live Activity*, Control Center*, iMessage stickers* | Actividad en directo, centro de control, stickers de iMessage |
