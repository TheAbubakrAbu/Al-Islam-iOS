// The welcome's shared pieces and its middle pages (Abu, 2026-10-19: "for splash screen force them to
// go through it ... instead of asking location and notification at the same time have them be buttons
// in a splash screen page ... tips and tricks ... you can also turn on simple mode"). SplashScreen.swift
// runs the pages in order: what the app is, About You (AboutYouView.swift), Location and Notifications
// (`WelcomePermissionsPage`, Al-Adhan and Al-Islam), what there is to discover and how much of it to
// show (`WelcomeDiscoverPage`), and on Al-Islam the iCloud offer (CloudBackupViews.swift) as the stage
// after it. Every page ends in the same `WelcomeActionBar` with a Skip that skips that page alone, and
// nothing leaves the whole walk at once (Abu, 2026-10-19: "have each page option have a skip button but
// don't have way to leave the tutorial completely"). Shared with the companion apps like the splash, so
// per-app content sits behind flags.
#if os(iOS)
import SwiftUI

// MARK: - The bar every page ends in

/// One glass primary button and, under it, a plain secondary (Skip, or Not Now on the Adhan tab's
/// sheet), with Back beside it where a page has a step to go back to. The splash, About You, the
/// permissions sheet and page and the iCloud offer all end this way; they used to carry their own
/// copies, already drifting in padding and weight.
struct WelcomeActionBar: View {
    let primaryTitle: String
    var primaryEnabled = true
    /// A spinner leads the title and both buttons wait (a permission being asked, a backup saving).
    var primaryBusy = false
    /// Only when a test needs it: an identifier replaces the label as what `app.buttons[...]` finds.
    var primaryIdentifier: String? = nil
    let primaryAction: () -> Void
    var secondaryTitle: String? = nil
    var secondaryIdentifier: String? = nil
    var secondaryAction: () -> Void = {}
    /// Back to the page's previous step (About You's tailored page), on the leading half of the row.
    var backAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 6) {
            // The system's prominent button on the accent, the call to action every notice in the app
            // ends with (`BetaTextConsentCard`); it was a tinted glass slab of its own until 2026-10-26.
            Button {
                Settings.shared.hapticFeedback()
                primaryAction()
            } label: {
                HStack(spacing: 8) {
                    if primaryBusy { ProgressView().tint(.white) }
                    Text(primaryTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Settings.shared.accentColor.color)
            .disabled(!primaryEnabled || primaryBusy)
            .modifier(OptionalIdentifier(identifier: primaryIdentifier))

            if secondaryTitle != nil || backAction != nil {
                HStack(spacing: 0) {
                    if let backAction {
                        secondaryButton(String(localized: "Back"), systemImage: "chevron.backward", identifier: "welcomeBack", action: backAction)
                    }
                    if let secondaryTitle {
                        secondaryButton(secondaryTitle, identifier: secondaryIdentifier, action: secondaryAction)
                    }
                }
            }
        }
    }

    private func secondaryButton(_ title: String, systemImage: String? = nil, identifier: String?,
                                 action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.semibold))
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            // The accent, as a text link under a prominent button reads on the system's own sheets
            // ("Not Now" under "Continue").
            .foregroundColor(Settings.shared.accentColor.color)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(primaryBusy)
        .modifier(OptionalIdentifier(identifier: identifier))
    }

    private struct OptionalIdentifier: ViewModifier {
        let identifier: String?

        @ViewBuilder
        func body(content: Content) -> some View {
            if let identifier {
                content.accessibilityIdentifier(identifier)
            } else {
                content
            }
        }
    }
}

// MARK: - Where in the welcome

/// One capsule per page, the current one long and in the accent (the tips tour's footer, reused).
struct WelcomeProgressDots: View {
    @Environment(\.appearance) private var appearance

    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(count, 1), id: \.self) { page in
                Capsule()
                    .fill(page == index ? appearance.accent : Color.secondary.opacity(0.3))
                    .frame(width: page == index ? 18 : 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: index)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(index + 1) of \(count)")
    }
}

// MARK: - Location and Notifications

#if HAS_ADHAN
/// The two permissions as two buttons of their own, each raising its system prompt when tapped, over the
/// same cards the Adhan tab's sheet shows (PermissionsSheet.swift). Continue once both are answered;
/// Skip, there whatever was answered, quiets whatever is not for a day, the sheet's own snooze, so the
/// tab does not ask again the moment the welcome ends.
struct WelcomePermissionsPage: View {
    @StateObject private var asker = PermissionAsker()

    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    PermissionsIntro()
                    PermissionCards(asker: asker)
                    Text(PermissionCards.footnote)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            WelcomeActionBar(
                primaryTitle: String(localized: "Continue"),
                primaryEnabled: !asker.anythingUndetermined,
                primaryAction: onFinished,
                secondaryTitle: String(localized: "Skip"),
                secondaryIdentifier: "welcomeSkip",
                secondaryAction: {
                    asker.snoozeUnanswered()
                    onFinished()
                }
            )
            .frame(maxWidth: 560)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .task { await asker.refresh() }
    }
}
#endif

