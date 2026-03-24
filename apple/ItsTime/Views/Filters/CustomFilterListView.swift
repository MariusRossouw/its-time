import SwiftUI
import SwiftData

struct CustomFilterListView: View {
    let filter: CustomFilter
    @Binding var selectedTask: TaskItem?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]

    private var matchingTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo && filter.matches($0) }
    }

    var body: some View {
        List {
            if matchingTasks.isEmpty {
                ContentUnavailableView(
                    "No matches",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("No tasks match this filter's rules.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(matchingTasks) { task in
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
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(filter.name)
    }
}
