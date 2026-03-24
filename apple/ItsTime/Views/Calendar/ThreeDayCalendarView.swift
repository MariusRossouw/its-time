import SwiftUI
import SwiftData

struct ThreeDayCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    @State private var quickAddDate: Date?
    @State private var now = Date()

    private let calendar = Calendar.current
    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 48
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var threeDates: [Date] {
        (-1...1).compactMap { calendar.date(byAdding: .day, value: $0, to: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            dayHeaders
            Divider()
            timeGrid
        }
        .sheet(item: $quickAddDate) { date in
            QuickAddView(initialDueDate: date)
        }
        .onReceive(timer) { _ in now = Date() }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { changeDay(-3) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(rangeTitle).font(.headline)
            Spacer()
            Button { changeDay(3) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Day Headers

    private var dayHeaders: some View {
        HStack(spacing: 0) {
            Text("").frame(width: timeColumnWidth)
            ForEach(threeDates, id: \.self) { date in
                let isToday = calendar.isDateInToday(date)
                VStack(spacing: 2) {
                    Text(dayName(date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(calendar.component(.day, from: date))")
                        .font(.title3.bold())
                        .foregroundStyle(isToday ? .white : .primary)
                        .frame(width: 36, height: 36)
                        .background(isToday ? Color.accentColor : .clear)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Time Grid

    private var timeGrid: some View {
        ScrollView {
            ScrollViewReader { proxy in
                ZStack(alignment: .topLeading) {
                    // Hour grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            HStack(alignment: .top, spacing: 0) {
                                Text(hourLabel(hour))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .frame(width: timeColumnWidth, alignment: .trailing)
                                    .padding(.trailing, 4)
                                    .offset(y: -6)

                                Rectangle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 0.5)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(height: hourHeight)
                            .id(hour)
                        }
                    }

                    // Task blocks overlay
                    HStack(spacing: 0) {
                        Color.clear.frame(width: timeColumnWidth)

                        HStack(spacing: 2) {
                            ForEach(threeDates, id: \.self) { date in
                                dayColumn(date: date)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    // Current time indicator
                    if threeDates.contains(where: { calendar.isDateInToday($0) }) {
                        currentTimeIndicator
                    }
                }
                .onAppear {
                    let currentHour = calendar.component(.hour, from: Date())
                    proxy.scrollTo(max(currentHour - 2, 0), anchor: .top)
                }
            }
        }
    }

    // MARK: - Day Column

    @ViewBuilder
    private func dayColumn(date: Date) -> some View {
        let dayTasks = allTasks.filter { task in
            guard let due = task.dueDate, task.status == .todo else { return false }
            return calendar.isDate(due, inSameDayAs: date)
        }

        ZStack(alignment: .topLeading) {
            // Tap targets per hour
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    Color.clear
                        .frame(height: hourHeight)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            var comps = calendar.dateComponents([.year, .month, .day], from: date)
                            comps.hour = hour
                            comps.minute = 0
                            if let targetDate = calendar.date(from: comps) {
                                quickAddDate = targetDate
                            }
                        }
                }
            }

            // Task blocks
            ForEach(dayTasks) { task in
                if let due = task.dueDate {
                    let hour = calendar.component(.hour, from: due)
                    let minute = calendar.component(.minute, from: due)
                    let topOffset = CGFloat(hour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

                    NavigationLink(value: task) {
                        threeDayTaskBlock(task)
                    }
                    .buttonStyle(.plain)
                    .frame(height: max(hourHeight * 0.8, 28))
                    .offset(y: topOffset + 2)
                    .padding(.horizontal, 2)
                }
            }
        }
        .frame(height: hourHeight * 24)
    }

    private func threeDayTaskBlock(_ task: TaskItem) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(taskColor(task))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                if let due = task.dueDate {
                    let hour = calendar.component(.hour, from: due)
                    let minute = calendar.component(.minute, from: due)
                    if hour != 0 || minute != 0 {
                        Text(due, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(task.title)
                    .font(.caption)
                    .lineLimit(2)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(taskColor(task).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(taskColor(task).opacity(0.25), lineWidth: 0.5)
        )
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let yOffset = CGFloat(hour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        let todayIndex = threeDates.firstIndex(where: { calendar.isDateInToday($0) }) ?? 0

        return GeometryReader { geo in
            let totalColumnWidth = geo.size.width - timeColumnWidth
            let dayWidth = totalColumnWidth / 3.0
            let xStart = timeColumnWidth + dayWidth * CGFloat(todayIndex)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: dayWidth, height: 1.5)
                    .offset(x: xStart, y: yOffset)

                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: xStart - 4, y: yOffset - 3.5)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func taskColor(_ task: TaskItem) -> Color {
        if let list = task.list {
            return Color(hex: list.color)
        }
        return Color.priorityColor(task.priority)
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    private func dayName(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df.string(from: date)
    }

    private var rangeTitle: String {
        guard let first = threeDates.first, let last = threeDates.last else { return "" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return "\(df.string(from: first)) – \(df.string(from: last))"
    }

    private func changeDay(_ delta: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .day, value: delta, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
}
