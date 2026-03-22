import XCTest

/// Tests for Automations/Triggers (TR-01 through TR-06).
final class AutomationsUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func navigateToAutomations() {
        tapTab("Settings")
        _ = waitFor(app.navigationBars["Settings"])

        // Scroll to find Automations
        for _ in 0..<3 {
            if app.buttons["Automations"].exists { break }
            app.swipeUp()
        }

        let automationsLink = app.buttons["Automations"]
        _ = waitFor(automationsLink, timeout: 5)
        automationsLink.tap()
    }

    // TR-01: Navigate to Automations from Settings
    func testNavigateToAutomations() {
        navigateToAutomations()
        let navBar = app.navigationBars["Automations"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "Automations view should open")
    }

    // TR-02: Empty state shows when no automations
    func testEmptyState() {
        navigateToAutomations()
        _ = waitFor(app.navigationBars["Automations"])
        let emptyText = app.staticTexts["No Automations"]
        XCTAssertTrue(waitFor(emptyText, timeout: 5), "Empty state should show 'No Automations'")
    }

    // TR-03: New automation button exists
    func testPlusButtonExists() {
        navigateToAutomations()
        _ = waitFor(app.navigationBars["Automations"])
        let plusButton = app.buttons["new_automation_button"]
        XCTAssertTrue(waitFor(plusButton, timeout: 5), "New automation button should exist in toolbar")
    }

    // TR-04: Tap plus opens new automation form
    func testOpenNewAutomationForm() {
        navigateToAutomations()
        _ = waitFor(app.navigationBars["Automations"])
        let plusButton = app.buttons["new_automation_button"]
        _ = waitFor(plusButton, timeout: 5)
        plusButton.tap()

        let navBar = app.navigationBars["New Automation"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "New Automation form should open")
    }

    // TR-05: New automation form has name field
    func testNewAutomationHasNameField() {
        navigateToAutomations()
        _ = waitFor(app.navigationBars["Automations"])
        let plusButton = app.buttons["new_automation_button"]
        _ = waitFor(plusButton, timeout: 5)
        plusButton.tap()

        _ = waitFor(app.navigationBars["New Automation"])
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(waitFor(nameField, timeout: 5), "Name field should exist in automation form")
    }

    // TR-06: Log button exists in automations toolbar
    func testLogButtonExists() {
        navigateToAutomations()
        _ = waitFor(app.navigationBars["Automations"])
        let logButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'list' OR label CONTAINS 'clipboard' OR label CONTAINS 'Log'")).firstMatch
        XCTAssertTrue(waitFor(logButton, timeout: 5), "Log button should exist in automations toolbar")
    }
}
