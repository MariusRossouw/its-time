import SwiftUI
import SwiftData

struct TriggerEditorView: View {
    var trigger: Trigger?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    @State private var name = ""
    @State private var triggerType: TriggerType = .event
    @State private var eventType: TriggerEventType = .taskCompleted
    @State private var matchAll = true
    @State private var conditions: [TriggerCondition] = []
    @State private var actions: [TriggerAction] = []

    // Time-based
    @State private var scheduledTime = Date()
    @State private var useRelativeOffset = false
    @State private var relativeMinutes = 15

    // Geolocation
    @State private var locationName = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var radiusMeters = 200.0
    @State private var geoDirection: GeoDirection = .enter

    // Chain
    @State private var sourceTaskId: UUID?

    private var isEditing: Bool { trigger != nil }

    var body: some View {
        let content = Form {
            Section("Name") {
                TextField("Automation name", text: $name)
            }

            Section("When") {
                Picker("Trigger Type", selection: $triggerType) {
                    ForEach(TriggerType.allCases, id: \.self) { type in
                        Label(type.label, systemImage: type.icon).tag(type)
                    }
                }

                triggerConfig
            }

            Section {
                Picker("Match", selection: $matchAll) {
                    Text("All conditions (AND)").tag(true)
                    Text("Any condition (OR)").tag(false)
                }
            } header: {
                Text("Conditions (optional)")
            }

            Section {
                ForEach($conditions) { $cond in
                    conditionRow(cond: $cond)
                }
                .onDelete { offsets in conditions.remove(atOffsets: offsets) }

                Button("Add Condition", systemImage: "plus.circle") {
                    conditions.append(TriggerCondition(field: .any, op: "equals", value: ""))
                }
            }

            Section("Then") {
                ForEach($actions) { $action in
                    actionRow(action: $action)
                }
                .onDelete { offsets in actions.remove(atOffsets: offsets) }

                Button("Add Action", systemImage: "plus.circle") {
                    actions.append(TriggerAction(actionType: .notify, value: ""))
                }
            }
        }

        if isEditing {
            content
                .navigationTitle("Edit Automation")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .bold()
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .onAppear { loadTrigger() }
        } else {
            NavigationStack {
                content
                    .navigationTitle("New Automation")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") { save() }
                                .bold()
                                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
            }
        }
    }

    // MARK: - Trigger Config

