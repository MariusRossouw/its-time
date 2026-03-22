import EventKit
import SwiftUI

@MainActor
@Observable
final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()
    var events: [EKEvent] = []
    var hasAccess = false

    private init() {}

    func requestAccess() {
        Task {
            do {
                let granted = try await store.requestFullAccessToEvents()
                hasAccess = granted
                if granted {
                    fetchTodayEvents()
                }
            } catch {
                print("Calendar access error: \(error)")
            }
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) {
        guard hasAccess else { return }
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func fetchTodayEvents() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        fetchEvents(from: start, to: end)
    }

    func fetchWeekEvents() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 7, to: start)!
        fetchEvents(from: start, to: end)
    }

    func fetchMonthEvents(for date: Date) {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let end = calendar.date(byAdding: .day, value: range.count, to: start)
        else { return }
        fetchEvents(from: start, to: end)
    }
}
