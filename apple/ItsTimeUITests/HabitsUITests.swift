import XCTest

/// Tests for Habits (HB-01 through HB-12).
final class HabitsUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func openHabits() {
        tapTab("Habits")
        _ = waitFor(app.navigationBars["Habits"])
    }

    // HB-01: Navigate to Habits tab
    func testNavigateToHabits() {
        openHabits()
        let navBar = app.navigationBars["Habits"]
        XCTAssertTrue(navBar.exists, "Habits navigation bar should exist")
    }

    // HB-02: Empty state shows when no habits
    func testEmptyState() {
        openHabits()
        let emptyTitle = app.staticTexts["No Habits Yet"]
        XCTAssertTrue(waitFor(emptyTitle), "Empty state should show 'No Habits Yet'")
        takeScreenshot("HB-02_habits_empty")
    }

    // HB-03: Plus menu exists with New Habit
    func testPlusMenuExists() {
        openHabits()

        // Tap the + menu in toolbar
        let plusMenu = app.navigationBars["Habits"].buttons.element(boundBy: 0)
        XCTAssertTrue(waitFor(plusMenu), "Plus menu should exist")
        plusMenu.tap()

        let newHabit = app.buttons["New Habit"]
        XCTAssertTrue(waitFor(newHabit), "New Habit option should appear")
    }

    // HB-04: Browse Gallery option exists
    func testBrowseGalleryExists() {
        openHabits()

        let plusMenu = app.navigationBars["Habits"].buttons.element(boundBy: 0)
        _ = waitFor(plusMenu)
        plusMenu.tap()

        let gallery = app.buttons["Browse Gallery"]
        XCTAssertTrue(waitFor(gallery), "Browse Gallery option should appear")
    }

    // HB-05: Create new habit
    func testCreateNewHabit() {
        openHabits()

        let plusMenu = app.navigationBars["Habits"].buttons.element(boundBy: 0)
        _ = waitFor(plusMenu)
        plusMenu.tap()

        let newHabit = app.buttons["New Habit"]
        _ = waitFor(newHabit)
        newHabit.tap()

        // Should show habit editor sheet/view
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(waitFor(nameField, timeout: 5), "Habit name field should appear")
    }

    // HB-06: Habits tab is accessible
    func testHabitsTabAccessible() {
        let habitsTab = app.tabBars.buttons["Habits"]
        XCTAssertTrue(habitsTab.exists, "Habits tab should be accessible")
    }
}
