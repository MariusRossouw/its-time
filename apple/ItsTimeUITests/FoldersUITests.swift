import XCTest

/// Tests for Folders (FO-01 through FO-05).
final class FoldersUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    // FO-01: Create folder via Tasks menu
    func testCreateFolder() {
        tapTab("Tasks")
        _ = waitFor(app.navigationBars["Tasks"])

        // Tap overflow menu
        let menuButton = app.navigationBars.buttons["More"]
        _ = waitFor(menuButton)
        menuButton.tap()

        let newFolder = app.buttons["New Folder"]
        _ = waitFor(newFolder)
        newFolder.tap()

        // Alert should appear
        let alert = app.alerts["New Folder"]
        XCTAssertTrue(waitFor(alert), "New Folder alert should appear")

        let nameField = alert.textFields.firstMatch
        nameField.tap()
        nameField.typeText("Work")
        alert.buttons["Create"].tap()

        // Folder should appear as a section header
        sleep(1)
        let folderText = app.staticTexts["Work"]
        XCTAssertTrue(waitFor(folderText, timeout: 5), "Folder should appear in task lists")
    }

    // FO-02: New Folder option in menu
    func testNewFolderMenuOption() {
        tapTab("Tasks")
        _ = waitFor(app.navigationBars["Tasks"])

        let menuButton = app.navigationBars.buttons["More"]
        _ = waitFor(menuButton)
        menuButton.tap()

        let newFolder = app.buttons["New Folder"]
        XCTAssertTrue(waitFor(newFolder), "New Folder option should exist in menu")
    }

    // FO-03: New List option in menu
    func testNewListMenuOption() {
        tapTab("Tasks")
        _ = waitFor(app.navigationBars["Tasks"])

        let menuButton = app.navigationBars.buttons["More"]
        _ = waitFor(menuButton)
        menuButton.tap()

        let newList = app.buttons["New List"]
        XCTAssertTrue(waitFor(newList), "New List option should exist in menu")
    }

    // FO-04: Folder cancel button works
    func testFolderCancelButton() {
        tapTab("Tasks")
        _ = waitFor(app.navigationBars["Tasks"])

        let menuButton = app.navigationBars.buttons["More"]
        _ = waitFor(menuButton)
        menuButton.tap()
        app.buttons["New Folder"].tap()

        let alert = app.alerts["New Folder"]
        _ = waitFor(alert)
        alert.buttons["Cancel"].tap()

        // Alert should dismiss
        XCTAssertFalse(alert.exists, "Alert should dismiss after cancel")
    }

    // FO-05: Lists section has New List button
    func testNewListButtonInSection() {
        tapTab("Tasks")
        _ = waitFor(app.navigationBars["Tasks"])

        let newListButton = app.buttons["new_list_button"]
        XCTAssertTrue(waitFor(newListButton, timeout: 5), "New List button should exist in Lists section")
    }
}
