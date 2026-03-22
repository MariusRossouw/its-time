import XCTest

/// Base class for all Its Time UI tests.
/// Provides shared setup, launch helpers, and common assertions.
class ItsTimeUITestBase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting"]
        // Reset state for clean tests
        app.launchArguments += ["-resetForTesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Directory where test screenshots are saved to disk.
    private static let screenshotDir = "/tmp/ItsTimeScreenshots"

    // MARK: - Screenshots

    /// Take a screenshot, attach it to the xcresult bundle, and save to disk.
    /// - Parameter name: File-friendly name, e.g. "TD-01_task_detail". Saved as {name}.png
    func takeScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()

        // Attach to xcresult (viewable in Xcode → Test Report)
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Save to disk so it can be read outside Xcode
        let fm = FileManager.default
        try? fm.createDirectory(atPath: Self.screenshotDir, withIntermediateDirectories: true)
        let path = "\(Self.screenshotDir)/\(name).png"
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
    }

    // MARK: - Helpers

    /// Launch the app fresh (no existing data).
    func launchFresh() {
        app.launch()
    }

    /// Complete onboarding with a given name and return to the main app.
    func completeOnboarding(name: String = "Test User") {
        launchFresh()
        let nameField = app.textFields["onboarding_name_field"]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText(name)
            app.buttons["onboarding_get_started"].tap()
        }
        // Wait for main app to appear
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)
    }

    /// Navigate to a tab by label.
    /// Handles tabs that are in the "More" overflow on iPhone.
    func tapTab(_ label: String) {
        let tabButton = app.tabBars.buttons[label]
        if tabButton.exists {
            tabButton.tap()
        } else {
            // Tab is in "More" overflow
            let moreButton = app.tabBars.buttons["More"]
            if moreButton.exists {
                moreButton.tap()
                let tableButton = app.tables.buttons[label]
                if tableButton.waitForExistence(timeout: 3) {
                    tableButton.tap()
                } else {
                    // Try static text in the More list
                    let text = app.tables.staticTexts[label]
                    if text.waitForExistence(timeout: 3) {
                        text.tap()
                    }
                }
            }
        }
    }

    /// Wait for an element to exist with a timeout.
    @discardableResult
    func waitFor(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Create a task via QuickAdd from the Today tab.
    /// Assumes we are on the main app (post-onboarding).
    func createTaskViaQuickAdd(title: String, tapToday: Bool = false) {
        let plusMenu = app.buttons["plus_menu"]
        _ = waitFor(plusMenu)
        plusMenu.tap()

        let newTaskButton = app.buttons["menu_new_task"]
        _ = waitFor(newTaskButton)
        newTaskButton.tap()

        let titleField = app.textFields["quick_add_title"]
        _ = waitFor(titleField)
        titleField.tap()
        titleField.typeText(title)

        if tapToday {
            let todayButton = app.buttons["quick_add_today"]
            _ = waitFor(todayButton)
            todayButton.tap()
        }

        app.buttons["quick_add_add"].tap()

        // Wait for sheet to dismiss
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 3)
    }

    /// Create a new list via the Tasks tab.
    func createList(name: String) {
        tapTab("Tasks")
        let newListButton = app.buttons["new_list_button"]
        _ = waitFor(newListButton)
        newListButton.tap()

        let nameField = app.alerts.textFields.firstMatch
        _ = waitFor(nameField)
        nameField.tap()
        nameField.typeText(name)
        app.alerts.buttons["Create"].tap()
    }
}
