import SwiftUI

// The window a floating banner lives in, shared by every banner the app raises (achievements,
// the playing adhan). Extracted from Achievements.swift when the adhan banner arrived, rather
// than copied: the two fixes below were each a live crash or a visible bug, and a second
// hand-rolled banner window would have had to rediscover them.

#if os(iOS)

/// Hosts a banner in its own `UIWindow`, above everything the app itself presents.
///
/// That is the whole reason a banner can be trusted: achievements are crossed from inside sheets
/// (the tasbih counter, the ayah bookmark sheet, the prayer nag dialog) and the adhan can start
/// while any screen at all is up. A root overlay renders UNDERNEATH a presented sheet, so the
/// banner would be invisible exactly when it fires. A window above `.alert` level always wins.
///
/// The window is created on demand and torn down when the banner goes away, so the app carries no
/// extra window in the ordinary case.
@MainActor
final class BannerWindow {
    private var window: PassthroughWindow?
    private let content: () -> AnyView

    /// - Parameter content: the banner's root view, built fresh each time the window is raised.
    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        self.content = { AnyView(content()) }
    }

    func present() {
        if let window {
            window.isHidden = false
            window.applyAppearance()
            return
        }

        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        else { return }

        // Its own window, so nothing from the app root's environment reaches it: inject the appearance
        // snapshot here too, or the banner's glass and accent would read a frozen default.
        let host = UIHostingController(rootView: content().appFontDesign().appearanceEnvironment())
        host.view.backgroundColor = .clear

        let window = PassthroughWindow(windowScene: scene)
        window.rootViewController = host
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1
        window.applyAppearance()
        window.isHidden = false
        self.window = window
    }

    func dismiss() {
        // Take the window OUT of the stored property before letting it deallocate. Releasing it
        // inside the `window = nil` assignment ran UIWindow dealloc - and the hosting view's
        // teardown - while the property's exclusive write access was still open; the teardown
        // re-entered `setInteractiveFrame`, whose read of `window` then trapped ("Simultaneous
        // accesses ... modification requires exclusive access", live crash on dismissing a
        // bookmark achievement's banner). The local keeps it alive until this scope ends, after
        // the write access has closed.
        let retiring = window
        window = nil
        retiring?.isHidden = true
    }

    /// The card reports its own frame so the window can pass every touch outside it straight
    /// through. Without this the window would swallow the whole screen: a SwiftUI hosting view
    /// answers `hitTest` for any point it covers, so "is the hit view the root view?" is not a
    /// usable test once the card carries gestures of its own.
    func setInteractiveFrame(_ frame: CGRect) {
        window?.interactiveFrame = frame
    }
}

private final class PassthroughWindow: UIWindow {
    var interactiveFrame: CGRect = .zero

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard interactiveFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }

    /// A separate window doesn't inherit the app's `preferredColorScheme`, so a user who has pinned
    /// the app to dark while the phone is light would get a light banner over a dark app.
    func applyAppearance() {
        switch Settings.shared.colorScheme {
        case .some(.dark):  overrideUserInterfaceStyle = .dark
        case .some(.light): overrideUserInterfaceStyle = .light
        default:            overrideUserInterfaceStyle = .unspecified
        }
    }
}

/// Publishes a banner card's on-screen rect to its hosting window, so everything outside the card
/// stays tappable. Attach to the card itself (`.background(BannerFrameReporter(...))`).
struct BannerFrameReporter: View {
    let report: (CGRect) -> Void

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { report(proxy.frame(in: .global)) }
                .onChange(of: proxy.frame(in: .global)) { frame in
                    report(frame)
                }
        }
    }
}

#endif
