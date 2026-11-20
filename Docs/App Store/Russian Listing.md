# App Store Russian Listing

The **Russian** localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store Connect,
add the Russian localization, then fill Name and Subtitle under App Information and the other four fields on
the version page. Screenshots can stay English: App Store Connect shows the primary language's screenshots for
a localization that has none of its own.
People whose device is set to Russian see this listing instead of the English one. In the Russian interface the
app keeps its Latin name, Al-Islam (the home-screen name too), and its tabs are Азан, Коран, Хадисы, Ислам and
Настройки; the listing uses the same words.

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
  file, not the store). Cyrillic letters count one each, like Latin ones. Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Russian Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Russian as Apple's own Russian pages write it**, addressing the reader with a lowercase "вы" and the
  plural imperative (читайте, коснитесь, загрузите), in sentence case: only the first word of a heading or a
  label and proper names take a capital. "е" where Apple writes it (еще, звезды, найдет), never "ё".
  Terminology as Russian-speaking Muslims write it (время намаза, кибла, азан, сура, аят, джуз, мусхаф,
  таджвид, тафсир, хатм, хифз, чтец, риваят, кираат, зикр, дуа), with the respectful register (Коран, Пророк
  Мухаммад). The honorific is always spelled out, "(да благословит его Аллах и приветствует)": App Store
  Connect rejects the one-glyph ligature (U+FDFA) as an invalid character.
- **Feature names are the labels the app shows** (the Russian `labels.json`, see the glossary below), in
  guillemets «» when they stand in a sentence, and always in the nominative inside the quotes: the case goes on a
  noun before them ("в разделе «Навигатор кираатов»", "функция «Спросить ИИ»", "план «Повторение»"). A label
  never changes inside its quotes. The tab names in a plain list (Азан, Коран, Хадисы) need no quotes.
- **No em dash, no en dash, and no spaced hyphen used as a dash.** Where Russian grammar puts a dash
  between subject and predicate ("X", a dash, "это Y"), the sentence is rephrased ("X означает Y"), or a
  colon, a comma, a semicolon or a new sentence takes its place. A leading "- " bullet is fine; the English
  fields use the same.
- **Russian punctuation and numbers:** Western digits, a space for thousands (50 000), guillemets «» for quotes
  (the English search example «patience in hardship» too). A colon is followed by a lowercase word, as
  Russian punctuation requires, unless a proper name or a quoted label follows. No version numbers.
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  iMessage, iOS, and Live Activity, which Apple's Russian keeps in Latin too. Apple's other features take
  Apple's Russian names: виджет, Пункт управления, экран блокировки, Быстрые команды, Настройки (the iOS
  app, with a capital).
- **Classical books and scholars take their Russian names**, spelled as the app's Russian text spells them
  (Бухари, Муслим, ан-Насаи, Абу Дауд, ат-Тирмизи, Ибн Маджа, «Муснад» Ахмада, Ибн Кясир, ат-Табари,
  ас-Саади, «Рияд ас-салихин»). Titles published in English stay Latin (Maarif Ul Quran, Tazkirul Quran), as
  the app keeps The Clear Quran and Saheeh International. The app also keeps its Latin surah names
  (Al-Baqarah) with their meaning in Russian, and the reference lookup keeps the spelling the search reads,
  «Bukhari 5»: the hadith search has no Cyrillic aliases.
