import SwiftUI

struct RecurrencePickerView: View {
    @Bindable var task: TaskItem

    private let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]


    var body: some View {
        Section("Repeat") {
            Picker("Repeat", selection: $task.recurrenceType) {
                ForEach(RecurrenceType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            }
            .onChange(of: task.recurrenceType) { task.updatedAt = Date() }

            if task.recurrenceType != .none {
                // Interval
                if task.recurrenceType == .custom {
                    Stepper("Every \(task.recurrenceInterval) day\(task.recurrenceInterval == 1 ? "" : "s")", value: $task.recurrenceInterval, in: 1...365)
                        .onChange(of: task.recurrenceInterval) { task.updatedAt = Date() }
                }

                // Weekday picker for weekly
                if task.recurrenceType == .weekly {
                    WeekdayPickerRow(
                        weekdays: $task.recurrenceWeekdays,
                        weekdayNames: weekdayNames,
                        onChanged: { task.updatedAt = Date() }
                    )
                }

                // Completion-based toggle
                Toggle("Based on completion date", isOn: $task.recurrenceBasedOnCompletion)
                    .onChange(of: task.recurrenceBasedOnCompletion) { task.updatedAt = Date() }

                // End date
                Toggle("End date", isOn: Binding(
                    get: { task.recurrenceEndDate != nil },
                    set: { enabled in
                        task.recurrenceEndDate = enabled ? Calendar.current.date(byAdding: .month, value: 3, to: Date()) : nil
                        task.updatedAt = Date()
                    }
                ))

                if let endDate = task.recurrenceEndDate {
                    DatePicker("Ends", selection: Binding(
                        get: { endDate },
                        set: { task.recurrenceEndDate = $0; task.updatedAt = Date() }
                    ), displayedComponents: .date)
                }
            }
        }
    }
}

struct WeekdayPickerRow: View {
    @Binding var weekdays: [Int]
    let weekdayNames: [String]
    let onChanged: () -> Void

    private let days: [Int] = Array(1...7)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On days")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    WeekdayButton(
                        label: weekdayNames[day - 1],
                        isSelected: weekdays.contains(day),
                        action: {
                            if weekdays.contains(day) {
                                weekdays.removeAll { $0 == day }
                            } else {
                                weekdays.append(day)
                                weekdays.sort()
                            }
                            onChanged()
                        }
                    )
                }
            }
        }
    }
}

struct WeekdayButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption2.bold())
                .frame(width: 36, height: 32)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
