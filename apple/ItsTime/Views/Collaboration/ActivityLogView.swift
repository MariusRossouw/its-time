import SwiftUI
import SwiftData

struct ActivityLogView: View {
    let task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collaborator.name) private var collaborators: [Collaborator]

    @State private var newCommentText = ""
    @State private var replyingTo: ActivityEntry?

    private var currentUser: Collaborator? {
        collaborators.first { $0.isCurrentUser }
    }

    private var sortedEntries: [ActivityEntry] {
        task.activityLog
            .filter { $0.parentCommentId == nil }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            if sortedEntries.isEmpty {
                ContentUnavailableView {
                    Label("No Activity", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Changes and comments will appear here.")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sortedEntries) { entry in
                            if entry.isComment {
                                commentBubble(entry, isReply: false)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)

                                // Replies
                                let replies = entry.replies.sorted { $0.timestamp < $1.timestamp }
                                ForEach(replies) { reply in
                                    commentBubble(reply, isReply: true)
                                        .padding(.leading, 52)
                                        .padding(.trailing)
                                        .padding(.vertical, 4)
                                }
                            } else {
                                activityRow(entry)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Divider()

            // Compose bar
            composeBar
        }
        .navigationTitle("Activity")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Activity Row (system events)

    @ViewBuilder
    private func activityRow(_ entry: ActivityEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(iconColor(entry.action).opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(iconColor(entry.action))
                )

            VStack(alignment: .leading, spacing: 3) {
                styledText(for: entry)
                    .font(.subheadline)

                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Comment Bubble

    @ViewBuilder
    private func commentBubble(_ entry: ActivityEntry, isReply: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            avatarCircle(
                name: entry.authorName,
                color: entry.authorColor ?? "#007AFF",
                size: isReply ? 24 : 30
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.authorName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(entry.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let text = entry.commentText {
                    Text(text)
                        .font(.subheadline)
                }

                if !isReply {
                    Button("Reply") {
                        replyingTo = entry
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteComment(entry)
            }
        }
    }

    // MARK: - Compose Bar

    private var composeBar: some View {
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
                    avatarCircle(name: user.name, color: user.color, size: 28)
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

    // MARK: - Actions

    private func addComment() {
        guard let user = currentUser, !newCommentText.isEmpty else { return }

        let entry = ActivityEntry(
            action: .commented,
            authorName: user.name,
            authorId: user.id,
            commentText: newCommentText,
            authorColor: user.color,
            parentCommentId: replyingTo?.id,
            task: task
        )

        if let parent = replyingTo {
            parent.replies.append(entry)
        }

        task.activityLog.append(entry)
        modelContext.insert(entry)
        task.updatedAt = Date()

        newCommentText = ""
        replyingTo = nil
    }

    private func deleteComment(_ entry: ActivityEntry) {
        // Remove replies first
        for reply in entry.replies {
            task.activityLog.removeAll { $0.id == reply.id }
            modelContext.delete(reply)
        }
        task.activityLog.removeAll { $0.id == entry.id }
        modelContext.delete(entry)
    }

    // MARK: - Avatar

    private func avatarCircle(name: String, color: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: color))
                .frame(width: size, height: size)
            Text(initials(name))
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
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

    // MARK: - Styled Text

    private func styledText(for entry: ActivityEntry) -> Text {
        let name = Text(entry.authorName).bold()

        switch entry.action {
        case .created:
            return name + Text(" created this task")
        case .completed:
            return name + Text(" marked this as ") + Text("done").foregroundColor(.green).bold()
        case .reopened:
            return name + Text(" reopened this task")
        case .assigned:
            if let newValue = entry.newValue {
                return name + Text(" assigned to ") + Text(newValue).bold()
            }
            return name + Text(" removed the assignee")
        case .commented:
            return name + Text(" added a comment")
        case .moved:
            if let oldValue = entry.oldValue, let newValue = entry.newValue {
                return name + Text(" moved from ") + Text(oldValue).bold() + Text(" to ") + Text(newValue).bold()
            } else if let newValue = entry.newValue {
                return name + Text(" moved to ") + Text(newValue).bold()
            } else if let oldValue = entry.oldValue {
                return name + Text(" removed from ") + Text(oldValue).bold()
            }
            return name + Text(" moved this task")
        case .fieldChanged:
            return fieldChangedText(name: name, entry: entry)
        case .wontDo:
            return name + Text(" marked this as ") + Text("won't do").foregroundColor(.gray).bold()
        case .tagAdded:
            return name + Text(" added tag ") + Text(entry.newValue ?? "").foregroundColor(.indigo).bold()
        case .tagRemoved:
            return name + Text(" removed tag ") + Text(entry.oldValue ?? "").foregroundColor(.indigo).bold()
        case .subtaskAdded:
            return name + Text(" added subtask \"\(entry.newValue ?? "")\"")
        case .subtaskCompleted:
            return name + Text(" completed subtask \"\(entry.newValue ?? "")\"")
        case .subtaskUncompleted:
            return name + Text(" unchecked subtask \"\(entry.newValue ?? "")\"")
        case .childAdded:
            return name + Text(" added child \"\(entry.newValue ?? "")\"")
        case .childRemoved:
            return name + Text(" removed child \"\(entry.oldValue ?? "")\"")
        case .habitLinked:
            return name + Text(" linked habit ") + Text("\"\(entry.newValue ?? "")\"").foregroundColor(.green).bold()
        case .habitUnlinked:
            return name + Text(" unlinked habit \"\(entry.oldValue ?? "")\"")
        case .reminderAdded:
            return name + Text(" added reminder: ") + Text(entry.newValue ?? "").bold()
        case .reminderRemoved:
            return name + Text(" removed reminder: ") + Text(entry.oldValue ?? "").bold()
        case .converted:
            return name + Text(" converted to ") + Text(entry.newValue ?? "task").bold()
        case .parentChanged:
            if let newValue = entry.newValue {
                return name + Text(" set parent to \"\(newValue)\"")
            } else if let oldValue = entry.oldValue {
                return name + Text(" removed parent \"\(oldValue)\"")
            }
            return name + Text(" changed the parent task")
        }
    }

    private func fieldChangedText(name: Text, entry: ActivityEntry) -> Text {
        if let field = entry.field, let oldValue = entry.oldValue, let newValue = entry.newValue {
            return name + Text(" changed the \(field) from ")
                + Text(oldValue).bold()
                + Text(" to ")
                + Text(newValue).foregroundColor(highlightColor(for: field, value: newValue)).bold()
        } else if let field = entry.field, let newValue = entry.newValue {
            return name + Text(" set \(field) to ")
                + Text(newValue).foregroundColor(highlightColor(for: field, value: newValue)).bold()
        } else if let field = entry.field, let oldValue = entry.oldValue {
            return name + Text(" cleared \(field)") + Text(" (was \(oldValue))").foregroundColor(.secondary)
        } else if let field = entry.field {
            return name + Text(" changed \(field)")
        }
        return name + Text(" updated this task")
    }

    // MARK: - Colors

    private func highlightColor(for field: String, value: String) -> Color {
        let lower = value.lowercased()
        if field.lowercased() == "priority" {
            switch lower {
            case "critical", "urgent": return .red
            case "high": return .orange
            case "medium": return .yellow
            case "low": return .blue
            case "none": return .secondary
            default: return .primary
            }
        }
        if field.lowercased() == "status" {
            switch lower {
            case "done", "completed": return .green
            case "in progress": return .blue
            case "blocked": return .red
            default: return .primary
            }
        }
        return .primary
    }

    private func iconColor(_ action: ActivityAction) -> Color {
        switch action {
        case .created: return .blue
        case .completed: return .green
        case .reopened: return .orange
        case .assigned: return .purple
        case .commented: return .blue
        case .moved: return .teal
        case .fieldChanged: return .secondary
        case .wontDo: return .gray
        case .tagAdded: return .indigo
        case .tagRemoved: return .indigo
        case .subtaskAdded: return .blue
        case .subtaskCompleted: return .green
        case .subtaskUncompleted: return .orange
        case .childAdded: return .teal
        case .childRemoved: return .red
        case .habitLinked: return .green
        case .habitUnlinked: return .orange
        case .reminderAdded: return .yellow
        case .reminderRemoved: return .secondary
        case .converted: return .purple
        case .parentChanged: return .teal
        }
    }
}
