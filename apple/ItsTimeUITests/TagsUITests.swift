import XCTest

/// Tests for Tags (TG-01 through TG-05).
final class TagsUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func openTagManager() {
        tapTab("Tasks")
        // Tap the overflow menu
        let menuButton = app.navigationBars.buttons["More"]
        _ = waitFor(menuButton)
        menuButton.tap()

        let manageTags = app.buttons["Manage Tags"]
        _ = waitFor(manageTags)
        manageTags.tap()
    }

    // TG-01: Tag manager opens
    func testTagManagerOpens() {
        openTagManager()
        let navBar = app.navigationBars["Tags"]
        XCTAssertTrue(waitFor(navBar), "Tag manager should open with 'Tags' navigation title")
    }

    // TG-02: Create new tag from tag manager
    func testCreateNewTag() {
        openTagManager()
        _ = waitFor(app.navigationBars["Tags"])

        // Tap "New Tag" button
        let newTagButton = app.buttons["New Tag"]
        XCTAssertTrue(waitFor(newTagButton), "New Tag button should exist")
        newTagButton.tap()

        // Alert should appear
        let alert = app.alerts["New Tag"]
        XCTAssertTrue(waitFor(alert), "New Tag alert should appear")

        let nameField = alert.textFields.firstMatch
        nameField.tap()
        nameField.typeText("Important")

        alert.buttons["Create"].tap()

        // Tag should appear in the list
        let tag = app.staticTexts["Important"]
        XCTAssertTrue(waitFor(tag, timeout: 3), "Created tag should appear in list")
    }

    // TG-03: Tag appears in list after creation
    func testTagAppearsInList() {
        openTagManager()
        _ = waitFor(app.navigationBars["Tags"])

        let newTagButton = app.buttons["New Tag"]
        _ = waitFor(newTagButton)
        newTagButton.tap()

        let alert = app.alerts["New Tag"]
        _ = waitFor(alert)
        alert.textFields.firstMatch.tap()
        alert.textFields.firstMatch.typeText("Work")
        alert.buttons["Create"].tap()

        sleep(1)
        // Dismiss tag manager
        app.buttons["Done"].tap()

        // Tag should also appear in the Tasks tab's Tags section
        tapTab("Tasks")
        app.swipeUp()
        let tagText = app.staticTexts["Work"]
        XCTAssertTrue(waitFor(tagText, timeout: 5), "Tag should appear in Tasks sidebar Tags section")
    }

    // TG-04: Tag manager Done button dismisses
    func testTagManagerDoneButton() {
        openTagManager()
        _ = waitFor(app.navigationBars["Tags"])

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should exist")
        doneButton.tap()

        // Should return to Tasks view
        let tasksNav = app.navigationBars["Tasks"]
        XCTAssertTrue(waitFor(tasksNav), "Should return to Tasks after dismissing tag manager")
    }

    // TG-05: Add tag to task via detail view
    func testAddTagToTask() {
        // Create a task and open detail
        createTaskViaQuickAdd(title: "Tag Task", tapToday: true)
        tapTab("Today")
        let taskText = app.staticTexts["Tag Task"]
        _ = waitFor(taskText)
        taskText.tap()
        _ = waitFor(app.navigationBars["Task"])

        // Scroll to Tags section
        for _ in 0..<4 {
            if app.staticTexts["Add Tag"].exists || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Tag'")).count > 0 { break }
            app.swipeUp()
        }

        // The "Add Tag" button should exist
        let addTagButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Tag'")).firstMatch
        XCTAssertTrue(waitFor(addTagButton, timeout: 5), "Add Tag button should exist in task detail")
    }
}
