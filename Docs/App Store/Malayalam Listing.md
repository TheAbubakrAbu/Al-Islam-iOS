# App Store Malayalam Listing

The **Malayalam** (`ml`) localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store
Connect (Malayalam listings since 2026, like Bangla), add the Malayalam localization, then fill Name and
Subtitle under App Information and the other four fields on the version page. Screenshots can stay English:
App Store Connect shows the primary language's screenshots for a localization that has none of its own.
People whose device is set to Malayalam see this listing instead of the English one. In the Malayalam
interface the app keeps its Latin name, Al-Islam (on the Home Screen too), and its tabs are ബാങ്കുവിളി, ഖുർആൻ,
ഹദീസ്, ഇസ്ലാം and ക്രമീകരണം; the listing uses the same words.

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
  file, not the store), after NFC normalization, the form the app's catalog and `labels.json` use. A chillu
  (ൺ ൻ ർ ൽ ൾ) is one code point, a conjunct counts its virama (്), and a vowel sign counts on its own:
  ഖുർആൻ is 5, നിസ്കാര സമയങ്ങൾ is 15. Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Malayalam Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
  (from zsh, a script that holds Malayalam text itself goes in a file with `# -*- coding: utf-8 -*-`, not in
  a heredoc).
- **Malayalam as Kerala's Muslims write it:** standard written Malayalam with the Islamic words Kerala Muslims
  use in madrasa and print (നിസ്കാരം, ബാങ്ക്, നോമ്പ്, ഖുർആൻ, ഖിബ്ല, ദുആ, ദിക്ർ, തജ്വീദ്, തഫ്സീർ, ഹിഫ്ള്,
  ഖത്തം), never another religion's rite word (not പ്രാർത്ഥന for salah, not ദൈവം for Allah). The reader is
  "നിങ്ങൾ", and every instruction takes Apple's polite imperative in -ൂ (വായിക്കൂ, ടാപ്പ് ചെയ്യൂ,
  തിരഞ്ഞെടുക്കൂ), never the dictionary form in -ുക. Every sentence ends in the Latin full stop, as Malayalam
  writes it. The honorific is always spelled out, "(സ്വല്ലല്ലാഹു അലൈഹി വസല്ലം)", after the possessive name
  (മുഹമ്മദ് നബിയുടെ (സ്വല്ലല്ലാഹു അലൈഹി വസല്ലം) ഹദീസുകൾ): App Store Connect rejects the one-glyph ligature
  (U+FDFA) as an invalid character.
- **Feature names are the labels the app shows** (the Malayalam translation of `Resources/Localizable.xcstrings`;
  `ml/labels.json` binds 331 of them; see the glossary below). A label that is a noun stands bare and may take
  a case ending (നിസ്കാര ട്രാക്കർ, ഖിറാഅത്ത് എക്സ്പ്ലോററിൽ). A label that is an imperative ("AI-യോട് ചോദിക്കൂ", "ഈ
  ആയത്ത് മുതൽ കേൾക്കൂ", "വിഷയമനുസരിച്ച് കാണൂ", "നിർത്താതെ ആവർത്തിക്കൂ") or reads as a plain phrase
  ("എങ്ങനെ ചെയ്യാം") goes in "quotes", so it reads as a name and not as an instruction. Apple's own features
  take Apple's Malayalam words (ക്രമീകരണം, വിജറ്റ്, കൺട്രോൾ സെന്റർ, തത്സമയ പ്രവർത്തനം, ലോക്ക് സ്ക്രീൻ). In a
  sentence the Settings tab is ക്രമീകരണങ്ങൾ, the glossary's form.
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma or a new sentence. A leading
  "- " bullet is fine; the English fields use the same. The hyphen before a case ending on a Latin name or a
  number (Al-Islam-ന്റെ, iCloud-ൽ, AI-യോട്, 60-ലധികം) is a hyphen, not a dash.
- **Plain characters in every store field:** Malayalam letters with every chillu as its atomic code point
  (U+0D7A to U+0D7E), never consonant + ് + ZWJ, and ന്റ written ന ് റ; no ZWJ or ZWNJ at all (U+200D, U+200C,
  which some keyboards slip into a conjunct such as ഫ്സ or ജ്വ), no dot reph (U+0D4E), no chillu k (U+0D7F),
  no direction marks. Western digits with a comma for thousands (50,000), never Malayalam digits (൦ to ൯), and
  straight ASCII quotes (" "), never the curly ‘ ’ and “ ” the app's own strings use. On 2026-10-29 App Store
  Connect refused characters in Al-Islam's Urdu fields without naming them, so these fields keep to the
  plainest characters of the script. No version numbers.
- **App names stay Latin:** Al-Islam, Al-Adhan, Al-Quran. A case ending joins a Latin name with a hyphen
  (Al-Islam-ന്റെ, iCloud-ൽ, iMessage-നുള്ള, Siri-യോട്), as the app's Malayalam strings join one (Apple
  Intelligence-ന്, Private Cloud Compute-ൽ); a list of Latin names takes "എന്നിവയിൽ" after the last (iPhone,
  iPad, Mac, Apple Watch എന്നിവയിൽ). Brand names stay Latin too: Apple, iCloud, Siri, Apple Watch, Apple
  Intelligence, iPhone, iPad, Mac, iMessage, iOS. So do the English editions' titles (Maarif Ul Quran,
  Tazkirul Quran): written in Malayalam they would read as Malayalam editions, which the app does not have.
