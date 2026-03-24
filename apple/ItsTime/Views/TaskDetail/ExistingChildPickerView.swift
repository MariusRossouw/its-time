import SwiftUI
import SwiftData

struct ExistingChildPickerView: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.title) private var allTasks: [TaskItem]
    @State private var searchText = ""

    private var excludedIds: Set<UUID> {
        var ids = task.descendantIds()
        ids.insert(task.id)
        ids.formUnion(task.ancestorIds)
        // Also exclude tasks already linked as children
        ids.formUnion(Set(task.childTasks.map(\.id)))
        return ids
    }

    private var eligibleItems: [TaskItem] {
        let excluded = excludedIds
        return allTasks.filter { candidate in
            !excluded.contains(candidate.id) &&
            candidate.parentTask == nil && // only orphans (not already a child)
            (searchText.isEmpty || candidate.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var notes: [TaskItem] {
        eligibleItems.filter { $0.isNote }
    }

    private var tasks: [TaskItem] {
        eligibleItems.filter { !$0.isNote }
    }

    var body: some View {
        List {
            if eligibleItems.isEmpty {
                ContentUnavailableView(
                    "Nothing to Link",
                    systemImage: "magnifyingglass",
                    description: Text("No available tasks or notes to link as children.")
                )
            } else {
                if !tasks.isEmpty {
                    Section("Tasks") {
                        ForEach(tasks) { item in
                            linkButton(item)
                        }
                    }
                }
                if !notes.isEmpty {
                    Section("Notes") {
                        ForEach(notes) { item in
                            linkButton(item)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search tasks & notes")
        .navigationTitle("Link Existing")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func linkButton(_ item: TaskItem) -> some View {
        Button {
            item.parentTask = task
            item.updatedAt = Date()
            task.updatedAt = Date()
            task.logActivity(action: .childAdded, newValue: item.title, context: modelContext)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                if item.isNote {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                } else {
                    Circle()
                        .fill(Color.priorityColor(item.priority))
                        .frame(width: 8, height: 8)
                        .frame(width: 20)
                }
                Text(item.title)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Spacer()
                if let list = item.list {
                    Text(list.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
