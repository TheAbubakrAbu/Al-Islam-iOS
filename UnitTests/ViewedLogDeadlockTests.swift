import XCTest
@testable import iPhone

/// The Mac freeze of 2026-10-05 (`iPhone-2026-10-05-004500.ips`, and the `.hang` reports of 09-28
/// and 10-02): the main thread sat in `ViewedLog`'s `ioQueue.sync {}` while that queue's
/// `UserDefaults.set` waited for the main thread to deliver `didChangeNotification`.
///
/// These tests hold the deadlock's shape rather than its symptom. Each one installs a main-QUEUE
/// observer, which is the jaw that turns a background defaults write into a blocking hop to main,
/// and then runs the call sequence from a background thread while the main thread is parked in a
/// `runLoop` spin. If any of this log's writes goes back onto `ioQueue`, these time out.
@MainActor
final class ViewedLogDeadlockTests: XCTestCase {

    /// Runs `body` off-main and keeps the MAIN thread serving its run loop until it finishes, which
    /// is what a real app does. Fails rather than hanging the whole suite if `body` blocks.
    private func runOffMainWhileMainSpins(
        timeout: TimeInterval = 10,
        _ body: @escaping @Sendable () -> Void
    ) -> Bool {
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            body()
            done.signal()
        }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if done.wait(timeout: .now() + 0.01) == .success { return true }
            // Serve the main run loop: a main-queue observer can only be delivered here.
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
        return false
    }

    /// Installs the jaw: an observer that makes NotificationCenter deliver on main and BLOCK the
    /// posting thread until main drains it.
    private func withMainQueueDefaultsObserver(_ body: () -> Void) {
        let token = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { _ in }
        defer { NotificationCenter.default.removeObserver(token) }
        body()
    }

    /// `flush()` then `flushSynchronously()` is literally what backgrounding runs
    /// (`AppLifecycle.hadithScenePhaseChanged`, then `automaticSaveIfDue` ->
    /// `CloudSnapshot.capture` -> `Settings.flushAllPendingWrites`). Before the fix `flush()` left
    /// an uncancellable `UserDefaults.set` on `ioQueue` and `flushSynchronously` sat down to wait
    /// for it.
    func testBackgroundingSequenceDoesNotDeadlock() {
        let log = HadithStore.shared.viewedLog
        withMainQueueDefaultsObserver {
            log.record(HadithStore.ViewedEntry(slug: "bukhari", idInBook: 1, reference: "Bukhari 1",
                                   arabicPreview: "", englishPreview: "", viewedAt: Date()))
            let finished = runOffMainWhileMainSpins {
                DispatchQueue.main.sync {
                    MainActor.assumeIsolated {
                        HadithStore.shared.viewedLog.flush()
                        HadithStore.shared.viewedLog.flushSynchronously()
                    }
                }
            }
            XCTAssertTrue(finished, "flush() + flushSynchronously() deadlocked with a main-queue observer installed")
        }
    }

    /// The restore path's guard. `reloadFromStorage` used to drain `ioQueue` too.
    func testReloadFromStorageDoesNotDeadlock() {
        let log = HadithStore.shared.viewedLog
        withMainQueueDefaultsObserver {
            log.record(HadithStore.ViewedEntry(slug: "muslim", idInBook: 2, reference: "Muslim 2",
                                   arabicPreview: "", englishPreview: "", viewedAt: Date()))
            let finished = runOffMainWhileMainSpins {
                DispatchQueue.main.sync {
                    MainActor.assumeIsolated { HadithStore.shared.viewedLog.reloadFromStorage() }
                }
            }
            XCTAssertTrue(finished, "reloadFromStorage() deadlocked with a main-queue observer installed")
        }
    }

    /// The debounced write must still land, and must land on the MAIN thread: that is what keeps
    /// its `didChangeNotification` off a background queue. A write that moved back to `ioQueue`
    /// would still pass a "did it save?" test, so assert the thread, not just the bytes.
    func testDebouncedWriteLandsOnMainThread() {
        let log = HadithStore.shared.viewedLog
        let observed = expectation(description: "didChange posted")
        observed.assertForOverFulfill = false
        nonisolated(unsafe) var postedOnMain: Bool?
        let token = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: nil
        ) { _ in
            if postedOnMain == nil {
                postedOnMain = Thread.isMainThread
                observed.fulfill()
            }
        }
        defer { NotificationCenter.default.removeObserver(token) }

        log.record(HadithStore.ViewedEntry(slug: "nasai", idInBook: 3, reference: "Nasai 3",
                               arabicPreview: "", englishPreview: "", viewedAt: Date()))
        wait(for: [observed], timeout: 10)
        XCTAssertEqual(postedOnMain, true,
                       "the log's defaults write posted didChangeNotification off the main thread")
    }

    /// The reason the write may be late without being wrong: `writeNow` encodes `entries` as they
    /// are when it runs, never a snapshot captured a second earlier, so a debounce that fires
    /// after a restore cannot put the pre-restore log back.
    func testWriteUsesLiveEntriesNotACapturedSnapshot() {
        let log = HadithStore.shared.viewedLog
        log.record(HadithStore.ViewedEntry(slug: "tirmidhi", idInBook: 4, reference: "Tirmidhi 4",
                               arabicPreview: "", englishPreview: "", viewedAt: Date()))
        let afterFirst = log.entries.count
        log.record(HadithStore.ViewedEntry(slug: "tirmidhi", idInBook: 5, reference: "Tirmidhi 5",
                               arabicPreview: "", englishPreview: "", viewedAt: Date()))
        log.writeNow()

        guard let data = UserDefaults.standard.data(forKey: HadithStore.ViewedLog.key),
              let stored = try? JSONDecoder().decode([HadithStore.ViewedEntry].self, from: data) else {
            return XCTFail("the log did not write")
        }
        XCTAssertEqual(stored.count, log.entries.count)
        XCTAssertGreaterThan(stored.count, afterFirst - 1)
        XCTAssertEqual(stored.first?.idInBook, log.entries.first?.idInBook,
                       "writeNow stored a stale snapshot instead of the live entries")
    }
}
