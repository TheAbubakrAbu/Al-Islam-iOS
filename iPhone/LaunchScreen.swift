import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Scales launch / splash hero UI on iPad so glows and icons fill the canvas.
enum LaunchScreenLayout {
    static func scale(for containerSize: CGSize) -> CGFloat {
        let d = min(containerSize.width, containerSize.height)
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return max(1.38, min(d / 410, 2.45))
        }
        #endif
        return 1.0
    }
}

/// Coordinates the "warm the main UI behind the launch screen, then reveal" hand-off.
///
/// The launch screen already has a quiet "hold on the logo and wait for init" phase; it now also waits for
/// `isWarm` before it plays its finale and hands off. `MainTabView` sets `isWarm` once it has built + retained
/// the heavy Quran tab (and the other tabs) and settled back on the Adhan landing tab - all behind the launch cover. Net effect: the
/// reveal happens only when everything is already built and on the right tab, so there's no tab flip and no
/// first-tap stall the user can see.
@MainActor
final class LaunchWarmup: ObservableObject {
    static let shared = LaunchWarmup()
    private init() {}

    @Published private(set) var isWarm = false

    func markWarm() { isWarm = true }

    /// Await `isWarm`, but never block the launch longer than `maxWaitNanos` (a safety cap so a failed warm can
    /// never strand the user on the launch screen).
    func waitUntilWarm(maxWaitNanos: UInt64) async {
        var waited: UInt64 = 0
        let step: UInt64 = 20_000_000
        while !isWarm && waited < maxWaitNanos {
            try? await Task.sleep(nanoseconds: step)
            waited += step
        }
    }
}

