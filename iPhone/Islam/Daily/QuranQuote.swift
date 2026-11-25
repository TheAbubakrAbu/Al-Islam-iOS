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

/// A cited surah's names, so a quote says WHICH surah, not only its number (Abu, 2026-11-24: "for
/// all quotes of Quran it says Quran 5:3 I want to hear the surha name like Quran Maidah 5:3 but
/// make it pretty"). Read from the Quran the app ships; an app without one (Al-Adhan) gets nil and
/// its citations read "Quran 5:3", as they always did.
struct QuranSurahNames: Equatable {
    let number: Int
    /// "Al-Ma'idah"
    let transliteration: String
    /// "The Table Spread"
    let english: String
    /// "المائدة"
    let arabic: String

    init?(surah: Int) {
        #if HAS_QURAN
        guard let found = QuranData.shared.surah(surah) else { return nil }
        number = surah
        transliteration = found.nameTransliteration
        english = found.nameEnglish
        arabic = found.nameArabic
        #else
        return nil
        #endif
    }

    /// The name in the interface's script: the Arabic in an Arabic-script interface, the
    /// transliteration everywhere else (`Surah.displayName`'s rule).
    var displayName: String {
        AppLanguage.isArabicScript ? arabic : transliteration
    }

    /// A citation in the articles' house style, "Quran 5:3" or "Quran 2:43, 110", as its reference
    /// and its surah's names; nil for anything else (a hadith, two surahs, no Quran in the app).
    static func cited(_ citation: String) -> (reference: QuranQuoteReference, names: QuranSurahNames)? {
        let trimmed = citation.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("Quran "), let reference = QuranQuoteReference(String(trimmed.dropFirst(6))),
              let names = QuranSurahNames(surah: reference.surah) else { return nil }
        return (reference, names)
    }

    /// A source line with its surah named before the numbers, in whatever language the line is:
    /// "Quran 13:28" reads "Quran Ar-Ra'd 13:28", "القرآن ١٣:٢٨" reads "القرآن الرعد ١٣:٢٨". Only the
    /// house style's "surah:ayah" counts (a hadith is cited by its number alone), and only a pair
    /// that is a real ayah; any other line comes back as it was.
    static func naming(_ source: String) -> String {
        guard source.contains(":"), let regex = sourceRegex else { return source }
        let ns = source as NSString
        guard let match = regex.firstMatch(in: source, range: NSRange(location: 0, length: ns.length)),
              let surah = number(ns.substring(with: match.range(at: 1))),
              let ayah = number(ns.substring(with: match.range(at: 2))),
              let names = QuranSurahNames(surah: surah), names.has(ayah: ayah) else { return source }
        let name = names.displayName
        guard !source.contains(name) else { return source }
        return ns.replacingCharacters(in: NSRange(location: match.range.location, length: 0), with: name + " ")
    }

    /// "s:a" in any script's digits, not inside a longer number or a time ("10:30 am" has no
    /// 3-digit ayah run, but a surah must also exist with that many ayahs).
    private static let sourceRegex = try? NSRegularExpression(pattern: #"(?<![\d:])(\d{1,3}):(\d{1,3})(?!\d)"#)

    /// The value of a run of decimal digits in any script ("١٣" is 13).
    private static func number(_ digits: String) -> Int? {
        var value = 0
        for scalar in digits.unicodeScalars {
            guard let digit = scalar.properties.numericValue, scalar.properties.numericType == .decimal else { return nil }
            value = value * 10 + Int(digit)
        }
        return digits.isEmpty ? nil : value
    }

    private func has(ayah: Int) -> Bool {
        #if HAS_QURAN
        return QuranData.shared.ayah(surah: number, ayah: ayah) != nil
        #else
        return false
        #endif
    }
}
