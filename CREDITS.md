# Credits

**Al-Islam** was created by **Abubakr Elmallah** (أبوبكر الملاح), who was a 17-year-old high school student when this app was published on **July 26, 2023**.

Website: <https://abubakrelmallah.com/>

<a href="https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone">
  <img src="Logo.jpg" alt="Logo" width="120" style="border-radius:10px;"/>
</a>

## The story

This app was inspired by my desire to help new reverts and non-Muslims learn about Islam and easily access the Quran and prayer times. I'm deeply grateful to my parents for instilling in me a love for the faith (may Allah reward them).

App Store: <https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655>

## Credits

### Prayer times

- **Adhan calculations** (fully offline, on-device) - **Batoul Apps** - <https://github.com/batoulapps/adhan-swift>
- **Adhan sounds** - **Omar Al-Ejel** - <https://github.com/oalejel/Athan-Utility>
- **"Serene" adhan** - **"Beautiful adhan" by Adam-synagda**, CC0 1.0 (public domain dedication), via Wikimedia Commons - <https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg>. Trimmed and loudness-normalized from the original.
- **"Aaqib Azeez" adhan** - **Aaqib Azeez**, CC BY-SA 4.0, via Wikimedia Commons - <https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3> - license: <https://creativecommons.org/licenses/by-sa/4.0/>. Trimmed and loudness-normalized from the original; the derived audio clips remain under CC BY-SA 4.0.
- **"Takbir" alert tone** - the opening takbir pair of the **Aaqib Azeez** adhan above, CC BY-SA 4.0, via Wikimedia Commons - <https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3> - license: <https://creativecommons.org/licenses/by-sa/4.0/>. Trimmed and loudness-normalized from the original; the derived clip remains under CC BY-SA 4.0.
- **"Chime" alert tone** - "[UI Sound] Approval - High Pitched Bell Synth" by GabFitzgerald, CC0 1.0 (public domain dedication), via Freesound - <https://freesound.org/people/GabFitzgerald/sounds/625174/> - license: <https://creativecommons.org/publicdomain/zero/1.0/>. Trimmed, repeated, and loudness-normalized from the original.
- **"Ring" alert tone** - "Signal-Ring 1" by Vendarro, CC0 1.0 (public domain dedication), via Freesound - <https://freesound.org/people/Vendarro/sounds/399315/> - license: <https://creativecommons.org/publicdomain/zero/1.0/>. Trimmed, repeated, and loudness-normalized from the original.
- **"Alarm" alert tone** - "Alarm clock beep" by Kesu, CC0 1.0 (public domain dedication), via Freesound - <https://freesound.org/people/Kesu/sounds/182351/> - license: <https://creativecommons.org/publicdomain/zero/1.0/>. Trimmed, repeated, and loudness-normalized from the original.
- **Moon phase algorithm** (the sky card and Moon widgets) - **SunCalc by Vladimir Agafonkin** (low-precision lunar theory from Meeus' *Astronomical Algorithms*) - <https://github.com/mourner/suncalc>

### Quran

- **English transliteration of the Quran** - the **English Transliteration (Tajweed)** dataset of **QUL (Tarteel)**, written the way each ayah is recited; the app's original transliteration came from **Risan Bagja Pradana**'s quran-json - <https://qul.tarteel.ai/resources/transliteration> · <https://github.com/risan/quran-json>
- **English Saheeh International translation** - **Global Quran** - <https://globalquran.com/download/data/>
- **All Quranic Arabic text and all qiraat/riwayaat data** - **quran-data-kfgqpc (KFGQPC)** - <https://github.com/thetruetruth/quran-data-kfgqpc>
- **Printed mushaf facsimiles (the in-app PDF reader) and the beta qiraat text for the twelve riwayat KFGQPC has never published digitally** - **Islamweb** - <https://www.islamweb.net>. Twenty complete mushafs, one per riwayah, 604 pages each on the Madani page division.
- **Reference for the qiraat guide's profiles of the ten imams and twenty narrators** - **QiraatHub** - <https://qiraathub.com/>. The profile pages in the app are written for it; QiraatHub is the companion reference each page links out to.
- **Uthmani Quran fonts (the Hafs face, and the Warsh face behind the Maghribi script style)** - **King Fahad Complex (KFGQPC)** - <https://qul.tarteel.ai/resources/font/245> The `Uthmani-NoStack.ttf` twin the non-Quran screens read in is the same Hafs face with its letter-over-haa stacking rules switched off (`Scripts/build_nostack_fonts.py`).
- **Indopak Nastaleeq Quran font** - **Ayman Siddiqui and R. Siddiqua** - <https://qul.tarteel.ai/resources/font/242>
- **Kufi Quran font (Noto Kufi Arabic)** - **The Noto Project Authors (Google)**, SIL Open Font License 1.1 (`Resources/Fonts/Kufi-OFL.txt`) - <https://fonts.google.com/noto/specimen/Noto+Kufi+Arabic>
- **Hijazi Quran font (Al-Islam Hijazi, adapted from hijazifont)** - **Khalid Alabdullah**, CC BY-NC 4.0 (`Resources/Fonts/Hijazi-CC-BY-NC.txt`), used with the author's permission. The tashkeel, annotation marks, hamza, digits and mark positioning were added by this project (`Scripts/build_hijazi_font.py`) in three mark styles: light marks, bold marks, and dot vowels after the earliest vocalised mushafs; the `Hijazi*-NoStack.ttf` twins used outside the Quran only switch off the stacking rule - <https://github.com/khalidalabdullah/hijazifont>
- **Surah (full) Quran recitations** - **MP3 Quran** - <https://mp3quran.net/eng>
- **Ayah-by-ayah Quran recitations** - **Al Quran** - <https://alquran.cloud/cdn>
- **Additional ayah-by-ayah Quran recitations** - **EveryAyah** - <https://everyayah.com/>
- **Ayah audio timings (offline ayah playback)** - **QDC audio API by Quran.com (Quran Foundation)** - <https://api-docs.quran.foundation/>
- **Word-by-word English meanings (tap a word in the reader)** - **QDC content API by Quran.com (Quran Foundation)**, whose per-word glosses derive from the **Quranic Arabic Corpus** (Kais Dukes) - <https://api-docs.quran.foundation/> · <https://corpus.quran.com/>
- **The word-by-word reader itself** - the idea, and the assembled gloss corpus this app's pack was built from, come from **Tilawa**, by my friend **Jamil Hammoudeh** - <https://github.com/jamilhammoudeh/quran-app> (private at the time of writing)
- **Similar Ayahs** - verified matches from **qurani.ai**'s similar-ayah corpus; further phrase-overlap matches generated by **Tilawa**'s matcher (built on the **Quranic Arabic Corpus** morphology) - <https://qurani.ai/> · <https://corpus.quran.com/>
- **Browse by Theme** - the **Quran Semantic Annotation Corpus (QSAC)** by Ahmad Bilal (CC BY 4.0) - <https://github.com/dev-ahmadbilal/quran-semantic-annotation-corpus>
- **Surah outlines ("Outline" in About this Surah)** - **Quranpedia** - <https://quranpedia.net/>
- **Tajweed Lessons (structured course)** - curriculum written by **Jamil Hammoudeh** for **Tilawa**, ported with his permission
- **English Quran translation comparison API** - **Al Quran Cloud** - <https://alquran.cloud/api>
- **English Tafsir API (Ibn Kathir, Maarif Ul Quran, Tazkirul Quran)** - **Quran API Pages** - <https://quranapi.pages.dev/>
- **Arabic Tafsirs (Ibn Kathir, al-Tabari, as-Sa'di)** - **Tafsir API by spa5k (data from QUL / Tarteel)** - <https://github.com/spa5k/tafsir_api>
- **Surah Info** - **Quran.com (Quran Foundation)** - <https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/get-chapter-info/>
- **Thematic topics (the topic trees behind Browse by Theme)** - **The Clear Quran** by Dr. Mustafa Khattab - <https://theclearquran.org/>
- **Quranic concepts (named entities and their relations)** - the **Quranic Arabic Corpus ontology** (Kais Dukes) - <https://corpus.quran.com/ontology.jsp>
- **Topic index, passage themes and the mushaf divisions (hizb, ruku, manzil)** - **QUL (Tarteel)** - <https://qul.tarteel.ai/>
- **Repeated phrases (Mutashabihat), for memorisation** - **QUL (Tarteel)** - <https://qul.tarteel.ai/resources/mutashabihat>
- **Roots and dictionary forms of every word** - the **Quranic Arabic Corpus** (Kais Dukes) - <https://corpus.quran.com/>
- **Which of the Ten reads which form (the qiraat matrix)** - **Quran.com (Quran Foundation)** - <https://quran.com/1:4/qiraat>
- **Word of the Day** - curation and glosses by **Tilawa**, by my friend **Jamil Hammoudeh**, with his permission; the occurrences are derived from the Hafs text - <https://github.com/jamilhammoudeh/quran-app>
- **Qiraat Explorer and the place index** - **Tilawa**, by **Jamil Hammoudeh**, with his permission, over Quran.com's matrix - <https://github.com/jamilhammoudeh/quran-app>
- **Theme wash and the share backdrops** - **Tilawa**, by **Jamil Hammoudeh**, with his permission - <https://github.com/jamilhammoudeh/quran-app>
- **Ranked search lanes (typo correction and skeleton matching)** - **Tilawa**, by **Jamil Hammoudeh**, with his permission - <https://github.com/jamilhammoudeh/quran-app>
- **Reminder of the Day, the Names in depth, hadith topics and the qiraat clips** - **Tilawa**, by **Jamil Hammoudeh**, with his permission - <https://github.com/jamilhammoudeh/quran-app>

### Hadith

- **Hadith collections (all 17 books)** - **hadith-json by Ahmed Baset** - <https://github.com/AhmedBaset/hadith-json>
- **Hadith text repairs, scholar gradings, and standard sunnah.com numbering** - restored and content-matched from two independent scrapes: **fawazahmed0/hadith-api** (<https://github.com/fawazahmed0/hadith-api>) and **CheeseWithSauce/HadithsJSONFormat** (<https://github.com/CheeseWithSauce/HadithsJSONFormat>), all ultimately from **sunnah.com** (<https://sunnah.com>). The gradings quote the published verdicts of Al-Albani, Zubair Ali Zai, Ahmad Muhammad Shakir, Shuaib Al Arnaut, the Darussalam editors, and others; where scholars differ, every verdict is shown.

### Islam

- **99 Names of Allah** - **MyIslam** - <https://myislam.org/99-names-of-allah/>
- **Hisn al-Muslim (Fortress of the Muslim)** - texts, transliterations, translations and references from the Dhikr API of **islamic.app**; the recitations stream from **hisnmuslim.com**; the library came to the app from **Tilawa**, by my friend **Jamil Hammoudeh**, with his permission - <https://www.hisnmuslim.com/>
- **Miracles of the Quran (202 articles)** - **miracles-of-quran.com**, whose author waived rights on the site's own prose; the illustrations stream from **Tilawa**'s copy, by **Jamil Hammoudeh**, with his permission. Third-party excerpts inside the articles are kept short and attributed to their own sources - <https://www.miracles-of-quran.com/>
- **Islam articles further reading** - **IslamQA** - <https://islamqa.info/en>. The articles themselves are written for this app and cite the classical works by name; IslamQA is the answer each one links out to.
- **Hadith Encyclopedia (the explained hadith behind the topic pages)** - **hadeethenc.com** - <https://hadeethenc.com/>
- **Islamic Journal** - **Tilawa**, by **Jamil Hammoudeh**, with his permission - <https://github.com/jamilhammoudeh/quran-app>

## Apps by Abubakr Elmallah

- [Al-Adhan | Prayer Times](https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493)
- [Al-Islam | Islamic Pillars](https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655)
- [Al-Quran | Beginner Quran](https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373)
- [Aurebesh Translator](https://apps.apple.com/us/app/aurebesh-translator/id6670201513)
- [Datapad | Aurebesh Translator](https://apps.apple.com/us/app/datapad-aurebesh-translator/id6450498054)

## A Note on Intent

This app is offered as *sadaqah jariyah*, a contribution for the benefit of the Muslim community and anyone building tools to pray on time and learn about Islam, and access the Quran. If it helps you, please keep the chain of attribution intact and consider contributing improvements back.
