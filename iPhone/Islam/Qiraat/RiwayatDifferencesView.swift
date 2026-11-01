import SwiftUI

/// How the riwayat differ ON THE PAGE (Abu, 2026-09-29: "mention which riwayahs have hamzas, which
/// don't, which have Madani hamzat al-wasl and which have dots as it, and other differences in
/// qiraat").
///
/// The Qiraat Explorer covers how the readings differ in WORDS. This page covers what a reader sees
/// the moment they switch the Quran tab to another riwayah: the hamzah kept, eased or dropped, the dot
/// that stands for an eased hamzah, the small ṣad against the Madani dot for hamzat al-wasl, the filled and hollow
/// dots of imalah and taqlil, the small waw of silah, and the madd sign. Every spelling below was
/// copied out of the app's own riwayah texts by a script (never retyped), and every count was taken
/// from them: the eight verified texts in Quran-Tajweed-Engine/sources/Qiraat (with Hafs from
/// Quran.json) and the twelve beta texts' v2 candidates, which is why the page says the beta counts
/// are close rather than exact.
///
/// The second half of the page (2026-11-01, Abu: "use tajweed legend and the sorting of them in
/// explaining differences for each riwayah ... put a lot more") goes through each print's COLOR CODE,
/// rule by rule in the Legend's order (`QiraahTajweedStore.ruleOrder`): the prose names the rule and
/// shows a spelling or two, again copied out of the texts by a script (the pack says which word a
/// print colors, the text says how it is written), and a `RiwayahRuleCard` under it lists every print
/// that marks the rule with its color and word count and one live example (RiwayatColorCode.swift).
struct RiwayatDifferencesView: View {
    #if os(iOS)
    /// The color-code cards' data: every print's legend, read once off the main thread. iPhone only;
    /// the packs are the Quran tab's.
    @StateObject private var colorCode = RiwayahColorCodeModel()
    #endif

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: all twenty riwayat share one Uthmanic skeleton. What changes on the page is the marks around it: the hamzah kept, eased or dropped, a dot on the joining alef where Hafs writes a small ṣad, and dots under the letters where a vowel tilts.")
                }

                Section(header: ArticleHeader("ONE SKELETON, DIFFERENT MARKS")) {
                    ArticleParagraph(verbatim: "The Companions wrote the mushaf without dots or vowel signs, and that one consonantal skeleton, the rasm (رَسم), carries every canonical reading. The marks came after them: the vowel dots attributed to Abu al-Aswad ad-Du’ali (d. 69 AH), the dots that tell one letter from another, and later the signs of al-Khalil ibn Ahmad (d. 170 AH) that became today’s harakat. A mushaf printed for a riwayah adds the marks its pronunciation needs, in the conventions of the lands that recite it, which is why two correct mushafs can look different on the same line.")

                    ArticleStatGrid([
                        ArticleStat("20", "riwayat, each with its own printed mushaf"),
                        ArticleStat("10", "qiraat, two riwayat each"),
                        ArticleStat("1", "Uthmanic skeleton under all of them"),
                    ])

                    ArticleParagraph(verbatim: "Below are the differences you will actually see when you switch the Quran tab to another riwayah: the hamzah, the dot that stands in for it, hamzat al-wasl, the dots under letters, the small waw after a meem, and the madd sign. Where the readings differ in a word or a vowel, the Qiraat Explorer in The 10 Qiraat walks through every place, ayah by ayah.")

                    ArticleParagraph(verbatim: "Each print also carries a color code, the legend box at the foot of its pages, and the second half of this page goes through it rule by rule, in the order the app’s Legend lists them.")

                    ArticleDoorRow(door: .article("QiraatView"))
                }

                Section(header: ArticleHeader("THE HAMZAH: PRONOUNCED, EASED, OR DROPPED")) {
                    ArticleParagraph(verbatim: "The hamzah, the catch in the throat written ء, is where the readings differ most often. Arabic itself was divided on it: the people of the Hijaz tended to soften it and the tribes of Najd to pronounce it fully. The canonical readings preserve both, each applying its own rule every time it meets one.")

                    RiwayahSpellingCard(title: "Quran 2:3 (2:2 outside the Kufan count): “they believe”", [
                        RiwayahSpelling("Hafs, Shu’bah, Qalun, ad-Duri, al-Bazzi, Qunbul", arabic: "يُؤۡمِنُونَ", note: "The hamzah pronounced: yu’minūn"),
                        RiwayahSpelling("Warsh, as-Susi, Ibn Wardan, Ibn Jammaz", arabic: "يُومِنُونَ", note: "The quiet hamzah becomes the long vowel before it: yūminūn"),
                    ])

                    ArticleCallout("**Hafs, Shu’bah, Ibn Dhakwan, Rawh, Ishaq, Idris, Abu al-Harith, and ad-Duri from al-Kisa’i.** Hamzah’s two narrators, **Khalaf and Khallad**, belong here too while they read on, but they ease the hamzah when they stop on a word that has one, a chapter of the science in itself.",
                                   title: "Pronounce it almost everywhere", systemImage: "circle.fill")

                    ArticleCallout("**Qalun, ad-Duri, al-Bazzi, Qunbul and Ruways**, and **Hisham** in one of his two ways, soften the second of two hamzahs that meet in one word (tas-hil). Qalun, ad-Duri and Hisham also put a short alef between the two (idkhal). Elsewhere they pronounce the hamzah.",
                                   title: "Ease the second of two", systemImage: "circle.lefthalf.filled")

                    ArticleCallout("**Warsh, as-Susi, Ibn Wardan and Ibn Jammaz** turn a hamzah that carries a sukoon into the long vowel before it (ibdal), in most words, so يُؤۡمِنُونَ is read yūminūn. Warsh goes furthest: he also moves a hamzah’s vowel onto a quiet letter before it and drops the hamzah (naql).",
                                   title: "Soften the quiet hamzah", systemImage: "circle")

                    RiwayahSpellingCard(title: "Quran 2:6 (2:5 outside the Kufan count): “whether you warn them”", [
                        RiwayahSpelling("Hafs, Shu’bah", arabic: "ءَأَنذَرۡتَهُمۡ", note: "Both hamzahs pronounced"),
                        RiwayahSpelling("Qalun, ad-Duri", arabic: "ءَٰا۬نذَرۡتَهُمۡ", note: "The second eased, with a short alef between the two; the dot on the second alef is the eased hamzah"),
                        RiwayahSpelling("al-Bazzi, Qunbul", arabic: "ءَا۬نذَرۡتَهُمُۥ", note: "The second eased, with no alef between; the small waw is Ibn Kathir’s silah"),
                        RiwayahSpelling("Warsh", arabic: "ءَآنذَرۡتَهُمُۥٓ", note: "The second made a long vowel; the meem is joined to the hamzah that follows it"),
                    ])

                    RiwayahSpellingCard(title: "Quran 23:1: “successful indeed”", [
                        RiwayahSpelling("Hafs and most readings", arabic: "قَدۡ أَفۡلَحَ", note: "qad aflaḥa"),
                        RiwayahSpelling("Warsh", arabic: "قَدَ اَفۡلَحَ", note: "The hamzah’s vowel moves onto the dal and the hamzah drops (naql): qadaflaḥa"),
                    ])

                    ArticleParagraph(verbatim: "How many hamzah signs each text carries (every ء, أ, إ, ؤ, ئ and seated hamzah):")

                    ArticleStatGrid([
                        ArticleStat("19,170", "Hafs"),
                        ArticleStat("19,043", "Qalun"),
                        ArticleStat("17,869", "as-Susi"),
                        ArticleStat("14,546", "Warsh"),
                    ])

                    ArticleParagraph(verbatim: "Qalun sits within 127 of Hafs. As-Susi writes about 1,300 fewer, Ibn Wardan and Ibn Jammaz, who share Abu Ja’far’s rule, about 1,500 fewer, and Warsh about 4,600 fewer, the most of any riwayah.")
                }

                Section(header: ArticleHeader("WHERE A DOT STANDS FOR THE HAMZAH")) {
                    ArticleParagraph(verbatim: "An eased hamzah is pronounced between a hamzah and the long vowel it leans towards, and the mushafs of the readings that ease it do not draw a hamzah there at all: a small dot takes its place. That is the dot on the second alef in Qalun’s and ad-Duri’s spelling of 2:6 above, and in al-Bazzi’s.")

                    ArticleParagraph(verbatim: "Hafs eases a hamzah only once in the whole Quran, and his mushaf marks it the same way:")

                    RiwayahSpellingCard(title: "Quran 41:44: “a foreign one?”", [
                        RiwayahSpelling("Hafs", arabic: "ءَا۬عۡجَمِيّٞ", note: "The second hamzah eased, drawn as a dot"),
                    ])
                }

                Section(header: ArticleHeader("HAMZAT AL-WASL: THE ṢAD OR THE DOT")) {
                    ArticleParagraph(verbatim: "Hamzat al-wasl is the alef that is sounded only when you begin with it and passes silently when you join, like the “al-” of ٱلۡحَمۡدُ. The mushafs write it in two ways.")

                    RiwayahSpellingCard(title: "Quran 1:2 (1:1 in the Madinan and Basran counts): “all praise”", [
                        RiwayahSpelling("Hafs, Shu’bah, al-Bazzi, Qunbul, Hisham, Ibn Dhakwan, and the narrators of Hamzah, al-Kisa’i and Khalaf", arabic: "ٱلۡحَمۡدُ", note: "The sign of joining: a small head of the letter ṣad over the alef"),
                        RiwayahSpelling("Qalun, Warsh, Ibn Wardan, Ibn Jammaz, ad-Duri, as-Susi, Ruways, Rawh", arabic: "اِ۬لۡحَمۡدُ", note: "A dot on the alef, set where the vowel of the join falls: the Madani hamzat al-wasl"),
                    ])

                    ArticleParagraph(verbatim: "In the second way the dot’s position carries the vowel that the joining takes from the word before: over the alef after a fatha, under it after a kasra, and beside it after a damma. Each Madani and Basri text in this app carries about ten thousand of these dots; Hafs’s carries 13,483 alefs with the small ṣad.")

                    RiwayahSpellingCard(title: "The dot follows the vowel before it (Qalun)", [
                        RiwayahSpelling("After a fatha, 1:7", arabic: "صِرَٰطَ اَ۬لذِينَ", note: "The dot over the alef"),
                        RiwayahSpelling("After a kasra, 1:7", arabic: "غَيۡرِ اِ۬لۡمَغۡضُوبِ", note: "The dot under the alef"),
                        RiwayahSpelling("After a damma, 2:5", arabic: "هُمُ اُ۬لۡمُفۡلِحُونَ", note: "The dot beside the alef"),
                    ])

                    ArticleParagraph(verbatim: "The small ṣad is the sign of the eastern system of marks that most printed mushafs follow today. The dot belongs to the dot-based way of marking kept for centuries in the mushafs of North and West Africa and of the Sudan, the lands where Warsh, Qalun and ad-Duri are recited.")
                }

                Section(header: ArticleHeader("DOTS UNDER THE LETTERS: IMALAH AND TAQLIL")) {
                    ArticleParagraph(verbatim: "Imalah tilts a fatha towards a kasra, so that the long a of مُوسَىٰ leans towards an e. The mushafs show it with a mark under the letter where the fatha would be: a filled dot for the full tilt (imalah kubra, the great tilt) and a hollow ring for the half tilt between the two (taqlil, also called bayna bayn).")

                    RiwayahSpellingCard(title: "Quran 2:7 (2:6 outside the Kufan count): “their sight”", [
                        RiwayahSpelling("Hafs and most readings", arabic: "أَبۡصَٰرِهِمۡ", note: "No tilt: abṣārihim"),
                        RiwayahSpelling("Warsh", arabic: "أَبۡصٰ۪رِهِمۡ", note: "A hollow ring under the ṣad: the half tilt"),
                        RiwayahSpelling("ad-Duri, as-Susi", arabic: "أَبۡصٰٜرِهِمۡ", note: "A filled dot: the full tilt, abṣērihim"),
                    ])

                    RiwayahSpellingCard(title: "Quran 20:9: “has there come to you the story of Musa?”", [
                        RiwayahSpelling("Hafs", arabic: "أَتَىٰكَ حَدِيثُ مُوسَىٰٓ", note: "atāka … mūsā"),
                        RiwayahSpelling("Khalaf from Hamzah", arabic: "أَتٜىٰكَ حَدِيثُ مُوسٜىٰٓ", note: "Both tilted fully: atēka … mūsē"),
                    ])

                    RiwayahSpellingCard(title: "Quran 8:17: “Allah threw”", [
                        RiwayahSpelling("Hafs", arabic: "رَمَىٰ", note: "ramā"),
                        RiwayahSpelling("Shu’bah", arabic: "رَمٜىٰ", note: "A filled dot: one of Shu’bah’s 79 imalahs"),
                        RiwayahSpelling("Warsh", arabic: "رَم۪ىٰ", note: "A hollow ring: taqlil"),
                    ])

                    ArticleParagraph(verbatim: "The readings of Kufa tilt the most. Hamzah, al-Kisa’i and Khalaf al-‘Ashir tilt nearly every word that ends in ى, and Hamzah and Ibn Dhakwan the alef of جَاءَ, شَاءَ and زَادَ; Shu’bah, Hisham and Rawh tilt a handful of words, among them letters at the head of a surah; Ruways tilts one word wherever it comes.")

                    RiwayahSpellingCard(title: "Quran 2:10 (2:9 outside the Kufan count): “so Allah increased them”", [
                        RiwayahSpelling("Hafs", arabic: "فَزَادَهُمُ", note: "zādahum"),
                        RiwayahSpelling("Ibn Dhakwan, Khalaf, Khallad", arabic: "فَزٜادَهُمُ", note: "The alef after the zāy tilted: zēdahum"),
                    ])

                    RiwayahSpellingCard(title: "Quran 10:1: “Alif, Lam, Ra”", [
                        RiwayahSpelling("Hafs", arabic: "الٓرۚ", note: "alif lām rā"),
                        RiwayahSpelling("Shu’bah, Hisham", arabic: "الٓرٜۚ", note: "The rā tilted, alif lām rē, at the head of every surah that opens with these letters"),
                    ])

                    RiwayahSpellingCard(title: "Quran 36:1: “Ya Sin”", [
                        RiwayahSpelling("Hafs", arabic: "يسٓ", note: "yā sīn"),
                        RiwayahSpelling("Rawh", arabic: "يٜسٓ", note: "The yā tilted, yē sīn: one of the three tilts in Rawh’s text"),
                    ])

                    RiwayahSpellingCard(title: "Quran 2:98 (2:97 outside the Kufan count): “to the disbelievers”", [
                        RiwayahSpelling("Hafs", arabic: "لِّلۡكَٰفِرِينَ", note: "lil-kāfirīn"),
                        RiwayahSpelling("Ruways, ad-Duri, as-Susi, ad-Duri from al-Kisa’i", arabic: "لِّلۡكٰٜفِرِينَ", note: "The alef of kāfirīn tilted, kēfirīn, wherever the word comes in the plural"),
                    ])

                    ArticleParagraph(verbatim: "Hafs tilts a vowel once in the whole Quran, in مَجۡر۪ىٰهَا (11:41). The other readings run from a handful of tilts to nearly two thousand:")

                    RiwayahBarChart(title: "Imalah and taqlil marks in each text", [
                        RiwayahBar("ad-Duri (al-Kisa’i)", filled: 1956, hollow: 0),
                        RiwayahBar("Khalaf", filled: 1922, hollow: 0),
                        RiwayahBar("Khallad", filled: 1911, hollow: 0),
                        RiwayahBar("Warsh", filled: 0, hollow: 1877),
                        RiwayahBar("Idris", filled: 1871, hollow: 0),
                        RiwayahBar("Ishaq", filled: 1871, hollow: 0),
                        RiwayahBar("Abu al-Harith", filled: 1608, hollow: 0),
                        RiwayahBar("ad-Duri (Abu ‘Amr)", filled: 748, hollow: 626),
                        RiwayahBar("as-Susi", filled: 620, hollow: 593),
                        RiwayahBar("Ibn Dhakwan", filled: 374, hollow: 0),
                        RiwayahBar("Ruways", filled: 92, hollow: 0),
                        RiwayahBar("Shu’bah", filled: 79, hollow: 0),
                        RiwayahBar("Qunbul", filled: 0, hollow: 15),
                        RiwayahBar("al-Bazzi", filled: 0, hollow: 15),
                        RiwayahBar("Hisham", filled: 13, hollow: 0),
                        RiwayahBar("Ibn Jammaz", filled: 4, hollow: 0),
                        RiwayahBar("Ibn Wardan", filled: 4, hollow: 0),
                        RiwayahBar("Qalun", filled: 1, hollow: 3),
                        RiwayahBar("Rawh", filled: 3, hollow: 0),
                        RiwayahBar("Hafs", filled: 1, hollow: 0),
                    ])

                    ArticleParagraph(verbatim: "The prints color the tilt too. Every print but Warsh’s captions it “imalah” and colors the full tilt; Warsh’s, whose tilt is the half tilt, captions its color “taqlil”. The two cards below list each.")
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "imalah")
                    RiwayahRuleCard(model: colorCode, key: "taqlil")
                    #endif
                }

                Section(header: ArticleHeader("THE SMALL WAW AFTER A MEEM: SILAH")) {
                    ArticleParagraph(verbatim: "Ibn Kathir’s and Abu Ja’far’s readings join the meem of the plural (-hum, -kum) to a long ū whenever a letter follows it, and their mushafs write that with a small waw:")

                    RiwayahSpellingCard(title: "Quran 1:7: “on them”", [
                        RiwayahSpelling("Hafs and most readings", arabic: "عَلَيۡهِمۡ", note: "ʿalayhim"),
                        RiwayahSpelling("al-Bazzi, Qunbul, Ibn Wardan, Ibn Jammaz", arabic: "عَلَيۡهِمُۥ", note: "ʿalayhimū: the meem joined to a long ū"),
                        RiwayahSpelling("Hamzah’s narrators, and Ya’qub’s", arabic: "عَلَيۡهُمۡ", note: "ʿalayhum: the ha read with a damma"),
                    ])

                    ArticleParagraph(verbatim: "Warsh joins the meem only when a hamzah follows, as in his spelling of 2:6 above. Qalun may join it or not, both being transmitted from him, and his printed mushaf writes it without the waw. In the app’s texts the small waw appears 8,037 times in al-Bazzi’s, 7,493 in Ibn Wardan’s, 2,142 in Warsh’s, and about 1,250 times in every other, where it marks mostly the joined pronoun of بِهِۦ that all the readings share.")

                    ArticleParagraph(verbatim: "The five prints that join the meem color it as well, under the caption ṣilat mīm al-jam’:")
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "silah_meem")
                    #endif
                }

                Section(header: ArticleHeader("THE MADD SIGN")) {
                    ArticleParagraph(verbatim: "A long vowel before a hamzah is stretched. When the long vowel ends one word and the hamzah begins the next (al-madd al-munfasil), the readings divide: some stretch it and some keep it short (qasr), and the printed mushafs show which by drawing the madd sign, the wavy line over the long vowel of بِمَآ, or leaving it out.")

                    RiwayahSpellingCard(title: "Quran 2:4 (2:3 outside the Kufan count): “in what was revealed”", [
                        RiwayahSpelling("Hafs, Warsh", arabic: "بِمَآ أُنزِلَ", note: "Stretched, with the madd sign"),
                        RiwayahSpelling("Qalun, al-Bazzi, as-Susi", arabic: "بِمَا أُنزِلَ", note: "Kept short: no madd sign"),
                    ])

                    ArticleStatGrid([
                        ArticleStat("5,652", "madd signs in Hafs’s text"),
                        ArticleStat("6,335", "in Warsh’s, who stretches more"),
                        ArticleStat("2,424", "in Qalun’s"),
                        ArticleStat("2,340", "in as-Susi’s"),
                    ])

                    ArticleCallout("**Stretch it:** Hafs, Shu’bah, Warsh, Hisham, Ibn Dhakwan, the narrators of Hamzah and al-Kisa’i, Ishaq and Idris, and ad-Duri as his mushaf prints it. **Keep it short:** Qalun as his mushaf prints it, al-Bazzi, Qunbul, as-Susi, Ibn Wardan, Ibn Jammaz, Ruways and Rawh. Qalun and ad-Duri each have both lengths transmitted from them.",
                                   title: "Long or short", systemImage: "arrow.left.and.right")
                }

                Section(header: ArticleHeader("OTHER THINGS YOU WILL NOTICE")) {
                    RiwayahSpellingCard(title: "Quran 1:4 (1:3 in the Madinan and Basran counts): “Master of the Day of Judgment”", [
                        RiwayahSpelling("Hafs, al-Kisa’i, Ya’qub, Khalaf", arabic: "مَٰلِكِ", note: "Māliki: the Owner"),
                        RiwayahSpelling("Qalun, Warsh and the others", arabic: "مَلِكِ", note: "Maliki: the King"),
                    ])

                    ArticleParagraph(verbatim: "Ayah numbers shift too, because each riwayah’s mushaf follows one of the schools of counting ayahs. The words are the same; only where an ayah ends differs. Hafs’s mushaf follows the Kufan count of 6,236 ayahs, Warsh’s and Qalun’s the later Madinan count of 6,214, al-Bazzi’s and Qunbul’s the Makkan count of 6,220, and Hisham’s and Ibn Dhakwan’s the Syrian count of 6,226.")
                }

                Section(header: ArticleHeader("THE COLORS OF A RIWAYAH’S MUSHAF")) {
                    ArticleParagraph(verbatim: "Open the Quran tab in any riwayah but Hafs with tajweed colors on, and the page is colored the way that riwayah’s printed mushaf colors it. Each of the nineteen prints carries a legend box at the foot of its pages: a color for the word or letter that differs from Hafs, one for a letter merged into the next, one for a tilted vowel, and so on, up to the eight colors of Warsh’s. The Legend button in the reader reproduces each print’s box, and the sections below take the rules in the Legend’s order: what differs from Hafs, the merges, the tilts and the joins above, then the pauses and blends, and last the rules that one reading alone marks.")

                    ArticleParagraph(verbatim: "Under each rule is every print that marks it, with its own color and the number of words it colors, and an example from the print that colors the most: one ayah of that riwayah’s text with the rule alone lit. Hafs’s mushaf is the exception. It prints no khilaf, since Hafs is the reading the others are measured against, and the app colors it by the ordinary tajweed code on the Legend’s first page.")
                }

                Section(header: ArticleHeader("WHAT DIFFERS FROM HAFS: THE MAGENTA")) {
                    ArticleParagraph(verbatim: "Every print begins its legend with the same color, a magenta for what is read differently from Hafs. Sixteen prints caption it “the letter differing from Hafs” and color only the letters that change; ad-Duri’s, Khalaf’s and Khallad’s caption it “the word differing from Hafs” and wash the whole word. It is one color marking one thing, and the Legend’s comparison folds the two captions into one rule.")

                    ArticleParagraph(verbatim: "What it marks is everything the Qiraat Explorer walks through: another word form, a letter added or dropped, a different vowel, a hamzah kept, eased or moved. The count under each riwayah is the number of words its print colors this way, a fair measure of how far a riwayah’s page stands from Hafs’s: Warsh’s print colors over seven thousand words, Shu’bah’s a few hundred.")

                    RiwayahSpellingCard(title: "Quran 2:45 (2:44 outside the Kufan count): “it is hard, except”", [
                        RiwayahSpelling("Hafs", arabic: "لَكَبِيرَةٌ إِلَّا", note: "lakabīratun illā: the hamzah of illā pronounced"),
                        RiwayahSpelling("Warsh", arabic: "لَكَبِيرَةٌ اِلَّا", note: "Naql: the hamzah drops and its kasrah moves onto the nūn of the tanween, lakabīratun-illā; the print colors the alef that is left"),
                    ])

                    RiwayahSpellingCard(title: "Quran 6:85 (6:86 in the Basran count): “and Zakariyya”", [
                        RiwayahSpelling("Hafs", arabic: "وَزَكَرِيَّا", note: "Zakariyyā"),
                        RiwayahSpelling("ad-Duri", arabic: "وَزَكَرِيَّآءَ", note: "Zakariyyā’, with a hamzah at the end, as most of the readings have the name; the whole word is colored"),
                    ])

                    RiwayahSpellingCard(title: "Quran 3:150: “and He is the best of helpers”", [
                        RiwayahSpelling("Hafs", arabic: "وَهُوَ", note: "wa-huwa"),
                        RiwayahSpelling("ad-Duri", arabic: "وَهۡوَ", note: "wa-hwa: the hā rests after the wāw, as Qalun, Abu ‘Amr and al-Kisa’i read it"),
                    ])
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "khilaf_harf")
                    #endif
                }

                Section(header: ArticleHeader("IDGHAM: ONE LETTER MERGED INTO THE NEXT")) {
                    ArticleParagraph(verbatim: "Idgham (إِدغَام) is the merging of one letter into the letter after it, so that the two are pronounced as a single doubled letter. Every reading merges a resting nūn or a tanween into the letters that take it, and the dhāl of إِذۡ, the dāl of قَدۡ, the tā of a feminine verb and the lām of هَلۡ and بَلۡ into certain letters after them; what differs is the list. Abu ‘Amr, Hisham, Hamzah, al-Kisa’i and Khalaf al-‘Ashir each carry more of these small mergings (al-idgham as-saghir) than Hafs, and the prints differ in how much of the ordinary merging they color at all, which is why the counts below range from a few dozen words to thousands.")

                    ArticleParagraph(verbatim: "The merging that marks a riwayah on sight is the great merging (al-idgham al-kabir) of Abu ‘Amr’s reading, carried furthest by as-Susi: a letter with a vowel at the end of one word is merged into the same or a close letter beginning the next. His print writes the first letter bare and the second with a shaddah, and colors both.")

                    RiwayahSpellingCard(title: "Quran 2:2 (2:1 outside the Kufan count): “in it is guidance”", [
                        RiwayahSpelling("Hafs", arabic: "فِيهِ هُدٗى", note: "fīhi hudā"),
                        RiwayahSpelling("as-Susi", arabic: "فِيه هُّدٗى", note: "The hā merged into the hā after it: fīh-hudā"),
                    ])

                    RiwayahSpellingCard(title: "Quran 2:11 (2:10 outside the Kufan count): “when it is said to them”", [
                        RiwayahSpelling("Hafs", arabic: "قِيلَ لَهُمۡ", note: "qīla lahum: two words, each lām its own"),
                        RiwayahSpelling("as-Susi", arabic: "قِيل لَّهُمۡ", note: "The lām of qīla merged into the lām of lahum: qīl-lahum"),
                    ])

                    RiwayahSpellingCard(title: "Quran 2:21 (2:20 outside the Kufan count): “who created you”", [
                        RiwayahSpelling("Hafs", arabic: "خَلَقَكُمۡ", note: "khalaqakum"),
                        RiwayahSpelling("as-Susi", arabic: "خَلَقكُّمۡ", note: "The qāf merged into the kāf: khalak-kum"),
                    ])
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "idgham")
                    #endif
                }

                Section(header: ArticleHeader("THE PRONOUN HA")) {
                    ArticleParagraph(verbatim: "The pronoun hā, the -hu or -hi of “him” and “his” at the end of a word, is joined to a long vowel by every reading when it stands between two vowels: بِهِۦ is bihī, لَهُۥ is lahū. Ibn Kathir’s reading, through al-Bazzi and Qunbul, joins it after a resting letter as well: عَلَيۡهِۦ is ʿalayhī, فِيهِۦ is fīhī. Hafs does this once, in fīhī muhānā (25:69); Ibn Kathir does it throughout, and his two prints color the hā with the small letter that lengthens it.")

                    RiwayahSpellingCard(title: "Quran 2:46 (2:45 in the Makkan count): “to Him they will return”", [
                        RiwayahSpelling("Hafs", arabic: "إِلَيۡهِ رَٰجِعُونَ", note: "ilayhi rājiʿūn"),
                        RiwayahSpelling("al-Bazzi, Qunbul", arabic: "إِلَيۡهِۦ رَٰجِعُونَ", note: "The hā joined to a long ī, written with a small yā: ilayhī rājiʿūn"),
                    ])
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "ha_dhamir")
                    #endif
                }

                Section(header: ArticleHeader("SAKT: THE BREATHLESS PAUSE")) {
                    ArticleParagraph(verbatim: "Sakt (سَكت) is a short pause on a resting letter without taking a breath, and then reading on. Hafs has it in four places, each marked in his mushaf with a small sīn over the word:")

                    RiwayahSpellingCard(title: "Hafs’s four pauses", [
                        RiwayahSpelling("Quran 18:1", arabic: "عِوَجَاۜ", note: "ʿiwajā, a pause, then qayyiman at the head of 18:2"),
                        RiwayahSpelling("Quran 36:52", arabic: "مَّرۡقَدِنَاۜۗ", note: "marqadinā, a pause, then hādhā"),
                        RiwayahSpelling("Quran 75:27", arabic: "مَنۡۜ رَاقٖ", note: "man, a pause, then rāq: without it the nūn would merge into the rā"),
                        RiwayahSpelling("Quran 83:14", arabic: "بَلۡۜ رَانَ", note: "bal, a pause, then rāna"),
                    ])

                    ArticleParagraph(verbatim: "Hamzah’s reading makes a rule of it. Khalaf pauses on the lām of the article before a hamzah (ٱلۡأَرۡضِ), on شَيۡء, and on any resting letter that ends a word before a hamzah beginning the next, وَإِنَّهَا لَكَبِيرَةٌ إِلَّا; Khallad pauses on the article and on شَيۡء. Their prints color every such place, which is why Khalaf’s count runs into the thousands and Khallad’s is a third of it.")

                    ArticleParagraph(verbatim: "Abu Ja’far’s reading pauses between the opening letters of a surah: الٓمٓ is alif, a stop, lām, a stop, mīm, and the prints of Ibn Wardan and Ibn Jammaz color those letters at the head of every surah that opens with them. None of these pauses is written into the text as Hafs’s four are; the color is the only mark.")
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "sakt")
                    #endif
                }

                Section(header: ArticleHeader("ISHMAM: A SAD WITH A SHADE OF ZAY")) {
                    ArticleParagraph(verbatim: "Ishmam (إِشمَام) here is a ṣād pronounced with a trace of the sound of zāy in it. Where a resting ṣād comes before a dāl, in أَصۡدَقُ, يَصۡدِفُونَ, وَتَصۡدِيَةٗ, تَصۡدِيقَ, فَٱصۡدَعۡ, قَصۡدُ, يُصۡدِرَ and يَصۡدُرُ, Hamzah, al-Kisa’i, Khalaf al-‘Ashir and Ruways give the ṣād that shade, and their prints color it: twelve words in each. Khalaf from Hamzah does the same to the ṣād of ٱلصِّرَٰطَ wherever it comes, in al-Fatihah and beyond, which lifts his count to fifty-nine; Khallad does so in al-Fatihah, in one of two ways transmitted from him.")

                    ArticleParagraph(verbatim: "The same word shows the other way a ṣād can go. Qunbul, from Ibn Kathir, reads it with a plain sīn, and his print writes a small sīn over the letter to say so:")

                    RiwayahSpellingCard(title: "Quran 1:6: “the path”", [
                        RiwayahSpelling("Hafs and most readings", arabic: "ٱلصِّرَٰطَ", note: "ṣirāṭ, with a ṣād"),
                        RiwayahSpelling("Qunbul", arabic: "ٱلصِّۜرَٰطَ", note: "A small sīn over the ṣād: Qunbul reads it sirāṭ, with an s"),
                        RiwayahSpelling("Khalaf", arabic: "ٱلصِّرَٰطَ", note: "Written as Hafs writes it; the print colors the ṣād for its shade of zāy"),
                    ])
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "ishmam_sad")
                    #endif
                }

                Section(header: ArticleHeader("ABU JA’FAR’S GHUNNAH, AND BEGINNING ON A WASL HAMZAH")) {
                    ArticleParagraph(verbatim: "Two colors belong to Abu Ja’far’s prints alone. A nūn or a tanween before خ or غ is pronounced clearly (izhar) by every other reading; Abu Ja’far hides it in a nasal hum (ikhfa with ghunnah), as every reading does before ت or ك. His prints leave the sukūn off the nūn and color the two words.")

                    RiwayahSpellingCard(title: "Quran 3:115: “of good”", [
                        RiwayahSpelling("Hafs", arabic: "مِنۡ خَيۡرٖ", note: "A sukūn on the nūn: pronounced clearly, min khayr"),
                        RiwayahSpelling("Ibn Wardan, Ibn Jammaz", arabic: "مِن خَيۡرٖ", note: "No sukūn: the nūn hums into the khā"),
                    ])

                    ArticleParagraph(verbatim: "The second color is for the reciter who begins at a word that opens with a waṣl hamzah followed by a resting hamzah, ٱئۡتِنَا, ٱؤۡتُمِنَ. Joined to the word before, the waṣl hamzah is silent and the second hamzah is pronounced. Begun on, the waṣl hamzah takes a vowel and, in every reading, the hamzah after it softens into the long vowel of that vowel: ٱئۡتِنَا is begun ītinā. Abu Ja’far’s prints are the ones that write this down, with a dot on the alef at the height of the vowel and the second hamzah drawn as the letter it becomes, in the sixteen places where it happens.")
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "ghunnah_kha_ghayn")
                    RiwayahRuleCard(model: colorCode, key: "ibtida_wasl")
                    #endif
                }

                Section(header: ArticleHeader("WARSH’S FOUR MARKS")) {
                    ArticleParagraph(verbatim: "Warsh’s print is the most colored of the twenty, and four of its eight colors are his alone. Madd al-badal is the long vowel after a hamzah, ءَامَنُواْ, ءَالَ, بِـَٔايَٰتِنَآ: every reading gives it two counts, and Warsh has three lengths transmitted from him, two, four and six. Madd al-līn is the soft wāw or yā before a hamzah in the same word, بِشَيۡءٖ, شَيۡءٞ: Warsh stretches it to four or six counts where the others read it short.")

                    ArticleParagraph(verbatim: "A rā with a fatḥah or a ḍammah after a kasrah, or after a resting yā, is read thin (tarqīq) by Warsh where Hafs reads it full: لَكَبِيرَةٌ, بَشِيرٗا وَنَذِيرٗا, خَيۡرُ. A lām with a fatḥah after ص, ط or ظ is read thick (taghlīẓ): اَ۬لصَّلَوٰةَ, صَلَوَٰتٞ, with the weight the lām of Allāh has. None of the four changes a letter on the page, so the color is the only sign of them, as the examples show.")
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "madd_badal")
                    RiwayahRuleCard(model: colorCode, key: "madd_leen")
                    RiwayahRuleCard(model: colorCode, key: "raa_muraqqaqah")
                    RiwayahRuleCard(model: colorCode, key: "lam_mughallazah")
                    #endif
                }

                Section(header: ArticleHeader("AL-BAZZI’S DOUBLED TA")) {
                    ArticleParagraph(verbatim: "Al-Bazzi, from Ibn Kathir, doubles the tā that begins a present-tense verb in thirty-one places when the word before it is joined to it: وَلَآ تَّيَمَّمُواْ, وَلَآ تَّفَرَّقُواْ, فَإِذَا هِيَ تَّلَقَّفُ. The doubling only happens in joining, so his print colors the particle before the verb together with it; a reciter who stops before the tā reads it single. Where a long vowel comes before the doubled tā, as in وَلَآ, the print adds the madd sign, because the vowel is now stretched before a doubled letter.")

                    RiwayahSpellingCard(title: "Quran 2:267 (2:266 in the Makkan count): “do not aim at the bad”", [
                        RiwayahSpelling("Hafs", arabic: "وَلَا تَيَمَّمُواْ", note: "wa-lā tayammamū"),
                        RiwayahSpelling("al-Bazzi", arabic: "وَلَآ تَّيَمَّمُواْ", note: "The tā doubled onto the word before, wa-lāt-tayammamū, with the madd sign over لَآ"),
                    ])

                    RiwayahSpellingCard(title: "Quran 3:103: “and do not become divided”", [
                        RiwayahSpelling("Hafs", arabic: "وَلَا تَفَرَّقُواْۚ", note: "wa-lā tafarraqū"),
                        RiwayahSpelling("al-Bazzi", arabic: "وَلَآ تَّفَرَّقُواْۚ", note: "wa-lāt-tafarraqū"),
                    ])
                    #if os(iOS)
                    RiwayahRuleCard(model: colorCode, key: "tashdid_ta")
                    #endif
                }

                Section(header: ArticleHeader("EVERY RIWAYAH AT A GLANCE")) {
                    ArticleParagraph(verbatim: "The twenty, in the classical order of their imams, each with six words as its own text spells them: the hamzah in يُؤۡمِنُونَ at 2:3, two hamzahs together in ءَأَنذَرۡتَهُمۡ at 2:6, hamzat al-wasl in ٱلۡحَمۡدُ at 1:2, the tilt in مُوسَىٰ at 2:54, silah in عَلَيۡهِمۡ at 1:7, and the madd in بِمَآ أُنزِلَ at 2:4, numbered as Hafs counts them. A word in color is written differently from Hafs. Tap a riwayah to read about its narrator.")

                    RiwayahTraitsTable()
                }

                Section(header: ArticleHeader("EACH MUSHAF’S COLOR CODE")) {
                    ArticleParagraph(verbatim: "The nineteen prints, in the classical order of their imams, each with the rules its legend box carries, in the app’s order, and the number of words it colors with each. A print marks only the rules its reading has: Qalun’s box has two colors, Warsh’s eight. Tap a riwayah to read about its narrator; the Legend button in the reader shows the same box, with the colors live on the page, whenever that riwayah is open.")
                    #if os(iOS)
                    RiwayahColorCodeCards(model: colorCode)
                    #else
                    ArticleParagraph(verbatim: "Open this page on the iPhone to see every print’s color code.")
                    #endif
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    ArticleParagraph(articleMarkdown: "**Is a mushaf without the hamzah missing something?**")
                    ArticleParagraph(verbatim: "No. The rasm of the word is the same. A riwayah that eases or drops a hamzah is pronouncing the word as it was taught from the Prophet (peace and blessings be upon him), and its mushaf writes down what is pronounced. Each of the twenty is the complete Quran.")

                    ArticleParagraph(articleMarkdown: "**Why does Hafs’s mushaf look like the “normal” one?**")
                    ArticleParagraph(verbatim: "Because most printed mushafs today are Hafs, set in the eastern system of marks. The Madani dot for hamzat al-wasl is not a modern invention: it belongs to the dot-based way of marking that the mushafs of North and West Africa have kept for centuries.")

                    ArticleParagraph(articleMarkdown: "**Can I recite Hafs from a Warsh mushaf?**")
                    ArticleParagraph(verbatim: "Not reliably. The marks tell the reader what to pronounce, and a Warsh mushaf marks Warsh’s pronunciation: its hamzahs, its tilts, its madd. Recite each riwayah from its own mushaf, or with a teacher who has an ijazah in it.")

                    ArticleParagraph(articleMarkdown: "**What do the colors mean when I read another riwayah?**")
                    ArticleParagraph(verbatim: "They are that riwayah’s own printed legend. Each word or letter is colored exactly where its mushaf colors it, and the Legend button in the reader opens the box with the same rules, in the same order as on this page, each with an example and a switch to show or hide it. The colors can be changed there too, and a color picked for a rule follows that rule into every riwayah that marks it.")

                    ArticleParagraph(articleMarkdown: "**Are the counts on this page exact?**")
                    ArticleParagraph(verbatim: "They are exact counts of the app’s own texts. Eight of the twenty (Hafs, Shu’bah, Warsh, Qalun, al-Bazzi, Qunbul, ad-Duri and as-Susi) are verified digital texts; the other twelve are beta texts read by machine from their printed mushafs, so their counts are close but not guaranteed to the last mark.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The twenty riwayat share one skeleton and one Quran. What their mushafs add, the hamzah or the dot that stands for it, a small ṣad or a dot on the joining alef, a filled dot or a hollow ring for a tilted vowel, a small waw, a madd sign, is each reading’s pronunciation written down faithfully, so that it can be recited exactly as it was taught. The colors of each print are that pronunciation written down a second time, as a legend any reader can follow.")
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    ArticleTermCard("Rasm", arabic: "رَسم", meaning: "The skeleton of the mushaf as the Companions wrote it, without dots or vowels. It is the same in every riwayah, apart from a few dozen places where the copies Uthman sent to the cities differ by a letter or a word, each reading agreeing with one of those copies.")
                    ArticleTermCard("Dabt", arabic: "ضَبط", meaning: "From **ض-ب-ط**, to make exact: the marks added to the rasm (vowels, sukoon, shadda, madd and the signs for hamzah and wasl), which differ from one riwayah’s mushaf to another.")
                    ArticleTermCard("Tas-hil", arabic: "تَسهِيل", meaning: "From **س-ه-ل**, to make easy: pronouncing a hamzah between itself and the long vowel it leans towards. Its mushafs draw a dot in its place.")
                    ArticleTermCard("Ibdal", arabic: "إِبدَال", meaning: "From **ب-د-ل**, to exchange: turning a hamzah into a long vowel, as in يُومِنُونَ.")
                    ArticleTermCard("Naql", arabic: "نَقل", meaning: "From **ن-ق-ل**, to move: moving a hamzah’s vowel onto the quiet letter before it and dropping the hamzah, Warsh’s way.")
                    ArticleTermCard("Idkhal", arabic: "إِدخَال", meaning: "From **د-خ-ل**, to put in: a short alef inserted between two hamzahs.")
                    ArticleTermCard("Hamzat al-wasl", arabic: "هَمزَة الوَصل", meaning: "The joining alef, sounded only when a word begins with it; written with a small ṣad over the alef in Hafs (ٱلۡحَمۡدُ) and with a dot in the Madani mushafs (اِ۬لۡحَمۡدُ).")
                    ArticleTermCard("Imalah", arabic: "إِمَالَة", meaning: "From **م-ي-ل**, to lean: tilting a fatha towards a kasra, marked with a filled dot.")
                    ArticleTermCard("Taqlil", arabic: "تَقلِيل", meaning: "From **ق-ل-ل**, to lessen: the half tilt between a fatha and an imalah, marked with a hollow ring.")
                    ArticleTermCard("Silah", arabic: "صِلَة", meaning: "From **و-ص-ل**, to join: joining a pronoun’s vowel to a long vowel, written with a small waw.")
                    ArticleTermCard("Al-madd al-munfasil", arabic: "المَدّ المُنفَصِل", meaning: "The separated madd: a long vowel ending one word before a hamzah beginning the next.")
                    ArticleTermCard("Al-idgham al-kabir", arabic: "الإِدغَام الكَبِير", meaning: "The great merging: a voweled letter merged into the same or a close letter after it, a mark of as-Susi’s reading.")
                    ArticleTermCard("Al-idgham as-saghir", arabic: "الإِدغَام الصَّغِير", meaning: "The small merging: a resting letter merged into the letter after it, the dhāl of إِذۡ, the dāl of قَدۡ, a nūn or a tanween, in the lists each reading carries.")
                    ArticleTermCard("Khilaf", arabic: "خِلَاف", meaning: "From **خ-ل-ف**, to differ: the word or letter a riwayah reads differently from Hafs, the first color in every print’s legend.")
                    ArticleTermCard("Sakt", arabic: "سَكت", meaning: "From **س-ك-ت**, to fall silent: a short pause on a resting letter without taking a breath; Hafs’s four places, Hamzah’s rule, Abu Ja’far’s opening letters.")
                    ArticleTermCard("Ishmam", arabic: "إِشمَام", meaning: "From **ش-م-م**, to give a scent of: here, a ṣād pronounced with a trace of zāy, in أَصۡدَقُ and its like, and in ٱلصِّرَٰطَ for Khalaf.")
                    ArticleTermCard("Ghunnah", arabic: "غُنَّة", meaning: "The nasal hum of nūn and mīm; Abu Ja’far keeps it on a nūn before خ and غ, where the other readings pronounce the nūn clearly.")
                    ArticleTermCard("Tarqiq and taghlidh", arabic: "تَرقِيق وَتَغلِيظ", meaning: "Thinning and thickening: Warsh’s thin rā after a kasrah or a yā, and his thick lām after ص, ط and ظ.")
                    ArticleTermCard("Madd al-badal", arabic: "مَدّ البَدَل", meaning: "The madd of exchange: the long vowel after a hamzah, ءَامَنُواْ, which Warsh may stretch to four or six counts.")
                    ArticleTermCard("Madd al-lin", arabic: "مَدّ اللِّين", meaning: "The soft madd: a wāw or yā resting after a fatḥah, as in شَيۡءٞ, which Warsh stretches before a hamzah.")
                    ArticleTermCard("Ha ad-damir", arabic: "هَاء الضَّمِير", meaning: "The pronoun hā, -hu and -hi; Ibn Kathir joins it to a long vowel after a resting letter too, عَلَيۡهِۦ.")
                }

                ArticleSourcesSection(article: "RiwayatDifferencesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Riwayat on the Page")
        .englishArticle().selectableArticleList(article: "RiwayatDifferencesView")
    }
}

