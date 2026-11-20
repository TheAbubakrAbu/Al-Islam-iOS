import XCTest
@testable import iPhone

/// The interface languages (Docs/Engineering/Localization Guide.md): each one ships its compiled strings,
/// the surah meanings the left-to-right languages show under a surah's name resolve in each of them, and
/// Siri phrases exist only where Siri speaks the language (Malay, Turkish, French, Russian, German, Spanish,
/// Dutch; not Urdu, Indonesian, Bangla, Hindi, Malayalam or Tamil).
final class LocalizationCoverageTests: XCTestCase {
    private static let languages = ["ar", "ur", "id", "ms", "tr", "fr", "bn", "ru", "hi", "de", "es", "ml", "ta", "nl"]

    private func bundle(_ language: String) -> Bundle? {
        Bundle.main.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:))
    }

    func testEveryLanguageShipsItsStrings() throws {
        for language in Self.languages {
            let strings = try XCTUnwrap(bundle(language), "\(language).lproj is missing")
            XCTAssertNotNil(strings.path(forResource: "Localizable", ofType: "strings"),
                            "\(language) has no Localizable.strings")
            XCTAssertNotEqual(strings.localizedString(forKey: "Settings", value: nil, table: nil), "Settings",
                              "\(language) does not translate Settings")
        }
    }

    /// `Surah.localizedMeaning` reads `surah.meaning.<id>`; a missing one would fall back to the English.
    func testSurahMeaningsResolveInTheLeftToRightLanguages() throws {
        for language in ["id", "ms", "tr", "fr", "bn", "ru", "hi", "de", "es", "ml", "ta", "nl"] {
            let strings = try XCTUnwrap(bundle(language), "\(language).lproj is missing")
            for id in 1...114 {
                let key = "surah.meaning.\(id)"
                let value = strings.localizedString(forKey: key, value: nil, table: nil)
                XCTAssertNotEqual(value, key, "\(language) has no \(key)")
            }
        }
    }

    func testSiriPhrasesExistOnlyWhereSiriSpeaksTheLanguage() throws {
        func phrases(_ language: String) -> [String: String]? {
            guard let path = bundle(language)?.path(forResource: "AppShortcuts", ofType: "strings") else { return nil }
            return NSDictionary(contentsOfFile: path) as? [String: String]
        }
        let arabic = try XCTUnwrap(phrases("ar"), "ar has no AppShortcuts.strings")
        for language in ["ms", "tr", "fr", "ru", "de", "es", "nl"] {
            let found = try XCTUnwrap(phrases(language), "\(language) has no AppShortcuts.strings")
            XCTAssertEqual(Set(found.keys), Set(arabic.keys), "\(language) phrases differ from the Arabic set")
            XCTAssertEqual(Set(found.values).count, found.count, "\(language) gives two phrases the same words")
        }
        XCTAssertNil(phrases("id"), "Siri has no Indonesian: an Indonesian phrase could never be heard")
        XCTAssertNil(phrases("ur"), "Siri has no Urdu: an Urdu phrase could never be heard")
        XCTAssertNil(phrases("bn"), "Siri has no Bangla: a Bangla phrase could never be heard")
        XCTAssertNil(phrases("hi"), "Siri has no Hindi: a Hindi phrase could never be heard")
        XCTAssertNil(phrases("ml"), "Siri has no Malayalam: a Malayalam phrase could never be heard")
        XCTAssertNil(phrases("ta"), "Siri has no Tamil: a Tamil phrase could never be heard")
    }
}
