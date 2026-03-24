import XCTest

/// Tests for Collaboration (CL-01 through CL-14).
final class CollaborationUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func openCollaborators() {
        tapTab("Settings")
        _ = waitFor(app.navigationBars["Settings"])
        app.swipeUp()
        let collabLink = app.staticTexts["Collaborators"]
        _ = waitFor(collabLink, timeout: 5)
        collabLink.tap()
    }

    // CL-01: Open Collaborators manager
    func testOpenCollaborators() {
        openCollaborators()
        let navBar = app.navigationBars["Collaborators"]
        XCTAssertTrue(waitFor(navBar), "Collaborators view should open")
    }

    // CL-02: Current user profile shows
    func testCurrentUserProfileShows() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        // The user created during onboarding ("Tester") should show
        let userText = app.staticTexts["Tester"]
        XCTAssertTrue(waitFor(userText, timeout: 5), "Current user 'Tester' should appear")
    }

    // CL-03: "You" badge shows for current user
    func testYouBadgeShows() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        let youBadge = app.staticTexts["You"]
        XCTAssertTrue(waitFor(youBadge, timeout: 5), "'You' badge should appear for current user")
    }

    // CL-04: Add collaborator button exists
    func testAddCollaboratorButton() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        let addButton = app.buttons["Add Collaborator"]
        XCTAssertTrue(waitFor(addButton, timeout: 5), "Add Collaborator button should exist")
    }

    // CL-05: Add collaborator opens editor
    func testAddCollaboratorOpensEditor() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        let addButton = app.buttons["Add Collaborator"]
        _ = waitFor(addButton, timeout: 5)
        addButton.tap()

        let editorNav = app.navigationBars["Add Collaborator"]
        XCTAssertTrue(waitFor(editorNav), "Add Collaborator editor should open")
    }

    // CL-06: Collaborator editor has name field
    func testEditorHasNameField() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        app.buttons["Add Collaborator"].tap()
        _ = waitFor(app.navigationBars["Add Collaborator"])

        let nameField = app.textFields["Display name"]
        XCTAssertTrue(waitFor(nameField), "Name field should exist in editor")
    }

    // CL-07: Collaborator editor has email field
    func testEditorHasEmailField() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        app.buttons["Add Collaborator"].tap()
        _ = waitFor(app.navigationBars["Add Collaborator"])

        let emailField = app.textFields["Email (optional)"]
        XCTAssertTrue(waitFor(emailField), "Email field should exist in editor")
    }

    // CL-08: Save button disabled when name empty
    func testSaveDisabledWhenEmpty() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        app.buttons["Add Collaborator"].tap()
        _ = waitFor(app.navigationBars["Add Collaborator"])

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(waitFor(saveButton), "Save button should exist")
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled when name is empty")
    }

    // CL-09: Create collaborator
    func testCreateCollaborator() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])
        app.buttons["Add Collaborator"].tap()
        _ = waitFor(app.navigationBars["Add Collaborator"])

        let nameField = app.textFields["Display name"]
        _ = waitFor(nameField)
        nameField.tap()
        nameField.typeText("Alice")

        app.buttons["Save"].tap()

        // Should return to list with new collaborator
        _ = waitFor(app.navigationBars["Collaborators"])
        let alice = app.staticTexts["Alice"]
        XCTAssertTrue(waitFor(alice, timeout: 5), "Created collaborator should appear in list")
    }

    // CL-10: Back button navigates away from collaborators
    func testBackButtonDismisses() {
        openCollaborators()
        _ = waitFor(app.navigationBars["Collaborators"])

        // Collaborators is a navigation destination, not a sheet — use the back button
        let backButton = app.navigationBars["Collaborators"].buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist")
        backButton.tap()

        // Should return to Settings
        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(waitFor(settingsNav, timeout: 5), "Should return to Settings after back")
    }

    // CL-11: Activity & Comments view accessible from task detail
    func testActivityCommentsFromTaskDetail() {
        createTaskViaQuickAdd(title: "Collab Task", tapToday: true)
        tapTab("Today")
        let taskText = app.staticTexts["Collab Task"]
        _ = waitFor(taskText)
        taskText.tap()
        _ = waitFor(app.navigationBars["Task"])

        // Scroll to Activity & Comments
        for _ in 0..<5 {
            if app.staticTexts["Activity & Comments"].exists { break }
            app.swipeUp()
        }
        let activity = app.staticTexts["Activity & Comments"]
        XCTAssertTrue(activity.exists, "Activity & Comments link should be accessible")
        activity.tap()
        let activityNav = app.navigationBars["Activity"]
        XCTAssertTrue(waitFor(activityNav), "Activity view should open")
    }

    // CL-12: Activity log accessible from task detail
    func testActivityFromTaskDetail() {
        createTaskViaQuickAdd(title: "Activity Task", tapToday: true)
        tapTab("Today")
        let taskText = app.staticTexts["Activity Task"]
        _ = waitFor(taskText)
        taskText.tap()
        _ = waitFor(app.navigationBars["Task"])

        for _ in 0..<5 {
            if app.staticTexts["Activity"].exists { break }
            app.swipeUp()
        }
        let activity = app.staticTexts["Activity"]
        XCTAssertTrue(activity.exists, "Activity link should be accessible")
        activity.tap()
        let activityNav = app.navigationBars["Activity"]
        XCTAssertTrue(waitFor(activityNav), "Activity view should open")
    }
}
