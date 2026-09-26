import SwiftUI
import CoreLocation
import Combine
import Adhan
#if os(iOS)
import UIKit
#endif

struct QiblaView: View {
    @ObservedObject private var settings = Settings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared

    let size: CGFloat

    private static let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    @StateObject private var compass: LocalQiblaCompass

    /// One entry, keyed on the coordinate: the distance is read on every render of the info card and
    /// the coordinate changes a few times a day. Was a `@State` pair written from inside `body`
    /// through `DispatchQueue.main.async`, i.e. a render that scheduled another render.
    private static var distanceMemo: (latitude: Double, longitude: Double, miles: Double)?

    /// Whether THIS compass is the one that started the GPS refinement burst. See `endRefinementIfStarted`.
    @State private var startedRefinement = false

    #if os(iOS)
    @State private var lastAngle: Double = 0
    @State private var lastHapticTime: TimeInterval = 0
    @State private var impact = UIImpactFeedbackGenerator(style: .light)
    private let notify = UINotificationFeedbackGenerator()
    #endif

    init(size: CGFloat = 50) {
        self.size = size
        _compass = StateObject(wrappedValue: LocalQiblaCompass {
            Settings.shared.currentLocation
        })
    }

    private var layout: QiblaLayoutMetrics {
        QiblaLayoutMetrics(size: size)
    }

    /// The expanded compass (100 pt in the location row, 160 pt in settings, 220 pt in the Glance
    /// sheet). Only this one is worth a GPS refinement burst.
    private var isExpanded: Bool { size > 50 }

    private var distanceToQibla: Double {
        angularDistance(compass.direction, 0)
    }

    /// Nothing here may claim alignment before a real heading sample has landed: `direction` starts
    /// at 0, and 0 is exactly the value that means "facing the Kaaba". A phone with no magnetometer,
    /// an uncalibrated one, or one with no location yet used to draw a straight-up needle, an accent
    /// ring and the words "You are facing the Kaaba" - the failure state was indistinguishable from
    /// success, which is what makes a broken compass read as a working one pointing the wrong way.
    private var isAligned: Bool { compass.hasHeading && distanceToQibla <= 1 }
    private var isNearlyAligned: Bool { compass.hasHeading && distanceToQibla <= 5 }
    private var isWithinArc: Bool { compass.hasHeading && distanceToQibla <= 20 }

    private var qiblaTurnText: String? {
        guard compass.hasHeading else {
            guard CLLocationManager.headingAvailable() else { return "No compass on this device" }
            // Heading samples are DROPPED while there is no usable fix (there is no bearing to
            // subtract them from), so "Waiting for the compass" named the wrong thing whenever the
            // real hold-up was location - which is the common case indoors and on a fresh install.
            return hasUsableLocation ? "Waiting for the compass\u{2026}" : "Waiting for your location\u{2026}"
        }
        guard !isAligned else { return "You are facing the Kaaba" }

        let delta = shortestDelta(from: 0, to: compass.direction)
        let direction = delta < 0 ? "left" : "right"
        let degrees = Int(abs(delta).rounded())
        return "Turn \(direction) \(degrees)°"
    }

    /// A fix the Qibla maths can actually use: present, and not the app's (1000, 1000) "none yet"
    /// sentinel. `LocalQiblaCompass.usableLocation()` applies the same test.
    private var hasUsableLocation: Bool {
        guard let currentLocation = live.currentLocation else { return false }
        return abs(currentLocation.latitude) <= 90 && abs(currentLocation.longitude) <= 180
    }

    private var distanceToKaabaMiles: Double? {
        guard let currentLocation = live.currentLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000 else { return nil }

        if let memo = Self.distanceMemo,
           memo.latitude == currentLocation.latitude, memo.longitude == currentLocation.longitude {
            return memo.miles
        }

        let miles = haversineMiles(
            fromLatitude: currentLocation.latitude,
            fromLongitude: currentLocation.longitude,
            toLatitude: Self.kaabaCoordinate.latitude,
            toLongitude: Self.kaabaCoordinate.longitude
        )
        Self.distanceMemo = (currentLocation.latitude, currentLocation.longitude, miles)
        return miles
    }

