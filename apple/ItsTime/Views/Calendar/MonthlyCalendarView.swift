import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    @State private var quickAddDate: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func tasksForDate(_ date: Date) -> [TaskItem] {
        allTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: date)
        }.sorted { lhs, rhs in
            // Active tasks first, then completed
            if lhs.status == .todo && rhs.status != .todo { return true }
            if lhs.status != .todo && rhs.status == .todo { return false }
            return (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
        }
    }

    private func activeTasksForDate(_ date: Date) -> [TaskItem] {
        tasksForDate(date).filter { $0.status == .todo }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month nav
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Day headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayNames, id: \.self) { name in
                    Text(name)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }

            // Days grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let tasks = activeTasksForDate(date)
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

                        Button {
                            selectedDate = date
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.subheadline)
                                    .fontWeight(isToday ? .bold : .regular)

                                // Task dots
                                HStack(spacing: 2) {
                                    ForEach(tasks.prefix(3).indices, id: \.self) { i in
                                        Circle()
                                            .fill(Color.priorityColor(tasks[i].priority))
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.accentColor.opacity(0.15) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isToday ? Color.accentColor : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .onLongPressGesture {
                            // Default to 9 AM on the selected day
                            var comps = calendar.dateComponents([.year, .month, .day], from: date)
                            comps.hour = 9
                            comps.minute = 0
                            quickAddDate = calendar.date(from: comps)
                        }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }

            Divider()

            // Selected day's tasks
            let dayTasks = tasksForDate(selectedDate)
            if dayTasks.isEmpty {
                Text("No tasks on this day")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(dayTasks) { task in
                        NavigationLink(value: task) {
                            TaskRowView(task: task)
                        }
                    }
                }
                .listStyle(.plain)
            }

            Spacer()
        }
        .padding(.top)
        .sheet(item: $quickAddDate) { date in
            QuickAddView(initialDueDate: date)
        }
    }

    private func changeMonth(_ delta: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .month, value: delta, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
}
