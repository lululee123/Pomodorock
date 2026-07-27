import ActivityKit
import Foundation

// MARK: - Pomodoro Live Activity Attributes
// Shared between the app (starts/updates/ends the activity) and the widget
// extension (renders it). `pausedAt` freezes the displayed countdown via
// Text(timerInterval:pauseTime:) instead of the activity disappearing.
// `totalTime` lets the widget derive a fixed start date (endDate - totalTime)
// for the countdown/progress ranges, without ever referencing `Date.now`.
struct PomodoroActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endDate: Date
        var totalTime: TimeInterval
        var pausedAt: Date?
    }
}
