#if os(iOS)
import StoreKit
import SwiftUI

// MARK: - Review request manager

/// Engagement-gated App Store review prompting, tuned to how the system prompt actually behaves:
/// iOS shows at most THREE prompts per app per 365 days and silently swallows every call beyond that,
/// so the right strategy is to keep asking - at a moment of delight or after real usage - on a paced
/// cooldown, and let StoreKit decide which asks become visible prompts. The old one-shot latch
/// (`shouldShowRateAlert`) asked once per install, ever; it is migrated below, never read again.
final class AppReviewManager {
    static let shared = AppReviewManager()

    /// Fresh foreground seconds required since the last ask before the usage-based ask fires.
    private static let usageThreshold: TimeInterval = 180
    /// Lighter time bar when the ask rides a delight moment (e.g. every prayer of the day just got
    /// marked prayed) - the moment itself is the evidence of engagement.
    private static let delightUsageThreshold: TimeInterval = 45
    /// Return visits required since the last ask: never prompt during the session that just asked,
    /// and never during a user's first-ever session.
    private static let sessionThreshold = 2
    /// Spacing between asks. 45 days paces the year's three visible prompts across the year instead
    /// of burning all three in the first weeks after an update.
    private static let cooldown: TimeInterval = 45 * 86_400
    /// Apple's rolling display quota. Calls past it are free but pointless - skip them.
    private static let maxAsksPerYear = 3

    private let defaults = UserDefaults.standard

    // The cycle counters deliberately reuse the legacy keys: users mid-bank keep their progress.
    private enum Key {
        static let cycleTime = "timeSpent"
        static let cycleSessions = "appReviewSessionCount"
        static let askDates = "appReviewAskDates"
        static let legacyLatch = "shouldShowRateAlert"
    }

    private var retryTask: Task<Void, Never>?

    private init() {
        migrateLegacyLatch()
    }

    /// The old system flipped `shouldShowRateAlert` to false after its single lifetime ask, without
    /// recording when. Seed the ask log as if that ask happened most-of-a-cooldown ago: long-time users
    /// become eligible again about a week of fresh use into this version - neither never again (the old
    /// behavior) nor instantly (which could re-ask someone prompted days before updating).
    private func migrateLegacyLatch() {
        guard defaults.object(forKey: Key.askDates) == nil else { return }
        guard defaults.object(forKey: Key.legacyLatch) != nil, !defaults.bool(forKey: Key.legacyLatch) else { return }

        let seeded = Date().addingTimeInterval(-(Self.cooldown - 7 * 86_400))
        askDates = [seeded.timeIntervalSince1970]
        defaults.set(0.0, forKey: Key.cycleTime)
        defaults.set(0, forKey: Key.cycleSessions)
    }

    private var askDates: [Double] {
        get { defaults.array(forKey: Key.askDates) as? [Double] ?? [] }
        set { defaults.set(Array(newValue.suffix(6)), forKey: Key.askDates) }
    }

    private var cycleTime: TimeInterval {
        get { defaults.double(forKey: Key.cycleTime) }
        set { defaults.set(newValue, forKey: Key.cycleTime) }
    }

    private var cycleSessions: Int {
        get { defaults.integer(forKey: Key.cycleSessions) }
        set { defaults.set(newValue, forKey: Key.cycleSessions) }
    }

    // MARK: Engagement feed (driven by the view modifier)

    func noteSessionStart() {
        cycleSessions += 1
    }

    func accumulateForegroundTime(_ seconds: TimeInterval) {
        guard seconds > 0 else { return }
        cycleTime += seconds
    }

    /// Seconds of foreground use still needed before the usage-based ask becomes eligible.
    var timeUntilUsageAsk: TimeInterval {
        max(Self.usageThreshold - cycleTime, 0)
    }

    // MARK: Asking

    /// The usage-based ask: enough fresh foreground time has accumulated this cycle.
    @MainActor
    func requestAfterUsage() {
        request(minimumUsage: Self.usageThreshold)
    }

    /// The delight-moment ask - call this right after the user completes something satisfying
    /// (all five prayers marked prayed, a khatm finished, ...). Cheap to call; every gate re-checks here.
    @MainActor
    func requestAtMomentOfDelight() {
        request(minimumUsage: Self.delightUsageThreshold)
    }

    private func eligible(minimumUsage: TimeInterval) -> Bool {
        guard cycleSessions >= Self.sessionThreshold else { return false }
        guard cycleTime >= minimumUsage else { return false }

        let now = Date().timeIntervalSince1970
        if let last = askDates.last, now - last < Self.cooldown { return false }
        let yearWindow = askDates.filter { now - $0 < 365 * 86_400 }
        guard yearWindow.count < Self.maxAsksPerYear else { return false }

        return true
    }

    @MainActor
    private func request(minimumUsage: TimeInterval, attempt: Int = 0) {
        guard eligible(minimumUsage: minimumUsage) else { return }

        // Never while the launch/splash cover is still up, and never without a foreground-active scene
        // (StoreKit needs one). Both states are transient, so retry a few times instead of dropping the
        // ask - read the LIVE `AppReveal` mirror, NOT `@Environment(\.appRevealed)`: an escaping Task's
        // captured environment froze at capture time and silently suppressed the prompt all session.
        guard AppReveal.revealed, let windowScene = activeWindowScene else {
            guard attempt < 6 else { return }
            retryTask?.cancel()
            retryTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.request(minimumUsage: minimumUsage, attempt: attempt + 1) }
            }
            return
        }

        if #available(iOS 16.0, *) {
            AppStore.requestReview(in: windowScene)
        } else {
            SKStoreReviewController.requestReview(in: windowScene)
        }

        // Whether the system actually showed the prompt is unknowable; treat the call as the ask and
        // start the next cycle: fresh time, fresh sessions, full cooldown.
        askDates = askDates + [Date().timeIntervalSince1970]
        cycleTime = 0
        cycleSessions = 0
        retryTask?.cancel()
    }

    @MainActor
    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}

// MARK: - Lifecycle tracking

private struct AppReviewPromptModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    @State private var startTime: Date?
    @State private var usageTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                AppReviewManager.shared.noteSessionStart()
                startTracking()
            }
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onDisappear {
                usageTask?.cancel()
            }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            startTracking()
        case .background, .inactive:
            stopTracking()
        @unknown default:
            break
        }
    }

    // Opens the active-time window and schedules the usage-based ask for when the cycle's remaining
    // foreground time will have elapsed.
    private func startTracking() {
        startTime = Date()

        let remaining = AppReviewManager.shared.timeUntilUsageAsk
        usageTask?.cancel()
        usageTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))

            guard !Task.isCancelled else { return }
            await MainActor.run {
                AppReviewManager.shared.requestAfterUsage()
            }
        }
    }

    // Closes the window and banks this stretch of foreground time into the current cycle.
    private func stopTracking() {
        usageTask?.cancel()

        guard let startTime else { return }
        AppReviewManager.shared.accumulateForegroundTime(Date().timeIntervalSince(startTime))
        self.startTime = nil
    }
}

extension View {
    // Applies the app review prompt behavior to any view.
    func appReviewPrompt() -> some View {
        modifier(AppReviewPromptModifier())
    }
}
#endif
