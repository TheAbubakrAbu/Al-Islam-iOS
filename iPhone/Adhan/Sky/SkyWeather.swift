// The sky's weather (Abu, 2026-10-11: "include weather conditions and temp and uv and humidity and
// all that stuff... so that it follows that, for both full page and tiny solar and widgets").
//
// This file is the part every sky shares: the reading itself, how it greys and veils a prayer's
// gradient, and the still frame of clouds, rain, snow or fog drawn over it. The app's card, the
// whole-tab sky (`SkyPageBackground`) and the sky widgets all paint from here, so the three skies
// agree. Fetching lives in SkyWeatherStore.swift (the app only; a widget reads the app's cache).
//
// Compiled for every target like SkyPalette.swift (the complication builds the widget provider,
// whose entry carries a reading), so nothing here is iOS-only; only the fetch is.
import SwiftUI

/// One Apple Weather reading, flattened to plain numbers and strings so the widget extension and the
/// unit tests never need WeatherKit. Stored as JSON in the app group under `storageKey`.
struct SkyWeather: Codable, Equatable {
    static let storageKey = "skyWeather"

    /// A reading older than this is not shown and no longer tints the sky: the hour it described is
    /// over, and a stale "Rain" on a clear afternoon is worse than no weather.
    static let freshFor: TimeInterval = 3 * 60 * 60
    /// The app asks Apple again once the reading is this old (while the Adhan tab is in front, or a
    /// location fix lands). Half an hour keeps a day's use to a handful of calls against the
    /// 500,000-a-month allowance that comes with the developer membership.
    static let refreshAfter: TimeInterval = 30 * 60
    /// A reading for a place this far from the current fix describes somewhere else.
    static let describesWithinMetres: Double = 25_000

    var fetchedAt: Date
    var latitude: Double
    var longitude: Double

    var temperatureC: Double
    var apparentC: Double
    var highC: Double?
    var lowC: Double?
    /// 0...1
    var humidity: Double
    var dewPointC: Double
    var uvIndex: Int
    /// "Low", "Moderate", "High", "Very High", "Extreme".
    var uvCategory: String
    /// 0...1
    var cloudCover: Double
    /// WeatherKit's `WeatherCondition` raw value ("partlyCloudy"); the look below is keyed on it.
    var condition: String
    /// Its sentence ("Partly Cloudy").
    var conditionText: String
    /// The SF Symbol WeatherKit names for the condition ("cloud.sun.fill").
    var symbolName: String
    var windKph: Double
    /// "NW"
    var windDirection: String
    var visibilityKm: Double
    var pressureHPa: Double
    /// "Rising", "Falling", "Steady".
    var pressureTrend: String
    /// This hour's chance of precipitation, 0...1, when the hourly forecast was available.
    var precipitationChance: Double?
    /// This hour's expected precipitation in millimetres.
    var precipitationMm: Double
    var isDaylight: Bool

    func isFresh(at now: Date = Date()) -> Bool {
        let age = now.timeIntervalSince(fetchedAt)
        return age >= -60 && age < Self.freshFor
    }

    func needsRefresh(at now: Date = Date()) -> Bool {
        now.timeIntervalSince(fetchedAt) >= Self.refreshAfter
    }

    /// Whether this reading was taken close enough to `latitude`/`longitude` to describe it.
    func describes(latitude: Double, longitude: Double) -> Bool {
        Self.metres(fromLatitude: self.latitude, longitude: self.longitude, toLatitude: latitude, longitude: longitude)
            <= Self.describesWithinMetres
    }

    /// Haversine, so this file needs no CoreLocation.
    static func metres(fromLatitude lat1: Double, longitude lon1: Double,
                       toLatitude lat2: Double, longitude lon2: Double) -> Double {
        let radius = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * radius * atan2(sqrt(a), sqrt(1 - a))
    }

    // MARK: Reading the cache

    /// The reading a process can see: the app group's copy (the app writes it there for the widgets).
    static func cached(in store: UserDefaults?) -> SkyWeather? {
        guard let data = store?.data(forKey: storageKey), !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(SkyWeather.self, from: data)
    }

    /// The cached reading, if it is still fresh.
    static func freshCached(in store: UserDefaults?, at now: Date = Date()) -> SkyWeather? {
        guard let weather = cached(in: store), weather.isFresh(at: now) else { return nil }
        return weather
    }

    // MARK: Text

