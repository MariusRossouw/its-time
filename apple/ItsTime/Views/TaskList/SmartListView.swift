import SwiftUI
import SwiftData

struct SmartListView: View {
    let smartList: SmartList
    @Binding var selectedTask: TaskItem?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]

    @State private var showCompleted = false

    private var shouldGroupByDay: Bool {
        smartList == .all || smartList == .next7Days
    }

    private var groupedTasks: [(key: String, tasks: [TaskItem])] {
        let calendar = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"

        var groups: [(key: String, tasks: [TaskItem])] = []
        var buckets: [String: [TaskItem]] = [:]
        var order: [String] = []

        // Tasks with dates, sorted by date
        let dated = filteredTasks.filter { $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        let undated = filteredTasks.filter { $0.dueDate == nil }

        for task in dated {
            let date = task.dueDate!
            let label: String
            if calendar.isDateInToday(date) {
                label = "Today"
            } else if calendar.isDateInTomorrow(date) {
                label = "Tomorrow"
            } else if calendar.isDateInYesterday(date) {
                label = "Yesterday"
            } else {
                label = df.string(from: date)
            }
            if buckets[label] == nil {
                order.append(label)
                buckets[label] = []
            }
            buckets[label]?.append(task)
        }

        // Overdue tasks go to the front
        let overdueLabel = "Overdue"
        let overdue = dated.filter { task in
            guard let due = task.dueDate else { return false }
            return due < calendar.startOfDay(for: Date()) && !calendar.isDateInToday(due)
        }
        if !overdue.isEmpty {
            // Remove overdue tasks from their date buckets
            for task in overdue {
                let date = task.dueDate!
                let label: String
                if calendar.isDateInYesterday(date) {
                    label = "Yesterday"
                } else {
                    label = df.string(from: date)
                }
                buckets[label]?.removeAll { $0.id == task.id }
                if buckets[label]?.isEmpty == true {
                    buckets.removeValue(forKey: label)
                    order.removeAll { $0 == label }
                }
            }
            groups.append((key: overdueLabel, tasks: overdue))
        }

        for key in order {
            if let tasks = buckets[key], !tasks.isEmpty {
                groups.append((key: key, tasks: tasks))
            }
        }

        if !undated.isEmpty {
            groups.append((key: "No Date", tasks: undated))
        }

        return groups
    }

    private var currentUserId: UUID? {
        collaborators.first { $0.isCurrentUser }?.id
    }

    private var filteredTasks: [TaskItem] {
        let calendar = Calendar.current
        let now = Date()

        switch smartList {
        case .inbox:
            return allTasks.filter { $0.status == .todo && $0.list?.isInbox == true && !$0.isChildTask }
        case .today:
            return allTasks.filter { task in
                guard task.status == .todo, !task.isChildTask else { return false }
                guard let due = task.dueDate else { return false }
                return calendar.isDateInToday(due)
            }
        case .next7Days:
            let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
            return allTasks.filter { task in
                guard task.status == .todo, !task.isChildTask else { return false }
                guard let due = task.dueDate else { return false }
                return due >= calendar.startOfDay(for: now) && due <= weekFromNow
            }
        case .all:
            return allTasks.filter { $0.status == .todo && !$0.isChildTask && !$0.isNote }
        case .notes:
            return allTasks.filter { $0.status == .todo && $0.isNote }
        case .assignedToMe:
            guard let userId = currentUserId else { return [] }
            return allTasks.filter { $0.status == .todo && $0.assignedTo == userId && !$0.isChildTask }
        default:
            return []
        }
    }

    private var completedTasks: [TaskItem] {
        let calendar = Calendar.current
        let now = Date()

        switch smartList {
        case .inbox:
            return allTasks.filter { $0.status != .todo && $0.list?.isInbox == true }
        case .today:
            return allTasks.filter { task in
                guard task.status != .todo else { return false }
                guard let completed = task.completedAt else { return false }
                return calendar.isDateInToday(completed)
            }
        case .next7Days:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return allTasks.filter { task in
                guard task.status != .todo else { return false }
                guard let completed = task.completedAt else { return false }
                return completed >= weekAgo
            }
        case .all:
            return allTasks.filter { $0.status != .todo && !$0.isNote }
        case .notes:
            return allTasks.filter { $0.status != .todo && $0.isNote }
        case .assignedToMe:
            guard let userId = currentUserId else { return [] }
            return allTasks.filter { $0.status != .todo && $0.assignedTo == userId }
        default:
            return []
        }
    }

    var body: some View {
        List(selection: horizontalSizeClass == .compact ? nil : $selectedTask) {
            if filteredTasks.isEmpty {
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: emptyIcon)
                } description: {
                    Text(emptyDescription)
                }
                .listRowSeparator(.hidden)
            } else if shouldGroupByDay {
                ForEach(groupedTasks, id: \.key) { group in
                    Section {
                        ForEach(group.tasks) { task in
                            HierarchicalTaskRowView(task: task, depth: 0)
                        }
                    } header: {
                        Text(group.key)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(group.key == "Overdue" ? .red : .primary)
                    }
                }
            } else {
                ForEach(filteredTasks) { task in
                    HierarchicalTaskRowView(task: task, depth: 0)
                }
            }

            // Completed tasks section
            if showCompleted && !completedTasks.isEmpty {
                Section {
                    DisclosureGroup("Completed (\(completedTasks.count))") {
                        ForEach(completedTasks) { task in
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
        .listStyle(.plain)
        .navigationTitle(smartList.title)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    withAnimation { showCompleted.toggle() }
                } label: {
                    Label(
                        showCompleted ? "Hide Completed" : "Show Completed",
                        systemImage: showCompleted ? "eye.fill" : "eye.slash"
                    )
                }
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

    private var emptyTitle: String {
        switch smartList {
        case .inbox: return "Inbox is empty"
        case .today: return "Nothing due today"
        case .next7Days: return "Nothing upcoming"
        case .all: return "No tasks"
        case .notes: return "No notes"
        case .assignedToMe: return "Nothing assigned"
        default: return "No tasks"
        }
    }

    private var emptyIcon: String {
        switch smartList {
        case .inbox: return "tray"
        case .today: return "sun.max"
        case .next7Days: return "calendar"
        case .all: return "checkmark.circle"
        case .notes: return "doc.text"
        case .assignedToMe: return "person.circle"
        default: return "checklist"
        }
    }

    private var emptyDescription: String {
        switch smartList {
        case .inbox: return "New tasks without a list will appear here."
        case .today: return "Tasks due today will show up here."
        case .next7Days: return "Tasks due in the next 7 days will appear here."
        case .all: return "Create your first task to get started."
        case .notes: return "Create a note to get started."
        case .assignedToMe: return "Tasks assigned to you will appear here."
        default: return ""
        }
    }
}
