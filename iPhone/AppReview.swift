import Foundation
#if os(iOS)
import StoreKit
import SwiftUI
import UIKit
#endif

// App Store review prompting, tuned for the most and the happiest reviews Apple's rules allow.
//
// How the system prompt behaves, and what follows from it:
//   - iOS shows it at most three times per app per 365 days and silently swallows every other call.
//     So calls are free: keep asking on a paced cooldown and let StoreKit decide which ones show.
//     There is deliberately no yearly cap here; Apple's is the only one that matters.
//   - The app cannot see the star rating or filter who gets to review (and must not try: custom
//     review prompts and filtered feedback are against the App Store rules). The one legitimate
//     lever is WHEN the prompt appears, so every rule below is about picking the moment:
//     right after something went well, never in the middle of a task, never after something failed.
//
// This file is meant to be identical in every app. An app only reports its own moments:
//
//     AppReviewManager.shared.celebrate(.big)    // finished something satisfying, and the screen is at rest
//     AppReviewManager.shared.bank(.big)         // same, but the user is still busy: ask at the next pause
//     AppReviewManager.shared.notePause()        // a natural break: nothing in progress
//     AppReviewManager.shared.noteSetback()      // an error, a failure or a loss: do not ask now
//
// The top half is Foundation-only so the rules can be unit tested from the command line
// (Scripts/tests/run_swift_tests.sh).

// MARK: - Tuning

/// Every number that shapes the prompt, in one place.
enum AppReviewPolicy {
    /// Minimum spacing between asks. Short enough to use Apple's three yearly prompts while the user
    /// is still around, long enough that someone who tapped "Not Now" is not asked again next week.
    static let cooldown: TimeInterval = 30 * 86_400

    /// A big win (a finished trial, a new high score, a successful scan) is its own proof of
    /// engagement, so it only needs this much foreground use behind it. Even a first session counts.
    static let bigWinUsage: TimeInterval = 60
    /// A small win (a finished translation, a shared image) needs more use behind it...
    static let smallWinUsage: TimeInterval = 120
    /// ...and either a second small win in the same cycle...
    static let smallWinsNeeded = 2
    /// ...or a user who has come back on a second day.
    static let returningDays = 2

    /// With no win at all, a returning user is asked at a pause after this much use...
    static let fallbackUsage: TimeInterval = 180
    static let fallbackSessions = 2
    /// ...and a first-visit user after this much.
    static let fallbackFirstVisitUsage: TimeInterval = 300

    /// How long a banked win stays warm while it waits for a pause.
    static let winFreshness: TimeInterval = 600

    /// A loss or a user slip: do not ask on its heels.
    static let minorMute: TimeInterval = 180
    /// The app failed the user (an error, a failed scan): leave them alone for a while.
    static let majorMute: TimeInterval = 1_800
    /// This many failures inside a day means a bad day with the app: stay quiet for a full one.
    static let repeatedMajorCount = 3
    static let repeatedMajorMute: TimeInterval = 86_400

    /// Users of the old ask-once-ever version become eligible again this long after updating.
    static let legacyReaskDelay: TimeInterval = 7 * 86_400

    /// Time away that makes the next foreground a new session.
    static let sessionGap: TimeInterval = 1_800
    /// Delay between a moment and the prompt, so the win's own animation lands first.
    static let beat: TimeInterval = 1.2
    /// Longer settle time when the moment is coming back into the app.
    static let returnBeat: TimeInterval = 2

    /// How a finished quiz or drill reads as a moment: 80% or better on a real run is a big win,
    /// under half is a setback, and anything else (including a run too short to judge) is a pause.
    static func outcome(correct: Int, attempts: Int) -> AppReviewRunOutcome {
        guard attempts >= 5 else { return .pause }
        if correct * 5 >= attempts * 4 { return .bigWin }
        if correct * 2 < attempts { return .setback }
        return .pause
    }
}

enum AppReviewRunOutcome {
    case bigWin
    case pause
    case setback
}

enum AppReviewWin: String {
    /// A completed core action: the app did its everyday job.
    case small
    /// A moment the user is proud of or delighted by.
    case big
}

enum AppReviewSetback {
    /// A loss or a user slip.
    case minor
    /// The app failed the user.
    case major
}

// MARK: - Rules

/// The review prompt's memory and its rules. A "cycle" is the stretch since the last ask.
struct AppReviewLedger: Equatable {
    var cycleUsage: TimeInterval = 0
    var cycleSessions = 0
    var cycleSmallWins = 0
    /// Distinct calendar days the app has been used, lifetime.
    var activeDays = 0
    /// The last active day as yyyymmdd.
    var lastActiveDay = 0
    var askDates: [TimeInterval] = []
    var mutedUntil: TimeInterval = 0
    var majorSetbacks: [TimeInterval] = []
    var bankedWin: AppReviewWin?
    var bankedAt: TimeInterval = 0