    /// "72°" in the device's locale (Fahrenheit where the region uses it).
    static func temperatureText(celsius: Double) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        return measurement.formatted(.measurement(width: .narrow, usage: .weather,
                                                  numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    var temperatureText: String { Self.temperatureText(celsius: temperatureC) }
    var apparentText: String { Self.temperatureText(celsius: apparentC) }
    var dewPointText: String { Self.temperatureText(celsius: dewPointC) }
    var highText: String? { highC.map(Self.temperatureText(celsius:)) }
    var lowText: String? { lowC.map(Self.temperatureText(celsius:)) }

    /// "45%"
    var humidityText: String { "\(Int((humidity * 100).rounded()))%" }
    /// "40%"
    var cloudCoverText: String { "\(Int((cloudCover * 100).rounded()))%" }
    /// "8 mph NW" (km/h where the region uses it).
    var windText: String {
        let speed = Measurement(value: windKph, unit: UnitSpeed.kilometersPerHour)
        let text = speed.formatted(.measurement(width: .abbreviated, usage: .general,
                                                numberFormatStyle: .number.precision(.fractionLength(0))))
        return windDirection.isEmpty ? text : "\(text) \(windDirection)"
    }
    /// "10 mi"
    var visibilityText: String {
        Measurement(value: visibilityKm, unit: UnitLength.kilometers)
            .formatted(.measurement(width: .abbreviated, usage: .road,
                                    numberFormatStyle: .number.precision(.fractionLength(0))))
    }
    /// "1,013 hPa"
    var pressureText: String {
        let pressure = Measurement(value: pressureHPa, unit: UnitPressure.hectopascals)
        // `.barometric` is iOS 16; the companions' floor is iOS 15, where the reading shows as given.
        if #available(iOS 16.0, *) {
            return pressure.formatted(.measurement(width: .abbreviated, usage: .barometric,
                                                   numberFormatStyle: .number.precision(.fractionLength(0))))
        }
        return pressure.formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                               numberFormatStyle: .number.precision(.fractionLength(0))))
    }
    /// "30%" or nil when the hourly forecast was not available.
    var precipitationChanceText: String? {
        precipitationChance.map { "\(Int(($0 * 100).rounded()))%" }
    }
    /// "0.2 mm" (inches where the region uses them).
    var precipitationText: String {
        let amount = Measurement(value: precipitationMm, unit: UnitLength.millimeters)
        // `.rainfall` is iOS 16, like `.barometric` above; on iOS 15 the reading shows as given.
        if #available(iOS 16.0, *) {
            return amount.formatted(.measurement(width: .abbreviated, usage: .rainfall,
                                                 numberFormatStyle: .number.precision(.fractionLength(0...1))))
        }
        return amount.formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                             numberFormatStyle: .number.precision(.fractionLength(0...1))))
    }
    /// "UV 3"
    var uvShortText: String { "UV \(uvIndex)" }

    /// What a widget redraws for: the chip's text and the sky's look. Two readings with the same
    /// signature paint the same widget, so the app skips the reload.
    var widgetSignature: String {
        "\(temperatureText)|\(symbolName)|\(look.signature)"
    }

    // MARK: The look

    var look: SkyWeatherLook { SkyWeatherLook(condition: condition, cloudCover: cloudCover) }
}

/// How a reading changes the sky: how far the gradient greys toward overcast, how much of a white
/// veil fog lays over it, and what the overlay draws. Derived from the condition and the cloud cover
/// alone, so it is pure and testable.
struct SkyWeatherLook: Equatable {
    enum Precipitation: Equatable {
        case none
        /// 0...1 how hard.
        case rain(Double)
        case snow(Double)
    }

    /// 0...1: how far the gradient mixes toward an overcast grey.
    var overcast: Double
    /// 0...1: the fog, haze or smoke veil.
    var fog: Double
    /// 0...1: the cloud puffs drawn over the sky.
    var cloudCover: Double
    var precipitation: Precipitation
    /// Lightning weather: the gradient darkens a step further.
    var storm: Bool

    static let clear = SkyWeatherLook(overcast: 0, fog: 0, cloudCover: 0, precipitation: .none, storm: false)

    init(overcast: Double, fog: Double, cloudCover: Double, precipitation: Precipitation, storm: Bool) {
        self.overcast = overcast
        self.fog = fog
        self.cloudCover = cloudCover
        self.precipitation = precipitation
        self.storm = storm
    }

