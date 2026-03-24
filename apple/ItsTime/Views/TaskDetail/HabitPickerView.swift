import SwiftUI
import SwiftData

struct HabitPickerView: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var allHabits: [Habit]
    @State private var searchText = ""

    private var availableHabits: [Habit] {
        let linkedIds = Set(task.childHabits.map(\.id))
        return allHabits.filter { habit in
            !habit.isArchived &&
            !linkedIds.contains(habit.id) &&
            (searchText.isEmpty || habit.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        List {
            if availableHabits.isEmpty {
                ContentUnavailableView(
                    "No Habits Available",
                    systemImage: "leaf",
                    description: Text("All habits are already linked, or create new ones in the Habits tab.")
                )
            } else {
                ForEach(availableHabits) { habit in
                    Button {
                        habit.parentTask = task
                        habit.updatedAt = Date()
                        task.updatedAt = Date()
                        task.logActivity(action: .habitLinked, newValue: habit.name, context: modelContext)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: habit.color).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: habit.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: habit.color))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.name)
                                    .foregroundStyle(.primary)
                                HStack(spacing: 6) {
                                    Text(habit.frequency.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if habit.currentStreak > 0 {
                                        Label("\(habit.currentStreak)", systemImage: "flame.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    if let parent = habit.parentTask {
                                        Text("linked to \(parent.title)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search habits")
        .navigationTitle("Link Habit")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
