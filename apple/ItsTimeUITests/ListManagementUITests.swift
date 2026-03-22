import XCTest

/// Tests for List Management (LM-01 through LM-07).
final class ListManagementUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    /// Create a list and add tasks to it, then navigate to it.
    private func setupListWithTasks(listName: String = "Test List") {
        createList(name: listName)

        // Create a couple tasks in this list
        for i in 1...2 {
            let plusMenu = app.buttons["plus_menu"]
            _ = waitFor(plusMenu)
            plusMenu.tap()
            let newTask = app.buttons["menu_new_task"]
            _ = waitFor(newTask)
            newTask.tap()
            let titleField = app.textFields["quick_add_title"]
            _ = waitFor(titleField)
            titleField.tap()
            titleField.typeText("List Task \(i)")

            let listMenu = app.buttons["quick_add_list"]
            _ = waitFor(listMenu)
            listMenu.tap()
            let listOption = app.buttons.matching(NSPredicate(format: "label CONTAINS '\(listName)'"))
            if listOption.count > 0 {
                listOption.firstMatch.tap()
            }

            app.buttons["quick_add_add"].tap()
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)
        }

        // Navigate to the list
        tapTab("Tasks")
        let listEntry = app.staticTexts[listName]
        _ = waitFor(listEntry)
        listEntry.tap()
        _ = waitFor(app.navigationBars[listName])
    }

    // LM-01: Create a new list
    func testCreateList() {
        createList(name: "My Projects")
        tapTab("Tasks")
        let listText = app.staticTexts["My Projects"]
        XCTAssertTrue(waitFor(listText, timeout: 5), "Created list should appear in Tasks sidebar")
    }

    // LM-02: Navigate to user-created list
    func testNavigateToList() {
        createList(name: "Shopping")
        tapTab("Tasks")
        let listText = app.staticTexts["Shopping"]
        _ = waitFor(listText)
        listText.tap()

        let navBar = app.navigationBars["Shopping"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "Should navigate to the created list")
    }

    // LM-03: List view has Select button
    func testListHasSelectButton() {
        setupListWithTasks(listName: "Select Test")
        let selectButton = app.buttons["Select"]
        XCTAssertTrue(waitFor(selectButton, timeout: 5), "Select button should exist in list view toolbar")
    }

    // LM-04: Sort menu exists in list view
    func testSortMenuExists() {
        setupListWithTasks(listName: "Sort Test")
        // The sort menu uses arrow.up.arrow.down icon
        let sortMenu = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sort' OR label CONTAINS 'arrow'")).firstMatch
        XCTAssertTrue(waitFor(sortMenu, timeout: 5), "Sort menu should exist in list view toolbar")
    }

    // LM-05: Add Section via sort menu
    func testAddSectionOption() {
        setupListWithTasks(listName: "Section Test")
        // Open the sort/options menu
        let menuButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sort' OR label CONTAINS 'arrow'")).firstMatch
        _ = waitFor(menuButton, timeout: 5)
        menuButton.tap()

        let addSection = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Section'")).firstMatch
        XCTAssertTrue(waitFor(addSection, timeout: 5), "Add Section option should exist in menu")
    }

    // LM-06: Tasks appear in list view
    func testTasksAppearInList() {
        setupListWithTasks(listName: "View Tasks")
        let task1 = app.staticTexts["List Task 1"]
        let task2 = app.staticTexts["List Task 2"]
        XCTAssertTrue(waitFor(task1, timeout: 5), "First task should appear in list")
        XCTAssertTrue(task2.exists, "Second task should appear in list")
    }

    // LM-07: Swipe to complete task in list
    func testSwipeToComplete() {
        setupListWithTasks(listName: "Swipe Test")
        let task = app.staticTexts["List Task 1"]
        _ = waitFor(task, timeout: 5)
        task.swipeLeft()

        // Look for destructive/action buttons
        let actionButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'Done' OR label CONTAINS[cd] 'Delete' OR label CONTAINS[cd] 'Won'")).firstMatch
        XCTAssertTrue(waitFor(actionButton, timeout: 3), "Swipe actions should appear")
    }
}
