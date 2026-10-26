# App Store Urdu Listing

The **Urdu** localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store Connect
(Urdu listings since 2026-03-31), add the Urdu localization, then fill Name and Subtitle under App Information
and the other four fields on the version page. Screenshots can stay English: App Store Connect shows the
primary language's screenshots for a localization that has none of its own.
People whose device is set to Urdu see this listing instead of the English one. In the Urdu interface the app
calls itself الاسلام, and its tabs are اذان، قرآن، حدیث، اسلام and ترتیبات; the listing uses the same words.

| Field | Limit | Editable without a new version? |
|---|---|---|
| Name | 30 | No |
| Subtitle | 30 | No |
| Keywords | 100 | No |
| Promotional Text | 170 | Yes |
| Description | 4,000 | No |
| What's New | 4,000 | No |

## Guidelines

- **Counts are Python `len()`** of the exact text inside each code block (the bold tally lines are for this
  file, not the store). Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Urdu Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Standard Urdu as Apple's own Urdu pages read it**, with the respectful register (نبی کریم ﷺ، قرآن مجید).
  Feature names are the labels the app shows (`Resources/Localizable.xcstrings`, see the glossary below).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, the comma ، or a new sentence. A leading
  "- " bullet is fine; the English fields use the same.
- **Urdu punctuation** (۔ ، ؟) and Western digits (60، 21), as Urdu in Pakistan writes them. No version numbers.
- **Urdu letters, never their Arabic look-alikes:** ی ک ہ ھ ۃ, not ي ك ه ة.
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  CarPlay, iMessage.
- **No zabar, zer or shadda in the name, subtitle or keywords:** nobody types them in a search.
- **Be honest about what is still English:** the in-depth articles of the Islam tab, AI search by meaning
  (English phrases only), and Siri, which has no Urdu.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md`: when a field changes for a feature, change it here too.

## 1. Name

Names are unique across the store, so a bare الاسلام will not be accepted. Each option keeps الاسلام first,
then a short descriptor after a separator, as the English name does with "|".

**Recommended:**

```
الاسلام | قرآن، اذان، حدیث
```

**26 / 30 characters.**

The app's three sections as bare words, each a search term of its own. The same shape as the Arabic name.

**Alternate:**

```
الاسلام | نماز، قرآن، حدیث
```

**26 / 30 characters.**

Leads with نماز, the word Urdu speakers search for prayer. With it, the subtitle below keeps its اوقات but
the keyword field takes اذان back (it is not in the name any more).

## 2. Subtitle

**Recommended** (with the recommended name):

```
نماز کے اوقات، قبلہ اور تفسیر
```

**29 / 30 characters.**

"نماز کے اوقات" is how Urdu says prayer times, and the most searched prayer phrase.

**Alternate:**

```
قرآن مجید کی تفسیر اور قبلہ
```

**27 / 30 characters.**

For the alternate name (which already says نماز): puts قرآن مجید, the common Urdu name of the Quran, in the
indexed fields.

## 3. Keywords

Written for the recommended name and subtitle. No word repeats one of theirs (الاسلام، قرآن، اذان، حدیث،
نماز، اوقات، قبلہ، تفسیر); if an alternate ships, re-check that and swap in the words it dropped.

```
القرآن,مجید,پاک,شریف,اذکار,دعا,تسبیح,بخاری,مسلم,رمضان,تجوید,حفظ,پارہ,سورت,مسجد,احادیث,سنت,ختم,قاری
```

**98 / 100 characters.**

Why these terms:
- **القرآن، مجید، پاک، شریف:** the definite form, and the three words Urdu adds to the Quran's name (قرآن
  مجید، قرآن پاک، قرآن شریف); with the name's قرآن they cover all three phrases.
- **پارہ، سورت، ختم، حفظ، قاری:** how Urdu speakers look for a juz, a surah, a khatm, memorization and a
  reciter.
- **اذکار، دعا، تسبیح، رمضان، مسجد:** the daily worship tools, the Ramadan season and the masjid locator.
- **بخاری، مسلم، احادیث، سنت:** Sahih al-Bukhari and Sahih Muslim, the plural of حدیث that Urdu searches
  use, and the Sunnah.
- **تجوید:** the colored tajweed and the 58-lesson course, which is in Urdu.

Left out for room, to rotate in from App Analytics: نمازیں، قضا، کلمہ، روزہ، عربی، قرآنی.

## 4. Promotional Text

Leads with the Urdu interface. Update it with the next release like the English one.

```
نیا: مکمل اردو انٹرفیس، دائیں سے بائیں، سورتوں اور حدیث کی کتابوں کے عربی ناموں کے ساتھ۔ قرآن، حدیث اور نماز کے اوقات ایک مفت ایپ میں، بغیر اشتہارات کے۔
```

**152 / 170 characters.**

## 5. Description

An Urdu rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Urdu headings on their own lines.

```
الاسلام ایپ عبادت اور دین سیکھنے میں آپ کی ساتھی ہے، چاہے آپ پیدائشی مسلمان ہوں، حال ہی میں اسلام قبول کیا ہو، یا اسلام کو جاننے آئے ہوں۔ قرآن مجید، حدیث کی بڑی کتابیں، تفسیر، نماز کے اوقات، نماز ٹریکر اور آپ کی ڈیوائس پر اے آئی سے تلاش، سب ایک سادہ ایپ میں: مفت، بغیر اشتہارات کے، اور آپ کی رازداری کے ساتھ۔

