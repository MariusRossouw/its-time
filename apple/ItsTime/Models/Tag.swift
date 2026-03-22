import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String // hex
    var sortOrder: Int

    var parentTag: Tag?
    @Relationship(inverse: \TaskItem.tags)
    var tasks: [TaskItem]

    init(name: String, color: String = "#8E8E93", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.sortOrder = sortOrder
        self.tasks = []
    }
}