- **Search spellings go in the keyword field only.** The name, subtitle and description write the app's forms
  (ഖുർആൻ, നിസ്കാരം, ബാങ്കുവിളി, ഖിബ്ല, തഫ്സീർ). The keyword field adds the spelling many Malayalis type
  (ഖുറാൻ) and the Latin words people type on an English keyboard (quran, namaz, and Kerala's own niskaram in
  Manglish, Malayalam typed in Latin letters): each is a search term of its own. Older Malayalam text and some
  keyboards still write a chillu as consonant + ് + ZWJ, or put a ZWNJ inside a conjunct; whether Apple's
  search folds those into the atomic forms is not documented, and the fields cannot hold them, so the atomic
  spelling is the only one offered.
- **Case endings and compounds:** Malayalam fuses case endings and "and" (-ഉം) to the word (ഖുർആനിലെ,
  ഹദീസും) and joins a noun to the next in its stem form (നിസ്കാരം becomes നിസ്കാര in നിസ്കാര സമയങ്ങൾ).
  Whether Apple's search folds an inflected word or a stem back to the bare word is not documented, so the
  name and subtitle keep bare words, and the keyword field treats a bare word as a term of its own even when
  its stem or plural is in the subtitle (നിസ്കാരം beside നിസ്കാര, സമയം beside സമയങ്ങൾ). If App Analytics
  shows Apple folding them, those bare words are the first to swap.
- **Be honest about what is still English:** the in-depth articles of the Islam tab, AI search by meaning
  (English phrases only), the Quran and hadith translations (English, beside the Arabic; there is no
  Malayalam translation, so the description says ഇംഗ്ലീഷ് പരിഭാഷ and the keyword field leaves out മലയാളം,
  malayalam, പരിഭാഷ and അർത്ഥം), and Siri, which has no Malayalam, so its phrases are said in English, as the
  Hindi listing says for Hindi. The surah names stay Latin (Al-Baqarah) with their meaning in Malayalam, and
  the hadith reference lookup reads Latin names only (the app's own Malayalam search tip keeps
  'bukhari 5103'), so the description keeps "Bukhari 5" in Latin.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with the Hindi and Bangla listings: when a field changes for a feature, change it here
  too.

## 1. Name

