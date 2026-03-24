import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Task Snippet (for widget display)

struct TaskSnippet: Hashable {
    let title: String
    let dueDate: Date?
    let dueTime: Date?
    let priorityRaw: String
    let listColor: String?
    let isAllDay: Bool

    var color: Color {
        if let listColor {
            return Color(hex: listColor)
        }
        switch priorityRaw {
        case "high": return Color(hex: "#FF3B30")
        case "medium": return Color(hex: "#FF9500")
        case "low": return Color(hex: "#007AFF")
        default: return Color(hex: "#C7C7CC")
        }
    }

    var timeString: String? {
        guard let due = dueDate, !isAllDay else { return nil }
        let cal = Calendar.current
        let hour = cal.component(.hour, from: due)
        let minute = cal.component(.minute, from: due)
        if hour == 0 && minute == 0 { return nil }
        let df = DateFormatter()
        df.timeStyle = .short
        var result = df.string(from: due)
        if let end = dueTime {
            result += " – \(df.string(from: end))"
        }
        return result
    }
}

// MARK: - Today Widget

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(
            date: Date(),
            taskCount: 3,
            completedCount: 1,
            tasks: [
                TaskSnippet(title: "Team standup", dueDate: Date(), dueTime: nil, priorityRaw: "high", listColor: "#007AFF", isAllDay: false),
                TaskSnippet(title: "Review PR", dueDate: Date(), dueTime: nil, priorityRaw: "medium", listColor: "#34C759", isAllDay: false),
            ],
            weekTaskCounts: [1, 2, 0, 3, 1, 0, 0]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    static let appGroupID = "group.com.mariusrossouw.itstime"

    static let widgetSchema: Schema = {
        Schema([
            TaskItem.self, Subtask.self, TaskList.self, ListSection.self,
            Folder.self, Tag.self, FocusSession.self, Habit.self, HabitEntry.self,
            CustomFilter.self, Trigger.self, TriggerLogEntry.self,
            Collaborator.self, ActivityEntry.self, ChatMessage.self,
            SyncProfile.self, TaskAttachment.self, TaskTemplate.self
        ])
    }()

    static func makeContainer() throws -> ModelContainer {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = containerURL.appending(path: "default.store")
            let config = ModelConfiguration(url: storeURL)
            return try ModelContainer(for: widgetSchema, configurations: config)
        } else {
            return try ModelContainer(for: widgetSchema)
        }
    }

    private func fetchEntry() -> TodayEntry {
        let calendar = Calendar.current
        let now = Date()

        do {
            let container = try Self.makeContainer()
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<TaskItem>()
            let tasks = try context.fetch(descriptor)

            let todayTasks = tasks.filter { task in
                guard let due = task.dueDate else { return false }
                return calendar.isDate(due, inSameDayAs: now)
            }

            let todo = todayTasks.filter { $0.status == .todo }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            let done = todayTasks.filter { $0.status == .done }

            let snippets = todo.prefix(6).map { task in
                let hour = task.dueDate.map { calendar.component(.hour, from: $0) } ?? 0
                let minute = task.dueDate.map { calendar.component(.minute, from: $0) } ?? 0
                return TaskSnippet(
                    title: task.title,
                    dueDate: task.dueDate,
                    dueTime: task.dueTime,
                    priorityRaw: task.priority.rawValue,
                    listColor: task.list?.color,
                    isAllDay: hour == 0 && minute == 0
                )
            }

            // Week task counts
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekCounts = (0..<7).map { offset -> Int in
                guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { return 0 }
                return tasks.filter { t in
                    guard let due = t.dueDate, t.status == .todo else { return false }
                    return calendar.isDate(due, inSameDayAs: date)
                }.count
            }

            return TodayEntry(
                date: now,
                taskCount: todo.count,
                completedCount: done.count,
                tasks: Array(snippets),
                weekTaskCounts: weekCounts
            )
        } catch {
            return TodayEntry(date: now, taskCount: 0, completedCount: 0, tasks: [], weekTaskCounts: Array(repeating: 0, count: 7))
        }
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let taskCount: Int
    let completedCount: Int
    let tasks: [TaskSnippet]
    let weekTaskCounts: [Int]
}

// MARK: - Today Widget View

struct TodayWidgetView: View {
    var entry: TodayEntry
    @Environment(\.widgetFamily) var family

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private let addTaskURL = URL(string: "itstime://add-task")!
    private let addNoteURL = URL(string: "itstime://add-note")!
    private let addHabitURL = URL(string: "itstime://add-habit")!

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    // MARK: - Small View

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Date header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(dayNumber)
                        .font(.system(size: 34, weight: .bold))
                    Text(monthName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(dayOfWeek)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#007AFF"))
                }
                Spacer()

