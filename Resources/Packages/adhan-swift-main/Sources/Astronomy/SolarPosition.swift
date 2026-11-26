//
//  SolarPosition.swift
//  Adhan
//
//  Added for Al-Islam's Flight Mode (2026-11-25). Not part of upstream adhan-swift.
//

import Foundation

/// Where the sun is at one instant, for an observer anywhere on Earth.
///
/// `PrayerTimes` answers "when does the sun reach this angle today, at this fixed place": it solves
/// for a time with the place held still. An observer who is moving (a passenger in an aircraft) has
/// no fixed place to solve at, so the question has to be asked the other way round: "how high is the
/// sun right now, from here?", evaluated along the route until the angle is crossed. This is that
/// question, built from the same `SolarCoordinates` the prayer times use, so a route that stands
/// still gives the same times they do.
public struct SolarPosition {

    /// The sun's declination, in degrees.
    public let declination: Double

    /// The sun's hour angle at the Greenwich meridian, in degrees, in 0..<360. The local hour angle
    /// is this plus the observer's east longitude.
    public let greenwichHourAngle: Double

    public init(date: Date) {
        // The Julian day of an instant: 2440587.5 is 1970-01-01 00:00 UTC.
        let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let solar = SolarCoordinates(julianDay: julianDay)
        self.declination = solar.declination.degrees
        self.greenwichHourAngle = (solar.apparentSiderealTime.degrees - solar.rightAscension.degrees)
            .normalizedToScale(360)
    }

    /// The local hour angle at an east longitude, in degrees, in -180...180: negative before the sun
    /// crosses the observer's meridian (morning), zero at the crossing (solar noon), positive after.
    public func hourAngle(longitude: Double) -> Double {
        let angle = (greenwichHourAngle + longitude).normalizedToScale(360)
        return angle > 180 ? angle - 360 : angle
    }

    /// The altitude of the sun's centre above the astronomical horizon, in degrees, with no
    /// refraction applied (the convention the prayer angles are written in: sunrise is -0.8333).
    public func altitude(latitude: Double, longitude: Double) -> Double {
        Astronomical.altitudeOfCelestialBody(
            observerLatitude: Angle(latitude),
            declination: Angle(declination),
            localHourAngle: Angle(hourAngle(longitude: longitude))
        ).degrees
    }

    /// The altitude at which Asr begins at a latitude: the sun's height when an object's shadow is
    /// `shadowLength` times its height longer than its shadow at noon (1, or 2 for the Hanafi school).
    public func asrAltitude(latitude: Double, shadowLength: Double) -> Double {
        let tangent = Angle(fabs(latitude - declination))
        let inverse = shadowLength + tan(tangent.radians)
        return Angle(radians: atan(1.0 / inverse)).degrees
    }
}
