import Foundation
import SwiftData
import UserNotifications

@MainActor @Observable
final class TriggerEngine {
    static let shared = TriggerEngine()
    private init() {}

    // MARK: - Event-Based Triggers

    func handleEvent(_ eventType: TriggerEventType, task: TaskItem, context: ModelContext) {
        let descriptor = FetchDescriptor<Trigger>()
        guard let triggers = try? context.fetch(descriptor) else { return }

        let matching = triggers.filter { trigger in
            guard trigger.isEnabled else { return false }
            guard trigger.triggerType == .event else { return false }
            guard trigger.eventType == eventType else { return false }
            return evaluateConditions(trigger, task: task)
        }

        for trigger in matching {
            executeActions(trigger, task: task, context: context)
        }
    }

    // MARK: - Chain Triggers (task A completed -> fire)

    func handleTaskCompletion(task: TaskItem, context: ModelContext) {
        // Event triggers
        handleEvent(.taskCompleted, task: task, context: context)

        // Chain triggers
        let descriptor = FetchDescriptor<Trigger>()
        guard let triggers = try? context.fetch(descriptor) else { return }

        let chains = triggers.filter { trigger in
            guard trigger.isEnabled else { return false }
            guard trigger.triggerType == .chain else { return false }
            return trigger.sourceTaskId == task.id
        }

        for trigger in chains {
            executeActions(trigger, task: task, context: context)
        }
    }

    // MARK: - Time-Based Trigger Scheduling

    func scheduleTimeTriggers(context: ModelContext) {
        let descriptor = FetchDescriptor<Trigger>()
        guard let triggers = try? context.fetch(descriptor) else { return }

        let timeTriggers = triggers.filter { $0.isEnabled && $0.triggerType == .timeBased }

        for trigger in timeTriggers {
            if let scheduledTime = trigger.scheduledTime, scheduledTime > Date() {
                scheduleNotification(
                    id: "trigger-\(trigger.id.uuidString)",
                    title: "Trigger: \(trigger.name)",
                    body: trigger.actions.first?.displayLabel ?? "Trigger fired",
                    at: scheduledTime
                )
            }
        }
    }

    // MARK: - Overdue Check

    func checkOverdueTasks(allTasks: [TaskItem], context: ModelContext) {
        let now = Date()
        let overdue = allTasks.filter { task in
            guard task.status == .todo, let due = task.dueDate else { return false }
            return due < now
        }

        for task in overdue {
            handleEvent(.taskOverdue, task: task, context: context)
        }
    }

    // MARK: - Evaluate Conditions

    private func evaluateConditions(_ trigger: Trigger, task: TaskItem) -> Bool {
        let conditions = trigger.conditions
        if conditions.isEmpty { return true }
        let results = conditions.map { $0.matches(task) }
        return trigger.matchAll ? results.allSatisfy { $0 } : results.contains { $0 }
    }

    // MARK: - Execute Actions

    private func executeActions(_ trigger: Trigger, task: TaskItem, context: ModelContext) {
        for action in trigger.actions {
            executeAction(action, trigger: trigger, task: task, context: context)
        }
    }

    private func executeAction(_ action: TriggerAction, trigger: Trigger, task: TaskItem, context: ModelContext) {
        switch action.actionType {
        case .notify:
            scheduleNotification(
                id: "trigger-action-\(UUID().uuidString)",
                title: trigger.name,
                body: action.value.isEmpty ? "Trigger fired for: \(task.title)" : action.value,
                at: Date().addingTimeInterval(1)
            )

        case .createTask:
            let newTask = TaskItem(title: action.value.isEmpty ? "Follow-up: \(task.title)" : action.value)
            newTask.list = task.list
            context.insert(newTask)

        case .moveToList:
            // Find list by name
            let listDescriptor = FetchDescriptor<TaskList>()
            if let lists = try? context.fetch(listDescriptor),
               let targetList = lists.first(where: { $0.name == action.value }) {
                task.list = targetList
                task.updatedAt = Date()
            }

        case .changePriority:
            if let priority = TaskPriority(rawValue: action.value) {
                task.priority = priority
                task.updatedAt = Date()
            }

        case .addTag:
            let tagDescriptor = FetchDescriptor<Tag>()
            if let tags = try? context.fetch(tagDescriptor),
               let tag = tags.first(where: { $0.name == action.value }) {
                if !task.tags.contains(where: { $0.id == tag.id }) {
                    task.tags.append(tag)
                    task.updatedAt = Date()
                }
            }

        case .startTimer:
            // Post notification to start timer
            NotificationCenter.default.post(name: .triggerStartTimer, object: nil)

        case .setStatus:
            if let status = TaskStatus(rawValue: action.value) {
                task.status = status
                if status == .done { task.completedAt = Date() }
                task.updatedAt = Date()
            }
        }

        // Log the action
        let logEntry = TriggerLogEntry(
            triggerName: trigger.name,
            actionDescription: action.displayLabel,
            taskTitle: task.title
        )
        logEntry.trigger = trigger
        trigger.logEntries.append(logEntry)
        context.insert(logEntry)
    }

    // MARK: - Notification Helper

    private func scheduleNotification(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

extension Notification.Name {
    static let triggerStartTimer = Notification.Name("triggerStartTimer")
}
