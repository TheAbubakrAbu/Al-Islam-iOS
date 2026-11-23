# App Store Tamil Listing

The **Tamil** (`ta`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store
Connect, add the Tamil localization, then fill Name and Subtitle under App Information and the other four
fields on the version page. Screenshots can stay English: App Store Connect shows the primary language's
screenshots for a localization that has none of its own.
People whose device is set to Tamil see this listing instead of the English one. In the Tamil interface the
app keeps its Latin name, Al-Islam (on the Home Screen too), and its tabs are பாங்கு, குர்ஆன், ஹதீஸ், இஸ்லாம்
and அமைப்புகள்; the listing uses the same words.

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
  file, not the store), after NFC normalization, the form the app's catalog and `labels.json` use. In NFC the
  two-part vowel signs ொ, ோ and ௌ are one code point each (NFC composes ெ plus ா into ொ), while every pulli (்)
  and the aytham (ஃ) counts as a character of its own: தொழுகை நேரம் is 12, தஃப்ஸீர் is 8. Re-check after any
  edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Tamil Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Tamil as Tamil Muslims and Apple's Tamil write it:** standard written Tamil, never colloquial, with the
  Tamil Nadu form where Tamil Nadu and Sri Lanka differ (ரமளான், not ரமழான்). The reader is "நீங்கள்", and an
  instruction takes Apple's polite -வும் (படிக்கவும், தட்டவும், தேர்வுசெய்யவும், பதிவிறக்கவும்); the app is
  செயலி. Every sentence ends in the Latin full stop, the stop Tamil uses. Islamic terms as the app's Tamil
  glossary writes them (குர்ஆன், ஹதீஸ், தொழுகை, பாங்கு, கிப்லா, துஆ, திக்ர், தஜ்வீத், தஃப்ஸீர், சூரா, வசனம்,
  ஜுஸ்உ, ரமளான், ஸஹர், இஃப்தார், கத்ம், மனனம், பள்ளிவாசல்), never another religion's word (no ஜெபம் or பூஜை
  for salah, no கடவுள் for Allah, no தீர்க்கதரிசி for a prophet). The honorific is always spelled out,
  "(ஸல்லல்லாஹு அலைஹி வஸல்லம்)", after the name it follows and before அவர்களின், the honorific plural Tamil
  Muslims give the Prophet (நபி முஹம்மது (ஸல்லல்லாஹு அலைஹி வஸல்லம்) அவர்களின் ஹதீஸ்கள்); never the
  abbreviation (ஸல்), and never the one-glyph ligature (U+FDFA), which App Store Connect rejects as an invalid
  character.
- **Feature names are the labels the app shows** (the Tamil translation of `Resources/Localizable.xcstrings`;
  `ta/labels.json` binds 331 of them; see the glossary below). A label that is a noun stands bare and may take
  a case ending (தொழுகை டிராக்கர், தேர்ந்தெடுத்த வசனத்துக்கும்). A label that is an imperative ("AIஇடம் கேள்",
  "இந்த வசனத்திலிருந்து கேள்", "கருப்பொருள் வாரியாக உலாவு", "நிறுத்தாமல் மீண்டும் கேள்") goes in "quotes", so
  it reads as a name and not as an instruction, and so does "கிராஅத் ஆய்வு", which the app's own strings quote
  and follow with பகுதி ("கிராஅத் ஆய்வு" பகுதியில்), since bare it reads as "a study of the qiraat". Apple's own
  features take the words of Apple's Tamil iOS (அமைப்புகள், விட்ஜெட், கட்டுப்பாட்டு மையம், நேரலைச் செயல்பாடு,
  பூட்டுத் திரை, சுருக்கவழிகள், பேக்-அப்).
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma or a new sentence. A leading
  "- " bullet is fine; the English fields use the same. The hyphen inside a word (பேக்-அப், அஸ்-ஸஃதி) is a
  hyphen, not a dash.
