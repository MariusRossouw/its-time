import Foundation
import SwiftData

@MainActor
@Observable
final class GitHubSyncService {
    static let shared = GitHubSyncService()

    var isSyncing = false
    var lastSyncDate: Date?
    var lastError: String?
    var syncStatus: SyncStatus = .idle
    var conflicts: [SyncConflict] = []

    private let keychain = KeychainService.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    // MARK: - Configuration

    private var token: String? { keychain.githubToken }

    private var repo: String? {
        let r = UserDefaults.standard.string(forKey: "githubRepo") ?? ""
        return r.isEmpty ? nil : r
    }

    var isConfigured: Bool {
        token != nil && repo != nil
    }

    // MARK: - Sync

    /// Legacy single-repo sync — now delegates to syncAllProfiles.
    func sync(context: ModelContext) async {
        await syncAllProfiles(context: context)
    }

    /// Sync all enabled SyncProfiles sequentially.
    func syncAllProfiles(context: ModelContext) async {
        guard !isSyncing else { return }

        let profiles = (try? context.fetch(FetchDescriptor<SyncProfile>())) ?? []
        let enabledProfiles = profiles.filter { $0.isEnabled && !$0.repoPath.isEmpty && KeychainService.shared.load(key: $0.tokenKeychainKey) != nil }

        // Fallback: if no profiles exist but old-style config is present, use legacy sync
        if enabledProfiles.isEmpty {
            guard let token, let repo else {
                // No profiles and no legacy config — nothing to do
                return
            }
            isSyncing = true
            syncStatus = .syncing
            lastError = nil

            do {
                try await pushAll(context: context, token: token, repo: repo)
                try await pullAll(context: context, token: token, repo: repo)
                lastSyncDate = Date()
                UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
                syncStatus = .synced
            } catch {
                lastError = error.localizedDescription
                syncStatus = .error
            }

            isSyncing = false
            return
        }

        isSyncing = true
        syncStatus = .syncing
        lastError = nil
        var anyError = false

        for profile in enabledProfiles {
            await syncProfile(profile, context: context)
            if profile.lastError != nil { anyError = true }
        }

        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
        syncStatus = anyError ? .error : .synced
        if anyError {
            lastError = "One or more profiles had errors"
        }
        isSyncing = false
    }

    /// Sync a single profile — push scoped lists/tasks, pull from its repo.
    func syncProfile(_ profile: SyncProfile, context: ModelContext) async {
        guard let token = KeychainService.shared.load(key: profile.tokenKeychainKey) else {
            profile.lastError = "No token configured"
            return
        }
        let repo = profile.repoPath
        guard !repo.isEmpty else {
            profile.lastError = "No repo configured"
            return
        }

        profile.lastError = nil

        do {
            try await pushForProfile(profile: profile, context: context, token: token, repo: repo)
            try await pullForProfile(profile: profile, context: context, token: token, repo: repo)
            profile.lastSyncDate = Date()
            profile.updatedAt = Date()
        } catch {
            profile.lastError = error.localizedDescription
        }
    }

    // MARK: - Profile-scoped Push