    @ViewBuilder
    private var triggerConfig: some View {
        switch triggerType {
        case .event:
            Picker("Event", selection: $eventType) {
                ForEach(TriggerEventType.allCases, id: \.self) { ev in
                    Text(ev.label).tag(ev)
                }
            }

        case .timeBased:
            Toggle("Relative to due date", isOn: $useRelativeOffset)
            if useRelativeOffset {
                Stepper("\(relativeMinutes) min before due", value: $relativeMinutes, in: 5...1440, step: 5)
            } else {
                DatePicker("At time", selection: $scheduledTime)
            }

        case .geolocation:
            TextField("Location name", text: $locationName)
            HStack {
                TextField("Latitude", text: $latitude)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                TextField("Longitude", text: $longitude)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
            Stepper("Radius: \(Int(radiusMeters))m", value: $radiusMeters, in: 50...5000, step: 50)
            Picker("Direction", selection: $geoDirection) {
                ForEach(GeoDirection.allCases, id: \.self) { dir in
                    Text(dir.label).tag(dir)
                }
            }

        case .chain:
            let todoTasks = allTasks.filter { $0.status == .todo && !$0.isNote }
            Picker("When this task completes", selection: $sourceTaskId) {
                Text("Select a task").tag(nil as UUID?)
                ForEach(todoTasks) { task in
                    Text(task.title).tag(task.id as UUID?)
                }
            }
        }
    }

    // MARK: - Condition Row

    @ViewBuilder
    private func conditionRow(cond: Binding<TriggerCondition>) -> some View {
        HStack {
            Picker("Field", selection: cond.field) {
                ForEach(TriggerConditionField.allCases, id: \.self) { f in
                    Text(f.label).tag(f)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 120)

            if cond.wrappedValue.field != .any {
                Picker("Op", selection: cond.op) {
                    Text("is").tag("equals")
                    Text("is not").tag("notEquals")
                }
                .labelsHidden()
                .frame(maxWidth: 80)

                conditionValueField(cond: cond)
            }
        }
    }

    @ViewBuilder
    private func conditionValueField(cond: Binding<TriggerCondition>) -> some View {
        switch cond.wrappedValue.field {
        case .priority:
            Picker("", selection: cond.value) {
                ForEach(TaskPriority.allCases, id: \.rawValue) { p in
                    Text(p.rawValue.capitalized).tag(p.rawValue)
                }
            }.labelsHidden()
        case .list:
            Picker("", selection: cond.value) {
                ForEach(lists) { list in Text(list.name).tag(list.name) }
            }.labelsHidden()
        case .tag:
            Picker("", selection: cond.value) {
                ForEach(tags) { tag in Text(tag.name).tag(tag.name) }
            }.labelsHidden()
        case .title:
            TextField("Contains...", text: cond.value)
        case .any:
            EmptyView()
        }
    }

    // MARK: - Action Row

    @ViewBuilder
    private func actionRow(action: Binding<TriggerAction>) -> some View {
        VStack(spacing: 8) {
            Picker("Action", selection: action.actionType) {
                ForEach(TriggerActionType.allCases, id: \.self) { at in
                    Label(at.label, systemImage: at.icon).tag(at)
                }
            }

            actionValueField(action: action)
        }
    }

    @ViewBuilder
    private func actionValueField(action: Binding<TriggerAction>) -> some View {
        switch action.wrappedValue.actionType {
        case .notify:
            TextField("Notification message", text: action.value)
        case .createTask:
            TextField("New task title", text: action.value)
        case .moveToList:
            Picker("List", selection: action.value) {
                ForEach(lists) { list in Text(list.name).tag(list.name) }
            }.labelsHidden()
        case .changePriority:
            Picker("Priority", selection: action.value) {
                ForEach(TaskPriority.allCases, id: \.rawValue) { p in
                    Text(p.rawValue.capitalized).tag(p.rawValue)
                }
            }.labelsHidden()
        case .addTag:
            Picker("Tag", selection: action.value) {
                ForEach(tags) { tag in Text(tag.name).tag(tag.name) }
            }.labelsHidden()
        case .startTimer:
            Text("Will start the focus timer")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .setStatus:
            Picker("Status", selection: action.value) {
                Text("To Do").tag("todo")
                Text("Done").tag("done")
                Text("Won't Do").tag("wontDo")
            }.labelsHidden()
        }
    }

    // MARK: - Load / Save

    private func loadTrigger() {
        guard let trigger else { return }
        name = trigger.name
        triggerType = trigger.triggerType
        eventType = trigger.eventType ?? .taskCompleted
        matchAll = trigger.matchAll
        conditions = trigger.conditions
        actions = trigger.actions
        if let time = trigger.scheduledTime { scheduledTime = time }
        if let offset = trigger.relativeOffset {
            useRelativeOffset = true
            relativeMinutes = abs(offset) / 60
        }
        if let lat = trigger.latitude { latitude = String(lat) }
        if let lon = trigger.longitude { longitude = String(lon) }
        if let r = trigger.radiusMeters { radiusMeters = r }
        locationName = trigger.locationName ?? ""
        geoDirection = trigger.geoDirection ?? .enter
        sourceTaskId = trigger.sourceTaskId
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let target = trigger ?? Trigger(name: trimmed)

        target.name = trimmed
        target.triggerType = triggerType
        target.matchAll = matchAll
        target.conditions = conditions
        target.actions = actions
        target.updatedAt = Date()

        switch triggerType {
        case .event:
            target.eventType = eventType
        case .timeBased:
            if useRelativeOffset {
                target.relativeOffset = -(relativeMinutes * 60)
                target.scheduledTime = nil
            } else {
                target.scheduledTime = scheduledTime
                target.relativeOffset = nil
            }
        case .geolocation:
            target.latitude = Double(latitude)
            target.longitude = Double(longitude)
            target.radiusMeters = radiusMeters
            target.locationName = locationName
            target.geoDirection = geoDirection
        case .chain:
            target.sourceTaskId = sourceTaskId
        }

        if trigger == nil {
            modelContext.insert(target)
        }

        // Register geo monitoring if needed
        if triggerType == .geolocation {
            LocationTriggerService.shared.startMonitoring(trigger: target)
        }

        dismiss()
    }
}