- **Be honest about what is still English:** the in-depth articles of the Islam tab; AI search by meaning,
  which matches English phrases only; and the translations: every Quran translation in the app is English
  (The Clear Quran, Saheeh International and the comparison sheet's editions), and so are the hadith and dua
  translations beside the Arabic. There is no Russian translation of the meanings, so the description says
  "английский перевод" and the keyword field leaves out перевод and русский. Siri, unlike in the Urdu
  listing, does speak Russian here: the app ships Russian Siri phrases (`ru.lproj/AppShortcuts.strings`).
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md`, `Urdu Listing.md` and `Turkish Listing.md`: when a field
  changes for a feature, change it here too.

## 1. Name

Names are unique across the store, so a bare Al-Islam will not be accepted. The name keeps Al-Islam first,
then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Коран, азан, хадисы
```

**30 / 30 characters.**

The app's three sections as bare words, each a search term of its own, the same shape as the Turkish,
Arabic and Urdu names. The descriptor is in sentence case, as Russian names on the store write one: Коран
keeps its capital as a proper name, азан and хадисы are lowercase. The Cyrillic words matter: a Russian
search does not match the Latin Islam of the name, which is why the keyword field carries ислам.

## 2. Subtitle

```
Время намаза, кибла, тафсир
```

**27 / 30 characters.**

"Время намаза" is the app's own label and the phrase most Russian searches for prayer times type; with the
keyword field's расписание it also answers "расписание намаза".

## 3. Promotional Text

Leads with the Russian interface. Update it with the next release like the English one.

```
Новое: приложение полностью на русском, включая уведомления о намазах и команды Siri. Коран, хадисы и время намаза в одном бесплатном приложении без рекламы.
```

**157 / 170 characters.**

## 4. Description

A Russian rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Russian ALL-CAPS headers on their own lines. Russian runs longer than English, so a few words are
trimmed to fit (the zakah and inheritance calculators are named together, as the English names them, not by
their two labels), and the feature labels take guillemets. Three changes from the English: the translation
is called "английский перевод"; the language line in КАК ВАМ УДОБНО gives the count of 12 interface languages
(naming Russian, English and Arabic, since the full list does not fit under 4,000), chosen per app in iOS Settings, and says the translations and the articles are English; and the books and
scholars take their Russian names (see the guidelines).

```
Al-Islam поможет вам в практике ислама, исповедуете ли вы его с рождения, недавно приняли или только знакомитесь с ним. Коран, сборники хадисов, тафсир, время намаза, трекер намазов и поиск с ИИ на устройстве в одном простом приложении: бесплатно, без рекламы и конфиденциально.

ВЕСЬ КОРАН
- Читайте по сурам, джузам или страницам, списком или как мусхаф; в альбомной ориентации по две страницы.
- Арабский текст, транслитерация и английский перевод; таджвид в цветах на ваш выбор.
- Тафсир к любому аяту: Ибн Кясир, Maarif Ul Quran и Tazkirul Quran на английском; Ибн Кясир, ат-Табари и ас-Саади на арабском, офлайн.
- «Разбор слова»: двойное касание слова покажет значение, грамматику, корень и все вхождения.
- Более 60 чтецов, офлайн-загрузки, «Повторять бесконечно» и «Слушать с этого аята» до конца страницы, суры, джуза или Корана.
- Хафс и еще 19 риваятов десяти кираатов: сравнивайте их в разделе «Навигатор кираатов».
- «Похожие аяты», «Обзор по темам», «Слово дня», закладки и заметки.

ЗАУЧИВАЙТЕ И ПОВТОРЯЙТЕ
- «Планировщик чтения Корана»: выберите дату завершения хатма и добавьте план «Повторение» для выученных сур.
- «Режим проверки» скрывает текст до касания: читайте по памяти и проверяйте каждый аят.

СБОРНИКИ ХАДИСОВ
- Девять книг (Бухари, Муслим, ан-Насаи, Абу Дауд, ат-Тирмизи, Ибн Маджа, «Муватта» Малика, ад-Дарими, «Муснад» Ахмада), сборники сорока хадисов и «Рияд ас-салихин».
- Арабский текст и английский перевод, иснады и страницы передатчиков, «Хадис дня», закладки и поиск вида «Bukhari 5».
- Ищите в одной книге или сразу во всех 50 000+ хадисах. Все сборники встроены и работают офлайн.

ИИ НА УСТРОЙСТВЕ
- Ищите в Коране и хадисах по смыслу, а не по словам: «patience in hardship» найдет аяты о терпении (сабр). Пока поиск работает с английскими фразами.
- С Apple Intelligence функция «Спросить ИИ» отвечает только по приводимым аятам и хадисам и никогда не выносит фетв.

ВРЕМЯ НАМАЗА, КИБЛА И ТРЕКЕР
- Точное время намаза рассчитывается на устройстве по методу, рекомендуемому для региона.
- Живое небо над временем намаза: солнце на дуге, ночью звезды, 3D-луна в настоящей фазе и погода по желанию.
- «Компас киблы», звуки азана, предварительные уведомления, «Режим путника» и «Режим настойчивых напоминаний»: он напоминает, пока вы не совершите намаз.
- «Трекер намазов»: отмечайте намазы одним касанием; серии, «Идеальные дни» и цветной календарь.
- Виджеты времени намаза и «Выбранный аят», элементы Пункта управления, Live Activity на Рамадан и Apple Watch.

ПОКЛОНЕНИЕ И УЧЕБА
- «Сегодня»: аят, хадис, дуа и имя Аллаха на день, «Напоминание дня» и «Напоминания из Сунны».
- Зикры, «Крепость мусульманина» и сборники дуа с источниками и аудио; «Счетчик тасбиха» и «Исламский дневник».
- «99 имен Аллаха» с объяснениями, «Чудеса Корана», «Доказательства ислама» и «Науки о хадисах».
- «Тест по чтению» из 21 уровня для арабского алфавита, «Курс таджвида» из 58 уроков и «Тест по таджвиду».
- «Пошаговые руководства», столпы ислама и веры, калькуляторы закята и наследства, «Календарь хиджры», «Поиск мечетей» и «Поиск халяльной еды».

КАК ВАМ УДОБНО
- Интерфейс на 12 языках, в том числе на русском, английском и арабском: язык приложения задается в Настройках iOS. Переводы Корана, хадисов, дуа и статьи вкладки «Ислам» на английском.
- «Упрощенный режим» оставляет на экране главное; полный режим включается в любой момент.
- Резервные копии профилей в вашем iCloud и восстановление на любом устройстве.
- Размер текста, арабские шрифты, цвета акцента и неба, поиск на каждой странице настроек.
- iPhone, iPad, Mac и Apple Watch, а также исламские стикеры для iMessage.

БЕСПЛАТНО, БЕЗ РЕКЛАМЫ И КОНФИДЕНЦИАЛЬНО
Приложение Al-Islam полностью бесплатно. Без рекламы, аккаунтов, подписок и отслеживания: ваши данные не собираются и не передаются.

Если вы ищете время намаза, Коран, хадисы Пророка Мухаммада (да благословит его Аллах и приветствует) или хотите глубже понять ислам, загрузите Al-Islam сегодня.
```

**3,953 / 4,000 characters.**

## 5. What's New

The release that adds the Russian interface; the opening line names the other eight new languages, since
all nine ship in one release. Only the new interface is here
so far.

```
Приложение теперь полностью на русском: Азан, Коран, Хадисы, Ислам и Настройки. Также в этом обновлении интерфейс появился на индонезийском, малайском, турецком, французском, бенгальском, хинди, немецком и испанском.

Русский интерфейс:
- Все экраны, меню, настройки, уведомления и виджеты переведены на русский: на iPhone, iPad, Mac и Apple Watch.
- Названия сур пишутся латиницей (например, Al-Baqarah) и показываются со значением на русском.
- Времена намазов под привычными названиями: Фаджр, Восход, Зухр, Аср, Магриб и Иша.
- «Курс таджвида» из 58 уроков, «Основы таджвида» и уроки арабского алфавита на русском.
- Уведомления о намазах приходят на русском.

Выбор языка:
- Приложение следует языку, выбранному для него в Настройках iOS; строка «Язык» в настройках приложения ведет туда.
- При смене языка ваши уведомления заново планируются на новом языке.
- Говорите с Siri по-русски: открывайте и слушайте суру по названию или номеру, продолжайте чтение с места остановки, спрашивайте о следующем намазе.
- Подробные статьи вкладки «Ислам» пока на английском. Поиск по смыслу работает с английскими фразами; переводы Корана, хадисов и дуа на английском.
```

**1,162 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Коран:, Азан:, Хадисы:, Исламские инструменты:, Настройки:, Исправления ошибок и улучшения:). Keep the
Russian interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al, Islam, Коран, азан, хадисы,
время, намаза, кибла, тафсир); a word in another form (намаз beside намаза) is a search term of its own.

