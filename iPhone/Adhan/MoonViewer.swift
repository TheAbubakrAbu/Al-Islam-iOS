#if os(iOS)
import SwiftUI
import SceneKit

// The moon up close (Abu, 2026-09-25: "When touching the moon i want it to take up the whole space and
// allow me to rotate it and view it and stuff would be nice"). Tapping the sky card's moon (the
// footer's phase glyph, or the marker riding the night's arc) opens this over the whole screen: the
// real moon as a globe, lit from where the sun actually is that night, that a finger can turn and
// pinch, with the phase, the Hijri date and the next full and new moons under it, and a slider that
// walks the month so the terminator can be watched sweeping across it.
//
// The globe is NASA's: the Scientific Visualization Studio's CGI Moon Kit (svs.gsfc.nasa.gov/4720),
// public domain, credited in Credits. `MoonColor.jpg` is the kit's own 2048 x 1024 LROC colour map,
// unchanged; `MoonNormal.jpg` (1536 x 768) is baked from the kit's LOLA elevation map (16 px/deg,
// slopes x3) so the craters stand up along the terminator. Both ship in the iPhone target only.
//
// SceneKit rather than RealityKit because the app still supports iOS 15, and RealityKit's SwiftUI
// view starts at iOS 18.

// MARK: - Opening

/// One opening of the moon viewer.
struct MoonViewerRequest: Identifiable {
    let id = UUID()
    /// The moment it opens on: now, or the day the prayer list is browsing.
    let date: Date
    /// True when `date` is now, which the day control then calls "Now".
    let isLive: Bool
    /// Which moon it grew out of, for the zoom: "footer" or "arc".
    let source: String
}

