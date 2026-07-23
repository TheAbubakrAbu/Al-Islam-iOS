#if os(iOS)
import StoreKit
import SwiftUI

private struct AppReviewPromptModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("timeSpent") private var timeSpent: Double = 0
    @AppStorage("shouldShowRateAlert") private var shouldShowRateAlert: Bool = true
    /// Foreground sessions seen. The prompt waits for a RETURN visit: asking a first-time user to rate
    /// the app three minutes into their first session is the wrong moment by definition.
    @AppStorage("appReviewSessionCount") private var sessionCount: Int = 0

    @State private var startTime: Date?
    @State private var reviewTask: Task<Void, Never>?

    private let requiredTimeInterval: TimeInterval = 180

    // Hooks the review-tracking lifecycle into the wrapped view.
    func body(content: Content) -> some View {
        content
            .onAppear {
                sessionCount += 1
                guard shouldShowRateAlert else { return }
                startTracking()
            }
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onDisappear {
                reviewTask?.cancel()
            }
    }

    // Starts or stops tracking as the app moves between active/inactive/background states.
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            guard shouldShowRateAlert else { return }
            startTracking()
        case .background, .inactive:
            stopTracking()
        @unknown default:
            break
        }
    }

    // Resets the active timer window and schedules the prompt once enough time is reached.
    private func startTracking() {
        startTime = Date()
        scheduleReviewPrompt()
    }

    // Stops the timer and accumulates this session's foreground time.
    private func stopTracking() {
        reviewTask?.cancel()

        guard let startTime else { return }
        timeSpent += Date().timeIntervalSince(startTime)
        self.startTime = nil
    }

    // Schedules a delayed review request based on remaining required usage time.
    private func scheduleReviewPrompt() {
        let remainingTime = max(requiredTimeInterval - timeSpent, 0)

        reviewTask?.cancel()
        reviewTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))

            guard !Task.isCancelled else { return }
            await MainActor.run {
                requestReview()
            }
        }
    }

    // Presents Apple's in-app review sheet once and then disables future prompts.
    private func requestReview() {
        guard shouldShowRateAlert else { return }
        // Not during the first session - the banked time makes them eligible on their return visit.
        guard sessionCount >= 2 else { return }
        // Never while the launch/splash cover is still up (a returning user with 3+ minutes banked used
        // to be eligible the instant the app became active - mid-launch animation). Retry shortly;
        // eligibility is already banked. Read the LIVE `AppReveal` mirror, NOT `@Environment(\.appRevealed)`:
        // this runs inside an escaping Task whose captured copy of `self` froze the environment value at
        // capture time - since every capture chain starts while the cover is still up, the old gate re-read
        // a stale `false` on every retry and silently suppressed the prompt for the whole session.
        guard AppReveal.revealed else {
            reviewTask?.cancel()
            reviewTask = Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { requestReview() }
            }
            return
        }
        guard let windowScene = activeWindowScene else { return }

        SKStoreReviewController.requestReview(in: windowScene)
        shouldShowRateAlert = false
        reviewTask?.cancel()
    }

    // Returns the currently foreground-active window scene used by StoreKit.
    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}

extension View {
    // Applies the app review prompt behavior to any view.
    func appReviewPrompt() -> some View {
        modifier(AppReviewPromptModifier())
    }
}
#endif