    /// WeatherKit's `WeatherCondition` raw values, each to the three dials above.
    init(condition: String, cloudCover: Double) {
        let cover = min(max(cloudCover, 0), 1)
        var precipitation: Precipitation = .none
        var fog = 0.0
        var storm = false
        switch condition {
        case "drizzle", "freezingDrizzle":                       precipitation = .rain(0.3)
        case "rain", "freezingRain", "sunShowers":               precipitation = .rain(0.6)
        case "heavyRain", "hurricane", "tropicalStorm":          precipitation = .rain(1.0)
        case "isolatedThunderstorms":                            precipitation = .rain(0.4); storm = true
        case "scatteredThunderstorms":                           precipitation = .rain(0.6); storm = true
        case "thunderstorms":                                    precipitation = .rain(0.8); storm = true
        case "strongStorms":                                     precipitation = .rain(1.0); storm = true
        case "flurries", "sunFlurries":                          precipitation = .snow(0.3)
        case "snow", "wintryMix", "sleet", "hail":               precipitation = .snow(0.6)
        case "heavySnow", "blizzard", "blowingSnow":             precipitation = .snow(1.0)
        case "foggy":                                            fog = 1.0
        case "haze", "smoky", "blowingDust":                     fog = 0.5
        default: break
        }
        var overcast = cover * 0.9
        switch precipitation {
        case .rain(let amount), .snow(let amount): overcast = max(overcast, 0.6 + 0.3 * amount)
        case .none: break
        }
        if storm { overcast = max(overcast, 0.95) }
        if fog > 0 { overcast = max(overcast, 0.5 * fog) }
        self.init(overcast: min(overcast, 1), fog: fog, cloudCover: cover, precipitation: precipitation, storm: storm)
    }

    /// Nothing worth painting: a few percent of cloud is a clear sky to the eye (and to the tint).
    var isClear: Bool {
        overcast < 0.03 && fog == 0 && precipitation == .none && !storm
    }

    /// How much of the stars still show: clouds hide them.
    var starFactor: Double { max(0, 1 - cloudCover) * (1 - 0.6 * fog) }

    /// The buckets a widget's picture changes on (a cloud cover of 41% and 44% draw the same).
    var signature: String {
        let precip: String
        switch precipitation {
        case .none: precip = "-"
        case .rain(let amount): precip = "r\(Int(amount * 10))"
        case .snow(let amount): precip = "s\(Int(amount * 10))"
        }
        return "o\(Int(overcast * 10))f\(Int(fog * 10))c\(Int(cloudCover * 10))\(precip)\(storm ? "!" : "")"
    }
}

/// A colour as three 0...1 components, so the tint maths needs no UIKit and runs in a test.
struct SkyRGB: Equatable {
    var red: Double
    var green: Double
    var blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// "RRGGBB", a leading "#" allowed.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let rgb = UInt64(s, radix: 16) else { return nil }
        red = Double((rgb >> 16) & 0xFF) / 255
        green = Double((rgb >> 8) & 0xFF) / 255
        blue = Double(rgb & 0xFF) / 255
    }

    var luminance: Double { 0.2126 * red + 0.7152 * green + 0.0722 * blue }

    func mixed(toward other: SkyRGB, by amount: Double) -> SkyRGB {
        let t = min(max(amount, 0), 1)
        return SkyRGB(red: red + (other.red - red) * t,
                      green: green + (other.green - green) * t,
                      blue: blue + (other.blue - blue) * t)
    }

    func scaled(_ factor: Double) -> SkyRGB {
        SkyRGB(red: red * factor, green: green * factor, blue: blue * factor)
    }

    var color: Color { Color(red: red, green: green, blue: blue) }
}

/// The gradient under the weather: a prayer's two stops, greyed by the overcast and veiled by the fog.
enum SkyWeatherTint {
    /// A cool overcast grey for a day sky...
    static let dayOvercast = SkyRGB(red: 0.60, green: 0.64, blue: 0.70)
    /// ...and a near-black one for the night, so Isha's navy goes charcoal rather than silver.
    static let nightOvercast = SkyRGB(red: 0.14, green: 0.15, blue: 0.19)
    static let fogVeil = SkyRGB(red: 0.80, green: 0.82, blue: 0.85)
    static let nightFogVeil = SkyRGB(red: 0.30, green: 0.31, blue: 0.35)

    /// The overcast never flattens a sky completely: the period must stay recognizable through it.
    static let maxOvercastMix = 0.62
    static let maxFogMix = 0.40

