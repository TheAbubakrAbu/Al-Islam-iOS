import XCTest
import UIKit

/// A crash sweep that needs no UI automation: the app is this bundle's test host, so a test run IS a
/// launch of the real app, with the scheme's launch arguments (the Test action uses the Run
/// action's). The test keeps the main run loop turning while the app opens whatever screen those
/// arguments ask for, then keeps a picture of the app's own window in the result bundle. A crash
/// in that time takes the host down, and xcodebuild reports the test as crashed.
///
/// This is how the Mac ("My Mac (Designed for iPad)") is swept: XCUITest there needs macOS
/// Automation Mode, which asks for a password. Skipped unless `TEST_RUNNER_QA_SMOKE_SECONDS` is set
/// on the xcodebuild line, so an ordinary unit test run never waits.
final class HostSmokeTests: XCTestCase {
    @MainActor
    func testHostSurvivesItsLaunchScreen() throws {
        guard let raw = ProcessInfo.processInfo.environment["QA_SMOKE_SECONDS"], let seconds = Double(raw) else {
            throw XCTSkip("set TEST_RUNNER_QA_SMOKE_SECONDS to run the host smoke sweep")
        }
        let name = ProcessInfo.processInfo.environment["QA_SMOKE_NAME"] ?? "host"
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))

        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { !$0.isHidden && $0.bounds.width > 0 }
        let window = try XCTUnwrap(windows.first { $0.isKeyWindow } ?? windows.first, "\(name): no window on screen")
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let shot = XCTAttachment(image: image)
        shot.name = "\(name) \(Int(window.bounds.width))x\(Int(window.bounds.height))"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
