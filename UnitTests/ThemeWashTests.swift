import XCTest
@testable import iPhone

/// The theme washes (`ThemeWashColor.washPaint`), measured the way the 2026-10-10 rework was: in OKLab,
/// where equal distances look equal. Abu's report was both halves of the problem at once ("if its too
/// strong its too strong but if its too weak then i cant differentiate yellow and green"), so these pin
/// both: no two of the seven washes may sit close enough to be mistaken for each other, on every page
/// the reader can show, and none may get heavy. The old opacity washes failed the first with a closest
/// pair 0.013 apart on white and on black.
final class ThemeWashTests: XCTestCase {
    private typealias Lab = (L: Double, a: Double, b: Double)

    private let white = WashRGB(r: 1, g: 1, b: 1)
    private let black = WashRGB(r: 0, g: 0, b: 0)
    private let sepia = WashRGB(r: 0.90, g: 0.83, b: 0.69)
    private let sepiaRow = WashRGB(r: 0.93, g: 0.90, b: 0.82)
    private let gray = WashRGB(r: 0.13, g: 0.13, b: 0.14)
    private let darkRow = WashRGB(r: 28 / 255, g: 28 / 255, b: 30 / 255)

    /// The wash as it lands on `ground`: its paint laid at `washOpacity`, as Core Graphics blends it.
    private func landed(_ color: ThemeWashColor, on ground: WashRGB, dark: Bool, increaseContrast: Bool = false) -> Lab {
        let paint = color.washPaint(dark: dark, ground: dark ? nil : ground, increaseContrast: increaseContrast)
        let alpha = ThemeWashColor.washOpacity
        return WashOKLab.lab(WashRGB(r: paint.r * alpha + ground.r * (1 - alpha),
                                     g: paint.g * alpha + ground.g * (1 - alpha),
                                     b: paint.b * alpha + ground.b * (1 - alpha)))
    }

    private func distance(_ x: Lab, _ y: Lab) -> Double {
        ((x.L - y.L) * (x.L - y.L) + (x.a - y.a) * (x.a - y.a) + (x.b - y.b) * (x.b - y.b)).squareRoot()
    }

    /// The hue of the step a wash takes away from its page, in degrees.
    private func hue(_ wash: Lab, from page: Lab) -> Double {
        let degrees = atan2(wash.b - page.b, wash.a - page.a) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }

    private func closestPair(on ground: WashRGB, dark: Bool, increaseContrast: Bool = false) -> (Double, String) {
        let washes = ThemeWashColor.allCases.map { ($0, landed($0, on: ground, dark: dark, increaseContrast: increaseContrast)) }
        var best = (Double.infinity, "")
        for i in washes.indices {
            for j in washes.indices where j > i {
                let d = distance(washes[i].1, washes[j].1)
                if d < best.0 { best = (d, "\(washes[i].0.name)/\(washes[j].0.name)") }
            }
        }
        return best
    }

    func testNoTwoWashesRunTogether() {
        // Measured 0.021 on every light page and 0.039 to 0.040 on the dark ones.
        for (name, ground) in [("white", white), ("Sepia", sepia), ("a Sepia row", sepiaRow)] {
            let (d, pair) = closestPair(on: ground, dark: false)
            XCTAssertGreaterThanOrEqual(d, 0.019, "\(pair) on \(name)")
        }
        for (name, ground) in [("black", black), ("Gray", gray), ("a dark row", darkRow)] {
            let (d, pair) = closestPair(on: ground, dark: true)
            XCTAssertGreaterThanOrEqual(d, 0.035, "\(pair) on \(name)")
        }
    }

    func testYellowIsNotGreen() {
        // On black a faint yellow turns olive, which is where yellow met green: gold, then, and a whole
        // hue band away from the green.
        for (ground, dark) in [(white, false), (black, true), (sepia, false), (gray, true)] {
            let page = WashOKLab.lab(ground)
            let yellow = hue(landed(.stories, on: ground, dark: dark), from: page)
            let green = hue(landed(.prophets, on: ground, dark: dark), from: page)
            XCTAssertLessThanOrEqual(yellow, 100, "yellow drifted toward olive")
            XCTAssertGreaterThanOrEqual(green - yellow, 50, "yellow \(yellow) and green \(green) are one hue band")
        }
    }

    func testWashesStayLight() {
        // The other half of the report: no wash may darken a light page, or lift a black one, much past
        // where the old ones did (0.052 and 0.274 at the most).
        for color in ThemeWashColor.allCases {
            let onWhite = landed(color, on: white, dark: false)
            XCTAssertLessThanOrEqual(1 - onWhite.L, 0.07, "\(color.name) darkens a white page too far")
            let onBlack = landed(color, on: black, dark: true)
            XCTAssertLessThanOrEqual(onBlack.L, 0.27, "\(color.name) lifts a black page too far")
        }
    }

    func testSepiaGetsTheSameStepAsWhite() {
        // A light wash is a step from its own page, so brown no longer vanishes into Sepia's own tan.
        let page = WashOKLab.lab(sepia)
        let paper = WashOKLab.lab(white)
        for color in ThemeWashColor.allCases {
            let onSepia = distance(landed(color, on: sepia, dark: false), page)
            let onWhite = distance(landed(color, on: white, dark: false), paper)
            XCTAssertEqual(onSepia, onWhite, accuracy: 0.004, "\(color.name) on Sepia")
        }
    }

    func testIncreaseContrastWidensTheGap() {
        XCTAssertGreaterThan(closestPair(on: white, dark: false, increaseContrast: true).0,
                             closestPair(on: white, dark: false).0)
        XCTAssertGreaterThan(closestPair(on: black, dark: true, increaseContrast: true).0,
                             closestPair(on: black, dark: true).0)
    }

    func testPaintsAreRealColours() {
        for color in ThemeWashColor.allCases {
            for dark in [false, true] {
                for increased in [false, true] {
                    for ground in [white, sepia, sepiaRow] {
                        let paint = color.washPaint(dark: dark, ground: dark ? nil : ground, increaseContrast: increased)
                        for channel in [paint.r, paint.g, paint.b] {
                            XCTAssertTrue((0...1).contains(channel), "\(color.name) dark=\(dark) contrast=\(increased)")
                        }
                    }
                }
            }
        }
    }
}
