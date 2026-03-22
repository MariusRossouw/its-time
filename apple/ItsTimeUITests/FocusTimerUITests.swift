import XCTest

/// Tests for the Focus Timer (FT-01 through FT-09).
final class FocusTimerUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func openFocus() {
        tapTab("Focus")
        _ = waitFor(app.navigationBars["Focus"])
    }

    // FT-01: Navigate to Focus tab
    func testNavigateToFocus() {
        openFocus()
        let navBar = app.navigationBars["Focus"]
        XCTAssertTrue(navBar.exists, "Focus navigation bar should exist")
        takeScreenshot("FT-01_focus_timer")
    }

    // FT-02: Start Pomodoro timer
    func testStartTimer() {
        openFocus()

        // Tap play button
        let playButton = app.buttons["play.fill"]
        XCTAssertTrue(waitFor(playButton), "Play button should exist")
        playButton.tap()

        // After starting, pause button should appear
        let pauseButton = app.buttons["pause.fill"]
        XCTAssertTrue(waitFor(pauseButton, timeout: 3), "Pause button should appear after starting")
    }

    // FT-03: Pause timer
    func testPauseTimer() {
        openFocus()

        let playButton = app.buttons["play.fill"]
        _ = waitFor(playButton)
        playButton.tap()

        let pauseButton = app.buttons["pause.fill"]
        _ = waitFor(pauseButton)
        pauseButton.tap()

        // Play button should reappear
        XCTAssertTrue(waitFor(app.buttons["play.fill"], timeout: 3), "Play button should reappear after pause")
    }

    // FT-04: Reset timer
    func testResetTimer() {
        openFocus()

        // Reset button
        let resetButton = app.buttons["arrow.counterclockwise"]
        XCTAssertTrue(waitFor(resetButton), "Reset button should exist")
        resetButton.tap()
    }

    // FT-05: Skip to next session
    func testSkipSession() {
        openFocus()

        let skipButton = app.buttons["forward.fill"]
        XCTAssertTrue(waitFor(skipButton), "Skip button should exist")
        skipButton.tap()
    }

    // FT-06: Switch to Stopwatch mode
    func testSwitchToStopwatch() {
        openFocus()

        let stopwatchButton = app.buttons["Stopwatch"]
        XCTAssertTrue(waitFor(stopwatchButton), "Stopwatch mode button should exist")
        stopwatchButton.tap()
    }

    // FT-07: Link a task button exists
    func testLinkTaskButton() {
        openFocus()

        let linkButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Link a task' OR label CONTAINS 'task'")).firstMatch
        XCTAssertTrue(waitFor(linkButton, timeout: 5), "Link a task button should exist")
    }

    // FT-08: Timer display shows time
    func testTimerDisplayExists() {
        openFocus()

        // The timer should show something like "25:00"
        let timerText = app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d+:\\\\d+'")).firstMatch
        XCTAssertTrue(waitFor(timerText, timeout: 5), "Timer display should show time in MM:SS format")
    }

    // FT-09: Focus stats button exists
    func testFocusStatsButton() {
        openFocus()

        let statsButton = app.buttons["chart.bar"]
        XCTAssertTrue(waitFor(statsButton, timeout: 3), "Focus stats button should exist")
    }
}
