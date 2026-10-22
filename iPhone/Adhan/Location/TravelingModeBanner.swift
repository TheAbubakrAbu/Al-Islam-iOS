#if os(iOS)
import SwiftUI
import CoreLocation

/// The traveling-mode row on the Adhan tab: one compact card under the countdown, above the list it
/// explains (Abu, 2026-10-19: "make praying qasr section smaller and simpler and maybe put it before
/// or after prayer countdown"). It names the mode, says in one line what Qasr changed and how far
/// from home you are, and opens Travel Settings. "View Full Prayers" lives in the footer under the
/// list, as before.
///
/// It replaces the loud card that led the whole tab from 2026-10-01 (readers had taken the four
/// combined prayers for a bug). The fill is the same: the accent pushed dark enough that WHITE text
/// reads at 4.5:1 on it in both appearances (`AccentContrast.legible` against white), so every
/// accent, the custom one included, gets a solid card instead of a tint that disappears into the list.
struct TravelingModeBanner: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var live = LiveState.shared
    @Environment(\.colorScheme) private var colorScheme

    /// Opens Adhan settings on the Traveling Mode screen (the tab's own settings sheet).
    let openTravelSettings: () -> Void

    var body: some View {
        let fill = Self.fill(for: settings.accentColor.color, dark: colorScheme == .dark)
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        Button {
            settings.hapticFeedback()
            openTravelSettings()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .bold))
                    .rotationEffect(.degrees(-30))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.22)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(fullPrayers ? "Traveling Mode · Full Prayers" : "Traveling Mode · Praying Qasr")
                        .font(.subheadline.weight(.bold))
                    Text(detailLine)
                        .font(.caption)
                        .opacity(0.9)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.8)
                    .accessibilityHidden(true)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(fill))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Travel Settings")
    }

    // MARK: - Values

    private var fullPrayers: Bool { settings.travelingShowFullPrayers }

    /// "Dhuhr + Asr and Maghrib + Isha, shortened and combined · 412 mi from Los Angeles"
    private var detailLine: String {
        let what = fullPrayers
            ? "Full times shown; you may still shorten and combine"
            : "Dhuhr + Asr and Maghrib + Isha, shortened and combined"
        return "\(what) · \(distanceLine)"
    }

    /// "412 mi from Los Angeles", or the reason without a number when one side is unknown.
    private var distanceLine: String {
        let homeCity = settings.homeLocation?.city.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let home = settings.homeLocation,
              let here = live.currentLocation,
              here.latitude != 1000, here.longitude != 1000
        else {
            return homeCity.isEmpty ? "away from home" : "away from \(homeCity)"
        }
        let meters = CLLocation(latitude: here.latitude, longitude: here.longitude)
            .distance(from: CLLocation(latitude: home.latitude, longitude: home.longitude))
        // Inside the home city the distance is GPS noise ("0.0 mi"): traveling mode was set by hand.
        guard meters > 1_000 else {
            return homeCity.isEmpty ? "at home, turned on by hand" : "in \(homeCity), turned on by hand"
        }
        let distance = Self.distanceText(meters)
        return homeCity.isEmpty ? "\(distance) from home" : "\(distance) from \(homeCity)"
    }

    /// Miles or kilometres as the locale measures ("412 mi" in the US, "663 km" elsewhere): one unit,
    /// since the row has one line for it.
    private static let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        // Medium, not short: short prints "2,451mi" with no space before the unit.
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    private static func distanceText(_ meters: CLLocationDistance) -> String {
        distanceFormatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }

    // MARK: - Color

    /// The accent as it resolves here, darkened only as far as white text needs to read at 4.5:1.
    static func fill(for accent: Color, dark: Bool) -> Color {
        let shade = AccentContrast.resolved(UIColor(accent), dark: dark)
        let white = AccentContrast.RGB(r: 1, g: 1, b: 1)
        let ink = AccentContrast.legible(shade, against: white, target: AccentContrast.textRatio)
        return Color(AccentContrast.uiColor(ink))
    }
}

/// The badge the PRAYER TIMES header wears while traveling, so the combined list labels itself.
struct QasrHeaderBadge: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let fill = TravelingModeBanner.fill(for: settings.accentColor.color, dark: colorScheme == .dark)
        HStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.caption2.weight(.bold))
                .accessibilityHidden(true)
            Text(settings.travelingShowFullPrayers ? "TRAVELING" : "QASR")
                .font(.caption2.weight(.heavy))
                .tracking(0.6)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(fill))
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(settings.travelingShowFullPrayers ? "Traveling mode on" : "Traveling mode on, Qasr prayers")
    }
}
#endif
