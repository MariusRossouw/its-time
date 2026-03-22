import SwiftUI
import SwiftData

struct AgendaCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    private let calendar = Calendar.current

    private var upcomingDays: [(date: Date, tasks: [TaskItem])] {
        let start = calendar.startOfDay(for: selectedDate)
        var result: [(date: Date, tasks: [TaskItem])] = []

        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let tasks = allTasks.filter { task in
                guard let due = task.dueDate, task.status == .todo else { return false }
                return calendar.isDate(due, inSameDayAs: date)
            }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

            if !tasks.isEmpty {
                result.append((date: date, tasks: tasks))
            }
        }
        return result
    }

    private var overdueTasks: [TaskItem] {
        let start = calendar.startOfDay(for: selectedDate)
        return allTasks.filter { task in
            guard let due = task.dueDate, task.status == .todo else { return false }
            return due < start
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Date nav
            HStack {
                Button { changeDate(-7) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text("Agenda").font(.headline)
                Spacer()
                Button { changeDate(7) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if overdueTasks.isEmpty && upcomingDays.isEmpty {
                ContentUnavailableView("No Tasks", systemImage: "checkmark.circle", description: Text("No upcoming tasks in the next 30 days."))
            } else {
                List {
                    // Overdue section
                    if !overdueTasks.isEmpty {
                        Section {
                            ForEach(overdueTasks) { task in
                                agendaRow(task: task)
                            }
                        } header: {
                            Text("Overdue")
                                .font(.subheadline.bold())
                                .foregroundStyle(.red)
                        }
                    }

                    // Day sections
                    ForEach(upcomingDays, id: \.date) { day in
                        Section {
                            ForEach(day.tasks) { task in
                                agendaRow(task: task)
                            }
                        } header: {
                            HStack {
                                Text(dayHeader(day.date))
                                    .font(.subheadline.bold())
                                if calendar.isDateInToday(day.date) {
                                    Text("Today")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func agendaRow(task: TaskItem) -> some View {
        NavigationLink(value: task) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.priorityColor(task.priority))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.body)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let due = task.dueDate {
                            Text(due, format: .dateTime.hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let list = task.list {
                            Label(list.name, systemImage: list.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if task.isRecurring {
                            Image(systemName: "repeat")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func dayHeader(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df.string(from: date)
    }

    private func changeDate(_ delta: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .day, value: delta, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
}
