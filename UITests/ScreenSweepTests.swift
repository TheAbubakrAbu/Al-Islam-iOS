import XCTest

/// Crash sweep: one cold launch per screen, each opened by its DEBUG launch arguments (the same
/// "name|seconds|args" lines as Scripts/qa/screens.txt), a wait, a screenshot kept in the result
/// bundle, and a failure for every screen the app did not survive. Runs anywhere XCUITest does,
/// including "My Mac (Designed for iPad)", where the shell sweep cannot launch the app.
///
/// The full list comes in through the environment: `TEST_RUNNER_QA_SCREENS="$(cat Scripts/qa/screens.txt)"`
/// on the `xcodebuild test` line (xcodebuild strips the prefix). Without it the core list below runs.
/// `QA_SCREEN_FILTER=quran` keeps only the screens whose name contains that text, and
/// `QA_ORIENTATION=landscape` turns the device first (a simulator only: the app's own DEBUG
/// "-landscape" request is ignored on iPadOS 27, which leaves the orientation to the device).
final class ScreenSweepTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    func testEveryScreenSurvivesLaunch() throws {
        let environment = ProcessInfo.processInfo.environment
        var screens = SweepScreen.parse(environment["QA_SCREENS"] ?? SweepScreen.coreList)
        if let filter = environment["QA_SCREEN_FILTER"], !filter.isEmpty {
            screens = screens.filter { $0.name.localizedCaseInsensitiveContains(filter) }
        }
        XCTAssertFalse(screens.isEmpty, "no screens to sweep")
        if environment["QA_ORIENTATION"] == "landscape", !ProcessInfo.processInfo.isiOSAppOnMac {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        var dead: [String] = []
        for screen in screens {
            let app = XCUIApplication()
            app.launchArguments = ["-skipNotificationPrompt"] + screen.arguments
            app.launch()
            // The cover lifts after 4-6 s; the per-screen wait is the shell sweep's, which already
            // allows for it. Waiting on `.runningForeground` first keeps a slow launch from reading
            // as a crash.
            _ = app.wait(for: .runningForeground, timeout: 20)
            Thread.sleep(forTimeInterval: screen.seconds)
            let alive = app.state == .runningForeground || app.state == .runningBackground
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = screen.name
            shot.lifetime = .keepAlways
            add(shot)
            if !alive {
                dead.append(screen.name)
                XCTFail("\(screen.name): the app is not running after \(screen.seconds) s (\(screen.arguments.joined(separator: " ")))")
            }
            app.terminate()
        }
        if environment["QA_ORIENTATION"] == "landscape", !ProcessInfo.processInfo.isiOSAppOnMac {
            XCUIDevice.shared.orientation = .portrait
        }
        let summary = XCTAttachment(string: "\(screens.count - dead.count) of \(screens.count) screens alive"
                                    + (dead.isEmpty ? "" : "; dead: \(dead.joined(separator: ", "))"))
        summary.name = "sweep summary"
        summary.lifetime = .keepAlways
        add(summary)
    }
}

struct SweepScreen {
    let name: String
    let seconds: Double
    let arguments: [String]

    /// Twelve screens, one per tab root and the heaviest readers.
    static let coreList = """
    adhan|9|
    adhan-tracker|8|-openPrayerTracker
    adhan-qibla|8|-showBigQibla
    quran-list|8|-launchTabQuran -quranListMode -noAutoOpenMushaf
    quran-list-surah|9|-launchTabQuran -quranListMode -lastRead 2:255
    quran-page|10|-launchTabQuran -quranPageMode -lastRead 2:255
    quran-page-arabic|10|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 18:1
    quran-page-pdf|10|-launchTabQuran -quranPageMode -mushafPageLanguage pdf -lastRead 36:1
    hadith|8|-launchTabHadith
    islam|8|-launchTabIslam
    settings|8|-launchTabSettings
    settings-aboutYou|8|-showAboutYou
    """

    /// "name|seconds|args" lines; blank lines, "#" comments and "!" shell lines are skipped. The
    /// arguments are split like a shell does for the list's needs: spaces separate, double quotes
    /// group (`-displayQiraah "Warsh an Nafi"`, and `""` is an empty argument).
    static func parse(_ list: String) -> [SweepScreen] {
        list.split(whereSeparator: \.isNewline).compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), !line.hasPrefix("!") else { return nil }
            let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 2 else { return nil }
            return SweepScreen(name: parts[0], seconds: Double(parts[1]) ?? 8,
                               arguments: parts.count > 2 ? words(parts[2]) : [])
        }
    }

    static func words(_ text: String) -> [String] {
        var words: [String] = []
        var current = ""
        var quoted = false
        var started = false
        for character in text {
            if character == "\"" {
                quoted.toggle()
                started = true
            } else if character == " " && !quoted {
                if started { words.append(current) }
                current = ""
                started = false
            } else {
                current.append(character)
                started = true
            }
        }
        if started { words.append(current) }
        return words
    }
}
