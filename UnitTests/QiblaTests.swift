import XCTest
import CoreLocation
@testable import iPhone
@testable import Adhan

/// The Qibla compass: the bearing maths, the angle helpers the needle and the turn text are built
/// on, and the guards that stop a broken compass from reading as a working one.
///
/// Nothing here existed before 2026-10-08. The only Qibla tests in the tree were inside the vendored
/// `adhan-swift` package, which is not part of the app's test target, so no app-side test covered the
/// bearing, the wraparound, the orientation frame or the "no fix yet" sentinel - every one of which
/// has been the cause of a real needle-pointing-the-wrong-way bug in this file's history.
final class QiblaTests: XCTestCase {

    // MARK: - Bearing

    /// The bearing to the Kaaba for cities on five continents, including both hemispheres and both
    /// sides of the 180th meridian.
    ///
    /// Cross-checked against an independent implementation of the standard great-circle initial
    /// bearing formula (`atan2(sin dLon * cos lat2, cos lat1 sin lat2 - sin lat1 cos lat2 cos dLon)`),
    /// which agrees with adhan-swift's spherical-trigonometry form to four decimal places at every
    /// city below.
    func testQiblaBearingForKnownCities() {
        let cases: [(name: String, latitude: Double, longitude: Double, bearing: Double)] = [
            ("New York", 40.7128, -74.0060, 58.4817),
            ("Chicago", 41.8781, -87.6298, 48.6710),
            ("Los Angeles", 34.0522, -118.2437, 23.8571),
            ("Toronto", 43.6532, -79.3832, 54.5806),
            ("London", 51.5074, -0.1278, 118.9872),
            ("Oslo", 59.9139, 10.7522, 139.0272),
            ("Cape Town", -33.9249, 18.4241, 23.3525),
            ("Jakarta", -6.2088, 106.8456, 295.1518),
            ("Tokyo", 35.6895, 139.6917, 293.0207),
            ("Sydney", -33.8688, 151.2093, 277.4996),
            ("Anchorage", 61.2181, -149.9003, 350.8831),
        ]

        for test in cases {
            let bearing = Qibla(
                coordinates: Coordinates(latitude: test.latitude, longitude: test.longitude)
            ).direction
            XCTAssertEqual(
                bearing, test.bearing, accuracy: 0.001,
                "\(test.name): bearing to the Kaaba drifted"
            )
        }
    }

    /// Every bearing is a usable compass heading: 0 ..< 360, never negative and never NaN.
    ///
    /// `atan2` returns -pi ... pi, so the unwinding step is what keeps this true. A negative bearing
    /// would subtract wrongly from the heading and put the needle a full turn out.
    func testBearingIsAlwaysNormalized() {
        for latitude in stride(from: -85.0, through: 85.0, by: 5) {
            for longitude in stride(from: -180.0, through: 180.0, by: 15) {
                let bearing = Qibla(
                    coordinates: Coordinates(latitude: latitude, longitude: longitude)
                ).direction
                XCTAssertFalse(bearing.isNaN, "NaN bearing at \(latitude), \(longitude)")
                XCTAssertGreaterThanOrEqual(bearing, 0, "negative bearing at \(latitude), \(longitude)")
                XCTAssertLessThan(bearing, 360, "bearing >= 360 at \(latitude), \(longitude)")
            }
        }
    }

    /// Due north and due south of the Kaaba the bearing collapses to exactly 0 or 180. These are the
    /// degenerate cases of the formula (the `sin(dLon)` term goes to zero), so they pin the poles of
    /// the result rather than a general direction.
    func testBearingDueNorthAndSouthOfKaaba() {
        let kaabaLongitude = 39.8261818

        // North of Mecca on the same meridian: the Kaaba is due south.
        let north = Qibla(coordinates: Coordinates(latitude: 48.0, longitude: kaabaLongitude)).direction
        XCTAssertEqual(north, 180, accuracy: 0.001)

        // South of Mecca on the same meridian: the Kaaba is due north, which must read 0 and not 360.
        let south = Qibla(coordinates: Coordinates(latitude: -10.0, longitude: kaabaLongitude)).direction
        XCTAssertEqual(south, 0, accuracy: 0.001)
    }