                Link(destination: addTaskURL) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "#007AFF"))
                }
            }

            Spacer(minLength: 2)

            // Top tasks
            if entry.tasks.isEmpty {
                Text("All clear!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entry.tasks.prefix(3), id: \.self) { task in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(task.color)
                                .frame(width: 6, height: 6)
                            Text(task.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }

            HStack {
                if entry.completedCount > 0 {
                    Text("\(entry.completedCount) done")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                }
                Spacer()
                if entry.taskCount > 0 {
                    Text("\(entry.taskCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color(hex: "#007AFF"))
                        .clipShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    // MARK: - Medium View

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Date header + week strip
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(dayNumber)
                        .font(.system(size: 28, weight: .bold))
                    Text("\(monthName) \(dayOfWeek)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Mini week strip
                HStack(spacing: 2) {
                    ForEach(weekDates.indices, id: \.self) { i in
                        let date = weekDates[i]
                        let isToday = calendar.isDateInToday(date)
                        let hasTasks = entry.weekTaskCounts[i] > 0

                        VStack(spacing: 1) {
                            Text(shortDay(date))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .fixedSize()
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                                .foregroundStyle(isToday ? .white : .primary)
                                .frame(width: 20, height: 20)
                                .background(isToday ? Color(hex: "#007AFF") : .clear)
                                .clipShape(Circle())
                            Circle()
                                .fill(hasTasks ? Color(hex: "#007AFF").opacity(0.6) : .clear)
                                .frame(width: 3, height: 3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Task list
            if entry.tasks.isEmpty {
                Text("No tasks today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entry.tasks.prefix(3), id: \.self) { task in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(task.color)
                                .frame(width: 3, height: 18)

                            if let time = task.timeString {
                                Text(time)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 55, alignment: .leading)
                            } else if task.isAllDay {
                                Text("All-Day")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 55, alignment: .leading)
                            }

                            Text(task.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // Quick add buttons
            HStack(spacing: 12) {
                Spacer()
                Link(destination: addTaskURL) {
                    Label("New Task", systemImage: "plus.circle.fill")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                Link(destination: addNoteURL) {
                    Label("New Note", systemImage: "doc.badge.plus")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    // MARK: - Large View

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Date header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(dayNumber)
                        .font(.system(size: 36, weight: .bold))
                    Text(monthName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Today, \(dayOfWeek)")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#007AFF"))
                }

                Spacer()

                // Mini week strip
                HStack(spacing: 4) {
                    ForEach(weekDates.indices, id: \.self) { i in
                        let date = weekDates[i]
                        let isToday = calendar.isDateInToday(date)
                        let hasTasks = entry.weekTaskCounts[i] > 0

                        VStack(spacing: 2) {
                            Text(shortDay(date))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .fixedSize()
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                                .foregroundStyle(isToday ? .white : .primary)
                                .frame(width: 24, height: 24)
                                .background(isToday ? Color(hex: "#007AFF") : .clear)
                                .clipShape(Circle())
                            Circle()
                                .fill(hasTasks ? Color(hex: "#007AFF").opacity(0.6) : .clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            Divider()

            // Full task list
            if entry.tasks.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Text("No tasks today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Enjoy your free time!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.tasks.prefix(6), id: \.self) { task in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(task.color)
                                .frame(width: 4, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                if let time = task.timeString {
                                    Text(time)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                } else if task.isAllDay {
                                    Text("All-Day")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                    }

                    if entry.taskCount > 6 {
                        Text("+\(entry.taskCount - 6) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                    }
                }

                Spacer()
            }

            // Bottom: stats + quick add
            Divider()

            HStack {
                if entry.completedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("\(entry.completedCount) done")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if entry.taskCount > 0 {
                    Text("\(entry.taskCount) remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Link(destination: addTaskURL) {
                    Label("Task", systemImage: "plus.circle.fill")
                        .font(.caption2.weight(.medium))
                }
                Link(destination: addNoteURL) {
                    Label("Note", systemImage: "doc.badge.plus")
                        .font(.caption2.weight(.medium))
                }
                Link(destination: addHabitURL) {
                    Label("Habit", systemImage: "leaf")
                        .font(.caption2.weight(.medium))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    // MARK: - Helpers

    private var dayNumber: String {
        "\(calendar.component(.day, from: entry.date))"
    }

    private var monthName: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM"
        return df.string(from: entry.date)
    }

    private var dayOfWeek: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: entry.date)
    }

    private func shortDay(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEEE" // Single-letter day abbreviation (S, M, T, W, T, F, S)
        return df.string(from: date).uppercased()
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("See your tasks for today at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Habit Streak Widget

struct HabitStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitStreakEntry {
        HabitStreakEntry(date: Date(), habits: [
            HabitSnippet(name: "Exercise", streak: 5, icon: "figure.run", color: "#FF3B30", completedToday: true),
            HabitSnippet(name: "Read", streak: 12, icon: "book.fill", color: "#FF9500", completedToday: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitStreakEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitStreakEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> HabitStreakEntry {
        do {
            let container = try TodayProvider.makeContainer()
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
            let habits = try context.fetch(descriptor).filter { !$0.isArchived }

            let snippets = habits.prefix(4).map { habit in
                HabitSnippet(
                    name: habit.name,
                    streak: habit.currentStreak,
                    icon: habit.icon,
                    color: habit.color,
                    completedToday: habit.isCompletedOn(Date())
                )
            }

            return HabitStreakEntry(date: Date(), habits: Array(snippets))
        } catch {
            return HabitStreakEntry(date: Date(), habits: [])
        }
    }
}

struct HabitSnippet: Hashable {
    let name: String
    let streak: Int
    let icon: String
    let color: String
    let completedToday: Bool
}

struct HabitStreakEntry: TimelineEntry {
    let date: Date
    let habits: [HabitSnippet]
}

struct HabitStreakWidgetView: View {
    var entry: HabitStreakEntry

    private let addHabitURL = URL(string: "itstime://add-habit")!

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Habits")
                    .font(.headline)
                Spacer()
                Link(destination: addHabitURL) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color(hex: "#007AFF"))
                }
            }

            if entry.habits.isEmpty {
                Spacer()
                Text("No habits yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.habits, id: \.self) { habit in
                    HStack(spacing: 8) {
                        Image(systemName: habit.completedToday ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundStyle(habit.completedToday ? Color(hex: habit.color) : .secondary)
                        Text(habit.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        if habit.streak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                                Text("\(habit.streak)")
                                    .font(.caption2.bold())
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct HabitStreakWidget: Widget {
    let kind: String = "HabitStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitStreakProvider()) { entry in
            HabitStreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Habit Streaks")
        .description("Track your habit streaks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct ItsTimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        HabitStreakWidget()
    }
}
