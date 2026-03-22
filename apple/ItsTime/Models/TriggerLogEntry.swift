import Foundation
import SwiftData

@Model
final class TriggerLogEntry {
    var id: UUID
    var firedAt: Date
    var triggerName: String
    var actionDescription: String
    var taskTitle: String?
    var trigger: Trigger?

    init(triggerName: String, actionDescription: String, taskTitle: String? = nil) {
        self.id = UUID()
        self.firedAt = Date()
        self.triggerName = triggerName
        self.actionDescription = actionDescription
        self.taskTitle = taskTitle
    }
}
