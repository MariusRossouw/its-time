import SwiftUI
import SwiftData

struct TimelineGanttView: View {
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]

    @State private var timeRange: TimelineRange = .week
    @State private var startDate = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current
    private let rowHeight: CGFloat = 40
    private let dayWidth: CGFloat = 70
    private let labelWidth: CGFloat = 120

    private var daysToShow: Int {
        switch timeRange {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }

    private var timelineTasks: [TaskItem] {
        let end = calendar.date(byAdding: .day, value: daysToShow, to: startDate)!
        return allTasks.filter { task in
            guard task.status == .todo, !task.isNote else { return false }
            guard let due = task.dueDate else { return false }
            let start = task.startDate ?? due
            // Task overlaps with visible range
            return start <= end && due >= startDate
        }
    }

    private var dates: [Date] {
        (0..<daysToShow).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Controls
            controlBar
            Divider()

            // Timeline
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    dateHeader
                    Divider()
                    taskRows
                }
            }
        }
        .navigationTitle("Timeline")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Controls

    private var controlBar: some View {
        HStack {
            Button { shiftDates(-daysToShow) } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Picker("Range", selection: $timeRange) {
                ForEach(TimelineRange.allCases, id: \.self) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            Spacer()

            Button { shiftDates(daysToShow) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(spacing: 0) {
            Text("Task")
                .font(.caption.bold())
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)

            ForEach(dates, id: \.timeIntervalSince1970) { date in
                VStack(spacing: 1) {
                    Text(date, format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(date, format: .dateTime.day())
                        .font(.caption2.bold())
                        .foregroundStyle(calendar.isDateInToday(date) ? .blue : .primary)
                }
                .frame(width: dayWidth)
            }
        }
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.06))
    }

    // MARK: - Task Rows

    private var taskRows: some View {
        VStack(spacing: 0) {
            if timelineTasks.isEmpty {
                Text("No tasks in this range")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(40)
            } else {
                ForEach(timelineTasks) { task in
                    timelineRow(task: task)
                    Divider().padding(.leading, labelWidth)
                }
            }
        }
    }

    private func timelineRow(task: TaskItem) -> some View {
        HStack(spacing: 0) {
            // Task label
            NavigationLink {
                if task.isNote {
                    NoteEditorView(note: task)
                } else {
                    TaskDetailView(task: task)
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.priorityColor(task.priority))
                        .frame(width: 6, height: 6)
                    Text(task.title)
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("timeline_task_link")

            // Bar chart area
            ZStack(alignment: .leading) {
                // Background grid
                HStack(spacing: 0) {
                    ForEach(dates, id: \.timeIntervalSince1970) { date in
                        Rectangle()
                            .fill(calendar.isDateInToday(date) ? Color.blue.opacity(0.05) : Color.clear)
                            .frame(width: dayWidth)
                    }
                }

                // Task bar
                taskBar(task: task)
            }
        }
        .frame(height: rowHeight)
    }

    @ViewBuilder
    private func taskBar(task: TaskItem) -> some View {
        let taskStart = task.startDate ?? task.dueDate ?? startDate
        let taskEnd = task.dueDate ?? taskStart

        let startOffset = max(0, calendar.dateComponents([.day], from: startDate, to: taskStart).day ?? 0)
        let duration = max(1, (calendar.dateComponents([.day], from: taskStart, to: taskEnd).day ?? 0) + 1)

        let barColor = Color.priorityColor(task.priority)
        let xOffset = CGFloat(startOffset) * dayWidth + 4
        let barWidth = CGFloat(duration) * dayWidth - 8

        if barWidth > 0 && startOffset < daysToShow {
            RoundedRectangle(cornerRadius: 5)
                .fill(barColor.opacity(0.8))
                .frame(width: min(barWidth, CGFloat(daysToShow - startOffset) * dayWidth - 8), height: 24)
                .offset(x: xOffset)
                .overlay(alignment: .leading) {
                    if barWidth > 30 {
                        Text(task.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.leading, xOffset + 6)
                    }
                }
        }
    }

    private func shiftDates(_ days: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .day, value: days, to: startDate) {
                startDate = newDate
            }
        }
    }
}

enum TimelineRange: String, CaseIterable {
    case week, twoWeeks, month

    var label: String {
        switch self {
        case .week: return "Week"
        case .twoWeeks: return "2 Weeks"
        case .month: return "Month"
        }
    }
}
