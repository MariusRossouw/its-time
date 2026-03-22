import SwiftUI

/// Renders a Markdown string as styled SwiftUI Text
struct MarkdownTextView: View {
    let text: String

    var body: some View {
        if text.isEmpty {
            EmptyView()
        } else {
            Text(attributedMarkdown)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var attributedMarkdown: AttributedString {
        // SwiftUI's Text natively supports AttributedString from Markdown
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(text)
    }
}

/// Full markdown editor with preview toggle
struct MarkdownEditorView: View {
    @Binding var text: String
    @State private var showPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showPreview.toggle()
                } label: {
                    Image(systemName: showPreview ? "pencil" : "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if showPreview {
                if text.isEmpty {
                    Text("No notes")
                        .foregroundStyle(.tertiary)
                        .italic()
                } else {
                    MarkdownTextView(text: text)
                        .textSelection(.enabled)
                }
            } else {
                TextField("Add notes... (supports **bold**, *italic*, `code`)", text: $text, axis: .vertical)
                    .lineLimit(5...30)
                    .font(.body)
            }
        }
    }
}
