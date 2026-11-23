# App Store Hindi Listing

The **Hindi** (`hi`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store
Connect, add the Hindi localization, then fill Name and Subtitle under App Information and the other four
fields on the version page. Screenshots can stay English: App Store Connect shows the primary language's
screenshots for a localization that has none of its own.
People whose device is set to Hindi see this listing instead of the English one. In the Hindi interface the
app keeps its Latin name, Al-Islam (on the Home Screen too), and its tabs are अज़ान, क़ुरआन, हदीस, इस्लाम and
सेटिंग्ज़; the listing uses the same words.

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
  file, not the store), after NFC normalization, the form the app's catalog and `labels.json` use. NFC never
  composes a nukta letter (U+0958 to U+095F are composition exclusions), so क़, ज़, फ़ are two code points
  each, and a conjunct counts its virama (्): नमाज़ के समय is 12, हिफ़्ज़ is 7. Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Hindi Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Hindi in Devanagari as Indian Muslims write it:** plain everyday Hindi (neither heavy Sanskrit nor heavy
  Persian) with the Islamic words Urdu uses, addressing the reader as "आप" with polite imperatives (पढ़ें,
  टैप करें, चुनें), every sentence ending in the purna viram । (never a Latin full stop after Hindi). Islamic
  terms as the app's Hindi glossary writes them (क़ुरआन, हदीस, नमाज़, अज़ान, क़िबला, ज़िक्र, दुआ, तजवीद, तफ़सीर,
  रमज़ान, सहरी, ख़त्म, हिफ़्ज़), never a Sanskrit substitute (not प्रार्थना for salah, not उपवास for sawm). The
  honorific is always spelled out, "(सल्लल्लाहु अलैहि वसल्लम)", after the name it follows (नबी मुहम्मद
  (सल्लल्लाहु अलैहि वसल्लम) की हदीस): App Store Connect rejects the one-glyph ligature (U+FDFA) as an invalid
  character.
- **Feature names are the labels the app shows** (the Hindi translation of `Resources/Localizable.xcstrings`;
  `hi/labels.json` binds 331 of them; see the glossary below). A label that is a noun stands bare and may take
  a postposition after it (नमाज़ ट्रैकर, चुनी हुई आयत के विजेट). A label that is an imperative ("AI से पूछें",
  "इस आयत से सुनें", "विषय के हिसाब से देखें", "लगातार दोहराएँ", "तरीक़ा सीखें") goes in "quotes", so it reads as
  a name and not as an instruction. Apple's own features take the Hindi loanwords Indian users read on their
  phones (सेटिंग्ज़, विजेट, कंट्रोल सेंटर, लाइव ऐक्टिविटी, लॉक स्क्रीन, शॉर्टकट).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma or a new sentence. A leading
  "- " bullet is fine; the English fields use the same. The hyphen inside a Hindi word (नव-मुस्लिम,
  मिलती-जुलती, आमने-सामने, उलूम-ए-हदीस) is a hyphen, not a dash.
- **Plain characters in every store field:** Devanagari letters with every nukta written as the base letter
  plus U+093C (never the precomposed U+0958 to U+095F), the purna viram (U+0964, never the double ॥), Western
  digits with a comma for thousands (50,000), and straight ASCII quotes (" "), never curly quotes. No
  Devanagari digits (० to ९), no ZWJ or ZWNJ (U+200D, U+200C, which some Hindi keyboards slip into a half
  letter), no direction marks. On 2026-10-29 App Store Connect refused characters in Al-Islam's Urdu fields
  without naming them, so these fields keep to the plainest characters of the script. No version numbers.
- **App names stay Latin:** Al-Islam, Al-Adhan, Al-Quran. Hindi writes a postposition as a word of its own,
  so it follows a Latin name after a space and needs no hyphen (Al-Islam का, Apple Watch पर, iCloud में,
  iMessage के लिए). Brand names stay Latin too: Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone,
  iPad, Mac, iMessage, iOS. So do the English editions' titles (Maarif Ul Quran, Tazkirul Quran): written in
  Devanagari they would read as the Hindi or Urdu editions Indian readers know, which the app does not have.
