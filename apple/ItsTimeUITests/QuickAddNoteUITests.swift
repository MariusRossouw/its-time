import XCTest

/// Tests for the Quick Add Note flow (QN-01 through QN-03).
final class QuickAddNoteUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    // MARK: - Helpers

    /// Open the quick add note sheet from the Today tab's plus menu.
    private func openQuickAddNote() {
        let plusMenu = app.buttons["plus_menu"]
        XCTAssertTrue(waitFor(plusMenu), "Plus menu should exist")
        plusMenu.tap()

        let newNoteButton = app.buttons["menu_new_note"]
        XCTAssertTrue(waitFor(newNoteButton), "New Note menu item should exist")
        newNoteButton.tap()
    }

    // QN-01: Open quick add note sheet
    func testOpenQuickAddNoteSheet() {
        openQuickAddNote()
        let navTitle = app.navigationBars["New Note"]
        XCTAssertTrue(waitFor(navTitle), "Quick Add Note sheet should show 'New Note' navigation title")
    }

    // QN-02: Create note with title
    func testCreateNoteWithTitle() {
        openQuickAddNote()

        let titleField = app.textFields["quick_add_note_title"]
        XCTAssertTrue(waitFor(titleField), "Note title field should exist")
        titleField.tap()
        titleField.typeText("Meeting notes")

        let createButton = app.buttons["quick_add_note_create"]
        XCTAssertTrue(createButton.isEnabled, "Create button should be enabled after entering title")
        createButton.tap()

        // Sheet should dismiss
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitFor(tabBar), "Tab bar should be visible after creating note")
    }

    // QN-03: Cancel note creation
    func testCancelNoteCreation() {
        openQuickAddNote()

        let titleField = app.textFields["quick_add_note_title"]
        XCTAssertTrue(waitFor(titleField), "Note title field should exist")
        titleField.tap()
        titleField.typeText("Draft note")

        let cancelButton = app.buttons["quick_add_note_cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Sheet should dismiss
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitFor(tabBar), "Tab bar should be visible after canceling")
    }
}
