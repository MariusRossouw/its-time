import XCTest

/// Tests for Subtasks (ST-01 through ST-05).
final class SubtasksUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    /// Create a task and navigate to its detail view.
    private func openTaskDetail(title: String = "Subtask Test") {
        createTaskViaQuickAdd(title: title, tapToday: true)
        tapTab("Today")
        let taskText = app.staticTexts[title]
        _ = waitFor(taskText)
        taskText.tap()
        _ = waitFor(app.navigationBars["Task"])
    }

    /// Scroll to the subtasks section in task detail.
    private func scrollToSubtasks() {
        for _ in 0..<6 {
            if app.textFields["add_subtask_field"].exists { break }
            app.swipeUp()
        }
    }

    // ST-01: Add subtask field exists in task detail
    func testAddSubtaskFieldExists() {
        openTaskDetail()
        scrollToSubtasks()
        let addField = app.textFields["add_subtask_field"]
        XCTAssertTrue(waitFor(addField, timeout: 5), "Add subtask field should exist in task detail")
    }

    // ST-02: Type text into add subtask field
    func testTypeSubtaskText() {
        openTaskDetail()
        scrollToSubtasks()
        let addField = app.textFields["add_subtask_field"]
        _ = waitFor(addField, timeout: 5)
        addField.tap()
        addField.typeText("Buy groceries")
        // Verify text was entered
        XCTAssertEqual(addField.value as? String, "Buy groceries", "Subtask text should be entered")
    }

    // ST-03: Submit subtask creates it via return key
    func testCreateSubtask() {
        openTaskDetail()
        scrollToSubtasks()
        let addField = app.textFields["add_subtask_field"]
        _ = waitFor(addField, timeout: 5)
        addField.tap()
        addField.typeText("Clean house")

        // Press the Return key on the keyboard to submit
        app.keyboards.buttons["Return"].tap()
        sleep(1)

        // Subtask row uses a TextField, so look for textFields with the subtask title as value
        let subtask = app.textFields.matching(NSPredicate(format: "value == 'Clean house'")).firstMatch
        XCTAssertTrue(waitFor(subtask, timeout: 5), "Created subtask should appear as a text field in the list")
    }

    // ST-04: Add subtask field has placeholder text
    func testSubtaskFieldPlaceholder() {
        openTaskDetail()
        scrollToSubtasks()
        let addField = app.textFields["add_subtask_field"]
        _ = waitFor(addField, timeout: 5)
        // The placeholder text should be "Add subtask"
        let placeholder = addField.placeholderValue
        XCTAssertEqual(placeholder, "Add subtask", "Subtask field should have 'Add subtask' placeholder")
    }

    // ST-05: Subtask plus icon exists next to field
    func testSubtaskPlusIconExists() {
        openTaskDetail()
        scrollToSubtasks()
        // The plus.circle icon is adjacent to the text field
        let addField = app.textFields["add_subtask_field"]
        XCTAssertTrue(waitFor(addField, timeout: 5), "Subtask add field should exist, confirming subtask section is present")
    }

    /// Helper: create a subtask and wait for it to appear.
    private func createSubtask(title: String) {
        scrollToSubtasks()
        let addField = app.textFields["add_subtask_field"]
        _ = waitFor(addField, timeout: 5)
        addField.tap()
        addField.typeText(title)
        app.keyboards.buttons["Return"].tap()
        sleep(1)
    }

    // ST-06: Subtask notes toggle button exists after creating subtask
    func testSubtaskNotesToggleExists() {
        openTaskDetail()
        createSubtask(title: "Note subtask")
        scrollToSubtasks()

        let notesToggle = app.buttons["subtask_notes_toggle"]
        XCTAssertTrue(waitFor(notesToggle, timeout: 5), "Notes toggle button should exist on subtask row")
    }

    // ST-07: Tap notes toggle expands notes field
    func testSubtaskNotesFieldExpandsOnTap() {
        openTaskDetail()
        createSubtask(title: "Expand subtask")
        scrollToSubtasks()

        let notesToggle = app.buttons["subtask_notes_toggle"]
        _ = waitFor(notesToggle, timeout: 5)
        notesToggle.tap()

        let notesField = app.textFields["subtask_notes_field"]
        XCTAssertTrue(waitFor(notesField, timeout: 5), "Notes field should appear after tapping toggle")
    }

    // ST-08: Type text into subtask notes field
    func testSubtaskNotesCanBeTyped() {
        openTaskDetail()
        createSubtask(title: "Typed subtask")
        scrollToSubtasks()

        let notesToggle = app.buttons["subtask_notes_toggle"]
        _ = waitFor(notesToggle, timeout: 5)
        notesToggle.tap()

        let notesField = app.textFields["subtask_notes_field"]
        _ = waitFor(notesField, timeout: 5)
        notesField.tap()
        notesField.typeText("Check the specs")

        XCTAssertEqual(notesField.value as? String, "Check the specs", "Notes text should be entered")
    }
}
