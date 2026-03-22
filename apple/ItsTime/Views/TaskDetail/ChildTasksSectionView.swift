import SwiftUI
import SwiftData

struct ChildTasksSectionView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @State private var newChildTitle = ""

    private var sortedChildren: [TaskItem] {
        task.childTasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        Section {
            // Progress header
            if !task.childTasks.isEmpty {
                let progress = task.childTaskProgress
                HStack {
                    Text("Child Tasks")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(progress.done)/\(progress.total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("child_tasks_header")
            }

            // Child task rows
            ForEach(sortedChildren) { child in
                NavigationLink(value: child) {
                    childRow(child)
                }
            }
            .onDelete { offsets in
                let sorted = sortedChildren
                for index in offsets {
                    let child = sorted[index]
                    child.parentTask = nil // orphan, don't delete
                    child.updatedAt = Date()
                }
            }

            // Inline add
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
                TextField("Add child task", text: $newChildTitle)
                    .accessibilityIdentifier("add_child_task_field")
                    .onSubmit {
                        addChildTask()
                    }
            }
        } header: {
            if task.childTasks.isEmpty {
                Text("Child Tasks")
            }
        }
        .accessibilityIdentifier("child_tasks_section")
    }

    private func childRow(_ child: TaskItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: child.status == .done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(child.status == .done ? .green : .secondary)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(child.title)
                    .lineLimit(1)
                    .strikethrough(child.status == .done)
                    .foregroundStyle(child.status == .done ? .secondary : .primary)

                HStack(spacing: 6) {
                    if let due = child.dueDate {
                        Label {
                            Text(due, format: .dateTime.month(.abbreviated).day())
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption2)
                        .foregroundStyle(!Calendar.current.isDateInToday(due) && due < Date() && child.status == .todo ? .red : .secondary)
                    }
                    if child.priority != .none {
                        Circle()
                            .fill(Color.priorityColor(child.priority))
                            .frame(width: 6, height: 6)
                    }
                    if !child.childTasks.isEmpty {
                        Label("\(child.childTaskProgress.done)/\(child.childTaskProgress.total)", systemImage: "rectangle.on.rectangle.angled")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
    }

    private func addChildTask() {
        let trimmed = newChildTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let child = TaskItem(
            title: trimmed,
            list: task.list,
            sortOrder: task.childTasks.count
        )
        child.parentTask = task
        modelContext.insert(child)
        task.updatedAt = Date()
        newChildTitle = ""
    }
}
