import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("theme") private var theme = "system"
    @AppStorage("weekStartDay") private var weekStartDay = 2
    @AppStorage("timeFormat") private var timeFormat = "12h"
    @AppStorage("defaultPriority") private var defaultPriority = "none"
    @AppStorage("dailySummaryEnabled") private var dailySummaryEnabled = false
    @AppStorage("dailySummaryHour") private var dailySummaryHour = 8
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStart = 22
    @AppStorage("quietHoursEnd") private var quietHoursEnd = 7
    @AppStorage("badgeCountEnabled") private var badgeCountEnabled = true
    @AppStorage("defaultReminder") private var defaultReminder = "none"
    @AppStorage("focusDuration") private var focusDuration = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration = 5
    @AppStorage("longBreakDuration") private var longBreakDuration = 15

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }

            Section("Date & Time") {
                Picker("Week Starts On", selection: $weekStartDay) {
                    Text("Sunday").tag(1)
                    Text("Monday").tag(2)
                    Text("Saturday").tag(7)
                }

                Picker("Time Format", selection: $timeFormat) {
                    Text("12-hour").tag("12h")
                    Text("24-hour").tag("24h")
                }
            }

            Section("Task Defaults") {
                Picker("Default Priority", selection: $defaultPriority) {
                    Text("None").tag("none")
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }

                Picker("Default Reminder", selection: $defaultReminder) {
                    Text("None").tag("none")
                    Text("At time of event").tag("0")
                    Text("5 minutes before").tag("-300")
                    Text("15 minutes before").tag("-900")
                    Text("30 minutes before").tag("-1800")
                    Text("1 hour before").tag("-3600")
                }
            }

            Section("Focus Timer") {
                Stepper("Focus: \(focusDuration) min", value: $focusDuration, in: 5...120, step: 5)
                Stepper("Short Break: \(shortBreakDuration) min", value: $shortBreakDuration, in: 1...30, step: 1)
                Stepper("Long Break: \(longBreakDuration) min", value: $longBreakDuration, in: 5...60, step: 5)
            }

            Section("Notifications") {
                Toggle("Daily Summary", isOn: $dailySummaryEnabled)
                if dailySummaryEnabled {
                    Picker("Summary Time", selection: $dailySummaryHour) {
                        ForEach(5..<12, id: \.self) { hour in
                            Text("\(hour):00 AM").tag(hour)
                        }
                    }
                    .onChange(of: dailySummaryHour) {
                        DailySummaryService.shared.scheduleDailySummary(hour: dailySummaryHour)
                    }
                }

                Toggle("Quiet Hours", isOn: $quietHoursEnabled)
                if quietHoursEnabled {
                    Picker("Start", selection: $quietHoursStart) {
                        ForEach(18..<24, id: \.self) { h in
                            Text("\(h > 12 ? h - 12 : h) PM").tag(h)
                        }
                    }
                    Picker("End", selection: $quietHoursEnd) {
                        ForEach(5..<10, id: \.self) { h in
                            Text("\(h) AM").tag(h)
                        }
                    }
                }

                Toggle("Badge Count", isOn: $badgeCountEnabled)
                    .onChange(of: badgeCountEnabled) {
                        if !badgeCountEnabled {
                            BadgeService.clearBadge()
                        }
                    }
            }

            Section("Sync") {
                NavigationLink {
                    SyncProfilesListView()
                } label: {
                    Label("Sync Profiles", systemImage: "arrow.triangle.2.circlepath")
                }

                Toggle("Auto-Sync", isOn: Binding(
                    get: { AutoSyncService.shared.isEnabled },
                    set: { AutoSyncService.shared.isEnabled = $0; AutoSyncService.shared.settingsChanged() }
                ))

                if AutoSyncService.shared.isEnabled {
                    Picker("Sync Delay", selection: Binding(
                        get: { AutoSyncService.shared.syncInterval },
                        set: { AutoSyncService.shared.syncInterval = $0; AutoSyncService.shared.settingsChanged() }
                    )) {
                        Text("5 seconds").tag(5.0)
                        Text("15 seconds").tag(15.0)
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                    }
                }
            }

            Section {
                Text("Its Time shows events from all calendar accounts on your device. To see Google, Outlook, or other calendars, add them in your device's system settings under Calendar or Mail accounts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                #if os(iOS)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
                #else
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open Internet Accounts", systemImage: "gear")
                }
                #endif
            } header: {
                Text("Calendar Accounts")
            }

            Section("Collaboration") {
                NavigationLink {
                    CollaboratorListSettingsView()
                } label: {
                    Label("Collaborators", systemImage: "person.2")
                }
            }

            Section("Automation") {
                NavigationLink {
                    TriggerListView()
                } label: {
                    Label("Automations", systemImage: "bolt.circle")
                }
            }

            Section("About") {
                LabeledContent("Version", value: "0.1.0")
                LabeledContent("Build", value: "Phase 4")
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - GitHub Sync Settings

struct GitHubSyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("githubRepo") private var githubRepo = ""
    @AppStorage("githubSyncEnabled") private var syncEnabled = false

    @State private var tokenInput = ""
    @State private var hasToken = false
    @State private var showTokenField = false
    @State private var showConflicts = false

    private var syncService: GitHubSyncService { .shared }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Sync", isOn: $syncEnabled)
            } footer: {
                Text("Sync your data to a private GitHub repository. You need a personal access token with repo scope.")
            }

            if syncEnabled {
                Section("Repository") {
                    TextField("owner/repo", text: $githubRepo)
                        .textContentType(.URL)
                        #if os(iOS)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        #endif
                }

                Section("Token") {
                    if hasToken && !showTokenField {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Token saved in Keychain")
                            Spacer()
                            Button("Change") { showTokenField = true }
                        }
                    } else {
                        SecureField("ghp_...", text: $tokenInput)
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                        Button("Save Token") {
                            if !tokenInput.isEmpty {
                                KeychainService.shared.githubToken = tokenInput
                                tokenInput = ""
                                hasToken = true
                                showTokenField = false
                            }
                        }
                        .disabled(tokenInput.isEmpty)
                    }

                    if hasToken {
                        Button("Remove Token", role: .destructive) {
                            KeychainService.shared.githubToken = nil
                            hasToken = false
                            showTokenField = false
                        }
                    }
                }

                Section("Sync") {
                    Button {
                        Task {
                            await syncService.sync(context: modelContext)
                        }
                    } label: {
                        HStack {
                            Text("Sync Now")
                            Spacer()
                            if syncService.isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(syncService.isSyncing || !syncService.isConfigured)
                }

                Section("Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        statusBadge
                    }
                    if let date = syncService.lastSyncDate {
                        LabeledContent("Last Sync") {
                            Text(date, style: .relative)
                        }
                    }
                    if let error = syncService.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    if !syncService.conflicts.isEmpty {
                        Button {
                            showConflicts = true
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("\(syncService.conflicts.count) conflict\(syncService.conflicts.count == 1 ? "" : "s") detected")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("GitHub Sync")
        .onAppear {
            hasToken = KeychainService.shared.githubToken != nil
        }
        .sheet(isPresented: $showConflicts) {
            ConflictResolutionView(
                conflicts: syncService.conflicts,
                onResolve: { conflict, resolution in
                    syncService.conflicts.removeAll { $0.id == conflict.id }
                },
                onResolveAll: { resolution in
                    syncService.conflicts.removeAll()
                }
            )
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch syncService.syncStatus {
        case .idle:
            Text("Not synced").foregroundStyle(.secondary)
        case .syncing:
            Text("Syncing...").foregroundStyle(.blue)
        case .synced:
            Text("Synced").foregroundStyle(.green)
        case .error:
            Text("Error").foregroundStyle(.red)
        }
    }
}