extension View {
    /// Marks a moon the viewer can zoom out of (iOS 18; nothing before).
    @ViewBuilder
    func moonZoomSource(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// The viewer's side of that zoom: it grows out of the moon that was touched and shrinks back
    /// into it on close. Before iOS 18 the cover simply rises.
    @ViewBuilder
    func moonZoomTransition(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}

// MARK: - The screen

struct MoonViewer: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let isLive: Bool

    /// Days from `date`, walked by the slider.
    @State private var dayOffset = 0
    /// Lights the whole face as if it were full, to look at the features whatever the phase.
    @State private var fullLight = false
    /// Bumped to send the globe home (facing Earth, at rest).
    @State private var resetToken = 0
    /// True once the globe has been turned or zoomed away from home, which shows the way back.
    @State private var isAway = false
    @State private var showsHint = true
    /// False until the globe's first frame is on screen; until then the flat moon stands in its place.
    @State private var globeReady = false
    /// The bar and the panel, in global space: the globe sits in what they leave.
    @State private var topBarFrame: CGRect = .zero
    @State private var panelFrame: CGRect = .zero

    private var shownDate: Date { date.addingTimeInterval(TimeInterval(dayOffset) * 86_400) }

    init(date: Date, isLive: Bool) {
        self.date = date
        self.isLive = isLive
        #if DEBUG
        // Screenshot hooks: `-moonViewerDays <n>` opens that many days on, `-moonViewerFullLight`
        // with the whole face lit (the globe's own turn and zoom have theirs in `MoonGlobeController`).
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-moonViewerDays"), arguments.indices.contains(index + 1),
           let days = Int(arguments[index + 1]) {
            _dayOffset = State(initialValue: max(-15, min(15, days)))
        }
        if arguments.contains("-moonViewerFullLight") { _fullLight = State(initialValue: true) }
        #endif
    }

    var body: some View {
        let phase = MoonPhase.on(shownDate)
        GeometryReader { root in
            let wide = root.size.width > root.size.height * 1.1
            ZStack {
                GeometryReader { globe in
                    let region = globeRegion(globe: globe.frame(in: .global), wide: wide)
                    MoonGlobe(phase: phase, fullLight: fullLight, resetToken: resetToken, region: region,
                              onInteract: hideHint,
                              onAwayChange: { away in withAnimation(.easeInOut(duration: 0.2)) { isAway = away } },
                              onReady: { withAnimation(.easeOut(duration: 0.35)) { globeReady = true } })

                    // The card's flat moon, exactly where and as large as the globe will be, while
                    // SceneKit loads the maps and builds the lunar shader (about half a second, which
                    // showed as black after the zoom landed). The screen grows out of the tapped
                    // moon with this one in it, and it turns to the globe when the first frame is up.
                    MoonPhaseView(date: shownDate,
                                  diameter: CGFloat(MoonGlobeController.fill) * min(region.width, region.height))
                        .position(x: region.midX, y: region.midY)
                        .opacity(globeReady ? 0 : 1)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .ignoresSafeArea()

                chrome(phase: phase, wide: wide)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        // The panel has to leave the moon most of the screen.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .statusBarHidden()
        .task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            hideHint()
        }
    }

    /// Where the globe sits, in its own view's points: under the bar and above the panel, or right of
    /// the panel on a wide screen. Before the first layout reports the two, a plain inset.
    private func globeRegion(globe: CGRect, wide: Bool) -> CGRect {
        let whole = CGRect(origin: .zero, size: globe.size)
        guard topBarFrame != .zero, panelFrame != .zero else { return whole.insetBy(dx: 16, dy: 80) }
        let top = topBarFrame.maxY - globe.minY
        let region: CGRect
        if wide {
            let left = panelFrame.maxX - globe.minX
            region = CGRect(x: left, y: top, width: globe.width - left, height: panelFrame.maxY - globe.minY - top)
        } else {
            region = CGRect(x: 0, y: top, width: globe.width, height: panelFrame.minY - globe.minY - top)
        }
        return region.insetBy(dx: 12, dy: 10)
    }

    private func hideHint() {
        guard showsHint else { return }
        withAnimation(.easeOut(duration: 0.4)) { showsHint = false }
    }

    // MARK: Chrome

    @ViewBuilder
    private func chrome(phase: MoonPhase, wide: Bool) -> some View {
        VStack(spacing: 0) {
            topBar
                .reportingFrame(into: $topBarFrame)

            Spacer(minLength: 0)

            if wide {
                HStack(alignment: .bottom, spacing: 0) {
                    panel(phase)
                        .frame(width: 350)
                        .reportingFrame(into: $panelFrame)
                    Spacer(minLength: 0)
                }
            } else {
                hint
                    .padding(.bottom, 10)
                panel(phase)
                    .frame(maxWidth: 560)
                    .reportingFrame(into: $panelFrame)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            if wide {
                hint.padding(.bottom, 16)
            }
        }
    }

    private var hint: some View {
        Text("Drag to turn, pinch to zoom, double-tap to face Earth")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .opacity(showsHint ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            circleButton(fullLight ? "sun.max.fill" : "sun.max", active: fullLight) {
                fullLight.toggle()
            }
            .accessibilityLabel("Full Light")
            .accessibilityValue(fullLight ? "On" : "Off")

            if isAway {
                circleButton("arrow.counterclockwise") {
                    resetToken &+= 1
                }
                .accessibilityLabel("Face Earth")
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Where every full-screen overlay in the app keeps its X (`FocusOverlay`).
            circleButton("xmark") {
                dismiss()
            }
            .accessibilityLabel("Close")
        }
        .padding(.top, 8)
    }

    private func circleButton(_ systemImage: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .conditionalGlassEffect(circle: true, useColor: active ? 0.3 : nil)
        }
        .buttonStyle(.plain)
    }

    // MARK: Panel

    private func panel(_ phase: MoonPhase) -> some View {
        let cycle = MoonPhase.cycle(around: shownDate)
        let hijri = hijriDate(for: shownDate)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(phase.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)

                    Text(detailLine(phase, cycle: cycle))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                // The flat glyph the card shows, as the legend for the globe's lighting.
                MoonPhaseView(date: shownDate, diameter: 36)
            }

            if let hijri {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(settings.accentColor.color)
                        Text(hijri.text)
                            .foregroundColor(.primary)
                    }
                    .font(.subheadline.weight(.semibold))

                    // The white days are the full moon's nights: the Sunnah fast of every month.
                    if (13...15).contains(hijri.day) {
                        Text("A White Day: fasting the 13th, 14th and 15th of the month is Sunnah (Sunan al-Tirmidhi 761, graded hasan sahih by al-Albani).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let cycle {
                HStack(spacing: 10) {
                    eventTile("NEXT FULL MOON", cycle.nextFullMoon)
                    eventTile("NEXT NEW MOON", cycle.nextNewMoon)
                }
            }

            dayControl
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect(rectangle: true)
    }

    private func detailLine(_ phase: MoonPhase, cycle: MoonPhase.Cycle?) -> String {
        let lit = "\(phase.illuminationPercent)% illuminated"
        guard let cycle else { return lit }
        let age = cycle.age(at: shownDate)
        return "\(lit) · \(String(format: "%.1f", age)) days old"
    }

    private func eventTile(_ title: String, _ event: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(event, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            Text(daysUntil(event))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.07)))
    }

    /// Calendar days from the day being shown, which is what the tiles are read against.
    private func daysUntil(_ event: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: shownDate),
                                           to: calendar.startOfDay(for: event)).day ?? 0
        switch days {
        case ..<1: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(days) days"
        }
    }

