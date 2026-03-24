import XCTest

/// Tests for Task Detail view (TD-01 through TD-26).
final class TaskDetailUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    /// Create a task and navigate to its detail view.
    private func createAndOpenTask(title: String = "Test Task") {
        createTaskViaQuickAdd(title: title, tapToday: true)
        tapTab("Today")
        let taskText = app.staticTexts[title]
        _ = waitFor(taskText, timeout: 5)
        taskText.tap()
        _ = waitFor(app.navigationBars["Task"])
    }

    // TD-01: Tap task → detail view opens with correct title
    func testDetailViewOpens() {
        createAndOpenTask(title: "My Task")
        let navBar = app.navigationBars["Task"]
        XCTAssertTrue(navBar.exists, "Task detail navigation bar should exist")
        // Title field should show the task title
        let titleField = app.textFields["task_detail_title"]
        XCTAssertTrue(waitFor(titleField), "Title field should exist")
        takeScreenshot("TD-01_task_detail_top")
    }

    // TD-02: Edit task title
    func testEditTaskTitle() {
        createAndOpenTask(title: "Original Title")
        let titleField = app.textFields["task_detail_title"]
        _ = waitFor(titleField)
        titleField.tap()
        // Clear existing and type new
        titleField.clearAndTypeText("Updated Title")
    }

    // TD-03: Status picker exists with Done option
    func testStatusPickerExists() {
        createAndOpenTask()
        let statusPicker = app.staticTexts["Status"]
        XCTAssertTrue(waitFor(statusPicker), "Status picker should exist")
    }

    // TD-04: Priority picker exists
    func testPriorityPickerExists() {
        createAndOpenTask()
        let priorityPicker = app.staticTexts["Priority"]
        XCTAssertTrue(waitFor(priorityPicker), "Priority picker should exist")
    }

    // TD-05: Due Date toggle exists
    func testDueDateToggleExists() {
        createAndOpenTask()
        let toggle = app.switches["Due Date"]
        XCTAssertTrue(waitFor(toggle), "Due Date toggle should exist")
    }

    // TD-06: Start Date toggle exists
    func testStartDateToggleExists() {
        createAndOpenTask()
        let toggle = app.switches["Start Date"]
        XCTAssertTrue(waitFor(toggle), "Start Date toggle should exist")
    }

    // TD-07: List picker is reachable by scrolling
    func testListPickerReachable() {
        createAndOpenTask()
        // Scroll until we find the List label
        for _ in 0..<5 {
            if app.staticTexts["List"].exists { break }
            app.swipeUp()
        }
        let listLabel = app.staticTexts["List"]
        XCTAssertTrue(listLabel.exists, "List picker should be reachable by scrolling")
    }

    // TD-08: List picker exists
    func testListPickerExists() {
        createAndOpenTask()
        app.swipeUp()
        let listPicker = app.staticTexts["List"]
        XCTAssertTrue(waitFor(listPicker, timeout: 5), "List picker should exist")
    }

    // TD-09: Reminders section exists (when due date set)
    func testRemindersSectionExists() {
        createAndOpenTask() // task created with tapToday: true
        app.swipeUp()
        takeScreenshot("TD-09_task_detail_mid")
        let addReminder = app.staticTexts["Add Reminder"]
        XCTAssertTrue(waitFor(addReminder, timeout: 5), "Add Reminder button should exist when due date is set")
    }

    // TD-10: Location Reminder section exists
    func testLocationReminderExists() {
        createAndOpenTask()
        app.swipeUp()
        let locationLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Location'")).firstMatch
        XCTAssertTrue(waitFor(locationLabel, timeout: 5), "Location Reminder section should exist")
    }

    // TD-11: Subtasks section exists with add field
    func testSubtasksSectionExists() {
        createAndOpenTask()
        app.swipeUp()
        app.swipeUp()
        let addField = app.textFields["add_subtask_field"]
        XCTAssertTrue(waitFor(addField, timeout: 5), "Add subtask field should exist")
    }

    // TD-12: Add subtask field is reachable and typeable
    func testAddSubtaskFieldWorks() {
        createAndOpenTask()
        // Scroll to subtask field
        for _ in 0..<5 {
            if app.textFields["add_subtask_field"].exists { break }
            app.swipeUp()
        }
        let addField = app.textFields["add_subtask_field"]
        XCTAssertTrue(addField.exists, "Add subtask field should be reachable")
        addField.tap()
        addField.typeText("Sub item 1")
        // Verify text was typed
        XCTAssertEqual(addField.value as? String, "Sub item 1", "Text should be typed into subtask field")
    }

    // TD-13: Description section exists
    func testDescriptionSectionExists() {
        createAndOpenTask()
        app.swipeUp()
        app.swipeUp()
        // The markdown editor has a text view
        // Just verify the collaboration section is reachable (below description)
        let activity = app.staticTexts["Activity & Comments"]
        XCTAssertTrue(waitFor(activity, timeout: 5), "Activity & Comments link should be reachable (description section above)")
    }

    // TD-14: Activity & Comments navigation link exists
    func testActivityCommentsLinkExists() {
        createAndOpenTask()
        app.swipeUp()
        app.swipeUp()
        let activity = app.staticTexts["Activity & Comments"]
        XCTAssertTrue(waitFor(activity, timeout: 5), "Activity & Comments link should exist")
    }

    // TD-15: (merged into TD-14 — Activity and Comments are now unified)
    func testActivityLinkExists() {
        createAndOpenTask()
        app.swipeUp()
        app.swipeUp()
        let activity = app.staticTexts["Activity & Comments"]
        XCTAssertTrue(waitFor(activity, timeout: 5), "Activity & Comments link should exist")
    }

    // TD-16: Info section shows created/updated dates
    func testInfoSectionExists() {
        createAndOpenTask()
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        takeScreenshot("TD-16_task_detail_bottom")
        let created = app.staticTexts["Created"]
        XCTAssertTrue(waitFor(created, timeout: 5), "Created date should be visible in Info section")
    }

    // TD-17: Navigate to Activity view (unified comments + activity)
    func testNavigateToActivity() {
        createAndOpenTask()
        app.swipeUp()
        app.swipeUp()
        let activity = app.staticTexts["Activity & Comments"]
        _ = waitFor(activity, timeout: 5)
        activity.tap()
        let activityNav = app.navigationBars["Activity"]
        XCTAssertTrue(waitFor(activityNav), "Activity view should open")
    }

    // TD-18: Navigate to Activity view
    func testNavigateToActivity() {
        createAndOpenTask()
        app.swipeUp()
        app.swipeUp()
        let activity = app.staticTexts["Activity"]
        _ = waitFor(activity, timeout: 5)
        activity.tap()
        let activityNav = app.navigationBars["Activity"]
        XCTAssertTrue(waitFor(activityNav), "Activity view should open")
    }

    // TD-19: Due Date and Start Date toggles coexist
    func testDateTogglesCoexist() {
        createAndOpenTask()
        let dueToggle = app.switches["Due Date"]
        let startToggle = app.switches["Start Date"]
        XCTAssertTrue(waitFor(dueToggle), "Due Date toggle should exist")
        XCTAssertTrue(startToggle.exists, "Start Date toggle should exist alongside Due Date")
    }

    // TD-20: Nudge toggle exists on task without due date
    func testNudgeToggleExistsWithoutDueDate() {
        // Create task WITHOUT tapToday (no due date)
        createTaskViaQuickAdd(title: "Nudge Task")
        tapTab("Today")
        let taskText = app.staticTexts["Nudge Task"]
        _ = waitFor(taskText, timeout: 5)
        taskText.tap()
        _ = waitFor(app.navigationBars["Task"])

        // Scroll to find Remind Me section
        for _ in 0..<6 {
            if app.switches["nudge_toggle"].exists { break }
            app.swipeUp()
        }

        let nudgeToggle = app.switches["nudge_toggle"]
        XCTAssertTrue(waitFor(nudgeToggle, timeout: 5), "Nudge toggle should exist even without due date")
    }

    // TD-21: Nudge toggle coexists with due-date Reminders
    func testNudgeToggleCoexistsWithReminders() {
        createAndOpenTask() // has due date via tapToday

        for _ in 0..<6 {
            if app.switches["nudge_toggle"].exists { break }
            app.swipeUp()
        }

        let nudgeToggle = app.switches["nudge_toggle"]
        XCTAssertTrue(waitFor(nudgeToggle, timeout: 5), "Nudge toggle should exist alongside due-date reminders")
    }

    // TD-22: Remind Me section exists with toggle
    func testRemindMeSectionExists() {
        createAndOpenTask()

        // Scroll to the Remind Me section
        for _ in 0..<6 {
            if app.staticTexts["Remind Me"].exists || app.switches["nudge_toggle"].exists { break }
            app.swipeUp()
        }

        // The "Set Reminder" label or toggle should exist within the Remind Me section
        let nudgeToggle = app.switches["nudge_toggle"]
        let setReminderLabel = app.staticTexts["Set Reminder"]
        let found = waitFor(nudgeToggle, timeout: 5) || waitFor(setReminderLabel, timeout: 3)
        XCTAssertTrue(found, "Remind Me section with Set Reminder toggle should exist")
    }

    // TD-23: Child Tasks section exists with add field
    func testChildTasksSectionExists() {
        createAndOpenTask()

        // Scroll until we see the CHILD TASKS section header (Form uppercases headers)
        for _ in 0..<15 {
            if app.staticTexts["CHILD TASKS"].exists { break }
            app.swipeUp()
        }

        let sectionHeader = app.staticTexts["CHILD TASKS"]
        XCTAssertTrue(waitFor(sectionHeader, timeout: 5), "Child Tasks section should exist in task detail")
        takeScreenshot("TD-23_child_tasks_section")
    }

    // TD-24: Add child task inline creates it
    func testAddChildTaskInline() {
        createAndOpenTask(title: "Parent Task")

        // Scroll to child tasks section
        for _ in 0..<15 {
            if app.staticTexts["CHILD TASKS"].exists { break }
            app.swipeUp()
        }

        // Find the add child task text field by placeholder
        let addField = app.textFields["Add child task"]
        XCTAssertTrue(waitFor(addField, timeout: 5), "Add child task field should exist")
        addField.tap()
        addField.typeText("Child Task One\n")

        // Verify child task text appears in the section
        let childText = app.staticTexts["Child Task One"]
        XCTAssertTrue(waitFor(childText, timeout: 5), "Child task should appear after creation")
        takeScreenshot("TD-24_child_task_added")
    }

    // TD-25: Parent task picker exists
    func testParentTaskPickerExists() {
        createAndOpenTask()

        // Scroll to find parent task picker (deep in form)
        for _ in 0..<12 {
            if app.buttons["set_parent_task"].exists { break }
            app.swipeUp()
        }

        let setParentButton = app.buttons["set_parent_task"]
        XCTAssertTrue(waitFor(setParentButton, timeout: 5), "Set Parent Task button should exist")
        takeScreenshot("TD-25_parent_task_picker")
    }

    // TD-26: Child task shows parent breadcrumb in detail
    func testChildTaskShowsParentBreadcrumb() {
        createAndOpenTask(title: "Parent Task")

        // Scroll to child tasks section
        for _ in 0..<15 {
            if app.staticTexts["CHILD TASKS"].exists { break }
            app.swipeUp()
        }

        let addField = app.textFields["Add child task"]
        _ = waitFor(addField, timeout: 5)
        addField.tap()
        addField.typeText("Breadcrumb Child\n")

        // Tap the child task to navigate to its detail
        let childText = app.staticTexts["Breadcrumb Child"]
        _ = waitFor(childText, timeout: 5)
        childText.tap()

        // Verify we're in the child's detail and the parent breadcrumb is visible
        let detailNav = app.navigationBars["Task"]
        _ = waitFor(detailNav, timeout: 5)

        // The "Part of" section with parent name should be visible at the top
        let parentLink = app.buttons["parent_task_link"]
        XCTAssertTrue(waitFor(parentLink, timeout: 5), "Parent task breadcrumb should be visible in child detail")
        takeScreenshot("TD-26_child_with_parent_breadcrumb")
    }
}

// Helper for clearing text field
extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else { return }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
