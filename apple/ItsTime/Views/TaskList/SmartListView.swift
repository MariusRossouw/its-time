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

    private var currentUserId: UUID? {
        collaborators.first { $0.isCurrentUser }?.id
    }

    private var filteredTasks: [TaskItem] {
        let calendar = Calendar.current
        let now = Date()

        switch smartList {
        case .inbox:
            return allTasks.filter { $0.status == .todo && $0.list?.isInbox == true }
        case .today:
            return allTasks.filter { task in
                guard task.status == .todo else { return false }
                guard let due = task.dueDate else { return false }
                return calendar.isDateInToday(due)
            }
        case .next7Days:
            let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
            return allTasks.filter { task in
                guard task.status == .todo else { return false }
                guard let due = task.dueDate else { return false }
                return due >= calendar.startOfDay(for: now) && due <= weekFromNow
            }
        case .all:
            return allTasks.filter { $0.status == .todo }
        case .assignedToMe:
            guard let userId = currentUserId else { return [] }
            return allTasks.filter { $0.status == .todo && $0.assignedTo == userId }
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
            return allTasks.filter { $0.status != .todo }
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
            } else {
                ForEach(filteredTasks) { task in
                    NavigationLink(value: task) {
                        TaskRowView(task: task)
                    }
                    .tag(task)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            task.markDone()
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            // Completed tasks section
            if showCompleted && !completedTasks.isEmpty {
                Section {
                    DisclosureGroup("Completed (\(completedTasks.count))") {
                        ForEach(completedTasks) { task in
                            NavigationLink(value: task) {
                                TaskRowView(task: task)
                            }
                            .tag(task)
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
        .taskNavigationDestination()
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

    private var emptyTitle: String {
        switch smartList {
        case .inbox: return "Inbox is empty"
        case .today: return "Nothing due today"
        case .next7Days: return "Nothing upcoming"
        case .all: return "No tasks"
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
        case .assignedToMe: return "Tasks assigned to you will appear here."
        default: return ""
        }
    }
}
