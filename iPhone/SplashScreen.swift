#if os(iOS)
import SwiftUI

struct SplashScreen: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// True when the Islam tab's "Learn More" presents this as a sheet over a running app. The button then
    /// reads "Done" and dismisses the sheet; on first launch (the default) it clears `firstLaunch` and the
    /// root fades the splash away itself.
    var presentedAsSheet = false

    @State private var openedAppStoreFromHero = false
    @State private var popCenter = false
    @State private var popLeft = false
    @State private var popRight = false
    /// One shimmer sweep across the Al-Islam card after the pop-in settles (the launch screen's
    /// gloss, reused) - the range LaunchLogoCard expects is -220 ... 220.
    @State private var splashShimmer: CGFloat = -220

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    private var isDarkMode: Bool {
        currentColorScheme == .dark
    }

    private var accent: Color {
        settings.accentColor.color
    }

    /// The app family below the card, at this fraction of the launch screen's size. The feature card
    /// needs the room: four rows in Al-Islam, where iCloud Backup joins them.
    private static let heroFraction: CGFloat = 0.8

    /// At the accessibility text sizes the family row and its labels would take half the screen and
    /// leave the promises a sliver, so they scroll with the text instead of standing below it.
    private var heroScrolls: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var heroSpring: Animation {
        .spring(response: 0.52, dampingFraction: 0.62, blendDuration: 0)
    }

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let s = LaunchScreenLayout.scale(for: geo.size)
                // One reading column: 20 pt gutters on a phone, a comfortable measure on an iPad.
                let column = min(geo.size.width - 40, 520 * min(s, 1.3))
                ZStack {
                    splashBackdrop(scale: s)

                    VStack(spacing: 0) {
                        // The greeting and the promises scroll only when they must (a small phone, a
                        // large text size, the sheet); the family row and the button stay put.
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 18 * s) {
                                greeting(scale: s)
                                featureCard
                                if heroScrolls {
                                    appHeroStack(layoutScale: s)
                                }
                            }
                            .frame(width: column)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10 * s)
                            .padding(.bottom, 12)
                        }

                        // Under the card, not over it: the aura spreads past its own frame, and on
                        // top it washed the last row's text.
                        if !heroScrolls {
                            appHeroStack(layoutScale: s)
                                .zIndex(-1)
                        }

                        actionButtons
                            .frame(width: column)
                            .padding(.top, 4)
                            .padding(.bottom, 16)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .animation(.easeInOut, value: settings.firstLaunch)
                .transition(.opacity)
            }
            .navigationBarTitleDisplayMode(.inline)
            // As a sheet ("Learn More") this had NO dismiss control at all: the only way out was the
            // full-width hero button at the bottom of a scroll view (Abu, 2026-09-18). The hero button
            // stays - it is the screen's own call to action, and on first launch it reads "Get
            // Started" - but the sheet now also closes from the house X, like every other sheet.
            .sheetDismissToolbarIf(presentedAsSheet)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 1.1)) {
                splashShimmer = 220
            }
        }
    }

    private func appHeroStack(layoutScale screenScale: CGFloat) -> some View {
        let s = screenScale * Self.heroFraction
        let card = 120 * s
        let cr = 32 * s
        let inset = 10 * s
        let titleFont: Font = screenScale > 1.15 ? .callout.weight(.semibold) : .caption.weight(.semibold)
        let jump: CGFloat = 88 * s
        let oxLeft: CGFloat = -132 * s
        let oxRight: CGFloat = 136 * s
        let oy: CGFloat = -2 * s
        let stackHeight = (275 * s) + (screenScale > 1 ? 24 * s : 0)

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
                        shimmerOffset: splashShimmer,
                        layoutScale: s,
                        showShimmer: true
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

    /// A quiet accent wash behind the greeting - the launch screen's glow language at whisper
    /// volume, so the hero cards' aura below stays the loudest thing on screen.
    private func splashBackdrop(scale s: CGFloat) -> some View {
        VStack {
            RadialGradient(
                colors: [
                    settings.accentColor.color.opacity(isDarkMode ? 0.22 : 0.14),
                    .clear
                ],
                center: .top,
                startRadius: 10 * s,
                endRadius: 380 * s
            )
            .frame(height: 420 * s)

            Spacer(minLength: 0)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func greeting(scale s: CGFloat) -> some View {
        VStack(spacing: 4 * s) {
            Text("ٱلسَّلَامُ عَلَيكُم")
                .font(Font.arabic(settings.nonQuranArabicFontName, size: 34 * s))
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .foregroundColor(accent)

            Text("Assalamu Alaikum")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("Peace be upon you, and welcome to \(AppIdentifiers.appName).")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private struct Feature: Identifiable {
        let icon: String
        let title: String
        let text: String
        /// A small capsule beside the title, for what only this app has.
        var tag: String? = nil
        var id: String { title }
    }

    /// What every app in the family promises, and what only Al-Islam has. iCloud Backup is Al-Islam's
    /// alone (`HAS_ICLOUD_BACKUP`, which the companion apps do not define), so they show three rows
    /// and name it in the family row instead.
    private var features: [Feature] {
        #if HAS_ICLOUD_BACKUP
        return [
            Feature(icon: "lock.shield.fill", title: "Private by design",
                    text: "No accounts and no tracking, and it works offline. What you save is yours alone."),
            Feature(icon: "heart.fill", title: "Free forever",
                    text: "No ads, fees or subscriptions. Offered as sadaqah jariyah."),
            Feature(icon: "icloud.fill", title: "iCloud Backup",
                    text: "Optional: your bookmarks, prayer tracker, khatm and journal, in your own private iCloud.",
                    tag: "Only in Al-Islam"),
            Feature(icon: "square.grid.2x2.fill", title: "One family of apps",
                    text: "Everything Al-Quran and Al-Adhan do, in one app. Tap an app below to see it on the App Store."),
        ]
        #else
        return [
            Feature(icon: "lock.shield.fill", title: "Private by design",
                    text: "Everything stays on your device: no accounts, no tracking, and it works offline."),
            Feature(icon: "heart.fill", title: "Free forever",
                    text: "No ads, fees or subscriptions. Offered as sadaqah jariyah."),
            Feature(icon: "square.grid.2x2.fill", title: "One family of apps",
                    text: "Al-Islam does everything Al-Quran and Al-Adhan do, plus iCloud Backup. Tap an app below to see it on the App Store."),
        ]
        #endif
    }

    /// The promises as one card, in the grammar of the About You and iCloud offer cards that follow
    /// this screen: a filled surface with a hairline edge, not glass (on this plain ground clear glass
    /// draws no surface in the light themes).
    private var featureCard: some View {
        let items = features
        return VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, feature in
                featureRow(feature)
                if index < items.count - 1 {
                    Divider()
                        .padding(.leading, 61)
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(alignment: .top, spacing: 13) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(colors: [accent, accent.opacity(0.74)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: feature.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                // The tag drops under the title at the accessibility sizes rather than squeezing it.
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        featureTitle(feature)
                        featureTag(feature)
                    }
                } else {
                    HStack(spacing: 6) {
                        featureTitle(feature)
                        featureTag(feature)
                    }
                }

                Text(feature.text)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }

    private func featureTitle(_ feature: Feature) -> some View {
        Text(feature.title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.primary)
    }

    @ViewBuilder
    private func featureTag(_ feature: Feature) -> some View {
        if let tag = feature.tag {
            Text(tag)
                .font(.caption2.weight(.bold))
                .foregroundColor(accent)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(accent.opacity(isDarkMode ? 0.24 : 0.14)))
        }
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

            // The outer halo ring. White on light mode is white on white - invisible, the same trap
            // the launch card's rim fell into; on light it has to be darker than the page.
            Circle()
                .stroke(
                    isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.10),
                    lineWidth: max(0.8, 1 * s)
                )
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
                if presentedAsSheet {
                    // A sheet over the running app: there is no first launch to end, only the sheet.
                    dismiss()
                } else {
                    withAnimation {
                        settings.firstLaunch = false
                    }
                }
            } label: {
                Text(actionTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .conditionalGlassEffect(
                rectangle: true,
                useColor: 0.38,
                customTint: AppIdentifiers.mainColor.color
            )
            .accessibilityLabel(actionTitle)
        }
    }

    /// "Get Started" only makes sense on the first launch; a sheet opened from "Learn More" closes with "Done".
    private var actionTitle: String {
        (presentedAsSheet || openedAppStoreFromHero) ? "Done" : "Get Started"
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