- **Plain characters in every store field:** Tamil letters with the two-part vowel signs in their composed
  NFC form (U+0BCA to U+0BCC, never ெ or ே followed by ா or ௗ), the Latin full stop, Western digits with a comma
  for thousands (50,000), and straight ASCII quotes (" "), never the curly “ ” the app's own strings use. No
  Tamil digits (௦ to ௯) or number signs (௰, ௱, ௲), no ZWJ or ZWNJ (U+200D, U+200C, which some Tamil keyboards
  slip in after a pulli), no direction marks, and no ஸ்ரீ ligature. On 2026-10-29 App Store Connect refused
  characters in Al-Islam's Urdu fields without naming them, so these fields keep to the plainest characters of
  the script. No version numbers.
- **App names stay Latin:** Al-Islam, Al-Adhan, Al-Quran. Where Tamil needs a case ending, the app's name
  takes செயலி and the ending goes on that (Al-Islam செயலியின் இடைமுகம், Al-Islam செயலியைப் பதிவிறக்கவும்), as
  the app's own strings write it ("Al-Islam என்ற ஒரே செயலியில்"). Other brand names stay Latin and take the
  ending directly, as Apple's Tamil and the app's strings do (Apple Watchஇல், iCloudஇல், iMessageக்கான,
  Siriஇடம்): Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac, iMessage, iOS. So do the
  English editions' titles (Maarif Ul Quran, Tazkirul Quran): written in Tamil they would read as Tamil
  editions, which the app does not have.
- **Search spellings go in the keyword field only.** The name, subtitle and description write the app's forms
  (குர்ஆன், ரமளான், தஃப்ஸீர், இஃப்தார்). The keyword field adds the spellings Tamil speakers type (குரான், the
  common spelling outside Muslim print, and ரமலான், the one most Tamil Muslims type) and the Latin words they
  type on an English keyboard (quran, namaz): each is a search term of its own.
- **Case endings and plurals:** Tamil fuses both to the word (நேரங்கள், சூராக்களின்), and whether Apple's
  search folds them back to the stem is not documented. The subtitle therefore writes the bare தொழுகை நேரம்,
  the form people search, where the app's label is the plural தொழுகை நேரங்கள் (see Subtitle), and the keyword
  field treats every form as a term of its own.
- **Be honest about what is still English:** the in-depth articles of the Islam tab, AI search by meaning
  (English phrases only), the Quran and hadith translations (English, beside the Arabic; there is no Tamil
  translation, so the description says ஆங்கில மொழிபெயர்ப்பு and the keyword field leaves out தமிழ்,
  மொழிபெயர்ப்பு and அர்த்தம்), and Siri, which has no Tamil (as the Hindi listing records for Hindi), so its
  phrases are said in English. The surah names stay Latin (Al-Baqarah) with their meaning in Tamil, and the
  hadith reference lookup reads Latin names only, so the description keeps "Bukhari 5" in Latin.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with the Hindi and Bangla listings: when a field changes for a feature, change it here
  too.

## 1. Name