    private func pushForProfile(profile: SyncProfile, context: ModelContext, token: String, repo: String) async throws {
        let profileId = profile.id

        // Lists assigned to this profile
        let allLists = try context.fetch(FetchDescriptor<TaskList>())
        let lists = allLists.filter { $0.syncProfileId == profileId }
        let listIds = Set(lists.map(\.id))

        // Tasks belonging to those lists
        let allTasks = try context.fetch(FetchDescriptor<TaskItem>())
        let tasks = allTasks.filter { task in
            guard let listId = task.list?.id else { return false }
            return listIds.contains(listId)
        }

        // Push lists
        for list in lists {
            let data = try encoder.encode(ListSyncDTO(from: list))
            try await pushFile(path: "data/lists/\(list.id.uuidString).json", content: data, token: token, repo: repo)
        }

        // Push tasks
        for task in tasks {
            let data = try encoder.encode(TaskSyncDTO(from: task))
            try await pushFile(path: "data/tasks/\(task.id.uuidString).json", content: data, token: token, repo: repo)
        }

        // Push comments for scoped tasks
        let taskIds = Set(tasks.map(\.id))
        let allComments = try context.fetch(FetchDescriptor<Comment>())
        let commentsByTask = Dictionary(grouping: allComments.filter { taskIds.contains($0.task?.id ?? UUID()) }) { $0.task?.id ?? UUID() }
        for (taskId, taskComments) in commentsByTask {
            let dtos = taskComments.map { CommentSyncDTO(from: $0) }
            let data = try encoder.encode(dtos)
            try await pushFile(path: "data/comments/\(taskId.uuidString).json", content: data, token: token, repo: repo)
        }

        // Push chat messages for scoped channels (list UUID channels + general)
        let chatMessages = try context.fetch(FetchDescriptor<ChatMessage>())
        let channelIds = Set(lists.map { $0.id.uuidString } + ["general"])
        let scopedMessages = chatMessages.filter { channelIds.contains($0.channelId) }
        let messagesByChannel = Dictionary(grouping: scopedMessages) { $0.channelId }
        for (channelId, messages) in messagesByChannel {
            let dtos = messages.map { ChatMessageSyncDTO(from: $0) }
            let data = try encoder.encode(dtos)
            try await pushFile(path: "data/chat/\(channelId).json", content: data, token: token, repo: repo)
        }

        // Global entities: collaborators, tags, folders, focus sessions — push to all profiles
        let collaborators = try context.fetch(FetchDescriptor<Collaborator>())
        let collabDTOs = collaborators.map { CollaboratorSyncDTO(from: $0) }
        try await pushFile(path: "data/collaborators/collaborators.json", content: try encoder.encode(collabDTOs), token: token, repo: repo)

        let tags = try context.fetch(FetchDescriptor<Tag>())
        let tagDTOs = tags.map { TagSyncDTO(from: $0) }
        try await pushFile(path: "data/tags/tags.json", content: try encoder.encode(tagDTOs), token: token, repo: repo)

        let folders = try context.fetch(FetchDescriptor<Folder>())
        for folder in folders {
            let data = try encoder.encode(FolderSyncDTO(from: folder))
            try await pushFile(path: "data/folders/\(folder.id.uuidString).json", content: data, token: token, repo: repo)
        }

        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let sessionDTOs = sessions.map { FocusSessionSyncDTO(from: $0) }
        try await pushFile(path: "data/focus/sessions.json", content: try encoder.encode(sessionDTOs), token: token, repo: repo)

        // Sync metadata
        let meta = SyncMeta(lastSync: Date(), deviceId: DeviceInfo.deviceId, schemaVersion: 2)
        try await pushFile(path: "data/sync_meta.json", content: try encoder.encode(meta), token: token, repo: repo)
    }

    // MARK: - Profile-scoped Pull

