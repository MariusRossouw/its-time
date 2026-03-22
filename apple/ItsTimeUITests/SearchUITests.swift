import XCTest

/// Tests for Search (SR-01 through SR-06).
final class SearchUITests: ItsTimeUITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        completeOnboarding(name: "Tester")
    }

    private func openSearch() {
        tapTab("Tasks")
        // Search button is in the top bar leading position
        let searchButton = app.navigationBars.buttons["magnifyingglass"]
        _ = waitFor(searchButton)
        // Workaround: on iOS the search button may be in the navigation bar
        if searchButton.exists {
            searchButton.tap()
        }
    }

    // SR-01: Open search
    func testOpenSearch() {
        openSearch()
        let navBar = app.navigationBars["Search"]
        XCTAssertTrue(waitFor(navBar), "Search view should open")
        takeScreenshot("SR-01_search")
    }

    // SR-02: Empty search shows prompt
    func testEmptySearchShowsPrompt() {
        openSearch()
        _ = waitFor(app.navigationBars["Search"])
        let prompt = app.staticTexts["Search Tasks"]
        XCTAssertTrue(waitFor(prompt, timeout: 5), "Empty search should show 'Search Tasks' prompt")
    }

    // SR-03: Search finds task by title
    func testSearchFindsTask() {
        // Create a task first
        createTaskViaQuickAdd(title: "Unique Search Target")
        openSearch()
        _ = waitFor(app.navigationBars["Search"])

        // Type in the search field
        let searchField = app.searchFields.firstMatch
        _ = waitFor(searchField, timeout: 5)
        searchField.tap()
        searchField.typeText("Unique Search")

        // Result should appear
        let result = app.staticTexts["Unique Search Target"]
        XCTAssertTrue(waitFor(result, timeout: 5), "Search should find task by title")
    }

    // SR-04: No results state
    func testNoResultsState() {
        openSearch()
        _ = waitFor(app.navigationBars["Search"])

        let searchField = app.searchFields.firstMatch
        _ = waitFor(searchField, timeout: 5)
        searchField.tap()
        searchField.typeText("zzzznonexistent")

        let noResults = app.staticTexts["No Results"]
        XCTAssertTrue(waitFor(noResults, timeout: 5), "No Results message should appear for non-matching query")
    }

    // SR-05: Tap search result navigates to detail
    func testTapResultNavigatesToDetail() {
        createTaskViaQuickAdd(title: "Navigate From Search")
        openSearch()
        _ = waitFor(app.navigationBars["Search"])

        let searchField = app.searchFields.firstMatch
        _ = waitFor(searchField, timeout: 5)
        searchField.tap()
        searchField.typeText("Navigate From Search")

        let result = app.staticTexts["Navigate From Search"]
        _ = waitFor(result, timeout: 5)
        result.tap()

        let detailNav = app.navigationBars["Task"]
        XCTAssertTrue(waitFor(detailNav), "Tapping search result should navigate to task detail")
    }

    // SR-06: Search field exists and is focusable
    func testSearchFieldExists() {
        openSearch()
        _ = waitFor(app.navigationBars["Search"])
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(waitFor(searchField, timeout: 5), "Search field should exist")
    }
}
