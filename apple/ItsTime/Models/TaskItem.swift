import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var taskDescription: String
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    var dueTime: Date?
    var startDate: Date?
    var completedAt: Date?
    var sortOrder: Int
    var reminderOffsets: [Int] // seconds before dueDate
    var nudgeDate: Date? // independent absolute-time reminder
    var createdAt: Date
    var updatedAt: Date
    var deviceId: String

    // Note mode
    var isNote: Bool

    // Assignment
    var assignedTo: UUID? // collaborator id
    var assignedToName: String?

    // Location-based reminder
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationRadius: Double // meters, default 200
    var locationName: String?
    var locationDirectionRaw: String? // "arrive" or "leave"

    var locationDirection: LocationReminderDirection {
        get { LocationReminderDirection(rawValue: locationDirectionRaw ?? "arrive") ?? .arrive }
        set { locationDirectionRaw = newValue.rawValue }
    }

    var hasLocationReminder: Bool {
        locationLatitude != nil && locationLongitude != nil
    }

    // Time preference
    var timePreference: TimePreference

    // Recurrence
    var recurrenceType: RecurrenceType
    var recurrenceInterval: Int // every N units
    var recurrenceWeekdays: [Int] // for weekly: 1=Sun..7=Sat
    var recurrenceBasedOnCompletion: Bool // next due = completion + interval
    var recurrenceEndDate: Date?

    // Relationships
    var list: TaskList?
    var section: ListSection?
    @Relationship(deleteRule: .cascade)
    var subtasks: [Subtask]
    var tags: [Tag]
    @Relationship(deleteRule: .cascade)
    var focusSessions: [FocusSession]
    @Relationship(deleteRule: .cascade, inverse: \ActivityEntry.task)
    var activityLog: [ActivityEntry]

    // Parent-child hierarchy
    var parentTask: TaskItem?
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.parentTask)
    var childTasks: [TaskItem]

    // Linked habits (habits that are children of this task)
    @Relationship(deleteRule: .nullify, inverse: \Habit.parentTask)
    var childHabits: [Habit]

    // Attachments
    @Relationship(deleteRule: .cascade, inverse: \TaskAttachment.task)
    var attachments: [TaskAttachment]

    // Progress (0–100, nil = auto-calculate from subtasks)
    var manualProgress: Int?

    init(
        title: String,
        taskDescription: String = "",
        status: TaskStatus = .todo,
        priority: TaskPriority = .none,
        dueDate: Date? = nil,
        dueTime: Date? = nil,
        startDate: Date? = nil,
        list: TaskList? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.startDate = startDate
        self.completedAt = nil
        self.list = list
        self.subtasks = []
        self.tags = []
        self.focusSessions = []
        self.activityLog = []
        self.assignedTo = nil
        self.assignedToName = nil
        self.locationLatitude = nil
        self.locationLongitude = nil
        self.locationRadius = 200.0
        self.locationName = nil
        self.locationDirectionRaw = nil
        self.sortOrder = sortOrder
        self.reminderOffsets = []
        self.nudgeDate = nil
        self.isNote = false
        self.timePreference = .anytime
        self.recurrenceType = .none
        self.recurrenceInterval = 1
        self.recurrenceWeekdays = []
        self.recurrenceBasedOnCompletion = false
        self.recurrenceEndDate = nil
        self.parentTask = nil
        self.childTasks = []
        self.childHabits = []
        self.attachments = []
        self.manualProgress = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deviceId = DeviceInfo.deviceId
    }

    var isRecurring: Bool {
        recurrenceType != .none
    }

    // MARK: - Hierarchy helpers

    var isChildTask: Bool { parentTask != nil }
    var isParentTask: Bool { !childTasks.isEmpty }

    var childTaskProgress: (done: Int, total: Int) {
        (childTasks.filter { $0.status == .done }.count, childTasks.count)
    }

    /// Progress 0–100. Uses manual override if set, otherwise auto-calculates from subtasks.
    var progress: Int {
        if let manual = manualProgress { return manual }
        guard !subtasks.isEmpty else { return 0 }
        let done = subtasks.filter(\.isCompleted).count
        return Int(Double(done) / Double(subtasks.count) * 100)
    }

    /// Duplicate this task (with subtasks), inserted into the same list.
    func duplicate(context: ModelContext) -> TaskItem {
        let copy = TaskItem(
            title: "\(title) (copy)",
            taskDescription: taskDescription,
            priority: priority,
            dueDate: dueDate,
            dueTime: dueTime,
            startDate: startDate,
            list: list,
            sortOrder: sortOrder + 1
        )
        copy.timePreference = timePreference
        copy.recurrenceType = recurrenceType
        copy.recurrenceInterval = recurrenceInterval
        copy.recurrenceWeekdays = recurrenceWeekdays
        copy.recurrenceBasedOnCompletion = recurrenceBasedOnCompletion
        copy.recurrenceEndDate = recurrenceEndDate
        copy.reminderOffsets = reminderOffsets
        copy.isNote = isNote
        copy.tags = tags
        copy.section = section
        copy.parentTask = parentTask
        context.insert(copy)

        // Duplicate subtasks
        for sub in subtasks.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let subCopy = Subtask(title: sub.title, sortOrder: sub.sortOrder)
            copy.subtasks.append(subCopy)
            context.insert(subCopy)
        }
        return copy
    }

    /// All ancestor IDs for cycle prevention
    var ancestorIds: Set<UUID> {
        var ids = Set<UUID>()
        var current = parentTask
        while let p = current { ids.insert(p.id); current = p.parentTask }
        return ids
    }

    /// All descendant IDs for cycle prevention
    func descendantIds() -> Set<UUID> {
        var ids = Set<UUID>()
        for child in childTasks {
            ids.insert(child.id)
            ids.formUnion(child.descendantIds())
        }
        return ids
    }

    /// Recursively assign a list to all descendants
    func assignListToDescendants(_ newList: TaskList?) {
        for child in childTasks {
            child.list = newList
            child.section = nil
            child.updatedAt = Date()
            child.assignListToDescendants(newList)
        }
    }

    func markDone() {
        status = .done
        completedAt = Date()
        updatedAt = Date()
    }

    func markWontDo() {
        status = .wontDo
        completedAt = Date()
        updatedAt = Date()
    }

    func reopen() {
        status = .todo
        completedAt = nil
        updatedAt = Date()
    }

    func convertToNote() {
        isNote = true
        status = .todo
        completedAt = nil
        dueDate = nil
        dueTime = nil
        startDate = nil
        reminderOffsets = []
        recurrenceType = .none
        updatedAt = Date()
    }

    func convertToTask() {
        isNote = false
        updatedAt = Date()
    }

    // MARK: - Activity Logging

    func logActivity(
        action: ActivityAction,
        field: String? = nil,
        oldValue: String? = nil,
        newValue: String? = nil,
        context: ModelContext
    ) {
        let descriptor = FetchDescriptor<Collaborator>(predicate: #Predicate { $0.isCurrentUser })
        let currentUser = try? context.fetch(descriptor).first

        let entry = ActivityEntry(
            action: action,
            field: field,
            oldValue: oldValue,
            newValue: newValue,
            authorName: currentUser?.name ?? "You",
            authorId: currentUser?.id ?? UUID(),
            task: self
        )
        self.activityLog.append(entry)
        context.insert(entry)
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo
    case done
    case wontDo
}

enum TaskPriority: String, Codable, CaseIterable, Comparable {
    case none
    case low
    case medium
    case high

    var sortValue: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        case .none: return 0
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.sortValue < rhs.sortValue
    }
}

enum TimePreference: String, Codable, CaseIterable {
    case anytime
    case daytime
    case nighttime

    var label: String {
        switch self {
        case .anytime: return "Anytime"
        case .daytime: return "Daytime"
        case .nighttime: return "Nighttime"
        }
    }

    var icon: String {
        switch self {
        case .anytime: return "clock"
        case .daytime: return "sun.max.fill"
        case .nighttime: return "moon.fill"
        }
    }
}

enum LocationReminderDirection: String, Codable, CaseIterable {
    case arrive
    case leave

    var label: String {
        switch self {
        case .arrive: return "When I arrive"
        case .leave: return "When I leave"
        }
    }

    var icon: String {
        switch self {
        case .arrive: return "arrow.down.to.line"
        case .leave: return "arrow.up.from.line"
        }
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case monthly
    case yearly
    case custom

    var label: String {
        switch self {
        case .none: return "None"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}
