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

                if task.dueDate != nil || !task.tags.isEmpty || task.timePreference != .anytime || task.priority == .high || task.priority == .medium {
                    HStack(spacing: 6) {
                        // Priority badge
                        if task.priority == .high || task.priority == .medium {
                            Text(task.priority == .high ? "High" : "Medium")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.priorityColor(task.priority).opacity(0.15))
                                .foregroundStyle(Color.priorityColor(task.priority))
                                .clipShape(Capsule())
                        }
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

            // Child task progress
            if !task.childTasks.isEmpty {
                let progress = task.childTaskProgress
                miniProgressBadge(
                    done: progress.done,
                    total: progress.total,
                    icon: "rectangle.on.rectangle.angled",
                    color: .blue
                )
            }

            // Subtask progress
            if !task.subtasks.isEmpty {
                let done = task.subtasks.filter(\.isCompleted).count
                miniProgressBadge(
                    done: done,
                    total: task.subtasks.count,
                    icon: "checklist",
                    color: .green
                )
            }

            // Attachment count
            if !task.attachments.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 9))
                    Text("\(task.attachments.count)")
                        .font(.system(size: 10, weight: .medium))
                }
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

    private func miniProgressBadge(done: Int, total: Int, icon: String, color: Color) -> some View {
        let fraction = total > 0 ? Double(done) / Double(total) : 0

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text("\(done)/\(total)")
                .font(.system(size: 10, weight: .medium))
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 3)
                    Capsule()
                        .fill(done == total ? .green : color)
                        .frame(width: max(0, geo.size.width * fraction), height: 3)
                }
            }
            .frame(width: 24, height: 3)
        }
        .foregroundStyle(done == total ? .green : .secondary)
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
        let dayLabel: String

        if calendar.isDateInToday(date) {
            dayLabel = "Today"
        } else if calendar.isDateInTomorrow(date) {
            dayLabel = "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            dayLabel = "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            dayLabel = formatter.string(from: date)
        }

        // If a specific time is set, append it
        if let dueTime = task.dueTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "\(dayLabel), \(formatter.string(from: dueTime))"
        }

        return dayLabel
    }
}
