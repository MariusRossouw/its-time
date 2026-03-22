import XCTest

/// Tests for Sync Profiles (SP-01 through SP-07).
final class SyncProfilesUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func navigateToSyncProfiles() {
        tapTab("Settings")
        _ = waitFor(app.navigationBars["Settings"])

        // Scroll to find Sync Profiles
        for _ in 0..<3 {
            if app.buttons["Sync Profiles"].exists { break }
            app.swipeUp()
        }

        let syncLink = app.buttons["Sync Profiles"]
        _ = waitFor(syncLink, timeout: 5)
        syncLink.tap()
    }

    // SP-01: Navigate to Sync Profiles from Settings
    func testNavigateToSyncProfiles() {
        navigateToSyncProfiles()
        let navBar = app.navigationBars["Sync Profiles"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "Sync Profiles view should open")
    }

    // SP-02: Empty state description shows when no profiles
    func testEmptyStateDescription() {
        navigateToSyncProfiles()
        _ = waitFor(app.navigationBars["Sync Profiles"])
        // There should be descriptive text about sync profiles
        let desc = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'sync' OR label CONTAINS[cd] 'GitHub'")).firstMatch
        XCTAssertTrue(waitFor(desc, timeout: 5), "Description about sync profiles should be visible")
    }

    // SP-03: Add Sync Profile button exists
    func testAddProfileButtonExists() {
        navigateToSyncProfiles()
        _ = waitFor(app.navigationBars["Sync Profiles"])
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Sync Profile'")).firstMatch
        XCTAssertTrue(waitFor(addButton, timeout: 5), "Add Sync Profile button should exist")
    }

    // SP-04: Tap Add opens new profile form
    func testOpenNewProfileForm() {
        navigateToSyncProfiles()
        _ = waitFor(app.navigationBars["Sync Profiles"])
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Sync Profile'")).firstMatch
        _ = waitFor(addButton, timeout: 5)
        addButton.tap()

        let navBar = app.navigationBars["New Sync Profile"]
        XCTAssertTrue(waitFor(navBar, timeout: 5), "New Sync Profile form should open")
    }

    // SP-05: New profile form has name and repo fields
    func testNewProfileFormFields() {
        navigateToSyncProfiles()
        _ = waitFor(app.navigationBars["Sync Profiles"])
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Sync Profile'")).firstMatch
        _ = waitFor(addButton, timeout: 5)
        addButton.tap()

        _ = waitFor(app.navigationBars["New Sync Profile"])
        // Should have at least 2 text fields (name and repo)
        XCTAssertTrue(app.textFields.count >= 2, "Form should have name and repo fields")
    }

    // SP-06: Create button disabled when fields empty
    func testCreateButtonDisabledWhenEmpty() {
        navigateToSyncProfiles()
        _ = waitFor(app.navigationBars["Sync Profiles"])
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Sync Profile'")).firstMatch
        _ = waitFor(addButton, timeout: 5)
        addButton.tap()

        _ = waitFor(app.navigationBars["New Sync Profile"])
        let createButton = app.buttons["Create"]
        _ = waitFor(createButton, timeout: 3)
        XCTAssertFalse(createButton.isEnabled, "Create button should be disabled when fields are empty")
    }

    // SP-07: Cancel button exists and works
    func testCancelButton() {
        navigateToSyncProfiles()
        _ = waitFor(app.navigationBars["Sync Profiles"])
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Sync Profile'")).firstMatch
        _ = waitFor(addButton, timeout: 5)
        addButton.tap()

        _ = waitFor(app.navigationBars["New Sync Profile"])
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Should return to Sync Profiles list
        let profilesNav = app.navigationBars["Sync Profiles"]
        XCTAssertTrue(waitFor(profilesNav, timeout: 5), "Should return to Sync Profiles list")
    }
}
