import SwiftUI
import SwiftData

struct CollaboratorManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
        NavigationStack {
            List {
                // Current user profile
                Section("Your Profile") {
                    if let user = currentUser {
                        collaboratorRow(user)
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") {
                                    editingCollaborator = user
                                }
                            }
                    } else {
                        Button {
                            showAddCollaborator = true
                        } label: {
                            Label("Set Up Your Profile", systemImage: "person.badge.plus")
                        }
                    }
                }

                // Other collaborators
                Section("Collaborators") {
                    if otherCollaborators.isEmpty {
                        Text("No collaborators yet. Add people who share your sync repo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(otherCollaborators) { collab in
                            collaboratorRow(collab)
                                .contextMenu {
                                    Button("Edit", systemImage: "pencil") {
                                        editingCollaborator = collab
                                    }
                                    Button("Remove", systemImage: "trash", role: .destructive) {
                                        modelContext.delete(collab)
                                    }
                                }
                        }
                    }

                    Button {
                        showAddCollaborator = true
                    } label: {
                        Label("Add Collaborator", systemImage: "plus")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    // empty
                } footer: {
                    Text("Collaborators share the same GitHub sync repo. Each person needs their own device with the app installed and the repo configured.")
                }
            }
            .navigationTitle("Collaborators")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddCollaborator) {
                CollaboratorEditorView(isCurrentUserSetup: currentUser == nil)
            }
            .sheet(item: $editingCollaborator) { collab in
                CollaboratorEditorView(collaborator: collab)
            }
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
                        .font(.body)
                    if collab.isCurrentUser {
                        Text("You")
                            .font(.caption)
                            .padding(.horizontal, 6)
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

// MARK: - Collaborator Editor

struct CollaboratorEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var collaborator: Collaborator?
    var isCurrentUserSetup: Bool = false

    @State private var name = ""
    @State private var email = ""
    @State private var githubUsername = ""
    @State private var selectedColor = "#007AFF"

    private let colors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#5856D6", "#AF52DE",
        "#FF2D55", "#A2845E", "#8E8E93", "#30B0C7"
    ]

    private var isEditing: Bool { collaborator != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Display name", text: $name)
                }

                Section("Contact") {
                    TextField("Email (optional)", text: $email)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                    TextField("GitHub username (optional)", text: $githubUsername)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Collaborator" : (isCurrentUserSetup ? "Set Up Profile" : "Add Collaborator"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let collaborator {
                    name = collaborator.name
                    email = collaborator.email
                    githubUsername = collaborator.githubUsername
                    selectedColor = collaborator.color
                }
            }
        }
    }

    private func save() {
        if let collaborator {
            collaborator.name = name
            collaborator.email = email
            collaborator.githubUsername = githubUsername
            collaborator.color = selectedColor
            collaborator.updatedAt = Date()
            // Recompute initials
            let parts = name.split(separator: " ")
            if parts.count >= 2 {
                collaborator.initials = String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
            } else if let first = parts.first {
                collaborator.initials = String(first.prefix(2)).uppercased()
            }
        } else {
            let collab = Collaborator(
                name: name,
                email: email,
                githubUsername: githubUsername,
                color: selectedColor,
                isCurrentUser: isCurrentUserSetup
            )
            modelContext.insert(collab)
        }
        dismiss()
    }
}