    private var dayControl: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(dayOffset == 0 && isLive ? "Now" : shownDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                if dayOffset != 0 {
                    Text(dayOffset > 0 ? "+\(dayOffset) \(dayOffset == 1 ? "day" : "days")"
                                       : "\u{2212}\(-dayOffset) \(dayOffset == -1 ? "day" : "days")")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if dayOffset != 0 {
                    Button {
                        settings.hapticFeedback()
                        dayOffset = 0
                    } label: {
                        Text(isLive ? "Back to Now" : "Back")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Plain, never animated (an animated binding makes a control's thumb bounce); the globe
            // eases the light on its own.
            Slider(value: Binding(
                get: { Double(dayOffset) },
                set: { value in
                    let day = Int(value.rounded())
                    guard day != dayOffset else { return }
                    dayOffset = day
                    settings.hapticFeedback()
                }
            ), in: -15...15, step: 1)
            .tint(settings.accentColor.color)
            .accessibilityLabel("Day")
            .accessibilityValue(dayOffset == 0 ? "Now" : shownDate.formatted(date: .complete, time: .omitted))
        }
    }

    // MARK: Hijri

    /// The Hijri date of `date`, the way the Adhan tab's header writes it: Umm al-Qura, the user's
    /// adjustment, and the day turning at Maghrib when that is on (`effectiveHijriReferenceDate`).
    private func hijriDate(for date: Date) -> (text: String, day: Int)? {
        let reference = settings.effectiveHijriReferenceDate(now: date)
        let calendar = settings.hijriCalendar
        guard let adjusted = calendar.date(byAdding: .day, value: settings.hijriOffset, to: reference) else { return nil }
        return (Self.hijriFormatter.string(from: adjusted), calendar.component(.day, from: adjusted))
    }

    /// The header's English Hijri format (`Settings.updateDates`).
    private static let hijriFormatter: DateFormatter = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en")
        formatter.dateStyle = .long
        return formatter
    }()
}

private extension View {
    /// Keeps `frame` at this view's frame in global space.
    func reportingFrame(into frame: Binding<CGRect>) -> some View {
        background(GeometryReader { geo in
            Color.clear
                .onAppear { frame.wrappedValue = geo.frame(in: .global) }
                .onChange(of: geo.frame(in: .global)) { frame.wrappedValue = $0 }
        })
    }
}

// MARK: - The globe

private struct MoonGlobe: UIViewRepresentable {
    let phase: MoonPhase
    let fullLight: Bool
    let resetToken: Int
    /// Where the globe sits, in this view's points; it fills most of the rect's shorter side.
    let region: CGRect
    let onInteract: () -> Void
    let onAwayChange: (Bool) -> Void
    let onReady: () -> Void

    func makeCoordinator() -> MoonGlobeController { MoonGlobeController() }

    func makeUIView(context: Context) -> MoonGlobeView {
        context.coordinator.makeView()
    }

    func updateUIView(_ view: MoonGlobeView, context: Context) {
        let controller = context.coordinator
        controller.onInteract = onInteract
        controller.onAwayChange = onAwayChange
        controller.onReady = onReady
        controller.show(phase)
        controller.setFullLight(fullLight)
        controller.setRegion(region)
        controller.reset(token: resetToken)
        view.accessibilityLabel = "The moon, \(phase.name), \(phase.illuminationPercent) percent illuminated"
    }

    static func dismantleUIView(_ view: MoonGlobeView, coordinator: MoonGlobeController) {
        coordinator.stop()
    }
}

/// An `SCNView` that tells its controller when its size changes: the framing is worked out from it.
final class MoonGlobeView: SCNView {
    var onLayout: ((CGSize) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds.size)
    }
}

/// The scene and the hands on it. The camera ORBITS a still moon: yaw around the moon's axis, then
/// pitch, two nested nodes so that turning sideways after tilting stays a turn and never becomes a
/// roll. The sun stays where it is, so orbiting walks round the terminator: at new moon the far side
/// is the lit one, and it can be gone round to and seen.
final class MoonGlobeController: NSObject, UIGestureRecognizerDelegate, SCNSceneRendererDelegate {
    private let scene = SCNScene()
    private let yawNode = SCNNode()
    private let pitchNode = SCNNode()
    private let cameraNode = SCNNode()
    private let camera = SCNCamera()
    private let sunNode = SCNNode()
    private let sun = SCNLight()
    private let earthshine = SCNLight()
    private let headlight = SCNLight()
    private weak var view: MoonGlobeView?
    private var momentumLink: CADisplayLink?

