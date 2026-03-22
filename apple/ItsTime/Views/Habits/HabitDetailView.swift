import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext

    @State private var showEditor = false

    private let calendar = Calendar.current
    private let today = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                checkInCard
                statsCards
                punchCard
                recentEntries
            }
            .padding()
        }
        .navigationTitle(habit.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") {
                        showEditor = true
                    }
                    Button(
                        habit.isArchived ? "Unarchive" : "Archive",
                        systemImage: habit.isArchived ? "tray.and.arrow.up" : "archivebox"
                    ) {
                        habit.isArchived.toggle()
                        habit.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            HabitEditorView(habit: habit)
        }
    }

    // MARK: - Check-in Card

    private var checkInCard: some View {
        VStack(spacing: 12) {
            let completed = habit.isCompletedOn(today)
            let currentValue = habit.valueOn(today)

            if habit.isCumulative {
                // Cumulative: show progress ring + increment button
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: min(Double(currentValue) / Double(habit.goalCount), 1.0))
                        .stroke(Color(hex: habit.color), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(currentValue)")
                            .font(.title.bold())
                        Text("/ \(habit.goalCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    addEntry(value: 1)
                } label: {
                    Label("Add One", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(hex: habit.color))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(completed)
            } else {
                // Simple: big check button
                Button {
                    if completed {
                        removeEntryToday()
                    } else {
                        addEntry(value: 1)
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(completed ? Color(hex: habit.color) : Color(hex: habit.color).opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: completed ? "checkmark" : habit.icon)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(completed ? .white : Color(hex: habit.color))
                        }
                        Text(completed ? "Done!" : "Check In")
                            .font(.headline)
                            .foregroundStyle(completed ? Color(hex: habit.color) : .primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats

    private var statsCards: some View {
        HStack(spacing: 12) {
            statCard(title: "Current Streak", value: "\(habit.currentStreak)", icon: "flame.fill", color: .orange)
            statCard(title: "Best Streak", value: "\(habit.bestStreak)", icon: "trophy.fill", color: .yellow)
            statCard(title: "Total", value: "\(habit.totalCompletions)", icon: "checkmark.circle", color: Color(hex: habit.color))
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Punch Card

    private var punchCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 12 Weeks")
                .font(.headline)
            PunchCardGrid(habit: habit, weeks: 12)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Entries

    private var recentEntries: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Activity")
                .font(.headline)

            let recent = habit.entries
                .sorted { $0.date > $1.date }
                .prefix(10)

            if recent.isEmpty {
                Text("No entries yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(recent)) { entry in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: habit.color))
                        Text(entry.date, style: .date)
                        if habit.isCumulative {
                            Spacer()
                            Text("+\(entry.value)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions

    private func addEntry(value: Int) {
        let entry = HabitEntry(date: Date(), value: value)
        entry.habit = habit
        habit.entries.append(entry)
        modelContext.insert(entry)
        habit.updatedAt = Date()
    }

    private func removeEntryToday() {
        let todayEntries = habit.entries.filter { calendar.isDate($0.date, inSameDayAs: today) }
        for entry in todayEntries {
            modelContext.delete(entry)
        }
        habit.updatedAt = Date()
    }
}
