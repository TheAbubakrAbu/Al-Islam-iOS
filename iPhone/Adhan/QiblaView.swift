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
            return CLLocationManager.headingAvailable()
                ? "Waiting for the compass\u{2026}"
                : "No compass on this device"
        }
        guard !isAligned else { return "You are facing the Kaaba" }

        let delta = shortestDelta(from: 0, to: compass.direction)
        let direction = delta < 0 ? "left" : "right"
        let degrees = Int(abs(delta).rounded())
        return "Turn \(direction) \(degrees)°"
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
        compass.start(needleRadius: size / 2)
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

final class LocalQiblaCompass: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var direction: Double = 0

    /// True once a usable heading has actually landed. `direction` starts at 0 and 0 means "aligned",
    /// so without this flag a compass that has never received a sample - no magnetometer, an
    /// uncalibrated one, or no location to compute a bearing from - draws as a perfect alignment.
    @Published private(set) var hasHeading = false

    private let locationManager = CLLocationManager()
    private let locationProvider: () -> Location?
    private var started = false
    private var cachedLocationKey: String?
    private var cachedQiblaDirection: Double?
    /// Continuous (unwrapped) low-pass accumulator of the heading→qibla delta. Published `direction`
    /// is this normalized to 0..<360. Smoothing here keeps the needle sharp but free of compass jitter.
    private var smoothedDelta: Double?

    /// Publish only when the needle would visibly move, set from the needle's radius by `start`.
    /// This was a flat 0.5° at every size, which is a different thing at each of them: half a degree
    /// moves a 50 pt needle's tip by a fifth of a point and a 220 pt one's by a full point, so the
    /// big compass published in visible steps - a stuttering needle rather than a turning one, since
    /// the rotation is deliberately unanimated.
    private var minPublishedDelta: Double = 0.5

    init(locationProvider: @escaping () -> Location?) {
        self.locationProvider = locationProvider
        super.init()
        locationManager.delegate = self
        locationManager.headingOrientation = .portrait
    }

    /// Start (or keep) heading updates for a needle of `needleRadius` points. The heading filter
    /// stays `kCLHeadingFilterNone` on purpose: the low-pass below only converges while samples keep
    /// coming, and a 1° filter went silent the moment the phone stopped turning, which froze the
    /// needle short of the Qibla ("mad laggy"). Cost is controlled downstream instead, by the publish
    /// gate that swallows sub-pixel jitter before it ever reaches SwiftUI.
    ///
    /// There is no sample-rate gate any more. Dropping to 10 Hz on the reduced tier starved the
    /// low-pass and, with the rotation unanimated, showed as a needle that jumped in chunks.
    func start(needleRadius: CGFloat) {
        guard CLLocationManager.headingAvailable() else { return }
        minPublishedDelta = Self.publishThreshold(needleRadius: needleRadius)
        locationManager.headingFilter = kCLHeadingFilterNone
        guard !started else { return }
        started = true
        locationManager.startUpdatingHeading()
    }

    /// The rotation, in degrees, that moves the needle's tip half a point: below that a publish
    /// costs a body evaluation and buys nothing. Clamped so the smallest compass still can't publish
    /// more than once per degree and the largest still tracks finely.
    private static func publishThreshold(needleRadius: CGFloat) -> Double {
        let radius = max(1, Double(needleRadius))
        return min(1.0, max(0.1, (0.5 / radius) * 180 / .pi))
    }

    func stop() {
        guard started else { return }
        started = false
        locationManager.stopUpdatingHeading()
        smoothedDelta = nil
        if hasHeading { hasHeading = false }
    }

    /// Offers the system's figure-eight calibration sheet while the compass is on screen. The
    /// default for this delegate method is `false`, so it was never offered: a phone whose
    /// magnetometer needed calibrating delivered nothing but `headingAccuracy < 0` samples, every
    /// one of which is dropped below, and the needle simply never moved.
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        started
    }

    private func qiblaDirection() -> Double? {
        guard let currentLocation = locationProvider() else { return nil }
        let locationKey = "\(currentLocation.latitude),\(currentLocation.longitude)"
        if cachedLocationKey == locationKey, let cachedQiblaDirection {
            return cachedQiblaDirection
        }
        let qiblaDirection = Qibla(
            coordinates: Coordinates(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        ).direction
        cachedLocationKey = locationKey
        cachedQiblaDirection = qiblaDirection
        return qiblaDirection
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0, let qiblaDirection = qiblaDirection() else { return }

        // Prefer the true (geographic) heading; magnetic is the fallback when declination is unknown.
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading

        var target = qiblaDirection - heading
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

        var published = normalized - direction
        published.formTruncatingRemainder(dividingBy: 360)
        if published > 180 { published -= 360 } else if published < -180 { published += 360 }
        guard abs(published) >= minPublishedDelta else { return }
        direction = normalized
    }

    deinit {
        // Not `stop()`: that publishes `hasHeading`, and an object being deallocated must not send
        // `objectWillChange`.
        guard started else { return }
        locationManager.stopUpdatingHeading()
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