The name keeps Al-Islam first, then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | குர்ஆன், ஹதீஸ்
```

**25 / 30 characters.**

The app's sections as bare words, each the label of its tab, the shape of the Hindi and Bangla names. All
three tabs come to 33 characters in Tamil ("Al-Islam | குர்ஆன், ஹதீஸ், பாங்கு"), so the name keeps the Quran
and Hadith tabs and the Adhan tab's பாங்கு closes the subtitle. With மற்றும் ("Al-Islam | குர்ஆன் மற்றும் ஹதீஸ்")
the name would be 32 characters, so the pair takes a comma. The keyword field adds குரான் and the Latin quran.

## 2. Subtitle

```
தொழுகை நேரம், கிப்லா, பாங்கு
```

**28 / 30 characters.**

தொழுகை நேரம் is how Tamil names prayer times in a search ("தொழுகை நேரம்", "இன்றைய தொழுகை நேரம்"). The app's
label is the plural, தொழுகை நேரங்கள், but with கிப்லா and பாங்கு it makes 31 characters, one too many, and the
singular is the form people type. கிப்லா is the Qibla, and பாங்கு the Adhan tab and the call to prayer itself,
the word Tamil Muslims use for it. The tafsir, which the Hindi and Bangla subtitles carry, moves to the keyword
field (தஃப்ஸீர்).

## 3. Promotional Text

Leads with the Tamil interface. Update it with the next release like the English one.

```
புதியது: முழுமையான தமிழ் இடைமுகம்; சூராப் பெயர்கள் லத்தீனில், அவற்றின் பொருள் தமிழில். குர்ஆன், ஹதீஸ், தொழுகை நேரங்கள், அனைத்தும் ஒரே இலவசச் செயலியில், விளம்பரமின்றி.
```

**166 / 170 characters.**

## 4. Description

A Tamil rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Tamil headings on their own lines (Tamil has no capitals). Four lines say what is English: the Quran
line and the hadith line name an English translation (ஆங்கில மொழிபெயர்ப்பு), the AI line says search by
meaning still works from English phrases, and the interface line says the Islam tab's articles are English.
The Nine books are named generically (ஒன்பது நூல்கள்) with each book's name as the app's Tamil writes it
(புகாரி, திர்மிதி, முஸ்னத் அஹ்மத்); the Six Books' label, ஆறு நூல்கள், would not cover all nine. The
forty-hadith collections take the app's heading, நாற்பது ஹதீஸ் தொகுப்புகள்.

Tamil runs long in code points (every pulli counts), and a line-for-line rendering of the Hindi text came to
4,959 characters. To fit, the bullets are cut to the feature and what it does, list items take commas
without மற்றும், and two things are left out: the English opener's second clause (lifelong believer, new
convert, or exploring the faith) and the word "controls" after Control Center. Every feature line stays.
At 3,979 the field has no room to grow: a new feature means trimming a line, not appending one.

```
Al-Islam, இஸ்லாத்தைக் கடைப்பிடிக்க உங்கள் முழுமையான துணை. குர்ஆன், ஹதீஸ் நூல்கள், தஃப்ஸீர், தொழுகை நேரங்கள், தொழுகை டிராக்கர், சாதனத்திலேயே AI தேடல், அனைத்தும் ஒரே செயலியில்: இலவசம், விளம்பரமில்லை, தனியுரிமை காக்கப்படும்.

முழுமையான குர்ஆன்
- சூரா, ஜுஸ்உ, பக்கம் வாரியாக, பட்டியலாகவோ முஸ்ஹஃப் பக்கங்களாகவோ படிக்கவும்; கிடைமட்டத்தில் இரு பக்கங்கள்.
- அரபி, ஒலிபெயர்ப்பு, ஆங்கில மொழிபெயர்ப்பு அருகருகே, நீங்கள் தேர்வுசெய்யும் நிறங்களில் தஜ்வீதுடன்.
- எந்த வசனத்துக்கும் தஃப்ஸீர்: ஆங்கிலத்தில் இப்னு கஸீர், Maarif Ul Quran, Tazkirul Quran; அரபியில் இப்னு கஸீர், அத்-தபரி, அஸ்-ஸஃதி.
- சொல் பகுப்பாய்வு: எந்தச் சொல்லையும் இருமுறை தட்டினால் அதன் பொருள், இலக்கணம், வேர்ச்சொல், அது வரும் இடங்கள்.
- 60க்கும் மேற்பட்ட காரிகள், ஆஃப்லைன் பதிவிறக்கம், "நிறுத்தாமல் மீண்டும் கேள்", பக்கம், சூரா, ஜுஸ்உ அல்லது குர்ஆனின் இறுதி வரை "இந்த வசனத்திலிருந்து கேள்".
- ஹஃப்ஸும் பத்துக் கிராஅத்களின் மேலும் 19 ரிவாயத்களும், "கிராஅத் ஆய்வு" பகுதியில் அருகருகே.
- ஒத்த வசனங்கள், "கருப்பொருள் வாரியாக உலாவு", இன்றைய சொல், புக்மார்க்குகள், குறிப்புகள்.

