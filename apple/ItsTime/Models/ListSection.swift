import Foundation
import SwiftData

@Model
final class ListSection {
    var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    var list: TaskList?
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.section)
    var tasks: [TaskItem]

    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.tasks = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