```
намаз,ислам,расписание,трекер,хатм,хифз,таджвид,дуа,зикр,тасбих,сунна,бухари,рамадан,ураза,мечеть
```

**97 / 100 characters.**

Why these terms:
- **намаз:** the bare word, the single most common Russian search for the prayer (the subtitle has the
  genitive намаза). If Apple's Russian search turns out to fold намаз and намаза together, it is redundant
  and the first to swap.
- **ислам:** the Cyrillic word. The name's Latin Al-Islam does not match a Russian search for it.
- **расписание, трекер:** with the subtitle's намаза, "расписание намаза" (the prayer timetable, as Russian
  often asks for it) and the app's own label Трекер намазов, the English field's `tracker`.
- **хатм, хифз, таджвид:** the Quran Planner's khatm, memorization (Test Mode and the Revision plan, the
  English `hifz`, which Russian-speaking students of the Quran also say), and the colored tajweed with the
  58-lesson course, which is in Russian.
- **дуа, зикр, тасбих:** the dua collections, the adhkar and the tasbih counter.
- **сунна, бухари:** the Sunnah (Sunnah Reminders and the Sunnahs of the Prophet) and Sahih al-Bukhari, as
  Russian spells it.
- **рамадан, ураза, мечеть:** the Ramadan Live Activity and its season; ураза, the word for the fast that
  Muslims in Tatarstan, Bashkortostan and much of Russia use ("ураза-байрам"); and the Masjid Locator.

