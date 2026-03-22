import SwiftUI
import SwiftData

struct AssignmentPickerView: View {
    @Bindable var task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]

    private var currentUser: Collaborator? {
        collaborators.first { $0.isCurrentUser }
    }

    var body: some View {
        if collaborators.isEmpty {
            // No collaborators set up yet — don't show the section
            EmptyView()
        } else {
            Section("Assigned To") {
                ForEach(assignmentOptions, id: \.id) { option in
                    Button {
                        assign(to: option)
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: option.color))
                                    .frame(width: 28, height: 28)
                                Text(option.initials)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            Text(option.name)
                                .foregroundStyle(.primary)

                            if option.isCurrentUser {
                                Text("You")
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .background(.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            if task.assignedTo == option.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                if task.assignedTo != nil {
                    Button("Unassign", role: .destructive) {
                        logAssignmentChange(newName: nil)
                        task.assignedTo = nil
                        task.assignedToName = nil
                        task.updatedAt = Date()
                    }
                }
            }
        }
    }

    private var assignmentOptions: [Collaborator] {
        // Show current user first, then others
        var result: [Collaborator] = []
        if let current = collaborators.first(where: { $0.isCurrentUser }) {
            result.append(current)
        }
        result.append(contentsOf: collaborators.filter { !$0.isCurrentUser })
        return result
    }

    private func assign(to collaborator: Collaborator) {
        logAssignmentChange(newName: collaborator.name)
        task.assignedTo = collaborator.id
        task.assignedToName = collaborator.name
        task.updatedAt = Date()
    }

    private func logAssignmentChange(newName: String?) {
        guard let user = currentUser else { return }
        let activity = ActivityEntry(
            action: .assigned,
            field: "assignedTo",
            oldValue: task.assignedToName,
            newValue: newName,
            authorName: user.name,
            authorId: user.id,
            task: task
        )
        task.activityLog.append(activity)
        modelContext.insert(activity)
    }
}
