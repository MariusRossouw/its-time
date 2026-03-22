import SwiftUI
import SwiftData

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    @State private var quickAddDate: Date?

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(spacing: 0) {
            weekNavBar
            dayHeaders
            Divider()
            timeGrid
        }
        .sheet(item: $quickAddDate) { date in
            QuickAddView(initialDueDate: date)
        }
    }

    // MARK: - Nav Bar

    private var weekNavBar: some View {
        HStack {
            Button { changeWeek(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(weekTitle).font(.headline)
            Spacer()
            Button { changeWeek(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Day Headers

    private var dayHeaders: some View {
        HStack(spacing: 0) {
            Text("").frame(width: 44)
            ForEach(weekDates, id: \.self) { date in
                WeeklyDayHeader(date: date, calendar: calendar)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Time Grid

    private var timeGrid: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ForEach(6..<23, id: \.self) { hour in
                        WeeklyHourRow(
                            hour: hour,
                            weekDates: weekDates,
                            allTasks: allTasks,
                            calendar: calendar,
                            onLongPress: { date in
                                quickAddDate = date
                            }
                        )
                        Divider()
                    }
                }
                .onAppear {
                    let currentHour = calendar.component(.hour, from: Date())
                    proxy.scrollTo(max(currentHour - 1, 6), anchor: .top)
                }
            }
        }
    }

    // MARK: - Helpers

    private var weekTitle: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return "\(df.string(from: first)) – \(df.string(from: last))"
    }

    private func changeWeek(_ delta: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: delta, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
}

// MARK: - Day Header

struct WeeklyDayHeader: View {
    let date: Date
    let calendar: Calendar

    var body: some View {
        let isToday = calendar.isDateInToday(date)
        VStack(spacing: 2) {
            Text(dayLetter)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline.bold())
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 28, height: 28)
                .background(isToday ? Color.accentColor : .clear)
                .clipShape(Circle())
        }
    }

    private var dayLetter: String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df.string(from: date)
    }
}

// MARK: - Hour Row

struct WeeklyHourRow: View {
    let hour: Int
    let weekDates: [Date]
    let allTasks: [TaskItem]
    let calendar: Calendar
    let onLongPress: (Date) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(hourLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
                .padding(.trailing, 4)

            HStack(spacing: 1) {
                ForEach(weekDates, id: \.self) { date in
                    WeeklyDayCell(
                        hour: hour,
                        date: date,
                        tasks: tasksForHour(date: date),
                        calendar: calendar,
                        onLongPress: onLongPress
                    )
                }
            }
        }
        .id(hour)
    }

    private var hourLabel: String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    private func tasksForHour(date: Date) -> [TaskItem] {
        allTasks.filter { task in
            guard let due = task.dueDate, task.status == .todo else { return false }
            guard calendar.isDate(due, inSameDayAs: date) else { return false }
            return calendar.component(.hour, from: due) == hour
        }
    }
}

// MARK: - Day Cell

struct WeeklyDayCell: View {
    let hour: Int
    let date: Date
    let tasks: [TaskItem]
    let calendar: Calendar
    let onLongPress: (Date) -> Void

    private var isDaylight: Bool { hour >= 6 && hour < 18 }

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(isDaylight ? Color.clear : Color.gray.opacity(0.1))
                .frame(height: 50)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    var comps = calendar.dateComponents([.year, .month, .day], from: date)
                    comps.hour = hour
                    comps.minute = 0
                    if let targetDate = calendar.date(from: comps) {
                        onLongPress(targetDate)
                    }
                }

            if hour == 6 {
                sunMarker(icon: "sunrise.fill", color: .orange)
            }
            if hour == 18 {
                sunMarker(icon: "sunset.fill", color: .indigo)
            }

            VStack(spacing: 2) {
                ForEach(tasks.prefix(2)) { task in
                    NavigationLink(value: task) {
                        Text(task.title)
                            .font(.system(size: 9))
                            .lineLimit(1)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.priorityColor(task.priority).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private func sunMarker(icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8))
            Rectangle().frame(height: 1)
        }
        .foregroundStyle(color.opacity(0.6))
        .padding(.horizontal, 2)
    }
}
