import Foundation
import UserNotifications

@MainActor
final class DailySummaryService {
    static let shared = DailySummaryService()
    private init() {}

    private let summaryIdentifier = "daily-summary"

    func scheduleDailySummary(hour: Int) {
        cancelDailySummary()

        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        content.body = "Check your tasks for today."
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: summaryIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule daily summary: \(error)")
            }
        }
    }

    func cancelDailySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [summaryIdentifier]
        )
    }
}
