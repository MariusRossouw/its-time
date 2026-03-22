import Foundation
import SwiftData

@Model
final class Trigger {
    var id: UUID
    var name: String
    var isEnabled: Bool
    var triggerType: TriggerType
    var matchAll: Bool // AND vs OR for conditions

    // Conditions stored as JSON
    var conditionsData: Data?

    // Actions stored as JSON
    var actionsData: Data?

    // Time-based
    var scheduledTime: Date? // specific time
    var relativeOffset: Int? // seconds relative to due date (negative = before)

    // Event-based
    var eventType: TriggerEventType?

    // Geolocation
    var latitude: Double?
    var longitude: Double?
    var radiusMeters: Double?
    var locationName: String?
    var geoDirection: GeoDirection?

    // Chained task
    var sourceTaskId: UUID? // completing this task fires the trigger

    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TriggerLogEntry.trigger)
    var logEntries: [TriggerLogEntry]

    init(
        name: String,
        triggerType: TriggerType = .event,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.isEnabled = true
        self.triggerType = triggerType
        self.matchAll = true
        self.sortOrder = sortOrder
        self.logEntries = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var conditions: [TriggerCondition] {
        get {
            guard let data = conditionsData else { return [] }
            return (try? JSONDecoder().decode([TriggerCondition].self, from: data)) ?? []
        }
        set { conditionsData = try? JSONEncoder().encode(newValue) }
    }

    var actions: [TriggerAction] {
        get {
            guard let data = actionsData else { return [] }
            return (try? JSONDecoder().decode([TriggerAction].self, from: data)) ?? []
        }
        set { actionsData = try? JSONEncoder().encode(newValue) }
    }
}

// MARK: - Enums

enum TriggerType: String, Codable, CaseIterable {
    case timeBased
    case event
    case geolocation
    case chain

    var label: String {
        switch self {
        case .timeBased: return "Time-Based"
        case .event: return "Event"
        case .geolocation: return "Location"
        case .chain: return "Task Chain"
        }
    }

    var icon: String {
        switch self {
        case .timeBased: return "clock"
        case .event: return "bolt"
        case .geolocation: return "location"
        case .chain: return "link"
        }
    }
}

enum TriggerEventType: String, Codable, CaseIterable {
    case taskCompleted
    case taskCreated
    case statusChanged
    case taskOverdue

    var label: String {
        switch self {
        case .taskCompleted: return "Task Completed"
        case .taskCreated: return "Task Created"
        case .statusChanged: return "Status Changed"
        case .taskOverdue: return "Task Overdue"
        }
    }
}

enum GeoDirection: String, Codable, CaseIterable {
    case enter
    case leave

    var label: String {
        switch self {
        case .enter: return "Enter Area"
        case .leave: return "Leave Area"
        }
    }
}

// MARK: - Conditions

struct TriggerCondition: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var field: TriggerConditionField
    var op: String // "equals", "notEquals", "contains"
    var value: String

    func matches(_ task: TaskItem) -> Bool {
        switch field {
        case .priority:
            return op == "equals" ? task.priority.rawValue == value : task.priority.rawValue != value
        case .list:
            return op == "equals" ? task.list?.name == value : task.list?.name != value
        case .tag:
            let names = task.tags.map(\.name)
            return op == "equals" ? names.contains(value) : !names.contains(value)
        case .title:
            return task.title.localizedCaseInsensitiveContains(value)
        case .any:
            return true
        }
    }
}

enum TriggerConditionField: String, Codable, CaseIterable {
    case any
    case priority
    case list
    case tag
    case title

    var label: String {
        switch self {
        case .any: return "Any Task"
        case .priority: return "Priority"
        case .list: return "List"
        case .tag: return "Tag"
        case .title: return "Title Contains"
        }
    }
}

// MARK: - Actions

struct TriggerAction: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var actionType: TriggerActionType
    var value: String // depends on action type

    var displayLabel: String {
        switch actionType {
        case .notify: return "Send notification: \(value)"
        case .createTask: return "Create task: \(value)"
        case .moveToList: return "Move to list: \(value)"
        case .changePriority: return "Set priority: \(value)"
        case .addTag: return "Add tag: \(value)"
        case .startTimer: return "Start focus timer"
        case .setStatus: return "Set status: \(value)"
        }
    }
}

enum TriggerActionType: String, Codable, CaseIterable {
    case notify
    case createTask
    case moveToList
    case changePriority
    case addTag
    case startTimer
    case setStatus

    var label: String {
        switch self {
        case .notify: return "Send Notification"
        case .createTask: return "Create Task"
        case .moveToList: return "Move to List"
        case .changePriority: return "Change Priority"
        case .addTag: return "Add Tag"
        case .startTimer: return "Start Focus Timer"
        case .setStatus: return "Set Status"
        }
    }

    var icon: String {
        switch self {
        case .notify: return "bell"
        case .createTask: return "plus.circle"
        case .moveToList: return "tray.and.arrow.right"
        case .changePriority: return "flag"
        case .addTag: return "tag"
        case .startTimer: return "timer"
        case .setStatus: return "checkmark.circle"
        }
    }
}