مکمل قرآن مجید
- سورت، پارے یا صفحے کے حساب سے پڑھیں، فہرست موڈ یا مصحف موڈ میں، اور افقی رخ میں آمنے سامنے دو صفحات کے ساتھ۔
- عربی متن، رومن تلفظ اور ترجمہ ساتھ ساتھ، اور آپ کے پسندیدہ رنگوں میں رنگین تجوید۔
- ہر آیت کی تفسیر: انگریزی میں ابن کثیر، معارف القرآن اور تذکیر القرآن، اور عربی میں ابن کثیر، طبری اور سعدی، آف لائن دستیاب۔
- لفظ کا مطالعہ: کسی بھی لفظ پر دو بار ٹیپ کر کے اس کا معنی، اعراب، مادہ اور قرآن میں تمام مقامات دیکھیں۔
- 60 سے زیادہ قراء، آف لائن سننے کے لیے ڈاؤن لوڈز، لامحدود تکرار، اور آیت سے چلائیں، صفحے، سورت، پارے یا پورے قرآن کے آخر تک۔
- روایتِ حفص اور قراءاتِ عشرہ کی انیس دیگر روایات، قراءات ایکسپلورر میں ساتھ ساتھ موازنے کے ساتھ۔
- ملتی جلتی آیات، موضوع کے لحاظ سے دیکھیں، آج کا لفظ، بک مارکس اور نوٹس۔

حفظ اور دہرائی
- قرآن پلانر: ختمِ قرآن کی تاریخ مقرر کریں، اور اپنی حفظ کی ہوئی سورتوں کے لیے دہرائی کا منصوبہ شامل کریں۔
- ٹیسٹ موڈ متن کو تب تک چھپائے رکھتا ہے جب تک آپ آیت پر ٹیپ نہ کریں، تاکہ آپ زبانی پڑھ کر ہر آیت جانچ سکیں۔

حدیث کی بڑی کتابیں
- کتبِ تسعہ (صحیح بخاری، صحیح مسلم، سنن نسائی، سنن ابی داؤد، جامع ترمذی، سنن ابن ماجہ، موطا امام مالک، سنن دارمی اور مسند احمد)، اربعین کے مجموعے، اور ریاض الصالحین جیسی مشہور کتابیں۔
- عربی متن انگریزی ترجمے اور سند کے ساتھ، آج کی حدیث، بک مارکس، اور «بخاری 5» جیسے حوالوں سے تلاش۔
- ایک کتاب میں یا 50 ہزار سے زیادہ احادیث میں تلاش کریں۔ تمام کتابیں ایپ میں شامل ہیں اور آف لائن کام کرتی ہیں۔

