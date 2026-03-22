import XCTest

/// Tests for Notes (NE-01 through NE-07).
final class NotesUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    /// Create a note and open it via Search (more reliable than navigating lists).
    private func createAndOpenNote(title: String = "Test Note") {
        // Create note via quick add
        let plusMenu = app.buttons["plus_menu"]
        _ = waitFor(plusMenu)
        plusMenu.tap()
        let newNote = app.buttons["menu_new_note"]
        _ = waitFor(newNote)
        newNote.tap()

        let titleField = app.textFields["quick_add_note_title"]
        _ = waitFor(titleField)
        titleField.tap()
        titleField.typeText(title)
        app.buttons["quick_add_note_create"].tap()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)

        // Open via Search
        tapTab("Tasks")
        let searchButton = app.navigationBars.buttons["magnifyingglass"]
        _ = waitFor(searchButton)
        // Fallback: find by identifier
        if searchButton.exists {
            searchButton.tap()
        }

        _ = waitFor(app.navigationBars["Search"])
        let searchField = app.searchFields.firstMatch
        _ = waitFor(searchField, timeout: 5)
        searchField.tap()
        searchField.typeText(title)

        let result = app.staticTexts[title]
        _ = waitFor(result, timeout: 5)
        result.tap()
    }

    // NE-01: Open note → NoteEditorView displayed
    func testOpenNoteEditor() {
        createAndOpenNote(title: "My Note")
        let navBar = app.navigationBars["Note"]
        XCTAssertTrue(waitFor(navBar), "Note editor should open with 'Note' navigation title")
    }

    // NE-02: Note title field exists
    func testNoteHasTitleField() {
        createAndOpenNote(title: "Title Note")
        _ = waitFor(app.navigationBars["Note"])
        let titleField = app.textFields["note_title_field"]
        XCTAssertTrue(waitFor(titleField, timeout: 5), "Note title field should exist")
    }

    // NE-03: Note has content area
    func testNoteHasContentArea() {
        createAndOpenNote(title: "Content Note")
        _ = waitFor(app.navigationBars["Note"])
        // Text editor for content
        let textEditor = app.textViews.firstMatch
        XCTAssertTrue(waitFor(textEditor, timeout: 5), "Note content editor should exist")
    }

    // NE-04: Note toolbar has buttons
    func testNoteToolbarExists() {
        createAndOpenNote(title: "Toolbar Note")
        _ = waitFor(app.navigationBars["Note"])
        let toolbar = app.navigationBars["Note"]
        XCTAssertTrue(toolbar.buttons.count > 0, "Note toolbar should have buttons")
    }

    // NE-05: Create and find note
    func testNoteAppearsInSearch() {
        // Create a note
        let plusMenu = app.buttons["plus_menu"]
        _ = waitFor(plusMenu)
        plusMenu.tap()
        let newNote = app.buttons["menu_new_note"]
        _ = waitFor(newNote)
        newNote.tap()

        let titleField = app.textFields["quick_add_note_title"]
        _ = waitFor(titleField)
        titleField.tap()
        titleField.typeText("Searchable Note")
        app.buttons["quick_add_note_create"].tap()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)

        // Search for it
        tapTab("Tasks")
        app.navigationBars.buttons["magnifyingglass"].tap()
        _ = waitFor(app.navigationBars["Search"])
        let searchField = app.searchFields.firstMatch
        _ = waitFor(searchField, timeout: 5)
        searchField.tap()
        searchField.typeText("Searchable Note")

        let result = app.staticTexts["Searchable Note"]
        XCTAssertTrue(waitFor(result, timeout: 5), "Note should be findable via search")
    }

    // NE-06: Note appears in Inbox
    func testNoteAppearsInInbox() {
        let plusMenu = app.buttons["plus_menu"]
        _ = waitFor(plusMenu)
        plusMenu.tap()
        let newNote = app.buttons["menu_new_note"]
        _ = waitFor(newNote)
        newNote.tap()

        let titleField = app.textFields["quick_add_note_title"]
        _ = waitFor(titleField)
        titleField.tap()
        titleField.typeText("Inbox Note")
        app.buttons["quick_add_note_create"].tap()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)

        // Navigate to Inbox
        tapTab("Tasks")
        let inbox = app.staticTexts["Inbox"]
        _ = waitFor(inbox)
        inbox.tap()

        let noteText = app.staticTexts["Inbox Note"]
        XCTAssertTrue(waitFor(noteText, timeout: 5), "Note should appear in Inbox")
    }

    // NE-07: Quick add note cancel works
    func testQuickAddNoteCancelWorks() {
        let plusMenu = app.buttons["plus_menu"]
        _ = waitFor(plusMenu)
        plusMenu.tap()
        let newNote = app.buttons["menu_new_note"]
        _ = waitFor(newNote)
        newNote.tap()

        _ = waitFor(app.navigationBars["New Note"])
        app.buttons["quick_add_note_cancel"].tap()

        // Should return to main app
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitFor(tabBar), "Tab bar should be visible after canceling")
    }
}
