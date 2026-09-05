import SwiftUI

#if os(iOS)

// A machine comparison of the twenty riwayaat against Hafs an Asim, reached from the last section
// of the Qiraat guide ("Riwayah Statistics").
//
// WHY IT LEADS WITH THE CAVEAT. Everything else in the Qiraat guide is the settled biographical and
// historical record. This page is not: it is the output of a program that read the printed mushafs
// and diffed them, and while the method is sound the numbers carry the extraction's own errors. A
// reader who meets a table of "how much each riwayah differs" without that context can badly misread
// it, so the page opens with the caveat rather than the data. (Until 2026-09-04 it also hid behind
// seven taps on the guide's closing line; Abu could not find it, so it is a plain row now.)
//
// SOURCING. The figures are this app's own measurements, described in "How these numbers were
// produced" below. The framing around them (why the counting traditions differ, what a printed
// mushaf can and cannot record) follows the standard works named in the further-reading section.

struct QiraahComparisonRow: Identifiable {
    let id = UUID()
    let narrator: String
    let imam: String
    /// Ayahs in this riwayah's own counting tradition.
    let ayahs: Int
    /// Words in the whole Quran, pause marks and ayah numbers excluded.
    let words: Int
    /// Words identical to Hafs, out of Hafs's 77,430.
    let identical: Int
    /// Same consonantal skeleton, different vowels or spelling.
    let sameSkeleton: Int
    /// A different consonantal skeleton: a genuinely different word form.
    let differentWord: Int

    var identicalPercent: Double { 100.0 * Double(identical) / 77_430.0 }
}

struct QiraahPairRow: Identifiable {
    let id = UUID()
    let imam: String
    let narrators: String
    let identical: Int
    let percent: Double
    let differentWord: Int
}

enum QiraatTextAnalysis {
    /// Hafs's own word total, the denominator for every percentage on the page.
    static let hafsWords = 77_430
    static let hafsAyahs = 6_236

    /// In mushaf order, imam by imam, each imam's two narrators together.
    static let rows: [QiraahComparisonRow] = [
        .init(narrator: "Qalun", imam: "Nafi al-Madani", ayahs: 6214, words: 77430,
              identical: 56971, sameSkeleton: 19649, differentWord: 822),
        .init(narrator: "Warsh", imam: "Nafi al-Madani", ayahs: 6214, words: 77427,
              identical: 54562, sameSkeleton: 21367, differentWord: 1544),
        .init(narrator: "al-Bazzi", imam: "Ibn Kathir al-Makki", ayahs: 6220, words: 77432,
              identical: 65019, sameSkeleton: 12040, differentWord: 380),
        .init(narrator: "Qunbul", imam: "Ibn Kathir al-Makki", ayahs: 6220, words: 77433,
              identical: 65064, sameSkeleton: 12035, differentWord: 337),
        .init(narrator: "ad-Duri", imam: "Abu Amr al-Basri", ayahs: 6217, words: 77426,
              identical: 61241, sameSkeleton: 15881, differentWord: 311),
        .init(narrator: "as-Susi", imam: "Abu Amr al-Basri", ayahs: 6217, words: 77468,
              identical: 55599, sameSkeleton: 20809, differentWord: 1093),
        .init(narrator: "Hisham", imam: "Ibn Amir ash-Shami", ayahs: 6226, words: 77425,
              identical: 76039, sameSkeleton: 1152, differentWord: 244),
        .init(narrator: "Ibn Dhakwan", imam: "Ibn Amir ash-Shami", ayahs: 6226, words: 77425,
              identical: 76000, sameSkeleton: 1194, differentWord: 240),
        .init(narrator: "Shu'bah", imam: "Asim al-Kufi", ayahs: 6236, words: 77431,
              identical: 76756, sameSkeleton: 540, differentWord: 136),
        .init(narrator: "Hafs", imam: "Asim al-Kufi", ayahs: 6236, words: 77430,
              identical: 77430, sameSkeleton: 0, differentWord: 0),
        .init(narrator: "Khalaf", imam: "Hamzah az-Zayyat", ayahs: 6236, words: 77435,
              identical: 70871, sameSkeleton: 6327, differentWord: 242),
        .init(narrator: "Khallad", imam: "Hamzah az-Zayyat", ayahs: 6236, words: 77431,
              identical: 74031, sameSkeleton: 3183, differentWord: 222),
        .init(narrator: "Abu al-Harith", imam: "al-Kisai", ayahs: 6236, words: 77436,
              identical: 74155, sameSkeleton: 3022, differentWord: 264),
        .init(narrator: "ad-Duri an al-Kisai", imam: "al-Kisai", ayahs: 6236, words: 77434,
              identical: 73828, sameSkeleton: 3351, differentWord: 260),
        .init(narrator: "Ruways", imam: "Ya'qub al-Hadrami", ayahs: 6204, words: 77428,
              identical: 59053, sameSkeleton: 18107, differentWord: 278),
        .init(narrator: "Rawh", imam: "Ya'qub al-Hadrami", ayahs: 6206, words: 77425,
              identical: 59311, sameSkeleton: 17889, differentWord: 233),
        .init(narrator: "Ibn Wardan", imam: "Abu Ja'far al-Madani", ayahs: 6214, words: 77424,
              identical: 49447, sameSkeleton: 26552, differentWord: 1561),
        .init(narrator: "Ibn Jammaz", imam: "Abu Ja'far al-Madani", ayahs: 6214, words: 77425,
              identical: 49452, sameSkeleton: 26551, differentWord: 1557),
        .init(narrator: "Ishaq", imam: "Khalaf al-Ashir", ayahs: 6236, words: 77432,
              identical: 74395, sameSkeleton: 2834, differentWord: 208),
        .init(narrator: "Idris", imam: "Khalaf al-Ashir", ayahs: 6236, words: 77432,
              identical: 74395, sameSkeleton: 2834, differentWord: 208),
    ]

