# App Store Turkish Listing

The **Turkish** localization of the App Store listing for **Al-Islam | Islamic Pillars**. In App Store Connect,
add the Turkish localization, then fill Name and Subtitle under App Information and the other four fields on
the version page. Screenshots can stay English: App Store Connect shows the primary language's screenshots for
a localization that has none of its own.
People whose device is set to Turkish see this listing instead of the English one. In the Turkish interface the
app keeps its Latin name, Al-Islam (the home-screen name too), and its tabs are Ezan, Kur'an, Hadis, İslam and
Ayarlar; the listing uses the same words.

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
  file, not the store). Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Turkish Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Turkish as Apple's own Turkish pages write it**, addressing the reader with the polite "siz" (okuyun,
  dokunun, indirin), with Diyanet terminology (namaz vakitleri, kıble, ezan, sure, ayet, cüz, tecvid, hatim,
  meal, kâri) and the respectful register (Kur'an-ı Kerim, Peygamberimiz Hz. Muhammed). The honorific is always
  spelled out, "(sallallahu aleyhi ve sellem)": App Store Connect rejects the one-glyph ligature (U+FDFA) as an
  invalid character. Feature names are the labels the app shows (the Turkish `labels.json` and catalog, see
  the glossary below).
- **Case endings after an apostrophe** on the app's names, Apple's products and the feature labels, with
  vowel harmony: Al-Islam'ı, Al-Islam'da, Kıraat Gezgini'nde, Apple Watch'ta, Ayarlar'da. The label itself
  never changes.
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, a comma, a semicolon or a new sentence. A
  leading "- " bullet is fine; the English fields use the same.
- **Turkish punctuation and numbers:** Western digits, a dot for thousands (50.000), the suffix on a numeral
  after an apostrophe (60'tan, 50.000'i). A colon before a list is followed by a lowercase word, before a full
  sentence by a capital. No version numbers.
- **Turkish letters always** (ç ğ ı İ ö ş ü), and the circumflex where Diyanet usage keeps it (zekât, kâri,
  Esmâ-ül Hüsnâ, Buhârî). ALL-CAPS headers write İ for i and I for ı (KUR'AN-I KERİM'İN). Plain ASCII
  apostrophes and "quotes" in the store text. The Turkish letters and the circumflex are ordinary Latin
  letters, unlike the ligature above.
- **Brand names stay Latin:** Apple, iCloud, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac,
  CarPlay, iMessage. Apple's own features take Apple's Turkish names: araç takımı (widget), Denetim Merkezi,
  Canlı Etkinlik, Kilitli Ekran, Kestirmeler.
- **Classical books and scholars take their Turkish names** (Kütüb-i Tis'a, Buhârî, Müslim, Tirmizî, İbn
  Kesîr, Taberî, Riyâzü's-Sâlihîn), as the Urdu listing gives them their Urdu ones. The app itself shows its
  Latin transliterations (Sahih al-Bukhari, Ibn Kathir), as it does for surah names (Al-Baqarah), so the
  reference lookup keeps the spelling the search reads, "Bukhari 5", and a tile the app names in Latin keeps
  that label (Hisn al-Muslim).
- **No circumflex in the name, subtitle or keywords:** nobody types one in a search (kari, zekat).
- **Be honest about what is still English:** the in-depth articles of the Islam tab; AI search by meaning,
  which matches English phrases only; and the translations: every Quran translation in the app is English
  (The Clear Quran, Saheeh International and the comparison sheet's editions), and so are the hadith and dua
  translations beside the Arabic. There is no Turkish meal, so the description says "İngilizce meal" and the
  keyword field leaves out meal and türkçe. Siri, unlike in the Urdu listing, does speak Turkish here: the
  app ships Turkish Siri phrases (`tr.lproj/AppShortcuts.strings`).
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md` and `Urdu Listing.md`: when a field changes for a feature,
  change it here too.

## 1. Name

Names are unique across the store, so a bare Al-Islam will not be accepted. The name keeps Al-Islam first,
then a short descriptor after a separator, as the English name does with "|".

```
Al-Islam | Kur'an, Ezan, Hadis
```

**30 / 30 characters.**

The app's three sections as bare words, each a search term of its own, the same shape as the Arabic and
Urdu names. Kur'an keeps the apostrophe Diyanet writes; the keyword field adds kuran without it, as most
people type it.

## 2. Subtitle

```
Namaz Vakitleri, Kıble, Tefsir
```

**30 / 30 characters.**

"Namaz vakitleri" is the app's own label and the Diyanet phrase for prayer times; with the keyword field's
vakti it also answers "namaz vakti", the form most Turkish searches type.

## 3. Promotional Text

Leads with the Turkish interface. Update it with the next release like the English one.

```
Yeni: tamamen Türkçe arayüz; namaz bildirimleri ve Siri komutları da Türkçe. Kur'an, hadis ve namaz vakitleri tek bir ücretsiz uygulamada, reklamsız.
```

**149 / 170 characters.**

## 4. Description

A Turkish rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Turkish ALL-CAPS headers on their own lines. Turkish runs longer than English, so a few words are
trimmed to fit (the opening leaves "on-device" to the CİHAZINIZDA YAPAY ZEKÂ header). Three changes from the
English: the translation is called "İngilizce meal"; the language line in DİLEDİĞİNİZ GİBİ gives the count of
15 interface languages (naming Turkish, English and Arabic), chosen per app in iOS Settings, and says the translations and the articles are English;
and the books and scholars take their Turkish names (see the guidelines).

```
İster ömür boyu Müslüman olun, ister yeni Müslüman olun, ister İslam'ı tanımak isteyin, Al-Islam ibadetinizde yol arkadaşınızdır. Kur'an-ı Kerim, hadis kitapları, tefsir, namaz vakitleri, namaz takibi ve yapay zekâ araması tek bir sade uygulamada: ücretsiz, reklamsız ve gizliliğinize saygılı.

KUR'AN-I KERİM'İN TAMAMI
- Sureye, cüze veya sayfaya göre okuyun: liste ya da mushaf olarak, yatay konumda iki sayfa yan yana.
- Arapça metin, okunuş ve İngilizce meal yan yana; renkli tecvidin renklerini siz seçin.
- Her ayet için tefsir: İngilizce İbn Kesîr, Maarif Ul Quran ve Tazkirul Quran; Arapça İbn Kesîr, Taberî ve Sa'dî, çevrimdışı.
- Kelime Tahlili: Bir kelimeye iki kez dokunun; anlamını, dil bilgisini, kökünü ve geçtiği her yeri görün.
- 60'tan fazla kâri, çevrimdışı indirmeler, Sürekli Tekrarla ve sayfanın, surenin, cüzün ya da Kur'an'ın sonuna dek Ayetten Başlayarak Dinle.
- Hafs ve on kıraatin 19 rivayeti daha, Kıraat Gezgini'nde yan yana karşılaştırmalı.
- Benzer Ayetler, Konuya Göre Göz At, Günün Kelimesi, yer imleri ve notlar.

EZBERLEYİN VE TEKRAR EDİN
- Kur'an Planlayıcı: Hatminiz için bitiş tarihi seçin, ezberlediğiniz sureler için de Tekrar planı ekleyin.
- Test Modu, siz dokunana dek metni gizler; ezberden okuyup her ayeti kontrol edin.

BÜYÜK HADİS KİTAPLARI
- Kütüb-i Tis'a (Buhârî, Müslim, Nesâî, Ebû Dâvûd, Tirmizî, İbn Mâce, Muvatta, Dârimî, Müsned), kırk hadis derlemeleri ve Riyâzü's-Sâlihîn gibi klasikler.
- Arapça metin, İngilizce çeviri, râvi zincirleri ve râvi sayfaları, Günün Hadisi, yer imleri ve "Bukhari 5" gibi aramalar.
- Bir kitapta ya da 50.000'i aşkın hadisin tümünde arayın. Hepsi yerleşiktir ve çevrimdışı çalışır.

CİHAZINIZDA YAPAY ZEKÂ
- Kur'an'da ve hadislerde kelimeyle değil anlamla arayın: "patience in hardship" sabır ayetlerini bulur. Bu arama şimdilik İngilizce ifadelerle çalışır.
- Apple Intelligence ile Yapay Zekâya Sor, yalnızca kaynak gösterdiği ayet ve hadislerle yanıt verir, asla fetva vermez.

NAMAZ VAKİTLERİ, KIBLE VE NAMAZ TAKİBİ
- Cihazınızda hesaplanan doğru vakitler, bölgenize önerilen hesaplama yöntemiyle.
- Vakitlerinizin üzerinde canlı bir gökyüzü: yayındaki güneş, gece yıldızlar, gerçek evresinde 3B Ay ve dilerseniz hava durumu.
- Kıble Pusulası, ezan sesleri, ön bildirimler, Yolculuk Modu ve namazı kılana dek hatırlatan Israrlı Hatırlatma Modu.
- Namaz Takibi: Her namazı tek dokunuşla işaretleyin; seriler, Kusursuz Günler ve renkli bir takvimle.
- Namaz vakti ve Seçilen Ayet araç takımları, Denetim Merkezi denetimleri, Ramazan Canlı Etkinliği ve Apple Watch.

GÜNLÜK İBADET VE ÖĞRENME
- Bugün: günün ayeti, hadisi, duası ve Allah'ın bir ismi; Günün Öğüdü kartı ve Sünnet Hatırlatıcıları.
- Kaynakları ve sesleriyle zikirler, Hisn al-Muslim ve dua derlemeleri; Tesbih Sayacı ve İslami Günlük.
- Ayrıntılarıyla Esmâ-ül Hüsnâ, Kur'an Mucizeleri, İslam'ın İspatı ve Hadis İlimleri.
- 21 seviyeli Okuma Testi ile Arap alfabesini, 58 dersli Tecvid Kursu ve Tecvid Testi ile tecvidi öğrenin.
- Nasıl Yapılır Rehberleri, İslam'ın ve imanın şartları, Zekât Hesaplayıcı, Miras Hesaplayıcı, Hicri Takvim, Cami Bulucu ve Helal Yemek Bulucu.

DİLEDİĞİNİZ GİBİ
- Arayüz Türkçe, İngilizce, Arapça dahil 15 dilde: iOS Ayarlar'da uygulama için seçtiğiniz dil. Meal, hadis ve dua çevirileri ile İslam sekmesindeki makaleler İngilizcedir.
- Basit Mod yalnızca temel özellikleri gösterir; dilediğiniz zaman Tam moda geçin.
- Adlandırdığınız profilleri iCloud'unuza yedekleyin, her cihazda geri yükleyin.
- Metin boyutları, Arapça yazı tipleri, vurgu ve gökyüzü renkleri, her ayarlar sayfasında da arama.
- iPhone, iPad, Mac ve Apple Watch'ta; ayrıca iMessage için İslami çıkartmalar.

ÜCRETSİZ, REKLAMSIZ VE GİZLİLİĞE SAYGILI
Al-Islam tamamen ücretsizdir. Reklam, hesap, abonelik ve izleme yok: Hiçbir veriniz toplanmaz ya da paylaşılmaz.

Namaz vakitleri, Kur'an-ı Kerim, Peygamberimiz Hz. Muhammed'in (sallallahu aleyhi ve sellem) hadisleri ya da İslam'ı daha iyi anlamak için Al-Islam'ı bugün indirin.
```

**3,979 / 4,000 characters.**

## 5. What's New

The release that adds the Turkish interface; the opening line names the other eleven new languages, since
all twelve ship in one release. Only the new interface is here
so far.

```
Uygulamanın tamamı artık Türkçe: Ezan, Kur'an, Hadis, İslam ve Ayarlar. Endonezce, Malayca, Fransızca, Bengalce, Rusça, Hintçe, Almanca, İspanyolca, Malayalamca, Tamilce ve Felemenkçe arayüz de bu sürümle geldi.

Türkçe arayüz:
- Tüm ekranlar, menüler, ayarlar, bildirimler ve araç takımları Türkçe; iPhone, iPad, Mac ve Apple Watch'ta.
- Sure adları Latin harfleriyle yazılır (Al-Baqarah gibi) ve Türkçe anlamlarıyla gösterilir.
- Vakitler alışık olduğunuz adlarla: Sabah, Güneş, Öğle, İkindi, Akşam ve Yatsı.
- 58 dersli Tecvid Kursu, Tecvidin Temelleri ve Arap Alfabesi dersleri Türkçe.
- Namaz bildirimleri Türkçe gelir.

Dil seçimi:
- Uygulama, iOS Ayarlar'da kendisi için seçtiğiniz dili izler; uygulama ayarlarındaki Dil satırı sizi oraya götürür.
- Dili değiştirdiğinizde bildirimleriniz yeni dilde yeniden planlanır.
- Siri'ye Türkçe seslenin: bir sureyi adıyla ya da numarasıyla açın veya dinleyin, tilavete kaldığınız yerden devam edin, sonraki namazı sorun.
- İslam sekmesindeki ayrıntılı makaleler şimdilik İngilizcedir. Anlama göre arama İngilizce ifadelerle çalışır; Kur'an meali ile hadis ve dua çevirileri İngilizcedir.
```

**1,136 / 4,000 characters.**

**To finish this release:** when the English notes for this version are written in `Whats New.md`, translate
the rest of them and append them below the last line of the block above, under the same headings the English
uses (Kur'an:, Ezan:, Hadis:, İslami Araçlar:, Ayarlar:, Hata düzeltmeleri ve iyileştirmeler:). Keep the
Turkish interface first, and keep the whole field near the English length (2,000 to 2,500 characters).

## 6. Keywords

Written for the name and subtitle above. No word repeats one of theirs (Al, Islam, Kur'an, Ezan, Hadis,
Namaz, Vakitleri, Kıble, Tefsir).

```
kuran,kerim,vakti,takibi,hatim,ezber,tecvid,dua,zikir,tesbih,esma,buhari,sünnet,ramazan,oruç,cami
```

**97 / 100 characters.**

Why these terms:
- **kuran, kerim:** "kuran" as most people type it, without the apostrophe; with kerim, "Kuran-ı Kerim" and
  "Kuran Kerim". If Apple's Turkish search turns out to drop the apostrophe in the name's Kur'an, kuran is
  redundant and the first to swap.
- **vakti:** with the subtitle's namaz and the name's ezan, "namaz vakti" and "ezan vakti", the singular
  forms Turkish searches use most (the subtitle has the plural vakitleri).
- **takibi:** with namaz, the app's own label Namaz Takibi, the English field's `tracker`.
- **hatim, ezber, tecvid:** the Quran Planner's khatm, memorization (Test Mode and the Revision plan, the
  English `hifz`), and the colored tajweed with the 58-lesson course, which is in Turkish.
- **dua, zikir, tesbih, esma:** the dua collections, the adhkar, the tasbih counter and the 99 Names
  ("esmaül hüsna").
- **buhari, sünnet:** Sahih al-Bukhari, as Turkish spells it, and the Sunnah (Sunnah Reminders and the
  Sunnahs of the Prophet).
- **ramazan, oruç, cami:** the Ramadan Live Activity and its season, fasting, and the Masjid Locator.

Left out for room, to rotate in from App Analytics: müslüman, hafız, cüz, sure, ayet, imsakiye, iftar,
elifba, and the ASCII spellings kible and oruc for people who type without Turkish letters. Deliberately
excluded: meal and türkçe ("Kuran meali", "Türkçe meal"), since the app has no Turkish translation of the
Quran.

## Glossary

The Turkish the app shows for the features the listing names (the Turkish `labels.json`, which is binding,
and the catalog). Two marked * are not labels in the app: Canlı Etkinlik and Denetim Merkezi are Apple's own
Turkish names for Live Activities and Control Center.

| English | Turkish |
|---|---|
| Al-Islam (the app), the tabs Adhan, Quran, Hadith, Islam, Settings | Al-Islam, Ezan, Kur'an, Hadis, İslam, Ayarlar (the İslam tab: İslam sekmesi) |
| Simple Mode / Full | Basit Mod / Tam |
| Prayer Times, Prayer Tracker | Namaz Vakitleri, Namaz Takibi |
| Streak, Perfect Days | Seri, Kusursuz Günler |
| Test Mode | Test Modu |
| Quran Planner, Revision | Kur'an Planlayıcı, Tekrar |
| Word Study | Kelime Tahlili |
| Qiraat Explorer | Kıraat Gezgini |
| Traveling Mode | Yolculuk Modu |
| Nagging Mode | Israrlı Hatırlatma Modu |
| Prenotification, Qibla Compass, Adhan Sound | Ön Bildirim, Kıble Pusulası, Ezan Sesi |
| Repeat Forever, Play From Ayah | Sürekli Tekrarla, Ayetten Başlayarak Dinle |
| Similar Ayahs, Browse by Theme, Word of the Day | Benzer Ayetler, Konuya Göre Göz At, Günün Kelimesi |
| Hadith of the Day, Chain of Narrators | Günün Hadisi, Râvi Zinciri |
| Ask AI, Search by meaning | Yapay Zekâya Sor, Anlama göre arayın |
| Chosen Ayah (widget), Widgets | Seçilen Ayet, araç takımları |
| Today, Name of Allah, Reminder of the Day | Bugün, Allah'ın Bir İsmi, Günün Öğüdü |
| Sunnah Reminders, Daily Reminder | Sünnet Hatırlatıcıları, Günlük Hatırlatıcı |
| Transliteration | Okunuş |
| Reading Test, Tajweed Course, Tajweed Test, Tajweed Foundations | Okuma Testi, Tecvid Kursu, Tecvid Testi, Tecvidin Temelleri |
| Arabic Alphabet | Arap Alfabesi |
| 99 Names of Allah, Hisn al-Muslim, Tasbih Counter | Esmâ-ül Hüsnâ, Hisn al-Muslim, Tesbih Sayacı |
| Proving Islam, Miracles of the Quran, The Sciences of Hadith (Islam tab) | İslam'ın İspatı, Kur'an Mucizeleri, Hadis İlimleri |
| Masjid Locator, Halal Food Locator (Islam tab) | Cami Bulucu, Helal Yemek Bulucu |
| Zakah Calculator, Inheritance Calculator | Zekât Hesaplayıcı, Miras Hesaplayıcı |
| Hijri Calendar, Islamic Journal | Hicri Takvim, İslami Günlük |
| How-To Guides, Pillars & Beliefs | Nasıl Yapılır Rehberleri, Şartlar ve İnançlar |
| Language (Settings row), Accent Color, Sky Colors | Dil, Vurgu Rengi, Gökyüzü Renkleri |
| Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha | Sabah, Güneş, Öğle, İkindi, Akşam, Yatsı |
| Live Activity*, Control Center* | Canlı Etkinlik, Denetim Merkezi |
