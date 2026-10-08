import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Holds the screen awake while recitation is FOLLOWING ALONG on screen - the moving ayah highlight.
///
/// Abu, 2026-10-07: "play from ayah if it highlights make it where the app doesnt turn off which it
/// should already be but apparently its not". It never was: nothing in the app had ever touched
/// `isIdleTimerDisabled`, so the display slept on its own schedule mid-recitation and the highlight the
/// user was reading along with went dark.
///
/// WHY NOT SIMPLY "WHILE PLAYING". Recitation is deliberately a background-audio feature (the lock
/// screen controls, CarPlay, the Now Playing bar): someone listening with the phone in a pocket must
/// still get a sleeping screen, or the battery pays for audio it is not showing. The lock is keyed to
/// the HIGHLIGHT instead, which is the only state where the screen is carrying something that moves and
/// cannot be scrolled back to. Pausing, ending, or leaving the tracked ayah drops it.
///
/// WHY A COUNTED LOCK. Two readers can be mounted over one playback (the surah list and the page-mode
/// pager, which swap as the user folds the chrome), and iOS has ONE flag per app. A plain `= false` from
/// whichever view disappeared last would clear a lock the other still needs, so holders are counted and
/// the flag only falls when the last one lets go.
///
/// WHY THE FLAG IS WRITTEN AND NOT TRUSTED. `isIdleTimerDisabled` is a property of the WINDOW SCENE's
/// application object and iOS resets it across background transitions, so the count is the truth and the
/// flag is re-asserted from it (see `reassert`) rather than read back.
@MainActor
final class ScreenWakeLock {
    static let shared = ScreenWakeLock()
    private init() {}

    /// How many views currently want the screen up. Never negative: an unbalanced release is a bug in a
    /// caller, and clamping keeps it from stranding the flag ON for the rest of the session.
    private var holders = 0

    func acquire() {
        holders += 1
        apply()
    }

    func release() {
        guard holders > 0 else { return }
        holders -= 1
        apply()
    }

    /// Re-applies the flag from the count. Called on foregrounding, where iOS may have cleared it while
    /// the app was away but our holders are all still mounted.
    func reassert() { apply() }

    private func apply() {
        // iOS only: `isIdleTimerDisabled` does not exist on watchOS, and on the Mac (Designed for iPad)
        // display sleep belongs to the system's own power settings, which an app should not hold open.
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = holders > 0
        #endif
    }
}

/// Keeps the screen awake while `active` is true, balanced across the view's lifetime.
///
/// Attach to the view that OWNS the on-screen highlight. It takes the lock when `active` turns true,
/// gives it back when it turns false, and - the part an `onChange` alone gets wrong - also gives it back
/// when the view disappears mid-recitation (navigating out of the reader while audio continues in the
/// background, which is exactly when the screen SHOULD be allowed to sleep again).
private struct KeepScreenAwake: ViewModifier {
    let active: Bool

    /// Whether THIS modifier instance is holding the lock, so appear/disappear and value changes can
    /// never double-acquire or double-release.
    @State private var holding = false

    func body(content: Content) -> some View {
        content
            .onAppear { sync(to: active) }
            .onDisappear { sync(to: false) }
            .onChange(of: active) { sync(to: $0) }
    }

    private func sync(to wanted: Bool) {
        guard wanted != holding else { return }
        holding = wanted
        if wanted {
            ScreenWakeLock.shared.acquire()
        } else {
            ScreenWakeLock.shared.release()
        }
    }
}

extension View {
    /// Holds the display awake while `active` - for a recitation highlight the user is reading along
    /// with. See `ScreenWakeLock` for why this is keyed to the highlight and not to playback.
    func keepScreenAwake(while active: Bool) -> some View {
        modifier(KeepScreenAwake(active: active))
    }
}
