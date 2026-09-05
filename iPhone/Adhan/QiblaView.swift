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
    @Environment(\.appearance) private var appearance

    let size: CGFloat

    private static let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    @StateObject private var compass: LocalQiblaCompass

    /// One entry, keyed on the coordinate: the distance is read on every render of the info card and
    /// the coordinate changes a few times a day. Was a `@State` pair written from inside `body`
    /// through `DispatchQueue.main.async`, i.e. a render that scheduled another render.
    private static var distanceMemo: (latitude: Double, longitude: Double, miles: Double)?

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

    /// The expanded compass (100 pt in the location row, 160 pt in settings). Only this one is worth
    /// a GPS refinement burst, and on the reduced tier only this one drives the magnetometer at all.
    private var isExpanded: Bool { size > 50 }

    /// Whether the needle follows the phone's heading. The 50 pt compass in the location row keeps
    /// turning on the full tier: with the 0.5° publish gate below it costs nothing while the phone
    /// rests, and the live row compass is the one people actually use. Under Low Power Mode (or a
    /// 3 GB-class device) the row compass shows the static bearing instead and the magnetometer
    /// stays off until the compass is expanded.
    private var isLive: Bool { isExpanded || !appearance.isReducedTier }

    private var distanceToQibla: Double {
        angularDistance(compass.direction, 0)
    }

    private var qiblaTurnText: String? {
        guard distanceToQibla > 1 else { return "You are facing the Kaaba" }

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
        // Quantized to 1/24 steps. Each distinct value re-rasterizes GlassyQiblaRing's decoration
        // layer (three blurs + a gradient border) - exactly while the user is aligned and watching.
        // Snapping to steps lets SwiftUI diff the ring out between visually identical frames; only
        // the cheap arrow rotates per sample.
        let raw = 1.0 - (min(20.0, distanceToQibla) / 20.0)
        return (raw * 24).rounded() / 24
    }

    private var arrowColor: Color {
        distanceToQibla <= 5 ? settings.accentColor.color : .primary
    }

    private var ringColor: Color {
        distanceToQibla <= 20 ? settings.accentColor.color : .primary
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
            settings.endLocationRefinement()
        }
        // The location row swaps 50 pt for 100 pt in place, so the same view goes from resting to
        // expanded: start the heading + burst then, and stop the burst on the way back.
        .onChange(of: size) { _ in configureCompass() }
        .onChange(of: appearance.isReducedTier) { _ in configureCompass() }
        #if os(iOS)
        .onChange(of: compass.direction) { newAngle in
            handleDirectionChange(newAngle)
        }
        #endif
    }

    /// Heading on or off, and the GPS burst, for the current size and tier. Idempotent.
    private func configureCompass() {
        if isLive {
            compass.start(minSampleInterval: appearance.isReducedTier ? 0.1 : 0)
        } else {
            compass.showStaticBearing()
        }
        if isExpanded {
            settings.beginLocationRefinementForCompass()
        } else {
            settings.endLocationRefinement()
        }
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
        // One texture, rotated: without this the two shadows were re-rendered offscreen on every
        // heading sample, because a shadow of a transformed layer is computed per frame.
        .drawingGroup()
    }

    private var qiblaInfoCard: some View {
        VStack(spacing: 3) {
            if let qiblaTurnText {
                Text(qiblaTurnText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(distanceToQibla <= 20 ? settings.accentColor.color : .primary)
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

    /// The material disc stays a live layer (a material samples what is behind it, so it cannot be
    /// rasterized); everything drawn over it is one `drawingGroup` texture below.
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

    private let locationManager = CLLocationManager()
    private let locationProvider: () -> Location?
    private var started = false
    private var cachedLocationKey: String?
    private var cachedQiblaDirection: Double?
    /// Continuous (unwrapped) low-pass accumulator of the heading→qibla delta. Published `direction`
    /// is this normalized to 0..<360. Smoothing here keeps the needle sharp but free of compass jitter.
    private var smoothedDelta: Double?
    /// Uptime of the last sample that was let through; samples closer than `minSampleInterval` are
    /// dropped. Zero on the full tier (every sample feeds the low-pass, as it always did), 100 ms
    /// on the reduced tier.
    private var lastSampleAt: TimeInterval = 0
    private var minSampleInterval: TimeInterval = 0

    /// Publish only when the needle would visibly move: below half a degree the rotation is a
    /// sub-pixel change of a 50-160 pt needle, and each publish is a body evaluation of the row.
    private static let minPublishedDelta: Double = 0.5

    init(locationProvider: @escaping () -> Location?) {
        self.locationProvider = locationProvider
        super.init()
        locationManager.delegate = self
        locationManager.headingOrientation = .portrait
    }

    /// Start (or keep) heading updates. The heading filter stays `kCLHeadingFilterNone` on purpose:
    /// the low-pass below only converges while samples keep coming, and a 1° filter went silent the
    /// moment the phone stopped turning, which froze the needle short of the Qibla ("mad laggy").
    /// Cost is controlled downstream instead: the optional sample gate for the reduced tier, and the
    /// half-degree publish gate that swallows resting jitter before it reaches SwiftUI.
    func start(minSampleInterval: TimeInterval) {
        guard CLLocationManager.headingAvailable() else { return }
        self.minSampleInterval = minSampleInterval
        locationManager.headingFilter = kCLHeadingFilterNone
        guard !started else { return }
        started = true
        locationManager.startUpdatingHeading()
    }

    func stop() {
        guard started else { return }
        started = false
        locationManager.stopUpdatingHeading()
    }

    /// No magnetometer: point the needle at the Qibla bearing with north up, the same number the
    /// Glance card prints. Used for the row compass on the reduced tier.
    func showStaticBearing() {
        stop()
        smoothedDelta = nil
        guard let bearing = qiblaDirection() else { return }
        if direction != bearing { direction = bearing }
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

        if minSampleInterval > 0 {
            let uptime = ProcessInfo.processInfo.systemUptime
            guard uptime - lastSampleAt >= minSampleInterval else { return }
            lastSampleAt = uptime
        }

        // Prefer the true (geographic) heading; magnetic is the fallback when declination is unknown.
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading

        var target = qiblaDirection - heading
        target.formTruncatingRemainder(dividingBy: 360)
        if target < 0 { target += 360 }

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
        guard abs(published) >= Self.minPublishedDelta else { return }
        direction = normalized
    }

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