- **Search spellings go in the keyword field only.** The name, subtitle and description write the app's forms,
  with the nukta (क़ुरआन, अज़ान, नमाज़, क़िबला, तफ़सीर, रमज़ान). Most Indians type without the nukta, and Hindi
  writes the Quran most often as कुरान, so the keyword field adds those spellings (कुरान, अजान, नमाज, किबला,
  तफसीर, रमजान, इफ्तार) and the Latin words people type on an English keyboard (quran, namaz): each is a search
  term of its own.
- **The nukta and search:** whether Apple's search folds the nukta is not documented, so a nukta-less spelling
  counts as a term of its own. Where the nukta sits on the last letter (नमाज़), the nukta-less word is a
  prefix of the subtitle's word and search-as-you-type may already reach it; if App Analytics shows the
  keyword field's नमाज adding nothing, it is the first to swap. Hindi has no case endings fused to a word, so
  the Bangla listing's bare-word question does not arise.
- **Be honest about what is still English:** the in-depth articles of the Islam tab, AI search by meaning
  (English phrases only), the Quran and hadith translations (English, beside the Arabic; there is no Hindi
  translation, so the description says अंग्रेज़ी अनुवाद and the keyword field leaves out हिंदी, अनुवाद and
  तर्जुमा), and Siri, which has no Hindi (Apple's iOS feature availability page lists Siri for India in
  English only; checked 2026-11-20), so its phrases are said in English. The surah names stay Latin
  (Al-Baqarah) with their meaning in Hindi, and the hadith reference lookup reads Latin names only, so the
  description keeps "Bukhari 5" in Latin.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with the Urdu and Bangla listings: when a field changes for a feature, change it here
  too.

## 1. Name

The name keeps Al-Islam first, then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | क़ुरआन, हदीस, अज़ान
```

**30 / 30 characters.**

The app's three sections as bare words, each the label of its tab, the shape of the Urdu name (which lists
them with commas too). " और " before the last word would cost two characters the name does not have. The
subtitle is free for prayer times, the Qibla and tafsir, as in the Urdu and Bangla subtitles. The keyword
field adds कुरान, अजान and the Latin quran.

## 2. Subtitle

```
नमाज़ के समय, क़िबला और तफ़सीर
```

**30 / 30 characters.**

नमाज़ के समय is the app's label for Prayer Times and how Hindi names them; with the keyword field's नमाज it
also answers "नमाज का समय" typed without the nukta. क़िबला is the Qibla, and तफ़सीर the tafsir for every ayah.

## 3. Promotional Text

Leads with the Hindi interface. Update it with the next release like the English one.

```
नया: पूरा हिंदी इंटरफ़ेस, जिसमें सूरतों के लैटिन नामों के साथ उनका अर्थ हिंदी में है। क़ुरआन, हदीस और नमाज़ के समय, सब एक मुफ़्त ऐप में, बिना किसी विज्ञापन के।
```

**159 / 170 characters.**

## 4. Description

A Hindi rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Hindi headings on their own lines (Hindi has no capitals). Four lines say what is English: the Quran
line and the hadith line name an English translation (अंग्रेज़ी अनुवाद), the AI line says search by meaning
still works from English phrases, and the interface line says the Islam tab's articles are English. The Nine
books are named generically (नौ बड़ी किताबें) with each book's name as the app's Hindi writes it (बुख़ारी,
तिर्मिज़ी, मुसनद अहमद); the Six Books' label, सिहाह सित्ता, would not cover all nine. The forty-hadith
collections take the app's label, अरबईन के संग्रह.

```
Al-Islam इस्लाम पर अमल के लिए आपका पूरा साथी है, चाहे आप पैदाइशी मुसलमान हों, नव-मुस्लिम हों या इस्लाम को जानना चाहते हों। क़ुरआन, हदीस की बड़ी किताबें, तफ़सीर, नमाज़ के समय, नमाज़ ट्रैकर और डिवाइस पर ही चलने वाली AI खोज, सब एक ऐप में: पूरी तरह मुफ़्त, बिना विज्ञापन के, और आपकी निजता सुरक्षित।

