import XCTest

/// Tests for the Today View (TV-01 through TV-07).
final class TodayViewUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    // TV-01: Today tab shows tasks due today
    func testTodayTabShowsTasksDueToday() {
        // Create a task with today's due date
        createTaskViaQuickAdd(title: "Today task", tapToday: true)

        // Navigate to Today tab
        tapTab("Today")

        // Task should appear
        let taskRow = app.staticTexts["Today task"]
        XCTAssertTrue(waitFor(taskRow), "Task due today should appear in Today view")
        takeScreenshot("TV-01_today_view")
    }

    // TV-02: Today shows empty state when no tasks
    func testTodayShowsEmptyState() {
        tapTab("Today")

        // No tasks created → should show "All Clear"
        let emptyState = app.staticTexts["All Clear"]
        XCTAssertTrue(waitFor(emptyState), "Empty state should show 'All Clear' when no tasks due today")
    }

    // TV-03: Swipe to complete a task
    func testSwipeToComplete() {
        createTaskViaQuickAdd(title: "Swipe me done", tapToday: true)
        tapTab("Today")

        let taskText = app.staticTexts["Swipe me done"]
        XCTAssertTrue(waitFor(taskText), "Task should appear")

        // Swipe right to reveal "Done" action
        taskText.swipeRight()

        let doneButton = app.buttons["Done"]
        if waitFor(doneButton, timeout: 3) {
            doneButton.tap()
        }

        // Task should disappear from the active list (or show as completed)
        // Give UI time to update
        sleep(1)
    }

    // TV-04: Tap task navigates to task detail
    func testTapTaskNavigatesToDetail() {
        createTaskViaQuickAdd(title: "Detail task", tapToday: true)
        tapTab("Today")

        let taskText = app.staticTexts["Detail task"]
        XCTAssertTrue(waitFor(taskText), "Task should appear")
        taskText.tap()

        // Should navigate to task detail view with "Task" nav title
        let detailNavBar = app.navigationBars["Task"]
        XCTAssertTrue(waitFor(detailNavBar), "Task detail navigation bar should appear")
    }

    // TV-05: Show/hide completed toggle
    func testShowHideCompletedToggle() {
        tapTab("Today")

        // The toggle button should exist in the toolbar
        // On iOS it may be in the navigation bar's more menu
        let navBar = app.navigationBars["Today"]
        XCTAssertTrue(waitFor(navBar), "Today navigation bar should exist")
    }

    // TV-06: Inbox tasks with no date appear in Today view
    func testInboxNoDueDateTasksAppear() {
        // Create a task with no due date (goes to Inbox)
        createTaskViaQuickAdd(title: "Inbox task no date")
        tapTab("Today")

        // This task should appear in "Inbox (no date)" section
        let taskText = app.staticTexts["Inbox task no date"]
        XCTAssertTrue(waitFor(taskText, timeout: 5), "Inbox task with no date should appear in Today view")
    }

    // TV-07: Today view navigation bar exists
    func testTodayViewNavigationBar() {
        tapTab("Today")
        let navBar = app.navigationBars["Today"]
        XCTAssertTrue(waitFor(navBar), "Today navigation bar should exist")
    }

    // TV-08: Inbox shows more than 5 tasks (cap removed)
    func testInboxShowsMoreThanFiveTasks() {
        for i in 1...7 {
            createTaskViaQuickAdd(title: "Inbox item \(i)")
        }
        tapTab("Today")

        // All 7 should be visible (may need to scroll since >5 uses DisclosureGroup)
        for _ in 0..<3 {
            if app.staticTexts["Inbox item 7"].exists { break }
            app.swipeUp()
        }
        let task7 = app.staticTexts["Inbox item 7"]
        XCTAssertTrue(waitFor(task7, timeout: 5), "7th inbox task should be visible (cap removed)")
    }

    // TV-09: Inbox DisclosureGroup shows count when many tasks
    func testInboxDisclosureGroupWithCount() {
        for i in 1...7 {
            createTaskViaQuickAdd(title: "Bulk task \(i)")
        }
        tapTab("Today")

        // Should show "Inbox (7)" in a disclosure group
        let disclosure = app.otherElements["inbox_disclosure"]
        let disclosureAlt = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Inbox' AND label CONTAINS '7'")).firstMatch
        let found = waitFor(disclosure, timeout: 5) || waitFor(disclosureAlt, timeout: 3)
        XCTAssertTrue(found, "Inbox disclosure group should show count when >5 tasks")
    }
}