    mutating func noteForeground(isNewSession: Bool, now: Date, calendar: Calendar = .current) {
        if isNewSession { cycleSessions += 1 }

        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let today = (parts.year ?? 0) * 10_000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
        if today != lastActiveDay {
            lastActiveDay = today
            activeDays += 1
        }
    }

    mutating func noteUsage(_ seconds: TimeInterval) {
        guard seconds > 0 else { return }
        cycleUsage += seconds
    }

    mutating func noteWin(_ win: AppReviewWin, now: Date) {
        let time = now.timeIntervalSince1970
        if win == .small {
            cycleSmallWins += 1
            // A small win never downgrades a big one that is still warm.
            if bankedWin == .big, time - bankedAt <= AppReviewPolicy.winFreshness { return }
        }
        bankedWin = win
        bankedAt = time
    }

    mutating func noteSetback(_ setback: AppReviewSetback, now: Date) {
        let time = now.timeIntervalSince1970
        // The good mood a banked win stood for is gone.
        bankedWin = nil
        bankedAt = 0

        var mute = AppReviewPolicy.minorMute
        if setback == .major {
            majorSetbacks = majorSetbacks.filter { time - $0 < 86_400 } + [time]
            mute = majorSetbacks.count >= AppReviewPolicy.repeatedMajorCount
                ? AppReviewPolicy.repeatedMajorMute
                : AppReviewPolicy.majorMute
        }
        mutedUntil = max(mutedUntil, time + mute)
    }

    /// Whether to ask right now. `atPause` is true at a natural break, where the no-win fallback may
    /// also fire; at any other moment only a warm win can justify the prompt.
    func shouldAsk(atPause: Bool, now: Date) -> Bool {
        let time = now.timeIntervalSince1970
        guard time >= mutedUntil else { return false }
        if let last = askDates.last, time - last < AppReviewPolicy.cooldown { return false }

        if let win = bankedWin, time - bankedAt <= AppReviewPolicy.winFreshness {
            switch win {
            case .big:
                if cycleUsage >= AppReviewPolicy.bigWinUsage { return true }
            case .small:
                let engaged = cycleSmallWins >= AppReviewPolicy.smallWinsNeeded
                    || activeDays >= AppReviewPolicy.returningDays
                if engaged, cycleUsage >= AppReviewPolicy.smallWinUsage { return true }
            }
        }

        guard atPause else { return false }
        if cycleUsage >= AppReviewPolicy.fallbackFirstVisitUsage { return true }
        return cycleUsage >= AppReviewPolicy.fallbackUsage && cycleSessions >= AppReviewPolicy.fallbackSessions
    }

    /// Whether iOS actually showed the prompt is unknowable, so the call itself is the ask:
    /// it starts the cooldown and a fresh cycle.
    mutating func noteAsked(now: Date) {
        askDates.append(now.timeIntervalSince1970)
        cycleUsage = 0
        cycleSessions = 0
        cycleSmallWins = 0
        bankedWin = nil
        bankedAt = 0
    }
}

// MARK: - Storage

extension AppReviewLedger {
    // The first three keys are the ones earlier versions already wrote, so users keep their progress.
    private enum Key {
        static let cycleUsage = "timeSpent"
        static let cycleSessions = "appReviewSessionCount"
        static let askDates = "appReviewAskDates"
        static let cycleSmallWins = "appReviewSmallWins"
        static let activeDays = "appReviewActiveDays"
        static let lastActiveDay = "appReviewLastActiveDay"
        static let mutedUntil = "appReviewMutedUntil"
        static let majorSetbacks = "appReviewMajorSetbacks"
        static let bankedWin = "appReviewBankedWin"
        static let bankedAt = "appReviewBankedAt"
        /// The oldest version asked once per install, ever, then flipped this to false.
        static let legacyLatch = "shouldShowRateAlert"
    }