    /// Each imam's two narrators measured against each other rather than against Hafs.
    static let pairs: [QiraahPairRow] = [
        .init(imam: "Nafi", narrators: "Qalun and Warsh",
              identical: 65972, percent: 85.20, differentWord: 852),
        .init(imam: "Ibn Kathir", narrators: "al-Bazzi and Qunbul",
              identical: 77233, percent: 99.74, differentWord: 59),
        .init(imam: "Abu Amr", narrators: "ad-Duri and as-Susi",
              identical: 70484, percent: 90.98, differentWord: 724),
        .init(imam: "Ibn Amir", narrators: "Hisham and Ibn Dhakwan",
              identical: 76676, percent: 99.03, differentWord: 23),
        .init(imam: "Asim", narrators: "Shu'bah and Hafs",
              identical: 76756, percent: 99.13, differentWord: 136),
        .init(imam: "Hamzah", narrators: "Khalaf and Khallad",
              identical: 73959, percent: 95.51, differentWord: 48),
        .init(imam: "al-Kisai", narrators: "Abu al-Harith and ad-Duri",
              identical: 77059, percent: 99.51, differentWord: 7),
        .init(imam: "Ya'qub", narrators: "Ruways and Rawh",
              identical: 76959, percent: 99.39, differentWord: 77),
        .init(imam: "Abu Ja'far", narrators: "Ibn Wardan and Ibn Jammaz",
              identical: 77400, percent: 99.97, differentWord: 5),
        .init(imam: "Khalaf al-Ashir", narrators: "Ishaq and Idris",
              identical: 77432, percent: 100.00, differentWord: 0),
    ]

    /// The counting traditions, in the order the table above uses them.
    static let countingTraditions: [(String, Int, String)] = [
        ("Kufi", 6236, "Asim, Hamzah, al-Kisai and Khalaf al-Ashir"),
        ("Shami", 6226, "Ibn Amir"),
        ("Makki", 6220, "Ibn Kathir"),
        ("Basri", 6217, "Abu Amr al-Basri"),
        ("Madani al-Awwal", 6214, "Nafi and Abu Ja'far"),
        ("Basri (Ya'qub)", 6204, "Ruways; Rawh counts 6206"),
    ]
}

