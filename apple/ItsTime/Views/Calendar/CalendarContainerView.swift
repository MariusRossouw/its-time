import SwiftUI
import SwiftData

struct CalendarContainerView: View {
    @State private var viewMode: CalendarViewMode = .weekly
    @State private var selectedDate: Date = Date()
    @State private var selectedTask: TaskItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch viewMode {
                case .monthly:
                    MonthlyCalendarView(selectedDate: $selectedDate, selectedTask: $selectedTask)
                case .weekly:
                    WeeklyCalendarView(selectedDate: $selectedDate, selectedTask: $selectedTask)
                case .threeDay:
                    ThreeDayCalendarView(selectedDate: $selectedDate, selectedTask: $selectedTask)
                case .daily:
                    DailyCalendarView(selectedDate: $selectedDate, selectedTask: $selectedTask)
                case .agenda:
                    AgendaCalendarView(selectedDate: $selectedDate, selectedTask: $selectedTask)
                }
            }
            .navigationTitle("Calendar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Today") {
                        withAnimation { selectedDate = Date() }
                    }
                }
            }
            .taskNavigationDestination()
        }
    }
}

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case monthly, weekly, threeDay, daily, agenda

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly: return "Month"
        case .weekly: return "Week"
        case .threeDay: return "3 Day"
        case .daily: return "Day"
        case .agenda: return "Agenda"
        }
    }
}