    /// A stop under `look`. Night is judged per stop by its luminance, so Maghrib's warm top and
    /// dark bottom each grey toward the grey that suits them.
    static func tint(_ stop: SkyRGB, look: SkyWeatherLook) -> SkyRGB {
        guard !look.isClear else { return stop }
        let night = stop.luminance < 0.18
        var out = stop.mixed(toward: night ? nightOvercast : dayOvercast, by: look.overcast * maxOvercastMix)
        if look.fog > 0 {
            out = out.mixed(toward: night ? nightFogVeil : fogVeil, by: look.fog * maxFogMix)
        }
        if look.storm {
            out = out.scaled(0.88)
        }
        return out
    }

    /// The two (or more) stops of a gradient, as hex strings, under `look`.
    static func colors(hexes: [String], look: SkyWeatherLook) -> [Color] {
        hexes.map { hex in
            guard let rgb = SkyRGB(hex: hex) else { return Color.black }
            return tint(rgb, look: look).color
        }
    }
}

extension Settings {
    /// The sky gradient for `transliteration`, under `weather` (a nil or clear reading is the plain
    /// gradient, exactly `skyGradientColors(forPrayer:)`). Every surface that paints a weather sky
    /// asks this, so the card, the page and the widgets grey together.
    func skyGradientColors(forPrayer transliteration: String?, weather: SkyWeather?) -> [Color] {
        guard let weather, !weather.look.isClear else { return skyGradientColors(forPrayer: transliteration) }
        return SkyWeatherTint.colors(hexes: skyGradientHexes(for: SkyPalette.editableKey(for: transliteration)),
                                     look: weather.look)
    }
}

// MARK: - The field

/// Where every cloud puff, fog bank, raindrop and snowflake sits at a moment, and when the lightning
/// strikes: pure maths over a fixed seed and `time`, like `SkyStars`, so the card, the page and a
/// widget agree on the frame, nothing reshuffles between frames (each particle keeps its own lane and
/// pace), and a test can watch it move. The overlay only paints what this places. Sizes are in points;
/// the speeds scale with the box, as the streaks and the puffs do.
enum SkyWeatherField {
    struct Streak: Equatable { var x: Double; var y: Double; var length: Double }
    struct Flake: Equatable { var x: Double; var y: Double; var radius: Double }
    /// A cloud puff or a fog bank; `x`, `y` is its centre.
    struct Puff: Equatable { var x: Double; var y: Double; var width: Double; var height: Double }

    /// The clouds' and the fog's cadence: a puff drifts a few points a second, so 8 fps is smooth, and
    /// the blur under each puff is the dearest stroke on the sky.
    static let slowFrameInterval: TimeInterval = 1.0 / 8.0

    /// The precipitation layer's cadence, nil when nothing falls (no layer at all then). Rain crosses
    /// the box in under a second and needs the full 30; snow drifts, 24 is plenty.
    static func fastFrameInterval(for look: SkyWeatherLook) -> TimeInterval? {
        switch look.precipitation {
        case .none: return nil
        case .rain: return 1.0 / 30.0
        case .snow: return 1.0 / 24.0
        }
    }