पूरा क़ुरआन
- सूरह, पारा या पृष्ठ के हिसाब से पढ़ें, सूची के रूप में या मुसहफ़ की तरह पृष्ठों के रूप में, और लैंडस्केप में आमने-सामने दो पृष्ठ।
- अरबी, लिप्यंतरण और अंग्रेज़ी अनुवाद साथ-साथ, रंगीन तजवीद के साथ, जिसके रंग आप ख़ुद चुन सकते हैं।
- हर आयत की तफ़सीर: अंग्रेज़ी में इब्ने कसीर, Maarif Ul Quran और Tazkirul Quran, और अरबी में इब्ने कसीर, तबरी और सअदी, ऑफ़लाइन भी।
- शब्द का अध्ययन: किसी भी शब्द पर दो बार टैप करके उसका अर्थ, व्याकरण, मूल और क़ुरआन में उसके आने की हर जगह देखें।
- 60 से ज़्यादा क़ारी, ऑफ़लाइन डाउनलोड, "लगातार दोहराएँ", और "इस आयत से सुनें", जो पृष्ठ, सूरह, पारे या पूरे क़ुरआन के आख़िर तक चलता है।
- हफ़्स और दस क़िराअतों की 19 और रिवायतें, जिनकी क़िराअत एक्सप्लोरर में साथ-साथ तुलना होती है।
- मिलती-जुलती आयतें, "विषय के हिसाब से देखें", आज का शब्द, बुकमार्क और नोट्स।

हिफ़्ज़ और दोहराई
- क़ुरआन प्लानर: अपने ख़त्म-ए-क़ुरआन की तारीख़ तय करें, और याद की हुई सूरतों के लिए दोहराई का प्लान जोड़ें।
- टेस्ट मोड टेक्स्ट को तब तक छिपाए रखता है जब तक आप टैप न करें, ताकि आप ज़बानी पढ़कर हर आयत जाँच सकें।

हदीस की बड़ी किताबें
- नौ बड़ी किताबें (बुख़ारी, मुस्लिम, नसाई, अबू दाऊद, तिर्मिज़ी, इब्ने माजा, मुवत्ता मालिक, दारिमी, मुसनद अहमद), अरबईन के संग्रह और रियाज़ुस्सालिहीन जैसी मशहूर किताबें।
- अरबी टेक्स्ट और अंग्रेज़ी अनुवाद, रावियों की सनद और हर रावी का पेज, आज की हदीस, बुकमार्क, और "Bukhari 5" जैसे हवालों से खोज।
- एक किताब में या 50,000 से ज़्यादा सभी हदीसों में खोजें, सब ऑफ़लाइन।

डिवाइस पर ही AI
- शब्दों से नहीं, अर्थ से क़ुरआन और हदीस में खोजें: "patience in hardship" लिखने पर सब्र की आयतें मिलती हैं। अर्थ से खोज अभी सिर्फ़ अंग्रेज़ी वाक्यांशों पर काम करती है।
- Apple Intelligence चालू हो तो "AI से पूछें" उन्हीं आयतों और हदीसों से जवाब देता है जिनका वह हवाला देता है, कभी फ़तवा नहीं देता।

नमाज़ के समय, क़िबला और ट्रैकर
- आपके डिवाइस पर ही निकाले गए सही नमाज़ के समय, आपके इलाक़े के लिए सुझाए गए तरीक़े से।
- नमाज़ के समय के ऊपर जीता-जागता आसमान: अपने रास्ते पर चलता सूरज, रात के तारे, अपनी असली कला में 3D चाँद, और चाहें तो मौसम भी।
- क़िबला कम्पास, अज़ान की आवाज़ें, पूर्व-सूचना, सफ़र मोड और बार-बार याद दिलाने का मोड, जो नमाज़ पढ़ने तक याद दिलाता रहता है।
- नमाज़ ट्रैकर: एक टैप में हर नमाज़ पर निशान लगाएँ, साथ में लगातार दिन, मुकम्मल दिन और रंगीन कैलेंडर।
- नमाज़ के समय और चुनी हुई आयत के विजेट, कंट्रोल सेंटर के कंट्रोल, रमज़ान की लाइव ऐक्टिविटी और Apple Watch।

