import Foundation
import SwiftData

@Model
final class ActivityEntry {
    var id: UUID
    var action: ActivityAction
    var field: String? // which field changed (e.g. "status", "priority")
    var oldValue: String?
    var newValue: String?
    var authorName: String
    var authorId: UUID
    var timestamp: Date

    // Relationships
    var task: TaskItem?

    init(
        action: ActivityAction,
        field: String? = nil,
        oldValue: String? = nil,
        newValue: String? = nil,
        authorName: String,
        authorId: UUID,
        task: TaskItem? = nil
    ) {
        self.id = UUID()
        self.action = action
        self.field = field
        self.oldValue = oldValue
        self.newValue = newValue
        self.authorName = authorName
        self.authorId = authorId
        self.task = task
        self.timestamp = Date()
    }

    var displayText: String {
        switch action {
        case .created:
            return "\(authorName) created this task"
        case .completed:
            return "\(authorName) marked this as done"
        case .reopened:
            return "\(authorName) reopened this task"
        case .assigned:
            if let newValue {
                return "\(authorName) assigned to \(newValue)"
            }
            return "\(authorName) removed the assignee"
        case .commented:
            return "\(authorName) added a comment"
        case .moved:
            if let oldValue, let newValue {
                return "\(authorName) moved from \(oldValue) to \(newValue)"
            }
            return "\(authorName) moved this task"
        case .fieldChanged:
            if let field, let oldValue, let newValue {
                return "\(authorName) changed \(field) from \(oldValue) to \(newValue)"
            } else if let field, let newValue {
                return "\(authorName) set \(field) to \(newValue)"
            } else if let field {
                return "\(authorName) changed \(field)"
            }
            return "\(authorName) updated this task"
        case .wontDo:
            return "\(authorName) marked this as won't do"
        }
    }

    var icon: String {
        switch action {
        case .created: return "plus.circle"
        case .completed: return "checkmark.circle.fill"
        case .reopened: return "arrow.uturn.backward.circle"
        case .assigned: return "person.circle"
        case .commented: return "text.bubble"
        case .moved: return "arrow.right.circle"
        case .fieldChanged: return "pencil.circle"
        case .wontDo: return "xmark.circle"
        }
    }
}

enum ActivityAction: String, Codable {
    case created
    case completed
    case reopened
    case assigned
    case commented
    case moved
    case fieldChanged
    case wontDo
}
