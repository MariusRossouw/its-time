import SwiftUI
import SwiftData

struct QuickAddView: View {
    var initialDueDate: Date? = nil
    var parentTask: TaskItem? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]

    @State private var title = ""
    @State private var priority: TaskPriority = .none
    @State private var dueDate: Date? = nil
    @State private var selectedList: TaskList?
    @State private var showDatePicker = false
    @AppStorage("defaultReminder") private var defaultReminder = "none"
    @FocusState private var titleFocused: Bool

    private var inbox: TaskList? {
        lists.first { $0.isInbox }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Parent banner
                if let parentTask {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.turn.up.left")
                        Text("Child of: \(parentTask.title)")
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                // Title input
                TextField("What do you need to do?", text: $title, axis: .vertical)
                    .font(.title3)
                    .focused($titleFocused)
                    .padding()
                    .accessibilityIdentifier("quick_add_title")
                    .onSubmit {
                        createTask()
                    }

                // Quick date buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        quickDateButton("Today", systemImage: "sun.max", date: Date())
                            .accessibilityIdentifier("quick_add_today")
                        quickDateButton("Tomorrow", systemImage: "sunrise", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                            .accessibilityIdentifier("quick_add_tomorrow")
                        quickDateButton("Next Week", systemImage: "calendar", date: nextMonday())
                            .accessibilityIdentifier("quick_add_next_week")
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Label("Pick Date", systemImage: "calendar.badge.clock")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(dueDate != nil && !isPresetDate() ? .blue : .secondary)
                        .accessibilityIdentifier("quick_add_pick_date")
                    }
                    .padding(.horizontal)
                }

                if showDatePicker {
                    DatePicker(
                        "Due date",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                }

                // Priority & List pickers
                HStack(spacing: 16) {
                    // Priority
                    Menu {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Button {
                                priority = p
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color.priorityColor(p))
                                        .frame(width: 10, height: 10)
                                    Text(p.rawValue.capitalized)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.priorityColor(priority))
                                .frame(width: 10, height: 10)
                            Text(priority == .none ? "Priority" : priority.rawValue.capitalized)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.fill.tertiary)
                        .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("quick_add_priority")

                    // List
                    Menu {
                        ForEach(lists) { list in
                            Button {
                                selectedList = list
                            } label: {
                                HStack {
                                    Image(systemName: list.icon)
                                    Text(list.name)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedList?.icon ?? "tray")
                                .font(.caption)
                            Text(selectedList?.name ?? "Inbox")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.fill.tertiary)
                        .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("quick_add_list")

                    Spacer()
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("quick_add_cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { createTask() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("quick_add_add")
                }
            }
            .onAppear {
                titleFocused = true
                if let initialDueDate {
                    dueDate = initialDueDate
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 350)
        #endif
    }

    private func createTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let targetList = selectedList ?? inbox
        let nextOrder = (targetList?.tasks.count ?? 0)

        let task = TaskItem(
            title: trimmed,
            priority: priority,
            dueDate: dueDate,
            list: targetList,
            sortOrder: nextOrder
        )

        // Apply default reminder if task has a due date
        if dueDate != nil, defaultReminder != "none", let offset = Int(defaultReminder) {
            task.reminderOffsets = [offset]
        }

        if let parentTask {
            task.parentTask = parentTask
            if selectedList == nil {
                task.list = parentTask.list
            }
        }

        modelContext.insert(task)

        if dueDate != nil && !task.reminderOffsets.isEmpty {
            NotificationService.shared.scheduleReminders(for: task)
        }

        AutoSyncService.shared.notifyChange()
        dismiss()
    }

    private func quickDateButton(_ label: String, systemImage: String, date: Date) -> some View {
        Button {
            dueDate = date
            showDatePicker = false
        } label: {
            Label(label, systemImage: systemImage)
                .font(.subheadline)
        }
        .buttonStyle(.bordered)
        .tint(isDateSelected(date) ? .blue : .secondary)
    }

    private func isDateSelected(_ date: Date) -> Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDate(dueDate, inSameDayAs: date)
    }

    private func isPresetDate() -> Bool {
        guard let dueDate else { return false }
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let monday = nextMonday()
        return Calendar.current.isDate(dueDate, inSameDayAs: today)
            || Calendar.current.isDate(dueDate, inSameDayAs: tomorrow)
            || Calendar.current.isDate(dueDate, inSameDayAs: monday)
    }

    private func nextMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = (9 - weekday) % 7
        return calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 7 : daysUntilMonday, to: today)!
    }
}

struct QuickAddButton: View {
    @Binding var showQuickAdd: Bool

    var body: some View {
        Button {
            showQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .accessibilityLabel("Add new task")
    }
}