    private var alignmentScore: Double {
        guard compass.hasHeading else { return 0 }
        // Quantized to 1/24 steps. Each distinct value re-rasterizes GlassyQiblaRing's decoration
        // layer (three blurs + a gradient border) - exactly while the user is aligned and watching.
        // Snapping to steps lets SwiftUI diff the ring out between visually identical frames; only
        // the cheap arrow rotates per sample.
        let raw = 1.0 - (min(20.0, distanceToQibla) / 20.0)
        return (raw * 24).rounded() / 24
    }

    private var arrowColor: Color {
        isNearlyAligned ? settings.accentColor.color : .primary
    }

    private var ringColor: Color {
        isWithinArc ? settings.accentColor.color : .primary
    }

    var body: some View {
        let _ = RenderCounter.hit("QiblaView")
        let _ = ChangePrinter.hit(Self.self)
        VStack(spacing: 10) {
            ZStack {
                GlassyQiblaRing(size: size, tint: ringColor, alignmentScore: alignmentScore)
                    .animation(.easeInOut(duration: 0.2), value: ringColor)

                pointerStack
                    .rotationEffect(.degrees(compass.direction))
            }
            .conditionalGlassEffect()

            if size >= 70 {
                qiblaInfoCard
            }
        }
        .animation(nil, value: compass.direction)
        .onAppear {
            configureCompass()
            prepareHaptics()
        }
        .onDisappear {
            compass.stop()
            endRefinementIfStarted()
        }
        // The location row swaps 50 pt for 100 pt in place, so the same view goes from resting to
        // expanded: start the burst then, and stop it on the way back. The needle itself is live at
        // both sizes, so nothing about the heading changes here.
        .onChange(of: size) { _ in configureCompass() }
        #if os(iOS)
        .onChange(of: compass.direction) { newAngle in
            handleDirectionChange(newAngle)
        }
        #endif
    }

    /// Heading updates and the GPS burst for the current size. Idempotent.
    ///
    /// The needle is live at EVERY size and on every performance tier. The 50 pt row compass used to
    /// fall back to `showStaticBearing()` under Low Power Mode (or on a 3 GB-class device), which
    /// published the ABSOLUTE Qibla bearing into `direction` - a number the rest of this view reads
    /// as "how far off you are". The row needle then sat permanently at the bearing angle in the
    /// unaligned colour, and jumped to a completely different angle the moment a tap expanded it and
    /// back again on the way down. The magnetometer is not what costs battery here; the GPS burst is,
    /// and that is still expanded-only.
    private func configureCompass() {
        compass.start()
        if isExpanded {
            if !startedRefinement, settings.beginLocationRefinementForCompass() {
                startedRefinement = true
            }
        } else {
            endRefinementIfStarted()
        }
    }

    /// Ends only a burst THIS compass started. `endLocationRefinement()` is global and not reference
    /// counted, so the collapsed row compass calling it unconditionally on appear cancelled whatever
    /// burst someone else had going - in particular the offline acquisition burst
    /// `refreshLocationIfStale` starts, which is the app's only way to get a fix at all with no
    /// network. With no `currentLocation` there is no bearing to compute, so every heading sample is
    /// dropped and the needle never moves: "the Qibla doesn't work".
    private func endRefinementIfStarted() {
        guard startedRefinement else { return }
        startedRefinement = false
        settings.endLocationRefinement()
    }

    private var pointerStack: some View {
        VStack(spacing: -(size * 0.40)) {
            QiblaArrow(width: layout.arrowWidth, height: layout.arrowHeight, tint: arrowColor)
                .animation(.easeInOut(duration: 0.2), value: arrowColor)
            Text("🕋")
                .font(.system(size: layout.kaabaSize))
                .softShadow(
                    color: .black.opacity(0.25),
                    radius: max(0.6, layout.kaabaSize * 0.08),
                    x: 0,
                    y: 0
                )
        }
        .padding(.vertical, size * 0.16)
        // NOT a `drawingGroup`: it rasterized the needle and then rotated the bitmap, so every
        // heading sample resampled a texture instead of redrawing a vector, and the buffer is the
        // stack's own bounds - which have no horizontal padding, so it clipped the two shadows it
        // was added to make cheap. `softShadow` already drops both on the reduced tier, which is
        // where that cost mattered. (The same Metal path is why `GlassyQiblaRing` below is not one.)
    }