रोज़ाना इबादत और सीखना
- आज: दिन की आयत, हदीस, दुआ और अल्लाह का नाम, आज की नसीहत का कार्ड और सुन्नत रिमाइंडर।
- ज़िक्र और अज़कार, हिस्नुल मुस्लिम, हवालों और ऑडियो के साथ दुआओं के संग्रह, तस्बीह काउंटर और इस्लामी डायरी।
- अल्लाह के 99 नाम विस्तार से, क़ुरआन के मोजिज़े, इस्लाम का सबूत और उलूम-ए-हदीस।
- 21 स्तरों वाले पढ़ने के टेस्ट से अरबी वर्णमाला सीखें, और 58 सबक़ों के तजवीद कोर्स और तजवीद टेस्ट से तजवीद।
- "तरीक़ा सीखें" गाइड, इस्लाम और ईमान के अरकान, ज़कात और विरासत कैलकुलेटर, हिजरी कैलेंडर, मस्जिद की खोज और हलाल खाने की खोज।

आपके अंदाज़ में
- इंटरफ़ेस हिंदी, अंग्रेज़ी, अरबी और उर्दू समेत 15 भाषाओं में: iOS सेटिंग्ज़ में इस ऐप के लिए भाषा चुनें। इस्लाम टैब के विस्तृत लेख अभी अंग्रेज़ी में हैं।
- सरल मोड सिर्फ़ ज़रूरी चीज़ें सामने रखता है। जब चाहें, पूरे मोड पर जाएँ।
- अपनी पसंद के नाम से प्रोफ़ाइल बनाकर अपने iCloud में बैकअप करें, और किसी भी डिवाइस पर रीस्टोर करें।
- टेक्स्ट का आकार, अरबी फ़ॉन्ट, एक्सेंट और आसमान के रंग, और सेटिंग्ज़ के हर पेज पर खोज।
- iPhone, iPad, Mac और Apple Watch, साथ में iMessage के लिए इस्लामी स्टिकर।

मुफ़्त, बिना विज्ञापन, निजता सुरक्षित
Al-Islam पूरी तरह मुफ़्त है। न कोई विज्ञापन, न अकाउंट, न सब्सक्रिप्शन, न ट्रैकिंग: आप जो कुछ करते हैं, उसमें से कुछ भी जमा या शेयर नहीं किया जाता।

चाहे आप नमाज़ के समय ढूँढ रहे हों, क़ुरआन, नबी मुहम्मद (सल्लल्लाहु अलैहि वसल्लम) की हदीस या इस्लाम की गहरी समझ, आज ही Al-Islam डाउनलोड करें।
```

**3,981 / 4,000 characters.**

## 5. What's New

The release that adds the Hindi interface; all twelve new languages ship in one release. Only the interface
notes are here so far. The Urdu text's right-to-left and digit lines have no Hindi counterpart and are left
out; in their place are the Latin surah names with their Hindi meanings, the prayer names as the Hindi
catalog writes them (फ़ज्र, ज़ुहर, अस्र, मग़रिब, इशा), and a line saying the translations are English. The
language line names the other eleven new languages, then all fifteen interface languages.

```
Al-Islam का इंटरफ़ेस अब हिंदी में: अज़ान, क़ुरआन और हदीस से लेकर इस्लाम और सेटिंग्ज़ तक।

हिंदी इंटरफ़ेस:
- सभी स्क्रीन, मेनू, सेटिंग्ज़, सूचनाएँ और विजेट हिंदी में, iPhone, iPad, Mac और Apple Watch पर।
- सूरतों के नाम लैटिन अक्षरों में ही रहते हैं, जैसे Al-Baqarah, और साथ में उनका अर्थ हिंदी में (गाय)।
- नमाज़ों के नाम हिंदी में: फ़ज्र, ज़ुहर, अस्र, मग़रिब और इशा।
- नमाज़ की सूचनाएँ हिंदी में आती हैं।
- 58 सबक़ों का पूरा तजवीद कोर्स हिंदी में।
- क़ुरआन और हदीस के अनुवाद अभी अंग्रेज़ी में हैं, अरबी टेक्स्ट के साथ।

नई भाषाएँ:
- Al-Islam अब इंडोनेशियाई, मलय, तुर्की, फ़्रेंच, बांग्ला, रूसी, जर्मन, स्पेनिश, मलयालम, तमिल और डच में भी उपलब्ध है। कुल 15 भाषाएँ: अंग्रेज़ी, अरबी, उर्दू, इंडोनेशियाई, मलय, तुर्की, फ़्रेंच, बांग्ला, रूसी, हिंदी, जर्मन, स्पेनिश, मलयालम, तमिल और डच।

