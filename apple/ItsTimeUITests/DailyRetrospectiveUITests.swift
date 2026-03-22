import XCTest

/// Tests for Daily Retrospective (DR-01 through DR-05).
final class DailyRetrospectiveUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func openDailyReview() {
        tapTab("Today")
        _ = waitFor(app.navigationBars["Today"])

        // The Daily Review button is in the secondary toolbar actions
        // On iOS, secondary actions appear in the overflow menu
        let menuButton = app.navigationBars.buttons["More"]
        if menuButton.exists {
            menuButton.tap()
            let reviewButton = app.buttons["Daily Review"]
            _ = waitFor(reviewButton, timeout: 3)
            reviewButton.tap()
        } else {
            // Try direct button
            let reviewButton = app.buttons["daily_review_button"]
            _ = waitFor(reviewButton, timeout: 3)
            reviewButton.tap()
        }
    }

    // DR-01: Daily Review button exists in Today toolbar
    func testDailyReviewButtonExists() {
        tapTab("Today")
        _ = waitFor(app.navigationBars["Today"])

        // Check overflow menu for the button
        let menuButton = app.navigationBars.buttons["More"]
        if menuButton.exists {
            menuButton.tap()
            let reviewButton = app.buttons["Daily Review"]
            XCTAssertTrue(waitFor(reviewButton, timeout: 5), "Daily Review button should exist in toolbar menu")
        } else {
            let reviewButton = app.buttons["daily_review_button"]
            XCTAssertTrue(waitFor(reviewButton, timeout: 5), "Daily Review button should exist in toolbar")
        }
    }

    // DR-02: Daily Review opens as sheet
    func testDailyReviewOpens() {
        openDailyReview()
        let navBar = app.navigationBars["Daily Review"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "Daily Review sheet should open with correct title")
    }

    // DR-03: Stats section exists in retrospective
    func testStatsSectionExists() {
        openDailyReview()
        _ = waitFor(app.navigationBars["Daily Review"])

        // Look for the stat labels
        let completed = app.staticTexts["Completed"]
        let remaining = app.staticTexts["Remaining"]
        XCTAssertTrue(waitFor(completed, timeout: 5), "Completed stat should exist")
        XCTAssertTrue(remaining.exists, "Remaining stat should exist")
    }

    // DR-04: Completed task appears in retrospective
    func testCompletedTaskAppearsInReview() {
        // Create and complete a task
        createTaskViaQuickAdd(title: "Review Done Task", tapToday: true)
        tapTab("Today")
        let taskText = app.staticTexts["Review Done Task"]
        _ = waitFor(taskText)
        taskText.swipeRight()
        let doneButton = app.buttons["Done"]
        if waitFor(doneButton, timeout: 3) {
            doneButton.tap()
        }
        sleep(1)

        // Open Daily Review
        openDailyReview()
        _ = waitFor(app.navigationBars["Daily Review"])

        // The completed task should appear
        let completedTask = app.staticTexts["Review Done Task"]
        XCTAssertTrue(waitFor(completedTask, timeout: 5), "Completed task should appear in Daily Review")
    }

    // DR-05: Done button dismisses the sheet
    func testDoneButtonDismisses() {
        openDailyReview()
        _ = waitFor(app.navigationBars["Daily Review"])

        let doneButton = app.buttons["retro_done"]
        XCTAssertTrue(doneButton.exists, "Done button should exist")
        doneButton.tap()

        // Should return to Today view
        let todayNav = app.navigationBars["Today"]
        XCTAssertTrue(waitFor(todayNav, timeout: 5), "Should return to Today view after dismissing")
    }
}
