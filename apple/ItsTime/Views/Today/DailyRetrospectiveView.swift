import SwiftUI
import SwiftData

struct DailyRetrospectiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]

    private var completedToday: [TaskItem] {
        allTasks.filter { task in
            guard task.status != .todo, let completed = task.completedAt else { return false }
            return Calendar.current.isDateInToday(completed)
        }
    }

    private var attemptedNotFinished: [TaskItem] {
        allTasks.filter { task in
            guard task.status == .todo, let due = task.dueDate else { return false }
            return Calendar.current.isDateInToday(due)
        }
    }

    private var inboxTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo && $0.dueDate == nil && $0.list?.isInbox == true }
    }

    private var subtasksCompletedToday: Int {
        completedToday.reduce(0) { $0 + $1.subtasks.filter(\.isCompleted).count }
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary stats
                Section {
                    HStack(spacing: 16) {
                        statBadge(value: "\(completedToday.count)", label: "Completed", color: .green)
                        statBadge(value: "\(attemptedNotFinished.count)", label: "Remaining", color: .orange)
                        statBadge(value: "\(subtasksCompletedToday)", label: "Subtasks", color: .blue)
                    }
                    .listRowBackground(Color.clear)
                }
                .accessibilityIdentifier("retro_stats")

                // Completed today
                if !completedToday.isEmpty {
                    Section("Completed (\(completedToday.count))") {
                        ForEach(completedToday) { task in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                    if !task.subtasks.isEmpty {
                                        let done = task.subtasks.filter(\.isCompleted).count
                                        Text("\(done)/\(task.subtasks.count) subtasks")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // Attempted but not finished
                if !attemptedNotFinished.isEmpty {
                    Section("Not Finished (\(attemptedNotFinished.count))") {
                        ForEach(attemptedNotFinished) { task in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(.orange)
                                Text(task.title)
                                Spacer()
                                Menu {
                                    Button("Move to Tomorrow") {
                                        task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                                        task.updatedAt = Date()
                                    }
                                    Button("Back to Inbox") {
                                        task.dueDate = nil
                                        task.updatedAt = Date()
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Still in inbox
                if !inboxTasks.isEmpty {
                    Section("Inbox (\(inboxTasks.count))") {
                        ForEach(inboxTasks.prefix(10)) { task in
                            HStack {
                                Image(systemName: "tray")
                                    .foregroundStyle(.secondary)
                                Text(task.title)
                            }
                        }
                        if inboxTasks.count > 10 {
                            Text("and \(inboxTasks.count - 10) more...")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // Empty state
                if completedToday.isEmpty && attemptedNotFinished.isEmpty && inboxTasks.isEmpty {
                    ContentUnavailableView {
                        Label("No Activity", systemImage: "tray")
                    } description: {
                        Text("No tasks to review today.")
                    }
                }
            }
            .navigationTitle("Daily Review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("retro_done")
                }
            }
            .accessibilityIdentifier("daily_retrospective_view")
        }
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
