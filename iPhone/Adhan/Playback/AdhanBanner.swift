import SwiftUI

// The banner that floats over the whole app while the adhan sounds in-app, so the recording can
// always be stopped from wherever you happen to be (Abu, 2026-10-06). The sky card's footer button
// is the other half of this and stays: dismissing the banner must never strand a playing adhan
// with no way to stop it.

#if os(iOS)

/// Raises and retires the adhan banner in step with `ForegroundAdhanPlayer`.
///
/// Driven from `adhanBannerHost()` on the app root rather than from the player itself, so the player
/// stays a pure audio engine with no window machinery in it - the same split the achievement banner
/// uses between its store and its presenter.
@MainActor
final class AdhanBannerPresenter: ObservableObject {
    static let shared = AdhanBannerPresenter()

    /// Set when the user dismisses the banner for the adhan currently playing. The adhan keeps
    /// going; only the card goes away. Cleared when the adhan stops, so the NEXT one banners again.
    @Published private(set) var dismissedPrayer: String?

    private let window = BannerWindow { AdhanBannerHost() }

    private init() {}

    /// Whether the card should be on screen for this player state.
    func shouldShow(playing: String?, dismissed: String?) -> Bool {
        guard let playing else { return false }
        return playing != dismissed
    }

    func sync(playingPrayerName: String?) {
        if let playing = playingPrayerName {
            if shouldShow(playing: playing, dismissed: dismissedPrayer) {
                window.present()
            } else {
                window.dismiss()
            }
        } else {
            // The adhan ended (finished, or stopped from anywhere): forget the dismissal so the next
            // adhan raises its own banner.
            dismissedPrayer = nil
            window.dismiss()
        }
    }

    /// Hides the card without touching the audio.
    func dismiss(prayerName: String?) {
        dismissedPrayer = prayerName
        window.dismiss()
    }

    func setInteractiveFrame(_ frame: CGRect) { window.setInteractiveFrame(frame) }
}

// MARK: - Banner UI

struct AdhanBannerHost: View {
    @ObservedObject private var player = ForegroundAdhanPlayer.shared
    @ObservedObject private var presenter = AdhanBannerPresenter.shared

    var body: some View {
        VStack(spacing: 0) {
            if let prayerName = player.playingPrayerName,
               presenter.shouldShow(playing: prayerName, dismissed: presenter.dismissedPrayer) {
                AdhanBannerCard(prayerName: prayerName)
                    .id(prayerName)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        // Clears the Dynamic Island the way a system notification does, rather than tucking up
        // against it. Same inset as the achievement banner, so the two read as one family.
        .padding(.top, 16)
        .animation(.spring(response: 0.48, dampingFraction: 0.78), value: player.playingPrayerName)
        .onDisappear { AdhanBannerPresenter.shared.setInteractiveFrame(.zero) }
    }
}

private struct AdhanBannerCard: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var player = ForegroundAdhanPlayer.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let prayerName: String

    /// What the card says under the prayer name. On `.ambient` the recording obeys the ringer switch,
    /// so a silenced phone shows this banner over silence - the line names the switch instead of
    /// claiming sound, because that is the only thing that explains it (Abu, 2026-10-08).
    private var subtitle: String {
        player.followsRingerSwitch
            ? "Silent if the ringer switch is off"
            : "Tap Stop to end the adhan"
    }

    @State private var pulse = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        let accent = settings.accentColor.color

        HStack(spacing: 12) {
            icon(accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("ADHAN PLAYING")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(accent)

                Text(prayerName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            stopButton(accent)
            dismissButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(background(accent))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
        .shadow(color: accent.opacity(0.22), radius: 18, y: 2)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                // Upward only: dragging down would fight the notification-shade pull the banner sits
                // under, and there is nothing below it to reveal anyway.
                .onChanged { dragOffset = min(0, $0.translation.height) }
                .onEnded { value in
                    if value.translation.height < -18 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragOffset = 0 }
                    }
                }
        )
        // Deliberately NOT `.onTapGesture { dismiss() }` the way the achievement card is: the two
        // buttons here do different things, and a stray tap that hid the stop control would be the
        // opposite of what this banner is for.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(prayerName) adhan playing")
        .background(BannerFrameReporter { AdhanBannerPresenter.shared.setInteractiveFrame($0) })
        .onAppear(perform: animateIn)
    }

    // MARK: Pieces

    private func stopButton(_ accent: Color) -> some View {
        Button {
            settings.hapticFeedback()
            ForegroundAdhanPlayer.shared.stopAdhan()
        } label: {
            Text("Stop")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(accent))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop adhan")
    }

    private var dismissButton: some View {
        Button {
            settings.hapticFeedback()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(7)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hide banner")
        .accessibilityHint("The adhan keeps playing")
    }

    /// A speaker whose rings breathe while the recording runs, so the card reads as something
    /// currently making sound rather than as a notification about something that happened.
    private func icon(_ accent: Color) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.95), accent.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .shadow(color: accent.opacity(0.45), radius: 7, y: 2)
                .scaleEffect(pulse ? 1.06 : 1)

            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 46, height: 46)
        .accessibilityHidden(true)
    }

    private func background(_ accent: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.20), accent.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private func dismiss() {
        AdhanBannerPresenter.shared.dismiss(prayerName: prayerName)
    }

    private func animateIn() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
    }
}

// MARK: - Root hook

extension View {
    /// Keeps the adhan banner in step with the player. Attach once, on the app root.
    func adhanBannerHost() -> some View {
        modifier(AdhanBannerTracker())
    }
}

private struct AdhanBannerTracker: ViewModifier {
    @ObservedObject private var player = ForegroundAdhanPlayer.shared

    func body(content: Content) -> some View {
        content
            .onChange(of: player.playingPrayerName) { name in
                AdhanBannerPresenter.shared.sync(playingPrayerName: name)
            }
    }
}

#endif
