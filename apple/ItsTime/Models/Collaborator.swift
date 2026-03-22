import Foundation
import SwiftData

@Model
final class Collaborator {
    var id: UUID
    var name: String
    var email: String
    var githubUsername: String
    var initials: String
    var color: String // hex
    var isCurrentUser: Bool
    var deviceId: String
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        email: String = "",
        githubUsername: String = "",
        color: String = "#007AFF",
        isCurrentUser: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.githubUsername = githubUsername
        self.color = color
        self.isCurrentUser = isCurrentUser
        self.deviceId = DeviceInfo.deviceId
        self.createdAt = Date()
        self.updatedAt = Date()

        // Compute initials from name
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            self.initials = String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = parts.first {
            self.initials = String(first.prefix(2)).uppercased()
        } else {
            self.initials = "?"
        }
    }
}
