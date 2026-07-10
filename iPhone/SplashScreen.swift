#if os(iOS)
import SwiftUI

struct SplashScreen: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.openURL) private var openURL

    @State private var openedAppStoreFromHero = false
    @State private var popCenter = false
    @State private var popLeft = false
    @State private var popRight = false

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    private var isDarkMode: Bool {
        currentColorScheme == .dark
    }

    private var heroSpring: Animation {
        .spring(response: 0.52, dampingFraction: 0.62, blendDuration: 0)
    }

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let s = LaunchScreenLayout.scale(for: geo.size)
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("These are the Al-Islamic apps: Adhan, Quran, and everything in between. What more do you need?")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Text("All the apps are privacy-focused, ensuring that all data remains on your device. Enjoy an ad-free, subscription-free, and cost-free experience. Al-Quran and Al-Adhan are extensions, and Al-Islam does everything Al-Quran and Al-Adhan do combined, with additional functionalities.")
                                .font(.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Text("Tap any app below to open it in the App Store.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                    }

                    Spacer()

                    appHeroStack(layoutScale: s)
                        .padding(.bottom, 8)

                    Spacer()

                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .animation(.easeInOut, value: settings.firstLaunch)
                .transition(.opacity)
            }
            .navigationTitle("Assalamu Alaikum")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: runHeroPopAnimation)
        }
        .navigationViewStyle(.stack)
    }

    private func runHeroPopAnimation() {
        popCenter = false
        popLeft = false
        popRight = false
        withAnimation(heroSpring) {
            popCenter = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(heroSpring) {
                popLeft = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(heroSpring) {
                popRight = true
            }
        }
    }

    private func appHeroStack(layoutScale s: CGFloat) -> some View {
        let card = 120 * s
        let cr = 32 * s
        let inset = 10 * s
        let titleFont: Font = s > 1.15 ? .callout.weight(.semibold) : .caption.weight(.semibold)
        let jump: CGFloat = 88 * s
        let oxLeft: CGFloat = -132 * s
        let oxRight: CGFloat = 136 * s
        let oy: CGFloat = -2 * s
        let stackHeight = (275 * s) + (s > 1 ? 24 * s : 0)

        return ZStack {
            // Borrow the launch-style glow language for the splash hero only.
            bottomHeroAura(scale: s)

            Button {
                openAppStoreFromHero(Self.alAdhanAppURL)
            } label: {
                VStack(spacing: 10 * s) {
                    Text("Al-Adhan")
                        .font(titleFont)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    LaunchCompanionCard(
                        imageName: "Al-Adhan",
                        accentColor: settings.accentColor.color,
                        isDarkMode: isDarkMode,
                        width: card,
                        height: card,
                        cornerRadius: cr,
                        imageInset: inset,
                        opacity: 1
                    )
                }
            }
            .contentShape(Rectangle())
            .scaleEffect(popLeft ? 1 : 0.18)
            .offset(y: popLeft ? 0 : jump)
            .opacity(popLeft ? 1 : 0.35)
            .rotationEffect(.degrees(-5.6))
            .offset(x: oxLeft, y: oy)
            .zIndex(2)
            .accessibilityLabel("Al-Adhan on the App Store")

            Button {
                openAppStoreFromHero(Self.alQuranAppURL)
            } label: {
                VStack(spacing: 10 * s) {
                    Text("Al-Quran")
                        .font(titleFont)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    LaunchCompanionCard(
                        imageName: "Al-Quran",
                        accentColor: settings.accentColor.color,
                        isDarkMode: isDarkMode,
                        width: card,
                        height: card,
                        cornerRadius: cr,
                        imageInset: inset,
                        opacity: 1
                    )
                }
            }
            .contentShape(Rectangle())
            .scaleEffect(popRight ? 1 : 0.18)
            .offset(y: popRight ? 0 : jump)
            .opacity(popRight ? 1 : 0.35)
            .rotationEffect(.degrees(7))
            .offset(x: oxRight, y: oy)
            .zIndex(2)
            .accessibilityLabel("Al-Quran on the App Store")

            Button {
                openAppStoreFromHero(Self.alIslamAppURL)
            } label: {
                VStack(spacing: 10 * s) {
                    Text("Al-Islam")
                        .font(titleFont)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    LaunchLogoCard(
                        title: "Al-Islam",
                        accentColor: settings.accentColor.color,
                        isDarkMode: isDarkMode,
                        shimmerOffset: 0,
                        layoutScale: s,
                        showShimmer: false
                    )
                }
            }
            .contentShape(Rectangle())
            .scaleEffect(popCenter ? 1 : 0.2)
            .offset(y: popCenter ? 0 : jump * 1.05)
            .opacity(popCenter ? 1 : 0.4)
            .zIndex(1)
            .accessibilityLabel("Al-Islam on the App Store")
        }
        .frame(height: stackHeight)
    }

    private func bottomHeroAura(scale s: CGFloat) -> some View {
        let disk = 350 * s
        let ring = 250 * s
        return ZStack {
            RadialGradient(
                colors: [
                    Color.yellow.opacity(isDarkMode ? 0.45 : 0.34),
                    Color.green.opacity(isDarkMode ? 0.45 : 0.34),
                    .clear
                ],
                center: .center,
                startRadius: 12 * s,
                endRadius: 200 * s
            )
            .frame(width: disk, height: disk)
            .blur(radius: 8 * s)

            LinearGradient(
                colors: [
                    .yellow.opacity(isDarkMode ? 0.24 : 0.17),
                    .green.opacity(isDarkMode ? 0.18 : 0.12),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(Circle())
            .frame(width: disk * 0.88, height: disk * 0.88)

            Circle()
                .stroke(settings.accentColor.color.opacity(0.2), lineWidth: max(1, 1.2 * s))
                .frame(width: ring, height: ring)

            Circle()
                .stroke(Color.white.opacity(isDarkMode ? 0.14 : 0.2), lineWidth: max(0.8, 1 * s))
                .frame(width: ring * 1.2, height: ring * 1.2)
        }
        .offset(y: 10 * s)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var actionButtons: some View {
        HStack {
            /*Button {
                settings.hapticFeedback()
                withAnimation {
                    settings.firstLaunch = false
                }
                openURLIfPossible(Self.alIslamAppURL)
            } label: {
                Text("Download Al-Islam")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .conditionalGlassEffect(rectangle: true, useColor: 0.38, customTint: AppIdentifiers.mainColor.color)*/
            
            Button {
                settings.hapticFeedback()
                withAnimation {
                    settings.firstLaunch = false
                }
            } label: {
                Text(openedAppStoreFromHero ? "Done" : "Skip for now")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .conditionalGlassEffect(
                rectangle: true,
                useColor: 0.38,
                customTint: openedAppStoreFromHero ? AppIdentifiers.mainColor.color : .red
            )
            .accessibilityLabel(openedAppStoreFromHero ? "Done" : "Skip for now")
        }
    }

    private func openAppStoreFromHero(_ url: URL?) {
        settings.hapticFeedback()
        withAnimation(.easeInOut(duration: 0.25)) {
            openedAppStoreFromHero = true
        }
        openURLIfPossible(url)
    }

    private func openURLIfPossible(_ url: URL?) {
        guard let url else { return }
        openURL(url)
    }

    private static let alAdhanAppURL = URL(string: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493?platform=iphone")
    private static let alIslamAppURL = URL(string: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone")
    private static let alQuranAppURL = URL(string: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373?platform=iphone")
}

#Preview {
    SplashScreen()
        .environmentObject(Settings.shared)
}
#endif
