import SwiftUI

struct TaskRowView: View {
    @Bindable var task: TaskItem

    var body: some View {
        HStack(spacing: 12) {
            if task.isNote {
                // Note icon
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            } else {
                // Priority-colored checkbox
                Button {
                    toggleStatus()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.priorityColor(task.priority), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if task.status == .done {
                            Circle()
                                .fill(Color.priorityColor(task.priority))
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else if task.status == .wontDo {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 24, height: 24)
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Title + metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.status != .todo)
                    .foregroundStyle(task.status != .todo ? .secondary : .primary)
                    .lineLimit(2)

                if task.dueDate != nil || !task.tags.isEmpty || task.timePreference != .anytime {
                    HStack(spacing: 8) {
                        if task.timePreference != .anytime {
                            HStack(spacing: 3) {
                                Image(systemName: task.timePreference.icon)
                                    .font(.system(size: 10))
                                Text(task.timePreference.label)
                            }
                            .font(.caption)
                            .foregroundStyle(task.timePreference == .daytime ? .orange : .indigo)
                        }
                        if let dueDate = task.dueDate {
                            dueDateChip(dueDate)
                        }
                        ForEach(task.tags.prefix(3)) { tag in
                            Text(tag.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: tag.color).opacity(0.15))
                                .foregroundStyle(Color(hex: tag.color))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            // Assignee avatar
            if let assigneeName = task.assignedToName {
                let parts = assigneeName.split(separator: " ")
                let initials: String = {
                    if parts.count >= 2 {
                        return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
                    } else if let first = parts.first {
                        return String(first.prefix(2)).uppercased()
                    }
                    return "?"
                }()
                ZStack {
                    Circle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 22, height: 22)
                    Text(initials)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            // Child task count
            if !task.childTasks.isEmpty {
                let progress = task.childTaskProgress
                HStack(spacing: 2) {
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .font(.system(size: 10))
                    Text("\(progress.done)/\(progress.total)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Subtask count
            if !task.subtasks.isEmpty {
                let done = task.subtasks.filter(\.isCompleted).count
                Text("\(done)/\(task.subtasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Parent indicator
            if task.isChildTask {
                Image(systemName: "arrow.turn.up.left")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityIdentifier("task_row_\(task.title)")
    }

    private func toggleStatus() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if task.status == .todo {
                task.markDone()
            } else {
                task.reopen()
            }
        }
    }

    private func dueDateChip(_ date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isOverdue = !isToday && date < Date() && task.status == .todo

        return HStack(spacing: 3) {
            Image(systemName: "calendar")
                .font(.system(size: 10))
            Text(formattedDate(date))
        }
        .font(.caption)
        .foregroundStyle(isOverdue ? .red : isToday ? .blue : .secondary)
    }

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
