import SwiftUI
import SwiftData

struct TaskListView: View {
    let list: TaskList
    @Binding var selectedTask: TaskItem?

    @Environment(\.modelContext) private var modelContext
    @State private var sortBy: SortOption = .manual
    @State private var showCompleted = false
    @State private var isEditing = false
    @State private var batchSelected: Set<TaskItem> = []
    @State private var showNewSection = false
    @State private var newSectionName = ""

    private var unsectionedTasks: [TaskItem] {
        sorted(list.tasks.filter { $0.status == .todo && !$0.isChildTask && $0.section == nil })
    }

    private var sortedSections: [ListSection] {
        list.sections.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var completedTasks: [TaskItem] {
        list.tasks.filter { $0.status != .todo }
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: isEditing ? $batchSelected : nil) {
                // Unsectioned tasks
                if !unsectionedTasks.isEmpty || sortedSections.isEmpty {
                    ForEach(unsectionedTasks) { task in
                        if isEditing {
                            TaskRowView(task: task).tag(task)
                        } else {
                            HierarchicalTaskRowView(task: task, depth: 0)
                        }
                    }
                    .onMove { from, to in
                        moveTasks(from: from, to: to)
                    }
                }

                // Sections
                ForEach(sortedSections) { section in
                    let sectionTasks = sorted(
                        list.tasks.filter { $0.status == .todo && !$0.isChildTask && $0.section?.id == section.id }
                    )
                    Section {
                        taskRows(sectionTasks)
                    } header: {
                        HStack {
                            Text(section.name)
                            Spacer()
                            Text("\(sectionTasks.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contextMenu {
                            Button("Rename", systemImage: "pencil") {
                                // Simple rename: reuse alert
                                newSectionName = section.name
                                showNewSection = true
                            }
                            Button("Delete Section", systemImage: "trash", role: .destructive) {
                                for task in section.tasks {
                                    task.section = nil
                                }
                                modelContext.delete(section)
                            }
                        }
                    }
                }

                // Completed
                if !completedTasks.isEmpty {
                    Section {
                        DisclosureGroup("Completed (\(completedTasks.count))", isExpanded: $showCompleted) {
                            ForEach(completedTasks) { task in
                                if isEditing {
                                    TaskRowView(task: task).tag(task)
                                } else {
                                    NavigationLink {
                                        taskDestination(task)
                                    } label: {
                                        TaskRowView(task: task)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            task.reopen()
                                        } label: {
                                            Label("Reopen", systemImage: "arrow.uturn.backward")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            #if os(iOS)
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            #endif

            if isEditing {
                BatchEditBar(selectedTasks: $batchSelected)
            }
        }
        .navigationTitle(list.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing { batchSelected.removeAll() }
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Select")
                    }

                    if !isEditing {
                        Menu {
                            Picker("Sort By", selection: $sortBy) {
                                ForEach(SortOption.allCases) { option in
                                    Text(option.label).tag(option)
                                }
                            }

                            Divider()

                            Button("Add Section", systemImage: "plus.rectangle") {
                                newSectionName = ""
                                showNewSection = true
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
            }
        }
        .alert("Section", isPresented: $showNewSection) {
            TextField("Section name", text: $newSectionName)
            Button("Cancel", role: .cancel) { newSectionName = "" }
            Button("Save") { createSection() }
        }
    }

    // MARK: - Task Rows

    @ViewBuilder
    private func taskRows(_ tasks: [TaskItem]) -> some View {
        ForEach(tasks) { task in
            if isEditing {
                TaskRowView(task: task).tag(task)
            } else {
                HierarchicalTaskRowView(task: task, depth: 0)
            }
        }
    }

    @ViewBuilder
    private func taskDestination(_ task: TaskItem) -> some View {
        if task.isNote {
            NoteEditorView(note: task)
        } else {
            TaskDetailView(task: task)
        }
    }

    // MARK: - Helpers

    private func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        switch sortBy {
        case .manual:
            return tasks.sorted { $0.sortOrder < $1.sortOrder }
        case .dueDate:
            return tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .priority:
            return tasks.sorted { $0.priority > $1.priority }
        case .title:
            return tasks.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        var mutable = unsectionedTasks
        mutable.move(fromOffsets: source, toOffset: destination)
        for (index, task) in mutable.enumerated() {
            task.sortOrder = index
            task.updatedAt = Date()
        }
        sortBy = .manual
    }

    private func createSection() {
        guard !newSectionName.isEmpty else { return }
        let section = ListSection(name: newSectionName, sortOrder: list.sections.count)
        section.list = list
        modelContext.insert(section)
        newSectionName = ""
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case manual, dueDate, priority, title

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: return "Manual"
        case .dueDate: return "Due Date"
        case .priority: return "Priority"
        case .title: return "Title"
        }
    }
}