மனனமும் மீள்பார்வையும்
- குர்ஆன் திட்டமிடல்: கத்முக்கு ஒரு நிறைவுத் தேதி, மனனம் செய்த சூராக்களுக்கு மீள்பார்வைத் திட்டம்.
- சோதனைப் பயன்முறை, நீங்கள் தட்டும் வரை உரையை மறைக்கும்; நினைவிலிருந்து ஓதிச் சரிபார்க்கலாம்.

முக்கிய ஹதீஸ் நூல்கள்
- ஒன்பது நூல்கள் (புகாரி, முஸ்லிம், நஸாயீ, அபூதாவூத், திர்மிதி, இப்னு மாஜா, முவத்தா மாலிக், தாரிமி, முஸ்னத் அஹ்மத்), நாற்பது ஹதீஸ் தொகுப்புகள், ரியாளுஸ் ஸாலிஹீன்.
- அரபியுடன் ஆங்கில மொழிபெயர்ப்பு, அறிவிப்பாளர் தொடர்களும் அவர்களின் பக்கங்களும், இன்றைய ஹதீஸ், "Bukhari 5" போன்ற மேற்கோள் தேடல்.
- ஒரு நூலில் அல்லது 50,000க்கும் மேற்பட்ட ஹதீஸ்களில் தேடல், ஆஃப்லைனிலும்.

சாதனத்திலேயே AI
- பொருளின்படி குர்ஆனிலும் ஹதீஸிலும் தேடவும்: "patience in hardship" பொறுமை பற்றிய வசனங்களைத் தரும். இது தற்போது ஆங்கிலச் சொற்றொடர்களில் மட்டுமே.
- Apple Intelligence இருந்தால், "AIஇடம் கேள்" தான் மேற்கோள் காட்டும் வசனங்கள், ஹதீஸ்களிலிருந்தே பதில் தரும், ஃபத்வா ஒருபோதும் தராது.

தொழுகை நேரங்கள், கிப்லா, டிராக்கர்
- சாதனத்திலேயே கணக்கிடப்படும் துல்லியமான தொழுகை நேரங்கள், உங்கள் பகுதிக்கேற்ற முறையில்.
- தொழுகை நேரங்களுக்கு மேல் உயிருள்ள வானம்: நகரும் சூரியன், இரவு நட்சத்திரங்கள், உண்மையான கலையில் 3D நிலவு, விருப்ப வானிலை.
- கிப்லா திசைகாட்டி, பாங்கு ஒலிகள், முன்னறிவிப்புகள், பயணப் பயன்முறை, தொழும் வரை நினைவூட்டும் தொடர் நினைவூட்டல் பயன்முறை.
- தொழுகை டிராக்கர்: ஒரே தட்டலில் ஒவ்வொரு தொழுகையையும் குறியிடவும்; தொடர் நாட்கள், முழுமையான நாட்கள், வண்ண நாட்காட்டி.
- தொழுகை நேரங்களுக்கும் தேர்ந்தெடுத்த வசனத்துக்கும் விட்ஜெட்கள், கட்டுப்பாட்டு மையம், ரமளான் நேரலைச் செயல்பாடு, Apple Watch.

தினசரி வணக்கமும் கல்வியும்
- இன்று: அன்றைய வசனம், ஹதீஸ், துஆ, அல்லாஹ்வின் திருநாமம், இன்றைய நினைவூட்டல், சுன்னத் நினைவூட்டல்கள்.
- திக்ர் & அத்கார், ஹிஸ்னுல் முஸ்லிம், ஆதாரமும் ஒலியும் கொண்ட துஆ தொகுப்புகள், தஸ்பீஹ் கவுண்டர், இஸ்லாமிய நாட்குறிப்பு.
- அல்லாஹ்வின் 99 திருநாமங்கள் விரிவாக, குர்ஆனின் அற்புதங்கள், இஸ்லாத்தின் சான்றுகள், ஹதீஸ் கலைகள்.
- அரபி எழுத்துகளுக்கு 21 நிலை வாசிப்புத் தேர்வு; 58 பாடங்களின் தஜ்வீத் பாடநெறியும் தஜ்வீத் தேர்வும்.
- செய்முறை வழிகாட்டிகள், தூண்கள் & நம்பிக்கைகள், ஜகாத், வாரிசுரிமைக் கணிப்பான்கள், ஹிஜ்ரி நாட்காட்டி, பள்ளிவாசல், ஹலால் உணவுத் தேடல்.