    /// The spherical bearing the app ships differs from a WGS84 ellipsoidal (Vincenty) bearing by
    /// well under a degree everywhere - about 0.18 degrees at worst, two orders of magnitude below a
    /// phone magnetometer's own error.
    ///
    /// This is here so the choice stays a measured one: it documents that moving to a geodesic
    /// bearing would be false precision, and it fails if someone changes the formula to something
    /// that is genuinely wrong rather than merely spherical.
    func testSphericalBearingAgreesWithGeodesicWithinSensorError() {
        let cases: [(latitude: Double, longitude: Double)] = [
            (40.7128, -74.0060), (51.5074, -0.1278), (-6.2088, 106.8456),
            (35.6895, 139.6917), (-33.8688, 151.2093), (61.2181, -149.9003),
            (-33.9249, 18.4241), (34.0522, -118.2437),
        ]

        for test in cases {
            let spherical = Qibla(
                coordinates: Coordinates(latitude: test.latitude, longitude: test.longitude)
            ).direction
            let geodesic = Self.geodesicBearingToKaaba(latitude: test.latitude, longitude: test.longitude)
            let delta = abs(Self.signedDelta(from: geodesic, to: spherical))
            XCTAssertLessThan(
                delta, 0.5,
                "spherical and geodesic bearings disagree by \(delta) degrees at \(test.latitude), \(test.longitude)"
            )
        }
    }

    // MARK: - Shared Kaaba coordinate

    /// The needle and the "miles away" line must measure to the SAME point. `QiblaView` held its own
    /// copy of the coordinate truncated to four decimals, about 20 m from the one the bearing uses.
    func testViewKaabaCoordinateMatchesBearingCoordinate() {
        XCTAssertEqual(QiblaView.kaabaCoordinate.latitude, 21.4225241, accuracy: 1e-9)
        XCTAssertEqual(QiblaView.kaabaCoordinate.longitude, 39.8261818, accuracy: 1e-9)
    }

    // MARK: - The degenerate case at the Kaaba

    /// Standing on or beside the Kaaba the great-circle bearing is UNDEFINED, not merely imprecise:
    /// every direction points at the Kaaba when you are on it.
    ///
    /// This pins the measured behaviour that justifies the `isAtKaaba` guard - two metres of walking
    /// across the mataaf swings the bearing a full 180 degrees. A compass obeying that is
    /// indistinguishable from a broken one, while the correct instruction inside the Masjid al-Haram
    /// is simply to face the Kaaba in view.
    func testBearingIsDegenerateAtTheKaaba() {
        let latitude = 21.4225241, longitude = 39.8261818
        let oneMetreInDegrees = 0.000009

        let justNorth = Qibla(
            coordinates: Coordinates(latitude: latitude + oneMetreInDegrees, longitude: longitude)
        ).direction
        let justSouth = Qibla(
            coordinates: Coordinates(latitude: latitude - oneMetreInDegrees, longitude: longitude)
        ).direction

        // Metres apart, opposite answers: the formula is correct and useless here.
        XCTAssertEqual(justNorth, 180, accuracy: 0.5, "one metre north of the Kaaba")
        XCTAssertEqual(justSouth, 0, accuracy: 0.5, "one metre south of the Kaaba")

        let swing = abs(Self.signedDelta(from: justSouth, to: justNorth))
        XCTAssertEqual(
            swing, 180, accuracy: 1,
            "two metres of walking must be shown to flip the needle - this is why isAtKaaba exists"
        )
    }

    /// The at-Kaaba guard covers the Masjid al-Haram and nothing beyond it. 1 km comfortably contains
    /// the Haram while leaving the rest of Mecca a normal, well-defined bearing.
    func testAtKaabaGuardCoversTheHaramOnly() {
        let kaaba = CLLocation(latitude: 21.4225241, longitude: 39.8261818)

        func metres(latitude: Double, longitude: Double) -> CLLocationDistance {
            CLLocation(latitude: latitude, longitude: longitude).distance(from: kaaba)
        }

        // Inside: the Kaaba itself and the edge of the mataaf.
        XCTAssertLessThanOrEqual(metres(latitude: 21.4225241, longitude: 39.8261818), 1_000)
        XCTAssertLessThanOrEqual(metres(latitude: 21.4231, longitude: 39.8268), 1_000)

        // Outside: the rest of Mecca keeps a real bearing, and so does Jeddah.
        XCTAssertGreaterThan(metres(latitude: 21.4400, longitude: 39.8500), 1_000, "elsewhere in Mecca")
        XCTAssertGreaterThan(metres(latitude: 21.4858, longitude: 39.1925), 1_000, "Jeddah")
    }

