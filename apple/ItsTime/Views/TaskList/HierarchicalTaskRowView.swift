import SwiftUI
import SwiftData

struct HierarchicalTaskRowView: View {
    let task: TaskItem
    let depth: Int

    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded = true

    private var activeChildren: [TaskItem] {
        task.childTasks
            .filter { $0.status == .todo }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        // Parent row — always a NavigationLink
        NavigationLink {
            taskDestination(task)
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

        // Children as indented rows underneath
        if !activeChildren.isEmpty && isExpanded {
            ForEach(activeChildren) { child in
                HierarchicalTaskRowView(task: child, depth: depth + 1)
                    .padding(.leading, 20)
            }
        }

        // Collapse/expand toggle for parents with children
        if !activeChildren.isEmpty {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                    Text(isExpanded ? "Hide \(activeChildren.count) subtasks" : "Show \(activeChildren.count) subtasks")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.leading, 34)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private func taskDestination(_ task: TaskItem) -> some View {
        if task.isNote {
            NoteEditorView(note: task)
        } else {
            TaskDetailView(task: task)
        }
    }
}
