import XCTest
@testable import ParkHunt

final class AppEnvironmentTests: XCTestCase {
    func testPrototypeDoesNotRequireBackend() {
        XCTAssertNil(AppEnvironment.development.apiBaseURL)
        XCTAssertNil(AppEnvironment.fieldTest.apiBaseURL)
        XCTAssertNil(AppEnvironment.production.apiBaseURL)
    }

    func testAnalyticsStartsDisabled() {
        XCTAssertFalse(AppEnvironment.development.analyticsEnabled)
        XCTAssertFalse(AppEnvironment.fieldTest.analyticsEnabled)
        XCTAssertFalse(AppEnvironment.production.analyticsEnabled)
    }

    func testFieldTestBuildIsClearlyLabeled() {
        XCTAssertEqual(
            AppEnvironment.fieldTest.areaBadgeText,
            "Disneyland field-test area"
        )
        XCTAssertEqual(
            AppEnvironment.fieldTest.buildChannelText,
            "Disneyland Field Test"
        )
        XCTAssertNil(AppEnvironment.production.buildChannelText)
    }
}
