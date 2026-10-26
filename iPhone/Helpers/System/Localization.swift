import Foundation
import SwiftUI

// Arabic interface (2026-10-24), Urdu (2026-10-26). Interface text written in the code goes through `String(localized:)` or a
// SwiftUI literal, which the compiler extracts into Resources/Localizable.xcstrings. What this file covers is
// the other kind: the app's English DATA shown to the reader (an enum's raw value, a reciter's name). That
// stays English wherever it is stored, compared, searched or sent to the model, and is translated only at the
// display site. The Islam tab's articles (Faith & Proofs, Hadith & Its Sciences) are not translated yet and
// keep reading English (`AppLanguage.pinsArticlesEnglish`); the rest of that tab is translated.

extension String {
    /// This data string as the reader should see it: looked up in Localizable.xcstrings, or itself when the
    /// catalog has no entry for it. A translation's written-out digits follow the locale (`localizedDigits`).
    /// For DISPLAY only; never store, compare or key on the result.
    var localizedDisplay: String {
        let translated = Bundle.main.localizedString(forKey: self, value: self, table: nil)
        return translated == self ? self : translated.localizedDigits
    }

    /// This display string with its digits written the way the interface writes numbers, so a number the app
    /// builds or a translation spells out matches every number Foundation and SwiftUI format: Arabic-Indic
    /// (٢:٢٥٥) where the locale writes them (Saudi Arabia, Egypt), Extended Arabic-Indic (۲:۲۵۵) where the
    /// reader picked Urdu digits in iOS, Western where it does not (an Arabic interface on a US-region phone
    /// is `ar_US`; Apple's Urdu locales write Western digits by default), untouched in English. For text the app
    /// builds itself ("\(surah):\(ayah)", `String(year)`, a count drawn verbatim) and for a translation that
    /// writes a number out ("٥ دقائق"). DISPLAY only: never store, compare or search the result.
    var localizedDigits: String {
        if let zero = AppLanguage.localeZero {
            // Western, Arabic-Indic and Extended Arabic-Indic (Urdu, Persian) alike become the locale's.
            return mappingDigits { value in
                switch value {
                case 0x30...0x39: return zero + value - 0x30
                case 0x660...0x669: return zero + value - 0x660
                case 0x6F0...0x6F9: return zero + value - 0x6F0
                default: return nil
                }
            }
        }
        // Western digits in an Arabic interface: the translations' Arabic-Indic and Persian digits, and
        // their decimal, thousands and percent signs, come back to the Western ones.
        guard AppLanguage.isRightToLeft else { return self }
        return mappingDigits { value in
            switch value {
            case 0x660...0x669: return value - 0x660 + 0x30
            case 0x6F0...0x6F9: return value - 0x6F0 + 0x30
            case 0x66B: return 0x2E   // ٫ decimal separator
            case 0x66C: return 0x2C   // ٬ thousands separator
            case 0x66A: return 0x25   // ٪ percent sign
            default: return nil
            }
        }
    }

    /// Each scalar `map` returns a replacement for, replaced; the rest kept.
    private func mappingDigits(_ map: (UInt32) -> UInt32?) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in unicodeScalars {
            if let value = map(scalar.value), let mapped = UnicodeScalar(value) {
                scalars.append(mapped)
            } else {
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    /// True when most of the letters are Arabic script, so content of unknown language (a model's
    /// answer, a source excerpt) can take its own direction: by majority rather than by the first
    /// letter, so an English answer that opens on an Arabic term still reads as English.
    var isMostlyArabicScript: Bool {
        var arabic = 0, latin = 0
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0600...0x06FF, 0x0750...0x077F, 0x08A0...0x08FF, 0xFB50...0xFDFF, 0xFE70...0xFEFF:
                arabic += 1
            case 0x41...0x5A, 0x61...0x7A, 0xC0...0x24F:
                latin += 1
            default:
                break
            }
        }
        return arabic > latin
    }
}

enum AppLanguage {
    /// The language the interface is showing: the per-app choice in Settings > Al-Islam > Language, or the
    /// phone's when there is none. Not `Locale.current`, whose region and formats can differ from it.
    static var code: String { Bundle.main.preferredLocalizations.first ?? "en" }

    static var isArabic: Bool { code.hasPrefix("ar") }

    static var isUrdu: Bool { code.hasPrefix("ur") }