भाषा चुनना:
- iOS सेटिंग्ज़ में आप इस ऐप के लिए जो भाषा चुनते हैं, ऐप वही भाषा अपनाता है, और ऐप की सेटिंग्ज़ में "भाषा" वाली पंक्ति आपको वहीं ले जाती है।
- भाषा बदलने पर आपकी सूचनाएँ नई भाषा में दोबारा शेड्यूल हो जाती हैं।
- Siri हिंदी में नहीं है, इसलिए Siri से अंग्रेज़ी में बात करें।
- इस्लाम टैब के विस्तृत लेख और अर्थ से खोज अभी अंग्रेज़ी में हैं।
```

**1,134 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (क़ुरआन:, अज़ान:, हदीस:, इस्लामी टूल्स:, सेटिंग्ज़:, बग फ़िक्स और सुधार:). Keep the Hindi interface first,
and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al-Islam, क़ुरआन, हदीस, अज़ान, नमाज़,
के, समय, क़िबला, और, तफ़सीर); as in the Urdu and Bangla fields, another spelling of the same word (कुरान beside
क़ुरआन, अजान beside अज़ान, किबला beside क़िबला, तफसीर beside तफ़सीर, the Latin quran and namaz) is a search
term of its own (see Guidelines).

```
quran,namaz,नमाज,कुरान,शरीफ,अजान,किबला,दुआ,रमजान,सहरी,इफ्तार,तस्बीह,तिलावत,तजवीद,ट्रैकर,तफसीर,पारा
```

**98 / 100 characters.**

Why these terms:
- **quran, namaz:** the two words Indian Muslims most often type on an English keyboard ("quran", "namaz
  time"); English's `Keywords.md` carries both too.
- **नमाज, कुरान, अजान, किबला, तफसीर:** the name's and subtitle's words as most people type them, without the
  nukta, and कुरान, the Quran's most common Hindi spelling.
- **शरीफ:** "कुरान शरीफ", the way many Indian Muslims name the Quran in a search.
- **दुआ, तस्बीह:** the dua collections and Hisn al-Muslim, and the तस्बीह काउंटर.
- **रमजान, सहरी, इफ्तार:** the Ramadan Live Activity, which counts down to the end of suhoor and to iftar:
  "सहरी इफ्तार का समय" is searched every Ramadan. सहरी is the app's spelling and a common one; रमजान and
  इफ्तार are the nukta-less forms people type.
- **तिलावत:** over 60 reciters ("कुरान तिलावत").
- **तजवीद:** the colored tajweed, the तजवीद कोर्स and the तजवीद टेस्ट.
- **ट्रैकर:** with the bare नमाज, the app's label नमाज़ ट्रैकर, the English field's `tracker`.
- **पारा:** a juz as Indian Muslims name it ("30 पारे", "पारा 1").

Left out for room, to rotate in from App Analytics: मजीद and पाक ("क़ुरआन मजीद", "क़ुरआन पाक"), जिक्र, सूरह,
मस्जिद, हिजरी, रोजा, टाइम ("नमाज टाइम"), हिफ्ज, मुस्लिम, dua, and बुखारी (a large search, but most of it
wants a Hindi translation of Sahih al-Bukhari, which the app does not have). Deliberately excluded: हिंदी,
अनुवाद and तर्जुमा ("कुरान हिंदी में", "कुरान शरीफ हिंदी अनुवाद" want a Hindi translation, and the app's
translations are English); इब्ने and कसीर (for "तफसीर इब्ने कसीर"), since a Hindi search for it wants a
Hindi edition and the app has it in English and Arabic only; and नूरानी, the name of a published teaching
method the app does not follow.

## Glossary

The Hindi the app shows for the features the listing names (the Hindi translation of
`Resources/Localizable.xcstrings`). Each label was checked on 2026-11-20 against `hi/labels.json` and the
finished interface batches (`hi/out/*.json`). A label marked † was still in a batch being translated (013 to
019): it takes the Hindi glossary's term where the glossary fixes one (Apple's words, लगातार दिन, ख़त्म,
लिप्यंतरण, भाषा) and otherwise the wording the finished strings use around it (अर्थ से for "by meaning",
रिमाइंडर as in रोज़ाना रिमाइंडर); check each † against the merged catalog before submitting.

| English | Hindi |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, अज़ान, क़ुरआन, हदीस, इस्लाम, सेटिंग्ज़ |
| Prayer Times, Qibla Compass, Prenotification, Adhan Sound | नमाज़ के समय, क़िबला कम्पास, पूर्व-सूचना, अज़ान की आवाज़ |
| Simple Mode / Full | सरल मोड / पूरा मोड † |
| Prayer Tracker, Streak, Perfect Days | नमाज़ ट्रैकर, लगातार दिन †, मुकम्मल दिन |
| Test Mode | टेस्ट मोड |
| Quran Planner, Revision, Khatm | क़ुरआन प्लानर, दोहराई, ख़त्म-ए-क़ुरआन |
| Read as List, Read as Pages | सूची के रूप में पढ़ें, पृष्ठों के रूप में पढ़ें |
| Transliteration | लिप्यंतरण † |
| Word Study, Root, Grammar | शब्द का अध्ययन, मूल, व्याकरण |
| Qiraat Explorer, the Ten Qiraat, riwayat | क़िराअत एक्सप्लोरर, दस क़िराअतें, रिवायतें |
| Traveling Mode | सफ़र मोड |
| Nagging Mode | बार-बार याद दिलाने का मोड |
| Repeat Forever, Play From Ayah | लगातार दोहराएँ, इस आयत से सुनें |
| Similar Ayahs, Browse by Theme, Word of the Day | मिलती-जुलती आयतें, विषय के हिसाब से देखें, आज का शब्द |
| Bookmarks, Notes | बुकमार्क, नोट्स † |
| Chain of Narrators, a narrator's page | रावियों की सनद, रावी का पेज |
| The Forty Collections, Hadith of the Day | अरबईन के संग्रह, आज की हदीस |
| Ask AI, Search by meaning | AI से पूछें, अर्थ से खोज † |
| Chosen Ayah (widget), Control Center, Live Activity | चुनी हुई आयत, कंट्रोल सेंटर †, लाइव ऐक्टिविटी † |
| Today, Name of Allah, Reminder of the Day | आज, अल्लाह का नाम, आज की नसीहत |
| Sunnah Reminders, Daily Reminder | सुन्नत रिमाइंडर †, रोज़ाना रिमाइंडर |
| Dhikr & Remembrances, Hisn al-Muslim, Tasbih Counter, Islamic Journal | ज़िक्र और अज़कार, हिस्नुल मुस्लिम, तस्बीह काउंटर, इस्लामी डायरी |
| 99 Names of Allah | अल्लाह के 99 नाम |
| Miracles of the Quran, Proving Islam, The Sciences of Hadith | क़ुरआन के मोजिज़े, इस्लाम का सबूत, उलूम-ए-हदीस |
| Arabic Alphabet, Reading Test | अरबी वर्णमाला, पढ़ने का टेस्ट |
| Tajweed Course, Tajweed Test | तजवीद कोर्स, तजवीद टेस्ट † |
| How-To Guides, Pillars & Beliefs | तरीक़ा सीखें, अरकान और अक़ीदे |
| Zakah Calculator, Inheritance Calculator, Hijri Calendar | ज़कात कैलकुलेटर, विरासत कैलकुलेटर, हिजरी कैलेंडर |
| Masjid Locator, Halal Food Locator | मस्जिद की खोज, हलाल खाने की खोज |
| iCloud Backup, Text Size, Arabic Font, Accent Color, Sky Colors | iCloud बैकअप, टेक्स्ट का आकार, अरबी फ़ॉन्ट, एक्सेंट रंग †, आसमान के रंग |
| Language (Settings row) | भाषा † |
| Ibn Kathir, al-Tabari, as-Sa'di | इब्ने कसीर, तबरी †, सअदी † |
| the hadith books | बुख़ारी, मुस्लिम, नसाई, अबू दाऊद, तिर्मिज़ी, इब्ने माजा, मुवत्ता मालिक, दारिमी (सुनन दारिमी), मुसनद अहमद, रियाज़ुस्सालिहीन |
| Fajr, Dhuhr, Asr, Maghrib, Isha | फ़ज्र, ज़ुहर, अस्र, मग़रिब, इशा |
| Suhoor, Iftar, Ramadan | सहरी, इफ़्तार, रमज़ान |
| surah meanings (surah.meaning.2) | गाय (Al-Baqarah) |
