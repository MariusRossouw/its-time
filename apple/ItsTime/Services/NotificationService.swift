import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func scheduleReminders(for task: TaskItem) {
        // Remove existing notifications for this task
        cancelReminders(for: task)

        guard let dueDate = task.dueDate, task.status == .todo else { return }

        for (index, offset) in task.reminderOffsets.enumerated() {
            let triggerDate = dueDate.addingTimeInterval(TimeInterval(offset))

            // Don't schedule reminders in the past
            guard triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = task.title
            content.body = reminderBody(offset: offset, dueDate: dueDate)
            content.sound = .default
            content.categoryIdentifier = "TASK_REMINDER"
            content.userInfo = ["taskId": task.id.uuidString]

            if task.priority == .high {
                content.interruptionLevel = .timeSensitive
            }

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(task.id.uuidString)-reminder-\(index)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }

    func cancelReminders(for task: TaskItem) {
        let prefix = task.id.uuidString
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func registerCategories() {
        let doneAction = UNNotificationAction(
            identifier: "MARK_DONE",
            title: "Done",
            options: []
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "Snooze 15 min",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [doneAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Fire a notification when someone @mentions you in chat.
    func fireMentionNotification(mentionedName: String, authorName: String, messageText: String, channelName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(authorName) mentioned you in \(channelName)"
        content.body = messageText
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "mention-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Fire a location-based reminder notification for a task.
    func fireLocationReminder(taskId: String, taskTitle: String, locationName: String?, direction: String) {
        let content = UNMutableNotificationContent()
        content.title = taskTitle
        let place = locationName ?? "this location"
        content.body = "You \(direction) \(place)"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": taskId]

        let request = UNNotificationRequest(
            identifier: "\(taskId)-location",
            content: content,
            trigger: nil // fire immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleNudge(for task: TaskItem) {
        cancelNudge(for: task)

        guard let nudgeDate = task.nudgeDate, task.status == .todo else { return }
        guard nudgeDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to check on: \(task.title)"
        content.body = "You set a reminder for this task"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": task.id.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nudgeDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(task.id.uuidString)-nudge",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Failed to schedule nudge: \(error)") }
        }
    }

    func cancelNudge(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(task.id.uuidString)-nudge"]
        )
    }

    private func reminderBody(offset: Int, dueDate: Date) -> String {
        let absOffset = abs(offset)
        if absOffset == 0 {
            return "Due now"
        } else if absOffset < 3600 {
            let minutes = absOffset / 60
            return "Due in \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if absOffset < 86400 {
            let hours = absOffset / 3600
            return "Due in \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let days = absOffset / 86400
            return "Due in \(days) day\(days == 1 ? "" : "s")"
        }
    }
}
