import XCTest

/// Random taps, swipes, back steps, tab changes and (on iPad) rotations, from a fixed seed so a
/// crash replays. After every step the app must still be running; a crash fails the test with the
/// last steps that led to it and relaunches, so one run can find several. Buttons that leave the
/// app, reach a network or account, or throw data away are never tapped (`isOffLimits`).
///
/// Environment (prefix each with TEST_RUNNER_ on the xcodebuild line): QA_MONKEY_STEPS (default
/// 150), QA_SEED (default 2026), QA_MONKEY_ARGS (extra launch arguments, e.g. "-launchTabQuran"),
/// QA_MONKEY_GAP (seconds between steps, default 0.6), QA_MONKEY_STRESS=1 (a fifth of the steps
/// become stress actions: a control tapped twice or three times in a row, a long press, a trip to
/// the background and back, a rotation on iPhone too, hostile text typed into a search field).
/// Without QA_MONKEY_STRESS a seed walks exactly the path it always did.
final class MonkeyTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
        Self.skipQuiescenceWait()
        // A system alert the walk raised itself (the keyboard's dictation key asks "Enable
        // Dictation?") is answered with its quiet button, never the one that leaves the app.
        addUIInterruptionMonitor(withDescription: "System alert") { alert in
            for label in ["Not Now", "Cancel", "Don’t Allow", "Don't Allow", "OK", "Close"] {
                let button = alert.buttons[label]
                if button.exists { button.tap(); return true }
            }
            return false
        }
    }

    /// XCUITest waits for the app to go idle before every event, and a screen with an endless
    /// animation (the Adhan sky) never does: each step then sat out a 60 s timeout. A walk only
    /// needs the app alive, so the wait becomes a no-op (private XCTest API, test target only).
    private static func skipQuiescenceWait() {
        guard let process = NSClassFromString("XCUIApplicationProcess") else { return }
        let oneArgument: @convention(block) (AnyObject, Bool) -> Void = { _, _ in }
        let twoArguments: @convention(block) (AnyObject, Bool, Bool) -> Void = { _, _, _ in }
        if let method = class_getInstanceMethod(process, NSSelectorFromString("waitForQuiescenceIncludingAnimationsIdle:")) {
            method_setImplementation(method, imp_implementationWithBlock(oneArgument))
        }
        if let method = class_getInstanceMethod(process, NSSelectorFromString("waitForQuiescenceIncludingAnimationsIdle:isPreEvent:")) {
            method_setImplementation(method, imp_implementationWithBlock(twoArguments))
        }
    }

    func testRandomWalkNeverCrashes() throws {
        let environment = ProcessInfo.processInfo.environment
        let steps = Int(environment["QA_MONKEY_STEPS"] ?? "") ?? 150
        var random = SeededRandom(seed: UInt64(environment["QA_SEED"] ?? "") ?? 2026)
        let extra = SweepScreen.words(environment["QA_MONKEY_ARGS"] ?? "")
        let rotates = !ProcessInfo.processInfo.isiOSAppOnMac && UIDevice.current.userInterfaceIdiom == .pad
        let gap = Double(environment["QA_MONKEY_GAP"] ?? "") ?? 0.6
        let stress = environment["QA_MONKEY_STRESS"] == "1"

        let app = XCUIApplication()
        app.launchArguments = ["-skipNotificationPrompt"] + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 20)
        Thread.sleep(forTimeInterval: 7)

        var trail: [String] = []
        var crashes = 0
        for step in 0..<steps {
            switch app.state {
            case .notRunning, .unknown:
                crashes += 1
                let lastSteps = trail.suffix(12).joined(separator: "\n")
                XCTFail("crash before step \(step) (seed \(random.seed)); the last steps:\n\(lastSteps)")
                keep("crash \(crashes) trail", lastSteps)
                app.launch()
                _ = app.wait(for: .runningForeground, timeout: 20)
                Thread.sleep(forTimeInterval: 7)
            case .runningBackground, .runningBackgroundSuspended:
                trail.append("\(step): back to the app from the background")
                app.activate()
                continue
            default:
                break
            }

            if stress, random.below(5) == 0 {
                trail.append("\(step): " + stressSomething(in: app, random: &random))
                Thread.sleep(forTimeInterval: gap)
                continue
            }

            let roll = random.below(100)
            switch roll {
            case 0..<58:
                trail.append("\(step): " + tapSomething(in: app, random: &random))
            case 58..<72:
                if random.below(2) == 0 { app.swipeUp() } else { app.swipeDown() }
                trail.append("\(step): swipe")
            case 72..<82:
                let back = app.navigationBars.buttons.firstMatch
                if back.exists, onScreen(back, in: app), !isOffLimits(back.label) {
                    trail.append("\(step): back (\(back.label))")
                    back.tap()
                } else {
                    trail.append("\(step): no back button")
                }
            case 82..<92:
                let tabs = app.tabBars.buttons.allElementsBoundByIndex.filter { onScreen($0, in: app) }
                if !tabs.isEmpty {
                    let tab = tabs[random.below(tabs.count)]
                    trail.append("\(step): tab \(tab.label)")
                    tab.tap()
                } else {
                    trail.append("\(step): no tab bar")
                }
            case 92..<96:
                // A sheet's own close button, else a downward swipe from its top.
                let close = app.buttons.matching(NSPredicate(format: "label IN %@", ["Close", "Done", "Cancel"])).firstMatch
                if close.exists, onScreen(close, in: app) {
                    trail.append("\(step): \(close.label)")
                    close.tap()
                } else {
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
                        .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
                    trail.append("\(step): drag down")
                }
            default:
                if rotates {
                    let orientation: UIDeviceOrientation = [.portrait, .landscapeLeft, .landscapeRight][random.below(3)]
                    XCUIDevice.shared.orientation = orientation
                    trail.append("\(step): rotate \(orientation.rawValue)")
                } else {
                    app.swipeLeft()
                    trail.append("\(step): swipe left")
                }
            }
            Thread.sleep(forTimeInterval: gap)
        }
        if rotates || stress { XCUIDevice.shared.orientation = .portrait }
        keep("trail", trail.joined(separator: "\n"))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "last screen"
        shot.lifetime = .keepAlways
        add(shot)
        XCTAssertEqual(crashes, 0, "\(crashes) crash(es) in \(steps) steps")
    }

    /// Taps one on-screen control chosen at random from a single snapshot of the tree (one round
    /// trip, instead of an `isHittable` query per candidate).
    private func tapSomething(in app: XCUIApplication, random: inout SeededRandom) -> String {
        guard let pick = pickTarget(in: app, random: &random) else { return "nothing to tap" }
        point(in: app, at: pick.frame).tap()
        return "tap \"\(pick.label.prefix(60))\""
    }

    /// One stress action (QA_MONKEY_STRESS), each a shape that has broken this app before: a second
    /// push raised before the first settled, a context menu, a scene-phase flush, a rotation, and
    /// out-of-range or malformed text where references and amounts are parsed.
    private func stressSomething(in app: XCUIApplication, random: inout SeededRandom) -> String {
        switch random.below(6) {
        case 0, 1:
            guard let pick = pickTarget(in: app, random: &random) else { return "nothing to tap" }
            let times = 2 + random.below(2)
            let target = point(in: app, at: pick.frame)
            for _ in 0..<times { target.tap() }
            return "tap x\(times) \"\(pick.label.prefix(60))\""
        case 2:
            guard let pick = pickTarget(in: app, random: &random) else { return "nothing to press" }
            point(in: app, at: pick.frame).press(forDuration: 0.9)
            return "long press \"\(pick.label.prefix(60))\""
        case 3:
            XCUIDevice.shared.press(.home)
            Thread.sleep(forTimeInterval: 1.5)
            app.activate()
            _ = app.wait(for: .runningForeground, timeout: 10)
            return "background and back"
        case 4:
            guard !ProcessInfo.processInfo.isiOSAppOnMac else { return "no rotation on a Mac" }
            let orientation: UIDeviceOrientation = [.portrait, .landscapeLeft, .landscapeRight][random.below(3)]
            XCUIDevice.shared.orientation = orientation
            return "rotate \(orientation.rawValue)"
        default:
            // From one snapshot, never a live element: a field that leaves the screen between a query
            // and its frame fails the whole walk ("No matches found"), which says nothing about the app.
            guard let snapshot = try? app.snapshot(), let fieldFrame = firstTextFieldFrame(in: snapshot) else {
                return "no text field"
            }
            let inputs = ["2:300", "999:1", "1:0", "0", "-1", "114:7", "2:286", "1:1:1", "2:", ":5",
                          "9999999999999999999", "0.0000001", "1e309", "a", "  ", "%", "\\", "''",
                          "bukhari 99999", "muslim 0", "Allah", "sabr", "رحمن", "١٢٣"]
            let text = inputs[random.below(inputs.count)]
            point(in: app, at: fieldFrame).tap()
            guard app.keyboards.firstMatch.waitForExistence(timeout: 1.5) else { return "no keyboard" }
            app.typeText(text)
            return "type \"\(text)\""
        }
    }

    /// The first on-screen text or search field in a snapshot, by its frame.
    private func firstTextFieldFrame(in node: XCUIElementSnapshot) -> CGRect? {
        if node.elementType == .textField || node.elementType == .searchField, !node.frame.isEmpty {
            return node.frame
        }
        for child in node.children {
            if let frame = firstTextFieldFrame(in: child) { return frame }
        }
        return nil
    }

    /// On screen by its frame. `isHittable` mid-animation can fail the test outright ("Failed to
    /// determine hittability"), which says nothing about the app.
    private func onScreen(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        let frame = element.frame
        return !frame.isEmpty && app.windows.firstMatch.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func point(in app: XCUIApplication, at frame: CGRect) -> XCUICoordinate {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY))
    }

    private func pickTarget(in app: XCUIApplication, random: inout SeededRandom) -> (label: String, frame: CGRect)? {
        guard let snapshot = try? app.snapshot() else { return nil }
        let window = app.windows.firstMatch.frame
        var candidates: [(label: String, frame: CGRect)] = []
        func walk(_ node: XCUIElementSnapshot) {
            switch node.elementType {
            case .button, .cell, .link, .switch, .toggle, .tab, .menuItem, .segmentedControl, .staticText, .image:
                let frame = node.frame
                let label = node.label.isEmpty ? node.identifier : node.label
                if frame.width >= 8, frame.height >= 8, window.contains(CGPoint(x: frame.midX, y: frame.midY)),
                   node.isEnabled, !isOffLimits(label),
                   // Plain text and images only count when they are small enough to be a row's tap target.
                   (node.elementType != .staticText && node.elementType != .image) || frame.height < 90 {
                    candidates.append((label, frame))
                }
            default:
                break
            }
            node.children.forEach(walk)
        }
        walk(snapshot)
        guard !candidates.isEmpty else { return nil }
        return candidates[random.below(candidates.count)]
    }

    /// Controls the walk must never press: leaving the app (links, mail, the App Store, Safari,
    /// system Settings), the network or an account (iCloud, downloads), or data loss (delete,
    /// reset, remove, clear). A share sheet is off limits too: its targets are other apps.
    private func isOffLimits(_ label: String) -> Bool {
        let lowered = label.lowercased()
        let phrases = ["delete", "remove", "reset", "erase", "clear", "sign out", "share", "app store",
                       "mail", "contact", "website", "safari", "open in", "report", "feedback", "icloud",
                       "back up", "backup", "restore", "download", "export", "import", "open settings",
                       "privacy", "terms", "donate", "github", "instagram", "youtube", "twitter", "discord",
                       "tiktok", "facebook", "whatsapp", "telegram", "save to photos", "save image",
                       "wallpaper", "unbookmark", "unfavorite", "forget", "log out", "subscribe", "purchase",
                       "copy link", "open link", "view on", "dictat"]
        if phrases.contains(where: { lowered.contains($0) }) { return true }
        // Short words only as whole words: "rate" must not catch "Narrated by", nor "tip" "Tips & Tricks".
        let wholeWords: Set<String> = ["rate", "review", "call", "send", "buy", "map", "maps"]
        let tokens = lowered.split(whereSeparator: { !$0.isLetter })
        return tokens.contains { wholeWords.contains(String($0)) }
    }

    private func keep(_ name: String, _ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// SplitMix64: a tiny, stable generator, so a seed always walks the same path.
struct SeededRandom {
    let seed: UInt64
    private var state: UInt64

    init(seed: UInt64) {
        self.seed = seed
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func below(_ bound: Int) -> Int {
        Int(next() % UInt64(max(1, bound)))
    }
}
