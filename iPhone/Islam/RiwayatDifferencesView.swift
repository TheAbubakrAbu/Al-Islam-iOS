import SwiftUI

/// How the riwayat differ ON THE PAGE (Abu, 2026-09-29: "mention which riwayahs have hamzas, which
/// don't, which have Madani hamzat al-wasl and which have dots as it, and other differences in
/// qiraat").
///
/// The Qiraat Explorer covers how the readings differ in WORDS. This page covers what a reader sees
/// the moment they switch the Quran tab to another riwayah: the hamzah kept, eased or dropped, the dot
/// that stands for an eased hamzah, ٱ against the Madani dot for hamzat al-wasl, the filled and hollow
/// dots of imalah and taqlil, the small waw of silah, and the madd sign. Every spelling below was
/// copied out of the app's own riwayah texts by a script (never retyped), and every count was taken
/// from them: the eight verified texts in Resources/JSONs-Deprecated/Qiraat (with Hafs from
/// Quran.json) and the twelve beta texts' v2 candidates, which is why the page says the beta counts
/// are close rather than exact.
struct RiwayatDifferencesView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: all twenty riwayat share one Uthmanic skeleton. What changes on the page is the marks around it: the hamzah kept, eased or dropped, a dot for hamzat al-wasl where Hafs writes ٱ, and dots under the letters where a vowel tilts.")
                }

                Section(header: ArticleHeader("ONE SKELETON, DIFFERENT MARKS")) {
                    Text(verbatim: "The Companions wrote the mushaf without dots or vowel signs, and that one consonantal skeleton, the rasm (رَسم), carries every canonical reading. The marks came after them: the vowel dots attributed to Abu al-Aswad ad-Du’ali (d. 69 AH), the dots that tell one letter from another, and later the signs of al-Khalil ibn Ahmad (d. 170 AH) that became today’s harakat. A mushaf printed for a riwayah adds the marks its pronunciation needs, in the conventions of the lands that recite it, which is why two correct mushafs can look different on the same line.")
                        .font(.body)

                    ArticleStatGrid([
                        ArticleStat("20", "riwayat, each with its own printed mushaf"),
                        ArticleStat("10", "qiraat, two riwayat each"),
                        ArticleStat("1", "Uthmanic skeleton under all of them"),
                    ])

                    Text(verbatim: "Below are the differences you will actually see when you switch the Quran tab to another riwayah: the hamzah, the dot that stands in for it, hamzat al-wasl, the dots under letters, the small waw after a meem, and the madd sign. Where the readings differ in a word or a vowel, the Qiraat Explorer in The 10 Qiraat walks through every place, ayah by ayah.")
                        .font(.body)

                    ArticleDoorRow(door: .article("QiraatView"))
                }

                Section(header: ArticleHeader("THE HAMZAH: PRONOUNCED, EASED, OR DROPPED")) {
                    Text(verbatim: "The hamzah, the catch in the throat written ء, is where the readings differ most often. Arabic itself was divided on it: the people of the Hijaz tended to soften it and the tribes of Najd to pronounce it fully. The canonical readings preserve both, each applying its own rule every time it meets one.")
                        .font(.body)

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

                    Text(verbatim: "How many hamzah signs each text carries (every ء, أ, إ, ؤ, ئ and seated hamzah):")
                        .font(.body)

                    ArticleStatGrid([
                        ArticleStat("19,170", "Hafs"),
                        ArticleStat("19,043", "Qalun"),
                        ArticleStat("17,869", "as-Susi"),
                        ArticleStat("14,546", "Warsh"),
                    ])

                    Text(verbatim: "Qalun sits within 127 of Hafs. As-Susi writes about 1,300 fewer, Ibn Wardan and Ibn Jammaz, who share Abu Ja’far’s rule, about 1,500 fewer, and Warsh about 4,600 fewer, the most of any riwayah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHERE A DOT STANDS FOR THE HAMZAH")) {
                    Text(verbatim: "An eased hamzah is pronounced between a hamzah and the long vowel it leans towards, and the mushafs of the readings that ease it do not draw a hamzah there at all: a small dot takes its place. That is the dot on the second alef in Qalun’s and ad-Duri’s spelling of 2:6 above, and in al-Bazzi’s.")
                        .font(.body)

                    Text(verbatim: "Hafs eases a hamzah only once in the whole Quran, and his mushaf marks it the same way:")
                        .font(.body)

                    RiwayahSpellingCard(title: "Quran 41:44: “a foreign one?”", [
                        RiwayahSpelling("Hafs", arabic: "ءَا۬عۡجَمِيّٞ", note: "The second hamzah eased, drawn as a dot"),
                    ])
                }

                Section(header: ArticleHeader("HAMZAT AL-WASL: ٱ OR A DOT")) {
                    Text(verbatim: "Hamzat al-wasl is the alef that is sounded only when you begin with it and passes silently when you join, like the “al-” of ٱلۡحَمۡدُ. The mushafs write it in two ways.")
                        .font(.body)

                    RiwayahSpellingCard(title: "Quran 1:2 (1:1 in the Madinan and Basran counts): “all praise”", [
                        RiwayahSpelling("Hafs, Shu’bah, al-Bazzi, Qunbul, Hisham, Ibn Dhakwan, and the narrators of Hamzah, al-Kisa’i and Khalaf", arabic: "ٱلۡحَمۡدُ", note: "ٱ: a small head of the letter ṣad over the alef, the sign of joining"),
                        RiwayahSpelling("Qalun, Warsh, Ibn Wardan, Ibn Jammaz, ad-Duri, as-Susi, Ruways, Rawh", arabic: "اِ۬لۡحَمۡدُ", note: "A dot on the alef, set where the vowel of the join falls: the Madani hamzat al-wasl"),
                    ])

                    Text(verbatim: "In the second way the dot’s position carries the vowel that the joining takes from the word before: over the alef after a fatha, under it after a kasra, and beside it after a damma. Each Madani and Basri text in this app carries about ten thousand of these dots; Hafs’s carries 13,483 of the ٱ.")
                        .font(.body)

                    RiwayahSpellingCard(title: "The dot follows the vowel before it (Qalun)", [
                        RiwayahSpelling("After a fatha, 1:7", arabic: "صِرَٰطَ اَ۬لذِينَ", note: "The dot over the alef"),
                        RiwayahSpelling("After a kasra, 1:7", arabic: "غَيۡرِ اِ۬لۡمَغۡضُوبِ", note: "The dot under the alef"),
                        RiwayahSpelling("After a damma, 2:5", arabic: "هُمُ اُ۬لۡمُفۡلِحُونَ", note: "The dot beside the alef"),
                    ])

                    Text(verbatim: "The ٱ is the sign of the eastern system of marks that most printed mushafs follow today. The dot belongs to the dot-based way of marking kept for centuries in the mushafs of North and West Africa and of the Sudan, the lands where Warsh, Qalun and ad-Duri are recited.")
                        .font(.body)
                }

                Section(header: ArticleHeader("DOTS UNDER THE LETTERS: IMALAH AND TAQLIL")) {
                    Text(verbatim: "Imalah tilts a fatha towards a kasra, so that the long a of مُوسَىٰ leans towards an e. The mushafs show it with a mark under the letter where the fatha would be: a filled dot for the full tilt (imalah kubra, the great tilt) and a hollow ring for the half tilt between the two (taqlil, also called bayna bayn).")
                        .font(.body)

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

                    Text(verbatim: "Hafs tilts a vowel once in the whole Quran, in مَجۡر۪ىٰهَا (11:41). The other readings run from a handful of tilts to nearly two thousand:")
                        .font(.body)

                    RiwayahBarChart(title: "Imalah and taqlil marks in each text", [
                        RiwayahBar("ad-Duri (al-Kisa’i)", filled: 1956, hollow: 0),
                        RiwayahBar("Khalaf", filled: 1922, hollow: 4),
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
                }

                Section(header: ArticleHeader("THE SMALL WAW AFTER A MEEM: SILAH")) {
                    Text(verbatim: "Ibn Kathir’s and Abu Ja’far’s readings join the meem of the plural (-hum, -kum) to a long ū whenever a letter follows it, and their mushafs write that with a small waw:")
                        .font(.body)

                    RiwayahSpellingCard(title: "Quran 1:7: “on them”", [
                        RiwayahSpelling("Hafs and most readings", arabic: "عَلَيۡهِمۡ", note: "ʿalayhim"),
                        RiwayahSpelling("al-Bazzi, Qunbul, Ibn Wardan, Ibn Jammaz", arabic: "عَلَيۡهِمُۥ", note: "ʿalayhimū: the meem joined to a long ū"),
                        RiwayahSpelling("Hamzah’s narrators, and Ya’qub’s", arabic: "عَلَيۡهُمۡ", note: "ʿalayhum: the ha read with a damma"),
                    ])

                    Text(verbatim: "Warsh joins the meem only when a hamzah follows, as in his spelling of 2:6 above. Qalun may join it or not, both being transmitted from him, and his printed mushaf writes it without the waw. In the app’s texts the small waw appears 8,037 times in al-Bazzi’s, 7,493 in Ibn Wardan’s, 2,142 in Warsh’s, and about 1,250 times in every other, where it marks mostly the joined pronoun of بِهِۦ that all the readings share.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE MADD SIGN")) {
                    Text(verbatim: "A long vowel before a hamzah is stretched. When the long vowel ends one word and the hamzah begins the next (al-madd al-munfasil), the readings divide: some stretch it and some keep it short (qasr), and the printed mushafs show which by drawing the madd sign ٓ or leaving it out.")
                        .font(.body)

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
                    RiwayahSpellingCard(title: "Quran 1:6: “the path”", [
                        RiwayahSpelling("Hafs and most readings", arabic: "ٱلصِّرَٰطَ", note: "ṣirāṭ, with a ṣad"),
                        RiwayahSpelling("Qunbul", arabic: "ٱلصِّۜرَٰطَ", note: "A small sin over the ṣad: Qunbul reads it sirāṭ, with an s"),
                    ])

                    RiwayahSpellingCard(title: "Quran 2:2 (2:1 outside the Kufan count): “in it is guidance”", [
                        RiwayahSpelling("Hafs", arabic: "فِيهِ هُدٗى", note: "fīhi hudā"),
                        RiwayahSpelling("as-Susi", arabic: "فِيه هُّدٗى", note: "The ha merged into the ha after it, the great merging (al-idgham al-kabir): fīh-hudā"),
                    ])

                    RiwayahSpellingCard(title: "Quran 1:4 (1:3 in the Madinan and Basran counts): “Master of the Day of Judgment”", [
                        RiwayahSpelling("Hafs, al-Kisa’i, Ya’qub, Khalaf", arabic: "مَٰلِكِ", note: "Māliki: the Owner"),
                        RiwayahSpelling("Qalun, Warsh and the others", arabic: "مَلِكِ", note: "Maliki: the King"),
                    ])

                    Text(verbatim: "Ayah numbers shift too, because each riwayah’s mushaf follows one of the schools of counting ayahs. The words are the same; only where an ayah ends differs. Hafs’s mushaf follows the Kufan count of 6,236 ayahs, Warsh’s and Qalun’s the later Madinan count of 6,214, al-Bazzi’s and Qunbul’s the Makkan count of 6,220, and Hisham’s and Ibn Dhakwan’s the Syrian count of 6,226.")
                        .font(.body)
                }

                Section(header: ArticleHeader("EVERY RIWAYAH AT A GLANCE")) {
                    Text(verbatim: "The twenty, in the classical order of their imams, with what each one’s mushaf shows. Tap one to read about its narrator.")
                        .font(.body)

                    RiwayahTraitsTable()
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Is a mushaf without the hamzah missing something?**")
                        .font(.body)
                    Text(verbatim: "No. The rasm is identical. A riwayah that eases or drops a hamzah is pronouncing the word as it was taught from the Prophet (peace and blessings be upon him), and its mushaf writes down what is pronounced. Each of the twenty is the complete Quran.")
                        .font(.body)

                    Text(articleMarkdown: "**Why does Hafs’s mushaf look like the “normal” one?**")
                        .font(.body)
                    Text(verbatim: "Because most printed mushafs today are Hafs, set in the eastern system of marks. The Madani dot for hamzat al-wasl is not a modern invention: it belongs to the dot-based way of marking that the mushafs of North and West Africa have kept for centuries.")
                        .font(.body)

                    Text(articleMarkdown: "**Can I recite Hafs from a Warsh mushaf?**")
                        .font(.body)
                    Text(verbatim: "Not reliably. The marks tell the reader what to pronounce, and a Warsh mushaf marks Warsh’s pronunciation: its hamzahs, its tilts, its madd. Recite each riwayah from its own mushaf, or with a teacher who has an ijazah in it.")
                        .font(.body)

                    Text(articleMarkdown: "**Are the counts on this page exact?**")
                        .font(.body)
                    Text(verbatim: "They are exact counts of the app’s own texts. Eight of the twenty (Hafs, Shu’bah, Warsh, Qalun, al-Bazzi, Qunbul, ad-Duri and as-Susi) are verified digital texts; the other twelve are beta texts read by machine from their printed mushafs, so their counts are close but not guaranteed to the last mark.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The twenty riwayat share one skeleton and one Quran. What their mushafs add, the hamzah or the dot that stands for it, ٱ or a dot for the joining alef, a filled dot or a hollow ring for a tilted vowel, a small waw, a madd sign, is each reading’s pronunciation written down faithfully, so that it can be recited exactly as it was taught.")
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    ArticleTermCard("Rasm", arabic: "رَسم", meaning: "The skeleton of the mushaf as the Companions wrote it, without dots or vowels. It is the same in every riwayah.")
                    ArticleTermCard("Dabt", arabic: "ضَبط", meaning: "From **ض-ب-ط**, to make exact: the marks added to the rasm (vowels, sukoon, shadda, madd and the signs for hamzah and wasl), which differ from one riwayah’s mushaf to another.")
                    ArticleTermCard("Tas-hil", arabic: "تَسهِيل", meaning: "From **س-ه-ل**, to make easy: pronouncing a hamzah between itself and the long vowel it leans towards. Its mushafs draw a dot in its place.")
                    ArticleTermCard("Ibdal", arabic: "إِبدَال", meaning: "From **ب-د-ل**, to exchange: turning a hamzah into a long vowel, as in يُومِنُونَ.")
                    ArticleTermCard("Naql", arabic: "نَقل", meaning: "From **ن-ق-ل**, to move: moving a hamzah’s vowel onto the quiet letter before it and dropping the hamzah, Warsh’s way.")
                    ArticleTermCard("Idkhal", arabic: "إِدخَال", meaning: "From **د-خ-ل**, to put in: a short alef inserted between two hamzahs.")
                    ArticleTermCard("Hamzat al-wasl", arabic: "هَمزَة الوَصل", meaning: "The joining alef, sounded only when a word begins with it; written ٱ in Hafs and with a dot in the Madani mushafs.")
                    ArticleTermCard("Imalah", arabic: "إِمَالَة", meaning: "From **م-ي-ل**, to lean: tilting a fatha towards a kasra, marked with a filled dot.")
                    ArticleTermCard("Taqlil", arabic: "تَقلِيل", meaning: "From **ق-ل-ل**, to lessen: the half tilt between a fatha and an imalah, marked with a hollow ring.")
                    ArticleTermCard("Silah", arabic: "صِلَة", meaning: "From **و-ص-ل**, to join: joining a pronoun’s vowel to a long vowel, written with a small waw.")
                    ArticleTermCard("Al-madd al-munfasil", arabic: "المَدّ المُنفَصِل", meaning: "The separated madd: a long vowel ending one word before a hamzah beginning the next.")
                    ArticleTermCard("Al-idgham al-kabir", arabic: "الإِدغَام الكَبِير", meaning: "The great merging: a voweled letter merged into the same or a close letter after it, a mark of as-Susi’s reading.")
                }

                ArticleSourcesSection(article: "RiwayatDifferencesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Riwayat on the Page")
        .selectableArticleList(article: "RiwayatDifferencesView")
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
                    Text(spelling.arabic)
                        .font(Font.arabic(Settings.hafsUthmaniFontName, size: 30, relativeTo: .title))
                        .foregroundColor(index == 0 ? .primary : accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(spelling.riwayat)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(spelling.note)
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
        RiwayahTraits(name: "al-Bazzi", from: "from Ibn Kathir", tag: Settings.Riwayah.buzzi, hamzah: "Eases the second of two", wasl: "ٱ", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "Qunbul", from: "from Ibn Kathir", tag: Settings.Riwayah.qunbul, hamzah: "Eases the second of two", wasl: "ٱ", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "ad-Duri", from: "from Abu ‘Amr", tag: Settings.Riwayah.duri, hamzah: "Eases the second of two", wasl: "Dot", dots: "748 filled, 626 hollow", silah: "No", madd: "Long as printed"),
        RiwayahTraits(name: "as-Susi", from: "from Abu ‘Amr", tag: Settings.Riwayah.susi, hamzah: "Softens the quiet hamzah", wasl: "Dot", dots: "620 filled, 593 hollow", silah: "No", madd: "Short"),
        RiwayahTraits(name: "Hisham", from: "from Ibn ‘Amir", tag: Settings.Riwayah.hisham, hamzah: "Pronounced; eased in one of two ways", wasl: "ٱ", dots: "Almost none", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Ibn Dhakwan", from: "from Ibn ‘Amir", tag: Settings.Riwayah.ibnDhakwan, hamzah: "Pronounced", wasl: "ٱ", dots: "374 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Shu’bah", from: "from ‘Asim", tag: Settings.Riwayah.shubah, hamzah: "Pronounced", wasl: "ٱ", dots: "79 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Hafs", from: "from ‘Asim", tag: Settings.Riwayah.hafsTag, hamzah: "Pronounced", wasl: "ٱ", dots: "One, in 11:41", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Khalaf", from: "from Hamzah", tag: Settings.Riwayah.khalaf, hamzah: "Pronounced; eased at a stop", wasl: "ٱ", dots: "1,922 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Khallad", from: "from Hamzah", tag: Settings.Riwayah.khallad, hamzah: "Pronounced; eased at a stop", wasl: "ٱ", dots: "1,911 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Abu al-Harith", from: "from al-Kisa’i", tag: Settings.Riwayah.abuHarith, hamzah: "Pronounced", wasl: "ٱ", dots: "1,608 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "ad-Duri", from: "from al-Kisa’i", tag: Settings.Riwayah.duriKisai, hamzah: "Pronounced", wasl: "ٱ", dots: "1,956 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Ibn Wardan", from: "from Abu Ja’far", tag: Settings.Riwayah.ibnWardan, hamzah: "Softens the quiet hamzah", wasl: "Dot", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "Ibn Jammaz", from: "from Abu Ja’far", tag: Settings.Riwayah.ibnJammaz, hamzah: "Softens the quiet hamzah", wasl: "Dot", dots: "Almost none", silah: "Always", madd: "Short"),
        RiwayahTraits(name: "Ruways", from: "from Ya’qub", tag: Settings.Riwayah.ruways, hamzah: "Eases the second of two", wasl: "Dot", dots: "92 filled", silah: "No", madd: "Short"),
        RiwayahTraits(name: "Rawh", from: "from Ya’qub", tag: Settings.Riwayah.rawh, hamzah: "Pronounced", wasl: "Dot", dots: "Almost none", silah: "No", madd: "Short"),
        RiwayahTraits(name: "Ishaq", from: "from Khalaf", tag: Settings.Riwayah.ishaq, hamzah: "Pronounced", wasl: "ٱ", dots: "1,871 filled", silah: "No", madd: "Long"),
        RiwayahTraits(name: "Idris", from: "from Khalaf", tag: Settings.Riwayah.idris, hamzah: "Pronounced", wasl: "ٱ", dots: "1,871 filled", silah: "No", madd: "Long"),
    ]
}

/// The twenty riwayat, one row each: the name, the imam, and the five traits as chips. A row opens the
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

            chips(traits)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func chips(_ traits: RiwayahTraits) -> some View {
        let items = [("Hamzah", traits.hamzah), ("Wasl", traits.wasl), ("Tilt", traits.dots),
                     ("Silah", traits.silah), ("Madd", traits.madd)]
        if #available(iOS 16.0, watchOS 9.0, *) {
            LeadingChipFlow(spacing: 5) {
                ForEach(items, id: \.0) { item in
                    chip(item.0, item.1)
                }
            }
        } else {
            Text(items.map { "\($0.0): \($0.1)" }.joined(separator: " \u{00B7} "))
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func chip(_ label: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(appearance.accent)
            Text(value)
                .font(.caption2.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(appearance.accent.opacity(0.1)))
    }
}
