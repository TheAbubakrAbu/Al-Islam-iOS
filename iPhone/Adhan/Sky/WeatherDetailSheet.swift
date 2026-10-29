// The weather up close: everything the reading holds (Abu, 2026-10-11: "temp and uv and humidity and
// all that stuff"), opened from the sky card's weather chip and the glance wall's weather tiles.
// Apple Weather's attribution lives here, as its terms ask: the mark, and a link to the legal page.
//
// Opens at the medium detent since 2026-10-19 (Abu: "make the sheet medium by the way"), with the sky
// card still in view above it: the TRY ANOTHER SKY row under the reading dresses that very sky in any
// condition Apple Weather can report ("allow me to preview somehow all the other conditions"). The
// preview lives in `SkyWeatherStore.preview` so the card, the whole-tab sky and the glance tiles all
// follow, and it is cleared when the sheet goes.
#if os(iOS) && canImport(WeatherKit) && HAS_WEATHER
import SwiftUI

struct WeatherDetailSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var store = SkyWeatherStore.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    if let weather = store.weather {
                        Section {
                            header(weather)
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }

                        Section {
                            conditionPicker(weather)
                                .listRowInsets(EdgeInsets())
                        } header: {
                            Text("TRY ANOTHER SKY")
                        } footer: {
                            Text("The sky behind this sheet takes the look while you choose. The reading above stays as it is.")
                        }

                        Section(header: Text("CONDITIONS")) {
                            row(String(localized: "UV Index"), systemImage: "sun.max.trianglebadge.exclamationmark",
                                value: weather.uvIndex.formatted(), detail: weather.uvCategory)
                            row(String(localized: "Humidity"), systemImage: "humidity.fill", value: weather.humidityText,
                                detail: String(localized: "Dew point \(weather.dewPointText)"))
                            row(String(localized: "Wind"), systemImage: "wind", value: weather.windText)
                            row(String(localized: "Cloud Cover"), systemImage: "cloud.fill", value: weather.cloudCoverText)
                            row(String(localized: "Precipitation"), systemImage: "drop.fill",
                                value: weather.precipitationChanceText ?? weather.precipitationText,
                                detail: precipitationDetail(weather))
                            row(String(localized: "Visibility"), systemImage: "eye.fill", value: weather.visibilityText)
                            row(String(localized: "Pressure"), systemImage: "gauge.with.dots.needle.33percent", value: weather.pressureText,
                                detail: weather.pressureTrend)
                        }

                        if let sunrise = prayerTime("Shurooq"), let sunset = prayerTime("Maghrib") {
                            Section(header: Text("SUN")) {
                                row(String(localized: "Sunrise"), systemImage: "sunrise.fill", value: settings.formatDate(sunrise))
                                row(String(localized: "Sunset"), systemImage: "sunset.fill", value: settings.formatDate(sunset))
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
                                Text((store.lastError.map { String(localized: "Apple Weather did not answer: \($0)") }
                                     ?? String(localized: "The sky asks Apple Weather for your location the next time the Adhan tab is in front.")).localizedDigits)
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
        .smallMediumSheetPresentation()
        .onAppear { store.refreshIfNeeded() }
        .onDisappear {
            if store.preview != nil { store.preview = nil }
        }
    }

    /// The big reading: the symbol, the temperature, the condition, and feels-like with the day's range.
    /// While a condition is being tried on, the symbol and the sentence are its, tagged Preview; the
    /// degrees are always today's.
    private func header(_ weather: SkyWeather) -> some View {
        let preview = store.preview
        return HStack(alignment: .center, spacing: 16) {
            Image(systemName: preview?.symbolName ?? weather.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 52, weight: .medium))
                .frame(width: 64)
                .accessibilityHidden(true)
                .animation(.easeInOut(duration: 0.2), value: preview)

            VStack(alignment: .leading, spacing: 3) {
                Text(weather.temperatureText)
                    .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(.primary)
                HStack(spacing: 8) {
                    Text(preview?.text ?? weather.conditionText)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if preview != nil {
                        Text("Preview")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(settings.accentColor.color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(settings.accentColor.color.opacity(0.14)))
                    }
                }
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

    /// Today's sky first, then every condition the sky can wear, as chips in one scrolling row. Tapping
    /// one dresses the sky behind the sheet in it (`SkyWeatherStore.preview`); Now puts it back.
    private func conditionPicker(_ weather: SkyWeather) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    conditionChip(title: String(localized: "Now"), systemImage: weather.symbolName, selected: store.preview == nil, id: "now") {
                        store.preview = nil
                    }
                    ForEach(SkyWeatherCondition.all) { condition in
                        conditionChip(title: condition.text, systemImage: condition.symbolName,
                                      selected: store.preview == condition, id: condition.id) {
                            store.preview = condition
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onChange(of: store.preview) { preview in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(preview?.id ?? "now", anchor: .center)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Try another sky")
    }

    private func conditionChip(title: String, systemImage: String, selected: Bool, id: String,
                               action: @escaping () -> Void) -> some View {
        let accent = settings.accentColor.color
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.25)) { action() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .symbolRenderingMode(selected ? .monochrome : .hierarchical)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .foregroundColor(selected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? accent : Color.primary.opacity(0.07))
            )
            .overlay(
                Capsule().strokeBorder(selected ? accent : Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .id(id)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
        return weather.precipitationMm > 0.05 ? String(localized: "\(weather.precipitationText) this hour") : String(localized: "None expected this hour")
    }

    private func prayerTime(_ name: String) -> Date? {
        settings.getPrayerTimes(for: Date(), fullPrayers: true)?
            .first { $0.nameTransliteration == name }?.time
    }
}
#endif