    static func load(from defaults: UserDefaults, now: Date) -> AppReviewLedger {
        let time = now.timeIntervalSince1970
        var ledger = AppReviewLedger()
        ledger.cycleUsage = defaults.double(forKey: Key.cycleUsage)
        ledger.cycleSessions = defaults.integer(forKey: Key.cycleSessions)
        ledger.cycleSmallWins = defaults.integer(forKey: Key.cycleSmallWins)
        ledger.activeDays = defaults.integer(forKey: Key.activeDays)
        ledger.lastActiveDay = defaults.integer(forKey: Key.lastActiveDay)
        // No real mute runs longer than a day, so one that does came from a wrong device clock.
        ledger.mutedUntil = min(defaults.double(forKey: Key.mutedUntil), time + AppReviewPolicy.repeatedMajorMute)
        ledger.majorSetbacks = defaults.array(forKey: Key.majorSetbacks) as? [Double] ?? []
        ledger.bankedWin = defaults.string(forKey: Key.bankedWin).flatMap(AppReviewWin.init(rawValue:))
        ledger.bankedAt = defaults.double(forKey: Key.bankedAt)

        if let stored = defaults.array(forKey: Key.askDates) as? [Double] {
            // An ask stamped in the future (the device clock was wrong) would block asking until
            // the clock caught up, so treat it as having just happened.
            ledger.askDates = stored.map { min($0, time) }
        } else if defaults.object(forKey: Key.legacyLatch) != nil, !defaults.bool(forKey: Key.legacyLatch) {
            // The old version asked this user once without recording when. Seed the log so they are
            // eligible again a week of calendar time from now: not never (the old behavior) and not
            // instantly (they may have been asked days before updating).
            ledger.askDates = [time - (AppReviewPolicy.cooldown - AppReviewPolicy.legacyReaskDelay)]
            ledger.cycleUsage = 0
            ledger.cycleSessions = 0
        }
        return ledger
    }

    func save(to defaults: UserDefaults) {
        defaults.set(cycleUsage, forKey: Key.cycleUsage)
        defaults.set(cycleSessions, forKey: Key.cycleSessions)
        defaults.set(cycleSmallWins, forKey: Key.cycleSmallWins)
        defaults.set(activeDays, forKey: Key.activeDays)
        defaults.set(lastActiveDay, forKey: Key.lastActiveDay)
        defaults.set(askDates, forKey: Key.askDates)
        defaults.set(mutedUntil, forKey: Key.mutedUntil)
        defaults.set(majorSetbacks, forKey: Key.majorSetbacks)
        defaults.set(bankedWin?.rawValue, forKey: Key.bankedWin)
        defaults.set(bankedAt, forKey: Key.bankedAt)
    }
}

#if os(iOS)

// MARK: - Manager

/// Feeds the ledger from the app's lifecycle and shows the system prompt when the rules say so.
/// Every entry point is safe to call from any thread; the work itself runs on the main actor.
final class AppReviewManager: @unchecked Sendable {
    static let shared = AppReviewManager()

    /// Return false while a splash, onboarding or paywall covers the app. Set once at launch.
    var isInterfaceReady: @MainActor () -> Bool = { true }

    private let defaults = UserDefaults.standard
    private var ledger: AppReviewLedger
    private var started = false
    private var hasBeenActive = false
    /// Start of the foreground stretch not yet added to the ledger.
    private var stretchStart: Date?
    private var lastBackgroundAt: Date?
    private var pendingAsk: Task<Void, Never>?
    private var pendingAllowsFallback = false

    private init() {
        ledger = AppReviewLedger.load(from: defaults, now: Date())
        // Written straight back so a seeded legacy ask date is fixed now, not re-derived each launch.
        ledger.save(to: defaults)
    }

    // MARK: What the app reports

    /// Begins tracking. Call once the real interface is on screen (`.appReviewPrompt()` does).
    func start() {
        onMain { $0.beginTracking() }
    }

    /// Something went well and the screen is at rest (a results screen, a finished share).
    /// Asks after a short beat if the rules allow.
    func celebrate(_ win: AppReviewWin) {
        onMain { $0.record(win, askNow: true) }
    }

    /// Something went well but the user is still busy or about to leave (an achievement mid-drill,
    /// a copied image). Remembered, and asked about at the next pause or return to the app.
    func bank(_ win: AppReviewWin) {
        onMain { $0.record(win, askNow: false) }
    }

    /// A natural break with nothing in progress (a tab switch, a closed result).
    func notePause() {
        onMain { $0.scheduleAsk(allowFallback: true, after: AppReviewPolicy.beat) }
    }

    /// Something went badly. Cancels any ask in flight and keeps quiet for a while.
    func noteSetback(_ setback: AppReviewSetback = .minor) {
        onMain { $0.record(setback) }
    }

    /// A quiz or drill just ended and its results are on screen. Scores the run with
    /// `AppReviewPolicy.outcome` and reports the matching moment.
    func noteFinishedRun(correct: Int, attempts: Int) {
        switch AppReviewPolicy.outcome(correct: correct, attempts: attempts) {
        case .bigWin: celebrate(.big)
        case .pause: notePause()
        case .setback: noteSetback(.minor)
        }
    }

