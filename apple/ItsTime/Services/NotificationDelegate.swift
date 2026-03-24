import Foundation
import UserNotifications
import SwiftData

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let shared = NotificationDelegate()

    // Handle notification actions (snooze, mark done)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let taskIdString = userInfo["taskId"] as? String else { return }

        switch response.actionIdentifier {
        case "SNOOZE_15":
            // Reschedule 15 minutes from now
            let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(taskIdString)-snooze-\(Int(Date().timeIntervalSince1970))",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)

        case "MARK_DONE", "NUDGE_DONE":
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .taskMarkedDoneFromNotification,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "NUDGE_LATER":
            // Snooze auto-nudge for 1 hour
            let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(taskIdString)-autonudge-snooze-\(Int(Date().timeIntervalSince1970))",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)

        case "NUDGE_WONT_DO":
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .taskMarkedWontDoFromNotification,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "NUDGE_DELETE":
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .taskDeletedFromNotification,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        default:
            break
        }
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

extension Notification.Name {
    static let taskMarkedDoneFromNotification = Notification.Name("taskMarkedDoneFromNotification")
    static let taskMarkedWontDoFromNotification = Notification.Name("taskMarkedWontDoFromNotification")
    static let taskDeletedFromNotification = Notification.Name("taskDeletedFromNotification")
}