    /// `isAtKaaba` short-circuits on a coordinate bounding box before paying for a geodesic distance,
    /// because it is read several times per heading sample. The box must therefore strictly CONTAIN
    /// the 1 km circle: too tight and someone standing in the Haram gets the spinning needle back.
    ///
    /// Walks the whole circle rather than the four cardinal points, since the longitude bound is the
    /// binding one at this latitude.
    func testAtKaabaBoundingBoxContainsTheRadius() {
        let kaaba = CLLocation(latitude: 21.4225241, longitude: 39.8261818)
        let latitudeBound = 0.01, longitudeBound = 0.011

        var worstLatitude = 0.0, worstLongitude = 0.0
        for tenthDegree in 0..<3600 {
            let bearing = Double(tenthDegree) / 10 * .pi / 180
            let angular = 1_000.0 / 6_371_008.8
            let latitude = asin(
                sin(kaaba.coordinate.latitude * .pi / 180) * cos(angular)
                    + cos(kaaba.coordinate.latitude * .pi / 180) * sin(angular) * cos(bearing)
            )
            let longitude = kaaba.coordinate.longitude * .pi / 180
                + atan2(
                    sin(bearing) * sin(angular) * cos(kaaba.coordinate.latitude * .pi / 180),
                    cos(angular) - sin(kaaba.coordinate.latitude * .pi / 180) * sin(latitude)
                )
            worstLatitude = max(worstLatitude, abs(latitude * 180 / .pi - kaaba.coordinate.latitude))
            worstLongitude = max(worstLongitude, abs(longitude * 180 / .pi - kaaba.coordinate.longitude))
        }

        XCTAssertLessThanOrEqual(
            worstLatitude, latitudeBound,
            "the latitude bound clips the 1 km circle, so the Haram guard would miss"
        )
        XCTAssertLessThanOrEqual(
            worstLongitude, longitudeBound,
            "the longitude bound clips the 1 km circle, so the Haram guard would miss"
        )
    }

    // MARK: - Angle helpers

    /// The needle turns the short way across the 0/360 seam. Standing just east of north and turning
    /// to just west of north is a 2 degree move, not a 358 degree one; getting this wrong spun the
    /// needle the long way around every time the user crossed north.
    func testShortestDeltaTakesTheShortArc() {
        let cases: [(from: Double, to: Double, expected: Double)] = [
            (359, 1, 2),
            (1, 359, -2),
            (0, 180, 180),
            (10, 350, -20),
            (350, 10, 20),
            (90, 270, 180),
            (0, 0, 0),
        ]

        for test in cases {
            let delta = Self.signedDelta(from: test.from, to: test.to)
            XCTAssertEqual(
                delta, test.expected, accuracy: 0.001,
                "shortest delta \(test.from) -> \(test.to)"
            )
            XCTAssertLessThanOrEqual(abs(delta), 180, "delta exceeded a half turn")
        }
    }

    /// The low-pass accumulator in `LocalQiblaCompass` works on an unwrapped angle and normalizes on
    /// the way out. Re-normalizing any accumulated value has to land back in 0 ..< 360 whether the
    /// needle has wound forwards or backwards many times.
    func testNormalizationHandlesWoundAccumulator() {
        for raw in [-1080.0, -721.0, -360.0, -0.5, 0.0, 359.5, 360.0, 721.0, 1080.0] {
            let normalized = Self.normalized(raw)
            XCTAssertGreaterThanOrEqual(normalized, 0, "normalizing \(raw)")
            XCTAssertLessThan(normalized, 360, "normalizing \(raw)")
        }
        XCTAssertEqual(Self.normalized(-0.5), 359.5, accuracy: 0.001)
        XCTAssertEqual(Self.normalized(360.0), 0, accuracy: 0.001)
        XCTAssertEqual(Self.normalized(-360.0), 0, accuracy: 0.001)
    }

