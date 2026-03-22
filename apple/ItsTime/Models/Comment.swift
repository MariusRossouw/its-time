import Foundation
import SwiftData

@Model
final class Comment {
    var id: UUID
    var text: String
    var authorName: String
    var authorId: UUID // collaborator id
    var authorColor: String // hex, cached for display
    var createdAt: Date
    var updatedAt: Date

    // Threading
    var parentId: UUID? // nil = top-level comment
    @Relationship(deleteRule: .cascade)
    var replies: [Comment]

    // Relationships
    var task: TaskItem?

    init(
        text: String,
        authorName: String,
        authorId: UUID,
        authorColor: String = "#007AFF",
        parentId: UUID? = nil,
        task: TaskItem? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.authorName = authorName
        self.authorId = authorId
        self.authorColor = authorColor
        self.parentId = parentId
        self.task = task
        self.replies = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isTopLevel: Bool {
        parentId == nil
    }
}