உங்கள் விருப்பப்படி
- தமிழ், ஆங்கிலம், அரபி உட்பட 15 மொழிகள்: iOS அமைப்புகளில் இந்தச் செயலியின் மொழியைத் தேர்வுசெய்யவும். இஸ்லாம் தாவலின் விரிவான கட்டுரைகள் தற்போது ஆங்கிலத்தில்.
- எளிய பயன்முறை அவசியமானவற்றை மட்டும் காட்டும்; எப்போது வேண்டுமானாலும் முழுமையான பயன்முறைக்கு மாறலாம்.
- பெயரிட்ட சுயவிவரங்களை உங்கள் iCloudஇல் பேக்-அப் செய்து, எந்தச் சாதனத்திலும் மீட்டெடுக்கவும்.
- உரை அளவு, அரபி எழுத்துரு, அக்சென்ட், வான நிறங்கள், ஒவ்வொரு அமைப்புப் பக்கத்திலும் தேடல்.
- iPhone, iPad, Mac, Apple Watch, iMessageக்கு இஸ்லாமிய ஸ்டிக்கர்கள்.

இலவசம், விளம்பரமில்லை, தனியுரிமை
Al-Islam முற்றிலும் இலவசம். விளம்பரம், கணக்கு, சந்தா, கண்காணிப்பு எதுவுமில்லை: நீங்கள் செய்வது எதுவும் சேகரிக்கப்படுவதோ பகிரப்படுவதோ இல்லை.

தொழுகை நேரங்கள், குர்ஆன், நபி முஹம்மது (ஸல்லல்லாஹு அலைஹி வஸல்லம்) அவர்களின் ஹதீஸ்கள், எதைத் தேடினாலும் இன்றே Al-Islam செயலியைப் பதிவிறக்கவும்.
```

**3,979 / 4,000 characters.**

## 5. What's New

The release that adds the Tamil interface; all twelve new languages ship in one release. Only the interface
notes are here so far. The Urdu text's right-to-left and digit lines have no Tamil counterpart and are left
out; in their place are the Latin surah names with their Tamil meanings, the prayer names as the Tamil catalog
writes them (ஃபஜ்ர், லுஹர், அஸர், மஃரிப், இஷா), and a line saying the translations are English. The language
line names the other eleven new languages briefly and gives the total, fifteen, with the three the app had
before.

```
Al-Islam செயலியின் இடைமுகம் இப்போது தமிழில்: பாங்கு, குர்ஆன், ஹதீஸ் முதல் இஸ்லாம் மற்றும் அமைப்புகள் வரை.

தமிழ் இடைமுகம்:
- அனைத்துத் திரைகள், மெனுக்கள், அமைப்புகள், அறிவிப்புகள் மற்றும் விட்ஜெட்கள் தமிழில், iPhone, iPad, Mac மற்றும் Apple Watchஇல்.
- சூராக்களின் பெயர்கள் லத்தீன் எழுத்துகளிலேயே இருக்கும் (Al-Baqarah போல), அருகில் அவற்றின் தமிழ்ப் பொருளுடன் (பசு மாடு).
- தொழுகைகளின் பெயர்கள் தமிழில்: ஃபஜ்ர், லுஹர், அஸர், மஃரிப் மற்றும் இஷா.
- தொழுகை அறிவிப்புகள் தமிழில் வரும்.
- 58 பாடங்கள் கொண்ட முழுத் தஜ்வீத் பாடநெறியும் தமிழில்.
- குர்ஆன் மற்றும் ஹதீஸ் மொழிபெயர்ப்புகள் தற்போது ஆங்கிலத்தில், அரபி உரையுடன்.

