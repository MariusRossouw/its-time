import SwiftUI
import SwiftData
import UserNotifications

@main
struct ItsTimeApp: App {
    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")

    private static let modelTypes: [any PersistentModel.Type] = [
        TaskItem.self,
        Subtask.self,
        TaskList.self,
        ListSection.self,
        Folder.self,
        Tag.self,
        FocusSession.self,
        Habit.self,
        HabitEntry.self,
        CustomFilter.self,
        Trigger.self,
        TriggerLogEntry.self,
        Collaborator.self,
        ActivityEntry.self,
        ChatMessage.self,
        SyncProfile.self,
        TaskAttachment.self,
        TaskTemplate.self
    ]

    static let appGroupID = "group.com.mariusrossouw.itstime"

    private static func makeContainer() -> ModelContainer {
        let schema = Schema(modelTypes)
        if isUITesting {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: config)
        } else if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = containerURL.appending(path: "default.store")
            let config = ModelConfiguration(url: storeURL)
            return try! ModelContainer(for: schema, configurations: config)
        } else {
            return try! ModelContainer(for: schema)
        }
    }

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    guard !Self.isUITesting else { return }
                    NotificationService.shared.requestPermission()
                    NotificationService.shared.registerCategories()
                    CalendarService.shared.requestAccess()

                    // Request location for solar calculations
                    LocationTriggerService.shared.requestPermission()
                    LocationTriggerService.shared.requestCurrentLocation()

                    // Daily summary
                    if UserDefaults.standard.bool(forKey: "dailySummaryEnabled") {
                        let hour = UserDefaults.standard.integer(forKey: "dailySummaryHour")
                        DailySummaryService.shared.scheduleDailySummary(hour: hour > 0 ? hour : 8)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .taskLocationTriggered)) { notification in
                    guard let userInfo = notification.userInfo,
                          let taskId = userInfo["taskId"] as? String,
                          let direction = userInfo["direction"] as? String else { return }
                    NotificationService.shared.fireLocationReminder(
                        taskId: taskId,
                        taskTitle: "Task Reminder",
                        locationName: nil,
                        direction: direction
                    )
                }
        }
        .modelContainer(Self.makeContainer())
    }
}