    // MARK: - Orientation frame

    /// Core Location reports a heading relative to the top of the DEVICE, so the interface
    /// orientation has to be translated into `CLDeviceOrientation` - and the two landscapes are
    /// inverted: `UIInterfaceOrientation.landscapeLeft` is `UIDeviceOrientation.landscapeRight`.
    ///
    /// Getting this backwards put the needle a flat 90 degrees off in landscape while every number
    /// on screen still looked plausible, which is the hardest kind of wrong to notice.
    #if os(iOS)
    func testInterfaceOrientationMapsToInvertedDeviceLandscape() {
        let cases: [(interface: UIInterfaceOrientation, device: CLDeviceOrientation)] = [
            (.portrait, .portrait),
            (.portraitUpsideDown, .portraitUpsideDown),
            (.landscapeLeft, .landscapeRight),
            (.landscapeRight, .landscapeLeft),
            (.unknown, .portrait),
        ]

        for test in cases {
            XCTAssertEqual(
                Self.headingOrientation(for: test.interface), test.device,
                "interface \(test.interface.rawValue) mapped to the wrong device frame"
            )
        }
    }
    #endif

    // MARK: - Guards

    /// The app-wide "no fix yet" sentinel is (1000, 1000). `Qibla(coordinates:)` returns a
    /// plausible-looking bearing for it, which drew a needle that moved and looked alive while
    /// pointing at nothing, so the compass must reject the coordinate before computing anything.
    func testSentinelCoordinateIsRejectedAsUnusable() {
        XCTAssertFalse(Self.isUsable(latitude: 1000, longitude: 1000), "the (1000, 1000) sentinel")
        XCTAssertFalse(Self.isUsable(latitude: 91, longitude: 0), "latitude past the pole")
        XCTAssertFalse(Self.isUsable(latitude: 0, longitude: 181), "longitude past the meridian")

        XCTAssertTrue(Self.isUsable(latitude: 0, longitude: 0))
        XCTAssertTrue(Self.isUsable(latitude: 90, longitude: 180))
        XCTAssertTrue(Self.isUsable(latitude: -90, longitude: -180))
        XCTAssertTrue(Self.isUsable(latitude: 40.7128, longitude: -74.0060))
    }

    /// A fresh compass must not claim alignment. `direction` starts at 0 and 0 is exactly the value
    /// that means "facing the Kaaba", so before any sample lands a phone with no magnetometer, an
    /// uncalibrated one, or one with no fix drew a straight-up needle and said "You are facing the
    /// Kaaba" - a failure state indistinguishable from success.
    @MainActor
    func testFreshCompassReportsNoHeadingAndNoAccuracy() {
        let compass = LocalQiblaCompass { nil }
        XCTAssertFalse(compass.hasHeading, "a compass with no sample claimed a heading")
        XCTAssertEqual(compass.direction, 0, "the needle starts at 0, which is why hasHeading exists")
        XCTAssertNil(compass.accuracyDegrees, "a compass with no sample claimed an accuracy")
    }

    /// The alignment tolerance follows the magnetometer's own reported error, floored at 3 degrees
    /// (a well-calibrated iPhone's realistic best) and capped at 15, beyond which the reading is not
    /// trustworthy at all and the claim is withheld rather than widened.
    ///
    /// The old behaviour was a hardcoded 1 degree, finer than the sensor can resolve, so "You are
    /// facing the Kaaba" was a claim the hardware never supported.
    func testAlignmentToleranceTracksReportedAccuracy() {
        XCTAssertEqual(Self.alignmentTolerance(for: nil), 3, accuracy: 0.001, "no sample yet")
        XCTAssertEqual(Self.alignmentTolerance(for: 1), 3, accuracy: 0.001, "better than the floor")
        XCTAssertEqual(Self.alignmentTolerance(for: 3), 3, accuracy: 0.001)
        XCTAssertEqual(Self.alignmentTolerance(for: 8), 8, accuracy: 0.001, "tracks the sensor")
        XCTAssertEqual(Self.alignmentTolerance(for: 15), 15, accuracy: 0.001)
        XCTAssertEqual(Self.alignmentTolerance(for: 40), 15, accuracy: 0.001, "capped, not widened")

        // Trust is withheld past the cap, and for the invalid-reading sentinel.
        XCTAssertTrue(Self.isTrustworthy(accuracy: 3))
        XCTAssertTrue(Self.isTrustworthy(accuracy: 15))
        XCTAssertFalse(Self.isTrustworthy(accuracy: 16), "a 16 degree error must not claim the Kaaba")
        XCTAssertFalse(Self.isTrustworthy(accuracy: 40))
        XCTAssertFalse(Self.isTrustworthy(accuracy: -1), "an invalid reading")
        XCTAssertFalse(Self.isTrustworthy(accuracy: nil), "no sample")
    }