    var onInteract: () -> Void = {}
    var onAwayChange: (Bool) -> Void = { _ in }
    var onReady: () -> Void = {}
    /// Set once the first frame with the scene in it has rendered (on SceneKit's render thread).
    private var hasRendered = false

    private var yaw: Float = 0
    private var pitch: Float = 0
    /// The globe's size on screen against its size at rest.
    private var zoom: Float = 1
    private var pinchStartZoom: Float = 1
    /// Points per second, from the end of a drag.
    private var velocity = SIMD2<Float>(0, 0)
    private var region: CGRect = .zero
    private var size: CGSize = .zero
    private var phase: MoonPhase?
    private var fullLight: Bool?
    private var resetToken: Int?
    private var isAway = false

    /// Vertical, in degrees: long, like a telephoto, so the sphere is not bent by perspective.
    private static let fieldOfView: CGFloat = 25
    /// How much of its region's shorter side the globe fills at rest (the stand-in moon is drawn to it).
    static let fill: Float = 0.88
    private static let pitchLimit: Float = 1.4
    private static let zoomRange: ClosedRange<Float> = 0.55...8

    func makeView() -> MoonGlobeView {
        let view = MoonGlobeView(frame: .zero, options: nil)
        view.backgroundColor = .black
        view.antialiasingMode = .multisampling4X
        view.pointOfView = cameraNode
        view.isAccessibilityElement = true
        view.accessibilityTraits = .image
        view.accessibilityHint = "Drag to turn it, pinch to zoom, double-tap to face Earth."
        view.onLayout = { [weak self] size in self?.layout(size) }
        buildScene()
        addGestures(to: view)
        self.view = view
        // The maps and the shader are readied off the main thread, and the scene goes up only once
        // they are: attached at once, it rendered black for its first half second. The stand-in moon
        // covers the wait (`MoonViewer`), and `onReady` fires once the first real frame has rendered.
        view.delegate = self
        view.prepare([scene]) { [weak self, weak view] _ in
            DispatchQueue.main.async {
                guard let self, let view else { return }
                view.scene = self.scene
                view.pointOfView = self.cameraNode
            }
        }
        #if DEBUG
        // `-moonViewerYaw <deg>`, `-moonViewerPitch <deg>`, `-moonViewerZoom <x>`: a turned or zoomed
        // globe for screenshots, since a drag cannot be scripted into a launch.
        let arguments = ProcessInfo.processInfo.arguments
        func value(_ name: String) -> Float? {
            guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
            return Float(arguments[index + 1])
        }
        if let degrees = value("-moonViewerYaw") { yaw = degrees * .pi / 180 }
        if let degrees = value("-moonViewerPitch") { pitch = degrees * .pi / 180 }
        if let debugZoom = value("-moonViewerZoom") { zoom = min(max(debugZoom, Self.zoomRange.lowerBound), Self.zoomRange.upperBound) }
        #endif
        return view
    }

