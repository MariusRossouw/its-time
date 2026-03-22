import SwiftUI
import SwiftData

struct BatchEditBar: View {
    @Binding var selectedTasks: Set<TaskItem>
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]

    var body: some View {
        if !selectedTasks.isEmpty {
            HStack(spacing: 16) {
                Text("\(selectedTasks.count) selected")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                // Complete all
                Button {
                    for task in selectedTasks {
                        task.markDone()
                    }
                    selectedTasks.removeAll()
                } label: {
                    Label("Done", systemImage: "checkmark.circle")
                }

                // Move to list
                Menu {
                    ForEach(lists) { list in
                        Button {
                            for task in selectedTasks {
                                task.list = list
                                task.updatedAt = Date()
                            }
                            selectedTasks.removeAll()
                        } label: {
                            HStack {
                                Image(systemName: list.icon)
                                Text(list.name)
                            }
                        }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }

                // Set priority
                Menu {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Button {
                            for task in selectedTasks {
                                task.priority = priority
                                task.updatedAt = Date()
                            }
                            selectedTasks.removeAll()
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color.priorityColor(priority))
                                    .frame(width: 10, height: 10)
                                Text(priority.rawValue.capitalized)
                            }
                        }
                    }
                } label: {
                    Label("Priority", systemImage: "flag")
                }

                // Delete all
                Button(role: .destructive) {
                    for task in selectedTasks {
                        modelContext.delete(task)
                    }
                    selectedTasks.removeAll()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
}
