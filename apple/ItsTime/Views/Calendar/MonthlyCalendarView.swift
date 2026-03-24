import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    @State private var quickAddDate: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayNames = ["M", "T", "W", "T", "F", "S", "S"]

    // Use Monday-start week
    private var mondayCalendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private var daysInMonth: [Date?] {
        let cal = mondayCalendar
        guard let range = cal.range(of: .day, in: .month, for: selectedDate),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        // Weekday offset for Monday-start (1=Mon..7=Sun)
        let weekday = cal.component(.weekday, from: firstDay)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)

        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private var selectedWeekDates: [Date] {
        let cal = mondayCalendar
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mini calendar
            miniCalendar
                .padding(.horizontal, 12)
                .padding(.top, 4)

            Divider()
                .padding(.top, 8)

            // Week summary
            weekSummary
        }
        .sheet(item: $quickAddDate) { date in
            QuickAddView(initialDueDate: date)
        }
    }

    // MARK: - Mini Calendar Grid

    private var miniCalendar: some View {
        VStack(spacing: 8) {
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

            // Day headers
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(dayNames.indices, id: \.self) { i in
                    Text(dayNames[i])
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }

            // Days grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let hasTasks = tasksForDate(date).contains { $0.status == .todo }

                        Button {
                            selectedDate = date
                        } label: {
                            VStack(spacing: 1) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.caption)
                                    .fontWeight(isToday ? .bold : .regular)
                                    .foregroundStyle(isSelected ? .white : isToday ? .accentColor : .primary)

                                Circle()
                                    .fill(hasTasks && !isSelected ? Color.accentColor : .clear)
                                    .frame(width: 3, height: 3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.accentColor : .clear)
                                    .frame(width: 30, height: 30)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 28)
                    }
                }
            }
        }
    }

    // MARK: - Week Summary

    private var weekSummary: some View {
        let weekDates = selectedWeekDates

        // Split into 2 columns: left (Mon/Tue/Wed/Thu) and right (blank/Fri/Sat/Sun)
        // Actually, inspired by the screenshot: 2-column grid, each day as a row with tasks
        return ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    daySummaryCard(date: date)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func daySummaryCard(date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let dayTasks = tasksForDate(date).filter { $0.status == .todo }

        VStack(alignment: .leading, spacing: 4) {
            // Day header
            HStack(spacing: 4) {
                Text(shortDayName(date))
                    .font(.caption.bold())
                    .foregroundStyle(isToday ? Color.accentColor : .secondary)
                Text("\(calendar.component(.day, from: date))")
                    .font(.caption.bold())
                    .foregroundStyle(isToday ? Color.accentColor : .primary)
                Spacer()
            }

            if dayTasks.isEmpty {
                Text("No tasks")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 2)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(dayTasks.prefix(5)) { task in
                        NavigationLink(value: task) {
                            monthTaskRow(task)
                        }
                        .buttonStyle(.plain)
                    }
                    if dayTasks.count > 5 {
                        Text("+\(dayTasks.count - 5) more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isToday ? Color.accentColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .onLongPressGesture {
            var comps = calendar.dateComponents([.year, .month, .day], from: date)
            comps.hour = 9
            comps.minute = 0
            quickAddDate = calendar.date(from: comps)
        }
    }

    private func monthTaskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1)
                .fill(taskColor(task))
                .frame(width: 3, height: 14)

            if let due = task.dueDate {
                let hour = calendar.component(.hour, from: due)
                let minute = calendar.component(.minute, from: due)
                if hour != 0 || minute != 0 {
                    Text(due, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .leading)
                }
            }

            Text(task.title)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Helpers

    private func taskColor(_ task: TaskItem) -> Color {
        if let list = task.list {
            return Color(hex: list.color)
        }
        return Color.priorityColor(task.priority)
    }

    private func tasksForDate(_ date: Date) -> [TaskItem] {
        allTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: date)
        }.sorted { lhs, rhs in
            if lhs.status == .todo && rhs.status != .todo { return true }
            if lhs.status != .todo && rhs.status == .todo { return false }
            return (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
        }
    }

    private func shortDayName(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df.string(from: date)
    }

    private func changeMonth(_ delta: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .month, value: delta, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
}
