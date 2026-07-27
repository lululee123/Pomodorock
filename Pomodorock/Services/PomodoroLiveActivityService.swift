import ActivityKit
import Foundation

// MARK: - Pomodoro Live Activity Service (Lock Screen / Dynamic Island)
// Local-only activity: no push-to-start or remote updates, so no extra
// entitlement is needed beyond the NSSupportsLiveActivities Info.plist key.
@MainActor
enum PomodoroLiveActivityService {
    private static var currentActivity: Activity<PomodoroActivityAttributes>?

    static func start(endDate: Date, totalTime: TimeInterval) {
        end()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = PomodoroActivityAttributes.ContentState(
            endDate: endDate,
            totalTime: totalTime,
            pausedAt: nil
        )
        currentActivity = try? Activity.request(
            attributes: PomodoroActivityAttributes(),
            content: .init(state: state, staleDate: nil)
        )
    }

    static func update(endDate: Date, totalTime: TimeInterval, pausedAt: Date?) {
        guard let activity = currentActivity else { return }
        let state = PomodoroActivityAttributes.ContentState(
            endDate: endDate,
            totalTime: totalTime,
            pausedAt: pausedAt
        )
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    // Freezes the display at the terminal value (rather than leaving a live
    // date range that has already elapsed) before dismissing shortly after.
    static func finish(endDate: Date, totalTime: TimeInterval) {
        guard let activity = currentActivity else { return }
        currentActivity = nil
        let state = PomodoroActivityAttributes.ContentState(
            endDate: endDate,
            totalTime: totalTime,
            pausedAt: endDate
        )
        Task {
            await activity.end(
                .init(state: state, staleDate: nil),
                dismissalPolicy: .after(Date().addingTimeInterval(5))
            )
        }
    }

    static func end() {
        guard let activity = currentActivity else { return }
        currentActivity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
