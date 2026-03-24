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

    // Comment fields (used when action == .commented)
    var commentText: String?
    var authorColor: String? // hex, for avatar display

    // Threading (replies to a comment)
    var parentCommentId: UUID? // nil = top-level or non-comment entry
    @Relationship(deleteRule: .cascade)
    var replies: [ActivityEntry]

    // Relationships
    var task: TaskItem?

    init(
        action: ActivityAction,
        field: String? = nil,
        oldValue: String? = nil,
        newValue: String? = nil,
        authorName: String,
        authorId: UUID,
        commentText: String? = nil,
        authorColor: String? = nil,
        parentCommentId: UUID? = nil,
        task: TaskItem? = nil
    ) {
        self.id = UUID()
        self.action = action
        self.field = field
        self.oldValue = oldValue
        self.newValue = newValue
        self.authorName = authorName
        self.authorId = authorId
        self.commentText = commentText
        self.authorColor = authorColor
        self.parentCommentId = parentCommentId
        self.replies = []
        self.task = task
        self.timestamp = Date()
    }

    var isComment: Bool {
        action == .commented && commentText != nil
    }

    var isTopLevelComment: Bool {
        isComment && parentCommentId == nil
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
            return commentText ?? "\(authorName) added a comment"
        case .moved:
            if let oldValue, let newValue {
                return "\(authorName) moved from \(oldValue) to \(newValue)"
            } else if let newValue {
                return "\(authorName) moved to \(newValue)"
            } else if let oldValue {
                return "\(authorName) removed from \(oldValue)"
            }
            return "\(authorName) moved this task"
        case .fieldChanged:
            if let field, let oldValue, let newValue {
                return "\(authorName) changed \(field) from \(oldValue) to \(newValue)"
            } else if let field, let newValue {
                return "\(authorName) set \(field) to \(newValue)"
            } else if let field, let oldValue {
                return "\(authorName) cleared \(field) (was \(oldValue))"
            } else if let field {
                return "\(authorName) changed \(field)"
            }
            return "\(authorName) updated this task"
        case .wontDo:
            return "\(authorName) marked this as won't do"
        case .tagAdded:
            return "\(authorName) added tag \(newValue ?? "")"
        case .tagRemoved:
            return "\(authorName) removed tag \(oldValue ?? "")"
        case .subtaskAdded:
            return "\(authorName) added subtask \"\(newValue ?? "")\""
        case .subtaskCompleted:
            return "\(authorName) completed subtask \"\(newValue ?? "")\""
        case .subtaskUncompleted:
            return "\(authorName) unchecked subtask \"\(newValue ?? "")\""
        case .childAdded:
            return "\(authorName) added child \"\(newValue ?? "")\""
        case .childRemoved:
            return "\(authorName) removed child \"\(oldValue ?? "")\""
        case .habitLinked:
            return "\(authorName) linked habit \"\(newValue ?? "")\""
        case .habitUnlinked:
            return "\(authorName) unlinked habit \"\(oldValue ?? "")\""
        case .reminderAdded:
            return "\(authorName) added reminder: \(newValue ?? "")"
        case .reminderRemoved:
            return "\(authorName) removed reminder: \(oldValue ?? "")"
        case .converted:
            return "\(authorName) converted to \(newValue ?? "task")"
        case .parentChanged:
            if let newValue {
                return "\(authorName) set parent to \"\(newValue)\""
            } else if let oldValue {
                return "\(authorName) removed parent \"\(oldValue)\""
            }
            return "\(authorName) changed the parent task"
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
        case .tagAdded: return "tag"
        case .tagRemoved: return "tag.slash"
        case .subtaskAdded: return "checklist"
        case .subtaskCompleted: return "checkmark.circle"
        case .subtaskUncompleted: return "circle"
        case .childAdded: return "plus.rectangle.on.rectangle"
        case .childRemoved: return "minus.rectangle"
        case .habitLinked: return "leaf"
        case .habitUnlinked: return "leaf.arrow.triangle.circlepath"
        case .reminderAdded: return "bell.badge"
        case .reminderRemoved: return "bell.slash"
        case .converted: return "arrow.triangle.2.circlepath"
        case .parentChanged: return "arrow.turn.up.left"
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
    case tagAdded
    case tagRemoved
    case subtaskAdded
    case subtaskCompleted
    case subtaskUncompleted
    case childAdded
    case childRemoved
    case habitLinked
    case habitUnlinked
    case reminderAdded
    case reminderRemoved
    case converted
    case parentChanged
}
