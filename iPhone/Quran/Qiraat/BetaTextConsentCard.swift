#if os(iOS)
import SwiftUI

// MARK: - The beta-text consent

/// Shown IN PLACE of a beta riwayah's text the first time text would render (the
/// list reader; the Page Text menu routes here too). Selecting a beta riwayah is
/// never blocked - its printed mushaf is exact and loads without any of this -
/// so the consent lives exactly where the beta thing (the TEXT) would appear,
/// with both ways out on the same screen. No dialog, no settings scavenger hunt.
///
/// In a file of its own since 2026-11-18, out of BetaQiraat.swift: the Widget and the Complication
/// compile that file for `BetaQiraatStore`, and this card's buttons wear the app's glass button
/// style (`GlassActionButtonStyle`), which those targets do not have.
struct BetaTextConsentCard: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Riwayah shown in the title, e.g. "Ruways an Yaqub".
    let riwayahLabel: String
    /// Switch this reader to the printed mushaf (page mode + facsimile).
    let onReadPrint: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "book.pages")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(settings.accentColor.color)
                    .padding(.top, 28)

                VStack(spacing: 6) {
                    Text(riwayahLabel)
                        .font(.title3.weight(.semibold))
                    Text("Printed mushaf, or beta text?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("The printed mushaf of this riwayah is exact: the scanned pages of its published print. Its SELECTABLE TEXT is a beta transcription:\n\n\(Settings.betaQiraatNotice)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 6)

                VStack(spacing: 10) {
                    Button {
                        settings.hapticFeedback()
                        onReadPrint()
                    } label: {
                        Label("Read the Printed Mushaf", systemImage: "doc.richtext")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glassAction)

                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) {
                            settings.betaQiraatEnabled = true
                            settings.acceptedBetaQiraatNotice = true
                        }
                    } label: {
                        Label("Use the Beta Text", systemImage: "flask")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glassAction(tinted: false))
                }

                Text("Change anytime: Quran Settings → Beta Text, or the reader's Page Text menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}
#endif
