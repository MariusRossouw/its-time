import XCTest

/// Tests for Settings (SE-01 through SE-15).
final class SettingsUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func openSettings() {
        tapTab("Settings")
        let navBar = app.navigationBars["Settings"]
        _ = waitFor(navBar)
    }

    // SE-01: Navigate to Settings tab
    func testNavigateToSettings() {
        openSettings()
        let navBar = app.navigationBars["Settings"]
        XCTAssertTrue(navBar.exists, "Settings navigation bar should exist")
        takeScreenshot("SE-01_settings")
    }

    // SE-02: Theme picker exists
    func testThemePickerExists() {
        openSettings()
        let theme = app.staticTexts["Theme"]
        XCTAssertTrue(waitFor(theme), "Theme picker should exist")
    }

    // SE-03: Week starts on picker exists
    func testWeekStartsOnExists() {
        openSettings()
        let picker = app.staticTexts["Week Starts On"]
        XCTAssertTrue(waitFor(picker), "Week Starts On picker should exist")
    }

    // SE-04: Time format picker exists
    func testTimeFormatExists() {
        openSettings()
        let picker = app.staticTexts["Time Format"]
        XCTAssertTrue(waitFor(picker), "Time Format picker should exist")
    }

    // SE-05: Default priority picker exists
    func testDefaultPriorityExists() {
        openSettings()
        let picker = app.staticTexts["Default Priority"]
        XCTAssertTrue(waitFor(picker), "Default Priority picker should exist")
    }

    // SE-06: Focus timer steppers exist
    func testFocusTimerSteppersExist() {
        openSettings()
        // Scroll to find the Focus section
        let focusText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Focus:'")).firstMatch
        XCTAssertTrue(waitFor(focusText, timeout: 5), "Focus timer stepper should exist")
    }

    // SE-07: Daily summary toggle exists
    func testDailySummaryToggleExists() {
        openSettings()
        let toggle = app.switches["Daily Summary"]
        // May need to scroll
        app.swipeUp()
        XCTAssertTrue(waitFor(toggle, timeout: 5), "Daily Summary toggle should exist")
    }

    // SE-08: Quiet hours toggle exists
    func testQuietHoursToggleExists() {
        openSettings()
        app.swipeUp()
        let toggle = app.switches["Quiet Hours"]
        XCTAssertTrue(waitFor(toggle, timeout: 5), "Quiet Hours toggle should exist")
    }

    // SE-09: Badge count toggle exists
    func testBadgeCountToggleExists() {
        openSettings()
        app.swipeUp()
        let toggle = app.switches["Badge Count"]
        XCTAssertTrue(waitFor(toggle, timeout: 5), "Badge Count toggle should exist")
    }

    // SE-10: Sync Profiles navigation link exists
    func testSyncProfilesExists() {
        openSettings()
        app.swipeUp()
        let link = app.staticTexts["Sync Profiles"]
        XCTAssertTrue(waitFor(link, timeout: 5), "Sync Profiles link should exist")
    }

    // SE-11: Auto-Sync toggle exists
    func testAutoSyncToggleExists() {
        openSettings()
        app.swipeUp()
        let toggle = app.switches["Auto-Sync"]
        XCTAssertTrue(waitFor(toggle, timeout: 5), "Auto-Sync toggle should exist")
    }

    // SE-12: Calendar Accounts section exists
    func testCalendarAccountsSectionExists() {
        openSettings()
        app.swipeUp()
        let info = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'calendar accounts'")).firstMatch
        XCTAssertTrue(waitFor(info, timeout: 5), "Calendar accounts info text should exist")
    }

    // SE-13: Collaborators navigation link exists
    func testCollaboratorsExists() {
        openSettings()
        app.swipeUp()
        let link = app.staticTexts["Collaborators"]
        XCTAssertTrue(waitFor(link, timeout: 5), "Collaborators link should exist")
    }

    // SE-14: Automations navigation link exists
    func testAutomationsExists() {
        openSettings()
        app.swipeUp()
        let link = app.staticTexts["Automations"]
        XCTAssertTrue(waitFor(link, timeout: 5), "Automations link should exist")
    }

    // SE-15: Version and build info exists
    func testVersionInfoExists() {
        openSettings()
        // Scroll to the very bottom
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        // Version may be a LabeledContent or a static text
        let version = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0.1.0'")).firstMatch
        XCTAssertTrue(waitFor(version, timeout: 5), "Version 0.1.0 should be visible")
    }
}
