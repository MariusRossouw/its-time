import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    @State private var showNewTag = false
    @State private var newTagName = ""
    @State private var newTagColor = "#007AFF"
    @State private var editingTag: Tag?
    @State private var editTagName = ""
    @State private var editTagColor = ""

    private let presetColors = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#007AFF",
        "#5856D6", "#AF52DE", "#FF2D55", "#8E8E93", "#A2845E"
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: tag.color))
                            .frame(width: 14, height: 14)
                        Text(tag.name)
                        Spacer()
                        Text("\(tag.tasks.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTag = tag
                        editTagName = tag.name
                        editTagColor = tag.color
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(tag)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onMove { from, to in
                    var mutable = tags
                    mutable.move(fromOffsets: from, toOffset: to)
                    for (i, t) in mutable.enumerated() { t.sortOrder = i }
                }

                Button {
                    showNewTag = true
                } label: {
                    Label("New Tag", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Tags")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("New Tag", isPresented: $showNewTag) {
                TextField("Tag name", text: $newTagName)
                Button("Cancel", role: .cancel) { newTagName = "" }
                Button("Create") { createTag() }
            }
            .sheet(item: $editingTag) { tag in
                TagEditSheet(
                    tag: tag,
                    name: $editTagName,
                    color: $editTagColor,
                    presetColors: presetColors
                )
            }
        }
    }

    private func createTag() {
        guard !newTagName.isEmpty else { return }
        let tag = Tag(name: newTagName, color: presetColors.randomElement() ?? "#007AFF", sortOrder: tags.count)
        modelContext.insert(tag)
        newTagName = ""
    }
}

struct TagEditSheet: View {
    @Bindable var tag: Tag
    @Binding var name: String
    @Binding var color: String
    let presetColors: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Tag name", text: $name)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if color == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { color = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Tag")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        tag.name = name
                        tag.color = color
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 300)
        #endif
    }
}
