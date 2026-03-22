import Foundation
import SwiftData

@Model
final class CustomFilter {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    // Filter rules stored as JSON-encoded array
    var rulesData: Data?
    var matchAll: Bool // true = AND, false = OR

    init(
        name: String,
        icon: String = "line.3.horizontal.decrease.circle",
        color: String = "#007AFF",
        matchAll: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.matchAll = matchAll
        self.sortOrder = sortOrder
        self.rulesData = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var rules: [FilterRule] {
        get {
            guard let data = rulesData else { return [] }
            return (try? JSONDecoder().decode([FilterRule].self, from: data)) ?? []
        }
        set {
            rulesData = try? JSONEncoder().encode(newValue)
        }
    }

    func matches(_ task: TaskItem) -> Bool {
        let results = rules.map { $0.matches(task) }
        if results.isEmpty { return true }
        return matchAll ? results.allSatisfy { $0 } : results.contains { $0 }
    }
}

// MARK: - Filter Rules

struct FilterRule: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var field: FilterField
    var op: FilterOp
    var value: String

    func matches(_ task: TaskItem) -> Bool {
        switch field {
        case .priority:
            let taskVal = task.priority.rawValue
            switch op {
            case .equals: return taskVal == value
            case .notEquals: return taskVal != value
            default: return false
            }
        case .status:
            let taskVal = task.status.rawValue
            switch op {
            case .equals: return taskVal == value
            case .notEquals: return taskVal != value
            default: return false
            }
        case .dueDate:
            return matchesDate(task.dueDate)
        case .tag:
            let tagNames = task.tags.map(\.name)
            switch op {
            case .equals: return tagNames.contains(value)
            case .notEquals: return !tagNames.contains(value)
            default: return false
            }
        case .list:
            switch op {
            case .equals: return task.list?.name == value
            case .notEquals: return task.list?.name != value
            default: return false
            }
        case .title:
            switch op {
            case .contains: return task.title.localizedCaseInsensitiveContains(value)
            case .notEquals: return !task.title.localizedCaseInsensitiveContains(value)
            default: return false
            }
        case .isNote:
            return task.isNote == (value == "true")
        case .timePreference:
            return task.timePreference.rawValue == value
        case .isRecurring:
            return task.isRecurring == (value == "true")
        }
    }

    private func matchesDate(_ date: Date?) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch op {
        case .equals:
            // "today", "tomorrow", "thisWeek"
            guard let date else { return false }
            switch value {
            case "today": return calendar.isDateInToday(date)
            case "tomorrow": return calendar.isDateInTomorrow(date)
            case "thisWeek":
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: now)!
                return date >= calendar.startOfDay(for: now) && date <= weekEnd
            case "overdue": return date < now
            case "none": return false
            default: return false
            }
        case .notEquals:
            if value == "none" { return date != nil }
            return true
        case .before:
            guard let date else { return false }
            if value == "today" { return date < calendar.startOfDay(for: now) }
            return false
        case .after:
            guard let date else { return false }
            if value == "today" { return date > calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!) }
            return false
        case .contains:
            return false
        }
    }
}

enum FilterField: String, Codable, CaseIterable {
    case priority
    case status
    case dueDate
    case tag
    case list
    case title
    case isNote
    case timePreference
    case isRecurring

    var label: String {
        switch self {
        case .priority: return "Priority"
        case .status: return "Status"
        case .dueDate: return "Due Date"
        case .tag: return "Tag"
        case .list: return "List"
        case .title: return "Title"
        case .isNote: return "Is Note"
        case .timePreference: return "Time Preference"
        case .isRecurring: return "Is Recurring"
        }
    }
}

enum FilterOp: String, Codable, CaseIterable {
    case equals
    case notEquals
    case contains
    case before
    case after

    var label: String {
        switch self {
        case .equals: return "is"
        case .notEquals: return "is not"
        case .contains: return "contains"
        case .before: return "before"
        case .after: return "after"
        }
    }
}
