import SwiftUI
import SwiftData

struct TodayView: View {
    @Binding var selectedTask: TaskItem?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]

    @State private var showCompleted = false
    @State private var inboxExpanded = true
    @State private var showRetrospective = false

    private var overdueTasks: [TaskItem] {
        let now = Calendar.current.startOfDay(for: Date())
        return allTasks.filter { task in
            guard task.status == .todo, let due = task.dueDate else { return false }
            return due < now
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var todayTasks: [TaskItem] {
        allTasks.filter { task in
            guard task.status == .todo, let due = task.dueDate else { return false }
            return Calendar.current.isDateInToday(due)
        }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var noDueDateTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo && $0.dueDate == nil && $0.list?.isInbox == true }
    }

    private var completedTodayTasks: [TaskItem] {
        allTasks.filter { task in
            guard task.status != .todo else { return false }
            guard let completed = task.completedAt else { return false }
            return Calendar.current.isDateInToday(completed)
        }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        List(selection: horizontalSizeClass == .compact ? nil : $selectedTask) {
            if overdueTasks.isEmpty && todayTasks.isEmpty && noDueDateTasks.isEmpty {
                ContentUnavailableView {
                    Label("All Clear", systemImage: "sun.max.fill")
                } description: {
                    Text("Nothing due today. Enjoy your day!")
                }
                .listRowSeparator(.hidden)
            }

            if !overdueTasks.isEmpty {
                Section {
                    ForEach(overdueTasks) { task in
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

                            Button {
                                task.dueDate = Date()
                                task.updatedAt = Date()
                            } label: {
                                Label("Today", systemImage: "arrow.right")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("Overdue")
                            .foregroundStyle(.red)
                    }
                }
            }

            if !todayTasks.isEmpty {
                Section("Today") {
                    ForEach(todayTasks) { task in
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
                    }
                }
            }

            if !noDueDateTasks.isEmpty {
                Section {
                    if noDueDateTasks.count > 5 {
                        DisclosureGroup(isExpanded: $inboxExpanded) {
                            ForEach(noDueDateTasks) { task in
                                NavigationLink(value: task) {
                                    TaskRowView(task: task)
                                }
                                .tag(task)
                            }
                        } label: {
                            Text("Inbox (\(noDueDateTasks.count))")
                        }
                        .accessibilityIdentifier("inbox_disclosure")
                    } else {
                        ForEach(noDueDateTasks) { task in
                            NavigationLink(value: task) {
                                TaskRowView(task: task)
                            }
                            .tag(task)
                        }
                    }
                } header: {
                    if noDueDateTasks.count <= 5 {
                        Text("Inbox (no date)")
                    }
                }
            }

            // Completed today section
            if showCompleted && !completedTodayTasks.isEmpty {
                Section {
                    DisclosureGroup("Completed today (\(completedTodayTasks.count))") {
                        ForEach(completedTodayTasks) { task in
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
        .navigationTitle("Today")
        .accessibilityIdentifier("today_view")
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
                .accessibilityIdentifier("toggle_completed")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showRetrospective = true
                } label: {
                    Label("Daily Review", systemImage: "chart.bar.doc.horizontal")
                }
                .accessibilityIdentifier("daily_review_button")
            }
        }
        .sheet(isPresented: $showRetrospective) {
            DailyRetrospectiveView()
        }
    }
}
