import SwiftUI
import SwiftData

struct CommentsView: View {
    let task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]

    @State private var newCommentText = ""
    @State private var replyingTo: Comment?

    private var currentUser: Collaborator? {
        collaborators.first { $0.isCurrentUser }
    }

    private var topLevelComments: [Comment] {
        task.comments
            .filter { $0.isTopLevel }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            if topLevelComments.isEmpty {
                ContentUnavailableView {
                    Label("No Comments", systemImage: "text.bubble")
                } description: {
                    Text("Start the conversation.")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(topLevelComments) { comment in
                            CommentBubble(comment: comment, onReply: { replyingTo = comment }, onDelete: { deleteComment(comment) })

                            // Replies
                            let replies = comment.replies.sorted { $0.createdAt < $1.createdAt }
                            if !replies.isEmpty {
                                ForEach(replies) { reply in
                                    CommentBubble(comment: reply, isReply: true, onDelete: { deleteComment(reply) })
                                }
                                .padding(.leading, 40)
                            }
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Compose bar
            VStack(spacing: 4) {
                if let replyingTo {
                    HStack {
                        Text("Replying to \(replyingTo.authorName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            self.replyingTo = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 10) {
                    if let user = currentUser {
                        avatarCircle(initials: user.initials, color: user.color)
                    }
                    TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                        .lineLimit(1...5)
                        .textFieldStyle(.plain)

                    Button {
                        addComment()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(newCommentText.isEmpty ? Color.secondary : Color.blue)
                    }
                    .disabled(newCommentText.isEmpty || currentUser == nil)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Comments")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func addComment() {
        guard let user = currentUser, !newCommentText.isEmpty else { return }

        let comment = Comment(
            text: newCommentText,
            authorName: user.name,
            authorId: user.id,
            authorColor: user.color,
            parentId: replyingTo?.id,
            task: task
        )

        if let parent = replyingTo {
            parent.replies.append(comment)
        }

        task.comments.append(comment)
        modelContext.insert(comment)
        task.updatedAt = Date()

        // Log activity
        let activity = ActivityEntry(
            action: .commented,
            authorName: user.name,
            authorId: user.id,
            task: task
        )
        task.activityLog.append(activity)
        modelContext.insert(activity)

        newCommentText = ""
        replyingTo = nil
    }

    private func deleteComment(_ comment: Comment) {
        task.comments.removeAll { $0.id == comment.id }
        modelContext.delete(comment)
    }

    private func avatarCircle(initials: String, color: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 28, height: 28)
            Text(initials)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Comment Bubble

struct CommentBubble: View {
    let comment: Comment
    var isReply: Bool = false
    var onReply: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: comment.authorColor))
                    .frame(width: isReply ? 24 : 30, height: isReply ? 24 : 30)
                Text(initials(comment.authorName))
                    .font(.system(size: isReply ? 9 : 11, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(comment.text)
                    .font(.subheadline)

                if !isReply {
                    HStack(spacing: 16) {
                        if let onReply {
                            Button("Reply") { onReply() }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .contextMenu {
            if let onDelete {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    onDelete()
                }
            }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}
