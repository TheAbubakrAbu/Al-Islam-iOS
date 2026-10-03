#if os(iOS)
import SwiftUI
import WidgetKit
import ActivityKit

/// Lock Screen card + Dynamic Island for the Ramadan fasting countdown - suhoor to Fajr, iftar to Maghrib.
///
/// Every countdown uses the system's self-updating `Text(timerInterval:)` rather than a timer of our own:
/// a Live Activity's process isn't running most of the time, so anything computed at render is frozen at that
/// instant. `timerInterval` is the only thing that keeps ticking.
///
/// From iOS 18 it also offers the small family, which is what CarPlay's dashboard (iOS 26) and a paired
/// watch's Smart Stack draw: without it the car shows only the Dynamic Island's two compact ends.
@available(iOS 16.2, *)
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingAttributes.self) { context in
            FastingActivityView(context: context)
                .appFontDesign()
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.phase.title, systemImage: context.attributes.phase.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .appFontDesign()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endTime, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .appFontDesign()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.center)
                        .appFontDesign()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("until \(context.state.prayerName) in \(context.attributes.city)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .appFontDesign()
                }
            } compactLeading: {
                Image(systemName: context.attributes.phase.symbol)
            } compactTrailing: {
                if context.isStale {
                    Image(systemName: "checkmark")
                } else {
                    Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                        .monospacedDigit()
                        .frame(maxWidth: 44)
                        .appFontDesign()
                }
            } minimal: {
                Image(systemName: context.attributes.phase.symbol)
            }
            .keylineTint(context.attributes.phase == .suhoor ? .indigo : .orange)
        }
        .offersSmallActivityFamily()
    }
}

private extension WidgetConfiguration {
    func offersSmallActivityFamily() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 18.0, *) {
            return supplementalActivityFamilies([.small])
        } else {
            return self
        }
    }
}

/// The Lock Screen card, or the small one where the system asks for the small family.
@available(iOS 16.2, *)
private struct FastingActivityView: View {
    let context: ActivityViewContext<FastingAttributes>

    var body: some View {
        if #available(iOSApplicationExtension 18.0, *) {
            FastingFamilyView(context: context)
        } else {
            FastingLockScreenView(context: context)
        }
    }
}

@available(iOSApplicationExtension 18.0, *)
private struct FastingFamilyView: View {
    @Environment(\.activityFamily) private var family
    let context: ActivityViewContext<FastingAttributes>

    var body: some View {
        if family == .small {
            FastingSmallView(context: context)
        } else {
            FastingLockScreenView(context: context)
        }
    }
}

/// CarPlay's dashboard and the watch's Smart Stack: the phase, the countdown in large type, and the time it
/// ends at, read at a glance.
@available(iOS 16.2, *)
private struct FastingSmallView: View {
    let context: ActivityViewContext<FastingAttributes>

    private var tint: Color { context.attributes.phase == .suhoor ? .indigo : .orange }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(context.attributes.phase.title, systemImage: context.attributes.phase.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
            if context.isStale {
                Text("\(context.state.prayerName) has begun")
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            } else {
                Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                    .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(context.state.isFinalStretch ? .red : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text("\(context.state.prayerName) at \(context.state.endTime, style: .time)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }
}

@available(iOS 16.2, *)
private struct FastingLockScreenView: View {
    let context: ActivityViewContext<FastingAttributes>

    private var tint: Color { context.attributes.phase == .suhoor ? .indigo : .orange }

    var body: some View {
        if context.isStale {
            ended
        } else {
            countdown
        }
    }

    /// Past the deadline (the stale date is a minute after it) and not yet ended by the app: say the
    /// time has come instead of a countdown frozen at 0:00 (P7).
    private var ended: some View {
        HStack(spacing: 10) {
            Image(systemName: context.attributes.phase.symbol)
                .font(.title3)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(context.state.prayerName) has begun")
                    .font(.headline)
                Text("at \(context.state.endTime, style: .time)\(context.attributes.city.isEmpty ? "" : " in \(context.attributes.city)")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var countdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(context.attributes.phase.title, systemImage: context.attributes.phase.symbol)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(context.state.prayerName) at \(context.state.endTime, style: .time)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())

            // `ProgressView(timerInterval:)` keeps animating on its own; a plain `ProgressView(value:)` would
            // freeze at whatever fraction it held the moment the system last rendered this card.
            ProgressView(timerInterval: context.state.startTime...context.state.endTime, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(context.state.isFinalStretch ? .red : tint)
            // Same slim-bar treatment as the widgets: squash the system bar (a custom style's fraction
            // wouldn't live-animate) and cap away the phantom space reserved for the (empty) labels.
            .scaleEffect(x: 1, y: 0.5, anchor: .center)
            .frame(height: 4)

            if !context.attributes.city.isEmpty {
                Text(context.attributes.city)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
#endif
