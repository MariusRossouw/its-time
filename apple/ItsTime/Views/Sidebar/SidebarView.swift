import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedSmartList: SmartList?
    @Binding var selectedList: TaskList?
    var onSelectFilter: ((CustomFilter) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]
    @Query(sort: \CustomFilter.sortOrder) private var customFilters: [CustomFilter]

    @State private var showNewList = false
    @State private var showNewFolder = false
    @State private var showRenameList = false
    @State private var showTagManager = false
    @State private var showNewFilter = false
    @State private var showSearch = false
    @State private var showCollaborators = false
    @State private var newListName = ""
    @State private var newFolderName = ""
    @State private var renameListName = ""
    @State private var listToRename: TaskList?
    @State private var selectedFilter: CustomFilter?
    @State private var filterToEdit: CustomFilter?
    @State private var listToShare: TaskList?

    private var inbox: TaskList? {
        lists.first { $0.isInbox }
    }

    private var userLists: [TaskList] {
        lists.filter { !$0.isInbox && $0.folder == nil }
    }

    var body: some View {
        List(selection: Binding(
            get: { selectedSmartList?.rawValue ?? selectedList?.id.uuidString },
            set: { _ in }
        )) {
            smartListsSection
            viewsSection
            filtersSection
            listsSection
            foldersSection
            moreSection
            tagsSection
        }
        .listStyle(.sidebar)
        .navigationTitle("Its Time")
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
                    Image(systemName: "plus.circle")
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
            ToolbarItem {
                Menu {
                    Button("New List") {
                        showNewList = true
                    }
                    Button("New Folder") {
                        showNewFolder = true
                    }
                    Button("New Filter") {
                        showNewFilter = true
                    }
                    Divider()
                    Button("Manage Tags") {
                        showTagManager = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            #endif
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
        .alert("Rename List", isPresented: $showRenameList) {
            TextField("List name", text: $renameListName)
            Button("Cancel", role: .cancel) {
                renameListName = ""
                listToRename = nil
            }
            Button("Rename") { renameList() }
        }
        .sheet(isPresented: $showTagManager) {
            TagManagerView()
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(isPresented: $showNewFilter) {
            FilterEditorView()
        }
        .sheet(item: $filterToEdit) { filter in
            FilterEditorView(filter: filter)
        }
        .sheet(isPresented: $showCollaborators) {
            CollaboratorManagerView()
        }
        .sheet(item: $listToShare) { list in
            NavigationStack {
                SharedListSettingsView(list: list)
            }
        }
    }

    // MARK: - Row builders

    private func smartListRow(_ smart: SmartList) -> some View {
        Button {
            selectedSmartList = smart
            selectedList = nil
        } label: {
            Label(smart.title, systemImage: smart.icon)
        }
        .tag(smart.rawValue)
    }

    private func listRow(_ list: TaskList) -> some View {
        Button {
            selectedList = list
            selectedSmartList = nil
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
        .tag(list.id.uuidString)
        .contextMenu {
            if !list.isInbox {
                Button("Rename", systemImage: "pencil") {
                    listToRename = list
                    renameListName = list.name
                    showRenameList = true
                }

                Button("Sharing", systemImage: "person.2") {
                    listToShare = list
                }

                // Move to folder
                Menu("Move to Folder") {
                    Button("None (top level)") {
                        list.folder = nil
                        list.updatedAt = Date()
                    }
                    ForEach(folders) { folder in
                        Button(folder.name) {
                            list.folder = folder
                            list.updatedAt = Date()
                        }
                    }
                }

                Divider()

                Button("Delete", systemImage: "trash", role: .destructive) {
                    deleteList(list)
                }
            }
        }
    }

    // MARK: - Actions

    private func createList() {
        guard !newListName.isEmpty else { return }
        let list = TaskList(name: newListName, sortOrder: lists.count)
        modelContext.insert(list)
        newListName = ""
        selectedList = list
        selectedSmartList = nil
    }

    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        let folder = Folder(name: newFolderName, sortOrder: folders.count)
        modelContext.insert(folder)
        newFolderName = ""
    }

    private func renameList() {
        guard let list = listToRename, !renameListName.isEmpty else { return }
        list.name = renameListName
        list.updatedAt = Date()
        renameListName = ""
        listToRename = nil
    }

    private func deleteList(_ list: TaskList) {
        modelContext.delete(list)
    }

    private func moveList(from source: IndexSet, to destination: Int) {
        var mutable = userLists
        mutable.move(fromOffsets: source, toOffset: destination)
        for (index, list) in mutable.enumerated() {
            list.sortOrder = index
            list.updatedAt = Date()
        }
    }

    // MARK: - Extracted Sections

    @ViewBuilder
    private var smartListsSection: some View {
        Section("Smart Lists") {
            ForEach(SmartList.basicLists) { smart in
                smartListRow(smart)
            }
        }
    }

    @ViewBuilder
    private var viewsSection: some View {
        Section("Views") {
            ForEach(SmartList.viewLists) { smart in
                smartListRow(smart)
            }
        }
    }

    @ViewBuilder
    private var filtersSection: some View {
        if !customFilters.isEmpty {
            Section("Filters") {
                ForEach(customFilters) { filter in
                    Button {
                        selectedSmartList = nil
                        selectedList = nil
                        selectedFilter = filter
                        onSelectFilter?(filter)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: filter.icon)
                                .foregroundStyle(Color(hex: filter.color))
                            Text(filter.name)
                            Spacer()
                        }
                    }
                    .contextMenu {
                        Button("Edit", systemImage: "pencil") {
                            filterToEdit = filter
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            modelContext.delete(filter)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var listsSection: some View {
        Section("Lists") {
            ForEach(userLists) { list in
                listRow(list)
            }
            .onMove { from, to in
                moveList(from: from, to: to)
            }

            Button {
                showNewList = true
            } label: {
                Label("New List", systemImage: "plus")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var foldersSection: some View {
        ForEach(folders) { folder in
            Section {
                ForEach(folder.lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
                    listRow(list)
                }
            } header: {
                HStack {
                    Text(folder.name)
                    Spacer()
                    Button {
                        withAnimation {
                            folder.isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: folder.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .contextMenu {
                    Button("Rename", systemImage: "pencil") {
                        newFolderName = folder.name
                        folder.name = folder.name
                    }
                    Button("Delete Folder", systemImage: "trash", role: .destructive) {
                        for list in folder.lists {
                            list.folder = nil
                        }
                        modelContext.delete(folder)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var moreSection: some View {
        Section("More") {
            NavigationLink {
                ChatListView()
            } label: {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            NavigationLink {
                HabitListView()
            } label: {
                Label("Habits", systemImage: "leaf")
            }
            NavigationLink {
                TriggerListView()
            } label: {
                Label("Automations", systemImage: "bolt.circle")
            }
            Button {
                showCollaborators = true
            } label: {
                Label("Collaborators", systemImage: "person.2")
            }
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
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
}
