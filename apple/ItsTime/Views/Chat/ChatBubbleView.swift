import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    let isOwnMessage: Bool
    let collaborators: [Collaborator]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isOwnMessage { Spacer(minLength: 40) }

            if !isOwnMessage {
                avatar
            }

            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 2) {
                if !isOwnMessage {
                    Text(message.authorName)
                        .font(.caption2.bold())
                        .foregroundStyle(Color(hex: message.authorColor))
                }

                // Task reference card
                if let taskTitle = message.referencedTaskTitle {
                    HStack(spacing: 6) {
                        Image(systemName: "checklist")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(taskTitle)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Message text with highlighted mentions
                mentionHighlightedText
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isOwnMessage ? Color.blue : Color.secondary.opacity(0.12))
                    .foregroundStyle(isOwnMessage ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.createdAt, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            if isOwnMessage {
                avatar
            }

            if !isOwnMessage { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color(hex: message.authorColor))
                .frame(width: 28, height: 28)
            Text(initials(message.authorName))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var mentionHighlightedText: some View {
        let parts = parseMentionParts(message.text)
        if parts.count == 1 && !parts[0].isMention {
            Text(parts[0].text)
        } else {
            parts.reduce(Text("")) { result, part in
                if part.isMention {
                    result + Text(part.text)
                        .bold()
                        .foregroundColor(isOwnMessage ? .white.opacity(0.9) : .blue)
                } else {
                    result + Text(part.text)
                }
            }
        }
    }

    // MARK: - Helpers

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    private func parseMentionParts(_ text: String) -> [MentionPart] {
        var parts: [MentionPart] = []
        let pattern = "@(\\w+(?:\\s\\w+)?)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [MentionPart(text: text, isMention: false)]
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var lastEnd = 0
        for match in matches {
            let matchRange = match.range
            // Add text before this match
            if matchRange.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: matchRange.location - lastEnd)
                parts.append(MentionPart(text: nsText.substring(with: beforeRange), isMention: false))
            }
            // Add the mention
            let mentionText = nsText.substring(with: matchRange)
            let mentionName = nsText.substring(with: match.range(at: 1))
            let isRealMention = collaborators.contains {
                $0.name.localizedCaseInsensitiveCompare(mentionName) == .orderedSame ||
                $0.name.split(separator: " ").first?.lowercased() == mentionName.lowercased()
            }
            parts.append(MentionPart(text: mentionText, isMention: isRealMention))
            lastEnd = matchRange.location + matchRange.length
        }

        // Add remaining text
        if lastEnd < nsText.length {
            let remaining = NSRange(location: lastEnd, length: nsText.length - lastEnd)
            parts.append(MentionPart(text: nsText.substring(with: remaining), isMention: false))
        }

        if parts.isEmpty {
            parts.append(MentionPart(text: text, isMention: false))
        }

        return parts
    }
}

private struct MentionPart {
    let text: String
    let isMention: Bool
}
