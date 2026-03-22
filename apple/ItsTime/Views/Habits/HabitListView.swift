import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var showNewHabit = false
    @State private var showGallery = false
    @State private var showArchived = false

    private var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }

    private var archivedHabits: [Habit] {
        habits.filter { $0.isArchived }
    }

    var body: some View {
        NavigationStack {
            List {
                if activeHabits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Yet",
                        systemImage: "leaf",
                        description: Text("Start building good habits by tapping + or browsing the gallery.")
                    )
                } else {
                    Section {
                        ForEach(activeHabits) { habit in
                            NavigationLink(value: habit) {
                                HabitRowView(habit: habit)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                modelContext.delete(activeHabits[i])
                            }
                        }
                    }
                }

                if !archivedHabits.isEmpty {
                    Section {
                        DisclosureGroup("Archived (\(archivedHabits.count))", isExpanded: $showArchived) {
                            ForEach(archivedHabits) { habit in
                                NavigationLink(value: habit) {
                                    HabitRowView(habit: habit)
                                        .opacity(0.6)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Habits")
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habit: habit)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("New Habit", systemImage: "plus") {
                            showNewHabit = true
                        }
                        Button("Browse Gallery", systemImage: "square.grid.2x2") {
                            showGallery = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showNewHabit) {
                HabitEditorView()
            }
            .sheet(isPresented: $showGallery) {
                HabitGalleryView()
            }
        }
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let habit: Habit

    private let calendar = Calendar.current
    private let today = Date()

    var body: some View {
        HStack(spacing: 12) {
            // Check-in button
            checkInIndicator

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.body)

                HStack(spacing: 8) {
                    if habit.currentStreak > 0 {
                        Label("\(habit.currentStreak)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(habit.frequency.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Mini week dots
            weekDots
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var checkInIndicator: some View {
        let completed = habit.isCompletedOn(today)
        ZStack {
            Circle()
                .fill(Color(hex: habit.color).opacity(completed ? 1 : 0.15))
                .frame(width: 36, height: 36)
            Image(systemName: habit.icon)
                .font(.system(size: 16))
                .foregroundStyle(completed ? .white : Color(hex: habit.color))
        }
    }

    private var weekDots: some View {
        HStack(spacing: 3) {
            ForEach((-6...0), id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
                Circle()
                    .fill(habit.isCompletedOn(date) ? Color(hex: habit.color) : Color.gray.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
