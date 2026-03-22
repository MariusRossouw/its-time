import Foundation
import SwiftData

@MainActor
final class RecurrenceService {
    static let shared = RecurrenceService()
    private init() {}

    /// When a recurring task is completed, create the next instance or reschedule it
    func handleCompletion(task: TaskItem, context: ModelContext) {
        guard task.isRecurring, let dueDate = task.dueDate else { return }

        let nextDate: Date?

        if task.recurrenceBasedOnCompletion {
            // Next due = now + interval
            nextDate = calculateNextDate(from: Date(), type: task.recurrenceType, interval: task.recurrenceInterval, weekdays: task.recurrenceWeekdays)
        } else {
            // Next due = previous due + interval
            nextDate = calculateNextDate(from: dueDate, type: task.recurrenceType, interval: task.recurrenceInterval, weekdays: task.recurrenceWeekdays)
        }

        guard let next = nextDate else { return }

        // Check end date
        if let endDate = task.recurrenceEndDate, next > endDate { return }

        // Create next occurrence as a new task
        let newTask = TaskItem(
            title: task.title,
            taskDescription: task.taskDescription,
            priority: task.priority,
            dueDate: next,
            dueTime: task.dueTime,
            list: task.list,
            sortOrder: task.sortOrder
        )
        newTask.recurrenceType = task.recurrenceType
        newTask.recurrenceInterval = task.recurrenceInterval
        newTask.recurrenceWeekdays = task.recurrenceWeekdays
        newTask.recurrenceBasedOnCompletion = task.recurrenceBasedOnCompletion
        newTask.recurrenceEndDate = task.recurrenceEndDate
        newTask.reminderOffsets = task.reminderOffsets
        newTask.tags = task.tags
        newTask.parentTask = task.parentTask // maintain hierarchy position

        // Recreate subtasks (unchecked)
        for sub in task.subtasks {
            let newSub = Subtask(title: sub.title, sortOrder: sub.sortOrder)
            newSub.task = newTask
            newTask.subtasks.append(newSub)
        }

        context.insert(newTask)
        NotificationService.shared.scheduleReminders(for: newTask)
    }

    /// Skip the current cycle and move to next occurrence
    func skipCycle(task: TaskItem) {
        guard task.isRecurring, let dueDate = task.dueDate else { return }

        let nextDate = calculateNextDate(
            from: dueDate,
            type: task.recurrenceType,
            interval: task.recurrenceInterval,
            weekdays: task.recurrenceWeekdays
        )

        if let next = nextDate {
            if let endDate = task.recurrenceEndDate, next > endDate {
                return
            }
            task.dueDate = next
            task.updatedAt = Date()
            NotificationService.shared.scheduleReminders(for: task)
        }
    }

    private func calculateNextDate(from date: Date, type: RecurrenceType, interval: Int, weekdays: [Int]) -> Date? {
        let calendar = Calendar.current

        switch type {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            if weekdays.isEmpty {
                return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
            }
            // Find next matching weekday
            var candidate = date
            for _ in 0..<(7 * interval + 1) {
                candidate = calendar.date(byAdding: .day, value: 1, to: candidate)!
                let wd = calendar.component(.weekday, from: candidate)
                if weekdays.contains(wd) {
                    return candidate
                }
            }
            return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: interval, to: date)
        case .custom:
            return calendar.date(byAdding: .day, value: interval, to: date)
        }
    }
}
