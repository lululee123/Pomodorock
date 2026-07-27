import ActivityKit
import SwiftUI
import WidgetKit

struct PomodoroLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            PomodoroLockScreenView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Pomodorock")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    PomodoroCountdownText(state: context.state)
                        .font(.title3.monospacedDigit())
                }
            } compactLeading: {
                Image(systemName: symbolName(for: context.state))
                    .foregroundStyle(.orange)
            } compactTrailing: {
                PomodoroCountdownText(state: context.state)
                    .font(.caption2.monospacedDigit())
                    .frame(width: 42)
            } minimal: {
                Image(systemName: symbolName(for: context.state))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func symbolName(for state: PomodoroActivityAttributes.ContentState) -> String {
        state.pausedAt == nil ? "timer" : "pause.circle.fill"
    }
}

// MARK: - Countdown text
// Uses a fixed start/end range (not `Date.now`) so the system can animate
// the countdown natively; `pauseTime` freezes the display without needing a
// range that could ever become invalid.
private struct PomodoroCountdownText: View {
    let state: PomodoroActivityAttributes.ContentState

    private var virtualStart: Date {
        state.endDate.addingTimeInterval(-state.totalTime)
    }

    var body: some View {
        Text(timerInterval: virtualStart...state.endDate, pauseTime: state.pausedAt)
            .multilineTextAlignment(.trailing)
    }
}

// MARK: - Lock Screen presentation
private struct PomodoroLockScreenView: View {
    let state: PomodoroActivityAttributes.ContentState

    private var virtualStart: Date {
        state.endDate.addingTimeInterval(-state.totalTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Pomodorock")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Spacer()
                PomodoroCountdownText(state: state)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(.white)
            }

            if state.pausedAt == nil {
                ProgressView(timerInterval: virtualStart...state.endDate, countsDown: true)
                    .tint(.orange)
            }
        }
        .padding()
    }
}
