import XCTest

final class ParkHuntUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testFirstLaunchShowsPrimaryHunt() {
        launch()

        XCTAssertTrue(
            app.navigationBars["Park Hunt"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.buttons["home.start-hunt"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element("home.primary-title").exists
        )
    }

    func testDeniedLocationCanBrowseManuallyAndStartHunt() {
        launch(locationDenied: true)

        tapButton("home.nearby")
        XCTAssertTrue(
            element("nearby.location-denied").waitForExistence(timeout: 5)
        )

        tapButton("nearby.browse-by-area")
        tapButton("manual.park.disneyland")
        tapButton("manual.land.new-orleans-square")
        tapButton("manual.start-suggested")

        XCTAssertTrue(
            element("hunt.title").waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element("hunt.hint.1").waitForExistence(timeout: 5)
        )
    }

    func testProgressiveHelpReachesFullReveal() {
        launch()
        startPrimaryHunt()

        XCTAssertTrue(
            element("hunt.hint.1").waitForExistence(timeout: 5)
        )

        tapButton("hunt.assist.hint.2")
        XCTAssertTrue(
            element("hunt.hint.2").waitForExistence(timeout: 5)
        )

        tapButton("hunt.assist.hint.3")
        XCTAssertTrue(
            element("hunt.hint.3").waitForExistence(timeout: 5)
        )

        tapButton("hunt.assist.reveal")

        XCTAssertTrue(
            element("reveal.title").waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element("reveal.exact-location").waitForExistence(timeout: 5)
        )
    }

    func testFoundFlowOffersAnotherHunt() {
        launch()
        startPrimaryHunt()

        tapButton("hunt.found")

        XCTAssertTrue(
            element("hunt.found-success").waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["hunt.find-another"].waitForExistence(timeout: 5)
        )
    }

    func testUnfinishedHuntRestoresAfterRelaunch() {
        launch()
        startPrimaryHunt()

        tapButton("hunt.assist.hint.2")
        XCTAssertTrue(
            element("hunt.hint.2").waitForExistence(timeout: 5)
        )

        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(
            element("hunt.title").waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element("hunt.hint.2").waitForExistence(timeout: 5)
        )
    }

    private func launch(
        resetState: Bool = true,
        locationDenied: Bool = false
    ) {
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

    private func startPrimaryHunt() {
        tapButton("home.start-hunt")
        XCTAssertTrue(
            element("hunt.title").waitForExistence(timeout: 8)
        )
    }

    private func tapButton(
        _ identifier: String,
        timeout: TimeInterval = 8
    ) {
        let button = app.buttons[identifier]
        XCTAssertTrue(
            button.waitForExistence(timeout: timeout),
            "Missing button: \(identifier)"
        )
        button.tap()
    }

    private func element(
        _ identifier: String
    ) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
