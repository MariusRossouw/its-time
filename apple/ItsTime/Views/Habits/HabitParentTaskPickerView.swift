import SwiftUI
import SwiftData

struct HabitParentTaskPickerView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.title) private var allTasks: [TaskItem]
    @State private var searchText = ""

    private var eligibleTasks: [TaskItem] {
        allTasks.filter { task in
            !task.isNote &&
            task.status == .todo &&
            (searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        List {
            if habit.parentTask != nil {
                Section {
                    Button("Remove Link", role: .destructive) {
                        if let parent = habit.parentTask {
                            parent.logActivity(action: .habitUnlinked, oldValue: habit.name, context: modelContext)
                        }
                        habit.parentTask = nil
                        habit.updatedAt = Date()
                        dismiss()
                    }
                }
            }

            if eligibleTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks Found",
                    systemImage: "magnifyingglass",
                    description: Text("Create tasks to link this habit to.")
                )
            } else {
                ForEach(eligibleTasks) { task in
                    Button {
                        habit.parentTask = task
                        habit.updatedAt = Date()
                        task.updatedAt = Date()
                        task.logActivity(action: .habitLinked, newValue: habit.name, context: modelContext)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.priorityColor(task.priority))
                                .frame(width: 8, height: 8)
                            Text(task.title)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer()
                            if let list = task.list {
                                Text(list.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search tasks")
        .navigationTitle("Link to Task")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
