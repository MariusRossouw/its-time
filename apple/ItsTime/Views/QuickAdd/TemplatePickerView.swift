import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    var onSelect: (TaskTemplate) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskTemplate.sortOrder) private var templates: [TaskTemplate]

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.badge.plus",
                        description: Text("Save a task as a template from its detail view.")
                    )
                } else {
                    List {
                        ForEach(templates) { template in
                            Button {
                                onSelect(template)
                            } label: {
                                templateRow(template)
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
            }
            .navigationTitle("Templates")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func templateRow(_ template: TaskTemplate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.subheadline.bold())

            if !template.title.isEmpty {
                Text(template.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                if template.priority != .none {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.priorityColor(template.priority))
                            .frame(width: 6, height: 6)
                        Text(template.priority.rawValue.capitalized)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                if !template.subtaskTitles.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9))
                        Text("\(template.subtaskTitles.count) subtasks")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                if template.isNote {
                    Label("Note", systemImage: "doc.text")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(templates[index])
        }
    }
}