    func stop() {
        momentumLink?.invalidate()
        momentumLink = nil
    }

    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard !hasRendered else { return }
        hasRendered = true
        DispatchQueue.main.async { [weak self] in self?.onReady() }
    }

    // MARK: Scene

    private func buildScene() {
        scene.background.contents = UIColor.black

        let sphere = SCNSphere(radius: 1)
        sphere.segmentCount = 144
        let material = SCNMaterial()
        material.lightingModel = .lambert
        material.diffuse.contents = Bundle.main.url(forResource: "MoonColor", withExtension: "jpg")
        material.diffuse.mipFilter = .linear
        material.diffuse.maxAnisotropy = 8
        material.normal.contents = Bundle.main.url(forResource: "MoonNormal", withExtension: "jpg")
        material.normal.mipFilter = .linear
        material.locksAmbientWithDiffuse = true
        material.shaderModifiers = [.lightingModel: Self.lunarReflectance]
        sphere.firstMaterial = material
        // Unturned: `SCNSphere` puts the middle of its texture on +z, which is where the camera
        // rests, and the kit's map is centred on 0 degrees longitude, the middle of the near side.
        // A quarter turn here showed Giordano Bruno at the centre, 103 degrees east.
        scene.rootNode.addChildNode(SCNNode(geometry: sphere))

        sun.type = .directional
        sun.color = UIColor(red: 1, green: 0.98, blue: 0.94, alpha: 1)
        sunNode.light = sun
        scene.rootNode.addChildNode(sunNode)

        // Earthshine: sunlight off the Earth, falling on the near side only (the far side never sees
        // the Earth), bluish, and strongest near new moon, when the Earth is nearly full in the moon's
        // sky. It is what shows the dark part of a crescent as a faint whole disc.
        earthshine.type = .directional
        earthshine.color = UIColor(red: 0.62, green: 0.71, blue: 0.95, alpha: 1)
        let earthNode = SCNNode()
        earthNode.light = earthshine
        earthNode.position = SCNVector3(0, 0, 50)
        earthNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(earthNode)

        // A trace of starlight everywhere, so the unlit far side is still a shape against the sky.
        let starlight = SCNLight()
        starlight.type = .ambient
        starlight.intensity = 10
        let starlightNode = SCNNode()
        starlightNode.light = starlight
        scene.rootNode.addChildNode(starlightNode)

        camera.fieldOfView = Self.fieldOfView
        camera.zNear = 0.02
        camera.zFar = 3000
        cameraNode.camera = camera
        // Full Light: a light that rides with the camera, so whatever faces it is lit.
        headlight.type = .directional
        headlight.intensity = 0
        let headlightNode = SCNNode()
        headlightNode.light = headlight
        cameraNode.addChildNode(headlightNode)

        pitchNode.addChildNode(cameraNode)
        yawNode.addChildNode(pitchNode)
        scene.rootNode.addChildNode(yawNode)

        // The long lens sees under 1% of the sky at once, so the sphere holds enough stars for a
        // hundred or so to be in view wherever the camera turns.
        scene.rootNode.addChildNode(Self.starField(count: 16_000, radius: 1.0...1.3, brightness: 0.3...0.75, seed: 0x5EED_2609))
        scene.rootNode.addChildNode(Self.starField(count: 2_400, radius: 1.5...2.2, brightness: 0.7...1, seed: 0x5EED_2610))
    }

