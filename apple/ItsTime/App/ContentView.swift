import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]
    @State private var selectedSmartList: SmartList? = .today
    @State private var selectedList: TaskList?
    @State private var selectedTask: TaskItem?
    @State private var showQuickAdd = false
    @State private var showNewNote = false
    @State private var selectedCustomFilter: CustomFilter?

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
        TabView {
            Tab("Today", systemImage: "sun.max") {
                NavigationStack {
                    TodayView(selectedTask: $selectedTask)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Menu {
                                    Button("New Task", systemImage: "checklist") {
                                        showQuickAdd = true
                                    }
                                    .accessibilityIdentifier("menu_new_task")
                                    Button("New Note", systemImage: "doc.text") {
                                        showNewNote = true
                                    }
                                    .accessibilityIdentifier("menu_new_note")
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                }
                                .accessibilityIdentifier("plus_menu")
                            }
                        }
                }
            }
            Tab("Tasks", systemImage: "checklist") {
                NavigationStack {
                    TaskListsView(
                        selectedSmartList: $selectedSmartList,
                        selectedList: $selectedList,
                        selectedTask: $selectedTask
                    )
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                Button("New Task", systemImage: "checklist") {
                                    showQuickAdd = true
                                }
                                .accessibilityIdentifier("menu_new_task")
                                Button("New Note", systemImage: "doc.text") {
                                    showNewNote = true
                                }
                                .accessibilityIdentifier("menu_new_note")
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .accessibilityIdentifier("plus_menu")
                        }
                    }
                }
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarContainerView()
            }
            Tab("Habits", systemImage: "leaf") {
                HabitListView()
            }
            Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                NavigationStack {
                    ChatListView()
                }
            }
            Tab("Focus", systemImage: "timer") {
                FocusTimerView()
            }
            Tab("Settings", systemImage: "gear") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
        }
        .sheet(isPresented: $showNewNote) {
            QuickAddNoteView()
        }
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
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
        }
        .sheet(isPresented: $showNewNote) {
            QuickAddNoteView()
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
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
        }
        .sheet(isPresented: $showNewNote) {
            QuickAddNoteView()
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