    /// The interface is written in the Arabic script: Arabic, or Urdu (since 2026-10-26). Where a comment says
    /// "the Arabic interface" it means this: a surah, juz, riwayah, hadith book or letter is named once, by its
    /// Arabic name, with no Latin transliteration or English meaning beside it (those would be untranslated
    /// English in either language), and lists take the Arabic comma and semicolon (، ؛), which Urdu writes
    /// too. `isArabic` alone is for what only Arabic does: the name Siri says back.
    static var isArabicScript: Bool { isArabic || isUrdu }

    /// The interface reads right to left. UIKit then lays out paging scroll views from the right on its own.
    /// A list, not `Locale.characterDirection(forLanguage:)`: that is deprecated on the iOS 16 floor, and its
    /// replacement does not exist on the companion apps' iOS 15.
    static var isRightToLeft: Bool {
        let base = code.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? code
        return rightToLeftLanguages.contains(base)
    }

    private static let rightToLeftLanguages: Set<String> = ["ar", "fa", "ur", "he", "ps", "sd", "ug", "yi", "ckb", "dv"]

    /// The Islam tab's articles have no translation yet: in Arabic they read English, laid out left to right
    /// (`ArticleLanguage`), and the few labels inside them whose key a translated screen shares ("Read the
    /// hadith") keep English with them rather than mixing. Everything else on that tab is translated.
    static var pinsArticlesEnglish: Bool { !code.hasPrefix("en") }

    /// Interface text inside an article: the English as written while the articles stay English, even where a
    /// translated screen shares the key, and the translation once the articles are translated.
    static func article(_ english: String) -> String {
        pinsArticlesEnglish ? english : english.localizedDisplay
    }

    /// The zero of the locale's digits when they are not the Western ones (U+0660 for Arabic-Indic), the
    /// digits every number Foundation and SwiftUI format is written in. Cached per locale.
    static var localeZero: UInt32? {
        let identifier = Locale.current.identifier
        zeroLock.lock()
        defer { zeroLock.unlock() }
        if let cached = zeroCache, cached.locale == identifier { return cached.zero }
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        let scalar = formatter.string(from: 0)?.unicodeScalars.first { $0.properties.numericType == .decimal }
        let zero = scalar.flatMap { $0.value == 0x30 ? nil : $0.value }
        zeroCache = (identifier, zero)
        return zero
    }

    private static let zeroLock = NSLock()
    private static var zeroCache: (locale: String, zero: UInt32?)?
}

extension View {
    /// English CONTENT (a translation of the Quran, a transliteration, a hadith's English) keeps its own
    /// left-to-right direction inside the Arabic interface, the way a browser resolves dir="auto": pushed to
    /// the right edge by an Arabic layout it reads as a layout bug, not as English. Put it on the text (or a
    /// stack of text only), never on a row whose chrome should follow the interface.
    func leftToRightContent() -> some View {
        environment(\.layoutDirection, .leftToRight)
    }

    /// An Islam-tab ARTICLE screen while the articles are still English (`AppLanguage.pinsArticlesEnglish`): in
    /// a right-to-left interface the whole page reads left to right, as it does in English, rather than
    /// English paragraphs pushed against the right edge. Put it on the screen's List (or its root), BELOW the
    /// NavigationStack: the navigation bar keeps the interface's direction, and the sheets and screens the
    /// article opens get it back on their own. Never on a tab root or a NavigationStack: a pin there drew
    /// Lists mirrored, letters backwards (2026-10-24). A no-op in English.
    func englishArticle() -> some View {
        leftToRightContent(AppLanguage.pinsArticlesEnglish)
    }

    /// `leftToRightContent()` only while `isEnglish`: for a view that shows English or Arabic content by a
    /// setting or by what the data holds (a hadith in Arabic-only mode, an Arabic tafsir). Arabic content
    /// keeps the direction it inherits, and the view's structure is the same either way.
    func leftToRightContent(_ isEnglish: Bool) -> some View {
        modifier(LeftToRightContentModifier(isEnglish: isEnglish))
    }
}

private struct LeftToRightContentModifier: ViewModifier {
    let isEnglish: Bool
    @Environment(\.layoutDirection) private var inherited

    func body(content: Content) -> some View {
        content.environment(\.layoutDirection, isEnglish ? .leftToRight : inherited)
    }
}
