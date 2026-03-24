import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @State private var selectedSmartList: SmartList? = .today
    @State private var selectedList: TaskList?
    @State private var selectedTask: TaskItem?
    @State private var showQuickAdd = false
    @State private var showNewNote = false
    @State private var showNewHabit = false
    @State private var showAddMenu = false
    @State private var selectedCustomFilter: CustomFilter?
    @State private var selectedTab: AppTab = .today
    @State private var todayPath = NavigationPath()
    @State private var tasksPath = NavigationPath()
    @State private var chatPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    private var hasCurrentUser: Bool {
        collaborators.contains { $0.isCurrentUser }
    }

    var body: some View {
        if hasCurrentUser {
            mainContent
                .onAppear {
                    ensureInboxExists()
                    migrateToSyncProfiles()
                    AutoSyncService.shared.start(context: modelContext)
                    NotificationService.shared.scheduleAutoNudges(tasks: allTasks)
                }
                .onReceive(NotificationCenter.default.publisher(for: .taskMarkedDoneFromNotification)) { notification in
                    handleNotificationAction(notification) { $0.markDone() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .taskMarkedWontDoFromNotification)) { notification in
                    handleNotificationAction(notification) { $0.markWontDo() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .taskDeletedFromNotification)) { notification in
                    handleNotificationAction(notification) { task in
                        modelContext.delete(task)
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .sheet(isPresented: $showQuickAdd) {
                    QuickAddView()
                }
                .sheet(isPresented: $showNewNote) {
                    QuickAddNoteView()
                }
                .sheet(isPresented: $showNewHabit) {
                    NavigationStack {
                        HabitEditorView()
                    }
                }
        } else {
            OnboardingView()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        Group {
            #if os(macOS)
            macOSLayout
            #else
            if horizontalSizeClass == .compact {
                iPhoneLayout
            } else {
                iPadLayout
            }
            #endif
        }
    }

    // MARK: - iPhone: Tab bar + navigation stack

    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                Tab("Today", systemImage: "sun.max", value: .today) {
                    NavigationStack(path: $todayPath) {
                        TodayView(selectedTask: $selectedTask)
                    }
                }
                Tab("Tasks", systemImage: "checklist", value: .tasks) {
                    NavigationStack(path: $tasksPath) {
                        TaskListsView(
                            selectedSmartList: $selectedSmartList,
                            selectedList: $selectedList,
                            selectedTask: $selectedTask
                        )
                    }
                }
                Tab("Calendar", systemImage: "calendar", value: .calendar) {
                    CalendarContainerView()
                }
                Tab("Habits", systemImage: "leaf", value: .habits) {
                    HabitListView()
                }
                Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: .chat) {
                    NavigationStack(path: $chatPath) {
                        ChatListView()
                    }
                }
                Tab("Focus", systemImage: "timer", value: .focus) {
                    FocusTimerView()
                }
                Tab("Settings", systemImage: "gear", value: .settings) {
                    NavigationStack(path: $settingsPath) {
                        SettingsView()
                    }
                }
            }
            .onChange(of: selectedTab) {
                // Reset navigation to root when switching tabs
                todayPath = NavigationPath()
                tasksPath = NavigationPath()
                chatPath = NavigationPath()
                settingsPath = NavigationPath()
            }

            // Floating add button — always visible above tab bar
            floatingAddButton
                .padding(.bottom, 60)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "itstime" else { return }
        switch url.host {
        case "add-task":
            showQuickAdd = true
        case "add-note":
            showNewNote = true
        case "add-habit":
            showNewHabit = true
        default:
            break
        }
    }

    private var floatingAddButton: some View {
        Menu {
            Button {
                showQuickAdd = true
            } label: {
                Label("New Task", systemImage: "checklist")
            }
            .accessibilityIdentifier("fab_new_task")

            Button {
                showNewNote = true
            } label: {
                Label("New Note", systemImage: "doc.text")
            }
            .accessibilityIdentifier("fab_new_note")
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .accessibilityIdentifier("floating_add_button")
    }

    // MARK: - iPad: Sidebar + content

    private var iPadLayout: some View {
        NavigationSplitView {
            SidebarView(
                selectedSmartList: $selectedSmartList,
                selectedList: $selectedList
            ) { filter in
                selectedCustomFilter = filter
            }
        } detail: {
            NavigationStack {
                detailContent
            }
        }
        .overlay(alignment: .bottomTrailing) {
            QuickAddButton(showQuickAdd: $showQuickAdd)
                .padding(20)
        }
    }

    // MARK: - macOS: Three-column

    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView {
            SidebarView(
                selectedSmartList: $selectedSmartList,
                selectedList: $selectedList
            ) { filter in
                selectedCustomFilter = filter
            }
        } content: {
            NavigationStack {
                detailContent
            }
        } detail: {
            if let selectedTask {
                if selectedTask.isNote {
                    NoteEditorView(note: selectedTask)
                } else {
                    TaskDetailView(task: selectedTask)
                }
            } else {
                ContentUnavailableView("Select a Task", systemImage: "checklist", description: Text("Choose a task to view its details."))
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Task") {
                        showQuickAdd = true
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    Button("New Note") {
                        showNewNote = true
                    }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
    }
    #endif

    // MARK: - Shared detail content

    @ViewBuilder
    private var detailContent: some View {
        if let selectedSmartList {
            switch selectedSmartList {
            case .matrix:
                EisenhowerMatrixView(selectedTask: $selectedTask)
            case .kanban:
                KanbanBoardView(selectedTask: $selectedTask)
            case .timeline:
                TimelineGanttView(selectedTask: $selectedTask)
            case .suggested:
                SuggestedTasksView(selectedTask: $selectedTask)
            default:
                SmartListView(
                    smartList: selectedSmartList,
                    selectedTask: $selectedTask
                )
            }
        } else if let selectedCustomFilter {
            CustomFilterListView(filter: selectedCustomFilter, selectedTask: $selectedTask)
        } else if let selectedList {
            TaskListView(
                list: selectedList,
                selectedTask: $selectedTask
            )
        } else {
            ContentUnavailableView("Select a List", systemImage: "list.bullet", description: Text("Choose a list from the sidebar."))
        }
    }

    // MARK: - Migration

    private func migrateToSyncProfiles() {
        let existingRepo = UserDefaults.standard.string(forKey: "githubRepo") ?? ""
        guard !existingRepo.isEmpty else { return }
        guard let existingToken = KeychainService.shared.githubToken else { return }

        let profiles = (try? modelContext.fetch(FetchDescriptor<SyncProfile>())) ?? []
        guard profiles.isEmpty else { return } // already migrated

        let profile = SyncProfile(
            name: "Default",
            repoPath: existingRepo,
            tokenKeychainKey: "github_token_default"
        )
        modelContext.insert(profile)

        // Copy the token to the new keychain key
        _ = KeychainService.shared.save(key: profile.tokenKeychainKey, value: existingToken)

        // Assign all existing shared lists to this profile
        let lists = (try? modelContext.fetch(FetchDescriptor<TaskList>())) ?? []
        for list in lists where list.isShared {
            list.syncProfileId = profile.id
        }
    }

    // MARK: - Notification action handler

    private func handleNotificationAction(_ notification: Notification, action: (TaskItem) -> Void) {
        guard let taskIdString = notification.userInfo?["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else { return }

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.id == taskId }
        )
        guard let task = try? modelContext.fetch(descriptor).first else { return }
        action(task)
    }

    // MARK: - Inbox bootstrap

    private func ensureInboxExists() {
        let descriptor = FetchDescriptor<TaskList>(
            predicate: #Predicate { $0.isInbox == true }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if existing.isEmpty {
            let inbox = TaskList(name: "Inbox", color: "#007AFF", icon: "tray", isInbox: true, sortOrder: -1)
            modelContext.insert(inbox)
        }
    }
}

