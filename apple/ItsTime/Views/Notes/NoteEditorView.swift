import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Bindable var note: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Tag.sortOrder) private var allTags: [Tag]

    @State private var isPreview = false

    var body: some View {
        VStack(spacing: 0) {
            // Title
            TextField("Note title", text: $note.title, axis: .vertical)
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top, 12)
                .accessibilityIdentifier("note_title_field")
                .onChange(of: note.title) { note.updatedAt = Date() }

            // Toolbar
            editorToolbar

            Divider()

            // Content
            if isPreview {
                ScrollView {
                    MarkdownEditorView(text: .constant(note.taskDescription))
                        .padding()
                }
            } else {
                TextEditor(text: $note.taskDescription)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .onChange(of: note.taskDescription) { note.updatedAt = Date() }
            }
        }
        .navigationTitle("Note")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    // List assignment
                    Menu("Move to List") {
                        Button("None") { note.list = nil; note.updatedAt = Date() }
                        ForEach(lists) { list in
                            Button {
                                note.list = list
                                note.updatedAt = Date()
                            } label: {
                                Label(list.name, systemImage: list.icon)
                            }
                        }
                    }

                    Button("Convert to Task", systemImage: "checklist") {
                        note.convertToTask()
                    }

                    Divider()

                    Button("Delete Note", systemImage: "trash", role: .destructive) {
                        modelContext.delete(note)
                        AutoSyncService.shared.notifyChange()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onDisappear {
            AutoSyncService.shared.notifyChange()
        }
    }

    private var editorToolbar: some View {
        HStack(spacing: 16) {
            // List badge
            if let list = note.list {
                HStack(spacing: 4) {
                    Image(systemName: list.icon)
                        .font(.caption)
                        .foregroundStyle(Color(hex: list.color))
                    Text(list.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Tags
            TagPickerView(task: note)

            // Preview toggle
            Button {
                isPreview.toggle()
            } label: {
                Image(systemName: isPreview ? "pencil" : "eye")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Timestamps
            Text(note.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