The name keeps Al-Islam first, then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | ഖുർആൻ, ഹദീസ്, ദുആ
```

**28 / 30 characters.**

The app's sections as bare words, the shape of the Hindi and Bangla names, each the label of its tab. The
third tab does not fit: "Al-Islam | ഖുർആൻ, ഹദീസ്, ബാങ്കുവിളി" is 35 characters, and the bare ബാങ്ക് also
spells "bank", which is why the glossary keeps it out of every label. The third word is ദുആ instead, the dua
collections and Hisn al-Muslim, a large search of its own; prayer times lead the subtitle. The keyword field
adds ഖുറാൻ, ബാങ്കുവിളി and the Latin quran.

## 2. Subtitle

```
നിസ്കാര സമയങ്ങൾ, ഖിബ്ല, തഫ്സീർ
```

**30 / 30 characters.**

നിസ്കാര സമയങ്ങൾ is the app's label for Prayer Times; with the keyword field's സമയം and നിസ്കാരം it also
answers "നിസ്കാര സമയം", the singular most people type. ഖിബ്ല is the Qibla, and തഫ്സീർ the tafsir for every
ayah, as in the Hindi and Bangla subtitles.

## 3. Promotional Text

Leads with the Malayalam interface. Update it with the next release like the English one.

```
പുതിയത്: പൂർണ്ണ മലയാളം ഇന്റർഫേസ്, സൂറത്തുകളുടെ ലാറ്റിൻ പേരുകൾക്കൊപ്പം മലയാള അർത്ഥവും. ഖുർആൻ, ഹദീസ്, നിസ്കാര സമയങ്ങൾ, എല്ലാം പരസ്യങ്ങളില്ലാത്ത ഒരൊറ്റ സൗജന്യ ആപ്പിൽ.
```

**163 / 170 characters.**

## 4. Description

A Malayalam rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers
as short Malayalam headings on their own lines (Malayalam has no capitals). Four lines say what is English:
the Quran line and the hadith line name an English translation (ഇംഗ്ലീഷ് പരിഭാഷ), the AI line says search by
meaning still works from English phrases only, and the interface line says the Islam tab's articles are
English. The Nine books are named generically (ഒമ്പത് ഗ്രന്ഥങ്ങൾ, under the heading പ്രധാന ഹദീസ് ഗ്രന്ഥങ്ങൾ)
with each book's short name as the app's Malayalam writes it (ബുഖാരി, തിർമിദി, മുസ്നദ് അഹ്മദ്); the Six
Books' label, സ്വിഹാഹുസ്സിത്ത, would not cover all nine. The forty-hadith collections take the app's label,
നാൽപത് ഹദീസ് സമാഹാരങ്ങൾ. The tafsir line splits its two languages with a semicolon, so neither English
title has to take a case ending. Malayalam runs longer than Hindi in code points, so the bullets are tighter
than the Hindi ones (Zakah and inheritance share one കാൽക്കുലേറ്ററുകൾ, the Masjid and Halal Food locators
one തിരയൽ, as the English does) while every feature and every honesty line stays.

```
Al-Islam ഇസ്ലാമിക ജീവിതത്തിന് സമ്പൂർണ്ണ കൂട്ടാണ്, ജന്മനാ മുസ്ലിമിനും പുതുമുസ്ലിമിനും ഇസ്ലാമിനെ അറിയാൻ ആഗ്രഹിക്കുന്നവർക്കും. ഖുർആൻ, ഹദീസ് ഗ്രന്ഥങ്ങൾ, തഫ്സീർ, നിസ്കാര സമയങ്ങളും ട്രാക്കറും, ഉപകരണത്തിലെ AI തിരയൽ, എല്ലാം ഒരു ആപ്പിൽ: പൂർണ്ണമായും സൗജന്യം, പരസ്യങ്ങളില്ല, സ്വകാര്യത സുരക്ഷിതം.

സമ്പൂർണ്ണ ഖുർആൻ
- സൂറത്ത്, ജുസ്അ്, പേജ് ക്രമത്തിൽ, ലിസ്റ്റായോ മുസ്ഹഫ് പേജുകളായോ വായിക്കൂ; ലാൻഡ്സ്കേപ്പിൽ രണ്ട് പേജ് ഒരുമിച്ച്.
- അറബി, ലിപ്യന്തരണം, ഇംഗ്ലീഷ് പരിഭാഷ ഒരുമിച്ച്, ഇഷ്ടമുള്ള നിറങ്ങളിൽ തജ്വീദ് സഹിതം.
- ഓരോ ആയത്തിനും തഫ്സീർ, ഓഫ്ലൈനിലും: ഇംഗ്ലീഷിൽ ഇബ്നു കസീർ, Maarif Ul Quran, Tazkirul Quran; അറബിയിൽ ഇബ്നു കസീർ, ത്വബരി, സഅ്ദി.
- വാക്ക് പഠനം: ഏത് വാക്കിലും രണ്ടുതവണ ടാപ്പ് ചെയ്താൽ അർത്ഥം, വ്യാകരണം, ധാതു, അത് വരുന്ന ഇടങ്ങളും.
- 60-ലധികം ഖാരിഉകൾ, ഓഫ്ലൈൻ ഡൗൺലോഡ്, "നിർത്താതെ ആവർത്തിക്കൂ", പേജ്, സൂറത്ത്, ജുസ്അ്, ഖുർആൻ എന്നിവയുടെ അവസാനം വരെ "ഈ ആയത്ത് മുതൽ കേൾക്കൂ".
- ഹഫ്സും പത്ത് ഖിറാഅത്തുകളിലെ മറ്റ് 19 റിവായത്തുകളും, ഖിറാഅത്ത് എക്സ്പ്ലോററിൽ താരതമ്യം ചെയ്യാം.
- സമാന ആയത്തുകൾ, "വിഷയമനുസരിച്ച് കാണൂ", ഇന്നത്തെ വാക്ക്, ബുക്ക്മാർക്കുകൾ, കുറിപ്പുകൾ.