    private func pullForProfile(profile: SyncProfile, context: ModelContext, token: String, repo: String) async throws {
        let profileId = profile.id

        // Pull lists — set syncProfileId on pulled lists
        let listFilePaths = try await listFiles(path: "data/lists", token: token, repo: repo)
        for file in listFilePaths where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dto = try decoder.decode(ListSyncDTO.self, from: data)
                try mergeList(dto: dto, context: context, syncProfileId: profileId)
            }
        }

        // Pull tasks
        let taskFiles = try await listFiles(path: "data/tasks", token: token, repo: repo)
        for file in taskFiles where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dto = try decoder.decode(TaskSyncDTO.self, from: data)
                try mergeTask(dto: dto, context: context)
            }
        }

        // Pull collaborators (global)
        if let collabData = try await pullFile(path: "data/collaborators/collaborators.json", token: token, repo: repo) {
            let dtos = try decoder.decode([CollaboratorSyncDTO].self, from: collabData)
            for dto in dtos {
                try mergeCollaborator(dto: dto, context: context)
            }
        }

        // Pull tags (global)
        if let tagData = try await pullFile(path: "data/tags/tags.json", token: token, repo: repo) {
            let dtos = try decoder.decode([TagSyncDTO].self, from: tagData)
            for dto in dtos {
                try mergeTag(dto: dto, context: context)
            }
        }

        // Pull comments
        let commentFiles = try await listFiles(path: "data/comments", token: token, repo: repo)
        for file in commentFiles where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dtos = try decoder.decode([CommentSyncDTO].self, from: data)
                for dto in dtos {
                    try mergeComment(dto: dto, context: context)
                }
            }
        }

        // Pull chat messages
        let chatFiles = try await listFiles(path: "data/chat", token: token, repo: repo)
        for file in chatFiles where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dtos = try decoder.decode([ChatMessageSyncDTO].self, from: data)
                for dto in dtos {
                    try mergeChatMessage(dto: dto, context: context)
                }
            }
        }
    }

    // MARK: - Push

    private func pushAll(context: ModelContext, token: String, repo: String) async throws {
        // Fetch all entities
        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        let lists = try context.fetch(FetchDescriptor<TaskList>())
        let folders = try context.fetch(FetchDescriptor<Folder>())
        let tags = try context.fetch(FetchDescriptor<Tag>())
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())

        // Serialize and push tasks
        for task in tasks {
            let data = try encoder.encode(TaskSyncDTO(from: task))
            try await pushFile(path: "data/tasks/\(task.id.uuidString).json", content: data, token: token, repo: repo)
        }

        // Push lists
        for list in lists {
            let data = try encoder.encode(ListSyncDTO(from: list))
            try await pushFile(path: "data/lists/\(list.id.uuidString).json", content: data, token: token, repo: repo)
        }

        // Push folders
        for folder in folders {
            let data = try encoder.encode(FolderSyncDTO(from: folder))
            try await pushFile(path: "data/folders/\(folder.id.uuidString).json", content: data, token: token, repo: repo)
        }

        // Push tags as single file
        let tagDTOs = tags.map { TagSyncDTO(from: $0) }
        let tagData = try encoder.encode(tagDTOs)
        try await pushFile(path: "data/tags/tags.json", content: tagData, token: token, repo: repo)

        // Push focus sessions
        let sessionDTOs = sessions.map { FocusSessionSyncDTO(from: $0) }
        let sessionData = try encoder.encode(sessionDTOs)
        try await pushFile(path: "data/focus/sessions.json", content: sessionData, token: token, repo: repo)

        // Push collaborators
        let collaborators = try context.fetch(FetchDescriptor<Collaborator>())
        let collabDTOs = collaborators.map { CollaboratorSyncDTO(from: $0) }
        let collabData = try encoder.encode(collabDTOs)
        try await pushFile(path: "data/collaborators/collaborators.json", content: collabData, token: token, repo: repo)

        // Push comments per task
        let comments = try context.fetch(FetchDescriptor<Comment>())
        let commentsByTask = Dictionary(grouping: comments) { $0.task?.id ?? UUID() }
        for (taskId, taskComments) in commentsByTask {
            let dtos = taskComments.map { CommentSyncDTO(from: $0) }
            let data = try encoder.encode(dtos)
            try await pushFile(path: "data/comments/\(taskId.uuidString).json", content: data, token: token, repo: repo)
        }

        // Push chat messages per channel
        let chatMessages = try context.fetch(FetchDescriptor<ChatMessage>())
        let messagesByChannel = Dictionary(grouping: chatMessages) { $0.channelId }
        for (channelId, messages) in messagesByChannel {
            let dtos = messages.map { ChatMessageSyncDTO(from: $0) }
            let data = try encoder.encode(dtos)
            try await pushFile(path: "data/chat/\(channelId).json", content: data, token: token, repo: repo)
        }

        // Push sync metadata
        let meta = SyncMeta(
            lastSync: Date(),
            deviceId: DeviceInfo.deviceId,
            schemaVersion: 1
        )
        let metaData = try encoder.encode(meta)
        try await pushFile(path: "data/sync_meta.json", content: metaData, token: token, repo: repo)
    }

    // MARK: - Pull

    private func pullAll(context: ModelContext, token: String, repo: String) async throws {
        // Pull task files
        let taskFiles = try await listFiles(path: "data/tasks", token: token, repo: repo)
        for file in taskFiles where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dto = try decoder.decode(TaskSyncDTO.self, from: data)
                try mergeTask(dto: dto, context: context)
            }
        }

        // Pull list files
        let listFilePaths = try await listFiles(path: "data/lists", token: token, repo: repo)
        for file in listFilePaths where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dto = try decoder.decode(ListSyncDTO.self, from: data)
                try mergeList(dto: dto, context: context)
            }
        }

        // Pull tags
        if let tagData = try await pullFile(path: "data/tags/tags.json", token: token, repo: repo) {
            let dtos = try decoder.decode([TagSyncDTO].self, from: tagData)
            for dto in dtos {
                try mergeTag(dto: dto, context: context)
            }
        }

        // Pull collaborators
        if let collabData = try await pullFile(path: "data/collaborators/collaborators.json", token: token, repo: repo) {
            let dtos = try decoder.decode([CollaboratorSyncDTO].self, from: collabData)
            for dto in dtos {
                try mergeCollaborator(dto: dto, context: context)
            }
        }

        // Pull comments
        let commentFiles = try await listFiles(path: "data/comments", token: token, repo: repo)
        for file in commentFiles where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dtos = try decoder.decode([CommentSyncDTO].self, from: data)
                for dto in dtos {
                    try mergeComment(dto: dto, context: context)
                }
            }
        }

        // Pull chat messages
        let chatFiles = try await listFiles(path: "data/chat", token: token, repo: repo)
        for file in chatFiles where file.hasSuffix(".json") {
            if let data = try await pullFile(path: file, token: token, repo: repo) {
                let dtos = try decoder.decode([ChatMessageSyncDTO].self, from: data)
                for dto in dtos {
                    try mergeChatMessage(dto: dto, context: context)
                }
            }
        }
    }

    // MARK: - GitHub API

    private func pushFile(path: String, content: Data, token: String, repo: String) async throws {
        let base64 = content.base64EncodedString()
        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!

        // Check if file exists (to get SHA for update)
        var sha: String?
        var getRequest = URLRequest(url: url)
        getRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        getRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        if let (data, response) = try? await URLSession.shared.data(for: getRequest),
           let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                sha = json["sha"] as? String
            }
        }

        // Create or update file
        var body: [String: Any] = [
            "message": "sync: update \(path)",
            "content": base64
        ]
        if let sha {
            body["sha"] = sha
        }

        var putRequest = URLRequest(url: url)
        putRequest.httpMethod = "PUT"
        putRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        putRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        putRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, putResponse) = try await URLSession.shared.data(for: putRequest)
        guard let httpResponse = putResponse as? HTTPURLResponse,
              (200...201).contains(httpResponse.statusCode) else {
            throw SyncError.pushFailed(path)
        }
    }

    private func pullFile(path: String, token: String, repo: String) async throws -> Data? {
        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return nil }

        if httpResponse.statusCode == 404 { return nil }
        guard httpResponse.statusCode == 200 else { return nil }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base64Content = json["content"] as? String else { return nil }

        let cleaned = base64Content.replacingOccurrences(of: "\n", with: "")
        return Data(base64Encoded: cleaned)
    }

    private func listFiles(path: String, token: String, repo: String) async throws -> [String] {
        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        guard let items = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return items.compactMap { $0["path"] as? String }
    }

    // MARK: - Merge (last-write-wins)

    private func mergeTask(dto: TaskSyncDTO, context: ModelContext) throws {
        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == dto.id })
        let existing = try context.fetch(descriptor).first

        if let existing {
            // Detect conflicts before overwriting
            let detected = detectConflicts(dto: dto, existing: existing)
            if !detected.isEmpty {
                conflicts.append(contentsOf: detected)
            }

            // Last-write-wins: only update if remote is newer
            if dto.updatedAt > existing.updatedAt {
                existing.title = dto.title
                existing.taskDescription = dto.taskDescription
                existing.status = dto.status
                existing.priority = dto.priority
                existing.dueDate = dto.dueDate
                existing.startDate = dto.startDate
                existing.completedAt = dto.completedAt
                existing.sortOrder = dto.sortOrder
                existing.reminderOffsets = dto.reminderOffsets
                existing.timePreference = dto.timePreference
                existing.recurrenceType = dto.recurrenceType
                existing.recurrenceInterval = dto.recurrenceInterval
                existing.recurrenceWeekdays = dto.recurrenceWeekdays
                existing.recurrenceBasedOnCompletion = dto.recurrenceBasedOnCompletion
                existing.recurrenceEndDate = dto.recurrenceEndDate
                existing.assignedTo = dto.assignedTo
                existing.assignedToName = dto.assignedToName
                existing.isNote = dto.isNote
                existing.updatedAt = dto.updatedAt
            }
        } else {
            // New task from remote
            let task = TaskItem(title: dto.title)
            task.id = dto.id
            task.taskDescription = dto.taskDescription
            task.status = dto.status
            task.priority = dto.priority
            task.dueDate = dto.dueDate
            task.startDate = dto.startDate
            task.completedAt = dto.completedAt
            task.sortOrder = dto.sortOrder
            task.reminderOffsets = dto.reminderOffsets
            task.timePreference = dto.timePreference
            task.recurrenceType = dto.recurrenceType
            task.recurrenceInterval = dto.recurrenceInterval
            task.recurrenceWeekdays = dto.recurrenceWeekdays
            task.recurrenceBasedOnCompletion = dto.recurrenceBasedOnCompletion
            task.recurrenceEndDate = dto.recurrenceEndDate
            task.assignedTo = dto.assignedTo
            task.assignedToName = dto.assignedToName
            task.isNote = dto.isNote
            task.createdAt = dto.createdAt
            task.updatedAt = dto.updatedAt
            task.deviceId = dto.deviceId
            context.insert(task)
        }

        // Resolve parent relationship
        if let parentId = dto.parentTaskId {
            let parentDescriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == parentId })
            if let parent = try? context.fetch(parentDescriptor).first {
                let target = existing ?? (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == dto.id })).first)
                target?.parentTask = parent
            }
        }
    }

    private func mergeList(dto: ListSyncDTO, context: ModelContext, syncProfileId: UUID? = nil) throws {
        let descriptor = FetchDescriptor<TaskList>(predicate: #Predicate { $0.id == dto.id })
        let existing = try context.fetch(descriptor).first

        if let existing {
            if dto.updatedAt > existing.updatedAt {
                existing.name = dto.name
                existing.color = dto.color
                existing.icon = dto.icon
                existing.sortOrder = dto.sortOrder
                existing.updatedAt = dto.updatedAt
            }
            // Ensure pulled list is linked to this profile
            if let syncProfileId {
                existing.syncProfileId = syncProfileId
                existing.isShared = true
            }
        } else {
            let list = TaskList(name: dto.name, color: dto.color, icon: dto.icon, isInbox: dto.isInbox, sortOrder: dto.sortOrder)
            list.id = dto.id
            list.createdAt = dto.createdAt
            list.updatedAt = dto.updatedAt
            if let syncProfileId {
                list.syncProfileId = syncProfileId
                list.isShared = true
            }
            context.insert(list)
        }
    }

    private func mergeTag(dto: TagSyncDTO, context: ModelContext) throws {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == dto.id })
        let existing = try context.fetch(descriptor).first

        if existing == nil {
            let tag = Tag(name: dto.name, color: dto.color, sortOrder: dto.sortOrder)
            tag.id = dto.id
            context.insert(tag)
        }
    }

    private func mergeCollaborator(dto: CollaboratorSyncDTO, context: ModelContext) throws {
        let descriptor = FetchDescriptor<Collaborator>(predicate: #Predicate { $0.id == dto.id })
        let existing = try context.fetch(descriptor).first

        if let existing {
            if dto.updatedAt > existing.updatedAt {
                existing.name = dto.name
                existing.email = dto.email
                existing.githubUsername = dto.githubUsername
                existing.initials = dto.initials
                existing.color = dto.color
                existing.updatedAt = dto.updatedAt
            }
        } else {
            let collab = Collaborator(name: dto.name, email: dto.email, githubUsername: dto.githubUsername, color: dto.color)
            collab.id = dto.id
            collab.initials = dto.initials
            collab.createdAt = dto.createdAt
            collab.updatedAt = dto.updatedAt
            context.insert(collab)
        }
    }

    private func mergeComment(dto: CommentSyncDTO, context: ModelContext) throws {
        let descriptor = FetchDescriptor<Comment>(predicate: #Predicate { $0.id == dto.id })
        let existing = try context.fetch(descriptor).first

        if existing == nil {
            let comment = Comment(
                text: dto.text,
                authorName: dto.authorName,
                authorId: dto.authorId,
                authorColor: dto.authorColor,
                parentId: dto.parentId
            )
            comment.id = dto.id
            comment.createdAt = dto.createdAt
            comment.updatedAt = dto.updatedAt

            // Link to task
            if let taskId = dto.taskId {
                let taskDescriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == taskId })
                if let task = try context.fetch(taskDescriptor).first {
                    comment.task = task
                }
            }

            // Link to parent comment for replies
            if let parentId = dto.parentId {
                let parentDescriptor = FetchDescriptor<Comment>(predicate: #Predicate { $0.id == parentId })
                if let parent = try context.fetch(parentDescriptor).first {
                    parent.replies.append(comment)
                }
            }

            context.insert(comment)
        }
    }

    private func mergeChatMessage(dto: ChatMessageSyncDTO, context: ModelContext) throws {
        let descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.id == dto.id })
        let existing = try context.fetch(descriptor).first

        if existing == nil {
            let message = ChatMessage(
                text: dto.text,
                authorName: dto.authorName,
                authorId: dto.authorId,
                authorColor: dto.authorColor,
                channelId: dto.channelId
            )
            message.id = dto.id
            message.createdAt = dto.createdAt
            message.mentionIdsData = dto.mentionIdsData
            message.referencedTaskId = dto.referencedTaskId
            message.referencedTaskTitle = dto.referencedTaskTitle
            context.insert(message)
        }
    }

    // MARK: - Conflict Detection

    func detectConflicts(dto: TaskSyncDTO, existing: TaskItem) -> [SyncConflict] {
        var result: [SyncConflict] = []

        // Only detect conflicts when both sides changed since last sync
        guard let lastSync = lastSyncDate,
              existing.updatedAt > lastSync,
              dto.updatedAt > lastSync else { return [] }

        if dto.title != existing.title {
            result.append(SyncConflict(
                taskId: dto.id, taskTitle: dto.title, field: "Title",
                localValue: existing.title, remoteValue: dto.title,
                localDevice: existing.deviceId, remoteDevice: dto.deviceId,
                localUpdatedAt: existing.updatedAt, remoteUpdatedAt: dto.updatedAt
            ))
        }
        if dto.status != existing.status {
            result.append(SyncConflict(
                taskId: dto.id, taskTitle: existing.title, field: "Status",
                localValue: existing.status.rawValue, remoteValue: dto.status.rawValue,
                localDevice: existing.deviceId, remoteDevice: dto.deviceId,
                localUpdatedAt: existing.updatedAt, remoteUpdatedAt: dto.updatedAt
            ))
        }
        if dto.priority != existing.priority {
            result.append(SyncConflict(
                taskId: dto.id, taskTitle: existing.title, field: "Priority",
                localValue: existing.priority.rawValue, remoteValue: dto.priority.rawValue,
                localDevice: existing.deviceId, remoteDevice: dto.deviceId,
                localUpdatedAt: existing.updatedAt, remoteUpdatedAt: dto.updatedAt
            ))
        }
        if dto.taskDescription != existing.taskDescription {
            result.append(SyncConflict(
                taskId: dto.id, taskTitle: existing.title, field: "Description",
                localValue: String(existing.taskDescription.prefix(100)),
                remoteValue: String(dto.taskDescription.prefix(100)),
                localDevice: existing.deviceId, remoteDevice: dto.deviceId,
                localUpdatedAt: existing.updatedAt, remoteUpdatedAt: dto.updatedAt
            ))
        }

        return result
    }
}

