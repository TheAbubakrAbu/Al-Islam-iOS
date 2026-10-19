import SwiftUI

// The banner that floats over the whole app while the adhan sounds in-app, so the recording can
// always be stopped from wherever you happen to be (Abu, 2026-10-06), and while an adhan is on
// OFFER, so the Play button is reachable from any tab too (Abu, 2026-10-19: "all adhans if playing
// should have a banner", and the button "where stop adhan would be"). The sky card's footer button
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

    /// The banner the user dismissed, by the player's key ("pending:Dhuhr", "playing:Dhuhr"). The
    /// adhan keeps going; only the card goes away. Keyed on the STATE as well as the prayer, so hiding
    /// the Play offer never hides the PLAYING card that follows a tap on the footer: every adhan that
    /// sounds gets its banner. Cleared when the player goes quiet, so the next adhan banners again.
    @Published private(set) var dismissedKey: String?

    private let window = BannerWindow { AdhanBannerHost() }

    private init() {}

    /// Whether the card should be on screen for this player state.
    func shouldShow(key: String?, dismissed: String?) -> Bool {
        guard let key else { return false }
        return key != dismissed
    }

    func sync(key: String?) {
        if let key {
            if shouldShow(key: key, dismissed: dismissedKey) {
                window.present()
            } else {
                window.dismiss()
            }
        } else {
            // The adhan ended (finished, stopped from anywhere, or the offer lapsed): forget the
            // dismissal so the next adhan raises its own banner.
            dismissedKey = nil
            window.dismiss()
        }
    }

    /// Hides the card without touching the audio or the offer.
    func dismiss(key: String?) {
        dismissedKey = key
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
            if let key = player.bannerKey,
               presenter.shouldShow(key: key, dismissed: presenter.dismissedKey),
               let prayerName = player.playingPrayerName ?? player.pendingPrayerName {
                AdhanBannerCard(prayerName: prayerName,
                                isPlaying: player.isPlaying,
                                reason: player.pendingReason,
                                key: key)
                    .id(key)
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
        .animation(.spring(response: 0.48, dampingFraction: 0.78), value: player.bannerKey)
        .onDisappear { AdhanBannerPresenter.shared.setInteractiveFrame(.zero) }
    }
}

private struct AdhanBannerCard: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let prayerName: String
    let isPlaying: Bool
    let reason: ForegroundAdhanPlayer.OfferReason?
    let key: String

    private var kicker: String { isPlaying ? "ADHAN PLAYING" : "ADHAN TIME" }

    /// What the card says under the prayer name: how to end a playing adhan, or why an offered one
    /// did not start by itself.
    private var subtitle: String {
        guard !isPlaying else { return "Tap Stop to end the adhan" }
        switch reason {
        case .silenced: return "In Silent Mode · Tap Play to hear it"
        case .manual, .none: return "Tap Play to hear the adhan"
        }
    }

    private var iconName: String {
        if isPlaying { return "speaker.wave.2.fill" }
        return reason == .silenced ? "speaker.slash.fill" : "play.fill"
    }

    @State private var pulse = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        let accent = settings.accentColor.color

        HStack(spacing: 12) {
            icon(accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(kicker)
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

            actionButton(accent)
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
        .accessibilityLabel(isPlaying ? "\(prayerName) adhan playing" : "Time for \(prayerName)")
        .background(BannerFrameReporter { AdhanBannerPresenter.shared.setInteractiveFrame($0) })
        .onAppear(perform: animateIn)
    }

    // MARK: Pieces

    /// Stop while the adhan sounds; Play while it is on offer. The same place on the card for both,
    /// the way the sky-card footer swaps the one capsule for the other.
    private func actionButton(_ accent: Color) -> some View {
        Button {
            settings.hapticFeedback()
            if isPlaying {
                ForegroundAdhanPlayer.shared.stopAdhan()
            } else {
                ForegroundAdhanPlayer.shared.playOfferedAdhan()
            }
        } label: {
            Text(isPlaying ? "Stop" : "Play")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(accent))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Stop adhan" : "Play adhan")
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
        .accessibilityHint(isPlaying ? "The adhan keeps playing" : "The Play button stays on the prayer card")
    }

    /// A speaker whose rings breathe while the recording runs, so the card reads as something
    /// currently making sound rather than as a notification about something that happened. Still
    /// while the adhan is only on offer.
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

            Image(systemName: iconName)
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
        AdhanBannerPresenter.shared.dismiss(key: key)
    }

    private func animateIn() {
        guard isPlaying, !reduceMotion else { return }
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
            .onChange(of: player.bannerKey) { key in
                AdhanBannerPresenter.shared.sync(key: key)
            }
            // `.onChange` has no previous value on the first body: an adhan already sounding when the
            // root mounts (a cold launch inside the window) would otherwise never get its banner.
            .onAppear {
                AdhanBannerPresenter.shared.sync(key: player.bannerKey)
            }
    }
}

#endif