ഹിഫ്ളും ആവർത്തനവും
- ഖുർആൻ പ്ലാനർ: ഖത്തം തീർക്കേണ്ട തീയതി നിശ്ചയിക്കൂ, മനഃപാഠമുള്ള സൂറത്തുകൾക്ക് ആവർത്തന പ്ലാനും ചേർക്കൂ.
- പരീക്ഷാ മോഡ്: ടാപ്പ് ചെയ്യുംവരെ ടെക്സ്റ്റ് മറഞ്ഞിരിക്കും, ഓർമ്മയിൽ നിന്ന് ഓതി ഓരോ ആയത്തും ഉറപ്പാക്കാം.

പ്രധാന ഹദീസ് ഗ്രന്ഥങ്ങൾ
- ഒമ്പത് ഗ്രന്ഥങ്ങൾ (ബുഖാരി, മുസ്ലിം, നസാഈ, അബൂദാവൂദ്, തിർമിദി, ഇബ്നു മാജ, മുവത്വ മാലിക്, ദാരിമി, മുസ്നദ് അഹ്മദ്), നാൽപത് ഹദീസ് സമാഹാരങ്ങൾ, റിയാളുസ്സ്വാലിഹീൻ പോലുള്ളവ.
- അറബിയും ഇംഗ്ലീഷ് പരിഭാഷയും, നിവേദക പരമ്പരയും നിവേദകരുടെ പേജുകളും, ഇന്നത്തെ ഹദീസ്, ബുക്ക്മാർക്കുകൾ, "Bukhari 5" പോലുള്ള റഫറൻസ് തിരയൽ.
- ഒരു ഗ്രന്ഥത്തിലോ 50,000-ലധികം ഹദീസുകളിൽ മുഴുവനുമോ തിരയൂ, ഓഫ്ലൈനിലും.

ഉപകരണത്തിലെ AI
- അർത്ഥമനുസരിച്ച് ഖുർആനിലും ഹദീസിലും തിരയൂ: "patience in hardship" എന്നെഴുതിയാൽ സ്വബ്റിന്റെ ആയത്തുകൾ കിട്ടും. ഈ തിരയൽ ഇപ്പോൾ ഇംഗ്ലീഷ് വാക്യങ്ങളിൽ മാത്രം.
- Apple Intelligence ഓണാണെങ്കിൽ "AI-യോട് ചോദിക്കൂ" അത് ഉദ്ധരിക്കുന്ന ആയത്തുകളും ഹദീസുകളും വെച്ച് മറുപടി നൽകും, ഫത്വ നൽകില്ല.

നിസ്കാരം, ഖിബ്ല, ട്രാക്കർ
- ഉപകരണത്തിൽ കണക്കാക്കുന്ന കൃത്യമായ നിസ്കാര സമയങ്ങൾ, പ്രദേശത്തിന് നിർദ്ദേശിക്കുന്ന രീതിയിൽ.
- നിസ്കാര സമയങ്ങൾക്ക് മേൽ ജീവനുള്ള ആകാശം: സൂര്യപഥം, നക്ഷത്രങ്ങൾ, യഥാർത്ഥ ചന്ദ്രക്കലയിൽ 3D ചന്ദ്രൻ, വേണമെങ്കിൽ കാലാവസ്ഥയും.
- ഖിബ്ല കോമ്പസ്, ബാങ്കുവിളി ശബ്ദങ്ങൾ, മുൻകൂർ അറിയിപ്പ്, യാത്രാ മോഡ്, നിസ്കരിക്കുംവരെ ഓർമ്മിപ്പിക്കുന്ന തുടർ ഓർമ്മപ്പെടുത്തൽ മോഡ്.
- നിസ്കാര ട്രാക്കർ: ഒറ്റ ടാപ്പിൽ ഓരോ നിസ്കാരവും രേഖപ്പെടുത്തൂ; തുടർച്ച, പൂർണ്ണ ദിവസങ്ങൾ, നിറമുള്ള കലണ്ടർ.
- നിസ്കാര സമയ, തിരഞ്ഞെടുത്ത ആയത്ത് വിജറ്റുകൾ, കൺട്രോൾ സെന്റർ നിയന്ത്രണങ്ങൾ, റമദാൻ തത്സമയ പ്രവർത്തനം, Apple Watch.

