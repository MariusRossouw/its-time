import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var results: [TaskItem] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return allTasks.filter { task in
            task.title.lowercased().contains(query)
            || task.taskDescription.lowercased().contains(query)
            || task.tags.contains(where: { $0.name.lowercased().contains(query) })
            || (task.list?.name.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    ContentUnavailableView("Search Tasks", systemImage: "magnifyingglass", description: Text("Search by title, description, tags, or list name."))
                        .listRowSeparator(.hidden)
                } else if results.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No tasks match \"\(searchText)\"."))
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(results) { task in
                        NavigationLink(value: task) {
                            VStack(alignment: .leading, spacing: 4) {
                                TaskRowView(task: task)
                                if let listName = task.list?.name {
                                    Text(listName)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
            .taskNavigationDestination()
            .listStyle(.plain)
            .navigationTitle("Search")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Tasks, tags, lists...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { searchFocused = true }
        }
    }
}