آپ کی ڈیوائس پر اے آئی
- قرآن و حدیث میں الفاظ کے بجائے معنی کے لحاظ سے تلاش کریں: «patience in hardship» صبر کی آیات ڈھونڈ لیتا ہے۔ معنی سے تلاش فی الحال انگریزی جملوں سے ہوتی ہے۔
- Apple Intelligence کے ساتھ، اے آئی سے پوچھیں انہی آیات اور احادیث سے جواب دیتا ہے جن کا وہ حوالہ دیتا ہے، اور کبھی فتویٰ نہیں دیتا۔

نماز کے اوقات، قبلہ اور نماز ٹریکر
- ڈیوائس پر حساب کیے گئے درست نماز کے اوقات، آپ کے علاقے کے لیے تجویز کردہ حساب کے طریقے کے ساتھ۔
- آپ کے اوقات کے اوپر ایک جیتا جاگتا آسمان: اپنے راستے پر سورج، رات کو ستارے، اصل منزل میں سہ جہتی چاند، اور چاہیں تو موسم بھی۔
- قبلہ کمپاس، اذان کی آوازیں، پیشگی اطلاعات، سفر موڈ، اور بار بار یاد دہانی کا موڈ، جو نماز ادا کرنے تک یاد دلاتی رہتی ہے۔
- نماز ٹریکر: ہر نماز ایک ٹیپ سے درج کریں، مسلسل دنوں، مثالی دنوں اور ایک کیلنڈر کے ساتھ جو آپ کی پابندی رنگوں میں دکھاتا ہے۔
- نماز کے اوقات کے ویجیٹس، منتخب آیت کا ویجیٹ، کنٹرول سینٹر کے کنٹرولز، رمضان میں لائیو ایکٹیویٹی، اور Apple Watch۔

روزانہ کی عبادت اور سیکھنا
- آج: ہر دن کے لیے ایک آیت، ایک حدیث، ایک دعا اور اللہ کا ایک نام، روزانہ کی یاد دہانی کے کارڈ اور سنت کی یاد دہانیوں کے ساتھ۔
- اذکار، حصن المسلم اور دعاؤں کے مجموعے حوالوں اور آڈیو کے ساتھ، تسبیح کاؤنٹر، اور ڈائری۔
- اللہ کے ننانوے نام تفصیل سے، قرآن کے معجزات، اثباتِ اسلام، اور حدیث اور اس کے علوم۔
- 21 درجوں کے ریڈنگ ٹیسٹ کے ساتھ عربی حروف سیکھیں، اور 58 اسباق کے اردو کورس میں تجوید۔
- عملی رہنمائی، اسلام اور ایمان کے ارکان، زکوٰۃ اور وراثت کے کیلکولیٹر، ہجری کیلنڈر، اور مساجد اور حلال کھانے کی تلاش۔

آپ کے انداز میں
- انٹرفیس اردو، عربی اور انگریزی میں، اس زبان کے مطابق جو آپ iOS کی سیٹنگز میں ایپ کے لیے منتخب کریں۔ اسلام ٹیب کے تفصیلی مضامین فی الحال انگریزی میں ہیں۔
- سادہ موڈ صرف بنیادی چیزیں سامنے رکھتا ہے، اور آپ جب چاہیں مکمل موڈ پر جا سکتے ہیں۔
- اپنی پسند کے ناموں سے پروفائلز اپنے iCloud اکاؤنٹ میں محفوظ کریں اور کسی بھی ڈیوائس پر بحال کریں۔
- متن کے سائز، عربی فونٹس، نمایاں رنگ اور آسمان کے رنگ، اور ترتیبات کے ہر صفحے پر تلاش۔
- iPhone، iPad، Mac اور Apple Watch پر، اور iMessage میں اسلامی اسٹیکرز۔

مفت، بغیر اشتہارات، آپ کی رازداری محفوظ
الاسلام ایپ مکمل طور پر مفت ہے۔ نہ اشتہارات، نہ اکاؤنٹس، نہ سبسکرپشن، نہ ٹریکنگ: آپ کی کوئی سرگرمی جمع یا شیئر نہیں کی جاتی۔