    /// The moon is not a matte ball. Lambert's law darkens a sphere toward its rim, and a full moon
    /// does not darken: it is lit nearly edge to edge, which is the Lommel-Seeliger law of dusty
    /// surfaces (brightness as incidence over incidence plus emission). Mostly that, with a little
    /// Lambert kept so the relief still reads under a high sun, capped so the lit limb never burns out.
    ///
    /// The relief (the normal map) is faded out in two places, both of which the first build got
    /// wrong: toward the RIM, where the map is seen edge-on and its steep slopes turned away from a
    /// light behind the camera, printing black specks along the limb of a full moon (and white ones
    /// on a new moon's); and toward FULL PHASE, where the light comes from behind the viewer and the
    /// real moon shows no shadows at all, only its albedo.
    private static let lunarReflectance = """
    float3 geometric = _surface.geometryNormal;
    float facing = max(0.0, dot(geometric, _surface.view));
    float relief = smoothstep(0.0, 0.35, facing) * (1.0 - smoothstep(0.8, 1.0, dot(_light.direction, _surface.view)));
    float3 surfaceNormal = normalize(mix(geometric, _surface.normal, relief));
    float incidence = max(0.0, dot(surfaceNormal, _light.direction));
    float emission = max(0.001, dot(surfaceNormal, _surface.view));
    float lommelSeeliger = 2.0 * incidence / (incidence + emission);
    _lightingContribution.diffuse += _light.intensity.rgb * min(mix(incidence, lommelSeeliger, 0.75), 1.35);
    """

    /// Stars as points on a sphere far outside everything, so turning round the moon sweeps them past
    /// and they never shift against each other. Deterministic, so the sky is the same every time.
    private static func starField(count: Int, radius: ClosedRange<CGFloat>, brightness: ClosedRange<Float>,
                                  seed start: UInt64) -> SCNNode {
        var seed = start
        func next() -> Float {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Float((seed >> 33) & 0xFF_FFFF) / Float(0xFF_FFFF)
        }
        var positions: [SCNVector3] = []
        var colors: [Float] = []
        positions.reserveCapacity(count)
        colors.reserveCapacity(count * 4)
        for _ in 0..<count {
            // Uniform over the sphere: height uniform, angle uniform.
            let z = next() * 2 - 1
            let angle = next() * 2 * .pi
            let ring = (1 - z * z).squareRoot()
            positions.append(SCNVector3(ring * cos(angle) * 1000, z * 1000, ring * sin(angle) * 1000))
            let level = brightness.lowerBound + (brightness.upperBound - brightness.lowerBound) * next() * next()
            let warmth = (next() - 0.5) * 0.24
            colors += [level * (1 + warmth), level, level * (1 - warmth), 1]
        }
        let colorData = colors.withUnsafeBufferPointer { Data(buffer: $0) }
        let colorSource = SCNGeometrySource(data: colorData, semantic: .color, vectorCount: count,
                                            usesFloatComponents: true, componentsPerVector: 4,
                                            bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0,
                                            dataStride: MemoryLayout<Float>.size * 4)
        let element = SCNGeometryElement(indices: Array(0..<Int32(count)), primitiveType: .point)
        element.pointSize = 1
        element.minimumPointScreenSpaceRadius = radius.lowerBound
        element.maximumPointScreenSpaceRadius = radius.upperBound
        let geometry = SCNGeometry(sources: [SCNGeometrySource(vertices: positions), colorSource], elements: [element])
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.white
        geometry.firstMaterial = material
        return SCNNode(geometry: geometry)
    }

