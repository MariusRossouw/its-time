import SwiftUI
import SwiftData

struct DailyCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    @State private var quickAddDate: Date?

    private let calendar = Calendar.current
    private var solar: SolarService { .shared }

    var body: some View {
        VStack(spacing: 0) {
            dayNavBar
            Divider()
            timeGrid
        }
        .sheet(item: $quickAddDate) { date in
            QuickAddView(initialDueDate: date)
        }
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

    // MARK: - Time Grid

    private var timeGrid: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ForEach(6..<23, id: \.self) { hour in
                        DailyHourRow(
                            hour: hour,
                            date: selectedDate,
                            tasks: tasksForHour(hour),
                            period: solar.period(for: hour),
                            marker: solar.marker(for: hour),
                            hasMarker: solar.markerHours.contains(hour),
                            onLongPress: { longPressDate in
                                quickAddDate = longPressDate
                            }
                        )
                        Divider().padding(.leading, 58)
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

    private var dayTitle: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df.string(from: selectedDate)
    }

    private func tasksForHour(_ hour: Int) -> [TaskItem] {
        allTasks.filter { task in
            guard let due = task.dueDate, task.status == .todo else { return false }
            guard calendar.isDate(due, inSameDayAs: selectedDate) else { return false }
            return calendar.component(.hour, from: due) == hour
        }
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

// MARK: - Hour Row

struct DailyHourRow: View {
    let hour: Int
    let date: Date
    let tasks: [TaskItem]
    var period: DayPeriod = .morning
    var marker: SolarMarker?
    var hasMarker: Bool = false
    let onLongPress: (Date) -> Void
    var onDrop: ((TaskItem, Int) -> Void)?

    private let calendar = Calendar.current

    @State private var isTargeted = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(hourLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
                .padding(.trailing, 6)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(dropFillColor)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                    .onLongPressGesture {
                        var comps = calendar.dateComponents([.year, .month, .day], from: date)
                        comps.hour = hour
                        comps.minute = 0
                        if let targetDate = calendar.date(from: comps) {
                            onLongPress(targetDate)
                        }
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let uuidString = items.first else { return false }
                        NotificationCenter.default.post(
                            name: .calendarTaskDropped,
                            object: nil,
                            userInfo: ["taskId": uuidString, "hour": hour]
                        )
                        return true
                    } isTargeted: { targeted in
                        isTargeted = targeted
                    }

                if let marker {
                    sunMarker(icon: marker.icon, color: marker.color)
                }

                VStack(spacing: 3) {
                    ForEach(tasks) { task in
                        NavigationLink(value: task) {
                            DailyTaskBlockLabel(task: task)
                        }
                        .buttonStyle(.plain)
                        .draggable(task.id.uuidString)
                    }
                }
                .padding(.top, hasMarker ? 14 : 2)
                .padding(.trailing, 8)
            }
            .frame(maxWidth: .infinity)
        }
        .id(hour)
    }

    private var hourLabel: String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    private var dropFillColor: Color {
        if isTargeted {
            return Color.accentColor.opacity(0.15)
        }
        switch period {
        case .morning: return Color.orange.opacity(0.03)
        case .afternoon: return Color.yellow.opacity(0.03)
        case .evening: return Color.indigo.opacity(0.04)
        case .night: return Color.gray.opacity(0.05)
        }
    }

    private func sunMarker(icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Rectangle().frame(height: 1)
        }
        .foregroundStyle(color.opacity(0.6))
        .padding(.trailing, 8)
    }
}

// MARK: - Task Block Label

struct DailyTaskBlockLabel: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.priorityColor(task.priority))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.caption)
                    .lineLimit(1)
                if let due = task.dueDate {
                    Text(due, format: .dateTime.hour().minute())
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.priorityColor(task.priority).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
