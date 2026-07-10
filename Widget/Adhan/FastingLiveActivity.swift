#if os(iOS)
import SwiftUI
import WidgetKit
import ActivityKit

/// Lock Screen card + Dynamic Island for the Ramadan fasting countdown — suhoor to Fajr, iftar to Maghrib.
///
/// Every countdown uses the system's self-updating `Text(timerInterval:)` rather than a timer of our own:
/// a Live Activity's process isn't running most of the time, so anything computed at render is frozen at that
/// instant. `timerInterval` is the only thing that keeps ticking.
@available(iOS 16.2, *)
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingAttributes.self) { context in
            FastingLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.phase.title, systemImage: context.attributes.phase.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endTime, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("until \(context.state.prayerName) in \(context.attributes.city)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.attributes.phase.symbol)
            } compactTrailing: {
                Text(timerInterval: context.state.startTime...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: context.attributes.phase.symbol)
            }
            .keylineTint(context.attributes.phase == .suhoor ? .indigo : .orange)
        }
    }
}

@available(iOS 16.2, *)
private struct FastingLockScreenView: View {
    let context: ActivityViewContext<FastingAttributes>

    private var tint: Color { context.attributes.phase == .suhoor ? .indigo : .orange }

    var body: some View {
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
