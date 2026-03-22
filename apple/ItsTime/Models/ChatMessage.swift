import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var text: String
    var authorName: String
    var authorId: UUID
    var authorColor: String // hex
    var channelId: String // "general" or list UUID string
    var createdAt: Date

    // Mentions — stored as JSON array of collaborator IDs
    var mentionIdsData: Data?

    var mentionIds: [UUID] {
        get {
            guard let data = mentionIdsData else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            mentionIdsData = try? JSONEncoder().encode(newValue)
        }
    }

    // Optional task reference (for linking a message to a task)
    var referencedTaskId: UUID?
    var referencedTaskTitle: String?

    init(
        text: String,
        authorName: String,
        authorId: UUID,
        authorColor: String = "#007AFF",
        channelId: String = "general"
    ) {
        self.id = UUID()
        self.text = text
        self.authorName = authorName
        self.authorId = authorId
        self.authorColor = authorColor
        self.channelId = channelId
        self.mentionIdsData = nil
        self.referencedTaskId = nil
        self.referencedTaskTitle = nil
        self.createdAt = Date()
    }

    /// Extract @mentions from the text and return matching collaborator IDs.
    func parseMentions(from collaborators: [Collaborator]) -> [UUID] {
        var ids: [UUID] = []
        // Match @Name or @FirstName patterns
        let pattern = "@(\\w+(?:\\s\\w+)?)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return ids }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            let mentionName = nsText.substring(with: match.range(at: 1)).lowercased()
            if let collab = collaborators.first(where: {
                $0.name.lowercased() == mentionName ||
                $0.name.split(separator: " ").first?.lowercased() == mentionName
            }) {
                ids.append(collab.id)
            }
        }
        return ids
    }
}
