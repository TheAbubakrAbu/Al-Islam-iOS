import XCTest
@testable import iPhone

/// The review prompt's ledger (AppReview.swift) describes this install, not the person: when it was
/// last asked, and how the app has been used since. AppReview.swift is shared with other apps and
/// keeps its keys in a private enum, which `Scripts/check_cloud_manifest.py` cannot see, so this is
/// what notices a key the shared file gains: everything a saved ledger writes must be device-only
/// (never in an iCloud backup, spared by a keep-content reset; `Settings.deviceOnlyStorageKeys`).
final class AppReviewStorageTests: XCTestCase {
    func testEveryKeyTheLedgerSavesIsDeviceOnly() throws {
        let suiteName = "AppReviewStorageTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Every field away from its default, so no key is left unwritten for holding nothing.
        let now = Date()
        var ledger = AppReviewLedger()
        ledger.noteAsked(now: now.addingTimeInterval(-40 * 86_400))
        ledger.noteForeground(isNewSession: true, now: now)
        ledger.noteUsage(90)
        ledger.noteWin(.small, now: now)
        ledger.noteSetback(.major, now: now)
        ledger.noteWin(.big, now: now)
        ledger.save(to: defaults)

        let saved = (defaults.persistentDomain(forName: suiteName) ?? [:]).keys.sorted()
        XCTAssertGreaterThanOrEqual(saved.count, 10, "the ledger saved fewer keys than it has fields: \(saved)")
        for key in saved {
            XCTAssertTrue(Settings.isResetSpared(key), "\(key) is missing from Settings.deviceOnlyStorageKeys")
        }
    }
}
