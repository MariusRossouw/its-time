import SwiftUI
import SwiftData

/// iPhone-only view: shows all lists for navigation, used inside the Tasks tab.
struct TaskListsView: View {
    @Binding var selectedSmartList: SmartList?
    @Binding var selectedList: TaskList?
    @Binding var selectedTask: TaskItem?

    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]
    @Query(sort: \CustomFilter.sortOrder) private var customFilters: [CustomFilter]

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

    var body: some View {
        List {
            // Smart Lists
            Section("Smart Lists") {
                ForEach(SmartList.basicLists) { smart in
                    NavigationLink {
                        SmartListView(smartList: smart, selectedTask: $selectedTask)
                    } label: {
                        Label(smart.title, systemImage: smart.icon)
                    }
                }
            }

            // Views
            Section("Views") {
                NavigationLink {
                    SuggestedTasksView(selectedTask: $selectedTask)
                } label: {
                    Label("Suggested", systemImage: "lightbulb")
                }
                NavigationLink {
                    EisenhowerMatrixView(selectedTask: $selectedTask)
                } label: {
                    Label("Matrix", systemImage: "square.grid.2x2")
                }
                NavigationLink {
                    KanbanBoardView(selectedTask: $selectedTask)
                } label: {
                    Label("Kanban", systemImage: "rectangle.split.3x1")
                }
                NavigationLink {
                    TimelineGanttView(selectedTask: $selectedTask)
                } label: {
                    Label("Timeline", systemImage: "chart.bar.xaxis")
                }
            }

            // Custom Filters
            if !customFilters.isEmpty {
                Section("Filters") {
                    ForEach(customFilters) { filter in
                        NavigationLink {
                            CustomFilterListView(filter: filter, selectedTask: $selectedTask)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: filter.icon)
                                    .foregroundStyle(Color(hex: filter.color))
                                Text(filter.name)
                            }
                        }
                    }
                }
            }

            // User Lists
            Section("Lists") {
                ForEach(userLists) { list in
                    NavigationLink {
                        TaskListView(list: list, selectedTask: $selectedTask)
                    } label: {
                        HStack {
                            Image(systemName: list.icon)
                                .foregroundStyle(Color(hex: list.color))
                            Text(list.name)
                            if list.isShared {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if list.activeTaskCount > 0 {
                                Text("\(list.activeTaskCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button {
                    showNewList = true
                } label: {
                    Label("New List", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("new_list_button")
            }

            // Folders
            ForEach(folders) { folder in
                Section(folder.name) {
                    ForEach(folder.lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
                        NavigationLink {
                            TaskListView(list: list, selectedTask: $selectedTask)
                        } label: {
                            HStack {
                                Image(systemName: list.icon)
                                    .foregroundStyle(Color(hex: list.color))
                                Text(list.name)
                                Spacer()
                                if list.activeTaskCount > 0 {
                                    Text("\(list.activeTaskCount)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // Tags
            if !tags.isEmpty {
                Section("Tags") {
                    ForEach(tags) { tag in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: tag.color))
                                .frame(width: 10, height: 10)
                            Text(tag.name)
                            Spacer()
                            Text("\(tag.tasks.filter { $0.status == .todo }.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showTagManager = true
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
