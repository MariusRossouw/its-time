import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class BadgeService {
    static func updateBadge(count: Int) {
        let enabled = UserDefaults.standard.bool(forKey: "badgeCountEnabled")
        guard enabled else {
            clearBadge()
            return
        }

        #if canImport(UIKit)
        UNUserNotificationCenter.current().setBadgeCount(count)
        #endif
    }

    static func clearBadge() {
        #if canImport(UIKit)
        UNUserNotificationCenter.current().setBadgeCount(0)
        #endif
    }
}