புதிய மொழிகள்:
- தமிழுடன் மேலும் 11 மொழிகள் இந்த வெளியீட்டில் வருகின்றன: இந்தோனேஷியன், மலாய், துருக்கிஷ், பிரெஞ்சு, வங்காளம், ரஷ்யன், இந்தி, ஜெர்மன், ஸ்பானிஷ், மலையாளம் மற்றும் டச்சு. ஆங்கிலம், அரபி, உருது உட்பட மொத்தம் 15 மொழிகள்.

மொழியைத் தேர்வுசெய்தல்:
- iOS அமைப்புகளில் இந்தச் செயலிக்கு நீங்கள் தேர்வுசெய்யும் மொழியையே செயலி பின்பற்றும்; செயலியின் அமைப்புகளில் உள்ள "மொழி" வரிசை உங்களை அங்கே அழைத்துச் செல்லும்.
- மொழியை மாற்றினால், உங்கள் அறிவிப்புகள் புதிய மொழியில் மீண்டும் திட்டமிடப்படும்.
- Siri தமிழில் இல்லை, எனவே Siriஇடம் ஆங்கிலத்தில் பேசவும்.
- இஸ்லாம் தாவலின் விரிவான கட்டுரைகளும் பொருளின்படி தேடலும் தற்போது ஆங்கிலத்தில் உள்ளன.
```

**1,261 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (குர்ஆன்:, பாங்கு:, ஹதீஸ்:, இஸ்லாமியக் கருவிகள்:, அமைப்புகள்:, பிழைத் திருத்தங்களும் மேம்பாடுகளும்:). Keep
the Tamil interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al-Islam, குர்ஆன், ஹதீஸ், தொழுகை,
நேரம், கிப்லா, பாங்கு); as in the Hindi and Bangla fields, another spelling of the same word (குரான் beside
குர்ஆன், the Latin quran and namaz) is a search term of its own (see Guidelines).

```
quran,namaz,குரான்,தஃப்ஸீர்,துஆ,திக்ர்,தஸ்பீஹ்,ரமலான்,நோன்பு,ஸஹர்,இஃப்தார்,தஜ்வீத்,கிராஅத்,சூரா,திசை
```

**100 / 100 characters.**

Why these terms:
- **quran, namaz:** the two words Tamil Muslims most often type on an English keyboard ("quran", "namaz
  time"), the Hindi and Bangla fields' choice too; English's `Keywords.md` carries both.
- **குரான்:** the Quran as most Tamil writing outside Muslim print spells it, and as many people type it.
- **தஃப்ஸீர்:** the tafsir for every ayah, which the Hindi and Bangla subtitles carry and the Tamil subtitle
  had no room for.
- **துஆ, திக்ர், தஸ்பீஹ்:** the dua collections and Hisn al-Muslim, the திக்ர் & அத்கார், and the தஸ்பீஹ்
  கவுண்டர்.
- **ரமலான், நோன்பு, ஸஹர், இஃப்தார்:** the Ramadan Live Activity, which counts down to the end of suhoor and to
  iftar. With the subtitle's நேரம் they make "ஸஹர் நேரம்", "இஃப்தார் நேரம்" and "நோன்பு நேரம்", searched every
  Ramadan. ரமலான் is the spelling most Tamil Muslims type for the app's ரமளான்; ஸஹர் and இஃப்தார் are the
  app's own words and the common ones.
- **தஜ்வீத்:** the colored tajweed, the தஜ்வீத் பாடநெறி and the தஜ்வீத் தேர்வு.
- **கிராஅத்:** the word Tamil Muslims use for a recitation of the Quran ("அழகிய கிராஅத்"), for the over 60
  reciters, and the app's "கிராஅத் ஆய்வு".
- **சூரா:** a surah looked up by name ("சூரா யாஸீன்").
- **திசை:** with the subtitle's கிப்லா, "கிப்லா திசை", the usual search for the Qibla direction; the app's
  label is கிப்லா திசைகாட்டி.

Left out for room, to rotate in from App Analytics: ரமளான் and ரம்ஜான் (the app's spelling, and the everyday
one outside Muslim print), நேரங்கள், திருக்குர்ஆன் (the formal name, worth testing), அதான், நமாஸ், ஜுஸ்உ,
வசனம், பள்ளிவாசல், ஹிஜ்ரி, டிராக்கர், dua. Deliberately excluded: தமிழ், மொழிபெயர்ப்பு and அர்த்தம் ("குர்ஆன்
தமிழ்", "குர்ஆன் தமிழ் மொழிபெயர்ப்பு" want a Tamil translation, and the app's translations are English);
இப்னு and கஸீர் (for "தஃப்ஸீர் இப்னு கஸீர்"), since a Tamil search for it wants a Tamil edition and the app has
it in English and Arabic only; புகாரி, a large search, but most of it wants a Tamil translation of Sahih
al-Bukhari, which the app does not have; and நூரானி, the name of a published teaching method the app does not
follow.

## Glossary

The Tamil the app shows for the features the listing names (the Tamil translation of
`Resources/Localizable.xcstrings`). Each label was checked on 2026-11-21 against `ta/labels.json` and the
finished interface batches (`ta/out/*.json`, all nineteen); every one matches. Control Center and Live
Activity have no key of their own: they take the Tamil glossary's Apple words, which the finished strings
use too ("கட்டுப்பாட்டு மையத்திலிருந்து தொடரவும்"). A label the listing changes to fit a sentence says so
in its row. The language names are the everyday Tamil ones; Arabic is the app's அரபி.

| English | Tamil |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam (Al-Islam செயலி with a case ending), பாங்கு, குர்ஆன், ஹதீஸ், இஸ்லாம், அமைப்புகள் |
| Prayer Times, Qibla Compass, Prenotification, Adhan Sound | தொழுகை நேரங்கள், கிப்லா திசைகாட்டி, முன்னறிவிப்பு, பாங்கு ஒலி |
| Simple Mode / Full | எளிய பயன்முறை / முழுமையானது (the welcome picker's எளியது / முழுமையானது; the listing writes முழுமையான பயன்முறை) |
| Prayer Tracker, Streak, Perfect Days | தொழுகை டிராக்கர், தொடர் நாட்கள், முழுமையான நாட்கள் |
| Test Mode | சோதனைப் பயன்முறை |
| Quran Planner, Revision, Khatm | குர்ஆன் திட்டமிடல், மீள்பார்வை, கத்ம் (never கத்தம், the recitation for the dead) |
| Read as List, Read as Pages | பட்டியலாகப் படி, பக்கங்களாகப் படி |
| Transliteration | ஒலிபெயர்ப்பு |
| Word Study, Root, Grammar | சொல் பகுப்பாய்வு, வேர்ச்சொல், இலக்கணம் |
| Qiraat Explorer, the Ten Qiraat, riwayat | கிராஅத் ஆய்வு (quoted, with பகுதி), பத்துக் கிராஅத்கள், ரிவாயத்கள் |
| Traveling Mode | பயணப் பயன்முறை |
| Nagging Mode | தொடர் நினைவூட்டல் பயன்முறை |
| Repeat Forever, Play From Ayah | நிறுத்தாமல் மீண்டும் கேள், இந்த வசனத்திலிருந்து கேள் |
| Similar Ayahs, Browse by Theme, Word of the Day | ஒத்த வசனங்கள், கருப்பொருள் வாரியாக உலாவு, இன்றைய சொல் |
| Bookmarks, Notes | புக்மார்க்குகள், குறிப்புகள் |
| Chain of Narrators, a narrator's page | அறிவிப்பாளர் தொடர், அறிவிப்பாளரின் பக்கம் |
| The Forty Collections, Hadith of the Day | நாற்பது ஹதீஸ் தொகுப்புகள், இன்றைய ஹதீஸ் |
| Ask AI, Search by meaning | AIஇடம் கேள், பொருளின்படி தேடவும் (the listing writes the noun, பொருளின்படி தேடல்) |
| Chosen Ayah (widget), Control Center, Live Activity | தேர்ந்தெடுத்த வசனம், கட்டுப்பாட்டு மையம், நேரலைச் செயல்பாடு (the glossary's நேரலைச் செயல்பாடுகள், singular) |
| Today, Name of Allah, Reminder of the Day | இன்று, அல்லாஹ்வின் திருநாமம், இன்றைய நினைவூட்டல் |
| Sunnah Reminders, Daily Reminder | சுன்னத் நினைவூட்டல்கள், தினசரி நினைவூட்டல் |
| Dhikr & Remembrances, Hisn al-Muslim, Tasbih Counter, Islamic Journal | திக்ர் & அத்கார், ஹிஸ்னுல் முஸ்லிம், தஸ்பீஹ் கவுண்டர், இஸ்லாமிய நாட்குறிப்பு |
| Dua collections | துஆ தொகுப்புகள் |
| 99 Names of Allah | அல்லாஹ்வின் 99 திருநாமங்கள் |
| Miracles of the Quran, Proving Islam, The Sciences of Hadith | குர்ஆனின் அற்புதங்கள், இஸ்லாத்தின் சான்றுகள், ஹதீஸ் கலைகள் |
| Arabic Alphabet, Reading Test | அரபி எழுத்துகள், வாசிப்புத் தேர்வு |
| Tajweed Course, Tajweed Test | தஜ்வீத் பாடநெறி, தஜ்வீத் தேர்வு |
| How-To Guides, Pillars & Beliefs | செய்முறை வழிகாட்டிகள், தூண்கள் & நம்பிக்கைகள் |
| Zakah Calculator, Inheritance Calculator, Hijri Calendar | ஜகாத் கணிப்பான், வாரிசுரிமைக் கணிப்பான், ஹிஜ்ரி நாட்காட்டி |
| Masjid Locator, Halal Food Locator | பள்ளிவாசல் தேடல், ஹலால் உணவுத் தேடல் |
| iCloud Backup, a profile, Text Size, Arabic Font, Accent Color, Sky Colors | iCloud பேக்-அப், சுயவிவரம், உரை அளவு, அரபி எழுத்துரு, அக்சென்ட் நிறம், வான நிறங்கள் |
| Language (Settings row) | மொழி |
| Ibn Kathir, al-Tabari, as-Sa'di | இப்னு கஸீர், அத்-தபரி, அஸ்-ஸஃதி (from the tafsir editions' names, தஃப்ஸீர் அத்-தபரி (அரபி), தஃப்ஸீர் அஸ்-ஸஃதி (அரபி)) |
| the hadith books | புகாரி, முஸ்லிம், நஸாயீ, அபூதாவூத், திர்மிதி, இப்னு மாஜா, முவத்தா மாலிக், தாரிமி (ஸுனன் தாரிமி), முஸ்னத் அஹ்மத், ரியாளுஸ் ஸாலிஹீன் |
| Fajr, Dhuhr, Asr, Maghrib, Isha | ஃபஜ்ர், லுஹர், அஸர், மஃரிப், இஷா |
| Suhoor, Iftar, Ramadan | ஸஹர், இஃப்தார், ரமளான் |
| the interface languages | தமிழ், ஆங்கிலம், அரபி, உருது, இந்தோனேஷியன், மலாய், துருக்கிஷ், பிரெஞ்சு, வங்காளம், ரஷ்யன், இந்தி, ஜெர்மன், ஸ்பானிஷ், மலையாளம், டச்சு |
| surah meanings (surah.meaning.2) | பசு மாடு (Al-Baqarah) |
