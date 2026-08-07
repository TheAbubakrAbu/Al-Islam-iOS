import SwiftUI

struct TajweedMaddView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("MADD") {
                Text("Madd (Elongation) Rules")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Madd means to lengthen a sound. In Quranic recitation, this lengthening is measured, consistent, and rule-based, not stylistic.")
                    .font(.body)

                Text("Madd is counted in harakat (counts).")
                    .font(.body)
            }

            Section("1. MADD TABII (NATURAL)") {
                Text("This is the default madd. If no special condition follows, this is what you apply.")
                    .font(.body)

                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Alif (ا) preceded by fathah")
                    Text("Waw (و) preceded by dammah")
                    Text("Yaa (ي) preceded by kasrah")
                    Text("No hamzah or sukun after")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2 counts")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "قَالَ", english: "qa-la", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَقُولُ", english: "ya-qu-lu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "فِيهِ", english: "fi-hi", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نُور", english: "nur", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If nothing special comes after, 2 counts, no more, no less.")
                    .font(.body)
            }

            Section("2. MADD WAJIB MUTTASIL") {
                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter")
                    Text("Followed by a hamzah")
                    Text("In the same word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 4 or 5 counts (be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "جَاءَ", english: "jaaa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "السَّمَاءِ", english: "as-samaaa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "سُوءَ", english: "suuu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "شَيْءٌ", english: "shay (with extended yaa sound)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("It is called wajib because the lengthening is mandatory.")
                    .font(.body)
            }

            Section("3. MADD JAIZ MUNFASIL") {
                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter at the end of a word")
                    Text("Followed by a hamzah")
                    Text("In the next word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2, 4, or 5 counts (be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Choose one and stay consistent.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "فِي أَنفُسِكُمْ", english: "fi an-fu-si-kum", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قَالُوا إِنَّا", english: "qalu in-na", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "إِنَّا أَعْطَيْنَاكَ", english: "in-naa a'-tay-naa-ka", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If you lengthen it, always lengthen it. If you keep it short, always keep it short.")
                    .font(.body)
            }

            Section("3B. MADD MUNFASIL HUKMI (RULED SEPARATED)") {
                Text("A special, \u{201C}ruled\u{201D} (hukmi) form of Madd Munfasil. The madd letter and the hamzah are written inside one word, so it looks like Madd Muttasil, but it is recited as a separated madd.")
                    .font(.body)

                Text("Why It Is Separated")
                    .font(.subheadline.weight(.semibold))

                Text("The madd letter is actually the tail of a small joined particle, the vocative يَا (\u{201C}O \u{2026}\u{201D}) or the demonstrative هَا (\u{201C}here/these \u{2026}\u{201D}), and the hamzah begins the word it is attached to. So in meaning it is two words, even though the script joins them.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("How To Spot It")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A superscript madd letter, dagger alif (\u{0670}), small waw (\u{06E5}), or small yaa (\u{06E6}), carrying a maddah (\u{0653})")
                    Text("Immediately followed by a hamzah in the SAME written word")
                    Text("The carrier is the tail of a joined يَا or هَا particle")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2, 4, or 5 counts (treated exactly like Madd Munfasil; be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "يَٰٓأَيُّهَا", english: "ya + ayyuha (O you…)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "هَٰٓأَنتُمۡ", english: "ha + antum (here you are)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَٰٓإِبۡرَٰهِيمُ", english: "ya + Ibrahim (O Abraham)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَٰٓـَٔادَمُ", english: "ya + Adam (O Adam)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("One Word Can Hold Two Different Madds")
                    .font(.subheadline.weight(.semibold))

                Text("Do not assume every long madd in these words is hukmi. The word هَٰٓؤُلَآءِ contains BOTH:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("هَٰٓؤُ → Madd Munfasil Hukmi (the joined هَا particle)")
                    Text("لَآءِ → a true Madd Muttasil (a real alif + hamzah in one word)")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Only the superscript-particle sequence is munfasil hukmi. Every other madd in the word follows the normal rules.")
                    .font(.body)

                Text("The Complete Set In The Qur\u{2019}an")
                    .font(.subheadline.weight(.semibold))

                Text("هَٰٓأَنتُمۡ · هَٰٓؤُلَآءِ · أَهَٰٓؤُلَآءِ · وَهَٰٓؤُلَآءِ · يَٰٓـَٔادَمُ · وَيَٰٓـَٔادَمُ · يَٰٓأَبَانَا · يَٰٓأَبَتِ · يَٰٓإِبۡرَٰهِيمُ · يَٰٓإِبۡلِيسُ · يَٰٓأُخۡتَ · يَٰٓأَرۡضُ · يَٰٓأَسَفَىٰ · يَٰٓأَهۡلَ · يَٰٓأُوْلِي · يَٰٓأَيَّتُهَا · يَٰٓأَيُّهَ · يَٰٓأَيُّهَا")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)

                Text("(Counting orthographic variants such as يَٰٓأَبَانَآ and the pause-mark forms, this is 21 written words in the Hafs muṣḥaf.)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("3C. OTHER MADD TYPES & EXCEPTIONS") {
                Text("Several named madds and special cases sit alongside the main five. They matter for accurate recitation and for any rule engine.")
                    .font(.body)

                Text("Madd Badal: hamzah BEFORE the madd")
                    .font(.subheadline.weight(.semibold))
                Text("A hamzah followed by a madd letter (the reverse of muttasil). Read 2 counts; it is not lengthened like muttasil.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ءَامَنُوا", english: "aa-manu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ءَادَمَ", english: "aa-dama", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Madd \u{02BF}Iwad: tanwin fath at a stop")
                    .font(.subheadline.weight(.semibold))
                Text("When you stop on a word ending in tanwin fath (\u{064B}), the tanwin drops and the alif is stretched 2 counts. It is not aarid lis-sukoon.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "عَلِيمًا", english: "stop: a-li-maa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "غَفُورًا", english: "stop: gha-fu-raa", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Madd Tamkin: doubled yaa")
                    .font(.subheadline.weight(.semibold))
                Text("A kasrah + shaddah yaa meeting a madd yaa. Read 2 counts, taking care not to swallow either yaa.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلنَّبِيِّـۧنَ", english: "an-nabiy-yiin", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "حُيِّيتُم", english: "huy-yi-tum", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Madd Silah: the pronoun haa")
                    .font(.subheadline.weight(.semibold))
                Text("The attached pronoun \u{0647} (\u{201C}his/its\u{201D}) between two voweled letters is given a hidden waw/yaa. Sughra (small) is 2 counts; Kubra (large) is 4\u{2013}5 counts when a hamzah follows; it then behaves like Madd Munfasil.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "إِنَّهُۥ كَانَ", english: "sughra: in-na-hu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "بِهِۦٓ أَحَدَۢا", english: "kubra: bi-hii (before hamzah)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Dagger Alif & Tiny Madd Marks")
                    .font(.subheadline.weight(.semibold))
                Text("Superscript madd marks, dagger alif (\u{0670}), small waw (\u{06E5}), small yaa (\u{06E6}), are still a 2-count natural madd even though they are written tiny. When such a mark also carries a maddah (\u{0653}) and a hamzah follows, it becomes the munfasil-hukmi case above.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Genuine Muttasil Written With A Dagger Alif")
                    .font(.subheadline.weight(.semibold))
                Text("Not every dagger alif + hamzah is hukmi. When both sit inside one true word (no joined يَا/هَا particle), it is ordinary Madd Muttasil, for example أُوْلَٰٓئِكَ, مَلَٰٓئِكَة, and إِسۡرَٰٓءِيل.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "أُوْلَٰٓئِكَ", english: "muttasil: ula-aa-ika", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "مَلَٰٓئِكَةِ", english: "muttasil: mala-aa-ikah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("4. ENDING MADD") {
                Text("Ending madd applies when you stop on a word and the ending sound changes because of waqf.")
                    .font(.body)

                Text("It includes Madd Aarid lis-Sukoon and Madd Leen.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Madd Leen")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A sakin yaa or sakin waaw")
                    Text("Preceded by fathah")
                    Text("You stop on the word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 12) {
                    Text("خَوۡف")
                    Text("بَيۡت")
                    Text("قُرَيۡش")
                }
                .font(arabicHeadlineFont)
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Madd Aarid lis-Sukoon")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلۡعَٰلَمِينَ", english: "stop: temporary sukoon", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلرَّحِيمِ", english: "stop: ٱلرَّحِيمۡ", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَسۡتَعِينُ", english: "stop: temporary sukoon", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2, 4, or 6 counts. Madd Leen should follow the stopping style you choose for Madd Aarid lis-Sukoon, and should not be longer than it.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("5. MADD LAZIM") {
                Text("This is the strongest and longest madd.")
                    .font(.body)

                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter")
                    Text("Followed by a permanent sukun")
                    Text("Either in a word or a letter name")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 6 counts (always)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("A. MADD LAZIM HARFI") {
                Text("Occurs in the disconnected letters at the start of some surahs.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "الم", english: "Alif (no madd) Laaaaaam (6) Miiiiiim (6)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "كهيعص", english: "Kaaaaaaf (6) Haa (2) Yaa (2) 'Ayyyn (4-6) Saaaaaad (6)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "حم", english: "Haa (2) Miiiiiim (6)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If the letter name itself contains a madd followed by sukun, it is 6 counts.")
                    .font(.body)
            }

            Section("B. MADD LAZIM KALIMI") {
                Text("Less common, but very important.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "الضَّالِّينَ", english: "ad-daaallin", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "الطَّامَّة", english: "at-taaammah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("OPENING LETTERS (MUQATTA’AT)") {
                Text("Some opening letters do not contain madd.")
                    .font(.body)

                Text("Read Normally (No Madd)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ألف (alone): no madd")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Have Madd")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("6 counts: نقص عسلكم")
                    Text("2 counts: حي طهر")
                    Text("'Ayn (ع) is a leen letter: 4 or 6 counts.")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("ن ق ص ع س ل ك م")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("ح ي ط ه ر")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Not every opening letter is lengthened. Read the letter name.")
                    .font(.body)
            }

            Section("KEY TEACHING RULES") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Madd is measured, not emotional. Do not stretch because it sounds nice.")
                    Text("Consistency matters more than length. 4 everywhere is better than random 2-6.")
                    Text("Never add a jump or break mid-madd. One smooth airflow from start to finish.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Madd")
    }
}

struct TajweedQalqalahView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("QALQALAH") {
                Text("Qalqalah (Echo) Letters")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Qalqalah is a natural bouncing sound that occurs when certain letters are in a sukun state. It is not a vowel and not silence.")
                    .font(.body)

                Text("Its purpose is to prevent the sound from becoming cut off or broken.")
                    .font(.body)
            }

            Section("THE FIVE LETTERS") {
                Text("The qalqalah letters are:")
                    .font(.body)

                Text("ق ط ب ج د")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Section("WHAT QALQALAH IS (AND IS NOT)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A slight echo")
                    Text("Natural and effortless")
                    Text("Not a fathah")
                    Text("Not an added vowel")
                    Text("Not exaggerated")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Think of it as releasing the letter, not opening the mouth.")
                    .font(.body)
            }

            Section("WHEN QALQALAH OCCURS") {
                Text("Qalqalah occurs when one of the five letters:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Has a sukun, or")
                    Text("Is stopped on (waqf)")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "أَحَدْ", english: "aha(d)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَجْعَل", english: "ya(j)-'al", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "أَجْر", english: "a(j)r", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَقْطَع", english: "ya(q)ta'", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَبْتَغُون", english: "ya(b)taghun", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Notice: the sound is heard, but no vowel is added.")
                    .font(.body)
            }

            Section("WHY QALQALAH EXISTS") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Without qalqalah, the letter would sound cut off.")
                    Text("Without qalqalah, words would sound unnatural or unclear.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qalqalah preserves:")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Clarity")
                    Text("Letter identity")
                    Text("Flow of speech")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qalqalah exists because Arabic does not allow these letters to die silently.")
                    .font(.body)
            }

            Section("IMPORTANT REMINDER") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Qalqalah is a sound, not a vowel.")
                    Text("If it sounds like \"a\", it is wrong.")
                    Text("If it disappears, it is also wrong.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Qalqalah")
    }
}

struct TajweedIdghamIkhfaView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("NOON SAKINAH AND TANWEEN") {
                Text("Noon Sakinah and Tanween Rules")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Tanween and noon saakinah are closely related, so this section groups the merge and hidden-sound rules together.")
                    .font(.body)
            }

            Section("TANWEEN PRONUNCIATION") {
                Text("Although tanween appears as vowel marks, it is pronounced as a hidden noon sound (نْ) at the end of the word.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "بًا",
                        pronunciation: "بَنْ (ban)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "بٌ",
                        pronunciation: "بُنْ (bun)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "بٍ",
                        pronunciation: "بِنْ (bin)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("What happens to this hidden sound depends entirely on the letter that follows.")
                    .font(.body)
            }

            Section("MUSHAF TANWEEN HINTS") {
                Text("The Mushaf often hints whether tanween is normal idhaar or whether a special noon sakinah rule is coming.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "رٞ  لٖ  رٗ",
                        pronunciation: "special tanween marks",
                        rule: "Apply ikhfaa, idghaam, iqlaab, or ghunnah by the next letter",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "نٌ  قٍ  بً",
                        pronunciation: "normal tanween marks",
                        rule: "Usually clear idhaar when followed by idhaar letters",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("1. IDHAAR (CLEAR)") {
                Text("The noon sound is pronounced clearly and fully, with no ghunnah merge.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ء ه ع ح غ خ")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedPairRow(arabic: "مِنْ هَادٍ", english: "min hadin", arabicFont: arabicHeadlineFont)

                Text("The throat letters prevent merging, so the sound must remain clear.")
                    .font(.body)
            }

            Section("2. IDGHAAM (MERGING)") {
                Text("The noon sound merges into the following letter.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ي ر م ل و ن")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("With Ghunnah")
                    .font(.subheadline.weight(.semibold))

                Text("ي ن م و")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Without Ghunnah")
                    .font(.subheadline.weight(.semibold))

                Text("ل ر")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "مَن يَقُول",
                        pronunciation: "may-yaqul",
                        rule: "Idghaam with ghunnah",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "مِن رَبِّهِم",
                        pronunciation: "mir-rabbihim",
                        rule: "Idghaam without ghunnah",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("With ghunnah: nasal sound. Without ghunnah: clean merge, no nasalization.")
                    .font(.body)
            }

            Section("3. IQLAAB (CONVERSION)") {
                Text("The noon sound changes into a miim with ghunnah.")
                    .font(.body)

                Text("Letter")
                    .font(.subheadline.weight(.semibold))

                Text("ب")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedRuleRow(
                    arabic: "سَمِيعٌۢ بَصِير",
                    pronunciation: "samium-basir",
                    rule: "",
                    arabicFont: arabicHeadlineFont
                )

                Text("The noon is not pronounced. It becomes a hidden miim.")
                    .font(.body)
            }

            Section("4. IKHFAA (HIDDEN)") {
                Text("The noon is hidden, pronounced with ghunnah, without full clarity or full merging.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ت ث ج د ذ ز س ش ص ض ط ظ ف ق ك, the remaining 15 letters (all except the idhaar, idghaam, and iqlaab letters)")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedRuleRow(
                    arabic: "مِن شَرِّ",
                    pronunciation: "min-sharri (nasal)",
                    rule: "",
                    arabicFont: arabicHeadlineFont
                )

                Text("The tongue does not fully touch the articulation point.")
                    .font(.body)
            }

            Section("GHUNNAH STRENGTH") {
                Text("Not all ghunnah is the same strength.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Strongest")
                        .font(.subheadline.weight(.semibold))
                    Text("Noon or Miim with shaddah (نّ / مّ)")
                        .foregroundColor(.secondary)

                    Text("Medium")
                        .font(.subheadline.weight(.semibold))
                    Text("Idghaam with ghunnah, then Ikhfaa")
                        .foregroundColor(.secondary)

                    Text("None")
                        .font(.subheadline.weight(.semibold))
                    Text("Idghaam without ghunnah")
                        .foregroundColor(.secondary)
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("KEY TEACHING LINE") {
                Text("Tanween is not a vowel. It is a hidden noon sound in disguise. The rule is determined by the next letter, not the vowel mark.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Noon Sakinah and Tanween")
    }
}

struct TajweedMeemSakinahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                Link("Meem Sakinah Rules", destination: URL(string: "https://www.youtube.com/watch?v=MAvDrZgWRTs")!)
            }

            Section("MEEM SAKINAH") {
                Text("Meem Sakinah means a meem with sukoon: مْ. In tajweed, Meem Sakinah has three rules, and all three are called Shafawi because they are pronounced from the lips. The word Shafawi comes from shafah, meaning \"lip.\"")
                    .font(.body)

                Text("The three rules are:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ikhfaa Shafawi")
                    Text("Idgham Shafawi")
                    Text("Idhaar Shafawi")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("These rules depend on the letter that comes after the Meem Sakinah.")
                    .font(.body)
            }

            Section("1. IKHFAA SHAFAWI") {
                Text("Ikhfaa Shafawi occurs when Meem Sakinah (مْ) is followed by the letter Ba (ب).")
                    .font(.body)

                Text("When this happens, the meem is hidden lightly while keeping ghunnah for two counts. The lips come close together, but the meem is not pronounced with full clarity like normal Idhaar.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                Text("مْ + ب = Ikhfaa Shafawi")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                Text("أَم بِهِۦ جِنَّةٌۢ")
                    .font(Font.arabic(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("In this example, the Meem Sakinah in أَم is followed by ب in بِهِۦ, so it is read with Ikhfaa Shafawi.")
                    .font(.body)

                Text("How to read it: am bihi, with ghunnah for two counts.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. IDGHAM SHAFAWI") {
                Text("Idgham Shafawi occurs when Meem Sakinah (مْ) is followed by another Meem (م).")
                    .font(.body)

                Text("When this happens, the first meem merges into the second meem, and the result is read as a doubled meem with ghunnah for two counts.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                Text("مْ + م = Idgham Shafawi")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                Text("وَلَهُم مَّا يَشْتَهُونَ")
                    .font(Font.arabic(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("In this example, the Meem Sakinah at the end of لَهُم is followed by another meem in مَّا, so the two meems merge.")
                    .font(.body)

                Text("How to read it: lahum maa, with ghunnah for two counts.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("3. IDHAAR SHAFAWI") {
                Text("Idhaar Shafawi occurs when Meem Sakinah (مْ) is followed by any letter other than Ba (ب) or Meem (م).")
                    .font(.body)

                Text("When this happens, the meem is pronounced clearly with no extra ghunnah beyond its normal sound.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                Text("مْ + any letter except ب or م = Idhaar Shafawi")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                Text("وَمَا بَلَغُوا۟ مِعْشَارَ مَآ ءَاتَيْنَٰهُمْ فَكَذَّبُوا۟ رُسُلِى")
                    .font(Font.arabic(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("In this example, the Meem Sakinah in ءَاتَيْنَٰهُمْ is followed by ف, so it is read with Idhaar Shafawi.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("لَكُمْ فِيهَا")
                    Text("عَلَيْكُمْ سَلَامٌ")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("MEEM MUSHADDADAH") {
                Text("A related rule is Meem Mushaddadah, which is a meem with shaddah: مّ.")
                    .font(.body)

                Text("Whenever you see مّ, it must be pronounced with a strong ghunnah for two counts.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ثُمَّ")
                    Text("لَمَّا")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This is not one of the three Meem Sakinah rules, but it is closely related because it also involves ghunnah on meem.")
                    .font(.body)
            }

            Section("QUICK SUMMARY") {
                Text("Meem Sakinah = مْ")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Ikhfaa Shafawi: مْ + ب, hide the meem with ghunnah. Example: أَم بِهِۦ")
                    Text("2. Idgham Shafawi: مْ + م, merge the two meems with ghunnah. Example: لَهُم مَّا")
                    Text("3. Idhaar Shafawi: مْ + any letter except ب or م, pronounce the meem clearly. Example: لَكُمْ فِيهَا")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }

            Section("SHORT SUMMARY") {
                Text("Meem Sakinah has three rules. If it is followed by Ba, it is read with Ikhfaa Shafawi, meaning the meem is hidden with ghunnah. If it is followed by another Meem, it is read with Idgham Shafawi, meaning the two meems merge with ghunnah. If it is followed by any other letter, it is read with Idhaar Shafawi, meaning the meem is pronounced clearly.")
                    .font(.body)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Meem Sakinah")
    }
}

struct TajweedAaridLisSukoonView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                Link("Tajweed Hints: 4 Types of Sukoon", destination: URL(string: "https://www.youtube.com/watch?v=MAvDrZgWRTs")!)
            }

            Section("The 4 Types of Sukoon Marks in the Qur’an") {
                Text("In the Uthmani script of the Qur’an, letters may carry different kinds of sukoon-style markings. These marks tell the reciter whether a letter is pronounced, skipped, pronounced only when stopping, or affected by a special tajweed rule.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("1. Normal Sukoon: Pronounce the Letter Without a Vowel") {
                Text("This is the common Qur’anic sukoon mark written like ـۡ above a consonant. It means the letter has no vowel, but the letter itself is still pronounced clearly.")
                    .font(.body)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ")
                    .font(Font.arabic(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Simple rule: Pronounce the letter, but do not add a vowel after it.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. Permanent Silent Letter: Always Skip It") {
                Text("This mark shows that the letter is written in the Qur’an’s script but is not pronounced. You skip it whether you continue reciting or stop.")
                    .font(.body)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("بِأَيۡيْدٖ")
                    .font(Font.arabic(settings.fontArabic, size: 22))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Simple rule: The letter is written, but never pronounced.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("3. Stop-Only Letter: Pronounce It Only If You Stop") {
                Text("This mark means the letter is ignored when continuing, but pronounced if you stop on the word.")
                    .font(.body)

                Text("Examples:")
                    .font(.subheadline.weight(.semibold))

                Text("قَوَارِيرَا۠ (stop: قَوَارِيرَا)")
                    .font(.body)

                Text("أَنَا۠ (in context: قُلۡ إِنَّمَآ أَنَا۠ بَشَرٞ مِّثۡلُكُمۡ)")
                    .font(.body)

                Text("Simple rule: Pronounce it when stopping, skip it when continuing.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("4. No Sukoon Mark: Madd Letter or Special Tajweed Rule") {
                Text("Sometimes a letter has no sukoon mark and no vowel mark. This usually means one of two things: either it is a madd letter (stretched for two counts), or a consonant affected by a special tajweed rule.")
                    .font(.body)

                Text("Examples:")
                    .font(.subheadline.weight(.semibold))

                Text("يُقِيمُونَ: madd letter example")
                    .font(.body)

                Text("يُنفِقُونَ: special tajweed (ikhfāʾ) example")
                    .font(.body)

                Text("Simple rule: No mark usually means either natural madd or a special recitation rule is happening.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Note about the example رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ: there is a qalqalah effect in the consonant, but there is no special visual marking for qalqalah in the Uthmani script; you must know it by rule or consult the tajweed colors in the app to see it highlighted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Super Simple Summary") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. ـۡ Normal sukoon: Pronounce the consonant with no vowel. Example: رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ")
                    Text("2. Silent written letter: Skip it always. Example: كَانُواْ")
                    Text("3. Stop-only letter: Pronounce it only when stopping. Example: أَنَا۠ / قَوَارِيرَا۠")
                    Text("4. No mark: Either a madd letter or a special tajweed rule. Example: يُقِيمُونَ / يُنفِقُونَ")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("4 Sukoon")
    }
}

struct TajweedHamzatulWaslView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                VStack(alignment: .leading, spacing: 6) {
                    Link("Hamzatul-Wasl short 1", destination: URL(string: "https://www.youtube.com/shorts/SpA7EtX3jMA")!)
                    Link("Hamzatul-Wasl short 2", destination: URL(string: "https://www.youtube.com/shorts/xNn-pR4eoHM")!)
                    Link("Hamzatul-Wasl short 3", destination: URL(string: "https://www.youtube.com/shorts/79Ku0wSKf9Q")!)
                }
            }

            Section("Hamzatul-Wasl: The Connecting Hamzah") {
                Text("Hamzatul-Wasl means “the hamzah of connection.” It is only pronounced when beginning recitation from that word; if you connect from the previous word, the Hamzatul-Wasl is dropped and not pronounced.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("In the Uthmani Qur’an script, Hamzatul-Wasl is usually written as an alif with a small ṣād-like sign above it: ٱ")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Common examples:")
                    .font(.subheadline.weight(.semibold))

                VStack(spacing: 6) {
                    Text("ٱبۡنُوا")
                    Text("ٱمۡشُوا")
                    Text("ٱقۡضُوا")
                    Text("ٱئۡتُوا")
                    Text("ٱئۡتُونِي")
                }
                .font(Font.arabic(settings.fontArabic, size: 22))
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .center)

                Text("Key rule: If you start from the word, pronounce Hamzatul-Wasl. If you connect from the previous word, drop it.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("1. Hamzatul-Wasl Is Dropped When Connecting") {
                Text("When reciting continuously, Hamzatul-Wasl is not pronounced. The previous word connects directly into the next word.")
                    .font(.body)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِ")
                    .font(Font.arabic(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("When continuing: dhālika l-kitāb (you do not say al- as a separate hamzah). If you stop and then begin from the word, pronounce the Hamzatul-Wasl: al-kitāb.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. Hamzatul-Wasl With “Al” Takes Fatḥah") {
                Text("When a word begins with the definite article ٱل, Hamzatul-Wasl is pronounced with fatḥah if you begin from that word (al-kitāb → al-kitāb; al-rahmān → ar-raḥmān).")
                    .font(.body)

                VStack(spacing:6) {
                    Text("ٱلۡكِتَٰبُ → al-kitāb")
                    Text("ٱلرَّحۡمَٰنُ → ar-raḥmān")
                    Text("ٱلصَّمَدُ → aṣ-ṣamad")
                    Text("ٱللَّهُ → Allāh")
                }
                .font(Font.arabic(settings.fontArabic, size: 20))
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .center)

                Text("Note: alif itself is treated as a vowel/madd letter; the opening sound of ٱل is the Hamzatul-Wasl, realized as an initial “a”.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("3. Hamzatul-Wasl in Nouns Usually Takes Kasrah") {
                Text("In nouns that begin with Hamzatul-Wasl and do not begin with ٱل, the Hamzatul-Wasl is pronounced with kasrah when starting (e.g. ٱسۡمُهُۥ → ismuhu).")
                    .font(.body)

                VStack(spacing:6) {
                    Text("ٱسۡم → ism")
                    Text("ٱبۡن → ibn")
                    Text("ٱبۡنَيۡ → ibnay")
                }
                .font(Font.arabic(settings.fontArabic, size: 20))
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Section("4. Hamzatul-Wasl in Verbs Depends on the Third Letter") {
                Text("For verbs, examine the third letter: if it has ḍammah, begin with “u”; if it has fatḥah or kasrah, begin with “i”. Exception: when that ḍammah is incidental (ʿāriḍah), begin with kasrah instead: ٱمْشُوا، ٱقْضُوا، ٱبْنُوا، ٱمْضُوا، ٱئْتُوا are read imshu, iqdu, ibnu, imdu, i’tu, not umshu / uqdu / ubnu.")
                    .font(.body)

                Text("Example (third letter ḍammah → start with 'u'):")
                    .font(.subheadline.weight(.semibold))

                Text("ٱتۡلُ → utlu (when starting); when connected: watlu")
                    .font(Font.arabic(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Simple rule: Third letter ḍammah → start with 'u'; otherwise start with 'i'.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("5. Special Verb Exceptions") {
                Text("Some verbs are special cases (e.g. ٱئۡتُوا / ٱئۡتُونِي) and are learned individually; they may behave differently than the third-letter rule.")
                    .font(.body)

                Text("Example: ٱئۡتُونِي → iʾtūnī when starting.")
                    .font(Font.arabic(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Section("6. Hamzatul-Wasl After Tanwīn: Add a Connecting Nūn") {
                Text("When a word ending in tanwīn is followed by a word beginning with Hamzatul-Wasl, a connecting 'nِ' (kasrah nūn) is commonly inserted when continuing (e.g. بِغُلَٰمٍ ٱسۡمُهُۥ → bighulāmin ismuhu).")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("بِغُلَٰمٍ ٱسۡمُهُۥ → بِغُلَٰمِنِ سۡمُهُۥ")
                    .font(Font.arabic(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Section("Summary: How to Start Hamzatul-Wasl") {
                Text("1. If the word begins with ٱل → start with 'a' (fatḥah). 2. If a noun without ٱل → start with 'i' (kasrah). 3. If a verb → check the third letter (ḍammah→'u', otherwise 'i'). 4. Some words are exceptions and must be learned individually.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("What Happens When Continuing") {
                Text("Hamzatul-Wasl is dropped when continuing from the previous word (e.g. ذَٰلِكَ ٱلۡكِتَٰبُ → dhālika l-kitāb; وَٱتۡلُ → watlu).")
                    .font(.body)
            }

            Section("SHORT SUMMARY") {
                Text("Hamzatul-Wasl is the connecting hamzah, pronounced only when starting from the word. Nouns usually take 'i', words with ٱل start with 'a', verbs depend on the third letter, and tanwīn before Hamzatul-Wasl connects with an 'nِ' sound.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Hamzatul-Wasl")
    }
}

struct TajweedWaqfView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("WAQF") {
                Text("Waqf (Stopping in the Quran)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("What Is Waqf?")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Waqf (وَقف) means to stop or pause while reciting the Quran, with the intention of resuming the recitation correctly afterward.")
                    .font(.body)

                Text("The word comes from the Arabic root و ق ف, meaning to stop, stand, or halt. In tajweed, it refers specifically to stopping at the end of a word while preserving the meaning, pronunciation, and beauty of the Quran.")
                    .font(.body)

                Text("Waqf is not random breathing. It is a deliberate, rule-based pause guided by the Mushaf and the meaning of the ayah.")
                    .font(.body)
            }

            Section("WHY WAQF MATTERS") {
                Text("Stopping incorrectly can:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Change the meaning of an ayah")
                    Text("Create theological errors")
                    Text("Break the grammatical structure")
                    Text("Distort the listener's understanding")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Correct waqf:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preserves meaning")
                    Text("Maintains clarity")
                    Text("Reflects proper understanding")
                    Text("Shows respect for the words of Allah")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Ali ibn Abi Talib (may Allah be pleased with him) defined tartil as: \"the tajweed of the letters and knowledge of the places of stopping.\"")
                    .font(.body)
            }

            Section("WAQF IN THE MUSHAF") {
                Text("Even without colors, the Mushaf signals where to stop or continue using:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Special symbols")
                    Text("Word endings")
                    Text("Sentence structure")
                    Text("Completion of meaning")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("A reader trained in waqf reads with understanding, not just sound.")
                    .font(.body)
            }

            Section("LAST LETTER WHEN YOU STOP") {
                Text("When stopping, the ending of the word almost always changes.")
                    .font(.body)

                Text("The Golden Rule of Waqf")
                    .font(.subheadline.weight(.semibold))

                Text("Every vowel at the end of a word becomes a sukun when stopping, except special cases.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("1. FINAL DAMMAH, FATHAH, OR KASRAH") {
                Text("When stopping, the vowel is dropped, and the letter becomes saakin.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "الْعَالَمِينَ -> الْعَالَمِينْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "نَسْتَعِينُ -> نَسْتَعِينْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "الْكِتَابِ -> الْكِتَابْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("The sound is cut cleanly, without adding extra vowels.")
                    .font(.body)
            }

            Section("2. STOPPING ON TANWEEN") {
                Text("Tanween is never pronounced when stopping.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "بَصِيرٌ -> بَصِيرْ",
                        pronunciation: "Dammatayn",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "عَلِيمٍ -> عَلِيمْ",
                        pronunciation: "Kasratayn",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "رَحْمَةً -> رَحْمَةْ",
                        pronunciation: "Fathatayn (no alif)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "كِتَابًا -> كِتَابَا",
                        pronunciation: "Fathatayn + alif",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Important: the tanween itself is dropped completely when stopping. There is no nuun sound and no vowel.")
                    .font(.body)

                Text("Exception: when fathatayn is followed by an alif (ا), the tanween is dropped but the alif is still pronounced, producing a long a sound.")
                    .font(.body)

                Text("This is because the alif is a written long vowel, not part of the tanween itself.")
                    .font(.body)

                Text("Rule to remember: fathatayn disappears when stopping, but a written alif remains pronounced.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("3. TAA MARBUTAH (ة)") {
                Text("When stopping, taa marbutah is pronounced as haa saakinah (ـهْ).")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "رَحْمَةٌ -> رَحْمَهْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "جَنَّةٍ -> جَنَّهْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This rule is consistent everywhere in the Quran.")
                    .font(.body)
            }

            Section("4. LONG VOWELS (ا، و، ي)") {
                Text("Long vowels remain unchanged when stopping.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "هُدَى -> هُدَى",
                        pronunciation: "Unchanged",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "يَقُولُ -> يَقُولْ",
                        pronunciation: "Final vowel drops, long sound remains",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "فِي -> فِي",
                        pronunciation: "Unchanged",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("No shortening occurs.")
                    .font(.body)
            }

            Section("WAQF TAM (COMPLETE)") {
                Text("The meaning is complete and independent.")
                    .font(.body)
                Text("Best place to stop.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF KAFI (SUFFICIENT)") {
                Text("The meaning is complete, but connected to what follows.")
                    .font(.body)
                Text("Permissible to stop.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF HASAN (GOOD)") {
                Text("The wording makes sense, but the meaning is incomplete.")
                    .font(.body)
                Text("Allowed only for breath, not preferred.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF QABIH (BAD)") {
                Text("Stopping breaks the meaning or creates error.")
                    .font(.body)
                Text("Not allowed.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("DANGEROUS STOP EXAMPLE") {
                Text("Example of a dangerous stop:")
                    .font(.subheadline.weight(.semibold))

                Text("لَا تَقْرَبُوا الصَّلَاةَ")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Stopping here implies \"Do not approach prayer,\" which is incorrect.")
                    .font(.body)

                Text("The ayah continues: وَأَنتُمْ سُكَارَى")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("WAQF SYMBOLS") {
                QuranSignsSectionContent(accentColor: settings.accentColor.color)

                Text("These symbols guide meaning, not breathing convenience.")
                    .font(.body)
            }

            Section("REMEMBER") {
                Text("Waqf is not about breath. It is about meaning.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("You stop where the meaning stops, not where the lungs give up.")
                    .font(.body)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Waqf")
    }
}

struct TajweedExampleRow: View {
    let arabic: String
    let middle: String
    let trailing: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(middle)
                .font(.subheadline)
            Text(trailing)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TajweedPairRow: View {
    let arabic: String
    let english: String
    let arabicFont: Font

    var body: some View {
        HStack {
            Text(english)
                .font(.subheadline)

            Spacer()

            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

struct TajweedRuleRow: View {
    let arabic: String
    let pronunciation: String
    let rule: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(pronunciation)
                .font(.subheadline)
            Text(rule)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TajweedWhyRow: View {
    let arabic: String
    let english: String
    let why: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(english)
                .font(.subheadline)
            Text(why)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TajweedTopicPlaceholderView: View {
    @ObservedObject var settings = Settings.shared

    let title: String

    var body: some View {
        List { }
            .applyConditionalListStyle()
            .navigationTitle(title)
    }
}

#Preview {
    AlIslamPreviewContainer {
        TajweedFoundationsView()
    }
}
