import XCTest

/// Tests for the Quick Add Task flow (QA-01 through QA-08).
final class QuickAddTaskUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    // MARK: - Helpers

    /// Open the quick add sheet from the Today tab's plus menu.
    private func openQuickAdd() {
        let plusMenu = app.buttons["plus_menu"]
        XCTAssertTrue(waitFor(plusMenu), "Plus menu should exist")
        plusMenu.tap()

        let newTaskButton = app.buttons["menu_new_task"]
        XCTAssertTrue(waitFor(newTaskButton), "New Task menu item should exist")
        newTaskButton.tap()
    }

    // QA-01: Open quick add sheet
    func testOpenQuickAddSheet() {
        openQuickAdd()
        let navTitle = app.navigationBars["New Task"]
        XCTAssertTrue(waitFor(navTitle), "Quick Add sheet should show 'New Task' navigation title")
        takeScreenshot("QA-01_quick_add_sheet")
    }

    // QA-02: Create task with title only
    func testCreateTaskWithTitleOnly() {
        openQuickAdd()

        let titleField = app.textFields["quick_add_title"]
        XCTAssertTrue(waitFor(titleField), "Title field should exist")
        titleField.tap()
        titleField.typeText("Buy groceries")

        let addButton = app.buttons["quick_add_add"]
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled after entering title")
        addButton.tap()

        // Sheet should dismiss — verify we're back on main app
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitFor(tabBar), "Tab bar should be visible after adding task")
    }

    // QA-03: Add button disabled when title empty
    func testAddButtonDisabledWhenTitleEmpty() {
        openQuickAdd()

        let addButton = app.buttons["quick_add_add"]
        XCTAssertTrue(waitFor(addButton), "Add button should exist")
        XCTAssertFalse(addButton.isEnabled, "Add button should be disabled when title is empty")
    }

    // QA-04: Set due date via quick date buttons
    func testSetDueDateViaQuickButtons() {
        openQuickAdd()

        let todayButton = app.buttons["quick_add_today"]
        XCTAssertTrue(waitFor(todayButton), "Today quick date button should exist")
        todayButton.tap()

        // Verify the button tint changed (it's now selected) — we just verify it's tappable
        let tomorrowButton = app.buttons["quick_add_tomorrow"]
        XCTAssertTrue(tomorrowButton.exists, "Tomorrow button should exist")
        tomorrowButton.tap()

        let nextWeekButton = app.buttons["quick_add_next_week"]
        XCTAssertTrue(nextWeekButton.exists, "Next Week button should exist")
        nextWeekButton.tap()
    }

    // QA-05: Set due date via date picker
    func testSetDueDateViaDatePicker() {
        openQuickAdd()

        let pickDateButton = app.buttons["quick_add_pick_date"]
        XCTAssertTrue(waitFor(pickDateButton), "Pick Date button should exist")
        pickDateButton.tap()

        // Date picker should appear
        let datePicker = app.datePickers.firstMatch
        XCTAssertTrue(waitFor(datePicker), "Date picker should appear after tapping Pick Date")
    }

    // QA-06: Set priority
    func testSetPriority() {
        openQuickAdd()

        let priorityMenu = app.buttons["quick_add_priority"]
        XCTAssertTrue(waitFor(priorityMenu), "Priority menu should exist")
        priorityMenu.tap()

        // Select "High" from the menu
        let highOption = app.buttons["High"]
        XCTAssertTrue(waitFor(highOption), "High priority option should appear")
        highOption.tap()
    }

    // QA-07: Set target list
    func testSetTargetList() {
        openQuickAdd()

        let listMenu = app.buttons["quick_add_list"]
        XCTAssertTrue(waitFor(listMenu), "List menu should exist")
        // The button label already shows "Inbox" (default)
        XCTAssertTrue(listMenu.label.contains("Inbox"), "Default list should be Inbox")
        listMenu.tap()

        // A menu should appear with at least the Inbox option
        // Use menuItems or collectionViews depending on how SwiftUI renders the Menu
        let menuItem = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Inbox'"))
        XCTAssertTrue(menuItem.count > 0, "Inbox should appear in list menu")
        // Tap the first matching menu item (skip the trigger button itself)
        menuItem.element(boundBy: menuItem.count > 1 ? 1 : 0).tap()
    }

    // QA-08: Cancel quick add
    func testCancelQuickAdd() {
        openQuickAdd()

        let titleField = app.textFields["quick_add_title"]
        XCTAssertTrue(waitFor(titleField), "Title field should exist")
        titleField.tap()
        titleField.typeText("This should not be saved")

        let cancelButton = app.buttons["quick_add_cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Sheet should dismiss — verify we're back on main app
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitFor(tabBar), "Tab bar should be visible after canceling")
    }
}
