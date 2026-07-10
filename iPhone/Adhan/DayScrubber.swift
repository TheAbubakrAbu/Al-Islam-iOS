import SwiftUI

/// Shared "what moment is the UI showing?" state, driven by dragging the sun along `SkyView`'s solar arc.
///
/// While a drag is in progress the whole Adhan tab previews that moment instead of now: the sky gradient
/// retints, the moon label follows, and `PrayerList` moves its highlight down the rows. Releasing snaps
/// everything back to live. A singleton for the same reason `FocusOverlayPresenter` is one — the views that
/// read it (`PrayerList`'s rows) sit deep inside a `List` two sections away from the view that writes it.
@MainActor
final class DayScrubber: ObservableObject {
    static let shared = DayScrubber()
    private init() {}

    /// The moment being previewed, or `nil` when the UI is showing the live time.
    @Published private(set) var scrubbedDate: Date?

    /// Today's prayers, sorted, captured once when a drag begins. Resolving the previewed prayer on every
    /// touch-move would otherwise recompute prayer times ~60×/second.
    private var timeline: [Prayer] = []

    var isScrubbing: Bool { scrubbedDate != nil }

    /// The prayer in effect at the previewed moment, or `nil` when live.
    var previewPrayer: Prayer? {
        guard let scrubbedDate else { return nil }
        // Between midnight and Fajr no prayer has begun *today*, but the prayer in effect is the one that
        // began last night — Isha, the day's last. Scrubbing to 2 AM should read Isha, not Fajr.
        return timeline.last { $0.time <= scrubbedDate } ?? timeline.last
    }

    func begin(timeline: [Prayer]) {
        self.timeline = timeline.sorted { $0.time < $1.time }
    }

    func scrub(to date: Date) {
        scrubbedDate = date
    }

    func end() {
        timeline = []
        withAnimation(.easeOut(duration: 0.25)) {
            scrubbedDate = nil
        }
    }
}
