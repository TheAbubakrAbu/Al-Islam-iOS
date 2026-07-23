#if os(iOS)
import SwiftUI

/// Two color pickers per prayer for the Adhan tab's sky card, with a live preview above them.
///
/// Only the six real prayers appear. Jumuah, the traveling-mode pairs and the optional night times inherit
/// through `SkyPalette.editableKey`, so there is nothing extra to set or keep in sync.
struct SkyColorsView: View {
    @ObservedObject var settings = Settings.shared

    /// Which prayer the preview is showing. Follows whichever picker was touched last.
    @State private var previewPrayer = "Fajr"

    var body: some View {
        List {
            Section {
                preview
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section(header: Text("SKY COLORS")) {
                ForEach(SkyPalette.editablePrayers, id: \.self) { prayer in
                    row(for: prayer)
                }

                Text("These color the sky at the top of the Adhan tab. Friday's Jumuah, the combined traveling prayers and the optional night times follow the prayer they belong to.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
            .themedListRowBackground()

            if settings.hasCustomSkyGradients {
                Section {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation { settings.resetSkyGradients() }
                    } label: {
                        Text("Restore Default Colors")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .themedListRowBackground()
            }
        }
        .applyConditionalListStyle()
        .navigationTitle("Sky Colors")
    }

    private var preview: some View {
        LinearGradient(
            colors: settings.skyGradientColors(forPrayer: previewPrayer),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .overlay(alignment: .bottomLeading) {
            Text(settings.customPrayerName(for: previewPrayer) ?? previewPrayer)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(10)
        }
        .animation(.easeInOut(duration: 0.25), value: previewPrayer)
        .animation(.easeInOut(duration: 0.25), value: settings.skyGradientsJSON)
    }

    private func row(for prayer: String) -> some View {
        HStack {
            Text(settings.customPrayerName(for: prayer) ?? prayer)
                .font(.subheadline)

            Spacer()

            ColorPicker("", selection: binding(for: prayer, isTop: true), supportsOpacity: false)
                .labelsHidden()
            ColorPicker("", selection: binding(for: prayer, isTop: false), supportsOpacity: false)
                .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { previewPrayer = prayer } }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(prayer) sky colors, top and bottom")
    }

    /// `ColorPicker` needs a `Binding<Color>`, but the palette is stored as a hex pair. Reading rebuilds the
    /// colors from storage; writing rewrites only the half that changed.
    private func binding(for prayer: String, isTop: Bool) -> Binding<Color> {
        Binding(
            get: {
                let hexes = settings.skyGradientHexes(for: prayer)
                return Color(hex: hexes[isTop ? 0 : 1]) ?? .black
            },
            set: { newColor in
                let hexes = settings.skyGradientHexes(for: prayer)
                let top = isTop ? newColor : (Color(hex: hexes[0]) ?? .black)
                let bottom = isTop ? (Color(hex: hexes[1]) ?? .black) : newColor
                settings.setSkyGradient(top: top, bottom: bottom, for: prayer)
                if previewPrayer != prayer {
                    withAnimation { previewPrayer = prayer }
                }
            }
        )
    }
}
#endif
