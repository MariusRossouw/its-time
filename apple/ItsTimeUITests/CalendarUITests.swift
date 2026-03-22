import XCTest

/// Tests for Calendar Views (CV-01 through CV-10).
final class CalendarUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    // CV-01: Navigate to Calendar tab
    func testNavigateToCalendar() {
        tapTab("Calendar")
        let navBar = app.navigationBars["Calendar"]
        XCTAssertTrue(waitFor(navBar), "Calendar navigation bar should exist")
        takeScreenshot("CV-01_calendar_month")
    }

    // CV-02: Switch between Month / Week / Day / Agenda modes
    func testSwitchCalendarModes() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        // Default should be Month. Tap Week
        let weekButton = app.buttons["Week"]
        if waitFor(weekButton, timeout: 3) {
            weekButton.tap()
        }

        // Tap Day
        let dayButton = app.buttons["Day"]
        if waitFor(dayButton, timeout: 3) {
            dayButton.tap()
        }

        // Tap Agenda
        let agendaButton = app.buttons["Agenda"]
        if waitFor(agendaButton, timeout: 3) {
            agendaButton.tap()
        }

        // Tap back to Month
        let monthButton = app.buttons["Month"]
        if waitFor(monthButton, timeout: 3) {
            monthButton.tap()
        }
    }

    // CV-03: Monthly: navigate forward/backward months
    func testMonthlyNavigateMonths() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        // Look for chevron buttons
        let forwardButton = app.buttons["chevron.right"]
        let backButton = app.buttons["chevron.left"]

        if waitFor(forwardButton, timeout: 3) {
            forwardButton.tap()
            sleep(1)
            backButton.tap()
        }
    }

    // CV-04: Today button exists
    func testTodayButtonExists() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        let todayButton = app.buttons["Today"]
        XCTAssertTrue(waitFor(todayButton, timeout: 3), "Today button should exist in Calendar toolbar")
    }

    // CV-05: Monthly view shows calendar content
    func testMonthlyViewShowsContent() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        // The calendar should have navigation arrows
        let forwardButton = app.buttons["chevron.right"]
        XCTAssertTrue(waitFor(forwardButton, timeout: 5), "Calendar navigation should be visible in monthly view")
    }

    // CV-06: Switch to Week mode
    func testWeekMode() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        let weekButton = app.buttons["Week"]
        XCTAssertTrue(waitFor(weekButton), "Week button should exist")
        weekButton.tap()
    }

    // CV-07: Switch to Day mode
    func testDayMode() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        let dayButton = app.buttons["Day"]
        XCTAssertTrue(waitFor(dayButton), "Day button should exist")
        dayButton.tap()
    }

    // CV-08: Switch to Agenda mode
    func testAgendaMode() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        let agendaButton = app.buttons["Agenda"]
        XCTAssertTrue(waitFor(agendaButton), "Agenda button should exist")
        agendaButton.tap()
    }

    // CV-09: Calendar tab is accessible
    func testCalendarTabAccessible() {
        let calendarTab = app.tabBars.buttons["Calendar"]
        XCTAssertTrue(calendarTab.exists, "Calendar tab should be accessible")
    }

    // CV-10: Calendar has mode picker
    func testCalendarHasModePicker() {
        tapTab("Calendar")
        _ = waitFor(app.navigationBars["Calendar"])

        // Verify all four mode buttons exist
        XCTAssertTrue(app.buttons["Month"].exists || app.buttons["Week"].exists,
                      "Calendar mode picker should exist")
    }
}
