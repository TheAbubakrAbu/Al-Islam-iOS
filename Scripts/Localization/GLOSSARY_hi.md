# Hindi (hi): as Indian Muslims and Apple's Hindi iOS write it

For Muslims in India first (and Hindi readers anywhere): standard Hindi in Devanagari, in the register Indian
Muslims read and write. Everyday words are plain, common Hindi (neither heavy Sanskrit nor heavy Persian);
every ISLAMIC word is the one Indian Muslims actually use, the same word Urdu uses, written in Devanagari
with the nukta (नमाज़, रोज़ा, वुज़ू, क़ुरआन, अज़ान, ज़िक्र), never a Sanskrit substitute (not प्रार्थना for
salah, not उपवास for sawm, not ईश्वर or भगवान for Allah). The `urdu` field on
each item shows the app's Urdu: follow its Islamic terms.

Address the reader with "आप" and polite imperatives (टैप करें, चुनें, चालू करें, खोलें), warm and clear;
buttons short, as Apple's Hindi writes them. Tech words Indian users read in English on their phones are
written in Devanagari as loanwords (सेटिंग्ज़, विजेट, ऐप, डाउनलोड, बैकअप), not coined Sanskrit.

**Spelling:** write the nukta on Perso-Arabic sounds: क़ ख़ ग़ ज़ फ़ (क़ुरआन, ख़त्म, ग़ुन्ना, ज़िक्र, फ़ज्र). Use the
base letter plus the nukta sign (U+093C), not the precomposed letters U+0958-U+095F; a python script that
writes your file can normalise with `unicodedata.normalize("NFC", text)` on the Hindi only (never on the
Arabic runs). Anusvara/chandrabindu as standard Hindi writes them (में, हैं, दुआएँ, यहाँ).
**Punctuation:** a sentence ends with the purna viram । (never a Latin full stop after Hindi; abbreviations
like डॉ. keep their dot); ? and ! as usual; “ ” for quotes. Western digits 0-9 (brief, rule 5).
**Placeholders:** `%@` can be any word, so do not make an adjective or verb agree with it; a postposition
after it is fine when it does not depend on its gender ("%@ में", "%@ से"), and का/की/के agree with the noun
that FOLLOWS, which you control. Otherwise rephrase ("सूरह: %@").

## Apple and interface words
Settings सेटिंग्ज़ · Cancel रद्द करें · Done हो गया · OK ठीक है · Close बंद करें · Back वापस · Next अगला ·
Previous पिछला · Save सहेजें · Delete डिलीट करें · Remove हटाएँ · Edit संपादित करें · Share शेयर करें ·
Copy कॉपी करें · Search खोजें · Reset रीसेट करें · Turn On / Off चालू करें / बंद करें · On / Off चालू / बंद ·
Allow अनुमति दें · Don't Allow अनुमति न दें · Notifications सूचनाएँ · Location लोकेशन ·
Location Services लोकेशन सेवाएँ · Widget विजेट · Lock Screen लॉक स्क्रीन · Home Screen होम स्क्रीन ·
Control Center कंट्रोल सेंटर · Shortcuts शॉर्टकट · Focus फ़ोकस · Live Activities लाइव ऐक्टिविटी ·
Play चलाएँ (recitation: सुनें where it reads better) · Pause रोकें · Stop बंद करें · Repeat दोहराएँ ·
Download डाउनलोड करें · Downloaded डाउनलोड हो गया · Favorites पसंदीदा · Language भाषा ·
Appearance दिखावट · Light / Dark लाइट / डार्क · Sound साउंड · Haptics हैप्टिक्स · Font फ़ॉन्ट ·
Text Size टेक्स्ट का आकार · Learn More और जानें · More और · Tip टिप · Tips & Tricks टिप्स और ट्रिक्स ·
Bookmarks बुकमार्क · Notes नोट्स · History इतिहास · Backup बैकअप · Restore रीस्टोर करें ·
Merge मिलाएँ · Import / Export इंपोर्ट / एक्सपोर्ट · Tab टैब · Grid ग्रिड · List सूची · Ask AI AI से पूछें ·
app ऐप · tap टैप करें · touch and hold दबाकर रखें · swipe स्वाइप करें · sheet (an iOS bottom sheet) शीट
(never पेज or पृष्ठ: a page is a mushaf page) · Streak लगातार दिन · Custom कस्टम · Always हमेशा ·
Dark Mode डार्क मोड · Accent Color एक्सेंट रंग · Highlight हाइलाइट.

