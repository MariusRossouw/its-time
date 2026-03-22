import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var isExpanded: Bool
    var createdAt: Date
    var updatedAt: Date
    var deviceId: String

    @Relationship(deleteRule: .nullify, inverse: \TaskList.folder)
    var lists: [TaskList]

    init(name: String, icon: String = "folder", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.isExpanded = true
        self.lists = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deviceId = DeviceInfo.deviceId
    }
}
