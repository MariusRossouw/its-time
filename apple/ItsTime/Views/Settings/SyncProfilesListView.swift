import SwiftUI
import SwiftData

struct SyncProfilesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SyncProfile.name) private var profiles: [SyncProfile]

    @State private var showAddProfile = false

    var body: some View {
        List {
            if profiles.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No sync profiles configured.")
                            .font(.subheadline)
                        Text("Add a profile to sync your lists to a GitHub repository. You can create separate profiles for work, home, or social.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                ForEach(profiles) { profile in
                    NavigationLink {
                        SyncProfileEditorView(profile: profile)
                    } label: {
                        profileRow(profile)
                    }
                }
                .onDelete(perform: deleteProfiles)
            }

            Section {
                Button {
                    showAddProfile = true
                } label: {
                    Label("Add Sync Profile", systemImage: "plus")
                }
            } footer: {
                Text("Each profile syncs to its own GitHub repo. Assign lists to a profile in the list's Sharing settings.")
            }
        }
        .navigationTitle("Sync Profiles")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showAddProfile) {
            NavigationStack {
                SyncProfileEditorView()
            }
        }
    }

    private func profileRow(_ profile: SyncProfile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: profile.icon)
                .foregroundStyle(Color(hex: profile.color))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(profile.name)
                        .font(.subheadline.bold())
                    if !profile.isEnabled {
                        Text("Disabled")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(.secondary.opacity(0.15))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                Text(profile.repoPath.isEmpty ? "Not configured" : profile.repoPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let error = profile.lastError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .help(error)
            } else if profile.lastSyncDate != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = profiles[index]
            // Remove token from keychain
            _ = KeychainService.shared.delete(key: profile.tokenKeychainKey)
            // Unlink lists
            let lists = (try? modelContext.fetch(FetchDescriptor<TaskList>())) ?? []
            for list in lists where list.syncProfileId == profile.id {
                list.syncProfileId = nil
            }
            modelContext.delete(profile)
        }
    }
}
