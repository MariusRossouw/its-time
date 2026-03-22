import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var plannedDuration: Int // seconds
    var actualDuration: Int // seconds
    var sessionType: FocusSessionType
    var isCompleted: Bool
    var createdAt: Date

    var task: TaskItem?

    init(
        plannedDuration: Int = 1500, // 25 min default
        sessionType: FocusSessionType = .pomodoro,
        task: TaskItem? = nil
    ) {
        self.id = UUID()
        self.startedAt = Date()
        self.endedAt = nil
        self.plannedDuration = plannedDuration
        self.actualDuration = 0
        self.sessionType = sessionType
        self.isCompleted = false
        self.task = task
        self.createdAt = Date()
    }

    func complete() {
        endedAt = Date()
        actualDuration = Int(endedAt!.timeIntervalSince(startedAt))
        isCompleted = true
    }

    func cancel() {
        endedAt = Date()
        actualDuration = Int(endedAt!.timeIntervalSince(startedAt))
        isCompleted = false
    }
}

enum FocusSessionType: String, Codable, CaseIterable {
    case pomodoro
    case stopwatch
    case shortBreak
    case longBreak

    var label: String {
        switch self {
        case .pomodoro: return "Focus"
        case .stopwatch: return "Stopwatch"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}
