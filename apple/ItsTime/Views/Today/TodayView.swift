import SwiftUI
import SwiftData

struct TodayView: View {
    @Binding var selectedTask: TaskItem?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @Query(sort: \Habit.sortOrder) private var allHabits: [Habit]

    @Query(filter: #Predicate<Collaborator> { $0.isCurrentUser == true })
    private var currentUsers: [Collaborator]

    @State private var showCompleted = false
    @State private var inboxExpanded = true
    @State private var showRetrospective = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date())
    }

    private var overdueTasks: [TaskItem] {
        let now = Calendar.current.startOfDay(for: Date())
        return allTasks.filter { task in
            guard task.status == .todo, !task.isChildTask, let due = task.dueDate else { return false }
            return due < now
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var todayTasks: [TaskItem] {
        allTasks.filter { task in
            guard task.status == .todo, !task.isChildTask, let due = task.dueDate else { return false }
            return Calendar.current.isDateInToday(due)
        }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var noDueDateTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo && !$0.isChildTask && $0.dueDate == nil && $0.list?.isInbox == true }
    }

    private var todayHabits: [Habit] {
        let today = Date()
        return allHabits.filter { !$0.isArchived && $0.shouldTrackOn(today) }
    }

    private var pendingHabits: [Habit] {
        let today = Date()
        return todayHabits.filter { !$0.isCompletedOn(today) }
    }

    private var completedHabits: [Habit] {
        let today = Date()
        return todayHabits.filter { $0.isCompletedOn(today) }
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
            // Greeting header + productivity card
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        if let user = currentUsers.first {
                            Text("\(greeting), \(user.name.split(separator: " ").first.map(String.init) ?? user.name)")
                                .font(.title2.bold())
                        } else {
                            Text(greeting)
                                .font(.title2.bold())
                        }
                        Text(dateString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Productivity summary card
                    let totalToday = todayTasks.count + overdueTasks.count + completedTodayTasks.count
                    if totalToday > 0 {
                        let doneCount = completedTodayTasks.count
                        let fraction = Double(doneCount) / Double(totalToday)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(taskSummaryMessage(done: doneCount, total: totalToday))
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(doneCount)/\(totalToday)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(.white.opacity(0.25))
                                        .frame(height: 6)
                                    Capsule()
                                        .fill(.white)
                                        .frame(width: max(0, geo.size.width * fraction), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(14)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: fraction >= 1.0
                                    ? [.green, .mint]
                                    : [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
            }

            if overdueTasks.isEmpty && todayTasks.isEmpty && noDueDateTasks.isEmpty && pendingHabits.isEmpty {
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
                        HierarchicalTaskRowView(task: task, depth: 0)
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
                        HierarchicalTaskRowView(task: task, depth: 0)
                    }
                }
            }

            // Habits for today
            if !todayHabits.isEmpty {
                Section {
                    ForEach(pendingHabits) { habit in
                        TodayHabitRow(habit: habit)
                    }
                    if !completedHabits.isEmpty {
                        ForEach(completedHabits) { habit in
                            TodayHabitRow(habit: habit)
                        }
                    }
                } header: {
                    HStack {
                        Text("Habits")
                        Spacer()
                        Text("\(completedHabits.count)/\(todayHabits.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !noDueDateTasks.isEmpty {
                Section {
                    if noDueDateTasks.count > 5 {
                        DisclosureGroup(isExpanded: $inboxExpanded) {
                            ForEach(noDueDateTasks) { task in
                                HierarchicalTaskRowView(task: task, depth: 0)
                            }
                        } label: {
                            Text("Inbox (\(noDueDateTasks.count))")
                        }
                        .accessibilityIdentifier("inbox_disclosure")
                    } else {
                        ForEach(noDueDateTasks) { task in
                            HierarchicalTaskRowView(task: task, depth: 0)
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

    @ViewBuilder
    private func taskDestination(_ task: TaskItem) -> some View {
        if task.isNote {
            NoteEditorView(note: task)
        } else {
            TaskDetailView(task: task)
        }
    }

    private func taskSummaryMessage(done: Int, total: Int) -> String {
        if done == 0 { return "\(total) tasks to complete today" }
        if done == total { return "All done! Great job" }
        return "\(total - done) tasks remaining"
    }
}

// MARK: - Today Habit Row

struct TodayHabitRow: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext

    private let today = Date()

    private var isCompleted: Bool {
        habit.isCompletedOn(today)
    }

    private var todayValue: Int {
        habit.valueOn(today)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Check-in button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if habit.isCumulative {
                        // Add one more
                        let entry = HabitEntry(date: today, value: 1)
                        entry.habit = habit
                        habit.entries.append(entry)
                        modelContext.insert(entry)
                    } else {
                        // Toggle
                        if isCompleted {
                            // Remove today's entries
                            let calendar = Calendar.current
                            let toRemove = habit.entries.filter { calendar.isDate($0.date, inSameDayAs: today) }
                            for entry in toRemove {
                                modelContext.delete(entry)
                            }
                        } else {
                            let entry = HabitEntry(date: today, value: 1)
                            entry.habit = habit
                            habit.entries.append(entry)
                            modelContext.insert(entry)
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.color).opacity(isCompleted ? 1 : 0.15))
                        .frame(width: 32, height: 32)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: habit.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: habit.color))
                    }
                }
            }
            .buttonStyle(.plain)

            // Name + info
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if habit.currentStreak > 0 {
                        Label("\(habit.currentStreak)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if habit.isCumulative {
                        Text("\(todayValue)/\(habit.goalCount)")
                            .font(.caption)
                            .foregroundStyle(isCompleted ? .green : .secondary)
                    }
                }
            }

            Spacer()

            // Cumulative progress or simple indicator
            if habit.isCumulative && !isCompleted {
                let fraction = Double(todayValue) / Double(habit.goalCount)
                ZStack {
                    Circle()
                        .stroke(Color(hex: habit.color).opacity(0.2), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: max(0, fraction))
                        .stroke(Color(hex: habit.color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 28, height: 28)
            }
        }
        .padding(.vertical, 2)
    }
}