ദൈനംദിന ഇബാദത്തും പഠനവും
- ഇന്ന്: ദിവസത്തെ ആയത്ത്, ഹദീസ്, ദുആ, അല്ലാഹുവിന്റെ നാമം, ഇന്നത്തെ ഉപദേശം, സുന്നത്ത് ഓർമ്മപ്പെടുത്തലുകൾ.
- ദിക്റും അദ്കാറും, ഹിസ്നുൽ മുസ്ലിം, ഉറവിടങ്ങളും ഓഡിയോയും സഹിതം ദുആ സമാഹാരങ്ങൾ, തസ്ബീഹ് കൗണ്ടർ, ഇസ്ലാമിക ഡയറി.
- അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ വിശദമായി, ഖുർആനിലെ അത്ഭുതങ്ങൾ, ഇസ്ലാമിന്റെ തെളിവുകൾ, ഹദീസ് വിജ്ഞാനീയങ്ങൾ.
- അറബി അക്ഷരമാലയ്ക്ക് 21 തലങ്ങളുള്ള വായനാ പരീക്ഷ, തജ്വീദിന് 58 പാഠങ്ങളുള്ള കോഴ്സും തജ്വീദ് പരീക്ഷയും.
- "എങ്ങനെ ചെയ്യാം" ഗൈഡുകൾ, ഇസ്ലാമിന്റെയും ഈമാനിന്റെയും സ്തംഭങ്ങൾ, സകാത്ത്, അനന്തരാവകാശ കാൽക്കുലേറ്ററുകൾ, ഹിജ്റ കലണ്ടർ, പള്ളി, ഹലാൽ ഭക്ഷണ തിരയൽ.

നിങ്ങളുടെ രീതിയിൽ
- ഇന്റർഫേസ് മലയാളം, ഇംഗ്ലീഷ്, അറബി ഉൾപ്പെടെ 15 ഭാഷകളിൽ: iOS ക്രമീകരണങ്ങളിൽ ഈ ആപ്പിന്റെ ഭാഷ തിരഞ്ഞെടുക്കൂ. ഇസ്ലാം ടാബിലെ വിശദ ലേഖനങ്ങൾ ഇപ്പോഴും ഇംഗ്ലീഷിലാണ്.
- ലളിത മോഡ് അത്യാവശ്യമുള്ളവ മാത്രം കാണിക്കും. എപ്പോഴും പൂർണ്ണ മോഡിലേക്ക് മാറാം.
- പ്രൊഫൈലുകൾ സ്വന്തം iCloud-ൽ ബാക്ക്അപ്പ് ചെയ്ത് ഏത് ഉപകരണത്തിലും റീസ്റ്റോർ ചെയ്യൂ.
- ടെക്സ്റ്റ് വലിപ്പം, അറബി ഫോണ്ടുകൾ, ആക്സന്റ്, ആകാശ നിറങ്ങൾ, ഓരോ ക്രമീകരണ പേജിലും തിരയൽ.
- iPhone, iPad, Mac, Apple Watch, iMessage-നുള്ള ഇസ്ലാമിക സ്റ്റിക്കറുകളും.

സൗജന്യം, പരസ്യമില്ല, സ്വകാര്യം
Al-Islam പൂർണ്ണമായും സൗജന്യമാണ്. പരസ്യമില്ല, അക്കൗണ്ടില്ല, സബ്സ്ക്രിപ്ഷനില്ല, ട്രാക്കിംഗില്ല: നിങ്ങൾ ചെയ്യുന്നതൊന്നും ശേഖരിക്കുകയോ പങ്കിടുകയോ ചെയ്യില്ല.

നിസ്കാര സമയങ്ങളോ ഖുർആനോ മുഹമ്മദ് നബിയുടെ (സ്വല്ലല്ലാഹു അലൈഹി വസല്ലം) ഹദീസുകളോ ഇസ്ലാമിന്റെ ആഴമുള്ള അറിവോ, എന്ത് തേടിയാലും ഇന്നുതന്നെ Al-Islam ഡൗൺലോഡ് ചെയ്യൂ.
```

**3,988 / 4,000 characters.**

## 5. What's New

The release that adds the Malayalam interface; all twelve new languages ship in one release. Only the
interface notes are here so far. The Urdu text's right-to-left and digit lines have no Malayalam counterpart
and are left out; in their place are the Latin surah names with their Malayalam meanings, the prayer names as
the Malayalam catalog writes them (സുബ്ഹ്, ളുഹ്ർ, അസ്ർ, മഗ്രിബ്, ഇശാ: Fajr is സുബ്ഹ്, as Kerala timetables
name it), and a line saying the translations are English. The language line names the other eleven new
languages, then gives the total, fifteen, with the three the app already had.

```
Al-Islam-ന്റെ ഇന്റർഫേസ് ഇപ്പോൾ മലയാളത്തിൽ, ബാങ്കുവിളി, ഖുർആൻ, ഹദീസ് മുതൽ ഇസ്ലാം, ക്രമീകരണം വരെ എല്ലാ ടാബുകളിലും.