struct LaunchScreen: View {
    @ObservedObject var settings = Settings.shared
    // Note: QuranData / QuranPlayer / NamesViewModel are intentionally NOT observed here. They publish
    // frequently while loading (load-state changes, the 6k-entry verse index, player/names state), and
    // observing them would re-render the launch screen mid-animation - the source of the startup chop.
    // Readiness is awaited via the `.shared` singletons below, which doesn't subscribe to their changes.
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.customColorScheme) private var customColorScheme

    @Binding var isLaunching: Bool

    // Initial state = a plain background with the Al-Islam icon already at rest: no gradient, no glow, no
    // motion. Everything heavy loads during the quiet "hold" below; the gradient / rings / companion apps are
    // only brought in for the finale once the app is fully ready - so nothing animates while the CPU is busy.
    @State private var size = 0.9
    @State private var opacity = 1.0
    @State private var gradientSize: CGFloat = 0.6
    @State private var glowOpacity: Double = 0.0
    @State private var ringScale: CGFloat = 0.9
    @State private var ringOpacity: Double = 0.0
    @State private var logoRotation: Double = 0
    @State private var logoYOffset: CGFloat = 0
    @State private var textOffset: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -220
    @State private var glassFloat: CGFloat = 0
    @State private var glassTilt: Double = 0
    @State private var glassOpacity: Double = 0.0
    @State private var leftGlassOffset: CGFloat = 0
    @State private var rightGlassOffset: CGFloat = 0
    @State private var contentBlur: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let layoutScale = LaunchScreenLayout.scale(for: geo.size)
            ZStack {
                LaunchScreenBackground(
                    backgroundColor: backgroundColor,
                    accentColor: settings.accentColor.color,
                    isDarkMode: currentColorScheme == .dark,
                    gradientSize: gradientSize,
                    glowOpacity: glowOpacity,
                    ringScale: ringScale,
                    ringOpacity: ringOpacity,
                    layoutScale: layoutScale
                )

                #if os(iOS)
                companionCards(layoutScale: layoutScale)
                #endif
                
                logoCard(layoutScale: layoutScale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.easeInOut, value: isLaunching)
            .transition(.opacity)
        }
        .ignoresSafeArea()
        .onAppear {
            Task { @MainActor in
                await runLaunchAnimation()
            }
        }
        .blur(radius: contentBlur)
    }

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    private var backgroundColor: Color {
        switch currentColorScheme {
        case .light:
            return .white
        case .dark:
            return .black
        @unknown default:
            return .white
        }
    }

    private func companionCards(layoutScale: CGFloat) -> some View {
        ZStack {
            let card: CGFloat = 120 * layoutScale
            let cr = 32 * layoutScale
            let inset = 10 * layoutScale
            
            LaunchCompanionCard(
                imageName: "Al-Adhan",
                accentColor: settings.accentColor.color,
                isDarkMode: currentColorScheme == .dark,
                width: card,
                height: card,
                cornerRadius: cr,
                imageInset: inset,
                opacity: glassOpacity * 0.58
            )
            .rotationEffect(.degrees(-glassTilt * 0.8))
            .offset(x: (-74 + leftGlassOffset) * layoutScale, y: glassFloat + 4 * layoutScale)

            LaunchCompanionCard(
                imageName: "Al-Quran",
                accentColor: settings.accentColor.color,
                isDarkMode: currentColorScheme == .dark,
                width: card,
                height: card,
                cornerRadius: cr,
                imageInset: inset,
                opacity: glassOpacity
            )
            .rotationEffect(.degrees(glassTilt))
            .offset(x: (80 + rightGlassOffset) * layoutScale, y: glassFloat + 4 * layoutScale)
        }
    }

    private func logoCard(layoutScale: CGFloat) -> some View {
        VStack {
            VStack {
                LaunchLogoCard(
                    title: "Al-Islam",
                    accentColor: settings.accentColor.color,
                    isDarkMode: currentColorScheme == .dark,
                    shimmerOffset: shimmerOffset,
                    layoutScale: layoutScale
                )
                .rotationEffect(.degrees(logoRotation))
                .offset(y: logoYOffset)
                .padding(16 * layoutScale)
            }
            .foregroundColor(settings.accentColor.color)
            .scaleEffect(size)
            .opacity(opacity)
        }
    }

    @MainActor
    private func runLaunchAnimation() async {
        // 1) Nothing animates yet. The initial state already shows just the Al-Islam icon on a plain background
        //    (no gradient), so the heavy load + warm in step 2 stays perfectly smooth — there are no running
        //    animations to drop frames.
        triggerHapticFeedback(.soft)

        // 2) Hold on the icon and wait for everything to finish initializing. Nothing is animating during this
        //    window, so background-init contention is invisible — the screen simply rests on the icon for as
        //    long as it takes. This is the "keep Al-Islam there and wait" behavior.
        async let settingsReady: Void = Settings.shared.waitUntilReady()
        async let quranReady: Void = {
            if QuranData.shared.shouldWaitForFullLaunchReadiness {
                await QuranData.shared.waitUntilLoaded()
            } else {
                await QuranData.shared.waitUntilCoreLoaded()
            }
        }()
        async let playerReady: Void = QuranPlayer.shared.waitUntilReady()
        async let namesReady: Void = NamesViewModel.shared.waitUntilLoaded()
        _ = await (settingsReady, quranReady, playerReady, namesReady)

        #if os(iOS)
        // Still nothing animating: also let the main tabs build + warm behind this cover (the Quran tab is
        // realized and retained, then we settle on Adhan). Waiting here means the flourish + hand-off below run
        // against an already-built UI, so the reveal is instant and the first Quran tap doesn't stall. Capped so
        // a failed warm can never strand us on the launch screen. iPhone-only: the Watch has no such tab warm.
        await LaunchWarmup.shared.waitUntilWarm(maxWaitNanos: 6_000_000_000)
        #endif

        // 3) Everything is ready and the CPU is free, so the finale plays smoothly on top of the resting icon:
        //    the gradient/glow blooms in, the rings expand, the shimmer sweeps the logo, and - a beat later -
        //    the Quran/Adhan companion apps are released outward.
        triggerHapticFeedback(.soft)
        // The finale is SACRED: these three animation blocks (springs, shimmer, companion release) play
        // exactly like this on every device, every mode - no Reduce Motion branch, no Low Power branch,
        // no alternate curves. The user has been explicit, repeatedly: optimize the loading and caching
        // around it all you like, but never change what this looks like.
        withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
            size = 0.94
            gradientSize = 3.4
            glowOpacity = 1.0
            ringScale = 1.08
            ringOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.85)) {
            shimmerOffset = 220
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.08)) {
            glassFloat = -10
            glassTilt = 7
            glassOpacity = 1.0
            leftGlassOffset = -34
            rightGlassOffset = 34
        }

        // DELIBERATELY SLOW - DO NOT SPEED UP. Everything from the moment loading finishes to the
        // hand-off below (the gradient/color bloom, the Quran/Adhan companion icons floating out,
        // this 900ms hold, and the 0.5s dissolve) is hand-tuned pacing, not waste. It has been
        // "optimized" faster several times and every time the finale looked rushed and hideous -
        // the reveal needs this beat to land. Data loading above is fair game; this finale is not.
        try? await Task.sleep(nanoseconds: 900_000_000)

        // 4) Smoothly hand off to the app (revealing the already-warm Adhan tab underneath).
        triggerHapticFeedback(.soft)
        withAnimation(.easeInOut(duration: 0.5)) {
            isLaunching = false
        }
    }

    private func triggerHapticFeedback(_ feedbackType: HapticFeedbackType) {
        guard settings.hapticOn else { return }

        #if os(iOS)
        switch feedbackType {
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        #else
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    enum HapticFeedbackType {
        case soft
        case light
        case medium
        case heavy
    }
}

struct LaunchScreenBackground: View {
    let backgroundColor: Color
    let accentColor: Color
    let isDarkMode: Bool
    let gradientSize: CGFloat
    let glowOpacity: Double
    let ringScale: CGFloat
    let ringOpacity: Double
    var layoutScale: CGFloat = 1

    var body: some View {
        let s = layoutScale
        let radialEnd = 220 * s
        let disk: CGFloat = 420 * s
        let ringInner: CGFloat = 210 * s
        let ringOuter: CGFloat = 260 * s
        let blurMain = max(12, 10 * s)
        let blurDisk = max(6, 5 * s)

        ZStack {
            backgroundColor
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    accentColor.opacity(isDarkMode ? 0.18 : 0.08),
                    .clear,
                    Color.cyan.opacity(isDarkMode ? 0.12 : 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            // Gated with the glow so the very first frame is a plain background + icon; the wash blooms in only
            // for the finale.
            .opacity(glowOpacity)

            RadialGradient(
                colors: [
                    accentColor.opacity(0.45),
                    accentColor.opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 20 * s,
                endRadius: radialEnd
            )
            .scaleEffect(gradientSize * 1.15)
            .blur(radius: blurMain)
            .opacity(glowOpacity)

            LinearGradient(
                colors: [
                    accentColor.opacity(0.18),
                    accentColor.opacity(0.45),
                    Color.cyan.opacity(isDarkMode ? 0.18 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(Circle())
            .contentShape(Circle())
            .frame(width: disk, height: disk)
            .scaleEffect(gradientSize)
            .blur(radius: blurDisk)
            // The colored disk behind the logo is the most visible "gradient"; keep it hidden until the finale
            // blooms it in (it also scales up via `gradientSize`).
            .opacity(glowOpacity)

            Circle()
                .stroke(accentColor.opacity(0.18), lineWidth: max(1.5, 1.2 * s))
                .frame(width: ringInner, height: ringInner)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .stroke(Color.white.opacity(isDarkMode ? 0.12 : 0.2), lineWidth: max(1, 0.9 * s))
                .frame(width: ringOuter, height: ringOuter)
                .scaleEffect(ringScale * 0.96)
                .opacity(ringOpacity * 0.75)
        }
    }
}

struct LaunchLogoCard: View {
    let title: String
    let accentColor: Color
    let isDarkMode: Bool
    let shimmerOffset: CGFloat
    var layoutScale: CGFloat = 1
    var showShimmer: Bool = true

    var body: some View {
        let s = layoutScale
        let outer: CGFloat = 170 * s
        let inner: CGFloat = 146 * s
        let cr: CGFloat = 34 * s
        let imgCr: CGFloat = 24 * s
        let glossCr: CGFloat = 26 * s

        ZStack {
            #if os(iOS)
            // Glass has to be built from opposite materials on the two backgrounds. On black, white at
            // low opacity IS the glass: the material lifts off the background and the white edge reads
            // as a lit rim. On white, every one of those cues is nothing - a white edge on white is
            // invisible, and a near-white material over white has nothing to lift off, which left the
            // light launch screen looking like the icon floating on a bare page. So light mode gets the
            // inverse: a faint accent tint so the body isn't the same white as the page, a dark neutral
            // rim instead of a white one, and a real drop shadow, which is what actually makes a pale
            // card read as floating rather than painted on.
            RoundedRectangle(cornerRadius: cr, style: .continuous)
                .fill(.ultraThinMaterial.opacity(isDarkMode ? 0.45 : 0.7))
                .frame(width: outer, height: outer)
                .overlay(
                    // NEUTRAL, not accent. Tinting the body with the accent turned the card into a
                    // green plate - a color cast reads as painted plastic, where glass reads as a
                    // faint grey because it is slightly darker than the page behind it.
                    RoundedRectangle(cornerRadius: cr, style: .continuous)
                        .fill(Color.black.opacity(isDarkMode ? 0 : 0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cr, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isDarkMode
                                    ? [Color.white.opacity(0.55), accentColor.opacity(0.4)]
                                    : [Color.black.opacity(0.20), accentColor.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.2, 1 * s)
                        )
                )
                // The accent halo is dialled DOWN on light, not up: at full strength it swamped the
                // card in green and became the only thing on screen. It's brand seasoning here; the
                // neutral shadow below is what actually carries the depth.
                .shadow(color: accentColor.opacity(isDarkMode ? 0.22 : 0.16), radius: 24 * s, y: 10 * s)
                .shadow(color: Color.black.opacity(isDarkMode ? 0 : 0.18), radius: 20 * s, y: 10 * s)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: glossCr, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDarkMode ? 0.18 : 0.34),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110 * s, height: 54 * s)
                        .blur(radius: 0.3)
                        .padding(12 * s)
                }
            #endif

            Image(title)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(imgCr)
                .frame(maxWidth: inner, maxHeight: inner)
                .overlay(alignment: .topLeading) {
                    if showShimmer {
                        LinearGradient(
                            colors: [
                                .white.opacity(0.0),
                                .white.opacity(0.32),
                                .white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .rotationEffect(.degrees(22))
                        .offset(x: shimmerOffset)
                        .blendMode(.screen)
                        .mask(
                            RoundedRectangle(cornerRadius: imgCr, style: .continuous)
                                .frame(width: inner, height: inner)
                        )
                    }
                }
        }
    }
}

struct LaunchCompanionCard: View {
    let imageName: String
    let accentColor: Color
    let isDarkMode: Bool
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let imageInset: CGFloat
    let opacity: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                #if os(iOS)
                .fill(.ultraThinMaterial.opacity(isDarkMode ? 0.22 : 0.38))
                #else
                .fill(Color.white.opacity(isDarkMode ? 0.08 : 0.16))
                #endif
                .overlay(
                    // Same white-on-white problem as `LaunchLogoCard` above, same fix: on light the
                    // rim has to be darker than the page, not lighter.
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.12),
                            lineWidth: 1
                        )
                )

            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(max(18, cornerRadius - 8))
                .padding(imageInset)
        }
        .frame(width: width, height: height)
        .opacity(opacity)
    }
}
