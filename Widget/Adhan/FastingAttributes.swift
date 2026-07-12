#if os(iOS)
import Foundation
import ActivityKit

/// The Ramadan fasting Live Activity: a Lock Screen card and Dynamic Island counting down either to Fajr
/// (the end of suhoor) or to Maghrib (iftar). Compiled into both the app - which starts and ends it - and the
/// widget extension, which renders it, so the two agree on the payload.
@available(iOS 16.1, *)
struct FastingAttributes: ActivityAttributes {
    /// Fixed for the life of one activity. A phase change ends this activity and starts the next, so the phase
    /// can live here rather than in the state.
    let phase: Phase
    let city: String

    enum Phase: String, Codable, Hashable {
        /// Counting down to Fajr: the last chance to eat.
        case suhoor
        /// Counting down to Maghrib: the fast breaks.
        case iftar

        var title: String {
            switch self {
            case .suhoor: return "Suhoor"
            case .iftar:  return "Iftar"
            }
        }

        var symbol: String {
            switch self {
            case .suhoor: return "moon.stars.fill"
            case .iftar:  return "sunset.fill"
            }
        }
    }

    struct ContentState: Codable, Hashable {
        /// When the countdown began. Needed to draw a progress bar, since the system's self-updating timer
        /// views take a date *range*, not a remaining duration.
        let startTime: Date
        /// Fajr for suhoor, Maghrib for iftar.
        let endTime: Date
        /// The user's own spelling of the prayer the countdown ends on.
        let prayerName: String
    }
}

@available(iOS 16.1, *)
extension FastingAttributes.ContentState {
    var secondsRemaining: TimeInterval { max(0, endTime.timeIntervalSinceNow) }

    /// Fraction of the countdown already elapsed, clamped - for the progress capsule.
    var progress: Double {
        let total = endTime.timeIntervalSince(startTime)
        guard total > 0 else { return 1 }
        return min(max(1 - secondsRemaining / total, 0), 1)
    }

    /// The last stretch, where the card turns urgent.
    var isFinalStretch: Bool { secondsRemaining <= 10 * 60 }
}
#endif