enum SmartList: String, CaseIterable, Identifiable {
    case inbox
    case today
    case next7Days
    case all
    case notes
    case assignedToMe
    case suggested
    case matrix
    case kanban
    case timeline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .next7Days: return "Next 7 Days"
        case .all: return "All"
        case .notes: return "Notes"
        case .assignedToMe: return "Assigned to Me"
        case .suggested: return "Suggested"
        case .matrix: return "Matrix"
        case .kanban: return "Kanban"
        case .timeline: return "Timeline"
        }
    }

    var icon: String {
        switch self {
        case .inbox: return "tray"
        case .today: return "sun.max"
        case .next7Days: return "calendar"
        case .all: return "tray.full"
        case .notes: return "doc.text"
        case .assignedToMe: return "person.circle"
        case .suggested: return "lightbulb"
        case .matrix: return "square.grid.2x2"
        case .kanban: return "rectangle.split.3x1"
        case .timeline: return "chart.bar.xaxis"
        }
    }

    /// The basic smart lists shown at the top of the sidebar
    static var basicLists: [SmartList] {
        [.inbox, .today, .next7Days, .all, .assignedToMe]
    }

    /// Advanced views shown in their own section
    static var viewLists: [SmartList] {
        [.suggested, .matrix, .kanban, .timeline]
    }
}

enum AppTab: Hashable {
    case today, tasks, calendar, habits, chat, focus, settings
}
