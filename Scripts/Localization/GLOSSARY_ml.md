# Malayalam (ml): as Kerala's Muslims and Apple's Malayalam iOS write it

For Kerala's Muslims (and Malayalis in the Gulf): standard written Malayalam with the Islamic words Kerala
Muslims use in madrasa and print (നിസ്കാരം, ബാങ്ക്, നോമ്പ്, പെരുന്നാൾ, ഓതുക), never another religion's rite
word (no പൂജ, no പ്രാർത്ഥന for salah, no ദൈവം for Allah). Interface words are Apple's Malayalam, which keeps
English loanwords in Malayalam script (ആപ്പ്, വിജറ്റ്). Address: "നിങ്ങൾ" and Apple's imperative in -ൂ
(ടാപ്പ് ചെയ്യൂ, തിരഞ്ഞെടുക്കൂ, ഓണാക്കൂ; never ടാപ്പ് ചെയ്യുക). Loanword verbs take ചെയ്യൂ; titles are nouns.

**Spelling:** chillu as the atomic letters ൺ ൻ ർ ൽ ൾ (U+0D7A-U+0D7E), never consonant + ് + ZWJ; ന്റ is
ന ് റ. No ZWJ or ZWNJ at all: write the conjunct (ഇസ്ലാം, മുസ്ലിം, മഗ്രിബ്). Arabic sounds, Arabi-Malayalam
style: ث സ · ذ ദ · ز സ · ص സ്വ · ض ള · ط ത്വ · ظ ള · خ and ق ഖ · ع അ് or the vowel (ജുമുഅ, ദുആ) · ر റ.
One exception: Ramadan റമദാൻ (Kerala print, Samastha's own site included).
**Punctuation:** Latin full stop; ? ! : as English. A control named in a sentence goes in ‘ ’ as Apple does
(‘കുറിപ്പ് ചേർക്കൂ’ ടാപ്പ് ചെയ്യൂ), a case ending on എന്നത് after it (‘X’ എന്നതിലേക്ക്). Speech, a hadith, an
example and a Siri phrase keep “ ”. Digits 0-9; ordinal "%lld-ാം".
**Placeholders:** no case ending on `%@` (no %@ൽ, %@-ന്റെ): inflect a noun after it ("%@ എന്ന സൂറത്തിൽ",
"%@ എന്നതിന്റെ") or use a label ("ഖാരിഅ്: %@"); "%@ and %@" is "%@, %@ എന്നിവ"; %@ വരെ, %@ മുതൽ are fine.
A Latin surah name likewise: "സൂറത്ത് Al-Kahf", inflected "Al-Kahf സൂറത്തിൽ".
**Plurals:** counted things take forms {"one": "%lld ആയത്ത്", "other": "%lld ആയത്തുകൾ"}: സൂറത്ത് /
സൂറത്തുകൾ, പേജ് / പേജുകൾ, ഹദീസ് / ഹദീസുകൾ, ജുസ്അ് / ജുസ്ഉകൾ, വാക്ക് / വാക്കുകൾ, അക്ഷരം / അക്ഷരങ്ങൾ.
A plain string where Malayalam keeps the singular: time and measure (%lld മിനിറ്റ്, മണിക്കൂർ, ദിവസം,
സെക്കൻഡ്), %lld തവണ (times, ×), %lld റക്അത്ത്, %lld ഹറകത്ത് (madd counts).

## Apple and interface words
Settings ക്രമീകരണം (in a sentence: ക്രമീകരണങ്ങൾ) · Cancel റദ്ദാക്കൂ · Done കഴിഞ്ഞു · OK ശരി ·
Close അടയ്ക്കൂ · Back പിന്നിലേക്ക് · Next അടുത്തത് · Previous മുൻപത്തേത് ·
Save സേവ് ചെയ്യൂ · Delete ഡിലീറ്റ് ചെയ്യൂ (bare button ഡിലീറ്റ്) · Remove നീക്കം ചെയ്യൂ · Edit എഡിറ്റ്
ചെയ്യൂ · Add ചേർക്കൂ · Share പങ്കിടൂ · Copy കോപ്പി ചെയ്യൂ · Search തിരയൂ (noun, field: തിരയൽ) ·
Reset റീസെറ്റ് ചെയ്യൂ · Choose തിരഞ്ഞെടുക്കൂ · Show / Hide കാണിക്കൂ / മറയ്ക്കൂ · Turn On / Off ഓണാക്കൂ /
ഓഫാക്കൂ · On / Off ഓൺ / ഓഫ് · Allow അനുവദിക്കൂ · Don't Allow അനുവദിക്കരുത് · Notifications അറിയിപ്പുകൾ ·
Location ലൊക്കേഷൻ · Location Services ലൊക്കേഷൻ സേവനങ്ങൾ · Widget വിജറ്റ് · Lock Screen ലോക്ക് സ്ക്രീൻ ·
Home Screen ഹോം സ്ക്രീൻ · Control Center കൺട്രോൾ സെന്റർ · Shortcuts ഷോർട്ട്കട്ട്സ് · Focus ഫോക്കസ് ·
Live Activities തത്സമയ പ്രവർത്തനങ്ങൾ · Silent mode നിശബ്ദ മോഡ് ·
Play പ്ലേ ചെയ്യൂ (recitation: കേൾക്കൂ where it reads better) · Pause പോസ് ചെയ്യൂ · Stop നിർത്തൂ ·
Repeat ആവർത്തിക്കൂ · Download ഡൗൺലോഡ് ചെയ്യൂ · Downloaded ഡൗൺലോഡ് ചെയ്തു · Favorites പ്രിയപ്പെട്ടവ ·
Language ഭാഷ · Appearance ദൃശ്യരീതി · Light / Dark ലൈറ്റ് / ഡാർക്ക് · Dark Mode ഡാർക്ക് മോഡ് · Sound ശബ്ദം ·
Haptics ഹാപ്റ്റിക്സ് · Font ഫോണ്ട് · Text Size ടെക്സ്റ്റ് വലിപ്പം · Learn More കൂടുതലറിയൂ · More കൂടുതൽ ·
Tip നുറുങ്ങ് · Tips & Tricks നുറുങ്ങുകളും വിദ്യകളും · Bookmarks ബുക്ക്മാർക്കുകൾ · Notes കുറിപ്പുകൾ ·
History ചരിത്രം · Backup ബാക്ക്അപ്പ് · Restore റീസ്റ്റോർ ചെയ്യൂ · Merge (backup) ലയിപ്പിക്കൂ · Import / Export
ഇംപോർട്ട് / എക്സ്പോർട്ട് · Tab ടാബ് · Grid ഗ്രിഡ് · List ലിസ്റ്റ് · Ask AI AI-യോട് ചോദിക്കൂ · app ആപ്പ് ·
tap ടാപ്പ് ചെയ്യൂ · touch and hold തൊട്ടുപിടിക്കൂ · swipe സ്വൈപ്പ് ചെയ്യൂ · sheet ഷീറ്റ് (never പേജ്: a page is
a mushaf page) · Streak തുടർച്ച · Custom കസ്റ്റം · Default ഡിഫോൾട്ട് · Always എപ്പോഴും ·
Accent Color ആക്സന്റ് നിറം · Highlight ഹൈലൈറ്റ്.

## The app's names and tabs
Al-Islam, Al-Adhan, Al-Quran: unchanged, Latin. Tabs: Islam "ഇസ്ലാം" · Quran "ഖുർആൻ" · Hadith "ഹദീസ്" ·
Adhan "ബാങ്കുവിളി" · Settings "ക്രമീകരണം". "Al-Hadith" stays. Adhan in ANY label (tab, title, row, button,
widget, a quoted label) is ബാങ്കുവിളി, since a bare ബാങ്ക് also spells "bank"; in sentences ബാങ്ക്.

## Islamic terms (Kerala Muslim usage)
the Quran ഖുർആൻ (വിശുദ്ധ ഖുർആൻ formally) · surah സൂറത്ത് (never അധ്യായം; Makki / Madani മക്കി / മദനി) ·
ayah ആയത്ത് · juz ജുസ്അ് · hizb ഹിസ്ബ് · page പേജ് · mushaf മുസ്ഹഫ് · recitation പാരായണം (to recite ഓതുക) ·
reciter ഖാരിഅ് · translation പരിഭാഷ · transliteration ലിപ്യന്തരണം · tafsir തഫ്സീർ · tajweed തജ്വീദ് ·
qiraat ഖിറാഅത്ത് · riwayah റിവായത്ത് · hadith ഹദീസ് · grades: സ്വഹീഹ്, ഹസൻ, ളഈഫ് · chain (isnad) സനദ് ·
hadith narrator നിവേദകൻ ("Narrated by %@": നിവേദനം: %@) · Companions സ്വഹാബികൾ · Successor താബിഈ ·
the Prophet ﷺ നബി ﷺ (Prophet Muhammad ﷺ മുഹമ്മദ് നബി ﷺ; a prophet പ്രവാചകൻ) · Allah അല്ലാഹു ·
prayer (salah) നിസ്കാരം, to pray നിസ്കരിക്കുക (നമസ്കാരം is also the everyday greeting) ·
adhan ബാങ്ക് · iqamah ഇഖാമത്ത് · qibla ഖിബ്ല · dua ദുആ · dhikr ദിക്ർ · tasbih തസ്ബീഹ് ·
sunnah സുന്നത്ത് · fard ഫർള് · fiqh ഫിഖ്ഹ് · aqeedah അഖീദ · fasting നോമ്പ് ·
zakah സകാത്ത് · hajj ഹജ്ജ് · umrah ഉംറ · mosque പള്ളി (a named one മസ്ജിദ്: മസ്ജിദുൽ ഹറാം) · Makkah /
Madinah മക്ക / മദീന · Friday prayer ജുമുഅ നിസ്കാരം · Eid പെരുന്നാൾ (Eid al-Fitr ഈദുൽ ഫിത്വ്ർ, Eid al-Adha
ഈദുൽ അള്ഹാ) · Ramadan റമദാൻ · Laylat al-Qadr ലൈലത്തുൽ ഖദ്ർ · Hijri ഹിജ്റ · the 99 Names അല്ലാഹുവിന്റെ
99 നാമങ്ങൾ · khatm ഖത്തം · revision ആവർത്തനം · memorise മനഃപാഠമാക്കുക (hifz ഹിഫ്ള്) · make up a prayer
ഖളാഅ് വീട്ടുക · night prayer രാത്രി നിസ്കാരം · witr വിത്ർ · rak'ah റക്അത്ത് · wudu വുളൂഅ് · ghusl കുളി ·
Torah തൗറാത്ത് · revelation (wahy) വഹ്യ് · revert പുതുമുസ്ലിം · worship ഇബാദത്ത് (verb ആരാധിക്കുക;
"public worship" ജമാഅത്ത് നിസ്കാരം).
Prayer names: സുബ്ഹ് (Fajr, as Kerala timetables say) · ഉദയം (Sunrise) · ളുഹ്ർ · അസ്ർ · മഗ്രിബ് ·
ഇശാ · ജുമുഅ · ളുഹാ (Duha) · തഹജ്ജുദ് (with "prayer": സുബ്ഹ് നിസ്കാരം ...; case forms ളുഹ്റിന്റെ,
സുബ്ഹിന്റെ, ഇശായുടെ). Hijri months: മുഹർറം, സ്വഫർ, റബീഉൽ അവ്വൽ, റബീഉൽ ആഖിർ, ജുമാദൽ ഊലാ, ജുമാദൽ ആഖിറ,
റജബ്, ശഅ്ബാൻ, റമദാൻ, ശവ്വാൽ, ദുൽഖഅ്ദ, ദുൽഹിജ്ജ. Methods keep their names (Muslim World League മുസ്ലിം
വേൾഡ് ലീഗ്). Madhabs: ഹനഫി, ശാഫിഈ, മാലികി, ഹമ്പലി.

## Tajweed and Arabic letters (as Kerala madrasas teach them)
harakat ഹറകത്തുകൾ · fatha ഫത്ഹ് · kasra കസ്റ് · damma ളമ്മ് · sukoon സുകൂൻ · shaddah ശദ്ദ് · tanween
തൻവീൻ · madd മദ്ദ് · ghunnah ഗുന്ന · qalqalah ഖൽഖല · idgham ഇദ്ഗാം · ikhfa ഇഖ്ഫാഅ് · iqlab ഇഖ്ലാബ് ·
izhar ഇള്ഹാർ (for every key spelling) · tafkheem തഫ്ഖീം · tarqeeq തർഖീഖ് · waqf വഖ്ഫ് · wasl വസ്ൽ ·
hamzat al-wasl ഹംസതുൽ വസ്ൽ · makhraj മഖ്റജ് (pl. മഖാരിജ്) · sifaat സ്വിഫാത്ത് · heavy / light letters
കനമുള്ള / നേർത്ത അക്ഷരങ്ങൾ · letter അക്ഷരം · vowel (sound) സ്വരം · count (madd length) ഹറകത്ത് ·
imalah ഇമാല · ishmam ഇശ്മാം.
Letter names in running prose (rule 7): ا അലിഫ് · ب ബാ · ت താ · ث ഥാ · ج ജീം · ح ഹാ · خ ഖാ · د ദാൽ ·
ذ ധാൽ · ر റാ · ز സാ · س സീൻ · ش ശീൻ · ص സ്വാദ് · ض ളാദ് · ط ത്വാ · ظ ളാ · ع ഐൻ · غ ഗൈൻ · ف ഫാ ·
ق ഖാഫ് · ك കാഫ് · ل ലാം · م മീം · ن നൂൻ · ه ഹാ · و വാവ് · ي യാ · ء ഹംസ · ة താ മർബൂത്വ · ى അലിഫ്
മഖ്സ്വൂറ. ح and ه are both ഹാ: always put the Arabic letter beside it. ذ is ധാൽ so it never reads as ദാൽ.
Rule names: Noon / Meem Sakinah നൂൻ സാകിൻ / മീം സാകിൻ (adjective: സാകിനായ) · Laam Shamsiyyah /
Qamariyyah ലാം ശംസിയ്യ / ഖമരിയ്യ (sun / moon letters ശംസിയ്യ / ഖമരിയ്യ അക്ഷരങ്ങൾ).

## Honorifics and recurring words
"(peace be upon him)" or "(peace and blessings be upon him)" after the Prophet: (സ്വല്ലല്ലാഹു അലൈഹി
വസല്ലം) · after another prophet: (അലൈഹിസ്സലാം) · "may Allah be pleased with him / her / them":
(റളിയല്ലാഹു അൻഹു / അൻഹാ / അൻഹും) · Assalamu Alaikum അസ്സലാമു അലൈക്കും · Alhamdulillah അൽഹംദുലില്ലാഹ്.

## Fixed terms (every batch uses exactly these)
exit / point of articulation മഖ്റജ് · leen (letters) ലീൻ അക്ഷരങ്ങൾ · hamzah ഹംസ · doubled (with shaddah)
ശദ്ദുള്ള · hum (ghunnah) ഗുന്ന · bounce (qalqalah) ഖൽഖല (the bounce ഇളക്കം, it bounces ഇളകുന്നു; echo
പ്രതിധ്വനി) · dagger alif ചെറിയ അലിഫ് · read on / joined ചേർത്ത് ഓതുമ്പോൾ · at a stop നിർത്തുമ്പോൾ ·
noon sakin നൂൻ സാകിൻ · shafawi ശഫവി · shiddah ശിദ്ദ · jahr ജഹ്ർ · silah സ്വില (സുഗ്റാ / കുബ്റാ) · sakt
സക്ത് · basmalah ബിസ്മി · tashkeel ഹറകത്തുകൾ · level തലം · tier ഘട്ടം · ladder ഏണി · rank (on the ladder)
പടി · reading (romanised pronunciation) ഉച്ചാരണം (a qiraah: ഖിറാഅത്ത്) · the cutting hamza ഹംസതുൽ ഖത്വ്അ് ·
madd names: മദ്ദ് മുത്തസ്വിൽ, മുൻഫസ്വിൽ, ലാസിം, ബദൽ, ആരിള്, ത്വബീഈ (each after മദ്ദ്) · isti‘la ഇസ്തിഅ്ലാഅ് ·
itbaq ഇത്വ്ബാഖ് · path (tariq) ത്വരീഖ് · mushaddad / mukhaffaf മുശദ്ദദ് / മുഖഫ്ഫഫ് · permanent / temporary
sukoon സ്ഥിരമായ / താൽക്കാലിക സുകൂൻ · madd letter മദ്ദ് അക്ഷരം · definite article അലിഫ് ലാം (ال) · pronoun ha
സർവനാമ ഹാ · round / upright zero വട്ടപ്പൂജ്യം / കുത്തനെയുള്ള പൂജ്യം · dots പുള്ളികൾ · throat തൊണ്ട ·
tongue നാവ് · the app's Quran reader ഖുർആൻ റീഡർ · Missed നഷ്ടമായി · Sound-Alikes സമാന ശബ്ദങ്ങൾ · Quran Words
ഖുർആൻ വാക്കുകൾ · rule നിയമം · ruling വിധി · lesson പാഠം · chapter (course or hadith) അധ്യായം ·
course കോഴ്സ് · practice പരിശീലനം · word വാക്ക് · session സെഷൻ · syllable പദാംശം · madhhab മദ്ഹബ് ·
noun നാമം · verb ക്രിയ · particle അവ്യയം · pronoun സർവനാമം. Word-grammar labels must all differ:
nominative മർഫൂഅ് · accusative മൻസ്വൂബ് · genitive മജ്റൂർ · past / present tense ഭൂതകാലം / വർത്തമാനകാലം ·
command ആജ്ഞ · definite / indefinite മഅ്രിഫ / നകിറ · active / passive participle ഇസ്മുൽ ഫാഇൽ / ഇസ്മുൽ
മഫ്ഊൽ · verbal noun മസ്വ്ദർ · jussive / subjunctive മജ്സൂം വർത്തമാനം / മൻസ്വൂബ് വർത്തമാനം.
Names (drop al-, ad-, an- before a bare name): "ibn" in a full name ഇബ്നു (never ബിൻ) · Ibn al-Jazari
ഇബ്നുൽ ജസരി · ash-Shatibiyyah ശാത്വിബിയ്യ · "Hafs an Asim" ആസ്വിമിൽ നിന്നുള്ള ഹഫ്സ്, one pattern for every
riwayah (നാഫിഇൽ നിന്നുള്ള വർശ്; inflect the last word) · a riwayah's narrator റാവി · Hafs ഹഫ്സ് · Asim ആസ്വിം ·
Warsh വർശ് · Qalun ഖാലൂൻ · Nafi നാഫിഅ് · Shu'bah ശുഅ്ബ · Hamzah ഹംസ · Khalaf ഖലഫ് · Khalaf al-Ashir ഖലഫുൽ
ആശിർ · al-Bazzi ബസ്സി · Qunbul ഖുൻബുൽ · Ibn Kathir ഇബ്നു കസീർ · ad-Duri ദൂരി · al-Kisai കിസാഈ · Abul
Harith അബുൽ ഹാരിസ് · Darimi ദാരിമി · books: സ്വഹീഹുൽ ബുഖാരി, സ്വഹീഹ് മുസ്ലിം, സുനൻ അബൂദാവൂദ്, ജാമിഅ്
തിർമിദി, സുനൻ നസാഈ, സുനൻ ഇബ്നു മാജ, സുനൻ ദാരിമി, മുവത്വ മാലിക്, മുസ്നദ് അഹ്മദ് · the developer
Abubakr Elmallah അബൂബക്ർ എൽമല്ലാഹ്.
Alert tones: Echo പ്രതിധ്വനി · Takbir തക്ബീർ · Chime മണിനാദം · Ring റിംഗ് · Alarm അലാറം · Serene ശാന്തം.
Widget abbreviations: FJR സുബ്ഹ് · SHQ ഉദയം · DHR ളുഹ്ർ · ASR അസ്ർ ·
MGB മഗ്രിബ് · ISH ഇശാ · DUH ളുഹാ · JUM ജുമുഅ.

Added during the run (binding): fathatan / kasratan / dammatan രണ്ട് ഫത്ഹ് / രണ്ട് കസ്റ് / രണ്ട് ളമ്മ് · idgham's merge ലയനം (noun), ലയിക്കുന്നു (verb) · teacher (of the Quran) ഉസ്താദ് · a case ending is never glued to a bare Arabic letter either: "ب എന്നതിന് മുമ്പ്", "ر എന്ന അക്ഷരത്തിൽ".
