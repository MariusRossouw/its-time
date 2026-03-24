import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Bindable var note: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query(sort: \Tag.sortOrder) private var allTags: [Tag]

    @State private var isPreview = false
    @State private var showParentPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Parent task breadcrumb
            if let parent = note.parentTask {
                Button {
                    // Navigate handled by NavigationLink below
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.turn.up.left")
                            .font(.caption)
                        Text("Part of: \(parent.title)")
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            let oldParent = note.parentTask?.title
                            note.parentTask = nil
                            note.updatedAt = Date()
                            note.logActivity(action: .parentChanged, oldValue: oldParent, context: modelContext)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.08))
                }
                .buttonStyle(.plain)
            }

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

                    if note.parentTask != nil {
                        Button("Unlink from Task", systemImage: "link.badge.minus") {
                            let oldParent = note.parentTask?.title
                            note.parentTask = nil
                            note.updatedAt = Date()
                            note.logActivity(action: .parentChanged, oldValue: oldParent, context: modelContext)
                        }
                    } else {
                        Button("Link to Task", systemImage: "link.badge.plus") {
                            showParentPicker = true
                        }
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
        .sheet(isPresented: $showParentPicker) {
            NavigationStack {
                ParentTaskSearchView(task: note)
            }
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
