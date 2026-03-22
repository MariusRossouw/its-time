import Foundation
import SwiftData

@Model
final class Subtask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var notes: String
    var sortOrder: Int

    var task: TaskItem?

    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.notes = ""
        self.sortOrder = sortOrder
    }
}