// MARK: - Sync DTOs

struct TaskSyncDTO: Codable {
    let id: UUID
    let title: String
    let taskDescription: String
    let status: TaskStatus
    let priority: TaskPriority
    let dueDate: Date?
    let startDate: Date?
    let completedAt: Date?
    let sortOrder: Int
    let reminderOffsets: [Int]
    let timePreference: TimePreference
    let recurrenceType: RecurrenceType
    let recurrenceInterval: Int
    let recurrenceWeekdays: [Int]
    let recurrenceBasedOnCompletion: Bool
    let recurrenceEndDate: Date?
    let assignedTo: UUID?
    let assignedToName: String?
    let isNote: Bool
    let createdAt: Date
    let updatedAt: Date
    let deviceId: String
    let listId: UUID?
    let tagIds: [UUID]
    let parentTaskId: UUID?
    let schemaVersion: Int

    init(from task: TaskItem) {
        self.id = task.id
        self.title = task.title
        self.taskDescription = task.taskDescription
        self.status = task.status
        self.priority = task.priority
        self.dueDate = task.dueDate
        self.startDate = task.startDate
        self.completedAt = task.completedAt
        self.sortOrder = task.sortOrder
        self.reminderOffsets = task.reminderOffsets
        self.timePreference = task.timePreference
        self.recurrenceType = task.recurrenceType
        self.recurrenceInterval = task.recurrenceInterval
        self.recurrenceWeekdays = task.recurrenceWeekdays
        self.recurrenceBasedOnCompletion = task.recurrenceBasedOnCompletion
        self.recurrenceEndDate = task.recurrenceEndDate
        self.assignedTo = task.assignedTo
        self.assignedToName = task.assignedToName
        self.isNote = task.isNote
        self.createdAt = task.createdAt
        self.updatedAt = task.updatedAt
        self.deviceId = task.deviceId
        self.listId = task.list?.id
        self.tagIds = task.tags.map(\.id)
        self.parentTaskId = task.parentTask?.id
        self.schemaVersion = 3
    }
}

