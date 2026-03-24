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
            if !task.childTasks.isEmpty || !task.childHabits.isEmpty {
                let taskProgress = task.childTaskProgress
                let habitsDone = task.childHabits.filter { $0.isCompletedOn(Date()) }.count
                let totalDone = taskProgress.done + habitsDone
                let totalCount = taskProgress.total + task.childHabits.count
                let fraction = totalCount > 0 ? Double(totalDone) / Double(totalCount) : 0
                VStack(spacing: 6) {
                    HStack {
                        Text("Children")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(Int(fraction * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(totalDone == totalCount ? .green : .secondary)
                        Text("\(totalDone)/\(totalCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 4)
                            Capsule()
                                .fill(totalDone == totalCount ? .green : .blue)
                                .frame(width: max(0, geo.size.width * fraction), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .accessibilityIdentifier("child_tasks_header")
            }

            // Child task rows
            ForEach(sortedChildren) { child in
                NavigationLink {
                    if child.isNote {
                        NoteEditorView(note: child)
                    } else {
                        TaskDetailView(task: child)
                    }
                } label: {
                    childRow(child)
                }
            }
            .onDelete { offsets in
                let sorted = sortedChildren
                for index in offsets {
                    let child = sorted[index]
                    task.logActivity(action: .childRemoved, oldValue: child.title, context: modelContext)
                    child.parentTask = nil // orphan, don't delete
                    child.updatedAt = Date()
                }
            }

            // Linked habits
            ForEach(task.childHabits.sorted(by: { $0.sortOrder < $1.sortOrder })) { habit in
                NavigationLink {
                    HabitDetailView(habit: habit)
                } label: {
                    habitRow(habit)
                }
            }
            .onDelete { offsets in
                let sorted = task.childHabits.sorted(by: { $0.sortOrder < $1.sortOrder })
                for index in offsets {
                    let habit = sorted[index]
                    task.logActivity(action: .habitUnlinked, oldValue: habit.name, context: modelContext)
                    habit.parentTask = nil
                    habit.updatedAt = Date()
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

            // Link existing task/note/habit
            NavigationLink {
                ExistingChildPickerView(task: task)
            } label: {
                Label("Link Existing Task or Note", systemImage: "link.badge.plus")
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("link_existing_button")

            NavigationLink {
                HabitPickerView(task: task)
            } label: {
                Label("Link Habit", systemImage: "leaf")
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("link_habit_button")
        } header: {
            if task.childTasks.isEmpty && task.childHabits.isEmpty {
                Text("Children")
            }
        }
        .accessibilityIdentifier("child_tasks_section")
    }

    private func habitRow(_ habit: Habit) -> some View {
        let completed = habit.isCompletedOn(Date())
        return HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.color).opacity(completed ? 1 : 0.15))
                    .frame(width: 24, height: 24)
                Image(systemName: completed ? "checkmark" : habit.icon)
                    .font(.system(size: 11, weight: completed ? .bold : .regular))
                    .foregroundStyle(completed ? .white : Color(hex: habit.color))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .lineLimit(1)
                    .strikethrough(completed)
                    .foregroundStyle(completed ? .secondary : .primary)

                HStack(spacing: 6) {
                    Text("Habit")
                        .font(.system(size: 8, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(hex: habit.color).opacity(0.15))
                        .foregroundStyle(Color(hex: habit.color))
                        .clipShape(Capsule())
                    if habit.currentStreak > 0 {
                        Label("\(habit.currentStreak)", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text(habit.frequency.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
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
                    if child.priority == .high || child.priority == .medium {
                        Text(child.priority == .high ? "High" : "Med")
                            .font(.system(size: 8, weight: .semibold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.priorityColor(child.priority).opacity(0.15))
                            .foregroundStyle(Color.priorityColor(child.priority))
                            .clipShape(Capsule())
                    } else if child.priority == .low {
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
        task.logActivity(action: .childAdded, newValue: trimmed, context: modelContext)
        newChildTitle = ""
    }
}
