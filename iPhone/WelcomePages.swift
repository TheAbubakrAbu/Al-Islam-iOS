// The welcome's shared pieces and its middle pages. SplashScreen.swift runs the pages in order: what the
// app is, About You (AboutYouView.swift), Location and Notifications (`WelcomePermissionsPage`, Al-Adhan
// and Al-Islam), Simple or Full (`WelcomeModePage`, Al-Islam), and on Al-Islam the iCloud offer
// (CloudBackupViews.swift) as the stage after it. Every page is one idea that fits the screen without
// scrolling (Abu, 2026-11-05: "make them look beautiful make them simple make them clear"): the same
// `WelcomeHeader`, at most two lines under it, and the same `WelcomeActionBar` with a Skip that skips
// that page alone. Nothing leaves the whole walk at once (Abu, 2026-10-19: "have each page option have a
// skip button but don't have way to leave the tutorial completely"). Shared with the companion apps like
// the splash, so per-app content sits behind flags.
#if os(iOS)
import SwiftUI

// MARK: - The bar every page ends in

/// One glass primary button and, under it, a plain secondary (Skip, or Not Now on the Adhan tab's
/// sheet), with Back beside it where a page has a step to go back to. The splash, About You, the
/// permissions sheet and page and the iCloud offer all end this way; they used to carry their own
/// copies, already drifting in padding and weight.
struct WelcomeActionBar: View {
    /// The accent off the environment, so an accent change redraws this view (a bare `Settings` read
    /// in a view that observes nothing kept the old colour).
    @Environment(\.appearance) private var appearance

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
            .tint(appearance.accent)
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
            .foregroundColor(appearance.accent)
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

// MARK: - The head of a page

/// What every page after the first opens with: one symbol on an accent tile, the title, and at most two
/// lines under it.
struct WelcomeHeader: View {
    @Environment(\.appearance) private var appearance

    let systemImage: String
    let title: String
    var text: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            AccentIconChip(systemImage: systemImage, size: 64)
                .shadow(color: appearance.accent.opacity(0.35), radius: 14, y: 6)
                .padding(.bottom, 10)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let text {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// The filled card every welcome page puts its rows on: a surface with a hairline edge, not glass (on
/// this plain ground clear glass draws no surface in the light themes). Selected, it wears the accent.
struct WelcomeCardSurface: View {
    @Environment(\.appearance) private var appearance

    var selected = false

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(selected ? appearance.accent.opacity(0.16) : Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? appearance.accent : Color.primary.opacity(0.08), lineWidth: selected ? 2 : 1)
            )
    }
}

// MARK: - Location and Notifications

#if HAS_ADHAN
/// The two permissions as two rows with their status (PermissionsSheet.swift, `PermissionCards`) over ONE
/// button that walks them in turn: Allow Location, then Allow Notifications, then Continue. Each tap
/// raises one system prompt, never both at once (Abu, 2026-10-19). Skip moves on and leaves whatever is
/// unanswered that way: the Adhan tab's own cards (`AdhanPermissionSection`) offer it from there.
struct WelcomePermissionsPage: View {
    @StateObject private var asker = PermissionAsker()
    /// Asked on this page already. A question the system would not put (Allow Notifications off in the
    /// app, a headless run) is not offered twice: the button moves on.
    @State private var askedLocation = false
    @State private var askedNotifications = false

    let onFinished: () -> Void

    private enum Step {
        case location, notifications, done
    }

    private var step: Step {
        if asker.locationUndetermined, !askedLocation { return .location }
        if asker.notificationsUndetermined, !askedNotifications { return .notifications }
        return .done
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    WelcomeHeader(systemImage: "mappin.and.ellipse",
                                  title: String(localized: "Prayer times for where you are"),
                                  text: String(localized: "Location finds today's times. Notifications call you to them."))
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
                primaryTitle: primaryTitle,
                primaryBusy: asker.asking,
                primaryIdentifier: primaryIdentifier,
                primaryAction: primaryAction,
                secondaryTitle: String(localized: "Skip"),
                secondaryIdentifier: "welcomeSkip",
                secondaryAction: onFinished
            )
            .frame(maxWidth: 560)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .task { await asker.refresh() }
    }

    private var primaryTitle: String {
        switch step {
        case .location: return String(localized: "Allow Location")
        case .notifications: return String(localized: "Allow Notifications")
        case .done: return String(localized: "Continue")
        }
    }

    /// The two asks keep the identifiers their own buttons had; Continue is found by its label.
    private var primaryIdentifier: String? {
        switch step {
        case .location: return "permissionsAllowLocation"
        case .notifications: return "permissionsAllowNotifications"
        case .done: return nil
        }
    }

    private func primaryAction() {
        switch step {
        case .location: asker.askLocation { askedLocation = true }
        case .notifications: asker.askNotifications { askedNotifications = true }
        case .done: onFinished()
        }
    }
}
#endif

// MARK: - Simple or Full

/// How much of the app to show (Docs/Product/Simple Mode Guide.md, Splash): two cards, Full preselected.
/// The choice is written by the splash when its page ends, not here. Al-Islam only: the companions skip
/// the question at the first launch and keep Full (Abu, 2026-10-14); Simple Mode is still in their
/// Settings.
struct WelcomeModePage: View {
    private let settings = Settings.shared
    @Environment(\.appearance) private var appearance

    @Binding var choosesSimple: Bool

    var body: some View {
        VStack(spacing: 22) {
            WelcomeHeader(systemImage: "slider.horizontal.3",
                          title: String(localized: "Simple or Full?"),
                          text: String(localized: "You can change it any time in Settings."))

            VStack(spacing: 10) {
                modeCard(simple: true, title: String(localized: "Simple"),
                         text: String(localized: "The essentials. Extras stay tucked away."),
                         systemImage: "rectangle.compress.vertical")
                modeCard(simple: false, title: String(localized: "Full"),
                         text: String(localized: "Every tool and detail, right on screen."),
                         systemImage: "rectangle.expand.vertical")
            }
        }
    }

    private func modeCard(simple: Bool, title: String, text: String, systemImage: String) -> some View {
        let selected = choosesSimple == simple
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) { choosesSimple = simple }
        } label: {
            HStack(spacing: 14) {
                AccentIconChip(systemImage: systemImage, size: 40)
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
                // The column takes the row's width itself: beside a Spacer it gave up a line's worth.
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selected ? appearance.accent : Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(WelcomeCardSurface(selected: selected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(text)")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(simple ? "splashChoiceSimple" : "splashChoiceFull")
    }
}
#endif
