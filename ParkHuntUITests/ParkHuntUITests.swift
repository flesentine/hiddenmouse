import XCTest

final class ParkHuntUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCriticalControlsAreHittableOnCurrentDevice() {
        launch()

        let start = app.buttons["home.start-hunt"]
        assertExists(
            start,
            timeout: 8,
            message: "Primary Start Hunt button did not appear"
        )
        XCTAssertTrue(
            start.isHittable,
            "Primary Start Hunt button is not hittable on this device size"
        )

        start.tap()

        let found = app.buttons["hunt.found"]
        assertExists(
            found,
            timeout: 8,
            message: "Found control did not appear"
        )
        XCTAssertTrue(
            found.isHittable,
            "Found control is not hittable on this device size"
        )

        let assist = app.buttons["hunt.assist.hint.2"]
        assertExists(
            assist,
            timeout: 5,
            message: "Assist control did not appear"
        )
        XCTAssertTrue(
            assist.isHittable,
            "Assist control is not hittable on this device size"
        )
    }

    @MainActor
    func testFirstLaunchShowsPrimaryHunt() {
        launch()

        assertExists(
            app.navigationBars["Park Hunt"],
            timeout: 8,
            message: "Park Hunt navigation bar did not appear"
        )
        assertExists(
            app.buttons["home.start-hunt"],
            timeout: 8,
            message: "Primary Start Hunt button did not appear"
        )
        assertExists(
            element("home.primary-title"),
            timeout: 2,
            message: "Primary discovery title did not appear"
        )
    }

    @MainActor
    func testDeniedLocationCanBrowseManuallyAndStartHunt() {
        launch(locationDenied: true)

        tapButton("home.nearby")
        assertExists(
            element("nearby.location-denied"),
            timeout: 5,
            message: "Denied-location state did not appear"
        )

        tapButton("nearby.browse-by-area")
        tapButton("manual.park.disneyland")
        tapButton("manual.land.new-orleans-square")
        tapButton("manual.start-suggested")

        assertExists(
            element("hunt.title"),
            timeout: 8,
            message: "Manual browsing did not open a hunt"
        )
        assertExists(
            element("hunt.hint.1"),
            timeout: 5,
            message: "First clue did not appear"
        )
    }

    @MainActor
    func testProgressiveHelpReachesFullReveal() {
        launch()
        startPrimaryHunt()

        assertExists(
            element("hunt.hint.1"),
            timeout: 5,
            message: "First clue did not appear"
        )

        tapButton("hunt.assist.hint.2")
        assertExists(
            element("hunt.hint.2"),
            timeout: 5,
            message: "Second clue did not appear"
        )

        tapButton("hunt.assist.hint.3")
        assertExists(
            element("hunt.hint.3"),
            timeout: 5,
            message: "Detailed hint did not appear"
        )

        tapButton("hunt.assist.reveal")

        assertExists(
            element("reveal.title"),
            timeout: 8,
            message: "Reveal screen did not appear"
        )
        assertExists(
            element("reveal.exact-location"),
            timeout: 5,
            message: "Exact location card did not appear"
        )
    }

    @MainActor
    func testFoundFlowOffersAnotherHunt() {
        launch()
        startPrimaryHunt()

        tapButton("hunt.found")

        assertExists(
            element("hunt.found-success"),
            timeout: 5,
            message: "Found success state did not appear"
        )
        assertExists(
            app.buttons["hunt.find-another"],
            timeout: 5,
            message: "Find Another was not offered"
        )
    }

    @MainActor
    func testUnfinishedHuntRestoresAfterRelaunch() {
        launch()
        startPrimaryHunt()

        tapButton("hunt.assist.hint.2")
        assertExists(
            element("hunt.hint.2"),
            timeout: 5,
            message: "Second clue did not appear before relaunch"
        )

        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        assertExists(
            element("hunt.title"),
            timeout: 8,
            message: "Active hunt was not restored"
        )
        assertExists(
            element("hunt.hint.2"),
            timeout: 5,
            message: "Restored hunt lost its clue progress"
        )
    }

    @MainActor
    private func launch(
        resetState: Bool = true,
        locationDenied: Bool = false
    ) {
        app = XCUIApplication()
        var arguments = ["--ui-testing"]

        if resetState {
            arguments.append("--ui-reset-state")
        }

        if locationDenied {
            arguments.append("--ui-location-denied")
        }

        app.launchArguments = arguments
        app.launch()
    }

    @MainActor
    private func startPrimaryHunt() {
        tapButton("home.start-hunt")
        assertExists(
            element("hunt.title"),
            timeout: 8,
            message: "Primary hunt did not open"
        )
    }

    @MainActor
    private func tapButton(
        _ identifier: String,
        timeout: TimeInterval = 8
    ) {
        let button = app.buttons[identifier]
        let exists = button.waitForExistence(timeout: timeout)
        XCTAssertTrue(
            exists,
            "Missing button: \(identifier)"
        )

        if exists {
            button.tap()
        }
    }

    @MainActor
    private func assertExists(
        _ element: XCUIElement,
        timeout: TimeInterval,
        message: String
    ) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, message)
    }

    @MainActor
    private func element(
        _ identifier: String
    ) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
