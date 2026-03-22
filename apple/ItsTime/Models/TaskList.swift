import Foundation
import SwiftData

@Model
final class TaskList {
    var id: UUID
    var name: String
    var color: String // hex
    var icon: String // SF Symbol name
    var isInbox: Bool
    var sortOrder: Int
    var isShared: Bool
    var collaboratorIdsData: Data? // JSON-encoded [UUID]
    var syncProfileId: UUID? // nil = local only
    var createdAt: Date
    var updatedAt: Date
    var deviceId: String

    var collaboratorIds: [UUID] {
        get {
            guard let data = collaboratorIdsData else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            collaboratorIdsData = try? JSONEncoder().encode(newValue)
        }
    }

    // Relationships
    var folder: Folder?
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.list)
    var tasks: [TaskItem]
    @Relationship(deleteRule: .cascade, inverse: \ListSection.list)
    var sections: [ListSection]

    init(
        name: String,
        color: String = "#007AFF",
        icon: String = "list.bullet",
        isInbox: Bool = false,
        sortOrder: Int = 0,
        folder: Folder? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.isInbox = isInbox
        self.sortOrder = sortOrder
        self.folder = folder
        self.isShared = false
        self.collaboratorIdsData = nil
        self.syncProfileId = nil
        self.tasks = []
        self.sections = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deviceId = DeviceInfo.deviceId
    }

    var activeTasks: [TaskItem] {
        tasks.filter { $0.status == .todo }
    }

    var activeTaskCount: Int {
        activeTasks.count
    }
}
