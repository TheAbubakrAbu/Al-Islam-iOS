import Foundation

// An article's Quran quote as a REFERENCE, not a copy. The Islam tab's articles used to carry each
// quoted ayah as two Swift string literals, the Arabic and the English, 804 of them across the
// article files, and 439 had already drifted from the mushaf's text (a tashkeel pass stripped
// their sukoons) by the time anyone looked. A reference cannot drift: the words are read out of
// the Quran the app already ships when the quote renders (`QuranQuoteSource`), so the article shows
// exactly what the reader finds when they open the same ayah in the Quran tab.
//
// `ScriptureQuote(quran: "2:255")`, `ScriptureQuote(quran: "52:35-36")`,
// `ScriptureQuote(quran: "2:43, 110")`; `words:` narrows the quote to the words the article is
// about, as a 0-based inclusive token range over the cited ayahs' raw text joined by spaces.
// The whole ayah is still shown (the English cannot be cut where the Arabic is), with those words
// in the full accent and the rest of the ayah lighter.

/// One surah, one or more runs of its ayahs.
struct QuranQuoteReference: Hashable {
    let surah: Int
    let runs: [ClosedRange<Int>]
    /// The reference as written, for the citation ("2:255", "52:35-36", "2:43, 110").
    let text: String

    /// Parses "s:a", "s:a-b" and "s:a-b, c-d" (one surah); nil for anything else.
    init?(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let surah = Int(parts[0]), (1...114).contains(surah) else { return nil }
        var runs: [ClosedRange<Int>] = []
        for piece in parts[1].split(separator: ",") {
            let bounds = piece.trimmingCharacters(in: .whitespaces).split(separator: "-").map { Int($0.trimmingCharacters(in: .whitespaces)) }
            switch bounds.count {
            case 1:
                guard let a = bounds[0], a >= 1 else { return nil }
                runs.append(a...a)
            case 2:
                guard let a = bounds[0], let b = bounds[1], a >= 1, b >= a else { return nil }
                runs.append(a...b)
            default:
                return nil
            }
        }
        guard !runs.isEmpty else { return nil }
        self.surah = surah
        self.runs = runs
        self.text = trimmed
    }

    /// Every cited ayah, in order.
    var ayahs: [Int] { runs.flatMap { Array($0) } }

    /// The citation the quote ends with, in the articles' own house style.
    var citation: String { "Quran \(text)" }
}

/// The cited text as the app's Quran has it: the ayahs' raw Arabic joined by spaces (so `words`
/// token ranges index straight in) and their translation joined the same way.
struct QuranQuoteText: Equatable {
    let arabic: String
    let english: String
}
