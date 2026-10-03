#if os(iOS)
import SwiftUI
import CoreLocation

/// The loud card at the TOP of the Adhan tab while traveling mode is on (Abu, 2026-10-01: "so many
/// people tell me ... make it big and loud"). Readers saw four combined prayers, missed the caption
/// under the list, and took Qasr for a bug. This card names the mode, says why the times are combined,
/// how far from home you are, and carries the two ways out (full prayers, Travel Settings).
///
/// The fill is the accent pushed dark enough that WHITE text reads at 4.5:1 on it in both appearances
/// (`AccentContrast.legible` against white), so every accent, the custom one included, gets the same
/// solid, saturated card instead of a tint that disappears into the list.
struct TravelingModeBanner: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var live = LiveState.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Opens Adhan settings on the Traveling Mode screen (the tab's own settings sheet).
    let openTravelSettings: () -> Void

    var body: some View {
        let fill = Self.fill(for: settings.accentColor.color, dark: colorScheme == .dark)

        VStack(alignment: .leading, spacing: 14) {
            header
            qasrPairs(fill: fill)
            actions(fill: fill)
        }
        .foregroundColor(.white)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background(fill: fill))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .softShadow(color: fill.opacity(0.45), radius: 12, x: 0, y: 4)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "airplane")
                .font(.system(size: 24, weight: .bold))
                .rotationEffect(.degrees(-30))
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.white.opacity(0.22)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("TRAVELING MODE IS ON")
                    .font(.caption.weight(.heavy))
                    .tracking(1.2)
                    .opacity(0.9)

                Text(fullPrayers ? "Showing Full Prayers" : "Praying Qasr")
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(distanceLine)
                    .font(.subheadline.weight(.medium))
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)
        }
    }

    /// The two combined pairs with their shortened rakah counts: the thing that changed, said plainly.
    @ViewBuilder
    private func qasrPairs(fill: Color) -> some View {
        let pairs = [
            QasrPair(names: "Dhuhr + Asr", rakahs: "2 + 2 rakahs", icon: "sun.max.fill"),
            QasrPair(names: "Maghrib + Isha", rakahs: "3 + 2 rakahs", icon: "moon.stars.fill"),
        ]
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayoutBox.vertical
            : AnyLayoutBox.horizontal

        VStack(alignment: .leading, spacing: 8) {
            Text(fullPrayers
                 ? "The full times are listed below. While traveling you may still shorten and combine:"
                 : "The prayers below are shortened and combined for travel (more than 48 mi from home):")
                .font(.footnote)
                .opacity(0.92)
                .fixedSize(horizontal: false, vertical: true)

            layout.stack(spacing: 8) {
                ForEach(pairs) { pair in
                    HStack(spacing: 8) {
                        Image(systemName: pair.icon)
                            .font(.footnote.weight(.semibold))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(pair.names)
                                .font(.subheadline.weight(.bold))
                            Text(pair.rakahs)
                                .font(.caption.weight(.medium))
                                .opacity(0.85)
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.16))
                    )
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private func actions(fill: Color) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayoutBox.vertical
            : AnyLayoutBox.horizontal

        layout.stack(spacing: 10) {
            Button {
                settings.hapticFeedback()
                withAnimation { settings.travelingShowFullPrayers.toggle() }
            } label: {
                bannerButtonLabel(fullPrayers ? "View Qasr Prayers" : "View Full Prayers",
                                  icon: fullPrayers ? "rectangle.compress.vertical" : "rectangle.expand.vertical",
                                  filled: false, fill: fill)
            }
            .buttonStyle(.plain)

            Button {
                settings.hapticFeedback()
                openTravelSettings()
            } label: {
                bannerButtonLabel("Travel Settings", icon: "gearshape.fill", filled: true, fill: fill)
            }
            .buttonStyle(.plain)
        }
    }

    /// White capsule with accent ink (the primary action), or a translucent one with white ink.
    private func bannerButtonLabel(_ title: String, icon: String, filled: Bool, fill: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(filled ? fill : .white)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            Capsule(style: .continuous)
                .fill(filled ? Color.white : Color.white.opacity(0.2))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(filled ? 0 : 0.4), lineWidth: 1)
        )
        .contentShape(Capsule())
    }

    private func background(fill: Color) -> some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [fill, Self.deeper(fill)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // A big faint plane in the corner: the card reads as "travel" from across the room.
            Image(systemName: "airplane")
                .font(.system(size: 130, weight: .bold))
                .rotationEffect(.degrees(-30))
                .foregroundColor(.white.opacity(0.09))
                .offset(x: 34, y: -26)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Values

    private var fullPrayers: Bool { settings.travelingShowFullPrayers }

    /// "412 mi from home (Los Angeles)", or the reason without a number when one side is unknown.
    private var distanceLine: String {
        let homeCity = settings.homeLocation?.city.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let home = settings.homeLocation,
              let here = live.currentLocation,
              here.latitude != 1000, here.longitude != 1000
        else {
            return homeCity.isEmpty ? "Away from home" : "Away from \(homeCity)"
        }
        let meters = CLLocation(latitude: here.latitude, longitude: here.longitude)
            .distance(from: CLLocation(latitude: home.latitude, longitude: home.longitude))
        // Inside the home city the distance is GPS noise ("0.0 mi"): traveling mode was set by hand.
        guard meters > 1_000 else {
            return homeCity.isEmpty ? "At home, turned on by hand" : "In \(homeCity), turned on by hand"
        }
        let distance = Self.distanceText(meters)
        return homeCity.isEmpty ? "\(distance) from home" : "\(distance) from \(homeCity)"
    }

    private static let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static func distanceText(_ meters: CLLocationDistance) -> String {
        let miles = meters / 1609.34
        let kilometers = meters / 1000
        guard miles >= 10 else { return String(format: "%.1f mi (%.1f km)", miles, kilometers) }
        let mi = distanceFormatter.string(from: NSNumber(value: miles)) ?? "\(Int(miles))"
        let km = distanceFormatter.string(from: NSNumber(value: kilometers)) ?? "\(Int(kilometers))"
        return "\(mi) mi (\(km) km)"
    }

    // MARK: - Color

    /// The accent as it resolves here, darkened only as far as white text needs to read at 4.5:1.
    static func fill(for accent: Color, dark: Bool) -> Color {
        let shade = AccentContrast.resolved(UIColor(accent), dark: dark)
        let white = AccentContrast.RGB(r: 1, g: 1, b: 1)
        let ink = AccentContrast.legible(shade, against: white, target: AccentContrast.textRatio)
        return Color(AccentContrast.uiColor(ink))
    }

    /// The gradient's far stop: the fill a fifth darker, so the card has depth without a second hue.
    private static func deeper(_ fill: Color) -> Color {
        let c = AccentContrast.rgb(UIColor(fill))
        return Color(AccentContrast.uiColor(.init(r: c.r * 0.78, g: c.g * 0.78, b: c.b * 0.78)))
    }

    private struct QasrPair: Identifiable {
        let names: String
        let rakahs: String
        let icon: String
        var id: String { names }
    }
}

/// HStack or VStack chosen at runtime without `AnyLayout` (iOS 16+; the app still runs on 15).
private enum AnyLayoutBox {
    case horizontal, vertical

    @ViewBuilder
    func stack<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        switch self {
        case .horizontal: HStack(spacing: spacing) { content() }
        case .vertical: VStack(alignment: .leading, spacing: spacing) { content() }
        }
    }
}

/// The badge the PRAYER TIMES header wears while traveling, so the combined list labels itself.
struct QasrHeaderBadge: View {
    @ObservedObject private var settings = Settings.shared
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
