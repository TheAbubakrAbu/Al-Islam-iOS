import SwiftUI
import CoreLocation
import Combine
import Adhan
#if os(iOS)
import UIKit
#endif

struct QiblaView: View {
    @ObservedObject private var settings = Settings.shared

    let size: CGFloat

    private static let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    @StateObject private var compass: LocalQiblaCompass
    @State private var cachedDistanceLocationKey: String?
    @State private var cachedDistanceToKaabaMiles: Double?

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
        guard let currentLocation = settings.currentLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000 else { return nil }

        let locationKey = "\(currentLocation.latitude),\(currentLocation.longitude)"
        if cachedDistanceLocationKey == locationKey {
            return cachedDistanceToKaabaMiles
        }

        let miles = haversineMiles(
            fromLatitude: currentLocation.latitude,
            fromLongitude: currentLocation.longitude,
            toLatitude: Self.kaabaCoordinate.latitude,
            toLongitude: Self.kaabaCoordinate.longitude
        )
        DispatchQueue.main.async {
            cachedDistanceLocationKey = locationKey
            cachedDistanceToKaabaMiles = miles
        }
        return miles
    }

    private var alignmentScore: Double {
        1.0 - (min(20.0, distanceToQibla) / 20.0)
    }

    private var arrowColor: Color {
        distanceToQibla <= 5 ? settings.accentColor.color : .primary
    }

    private var ringColor: Color {
        distanceToQibla <= 20 ? settings.accentColor.color : .primary
    }

    var body: some View {
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
            compass.start()
            settings.beginLocationRefinement()
            prepareHaptics()
        }
        .onDisappear {
            compass.stop()
            settings.endLocationRefinement()
        }
        #if os(iOS)
        .onChange(of: compass.direction) { newAngle in
            handleDirectionChange(newAngle)
        }
        #endif
    }

    private var pointerStack: some View {
        VStack(spacing: -(size * 0.40)) {
            QiblaArrow(width: layout.arrowWidth, height: layout.arrowHeight, tint: arrowColor)
                .animation(.easeInOut(duration: 0.2), value: arrowColor)
            Text("🕋")
                .font(.system(size: layout.kaabaSize))
                .shadow(
                    color: .black.opacity(0.25),
                    radius: max(0.6, layout.kaabaSize * 0.08),
                    x: 0,
                    y: 0
                )
        }
        .padding(.vertical, size * 0.16)
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
        .shadow(color: .primary.opacity(0.08), radius: 8, y: 2)
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
    let size: CGFloat
    let tint: Color
    let alignmentScore: Double

    @ViewBuilder
    private var glassFill: some View {
        #if os(iOS)
        Circle().fill(.ultraThinMaterial)
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
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.14), lineWidth: innerLineWidth)
                        .blur(radius: innerBlur)
                        .mask(Circle().stroke(lineWidth: innerLineWidth))
                )
                .overlay(
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
                )
                .shadow(color: .black.opacity(0.18), radius: shadowRadius, x: 0, y: max(0.5, size * 0.04))

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
            .shadow(color: tint.opacity(0.35), radius: max(0.6, width * 0.18), x: 0, y: 0)
    }
}

final class LocalQiblaCompassHolder: ObservableObject {
    @Published private(set) var inner: LocalQiblaCompass?
    @Published var direction: Double = 0

    private var cancellable: AnyCancellable?

    func startIfNeeded() {
        if let inner {
            inner.start()
            return
        }

        let compass = LocalQiblaCompass(locationProvider: {
            Settings.shared.currentLocation
        })

        inner = compass
        cancellable = compass.$direction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.direction = value
            }
        compass.start()
    }

    func stop() {
        inner?.stop()
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

    init(locationProvider: @escaping () -> Location?) {
        self.locationProvider = locationProvider
        super.init()
        locationManager.delegate = self
        // Take every heading sample and do our own smoothing - gives a steadier, sharper needle than
        // letting Core Location drop sub-degree changes.
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.headingOrientation = .portrait
    }

    func start() {
        guard !started, CLLocationManager.headingAvailable() else { return }
        started = true
        locationManager.startUpdatingHeading()
    }

    func stop() {
        guard started else { return }
        started = false
        locationManager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0, let currentLocation = locationProvider() else { return }

        let locationKey = "\(currentLocation.latitude),\(currentLocation.longitude)"
        let qiblaDirection: Double
        if cachedLocationKey == locationKey, let cachedQiblaDirection {
            qiblaDirection = cachedQiblaDirection
        } else {
            qiblaDirection = Qibla(
                coordinates: Coordinates(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            ).direction
            cachedLocationKey = locationKey
            cachedQiblaDirection = qiblaDirection
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
