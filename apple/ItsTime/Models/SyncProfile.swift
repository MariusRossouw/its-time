import Foundation
import SwiftData

@Model
final class SyncProfile {
    var id: UUID
    var name: String
    var repoPath: String
    var tokenKeychainKey: String
    var color: String
    var icon: String
    var isEnabled: Bool
    var lastSyncDate: Date?
    var lastError: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        repoPath: String,
        tokenKeychainKey: String,
        color: String = "#007AFF",
        icon: String = "cloud",
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.repoPath = repoPath
        self.tokenKeychainKey = tokenKeychainKey
        self.color = color
        self.icon = icon
        self.isEnabled = isEnabled
        self.lastSyncDate = nil
        self.lastError = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

}
