import XCTest

/// Tests for Task Lists & Smart Lists (TL-01 through TL-12).
final class TaskListsUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    // TL-01: Navigate to Inbox smart list
    func testNavigateToInbox() {
        tapTab("Tasks")
        takeScreenshot("TL-01_tasks_tab")
        let inbox = app.staticTexts["Inbox"]
        XCTAssertTrue(waitFor(inbox), "Inbox should be visible in smart lists")
        inbox.tap()

        let navBar = app.navigationBars["Inbox"]
        XCTAssertTrue(waitFor(navBar), "Inbox navigation bar should appear")
    }

    // TL-02: Navigate to Today smart list
    func testNavigateToTodaySmartList() {
        tapTab("Tasks")
        let today = app.staticTexts["Today"]
        XCTAssertTrue(waitFor(today), "Today should be visible in smart lists")
        today.tap()

        let navBar = app.navigationBars["Today"]
        XCTAssertTrue(waitFor(navBar), "Today navigation bar should appear")
    }

    // TL-03: Navigate to Next 7 Days smart list
    func testNavigateToNext7Days() {
        tapTab("Tasks")
        let next7 = app.staticTexts["Next 7 Days"]
        XCTAssertTrue(waitFor(next7), "Next 7 Days should be visible in smart lists")
        next7.tap()

        let navBar = app.navigationBars["Next 7 Days"]
        XCTAssertTrue(waitFor(navBar), "Next 7 Days navigation bar should appear")
    }

    // TL-04: Navigate to All smart list
    func testNavigateToAll() {
        tapTab("Tasks")
        let all = app.staticTexts["All"]
        XCTAssertTrue(waitFor(all), "All should be visible in smart lists")
        all.tap()

        let navBar = app.navigationBars["All"]
        XCTAssertTrue(waitFor(navBar), "All navigation bar should appear")
    }

    // TL-05: Navigate to Assigned to Me smart list
    func testNavigateToAssignedToMe() {
        tapTab("Tasks")
        let assigned = app.staticTexts["Assigned to Me"]
        XCTAssertTrue(waitFor(assigned), "Assigned to Me should be visible in smart lists")
        assigned.tap()

        let navBar = app.navigationBars["Assigned to Me"]
        XCTAssertTrue(waitFor(navBar), "Assigned to Me navigation bar should appear")
    }

    // TL-06: Create a new list
    func testCreateNewList() {
        createList(name: "Shopping")

        // The new list should appear
        let listEntry = app.staticTexts["Shopping"]
        XCTAssertTrue(waitFor(listEntry), "Newly created list should appear")
    }

    // TL-07: Navigate to a user-created list
    func testNavigateToUserList() {
        createList(name: "Errands")

        let listEntry = app.staticTexts["Errands"]
        XCTAssertTrue(waitFor(listEntry), "List should exist")
        listEntry.tap()

        let navBar = app.navigationBars["Errands"]
        XCTAssertTrue(waitFor(navBar), "Should navigate to the user-created list")
    }

    // TL-08: Smart Lists section content exists
    func testSmartListsContentExists() {
        tapTab("Tasks")
        // Verify smart list items are visible
        XCTAssertTrue(waitFor(app.staticTexts["Inbox"]), "Inbox should be visible")
        XCTAssertTrue(app.staticTexts["Today"].exists, "Today should be visible")
        XCTAssertTrue(app.staticTexts["Next 7 Days"].exists, "Next 7 Days should be visible")
        XCTAssertTrue(app.staticTexts["All"].exists, "All should be visible")
        XCTAssertTrue(app.staticTexts["Assigned to Me"].exists, "Assigned to Me should be visible")
    }

    // TL-09: Views content exists
    func testViewsContentExists() {
        tapTab("Tasks")
        // Verify view items are visible
        XCTAssertTrue(waitFor(app.staticTexts["Suggested"]), "Suggested should be visible")
        XCTAssertTrue(app.staticTexts["Matrix"].exists, "Matrix should be visible")
        XCTAssertTrue(app.staticTexts["Kanban"].exists, "Kanban should be visible")
        XCTAssertTrue(app.staticTexts["Timeline"].exists, "Timeline should be visible")
    }

    // TL-10: Navigate to Suggested view
    func testNavigateToSuggested() {
        tapTab("Tasks")
        let suggested = app.staticTexts["Suggested"]
        XCTAssertTrue(waitFor(suggested), "Suggested should be visible")
        suggested.tap()
    }

    // TL-11: Navigate to Matrix view
    func testNavigateToMatrix() {
        tapTab("Tasks")
        let matrix = app.staticTexts["Matrix"]
        XCTAssertTrue(waitFor(matrix), "Matrix should be visible")
        matrix.tap()
    }

    // TL-12: Navigate to Kanban view
    func testNavigateToKanban() {
        tapTab("Tasks")
        let kanban = app.staticTexts["Kanban"]
        XCTAssertTrue(waitFor(kanban), "Kanban should be visible")
        kanban.tap()
    }
}
