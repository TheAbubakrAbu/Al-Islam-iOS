#if DEBUG && os(iOS)
import SwiftUI
import UIKit

/// An in-process monkey: a seeded random walk over the running app that needs no simulator, no
/// XCUITest and no accessibility permission, so it runs anywhere the app runs, including "My Mac
/// (Designed for iPad)", where nothing outside the process can tap it (2026-10-12, Abu: "crashes a
/// lot on my mac ... come up with some way to test that hardcore, I want 0 crashes").
///
/// Each step is one of: activating a random accessibility element on screen (the same tree VoiceOver
/// and XCUITest drive, so rows, buttons, links, switches and tiles all count), two activations in one
/// run-loop turn (the "two doors in one frame" class), a pop, a tab change, a sheet dismissal, a
/// scroll, hostile text into the first text field, a Mac window resize (every layout at every width),
/// a light/dark or Dynamic Type flip, a settings storm through the real setters (a publish while every
/// screen is up), a cross-tab deep link, playback, a second window, a fake memory warning, a rotation
/// on a phone or an iPad. Every step is logged (`STRESS <n> <action> | <screen>`) and appended to
/// Documents/stress/trail-<seed>.log, synchronised to disk, so a crash report's time maps to a step and
/// the seed replays it. A background watchdog logs `STRESS HANG` when the main thread stops answering.
///
/// Launch arguments: `-stressWalk [steps]` (default 400), `-stressSeed <n>` (default 2026),
/// `-stressGap <seconds>` (default 0.35), `-stressMix ax|nav|all` (default all: `ax` keeps to the
/// accessibility walk, pops, tabs and dismissals; `nav` keeps everything but the accessibility walk),
/// `-stressNoAudio` (no playback or speech), `-stressExit` (exit 0 when the walk ends, so a shell
/// harness can wait on the process). Add `-stressWalk 2000` to the Run scheme to watch it in Xcode.
///
/// Controls that leave the app, reach an account or the network on purpose, or throw data away are
/// never activated (`isOffLimits`, the MonkeyTests list plus system permission prompts).
@MainActor
enum StressWalker {
    static func runIfRequested() async {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-stressRestore") {
            // The recovery pass: put the container back the way the last walk found it (a crashed walk
            // never reached its own restore), then leave.
            await AppReveal.waitUntilRevealed()
            let restored = StateGuard.restoreIfPending()
            NSLog("STRESS restore pass: %@", restored ? "restored" : "nothing pending")
            finished = true
            if args.contains("-stressExit") { exit(0) }
            return
        }
        if let script = value(after: "-stressScript", in: args) {
            // "-stressScript 'wait:3;tap:Ask AI about;wait:2;tap:Play;dismiss;resize:1600x900;wait:3;release'":
            // the walk's primitives in a fixed order (see `Walk.runScript`), for replaying a shape.
            await runScript(script, gap: value(after: "-stressGap", in: args).flatMap(Double.init) ?? 0.35)
            finished = true
            if args.contains("-stressExit") { NSLog("STRESS exiting"); exit(0) }
            return
        }
        guard let index = args.firstIndex(of: "-stressWalk") else { return }
        let steps = args.indices.contains(index + 1) ? Int(args[index + 1]) ?? 400 : 400
        let seed = value(after: "-stressSeed", in: args).flatMap(UInt64.init) ?? 2026
        let gap = value(after: "-stressGap", in: args).flatMap(Double.init) ?? 0.35
        let mix = Mix(rawValue: value(after: "-stressMix", in: args) ?? "all") ?? .all
        let audio = !args.contains("-stressNoAudio")
        await run(steps: steps, seed: seed, gap: gap, mix: mix, audio: audio)
        if args.contains("-stressExit") {
            NSLog("STRESS exiting")
            exit(0)
        }
    }

    /// True once a walk (or a restore pass) has ended, for a hosted test that keeps the process alive.
    static var finished = false

    enum Mix: String { case ax, nav, all }

    private static func value(after flag: String, in args: [String]) -> String? {
        guard let i = args.firstIndex(of: flag), args.indices.contains(i + 1) else { return nil }
        return args[i + 1]
    }

    /// The whole walk. Returns when it has done `steps` steps (or when nothing on screen can be
    /// driven for 40 steps in a row, which is a harness problem, never an app pass).
    static func run(steps: Int, seed: UInt64, gap: Double, mix: Mix = .all, audio: Bool = true) async {
        await AppReveal.waitUntilRevealed()
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        // The walk changes settings, marks and files at random. On a Mac it runs in the SAME container
        // as the installed app, so what it found is put back when it ends (or by the next walk, or by
        // a "-stressRestore" launch, when it crashed before it could).
        let guardState = StateGuard.begin()
        #if HAS_ICLOUD_BACKUP
        CloudBackupManager.automaticSavesSuspended = true
        #endif
        let axEnabled = AccessibilityBridge.enable()
        let walk = Walk(seed: seed, gap: gap, mix: mix, audio: audio)
        walk.log("accessibility bridge: \(axEnabled)")
        if ProcessInfo.processInfo.arguments.contains("-stressDump") { walk.dumpTree() }
        walk.log("start steps=\(steps) seed=\(seed) gap=\(gap) mix=\(mix) audio=\(audio) mac=\(walk.isMac) idiom=\(UIDevice.current.userInterfaceIdiom.rawValue) guard=\(guardState)")
        Watchdog.start(trail: walk.trail, beat: walk.beat)
        var idle = 0
        for step in 0..<steps {
            walk.trail.step = step
            let outcome = walk.doStep()
            idle = outcome.didSomething ? 0 : idle + 1
            if idle >= 40 {
                walk.log("STOP nothing to drive for 40 steps")
                break
            }
            try? await Task.sleep(nanoseconds: UInt64(max(gap, 0.05) * 1_000_000_000))
        }
        // "-stressThen '<script>'": a fixed sequence after the random walk, on the state the walk built
        // (bisecting what a seed's crash or hang needs: the iPad tab bar hang, 2026-10-13).
        if let then = value(after: "-stressThen", in: ProcessInfo.processInfo.arguments) {
            walk.log("then: \(then)")
            await performScript(then, on: walk, gap: gap, firstStep: walk.trail.step + 1)
        }
        walk.releaseWindowSize()
        walk.log("done \(walk.trail.step + 1) steps, \(walk.activations) activations, \(walk.unresolved) unresolved")
        Watchdog.stop()
        QuranPlayer.shared.stop()
        ArabicSpeech.shared.stop()
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        walk.log("restore: \(StateGuard.restoreIfPending() ? "done" : "nothing pending")")
        #if HAS_ICLOUD_BACKUP
        CloudBackupManager.automaticSavesSuspended = false
        #endif
        finished = true
    }

    /// A scripted sequence: `step;step;...`, each `wait:<s>`, `tap:<label part>` (the first on-screen
    /// element whose label contains it), `double:<label part>` (twice in one turn), `back`, `dismiss`,
    /// `tab:<adhan|quran|hadith|islam|settings>`, `resize:WxH`, `release`, `hide`, `appearance:<dark|light|system>`,
    /// `deeplink:<quran|surah:n|ayah:s:a|duas|adhkar|names|qibla|hadith|search:q>`, `play:<surah>`,
    /// `playayah:<s:a>`, `stop`, `type:<text>`, `memory`, `window`, `scroll:<top|bottom>`.
    static func runScript(_ script: String, gap: Double) async {
        await AppReveal.waitUntilRevealed()
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let guardState = StateGuard.begin()
        #if HAS_ICLOUD_BACKUP
        CloudBackupManager.automaticSavesSuspended = true
        #endif
        _ = AccessibilityBridge.enable()
        let walk = Walk(seed: 0, gap: gap, mix: .all, audio: true)
        walk.log("script start guard=\(guardState): \(script)")
        Watchdog.start(trail: walk.trail, beat: walk.beat)
        await performScript(script, on: walk, gap: gap, firstStep: 0)
        walk.releaseWindowSize()
        Watchdog.stop()
        QuranPlayer.shared.stop()
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        walk.log("script done; restore: \(StateGuard.restoreIfPending() ? "done" : "nothing pending")")
        #if HAS_ICLOUD_BACKUP
        CloudBackupManager.automaticSavesSuspended = false
        #endif
    }

    /// The script's steps, one after the other, on `walk` (the trail numbers them from `firstStep`).
    static func performScript(_ script: String, on walk: Walk, gap: Double, firstStep: Int) async {
        for (index, raw) in script.split(separator: ";").enumerated() {
            walk.trail.step = firstStep + index
            walk.beat.touch()
            let step = raw.trimmingCharacters(in: .whitespaces)
            let parts = step.split(separator: ":", maxSplits: 1).map(String.init)
            // An underscore stands for a space, so a script survives a scheme's argument splitting.
            let name = parts[0], arg = parts.count > 1 ? parts[1].replacingOccurrences(of: "_", with: " ") : ""
            var text = "script \(step): "
            switch name {
            case "wait":
                try? await Task.sleep(nanoseconds: UInt64((Double(arg) ?? 1) * 1_000_000_000))
                text += "waited"
            case "tap", "double":
                let list = walk.candidates().filter { $0.label.localizedCaseInsensitiveContains(arg) }
                if let element = list.first {
                    var done = walk.activate(element)
                    if name == "double" { done = walk.activate(element) || done }
                    text += "\(done ? "activated" : "UNRESOLVED") \(walk.describe(element))"
                } else {
                    text += "NOT FOUND among \(walk.candidates().count)"
                }
            case "back": text += walk.pop().0
            case "dismiss": text += walk.dismissTop().0
            case "tab":
                NotificationCenter.default.post(name: Notification.Name("AlIslamDebugSwitchTab"), object: arg)
                text += "tab \(arg)"
            case "resize":
                let dims = arg.lowercased().split(separator: "x").compactMap { Double($0) }
                if dims.count == 2 {
                    for scene in walk.scenes() {
                        scene.sizeRestrictions?.minimumSize = CGSize(width: dims[0], height: dims[1])
                        scene.sizeRestrictions?.maximumSize = CGSize(width: dims[0], height: dims[1])
                    }
                    text += "resized"
                }
            case "release": walk.releaseWindowSize(); text += "released"
            case "hide": text += walk.hideAndUnhide()
            case "appearance":
                let style: UIUserInterfaceStyle = arg == "dark" ? .dark : arg == "light" ? .light : .unspecified
                walk.keyWindow()?.overrideUserInterfaceStyle = style
                text += "style \(style.rawValue)"
            case "rotate":
                // "rotate:portrait|left|right": the walk's rotation (`rotate`), for replaying a shape.
                if #available(iOS 16.0, *), !walk.isMac {
                    let mask: UIInterfaceOrientationMask = arg == "left" ? .landscapeLeft : arg == "right" ? .landscapeRight : .portrait
                    for scene in walk.scenes() where scene.activationState == .foregroundActive {
                        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
                    }
                    text += "rotate \(mask.rawValue)"
                }
            case "typesize", "rawtypesize":
                // "typesize:AccessibilityXXXL", "typesize:M", "typesize:system": the walk's Dynamic Type
                // change (`flipAppearance`), through the app's coalescer where it runs; "rawtypesize:" sets
                // the window override directly, which on an iPad reproduces the UIKit tab bar hang when
                // two land inside a second (2026-10-13).
                if #available(iOS 17.0, *), let window = walk.keyWindow() {
                    if arg == "system" {
                        window.traitOverrides.remove(UITraitPreferredContentSizeCategory.self)
                        text += "type size system"
                    } else {
                        let size = UIContentSizeCategory(rawValue: "UICTContentSizeCategory" + arg)
                        if name == "typesize", DynamicTypeCoalescer.isActive {
                            DynamicTypeCoalescer.request(size)
                        } else {
                            window.traitOverrides.preferredContentSizeCategory = size
                        }
                        text += "type size \(size.rawValue)"
                    }
                }
            case "deeplink":
                let p = arg.split(separator: ":").map(String.init)
                switch p.first ?? "" {
                case "quran": AppNavigation.shared.open(.tab)
                case "surah": AppNavigation.shared.open(.surah(Int(p[1]) ?? 1))
                case "ayah": AppNavigation.shared.open(.ayah(Int(p[1]) ?? 1, Int(p[2]) ?? 1))
                case "duas": AppNavigation.shared.openIslam(.duas)
                case "adhkar": AppNavigation.shared.openIslam(.adhkar)
                case "names": AppNavigation.shared.openIslam(.names(nil))
                case "qibla": AppNavigation.shared.openAdhan(.qibla)
                case "hadith": AppNavigation.shared.openIslam(.hadithTab)
                case "search": QuranSearchHandoff.shared.request(p.dropFirst().joined(separator: ":"))
                default: break
                }
                text += "deep link \(arg)"
            case "play":
                let n = Int(arg) ?? 1
                if QuranData.shared.quran.indices.contains(n - 1) {
                    _ = QuranPlayer.shared.playSurah(surahNumber: n, surahName: QuranData.shared.quran[n - 1].nameTransliteration)
                }
                text += "play \(n)"
            case "playayah":
                let p = arg.split(separator: ":").compactMap { Int($0) }
                if p.count == 2 { _ = QuranPlayer.shared.playAyah(surahNumber: p[0], ayahNumber: p[1]) }
                text += "play ayah \(arg)"
            case "stop": QuranPlayer.shared.stop(); text += "stopped"
            case "type":
                if let field = walk.allViews(of: UITextField.self, in: walk.keyWindow()).first(where: { $0.window != nil }) {
                    field.becomeFirstResponder(); field.insertText(arg); field.sendActions(for: .editingChanged)
                    text += "typed"
                } else { text += "no field" }
            case "memory":
                NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: UIApplication.shared)
                text += "memory warning"
            case "dump": walk.dumpTree(); text += "dumped"
            case "window": text += walk.secondWindow()
            case "scroll":
                if let scroller = walk.allViews(of: UIScrollView.self, in: walk.keyWindow()).first(where: { $0.contentSize.height > $0.bounds.height }) {
                    let y = arg == "bottom" ? scroller.contentSize.height - scroller.bounds.height : 0
                    scroller.setContentOffset(CGPoint(x: 0, y: y), animated: true)
                    text += "scrolled \(arg)"
                }
            default: text += "unknown step"
            }
            walk.log(text + " | \(walk.screenName())")
            try? await Task.sleep(nanoseconds: UInt64(max(gap, 0.05) * 1_000_000_000))
        }
    }

    // MARK: - The walk

    @MainActor
    final class Walk {
        var random: SeededRandom
        let gap: Double
        let mix: Mix
        let audio: Bool
        let isMac = ProcessInfo.processInfo.isiOSAppOnMac
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        var activations = 0
        var unresolved = 0
        /// Steps left before a pinned Mac window size is released.
        var pinnedFor = 0
        /// The window's own size floor and ceiling before the walk touched them (the Mac): a person
        /// can resize only within these, so the walk's sizes are clamped to them and they are put
        /// back when a pin is released. Read once, on the first resize.
        var originalRestrictions: (minimum: CGSize, maximum: CGSize)?
        /// The main thread's last heartbeat, read by the watchdog from its own thread.
        let beat = Beat()
        /// The step counter and the trail file, shared with the watchdog thread.
        let trail: Trail

        init(seed: UInt64, gap: Double, mix: Mix, audio: Bool) {
            random = SeededRandom(seed: seed)
            self.gap = gap
            self.mix = mix
            self.audio = audio
            trail = Trail(seed: seed)
        }

        func log(_ text: String) { trail.log(text) }

        struct Outcome { let didSomething: Bool }

        func doStep() -> Outcome {
            beat.touch()
            if pinnedFor > 0 {
                pinnedFor -= 1
                if pinnedFor == 0 { releaseWindowSize() }
            }
            let screen = screenName()
            if settling {
                // The step after a menu or a sheet closed is a wait: the dismissal animates for a third
                // of a second, and a sheet raised inside that beat queued behind the closing one ("only
                // presenting a single sheet is supported", the Hadith and Quran filter sheets, seeds 31
                // and 32, 2026-10-13), a timing no finger has: the tap that closes a menu lands on
                // nothing else, and a closing sheet still owns the touches under it.
                settling = false
                log("settling | \(screen)")
                return Outcome(didSomething: true)
            }
            let roll = random.below(100)
            let text: String
            var did = true
            if let menu = presentedMenu() {
                // A menu is up: pick one of its items, or close it. Nothing else is possible for a person.
                (text, did) = actInsideMenu(menu)
                log("\(text) | \(screen)")
                return Outcome(didSomething: did)
            }
            switch pick(roll) {
            case .axTap:
                (text, did) = activateRandomElement()
            case .axDouble:
                (text, did) = activateTwoElements()
            case .customAction:
                (text, did) = performCustomAction()
            case .back:
                (text, did) = pop()
            case .tab:
                text = switchTab()
            case .dismiss:
                (text, did) = dismissTop()
            case .scroll:
                (text, did) = scrollSomething()
            case .resize:
                text = pinRandomWindowSize()
            case .appearance:
                text = flipAppearance()
            case .settings:
                text = stormSetting()
            case .deepLink:
                text = deepLink()
            case .playback:
                text = playback()
            case .text:
                (text, did) = typeSomething()
            case .rotate:
                text = rotate()
            case .window:
                text = secondWindow()
            case .memory:
                NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: UIApplication.shared)
                text = "memory warning"
            case .hide:
                text = hideAndUnhide()
            }
            log("\(text) | \(screen)")
            return Outcome(didSomething: did)
        }

        enum Action { case axTap, axDouble, customAction, back, tab, dismiss, scroll, resize, appearance, settings, deepLink, playback, text, rotate, window, memory, hide }

        /// Weighted by platform: the accessibility walk is most of every step, the rest are the shapes
        /// that have crashed this app before. A Mac gets window resizes, a phone or an iPad rotations.
        private func pick(_ roll: Int) -> Action {
            var table: [(Action, Int)] = []
            if mix != .nav {
                table += [(.axTap, 42), (.axDouble, 6), (.customAction, 2), (.back, 8), (.tab, 7), (.dismiss, 5), (.scroll, 5)]
            }
            if mix != .ax {
                table += [(.appearance, 3), (.settings, 7), (.deepLink, 4), (.text, 4), (.memory, 1)]
                if audio { table.append((.playback, 3)) }
                if isMac { table += [(.resize, 7), (.hide, 3)] } else { table.append((.rotate, 3)) }
                if isMac || isPad { table.append((.window, 1)) }
            }
            if mix == .nav { table += [(.back, 6), (.tab, 8), (.dismiss, 4)] }
            let total = table.reduce(0) { $0 + $1.1 }
            var cursor = roll * total / 100
            for (action, weight) in table {
                if cursor < weight { return action }
                cursor -= weight
            }
            return table.last?.0 ?? .tab
        }

        // MARK: Screens, windows, controllers

        func keyWindow() -> UIWindow? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive }
                ?? scenes.first { $0.activationState == .foregroundInactive } ?? scenes.first
            return scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first
        }

        func screenName() -> String {
            guard let top = topmostViewController() else { return "no controller" }
            var name = String(describing: type(of: top))
            if name.count > 40 { name = String(name.prefix(40)) }
            if let bar = firstView(of: UINavigationBar.self, in: keyWindow()), let title = bar.topItem?.title, !title.isEmpty {
                name += " \"\(title.prefix(40))\""
            }
            return name
        }

        func firstView<T: UIView>(of type: T.Type, in root: UIView?) -> T? {
            guard let root else { return nil }
            if let hit = root as? T, !hit.isHidden { return hit }
            for sub in root.subviews {
                if let hit = firstView(of: type, in: sub) { return hit }
            }
            return nil
        }

        func allViews<T: UIView>(of type: T.Type, in root: UIView?) -> [T] {
            guard let root, !root.isHidden else { return [] }
            var out: [T] = []
            if let hit = root as? T { out.append(hit) }
            for sub in root.subviews { out += allViews(of: type, in: sub) }
            return out
        }

        /// The deepest navigation controller with something to pop, presented sheets included.
        func navigationController(toPop root: UIViewController?) -> UINavigationController? {
            guard let root else { return nil }
            var found: UINavigationController?
            func visit(_ vc: UIViewController) {
                if let nav = vc as? UINavigationController, nav.viewControllers.count > 1 { found = nav }
                for child in vc.children { visit(child) }
                if let presented = vc.presentedViewController { visit(presented) }
            }
            visit(root)
            return found
        }

        /// "-stressDump": what the window exposes, for tuning the walk (hosting views, element counts).
        func dumpTree() {
            guard let window = keyWindow() else { log("dump: no window"); return }
            var views = 0, elements = 0, containers = 0, hosting: [String: Int] = [:]
            func visit(_ view: UIView, depth: Int) {
                views += 1
                let name = String(describing: type(of: view))
                if name.contains("Hosting") { hosting[name, default: 0] += 1 }
                if view.isAccessibilityElement { elements += 1 }
                if let list = view.accessibilityElements, !list.isEmpty { containers += 1 }
                for sub in view.subviews { visit(sub, depth: depth + 1) }
            }
            visit(window, depth: 0)
            log("dump: views=\(views) axElements=\(elements) axContainers=\(containers) hosting=\(hosting)")
            let all = collectElements()
            log("dump: collected \(all.count) elements, \(candidates().count) candidates")
            for element in all.prefix(40) {
                log("dump: \(describe(element)) traits=\(element.traits.rawValue) \(type(of: element.object))")
            }
        }

        // MARK: Menus

        enum PresentedMenu { case contextMenu(UIView), nativeMac }

        /// A context menu or SwiftUI Menu on screen: on iOS a `_UIContextMenu*` controller is presented;
        /// on the Mac a native menu runs its own event loop (the main run loop sits in the tracking mode).
        func presentedMenu() -> PresentedMenu? {
            if isMac, RunLoop.main.currentMode?.rawValue == "NSEventTrackingRunLoopMode" { return .nativeMac }
            guard let top = topmostViewController() else { return nil }
            let name = String(describing: type(of: top))
            if name.contains("ContextMenu"), top.isViewLoaded { return .contextMenu(top.view) }
            if let window = keyWindow() {
                for view in allViews(of: UIView.self, in: window) where String(describing: type(of: view)).contains("_UIContextMenuContainerView") {
                    return .contextMenu(view)
                }
            }
            return nil
        }

        private var menuSteps = 0
        /// The step after a menu or a presentation closed is a wait (see `doStep`).
        private var settling = false

        func actInsideMenu(_ menu: PresentedMenu) -> (String, Bool) {
            menuSteps += 1
            defer { if menuSteps > 3 { menuSteps = 0 } }
            switch menu {
            case .nativeMac:
                // A native menu runs its own event loop; nothing in the UIKit tree can be driven until
                // it closes, and nothing may be asked of AppKit from inside that loop: hiding the app
                // there deadlocked in LaunchServices (`activateIgnoringOtherApps:` ->
                // `_LSCopyApplicationInformation`, sampled 2026-10-12), a synthesised Escape threw. The
                // menu closes by itself when its item is chosen or its view goes away; a step inside it
                // is a wait.
                return ("menu: native menu open, waiting", true)
            case .contextMenu(let container):
                // Elements inside the menu's own view only; beyond three steps in one menu, close it.
                let inside = candidates().filter { element in
                    guard let view = element.object as? UIView ?? (element.object as? UIAccessibilityElement)?.accessibilityContainer as? UIView else {
                        return container.convert(container.bounds, to: nil).contains(CGPoint(x: element.frame.midX, y: element.frame.midY))
                    }
                    return view.isDescendant(of: container)
                }
                if menuSteps <= 3, !inside.isEmpty, random.below(4) != 0 {
                    let element = inside[random.below(inside.count)]
                    let done = activate(element)
                    if done { activations += 1 } else { unresolved += 1 }
                    return ("menu item \(done ? "" : "(unresolved) ")\(describe(element)) of \(inside.count)", done)
                }
                menuSteps = 0
                settling = true
                // The escape gesture first (VoiceOver's way out, which SwiftUI's menu handles itself);
                // a direct dismissal of the controller is what SwiftUI learns of late.
                if container.accessibilityPerformEscape() { return ("menu: escape", true) }
                if let top = topmostViewController(), top.presentingViewController != nil {
                    top.dismiss(animated: true)
                    return ("menu: dismiss \(type(of: top))", true)
                }
                return ("menu: escape (no-op)", true)
            }
        }

        // MARK: Accessibility walk

        struct Element {
            let object: NSObject
            let label: String
            let frame: CGRect
            let traits: UIAccessibilityTraits
            let customActions: [UIAccessibilityCustomAction]
        }

        /// What a finger can reach: the topmost presented controller's view while a sheet, an alert
        /// or a popover is up (it covers what it was presented over, and a tap "through" it lands on
        /// nothing), else the window. Collecting from the window found the rows UNDER a sheet and
        /// activated them (the Quran search's filter sheet up, then its "Ask AI about" row behind it:
        /// two sheets on one List, "only presenting a single sheet is supported" on every update for
        /// the rest of the walk, seed 21 on the iPhone, 2026-10-13), a path no hand has.
        func reachableRoot(in window: UIWindow) -> UIView {
            var top = window.rootViewController
            while let presented = top?.presentedViewController, !presented.isBeingDismissed { top = presented }
            if let top, top !== window.rootViewController, let view = top.view, view.window === window { return view }
            return window
        }

        func collectElements() -> [Element] {
            guard let window = keyWindow() else { return [] }
            let screen = window.convert(window.bounds, to: nil)
            let root = reachableRoot(in: window)
            var out: [Element] = []
            var visited = Set<ObjectIdentifier>()
            var budget = 5000
            func visit(_ object: NSObject) {
                guard budget > 0 else { return }
                let id = ObjectIdentifier(object)
                if visited.contains(id) { return }
                visited.insert(id)
                budget -= 1
                if let view = object as? UIView, view.isHidden || view.alpha < 0.05 { return }
                if object.isAccessibilityElement {
                    let frame = object.accessibilityFrame
                    guard !frame.isEmpty, frame.width >= 6, frame.height >= 6, screen.intersects(frame) else { return }
                    let label = object.accessibilityLabel
                        ?? (object as? UIAccessibilityIdentification)?.accessibilityIdentifier
                        ?? object.accessibilityValue ?? ""
                    out.append(Element(object: object, label: label, frame: frame, traits: object.accessibilityTraits,
                                       customActions: object.accessibilityCustomActions ?? []))
                    return
                }
                if let elements = object.accessibilityElements {
                    for element in elements { if let node = element as? NSObject { visit(node) } }
                } else {
                    let count = object.accessibilityElementCount()
                    if count > 0, count != NSNotFound {
                        for i in 0..<min(count, 400) {
                            if let node = object.accessibilityElement(at: i) as? NSObject { visit(node) }
                        }
                    }
                }
                if let view = object as? UIView {
                    for sub in view.subviews { visit(sub) }
                }
            }
            visit(root)
            return out
        }

        /// Elements worth driving: anything that acts (button, link, adjustable, switch, a cell), text
        /// and images only when small enough to be a row's tap target, never the off-limits labels.
        func candidates() -> [Element] {
            collectElements().filter { element in
                if isOffLimits(element.label) { return false }
                let traits = element.traits
                let acts = traits.contains(.button) || traits.contains(.link) || traits.contains(.adjustable)
                    || traits.contains(.searchField) || traits.contains(.keyboardKey) || traits.contains(.tabBar)
                    || element.object is UIControl || !element.customActions.isEmpty
                if acts { return true }
                if traits.contains(.notEnabled) { return false }
                return (traits.contains(.staticText) || traits.contains(.image)) && element.frame.height < 90
            }
        }

        func activate(_ element: Element) -> Bool {
            if element.object.accessibilityActivate() { return true }
            if let control = element.object as? UIControl {
                if let sw = control as? UISwitch {
                    sw.setOn(!sw.isOn, animated: true)
                }
                control.sendActions(for: .touchUpInside)
                if control is UISwitch { control.sendActions(for: .valueChanged) }
                return true
            }
            if element.traits.contains(.adjustable) {
                if random.below(2) == 0 { element.object.accessibilityIncrement() } else { element.object.accessibilityDecrement() }
                return true
            }
            // A UIKit control behind the node (a bar button, a page chevron): the control under the
            // element's centre, or its nearest control ancestor, fires as a tap would.
            if let window = keyWindow() {
                let point = window.convert(CGPoint(x: element.frame.midX, y: element.frame.midY), from: nil)
                var view = window.hitTest(point, with: nil)
                while let current = view {
                    if let control = current as? UIControl, control.isEnabled {
                        control.sendActions(for: .touchUpInside)
                        if control is UISwitch { control.sendActions(for: .valueChanged) }
                        return true
                    }
                    view = current.superview
                }
            }
            return false
        }

        func describe(_ element: Element) -> String {
            let label = element.label.isEmpty ? "(unlabelled)" : element.label
            return "\"\(label.prefix(50))\" @\(Int(element.frame.midX)),\(Int(element.frame.midY))"
        }

        func activateRandomElement() -> (String, Bool) {
            let list = candidates()
            guard !list.isEmpty else { return ("nothing to activate", false) }
            let element = list[random.below(list.count)]
            let done = activate(element)
            if done { activations += 1 } else { unresolved += 1 }
            return ("\(done ? "tap" : "tap(unresolved)") \(describe(element)) of \(list.count)", done)
        }

        /// Two activations in one run-loop turn: a second push or sheet raised before the first
        /// settled, the shape behind the 2026-10-09 double-door crashes.
        func activateTwoElements() -> (String, Bool) {
            let list = candidates()
            guard list.count >= 2 else { return activateRandomElement() }
            let first = list[random.below(list.count)]
            let second = random.below(3) == 0 ? first : list[random.below(list.count)]
            let a = activate(first)
            let b = activate(second)
            activations += (a ? 1 : 0) + (b ? 1 : 0)
            return ("double \(describe(first)) + \(describe(second))", a || b)
        }

        func performCustomAction() -> (String, Bool) {
            let list = collectElements().filter { !$0.customActions.isEmpty && !isOffLimits($0.label) }
            guard !list.isEmpty else { return activateRandomElement() }
            let element = list[random.below(list.count)]
            let actions = element.customActions.filter { !isOffLimits($0.name) }
            guard !actions.isEmpty else { return ("custom action: all off limits", false) }
            let action = actions[random.below(actions.count)]
            var fired = false
            if let handler = action.actionHandler {
                fired = handler(action)
            } else if let target = action.target as? NSObject, target.responds(to: action.selector) {
                _ = target.perform(action.selector, with: action)
                fired = true
            }
            return ("custom action \"\(action.name.prefix(40))\" on \(describe(element))", fired)
        }

        func pop() -> (String, Bool) {
            guard let nav = navigationController(toPop: keyWindow()?.rootViewController) else {
                return ("back: nothing to pop", false)
            }
            nav.popViewController(animated: true)
            return ("back (pop to \(nav.viewControllers.count - 1))", true)
        }

        func switchTab() -> String {
            let tabs = ["adhan", "quran", "hadith", "islam", "settings"]
            let tab = tabs[random.below(tabs.count)]
            NotificationCenter.default.post(name: Notification.Name("AlIslamDebugSwitchTab"), object: tab)
            return "tab \(tab)"
        }

        func dismissTop() -> (String, Bool) {
            guard let top = topmostViewController(), top.presentingViewController != nil else {
                // Nothing presented: the escape gesture on the top element covers popovers and menus.
                if let window = keyWindow(), window.accessibilityPerformEscape() { return ("escape", true) }
                return ("dismiss: nothing presented", false)
            }
            top.dismiss(animated: true)
            settling = true
            return ("dismiss \(type(of: top))", true)
        }

        func scrollSomething() -> (String, Bool) {
            let scrollers = allViews(of: UIScrollView.self, in: keyWindow()).filter {
                $0.contentSize.height > $0.bounds.height + 20 && $0.bounds.height > 100 && $0.window != nil
                    // A wheel picker's inner table is UIPickerView's own: a person spins the wheel, and the
                    // picker reports the row; a content offset set under it reports rows the picker never had.
                    && !String(describing: type(of: $0)).contains("Picker")
            }
            guard !scrollers.isEmpty else { return ("scroll: nothing scrolls", false) }
            let scroller = scrollers[random.below(scrollers.count)]
            let maxY = max(0, scroller.contentSize.height - scroller.bounds.height + scroller.adjustedContentInset.bottom)
            let y = [0, maxY, CGFloat(random.below(Int(maxY) + 1))][random.below(3)]
            scroller.setContentOffset(CGPoint(x: scroller.contentOffset.x, y: y - scroller.adjustedContentInset.top), animated: true)
            return ("scroll \(type(of: scroller)) to \(Int(y)) of \(Int(maxY))", true)
        }

        // MARK: Mac windows, appearance, rotation

        func scenes() -> [UIWindowScene] {
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        }

        func pinRandomWindowSize() -> String {
            if originalRestrictions == nil, let scene = scenes().first, let restrictions = scene.sizeRestrictions {
                originalRestrictions = (restrictions.minimumSize, restrictions.maximumSize)
                // The ceiling is CGFloat.greatestFiniteMagnitude by default: never Int() it.
                func text(_ size: CGSize) -> String {
                    let w = size.width > 100_000 ? "open" : "\(Int(size.width))"
                    let h = size.height > 100_000 ? "open" : "\(Int(size.height))"
                    return "\(w)x\(h)"
                }
                log("window size floor \(text(restrictions.minimumSize)) ceiling \(text(restrictions.maximumSize))")
            }
            let sizes: [CGSize] = [
                CGSize(width: 320, height: 568), CGSize(width: 390, height: 844), CGSize(width: 500, height: 900),
                CGSize(width: 700, height: 500), CGSize(width: 820, height: 1180), CGSize(width: 1000, height: 700),
                CGSize(width: 1366, height: 1024), CGSize(width: 1600, height: 900), CGSize(width: 400, height: 400),
                CGSize(width: 1100, height: 520)
            ]
            var size = sizes[random.below(sizes.count)]
            if let original = originalRestrictions {
                // Within what a person can do: no smaller than the window's own floor.
                size.width = max(size.width, original.minimum.width)
                size.height = max(size.height, original.minimum.height)
            }
            for scene in scenes() {
                scene.sizeRestrictions?.minimumSize = size
                scene.sizeRestrictions?.maximumSize = size
            }
            pinnedFor = 1 + random.below(6)
            return "resize window to \(Int(size.width))x\(Int(size.height)) for \(pinnedFor) steps"
        }

        func releaseWindowSize() {
            for scene in scenes() {
                scene.sizeRestrictions?.minimumSize = originalRestrictions?.minimum ?? CGSize(width: 320, height: 400)
                scene.sizeRestrictions?.maximumSize = originalRestrictions?.maximum ?? CGSize(width: 8000, height: 8000)
            }
        }

        func flipAppearance() -> String {
            guard let window = keyWindow() else { return "appearance: no window" }
            if random.below(2) == 0 {
                let styles: [UIUserInterfaceStyle] = [.dark, .light, .unspecified]
                let style = styles[random.below(styles.count)]
                window.overrideUserInterfaceStyle = style
                return "appearance style \(style.rawValue)"
            }
            if #available(iOS 17.0, *) {
                let sizes: [UIContentSizeCategory] = [.extraSmall, .medium, .large, .extraExtraExtraLarge, .accessibilityLarge, .accessibilityExtraExtraExtraLarge]
                let size = sizes[random.below(sizes.count)]
                // Through the app's coalescer where it runs (the iPad), as a system change would arrive:
                // a raw override lands the second change inside the bar's animation, the UIKit hang the
                // coalescer exists for (`rawtypesize:` in a script reproduces it on purpose).
                if DynamicTypeCoalescer.isActive {
                    DynamicTypeCoalescer.request(size)
                } else {
                    window.traitOverrides.preferredContentSizeCategory = size
                }
                return "appearance type size \(size.rawValue)"
            }
            return "appearance: no trait overrides before iOS 17"
        }

        func rotate() -> String {
            guard #available(iOS 16.0, *), !isMac else { return "rotate: not here" }
            let masks: [UIInterfaceOrientationMask] = [.portrait, .landscapeLeft, .landscapeRight]
            let mask = masks[random.below(masks.count)]
            for scene in scenes() where scene.activationState == .foregroundActive {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
            }
            return "rotate \(mask.rawValue)"
        }

        /// Mac only: hide the whole app for a moment and bring it back, the way Cmd+H or a click on another
        /// app does. Every scene goes inactive then background and returns, which is where the 2026-10-05
        /// Mac deadlock lived (flushes on the phase change). AppKit is reached by name: an iOS app cannot
        /// import it, but on the Mac it is loaded in the process.
        func hideAndUnhide() -> String {
            guard isMac, let cls = NSClassFromString("NSApplication") as? NSObject.Type,
                  let app = cls.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? NSObject else {
                return "hide: no AppKit here"
            }
            app.perform(NSSelectorFromString("hide:"), with: nil)
            let delay = 0.8 + Double(random.below(20)) / 10
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                app.perform(NSSelectorFromString("unhide:"), with: nil)
                app.perform(NSSelectorFromString("activateIgnoringOtherApps:"), with: true as NSNumber)
            }
            return "hide app for \(delay) s"
        }

        func secondWindow() -> String {
            guard #available(iOS 17.0, *) else { return "window: needs iOS 17" }
            let all = scenes()
            if all.count >= 2, random.below(2) == 0 {
                let others = all.filter { $0.activationState != .foregroundActive }
                guard let scene = others.first else { return "window: all active" }
                UIApplication.shared.requestSceneSessionDestruction(scene.session, options: nil)
                return "window close (\(all.count - 1) left)"
            }
            guard all.count < 4 else { return "window: enough open" }
            UIApplication.shared.activateSceneSession(for: UISceneSessionActivationRequest(role: .windowApplication)) { error in
                NSLog("STRESS second window failed: %@", error.localizedDescription)
            }
            return "window open (\(all.count + 1))"
        }

        // MARK: Settings storm, deep links, playback, text

        func stormSetting() -> String {
            let s = Settings.shared
            let flips: [(String, () -> String)] = [
                ("fontArabicSize", { let v = Double(14 + self.random.below(42)); s.fontArabicSize = v; return "\(v)" }),
                ("englishFontSize", { let v = Double(10 + self.random.below(24)); s.englishFontSize = v; return "\(v)" }),
                ("hadithArabicFontSize", { let v = Double(14 + self.random.below(30)); s.hadithArabicFontSize = v; return "\(v)" }),
                ("hadithEnglishFontSize", { let v = Double(10 + self.random.below(24)); s.hadithEnglishFontSize = v; return "\(v)" }),
                ("showArabicText", { s.showArabicText.toggle(); return "\(s.showArabicText)" }),
                ("beginnerMode", { s.beginnerMode.toggle(); return "\(s.beginnerMode)" }),
                ("showTajweedColors", { s.showTajweedColors.toggle(); return "\(s.showTajweedColors)" }),
                ("highlightAllahNames", { s.highlightAllahNames.toggle(); return "\(s.highlightAllahNames)" }),
                ("cleanArabicText", { s.cleanArabicText.toggle(); return "\(s.cleanArabicText)" }),
                ("removeArabicDots", { s.removeArabicDots.toggle(); return "\(s.removeArabicDots)" }),
                ("wordByWordMeanings", { s.wordByWordMeanings.toggle(); return "\(s.wordByWordMeanings)" }),
                ("wordByWordInline", { s.wordByWordInline.toggle(); return "\(s.wordByWordInline)" }),
                ("showTransliteration", { s.showTransliteration.toggle(); return "\(s.showTransliteration)" }),
                ("showEnglishSaheeh", { s.showEnglishSaheeh.toggle(); return "\(s.showEnglishSaheeh)" }),
                ("showEnglishMustafa", { s.showEnglishMustafa.toggle(); return "\(s.showEnglishMustafa)" }),
                ("classicLook", { s.classicLook.toggle(); return "\(s.classicLook)" }),
                ("simpleMode", { s.simpleMode.toggle(); return "\(s.simpleMode)" }),
                ("quranPageMode", { s.quranPageMode.toggle(); return "\(s.quranPageMode)" }),
                ("mushafTwoPageSpread", { s.mushafTwoPageSpread.toggle(); return "\(s.mushafTwoPageSpread)" }),
                ("mushafPageLanguage", { let v = ["arabic", "pdf", "english"][self.random.below(3)]; s.mushafPageLanguage = v; return v }),
                ("showSkyView", { s.showSkyView.toggle(); return "\(s.showSkyView)" }),
                ("skyFillsAdhanTab", { s.skyFillsAdhanTab.toggle(); return "\(s.skyFillsAdhanTab)" }),
                ("betaQiraatEnabled", { s.betaQiraatEnabled.toggle(); return "\(s.betaQiraatEnabled)" }),
                ("showOtherQiraatReciters", { s.showOtherQiraatReciters.toggle(); return "\(s.showOtherQiraatReciters)" }),
                ("showDuha", { s.showDuha.toggle(); return "\(s.showDuha)" }),
                ("gridMode", { s.gridMode.toggle(); return "\(s.gridMode)" }),
                ("accentColor", { let all = AccentColor.allCases; let v = all[self.random.below(all.count)]; s.accentColor = v; return v.rawValue }),
                ("customAccentColorHex", { let v = String(format: "%06X", self.random.below(0xFFFFFF)); s.customAccentColorHex = v; return v }),
                ("colorSchemeString", { let v = ["system", "light", "dark", "sepia", "gray", "custom"][self.random.below(6)]; s.colorSchemeString = v; return v }),
                ("displayQiraah", {
                    var tags = ["", "Shubah an Asim", "Khalaf an Hamzah", "al-Bazzi an Ibn Kathir", "Qunbul an Ibn Kathir",
                                "Warsh an Nafi", "Qalun an Nafi", "ad-Duri an Abi Amr", "as-Susi an Abi Amr"]
                    if s.betaQiraatEnabled {
                        tags += ["Hisham an Ibn Amir", "Ibn Dhakwan an Ibn Amir", "Khallad an Hamzah", "Abu al-Harith an al-Kisai",
                                 "ad-Duri an al-Kisai", "Ibn Wardan an Abi Jafar", "Ibn Jammaz an Abi Jafar", "Ruways an Yaqub",
                                 "Rawh an Yaqub", "Ishaq an Khalaf al-Ashir", "Idris an Khalaf al-Ashir"]
                    }
                    let v = tags[self.random.below(tags.count)]
                    s.displayQiraah = v
                    return v.isEmpty ? "Hafs" : v
                }),
                ("islamArabicFontFace", { let all = Settings.IslamArabicFace.allCases; let v = all[self.random.below(all.count)]; s.islamArabicFaceRaw = v.rawValue; return v.rawValue }),
                ("launchTab", { let v = ["adhan", "quran", "hadith", "islam", "settings"][self.random.below(5)]; s.launchTabRaw = v; return v }),
            ]
            let (name, flip) = flips[random.below(flips.count)]
            let value: String
            if random.below(2) == 0 {
                value = withAnimation(.easeInOut) { flip() }
            } else {
                value = flip()
            }
            return "setting \(name) = \(value)"
        }

        func deepLink() -> String {
            let surah = 1 + random.below(114)
            let count = QuranData.shared.quran.indices.contains(surah - 1) ? QuranData.shared.quran[surah - 1].numberOfAyahs : 7
            let ayah = 1 + random.below(max(1, count))
            switch random.below(9) {
            case 0: AppNavigation.shared.open(.tab); return "deep link quran tab"
            case 1: AppNavigation.shared.open(.surah(surah)); return "deep link surah \(surah)"
            case 2: AppNavigation.shared.open(.ayah(surah, ayah)); return "deep link ayah \(surah):\(ayah)"
            case 3: AppNavigation.shared.openIslam(.duas); return "deep link duas"
            case 4: AppNavigation.shared.openIslam(.adhkar); return "deep link adhkar"
            case 5: let n = random.below(2) == 0 ? nil : 1 + random.below(99); AppNavigation.shared.openIslam(.names(n)); return "deep link names \(n.map(String.init) ?? "all")"
            case 6: AppNavigation.shared.openAdhan(.qibla); return "deep link qibla"
            case 7:
                let queries = ["الصبر", "mercy", "2:255", "yaseen", "", "%", "9999", "الرحمن الرحيم", "a", "١٢٣"]
                let q = queries[random.below(queries.count)]
                QuranSearchHandoff.shared.request(q)
                return "deep link quran search \"\(q)\""
            default: AppNavigation.shared.openIslam(.hadithTab); return "deep link hadith tab"
            }
        }

        func playback() -> String {
            let player = QuranPlayer.shared
            let surah = 1 + random.below(114)
            guard QuranData.shared.quran.indices.contains(surah - 1) else { return "playback: quran not loaded" }
            let name = QuranData.shared.quran[surah - 1].nameTransliteration
            let count = QuranData.shared.quran[surah - 1].numberOfAyahs
            switch random.below(10) {
            case 0, 1: _ = player.playSurah(surahNumber: surah, surahName: name); return "play surah \(surah)"
            case 2: let a = 1 + random.below(max(1, count)); _ = player.playAyah(surahNumber: surah, ayahNumber: a); return "play ayah \(surah):\(a)"
            case 3: let a = 1 + random.below(max(1, count)); _ = player.playAyah(surahNumber: surah, ayahNumber: a, continueRecitation: true); return "play from ayah \(surah):\(a)"
            case 4: player.pause(); return "pause"
            case 5: player.resume(); return "resume"
            case 6: player.skipForward(); return "skip forward"
            case 7: player.seek(by: Double(random.below(120)) - 30); return "seek"
            case 8: ArabicSpeech.shared.speak(["بِسْمِ ٱللَّهِ", "ٱلْحَمْدُ لِلَّهِ", "قل"][random.below(3)]); return "speak"
            default: player.stop(); ArabicSpeech.shared.stop(); return "stop"
            }
        }

        func typeSomething() -> (String, Bool) {
            let fields = allViews(of: UITextField.self, in: keyWindow()).filter { $0.window != nil && $0.isEnabled && $0.bounds.width > 20 }
            let views = allViews(of: UITextView.self, in: keyWindow()).filter { $0.window != nil && $0.isEditable && $0.bounds.width > 20 }
            let inputs = ["2:300", "999:1", "1:0", "0", "-1", "114:7", "2:286", "1:1:1", "2:", ":5",
                          "9999999999999999999", "-9223372036854775808", "0.0000001", "1e309", "a", "  ", "%", "\\", "''",
                          "bukhari 99999", "muslim 0", "Allah", "sabr", "رحمن", "١٢٣", "\u{202E}abc", "😀🕌", String(repeating: "ب", count: 300)]
            let text = inputs[random.below(inputs.count)]
            if !fields.isEmpty, views.isEmpty || random.below(2) == 0 {
                let field = fields[random.below(fields.count)]
                field.becomeFirstResponder()
                if random.below(3) == 0 { field.text = ""; field.sendActions(for: .editingChanged) }
                field.insertText(text)
                field.sendActions(for: .editingChanged)
                if random.below(2) == 0 {
                    _ = field.delegate?.textFieldShouldReturn?(field)
                    field.resignFirstResponder()
                }
                return ("type \"\(text.prefix(30))\" into \(type(of: field)) \"\((field.placeholder ?? "").prefix(30))\"", true)
            }
            if !views.isEmpty {
                let view = views[random.below(views.count)]
                view.becomeFirstResponder()
                view.insertText(text)
                if random.below(2) == 0 { view.resignFirstResponder() }
                return ("type \"\(text.prefix(30))\" into text view", true)
            }
            return ("type: no text field", false)
        }

        /// The MonkeyTests list, plus system prompts: nothing that leaves the app, reaches an account
        /// or the network on purpose, asks the system for a permission, or throws data away.
        func isOffLimits(_ label: String) -> Bool {
            let lowered = label.lowercased()
            let phrases = ["delete", "remove", "reset", "erase", "clear", "sign out", "share", "app store",
                           "mail", "contact", "website", "safari", "open in", "report", "feedback", "icloud",
                           "back up", "backup", "restore", "download", "export", "import", "open settings",
                           "privacy", "terms", "donate", "github", "instagram", "youtube", "twitter", "discord",
                           "tiktok", "facebook", "whatsapp", "telegram", "save to photos", "save image",
                           "wallpaper", "unbookmark", "unfavorite", "forget", "log out", "subscribe", "purchase",
                           "copy link", "open link", "view on", "dictat", "sign in", "allow", "turn on notifications",
                           "enable notifications", "location", "apple weather", "weatherkit", "open system",
                           "quit", "erase everything", "cloud", "directions", "open in maps", "navigate", "get there"]
            if phrases.contains(where: { lowered.contains($0) }) { return true }
            let wholeWords: Set<String> = ["rate", "review", "call", "send", "buy", "map", "maps", "exit", "route"]
            let tokens = lowered.split(whereSeparator: { !$0.isLetter })
            return tokens.contains { wholeWords.contains(String($0)) }
        }
    }

    // MARK: - The accessibility bridge

    /// SwiftUI builds its accessibility nodes, and UIKit loads its accessibility bundles, only once
    /// the process has accessibility enabled, which the system does when VoiceOver or an automation
    /// client (XCUITest) attaches. In-process there is no client, so the walk turns it on itself
    /// through libAccessibility's `_AXSApplicationAccessibilitySetEnabled` (private; DEBUG and this
    /// walk only). Without it `accessibilityElements` is nil on every hosting view and the walk has
    /// nothing to activate (2026-10-12, the first run: 0 activations in 60 steps).
    enum AccessibilityBridge {
        @MainActor
        static func enable() -> String {
            typealias SetEnabled = @convention(c) (Int32) -> Void
            typealias IsEnabled = @convention(c) () -> Int32
            guard let handle = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW) else {
                return "libAccessibility not found"
            }
            var report = ""
            if let sym = dlsym(handle, "_AXSApplicationAccessibilityEnabled") {
                let isEnabled = unsafeBitCast(sym, to: IsEnabled.self)
                report += "was \(isEnabled())"
            }
            guard let set = dlsym(handle, "_AXSApplicationAccessibilitySetEnabled") else {
                return report + " setter missing"
            }
            unsafeBitCast(set, to: SetEnabled.self)(1)
            if let sym = dlsym(handle, "_AXSApplicationAccessibilityEnabled") {
                let isEnabled = unsafeBitCast(sym, to: IsEnabled.self)
                report += " now \(isEnabled())"
            }
            // UIKit reads the flag when it loads its accessibility bundles; the private
            // `_accessibilityInit` is what the system calls, and a message to it is harmless if absent.
            let app = UIApplication.shared
            let selector = NSSelectorFromString("_accessibilityInit")
            if app.responds(to: selector) {
                _ = app.perform(selector)
                report += " +init"
            }
            return report
        }
    }

    // MARK: - Trail, heartbeat and watchdog

    /// The step counter and the trail file (Library/stress/trail-<seed>.log, synchronised after every
    /// line), written from the main thread and from the watchdog thread.
    final class Trail: @unchecked Sendable {
        private let lock = NSLock()
        private let handle: FileHandle?
        private var currentStep = 0
        let url: URL

        init(seed: UInt64) {
            let dir = StateGuard.libraryDirectory.appendingPathComponent("stress")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            url = dir.appendingPathComponent("trail-\(seed).log")
            FileManager.default.createFile(atPath: url.path, contents: nil)
            handle = try? FileHandle(forWritingTo: url)
        }

        var step: Int {
            get { lock.lock(); defer { lock.unlock() }; return currentStep }
            set { lock.lock(); currentStep = newValue; lock.unlock() }
        }

        func log(_ text: String) {
            lock.lock()
            let line = "STRESS \(currentStep) \(text)"
            NSLog("%@", line)
            if let data = (line + "\n").data(using: .utf8) {
                handle?.write(data)
                try? handle?.synchronize()
            }
            lock.unlock()
        }
    }

    /// The main thread's last sign of life, written on main and read from the watchdog thread.
    final class Beat: @unchecked Sendable {
        private let lock = NSLock()
        private var last = Date()
        func touch() { lock.lock(); last = Date(); lock.unlock() }
        var age: TimeInterval { lock.lock(); defer { lock.unlock() }; return Date().timeIntervalSince(last) }
    }

    /// A main-queue timer keeps the beat fresh while the walk sleeps; a plain thread reads it. When
    /// the main thread stops answering for 12 s the thread logs `STRESS HANG` (NSLog works from any
    /// thread, and so does the trail file), which is what a deadlock looks like from outside.
    enum Watchdog {
        nonisolated(unsafe) private static var timer: DispatchSourceTimer?
        nonisolated(unsafe) private static var running = false

        static func start(trail: Trail, beat: Beat) {
            let timer = DispatchSource.makeTimerSource(queue: .main)
            timer.schedule(deadline: .now(), repeating: 1.0)
            timer.setEventHandler { beat.touch() }
            timer.resume()
            self.timer = timer
            running = true
            // "-stressHangAfter <s>": the silence that counts as a hang (12 s). Lower it to sample a
            // stall that recovers before the driver's poll reaches it (the 13-second audio stalls, 2026-10-13).
            let args = ProcessInfo.processInfo.arguments
            let limit = args.firstIndex(of: "-stressHangAfter").flatMap { args.indices.contains($0 + 1) ? Double(args[$0 + 1]) : nil } ?? 12
            let thread = Thread {
                var reported = false
                while running {
                    Thread.sleep(forTimeInterval: min(2, limit / 2))
                    let age = beat.age
                    if age > limit, !reported {
                        reported = true
                        trail.log("HANG main thread silent for \(Int(age)) s")
                    } else if age < 2 {
                        reported = false
                    }
                }
            }
            thread.name = "StressWalker.watchdog"
            thread.start()
        }

        static func stop() {
            running = false
            timer?.cancel()
            timer = nil
        }
    }

    // MARK: - The container guard

    /// What a walk may change and must put back: both defaults domains (the app's and the app
    /// group's, replaced whole with `setPersistentDomain`) and the files under Documents and
    /// Application Support (reciter downloads excepted: large, and the walk never touches them, its
    /// off-limits list covers every download and delete control). The snapshot lives in
    /// Library/stress-backup with a `pending` marker; a walk that finds one keeps it (it is the clean
    /// state, the last walk died) rather than snapshotting the state it died in.
    enum StateGuard {
        static let groupSuite = "group.com.IslamicPillars.AppGroup"
        static var libraryDirectory: URL { FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0] }
        static var backupDirectory: URL { libraryDirectory.appendingPathComponent("stress-backup") }
        static var pendingMarker: URL { backupDirectory.appendingPathComponent("pending") }
        static let fileRoots: [(name: String, url: URL)] = [
            ("Documents", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]),
            ("ApplicationSupport", FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]),
        ]
        static let skippedFolders: Set<String> = ["ReciterDownloads", "stress", "stress-backup", ".DS_Store"]

        /// Takes the snapshot, or keeps a pending one. Returns a word for the log.
        static func begin() -> String {
            let fm = FileManager.default
            if fm.fileExists(atPath: pendingMarker.path) { return "kept pending snapshot" }
            try? fm.removeItem(at: backupDirectory)
            try? fm.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            let bundleID = Bundle.main.bundleIdentifier ?? "com.Quran.Elmallah.Islamic-Pillars"
            let main = UserDefaults.standard.persistentDomain(forName: bundleID) ?? [:]
            let group = UserDefaults(suiteName: groupSuite)?.persistentDomain(forName: groupSuite) ?? [:]
            var ok = write(plist: main, to: "defaults-main.plist") && write(plist: group, to: "defaults-group.plist")
            for root in fileRoots {
                let dst = backupDirectory.appendingPathComponent("files-\(root.name)")
                ok = copyTree(from: root.url, to: dst) && ok
            }
            guard ok else { return "snapshot FAILED (nothing will be restored)" }
            fm.createFile(atPath: pendingMarker.path, contents: Data("\(Date())".utf8))
            return "snapshot taken"
        }

        /// Puts the snapshot back and clears the marker. False when there was nothing pending.
        @discardableResult
        static func restoreIfPending() -> Bool {
            let fm = FileManager.default
            guard fm.fileExists(atPath: pendingMarker.path) else { return false }
            let bundleID = Bundle.main.bundleIdentifier ?? "com.Quran.Elmallah.Islamic-Pillars"
            if let main = read(plist: "defaults-main.plist") {
                UserDefaults.standard.setPersistentDomain(main, forName: bundleID)
            }
            if let group = read(plist: "defaults-group.plist"), let suite = UserDefaults(suiteName: groupSuite) {
                suite.setPersistentDomain(group, forName: groupSuite)
            }
            UserDefaults.standard.synchronize()
            for root in fileRoots {
                let src = backupDirectory.appendingPathComponent("files-\(root.name)")
                guard fm.fileExists(atPath: src.path) else { continue }
                // Drop what the walk added, then copy the snapshot back over what it changed.
                for name in (try? fm.contentsOfDirectory(atPath: root.url.path)) ?? [] where !skippedFolders.contains(name) {
                    try? fm.removeItem(at: root.url.appendingPathComponent(name))
                }
                _ = copyTree(from: src, to: root.url)
            }
            try? fm.removeItem(at: pendingMarker)
            NSLog("STRESS state restored from %@", backupDirectory.path)
            return true
        }

        private static func write(plist: [String: Any], to name: String) -> Bool {
            guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0) else { return false }
            return (try? data.write(to: backupDirectory.appendingPathComponent(name))) != nil
        }

        private static func read(plist name: String) -> [String: Any]? {
            guard let data = try? Data(contentsOf: backupDirectory.appendingPathComponent(name)) else { return nil }
            return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
        }

        /// Copies a folder's top-level entries (files and folders) into another folder, skipping the
        /// excluded names; existing entries at the destination are replaced.
        private static func copyTree(from src: URL, to dst: URL) -> Bool {
            let fm = FileManager.default
            try? fm.createDirectory(at: dst, withIntermediateDirectories: true)
            guard let names = try? fm.contentsOfDirectory(atPath: src.path) else { return true }
            var ok = true
            for name in names where !skippedFolders.contains(name) {
                let from = src.appendingPathComponent(name)
                let to = dst.appendingPathComponent(name)
                try? fm.removeItem(at: to)
                do { try fm.copyItem(at: from, to: to) } catch {
                    NSLog("STRESS snapshot copy failed for %@: %@", name, error.localizedDescription)
                    ok = false
                }
            }
            return ok
        }
    }

    /// SplitMix64, the same generator as MonkeyTests, so a seed always walks the same path.
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
}
#endif