    /// `value` folded into `0..<span`.
    static func wrapped(_ value: Double, span: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: span)
        return remainder < 0 ? min(remainder + span, span.nextDown) : remainder
    }

    /// The stars' generator: the same seed gives the same field everywhere.
    private struct Generator {
        var seed: UInt64
        mutating func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((seed >> 33) & 0xFFFF) / Double(0xFFFF)
        }
    }

    /// Streaks leaning with the wind, denser as it pours. Each falls at its own pace along its own
    /// lean, so the sheet never moves as one.
    static func rain(amount: Double, size: CGSize, time: TimeInterval) -> [Streak] {
        var rng = Generator(seed: 0x51CE_C10D)
        let count = Int(30 + 70 * amount)
        let length = max(9, size.height * 0.06)
        return (0..<count).map { _ in
            let x0 = rng.next() * size.width
            let y0 = rng.next() * size.height
            let speed = (1.0 + 0.5 * rng.next()) * size.height
            let travelled = speed * time
            return Streak(x: wrapped(x0 - 0.25 * travelled, span: size.width),
                          y: wrapped(y0 + travelled, span: size.height),
                          length: length)
        }
    }

    /// Flakes drifting down and swaying as they go; the big ones are the near ones, falling faster and
    /// swinging wider.
    static func snow(amount: Double, size: CGSize, time: TimeInterval) -> [Flake] {
        var rng = Generator(seed: 0x5A0F_1A4E)
        let count = Int(24 + 56 * amount)
        return (0..<count).map { _ in
            let x0 = rng.next() * size.width
            let y0 = rng.next() * size.height
            let radius = 0.9 + rng.next() * 1.4
            let near = (radius - 0.9) / 1.4
            let speed = (0.08 + 0.10 * near) * size.height
            let period = 2.4 + 1.6 * rng.next()
            let phase = rng.next()
            let sway = (5 + 7 * near) * sin(2 * .pi * (time / period + phase))
            return Flake(x: wrapped(x0 + sway, span: size.width),
                         y: wrapped(y0 + speed * time, span: size.height),
                         radius: radius)
        }
    }

    /// Puffs across the upper sky, more with the cover, drifting left with the wind (the way the rain
    /// leans), the wider, nearer ones a little faster. A puff leaves at the left edge and comes back in
    /// at the right, so the wrap is the box plus a puff's width each side.
    static func clouds(cover: Double, size: CGSize, time: TimeInterval) -> [Puff] {
        guard cover > 0.12 else { return [] }
        var rng = Generator(seed: 0xC10D_D81F)
        let count = Int((cover * 9).rounded())
        return (0..<count).map { _ in
            let x0 = rng.next() * size.width
            let y = (0.06 + rng.next() * 0.48) * size.height
            let w = (0.16 + rng.next() * 0.20) * size.width
            let h = w * (0.28 + rng.next() * 0.14)
            // A puff crosses the box in half a minute to a minute: slow enough to be cloud, quick
            // enough that a glance at the card sees it move.
            let speed = (0.015 + 0.02 * (w / size.width - 0.16) / 0.20) * size.width
            return Puff(x: drifting(from: x0, width: w, speed: speed, time: time, across: size.width), y: y, width: w, height: h)
        }
    }

    /// Three low, wide banks drifting through the fog veil, so fog is weather and not only a tint.
    static func fogBanks(size: CGSize, time: TimeInterval) -> [Puff] {
        var rng = Generator(seed: 0xF06B_A4C5)
        return (0..<3).map { index in
            let w = (0.55 + rng.next() * 0.35) * size.width
            let h = (0.08 + rng.next() * 0.06) * size.height
            let y = (0.58 + 0.14 * Double(index) + rng.next() * 0.08) * size.height
            let x0 = rng.next() * size.width
            let speed = (0.015 + 0.01 * rng.next()) * size.width
            return Puff(x: drifting(from: x0, width: w, speed: speed, time: time, across: size.width), y: y, width: w, height: h)
        }
    }

    /// The centre of a shape `width` wide that started at `x0` and drifts left at `speed` points a
    /// second, wrapping once it has fully left the box (so it comes back in at the right edge whole).
    private static func drifting(from x0: Double, width: Double, speed: Double, time: TimeInterval, across boxWidth: Double) -> Double {
        wrapped(x0 + width - speed * time, span: boxWidth + 2 * width) - width
    }

    /// A storm's whole-sky flash, 0...1: a strike every ten seconds or so (nine-second cycles, six in
    /// ten striking, each at its own moment), two flickers 120 ms apart, a sharp attack and a 160 ms
    /// fade. Deterministic in `time`, so the card and the page flash together.
    static func lightning(at time: TimeInterval) -> Double {
        let cycle = 9.0
        let index = (time / cycle).rounded(.down)
        let t = time - index * cycle
        let hash = wrapped(sin(index * 12.9898 + 78.233) * 43758.5453, span: 1)
        guard hash < 0.6 else { return 0 }
        let strike = 1 + (hash / 0.6) * (cycle - 2)
        func flicker(_ dt: Double, peak: Double) -> Double {
            guard dt >= 0, dt < 0.16 else { return 0 }
            return peak * (1 - dt / 0.16)
        }
        return max(flicker(t - strike, peak: 1), flicker(t - strike - 0.12, peak: 0.7))
    }
}

// MARK: - The overlay

