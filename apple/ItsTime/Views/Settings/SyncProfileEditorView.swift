import SwiftUI
import SwiftData

struct SyncProfileEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var profile: SyncProfile?

    @State private var name = ""
    @State private var repoPath = ""
    @State private var tokenInput = ""
    @State private var hasToken = false
    @State private var showTokenField = false
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "cloud"
    @State private var isEnabled = true

    private var isEditing: Bool { profile != nil }

    private let colors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#5856D6", "#AF52DE",
        "#FF2D55", "#A2845E", "#8E8E93", "#30B0C7"
    ]

    private let icons = [
        ("cloud", "Cloud"),
        ("briefcase", "Work"),
        ("house", "Home"),
        ("person.2", "Social"),
        ("building.2", "Office"),
        ("leaf", "Personal"),
        ("book", "Study"),
        ("heart", "Family")
    ]

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name (e.g. Work, Home)", text: $name)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(icons, id: \.0) { icon, label in
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.2) : Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color(hex: selectedColor) : .clear, lineWidth: 2)
                                )
                            Text(label)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .onTapGesture { selectedIcon = icon }
                    }
                }
                .padding(.vertical, 4)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture { selectedColor = color }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Repository") {
                TextField("owner/repo", text: $repoPath)
                    .textContentType(.URL)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            }

            Section {
                if hasToken && !showTokenField {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Token saved")
                        Spacer()
                        Button("Change") { showTokenField = true }
                    }
                } else {
                    SecureField("ghp_...", text: $tokenInput)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    Button("Save Token") {
                        saveToken()
                    }
                    .disabled(tokenInput.isEmpty)
                }

                if hasToken {
                    Button("Remove Token", role: .destructive) {
                        removeToken()
                    }
                }
            } header: {
                Text("GitHub Token")
            } footer: {
                Text("A personal access token with repo scope. Each profile can use the same or a different GitHub account.")
            }

            Section {
                Toggle("Enabled", isOn: $isEnabled)
            }

            if isEditing, let profile {
                Section("Status") {
                    if let date = profile.lastSyncDate {
                        LabeledContent("Last Sync") {
                            Text(date, style: .relative)
                        }
                    }
                    if let error = profile.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Button {
                        Task {
                            await GitHubSyncService.shared.syncProfile(profile, context: modelContext)
                        }
                    } label: {
                        HStack {
                            Text("Sync Now")
                            Spacer()
                            if GitHubSyncService.shared.isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(GitHubSyncService.shared.isSyncing || profile.repoPath.isEmpty || KeychainService.shared.load(key: profile.tokenKeychainKey) == nil)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Profile" : "New Sync Profile")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Create") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || repoPath.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let profile {
                name = profile.name
                repoPath = profile.repoPath
                selectedColor = profile.color
                selectedIcon = profile.icon
                isEnabled = profile.isEnabled
                hasToken = KeychainService.shared.load(key: profile.tokenKeychainKey) != nil
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedRepo = repoPath.trimmingCharacters(in: .whitespaces)

        if let profile {
            profile.name = trimmedName
            profile.repoPath = trimmedRepo
            profile.color = selectedColor
            profile.icon = selectedIcon
            profile.isEnabled = isEnabled
            profile.updatedAt = Date()
        } else {
            let keychainKey = "github_token_\(UUID().uuidString)"
            let newProfile = SyncProfile(
                name: trimmedName,
                repoPath: trimmedRepo,
                tokenKeychainKey: keychainKey,
                color: selectedColor,
                icon: selectedIcon,
                isEnabled: isEnabled
            )
            modelContext.insert(newProfile)

            // Save token if entered
            if !tokenInput.isEmpty {
                _ = KeychainService.shared.save(key: keychainKey, value: tokenInput)
                tokenInput = ""
            }
        }

        dismiss()
    }

    private func saveToken() {
        guard !tokenInput.isEmpty else { return }
        let key = profile?.tokenKeychainKey ?? "github_token_\(UUID().uuidString)"
        _ = KeychainService.shared.save(key: key, value: tokenInput)
        tokenInput = ""
        hasToken = true
        showTokenField = false
    }

    private func removeToken() {
        if let key = profile?.tokenKeychainKey {
            _ = KeychainService.shared.delete(key: key)
        }
        hasToken = false
        showTokenField = false
    }
}
