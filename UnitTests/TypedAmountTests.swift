import XCTest
@testable import iPhone

/// `TypedAmount.parse`, behind the zakah, zakat al-fitr and inheritance calculators.
final class TypedAmountTests: XCTestCase {

    private func assertParses(_ text: String, _ expected: Double, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(TypedAmount.parse(text), expected, accuracy: 0.000_001, text, file: file, line: line)
    }

    /// A11: Arabic-Indic and Persian digits read as numbers, not as zero.
    func testEasternDigits() {
        assertParses("\u{0661}\u{0662}\u{0663}\u{0664}\u{0665}", 12345)   // ١٢٣٤٥
        assertParses("\u{06F1}\u{06F0}\u{06F0}\u{06F0}", 1000)              // ۱۰۰۰
        assertParses("\u{0660}", 0)
    }

    /// A11: the Arabic decimal and thousands marks (U+066B, U+066C) and the Arabic comma.
    func testArabicSeparators() {
        assertParses("\u{0663}\u{066B}\u{0665}", 3.5)                                                  // ٣٫٥
        assertParses("\u{0661}\u{066C}\u{0662}\u{0663}\u{0664}\u{066B}\u{0665}\u{0666}", 1234.56)     // ١٬٢٣٤٫٥٦
        assertParses("1\u{066C}234\u{066B}56", 1234.56)
    }

    /// A11: both separators present: the last one is the decimal point, in either convention.
    func testBothConventions() {
        assertParses("1.234,56", 1234.56)
        assertParses("1,234.56", 1234.56)
        assertParses("12.345.678,9", 12_345_678.9)
        assertParses("12,345,678.9", 12_345_678.9)
    }

    /// A11: a repeated lone separator is grouping.
    func testRepeatedSeparatorIsGrouping() {
        assertParses("1.000.000", 1_000_000)
        assertParses("12,345,678", 12_345_678)
    }

    /// A11: currency symbols, codes and spaces are ignored.
    func testSymbolsAndSpaces() {
        assertParses("$ 2,500.00", 2500)
        assertParses("2,500.00 SAR", 2500)
        assertParses("  750  ", 750)
    }

    /// A11: nothing numeric is zero, never a crash or NaN.
    func testNonNumericIsZero() {
        assertParses("", 0)
        assertParses("abc", 0)
        assertParses(".", 0)
        assertParses(",,", 0)
    }

    /// A11: the guide's probe cases as the simulator's en_US locale reads them ("2,500" is grouping there).
    func testGuideProbeCasesInAPointDecimalLocale() throws {
        let locale = Locale.autoupdatingCurrent
        guard locale.decimalSeparator == ".", locale.groupingSeparator == "," else {
            throw XCTSkip("locale \(locale.identifier) does not use a point decimal and comma grouping")
        }
        assertParses("\u{0661}\u{0662}\u{0663}\u{0664}\u{0665}", 12345)
        assertParses("1.234,56", 1234.56)
        assertParses("1,234.56", 1234.56)
        assertParses("\u{0663}\u{066B}\u{0665}", 3.5)
        assertParses("$ 2,500", 2500)
        assertParses("\u{06F1}\u{06F0}\u{06F0}\u{06F0}", 1000)
        assertParses("1.5", 1.5)
        assertParses("1,234", 1234)
    }
}
