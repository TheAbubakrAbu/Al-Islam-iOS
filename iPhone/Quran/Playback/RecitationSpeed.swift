import SwiftUI
import AVFoundation

// Recitation speed (a reader's request, Ahmad Omaid Alham Osmani, 2026-11-19: "make the recitation
// slower or faster for example 0.5x, 0.75x, 1.0x, 1.5x, 1.75x, 2.0x").
//
// - ONE remembered speed, `Settings.recitationSpeed`, for everything `QuranPlayer` recites: a surah,
//   an ayah, a range, a repeat. Play Word by Word, the qiraat variant clips, the adhan and the duas
//   have players of their own and stay as recorded.
// - The player takes it in three places (QuranPlayer.swift): `player.didSet` hands every new player
//   the speed as its `defaultRate`, which is what `play()` starts at; the starts that skip the
//   buffering wait pass it to `playImmediately(atRate:)`; and `setRecitationSpeed` changes a
//   recitation that is already running. At 1× all three do what they did before the speed existed.
// - The voice keeps its pitch (`RecitationSpeed.keepPitch`): faster or slower, never higher or lower.
// - Where it is set: the Speed submenu in the Now Playing bar's hold menu, and the chip beside the
//   reciter on the big player. The small player only SHOWS a speed that is not 1×.
// - The watch recites at 1×: its card has no control to show or change the speed with.
// No em dashes and no spaced hyphens in any of this text (house rule).

/// The speeds the recitation can play at.
enum RecitationSpeed {
    /// Slowest first, as the menu lists them: the reader's six and 1.25×.
    static let all: [Double] = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

    /// As recorded.
    static let normal: Double = 1

    /// The offered speed nearest a stored value. Everything that reads the setting comes through
    /// here, so a value from a later build with other speeds, or one that is no speed at all (a
    /// rate of 0 is a pause), never reaches the player.
    static func nearest(to value: Double) -> Double {
        guard value.isFinite, value > 0 else { return normal }
        return all.min { abs($0 - value) < abs($1 - value) } ?? normal
    }

    /// "1×", "1.25×", "0.5×": no trailing zeros, and the multiplication sign.
    static func label(_ speed: Double) -> String {
        String(format: "%g", speed) + "\u{00D7}"
    }

    /// Faster or slower without the voice rising or falling: the time-domain algorithm is the one
    /// AVFoundation makes for speech, and at 1× it leaves the audio untouched.
    static func keepPitch(of item: AVPlayerItem) {
        item.audioTimePitchAlgorithm = .timeDomain
    }
}

#if os(iOS)
/// The speeds as menu rows, the current one ticked: the content of a `Menu`, which the Now
/// Playing bar's hold menu shows as its Speed submenu and the big player's chip opens directly.
///
/// Always an INLINE picker inside a Menu. A menu-style picker placed straight into a `.contextMenu`
/// draws its own submenu, but lists every speed disabled: greyed, and a tap does nothing (measured
/// on the iOS 27 simulator, 2026-11-19, with the same picker working from the chip's Menu).
struct RecitationSpeedPicker: View {
    private let settings = Settings.shared
    /// The slice that publishes `recitationSpeed`, so an open menu's tick follows the choice.
    @ObservedObject private var quranContent = QuranContent.shared

    var body: some View {
        // A plain binding: an animated Picker selection slides, snaps back and slides again.
        Picker("Recitation Speed", selection: Binding(
            get: { RecitationSpeed.nearest(to: settings.recitationSpeed) },
            set: { speed in
                settings.hapticFeedback()
                QuranPlayer.shared.setRecitationSpeed(speed)
            }
        )) {
            ForEach(RecitationSpeed.all, id: \.self) { speed in
                Text(RecitationSpeed.label(speed).localizedDigits).tag(speed)
            }
        }
        .pickerStyle(.inline)
        .labelsHidden()
    }
}

/// The speed as a small capsule: "1×" in grey at normal speed, the accent at any other, so a
/// recitation that is not as recorded says so at a glance. The capsule is drawn outside the text's
/// own height: the reciter line it sits on, and so the card, stay exactly as tall as they were.
struct RecitationSpeedChip: View {
    let speed: Double
    let accent: Color

    var body: some View {
        let tint = speed == RecitationSpeed.normal ? Color.secondary : accent
        Text(RecitationSpeed.label(speed).localizedDigits)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundColor(tint)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 6)
            .background(Capsule().fill(tint.opacity(0.16)).padding(.vertical, -2))
    }
}

/// Where the big player's speed chip sits, for the menu laid over it (`NowPlayingView`).
struct RecitationSpeedChipBounds: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
#endif
