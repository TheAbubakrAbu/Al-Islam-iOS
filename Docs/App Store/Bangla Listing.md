# App Store Bangla Listing

The **Bangla** (`bn`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store
Connect (Bangla listings since 2026), add the Bangla localization, then fill Name and Subtitle under App
Information and the other four fields on the version page. Screenshots can stay English: App Store Connect
shows the primary language's screenshots for a localization that has none of its own.
People whose device is set to Bangla see this listing instead of the English one. In the Bangla interface the
app keeps its Latin name, Al-Islam (on the Home Screen too), and its tabs are আযান, কুরআন, হাদীস, ইসলাম and
সেটিংস; the listing uses the same words.

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
  file, not the store), after NFC normalization, the form the app's catalog and `labels.json` use. In NFC a
  letter with a nukta (য়, ড়, ঢ়) is two code points, and a conjunct counts its hasanta (্): নামাজের সময় is 12.
  Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Bangla Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Standard Bangla for Bangladeshi Muslims**, in Bangla Academy spelling, addressing the reader as "আপনি"
  with polite imperatives (পড়ুন, ট্যাপ করুন, বেছে নিন), every sentence ending in the danda । (never a Latin
  full stop after Bangla). Islamic terms as the app's Bangla glossary writes them (কুরআন, হাদীস, নামাজ, আযান,
  কিবলা, যিকির, দোয়া, তাজবীদ, রমজান, সাহরি, খতম). The honorific is always spelled out, "(সাল্লাল্লাহু আলাইহি
  ওয়াসাল্লাম)", after the possessive name (নবী মুহাম্মাদের (...) হাদীস): App Store Connect rejects the
  one-glyph ligature (U+FDFA) as an invalid character.
- **Feature names are the labels the app shows** (the Bangla translation of `Resources/Localizable.xcstrings`;
  `bn/labels.json` binds 331 of them; see the glossary below). A label that is a noun stands bare and may take a
  case ending (নামাজ ট্র্যাকার, বাছাই করা আয়াতের উইজেট). A label that is an imperative (এআই-কে জিজ্ঞাসা করুন,
  এই আয়াত থেকে শুনুন, বিষয় অনুসারে দেখুন) goes in "quotes", so it reads as a name and not as an instruction.
  Apple's own features take the Bangla loanwords Bangladeshi users read on their phones (সেটিংস, উইজেট, কন্ট্রোল
  সেন্টার, লাইভ অ্যাক্টিভিটি, লক স্ক্রিন, শর্টকাট).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma or a new sentence. A leading
  "- " bullet is fine; the English fields use the same. The hyphen inside a Bangla word (যে-ই, আত-তাবারী) and
  before a case ending (Al-Islam-এর) is a hyphen, not a dash.
- **Plain characters in every store field:** Bangla letters, the danda, Western digits with a comma for
  thousands (50,000), and straight ASCII quotes (" "), never curly quotes or « ». No Bengali digits (০-৯), no
  ZWJ or ZWNJ (U+200D, U+200C, which some keyboards slip into র‍্যা), no direction marks. On 2026-10-29 App
  Store Connect refused characters in Al-Islam's Urdu fields without naming them, so these fields keep to the
  plainest characters of the script. No version numbers.
- **App names stay Latin:** Al-Islam, Al-Adhan, Al-Quran. A case ending joins a Latin name with a hyphen
  (Al-Islam-এর, Apple Watch-এ, iCloud-এ, iMessage-এর), as the app's Bangla strings join one after a
  placeholder. Brand names stay Latin too: Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad,
  Mac, iMessage, iOS. So do the English editions' titles (Maarif Ul Quran, Tazkirul Quran): written in Bangla
  they would read as the Bangla editions Bangladeshi readers know, which the app does not have.
- **Search spellings go in the keyword field only.** The name, subtitle and description write the app's forms
  (কুরআন, হাদীস, আযান, সাহরি). The keyword field adds the spellings Bangladeshis type (কোরআন, হাদিস, আজান,
  সেহরি) and the Latin words they type on an English keyboard (quran, namaz): each is a search term of its own.