മലയാളം ഇന്റർഫേസ്:
- എല്ലാ സ്ക്രീനുകളും മെനുകളും ക്രമീകരണങ്ങളും അറിയിപ്പുകളും വിജറ്റുകളും മലയാളത്തിൽ, iPhone, iPad, Mac, Apple Watch എന്നിവയിൽ.
- സൂറത്തുകളുടെ പേരുകൾ ലാറ്റിൻ ലിപിയിൽ തന്നെ തുടരുന്നു, ഉദാഹരണത്തിന് Al-Baqarah, ഒപ്പം മലയാളത്തിൽ അർത്ഥവും (പശു).
- നിസ്കാരങ്ങളുടെ പേരുകൾ മലയാളത്തിൽ: സുബ്ഹ്, ളുഹ്ർ, അസ്ർ, മഗ്രിബ്, ഇശാ.
- നിസ്കാര അറിയിപ്പുകൾ മലയാളത്തിൽ വരുന്നു.
- 58 പാഠങ്ങളുള്ള തജ്വീദ് കോഴ്സ് പൂർണ്ണമായും മലയാളത്തിൽ.
- ഖുർആന്റെയും ഹദീസിന്റെയും പരിഭാഷകൾ ഇപ്പോൾ ഇംഗ്ലീഷിലാണ്, അറബി ടെക്സ്റ്റിനൊപ്പം.

പുതിയ ഭാഷകൾ:
- മലയാളത്തോടൊപ്പം Al-Islam ഇപ്പോൾ ഇന്തോനേഷ്യൻ, മലായ്, ടർക്കിഷ്, ഫ്രഞ്ച്, ബംഗാളി, റഷ്യൻ, ഹിന്ദി, ജർമ്മൻ, സ്പാനിഷ്, തമിഴ്, ഡച്ച് ഭാഷകളിലും ലഭ്യമാണ്. ഇംഗ്ലീഷ്, അറബി, ഉർദു എന്നിവ ഉൾപ്പെടെ ആകെ 15 ഭാഷകൾ.

