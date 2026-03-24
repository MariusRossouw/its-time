import SwiftUI
import SwiftData

struct DailyCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    @State private var quickAddDate: Date?
    @State private var now = Date()

    private let calendar = Calendar.current
    private let hourHeight: CGFloat = 64
    private let timeColumnWidth: CGFloat = 52
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private var solar: SolarService { .shared }

    private var weekDates: [Date] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(spacing: 0) {
            dayNavBar
            miniWeekStrip
            Divider()
            timeGrid
        }
        .sheet(item: $quickAddDate) { date in
            QuickAddView(initialDueDate: date)
        }
        .onReceive(timer) { _ in now = Date() }
        .onChange(of: selectedDate) {
            if let loc = solar.lastLocation {
                solar.update(for: loc, date: selectedDate)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .calendarTaskDropped)) { notification in
            guard let userInfo = notification.userInfo,
                  let taskIdString = userInfo["taskId"] as? String,
                  let hour = userInfo["hour"] as? Int,
                  let taskId = UUID(uuidString: taskIdString) else { return }

            if let task = allTasks.first(where: { $0.id == taskId }) {
                var comps = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                comps.hour = hour
                comps.minute = 0
                if let newDate = calendar.date(from: comps) {
                    withAnimation {
                        task.dueDate = newDate
                        task.updatedAt = Date()
                    }
                }
            }
        }
    }

    // MARK: - Nav Bar

    private var dayNavBar: some View {
        HStack {
            Button { changeDay(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            VStack(spacing: 2) {
                Text(dayTitle).font(.headline)
                if calendar.isDateInToday(selectedDate) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
            Spacer()
            Button { changeDay(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Mini Week Strip

    private var miniWeekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let hasTasks = allTasks.contains { task in
                    guard let due = task.dueDate, task.status == .todo else { return false }
                    return calendar.isDate(due, inSameDayAs: date)
                }

                Button {
                    withAnimation { selectedDate = date }
                } label: {
                    VStack(spacing: 3) {
                        Text(shortDayName(date))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text("\(calendar.component(.day, from: date))")
                            .font(.subheadline.weight(isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : isToday ? .accentColor : .primary)
                            .frame(width: 32, height: 32)
                            .background(isSelected ? Color.accentColor : .clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(isToday && !isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                            )
                        Circle()
                            .fill(hasTasks ? Color.accentColor : .clear)
                            .frame(width: 4, height: 4)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
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
                                    .padding(.trailing, 6)
                                    .offset(y: -6)

                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(height: 0.5)
                                    Spacer()
                                }
                            }
                            .frame(height: hourHeight)
                            .id(hour)
                        }
                    }

                    // Task cards
                    taskCardsOverlay

                    // Current time indicator
                    if calendar.isDateInToday(selectedDate) {
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

    // MARK: - Task Cards Overlay

    private var taskCardsOverlay: some View {
        let dayTasks = allTasks.filter { task in
            guard let due = task.dueDate, task.status == .todo else { return false }
            return calendar.isDate(due, inSameDayAs: selectedDate)
        }

        return ZStack(alignment: .topLeading) {
            ForEach(dayTasks) { task in
                if let due = task.dueDate {
                    let hour = calendar.component(.hour, from: due)
                    let minute = calendar.component(.minute, from: due)
                    let yOffset = CGFloat(hour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

                    HStack(alignment: .top, spacing: 0) {
                        // Timeline node
                        VStack(spacing: 0) {
                            Circle()
                                .fill(taskColor(task))
                                .frame(width: 10, height: 10)
                        }
                        .frame(width: timeColumnWidth)
                        .offset(y: 8)

                        // Task card
                        NavigationLink(value: task) {
                            dailyTaskCard(task)
                        }
                        .buttonStyle(.plain)
                        .draggable(task.id.uuidString)
                        .padding(.trailing, 12)
                    }
                    .offset(y: yOffset)
                }
            }
        }
        .frame(height: hourHeight * 24)
    }

    private func dailyTaskCard(_ task: TaskItem) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(taskColor(task))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                if let due = task.dueDate {
                    HStack(spacing: 4) {
                        Text(due, format: .dateTime.hour().minute())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let dueTime = task.dueTime {
                            Text("– \(dueTime, format: .dateTime.hour().minute())")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let list = task.list {
                        HStack(spacing: 3) {
                            Image(systemName: list.icon)
                                .font(.system(size: 9))
                            Text(list.name)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if !task.subtasks.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "checklist")
                                .font(.system(size: 9))
                            let done = task.subtasks.filter(\.isCompleted).count
                            Text("\(done)/\(task.subtasks.count)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if task.isRecurring {
                        Image(systemName: "repeat")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Spacer(minLength: 0)
        }
        .background(taskColor(task).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(taskColor(task).opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let yOffset = CGFloat(hour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        return HStack(spacing: 0) {
            // Time label
            Text(now, format: .dateTime.hour().minute())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.red)
                .frame(width: timeColumnWidth, alignment: .trailing)
                .padding(.trailing, 4)

            // Red dot + line
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: -4)

            Rectangle()
                .fill(Color.red)
                .frame(height: 1.5)
        }
        .offset(y: yOffset - 4)
        .allowsHitTesting(false)
    }

    // MARK: - Drop targets (invisible overlay for each hour)

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

    private var dayTitle: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df.string(from: selectedDate)
    }

    private func shortDayName(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df.string(from: date)
    }

    private func changeDay(_ delta: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .day, value: delta, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
}

// MARK: - Notification for calendar drag-and-drop

extension Notification.Name {
    static let calendarTaskDropped = Notification.Name("calendarTaskDropped")
}

// Make Date identifiable for .sheet(item:)
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