struct ListSyncDTO: Codable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let isInbox: Bool
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    let folderId: UUID?
    let syncProfileId: UUID?
    let schemaVersion: Int

    init(from list: TaskList) {
        self.id = list.id
        self.name = list.name
        self.color = list.color
        self.icon = list.icon
        self.isInbox = list.isInbox
        self.sortOrder = list.sortOrder
        self.createdAt = list.createdAt
        self.updatedAt = list.updatedAt
        self.folderId = list.folder?.id
        self.syncProfileId = list.syncProfileId
        self.schemaVersion = 2
    }
}

struct FolderSyncDTO: Codable {
    let id: UUID
    let name: String
    let sortOrder: Int
    let isExpanded: Bool
    let schemaVersion: Int

    init(from folder: Folder) {
        self.id = folder.id
        self.name = folder.name
        self.sortOrder = folder.sortOrder
        self.isExpanded = folder.isExpanded
        self.schemaVersion = 1
    }
}

struct TagSyncDTO: Codable {
    let id: UUID
    let name: String
    let color: String
    let sortOrder: Int
    let schemaVersion: Int

    init(from tag: Tag) {
        self.id = tag.id
        self.name = tag.name
        self.color = tag.color
        self.sortOrder = tag.sortOrder
        self.schemaVersion = 1
    }
}

