import SwiftUI
import SwiftData

struct KanbanBoardView: View {
    @Binding var selectedTask: TaskItem?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]

    private var todoTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo && !$0.isNote }
    }

    private var doneTasks: [TaskItem] {
        allTasks.filter { $0.status == .done && !$0.isNote }
    }

    private var wontDoTasks: [TaskItem] {
        allTasks.filter { $0.status == .wontDo && !$0.isNote }
    }

    var body: some View {
        GeometryReader { geo in
        let columnWidth = min(280, max(200, (geo.size.width - 48) / 2.5))
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 10) {
                kanbanColumn(
                    title: "To Do",
                    icon: "circle",
                    color: .blue,
                    tasks: todoTasks,
                    width: columnWidth
                )
                kanbanColumn(
                    title: "Done",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    tasks: doneTasks,
                    width: columnWidth
                )
                kanbanColumn(
                    title: "Won't Do",
                    icon: "xmark.circle.fill",
                    color: .orange,
                    tasks: wontDoTasks,
                    width: columnWidth
                )
            }
            .padding()
        }
        }
        .navigationTitle("Kanban Board")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func kanbanColumn(title: String, icon: String, color: Color, tasks: [TaskItem], width: CGFloat = 280) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Text("\(tasks.count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)

            // Cards
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        NavigationLink {
                            if task.isNote {
                                NoteEditorView(note: task)
                            } else {
                                TaskDetailView(task: task)
                            }
                        } label: {
                            KanbanCardView(task: task)
                        }
                        .buttonStyle(.plain)
                        .draggable(task.id.uuidString)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(minHeight: 200)
            .dropDestination(for: String.self) { items, _ in
                guard let uuidString = items.first,
                      let taskId = UUID(uuidString: uuidString),
                      let task = allTasks.first(where: { $0.id == taskId }) else { return false }

                withAnimation {
                    switch title {
                    case "To Do":
                        task.reopen()
                    case "Done":
                        task.markDone()
                    case "Won't Do":
                        task.markWontDo()
                    default:
                        break
                    }
                }
                return true
            } isTargeted: { targeted in
                // Could add visual feedback here
            }
        }
        .frame(width: width)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Kanban Card

struct KanbanCardView: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.priorityColor(task.priority))
                    .frame(width: 8, height: 8)
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if let due = task.dueDate {
                    Label {
                        Text(due, format: .dateTime.month(.abbreviated).day())
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(!Calendar.current.isDateInToday(due) && due < Date() && task.status == .todo ? .red : .secondary)
                }

                if !task.childTasks.isEmpty {
                    let progress = task.childTaskProgress
                    Label("\(progress.done)/\(progress.total)", systemImage: "rectangle.on.rectangle.angled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !task.subtasks.isEmpty {
                    let done = task.subtasks.filter(\.isCompleted).count
                    Label("\(done)/\(task.subtasks.count)", systemImage: "checklist")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let list = task.list, !list.isInbox {
                    Text(list.name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: list.color).opacity(0.1))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            if !task.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(task.tags.prefix(3)) { tag in
                        Text(tag.name)
                            .font(.system(size: 9))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color(hex: tag.color).opacity(0.15))
                            .foregroundStyle(Color(hex: tag.color))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }
}
