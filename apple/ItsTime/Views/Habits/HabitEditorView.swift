import SwiftUI
import SwiftData

struct HabitEditorView: View {
    var habit: Habit?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var habitDescription = ""
    @State private var icon = "checkmark.circle"
    @State private var color = "#007AFF"
    @State private var frequency: HabitFrequency = .daily
    @State private var customDays: [Int] = []
    @State private var goalCount = 1
    @State private var hasReminder = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

    private let iconOptions = [
        "checkmark.circle", "heart.fill", "drop.fill", "figure.run",
        "book.fill", "bed.double.fill", "leaf.fill", "brain.head.profile",
        "dumbbell.fill", "cup.and.saucer.fill", "pill.fill", "pencil.and.outline",
        "music.note", "paintpalette.fill", "gamecontroller.fill", "phone.down.fill"
    ]

    private let colorOptions = [
        "#007AFF", "#34C759", "#FF3B30", "#FF9500",
        "#AF52DE", "#5856D6", "#FF2D55", "#00C7BE",
        "#FFD60A", "#AC8E68"
    ]

    private var isEditing: Bool { habit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Habit name", text: $name)
                    TextField("Description (optional)", text: $habitDescription, axis: .vertical)
                }

                Section("Icon & Color") {
                    iconPicker
                    colorPicker
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.label).tag(freq)
                        }
                    }

                    if frequency == .custom {
                        weekdayPicker
                    }
                }

                Section("Goal") {
                    Stepper("Daily goal: \(goalCount)", value: $goalCount, in: 1...100)
                    if goalCount > 1 {
                        Text("Cumulative habit — track increments toward your daily goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Reminder") {
                    Toggle("Reminder", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") { save() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let habit {
                    name = habit.name
                    habitDescription = habit.habitDescription
                    icon = habit.icon
                    color = habit.color
                    frequency = habit.frequency
                    customDays = habit.customDays
                    goalCount = habit.goalCount
                    hasReminder = habit.reminderTime != nil
                    if let rt = habit.reminderTime { reminderTime = rt }
                }
            }
        }
    }

    // MARK: - Icon Picker

    private var iconPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
            ForEach(iconOptions, id: \.self) { ic in
                Button {
                    icon = ic
                } label: {
                    Image(systemName: ic)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(icon == ic ? Color(hex: color).opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        HStack(spacing: 8) {
            ForEach(colorOptions, id: \.self) { c in
                Button {
                    color = c
                } label: {
                    Circle()
                        .fill(Color(hex: c))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if c == color {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Weekday Picker

    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, label in
                let day = index + 1 // 1=Sun..7=Sat
                Button {
                    if customDays.contains(day) {
                        customDays.removeAll { $0 == day }
                    } else {
                        customDays.append(day)
                    }
                } label: {
                    Text(label)
                        .font(.caption.bold())
                        .frame(width: 32, height: 32)
                        .background(customDays.contains(day) ? Color(hex: color) : Color.gray.opacity(0.2))
                        .foregroundStyle(customDays.contains(day) ? .white : .primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Save

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let habit {
            // Update existing
            habit.name = trimmed
            habit.habitDescription = habitDescription
            habit.icon = icon
            habit.color = color
            habit.frequency = frequency
            habit.customDays = customDays
            habit.goalCount = goalCount
            habit.reminderTime = hasReminder ? reminderTime : nil
            habit.updatedAt = Date()
        } else {
            // Create new
            let newHabit = Habit(
                name: trimmed,
                habitDescription: habitDescription,
                icon: icon,
                color: color,
                frequency: frequency,
                customDays: customDays,
                goalCount: goalCount,
                reminderTime: hasReminder ? reminderTime : nil
            )
            modelContext.insert(newHabit)
        }

        dismiss()
    }
}