struct FocusSessionSyncDTO: Codable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date?
    let plannedDuration: Int
    let actualDuration: Int
    let sessionType: FocusSessionType
    let isCompleted: Bool
    let taskId: UUID?
    let schemaVersion: Int

    init(from session: FocusSession) {
        self.id = session.id
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.plannedDuration = session.plannedDuration
        self.actualDuration = session.actualDuration
        self.sessionType = session.sessionType
        self.isCompleted = session.isCompleted
        self.taskId = session.task?.id
        self.schemaVersion = 1
    }
}

struct SyncMeta: Codable {
    let lastSync: Date
    let deviceId: String
    let schemaVersion: Int
}

enum SyncStatus: String {
    case idle
    case syncing
    case synced
    case error
}

struct CollaboratorSyncDTO: Codable {
    let id: UUID
    let name: String
    let email: String
    let githubUsername: String
    let initials: String
    let color: String
    let isCurrentUser: Bool
    let createdAt: Date
    let updatedAt: Date
    let schemaVersion: Int

    init(from collab: Collaborator) {
        self.id = collab.id
        self.name = collab.name
        self.email = collab.email
        self.githubUsername = collab.githubUsername
        self.initials = collab.initials
        self.color = collab.color
        self.isCurrentUser = collab.isCurrentUser
        self.createdAt = collab.createdAt
        self.updatedAt = collab.updatedAt
        self.schemaVersion = 1
    }
}

