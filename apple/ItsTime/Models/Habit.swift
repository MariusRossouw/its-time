import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String
    var icon: String
    var color: String
    var frequency: HabitFrequency
    var customDays: [Int] // weekdays for custom frequency: 1=Sun..7=Sat
    var goalCount: Int // 1 for simple check-in, >1 for cumulative (e.g. 8 glasses of water)
    var reminderTime: Date?
    var isArchived: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry]

    init(
        name: String,
        habitDescription: String = "",
        icon: String = "checkmark.circle",
        color: String = "#007AFF",
        frequency: HabitFrequency = .daily,
        customDays: [Int] = [],
        goalCount: Int = 1,
        reminderTime: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.icon = icon
        self.color = color
        self.frequency = frequency
        self.customDays = customDays
        self.goalCount = goalCount
        self.reminderTime = reminderTime
        self.isArchived = false
        self.sortOrder = sortOrder
        self.entries = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isCumulative: Bool {
        goalCount > 1
    }

    // MARK: - Streak Calculation

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        // If today isn't completed yet, start from yesterday
        if !isCompletedOn(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDate = yesterday
        }

        while isCompletedOn(checkDate) {
            if shouldTrackOn(checkDate) {
                streak += 1
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev

            // Skip non-tracking days going backwards
            while !shouldTrackOn(checkDate) {
                guard let prev2 = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev2
            }
        }

        return streak
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let sortedEntries = entries
            .filter { completionValue(for: $0) >= goalCount }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()

        guard !sortedEntries.isEmpty else { return 0 }

        var best = 1
        var current = 1

        for i in 1..<sortedEntries.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedEntries[i-1], to: sortedEntries[i]).day ?? 0
            if daysBetween == 1 {
                current += 1
                best = max(best, current)
            } else if daysBetween > 1 {
                current = 1
            }
        }

        return best
    }

    var totalCompletions: Int {
        entries.filter { completionValue(for: $0) >= goalCount }.count
    }

    func isCompletedOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
        let total = dayEntries.reduce(0) { $0 + $1.value }
        return total >= goalCount
    }

    func valueOn(_ date: Date) -> Int {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.value }
    }

    func shouldTrackOn(_ date: Date) -> Bool {
        switch frequency {
        case .daily:
            return true
        case .weekly:
            return true // track any day, but only need once per week
        case .custom:
            let weekday = Calendar.current.component(.weekday, from: date)
            return customDays.contains(weekday)
        }
    }

    private func completionValue(for entry: HabitEntry) -> Int {
        entry.value
    }
}

enum HabitFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case custom

    var label: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .custom: return "Custom Days"
        }
    }
}