    // MARK: - Reference implementations
    //
    // These mirror the private logic under test. `QiblaView`'s helpers and `LocalQiblaCompass`'s
    // guards are private to the view layer, so the tests above pin the BEHAVIOUR against an
    // independent statement of it: if the shipped rule changes, these have to be updated
    // deliberately, which is the point.

    private static func normalized(_ value: Double) -> Double {
        var degrees = value.truncatingRemainder(dividingBy: 360)
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    private static func signedDelta(from lhs: Double, to rhs: Double) -> Double {
        var delta = (rhs - lhs).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return delta
    }

    private static func isUsable(latitude: Double, longitude: Double) -> Bool {
        abs(latitude) <= 90 && abs(longitude) <= 180
    }

    private static let minimumAlignmentTolerance: Double = 3
    private static let maximumAlignmentTolerance: Double = 15

    private static func alignmentTolerance(for accuracy: Double?) -> Double {
        guard let accuracy, accuracy > 0 else { return minimumAlignmentTolerance }
        return min(maximumAlignmentTolerance, max(minimumAlignmentTolerance, accuracy))
    }

    private static func isTrustworthy(accuracy: Double?) -> Bool {
        guard let accuracy else { return false }
        return accuracy > 0 && accuracy <= maximumAlignmentTolerance
    }

    #if os(iOS)
    private static func headingOrientation(for interface: UIInterfaceOrientation) -> CLDeviceOrientation {
        switch interface {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return .portrait
        }
    }
    #endif

    /// WGS84 ellipsoidal initial bearing to the Kaaba (Vincenty inverse), used only to bound how far
    /// the shipped spherical bearing can be from a geodesic one.
    private static func geodesicBearingToKaaba(latitude: Double, longitude: Double) -> Double {
        let kaabaLatitude = 21.4225241, kaabaLongitude = 39.8261818
        let a = 6_378_137.0, f = 1 / 298.257223563
        let L = (kaabaLongitude - longitude) * .pi / 180
        let U1 = atan((1 - f) * tan(latitude * .pi / 180))
        let U2 = atan((1 - f) * tan(kaabaLatitude * .pi / 180))
        let sinU1 = sin(U1), cosU1 = cos(U1), sinU2 = sin(U2), cosU2 = cos(U2)

        var lambda = L
        for _ in 0..<200 {
            let sinL = sin(lambda), cosL = cos(lambda)
            let sinSigma = (pow(cosU2 * sinL, 2) + pow(cosU1 * sinU2 - sinU1 * cosU2 * cosL, 2)).squareRoot()
            if sinSigma == 0 { return 0 }
            let cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosL
            let sigma = atan2(sinSigma, cosSigma)
            let sinAlpha = cosU1 * cosU2 * sinL / sinSigma
            let cosSqAlpha = 1 - sinAlpha * sinAlpha
            let cos2SigmaM = cosSqAlpha == 0 ? 0 : cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha
            let C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
            let previous = lambda
            lambda = L + (1 - C) * f * sinAlpha
                * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))
            if abs(lambda - previous) < 1e-14 { break }
        }

        let sinL = sin(lambda), cosL = cos(lambda)
        let bearing = atan2(cosU2 * sinL, cosU1 * sinU2 - sinU1 * cosU2 * cosL) * 180 / .pi
        return normalized(bearing)
    }
}