    /// The name the first version of this manager used for `celebrate(.big)`.
    func requestAtMomentOfDelight() {
        celebrate(.big)
    }

    /// For a "Leave a Review" button in an app that has no App Store id to link to yet. Skips the
    /// rules because the user asked outright. An app that has an id should open its write-review
    /// link instead: StoreKit may show nothing here once its yearly quota is spent.
    func requestManually() {
        onMain { $0.ask() }
    }

    private func onMain(_ work: @escaping @MainActor (AppReviewManager) -> Void) {
        Task { @MainActor in work(self) }
    }

    // MARK: Lifecycle

    @MainActor
    private func beginTracking() {
        guard !started else { return }
        started = true

        // Each observer hops with its own Task (not `onMain`) so this compiles the same whether the
        // app's default isolation is nonisolated or the main actor.
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.becameActive() }
        }
        center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.resignedActive() }
        }
        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.lastBackgroundAt = Date() }
        }

        if UIApplication.shared.applicationState == .active {
            becameActive()
        }
    }

    @MainActor
    private func becameActive() {
        guard stretchStart == nil else { return }
        let now = Date()
        stretchStart = now

        // The first activation of a launch is a new session; later ones only after real time away.
        // Brief interruptions (Control Center, a system alert, the review prompt itself) are not.
        var isNewSession = !hasBeenActive
        if let lastBackgroundAt, now.timeIntervalSince(lastBackgroundAt) >= AppReviewPolicy.sessionGap {
            isNewSession = true
        }
        hasBeenActive = true
        lastBackgroundAt = nil

        ledger.noteForeground(isNewSession: isNewSession, now: now)
        ledger.save(to: defaults)

        // Coming back with a win still warm (copied a result, pasted it elsewhere, returned) is a
        // good moment. With no warm win this does nothing: arriving is not a pause.
        scheduleAsk(allowFallback: false, after: AppReviewPolicy.returnBeat)
    }

    @MainActor
    private func resignedActive() {
        pendingAsk?.cancel()
        pendingAsk = nil
        bankUsage()
        stretchStart = nil
    }

    /// Moves the foreground time since the last call into the ledger.
    @MainActor
    private func bankUsage() {
        guard let start = stretchStart else { return }
        let now = Date()
        ledger.noteUsage(now.timeIntervalSince(start))
        stretchStart = now
        ledger.save(to: defaults)
    }

    // MARK: Asking

    @MainActor
    private func record(_ win: AppReviewWin, askNow: Bool) {
        ledger.noteWin(win, now: Date())
        ledger.save(to: defaults)
        if askNow {
            scheduleAsk(allowFallback: false, after: AppReviewPolicy.beat)
        }
    }

    @MainActor
    private func record(_ setback: AppReviewSetback) {
        pendingAsk?.cancel()
        pendingAsk = nil
        ledger.noteSetback(setback, now: Date())
        ledger.save(to: defaults)
    }

    /// Decides after `delay`, not now: the beat lets the moment's own animation land, and lets a win
    /// reported in the same breath as a pause be on the books by the time the rules are checked.
    @MainActor
    private func scheduleAsk(allowFallback: Bool, after delay: TimeInterval) {
        // A pause already waiting keeps its fallback rights when another moment lands on top of it.
        let fallback = allowFallback || (pendingAsk != nil && pendingAllowsFallback)
        pendingAsk?.cancel()
        pendingAllowsFallback = fallback
        pendingAsk = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            self.pendingAsk = nil
            self.askIfAppropriate(allowFallback: fallback)
        }
    }

    @MainActor
    private func askIfAppropriate(allowFallback: Bool) {
        bankUsage()
        let now = Date()
        guard ledger.shouldAsk(atPause: allowFallback, now: now) else { return }

        // The prompt must never land on a splash or onboarding. If the interface is not ready the
        // moment is simply skipped: nothing is spent, and the next one asks.
        guard isInterfaceReady() else { return }
        ask()
    }

    /// Shows the system prompt and starts a new cycle. Does nothing without a foreground scene,
    /// which StoreKit needs; in that case nothing is spent either.
    @MainActor
    private func ask() {
        guard let scene = activeScene else { return }

        if #available(iOS 16.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }

        ledger.noteAsked(now: Date())
        ledger.save(to: defaults)
    }

    @MainActor
    private var activeScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}

extension View {
    /// Starts review-prompt tracking when this view appears. Attach it to the app's real interface
    /// (not the splash), so time spent on launch and onboarding screens is not counted as use.
    func appReviewPrompt() -> some View {
        onAppear { AppReviewManager.shared.start() }
    }
}

#endif