- **Case endings:** Bangla fuses them to the word (নামাজের, ইফতারের), and whether Apple's search folds an
  inflected word back to its stem is not documented. The keyword field therefore treats a bare word as a term
  of its own even when its inflected form is in the name or subtitle (নামাজ beside the subtitle's নামাজের). If
  App Analytics shows Apple folding them, those bare words are the first to swap.
- **Be honest about what is still English:** the in-depth articles of the Islam tab, AI search by meaning
  (English phrases only), the Quran and hadith translations (English, beside the Arabic; there is no Bangla
  translation, so the description says ইংরেজি অনুবাদ and the keyword field leaves out বাংলা, অনুবাদ and অর্থসহ),
  and Siri, which has no Bangla, so its phrases are said in English, as the app's own Bangla Siri tips say
  ("Siri বাংলায় নেই"). The surah names stay Latin (Al-Baqarah) with their meaning in Bangla, and the hadith
  reference lookup reads Latin names only, so the description keeps "Bukhari 5" in Latin.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with the Arabic, Urdu and Indonesian listings: when a field changes for a feature, change
  it here too.

## 1. Name

The name keeps Al-Islam first, then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | কুরআন, হাদীস ও আযান
```

**30 / 30 characters.**

The app's three sections as bare words, the shape of the Urdu and Arabic names, each the label of its tab.
Bangla fits all three where Indonesian could not, so the subtitle is free for prayer times, the Qibla and
tafsir, as in the Urdu subtitle. কুরআন and হাদীস are the app's spellings; the keyword field adds কোরআন, হাদিস,
আজান and the Latin quran.

## 2. Subtitle

```
নামাজের সময়, কিবলা ও তাফসীর
```

**28 / 30 characters.**

নামাজের সময় is the app's label for Prayer Times and the phrase Bangladeshis search for them; with the keyword
field's সময়সূচি it also answers "নামাজের সময়সূচি", the timetable search. কিবলা is the Qibla, and তাফসীর the
tafsir for every ayah.

## 3. Promotional Text

Leads with the Bangla interface. Update it with the next release like the English one.

```
নতুন: পূর্ণাঙ্গ বাংলা ইন্টারফেস, সূরার লাতিন নামের পাশে বাংলা অর্থসহ। কুরআন, হাদীস ও নামাজের সময়, সবই একটি বিনামূল্যের, বিজ্ঞাপনমুক্ত অ্যাপে।
```

**142 / 170 characters.**

## 4. Description

A Bangla rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Bangla headings on their own lines (Bangla has no capitals). Four lines say what is English: the Quran
line and the hadith line name an English translation (ইংরেজি অনুবাদ), the AI line says search by meaning still
works from English phrases, and the interface line says the Islam tab's articles are English. The Nine books
are named generically (নয়টি প্রধান গ্রন্থ) with each book's Bangla name, as Bangladeshi readers know them
(বুখারী, তিরমিযী, মুসনাদে আহমাদ); the Six Books' label, সিহাহ সিত্তাহ, would not cover all nine.

```
Al-Islam ইসলাম পালনে আপনার পূর্ণাঙ্গ সঙ্গী, আপনি জন্মসূত্রে মুসলিম, নওমুসলিম বা ইসলাম সম্পর্কে জানতে আগ্রহী, যে-ই হোন না কেন। কুরআন, প্রধান হাদীসগ্রন্থ, তাফসীর, নামাজের সময়, নামাজ ট্র্যাকার এবং ডিভাইসেই চলা এআই অনুসন্ধান, সবই এক অ্যাপে: সম্পূর্ণ বিনামূল্যে, বিজ্ঞাপনমুক্ত এবং আপনার গোপনীয়তা সুরক্ষিত।

পূর্ণাঙ্গ কুরআন
- সূরা, পারা বা পৃষ্ঠা ধরে পড়ুন, তালিকা আকারে বা মুসহাফের মতো পৃষ্ঠা আকারে, আর ল্যান্ডস্কেপে পাশাপাশি দুই পৃষ্ঠা।
- আরবি, উচ্চারণ ও ইংরেজি অনুবাদ পাশাপাশি, সঙ্গে রঙিন তাজবীদ, যার রং আপনি নিজেই বেছে নিতে পারেন।
- যেকোনো আয়াতের তাফসীর: ইংরেজিতে ইবনে কাসীর, Maarif Ul Quran ও Tazkirul Quran, আর আরবিতে ইবনে কাসীর, আত-তাবারী ও আস-সাদী, অফলাইনেও।
- শব্দ বিশ্লেষণ: যেকোনো শব্দে দুবার ট্যাপ করে দেখুন তার অর্থ, ব্যাকরণ, মূল ধাতু এবং কুরআনে তা যেখানে যেখানে এসেছে।
- 60 জনের বেশি কারী, অফলাইন ডাউনলোড, অবিরাম পুনরাবৃত্তি, আর "এই আয়াত থেকে শুনুন", যা পৃষ্ঠা, সূরা, পারা বা পুরো কুরআনের শেষ পর্যন্ত চলে।
- হাফস ও দশ কিরাআতের আরও 19টি রিওয়ায়াত, যা কিরাআত এক্সপ্লোরারে পাশাপাশি তুলনা করা যায়।
- সদৃশ আয়াত, "বিষয় অনুসারে দেখুন", আজকের শব্দ, বুকমার্ক ও নোট।

মুখস্থ ও রিভিশন
- কুরআন প্ল্যানার: খতমের তারিখ ঠিক করুন, আর মুখস্থ সূরাগুলোর জন্য রিভিশন পরিকল্পনা যোগ করুন।
- পরীক্ষা মোড আপনি ট্যাপ না করা পর্যন্ত লেখা লুকিয়ে রাখে, যাতে মুখস্থ থেকে পড়ে প্রতিটি আয়াত যাচাই করতে পারেন।

প্রধান হাদীসগ্রন্থ
- নয়টি প্রধান গ্রন্থ (বুখারী, মুসলিম, নাসাঈ, আবু দাউদ, তিরমিযী, ইবনে মাজাহ, মুয়াত্তা মালিক, দারেমী, মুসনাদে আহমাদ), চল্লিশ হাদীসের সংকলন এবং রিয়াদুস সালেহীনের মতো প্রসিদ্ধ গ্রন্থ।
- আরবি লেখা ও ইংরেজি অনুবাদ, বর্ণনাকারীদের সনদ ও প্রত্যেক বর্ণনাকারীর পাতা, আজকের হাদীস, বুকমার্ক, আর "Bukhari 5"-এর মতো রেফারেন্স দিয়ে খোঁজা।
- একটি গ্রন্থে বা 50,000-এর বেশি হাদীসের সবগুলোতে অনুসন্ধান করুন, সবই অফলাইনে।

ডিভাইসেই এআই
- শব্দ নয়, অর্থ দিয়ে কুরআন ও হাদীসে খুঁজুন: "patience in hardship" লিখলে সবর বিষয়ক আয়াত পাওয়া যায়। অর্থ দিয়ে অনুসন্ধান আপাতত ইংরেজি বাক্যাংশেই কাজ করে।
- Apple Intelligence চালু থাকলে "এআই-কে জিজ্ঞাসা করুন" উদ্ধৃত আয়াত ও হাদীস থেকেই উত্তর দেয়, কখনো ফতোয়া দেয় না।

নামাজের সময়, কিবলা ও ট্র্যাকার
- আপনার ডিভাইসেই হিসাব করা নির্ভুল নামাজের সময়, আপনার অঞ্চলের জন্য প্রস্তাবিত পদ্ধতিতে।
- নামাজের সময়ের ওপর জীবন্ত আকাশ: নিজ পথে চলা সূর্য, রাতের তারা, চাঁদের প্রকৃত কলা অনুযায়ী 3D চাঁদ, আর চাইলে আবহাওয়া।
- কিবলা কম্পাস, আযানের সাউন্ড, আগাম নোটিফিকেশন, সফর মোড এবং তাগাদা মোড, যা নামাজ না পড়া পর্যন্ত আপনাকে মনে করিয়ে দেয়।
- নামাজ ট্র্যাকার: এক ট্যাপে প্রতিটি নামাজ চিহ্নিত করুন, সঙ্গে ধারাবাহিকতা, নিখুঁত দিন ও রঙিন ক্যালেন্ডার।
- নামাজের সময় ও বাছাই করা আয়াতের উইজেট, কন্ট্রোল সেন্টারের কন্ট্রোল, রমজানের লাইভ অ্যাক্টিভিটি এবং Apple Watch।

দৈনিক ইবাদত ও শিক্ষা
- আজ: দিনের আয়াত, হাদীস, দোয়া ও আল্লাহর নাম, আজকের নসিহত কার্ড এবং সুন্নাহ রিমাইন্ডার।
- যিকির ও আযকার, হিসনুল মুসলিম, উৎস ও অডিওসহ দোয়ার সংকলন, তাসবীহ কাউন্টার এবং ইসলামি ডায়েরি।
- বিস্তারিতভাবে আল্লাহর 99টি নাম, কুরআনের মুজিযা, ইসলামের প্রমাণ এবং হাদীসশাস্ত্র।
- 21 স্তরের পড়ার পরীক্ষা দিয়ে আরবি বর্ণমালা শিখুন, আর 58 পাঠের তাজবীদ কোর্স ও তাজবীদ পরীক্ষা দিয়ে তাজবীদ।
- ধাপে ধাপে নির্দেশিকা, ইসলাম ও ঈমানের রুকন, যাকাত ও উত্তরাধিকার ক্যালকুলেটর, হিজরি ক্যালেন্ডার, মসজিদ ও হালাল খাবার সন্ধান।

আপনার মতো করে
- ইন্টারফেস বাংলা, ইংরেজি ও আরবিসহ 15টি ভাষায়: iOS সেটিংসে এই অ্যাপের জন্য ভাষা বেছে নিন। ইসলাম ট্যাবের বিস্তারিত প্রবন্ধগুলো এখনো ইংরেজিতে।
- সহজ মোড শুধু প্রয়োজনীয় জিনিসগুলো সামনে রাখে। যেকোনো সময় পূর্ণ মোডে যেতে পারেন।
- নাম দেওয়া প্রোফাইল আপনার নিজের iCloud-এ ব্যাকআপ করুন এবং যেকোনো ডিভাইসে ফিরিয়ে আনুন।
- লেখার আকার, আরবি ফন্ট, অ্যাকসেন্ট ও আকাশের রং, আর প্রতিটি সেটিংস পৃষ্ঠায় অনুসন্ধান।
- iPhone, iPad, Mac ও Apple Watch, সঙ্গে iMessage-এর জন্য ইসলামি স্টিকার।

বিনামূল্যে, বিজ্ঞাপনমুক্ত, গোপনীয়তা সুরক্ষিত
Al-Islam সম্পূর্ণ বিনামূল্যে। কোনো বিজ্ঞাপন, অ্যাকাউন্ট, সাবস্ক্রিপশন বা ট্র্যাকিং নেই: আপনি যা করেন, তার কিছুই সংগ্রহ বা শেয়ার করা হয় না।

নামাজের সময়, কুরআন, নবী মুহাম্মাদের (সাল্লাল্লাহু আলাইহি ওয়াসাল্লাম) হাদীস বা ইসলামের আরও গভীর জ্ঞান, আপনি যা-ই খুঁজুন, আজই Al-Islam ডাউনলোড করুন।
```

**3,944 / 4,000 characters.**

## 5. What's New

The release that adds the Bangla interface; all twelve new languages ship in one release. Only the interface
notes are here so far. The Urdu text's right-to-left and digit lines have no Bangla counterpart and are left
out; in their place are the Latin surah names with their Bangla meanings, the Bangla prayer names (the
catalog's ফজর, যোহর, আসর, মাগরিব, এশা), and a line saying the translations are English. The language line
names the other eleven new languages, then all fifteen interface languages.

```
Al-Islam-এর ইন্টারফেস এখন বাংলায়: আযান, কুরআন ও হাদীস থেকে ইসলাম ও সেটিংস পর্যন্ত।

বাংলা ইন্টারফেস:
- সব স্ক্রিন, মেনু, সেটিংস, নোটিফিকেশন ও উইজেট বাংলায়, iPhone, iPad, Mac ও Apple Watch-এ।
- সূরার নাম লাতিন হরফেই থাকে, যেমন Al-Baqarah, আর পাশে থাকে বাংলায় তার অর্থ (গাভী)।
- নামাজের নাম বাংলায়: ফজর, যোহর, আসর, মাগরিব ও এশা।
- নামাজের নোটিফিকেশন আসে বাংলায়।
- 58 পাঠের পুরো তাজবীদ কোর্স বাংলায়।
- কুরআন ও হাদীসের অনুবাদ আপাতত ইংরেজিতে, আরবি লেখার পাশে।

নতুন ভাষা:
- Al-Islam এখন ইন্দোনেশীয়, মালয়, তুর্কি, ফরাসি, রুশ, হিন্দি, জার্মান, স্প্যানিশ, মালয়ালম, তামিল ও ডাচ ভাষাতেও পাওয়া যায়। সব মিলিয়ে 15টি ভাষা: ইংরেজি, আরবি, উর্দু, ইন্দোনেশীয়, মালয়, তুর্কি, ফরাসি, বাংলা, রুশ, হিন্দি, জার্মান, স্প্যানিশ, মালয়ালম, তামিল ও ডাচ।

ভাষা বেছে নেওয়া:
- iOS সেটিংসে এই অ্যাপের জন্য আপনি যে ভাষা বেছে নেন, অ্যাপটি সেই ভাষাই অনুসরণ করে, আর অ্যাপের সেটিংসের "ভাষা" সারি আপনাকে সেখানে নিয়ে যায়।
- ভাষা বদলালে আপনার নোটিফিকেশন নতুন ভাষায় আবার নির্ধারিত হয়।
- Siri বাংলায় নেই, তাই Siri-কে ইংরেজিতে বলুন।
- ইসলাম ট্যাবের বিস্তারিত প্রবন্ধ এবং অর্থ দিয়ে অনুসন্ধান আপাতত ইংরেজিতে।
```

**1,084 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (কুরআন:, আযান:, হাদীস:, ইসলামি টুলস:, সেটিংস:, ত্রুটি সংশোধন ও উন্নতি:). Keep the Bangla interface first, and
keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al-Islam, কুরআন, হাদীস, আযান,
নামাজের, সময়, কিবলা, তাফসীর); as in the Urdu and Indonesian fields, another spelling of the same word (কোরআন
beside কুরআন, হাদিস beside হাদীস, আজান beside আযান, the Latin quran) is a search term of its own, and so is a
bare word beside its inflected form (নামাজ beside নামাজের; see Guidelines).

```
quran,namaz,নামাজ,সময়সূচি,আজান,কোরআন,হাদিস,দোয়া,রমজান,সেহরি,ইফতার,তাসবীহ,তিলাওয়াত,কম্পাস,তাজবীদ
```

**98 / 100 characters.**

Why these terms:
- **quran, namaz:** the two words Bangladeshis most often type on an English keyboard ("quran", "namaz time",
  "namaz shikkha"); English's `Keywords.md` carries both too.
- **নামাজ, সময়সূচি:** the bare নামাজ for "নামাজ শিক্ষা" and "নামাজ ট্র্যাকার", and সময়সূচি with the
  subtitle's নামাজের for "নামাজের সময়সূচি", the usual search for a prayer timetable.
- **আজান, কোরআন, হাদিস:** the spellings Bangladeshis type beside the app's আযান, কুরআন and হাদীস (কোরআন is
  also the Bangla Academy form, and "কোরআন শরীফ" a common search).
- **দোয়া, তাসবীহ:** the dua collections and Hisn al-Muslim, and the তাসবীহ কাউন্টার.
- **রমজান, সেহরি, ইফতার:** the Ramadan Live Activity, which counts down to the end of suhoor and to iftar:
  "সেহরি ও ইফতারের সময়সূচি" is searched every Ramadan. সেহরি is how most people spell the app's সাহরি.
- **তিলাওয়াত:** over 60 reciters ("কুরআন তিলাওয়াত").
- **কম্পাস:** with the subtitle's কিবলা, the app's label কিবলা কম্পাস.
- **তাজবীদ:** the colored tajweed, the তাজবীদ কোর্স and the তাজবীদ পরীক্ষা.

Left out for room, to rotate in from App Analytics: যিকির, রোজা, সূরা, পারা, মুখস্থ, হিফজ, মসজিদ, হিজরি,
ক্যালেন্ডার, আল্লাহর নাম (নাম), muslim, dua, and বুখারী (a large search, but most of it wants a Bangla
translation of Sahih al-Bukhari, which the app does not have). Deliberately excluded: বাংলা, অনুবাদ and অর্থসহ
("কুরআন শরীফ বাংলা অর্থসহ" wants a Bangla translation, and the app's translations are English); ইবনে and
কাসীর (for "তাফসীর ইবনে কাসীর"), since a Bangla search for it wants the Bangla edition and the app has it in
English and Arabic only; and নূরানী, the name of a published teaching method the app does not follow.

## Glossary

The Bangla the app shows for the features the listing names (the Bangla translation of
`Resources/Localizable.xcstrings`; `bn/labels.json` binds the ones it holds). Every label here was checked against the merged catalog (2026-11-20) and matches it.

| English | Bangla |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, আযান, কুরআন, হাদীস, ইসলাম, সেটিংস |
| Prayer Times, Qibla Compass, Prenotification, Adhan Sound | নামাজের সময়, কিবলা কম্পাস, আগাম নোটিফিকেশন, আযানের সাউন্ড |
| Simple Mode / Full | সহজ মোড / পূর্ণ মোড |
| Prayer Tracker, Streak, Perfect Days | নামাজ ট্র্যাকার, ধারাবাহিকতা, নিখুঁত দিন |
| Test Mode | পরীক্ষা মোড |
| Quran Planner, Revision, Khatm | কুরআন প্ল্যানার, রিভিশন, খতম |
| Read as List, Read as Pages | তালিকা আকারে পড়ুন, পৃষ্ঠা আকারে পড়ুন |
| Transliteration | উচ্চারণ |
| Word Study | শব্দ বিশ্লেষণ |
| Qiraat Explorer, the Ten Qiraat, riwayah | কিরাআত এক্সপ্লোরার, দশ কিরাআত, রিওয়ায়াত |
| Traveling Mode | সফর মোড |
| Nagging Mode | তাগাদা মোড |
| Repeat Forever, Play From Ayah | অবিরাম পুনরাবৃত্তি, এই আয়াত থেকে শুনুন |
| Similar Ayahs, Browse by Theme, Word of the Day | সদৃশ আয়াত, বিষয় অনুসারে দেখুন, আজকের শব্দ |
| Bookmarks, Notes | বুকমার্ক, নোট |
| The Nine books, Chain of Narrators | নয়টি প্রধান গ্রন্থ, বর্ণনাকারীদের সনদ |
| Hadith of the Day | আজকের হাদীস |
| Ask AI, Search by meaning | এআই-কে জিজ্ঞাসা করুন, অর্থ দিয়ে অনুসন্ধান |
| Chosen Ayah (widget), Control Center, Live Activity | বাছাই করা আয়াত, কন্ট্রোল সেন্টার, লাইভ অ্যাক্টিভিটি |
| Today, Name of Allah, Reminder of the Day | আজ, আল্লাহর নাম, আজকের নসিহত |
| Sunnah Reminders, Daily Reminder | সুন্নাহ রিমাইন্ডার, দৈনিক রিমাইন্ডার |
| Dhikr & Remembrances, Hisn al-Muslim, Tasbih Counter, Islamic Journal | যিকির ও আযকার, হিসনুল মুসলিম, তাসবীহ কাউন্টার, ইসলামি ডায়েরি |
| 99 Names of Allah | আল্লাহর 99টি নাম |
| Miracles of the Quran, Proving Islam, The Sciences of Hadith | কুরআনের মুজিযা, ইসলামের প্রমাণ, হাদীসশাস্ত্র |
| Arabic Alphabet, Reading Test | আরবি বর্ণমালা, পড়ার পরীক্ষা |
| Tajweed Course, Tajweed Test | তাজবীদ কোর্স, তাজবীদ পরীক্ষা |
| How-To Guides, Pillars & Beliefs | ধাপে ধাপে নির্দেশিকা, রুকন ও আকীদা |
| Zakah Calculator, Inheritance Calculator, Hijri Calendar | যাকাত ক্যালকুলেটর, উত্তরাধিকার ক্যালকুলেটর, হিজরি ক্যালেন্ডার |
| Masjid Locator, Halal Food Locator | মসজিদ সন্ধান, হালাল খাবার সন্ধান |
| iCloud Backup, Text Size, Arabic Font, Accent Color, Sky Colors | iCloud ব্যাকআপ, লেখার আকার, আরবি ফন্ট, অ্যাকসেন্ট রং, আকাশের রং |
| Language (Settings row) | ভাষা |
| Ibn Kathir; the hadith books | ইবনে কাসীর; বুখারী, মুসলিম, নাসাঈ, আবু দাউদ, তিরমিযী, ইবনে মাজাহ, মুয়াত্তা মালিক, দারেমী, মুসনাদে আহমাদ, রিয়াদুস সালেহীন |
| Fajr, Dhuhr, Asr, Maghrib, Isha | ফজর, যোহর, আসর, মাগরিব, এশা |
| Suhoor, Iftar, Ramadan | সাহরি, ইফতার, রমজান |
| surah meanings (surah.meaning.2) | গাভী (Al-Baqarah) |
