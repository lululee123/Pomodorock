import Foundation
import UserNotifications

// MARK: - Notification Service (本地「專注完成」提醒)
// Fires even if the app is fully suspended, complementing the Live Activity.
enum NotificationService {
    private static let completionRequestID = "com.pomodorock.focusCompleted"

    static func requestAuthorizationIfNeeded() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    static func scheduleCompletion(at endDate: Date, title: String) {
        cancelPendingCompletion()

        let interval = endDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: completionRequestID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelPendingCompletion() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [completionRequestID])
    }
}
