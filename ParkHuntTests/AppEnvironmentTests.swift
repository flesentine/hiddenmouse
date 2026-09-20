import XCTest
@testable import ParkHunt

final class AppEnvironmentTests: XCTestCase {
    func testPrototypeDoesNotRequireBackend() {
        XCTAssertNil(AppEnvironment.development.apiBaseURL)
        XCTAssertNil(AppEnvironment.production.apiBaseURL)
    }

    func testAnalyticsStartsDisabled() {
        XCTAssertFalse(AppEnvironment.development.analyticsEnabled)
        XCTAssertFalse(AppEnvironment.production.analyticsEnabled)
    }
}