## The app's names and tabs
Al-Islam, Al-Adhan, Al-Quran: unchanged, Latin, in every sentence. Tabs: Islam "इस्लाम" · Quran "क़ुरआन" ·
Hadith "हदीस" · Adhan "अज़ान" · Settings "सेटिंग्ज़". "Al-Hadith" (a screen title) stays "Al-Hadith".

## Islamic terms (Indian Muslim usage)
the Quran क़ुरआन (क़ुरआन मजीद / क़ुरआन पाक in formal mentions) · surah सूरह (pl. सूरतें; Makki / Madani: मक्की /
मदनी) · ayah आयत (pl. आयतें) · juz पारा · hizb हिज़्ब · page (of the mushaf) पृष्ठ · mushaf मुसहफ़ ·
recitation तिलावत · reciter क़ारी · translation अनुवाद · transliteration लिप्यंतरण · tafsir तफ़सीर ·
tajweed तजवीद · qiraat क़िराअत · riwayah रिवायत · hadith हदीस (pl. हदीसें) · grades: सहीह, हसन, ज़ईफ़ ·
chain (isnad) सनद · narrator रावी · Companions सहाबा · the Prophet ﷺ नबी ﷺ / रसूलुल्लाह ﷺ (Muhammad ﷺ
मुहम्मद ﷺ) · Allah अल्लाह · prayer नमाज़ (where the English says "salah": सलात) · adhan अज़ान ·
iqamah इक़ामत · qibla क़िबला · dua दुआ (pl. दुआएँ) · dhikr ज़िक्र · tasbih तस्बीह · sunnah सुन्नत · fard फ़र्ज़ ·
fiqh फ़िक़्ह · aqeedah अक़ीदा · fasting रोज़ा · zakah ज़कात · hajj हज · umrah उमरा · mosque मस्जिद ·
Friday prayer जुमे की नमाज़ · Eid ईद (ईद-उल-फ़ित्र, ईद-उल-अज़हा) · Ramadan रमज़ान · Hijri हिजरी ·
the 99 Names अल्लाह के 99 नाम (अस्मा-उल-हुस्ना) · khatm ख़त्म · revision दोहराई · memorise याद करना
(हिफ़्ज़ for the hafiz's memorisation) · night prayer रात की नमाज़ · witr वित्र · wudu वुज़ू · ghusl ग़ुस्ल ·
Torah तौरात · revelation (wahy) वह्य · revert / new Muslim नव-मुस्लिम.
Prayer names: फ़ज्र · सूर्योदय · ज़ुहर · अस्र · मग़रिब · इशा · जुमा · चाश्त (Duha) · तहज्जुद (with
"prayer": फ़ज्र की नमाज़, ज़ुहर की नमाज़ ...). Calculation methods keep their proper names, institutions
translated if usual (Muslim World League = मुस्लिम वर्ल्ड लीग). Madhabs: हनफ़ी, शाफ़ई, मालिकी, हंबली.

## Tajweed and Arabic letters (as taught to Indian Muslims, Noorani Qaida terms)
harakat हरकतें · fatha ज़बर · kasra ज़ेर · damma पेश · sukoon सुकून (the sign: जज़्म) · shaddah तशदीद ·
tanween तनवीन (दो ज़बर / दो ज़ेर / दो पेश) · madd मद · ghunnah ग़ुन्ना · qalqalah क़लक़ला · idgham इदग़ाम ·
ikhfa इख़फ़ा · iqlab इक़लाब · izhar इज़हार · tafkheem पुर (तफ़ख़ीम) · tarqeeq बारीक (तरक़ीक़) · waqf वक़्फ़ ·
wasl वस्ल · hamzat al-wasl हमज़ा-ए-वस्ल · makhraj मख़रज (pl. मख़ारिज) · sifaat सिफ़ात · heavy / light letters
पुर / बारीक हुरूफ़ · letter (of the Arabic alphabet) हर्फ़ (pl. हुरूफ़) · count (of madd length) हरकत
("2 हरकत").
Surah names stay in the app's Latin spelling (brief, rule 7). Letter names in running prose (rule 7):
ا अलिफ़ · ب बा · ت ता · ث सा · ج जीम · ح हा (बड़ी हा) · خ ख़ा · د दाल · ذ ज़ाल · ر रा · ز ज़ा · س सीन ·
ش शीन · ص स्वाद · ض ज़्वाद · ط तोय · ظ ज़ोय · ع ऐन · غ ग़ैन · ف फ़ा · ق क़ाफ़ · ك काफ़ · ل लाम · م मीम ·
ن नून · ه हा (छोटी हा) · و वाव · ي या · ء हमज़ा · ة गोल ता (ता मरबूता) · ى अलिफ़ मक़सूरा.
Tajweed RULE names built on a letter: Noon Sakinah नून साकिन, Meem Sakinah मीम साकिन, Tanween तनवीन,
Laam Shamsiyyah / Qamariyyah लाम शम्सी / क़मरी (sun / moon letters शम्सी / क़मरी हुरूफ़).

## Honorifics and recurring words
"(peace be upon him)" after the Prophet: (सल्लल्लाहु अलैहि वसल्लम) · after another prophet:
(अलैहिस्सलाम) · "may Allah be pleased with him / her / them": (रज़ियल्लाहु अन्हु / अन्हा / अन्हुम) ·
Assalamu Alaikum: अस्सलामु अलैकुम.

## Fixed terms (every batch uses exactly these)
exit / point of articulation मख़रज · leen (letters) लीन (हुरूफ़-ए-लीन) · hamzah हमज़ा · doubled (with
shaddah) मुशद्दद · hum (ghunnah) ग़ुन्ना · bounce (qalqalah) क़लक़ला (the bounce: उछाल) · dagger alif खड़ा
ज़बर · read on / joined मिलाकर पढ़ना (वस्ल) · at a stop रुककर (वक़्फ़ में) · noon sakin नून साकिन · shafawi शफ़वी ·
shiddah शिद्दत · jahr जह्र · silah सिला (सिला सुग़रा / कुबरा) · sakt सक्ता · basmalah बिस्मिल्लाह ·
tashkeel एराब (हरकतें) · level स्तर · tier चरण · ladder सीढ़ी · reading (a romanised pronunciation)
उच्चारण · the cutting hamza हमज़ा-ए-क़त्अ · madd names: मद्दे मुत्तसिल, मद्दे मुनफ़सिल, मद्दे लाज़िम, मद्दे
बदल, मद्दे आरिज़, मद्दे तबई · isti‘la इस्तिअला · path (tariq) तरीक़ · mushaddad / mukhaffaf मुशद्दद / मुख़फ़्फ़फ़ ·
the app's Quran reader क़ुरआन रीडर · Missed छूट गई · Sound-Alikes मिलती-जुलती आवाज़ें · Quran Words
क़ुरआन के शब्द. · particle (grammar) अव्यय · syllable शब्दांश · ग़ुन्ना and the letter names are masculine (ग़ुन्ना होता है, रा पुर होता है) · permanent / temporary sukoon लाज़िमी / आरज़ी सुकून. · rule नियम · ruling हुक्म · lesson सबक़ · chapter अध्याय · course कोर्स · practice अभ्यास · word शब्द · session बैठक · dots नुक़्ते · madd letter हर्फ़-ए-मद · definite article हर्फ़-ए-तारीफ़ · pronoun ha हा-ए-ज़मीर · madhhab मसलक · grammatical gender: तनवीन, तशदीद, हरकत feminine · the developer's name अबूबक्र एलमल्लाह. · the letter ي named in prose: या (ي) (या alone also means "or"); "or" between letter names: अथवा · rank (ghunnah ladder) दर्जा. · throat हल्क़ · tongue ज़बान · ash-Shatibiyyah शातिबिय्या.