    private var qiblaInfoCard: some View {
        VStack(spacing: 3) {
            if let qiblaTurnText {
                Text(qiblaTurnText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isWithinArc ? settings.accentColor.color : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let distanceToKaabaMiles {
                Text(String(format: "%.1f miles away", distanceToKaabaMiles))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .conditionalGlassEffect()
        .softShadow(color: .primary.opacity(0.08), radius: 8, y: 2)
    }

    private func angularDistance(_ lhs: Double, _ rhs: Double) -> Double {
        var delta = (lhs - rhs).truncatingRemainder(dividingBy: 360)
        if delta < -180 { delta += 360 }
        if delta > 180 { delta -= 360 }
        return abs(delta)
    }

    private func shortestDelta(from lhs: Double, to rhs: Double) -> Double {
        var delta = (rhs - lhs).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return delta
    }

    private func haversineMiles(
        fromLatitude lat1: Double,
        fromLongitude lon1: Double,
        toLatitude lat2: Double,
        toLongitude lon2: Double
    ) -> Double {
        let radiusMiles = 3_958.7613
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let rLat1 = lat1 * .pi / 180
        let rLat2 = lat2 * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(rLat1) * cos(rLat2) * sin(dLon / 2) * sin(dLon / 2)
        return radiusMiles * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private func prepareHaptics() {
        #if os(iOS)
        lastAngle = compass.direction
        lastHapticTime = ProcessInfo.processInfo.systemUptime
        impact.prepare()
        notify.prepare()
        #endif
    }

    #if os(iOS)
    private func handleDirectionChange(_ newAngle: Double) {
        guard size > 50 else { return }

        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastHapticTime >= 0.08 else { return }

        let delta = shortestDelta(from: lastAngle, to: newAngle)
        let absoluteDelta = abs(delta)
        let distance = angularDistance(newAngle, 0)
        let threshold = max(2.0, min(8.0, distance / 3.0))

        guard absoluteDelta >= threshold else { return }

        if distance <= 5 {
            notify.notificationOccurred(.success)
            notify.prepare()
        } else {
            let intensity = CGFloat(distance <= 20 ? 0.25 : 0.15)
            impact.impactOccurred(intensity: intensity)
            impact.prepare()
        }

        withAnimation {
            lastHapticTime = now
            lastAngle = newAngle
        }
    }
    #endif
}

private struct QiblaLayoutMetrics {
    let size: CGFloat

    var arrowWidth: CGFloat { max(10, size * 0.18) }
    var arrowHeight: CGFloat { max(30, size * 0.55) }
    var kaabaSize: CGFloat { max(20, size * 0.40) }
}

struct GlassyQiblaRing: View {
    @Environment(\.appearance) private var appearance

    let size: CGFloat
    let tint: Color
    let alignmentScore: Double

    /// The material disc stays a live layer: a material samples what is behind it, so it cannot be
    /// rasterized. The decorations are a separate subtree below, kept off the Metal path too.
    @ViewBuilder
    private var glassFill: some View {
        #if os(iOS)
        if appearance.flattenMaterials {
            Circle().fill(Color(UIColor.secondarySystemBackground).opacity(0.7))
        } else {
            Circle().fill(.ultraThinMaterial)
        }
        #else
        Circle().fill(Color.white.opacity(0.18))
        #endif
    }

    var body: some View {
        let ringWidth = max(1, size * 0.045)
        let glossWidth = size * 0.16
        let outerGlowWidth = size * 0.085
        let shadowRadius = max(1, size * 0.10)
        let innerLineWidth = max(1, size * 0.06)
        let innerBlur = max(0.5, size * 0.04)

        ZStack {
            glassFill
                .softShadow(color: .black.opacity(0.18), radius: shadowRadius, x: 0, y: max(0.5, size * 0.04))

            // The inner shade, the gloss, the gradient border and the alignment glow. NOT a
            // `drawingGroup`: tried, and the Metal path rendered the masked blurs as a grey halo
            // around the ring (light) and a grey square (reduced tier). The 24-step score above
            // already keeps this subtree diffed out between visually identical frames.
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.14), lineWidth: innerLineWidth)
                    .blur(radius: innerBlur)
                    .mask(Circle().stroke(lineWidth: innerLineWidth))

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.12), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .blur(radius: max(0.5, size * 0.06))
                    .scaleEffect(0.98)
                    .mask(
                        Circle()
                            .inset(by: glossWidth * 0.35)
                            .trim(from: 0, to: 0.58)
                            .stroke(style: .init(lineWidth: glossWidth, lineCap: .round))
                    )

                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [tint.opacity(0.95), Color.white.opacity(0.75), tint.opacity(0.95)]),
                            center: .center
                        ),
                        lineWidth: ringWidth
                    )

                Circle()
                    .stroke(tint.opacity(0.25 + 0.45 * alignmentScore), lineWidth: outerGlowWidth)
                    .blur(radius: max(0.6, size * 0.05))
                    .mask(Circle().stroke(lineWidth: outerGlowWidth))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .compositingGroup()
    }
}