struct QiraatTextAnalysisView: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        List {
            disclaimerSection
            methodSection
            ayahCountSection
            againstHafsSection
            withinPairSection
            sharedSection
            caveatSection
            readingSection
        }
        .applyConditionalListStyle()
        .themedListRowBackground()
        .navigationTitle("Textual Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var disclaimerSection: some View {
        Section(header: Text("READ THIS FIRST")) {
            Text("This page is not a work of scholarship. It is the output of a program that read the printed mushaf of each riwayah, letter by letter, and compared it against Hafs an Asim. It may not be one hundred percent accurate.")
                .font(.body)
                .foregroundColor(settings.accentColor.color)

            Text("Everywhere else in this guide reports the settled record of the qurra: names, chains, dates, what each reading is known for. This page does not. It reports measurements, and a measurement can be wrong in ways a biography cannot: a mark misread off the page, two words joined where the print separated them, a rule applied one letter too wide.")
                .font(.body)

            Text("Nothing here is a ruling, and none of it replaces a qualified teacher or the classical works. Where a scholar disagrees with a number on this page, the scholar is right and the number is wrong.")
                .font(.body)

            Text("Above all: not one of these figures suggests any disagreement about what the Quran is. Every one of the twenty is the Quran, complete, and every difference between them was received by transmission, never invented.")
                .font(.body)
                .fontWeight(.medium)
        }
    }

    private var methodSection: some View {
        Section(header: Text("HOW THESE NUMBERS WERE PRODUCED")) {
            Text("Ayah numbering is itself one of the things that differs, so nothing was compared ayah against ayah. Each riwayah's whole text was flattened into one ordered list of words, and that list was aligned against Hafs's 77,430 words. The alignment does not care where anyone puts an ayah boundary.")
                .font(.body)

            Text("Every word then falls into one of three buckets:")
                .font(.body)

            bullet("Identical", "the same word, spelled and voweled exactly as Hafs spells it.")
            bullet("Same skeleton", "the same consonantal outline, written with different vowels or a different orthographic convention. This is the large middle: a fathah where Hafs has a dammah, the Madani prints' اَ۬ where Hafs writes ٱ, a drawn-out pronoun vowel.")
            bullet("Different word", "the consonantal outline itself differs, after setting aside the hamzah seats, alif maqsurah against ya, and the silah waw and ya. This is the narrow bucket, and it is the one that corresponds to what a reader would hear as a different word.")

            Text("Pause marks, ayah numbers and the sajdah signs were excluded throughout: they are editorial furniture of a particular print, not the reading.")
                .font(.body)
        }
    }

    private var ayahCountSection: some View {
        Section(header: Text("HOW MANY AYAHS")) {
            Text("Six counting traditions are represented among the twenty. They disagree about where one ayah ends and the next begins, not about how much text there is.")
                .font(.body)

            ForEach(QiraatTextAnalysis.countingTraditions, id: \.0) { name, count, who in
                HStack(alignment: .firstTextBaseline) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Text("\(count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(settings.accentColor.color)
                }
                Text(who)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("The proof that this is boundary-drawing and not more or less Quran is the word count. Across all twenty the whole text runs between 77,424 and 77,468 words: a spread of 44 words, well under a tenth of one percent, against an ayah-count spread of 32.")
                .font(.body)
        }
    }

    private var againstHafsSection: some View {
        Section(header: Text("EACH RIWAYAH AGAINST HAFS")) {
            Text("Reading across: how many of Hafs's 77,430 words this riwayah writes identically, how many it writes with the same skeleton but different vowelling, and how many are a different word form.")
                .font(.footnote)
                .foregroundColor(.secondary)

            ForEach(QiraatTextAnalysis.rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.narrator)
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 8)
                        Text(String(format: "%.2f%%", row.identicalPercent))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(settings.accentColor.color)
                    }
                    Text("\(row.imam) · \(row.ayahs) ayahs · \(row.words) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("identical \(row.identical) · same skeleton \(row.sameSkeleton) · different word \(row.differentWord)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }

            Text("The percentage is not a measure of how much of the Quran a riwayah shares with Hafs: it is a measure of how much of it is spelled identically in print. Ibn Wardan sits lowest at 63.86 percent because the Madani print writes almost every definite article differently, not because a third of his reading is different.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var withinPairSection: some View {
        Section(header: Text("THE TWO NARRATORS OF EACH IMAM")) {
            Text("Each qiraah reaches us through two narrators. Measured against each other rather than against Hafs, this is how far apart the two transmissions of one imam are.")
                .font(.footnote)
                .foregroundColor(.secondary)

            ForEach(QiraatTextAnalysis.pairs) { pair in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(pair.imam)
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 8)
                        Text(String(format: "%.2f%%", pair.percent))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(settings.accentColor.color)
                    }
                    Text(pair.narrators)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("identical \(pair.identical) · different word \(pair.differentWord)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }

            Text("Nafi's two narrators are the furthest apart of any pair, and even there 85 percent of the words are spelled identically. At the other end, the printed texts of Ishaq and Idris are the same text.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var sharedSection: some View {
        Section(header: Text("WHAT ALL TWENTY SHARE")) {
            bullet("The same rasm", "the Uthmanic consonantal skeleton is one skeleton. Every reading among the twenty is readable off it, which is exactly the point the Uthmanic copies were written to serve.")
            bullet("The same 114 surahs", "in the same order, with the same names and the same openings.")
            bullet("The same length", "77,424 to 77,468 words end to end.")
            bullet("The same subject matter, ayah for ayah", "the boundary disagreements move where a number is printed; no riwayah has an ayah another lacks.")

            Text("Set against Hafs, the different-word bucket runs from 136 words (Shu'bah, who studied under the same teacher) to 1,561 (Ibn Wardan). Even the largest is two percent of the text, and every one of those words was transmitted, not chosen.")
                .font(.body)
        }
    }

    private var caveatSection: some View {
        Section(header: Text("WHAT A PRINTED PAGE CANNOT SHOW")) {
            Text("This is the most important limit on everything above. A great deal of what separates one riwayah from another never reaches the page at all.")
                .font(.body)
                .fontWeight(.medium)

            bullet("Sakt", "a brief pause without breathing. Hamzah and Khalaf al-Ashir are known for it; a print may mark it, may mark it inconsistently, or may not mark it.")
            bullet("Madd lengths", "how many counts a prolongation is held. Two riwayat can write a word identically and hold it for different lengths.")
            bullet("Degrees of imalah and taqlil", "how far a fathah is bent toward a kasrah is a matter of degree, and the sign for it is not standardised across prints.")
            bullet("Idgham, ikhfa and ghunnah", "junction behaviour between words, only partly reflected in the writing.")
            bullet("Where to stop and start", "waqf and ibtida, which belong to the recitation rather than to the text.")

            Text("Khalaf al-Ashir is the clearest case. Ishaq and Idris come out of this comparison as one identical text, 77,432 words with not a single difference, and that is genuinely what the printed mushafs say. It does not mean the two transmissions are the same recitation. What separates them, and much of what separates Khalaf al-Ashir from Hamzah whose riwayah he himself narrated, lives in sakt, in stopping, and in the other recitation-level matters listed above. Ibn al-Jazari's al-Durrah records Khalaf al-Ashir's usul as differences from ash-Shatibiyyah for the same reason: the reading is defined by how it is recited, not only by how it is written.")
                .font(.body)

            Text("So read the tables as a comparison of printed texts, which is all they are, and never as a measure of how far apart two recitations sound.")
                .font(.body)
                .foregroundColor(settings.accentColor.color)
        }
    }

    private var readingSection: some View {
        Section(header: Text("WHERE TO READ THE REAL SCHOLARSHIP")) {
            Text("For the questions this page can only gesture at, these are the works and references to go to.")
                .font(.footnote)
                .foregroundColor(.secondary)

            reference("an-Nashr fi al-Qiraat al-Ashr", "Ibn al-Jazari (d. 833 AH). The standard reference for all ten readings and their chains.")
            reference("ad-Durrah al-Mudiyyah", "Ibn al-Jazari. The three readings beyond the seven, Abu Ja'far, Ya'qub and Khalaf al-Ashir, recorded as their differences from ash-Shatibiyyah.")
            reference("Hirz al-Amani (ash-Shatibiyyah)", "ash-Shatibi (d. 590 AH). The seven readings in verse; the reference every later work measures against.")
            reference("al-Bayan fi Add Ay al-Quran", "ad-Dani (d. 444 AH). The classical treatment of ayah counting and why the traditions differ.")
            reference("Kitab Adad Ay al-Quran", "al-Antaki (d. 377 AH). The agreed and disputed ayah counts of the Makki, Madani, Kufi, Basri and Shami traditions.")

            Link(destination: QiraatProfiles.sourceURL) {
                HStack {
                    Text("QiraatHub")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
                .font(.subheadline)
            }
            .foregroundColor(settings.accentColor.color)
        }
    }

    // MARK: - Pieces

    private func bullet(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(body)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func reference(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
            Text(body)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#endif
