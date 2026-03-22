import SwiftUI
import SwiftData

struct ChatRoomView: View {
    let channelId: String
    let channelName: String

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt) private var allMessages: [ChatMessage]
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]
    @Query(sort: \TaskItem.sortOrder) private var tasks: [TaskItem]

    @State private var messageText = ""
    @State private var showMentionPicker = false
    @State private var showTaskPicker = false
    @State private var mentionSearchText = ""

    private var currentUser: Collaborator? {
        collaborators.first { $0.isCurrentUser }
    }

    private var channelMessages: [ChatMessage] {
        allMessages.filter { $0.channelId == channelId }
    }

    private var mentionSuggestions: [Collaborator] {
        if mentionSearchText.isEmpty { return collaborators }
        return collaborators.filter {
            $0.name.localizedCaseInsensitiveContains(mentionSearchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(channelMessages) { message in
                            ChatBubbleView(
                                message: message,
                                isOwnMessage: message.authorId == currentUser?.id,
                                collaborators: collaborators
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: channelMessages.count) {
                    if let last = channelMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let last = channelMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            // Mention suggestions
            if showMentionPicker {
                mentionSuggestionsBar
            }

            Divider()

            // Compose bar
            composeBar
        }
        .navigationTitle(channelName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showTaskPicker = true
                } label: {
                    Label("Link Task", systemImage: "link")
                }
            }
        }
        .sheet(isPresented: $showTaskPicker) {
            taskPickerSheet
        }
    }

    // MARK: - Compose Bar

    private var composeBar: some View {
        HStack(spacing: 10) {
            Button {
                showMentionPicker.toggle()
            } label: {
                Image(systemName: "at")
                    .foregroundStyle(showMentionPicker ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            TextField("Message...", text: $messageText, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .onChange(of: messageText) {
                    // Auto-show mention picker when typing @
                    if messageText.hasSuffix("@") {
                        showMentionPicker = true
                        mentionSearchText = ""
                    } else if showMentionPicker {
                        // Update search based on text after last @
                        if let atRange = messageText.range(of: "@", options: .backwards) {
                            mentionSearchText = String(messageText[atRange.upperBound...])
                        }
                    }
                }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || currentUser == nil)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Mention Suggestions

    private var mentionSuggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(mentionSuggestions) { collab in
                    Button {
                        insertMention(collab)
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: collab.color))
                                    .frame(width: 24, height: 24)
                                Text(collab.initials)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Text(collab.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(.bar)
    }

    // MARK: - Task Picker

    private var taskPickerSheet: some View {
        NavigationStack {
            List {
                let activeTasks = tasks.filter { $0.status == .todo }
                ForEach(activeTasks) { task in
                    Button {
                        linkTask(task)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.priorityColor(task.priority))
                                .frame(width: 8, height: 8)
                            Text(task.title)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Link a Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showTaskPicker = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        guard let user = currentUser else { return }
        let trimmed = messageText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let message = ChatMessage(
            text: trimmed,
            authorName: user.name,
            authorId: user.id,
            authorColor: user.color,
            channelId: channelId
        )

        // Parse and store mentions
        let mentionedIds = message.parseMentions(from: collaborators)
        if !mentionedIds.isEmpty {
            message.mentionIds = mentionedIds
            // Fire notifications for mentioned users
            for mentionId in mentionedIds where mentionId != user.id {
                if let mentioned = collaborators.first(where: { $0.id == mentionId }) {
                    NotificationService.shared.fireMentionNotification(
                        mentionedName: mentioned.name,
                        authorName: user.name,
                        messageText: trimmed,
                        channelName: channelName
                    )
                }
            }
        }

        modelContext.insert(message)
        messageText = ""
        showMentionPicker = false

        // Trigger auto-sync
        AutoSyncService.shared.notifyChange()
    }

    private func insertMention(_ collab: Collaborator) {
        // Replace text from last @ to cursor with the mention
        if let atRange = messageText.range(of: "@", options: .backwards) {
            messageText = String(messageText[messageText.startIndex..<atRange.lowerBound]) + "@\(collab.name) "
        } else {
            messageText += "@\(collab.name) "
        }
        showMentionPicker = false
    }

    private func linkTask(_ task: TaskItem) {
        guard let user = currentUser else { return }
        let message = ChatMessage(
            text: "Linked task: \(task.title)",
            authorName: user.name,
            authorId: user.id,
            authorColor: user.color,
            channelId: channelId
        )
        message.referencedTaskId = task.id
        message.referencedTaskTitle = task.title
        modelContext.insert(message)
        showTaskPicker = false

        AutoSyncService.shared.notifyChange()
    }
}
