import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Tag.sortOrder) private var allTags: [Tag]

    @State private var newSubtaskTitle = ""
    @State private var showDatePicker = false

    var body: some View {
        Form {
            // Breadcrumb for child tasks
            if let parent = task.parentTask {
                Section("Part of") {
                    NavigationLink(value: parent) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.turn.up.left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(parent.title)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                    .accessibilityIdentifier("parent_task_link")
                }
            }

            // Title
            Section {
                TextField("Task title", text: $task.title, axis: .vertical)
                    .font(.title3.bold())
                    .accessibilityIdentifier("task_detail_title")
                    .onChange(of: task.title) { task.updatedAt = Date() }
            }

            // Status & Priority
            Section {
                Picker("Status", selection: $task.status) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        Text(statusLabel(status)).tag(status)
                    }
                }
                .onChange(of: task.status) {
                    if task.status == .done {
                        task.completedAt = Date()
                        NotificationService.shared.cancelReminders(for: task)
                        RecurrenceService.shared.handleCompletion(task: task, context: modelContext)
                        TriggerEngine.shared.handleTaskCompletion(task: task, context: modelContext)
                    } else if task.status == .todo {
                        task.completedAt = nil
                        NotificationService.shared.scheduleReminders(for: task)
                    } else {
                        NotificationService.shared.cancelReminders(for: task)
                    }
                    TriggerEngine.shared.handleEvent(.statusChanged, task: task, context: modelContext)
                    task.updatedAt = Date()
                }

                Picker("Priority", selection: $task.priority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        HStack {
                            Circle()
                                .fill(Color.priorityColor(priority))
                                .frame(width: 10, height: 10)
                            Text(priorityLabel(priority))
                        }
                        .tag(priority)
                    }
                }
                .onChange(of: task.priority) { task.updatedAt = Date() }
            }

            // Dates
            Section("Dates") {
                Toggle("Due Date", isOn: Binding(
                    get: { task.dueDate != nil },
                    set: { enabled in
                        if enabled { task.dueDate = Date() }
                        else { task.dueDate = nil }
                        task.updatedAt = Date()
                    }
                ))

                if let dueDate = task.dueDate {
                    DatePicker(
                        "Due",
                        selection: Binding(
                            get: { dueDate },
                            set: {
                                task.dueDate = $0
                                task.updatedAt = Date()
                                NotificationService.shared.scheduleReminders(for: task)
                            }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Toggle("Start Date", isOn: Binding(
                    get: { task.startDate != nil },
                    set: { enabled in
                        if enabled {
                            task.startDate = task.dueDate ?? Date()
                        } else {
                            task.startDate = nil
                        }
                        task.updatedAt = Date()
                    }
                ))

                if let startDate = task.startDate {
                    DatePicker(
                        "Start",
                        selection: Binding(
                            get: { startDate },
                            set: {
                                task.startDate = $0
                                task.updatedAt = Date()
                            }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }

            // Time preference
            Section("When to complete") {
                Picker("Preferred time", selection: $task.timePreference) {
                    ForEach(TimePreference.allCases, id: \.self) { pref in
                        Label(pref.label, systemImage: pref.icon).tag(pref)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: task.timePreference) { task.updatedAt = Date() }
            }

            // List assignment
            Section("List") {
                Picker("List", selection: Binding(
                    get: { task.list },
                    set: {
                        task.list = $0
                        task.section = nil // reset section when list changes
                        task.updatedAt = Date()
                    }
                )) {
                    Text("None").tag(nil as TaskList?)
                    ForEach(lists) { list in
                        HStack {
                            Image(systemName: list.icon)
                                .foregroundStyle(Color(hex: list.color))
                            Text(list.name)
                        }
                        .tag(list as TaskList?)
                    }
                }

                // Section within list
                if let currentList = task.list, !currentList.sections.isEmpty {
                    Picker("Section", selection: Binding(
                        get: { task.section },
                        set: { task.section = $0; task.updatedAt = Date() }
                    )) {
                        Text("None").tag(nil as ListSection?)
                        ForEach(currentList.sections.sorted(by: { $0.sortOrder < $1.sortOrder })) { section in
                            Text(section.name).tag(section as ListSection?)
                        }
                    }
                }
            }

            // Reminders
            if task.dueDate != nil {
                Section("Reminders") {
                    ForEach(Array(task.reminderOffsets.enumerated()), id: \.offset) { index, offset in
                        HStack {
                            Image(systemName: "bell")
                                .foregroundStyle(.secondary)
                            Text(reminderLabel(offset))
                            Spacer()
                            Button(role: .destructive) {
                                task.reminderOffsets.remove(at: index)
                                task.updatedAt = Date()
                                NotificationService.shared.scheduleReminders(for: task)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Menu {
                        Button("At time of event") { addReminder(0) }
                        Button("5 minutes before") { addReminder(-300) }
                        Button("15 minutes before") { addReminder(-900) }
                        Button("30 minutes before") { addReminder(-1800) }
                        Button("1 hour before") { addReminder(-3600) }
                        Button("1 day before") { addReminder(-86400) }
                    } label: {
                        Label("Add Reminder", systemImage: "plus.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Nudge reminder (independent of due date)
            Section("Remind Me") {
                Toggle("Set Reminder", isOn: Binding(
                    get: { task.nudgeDate != nil },
                    set: { enabled in
                        if enabled {
                            task.nudgeDate = Date().addingTimeInterval(3600)
                            NotificationService.shared.scheduleNudge(for: task)
                        } else {
                            task.nudgeDate = nil
                            NotificationService.shared.cancelNudge(for: task)
                        }
                        task.updatedAt = Date()
                    }
                ))
                .accessibilityIdentifier("nudge_toggle")

                if let nudgeDate = task.nudgeDate {
                    DatePicker(
                        "When",
                        selection: Binding(
                            get: { nudgeDate },
                            set: {
                                task.nudgeDate = $0
                                task.updatedAt = Date()
                                NotificationService.shared.scheduleNudge(for: task)
                            }
                        ),
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("nudge_date_picker")
                }
            }

            // Location Reminder
            Section("Location Reminder") {
                NavigationLink {
                    LocationReminderView(task: task)
                } label: {
                    if task.hasLocationReminder {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            VStack(alignment: .leading) {
                                Text(task.locationName ?? "Location set")
                                    .font(.subheadline)
                                Text(task.locationDirection.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Label("Add Location", systemImage: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Assignment
            AssignmentPickerView(task: task)

            // Recurrence
            RecurrencePickerView(task: task)

            // Tags
            TagPickerView(task: task)

            // Parent-child hierarchy
            ParentTaskPickerView(task: task)
            ChildTasksSectionView(task: task)

            // Description (Markdown)
            Section {
                MarkdownEditorView(text: $task.taskDescription)
                    .onChange(of: task.taskDescription) { task.updatedAt = Date() }
            }

            // Subtasks
            Section("Subtasks") {
                ForEach(task.subtasks.sorted(by: { $0.sortOrder < $1.sortOrder })) { subtask in
                    SubtaskRowView(subtask: subtask)
                }
                .onDelete { offsets in
                    let sorted = task.subtasks.sorted(by: { $0.sortOrder < $1.sortOrder })
                    for index in offsets {
                        modelContext.delete(sorted[index])
                    }
                }

                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.secondary)
                    TextField("Add subtask", text: $newSubtaskTitle)
                        .accessibilityIdentifier("add_subtask_field")
                        .onSubmit {
                            addSubtask()
                        }
                }
            }

            // Comments & Activity
            Section("Collaboration") {
                NavigationLink {
                    CommentsView(task: task)
                } label: {
                    HStack {
                        Label("Comments", systemImage: "text.bubble")
                        Spacer()
                        if !task.comments.isEmpty {
                            Text("\(task.comments.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                NavigationLink {
                    ActivityLogView(task: task)
                } label: {
                    HStack {
                        Label("Activity", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        if !task.activityLog.isEmpty {
                            Text("\(task.activityLog.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Metadata
            Section("Info") {
                LabeledContent("Created") {
                    Text(task.createdAt, style: .date)
                }
                LabeledContent("Updated") {
                    Text(task.updatedAt, style: .relative)
                }
                if let completedAt = task.completedAt {
                    LabeledContent("Completed") {
                        Text(completedAt, style: .date)
                    }
                }
            }
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .formStyle(.grouped)
        .navigationTitle(task.isNote ? "Note" : "Task")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    if task.isNote {
                        task.convertToTask()
                    } else {
                        task.convertToNote()
                    }
                } label: {
                    Label(
                        task.isNote ? "Convert to Task" : "Convert to Note",
                        systemImage: task.isNote ? "checklist" : "doc.text"
                    )
                }
            }
        }
        .onDisappear {
            AutoSyncService.shared.notifyChange()
        }
    }

    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        let subtask = Subtask(title: newSubtaskTitle, sortOrder: task.subtasks.count)
        subtask.task = task
        task.subtasks.append(subtask)
        task.updatedAt = Date()
        newSubtaskTitle = ""
    }

    private func statusLabel(_ status: TaskStatus) -> String {
        switch status {
        case .todo: return "To Do"
        case .done: return "Done"
        case .wontDo: return "Won't Do"
        }
    }

    private func priorityLabel(_ priority: TaskPriority) -> String {
        switch priority {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    private func addReminder(_ offset: Int) {
        if !task.reminderOffsets.contains(offset) {
            task.reminderOffsets.append(offset)
            task.reminderOffsets.sort(by: >)
            task.updatedAt = Date()
            NotificationService.shared.scheduleReminders(for: task)
        }
    }

    private func reminderLabel(_ offset: Int) -> String {
        let abs = abs(offset)
        if abs == 0 { return "At time of event" }
        if abs < 3600 { return "\(abs / 60) min before" }
        if abs < 86400 { return "\(abs / 3600) hour\(abs / 3600 == 1 ? "" : "s") before" }
        return "\(abs / 86400) day\(abs / 86400 == 1 ? "" : "s") before"
    }
}

struct SubtaskRowView: View {
    @Bindable var subtask: Subtask
    @State private var showNotes = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Button {
                    subtask.isCompleted.toggle()
                } label: {
                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(subtask.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                TextField("Subtask", text: $subtask.title)
                    .strikethrough(subtask.isCompleted)
                    .foregroundStyle(subtask.isCompleted ? .secondary : .primary)

                Button {
                    withAnimation { showNotes.toggle() }
                } label: {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(!subtask.notes.isEmpty ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("subtask_notes_toggle")
            }

            if showNotes {
                TextField("Add note...", text: $subtask.notes, axis: .vertical)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 34)
                    .accessibilityIdentifier("subtask_notes_field")
            }
        }
    }
}
