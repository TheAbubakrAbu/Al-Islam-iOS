# App Store Arabic Listing

The **Arabic** localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store Connect,
add the Arabic localization, then fill Name and Subtitle under App Information and the other four fields on
the version page.
People whose device is set to Arabic see this listing instead of the English one. In the Arabic interface the
app calls itself الإسلام, and its sections are القرآن، الأذان، الحديث; the listing uses the same words.

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
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Arabic Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Modern Standard Arabic as Apple's own Arabic pages read it**, with the respectful register (النبي محمد ﷺ).
  Feature names are the labels the app shows (`Resources/Localizable.xcstrings`, see the glossary below).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, the Arabic comma ، or a new sentence.
  A leading "- " bullet is fine; the English fields use the same.
- **Arabic punctuation** (، ؛ ؟) and Arabic-Indic digits (٦٠، ٢١) in the store text. No version numbers.
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  CarPlay, iMessage.
- **No harakat in the name, subtitle or keywords.** A shadda is a character of its own and nobody types one
  in a search. The description and notes may use them where the app's own label does (متتبّع الصلاة).
- **Be honest about what is still English:** the in-depth articles of the Islam tab, and AI search by
  meaning, which matches English phrases only.
- Keep in sync with the English docs: `App Store Description.md`, `Keywords.md`, `Promotional Text.md` and
  `Whats New.md`. When an English field changes for a feature, change the Arabic one in the same pass.

## 1. Name

Names are unique across the store, so a bare الإسلام will not be accepted. Each option keeps الإسلام first,
then a short descriptor after a separator, as the English name does with "|".

**Recommended:**

```
الإسلام | قرآن، أذان، حديث
```

**26 / 30 characters.**

The app's three sections as bare words. Each one is a search term of its own (no و attached to it), and the
forms with ال go in the keyword field.

**Alternate A:**

```
الإسلام | القرآن والأذان
```

**24 / 30 characters.**

The app's own section names with the article; reads the most naturally, but drops الحديث.

**Alternate B:**

```
الإسلام: القرآن ومواقيت الصلاة
```

**30 / 30 characters.**

Leads with مواقيت الصلاة, the most searched prayer phrase, and sits exactly at the limit. Pair it with a
subtitle that does not repeat مواقيت or الصلاة, for example الحديث، القبلة، التفسير (23 characters).

## 2. Subtitle

**Recommended** (with the recommended name):

```
مواقيت الصلاة، القبلة، التفسير
```

**30 / 30 characters.**

**Alternate:**

```
مواقيت الصلاة وتفسير القرآن
```

**27 / 30 characters.**

Reads as one phrase and adds the القرآن form. With it, drop القرآن from the keyword field and use the
characters for القبلة.

## 3. Keywords

Written for the recommended name and subtitle. No word repeats one of theirs (الإسلام، قرآن، أذان، حديث،
مواقيت، الصلاة، القبلة، التفسير); if an alternate ships, re-check that and swap in the words it dropped.

```
القرآن,القران,الكريم,مصحف,اذان,اوقات,اذكار,دعاء,تفسير,قبلة,البخاري,مسلم,رمضان,تسبيح,تجويد,حفظ,حصن
```

**97 / 100 characters.**

Why these terms:
- **القرآن، القران، الكريم:** the name has the bare قرآن; these add the definite form, the spelling without
  the madda that most people type, and الكريم for "القرآن الكريم", the most common Quran search.
- **مصحف:** mushaf searches, and the page mode reader.
- **اذان، اوقات:** أذان as it is usually typed, without the hamza; اوقات pairs with the subtitle's الصلاة for
  "اوقات الصلاة", searched as often as مواقيت الصلاة.
- **اذكار، دعاء، تسبيح، رمضان:** the daily worship tools, and the Ramadan season.
- **تفسير، قبلة:** the subtitle's words without ال.
- **البخاري، مسلم، حصن:** Sahih al-Bukhari and Sahih Muslim; مسلم also matches the audience, and with حصن it
  covers "حصن المسلم".
- **تجويد، حفظ:** the colored tajweed and the 58-lesson course; memorization (Test Mode, the Revision plan).