    // MARK: Light

    func show(_ phase: MoonPhase) {
        guard phase != self.phase else { return }
        let first = self.phase == nil
        self.phase = phase
        // From the moon toward the sun, with the camera (the Earth) on +z: straight behind the camera
        // at full moon, straight behind the moon at new, and to the right while waxing, the side the
        // card's glyph lights. Kept a hair off both ends so the light can always be aimed.
        let angle = min(max(phase.phaseAngle, 0.002), .pi - 0.002)
        let side: Double = phase.isWaxing ? 1 : -1
        SCNTransaction.begin()
        SCNTransaction.animationDuration = first ? 0 : 0.45
        sunNode.position = SCNVector3(Float(side * sin(angle) * 50), 0, Float(cos(angle) * 50))
        sunNode.look(at: SCNVector3(0, 0, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        applyLights()
        SCNTransaction.commit()
    }

    func setFullLight(_ on: Bool) {
        guard on != fullLight else { return }
        let first = fullLight == nil
        fullLight = on
        SCNTransaction.begin()
        SCNTransaction.animationDuration = first ? 0 : 0.5
        applyLights()
        SCNTransaction.commit()
    }

    private func applyLights() {
        let full = fullLight ?? false
        let dark = 1 - (phase?.illumination ?? 1)
        sun.intensity = full ? 0 : 1000
        earthshine.intensity = full ? 0 : CGFloat(12 + 70 * dark)
        headlight.intensity = full ? 1000 : 0
    }

    // MARK: Framing

    private func layout(_ size: CGSize) {
        guard size != self.size else { return }
        self.size = size
        applyCamera(duration: 0)
    }

    func setRegion(_ region: CGRect) {
        guard region != self.region else { return }
        let first = self.region == .zero
        self.region = region
        applyCamera(duration: first ? 0 : 0.3)
    }

    /// The globe's radius on screen, in points, at the current zoom.
    private var onScreenRadius: Float {
        let area = region.isEmpty ? CGRect(origin: .zero, size: size) : region
        return Self.fill * Float(min(area.width, area.height)) / 2 * zoom
    }

    /// Places the camera for `yaw`, `pitch`, `zoom` and the region. The distance is the one at which
    /// the globe's rim lands `onScreenRadius` from its centre; the camera then slides sideways in its
    /// own plane, looking straight ahead, which moves the globe to the region's centre without viewing
    /// it at a slant (a lens shift, not a turn), and keeps it there however it is turned or zoomed.
    private func applyCamera(duration: TimeInterval, timing: CAMediaTimingFunctionName = .easeInEaseOut) {
        guard size.width > 0, size.height > 0 else { return }
        let area = region.isEmpty ? CGRect(origin: .zero, size: size) : region
        let tanHalf = Float(tan(Double(Self.fieldOfView) / 2 * .pi / 180))
        let halfHeight = Float(size.height) / 2
        let alpha = atan(onScreenRadius / halfHeight * tanHalf)
        let distance = max(1 / sin(alpha), 1.06)
        let unitsPerPoint = distance * tanHalf / halfHeight
        let shiftX = Float(area.midX - size.width / 2)
        let shiftY = Float(area.midY - size.height / 2)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: timing)
        cameraNode.position = SCNVector3(-shiftX * unitsPerPoint, shiftY * unitsPerPoint, distance)
        yawNode.eulerAngles.y = yaw
        pitchNode.eulerAngles.x = pitch
        SCNTransaction.commit()
    }

    func reset(token: Int) {
        guard let current = resetToken else {
            resetToken = token
            return
        }
        guard token != current else { return }
        resetToken = token
        stopMomentum()
        // Unwind whole turns first, silently, so the way home is the short way round.
        yaw = remainder(yaw, 2 * .pi)
        applyCamera(duration: 0)
        yaw = 0
        pitch = 0
        zoom = 1
        applyCamera(duration: 0.7)
        updateAway()
    }

    private func updateAway() {
        let away = abs(remainder(yaw, 2 * .pi)) > 0.03 || abs(pitch) > 0.03 || abs(zoom - 1) > 0.03
        guard away != isAway else { return }
        isAway = away
        let callback = onAwayChange
        DispatchQueue.main.async { callback(away) }
    }

    // MARK: Hands

    private func addGestures(to view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        for recognizer in [pan, pinch, doubleTap] as [UIGestureRecognizer] {
            recognizer.delegate = self
            view.addGestureRecognizer(recognizer)
        }
    }

    private func isOwn(_ recognizer: UIGestureRecognizer) -> Bool {
        recognizer.view === view
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        isOwn(gestureRecognizer) && isOwn(other)
    }

    /// Anything that is not the globe's own (the zoom transition's pull-down-to-close above all) waits
    /// for the globe's turn and pinch to fail, so turning the moon downward never drags the screen away.
    /// The X closes it.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
        !isOwn(other) && !(gestureRecognizer is UITapGestureRecognizer)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view else { return }
        switch gesture.state {
        case .began:
            stopMomentum()
            onInteract()
        case .changed:
            let moved = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            turn(by: SIMD2(Float(moved.x), Float(moved.y)))
        case .ended:
            let speed = gesture.velocity(in: view)
            velocity = SIMD2(Float(speed.x), Float(speed.y))
            startMomentum()
        default:
            break
        }
    }