ഭാഷ തിരഞ്ഞെടുക്കൽ:
- iOS ക്രമീകരണങ്ങളിൽ ഈ ആപ്പിനായി നിങ്ങൾ തിരഞ്ഞെടുക്കുന്ന ഭാഷ ആപ്പ് പിന്തുടരുന്നു, ആപ്പിന്റെ ക്രമീകരണങ്ങളിലെ "ഭാഷ" എന്ന വരി നിങ്ങളെ അവിടേക്ക് കൊണ്ടുപോകും.
- ഭാഷ മാറ്റുമ്പോൾ നിങ്ങളുടെ അറിയിപ്പുകൾ പുതിയ ഭാഷയിൽ വീണ്ടും ഷെഡ്യൂൾ ചെയ്യപ്പെടുന്നു.
- Siri മലയാളത്തിൽ ലഭ്യമല്ല, അതിനാൽ Siri-യോട് ഇംഗ്ലീഷിൽ സംസാരിക്കൂ.
- ഇസ്ലാം ടാബിലെ വിശദമായ ലേഖനങ്ങളും അർത്ഥമനുസരിച്ചുള്ള തിരയലും ഇപ്പോൾ ഇംഗ്ലീഷിലാണ്.
```

**1,240 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (ഖുർആൻ:, ബാങ്കുവിളി:, ഹദീസ്:, ഇസ്ലാമിക ടൂളുകൾ:, ക്രമീകരണം:, ബഗ് പരിഹാരങ്ങളും മെച്ചപ്പെടുത്തലുകളും:). Keep
the Malayalam interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al-Islam, ഖുർആൻ, ഹദീസ്, ദുആ, നിസ്കാര,
സമയങ്ങൾ, ഖിബ്ല, തഫ്സീർ); as in the Hindi and Bangla fields, another spelling of the same word (ഖുറാൻ beside
ഖുർആൻ, the Latin quran, namaz and niskaram) is a search term of its own, and so is a bare word beside the
stem or plural in the subtitle (നിസ്കാരം beside നിസ്കാര, സമയം beside സമയങ്ങൾ; see Guidelines).

```
quran,niskaram,namaz,നിസ്കാരം,സമയം,ബാങ്കുവിളി,ഖുറാൻ,തജ്വീദ്,ദിക്ർ,തസ്ബീഹ്,റമദാൻ,നോമ്പ്,പാരായണം
```

**94 / 100 characters.**

Why these terms:
- **quran, namaz:** the two words Indian Muslims most often type on an English keyboard ("quran", "namaz
  time"), the Hindi and Bangla fields' choice; English's `Keywords.md` carries both too.
- **niskaram:** Kerala's own word for salah as Malayalis type it in Latin letters ("niskaram time",
  "niskara samayam"); Manglish is how a large share of Kerala searches, even on a Malayalam phone.
- **നിസ്കാരം, സമയം:** the bare noun beside the subtitle's stem നിസ്കാര, and the singular beside the
  subtitle's plural സമയങ്ങൾ, so "നിസ്കാര സമയം", the usual search for a prayer timetable, meets whole words.
- **ബാങ്കുവിളി:** the call to prayer and the label of the Adhan tab ("ബാങ്കുവിളി ശബ്ദം", the adhan sounds);
  the bare ബാങ്ക് is left out because it also spells "bank".
- **ഖുറാൻ:** the everyday spelling many Malayalis type beside the app's ഖുർആൻ.
- **തജ്വീദ്:** the colored tajweed, the തജ്വീദ് കോഴ്സ് and the തജ്വീദ് പരീക്ഷ.
- **ദിക്ർ, തസ്ബീഹ്:** ദിക്റും അദ്കാറും and the തസ്ബീഹ് കൗണ്ടർ; the name's ദുആ already covers the dua
  collections.
- **റമദാൻ, നോമ്പ്:** the Ramadan Live Activity, which counts down to the end of അത്താഴം (suhoor) and to
  നോമ്പുതുറ (iftar); with സമയം, "നോമ്പ് സമയം" is searched every Ramadan.
- **പാരായണം:** over 60 reciters ("ഖുർആൻ പാരായണം").

Left out for room, to rotate in from App Analytics: ട്രാക്കർ ("നിസ്കാര ട്രാക്കർ"), കോമ്പസ് ("ഖിബ്ല
കോമ്പസ്"), നോമ്പുതുറ and അത്താഴം, ജുസ്അ്, സൂറത്ത്, ഹിഫ്ള്, ഹിജ്റ, നമസ്കാരം (the other common word for salah,
which is also the everyday greeting), the two-word "ബാങ്ക് വിളി" (as ബാങ്ക്,വിളി, if App Analytics shows it
beating ബാങ്കുവിളി), salah, dua, and ബുഖാരി (a large search, but most of it wants a Malayalam translation of
Sahih al-Bukhari, which the app does not have). Deliberately excluded: മലയാളം, malayalam, പരിഭാഷ and അർത്ഥം
("quran malayalam" and "ഖുർആൻ മലയാളം പരിഭാഷ", Kerala's largest Quran searches, want a Malayalam translation,
and the app's translations are English); ഇബ്നു and കസീർ (for "തഫ്സീർ ഇബ്നു കസീർ"), since a Malayalam search
for it wants a Malayalam edition and the app has it in English and Arabic only; and പള്ളി, which in Kerala
names a church as often as a mosque.

## Glossary

The Malayalam the app shows for the features the listing names (the Malayalam translation of
`Resources/Localizable.xcstrings`). Each label was checked on 2026-11-21 against `ml/labels.json` and the
finished interface batches (`ml/out/*.json`, 001 to 015). Batches 016 to 019 were checked again on 2026-11-21 against the merged catalog: every label matches it, and
Repeat Forever is the app's നിർത്താതെ ആവർത്തിക്കൂ. Two features are named in prose rather than by their
control: the Full option (the picker says പൂർണ്ണം; the fields say പൂർണ്ണ മോഡ്) and search by meaning (the
control says അർത്ഥം കൊണ്ട് തിരയൂ; the fields name the feature അർത്ഥമനുസരിച്ചുള്ള തിരയൽ).

| English | Malayalam |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, ബാങ്കുവിളി, ഖുർആൻ, ഹദീസ്, ഇസ്ലാം, ക്രമീകരണം (in a sentence ക്രമീകരണങ്ങൾ) |
| Prayer Times, Qibla Compass, Prenotification, Adhan Sound | നിസ്കാര സമയങ്ങൾ, ഖിബ്ല കോമ്പസ്, മുൻകൂർ അറിയിപ്പ്, ബാങ്കുവിളി ശബ്ദം |
| Simple Mode / Full | ലളിത മോഡ് / പൂർണ്ണ മോഡ് |
| Prayer Tracker, Streak, Perfect Days | നിസ്കാര ട്രാക്കർ, തുടർച്ച, പൂർണ്ണ ദിവസങ്ങൾ |
| Test Mode | പരീക്ഷാ മോഡ് |
| Quran Planner, Revision, Khatm | ഖുർആൻ പ്ലാനർ, ആവർത്തനം, ഖത്തം |
| Read as List, Read as Pages | ലിസ്റ്റായി വായിക്കൂ, പേജുകളായി വായിക്കൂ |
| Transliteration, Translation | ലിപ്യന്തരണം, പരിഭാഷ |
| Word Study, Root, Grammar | വാക്ക് പഠനം, ധാതു, വ്യാകരണം |
| Qiraat Explorer, the Ten Qiraat, riwayat | ഖിറാഅത്ത് എക്സ്പ്ലോറർ, പത്ത് ഖിറാഅത്തുകൾ, റിവായത്തുകൾ |
| Reciters | ഖാരിഉകൾ |
| Traveling Mode | യാത്രാ മോഡ് |
| Nagging Mode | തുടർ ഓർമ്മപ്പെടുത്തൽ മോഡ് |
| Repeat Forever, Play From Ayah | നിർത്താതെ ആവർത്തിക്കൂ, ഈ ആയത്ത് മുതൽ കേൾക്കൂ |
| Similar Ayahs, Browse by Theme, Word of the Day | സമാന ആയത്തുകൾ, വിഷയമനുസരിച്ച് കാണൂ, ഇന്നത്തെ വാക്ക് |
| Bookmarks, Notes | ബുക്ക്മാർക്കുകൾ, കുറിപ്പുകൾ |
| Chain of Narrators, a narrator's page | നിവേദക പരമ്പര, നിവേദകന്റെ പേജ് |
| The Forty Collections, Hadith of the Day | നാൽപത് ഹദീസ് സമാഹാരങ്ങൾ, ഇന്നത്തെ ഹദീസ് |
| Ask AI, Search by meaning | AI-യോട് ചോദിക്കൂ, അർത്ഥമനുസരിച്ചുള്ള തിരയൽ |
| Chosen Ayah (widget), Control Center, Live Activity | തിരഞ്ഞെടുത്ത ആയത്ത്, കൺട്രോൾ സെന്റർ, തത്സമയ പ്രവർത്തനം |
| Today, Name of Allah, Reminder of the Day | ഇന്ന്, അല്ലാഹുവിന്റെ നാമം, ഇന്നത്തെ ഉപദേശം |
| Sunnah Reminders, Daily Reminder | സുന്നത്ത് ഓർമ്മപ്പെടുത്തലുകൾ, പ്രതിദിന ഓർമ്മപ്പെടുത്തൽ |
| Dhikr & Remembrances, Hisn al-Muslim, Tasbih Counter, Islamic Journal | ദിക്റും അദ്കാറും, ഹിസ്നുൽ മുസ്ലിം, തസ്ബീഹ് കൗണ്ടർ, ഇസ്ലാമിക ഡയറി |
| 99 Names of Allah | അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ |
| Miracles of the Quran, Proving Islam, The Sciences of Hadith | ഖുർആനിലെ അത്ഭുതങ്ങൾ, ഇസ്ലാമിന്റെ തെളിവുകൾ, ഹദീസ് വിജ്ഞാനീയങ്ങൾ |
| Arabic Alphabet, Reading Test | അറബി അക്ഷരമാല, വായനാ പരീക്ഷ |
| Tajweed Course, Tajweed Test | തജ്വീദ് കോഴ്സ്, തജ്വീദ് പരീക്ഷ |
| How-To Guides, Pillars & Beliefs | എങ്ങനെ ചെയ്യാം, സ്തംഭങ്ങളും വിശ്വാസങ്ങളും |
| Zakah Calculator, Inheritance Calculator, Hijri Calendar | സകാത്ത് കാൽക്കുലേറ്റർ, അനന്തരാവകാശ കാൽക്കുലേറ്റർ, ഹിജ്റ കലണ്ടർ |
| Masjid Locator, Halal Food Locator | പള്ളി തിരയൽ, ഹലാൽ ഭക്ഷണ തിരയൽ |
| iCloud Backup, Text Size, Arabic Font, Accent Color, Sky Colors | iCloud ബാക്ക്അപ്പ്, ടെക്സ്റ്റ് വലിപ്പം, അറബി ഫോണ്ട്, ആക്സന്റ് നിറം, ആകാശ നിറങ്ങൾ |
| Language (Settings row) | ഭാഷ |
| Ibn Kathir, al-Tabari, as-Sa'di | ഇബ്നു കസീർ, ത്വബരി, സഅ്ദി |
| the hadith books | ബുഖാരി, മുസ്ലിം, നസാഈ, അബൂദാവൂദ്, തിർമിദി, ഇബ്നു മാജ, മുവത്വ മാലിക്, ദാരിമി (സുനൻ ദാരിമി), മുസ്നദ് അഹ്മദ്, റിയാളുസ്സ്വാലിഹീൻ |
| Fajr, Dhuhr, Asr, Maghrib, Isha | സുബ്ഹ്, ളുഹ്ർ, അസ്ർ, മഗ്രിബ്, ഇശാ |
| Suhoor, Iftar, Ramadan | അത്താഴം, നോമ്പുതുറ, റമദാൻ |
| surah meanings (surah.meaning.2) | പശു (Al-Baqarah) |
