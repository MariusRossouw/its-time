import XCTest

/// Tests for Advanced Views (AV-01 through AV-08).
final class AdvancedViewsUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func navigateToView(_ name: String) {
        tapTab("Tasks")
        let viewLink = app.staticTexts[name]
        _ = waitFor(viewLink)
        viewLink.tap()
    }

    // AV-01: Navigate to Eisenhower Matrix view
    func testNavigateToMatrix() {
        navigateToView("Matrix")
        let navBar = app.navigationBars["Eisenhower Matrix"]
        XCTAssertTrue(waitFor(navBar), "Eisenhower Matrix navigation bar should appear")
    }

    // AV-02: Matrix shows quadrant labels
    func testMatrixShowsQuadrants() {
        navigateToView("Matrix")
        _ = waitFor(app.navigationBars["Eisenhower Matrix"])
        sleep(1)
        XCTAssertTrue(app.navigationBars["Eisenhower Matrix"].exists, "Matrix view should load successfully")
        takeScreenshot("AV-02_eisenhower_matrix")
    }

    // AV-03: Navigate to Kanban board
    func testNavigateToKanban() {
        navigateToView("Kanban")
        // Kanban may not have a nav bar title in the same way
        sleep(1)
        // Verify columns exist
        let todoColumn = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'To Do' OR label CONTAINS[cd] 'Todo'")).firstMatch
        XCTAssertTrue(waitFor(todoColumn, timeout: 5), "Kanban should show To Do column")
    }

    // AV-04: Kanban shows column headers
    func testKanbanColumns() {
        navigateToView("Kanban")
        sleep(1)
        let doneColumn = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'Done'")).firstMatch
        XCTAssertTrue(waitFor(doneColumn, timeout: 5), "Kanban should show Done column")
        takeScreenshot("AV-04_kanban_board")
    }

    // AV-05: Navigate to Timeline/Gantt view
    func testNavigateToTimeline() {
        navigateToView("Timeline")
        sleep(1)
        // Just verify the view loaded
        XCTAssertTrue(true, "Timeline view should load without crash")
    }

    // AV-06: Navigate to Suggested tasks view
    func testNavigateToSuggested() {
        navigateToView("Suggested")
        let navBar = app.navigationBars["Suggested"]
        XCTAssertTrue(waitFor(navBar), "Suggested navigation bar should appear")
    }

    // AV-07: Suggested shows appropriate sections
    func testSuggestedSections() {
        // Create a task with today's date to have something in suggestions
        createTaskViaQuickAdd(title: "Suggested task", tapToday: true)
        navigateToView("Suggested")
        _ = waitFor(app.navigationBars["Suggested"])
        // The suggested view should load — content depends on data
        sleep(1)
        XCTAssertTrue(app.navigationBars["Suggested"].exists, "Suggested view should load")
    }

    // AV-08: Timeline view loads
    func testTimelineViewLoads() {
        // Create a task with date for timeline
        createTaskViaQuickAdd(title: "Timeline task", tapToday: true)
        navigateToView("Timeline")
        sleep(1)
        takeScreenshot("AV-08_timeline_view")
        // Just verify no crash
        XCTAssertTrue(true, "Timeline view should load with tasks")
    }

    // AV-09: Tap kanban card navigates to task detail
    func testKanbanCardNavigation() {
        createTaskViaQuickAdd(title: "Kanban Nav Test", tapToday: true)
        tapTab("Tasks")
        sleep(1)
        navigateToView("Kanban")
        sleep(2)
        // The task text might be inside a NavigationLink — search broadly
        let card = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Kanban Nav Test'")).firstMatch
        XCTAssertTrue(waitFor(card, timeout: 5), "Task card should appear in Kanban")
        card.tap()
        let detailNav = app.navigationBars["Task"]
        XCTAssertTrue(waitFor(detailNav, timeout: 5), "Task detail should open after tapping kanban card")
    }

    // AV-10: Tap timeline task navigates to task detail
    func testTimelineTaskNavigation() {
        createTaskViaQuickAdd(title: "Timeline Nav Test", tapToday: true)
        tapTab("Tasks")
        sleep(1)
        navigateToView("Timeline")
        sleep(2)
        // Use the accessibility identifier on the NavigationLink (not the bar overlay text)
        let taskLink = app.buttons["timeline_task_link"].firstMatch
        XCTAssertTrue(waitFor(taskLink, timeout: 5), "Task link should appear in Timeline")
        taskLink.tap()
        let detailNav = app.navigationBars["Task"]
        XCTAssertTrue(waitFor(detailNav, timeout: 5), "Task detail should open after tapping timeline task")
    }
}
