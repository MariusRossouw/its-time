import XCTest

/// Tests for Batch Edit (BE-01 through BE-06).
final class BatchEditUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    /// Create a list with tasks and navigate to it.
    private func setupListWithTasks() {
        // Create a list
        createList(name: "Batch List")

        // Create tasks in that list
        for i in 1...3 {
            let plusMenu = app.buttons["plus_menu"]
            _ = waitFor(plusMenu)
            plusMenu.tap()
            let newTask = app.buttons["menu_new_task"]
            _ = waitFor(newTask)
            newTask.tap()
            let titleField = app.textFields["quick_add_title"]
            _ = waitFor(titleField)
            titleField.tap()
            titleField.typeText("Batch Task \(i)")

            // Select the list
            let listMenu = app.buttons["quick_add_list"]
            _ = waitFor(listMenu)
            listMenu.tap()
            let listOption = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Batch List'"))
            if listOption.count > 0 {
                listOption.firstMatch.tap()
            }

            app.buttons["quick_add_add"].tap()
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)
        }

        // Navigate to the list
        tapTab("Tasks")
        let listEntry = app.staticTexts["Batch List"]
        _ = waitFor(listEntry)
        listEntry.tap()
        _ = waitFor(app.navigationBars["Batch List"])
    }

    // BE-01: Select button exists in list view toolbar
    func testSelectButtonExists() {
        createList(name: "Select List")
        tapTab("Tasks")
        let listEntry = app.staticTexts["Select List"]
        _ = waitFor(listEntry)
        listEntry.tap()
        _ = waitFor(app.navigationBars["Select List"])

        let selectButton = app.buttons["Select"]
        XCTAssertTrue(waitFor(selectButton, timeout: 5), "Select button should exist in list view toolbar")
    }

    // BE-02: Tapping Select enters edit mode
    func testEnterEditMode() {
        setupListWithTasks()

        let selectButton = app.buttons["Select"]
        _ = waitFor(selectButton, timeout: 5)
        selectButton.tap()

        // "Done" button should appear (replacing "Select")
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(waitFor(doneButton, timeout: 3), "Done button should appear in edit mode")
    }

    // BE-03: Exit edit mode
    func testExitEditMode() {
        setupListWithTasks()

        let selectButton = app.buttons["Select"]
        _ = waitFor(selectButton, timeout: 5)
        selectButton.tap()

        let doneButton = app.buttons["Done"]
        _ = waitFor(doneButton)
        doneButton.tap()

        // Select button should reappear
        XCTAssertTrue(waitFor(app.buttons["Select"], timeout: 3), "Select button should reappear after exiting edit mode")
    }
}