struct QiblaArrow: View {
    let width: CGFloat
    let height: CGFloat
    let tint: Color

    var body: some View {
        Image(systemName: "arrow.up")
            .resizable()
            .frame(width: width, height: height)
            .foregroundStyle(
                LinearGradient(
                    colors: [tint.opacity(0.95), tint.opacity(0.55), tint.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .softShadow(color: tint.opacity(0.35), radius: max(0.6, width * 0.18), x: 0, y: 0)
    }
}

/// Turns heading samples into the needle angle.
///
/// Every sample is smoothed and published, as the compass did before the 2026-09-04 performance pass.
/// That pass and its two follow-ups added a heading filter, a sample-rate gate, a publish gate and the
/// system calibration prompt. Each one made the needle worse: it froze short of the Qibla, stepped
/// instead of turning, or a figure-eight sheet covered the Adhan tab. All four are gone on purpose (Abu,
/// 2026-09-23: "worked perfectly before"); do not bring them back to save body evaluations. A sample
/// costs one `QiblaView` body, and the ring is diffed out by the quantized alignment score, so only the
/// pointer redraws.
final class LocalQiblaCompass: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var direction: Double = 0

    /// True once a usable heading has actually landed. `direction` starts at 0 and 0 means "aligned",
    /// so without this flag a compass that has never received a sample (no magnetometer, an
    /// uncalibrated one, or no location to compute a bearing from) draws as a perfect alignment.
    /// It stays true through `stop()`: a compass that scrolls or tabs away and comes back keeps its
    /// last reading until the next sample, instead of flashing "Waiting for the compass" every time.
    @Published private(set) var hasHeading = false

    private let locationManager = CLLocationManager()
    private let locationProvider: () -> Location?
    private var started = false
    /// The Qibla bearing for the last coordinate it was computed for.
    private var cachedBearing: (latitude: Double, longitude: Double, degrees: Double)?
    /// Continuous (unwrapped) low-pass accumulator of the heading→qibla delta. Published `direction`
    /// is this normalized to 0..<360. Smoothing here keeps the needle sharp but free of compass jitter.
    private var smoothedDelta: Double?

    /// True minus magnetic heading, read off the last sample that carried a true heading, and the
    /// place it was read at. Shared by every compass for the life of the process.
    private struct Declination {
        let degrees: Double
        let latitude: Double
        let longitude: Double

        /// Declination changes by about a degree every 100 to 200 km, so one reading serves a region.
        func covers(latitude: Double, longitude: Double) -> Bool {
            abs(self.latitude - latitude) <= 1 && abs(self.longitude - longitude) <= 1
        }
    }
    private static var learnedDeclination: Declination?

    /// Ends this compass's own coarse location lookup (see `geographicHeading`) if it runs out of
    /// time. Non-nil exactly while that lookup is running.
    private var declinationLookupTimeout: DispatchWorkItem?
    /// Set when a lookup ran out of time without a true heading, so it is not retried on every
    /// sample. `stop()` clears it.
    private var declinationLookupGaveUp = false
    private static let declinationLookupLimit: TimeInterval = 30

    #if os(iOS)
    /// Uptime of the last interface-orientation read (see `refreshHeadingOrientationIfDue`).
    private var lastOrientationCheck: TimeInterval = 0
    #endif

    init(locationProvider: @escaping () -> Location?) {
        self.locationProvider = locationProvider
        super.init()
        locationManager.delegate = self
        // Take every heading sample and do our own smoothing: a steadier, sharper needle than letting
        // Core Location drop sub-degree changes.
        locationManager.headingFilter = kCLHeadingFilterNone
        #if os(iOS)
        applyHeadingOrientation()
        #else
        locationManager.headingOrientation = .portrait
        #endif
    }

    func start() {
        guard !started, CLLocationManager.headingAvailable() else { return }
        started = true
        #if os(iOS)
        // Re-read here, not only in `init`: at init time the window scene is often not yet
        // foregroundActive, and the orientation may have changed while the compass was stopped.
        applyHeadingOrientation()
        #endif
        locationManager.startUpdatingHeading()
    }

    func stop() {
        guard started else { return }
        started = false
        endDeclinationLookup()
        declinationLookupGaveUp = false
        locationManager.stopUpdatingHeading()
    }

    #if os(iOS)
    /// CoreLocation reports a heading relative to the TOP OF THE DEVICE, so `headingOrientation` has
    /// to say which edge that is. Pinned to `.portrait`, a landscape window (iPhone landscape, any iPad
    /// orientation) put the needle a flat 90 degrees off while every number still looked plausible.
    ///
    /// Mapped from the INTERFACE orientation (what the user is actually looking at) rather than the
    /// device one, and the two are inverted for the landscapes: `UIInterfaceOrientation.landscapeLeft`
    /// IS `UIDeviceOrientation.landscapeRight`, and `CLDeviceOrientation` follows the device.
    private static func headingOrientation(for interface: UIInterfaceOrientation) -> CLDeviceOrientation {
        switch interface {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return .portrait
        }
    }

    /// The frontmost scene's interface orientation, or nil when no scene is frontmost (Control Center,
    /// the app switcher) or it reports unknown. Nil keeps the current frame instead of guessing portrait.
    private static func activeInterfaceOrientation() -> UIInterfaceOrientation? {
        let orientation = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .interfaceOrientation
        guard let orientation, orientation != .unknown else { return nil }
        return orientation
    }

    /// Points `headingOrientation` at the edge that is currently the top of the screen. Returns true
    /// when the frame changed, so the caller can drop the sample in hand.
    @discardableResult
    private func applyHeadingOrientation() -> Bool {
        lastOrientationCheck = ProcessInfo.processInfo.systemUptime
        guard let interface = Self.activeInterfaceOrientation() else { return false }
        let wanted = Self.headingOrientation(for: interface)
        guard locationManager.headingOrientation != wanted else { return false }
        locationManager.headingOrientation = wanted
        // The low-pass accumulator holds a delta measured in the OLD frame. Kept, it would walk the
        // needle across the 90 degrees instead of the frame simply changing under it; dropped, the
        // next sample re-seeds it (see the `smoothedDelta == nil` branch below).
        smoothedDelta = nil
        return true
    }

    /// Re-reads the orientation from the heading callback, at most twice a second. This replaced a
    /// device-orientation observer: that notification can arrive before the window scene reports its
    /// new interface orientation, so the observer read the OLD one and could leave the needle 90
    /// degrees off in portrait after a turn through landscape, until something else rotated.
    private func refreshHeadingOrientationIfDue() -> Bool {
        guard ProcessInfo.processInfo.systemUptime - lastOrientationCheck >= 0.5 else { return false }
        return applyHeadingOrientation()
    }
    #endif

    /// The app-wide "no fix yet" sentinel is (1000, 1000). `Qibla(coordinates:)` happily returns a
    /// bearing for it, which drew a needle that moved and looked alive while pointing at nothing.
    private func usableLocation() -> Location? {
        guard let location = locationProvider(),
              abs(location.latitude) <= 90,
              abs(location.longitude) <= 180 else { return nil }
        return location
    }

    private func qiblaBearing(latitude: Double, longitude: Double) -> Double {
        if let cachedBearing, cachedBearing.latitude == latitude, cachedBearing.longitude == longitude {
            return cachedBearing.degrees
        }
        let degrees = Qibla(coordinates: Coordinates(latitude: latitude, longitude: longitude)).direction
        cachedBearing = (latitude, longitude, degrees)
        return degrees
    }

    /// The heading from true north, which is what the Qibla bearing is measured from.
    ///
    /// Apple documents `trueHeading` as valid only while the same location manager is also delivering
    /// location updates; otherwise it is -1 and the magnetic heading is off by the local declination
    /// (more than 10 degrees across much of North America). This manager never turned location on,
    /// so the needle could depend on unrelated location activity: true north while the old 25 s GPS
    /// burst ran, magnetic after it, and a swing of the full declination at each switch. Fewer bursts
    /// since 2026-09-04 made the magnetic side the common one.
    ///
    /// Now a true heading is used and its declination remembered. Without one, the magnetic heading
    /// plus that declination. With neither, a short coarse location lookup on this manager (cell and
    /// Wi-Fi accuracy, not the GPS) until a true heading lands, and the raw magnetic heading meanwhile.
    private func geographicHeading(_ heading: CLHeading, latitude: Double, longitude: Double) -> Double {
        if heading.trueHeading >= 0 {
            Self.learnedDeclination = Declination(
                degrees: Self.signedDegrees(heading.trueHeading - heading.magneticHeading),
                latitude: latitude,
                longitude: longitude
            )
            endDeclinationLookup()
            return heading.trueHeading
        }
        if let learned = Self.learnedDeclination, learned.covers(latitude: latitude, longitude: longitude) {
            return Self.normalizedDegrees(heading.magneticHeading + learned.degrees)
        }
        beginDeclinationLookupIfNeeded()
        return heading.magneticHeading
    }

    private func beginDeclinationLookupIfNeeded() {
        guard started, declinationLookupTimeout == nil, !declinationLookupGaveUp else { return }
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.startUpdatingLocation()
        // Bounded: a device that never reports a true heading must not keep location running.
        let timeout = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.endDeclinationLookup()
            self.declinationLookupGaveUp = true
        }
        declinationLookupTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.declinationLookupLimit, execute: timeout)
    }