/// The weather over a sky: cloud puffs drifting across the upper sky, rain streaking or snow drifting
/// down across all of it, fog banks low down, a storm's flash. Two Canvases, each on its own clock
/// (Abu, 2026-10-21: "make rain and conditions move"): the clouds and the fog at 8 fps, since a puff
/// moves a few points a second and its blur is the dearest stroke here; the rain or the snow at 30 or
/// 24, in a layer that exists only while something falls. Both hold a still frame while `paused` (the
/// card off screen, another tab in front of the page, animation reduced), as the stars do. What each
/// frame places comes from `SkyWeatherField`, so a widget draws the same field through `draw`.
struct SkyWeatherOverlay: View {
    let look: SkyWeatherLook
    /// True over a night gradient: the clouds go grey instead of white.
    let night: Bool
    /// True while the sky is off screen or animation is reduced: the layers hold one still frame.
    var paused: Bool = false

    var body: some View {
        ZStack {
            if look.cloudCover > 0.12 || look.fog > 0 {
                TimelineView(.animation(minimumInterval: SkyWeatherField.slowFrameInterval, paused: paused)) { timeline in
                    Canvas { context, size in
                        Self.drawSky(in: &context, size: size, look: look, night: night,
                                     time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
            if let interval = SkyWeatherField.fastFrameInterval(for: look) {
                TimelineView(.animation(minimumInterval: interval, paused: paused)) { timeline in
                    Canvas { context, size in
                        Self.drawPrecipitation(in: &context, size: size, look: look, night: night,
                                               time: timeline.date.timeIntervalSinceReferenceDate, lightning: true)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One still frame of the whole field, for a widget's `Canvas`: the same clouds, fog and
    /// precipitation at `time`, without the lightning (a frame that stands for half an hour should not
    /// be a lit one).
    static func draw(in context: inout GraphicsContext, size: CGSize, look: SkyWeatherLook, night: Bool, time: TimeInterval) {
        drawSky(in: &context, size: size, look: look, night: night, time: time)
        drawPrecipitation(in: &context, size: size, look: look, night: night, time: time, lightning: false)
    }

    /// The slow layer: the clouds and the fog.
    static func drawSky(in context: inout GraphicsContext, size: CGSize, look: SkyWeatherLook, night: Bool, time: TimeInterval) {
        guard !look.isClear, size.width > 1, size.height > 1 else { return }

        // Clouds: soft puffs, each three overlapping ellipses blurred together so it reads as cloud
        // rather than as three discs. Kept faint (Abu, 2026-10-11: "clouds are too strong"; they were
        // bright white blobs on every cloudy sky), and fading as the sky greys over: an overcast sky is
        // one grey, its tint already says so, and separate puffs on it read as decoration rather than
        // weather.
        let puffs = SkyWeatherField.clouds(cover: look.cloudCover, size: size, time: time)
        if !puffs.isEmpty {
            let distinct = 1 - 0.55 * look.overcast
            let alpha = (night ? 0.03 + 0.06 * look.cloudCover : 0.06 + 0.10 * look.cloudCover) * distinct
            let fill = night ? Color(white: 0.78) : Color.white
            var clouds = context
            clouds.addFilter(.blur(radius: max(8, size.width * 0.03)))
            for puff in puffs {
                for (dx, scale) in [(-0.28, 0.72), (0.0, 1.0), (0.3, 0.8)] {
                    let rect = CGRect(x: puff.x + dx * puff.width - puff.width * scale / 2,
                                      y: puff.y - puff.height * scale / 2,
                                      width: puff.width * scale, height: puff.height * scale)
                    clouds.fill(Path(ellipseIn: rect), with: .color(fill.opacity(alpha)))
                }
            }
        }

        // Fog: a veil that thickens toward the ground, where fog sits, with banks drifting through it.
        if look.fog > 0 {
            let veil = night ? Color(white: 0.6) : Color.white
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(veil.opacity(0.10 * look.fog)))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [veil.opacity(0), veil.opacity(0.32 * look.fog)]),
                startPoint: CGPoint(x: size.width / 2, y: size.height * 0.35),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            ))
            var banks = context
            banks.addFilter(.blur(radius: max(10, size.width * 0.05)))
            for bank in SkyWeatherField.fogBanks(size: size, time: time) {
                let rect = CGRect(x: bank.x - bank.width / 2, y: bank.y - bank.height / 2,
                                  width: bank.width, height: bank.height)
                banks.fill(Path(ellipseIn: rect), with: .color(veil.opacity((night ? 0.07 : 0.11) * look.fog)))
            }
        }
    }

    /// The fast layer: the rain or the snow, over a storm's flash.
    static func drawPrecipitation(in context: inout GraphicsContext, size: CGSize, look: SkyWeatherLook, night: Bool,
                                  time: TimeInterval, lightning: Bool) {
        guard !look.isClear, size.width > 1, size.height > 1 else { return }

        // Lightning: a flash out of the clouds, brightest at the top, faint enough to read as weather
        // and never as a strobe.
        if lightning, look.storm {
            let flash = SkyWeatherField.lightning(at: time)
            if flash > 0 {
                let peak = (night ? 0.22 : 0.16) * flash
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(colors: [.white.opacity(peak), .white.opacity(peak * 0.35)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            }
        }

        switch look.precipitation {
        case .none:
            break
        case .rain(let amount):
            let ink = Color.white.opacity(night ? 0.16 : 0.24)
            for streak in SkyWeatherField.rain(amount: amount, size: size, time: time) {
                var path = Path()
                path.move(to: CGPoint(x: streak.x, y: streak.y))
                path.addLine(to: CGPoint(x: streak.x - streak.length * 0.25, y: streak.y + streak.length))
                context.stroke(path, with: .color(ink), lineWidth: 1)
            }
        case .snow(let amount):
            let ink = Color.white.opacity(night ? 0.45 : 0.6)
            for flake in SkyWeatherField.snow(amount: amount, size: size, time: time) {
                let r = flake.radius
                context.fill(Path(ellipseIn: CGRect(x: flake.x - r, y: flake.y - r, width: 2 * r, height: 2 * r)),
                             with: .color(ink))
            }
        }
    }
}

// MARK: - Trying a condition on

/// A condition the weather sheet can try on the sky (Abu, 2026-10-19: "allow me to preview somehow all
/// the other conditions"): WeatherKit's raw value, the sentence and symbol Apple Weather gives it, and
/// the cloud cover that goes with it. The sky paints from `SkyWeatherLook(condition:cloudCover:)`, so
/// this list names every look that initializer can produce, once each; conditions that paint the same
/// sky (windy, hot and frigid are all a clear one) are left out.
struct SkyWeatherCondition: Identifiable, Equatable {
    let condition: String
    let text: String
    let symbolName: String
    let cloudCover: Double

    var id: String { condition }

    static let all: [SkyWeatherCondition] = [
        .init(condition: "clear", text: "Clear", symbolName: "sun.max.fill", cloudCover: 0.03),
        .init(condition: "mostlyClear", text: "Mostly Clear", symbolName: "sun.min.fill", cloudCover: 0.2),
        .init(condition: "partlyCloudy", text: "Partly Cloudy", symbolName: "cloud.sun.fill", cloudCover: 0.45),
        .init(condition: "mostlyCloudy", text: "Mostly Cloudy", symbolName: "cloud.fill", cloudCover: 0.75),
        .init(condition: "cloudy", text: "Cloudy", symbolName: "cloud.fill", cloudCover: 0.98),
        .init(condition: "drizzle", text: "Drizzle", symbolName: "cloud.drizzle.fill", cloudCover: 0.85),
        .init(condition: "rain", text: "Rain", symbolName: "cloud.rain.fill", cloudCover: 0.95),
        .init(condition: "heavyRain", text: "Heavy Rain", symbolName: "cloud.heavyrain.fill", cloudCover: 1.0),
        .init(condition: "isolatedThunderstorms", text: "Isolated Thunderstorms", symbolName: "cloud.bolt.fill", cloudCover: 0.7),
        .init(condition: "thunderstorms", text: "Thunderstorms", symbolName: "cloud.bolt.rain.fill", cloudCover: 1.0),
        .init(condition: "flurries", text: "Flurries", symbolName: "cloud.snow.fill", cloudCover: 0.8),
        .init(condition: "snow", text: "Snow", symbolName: "cloud.snow.fill", cloudCover: 0.95),
        .init(condition: "heavySnow", text: "Heavy Snow", symbolName: "snowflake", cloudCover: 1.0),
        .init(condition: "sleet", text: "Sleet", symbolName: "cloud.sleet.fill", cloudCover: 0.95),
        .init(condition: "hail", text: "Hail", symbolName: "cloud.hail.fill", cloudCover: 0.95),
        .init(condition: "foggy", text: "Fog", symbolName: "cloud.fog.fill", cloudCover: 0.6),
        .init(condition: "haze", text: "Haze", symbolName: "sun.haze.fill", cloudCover: 0.3),
        .init(condition: "smoky", text: "Smoky", symbolName: "smoke.fill", cloudCover: 0.4),
        .init(condition: "blowingDust", text: "Blowing Dust", symbolName: "sun.dust.fill", cloudCover: 0.3),
    ]

    static func named(_ condition: String) -> SkyWeatherCondition? {
        all.first { $0.condition == condition }
    }

    /// Whether `precipitation` falls in this condition, for the sample numbers.
    var isWet: Bool {
        let look = SkyWeatherLook(condition: condition, cloudCover: cloudCover)
        return look.precipitation != .none
    }
}

extension SkyWeather {
    /// This reading wearing `condition`: the numbers stay (the temperature is still today's), only the
    /// sky changes. What the sheet's preview paints, so the chip and the card say "Rain" over the real
    /// degrees rather than inventing a day.
    func wearing(_ condition: SkyWeatherCondition) -> SkyWeather {
        var out = self
        out.condition = condition.condition
        out.conditionText = condition.text
        out.symbolName = condition.symbolName
        out.cloudCover = condition.cloudCover
        if condition.isWet {
            out.precipitationChance = max(out.precipitationChance ?? 0, 0.8)
            if out.precipitationMm < 0.5 { out.precipitationMm = condition.condition.contains("heavy") ? 5 : 2.4 }
        } else {
            out.precipitationChance = out.precipitationChance.map { min($0, 0.05) }
            out.precipitationMm = 0
        }
        return out
    }

    /// A made-up reading in `condition` for a place, when there is no real one to dress: the sheet's
    /// preview before the first fetch, the DEBUG `-fakeWeather` seed and the `-weatherGallery` sheet.
    static func sample(_ condition: SkyWeatherCondition, celsius: Double? = nil, latitude: Double, longitude: Double,
                       now: Date = Date()) -> SkyWeather {
        let wet = condition.isWet
        let foggy = condition.condition == "foggy"
        let temp = celsius ?? (condition.condition.contains("snow") || condition.condition == "flurries" || condition.condition == "sleet" ? -2
                               : wet ? 13 : condition.cloudCover > 0.7 ? 16 : 23)
        let humidity = foggy ? 0.97 : wet ? 0.88 : 0.35 + 0.35 * condition.cloudCover
        let uv = wet || foggy ? 1 : max(1, Int((7 * (1 - condition.cloudCover)).rounded()))
        return SkyWeather(
            fetchedAt: now, latitude: latitude, longitude: longitude,
            temperatureC: temp, apparentC: temp + (humidity > 0.7 ? 1.5 : -1), highC: temp + 4, lowC: temp - 7,
            humidity: humidity, dewPointC: temp - 8, uvIndex: uv,
            uvCategory: uv >= 8 ? "Very High" : uv >= 6 ? "High" : uv >= 3 ? "Moderate" : "Low",
            cloudCover: condition.cloudCover, condition: condition.condition, conditionText: condition.text,
            symbolName: condition.symbolName,
            windKph: 14, windDirection: "NW", visibilityKm: foggy ? 0.8 : 16,
            pressureHPa: 1013, pressureTrend: "Steady",
            precipitationChance: wet ? 0.8 : 0.05,
            precipitationMm: wet ? (condition.condition.contains("heavy") || condition.condition == "thunderstorms" ? 5 : 2.4) : 0,
            isDaylight: true
        )
    }
}

#if DEBUG
extension SkyWeather {
    /// `-fakeWeather <preset>[,<celsius>]`: a reading for screenshots, since the simulator's Apple
    /// Weather needs the App ID's capability to answer. Presets: clear, partly, cloudy, overcast,
    /// rain, storm, snow, fog, hot (and any `SkyWeatherCondition` raw value).
    static func fake(preset: String, celsius: Double?, latitude: Double, longitude: Double, now: Date = Date()) -> SkyWeather? {
        let condition: SkyWeatherCondition?
        var temperature = celsius
        switch preset {
        case "partly":   condition = .named("partlyCloudy")
        case "cloudy":   condition = .named("mostlyCloudy")
        case "overcast": condition = .named("cloudy")
        case "storm":    condition = .named("thunderstorms")
        case "fog":      condition = .named("foggy")
        case "hot":
            condition = SkyWeatherCondition(condition: "hot", text: "Hot", symbolName: "thermometer.sun.fill", cloudCover: 0.02)
            temperature = temperature ?? 41
        default:         condition = .named(preset)
        }
        guard let condition else { return nil }
        return sample(condition, celsius: temperature, latitude: latitude, longitude: longitude, now: now)
    }
}
#endif