// MARK: - A lot to discover

/// What there is in the app and how much of it to show: a short pitch, the Tips & Tricks door (the
/// tour of what only this app does), then the Simple or Full choice (Docs/Product/Simple Mode Guide.md,
/// Splash). The choice is written by the splash when its page ends, not here.
struct WelcomeDiscoverPage: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.colorScheme) private var systemColorScheme

    @Binding var choosesSimple: Bool

    @State private var showTour = false

    private var accent: Color { settings.accentColor.color }
    private var isDarkMode: Bool { (settings.colorScheme ?? systemColorScheme) == .dark }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(accent)
                    .padding(.bottom, 2)
                    .accessibilityHidden(true)

                Text("A lot to discover")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(pitch)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            tipsCard

            VStack(alignment: .leading, spacing: 10) {
                Text("HOW MUCH WOULD YOU LIKE TO SEE?")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                    .accessibilityAddTraits(.isHeader)

                modeCard(simple: true, title: String(localized: "Simple"), text: simpleModeSummary,
                         systemImage: "rectangle.compress.vertical")
                modeCard(simple: false, title: String(localized: "Full"), text: String(localized: "Every tool, shortcut and detail, right on screen."),
                         systemImage: "rectangle.expand.vertical")
            }

            Text("You can change this any time in Settings \u{203A} Simple Mode.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(isPresented: $showTour) {
            TipsTourView(area: .app, tips: TipCatalog.spotlight, title: String(localized: "Only in \(AppIdentifiers.displayName)"))
                .smallMediumSheetPresentation()
        }
    }

    /// Named after the Settings tab's own spotlight cards, so each app names what it really has.
    private var pitch: String {
        let highlights = TipCatalog.spotlight.prefix(3).compactMap { $0.card?.title }
        let lead = highlights.isEmpty
            ? String(localized: "\(AppIdentifiers.displayName) does things no other app does.")
            : String(localized: "\(AppIdentifiers.displayName) does things no other app does, like \(Self.listed(highlights)).")
        return String(localized: "\(lead) It can feel like a lot at first. Browse the Tips & Tricks whenever you like, or start with Simple Mode and bring the extras in when you want them.")
    }

    /// "A, B and C".
    static func listed(_ items: [String]) -> String {
        guard items.count > 1, let last = items.last else { return items.first ?? "" }
        return String(localized: "\(items.dropLast().joined(separator: ", ")) and \(last)")
    }

    private var tipCount: Int {
        TipArea.offered.reduce(0) { $0 + TipCatalog.tips(in: $1).count }
    }

    /// The door to the tour of what only this app does; every settings page keeps its own list too.
    private var tipsCard: some View {
        Button {
            settings.hapticFeedback()
            showTour = true
        } label: {
            HStack(alignment: .center, spacing: 13) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.74)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Tips & Tricks")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(tipCount) things that are easy to miss, each with where to find it. Every settings page opens with its own list, and this short tour shows what only \(AppIdentifiers.displayName) does.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color.secondary.opacity(0.6))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tips & Tricks")
        .accessibilityHint("Opens a short tour")
        .accessibilityIdentifier("welcomeTipsTour")
    }

    /// What Simple keeps on screen, named by the domains this app ships (Al-Quran has no prayer
    /// times, Al-Adhan no Quran reader).
    private var simpleModeSummary: String {
        #if HAS_ADHAN && HAS_QURAN
        return String(localized: "Prayer times, the Quran and the essentials, with the extras tucked away until you want them.")
        #elseif HAS_ADHAN
        return String(localized: "Prayer times and the essentials, with the extras tucked away until you want them.")
        #else
        return String(localized: "The Quran and the essentials, with the extras tucked away until you want them.")
        #endif
    }

    private func modeCard(simple: Bool, title: String, text: String, systemImage: String) -> some View {
        let selected = choosesSimple == simple
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) { choosesSimple = simple }
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.74)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(text)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selected ? accent : Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selected ? accent.opacity(0.16) : Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(selected ? accent : Color.primary.opacity(0.08), lineWidth: selected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(text)")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(simple ? "splashChoiceSimple" : "splashChoiceFull")
    }
}
#endif
