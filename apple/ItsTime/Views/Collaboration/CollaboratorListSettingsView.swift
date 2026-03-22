import SwiftUI
import SwiftData

struct CollaboratorListSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]

    @State private var showAddCollaborator = false
    @State private var editingCollaborator: Collaborator?

    private var currentUser: Collaborator? {
        collaborators.first { $0.isCurrentUser }
    }

    private var otherCollaborators: [Collaborator] {
        collaborators.filter { !$0.isCurrentUser }
    }

    var body: some View {
        Form {
            Section {
                if let user = currentUser {
                    collaboratorRow(user)
                        .swipeActions {
                            Button("Edit") { editingCollaborator = user }
                                .tint(.blue)
                        }
                } else {
                    Button {
                        showAddCollaborator = true
                    } label: {
                        Label("Set Up Your Profile", systemImage: "person.badge.plus")
                    }
                }
            } header: {
                Text("Your Profile")
            } footer: {
                Text("Your profile is used to identify you in comments, activity logs, and task assignments when sharing lists.")
            }

            Section {
                ForEach(otherCollaborators) { collab in
                    collaboratorRow(collab)
                        .swipeActions(edge: .trailing) {
                            Button("Remove", role: .destructive) {
                                modelContext.delete(collab)
                            }
                            Button("Edit") { editingCollaborator = collab }
                                .tint(.blue)
                        }
                }

                Button {
                    showAddCollaborator = true
                } label: {
                    Label("Add Collaborator", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Team")
            } footer: {
                Text("Add people who share the same GitHub sync repo. Each person sees and edits tasks in shared lists.")
            }
        }
        .navigationTitle("Collaborators")
        .sheet(isPresented: $showAddCollaborator) {
            CollaboratorEditorView(isCurrentUserSetup: currentUser == nil)
        }
        .sheet(item: $editingCollaborator) { collab in
            CollaboratorEditorView(collaborator: collab)
        }
    }

    private func collaboratorRow(_ collab: Collaborator) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: collab.color))
                    .frame(width: 36, height: 36)
                Text(collab.initials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(collab.name)
                    if collab.isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                if !collab.email.isEmpty {
                    Text(collab.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !collab.githubUsername.isEmpty {
                    Text("@\(collab.githubUsername)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
