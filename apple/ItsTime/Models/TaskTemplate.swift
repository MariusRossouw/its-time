import Foundation
import SwiftData

@Model
final class TaskTemplate {
    var id: UUID
    var name: String
    var title: String
    var taskDescription: String
    var priority: TaskPriority
    var subtaskTitles: [String]
    var tagIds: [UUID]
    var isNote: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        title: String = "",
        taskDescription: String = "",
        priority: TaskPriority = .none,
        subtaskTitles: [String] = [],
        tagIds: [UUID] = [],
        isNote: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.subtaskTitles = subtaskTitles
        self.tagIds = tagIds
        self.isNote = isNote
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Create a TaskTemplate from an existing TaskItem
    static func from(task: TaskItem, name: String) -> TaskTemplate {
        TaskTemplate(
            name: name,
            title: task.title,
            taskDescription: task.taskDescription,
            priority: task.priority,
            subtaskTitles: task.subtasks.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.title),
            tagIds: task.tags.map(\.id),
            isNote: task.isNote
        )
    }
}
