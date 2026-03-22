import SwiftUI
import SwiftData

struct SharedListSettingsView: View {
    @Bindable var list: TaskList

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]
    @Query(sort: \SyncProfile.name) private var syncProfiles: [SyncProfile]

    var body: some View {
        Form {
            Section {
                Toggle("Shared List", isOn: $list.isShared)
                    .onChange(of: list.isShared) {
                        if !list.isShared {
                            list.collaboratorIds = []
                        }
                        list.updatedAt = Date()
                    }
            } footer: {
                Text("Shared lists sync to the GitHub repo so all collaborators can see and edit tasks.")
            }

            if list.isShared {
                if !syncProfiles.isEmpty {
                    Section {
                        Picker("Sync Profile", selection: Binding(
                            get: { list.syncProfileId },
                            set: { newValue in
                                list.syncProfileId = newValue
                                list.updatedAt = Date()
                            }
                        )) {
                            Text("Local Only").tag(UUID?.none)
                            ForEach(syncProfiles) { profile in
                                Label(profile.name, systemImage: profile.icon)
                                    .tag(UUID?.some(profile.id))
                            }
                        }
                    } footer: {
                        Text("Choose which GitHub repo this list syncs to.")
                    }
                }

                Section("Collaborators") {
                    ForEach(collaborators) { collab in
                        let isIncluded = list.collaboratorIds.contains(collab.id)
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: collab.color))
                                    .frame(width: 30, height: 30)
                                Text(collab.initials)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading) {
                                HStack {
                                    Text(collab.name)
                                    if collab.isCurrentUser {
                                        Text("You")
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .background(.blue.opacity(0.15))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                                .font(.subheadline)
                            }

                            Spacer()

                            if collab.isCurrentUser {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button {
                                    toggleCollaborator(collab)
                                } label: {
                                    Image(systemName: isIncluded ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isIncluded ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if collaborators.isEmpty {
                        Text("Set up collaborators in Settings to share lists.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Info") {
                    LabeledContent("Tasks") {
                        Text("\(list.activeTaskCount)")
                    }
                    LabeledContent("Total Members") {
                        Text("\(list.collaboratorIds.count + 1)") // +1 for owner
                    }
                }
            }
        }
        .navigationTitle("Sharing")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func toggleCollaborator(_ collab: Collaborator) {
        var ids = list.collaboratorIds
        if let index = ids.firstIndex(of: collab.id) {
            ids.remove(at: index)
        } else {
            ids.append(collab.id)
        }
        list.collaboratorIds = ids
        list.updatedAt = Date()
    }
}
