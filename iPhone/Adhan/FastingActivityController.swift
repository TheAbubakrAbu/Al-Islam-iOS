#if os(iOS)
import Foundation
import ActivityKit

/// Starts and ends the Ramadan fasting Live Activity: a countdown to Fajr (the end of suhoor) before dawn, and
/// a countdown to Maghrib (iftar) before sunset.
///
/// A Live Activity can only be *requested* while the app is in the foreground, so this is driven from the
/// app-active path rather than from a timer: every time the app comes forward we ask which phase - if any - 
/// we're inside, and start, refresh or end accordingly.
@MainActor
enum FastingActivityController {
    /// How long before Fajr or Maghrib the countdown appears. An hour is long enough to be useful for suhoor
    /// and for the last stretch of the fast, without occupying the Lock Screen all day.
    static let leadTime: TimeInterval = 60 * 60

    /// Kept on screen briefly past the deadline so the "0:00" is seen, then dismissed.
    private static let lingerAfterDeadline: TimeInterval = 5 * 60

    /// Availability-gated because it names `FastingAttributes.Phase`, which is iOS 16.1+.
    @available(iOS 16.1, *)
    private struct Window {
        let phase: FastingAttributes.Phase
        let deadline: Date
        let prayerName: String
    }

    static func refresh() {
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let settings = Settings.shared
        guard let window = activeWindow(settings: settings) else {
            endAll()
            return
        }

        let state = FastingAttributes.ContentState(
            startTime: window.deadline.addingTimeInterval(-leadTime),
            endTime: window.deadline,
            prayerName: window.prayerName
        )
        let staleDate = window.deadline.addingTimeInterval(60)

        // An activity for this same phase and deadline is already up - update it rather than stacking another.
        if let existing = Activity<FastingAttributes>.activities.first(where: {
            $0.attributes.phase == window.phase
                && abs($0.content.state.endTime.timeIntervalSince(window.deadline)) < 60
        }) {
            // Every foregrounding used to push an identical state, and each push is a re-archive of the
            // card's views by the system. Same times, same name: nothing to say.
            if existing.content.state != state {
                Task { await existing.update(ActivityContent(state: state, staleDate: staleDate)) }
            }
            scheduleFinalStretchRender(phase: window.phase, deadline: window.deadline)
            return
        }

        // Anything else on screen belongs to a phase that has finished, or to a previous day.
        endAll()

        do {
            _ = try Activity.request(
                attributes: FastingAttributes(phase: window.phase, city: settings.currentLocation?.city ?? ""),
                content: ActivityContent(state: state, staleDate: staleDate),
                pushType: nil
            )
            scheduleFinalStretchRender(phase: window.phase, deadline: window.deadline)
        } catch {
            logger.error("Fasting Live Activity request failed: \(error.localizedDescription)")
        }
    }

    private static var finalStretchWork: DispatchWorkItem?

    /// The card's red "final stretch" tint (`ContentState.isFinalStretch`) reads the clock when the
    /// system renders the card, and the system renders only on an update. With identical states no
    /// longer pushed, this schedules the one update that matters: at ten minutes out, with the same
    /// content, purely so the card is drawn again. Only while the app process lives, which is the same
    /// limit the old "re-render on every foregrounding" had.
    @available(iOS 16.2, *)
    private static func scheduleFinalStretchRender(phase: FastingAttributes.Phase, deadline: Date) {
        finalStretchWork?.cancel()
        finalStretchWork = nil
        let fireAt = deadline.addingTimeInterval(-10 * 60)
        let delay = fireAt.timeIntervalSinceNow
        guard delay > 0 else { return }
        let work = DispatchWorkItem {
            finalStretchWork = nil
            guard let activity = Activity<FastingAttributes>.activities.first(where: {
                $0.attributes.phase == phase && abs($0.content.state.endTime.timeIntervalSince(deadline)) < 60
            }) else { return }
            let content = ActivityContent(state: activity.content.state, staleDate: deadline.addingTimeInterval(60))
            Task { await activity.update(content) }
        }
        finalStretchWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    static func endAll() {
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<FastingAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    // MARK: - Which phase are we in?

    /// The countdown that should be on screen right now, or `nil`. Iftar is tested before suhoor: late on a
    /// fasting day both Maghrib (this evening) and Fajr (tomorrow's dawn, via the `offset == 1` pass) exist,
    /// and the one closing sooner is the one that matters.
    @available(iOS 16.1, *)
    private static func activeWindow(settings: Settings) -> Window? {
        let now = Date()
        let phases: [(FastingAttributes.Phase, String)] = [(.iftar, "Maghrib"), (.suhoor, "Fajr")]

        for offset in 0...1 {
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: now),
                  isFastingDay(day, settings: settings),
                  let prayers = settings.getPrayerTimes(for: day, fullPrayers: true)
            else { continue }

            for (phase, name) in phases {
                guard let deadline = prayers.first(where: { $0.nameTransliteration == name })?.time else { continue }
                let remaining = deadline.timeIntervalSince(now)
                guard remaining > -lingerAfterDeadline, remaining <= leadTime else { continue }
                return Window(
                    phase: phase,
                    deadline: deadline,
                    prayerName: settings.customPrayerName(for: name) ?? name
                )
            }
        }
        return nil
    }

    /// Whether `date` falls in Ramadan, honoring the user's Hijri offset so the countdown agrees with the
    /// Hijri date the app displays. Sampled at noon: a Hijri day turns over at Maghrib, so reading near either
    /// end of the Gregorian day would land on the wrong Hijri day.
    ///
    /// Gated at all because suhoor and iftar are Ramadan observances - an unconditional nightly countdown to
    /// Fajr would sit on the Lock Screen 365 nights a year.
    private static func isFastingDay(_ date: Date, settings: Settings) -> Bool {
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = Calendar.current.timeZone

        guard let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date),
              let adjusted = hijri.date(byAdding: .day, value: settings.hijriOffset, to: noon)
        else { return false }

        return hijri.component(.month, from: adjusted) == 9
    }
}
#endif
