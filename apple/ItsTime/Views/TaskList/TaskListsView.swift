import SwiftUI
import SwiftData

/// iPhone-only view: shows all lists for navigation, used inside the Tasks tab.
struct TaskListsView: View {
    @Binding var selectedSmartList: SmartList?
    @Binding var selectedList: TaskList?
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]
    @Query(sort: \CustomFilter.sortOrder) private var customFilters: [CustomFilter]
    @Query(sort: \Habit.sortOrder) private var allHabits: [Habit]

    @Environment(\.modelContext) private var modelContext

    @State private var showSearch = false
    @State private var showTagManager = false
    @State private var showNewList = false
    @State private var showNewFolder = false
    @State private var showNewFilter = false
    @State private var newListName = ""
    @State private var newFolderName = ""

    private var inbox: TaskList? {
        lists.first { $0.isInbox }
    }

    private var userLists: [TaskList] {
        lists.filter { !$0.isInbox && $0.folder == nil }
    }

    // Counts
    private var activeTasks: [TaskItem] {
        allTasks.filter { $0.status == .todo && !$0.isNote }
    }

    private var activeNotes: [TaskItem] {
        allTasks.filter { $0.isNote && $0.status == .todo }
    }

    private var activeHabits: [Habit] {
        allHabits.filter { !$0.isArchived }
    }

    private var todayTasks: [TaskItem] {
        let cal = Calendar.current
        return activeTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return cal.isDateInToday(due)
        }
    }

    private var overdueTasks: [TaskItem] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return activeTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return due < startOfToday
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary cards
                summaryCards

                // Views (icon buttons)
                viewsSection

                // Custom Filters
                if !customFilters.isEmpty {
                    filtersSection
                }

                // User Lists
                listsSection

                // Folders
                foldersSection

                // Tags
                if !tags.isEmpty {
                    tagsSection
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .navigationTitle("Tasks")
        .accessibilityIdentifier("task_lists_view")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("New List", systemImage: "list.bullet") {
                        showNewList = true
                    }
                    Button("New Folder", systemImage: "folder.badge.plus") {
                        showNewFolder = true
                    }
                    Button("New Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        showNewFilter = true
                    }
                    Divider()
                    Button("Manage Tags", systemImage: "tag") {
                        showTagManager = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            #else
            ToolbarItem {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
            #endif
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(isPresented: $showTagManager) {
            TagManagerView()
        }
        .sheet(isPresented: $showNewFilter) {
            NavigationStack {
                FilterEditorView()
            }
        }
        .alert("New List", isPresented: $showNewList) {
            TextField("List name", text: $newListName)
            Button("Cancel", role: .cancel) { newListName = "" }
            Button("Create") { createList() }
        }
        .alert("New Folder", isPresented: $showNewFolder) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create") { createFolder() }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let cardColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

        return VStack(alignment: .leading, spacing: 8) {
            // Top row: Tasks, Notes, Habits
            LazyVGrid(columns: cardColumns, spacing: 10) {
                NavigationLink {
                    SmartListView(smartList: .all, selectedTask: $selectedTask)
                } label: {
                    summaryCard(
                        title: "Tasks",
                        count: activeTasks.count,
                        icon: "checklist",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SmartListView(smartList: .notes, selectedTask: $selectedTask)
                } label: {
                    summaryCard(
                        title: "Notes",
                        count: activeNotes.count,
                        icon: "doc.text",
                        color: .orange
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: HabitListView()) {
                    summaryCard(
                        title: "Habits",
                        count: activeHabits.count,
                        icon: "leaf",
                        color: .green
                    )
                }
                .buttonStyle(.plain)
            }

            // Smart list cards
            let smartColumns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: smartColumns, spacing: 10) {
                ForEach(SmartList.basicLists) { smart in
                    NavigationLink {
                        SmartListView(smartList: smart, selectedTask: $selectedTask)
                    } label: {
                        smartListCard(smart)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func summaryCard(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func smartListCard(_ smart: SmartList) -> some View {
        let count = countForSmartList(smart)

        return HStack(spacing: 10) {
            Image(systemName: smart.icon)
                .font(.body)
                .foregroundStyle(colorForSmartList(smart))
                .frame(width: 28)

            Text(smart.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Views Section (icon buttons)

    private var viewsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Views")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            HStack(spacing: 10) {
                viewIconButton(
                    title: "Suggested",
                    icon: "lightbulb",
                    color: .yellow
                ) {
                    SuggestedTasksView(selectedTask: $selectedTask)
                }

                viewIconButton(
                    title: "Matrix",
                    icon: "square.grid.2x2",
                    color: .purple
                ) {
                    EisenhowerMatrixView(selectedTask: $selectedTask)
                }

                viewIconButton(
                    title: "Kanban",
                    icon: "rectangle.split.3x1",
                    color: .teal
                ) {
                    KanbanBoardView(selectedTask: $selectedTask)
                }

                viewIconButton(
                    title: "Timeline",
                    icon: "chart.bar.xaxis",
                    color: .indigo
                ) {
                    TimelineGanttView(selectedTask: $selectedTask)
                }
            }
        }
    }

    private func viewIconButton<Destination: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filters")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ForEach(customFilters) { filter in
                NavigationLink {
                    CustomFilterListView(filter: filter, selectedTask: $selectedTask)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: filter.icon)
                            .foregroundStyle(Color(hex: filter.color))
                            .frame(width: 28)
                        Text(filter.name)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Lists Section

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lists")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showNewList = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityIdentifier("new_list_button")
            }
            .padding(.horizontal, 4)

            ForEach(userLists) { list in
                NavigationLink {
                    TaskListView(list: list, selectedTask: $selectedTask)
                } label: {
                    listCard(list)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func listCard(_ list: TaskList) -> some View {
        HStack(spacing: 10) {
            Image(systemName: list.icon)
                .font(.body)
                .foregroundStyle(Color(hex: list.color))
                .frame(width: 28)

            Text(list.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            if list.isShared {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if list.activeTaskCount > 0 {
                Text("\(list.activeTaskCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Folders Section

    private var foldersSection: some View {
        ForEach(folders) { folder in
            VStack(alignment: .leading, spacing: 8) {
                Text(folder.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                ForEach(folder.lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
                    NavigationLink {
                        TaskListView(list: list, selectedTask: $selectedTask)
                    } label: {
                        listCard(list)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showTagManager = true
                } label: {
                    Text("Manage")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 4)

            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    let count = tag.tasks.filter { $0.status == .todo }.count
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: tag.color))
                            .frame(width: 8, height: 8)
                        Text(tag.name)
                            .font(.caption)
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: tag.color).opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Helpers

    private func countForSmartList(_ smart: SmartList) -> Int {
        let cal = Calendar.current
        let now = Date()
        switch smart {
        case .inbox:
            return allTasks.filter { $0.status == .todo && $0.list?.isInbox == true }.count
        case .today:
            return todayTasks.count
        case .next7Days:
            guard let weekEnd = cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: now)) else { return 0 }
            return activeTasks.filter { task in
                guard let due = task.dueDate else { return false }
                return due >= cal.startOfDay(for: now) && due < weekEnd
            }.count
        case .all:
            return activeTasks.count
        case .assignedToMe:
            return activeTasks.filter { $0.assignedTo != nil }.count
        default:
            return 0
        }
    }

    private func colorForSmartList(_ smart: SmartList) -> Color {
        switch smart {
        case .inbox: return .gray
        case .today: return .orange
        case .next7Days: return .blue
        case .all: return .purple
        case .assignedToMe: return .teal
        default: return .accentColor
        }
    }

    private func createList() {
        guard !newListName.isEmpty else { return }
        let list = TaskList(name: newListName, sortOrder: lists.count)
        modelContext.insert(list)
        newListName = ""
    }

    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        let folder = Folder(name: newFolderName, sortOrder: folders.count)
        modelContext.insert(folder)
        newFolderName = ""
    }
}
