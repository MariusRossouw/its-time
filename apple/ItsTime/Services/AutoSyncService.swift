import Foundation
import SwiftData
import Combine

/// Manages automatic syncing with debounce.
/// Triggers a sync after a period of idle following data changes.
@MainActor @Observable
final class AutoSyncService {
    static let shared = AutoSyncService()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "autoSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "autoSyncEnabled") }
    }

    var syncInterval: TimeInterval {
        get {
            let val = UserDefaults.standard.double(forKey: "autoSyncInterval")
            return val > 0 ? val : 15.0
        }
        set { UserDefaults.standard.set(newValue, forKey: "autoSyncInterval") }
    }

    private var debounceTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private weak var modelContext: ModelContext?

    private init() {}

    /// Start the auto-sync system with a model context.
    func start(context: ModelContext) {
        self.modelContext = context
        guard isEnabled else { return }
        startPolling()
    }

    /// Stop all auto-sync activity.
    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        pollTask?.cancel()
        pollTask = nil
    }

    /// Call this whenever data changes to trigger a debounced sync.
    func notifyChange() {
        guard isEnabled else { return }

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(syncInterval))
            guard !Task.isCancelled else { return }
            await performSync()
        }
    }

    /// Start polling for remote changes periodically.
    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { return }
                // Only pull if not currently syncing from a push
                if !GitHubSyncService.shared.isSyncing {
                    await performSync()
                }
            }
        }
    }

    private func performSync() async {
        guard let context = modelContext else { return }
        await GitHubSyncService.shared.syncAllProfiles(context: context)
    }

    /// Restart polling/debounce when settings change.
    func settingsChanged() {
        stop()
        if isEnabled, modelContext != nil {
            startPolling()
        }
    }
}

// MARK: - Notification for sync triggers

extension Notification.Name {
    static let dataMutated = Notification.Name("dataMutated")
}
