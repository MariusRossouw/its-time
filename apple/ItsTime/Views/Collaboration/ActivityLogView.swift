import SwiftUI
import SwiftData

struct ActivityLogView: View {
    let task: TaskItem

    private var sortedEntries: [ActivityEntry] {
        task.activityLog.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        Group {
            if sortedEntries.isEmpty {
                ContentUnavailableView {
                    Label("No Activity", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Changes to this task will be logged here.")
                }
            } else {
                List {
                    ForEach(sortedEntries) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: entry.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(iconColor(entry.action))
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayText)
                                    .font(.subheadline)
                                Text(entry.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Activity")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
        }
    }
}