// MARK: - Spellings

/// One spelling of a word in one or more riwayat, copied from the app's own text of each.
struct RiwayahSpelling: Hashable {
    let riwayat: String
    let arabic: String
    let note: String

    init(_ riwayat: String, arabic: String, note: String) {
        self.riwayat = riwayat
        self.arabic = arabic
        self.note = note
    }
}

/// A word as each group of riwayat writes it, one row per spelling, the Arabic set in the Hafs Uthmani
/// face: that face carries both wasl notations and the filled and hollow dots (see the imaalah marks
/// work in Uthmani.ttf), where the reader's own Quran font may not.
struct RiwayahSpellingCard: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let spellings: [RiwayahSpelling]

    init(title: String, _ spellings: [RiwayahSpelling]) {
        self.title = title
        self.spellings = spellings
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(accent)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(spellings.enumerated()), id: \.offset) { index, spelling in
                VStack(alignment: .leading, spacing: 4) {
                    // No single-line shrink: it halved Hafs's ٱلۡحَمۡدُ beside the dot spelling under it, and
                    // every spelling here fits a line at this size anyway.
                    Text(spelling.arabic)
                        .font(Font.arabic(Settings.hafsUthmaniFontName, size: 30, relativeTo: .title))
                        .foregroundColor(index == 0 ? .primary : accent)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        // The Arabic word sits on the right in both interfaces (`.trailing` alone is the
                        // left edge in a right-to-left layout).
                        .environment(\.layoutDirection, .leftToRight)

                    Text(spelling.riwayat)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(quranicInline: spelling.note, size: 12, relativeTo: .caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)

                if index < spellings.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.12), accent.opacity(0.03)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(accent.opacity(0.2), lineWidth: 1))
        )
        .padding(.vertical, 3)
    }
}

