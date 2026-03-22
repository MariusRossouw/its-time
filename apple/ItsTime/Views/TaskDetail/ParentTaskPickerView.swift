import SwiftUI
import SwiftData

struct ParentTaskPickerView: View {
    @Bindable var task: TaskItem

    var body: some View {
        Section("Parent Task") {
            if let parent = task.parentTask {
                NavigationLink(value: parent) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.turn.up.left")
                            .foregroundStyle(.secondary)
                        Text(parent.title)
                            .lineLimit(1)
                        Spacer()
                    }
                }

                Button("Remove Parent", role: .destructive) {
                    task.parentTask = nil
                    task.updatedAt = Date()
                }
            }

            NavigationLink {
                ParentTaskSearchView(task: task)
            } label: {
                Label(
                    task.parentTask == nil ? "Set Parent Task" : "Change Parent Task",
                    systemImage: "arrow.turn.up.left"
                )
                .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("set_parent_task")
        }
    }
}

// MARK: - Search view for picking a parent task

struct ParentTaskSearchView: View {
    @Bindable var task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.title) private var allTasks: [TaskItem]
    @State private var searchText = ""

    private var excludedIds: Set<UUID> {
        var ids = task.descendantIds()
        ids.insert(task.id)
        ids.formUnion(task.ancestorIds)
        return ids
    }

    private var eligibleTasks: [TaskItem] {
        let excluded = excludedIds
        return allTasks.filter { candidate in
            !candidate.isNote &&
            !excluded.contains(candidate.id) &&
            (searchText.isEmpty || candidate.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        List {
            if eligibleTasks.isEmpty {
                ContentUnavailableView(
                    "No Eligible Tasks",
                    systemImage: "magnifyingglass",
                    description: Text("Create more tasks to build a hierarchy.")
                )
            } else {
                ForEach(eligibleTasks) { candidate in
                    Button {
                        task.parentTask = candidate
                        task.updatedAt = Date()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.priorityColor(candidate.priority))
                                .frame(width: 8, height: 8)
                            Text(candidate.title)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer()
                            if let list = candidate.list {
                                Text(list.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search tasks")
        .navigationTitle("Select Parent")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
