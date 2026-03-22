import Foundation
import SwiftData

@Model
final class HabitEntry {
    var id: UUID
    var date: Date
    var value: Int // 1 for simple check-in, count for cumulative
    var habit: Habit?

    init(date: Date = Date(), value: Int = 1) {
        self.id = UUID()
        self.date = date
        self.value = value
    }
}
