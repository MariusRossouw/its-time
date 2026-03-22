import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Today Widget

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), taskCount: 3, completedCount: 1, topTasks: ["Sample task 1", "Sample task 2"])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> TodayEntry {
        let calendar = Calendar.current
        let now = Date()

        do {
            let container = try ModelContainer(for: TaskItem.self)
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<TaskItem>()
            let tasks = try context.fetch(descriptor)

            let todayTasks = tasks.filter { task in
                guard let due = task.dueDate else { return false }
                return calendar.isDate(due, inSameDayAs: now)
            }

            let todo = todayTasks.filter { $0.status == .todo }
            let done = todayTasks.filter { $0.status == .done }
            let topNames = todo.prefix(4).map(\.title)

            return TodayEntry(
                date: now,
                taskCount: todo.count,
                completedCount: done.count,
                topTasks: Array(topNames)
            )
        } catch {
            return TodayEntry(date: now, taskCount: 0, completedCount: 0, topTasks: [])
        }
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let taskCount: Int
    let completedCount: Int
    let topTasks: [String]
}

struct TodayWidgetView: View {
    var entry: TodayEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Today")
                    .font(.headline)
            }

            Spacer()

            if entry.taskCount == 0 {
                Text("All clear!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(entry.taskCount)")
                    .font(.system(size: 36, weight: .bold))
                Text("tasks remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.completedCount > 0 {
                Text("\(entry.completedCount) done")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.orange)
                    Text("Today")
                        .font(.headline)
                }

                HStack(spacing: 16) {
                    VStack {
                        Text("\(entry.taskCount)")
                            .font(.title.bold())
                        Text("to do")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(entry.completedCount)")
                            .font(.title.bold())
                            .foregroundStyle(.green)
                        Text("done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Task list
            VStack(alignment: .leading, spacing: 4) {
                if entry.topTasks.isEmpty {
                    Text("No tasks today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.topTasks, id: \.self) { taskName in
                        HStack(spacing: 4) {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                            Text(taskName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
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
        .supportedFamilies([.systemSmall, .systemMedium])
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
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitStreakEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> HabitStreakEntry {
        do {
            let container = try ModelContainer(for: Habit.self, HabitEntry.self)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Habits")
                    .font(.headline)
                Spacer()
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
