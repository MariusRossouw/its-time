import XCTest

/// Tests for Habit Detail and Editor (HB-07 through HB-12).
final class HabitDetailUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    /// Create a habit and navigate to it.
    private func createHabitAndOpen(name: String = "Test Habit") {
        tapTab("Habits")
        _ = waitFor(app.navigationBars["Habits"])

        // Tap plus menu
        let plusButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS 'plus' OR label CONTAINS 'Add'")).firstMatch
        _ = waitFor(plusButton, timeout: 5)
        plusButton.tap()

        // Select "New Habit" from the menu
        let newHabit = app.buttons.matching(NSPredicate(format: "label CONTAINS 'New Habit'")).firstMatch
        _ = waitFor(newHabit, timeout: 3)
        newHabit.tap()

        // Fill in the habit name
        _ = waitFor(app.navigationBars["New Habit"])
        let nameField = app.textFields.firstMatch
        _ = waitFor(nameField, timeout: 5)
        nameField.tap()
        nameField.typeText(name)

        // Tap Create
        let createButton = app.buttons["Create"]
        _ = waitFor(createButton)
        createButton.tap()

        // Wait for dismissal and navigate to the habit
        sleep(1)
        let habitText = app.staticTexts[name]
        _ = waitFor(habitText, timeout: 5)
        habitText.tap()
    }

    // HB-07: Create habit and navigate to detail
    func testNavigateToHabitDetail() {
        createHabitAndOpen(name: "Morning Run")
        // Verify we're on the habit detail (nav bar shows habit name)
        let navBar = app.navigationBars["Morning Run"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "Habit detail should open with habit name as title")
    }

    // HB-08: Habit detail shows check-in button
    func testCheckInButtonExists() {
        createHabitAndOpen(name: "Read Book")
        _ = waitFor(app.navigationBars["Read Book"])

        // Check-in button should exist (either "Check In" or "Add One")
        let checkIn = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'Check In' OR label CONTAINS[cd] 'Add One'")).firstMatch
        XCTAssertTrue(waitFor(checkIn, timeout: 5), "Check-in button should exist in habit detail")
    }

    // HB-09: Habit detail shows stats cards
    func testStatsCardsExist() {
        createHabitAndOpen(name: "Meditate")
        _ = waitFor(app.navigationBars["Meditate"])

        // Look for streak and total stats labels
        let currentStreak = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'Current'")).firstMatch
        let bestStreak = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'Best'")).firstMatch
        let total = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'Total'")).firstMatch

        XCTAssertTrue(waitFor(currentStreak, timeout: 5), "Current streak card should exist")
        XCTAssertTrue(bestStreak.exists, "Best streak card should exist")
        XCTAssertTrue(total.exists, "Total completions card should exist")
    }

    // HB-10: Habit editor opens from detail
    func testEditHabitOpens() {
        createHabitAndOpen(name: "Drink Water")
        _ = waitFor(app.navigationBars["Drink Water"])

        // Tap the overflow menu
        let menuButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS 'More' OR label CONTAINS 'ellipsis'")).firstMatch
        _ = waitFor(menuButton, timeout: 5)
        menuButton.tap()

        let editButton = app.buttons["Edit"]
        _ = waitFor(editButton, timeout: 3)
        editButton.tap()

        let editNav = app.navigationBars["Edit Habit"]
        XCTAssertTrue(waitFor(editNav, timeout: 5), "Edit Habit form should open")
    }

    // HB-11: Archive habit option exists
    func testArchiveOptionExists() {
        createHabitAndOpen(name: "Exercise")
        _ = waitFor(app.navigationBars["Exercise"])

        let menuButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS 'More' OR label CONTAINS 'ellipsis'")).firstMatch
        _ = waitFor(menuButton, timeout: 5)
        menuButton.tap()

        let archiveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'Archive'")).firstMatch
        XCTAssertTrue(waitFor(archiveButton, timeout: 3), "Archive option should exist in habit detail menu")
    }

    // HB-12: Punch card grid exists
    func testPunchCardExists() {
        createHabitAndOpen(name: "Journal")
        _ = waitFor(app.navigationBars["Journal"])

        // Scroll to find punch card section
        for _ in 0..<3 {
            if app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'Last' OR label CONTAINS[cd] 'Weeks'")).firstMatch.exists { break }
            app.swipeUp()
        }

        let punchCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'Last' OR label CONTAINS[cd] 'Weeks'")).firstMatch
        XCTAssertTrue(waitFor(punchCard, timeout: 5), "Punch card section should exist")
    }
}