چاہے آپ نماز کے اوقات ڈھونڈ رہے ہوں، قرآن مجید، نبی کریم ﷺ کی حدیث، یا اسلام کی گہری سمجھ، آج ہی الاسلام ایپ ڈاؤن لوڈ کریں۔
```

**3,984 / 4,000 characters.**

## 6. What's New

The release that adds the Urdu interface. Only the Urdu interface is here so far.

```
پوری ایپ اب اردو میں ہے، قرآن، اذان، حدیث اور ترتیبات میں دائیں سے بائیں انٹرفیس کے ساتھ۔

اردو انٹرفیس:
- تمام اسکرینیں، مینیو، ترتیبات، اطلاعات اور ویجیٹس اردو میں، iPhone، iPad، Mac اور Apple Watch پر۔
- ہر جگہ دائیں سے بائیں ترتیب، جبکہ انگریزی متن، جیسے تراجم اور انگریزی تفاسیر، آسانی سے پڑھنے کے لیے بائیں سے دائیں رہتا ہے۔
- سورتوں، حدیث کی کتابوں اور ان کے ابواب کے نام عربی میں۔
- تجوید کا 58 اسباق کا پورا کورس اردو میں۔
- نماز کی اطلاعات اردو میں آتی ہیں۔
- ہندسے iOS کی ترتیبات کے مطابق: عام طور پر 0-9، اور اگر آپ نے اردو ہندسے چنے ہیں تو ۰-۹۔

زبان کا انتخاب:
- ایپ اس زبان کی پیروی کرتی ہے جو آپ iOS کی سیٹنگز میں اس کے لیے منتخب کریں، اور ایپ کی ترتیبات میں زبان کی قطار آپ کو وہاں لے جاتی ہے۔
- زبان بدلنے پر آپ کی اطلاعات نئی زبان میں دوبارہ ترتیب پاتی ہیں۔
- Siri اردو نہیں بولتا، اس لیے Siri سے انگریزی یا عربی میں بات کریں۔
- اسلام ٹیب کے تفصیلی مضامین فی الحال انگریزی میں ہیں۔
```

**900 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (قرآن:، اذان:، حدیث:، ٹولز:، ترتیبات:، اصلاحات اور بہتریاں:). Keep the Urdu interface first, and keep
the whole field near the English length (2,000 to 2,500 characters).

## Glossary

The Urdu the app shows for the features the listing names (`Resources/Localizable.xcstrings`).

| English | Urdu |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | الاسلام (الاسلام ایپ in a sentence)، اذان، قرآن، حدیث، اسلام، ترتیبات |
| Simple Mode / Full | سادہ موڈ / مکمل |
| Prayer Tracker | نماز ٹریکر |
| Test Mode | ٹیسٹ موڈ |
| Quran Planner, Revision | قرآن پلانر، دہرائی |
| Word Study | لفظ کا مطالعہ |
| Qiraat Explorer | قراءات ایکسپلورر |
| Traveling Mode | سفر موڈ |
| Nagging Mode | بار بار یاد دہانی کا موڈ |
| Repeat Forever, Play From Ayah | لامحدود تکرار، آیت سے چلائیں |
| Similar Ayahs, Browse by Theme, Word of the Day | ملتی جلتی آیات، موضوع کے لحاظ سے دیکھیں، آج کا لفظ |
| Hadith of the Day | آج کی حدیث |
| Ask AI, Search by meaning | اے آئی سے پوچھیں، معنی کے لحاظ سے تلاش |
| Chosen Ayah (widget) | منتخب آیت |
| Sunnah Reminders, Daily Reminder | سنت کی یاد دہانیاں، روزانہ یاد دہانی |
| Transliteration | رومن تلفظ |
| Streak, Perfect Days | مسلسل دن، مثالی دن |
| Reading Test, Tajweed Course | ریڈنگ ٹیسٹ، تجوید کورس |
| Proving Islam, Miracles of the Quran (Islam tab) | اثباتِ اسلام، قرآن کے معجزات |
| Masjid Locator, Halal Food Locator (Islam tab) | مسجد کی تلاش، حلال کھانے کی تلاش |
| Zakah Calculator, Inheritance Calculator | زکوٰۃ کیلکولیٹر، وراثت کیلکولیٹر |
| Hijri Calendar, Journal | ہجری کیلنڈر، ڈائری |
| How-To Guides | عملی رہنمائی |