    /// Turns so the surface under the finger follows it: a drag across the globe's full width is
    /// about half a turn, whatever the zoom.
    private func turn(by points: SIMD2<Float>) {
        let perPoint = 1 / max(onScreenRadius, 1)
        yaw -= points.x * perPoint
        let tilted = pitch - points.y * perPoint
        pitch = min(max(tilted, -Self.pitchLimit), Self.pitchLimit)
        if pitch != tilted { velocity.y = 0 }
        applyCamera(duration: 0)
        updateAway()
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            stopMomentum()
            onInteract()
            pinchStartZoom = zoom
        case .changed:
            zoom = min(max(pinchStartZoom * Float(gesture.scale), Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
            applyCamera(duration: 0)
            updateAway()
        default:
            break
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        onInteract()
        reset(token: (resetToken ?? 0) &+ 1)
    }

    // MARK: Momentum

    private func startMomentum() {
        guard (velocity.x * velocity.x + velocity.y * velocity.y).squareRoot() > 40 else { return }
        let link = CADisplayLink(target: MomentumTarget(self), selector: #selector(MomentumTarget.tick(_:)))
        link.add(to: .main, forMode: .common)
        momentumLink = link
    }

    private func stopMomentum() {
        momentumLink?.invalidate()
        momentumLink = nil
        velocity = .zero
    }

    fileprivate func tick(_ link: CADisplayLink) {
        let step = Float(min(max(link.targetTimestamp - link.timestamp, 1.0 / 240), 1.0 / 30))
        turn(by: velocity * step)
        // Most of the spin is gone within a second, the way a globe on a stand slows.
        velocity *= pow(0.02, step)
        if (velocity.x * velocity.x + velocity.y * velocity.y).squareRoot() < 12 {
            stopMomentum()
        }
    }
}

/// The display link's target: a link retains its target, and the controller must be free to go when
/// the viewer closes mid-spin.
private final class MomentumTarget: NSObject {
    private weak var controller: MoonGlobeController?

    init(_ controller: MoonGlobeController) {
        self.controller = controller
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let controller else {
            link.invalidate()
            return
        }
        controller.tick(link)
    }
}
#endif
