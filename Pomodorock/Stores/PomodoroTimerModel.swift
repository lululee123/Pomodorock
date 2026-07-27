import Foundation
import Observation
import SwiftUI

// MARK: - Pomodoro Timer Model
// Countdown is derived from an absolute endDate rather than a per-tick
// decrement, so it stays correct across backgrounding/locking regardless of
// how many ticks were missed while suspended.
@MainActor
@Observable
final class PomodoroTimerModel {
    var focusMinutes: Int {
        didSet {
            guard !isRunning else { return }
            timeRemaining = totalTime
        }
    }
    private(set) var timeRemaining: TimeInterval
    private(set) var isRunning = false
    private(set) var isPaused = false

    // Set by the view once, to react to a completed session (sound, quote bubble).
    var onFinish: (() -> Void)?

    private var endDate: Date?

    var totalTime: TimeInterval { Double(focusMinutes) * 60 }

    var progress: Double {
        totalTime > 0 ? timeRemaining / totalTime : 0
    }

    init(focusMinutes: Int = TimerConfig.focusMinutes) {
        self.focusMinutes = focusMinutes
        self.timeRemaining = Double(focusMinutes) * 60
    }

    // Called every second while foreground, and once when the app becomes
    // active again (to correct any drift accumulated while suspended).
    func tick() {
        guard isRunning, let endDate else { return }
        let remaining = max(0, endDate.timeIntervalSinceNow)
        timeRemaining = remaining
        if remaining <= 0 {
            finish(at: endDate)
        }
    }

    func toggle(notificationTitle: String) {
        isRunning ? pause() : start(notificationTitle: notificationTitle)
    }

    func start(notificationTitle: String) {
        let newEndDate = Date().addingTimeInterval(timeRemaining)
        endDate = newEndDate
        isRunning = true
        isPaused = false

        PomodoroLiveActivityService.start(endDate: newEndDate, totalTime: totalTime)
        NotificationService.scheduleCompletion(at: newEndDate, title: notificationTitle)
    }

    func pause() {
        guard isRunning, let currentEndDate = endDate else { return }
        let now = Date()
        timeRemaining = max(0, currentEndDate.timeIntervalSince(now))
        endDate = nil
        isRunning = false
        isPaused = true

        let frozenEndDate = now.addingTimeInterval(timeRemaining)
        PomodoroLiveActivityService.update(
            endDate: frozenEndDate,
            totalTime: totalTime,
            pausedAt: now
        )
        NotificationService.cancelPendingCompletion()
    }

    func reset() {
        endDate = nil
        isRunning = false
        isPaused = false
        timeRemaining = totalTime

        PomodoroLiveActivityService.end()
        NotificationService.cancelPendingCompletion()
    }

    private func finish(at completedEndDate: Date) {
        endDate = nil
        isRunning = false
        isPaused = false

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            timeRemaining = totalTime
        }

        PomodoroLiveActivityService.finish(endDate: completedEndDate, totalTime: totalTime)
        NotificationService.cancelPendingCompletion()
        onFinish?()
    }
}
