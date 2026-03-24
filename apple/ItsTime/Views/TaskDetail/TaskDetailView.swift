import SwiftUI
import SwiftData

enum TaskDetailTab: String, CaseIterable {
    case notes, children, subtasks, attachments, activity

    var icon: String {
        switch self {
        case .notes: return "doc.text"
        case .children: return "list.bullet.indent"
        case .subtasks: return "checklist"
        case .attachments: return "paperclip"
        case .activity: return "clock.arrow.circlepath"
        }
    }

    var selectedIcon: String {
        switch self {
        case .notes: return "doc.text.fill"
        case .children: return "list.bullet.indent"
        case .subtasks: return "checklist"
        case .attachments: return "paperclip.circle.fill"
        case .activity: return "clock.arrow.circlepath"
        }
    }

    var label: String {
        switch self {
        case .notes: return "Notes"
        case .children: return "Children"
        case .subtasks: return "Subtasks"
        case .attachments: return "Files"
        case .activity: return "Activity"
        }
    }
}

struct TaskDetailView: View {
    @Bindable var task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Tag.sortOrder) private var allTags: [Tag]
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]

    @State private var selectedTab: TaskDetailTab = .notes
    @State private var newSubtaskTitle = ""
    @State private var showMoreSettings = false
    @State private var showDateEditor = false
    @State private var showNewTag = false
    @State private var newTagName = ""
    @State private var showSaveTemplate = false
    @State private var templateName = ""

    private var assignedCollaborator: Collaborator? {
        guard let id = task.assignedTo else { return nil }
        return collaborators.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Parent breadcrumb
            if let parent = task.parentTask {
                NavigationLink {
                    TaskDetailView(task: parent)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.turn.up.left")
                            .font(.caption)
                        Text(parent.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.06))
                }
                .accessibilityIdentifier("parent_task_link")
            }

            // Header card — always visible key info
            headerCard

            // Tab bar
            tabBar

            Divider()

            // Tab content (scrollable)
            Form {
                tabContent
            }
            .formStyle(.grouped)
        }
        .navigationTitle(task.isNote ? "Note" : "Task")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showMoreSettings = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showMoreSettings) {
            moreSettingsSheet
        }
        .sheet(isPresented: $showDateEditor) {
            dateEditorSheet
        }
        .alert("New Tag", isPresented: $showNewTag) {
            TextField("Tag name", text: $newTagName)
            Button("Cancel", role: .cancel) { newTagName = "" }
            Button("Create") { createAndAssignTag() }
        }
        .alert("Save as Template", isPresented: $showSaveTemplate) {
            TextField("Template name", text: $templateName)
            Button("Cancel", role: .cancel) { templateName = "" }
            Button("Save") {
                guard !templateName.isEmpty else { return }
                let template = TaskTemplate.from(task: task, name: templateName)
                modelContext.insert(template)
                templateName = ""
            }
        } message: {
            Text("Save this task's structure as a reusable template.")
        }
        .onDisappear {
            AutoSyncService.shared.notifyChange()
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: Status pill + Priority badge
            HStack {
                statusPill
                Spacer()
                priorityBadge
            }

            // Row 2: Title
            TextField("Task title", text: $task.title, axis: .vertical)
                .font(.title3.bold())
                .lineLimit(1...3)
                .accessibilityIdentifier("task_detail_title")
                .onChange(of: task.title) { task.updatedAt = Date() }

            // Row 3: Assignment + Due Date + List
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ASSIGNED")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                    assignmentRow
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DUE DATE")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        dueDateRow
                    }
                    listRow
                }
            }

            // Row 5: Tags
            tagsRow

            // Row 6: Progress bar (when subtasks exist or manual progress set)
            if !task.subtasks.isEmpty || task.manualProgress != nil {
                progressRow
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Progress Row

    private var progressRow: some View {
        HStack(spacing: 8) {
            ProgressView(value: Double(task.progress), total: 100)
                .tint(task.progress == 100 ? .green : .accentColor)

            Text("\(task.progress)%")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)

            if task.manualProgress != nil {
                Button {
                    task.manualProgress = nil
                    task.updatedAt = Date()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reset to auto-calculate from subtasks")
            }
        }
    }

    // MARK: - Status Pill

    private var statusPill: some View {
        Menu {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                Button {
                    let oldStatus = task.status
                    task.status = status
                    handleStatusChange(from: oldStatus)
                } label: {
                    Label(statusLabel(status), systemImage: statusIcon(status))
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor(task.status))
                    .frame(width: 8, height: 8)
                Text(statusLabel(task.status))
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor(task.status).opacity(0.12))
            .clipShape(Capsule())
            .foregroundStyle(statusColor(task.status))
        }
    }

    // MARK: - Priority Badge

    private var priorityBadge: some View {
        Menu {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Button {
                    let old = task.priority
                    task.priority = priority
                    task.updatedAt = Date()
                    if old != priority {
                        logActivity(action: .fieldChanged, field: "priority", oldValue: priorityLabel(old), newValue: priorityLabel(priority))
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(Color.priorityColor(priority))
                            .frame(width: 10, height: 10)
                        Text(priorityLabel(priority))
                    }
                }
            }
        } label: {
            if task.priority != .none {
                HStack(spacing: 4) {
                    Image(systemName: priorityIcon(task.priority))
                        .font(.system(size: 10, weight: .bold))
                    Text(priorityLabel(task.priority).uppercased())
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.priorityColor(task.priority).opacity(0.15))
                .foregroundStyle(Color.priorityColor(task.priority))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "flag")
                        .font(.caption)
                    Text("Priority")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Assignment Row

    private var assignmentRow: some View {
        Menu {
            ForEach(sortedCollaborators) { person in
                Button {
                    let oldName = task.assignedToName
                    task.assignedTo = person.id
                    task.assignedToName = person.name
                    task.updatedAt = Date()
                    logActivity(action: .assigned, oldValue: oldName, newValue: person.name)
                } label: {
                    HStack {
                        Text(person.name)
                        if person.isCurrentUser { Text("(You)") }
                        if task.assignedTo == person.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            if task.assignedTo != nil {
                Divider()
                Button("Unassign", role: .destructive) {
                    let oldName = task.assignedToName
                    task.assignedTo = nil
                    task.assignedToName = nil
                    task.updatedAt = Date()
                    logActivity(action: .assigned, oldValue: oldName)
                }
            }
        } label: {
            HStack(spacing: -6) {
                if let person = assignedCollaborator {
                    ZStack {
                        Circle()
                            .fill(Color(hex: person.color))
                            .frame(width: 32, height: 32)
                        Text(person.initials)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                // Add / change button
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Due Date Row

    private var dueDateRow: some View {
        Button {
            if task.dueDate == nil {
                task.dueDate = Calendar.current.startOfDay(for: Date())
                task.updatedAt = Date()
            }
            showDateEditor = true
        } label: {
            if let dueDate = task.dueDate {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(formattedDueDate(dueDate))
                            .font(.subheadline.weight(.medium))
                        if let dueTime = task.dueTime {
                            Text(formattedTime(dueTime))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Image(systemName: task.timePreference.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(timePreferenceColor(task.timePreference))
                }
                .foregroundStyle(isDueDateOverdue ? .red : .primary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.caption)
                    Text("Set date")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - List Row

    private var listRow: some View {
        Menu {
            Button("None") {
                let oldName = task.list?.name
                task.list = nil
                task.section = nil
                task.updatedAt = Date()
                logActivity(action: .moved, oldValue: oldName)
            }
            ForEach(lists) { list in
                Button {
                    let oldName = task.list?.name
                    task.list = list
                    task.section = nil
                    task.updatedAt = Date()
                    task.assignListToDescendants(list)
                    logActivity(action: .moved, oldValue: oldName, newValue: list.name)
                } label: {
                    Label(list.name, systemImage: list.icon)
                }
            }
        } label: {
            if let list = task.list {
                HStack(spacing: 6) {
                    Image(systemName: list.icon)
                        .font(.caption)
                        .foregroundStyle(Color(hex: list.color))
                    Text(list.name)
                        .font(.subheadline)
                    if let section = task.section {
                        Text("›")
                            .foregroundStyle(.tertiary)
                        Text(section.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus")
                        .font(.caption)
                    Text("Add to list")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tags Row

    private var tagsRow: some View {
        FlowLayout(spacing: 6) {
            ForEach(task.tags.sorted(by: { $0.sortOrder < $1.sortOrder })) { tag in
                TagChip(tag: tag, isSelected: true) {
                    task.tags.removeAll { $0.id == tag.id }
                    task.updatedAt = Date()
                    logActivity(action: .tagRemoved, oldValue: tag.name)
                }
            }

            addTagButton
        }
    }

    private var addTagButton: some View {
        Menu {
            let assignedIds = Set(task.tags.map(\.id))
            ForEach(allTags.filter { !assignedIds.contains($0.id) }) { tag in
                Button {
                    task.tags.append(tag)
                    task.updatedAt = Date()
                    logActivity(action: .tagAdded, newValue: tag.name)
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(hex: tag.color))
                            .frame(width: 10, height: 10)
                        Text(tag.name)
                    }
                }
            }
            Divider()
            Button("New Tag...") { showNewTag = true }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 10))
                if task.tags.isEmpty {
                    Text("Add tag")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(TaskDetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 16))
                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab_\(tab.rawValue)")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .notes:
            notesTab
        case .children:
            childrenTab
        case .subtasks:
            subtasksTab
        case .attachments:
            AttachmentsSectionView(task: task)
        case .activity:
            activityTab
        }
    }

    // MARK: - Notes Tab

    @ViewBuilder
    private var notesTab: some View {
        Section {
            MarkdownEditorView(text: $task.taskDescription)
                .onChange(of: task.taskDescription) { task.updatedAt = Date() }
        }
    }

    // MARK: - Children Tab

    @ViewBuilder
    private var childrenTab: some View {
        ChildTasksSectionView(task: task)
    }

    // MARK: - Subtasks Tab

    @ViewBuilder
    private var subtasksTab: some View {
        Section {
            ForEach(task.subtasks.sorted(by: { $0.sortOrder < $1.sortOrder })) { subtask in
                SubtaskRowView(subtask: subtask) { sub, completed in
                    logActivity(
                        action: completed ? .subtaskCompleted : .subtaskUncompleted,
                        newValue: sub.title
                    )
                }
            }
            .onDelete { offsets in
                let sorted = task.subtasks.sorted(by: { $0.sortOrder < $1.sortOrder })
                for index in offsets {
                    let subtask = sorted[index]
                    logActivity(action: .fieldChanged, field: "subtask", oldValue: subtask.title)
                    modelContext.delete(subtask)
                }
            }

            HStack {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
                TextField("Add subtask", text: $newSubtaskTitle)
                    .accessibilityIdentifier("add_subtask_field")
                    .onSubmit { addSubtask() }
            }
        } header: {
            subtaskSectionHeader
        }
    }

    // MARK: - Activity Tab

    @ViewBuilder
    private var activityTab: some View {
        Section("Collaboration") {
            NavigationLink {
                ActivityLogView(task: task)
            } label: {
                HStack {
                    Label("Activity & Comments", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    if !task.activityLog.isEmpty {
                        let commentCount = task.activityLog.filter { $0.isComment }.count
                        let eventCount = task.activityLog.count - commentCount
                        HStack(spacing: 6) {
                            if commentCount > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "text.bubble")
                                        .font(.caption2)
                                    Text("\(commentCount)")
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }
                            if eventCount > 0 {
                                Text("\(eventCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }

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

    // MARK: - Date Editor Sheet

    private var dateEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Due Date", isOn: Binding(
                        get: { task.dueDate != nil },
                        set: { enabled in
                            if enabled {
                                task.dueDate = Calendar.current.startOfDay(for: Date())
                                task.updatedAt = Date()
                                logActivity(action: .fieldChanged, field: "due date", newValue: formattedDueDate(task.dueDate!))
                            } else {
                                let old = task.dueDate.map { formattedDueDate($0) }
                                task.dueDate = nil
                                task.dueTime = nil
                                task.updatedAt = Date()
                                logActivity(action: .fieldChanged, field: "due date", oldValue: old)
                            }
                        }
                    ))

                    if let dueDate = task.dueDate {
                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: { dueDate },
                                set: {
                                    task.dueDate = Calendar.current.startOfDay(for: $0)
                                    task.updatedAt = Date()
                                    NotificationService.shared.scheduleReminders(for: task)
                                }
                            ),
                            displayedComponents: [.date]
                        )

                        Picker("When", selection: $task.timePreference) {
                            ForEach(TimePreference.allCases, id: \.self) { pref in
                                Label(pref.label, systemImage: pref.icon).tag(pref)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: task.timePreference) { _, newValue in
                            task.updatedAt = Date()
                            logActivity(action: .fieldChanged, field: "time preference", newValue: newValue.label)
                        }

                        Toggle("Specific Time", isOn: Binding(
                            get: { task.dueTime != nil },
                            set: { enabled in
                                task.dueTime = enabled ? Date() : nil
                                task.updatedAt = Date()
                                logActivity(action: .fieldChanged, field: "specific time", newValue: enabled ? "on" : "off")
                            }
                        ))

                        if let dueTime = task.dueTime {
                            DatePicker(
                                "Time",
                                selection: Binding(
                                    get: { dueTime },
                                    set: {
                                        task.dueTime = $0
                                        task.updatedAt = Date()
                                        NotificationService.shared.scheduleReminders(for: task)
                                    }
                                ),
                                displayedComponents: [.hourAndMinute]
                            )
                        }
                    }
                }

                // Quick date buttons
                Section("Quick Set") {
                    HStack(spacing: 12) {
                        quickDateButton("Today", date: Date())
                        quickDateButton("Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                        quickDateButton("Next Week", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date())
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .navigationTitle("Due Date")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDateEditor = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func quickDateButton(_ label: String, date: Date) -> some View {
        Button(label) {
            let startOfDay = Calendar.current.startOfDay(for: date)
            task.dueDate = startOfDay
            task.updatedAt = Date()
            NotificationService.shared.scheduleReminders(for: task)
            logActivity(action: .fieldChanged, field: "due date", newValue: formattedDueDate(startOfDay))
        }
    }

    // MARK: - More Settings Sheet

    private var moreSettingsSheet: some View {
        NavigationStack {
            Form {
                // Section picker
                if let currentList = task.list, !currentList.sections.isEmpty {
                    Section("Section") {
                        Picker("Section", selection: Binding(
                            get: { task.section },
                            set: { newSection in
                                let old = task.section?.name
                                task.section = newSection
                                task.updatedAt = Date()
                                logActivity(action: .fieldChanged, field: "section", oldValue: old, newValue: newSection?.name)
                            }
                        )) {
                            Text("None").tag(nil as ListSection?)
                            ForEach(currentList.sections.sorted(by: { $0.sortOrder < $1.sortOrder })) { section in
                                Text(section.name).tag(section as ListSection?)
                            }
                        }
                    }
                }

                // Parent task
                ParentTaskPickerView(task: task)

                // Recurrence
                RecurrencePickerView(task: task)

                // Start date
                Section("Start Date") {
                    Toggle("Start Date", isOn: Binding(
                        get: { task.startDate != nil },
                        set: { enabled in
                            if enabled {
                                task.startDate = task.dueDate ?? Date()
                                task.updatedAt = Date()
                                logActivity(action: .fieldChanged, field: "start date", newValue: "set")
                            } else {
                                task.startDate = nil
                                task.updatedAt = Date()
                                logActivity(action: .fieldChanged, field: "start date", oldValue: "cleared")
                            }
                        }
                    ))
                    if let startDate = task.startDate {
                        DatePicker(
                            "Start",
                            selection: Binding(
                                get: { startDate },
                                set: { task.startDate = $0; task.updatedAt = Date() }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Reminders
                remindersSection

                // Nudge
                nudgeSection

                // Location
                Section("Location") {
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
                            Label("Add Location Reminder", systemImage: "mappin.and.ellipse")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Progress
                Section("Progress") {
                    HStack {
                        Text("Progress")
                        Spacer()
                        Text("\(task.progress)%")
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(task.manualProgress ?? task.progress) },
                            set: { task.manualProgress = Int($0); task.updatedAt = Date() }
                        ),
                        in: 0...100,
                        step: 5
                    )

                    if task.manualProgress != nil {
                        Button("Reset to Auto") {
                            task.manualProgress = nil
                            task.updatedAt = Date()
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                // Duplicate & Template
                Section {
                    Button {
                        let copy = task.duplicate(context: modelContext)
                        logActivity(action: .fieldChanged, field: "duplicate", newValue: copy.id.uuidString)
                        showMoreSettings = false
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    Button {
                        showSaveTemplate = true
                    } label: {
                        Label("Save as Template", systemImage: "doc.badge.plus")
                    }
                }

                // Convert & actions
                Section {
                    Button {
                        let targetType = task.isNote ? "task" : "note"
                        if task.isNote {
                            task.convertToTask()
                        } else {
                            task.convertToNote()
                        }
                        logActivity(action: .converted, newValue: targetType)
                        showMoreSettings = false
                    } label: {
                        Label(
                            task.isNote ? "Convert to Task" : "Convert to Note",
                            systemImage: task.isNote ? "checklist" : "doc.text"
                        )
                    }
                }
            }
            .navigationTitle("More Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showMoreSettings = false }
                }
            }
        }
    }

    @ViewBuilder
    private var remindersSection: some View {
        if task.dueDate != nil {
            Section("Reminders") {
                ForEach(Array(task.reminderOffsets.enumerated()), id: \.offset) { index, offset in
                    HStack {
                        Image(systemName: "bell")
                            .foregroundStyle(.secondary)
                        Text(reminderLabel(offset))
                        Spacer()
                        Button(role: .destructive) {
                            let label = reminderLabel(offset)
                            task.reminderOffsets.remove(at: index)
                            task.updatedAt = Date()
                            NotificationService.shared.scheduleReminders(for: task)
                            logActivity(action: .reminderRemoved, oldValue: label)
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
    }

    @ViewBuilder
    private var nudgeSection: some View {
        Section("Nudge Reminder") {
            Toggle("Set Reminder", isOn: Binding(
                get: { task.nudgeDate != nil },
                set: { enabled in
                    if enabled {
                        task.nudgeDate = Date().addingTimeInterval(3600)
                        NotificationService.shared.scheduleNudge(for: task)
                        logActivity(action: .fieldChanged, field: "nudge reminder", newValue: "enabled")
                    } else {
                        task.nudgeDate = nil
                        NotificationService.shared.cancelNudge(for: task)
                        logActivity(action: .fieldChanged, field: "nudge reminder", oldValue: "disabled")
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
    }

    // MARK: - Subtask Header

    @ViewBuilder
    private var subtaskSectionHeader: some View {
        let total = task.subtasks.count
        let done = task.subtasks.filter(\.isCompleted).count

        HStack {
            Text("Subtasks")
            if total > 0 {
                Spacer()
                Text("\(Int(Double(done) / Double(total) * 100))%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(done == total ? .green : .secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)
                        Capsule()
                            .fill(done == total ? .green : .blue)
                            .frame(width: max(0, geo.size.width * (Double(done) / Double(total))), height: 4)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(width: 60, height: 12)
            }
        }
    }

    // MARK: - Helpers

    private var currentUser: Collaborator? {
        collaborators.first { $0.isCurrentUser }
    }

    private func logActivity(
        action: ActivityAction,
        field: String? = nil,
        oldValue: String? = nil,
        newValue: String? = nil
    ) {
        let entry = ActivityEntry(
            action: action,
            field: field,
            oldValue: oldValue,
            newValue: newValue,
            authorName: currentUser?.name ?? "You",
            authorId: currentUser?.id ?? UUID(),
            task: task
        )
        task.activityLog.append(entry)
        modelContext.insert(entry)
    }

    private var sortedCollaborators: [Collaborator] {
        var result: [Collaborator] = []
        if let current = collaborators.first(where: { $0.isCurrentUser }) {
            result.append(current)
        }
        result.append(contentsOf: collaborators.filter { !$0.isCurrentUser })
        return result
    }

    private func handleStatusChange(from oldStatus: TaskStatus) {
        guard task.status != oldStatus else { return }
        if task.status == .done {
            logActivity(action: .completed)
            task.completedAt = Date()
            NotificationService.shared.cancelReminders(for: task)
            RecurrenceService.shared.handleCompletion(task: task, context: modelContext)
            TriggerEngine.shared.handleTaskCompletion(task: task, context: modelContext)
        } else if task.status == .todo {
            logActivity(action: .reopened)
            task.completedAt = nil
            NotificationService.shared.scheduleReminders(for: task)
        } else {
            logActivity(action: .wontDo)
            NotificationService.shared.cancelReminders(for: task)
        }
        TriggerEngine.shared.handleEvent(.statusChanged, task: task, context: modelContext)
        task.updatedAt = Date()
    }

    private func addSubtask() {
        guard !newSubtaskTitle.isEmpty else { return }
        let subtask = Subtask(title: newSubtaskTitle, sortOrder: task.subtasks.count)
        subtask.task = task
        task.subtasks.append(subtask)
        task.updatedAt = Date()
        logActivity(action: .subtaskAdded, newValue: newSubtaskTitle)
        newSubtaskTitle = ""
    }

    private func createAndAssignTag() {
        guard !newTagName.isEmpty else { return }
        let tag = Tag(name: newTagName, sortOrder: allTags.count)
        modelContext.insert(tag)
        task.tags.append(tag)
        task.updatedAt = Date()
        logActivity(action: .tagAdded, newValue: newTagName)
        newTagName = ""
    }

    private func statusLabel(_ status: TaskStatus) -> String {
        switch status {
        case .todo: return "To Do"
        case .done: return "Done"
        case .wontDo: return "Won't Do"
        }
    }

    private func statusIcon(_ status: TaskStatus) -> String {
        switch status {
        case .todo: return "circle"
        case .done: return "checkmark.circle.fill"
        case .wontDo: return "xmark.circle"
        }
    }

    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .todo: return .blue
        case .done: return .green
        case .wontDo: return .secondary
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

    private func priorityIcon(_ priority: TaskPriority) -> String {
        switch priority {
        case .none: return "flag"
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "exclamationmark"
        }
    }

    private func timePreferenceColor(_ pref: TimePreference) -> Color {
        switch pref {
        case .anytime: return .secondary
        case .daytime: return .orange
        case .nighttime: return .indigo
        }
    }

    private var isDueDateOverdue: Bool {
        guard let due = task.dueDate, task.status == .todo else { return false }
        return due < Calendar.current.startOfDay(for: Date())
    }

    private func formattedDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func addReminder(_ offset: Int) {
        if !task.reminderOffsets.contains(offset) {
            task.reminderOffsets.append(offset)
            task.reminderOffsets.sort(by: >)
            task.updatedAt = Date()
            NotificationService.shared.scheduleReminders(for: task)
            logActivity(action: .reminderAdded, newValue: reminderLabel(offset))
        }
    }

    private func reminderLabel(_ offset: Int) -> String {
        let absVal = abs(offset)
        if absVal == 0 { return "At time of event" }
        if absVal < 3600 { return "\(absVal / 60) min before" }
        if absVal < 86400 { return "\(absVal / 3600) hour\(absVal / 3600 == 1 ? "" : "s") before" }
        return "\(absVal / 86400) day\(absVal / 86400 == 1 ? "" : "s") before"
    }
}

// MARK: - SubtaskRowView

struct SubtaskRowView: View {
    @Bindable var subtask: Subtask
    var onToggle: ((Subtask, Bool) -> Void)?
    @State private var showNotes = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Button {
                    subtask.isCompleted.toggle()
                    onToggle?(subtask, subtask.isCompleted)
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