Left out for room, to rotate in from App Analytics: قران، صلاة، ختمة، مسجد، احاديث، اتجاه (for "اتجاه
القبلة"). If Apple's Arabic search turns out to fold the hamza and madda (أ and آ to ا), القران and اذان are
redundant and are the first to swap.

## 4. Promotional Text

Leads with the Arabic interface. Update it with the next release like the English one.

```
جديد: واجهة عربية كاملة من اليمين إلى اليسار، بأسماء عربية للسور والكتب، ومع Siri بالعربية. القرآن والحديث ومواقيت الصلاة في تطبيق مجاني بلا إعلانات.
```

**149 / 170 characters.**

## 5. Description

An Arabic rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Arabic headings on their own lines.

```
تطبيق الإسلام رفيقك في عبادتك وتعلّم دينك، سواء نشأت على الإسلام أو اعتنقته حديثًا أو جئت تتعرّف عليه. القرآن الكريم وكتب الحديث الكبرى والتفسير ومواقيت الصلاة ومتتبّع الصلاة والبحث بالذكاء الاصطناعي على جهازك، في تطبيق واحد بسيط: مجاني تمامًا، بلا إعلانات، ويحفظ خصوصيتك.

القرآن الكريم كاملًا
- اقرأ حسب السورة أو الجزء أو الصفحة، في وضع القائمة أو وضع المصحف، مع صفحتين متجاورتين في الوضع الأفقي.
- النص العربي والكتابة اللاتينية والترجمة جنبًا إلى جنب، مع تجويد ملوّن بألوان تختارها.
- تفسير لكل آية: ابن كثير ومعارف القرآن وتذكير القرآن بالإنجليزية، وابن كثير والطبري والسعدي بالعربية، متاحة دون اتصال.
- دراسة الكلمة: اضغط على أي كلمة مرتين لمعناها وإعرابها وجذرها وكل مواضعها في القرآن.
- أكثر من ٦٠ قارئًا، وتنزيلات للاستماع دون اتصال، و«تكرار بلا توقف»، و«التشغيل من الآية» حتى آخر الصفحة أو السورة أو الجزء أو القرآن كله.
- رواية حفص وتسع عشرة رواية أخرى من القراءات العشر، مع المقارنة بينها جنبًا إلى جنب في «مستكشف القراءات».
- الآيات المتشابهة، والتصفّح حسب الموضوع، وكلمة اليوم، والعلامات، والملاحظات.

الحفظ والمراجعة
- مخطِّط القرآن: حدّد موعدًا لإتمام ختمتك، وأضف خطة مراجعة للسور التي تحفظها.
- «وضع الاختبار» يُخفي النص حتى تضغط على الآية، فتتلو من حفظك وتتحقق من كل آية.

كتب الحديث الكبرى
- الكتب التسعة (صحيح البخاري، وصحيح مسلم، وسنن النسائي، وسنن أبي داود، وجامع الترمذي، وسنن ابن ماجه، وموطأ مالك، وسنن الدارمي، ومسند أحمد)، وكتب الأربعين، وكتب مشهورة مثل رياض الصالحين.
- النص العربي مع الترجمة الإنجليزية والإسناد، وحديث اليوم، والعلامات، والبحث بالمرجع مثل «البخاري ٥».
- ابحث في كتاب واحد أو في أكثر من ٥٠ ألف حديث. كل الكتب مضمّنة في التطبيق وتعمل دون اتصال.

ذكاء اصطناعي على جهازك
- ابحث في القرآن والحديث بالمعنى لا بالكلمة: عبارة «patience in hardship» تجد آيات الصبر. يعمل البحث بالمعنى بالعبارات الإنجليزية حاليًا.
- مع Apple Intelligence، يجيبك «اسأل الذكاء الاصطناعي» من الآيات والأحاديث التي يستشهد بها، ولا يُصدر فتوى أبدًا.

مواقيت الصلاة والقبلة ومتتبّع الصلاة
- مواقيت صلاة دقيقة تُحسب على جهازك، مع طريقة حساب مقترحة لمنطقتك.
- سماء حيّة فوق مواقيتك: الشمس في مسارها، والنجوم ليلًا، وقمر ثلاثي الأبعاد في طوره الحقيقي، والطقس إن شئت.
- بوصلة القبلة، وأصوات الأذان، والإشعارات المسبقة، و«وضع السفر»، و«وضع التذكير المتكرر» الذي يذكّرك حتى تصلي.
- متتبّع الصلاة: علّم كل صلاة بضغطة، مع سلسلة الأيام والأيام المثالية وتقويم يُظهر التزامك بالألوان.
- أدوات لمواقيت الصلاة، وأداة «الآية المختارة»، وعناصر في مركز التحكم، ونشاط مباشر في رمضان، وApple Watch.

العبادة اليومية والتعلّم
- «اليوم»: آية وحديث ودعاء واسم من أسماء الله الحسنى لكل يوم، مع بطاقة تذكير يومي و«تذكيرات السنة».
- الأذكار وحصن المسلم ومجموعات الأدعية بمصادرها وتسجيلاتها الصوتية، وعدّاد للتسبيح، ودفتر يوميات.
- أسماء الله الحسنى بالتفصيل، ومعجزات القرآن، وإثبات الإسلام، والحديث وعلومه.
- تعلّم الحروف العربية مع «اختبار القراءة» في ٢١ مستوًى، والتجويد في دورة من ٥٨ درسًا.
- أدلة عملية، وأركان الإسلام والإيمان، وحاسبتا الزكاة والمواريث، والتقويم الهجري، ودليلا المساجد والطعام الحلال.

على طريقتك
- الواجهة بالعربية والإنجليزية، حسب اللغة التي تختارها للتطبيق في إعدادات iOS. أما المقالات المفصّلة في تبويب الإسلام فبالإنجليزية حاليًا.
- «الوضع المبسّط» يُبقي الأساسيات على الشاشة، وبإمكانك التبديل إلى الوضع الكامل متى شئت.
- احفظ ملفات شخصية بأسماء تختارها في حسابك على iCloud، واستعدها على أي جهاز.
- أحجام النص، والخطوط العربية، وألوان التمييز والسماء، وشريط بحث في كل صفحة إعدادات.
- على iPhone وiPad وMac وApple Watch، مع ملصقات إسلامية في iMessage.

مجاني، بلا إعلانات، ويحفظ خصوصيتك
تطبيق الإسلام مجاني تمامًا. لا إعلانات، ولا حسابات، ولا اشتراكات، ولا تتبّع: لا يُجمَع شيء مما تفعله ولا يُشارَك.

سواء كنت تبحث عن مواقيت الصلاة أو القرآن الكريم أو حديث النبي محمد ﷺ أو فهمٍ أعمق للإسلام، حمّل تطبيق الإسلام اليوم.
```

**3,635 / 4,000 characters.**

## 6. What's New

The release that adds the Arabic interface. Only the Arabic interface is here so far.

```
التطبيق كله الآن بالعربية، بواجهة من اليمين إلى اليسار في القرآن والأذان والحديث والإعدادات.

الواجهة العربية:
- الشاشات والقوائم والإعدادات والإشعارات والأدوات كلها بالعربية، على iPhone وiPad وMac وApple Watch.
- تخطيط من اليمين إلى اليسار في كل مكان، وتبقى النصوص الإنجليزية، كالترجمات والتفاسير الإنجليزية، من اليسار إلى اليمين لتُقرأ بسهولة.
- أسماء السور وكتب الحديث وأبوابها بالعربية.
- تحدّث إلى Siri بالعربية: شغّل سورة أو افتحها، وتابع التلاوة من حيث توقفت، واسأل عن الصلاة القادمة.
- تصلك إشعارات الصلاة بالعربية، ويظهر اسم مدينتك بلغة الواجهة.
- تقبل حقول البحث الأرقام العربية، مثل ٢:٢٥٥ أو «البخاري ٥».

اختيار اللغة:
- يتبع التطبيق اللغة التي تختارها له في إعدادات iOS، ويوصلك إليها صف «اللغة» في إعدادات التطبيق.
- عند تغيير اللغة تُعاد جدولة إشعاراتك باللغة الجديدة.
- تبقى المقالات المفصّلة في تبويب الإسلام بالإنجليزية حاليًا.
```

**844 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (القرآن:، الأذان:، الحديث:، الأدوات:، الإعدادات:، إصلاحات وتحسينات:). Keep the Arabic interface first,
and keep the whole field near the English length (2,000 to 2,500 characters).

## Glossary

The Arabic the app shows for the features the listing names (`Resources/Localizable.xcstrings`). The Islam tab
names have no Arabic label yet; those below come from the catalog's own sentences that mention them.

| English | Arabic |
|---|---|
| Al-Quran, Al-Adhan, Al-Hadith | القرآن، الأذان، الحديث |
| Simple Mode / Full | الوضع المبسّط / كامل |
| Prayer Tracker | متتبّع الصلاة |
| Test Mode | وضع الاختبار |
| Quran Planner, Revision | مخطِّط القرآن، المراجعة |
| Word Study | دراسة الكلمة |
| Qiraat Explorer | مستكشف القراءات |
| Traveling Mode | وضع السفر |
| Nagging Mode | وضع التذكير المتكرر |
| Repeat Forever, Play From Ayah | تكرار بلا توقف، التشغيل من الآية |
| Similar Ayahs, Browse by Theme, Word of the Day | الآيات المتشابهة، تصفّح حسب الموضوع، كلمة اليوم |
| Ask AI, Search by meaning | اسأل الذكاء الاصطناعي، البحث بالمعنى |
| Chosen Ayah (widget), widgets | الآية المختارة، الأدوات |
| Sunnah Reminders, Daily Reminder | تذكيرات السنة، تذكير يومي |
| Transliteration | الكتابة اللاتينية |
| List mode, page mode | وضع القائمة، وضع المصحف |
| Pre-notifications | الإشعارات المسبقة |
| Streak, Perfect Days | سلسلة الأيام، الأيام المثالية |
| The forty collections | كتب الأربعين |
| Proving Islam, Miracles of the Quran (Islam tab) | إثبات الإسلام، معجزات القرآن |
| Masjid and Halal Food Locators (Islam tab) | دليل المساجد، دليل الطعام الحلال |
