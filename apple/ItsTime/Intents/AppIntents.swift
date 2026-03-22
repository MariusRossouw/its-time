import AppIntents
import SwiftData

// MARK: - Create Task Intent

struct CreateTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Task"
    static let description = IntentDescription("Create a new task in Its Time")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Priority", default: .none)
    var priority: IntentPriority

    @Parameter(title: "Due Date", default: nil)
    var dueDate: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("Create task \(\.$title)") {
            \.$priority
            \.$dueDate
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: TaskItem.self)
        let context = ModelContext(container)

        let taskPriority: TaskPriority
        switch priority {
        case .none: taskPriority = .none
        case .low: taskPriority = .low
        case .medium: taskPriority = .medium
        case .high: taskPriority = .high
        }

        let task = TaskItem(
            title: title,
            priority: taskPriority,
            dueDate: dueDate
        )
        context.insert(task)
        try context.save()

        return .result(dialog: "Created task: \(title)")
    }
}

// MARK: - Complete Task Intent

struct CompleteTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Task"
    static let description = IntentDescription("Mark a task as done")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Task Name")
    var taskName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$taskName)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: TaskItem.self)
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<TaskItem>()
        let tasks = try context.fetch(descriptor)

        if let task = tasks.first(where: {
            $0.title.localizedCaseInsensitiveContains(taskName) && $0.status == .todo
        }) {
            task.markDone()
            try context.save()
            return .result(dialog: "Marked '\(task.title)' as done")
        } else {
            return .result(dialog: "Couldn't find a task matching '\(taskName)'")
        }
    }
}

// MARK: - Today Summary Intent

struct TodaySummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Tasks"
    static let description = IntentDescription("Get a summary of today's tasks")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: TaskItem.self)
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<TaskItem>()
        let tasks = try context.fetch(descriptor)

        let calendar = Calendar.current
        let todayTasks = tasks.filter { task in
            guard task.status == .todo, let due = task.dueDate else { return false }
            return calendar.isDateInToday(due)
        }

        if todayTasks.isEmpty {
            return .result(dialog: "You have no tasks due today. Enjoy your free time!")
        }

        let names = todayTasks.prefix(5).map(\.title).joined(separator: ", ")
        let count = todayTasks.count
        let summary = count <= 5
            ? "You have \(count) task\(count == 1 ? "" : "s") today: \(names)"
            : "You have \(count) tasks today. Top ones: \(names)"

        return .result(dialog: "\(summary)")
    }
}

// MARK: - Check Habit Intent

struct CheckHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Check In Habit"
    static let description = IntentDescription("Check in for a habit")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Habit Name")
    var habitName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Check in \(\.$habitName)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Habit.self, HabitEntry.self)
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Habit>()
        let habits = try context.fetch(descriptor)

        if let habit = habits.first(where: {
            $0.name.localizedCaseInsensitiveContains(habitName) && !$0.isArchived
        }) {
            if habit.isCompletedOn(Date()) {
                return .result(dialog: "'\(habit.name)' is already done for today!")
            }
            let entry = HabitEntry(date: Date(), value: 1)
            entry.habit = habit
            habit.entries.append(entry)
            context.insert(entry)
            try context.save()

            let streak = habit.currentStreak
            return .result(dialog: "Checked in '\(habit.name)'. \(streak > 1 ? "Streak: \(streak) days!" : "Keep it up!")")
        } else {
            return .result(dialog: "Couldn't find a habit matching '\(habitName)'")
        }
    }
}

// MARK: - Priority Enum for Intents

enum IntentPriority: String, AppEnum {
    case none
    case low
    case medium
    case high

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Priority")
    static let caseDisplayRepresentations: [IntentPriority: DisplayRepresentation] = [
        .none: "None",
        .low: "Low",
        .medium: "Medium",
        .high: "High"
    ]
}

// MARK: - Shortcuts Provider

struct ItsTimeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "Create a task in \(.applicationName)",
                "Add a task to \(.applicationName)",
                "New task in \(.applicationName)"
            ],
            shortTitle: "Create Task",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: TodaySummaryIntent(),
            phrases: [
                "What's on my list in \(.applicationName)",
                "Today's tasks in \(.applicationName)",
                "What do I need to do in \(.applicationName)"
            ],
            shortTitle: "Today's Tasks",
            systemImageName: "sun.max"
        )
        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Complete a task in \(.applicationName)",
                "Mark task done in \(.applicationName)"
            ],
            shortTitle: "Complete Task",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: CheckHabitIntent(),
            phrases: [
                "Check in habit in \(.applicationName)",
                "Log habit in \(.applicationName)"
            ],
            shortTitle: "Check In Habit",
            systemImageName: "leaf"
        )
    }
}
