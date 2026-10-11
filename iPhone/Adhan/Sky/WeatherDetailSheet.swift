// The weather up close: everything the reading holds (Abu, 2026-10-11: "temp and uv and humidity and
// all that stuff"), opened from the sky card's weather chip and the glance wall's weather tiles.
// Apple Weather's attribution lives here, as its terms ask: the mark, and a link to the legal page.
#if os(iOS) && canImport(WeatherKit) && HAS_WEATHER
import SwiftUI

struct WeatherDetailSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = SkyWeatherStore.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationView {
            List {
                Group {
                    if let weather = store.weather {
                        Section {
                            header(weather)
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }

                        Section(header: Text("CONDITIONS")) {
                            row("UV Index", systemImage: "sun.max.trianglebadge.exclamationmark",
                                value: "\(weather.uvIndex)", detail: weather.uvCategory)
                            row("Humidity", systemImage: "humidity.fill", value: weather.humidityText,
                                detail: "Dew point \(weather.dewPointText)")
                            row("Wind", systemImage: "wind", value: weather.windText)
                            row("Cloud Cover", systemImage: "cloud.fill", value: weather.cloudCoverText)
                            row("Precipitation", systemImage: "drop.fill",
                                value: weather.precipitationChanceText ?? weather.precipitationText,
                                detail: precipitationDetail(weather))
                            row("Visibility", systemImage: "eye.fill", value: weather.visibilityText)
                            row("Pressure", systemImage: "gauge.with.dots.needle.33percent", value: weather.pressureText,
                                detail: weather.pressureTrend)
                        }

                        if let sunrise = prayerTime("Shurooq"), let sunset = prayerTime("Maghrib") {
                            Section(header: Text("SUN")) {
                                row("Sunrise", systemImage: "sunrise.fill", value: settings.formatDate(sunrise))
                                row("Sunset", systemImage: "sunset.fill", value: settings.formatDate(sunset))
                            }
                        }

                        Section {
                            Button {
                                settings.hapticFeedback()
                                store.refreshIfNeeded(force: true)
                            } label: {
                                HStack(spacing: 10) {
                                    if store.isFetching {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(settings.accentColor.color)
                                    }
                                    Text(store.isFetching ? "Checking the sky..." : "Refresh")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if let updated = store.updatedText {
                                        Text(updated)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .disabled(store.isFetching)
                            if !weather.isFresh() {
                                Text("This reading is more than three hours old, so the sky is painted without it until a new one arrives.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } footer: {
                            attribution
                        }
                    } else {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(store.isFetching ? "Checking the sky..." : "No weather yet")
                                    .font(.headline)
                                Text(store.lastError.map { "Apple Weather did not answer: \($0)" }
                                     ?? "The sky asks Apple Weather for your location the next time the Adhan tab is in front.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button {
                                    settings.hapticFeedback()
                                    store.refreshIfNeeded(force: true)
                                } label: {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .disabled(store.isFetching)
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)
                        } footer: {
                            attribution
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation(startLarge: true)
        .onAppear { store.refreshIfNeeded() }
    }

    /// The big reading: the symbol, the temperature, the condition, and feels-like with the day's range.
    private func header(_ weather: SkyWeather) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: weather.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 52, weight: .medium))
                .frame(width: 64)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(weather.temperatureText)
                    .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(.primary)
                Text(weather.conditionText)
                    .font(.headline)
                    .foregroundColor(.primary)
                HStack(spacing: 10) {
                    Text("Feels like \(weather.apparentText)")
                    if let high = weather.highText, let low = weather.lowText {
                        Text("H:\(high) L:\(low)")
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func row(_ title: String, systemImage: String, value: String, detail: String? = nil) -> some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: SettingsTint.sky, size: 26)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundColor(.primary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }

    /// Apple's mark and legal link, as the WeatherKit terms require.
    private var attribution: some View {
        HStack(spacing: 4) {
            Image(systemName: "apple.logo")
                .accessibilityHidden(true)
            Text("Weather")
            Text("·")
            Button("Legal") { openURL(store.legalURL) }
                .buttonStyle(.plain)
                .foregroundColor(settings.accentColor.color)
        }
        .font(.caption)
        .padding(.top, 2)
        .accessibilityLabel("Weather data by Apple Weather. Legal attribution.")
    }

    /// Under the chance: how much is expected this hour, or that nothing is ("0 in this hour" read
    /// as a typo). Nothing when the chance itself is missing and the amount is the value.
    private func precipitationDetail(_ weather: SkyWeather) -> String? {
        guard weather.precipitationChanceText != nil else { return nil }
        return weather.precipitationMm > 0.05 ? "\(weather.precipitationText) this hour" : "None expected this hour"
    }

    private func prayerTime(_ name: String) -> Date? {
        settings.getPrayerTimes(for: Date(), fullPrayers: true)?
            .first { $0.nameTransliteration == name }?.time
    }
}
#endif