Left out for room, to rotate in from App Analytics: мусульманин, сура, аят, джуз, мусхаф, чтец, хадис,
пост, ифтар, молитва (the word some converts type for the prayer), and the 99 Names (асма). Deliberately
excluded: перевод and русский ("Коран на русском", "перевод смыслов"), since the app has no Russian
translation of the Quran, and транскрипция, which Russian searches use for a Cyrillic reading of the Arabic,
while the app's transliteration is Latin.

## Glossary

The Russian the app shows for the features the listing names (the Russian `labels.json`, which is binding,
and the finished interface batches). Every label here was checked against the merged catalog (2026-11-20). Those marked * are not labels in the app: Live Activity, Пункт управления and
Настройки are Apple's own Russian names for Live Activities, Control Center and the Settings app.

| English | Russian |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Азан, Коран, Хадисы, Ислам, Настройки (the Islam tab: вкладка «Ислам») |
| Simple Mode / Full | Упрощенный режим / полный режим |
| Prayer Times, Prayer Tracker | Время намаза, Трекер намазов |
| Streak, Perfect Days | серия (the glossary's word), Идеальные дни |
| Test Mode | Режим проверки |
| Quran Planner, Revision | Планировщик чтения Корана, Повторение |
| Word Study | Разбор слова |
| Qiraat Explorer | Навигатор кираатов |
| Traveling Mode | Режим путника |
| Nagging Mode | Режим настойчивых напоминаний |
| Prenotification, Qibla Compass, Adhan Sound | Предварительное уведомление, Компас киблы, Звук азана |
| Repeat Forever, Play From Ayah | Повторять бесконечно, Слушать с этого аята |
| Similar Ayahs, Browse by Theme, Word of the Day | Похожие аяты, Обзор по темам, Слово дня |
| Hadith of the Day, Chain of Narrators | Хадис дня, Цепочка передатчиков |
| Ask AI, Search by meaning | Спросить ИИ, поиск по смыслу |
| Chosen Ayah (widget), Widgets | Выбранный аят, виджеты |
| Today, Name of Allah, Reminder of the Day | Сегодня, Имя Аллаха, Напоминание дня |
| Sunnah Reminders | Напоминания из Сунны |
| Transliteration | Транслитерация |
| Reading Test, Tajweed Course, Tajweed Test, Tajweed Foundations | Тест по чтению, Курс таджвида, Тест по таджвиду, Основы таджвида |
| Arabic Alphabet | Арабский алфавит |
| 99 Names of Allah, Fortress of the Muslim (the Hisn al-Muslim tile), Tasbih Counter | 99 имен Аллаха, Крепость мусульманина (the screen it opens is titled Хисн аль-Муслим), Счетчик тасбиха |
| Proving Islam, Miracles of the Quran, The Sciences of Hadith (Islam tab) | Доказательства ислама, Чудеса Корана, Науки о хадисах |
| Masjid Locator, Halal Food Locator (Islam tab) | Поиск мечетей, Поиск халяльной еды |
| Hijri Calendar, Islamic Journal | Календарь хиджры, Исламский дневник |
| How-To Guides | Пошаговые руководства |
| Language (Settings row), Accent Color, Sky Colors | Язык, цвет акцента, Цвета неба |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Фаджр, Восход, Зухр, Аср, Магриб, Иша |
| Live Activity*, Control Center*, Settings (iOS)* | Live Activity, Пункт управления, Настройки |
