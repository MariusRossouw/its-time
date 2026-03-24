import SwiftUI
import SwiftData

struct SuggestedTasksView: View {
    @Binding var selectedTask: TaskItem?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    private let calendar = Calendar.current

    private var overdueTasks: [TaskItem] {
        let now = Date()
        return allTasks.filter { task in
            guard task.status == .todo, !task.isNote, let due = task.dueDate else { return false }
            return due < now
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var upcomingTasks: [TaskItem] {
        let now = Date()
        let threeDays = calendar.date(byAdding: .day, value: 3, to: now)!
        return allTasks.filter { task in
            guard task.status == .todo, !task.isNote, let due = task.dueDate else { return false }
            return due >= now && due <= threeDays
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var highPriorityNoDue: [TaskItem] {
        allTasks.filter { task in
            task.status == .todo && !task.isNote && task.dueDate == nil &&
            (task.priority == .high || task.priority == .medium)
        }
    }

    private var staleTasksDays: Int { 14 }

    private var staleTasks: [TaskItem] {
        let cutoff = calendar.date(byAdding: .day, value: -staleTasksDays, to: Date())!
        return allTasks.filter { task in
            task.status == .todo && !task.isNote && task.updatedAt < cutoff
        }
        .sorted { $0.updatedAt < $1.updatedAt }
        .prefix(10)
        .map { $0 }
    }

    var body: some View {
        List {
            if overdueTasks.isEmpty && upcomingTasks.isEmpty && highPriorityNoDue.isEmpty && staleTasks.isEmpty {
                ContentUnavailableView(
                    "All Caught Up",
                    systemImage: "sparkles",
                    description: Text("No overdue, upcoming, or stale tasks to review.")
                )
                .listRowSeparator(.hidden)
            }

            if !overdueTasks.isEmpty {
                taskSection(
                    title: "Overdue",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    tasks: overdueTasks
                )
            }

            if !upcomingTasks.isEmpty {
                taskSection(
                    title: "Due Soon",
                    icon: "clock.fill",
                    color: .orange,
                    tasks: upcomingTasks
                )
            }

            if !highPriorityNoDue.isEmpty {
                taskSection(
                    title: "High Priority (No Date)",
                    icon: "flag.fill",
                    color: .purple,
                    tasks: highPriorityNoDue
                )
            }

            if !staleTasks.isEmpty {
                taskSection(
                    title: "Stale (Not Updated in \(staleTasksDays)+ Days)",
                    icon: "hourglass",
                    color: .gray,
                    tasks: staleTasks
                )
            }
        }
        .listStyle(.plain)
        .navigationTitle("Suggested")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private func taskSection(title: String, icon: String, color: Color, tasks: [TaskItem]) -> some View {
        Section {
            ForEach(tasks) { task in
                NavigationLink {
                    if task.isNote { NoteEditorView(note: task) } else { TaskDetailView(task: task) }
                } label: {
                    TaskRowView(task: task)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button { task.markDone() } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { modelContext.delete(task) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button { task.markWontDo() } label: {
                        Label("Won't Do", systemImage: "xmark")
                    }
                    .tint(.orange)
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                Text("(\(tasks.count))")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
