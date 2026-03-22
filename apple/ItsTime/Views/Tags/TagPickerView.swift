import SwiftUI
import SwiftData

/// Inline tag picker for assigning tags to a task
struct TagPickerView: View {
    @Bindable var task: TaskItem
    @Query(sort: \Tag.sortOrder) private var allTags: [Tag]
    @Environment(\.modelContext) private var modelContext

    @State private var showNewTag = false
    @State private var newTagName = ""

    private var assignedTagIds: Set<UUID> {
        Set(task.tags.map(\.id))
    }

    var body: some View {
        Section("Tags") {
            // Assigned tags
            if !task.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(task.tags.sorted(by: { $0.sortOrder < $1.sortOrder })) { tag in
                        TagChip(tag: tag, isSelected: true) {
                            task.tags.removeAll { $0.id == tag.id }
                            task.updatedAt = Date()
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Available tags to add
            Menu {
                ForEach(allTags.filter { !assignedTagIds.contains($0.id) }) { tag in
                    Button {
                        task.tags.append(tag)
                        task.updatedAt = Date()
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.color))
                                .frame(width: 10, height: 10)
                            Text(tag.name)
                        }
                    }
                }
                Divider()
                Button("New Tag...") {
                    showNewTag = true
                }
            } label: {
                Label("Add Tag", systemImage: "plus.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .alert("New Tag", isPresented: $showNewTag) {
            TextField("Tag name", text: $newTagName)
            Button("Cancel", role: .cancel) { newTagName = "" }
            Button("Create") { createAndAssignTag() }
        }
    }

    private func createAndAssignTag() {
        guard !newTagName.isEmpty else { return }
        let tag = Tag(name: newTagName, sortOrder: allTags.count)
        modelContext.insert(tag)
        task.tags.append(tag)
        task.updatedAt = Date()
        newTagName = ""
    }
}

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: tag.color))
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.caption)
            if isSelected {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: tag.color).opacity(0.12))
        .clipShape(Capsule())
    }
}

/// Simple horizontal flow layout for tag chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
