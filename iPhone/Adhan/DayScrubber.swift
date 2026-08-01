import SwiftUI

/// Shared "what moment is the UI showing?" state, driven by dragging the sun along `SkyView`'s solar arc.
///
/// While a drag is in progress the whole Adhan tab previews that moment instead of now: the sky gradient
/// retints, the moon label follows, and `PrayerList` moves its highlight down the rows. Releasing snaps
/// everything back to live. A singleton for the same reason `FocusOverlayPresenter` is one - the views that
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
    ///
    /// Views that need per-move updates anyway (SkyView, the watch strip) read this directly. Views that
    /// only care about the highlighted PRAYER - which changes a handful of times per drag, not per
    /// touch-move - observe `ScrubHighlight.shared` instead, so ~60 `scrubbedDate` writes/second don't
    /// rebuild them (dragging used to rebuild the entire `PrayerList` section every touch-move).
    var previewPrayer: Prayer? {
        guard let scrubbedDate else { return nil }
        // Between midnight and Fajr no prayer has begun *today*, but the prayer in effect is the one that
        // began last night - Isha, the day's last. Scrubbing to 2 AM should read Isha, not Fajr.
        return timeline.last { $0.time <= scrubbedDate } ?? timeline.last
    }

    func begin(timeline: [Prayer]) {
        self.timeline = timeline.sorted { $0.time < $1.time }
    }

    func scrub(to date: Date) {
        scrubbedDate = date
        ScrubHighlight.shared.update(previewPrayer)
    }

    func end() {
        timeline = []
        withAnimation(.easeOut(duration: 0.25)) {
            scrubbedDate = nil
        }
        ScrubHighlight.shared.update(nil)
    }
}

/// The day picked in `PrayerList`'s date footer, or `nil` when the list is showing today. The moon in
/// `SkyView` follows it, so browsing another day's prayers also previews that night's moon phase - the
/// rest of the sky card (sun, gradient, countdown) stays live. Publishes only when the calendar DAY
/// actually changes, so sub-day churn from the date picker can't re-render the card.
@MainActor
final class SelectedDayPreview: ObservableObject {
    static let shared = SelectedDayPreview()
    private init() {}

    @Published private(set) var date: Date?

    func update(_ newDate: Date?) {
        let changed: Bool
        switch (date, newDate) {
        case (nil, nil):
            changed = false
        case let (old?, new?):
            changed = !Calendar.current.isDate(old, inSameDayAs: new)
        default:
            changed = true
        }
        guard changed else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            date = newDate
        }
    }
}

/// The row-highlight slice of the scrubber: publishes only when the prayer under the thumb actually
/// CHANGES. `PrayerList` observes this (not `DayScrubber`), so its section rebuilds a handful of times
/// per drag instead of on every touch-move.
@MainActor
final class ScrubHighlight: ObservableObject {
    static let shared = ScrubHighlight()
    private init() {}

    @Published private(set) var previewPrayer: Prayer?

    func update(_ prayer: Prayer?) {
        guard prayer?.nameTransliteration != previewPrayer?.nameTransliteration else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            previewPrayer = prayer
        }
    }
}
