import SwiftUI
import SwiftData

struct QuickAddView: View {
    var initialDueDate: Date? = nil
    var parentTask: TaskItem? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(filter: #Predicate<Collaborator> { $0.isCurrentUser == true })
    private var currentUsers: [Collaborator]

    @State private var title = ""
    @State private var priority: TaskPriority = .none
    @State private var dueDate: Date? = nil
    @State private var dueTime: Date? = nil
    @State private var timePreference: TimePreference = .anytime
    @State private var selectedList: TaskList?
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showTemplates = false
    @AppStorage("defaultReminder") private var defaultReminder = "none"
    @FocusState private var titleFocused: Bool
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var selectedTemplate: TaskTemplate?

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

                // Title input with voice
                HStack(alignment: .top, spacing: 8) {
                    TextField("What do you need to do?", text: $title, axis: .vertical)
                        .font(.title3)
                        .focused($titleFocused)
                        .accessibilityIdentifier("quick_add_title")
                        .onSubmit {
                            createTask()
                        }

                    #if os(iOS)
                    Button {
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopRecording()
                            if !speechRecognizer.transcript.isEmpty {
                                title = speechRecognizer.transcript
                            }
                        } else {
                            titleFocused = false
                            speechRecognizer.transcript = ""
                            Task { await speechRecognizer.startRecording() }
                        }
                    } label: {
                        Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                            .font(.title3)
                            .foregroundStyle(speechRecognizer.isRecording ? .red : .secondary)
                            .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("quick_add_voice")
                    #endif
                }
                .padding()
                .onChange(of: speechRecognizer.transcript) {
                    if speechRecognizer.isRecording {
                        title = speechRecognizer.transcript
                    }
                }

                // Quick date buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickDateButton("Today", systemImage: "sun.max", date: Calendar.current.startOfDay(for: Date()))
                            .accessibilityIdentifier("quick_add_today")
                        quickDateButton("Tomorrow", systemImage: "sunrise", date: Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!))
                            .accessibilityIdentifier("quick_add_tomorrow")

                        // Next 7 days by name
                        ForEach(upcomingWeekDays(), id: \.name) { day in
                            quickDateButton(day.name, systemImage: "calendar.day.timeline.left", date: day.date)
                        }

                        quickDateButton("Next Week", systemImage: "calendar", date: Calendar.current.startOfDay(for: nextMonday()))
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
                            set: { dueDate = Calendar.current.startOfDay(for: $0) }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                }

                // Time preference (when during the day)
                if dueDate != nil {
                    VStack(spacing: 8) {
                        Picker("When", selection: $timePreference) {
                            ForEach(TimePreference.allCases, id: \.self) { pref in
                                Label(pref.label, systemImage: pref.icon).tag(pref)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Optional specific time
                        HStack {
                            Button {
                                withAnimation {
                                    if showTimePicker {
                                        showTimePicker = false
                                        dueTime = nil
                                    } else {
                                        showTimePicker = true
                                        dueTime = Date()
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: showTimePicker ? "clock.fill" : "clock")
                                        .font(.caption)
                                    Text(showTimePicker ? "Remove time" : "Add specific time")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(showTimePicker ? .blue : .secondary)
                            }
                            .buttonStyle(.plain)

                            if showTimePicker, let time = dueTime {
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { time },
                                        set: { dueTime = $0 }
                                    ),
                                    displayedComponents: [.hourAndMinute]
                                )
                                .labelsHidden()
                            }

                            Spacer()
                        }
                    }
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
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            showTemplates = true
                        } label: {
                            Image(systemName: "doc.badge.plus")
                        }
                        .accessibilityIdentifier("quick_add_templates")

                        Button("Add") { createTask() }
                            .bold()
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                            .accessibilityIdentifier("quick_add_add")
                    }
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatePickerView { template in
                    title = template.title
                    priority = template.priority
                    selectedTemplate = template
                    showTemplates = false
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
            dueTime: dueTime,
            list: targetList,
            sortOrder: nextOrder
        )
        task.timePreference = timePreference

        // Auto-assign to current user
        if let currentUser = currentUsers.first {
            task.assignedTo = currentUser.id
            task.assignedToName = currentUser.name
        }

        // Apply default reminder if task has a due date
        if dueDate != nil, defaultReminder != "none", let offset = Int(defaultReminder) {
            task.reminderOffsets = [offset]
        }

        // Apply template subtasks and tags
        if let template = selectedTemplate {
            task.taskDescription = template.taskDescription
            task.isNote = template.isNote
            for (i, subtaskTitle) in template.subtaskTitles.enumerated() {
                let sub = Subtask(title: subtaskTitle, sortOrder: i)
                task.subtasks.append(sub)
                modelContext.insert(sub)
            }
            // Re-link tags by ID
            if !template.tagIds.isEmpty {
                let tagDescriptor = FetchDescriptor<Tag>()
                if let allTags = try? modelContext.fetch(tagDescriptor) {
                    task.tags = allTags.filter { template.tagIds.contains($0.id) }
                }
            }
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
            dueTime = nil
            showTimePicker = false
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

    private func upcomingWeekDays() -> [(name: String, date: Date)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let df = DateFormatter()
        df.dateFormat = "EEEE" // Full day name

        // Start from day after tomorrow, show next 5 days (to fill a 7-day window with today+tomorrow)
        return (2...6).compactMap { offset -> (name: String, date: Date)? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return (name: df.string(from: date), date: date)
        }
    }

    private func isPresetDate() -> Bool {
        guard let dueDate else { return false }
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let monday = nextMonday()
        if calendar.isDate(dueDate, inSameDayAs: today)
            || calendar.isDate(dueDate, inSameDayAs: tomorrow)
            || calendar.isDate(dueDate, inSameDayAs: monday) {
            return true
        }
        // Check the weekday buttons (days 2-6 from today)
        for offset in 2...6 {
            if let date = calendar.date(byAdding: .day, value: offset, to: today),
               calendar.isDate(dueDate, inSameDayAs: date) {
                return true
            }
        }
        return false
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
