import SwiftUI
import SwiftData

struct ChatListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt) private var allMessages: [ChatMessage]
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]

    private var currentUser: Collaborator? {
        collaborators.first { $0.isCurrentUser }
    }

    private var channels: [ChatChannel] {
        var result: [ChatChannel] = []

        // General channel
        let generalCount = allMessages.filter { $0.channelId == "general" }.count
        let generalLast = allMessages.filter { $0.channelId == "general" }.last
        result.append(ChatChannel(
            id: "general",
            name: "General",
            icon: "bubble.left.and.bubble.right",
            color: "#007AFF",
            messageCount: generalCount,
            lastMessage: generalLast
        ))

        // Shared list channels
        for list in lists where list.isShared {
            let listMessages = allMessages.filter { $0.channelId == list.id.uuidString }
            result.append(ChatChannel(
                id: list.id.uuidString,
                name: list.name,
                icon: list.icon,
                color: list.color,
                messageCount: listMessages.count,
                lastMessage: listMessages.last
            ))
        }

        return result
    }

    var body: some View {
        List {
            if currentUser == nil {
                Section {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .foregroundStyle(.orange)
                        Text("Set up your profile in Collaborators to start chatting.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Channels") {
                ForEach(channels) { channel in
                    NavigationLink {
                        ChatRoomView(channelId: channel.id, channelName: channel.name)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: channel.icon)
                                .foregroundStyle(Color(hex: channel.color))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(channel.name)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    if let last = channel.lastMessage {
                                        Text(last.createdAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                if let last = channel.lastMessage {
                                    Text("\(last.authorName): \(last.text)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                } else {
                                    Text("No messages yet")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            if channel.unreadCount > 0 {
                                Text("\(channel.unreadCount)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Chat")
    }
}

// MARK: - Chat Channel

struct ChatChannel: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let messageCount: Int
    let lastMessage: ChatMessage?

    var unreadCount: Int { 0 } // TODO: track read state per channel
}