    private func endDeclinationLookup() {
        guard let timeout = declinationLookupTimeout else { return }
        timeout.cancel()
        declinationLookupTimeout = nil
        locationManager.stopUpdatingLocation()
    }

    private static func normalizedDegrees(_ value: Double) -> Double {
        var degrees = value.truncatingRemainder(dividingBy: 360)
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    private static func signedDegrees(_ value: Double) -> Double {
        var degrees = value.truncatingRemainder(dividingBy: 360)
        if degrees > 180 { degrees -= 360 } else if degrees < -180 { degrees += 360 }
        return degrees
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0, let location = usableLocation() else { return }
        #if os(iOS)
        // A new frame makes this sample meaningless (it was measured against the old top edge); the
        // next one re-seeds the low-pass.
        if refreshHeadingOrientationIfDue() { return }
        #endif

        let heading = geographicHeading(newHeading, latitude: location.latitude, longitude: location.longitude)
        var target = qiblaBearing(latitude: location.latitude, longitude: location.longitude) - heading
        target.formTruncatingRemainder(dividingBy: 360)
        if target < 0 { target += 360 }

        if !hasHeading { hasHeading = true }

        guard let current = smoothedDelta else {
            smoothedDelta = target
            direction = target
            return
        }

        // Move along the shortest arc so crossing north never spins the needle the long way around.
        var diff = target - current
        diff.formTruncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 } else if diff < -180 { diff += 360 }

        // Adaptive low-pass: snap quickly on real turns, damp tiny jitter for a steady needle.
        let magnitude = abs(diff)
        let alpha: Double = magnitude > 45 ? 0.55 : (magnitude > 12 ? 0.32 : 0.16)
        let updated = current + diff * alpha
        smoothedDelta = updated

        var normalized = updated.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        direction = normalized
    }

    /// The declination lookup's fixes. They exist only so Core Location can fill `trueHeading`; the
    /// app's location still comes from `Settings`, which owns the commits, the city and prayer times.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    deinit {
        stop()
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        List {
            QiblaView(size: 160)
                .padding()
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
    }
}
