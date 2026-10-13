import UIKit

/// iPadOS 26's floating tab bar locks the main thread for good when a second Dynamic Type change lands
/// while its re-layout from the first is still animating (under a second apart): UIKit's
/// `_rebuildTabModelAnimated` -> `_updateTabBarPaginationAnimated` -> `layoutBelowIfNeeded` never
/// returns and the process sits at 100% CPU until it is force-quit (sampled 2026-10-13, no app frame on
/// the stack). The stress walk's size flips found it; `simctl ui content_size` back to back reproduced
/// it with the reader open, so a quick drag of Control Center's text size slider, which posts a change
/// per notch, is enough on an iPad.
///
/// The loop needs a change to land while the bar's selection animation is running, whatever started
/// that animation: the bar's own rebuild for a previous size change, or a tab switch (a deep link to a
/// tab, then one change 0.4 s later, hung the same way with a single change). This keeps every window
/// on a managed override of the category and moves it at most once per `settle` seconds after the bar
/// last animated: the first change of a burst lands at once, the rest land together once the slider
/// rests, and a change right after a tab switch waits for that switch to settle. iPad only (the
/// iPhone's bar has no such loop: the same flips in hundreds of walks never hung it), iOS 18 and later
/// (the floating bar). Everything under the window follows the override, so the app reads one size,
/// a beat late during a drag.
///
/// It also never moves the category under an alert. A bare trait change (what this override is) under
/// UIKit's alert traps in its text field layout: the reader's Go to Page / Go to Juz prompt, an `.alert`
/// with a TextField, threw `NSRangeException` in `-[_UIFlowLayoutInfo setSizes:forItemsAtIndexPaths:]`
/// under `UIAlertController viewDidLayoutSubviews` (2026-10-13: the stress walk's flips, a change held
/// here and released with the prompt up, a system change while it presented). So a change waits while
/// any alert is up and lands once it is gone. The iPhone has no override, but a system change landing
/// while the prompt presents traps there too, so the prompt calls `holdForAlert()` first.
@MainActor
enum DynamicTypeCoalescer {
    /// Longer than the bar's animations, with margin: 0.8 s between two changes hung, 1.4 s did not; a
    /// change 1.65 s after a tab switch that followed a change by 0.7 s, with a sheet up, hung too (the
    /// two animations chained), so 1.5 s was not enough (2026-10-13). A single change still lands at once.
    static let settle: TimeInterval = 3

    private static var shown: UIContentSizeCategory?
    /// When the bar last started an animation: a category move, or a tab selection change.
    private static var lastBarAnimation = Date.distantPast
    private static var pending: UIContentSizeCategory?
    private static var releaseTask: Task<Void, Never>?
    private static var installed = false
    /// The windows `holdForAlert()` pinned where the coalescer does not run, and the task that lets
    /// them go.
    private static var alertPinned: [UIWindow] = []
    private static var alertHoldTask: Task<Void, Never>?

    static var isActive: Bool {
        guard #available(iOS 18.0, *) else { return false }
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Call once at launch (AppDelegate). Harmless where it does not apply.
    static func install() {
        guard isActive, !installed else { return }
        installed = true
        let center = NotificationCenter.default
        center.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { note in
            let new = note.userInfo?[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory
            MainActor.assumeIsolated { request(new ?? UIApplication.shared.preferredContentSizeCategory) }
        }
        // A window that arrives later (a second scene, the banner window) joins the managed override.
        center.addObserver(forName: UIWindow.didBecomeKeyNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { pinWindows() }
        }
        pinWindows()
    }

    /// The tab selection changed (MainTabView): the bar animates, and a category change inside that
    /// animation is the hang, so the next one waits `settle` seconds from here.
    static func noteTabSelectionChanged() {
        guard isActive else { return }
        lastBarAnimation = Date()
        if pending != nil { request(pending!) }
    }

    /// A text-entry alert is about to come up (the reader's Go to Page / Go to Juz prompt). Where the
    /// coalescer runs (the iPad) the managed override already waits for the alert. Elsewhere every
    /// window is pinned to the category it shows now, so a system change cannot reach the alert, and
    /// let go once the alert has come and gone: the windows then follow the system again, the held
    /// change landing with no alert up.
    static func holdForAlert() {
        guard !isActive, #available(iOS 17.0, *) else { return }
        if alertPinned.isEmpty {
            for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
                for window in scene.windows where !window.traitOverrides.contains(UITraitPreferredContentSizeCategory.self) {
                    window.traitOverrides.preferredContentSizeCategory = window.traitCollection.preferredContentSizeCategory
                    alertPinned.append(window)
                }
            }
        }
        alertHoldTask?.cancel()
        alertHoldTask = Task { @MainActor in
            // Up to 3 s for the alert to arrive, then for as long as it is up.
            var waited = 0
            while !Task.isCancelled, !alertIsUp, waited < 6 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                waited += 1
            }
            while !Task.isCancelled, alertIsUp {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            guard !Task.isCancelled else { return }
            for window in alertPinned {
                window.traitOverrides.remove(UITraitPreferredContentSizeCategory.self)
            }
            alertPinned = []
        }
    }

    /// A new category from the system (or the stress walk's flips): applied now when the bar last
    /// animated `settle` seconds ago or more and no alert is up, else held until the burst (or the tab
    /// switch) rests and the alert is gone.
    static func request(_ category: UIContentSizeCategory) {
        guard isActive else { return }
        if Date().timeIntervalSince(lastBarAnimation) >= settle, pending == nil, !alertIsUp {
            apply(category)
            return
        }
        pending = category
        releaseTask?.cancel()
        releaseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(settle * 1_000_000_000))
            // An alert keeps it until the alert is gone (dismissal animation included).
            while !Task.isCancelled, alertIsUp {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            guard !Task.isCancelled, let category = pending else { return }
            pending = nil
            apply(category)
        }
    }

    private static func apply(_ category: UIContentSizeCategory) {
        shown = category
        lastBarAnimation = Date()
        pinWindows()
    }

    /// An alert (SwiftUI's `.alert` and `.confirmationDialog` are `UIAlertController`s) presented in
    /// any window, on its way in or out included: the category must not move under it.
    static var alertIsUp: Bool {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).contains { window in
            var controller = window.rootViewController?.presentedViewController
            while let current = controller {
                if current is UIAlertController { return true }
                controller = current.presentedViewController
            }
            return false
        }
    }

    private static func pinWindows() {
        guard isActive, #available(iOS 17.0, *) else { return }
        let category = shown ?? UIApplication.shared.preferredContentSizeCategory
        shown = category
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows
            where !window.traitOverrides.contains(UITraitPreferredContentSizeCategory.self)
                || window.traitOverrides.preferredContentSizeCategory != category {
                window.traitOverrides.preferredContentSizeCategory = category
            }
        }
    }
}
