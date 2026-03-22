import SwiftUI
import SwiftData

struct HabitGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Health & Fitness") {
                    galleryRow("Drink Water", icon: "drop.fill", color: "#007AFF", goal: 8, desc: "Stay hydrated — 8 glasses a day")
                    galleryRow("Exercise", icon: "figure.run", color: "#FF3B30", goal: 1, desc: "Get moving every day")
                    galleryRow("Sleep Early", icon: "bed.double.fill", color: "#5856D6", goal: 1, desc: "Be in bed by your target time")
                    galleryRow("Take Vitamins", icon: "pill.fill", color: "#34C759", goal: 1, desc: "Daily vitamin and supplements")
                    galleryRow("Stretch", icon: "figure.flexibility", color: "#FF9500", goal: 1, desc: "Morning or evening stretching")
                }

                Section("Mindfulness") {
                    galleryRow("Meditate", icon: "brain.head.profile", color: "#AF52DE", goal: 1, desc: "Daily mindfulness practice")
                    galleryRow("Journal", icon: "pencil.and.outline", color: "#AC8E68", goal: 1, desc: "Write your thoughts daily")
                    galleryRow("Gratitude", icon: "heart.fill", color: "#FF2D55", goal: 3, desc: "Note 3 things you're grateful for")
                    galleryRow("No Phone Before Bed", icon: "phone.down.fill", color: "#5856D6", goal: 1, desc: "Screen-free wind-down")
                }

                Section("Learning & Productivity") {
                    galleryRow("Read", icon: "book.fill", color: "#FF9500", goal: 1, desc: "Read every day")
                    galleryRow("Practice Instrument", icon: "music.note", color: "#FF2D55", goal: 1, desc: "Daily practice session")
                    galleryRow("Study", icon: "brain.head.profile", color: "#007AFF", goal: 1, desc: "Dedicated study time")
                    galleryRow("Draw / Create", icon: "paintpalette.fill", color: "#34C759", goal: 1, desc: "Daily creative time")
                }

                Section("Lifestyle") {
                    galleryRow("No Junk Food", icon: "leaf.fill", color: "#34C759", goal: 1, desc: "Eat clean today")
                    galleryRow("Walk 10K Steps", icon: "figure.walk", color: "#FF9500", goal: 1, desc: "Hit your step goal")
                    galleryRow("Tidy Up", icon: "sparkles", color: "#00C7BE", goal: 1, desc: "5-minute daily tidy")
                    galleryRow("Screen Time Limit", icon: "hourglass", color: "#AF52DE", goal: 1, desc: "Stay under your limit")
                }
            }
            .navigationTitle("Habit Gallery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func galleryRow(_ name: String, icon: String, color: String, goal: Int, desc: String) -> some View {
        Button {
            let habit = Habit(
                name: name,
                habitDescription: desc,
                icon: icon,
                color: color,
                goalCount: goal
            )
            modelContext.insert(habit)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(Color(hex: color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.body)
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if goal > 1 {
                    Text("Goal: \(goal)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: color).opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
    }
}
