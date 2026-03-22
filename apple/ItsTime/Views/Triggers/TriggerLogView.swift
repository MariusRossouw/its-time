import SwiftUI
import SwiftData

struct TriggerLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TriggerLogEntry.firedAt, order: .reverse) private var logEntries: [TriggerLogEntry]

    var body: some View {
        List {
            if logEntries.isEmpty {
                ContentUnavailableView(
                    "No Activity",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Trigger activity will appear here when automations fire.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(logEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text(entry.triggerName)
                                .font(.subheadline.bold())
                        }

                        Text(entry.actionDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let taskTitle = entry.taskTitle {
                            HStack(spacing: 4) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 9))
                                Text(taskTitle)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Text(entry.firedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { offsets in
                    for i in offsets { modelContext.delete(logEntries[i]) }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Trigger Log")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
            if !logEntries.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All", role: .destructive) {
                        for entry in logEntries { modelContext.delete(entry) }
                    }
                }
            }
        }
    }
}