struct CommentSyncDTO: Codable {
    let id: UUID
    let text: String
    let authorName: String
    let authorId: UUID
    let authorColor: String
    let parentId: UUID?
    let taskId: UUID?
    let createdAt: Date
    let updatedAt: Date
    let schemaVersion: Int

    init(from comment: Comment) {
        self.id = comment.id
        self.text = comment.text
        self.authorName = comment.authorName
        self.authorId = comment.authorId
        self.authorColor = comment.authorColor
        self.parentId = comment.parentId
        self.taskId = comment.task?.id
        self.createdAt = comment.createdAt
        self.updatedAt = comment.updatedAt
        self.schemaVersion = 1
    }
}

struct ChatMessageSyncDTO: Codable {
    let id: UUID
    let text: String
    let authorName: String
    let authorId: UUID
    let authorColor: String
    let channelId: String
    let mentionIdsData: Data?
    let referencedTaskId: UUID?
    let referencedTaskTitle: String?
    let createdAt: Date
    let schemaVersion: Int

    init(from message: ChatMessage) {
        self.id = message.id
        self.text = message.text
        self.authorName = message.authorName
        self.authorId = message.authorId
        self.authorColor = message.authorColor
        self.channelId = message.channelId
        self.mentionIdsData = message.mentionIdsData
        self.referencedTaskId = message.referencedTaskId
        self.referencedTaskTitle = message.referencedTaskTitle
        self.createdAt = message.createdAt
        self.schemaVersion = 1
    }
}

enum SyncError: LocalizedError {
    case pushFailed(String)
    case pullFailed(String)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .pushFailed(let path): return "Failed to push \(path)"
        case .pullFailed(let path): return "Failed to pull \(path)"
        case .notConfigured: return "GitHub sync not configured"
        }
    }
}
