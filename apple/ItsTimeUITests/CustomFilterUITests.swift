import XCTest

/// Tests for Custom Filters (CF-01 through CF-05).
final class CustomFilterUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    /// Navigate to Tasks tab and look for filters section or creation path.
    private func navigateToFilterCreation() {
        tapTab("Tasks")
        _ = waitFor(app.navigationBars["Tasks"])

        // Open overflow menu
        let menuButton = app.navigationBars.buttons["More"]
        _ = waitFor(menuButton)
        menuButton.tap()

        // Look for filter-related option
        let newFilter = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'Filter'")).firstMatch
        _ = waitFor(newFilter, timeout: 5)
        newFilter.tap()
    }

    // CF-01: New Filter option exists in Tasks menu
    func testNewFilterMenuOption() {
        tapTab("Tasks")
        _ = waitFor(app.navigationBars["Tasks"])

        let menuButton = app.navigationBars.buttons["More"]
        _ = waitFor(menuButton)
        menuButton.tap()

        let newFilter = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'Filter'")).firstMatch
        XCTAssertTrue(waitFor(newFilter, timeout: 5), "New Filter option should exist in menu")
    }

    // CF-02: Open new filter form
    func testOpenNewFilterForm() {
        navigateToFilterCreation()

        let navBar = app.navigationBars["New Filter"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "New Filter form should open")
    }

    // CF-03: New filter form has name field
    func testFilterFormHasNameField() {
        navigateToFilterCreation()
        _ = waitFor(app.navigationBars["New Filter"])

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(waitFor(nameField, timeout: 5), "Filter form should have a name field")
    }

    // CF-04: Create button disabled when name empty
    func testCreateDisabledWhenEmpty() {
        navigateToFilterCreation()
        _ = waitFor(app.navigationBars["New Filter"])

        let createButton = app.buttons["Create"]
        _ = waitFor(createButton, timeout: 3)
        XCTAssertFalse(createButton.isEnabled, "Create button should be disabled when name is empty")
    }

    // CF-05: Cancel button works
    func testCancelButton() {
        navigateToFilterCreation()
        _ = waitFor(app.navigationBars["New Filter"])

        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Should return to Tasks view
        let tasksNav = app.navigationBars["Tasks"]
        XCTAssertTrue(waitFor(tasksNav, timeout: 5), "Should return to Tasks after canceling")
    }
}
