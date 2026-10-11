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
        Measurement(value: pressureHPa, unit: UnitPressure.hectopascals)
            .formatted(.measurement(width: .abbreviated, usage: .barometric,
                                    numberFormatStyle: .number.precision(.fractionLength(0))))
    }
    /// "30%" or nil when the hourly forecast was not available.
    var precipitationChanceText: String? {
        precipitationChance.map { "\(Int(($0 * 100).rounded()))%" }
    }
    /// "0.2 mm" (inches where the region uses them).
    var precipitationText: String {
        Measurement(value: precipitationMm, unit: UnitLength.millimeters)
            .formatted(.measurement(width: .abbreviated, usage: .rainfall,
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
    static let maxOvercastMix = 0.72
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

// MARK: - The overlay

/// One still frame of the weather over a sky: cloud puffs across the upper sky, rain streaks or snow
/// across all of it, a fog veil low down. Deterministic like `SkyStars` (the same seed on the card,
/// the page and a widget), with `time` picking the frame so two moments differ a little. Drawn in a
/// Canvas: cheap enough for the minute tick, and a widget can draw it too.
struct SkyWeatherOverlay: View {
    let look: SkyWeatherLook
    /// True over a night gradient: the clouds go grey instead of white.
    let night: Bool
    /// Seconds; shifts the rain and snow between frames.
    var time: TimeInterval = 0

    var body: some View {
        Canvas { context, size in
            Self.draw(in: &context, size: size, look: look, night: night, time: time)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The same frame, for a widget's `Canvas`.
    static func draw(in context: inout GraphicsContext, size: CGSize, look: SkyWeatherLook, night: Bool, time: TimeInterval) {
        guard !look.isClear, size.width > 1, size.height > 1 else { return }
        var seed: UInt64 = 0x51CE_C10D
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((seed >> 33) & 0xFFFF) / Double(0xFFFF)
        }

        // Clouds: soft puffs across the upper sky, more and denser with the cover. Each puff is three
        // overlapping ellipses blurred together, so it reads as cloud rather than as three discs.
        if look.cloudCover > 0.12 {
            let count = Int((look.cloudCover * 9).rounded())
            let alpha = night ? 0.05 + 0.10 * look.cloudCover : 0.10 + 0.18 * look.cloudCover
            let fill = night ? Color(white: 0.78) : Color.white
            var clouds = context
            clouds.addFilter(.blur(radius: max(6, size.width * 0.018)))
            for _ in 0..<count {
                let cx = next() * size.width
                let cy = (0.06 + next() * 0.48) * size.height
                let w = (0.22 + next() * 0.26) * size.width
                let h = w * (0.28 + next() * 0.14)
                for (dx, scale) in [(-0.28, 0.72), (0.0, 1.0), (0.3, 0.8)] {
                    let rect = CGRect(x: cx + dx * w - w * scale / 2, y: cy - h * scale / 2,
                                      width: w * scale, height: h * scale)
                    clouds.fill(Path(ellipseIn: rect), with: .color(fill.opacity(alpha)))
                }
            }
        }

        // Fog: a veil that thickens toward the ground, where fog sits.
        if look.fog > 0 {
            let veil = night ? Color(white: 0.6) : Color.white
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(veil.opacity(0.10 * look.fog)))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [veil.opacity(0), veil.opacity(0.32 * look.fog)]),
                startPoint: CGPoint(x: size.width / 2, y: size.height * 0.35),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            ))
        }

        switch look.precipitation {
        case .none:
            break
        case .rain(let amount):
            // Streaks leaning with the wind, denser as it pours; the frame slides them down a little.
            let count = Int(30 + 70 * amount)
            let drop = time.truncatingRemainder(dividingBy: 60) / 60
            let length = max(9, size.height * 0.06)
            let ink = Color.white.opacity(night ? 0.16 : 0.24)
            for _ in 0..<count {
                let x = next() * size.width
                let y = ((next() + drop).truncatingRemainder(dividingBy: 1)) * size.height
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x - length * 0.25, y: y + length))
                context.stroke(path, with: .color(ink), lineWidth: 1)
            }
        case .snow(let amount):
            let count = Int(24 + 56 * amount)
            let drift = time.truncatingRemainder(dividingBy: 120) / 120
            for _ in 0..<count {
                let x = next() * size.width
                let y = ((next() + drift).truncatingRemainder(dividingBy: 1)) * size.height
                let r = 0.9 + next() * 1.4
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)),
                             with: .color(.white.opacity(night ? 0.45 : 0.6)))
            }
        }
    }
}

#if DEBUG
extension SkyWeather {
    /// `-fakeWeather <preset>[,<celsius>]`: a reading for screenshots, since the simulator's Apple
    /// Weather needs the App ID's capability to answer. Presets: clear, partly, cloudy, overcast,
    /// rain, storm, snow, fog, hot.
    static func fake(preset: String, celsius: Double?, latitude: Double, longitude: Double, now: Date = Date()) -> SkyWeather? {
        let base: (condition: String, text: String, symbol: String, cover: Double, temp: Double, uv: Int, humidity: Double)
        switch preset {
        case "clear":    base = ("clear", "Clear", "sun.max.fill", 0.05, 24, 6, 0.35)
        case "partly":   base = ("partlyCloudy", "Partly Cloudy", "cloud.sun.fill", 0.40, 21, 4, 0.45)
        case "cloudy":   base = ("mostlyCloudy", "Mostly Cloudy", "cloud.fill", 0.75, 18, 2, 0.60)
        case "overcast": base = ("cloudy", "Cloudy", "cloud.fill", 0.98, 15, 1, 0.70)
        case "rain":     base = ("rain", "Rain", "cloud.rain.fill", 0.95, 13, 1, 0.88)
        case "storm":    base = ("thunderstorms", "Thunderstorms", "cloud.bolt.rain.fill", 1.0, 19, 1, 0.85)
        case "snow":     base = ("snow", "Snow", "cloud.snow.fill", 0.95, -2, 1, 0.80)
        case "fog":      base = ("foggy", "Foggy", "cloud.fog.fill", 0.6, 9, 1, 0.97)
        case "hot":      base = ("hot", "Hot", "thermometer.sun.fill", 0.02, 41, 11, 0.12)
        default: return nil
        }
        let temp = celsius ?? base.temp
        return SkyWeather(
            fetchedAt: now, latitude: latitude, longitude: longitude,
            temperatureC: temp, apparentC: temp + (base.humidity > 0.7 ? 1.5 : -1), highC: temp + 4, lowC: temp - 7,
            humidity: base.humidity, dewPointC: temp - 8, uvIndex: base.uv,
            uvCategory: base.uv >= 8 ? "Very High" : base.uv >= 6 ? "High" : base.uv >= 3 ? "Moderate" : "Low",
            cloudCover: base.cover, condition: base.condition, conditionText: base.text, symbolName: base.symbol,
            windKph: 14, windDirection: "NW", visibilityKm: base.condition == "foggy" ? 0.8 : 16,
            pressureHPa: 1013, pressureTrend: "Steady",
            precipitationChance: base.condition.contains("rain") || base.condition == "snow" || base.condition == "thunderstorms" ? 0.8 : 0.05,
            precipitationMm: base.condition == "rain" ? 2.4 : base.condition == "thunderstorms" ? 5 : 0,
            isDaylight: true
        )
    }
}
#endif
