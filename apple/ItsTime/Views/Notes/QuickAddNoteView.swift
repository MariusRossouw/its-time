import SwiftUI
import SwiftData

struct QuickAddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(filter: #Predicate<Collaborator> { $0.isCurrentUser == true })
    private var currentUsers: [Collaborator]

    @State private var title = ""
    @State private var selectedList: TaskList?
    @FocusState private var titleFocused: Bool

    private var inbox: TaskList? {
        lists.first { $0.isInbox }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Note title", text: $title, axis: .vertical)
                    .font(.title3)
                    .focused($titleFocused)
                    .padding()
                    .accessibilityIdentifier("quick_add_note_title")

                // List picker
                HStack {
                    Menu {
                        ForEach(lists) { list in
                            Button {
                                selectedList = list
                            } label: {
                                Label(list.name, systemImage: list.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedList?.icon ?? "tray")
                                .font(.caption)
                            Text(selectedList?.name ?? "Inbox")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.fill.tertiary)
                        .clipShape(Capsule())
                    }

                    Spacer()
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("New Note")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("quick_add_note_cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createNote() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("quick_add_note_create")
                }
            }
            .onAppear {
                titleFocused = true
            }
        }
    }

    private func createNote() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let targetList = selectedList ?? inbox
        let nextOrder = (targetList?.tasks.count ?? 0)

        let note = TaskItem(
            title: trimmed,
            list: targetList,
            sortOrder: nextOrder
        )
        note.isNote = true

        // Auto-assign to current user
        if let currentUser = currentUsers.first {
            note.assignedTo = currentUser.id
            note.assignedToName = currentUser.name
        }

        modelContext.insert(note)
        dismiss()
    }
}