// MARK: - The tilt chart

/// One riwayah's imalah (filled) and taqlil (hollow) marks, counted in its text.
struct RiwayahBar: Hashable {
    let name: String
    let filled: Int
    let hollow: Int

    init(_ name: String, filled: Int, hollow: Int) {
        self.name = name
        self.filled = filled
        self.hollow = hollow
    }
}

/// A bar per riwayah: the filled dots in the accent, the hollow rings in an outline of it, on one
/// scale, so the full-tilt readings of Kufa and the half-tilt reading of Warsh sit side by side.
struct RiwayahBarChart: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let bars: [RiwayahBar]

    init(title: String, _ bars: [RiwayahBar]) {
        self.title = title
        self.bars = bars
    }

    private var maximum: Int { max(1, bars.map { $0.filled + $0.hollow }.max() ?? 1) }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(accent)

            HStack(spacing: 14) {
                legend(filled: true, "Filled dot: imalah")
                legend(filled: false, "Hollow ring: taqlil or an eased hamzah")
            }
            .padding(.bottom, 4)

            ForEach(bars, id: \.self) { bar in
                HStack(spacing: 8) {
                    Text(bar.name)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 98, alignment: .leading)

                    GeometryReader { proxy in
                        let width = proxy.size.width
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(accent)
                                .frame(width: width * CGFloat(bar.filled) / CGFloat(maximum))
                            Rectangle()
                                .fill(accent.opacity(0.18))
                                .overlay(Rectangle().strokeBorder(accent, lineWidth: 1))
                                .frame(width: width * CGFloat(bar.hollow) / CGFloat(maximum))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                    .frame(height: 12)

                    Text((bar.filled + bar.hollow).formatted())
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(bar.name): \(bar.filled) filled dots, \(bar.hollow) hollow rings")
            }

            Text("Counted in the app’s texts; the twelve beta texts are machine-read, so their counts are close rather than exact.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(accent.opacity(0.18), lineWidth: 1))
        )
        .padding(.vertical, 3)
    }

    private func legend(filled: Bool, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(filled ? appearance.accent : appearance.accent.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 2, style: .continuous).strokeBorder(appearance.accent, lineWidth: filled ? 0 : 1))
                .frame(width: 12, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - At a glance

/// What one riwayah's mushaf shows, in five short answers. The corpus builder reads these literals
/// (Scripts/build_islam_corpus.py) where `RiwayahTraitsTable()` sits in the page.
struct RiwayahTraits: Identifiable {
    let name: String
    let from: String
    let tag: String
    let hamzah: String
    let wasl: String
    let dots: String
    let silah: String
    let madd: String

    var id: String { name + from }

    static let all: [RiwayahTraits] = [
        RiwayahTraits(name: "Qalun", from: "from Nafi’", tag: Settings.Riwayah.qaloon, hamzah: "Eases the second of two", wasl: "Dot", dots: "Almost none", silah: "Optional; printed without", madd: "Short as printed"),
        RiwayahTraits(name: "Warsh", from: "from Nafi’", tag: Settings.Riwayah.warsh, hamzah: "Softens the quiet hamzah; naql", wasl: "Dot", dots: "1,877 hollow", silah: "Before a hamzah", madd: "Long"),
        RiwayahTraits(name: "al-Bazzi", from: "from Ibn Kathir", tag: Settings.Riwayah.buzzi, hamzah: "Eases the second of two", wasl: "Small ṣad", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "Qunbul", from: "from Ibn Kathir", tag: Settings.Riwayah.qunbul, hamzah: "Eases the second of two", wasl: "Small ṣad", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "ad-Duri", from: "from Abu ‘Amr", tag: Settings.Riwayah.duri, hamzah: "Eases the second of two", wasl: "Dot", dots: "748 filled, 626 hollow", silah: "No", madd: "Long as printed"),
        RiwayahTraits(name: "as-Susi", from: "from Abu ‘Amr", tag: Settings.Riwayah.susi, hamzah: "Softens the quiet hamzah", wasl: "Dot", dots: "620 filled, 593 hollow", silah: "No", madd: "Short"),
        RiwayahTraits(name: "Hisham", from: "from Ibn ‘Amir", tag: Settings.Riwayah.hisham, hamzah: "Pronounced; eased in one of two ways", wasl: "Small ṣad", dots: "Almost none", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Ibn Dhakwan", from: "from Ibn ‘Amir", tag: Settings.Riwayah.ibnDhakwan, hamzah: "Pronounced", wasl: "Small ṣad", dots: "374 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Shu’bah", from: "from ‘Asim", tag: Settings.Riwayah.shubah, hamzah: "Pronounced", wasl: "Small ṣad", dots: "79 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Hafs", from: "from ‘Asim", tag: Settings.Riwayah.hafsTag, hamzah: "Pronounced", wasl: "Small ṣad", dots: "One, in 11:41", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Khalaf", from: "from Hamzah", tag: Settings.Riwayah.khalaf, hamzah: "Pronounced; eased at a stop", wasl: "Small ṣad", dots: "1,922 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Khallad", from: "from Hamzah", tag: Settings.Riwayah.khallad, hamzah: "Pronounced; eased at a stop", wasl: "Small ṣad", dots: "1,911 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Abu al-Harith", from: "from al-Kisa’i", tag: Settings.Riwayah.abuHarith, hamzah: "Pronounced", wasl: "Small ṣad", dots: "1,608 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "ad-Duri", from: "from al-Kisa’i", tag: Settings.Riwayah.duriKisai, hamzah: "Pronounced", wasl: "Small ṣad", dots: "1,956 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Ibn Wardan", from: "from Abu Ja’far", tag: Settings.Riwayah.ibnWardan, hamzah: "Softens the quiet hamzah", wasl: "Dot", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "Ibn Jammaz", from: "from Abu Ja’far", tag: Settings.Riwayah.ibnJammaz, hamzah: "Softens the quiet hamzah", wasl: "Dot", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "Ruways", from: "from Ya’qub", tag: Settings.Riwayah.ruways, hamzah: "Eases the second of two", wasl: "Dot", dots: "92 filled", silah: "No", madd: "Short"),
        RiwayahTraits(name: "Rawh", from: "from Ya’qub", tag: Settings.Riwayah.rawh, hamzah: "Pronounced", wasl: "Dot", dots: "Almost none", silah: "No", madd: "Short"),
        RiwayahTraits(name: "Ishaq", from: "from Khalaf", tag: Settings.Riwayah.ishaq, hamzah: "Pronounced", wasl: "Small ṣad", dots: "1,871 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Idris", from: "from Khalaf", tag: Settings.Riwayah.idris, hamzah: "Pronounced", wasl: "Small ṣad", dots: "1,871 filled", silah: "No", madd: "Long"),
    ]
}

/// The six words of the at-a-glance table, each as every riwayah's own text writes it (Abu, 2026-10-27:
/// "how the riwayah differ on the page ... why not use Arabic text?"). Copied out of the app's twenty
/// texts by a script, never retyped: the seven KFGQPC sources behind qiraat.qpk, the twelve beta texts
/// behind qiraah.solidpack, and Hafs from Quran.json. Each word was found by its skeleton in its surah,
/// so a text's own ayah numbering did not matter.
enum RiwayahGlance {
    struct Word {
        let label: String
        let reference: String
    }

    /// The order of every list in `spellings`; the references are Hafs's count.
    static let words: [Word] = [
        Word(label: "Hamzah", reference: "2:3"),
        Word(label: "Two hamzahs", reference: "2:6"),
        Word(label: "Wasl", reference: "1:2"),
        Word(label: "Tilt", reference: "2:54"),
        Word(label: "Silah", reference: "1:7"),
        Word(label: "Madd", reference: "2:4"),
    ]

    static let spellings: [String: [String]] = [
        Settings.Riwayah.qaloon: ["يُؤۡمِنُونَ", "ءَٰا۬نذَرۡتَهُمۡ", "اِ۬لۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمۡ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.warsh: ["يُومِنُونَ", "ءَآنذَرۡتَهُمُۥٓ", "اِ۬لۡحَمۡدُ", "مُوس۪ىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.buzzi: ["يُؤۡمِنُونَ", "ءَا۬نذَرۡتَهُمُۥ", "ٱلۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمُۥ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.qunbul: ["يُؤۡمِنُونَ", "ءَا۬نذَرۡتَهُمُۥ", "ٱلۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمُۥ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.duri: ["يُؤۡمِنُونَ", "ءَٰا۬نذَرۡتَهُمۡ", "اِ۬لۡحَمۡدُ", "مُوس۪يٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.susi: ["يُومِنُونَ", "ءَٰا۬نذَرۡتَهُمۡ", "اِ۬لۡحَمۡدُ", "مُوس۪يٰ", "عَلَيۡهِمۡ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.hisham: ["يُؤۡمِنُونَ", "ءَٰا۬نذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.ibnDhakwan: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.shubah: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.hafsTag: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.khalaf: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسٜىٰ", "عَلَيۡهُمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.khallad: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسٜىٰ", "عَلَيۡهُمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.abuHarith: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسٜىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.duriKisai: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسٜىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.ibnWardan: ["يُومِنُونَ", "ءَٰا۬نذَرۡتَهُمُۥ", "اِ۬لۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمُۥ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.ibnJammaz: ["يُومِنُونَ", "ءَٰا۬نذَرۡتَهُمُۥ", "اِ۬لۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهِمُۥ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.ruways: ["يُؤۡمِنُونَ", "ءَا۬نذَرۡتَهُمۡ", "اِ۬لۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهُمۡ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.rawh: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "اِ۬لۡحَمۡدُ", "مُوسَىٰ", "عَلَيۡهُمۡ", "بِمَا أُنزِلَ"],
        Settings.Riwayah.ishaq: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسٜىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
        Settings.Riwayah.idris: ["يُؤۡمِنُونَ", "ءَأَنذَرۡتَهُمۡ", "ٱلۡحَمۡدُ", "مُوسٜىٰ", "عَلَيۡهِمۡ", "بِمَآ أُنزِلَ"],
    ]
}

/// The twenty riwayat, one row each: the name, the imam, and the six words of `RiwayahGlance` as the
/// riwayah writes them, in a fixed grid so a column compares one word down all twenty. A word written
/// differently from Hafs takes the accent. VoiceOver reads the five traits in words. A row opens the
/// narrator's profile.
struct RiwayahTraitsTable: View {
    @Environment(\.appearance) private var appearance

    init() {}

    var body: some View {
        ForEach(RiwayahTraits.all) { traits in
            if let profile = QiraatProfiles.narrator(tag: traits.tag) {
                NavigationLink(destination: LazyDestination { RiwayahNarratorDetailView(profile: profile) }) {
                    row(traits)
                }
            } else {
                row(traits)
            }
        }
    }

    private func row(_ traits: RiwayahTraits) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(traits.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(traits.from)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            words(traits)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(traits.name), \(traits.from). Hamzah: \(traits.hamzah). Hamzat al-wasl: \(traits.wasl). Tilt: \(traits.dots). Silah: \(traits.silah). Madd: \(traits.madd)."))
    }

    /// Three words a line on a phone, two on the watch, the same cells in every row.
    #if os(watchOS)
    private static let columns = 2
    #else
    private static let columns = 3
    #endif

    private func words(_ traits: RiwayahTraits) -> some View {
        let spellings = RiwayahGlance.spellings[traits.tag] ?? []
        let hafs = RiwayahGlance.spellings[Settings.Riwayah.hafsTag] ?? []
        let lines = (RiwayahGlance.words.count + Self.columns - 1) / Self.columns
        return VStack(spacing: 5) {
            ForEach(0..<lines, id: \.self) { line in
                HStack(spacing: 5) {
                    ForEach(0..<Self.columns, id: \.self) { column in
                        let index = line * Self.columns + column
                        if index < spellings.count, index < hafs.count {
                            cell(RiwayahGlance.words[index].label, spellings[index], differs: spellings[index] != hafs[index])
                        }
                    }
                }
            }
        }
    }

    private func cell(_ label: String, _ arabic: String, differs: Bool) -> some View {
        let accent = appearance.accent
        // Room under the label: this face stacks a small waw over the damma (عَلَيۡهِمُۥ), above the line.
        return VStack(spacing: 6) {
            Text(verbatim: label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(differs ? accent : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            // The Hafs Uthmani face, like the spelling cards: it carries both wasl notations and the
            // filled and hollow dots. One line, shrinking only if a narrow column cannot hold it.
            Text(verbatim: arabic)
                .font(Font.arabic(Settings.hafsUthmaniFontName, size: 19, relativeTo: .body))
                .foregroundColor(differs ? accent : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(differs ? accent.opacity(0.12) : Color.secondary.opacity(0.07))
        )
    }
}
